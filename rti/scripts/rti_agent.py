#!/usr/bin/env python3
"""Tiny smoke test for the shared AI agent repository."""

from pathlib import Path


def main() -> None:
    repo_root = Path(__file__).resolve().parents[1]
    agent = repo_root / ".github" / "agents" / "test.agent.md"
    instructions = repo_root / ".github" / "instructions" / "test.instructions.md"

    missing = [str(path.relative_to(repo_root)) for path in (agent, instructions) if not path.is_file()]
    if missing:
        raise SystemExit(f"ai-skills test: FAIL (missing: {', '.join(missing)})")

    print("ai-skills test: OK")


if __name__ == "__main__":
    main()
