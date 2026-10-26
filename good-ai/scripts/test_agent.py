#!/usr/bin/env python3
"""Smoke test for the good-ai instruction pack."""

from pathlib import Path


def main() -> None:
    pack_root = Path(__file__).resolve().parents[1]
    required = (
        pack_root / "agents" / "test.agent.md",
        pack_root / "instructions" / "test.instructions.md",
    )
    missing = [str(path.relative_to(pack_root)) for path in required if not path.is_file()]
    if missing:
        raise SystemExit(f"good-ai test: FAIL (missing: {', '.join(missing)})")
    print("good-ai test: OK")


if __name__ == "__main__":
    main()
