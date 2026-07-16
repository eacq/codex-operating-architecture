#!/usr/bin/env python3
"""Initialize non-destructive project-local Codex lifecycle files."""

from __future__ import annotations

import argparse
import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path


BEGIN = "<!-- BEGIN MANAGED BLOCK: codex-project-lifecycle -->"
END = "<!-- END MANAGED BLOCK: codex-project-lifecycle -->"
MANAGED = f"""{BEGIN}
## Codex Project Lifecycle

- At every project entry, invoke `$codex-self-evolution` to route the task and check lifecycle state.
- On first use, when `.codex/project/state.json` is absent, invoke `$codex-project-optimization` and initialize the project lifecycle before substantial work.
- Before planning or implementation, read `.codex/project/REQUIREMENTS.md`, `WORKFLOWS.md`, and relevant `EXPERIENCE.md` entries.
- After Git initialization, commit, merge, rebase, tag, release, or a complete verified iteration, invoke `$codex-git-operations` and `$codex-experience-capture`.
- Process `.codex/project/pending-events.jsonl`, then synchronize requirements, workflows, project experience, retrospectives, and lifecycle state.
- Keep project-specific knowledge in this repository. Promote only verified cross-project rules to the global Codex skills.
- Preserve user content outside this managed block and never store credentials or raw private session content.
{END}
"""

TEMPLATES = {
    "REQUIREMENTS.md": """# Project Requirements

> Status: initialized; replace unknowns only with repository or user evidence.

## Purpose and Users

- Purpose: Unknown
- Primary users: Unknown

## Current Scope

- In scope: Unknown
- Out of scope: Unknown

## Functional Requirements

- Unknown

## Quality and Operational Requirements

- Build: Unknown
- Test: Unknown
- Security and privacy: Do not commit secrets.

## Acceptance Criteria

- Unknown

## Constraints and Open Decisions

- Unknown
""",
    "WORKFLOWS.md": """# Project Workflows

## Development

- Prerequisites: Unknown
- Build: Unknown
- Test: Unknown
- Run: Unknown

## Git and Release

- Branch convention: Use repository evidence.
- Commit verification: Review scoped diff and run relevant tests.
- Release: Unknown

## Recovery

- Known rollback path: Unknown
""",
    "EXPERIENCE.md": """# Project Experience

Read this file before related work. Keep evergreen verified lessons near the top and candidates below.

## Verified Lessons

- None yet.

## Candidates

- None yet.
""",
    "RETROSPECTIVES.md": """# Iteration Retrospectives

Append after a complete verified iteration.

## Template

- Date:
- Commit range:
- Scope and requirements changed:
- Workflow changed:
- Validation evidence:
- Wins:
- Misses and root causes:
- Plan deviations and surprises:
- Project lessons promoted:
- Cross-project candidates:
""",
    "pending-events.jsonl": "",
}


def git_head(root: Path) -> str | None:
    result = subprocess.run(["git", "-C", str(root), "rev-parse", "HEAD"], capture_output=True, text=True)
    return result.stdout.strip() if result.returncode == 0 else None


def write_if_missing(path: Path, content: str) -> None:
    if not path.exists():
        path.write_text(content, encoding="utf-8")


def update_agents(path: Path) -> None:
    current = path.read_text(encoding="utf-8") if path.exists() else ""
    if BEGIN in current and END in current:
        start = current.index(BEGIN)
        finish = current.index(END, start) + len(END)
        updated = current[:start] + MANAGED.rstrip() + current[finish:]
    else:
        separator = "\n\n" if current.strip() else ""
        updated = current.rstrip() + separator + MANAGED.rstrip() + "\n"
    path.write_text(updated, encoding="utf-8")


def install_hook(root: Path) -> str:
    hooks = root / ".git" / "hooks"
    if not hooks.is_dir():
        return "not-a-git-repository"
    hook = hooks / "post-commit"
    if hook.exists():
        return "preserved-existing-hook"
    hook.write_text("""#!/bin/sh
event_file=\"$(git rev-parse --show-toplevel)/.codex/project/pending-events.jsonl\"
mkdir -p \"$(dirname \"$event_file\")\"
printf '{\"event\":\"git-post-commit\",\"head\":\"%s\"}\n' \"$(git rev-parse HEAD)\" >> \"$event_file\"
""", encoding="utf-8")
    return "installed"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project-root", required=True, type=Path)
    parser.add_argument("--install-git-hook", action="store_true")
    args = parser.parse_args()
    root = args.project_root.resolve()
    if not root.is_dir():
        parser.error(f"project root does not exist: {root}")

    project_dir = root / ".codex" / "project"
    project_dir.mkdir(parents=True, exist_ok=True)
    for name, content in TEMPLATES.items():
        write_if_missing(project_dir / name, content)
    update_agents(root / "AGENTS.md")

    state_path = project_dir / "state.json"
    previous = json.loads(state_path.read_text(encoding="utf-8")) if state_path.exists() else {}
    now = datetime.now(timezone.utc).isoformat()
    state = {
        "schema_version": 1,
        "initialized_at": previous.get("initialized_at", now),
        "updated_at": now,
        "last_observed_head": git_head(root),
        "last_completed_iteration": previous.get("last_completed_iteration"),
        "pending_sync": True,
    }
    state_path.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")
    hook_status = install_hook(root) if args.install_git_hook else "not-requested"
    print(json.dumps({"project_root": str(root), "project_dir": str(project_dir), "git_hook": hook_status}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
