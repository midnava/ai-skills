#!/usr/bin/env python3
"""Smoke test for the rti instruction pack."""

from pathlib import Path


def main() -> None:
    pack_root = Path(__file__).resolve().parents[1]
    required = (
        pack_root / "agents" / "rti.agent.md",
        pack_root / "instructions" / "rti.instructions.md",
    )
    missing = [str(path.relative_to(pack_root)) for path in required if not path.is_file()]
    if missing:
        raise SystemExit(f"rti test: FAIL (missing: {', '.join(missing)})")
    print("rti test: OK")


if __name__ == "__main__":
    main()
