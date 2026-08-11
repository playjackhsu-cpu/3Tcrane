#!/usr/bin/env python3
"""Check local Markdown and Obsidian wiki links without network access."""

from __future__ import annotations

import re
import sys
from pathlib import Path
from urllib.parse import unquote


ROOT = Path(__file__).resolve().parents[2]
MARKDOWN_LINK = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")
WIKI_LINK = re.compile(r"\[\[([^\]]]+)\]\]")


def exists_markdown(source: Path, raw_target: str) -> bool:
    target = raw_target.strip().split(maxsplit=1)[0].strip("<>")
    if not target or target.startswith(("#", "http://", "https://", "mailto:")):
        return True
    target = unquote(target.split("#", 1)[0])
    return (source.parent / target).resolve().exists()


def exists_wiki(raw_target: str) -> bool:
    target = raw_target.split("|", 1)[0].split("#", 1)[0].strip()
    if not target:
        return True
    candidate = ROOT / target
    if candidate.suffix:
        return candidate.exists()
    if candidate.with_suffix(".md").exists():
        return True
    matches = list(ROOT.rglob(f"{Path(target).name}.md"))
    return len(matches) == 1


def main() -> int:
    failures: list[str] = []
    for source in sorted(ROOT.rglob("*.md")):
        if ".git" in source.parts or "PrivateResources" in source.parts:
            continue
        text = source.read_text(encoding="utf-8")
        for target in MARKDOWN_LINK.findall(text):
            if not exists_markdown(source, target):
                failures.append(f"{source.relative_to(ROOT)}: missing Markdown target {target}")
        for target in WIKI_LINK.findall(text):
            if not exists_wiki(target):
                failures.append(f"{source.relative_to(ROOT)}: missing wiki target {target}")
    if failures:
        print("\n".join(failures), file=sys.stderr)
        return 1
    print("Markdown and Obsidian local links passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
