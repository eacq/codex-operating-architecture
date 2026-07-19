import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const args = new Map();
for (let index = 2; index < process.argv.length; index += 2) args.set(process.argv[index], process.argv[index + 1]);

const required = (name) => {
  const value = args.get(name);
  if (!value) throw new Error(`Missing ${name}.`);
  return value;
};

const playwrightRoot = required("--playwright-root");
const playwrightModule = await import(pathToFileURL(path.join(playwrightRoot, "index.js")).href);
const { chromium } = playwrightModule.default ?? playwrightModule;
const outputDirectory = required("--frames-dir");
const frameCount = Number(args.get("--frames") ?? "120");
const width = Number(args.get("--width") ?? "1200");
const height = Number(args.get("--height") ?? "570");
const zoomSteps = Number(args.get("--zoom-steps") ?? "15");
const frameRenderWaitMs = Number(args.get("--frame-render-wait-ms") ?? "20");
const staticFrame = args.get("--static") === "true";
const uiUrl = required("--ui-url").replace(/\/$/, "");
const project = required("--project");

function pathToFileURL(filePath) {
  return new URL(`file:///${filePath.replace(/\\/g, "/")}`);
}

fs.mkdirSync(outputDirectory, { recursive: true });

const browser = await chromium.launch({
  executablePath: required("--chrome-path"),
  headless: true,
  args: ["--enable-webgl", "--ignore-gpu-blocklist", "--use-angle=swiftshader-webgl", "--enable-unsafe-swiftshader"],
});

try {
  const page = await browser.newPage({
    viewport: { width: width + 264, height: height + 48 },
    deviceScaleFactor: 1,
  });
  await page.addInitScript((projectName) => {
    const getContext = HTMLCanvasElement.prototype.getContext;
    HTMLCanvasElement.prototype.getContext = function (type, attributes) {
      const webgl = type === "webgl" || type === "webgl2" || type === "experimental-webgl";
      return getContext.call(this, type, webgl ? { ...attributes, preserveDrawingBuffer: true } : attributes);
    };
    localStorage.setItem(`cbm-node-budget:${projectName}`, "20000");
    localStorage.setItem("cbm-display", JSON.stringify({ edgeBrightness: 1, nodeGlow: 1, bloom: 1 }));
  }, project);
  await page.goto(`${uiUrl}/?tab=graph&project=${encodeURIComponent(project)}`, { waitUntil: "networkidle", timeout: 120000 });
  await page.waitForSelector("canvas", { timeout: 120000 });
  await page.waitForTimeout(5000);
  await page.evaluate(() => [...document.querySelectorAll("button")].find((button) => button.textContent.includes("Show labels"))?.click());

  const canvas = page.locator("canvas");
  const box = await canvas.boundingBox();
  for (let index = 0; index < zoomSteps; index += 1) {
    await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2);
    await page.mouse.wheel(0, 100);
    await page.waitForTimeout(120);
  }
  await page.waitForTimeout(1000);

  await page.evaluate(() => {
    const sample = document.createElement("canvas");
    sample.width = 120;
    sample.height = 57;
    const context = sample.getContext("2d", { willReadFrequently: true });
    window.__codebaseMemoryGraphSignature = () => {
      context.drawImage(document.querySelector("canvas"), 0, 0, sample.width, sample.height);
      return Array.from(context.getImageData(0, 0, sample.width, sample.height).data);
    };
  });

  const captureFrame = async (index) => {
    const [signature, dataUrl] = await page.evaluate(() => [window.__codebaseMemoryGraphSignature(), document.querySelector("canvas").toDataURL("image/png")]);
    const filename = path.join(outputDirectory, `frame-${String(index).padStart(3, "0")}.png`);
    fs.writeFileSync(filename, Buffer.from(dataUrl.split(",")[1], "base64"));
    return signature;
  };
  const signatureDistance = (left, right) => left.reduce((total, value, index) => total + Math.abs(value - right[index]), 0) / left.length;
  const initialSignature = await captureFrame(0);
  if (staticFrame) {
    fs.writeFileSync(path.join(outputDirectory, "capture.json"), JSON.stringify({ loop_frame_count: 1, loop_distance: 0 }));
  } else {
    const startX = box.x + (box.width - box.height) / 2;
    const centerY = box.y + box.height / 2;
    const minimumRotationFrames = Math.ceil(frameCount * 0.75);
    const maximumRotationFrames = frameCount * 3;
    const returnThreshold = 0.5;
    let bestIndex = -1;
    let bestDistance = Number.POSITIVE_INFINITY;
    await page.mouse.move(startX, centerY);
    await page.mouse.down();
    for (let index = 1; index <= maximumRotationFrames; index += 1) {
      const phase = index % frameCount || frameCount;
      await page.mouse.move(startX + phase * box.height / frameCount, centerY);
      await page.waitForTimeout(frameRenderWaitMs);
      const distance = signatureDistance(initialSignature, await captureFrame(index));
      if (index >= minimumRotationFrames && distance < bestDistance) {
        bestDistance = distance;
        bestIndex = index;
      }
      if (index >= minimumRotationFrames && distance <= returnThreshold) break;
      if (phase === frameCount && index < maximumRotationFrames) {
        await page.mouse.up();
        await page.mouse.move(startX, centerY);
        await page.mouse.down();
      }
    }
    await page.mouse.up();
    if (bestIndex < 0 || bestDistance > returnThreshold) throw new Error("The UI rotation did not return to the initial graph state.");
    fs.writeFileSync(path.join(outputDirectory, "capture.json"), JSON.stringify({ loop_frame_count: bestIndex, loop_distance: bestDistance }));
  }
} finally {
  await browser.close();
}
