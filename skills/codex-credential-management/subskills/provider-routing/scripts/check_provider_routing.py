from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys
import urllib.error
import urllib.request
from typing import Any


def normalize_key(value: Any) -> str:
    key = str(value or "").strip().strip('"').strip("'")
    if key.lower().startswith("bearer "):
        key = key[7:].strip()
    return key


def credential_candidates(environment_variable: str) -> list[tuple[str, str]]:
    candidates = [(f"environment:{environment_variable}", normalize_key(os.environ.get(environment_variable)))]
    unique: list[tuple[str, str]] = []
    seen: set[bytes] = set()
    for name, key in candidates:
        if not key:
            continue
        fingerprint = hashlib.sha256(key.encode("utf-8")).digest()
        if fingerprint not in seen:
            seen.add(fingerprint)
            unique.append((name, key))
    return unique[:3]


def check(base_url: str, model: str, api_key: str, timeout: int) -> tuple[int, bool]:
    body = json.dumps(
        {
            "model": model,
            "messages": [
                {"role": "developer", "content": "You are a connectivity checker."},
                {"role": "user", "content": "Reply with exactly: ok"},
            ],
        }
    ).encode("utf-8")
    request = urllib.request.Request(
        base_url.rstrip("/") + "/chat/completions",
        data=body,
        headers={"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            raw = response.read(1_000_001)
            if len(raw) > 1_000_000:
                return response.status, False
            payload = json.loads(raw.decode("utf-8"))
        content = payload.get("choices", [{}])[0].get("message", {}).get("content")
        return response.status, bool(content)
    except urllib.error.HTTPError as exc:
        return exc.code, False


def main() -> int:
    parser = argparse.ArgumentParser(description="Low-frequency, stdlib-only OpenAI-compatible endpoint check.")
    parser.add_argument("--model", required=True, help="Model selected in the private local profile")
    parser.add_argument("--fallback-model", action="append", default=[], help="Documented fallback model; repeat at most twice")
    parser.add_argument("--base-url", required=True, help="OpenAI-compatible base URL from the private local profile")
    parser.add_argument("--api-key-env", required=True, help="Environment-variable name from the private local profile")
    parser.add_argument("--timeout", type=int, default=45)
    args = parser.parse_args()

    models = [args.model, *args.fallback_model][:3]
    credentials = credential_candidates(args.api_key_env)
    if not credentials:
        print("missing_api_key: the selected private environment variable is empty", file=sys.stderr)
        return 2

    observations: list[str] = []
    for credential_name, api_key in credentials:
        for model in models:
            try:
                status, content_present = check(args.base_url, model, api_key, max(5, min(args.timeout, 120)))
            except (OSError, TimeoutError, ValueError, json.JSONDecodeError) as exc:
                observations.append(f"source={credential_name} model={model} error={type(exc).__name__}")
                break
            if status == 200 and content_present:
                print(f"ok model={model} credential_source={credential_name} content_present=true")
                return 0
            observations.append(f"source={credential_name} model={model} http={status}")
            if status in {401, 403}:
                break
            if status not in {500, 502, 503}:
                break

    print("request_failed: " + "; ".join(observations), file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
