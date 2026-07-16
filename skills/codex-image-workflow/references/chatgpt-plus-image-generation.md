# ChatGPT Plus Image Generation

This workflow uses the user's existing OpenAI/ChatGPT login through a visible browser session or a host-authorized Codex image tool. It is not an OpenAI API integration and must not read, export, copy, or store browser cookies, access tokens, passwords, or local account state.

## Capability boundary

- ChatGPT Plus provides broader ChatGPT web-app access, including image generation when available to the account. Model and tool availability can change; verify in the ChatGPT model/tool picker at use time.
- OpenAI API image generation is separate from ChatGPT Plus subscription billing. Use API workflows only when a real API key and API billing path are intentionally configured.
- Browser automation may open ChatGPT and paste or copy a prompt for visible user-approved work. Host-native generation may read a saved prompt file and call the platform image tool when that tool is available. Neither path may operate as a hidden credential extractor.
- A local Codex CLI handoff can be attempted only when the CLI is executable and already authenticated. If CLI execution fails or the plan/tool is unavailable, keep the prompt request folder and stop with a visible-login refresh or host-tool fallback.

## Project workflow

1. Decide whether a generated image materially improves the project or knowledge note.
2. Render the prompt from direct text, a prompt file, or a template:
   `scripts/New-ChatGPTImageRequest.ps1 -ProjectRoot <root> -PromptFile <file> -Purpose <purpose> -Destination <path>`.
3. For reusable requirements, prefer `-Template <name> -Set key=value` using the files under `prompt-templates/`.
4. The script writes `.codex/images/chatgpt-plus/<timestamp>/request.json`, `prompt.md`, and `codex-handoff.md`.
5. Generate the image through the host image tool, visible ChatGPT session, or `-InvokeCodexCli` when the local Codex CLI is executable and already authenticated. If login, plan, CLI, or tool access fails, stop and ask the user to refresh the available login path.
6. Save the downloaded or generated image under the project or knowledge-vault image workspace, then record provenance: prompt file, generation date, account mode `chatgpt-plus-visible-session` or `host-openai-login`, and any manual edits.
7. If the image should be embedded broadly, pass it through the normal image workflow: verify, optionally host, rewrite links, and retain migration manifests.

## Safety rules

- Do not store account email, cookies, tokens, passwords, browser profile files, or ChatGPT conversation exports in Git.
- Do not upload confidential, private, paywalled, or unlicensed source images unless the user explicitly owns and authorizes that use.
- Do not promise stable batch generation, API limits, or reproducible seeds through the ChatGPT web UI.
- If the request requires unattended batch generation, use the official OpenAI API route instead of the Plus web route.
- Prompt templates are allowed in Git; rendered project prompts are allowed only when they contain no private source text, secrets, or account identifiers.

## Sources checked 2026-07-15

- OpenAI Help Center: <https://help.openai.com/en/articles/6950777-what-is-chatgpt-plus>
- OpenAI image generation API guide: <https://platform.openai.com/docs/guides/image-generation>
