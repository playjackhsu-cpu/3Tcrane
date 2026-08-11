#!/usr/bin/env python3
"""Render scanned PDF spreads, split book pages, and produce private raw OCR.

This tool deliberately stops at OCR evidence. It never writes to Content/Releases
and it never claims that recognized text, printed answers, or legal references are
correct. A reviewer must compare every field with the source image first.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable

try:
    from PIL import Image, ImageEnhance, ImageFilter, ImageOps
    from pypdf import PdfReader
except ImportError as exc:
    raise SystemExit(
        "Missing PDF/OCR runtime dependencies. Run with the bundled Codex Python "
        "runtime or install Pillow and pypdf in an isolated environment."
    ) from exc


PROJECT_ROOT = Path(__file__).resolve().parents[2]
PRIVATE_ROOT = PROJECT_ROOT / "PrivateResources"
DEFAULT_PDF = PRIVATE_ROOT / "QuestionBank-Inbox" / "source" / "題庫.pdf"
DEFAULT_OUTPUT = PRIVATE_ROOT / "QuestionBank-Inbox" / "ocr"
DEFAULT_PDFTOPPM = Path(
    os.environ.get("THREETCRANE_PDFTOPPM", shutil.which("pdftoppm") or "pdftoppm")
)


def resolve_project_path(value: str | Path) -> Path:
    path = Path(value).expanduser()
    return path.resolve() if path.is_absolute() else (PROJECT_ROOT / path).resolve()


def require_private_output(path: Path) -> None:
    try:
        path.relative_to(PRIVATE_ROOT.resolve())
    except ValueError as exc:
        raise SystemExit(f"OCR output must stay under {PRIVATE_ROOT}") from exc


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def parse_pages(selection: str, page_count: int) -> list[int]:
    if selection.strip().lower() == "all":
        return list(range(1, page_count + 1))

    pages: set[int] = set()
    for token in selection.split(","):
        token = token.strip()
        if not token:
            continue
        if "-" in token:
            start_text, end_text = token.split("-", 1)
            start, end = int(start_text), int(end_text)
            if end < start:
                raise SystemExit(f"Invalid page range: {token}")
            pages.update(range(start, end + 1))
        else:
            pages.add(int(token))

    invalid = sorted(page for page in pages if page < 1 or page > page_count)
    if invalid:
        raise SystemExit(f"PDF page outside 1...{page_count}: {invalid}")
    if not pages:
        raise SystemExit("No PDF pages selected")
    return sorted(pages)


def tool_path(candidate: Path, fallback_name: str) -> str:
    if candidate.is_file():
        return str(candidate)
    fallback = shutil.which(fallback_name)
    if fallback:
        return fallback
    raise SystemExit(f"Required tool not found: {fallback_name}")


def version_line(command: list[str]) -> str:
    result = subprocess.run(command, check=True, capture_output=True, text=True)
    text = (result.stdout or result.stderr).strip()
    return text.splitlines()[0] if text else "unknown"


def render_page(pdf: Path, page: int, dpi: int, pdftoppm: str, target: Path) -> None:
    subprocess.run(
        [
            pdftoppm,
            "-f",
            str(page),
            "-l",
            str(page),
            "-r",
            str(dpi),
            "-png",
            "-singlefile",
            str(pdf),
            str(target.with_suffix("")),
        ],
        check=True,
        capture_output=True,
        text=True,
    )


def split_and_enhance(image: Image.Image) -> Iterable[tuple[str, Image.Image]]:
    """Split the photographed two-page spread using ratios verified on this source."""
    width, height = image.size
    y0, y1 = int(height * 0.015), int(height * 0.90)
    crops = {
        "left": (int(width * 0.125), y0, int(width * 0.585), y1),
        "right": (int(width * 0.57), y0, width, y1),
    }
    for side, box in crops.items():
        page = image.crop(box)
        page = ImageOps.grayscale(page)
        page = ImageOps.autocontrast(page, cutoff=1)
        page = ImageEnhance.Contrast(page).enhance(1.35)
        page = page.filter(ImageFilter.UnsharpMask(radius=1.4, percent=170, threshold=2))
        page = ImageOps.expand(page, border=24, fill="white")
        yield side, page


def tsv_average_confidence(path: Path) -> float | None:
    values: list[float] = []
    with path.open(encoding="utf-8", errors="replace", newline="") as handle:
        for row in csv.DictReader(handle, delimiter="\t"):
            try:
                value = float(row.get("conf", "-1"))
            except ValueError:
                continue
            if value >= 0 and row.get("text", "").strip():
                values.append(value)
    return round(sum(values) / len(values), 2) if values else None


def run_ocr(
    image_path: Path,
    output_base: Path,
    tesseract: str,
    languages: str,
    psm: int,
) -> float | None:
    subprocess.run(
        [
            tesseract,
            str(image_path),
            str(output_base),
            "-l",
            languages,
            "--psm",
            str(psm),
            "txt",
            "tsv",
        ],
        check=True,
        capture_output=True,
        text=True,
    )
    return tsv_average_confidence(output_base.with_suffix(".tsv"))


def relative_to_output(path: Path, output: Path) -> str:
    return path.relative_to(output).as_posix()


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Create private OCR evidence from the scanned question-bank PDF."
    )
    parser.add_argument("--pdf", default=str(DEFAULT_PDF))
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--pages", default="all", help="Examples: all, 1-3,20")
    parser.add_argument("--dpi", type=int, default=300)
    parser.add_argument("--languages", default="chi_tra+eng")
    parser.add_argument("--psm", type=int, default=3)
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args()

    pdf = resolve_project_path(args.pdf)
    output = resolve_project_path(args.output)
    require_private_output(output)
    if not pdf.is_file():
        raise SystemExit(f"Source PDF not found: {pdf}")
    if args.dpi < 150 or args.dpi > 600:
        raise SystemExit("DPI must be within 150...600")
    if args.psm < 0 or args.psm > 13:
        raise SystemExit("Tesseract PSM must be within 0...13")

    reader = PdfReader(str(pdf))
    page_count = len(reader.pages)
    selected_pages = parse_pages(args.pages, page_count)
    pdftoppm = tool_path(DEFAULT_PDFTOPPM, "pdftoppm")
    tesseract = tool_path(Path(shutil.which("tesseract") or ""), "tesseract")

    processed_dir = output / "processed-pages"
    raw_text_dir = output / "raw-text"
    tsv_dir = output / "tsv"
    for directory in (processed_dir, raw_text_dir, tsv_dir):
        directory.mkdir(parents=True, exist_ok=True)

    page_records: list[dict[str, object]] = []
    with tempfile.TemporaryDirectory(prefix="3tcrane-ocr-") as temporary:
        temp_dir = Path(temporary)
        for pdf_page in selected_pages:
            rendered = temp_dir / f"pdf-{pdf_page:03d}.png"
            render_page(pdf, pdf_page, args.dpi, pdftoppm, rendered)
            with Image.open(rendered) as spread:
                for side, image in split_and_enhance(spread):
                    stem = f"pdf-{pdf_page:03d}-{side}"
                    processed = processed_dir / f"{stem}.png"
                    text_path = raw_text_dir / f"{stem}.txt"
                    tsv_path = tsv_dir / f"{stem}.tsv"
                    if args.force or not (processed.exists() and text_path.exists() and tsv_path.exists()):
                        image.save(processed, format="PNG", optimize=True)
                        with tempfile.TemporaryDirectory(prefix="3tcrane-tesseract-") as ocr_temp:
                            ocr_base = Path(ocr_temp) / stem
                            average_confidence = run_ocr(
                                processed, ocr_base, tesseract, args.languages, args.psm
                            )
                            shutil.copy2(ocr_base.with_suffix(".txt"), text_path)
                            shutil.copy2(ocr_base.with_suffix(".tsv"), tsv_path)
                    else:
                        average_confidence = tsv_average_confidence(tsv_path)

                    page_records.append(
                        {
                            "pdfPage": pdf_page,
                            "spreadSide": side,
                            "processedImage": relative_to_output(processed, output),
                            "rawText": relative_to_output(text_path, output),
                            "tsv": relative_to_output(tsv_path, output),
                            "averageWordConfidence": average_confidence,
                            "status": "ocr-raw-needs-line-review",
                        }
                    )
            print(f"OCR candidate complete: PDF page {pdf_page}/{page_count}", flush=True)

    manifest = {
        "schemaVersion": 1,
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "status": "private-ocr-evidence-only",
        "source": {
            "fileName": pdf.name,
            "sha256": sha256(pdf),
            "byteSize": pdf.stat().st_size,
            "pdfPageCount": page_count,
            "hasTextLayer": False,
        },
        "processing": {
            "dpi": args.dpi,
            "languages": args.languages,
            "tesseractPsm": args.psm,
            "splitRatios": {
                "vertical": [0.015, 0.90],
                "left": [0.125, 0.585],
                "right": [0.57, 1.0],
            },
            "pdftoppm": version_line([pdftoppm, "-v"]),
            "tesseract": version_line([tesseract, "--version"]),
        },
        "pages": page_records,
        "promotionPolicy": "Never publish before source, answer, explanation, rights, and public-source review.",
    }
    (output / "ocr-manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"Wrote private OCR manifest for {len(page_records)} book-page candidates.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
