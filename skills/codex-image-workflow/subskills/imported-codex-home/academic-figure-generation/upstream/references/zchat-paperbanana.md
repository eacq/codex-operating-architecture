# ZCHAT + PaperBanana Reference

Use this reference when a user asks to configure, debug, or run ke yan hua tu /
academic-figure generation with ZCHAT.

## Credential Handling

- Do not print the full API key.
- Current credential locations:
  - Windows user environment variable: `ZCHAT_API_KEY`
  - Codex auth file: `%USERPROFILE%\.codex\auth.json`
  - `auth.json` should contain:

    ```json
    {
      "auth_mode": "apikey",
      "OPENAI_API_KEY": "..."
    }
    ```

- PaperBanana runner maps `ZCHAT_API_KEY` to `OPENAI_API_KEY` at runtime.
- Keep PaperBanana `model_config.yaml` free of hardcoded secrets when possible.

## ZCHAT API

Base URL:

```text
https://api.zchat.tech/v1
```

Chat completions endpoint:

```text
https://api.zchat.tech/v1/chat/completions
```

Embeddings endpoint:

```text
https://api.zchat.tech/v1/embeddings
```

Documented chat models:

```text
gpt-5
gpt-5-thinking
claude-sonnet-4-5
grok-3
grok-4
gemini-3-pro
```

Documented embedding models:

```text
text-embedding-ada-002
text-embedding-3-small
text-embedding-3-large
```

ZCHAT notes from user-provided docs:

- It uses OpenAI-compatible output.
- It may not support OpenAI temperature/length parameters.
- Avoid high-concurrency apps such as immersive translation.
- Do not continue prompts that trigger safety/moral review warnings.
- Do not use it for sexual, violent, bloody role-play, jailbreaks, or policy-abusive requests.

## Codex Desktop Config

Config file:

```text
%USERPROFILE%\.codex\config.toml
```

Required core provider config:

```toml
model_provider = "openai-chat-completions"
model = "gpt-5"

[model_providers.openai-chat-completions]
name = "ZCHAT"
wire_api = "responses"
base_url = "https://api.zchat.tech/v1"
```

Preserve desktop/plugin/runtime sections already present in the user's
`config.toml`; do not wipe them unless the user explicitly asks.

If `gpt-5` is unavailable, change both Codex and PaperBanana model config to a
currently working ZCHAT model, commonly `grok-3` or `gemini-3-pro`.

## PaperBanana Config

Configured local root:

```text
%USERPROFILE%\Documents\Codex\2026-07-09\qin\work\PaperBanana
```

PaperBanana config file:

```text
%USERPROFILE%\Documents\Codex\2026-07-09\qin\work\PaperBanana\configs\model_config.yaml
```

Expected ZCHAT-compatible config:

```yaml
defaults:
  main_model_name: "gpt-5"
  image_gen_model_name: "gpt-5"

api_keys:
  google_api_key: ""
  openai_api_key: ""
  openai_base_url: "https://api.zchat.tech/v1"
  anthropic_api_key: ""
  openrouter_api_key: ""

compatibility:
  omit_openai_sampling_params: true
```

Important implementation detail: this local PaperBanana copy has been adapted
so that when only an OpenAI-compatible chat client is available, diagram
generation falls back to asking the model for matplotlib code and rendering the
PNG locally.

## Python Runtime Integration

Codex primary Python:

```text
%USERPROFILE%\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe
```

PaperBanana dedicated Python:

```text
%USERPROFILE%\Documents\Codex\2026-07-09\qin\work\PaperBanana\.venv\Scripts\python.exe
```

The Codex primary Python has been prepared with the runtime packages needed by
this skill:

```text
pyyaml
openai
google-genai
anthropic
httpx
aiofiles
tqdm
json_repair
huggingface_hub
python-dotenv
```

It also already has the bundled scientific stack used for local rendering:

```text
pillow
matplotlib
numpy
pandas
```

Check runtime status with:

```powershell
%USERPROFILE%\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe `
  %USERPROFILE%\.codex\skills\academic-figure-generation\scripts\check_runtime.py
```

If Codex updates and resets the primary runtime, reinstall with:

```powershell
%USERPROFILE%\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe `
  -m pip install pyyaml openai google-genai anthropic httpx aiofiles tqdm json_repair huggingface_hub python-dotenv
```

## Run Command

From workspace root `%USERPROFILE%\Documents\Codex\2026-07-09\qin`:

```powershell
.\work\run_paperbanana.ps1 `
  -MethodFile "C:\path\to\method.md" `
  -Caption "Figure 1: Overview of the proposed framework" `
  -Output "%USERPROFILE%\Documents\Codex\2026-07-09\qin\outputs\figure.png" `
  -AspectRatio "16:9" `
  -Candidates 3 `
  -CriticRounds 0
```

Use `CriticRounds=0` for first runs with ZCHAT. Increase only after verifying
the chosen model is stable and can support the extra refinement calls.

## Minimal OpenAI-Compatible Python Test

Use this only for a low-frequency connectivity check:

```python
from openai import OpenAI
import os

client = OpenAI(
    api_key=os.environ["ZCHAT_API_KEY"],
    base_url="https://api.zchat.tech/v1",
)

response = client.chat.completions.create(
    model="grok-3",
    messages=[
        {"role": "developer", "content": "You are a helpful assistant."},
        {"role": "user", "content": "Reply with exactly: ok"},
    ],
)

print(response.choices[0].message.content)
```

If a model returns `No available accounts`, treat that as provider-side model
availability rather than a local path/config error.
