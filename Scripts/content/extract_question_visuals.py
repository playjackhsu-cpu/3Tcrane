#!/usr/bin/env python3
"""Extract the governed visual assets used by image-based questions.

The mappings are intentionally explicit so a watermark or unrelated page image
cannot be silently included. Outputs and the updated inventory remain private.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from PIL import Image
from pypdf import PdfReader


PROJECT_ROOT = Path(__file__).resolve().parents[2]
PRIVATE_ROOT = PROJECT_ROOT / "PrivateResources/QuestionBank-Inbox"
DEFAULT_SOURCE_DIR = PRIVATE_ROOT / "source/official"
DEFAULT_OUTPUT_DIR = PRIVATE_ROOT / "visual-evidence/assets"
DEFAULT_MANIFEST = PRIVATE_ROOT / "visual-evidence/manifest.json"
DEFAULT_INVENTORY = PRIVATE_ROOT / "official-question-inventory.json"


@dataclass(frozen=True)
class VisualAsset:
    question_id: str
    source_file: str
    pdf_page: int
    source_image_name: str
    role: str
    option_index: int | None = None


ASSETS = (
    VisualAsset("crane-06100-w02-q205", "061004A13.pdf", 28, "Image71.png", "diagram"),
    VisualAsset("crane-06100-w02-q206", "061004A13.pdf", 28, "Image72.png", "diagram"),
    VisualAsset("crane-06100-w02-q207", "061004A13.pdf", 28, "Image73.jpg", "diagram"),
    VisualAsset("crane-06100-w02-q208", "061004A13.pdf", 28, "Image74.jpg", "diagram"),
    VisualAsset("crane-06100-w02-q209", "061004A13.pdf", 29, "Image77.jpg", "diagram"),
    VisualAsset("crane-90008-w03-q013", "900080A16.pdf", 2, "Image16.jpg", "option", 0),
    VisualAsset("crane-90008-w03-q013", "900080A16.pdf", 2, "Image17.jpg", "option", 1),
    VisualAsset("crane-90008-w03-q013", "900080A16.pdf", 2, "Image18.jpg", "option", 2),
    VisualAsset("crane-90008-w03-q013", "900080A16.pdf", 2, "Image19.jpg", "option", 3),
    VisualAsset("crane-90009-w04-q002", "900090A11.pdf", 2, "Image18.jpg", "option", 0),
    VisualAsset("crane-90009-w04-q002", "900090A11.pdf", 2, "Image19.jpg", "option", 1),
    VisualAsset("crane-90009-w04-q002", "900090A11.pdf", 2, "Image20.jpg", "option", 2),
    VisualAsset("crane-90009-w04-q002", "900090A11.pdf", 2, "Image21.jpg", "option", 3),
    VisualAsset("crane-90009-w04-q069", "900090A11.pdf", 7, "Image32.jpg", "diagram"),
    VisualAsset("crane-90009-w04-q086", "900090A11.pdf", 8, "Image35.jpg", "diagram"),
)

EVIDENCE_PAGES = {
    "crane-06100-w02-q205": "visual-evidence/pages/061004A13-28.png",
    "crane-06100-w02-q206": "visual-evidence/pages/061004A13-28.png",
    "crane-06100-w02-q207": "visual-evidence/pages/061004A13-28.png",
    "crane-06100-w02-q208": "visual-evidence/pages/061004A13-28.png",
    "crane-06100-w02-q209": "visual-evidence/pages/061004A13-29.png",
    "crane-90008-w03-q013": "visual-evidence/pages/900080A16-2.png",
    "crane-90009-w04-q002": "visual-evidence/pages/900090A11-p02-2.png",
    "crane-90009-w04-q069": "visual-evidence/pages/900090A11-7.png",
    "crane-90009-w04-q086": "visual-evidence/pages/900090A11-8.png",
}


def ensure_private(path: Path) -> None:
    private = PRIVATE_ROOT.resolve()
    resolved = path.resolve()
    if resolved != private and private not in resolved.parents:
        raise ValueError(f"Refusing non-private path: {resolved}")


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def output_name(asset: VisualAsset) -> str:
    extension = Path(asset.source_image_name).suffix.lower()
    suffix = (
        f"option-{asset.option_index + 1}"
        if asset.option_index is not None
        else asset.role
    )
    return f"{asset.question_id}-{suffix}{extension}"


def extract_assets(source_dir: Path, output_dir: Path) -> list[dict[str, Any]]:
    readers: dict[str, PdfReader] = {}
    records: list[dict[str, Any]] = []
    output_dir.mkdir(parents=True, exist_ok=True)

    for asset in ASSETS:
        reader = readers.setdefault(
            asset.source_file, PdfReader(str(source_dir / asset.source_file))
        )
        page = reader.pages[asset.pdf_page - 1]
        page_images = {image.name: image for image in page.images}
        if asset.source_image_name not in page_images:
            raise ValueError(
                f"{asset.source_file} page {asset.pdf_page}: "
                f"missing {asset.source_image_name}"
            )
        image = page_images[asset.source_image_name]
        data = image.data
        destination = output_dir / output_name(asset)
        destination.write_bytes(data)
        with Image.open(destination) as decoded:
            width, height = decoded.size
            decoded.verify()
        records.append(
            {
                "questionId": asset.question_id,
                "role": asset.role,
                "optionIndex": asset.option_index,
                "sourceFile": asset.source_file,
                "sourcePdfPage": asset.pdf_page,
                "sourceImageName": asset.source_image_name,
                "outputPath": str(destination.relative_to(PRIVATE_ROOT)),
                "sha256": sha256(data),
                "width": width,
                "height": height,
            }
        )
    return records


def update_inventory(
    inventory_path: Path,
    records: list[dict[str, Any]],
    mark_reviewed: bool,
) -> None:
    inventory = json.loads(inventory_path.read_text(encoding="utf-8"))
    by_id = {question["questionId"]: question for question in inventory["questions"]}
    grouped: dict[str, list[dict[str, Any]]] = {}
    for record in records:
        grouped.setdefault(record["questionId"], []).append(record)

    expected_ids = set(EVIDENCE_PAGES)
    if set(grouped) != expected_ids:
        raise ValueError(
            f"Visual mapping mismatch: extracted={sorted(grouped)}, "
            f"expected={sorted(expected_ids)}"
        )
    for question_id, assets in grouped.items():
        question = by_id[question_id]
        question["visual"]["assets"] = assets
        question["visual"]["evidencePage"] = EVIDENCE_PAGES[question_id]
        question["visual"]["assetReviewStatus"] = (
            "source-page-reviewed-complete"
            if mark_reviewed
            else "extracted-needs-source-page-review"
        )
    inventory["visualAssetExtraction"] = {
        "questionCount": len(grouped),
        "assetCount": len(records),
        "reviewStatus": (
            "source-page-reviewed-complete" if mark_reviewed else "needs-review"
        ),
    }
    inventory_path.write_text(
        json.dumps(inventory, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source-dir", type=Path, default=DEFAULT_SOURCE_DIR)
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--inventory", type=Path, default=DEFAULT_INVENTORY)
    parser.add_argument("--mark-reviewed", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    for path in (args.output_dir, args.manifest, args.inventory):
        ensure_private(path)
    if not args.inventory.is_file():
        print(
            "Build the official question inventory before extracting visuals.",
            file=sys.stderr,
        )
        return 2

    records = extract_assets(args.source_dir, args.output_dir)
    manifest = {
        "schemaVersion": 1,
        "purpose": "private-question-visual-evidence",
        "reviewStatus": (
            "source-page-reviewed-complete" if args.mark_reviewed else "needs-review"
        ),
        "assets": records,
    }
    args.manifest.parent.mkdir(parents=True, exist_ok=True)
    args.manifest.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    update_inventory(args.inventory, records, args.mark_reviewed)
    print(
        json.dumps(
            {
                "questions": len({record["questionId"] for record in records}),
                "assets": len(records),
                "reviewed": args.mark_reviewed,
                "manifest": str(args.manifest),
            },
            ensure_ascii=False,
            indent=2,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
