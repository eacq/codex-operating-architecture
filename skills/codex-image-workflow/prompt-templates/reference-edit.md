# Reference Edit Prompt

Edit the supplied user-owned reference image according to the request. Use the
image as the authority for identity, geometry, lighting, and composition unless
the requested change explicitly says otherwise.

Subject to preserve: {{preserve}}
Requested change: {{change}}
Edit area or mask: {{edit_area}}
Output use: {{purpose}}
Aspect ratio: {{aspect_ratio}}

Step 1 - inspect before editing:

- Identify the main subject, background, camera angle, crop, perspective,
  lighting direction, shadows, reflections, texture, color temperature, and any
  text or logos already present.
- Treat everything in `Subject to preserve` as locked unless it conflicts with
  `Requested change`.

Step 2 - apply the edit:

- Apply the requested change only inside the specified edit area or the smallest
  visually necessary region.
- Preserve subject identity, pose, proportions, composition, perspective,
  material texture, lighting, shadows, reflections, and background continuity.
- Reconstruct removed or changed regions naturally; edges must blend with the
  surrounding pixels.
- If the task is expansion/outpainting, extend the scene plausibly without
  stretching the subject or changing the original crop logic.
- If the task is style transfer, preserve the subject, pose, composition, and
  key details while changing only the requested style attributes.
- If the task is product, ad, paper, or presentation use, keep clean negative
  space where requested but do not add text unless explicitly required.

Quality bar:

- The edit should look like a single coherent original image, not a pasted
  patch.
- No visible seams, warped anatomy, inconsistent shadows, duplicated objects,
  blurry repair zones, or mismatched texture.

Do not include:

- Extra objects, new people, unintended style transfer, watermarks, fake
  signatures, fake claims, new logos, unsolicited text, or changes outside the
  requested area.
