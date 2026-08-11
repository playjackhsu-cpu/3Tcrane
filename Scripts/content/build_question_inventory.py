#!/usr/bin/env python3
"""Build the private, non-release question inventory from official PDFs.

The output deliberately stays below PrivateResources/. It is an intake and
review ledger, not an App release bank. Printed answers remain reference
evidence until source, explanation, accuracy, and rights reviews pass.
"""

from __future__ import annotations

import argparse
import bisect
import hashlib
import json
import re
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable

from pypdf import PdfReader


PROJECT_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SOURCE_DIR = (
    PROJECT_ROOT / "PrivateResources/QuestionBank-Inbox/source/official"
)
DEFAULT_OUTPUT = (
    PROJECT_ROOT
    / "PrivateResources/QuestionBank-Inbox/official-question-inventory.json"
)
DEFAULT_REPORT = (
    PROJECT_ROOT
    / "PrivateResources/QuestionBank-Inbox/reports/official-question-inventory.md"
)
DEFAULT_SCAN_VISION_DIR = (
    PROJECT_ROOT / "PrivateResources/QuestionBank-Inbox/ocr/raw-text-vision"
)
DEFAULT_SCAN_OVERRIDES = (
    PROJECT_ROOT / "PrivateResources/QuestionBank-Inbox/scan-manual-overrides.json"
)

QUESTION_RE = re.compile(
    r"(?m)^\s*((?:\d\s*){1,3})\s*\.\s*\(\s*([1-4])\s*\)"
)
WORK_ITEM_RE = re.compile(
    r"工作項目\s*(\d{2})\s*[：:]\s*([^\n]+)"
)
FOOTER_RE = re.compile(r"\s*Page\s+\d+\s+of\s+\d+\s*", re.IGNORECASE)
SECTION_HEADER_PREFIX_RE = re.compile(
    r"\s*\n\s*\d{5}\s+[^\n]*?\s+(?:單一(?:級)?|甲級|乙級|丙級)\s*$"
)
SPACE_RE = re.compile(r"\s+")
CJK_SPACE_RE = re.compile(r"(?<=[\u3400-\u9fff]) (?=[\u3400-\u9fff])")
OPTION_SYMBOLS = "①②③④"
SCAN_QUESTION_RE = re.compile(
    r"(?m)^\s*[•·]?\s*(\d{1,3})\s*[.．、:]?\s*[（(]\s*([1-4])\s*[）)]"
)
VISUAL_KEYWORDS = (
    "下圖",
    "圖示",
    "依圖",
    "如圖",
    "圖中",
    "何者為環保標章",
    "何者為節能標章",
)


@dataclass(frozen=True)
class SourceSpec:
    file_name: str
    source_url: str
    subject_code: str
    subject_name: str
    work_items: tuple[tuple[str, str, int], ...]
    scan_printed_page_offset: int


SOURCE_SPECS = (
    SourceSpec(
        file_name="061004A13.pdf",
        source_url=(
            "https://owinform.wdasec.gov.tw/owInform/DLowFile/"
            "061004A13.pdf"
        ),
        subject_code="06100",
        subject_name="固定式起重機操作",
        work_items=(
            ("01", "作業之準備與檢點", 267),
            ("02", "吊掛、操作與指揮", 224),
            ("03", "安全措施", 76),
            ("04", "安全衛生法規", 33),
        ),
        scan_printed_page_offset=0,
    ),
    SourceSpec(
        file_name="900060A18.pdf",
        source_url=(
            "https://owinform.wdasec.gov.tw/owInform/DLowFile/"
            "900060A18.pdf"
        ),
        subject_code="90006",
        subject_name="職業安全衛生共同科目",
        work_items=(("01", "職業安全衛生", 100),),
        scan_printed_page_offset=36,
    ),
    SourceSpec(
        file_name="900070A17.pdf",
        source_url=(
            "https://owinform.wdasec.gov.tw/owInform/DLowFile/"
            "900070A17.pdf"
        ),
        subject_code="90007",
        subject_name="工作倫理與職業道德共同科目",
        work_items=(("01", "工作倫理與職業道德", 100),),
        scan_printed_page_offset=43,
    ),
    SourceSpec(
        file_name="900080A16.pdf",
        source_url=(
            "https://owinform.wdasec.gov.tw/owInform/DLowFile/"
            "900080A16.pdf"
        ),
        subject_code="90008",
        subject_name="環境保護共同科目",
        work_items=(("03", "環境保護", 100),),
        scan_printed_page_offset=54,
    ),
    SourceSpec(
        file_name="900090A11.pdf",
        source_url=(
            "https://owinform.wdasec.gov.tw/owInform/DLowFile/"
            "900090A11.pdf"
        ),
        subject_code="90009",
        subject_name="節能減碳共同科目",
        work_items=(("04", "節能減碳", 100),),
        scan_printed_page_offset=62,
    ),
)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def normalize_text(value: str) -> str:
    value = value.replace("\u3000", " ").replace("\x00", "")
    value = SPACE_RE.sub(" ", value).strip()
    return CJK_SPACE_RE.sub("", value)


def clean_tail(value: str) -> str:
    value = FOOTER_RE.sub("", value)
    value = SECTION_HEADER_PREFIX_RE.sub("", value)
    return value.strip()


def parse_header(text: str) -> dict[str, str]:
    fields: dict[str, str] = {}
    patterns = {
        "fileName": r"檔案名稱\s*[:：]\s*([^\s]+)",
        "version": r"版次編號\s*[:：]\s*([^\s]+)",
        "announcementDate": r"公告日期\s*[:：]\s*([^\n]+)",
        "applicableFrom": r"自\s*([^\n]+?報檢者適用)",
    }
    for key, pattern in patterns.items():
        match = re.search(pattern, text)
        fields[key] = normalize_text(match.group(1)) if match else ""
    return fields


def split_prompt_options(body: str) -> tuple[str, list[str], list[str]]:
    positions: list[tuple[int, str]] = []
    cursor = 0
    missing_symbols: list[str] = []
    for symbol in OPTION_SYMBOLS:
        position = body.find(symbol, cursor)
        if position < 0:
            missing_symbols.append(symbol)
            continue
        positions.append((position, symbol))
        cursor = position + 1

    if len(positions) != 4:
        return normalize_text(body), ["", "", "", ""], missing_symbols

    prompt = normalize_text(body[: positions[0][0]])
    options: list[str] = []
    for index, (position, _symbol) in enumerate(positions):
        start = position + 1
        end = positions[index + 1][0] if index < 3 else len(body)
        option = normalize_text(body[start:end])
        option = re.sub(r"\s*[。．]\s*$", "", option).strip()
        options.append(option)
    return prompt, options, missing_symbols


def scan_locator(printed_page: int) -> dict[str, Any]:
    if printed_page % 2:
        pdf_page = (printed_page + 5) // 2
        side = "left"
    else:
        pdf_page = (printed_page + 4) // 2
        side = "right"
    return {
        "fileName": "題庫.pdf",
        "pdfPage": pdf_page,
        "spreadSide": side,
        "printedPage": printed_page,
    }


def expected_work_item(spec: SourceSpec, code: str) -> tuple[str, int]:
    for item_code, name, count in spec.work_items:
        if item_code == code:
            return name, count
    raise ValueError(
        f"{spec.file_name}: unexpected work item {code}; "
        f"expected {[item[0] for item in spec.work_items]}"
    )


def question_id(subject_code: str, work_item: str, number: int) -> str:
    return f"crane-{subject_code}-w{work_item}-q{number:03d}"


def public_code(subject_code: str, work_item: str, number: int) -> str:
    return f"CR-{subject_code}-W{work_item}-{number:03d}"


def parse_source(spec: SourceSpec, source_dir: Path) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    path = source_dir / spec.file_name
    if not path.is_file():
        raise FileNotFoundError(f"Missing private source: {path}")

    reader = PdfReader(str(path))
    page_texts = [page.extract_text() or "" for page in reader.pages]
    header = parse_header(page_texts[0])
    source_sha = sha256(path)
    source_record: dict[str, Any] = {
        "fileName": spec.file_name,
        "sha256": source_sha,
        "sizeBytes": path.stat().st_size,
        "pdfPages": len(reader.pages),
        "textLayer": True,
        "officialUrl": spec.source_url,
        **header,
    }

    questions: list[dict[str, Any]] = []
    current_work_item = ""
    work_item_names = {item[0]: item[1] for item in spec.work_items}

    page_offsets: list[int] = []
    combined_parts: list[str] = []
    combined_length = 0
    for page_text in page_texts:
        page_offsets.append(combined_length)
        combined_parts.append(page_text)
        combined_length += len(page_text) + 1
    combined_text = "\n".join(combined_parts)

    section_matches = list(WORK_ITEM_RE.finditer(combined_text))
    question_matches = list(QUESTION_RE.finditer(combined_text))
    events: list[tuple[int, str, re.Match[str]]] = [
        (match.start(), "section", match) for match in section_matches
    ] + [(match.start(), "question", match) for match in question_matches]
    events.sort(key=lambda event: (event[0], 0 if event[1] == "section" else 1))

    for event_index, (_start, event_type, match) in enumerate(events):
        page_position = match.start(1) if event_type == "question" else match.start()
        pdf_page = bisect.bisect_right(page_offsets, page_position)
        if event_type == "section":
            current_work_item = match.group(1)
            expected_work_item(spec, current_work_item)
            continue

        if not current_work_item:
            if len(spec.work_items) == 1:
                current_work_item = spec.work_items[0][0]
            else:
                raise ValueError(
                    f"{spec.file_name} page {pdf_page}: question before work item"
                )

        number = int(re.sub(r"\s+", "", match.group(1)))
        printed_answer = int(match.group(2))
        next_start = (
            events[event_index + 1][0]
            if event_index + 1 < len(events)
            else len(combined_text)
        )
        body = clean_tail(combined_text[match.end() : next_start])
        prompt, options, missing_symbols = split_prompt_options(body)
        officially_deleted = "本題刪題" in prompt[:20]
        visual_reasons: list[str] = []
        if any(keyword in prompt for keyword in VISUAL_KEYWORDS):
            visual_reasons.append("visual-keyword")
        if missing_symbols:
            visual_reasons.append("missing-option-symbols")
        if any(not option for option in options):
            visual_reasons.append("empty-option-text")

        work_item_name, _expected_count = expected_work_item(
            spec, current_work_item
        )
        printed_page = pdf_page + spec.scan_printed_page_offset
        questions.append(
                {
                    "questionId": question_id(
                        spec.subject_code, current_work_item, number
                    ),
                    "publicCode": public_code(
                        spec.subject_code, current_work_item, number
                    ),
                    "subjectCode": spec.subject_code,
                    "subjectName": spec.subject_name,
                    "workItemCode": current_work_item,
                    "workItemName": work_item_names[current_work_item],
                    "sourceLocator": {
                        "officialFile": spec.file_name,
                        "officialSha256": source_sha,
                        "officialPdfPage": pdf_page,
                        "officialPrintedPage": max(0, pdf_page - 1),
                        "questionNumber": number,
                        "scanCrossReference": scan_locator(printed_page),
                    },
                    "transcription": {
                        "prompt": prompt,
                        "options": options,
                        "printedAnswerNumber": printed_answer,
                        "printedAnswerIndex": printed_answer - 1,
                        "rawExtractedText": normalize_text(body),
                        "sourceTextStatus": "official-text-layer-extracted",
                        "optionParseStatus": (
                            "complete-text"
                            if not missing_symbols and all(options)
                            else "visual-or-needs-review"
                        ),
                        "scanLineReviewStatus": "pending",
                    },
                    "visual": {
                        "required": bool(visual_reasons),
                        "reasons": visual_reasons,
                        "evidenceCrop": "",
                        "assetReviewStatus": (
                            "needs-crop-review" if visual_reasons else "not-required"
                        ),
                    },
                    "verification": {
                        "currentAnswerIndex": None,
                        "answerStatus": (
                            "officially-deleted-reference-only"
                            if officially_deleted
                            else "printed-reference-only"
                        ),
                        "answerConflict": "",
                        "publicSources": [],
                        "publicSourceCheckedAt": "",
                    },
                    "editorial": {
                        "explanation": "",
                        "alternativeAnswer": "",
                        "choiceRationales": ["", "", "", ""],
                    },
                    "rightsStatus": "needs-review",
                    "officialDisposition": (
                        "deleted-retained-for-completeness"
                        if officially_deleted
                        else "active-reference"
                    ),
                    "reviewStatus": (
                        "deprecated-retained-for-completeness"
                        if officially_deleted
                        else "transcribed-from-official-text-layer"
                    ),
                    "releaseEligible": False,
                    "reviewNotes": "",
                }
            )

    return source_record, questions


def validate_inventory(questions: Iterable[dict[str, Any]]) -> list[str]:
    question_list = list(questions)
    errors: list[str] = []
    identifiers = [question["questionId"] for question in question_list]
    duplicates = sorted(
        identifier for identifier, count in Counter(identifiers).items() if count > 1
    )
    if duplicates:
        errors.append(f"duplicate questionId values: {duplicates}")

    grouped: defaultdict[tuple[str, str], list[int]] = defaultdict(list)
    for question in question_list:
        key = (question["subjectCode"], question["workItemCode"])
        grouped[key].append(question["sourceLocator"]["questionNumber"])
        answer = question["transcription"]["printedAnswerIndex"]
        if answer not in range(4):
            errors.append(f"{question['questionId']}: invalid printed answer {answer}")
        if len(question["transcription"]["options"]) != 4:
            errors.append(f"{question['questionId']}: option array is not length 4")

    for spec in SOURCE_SPECS:
        for work_item, _name, expected_count in spec.work_items:
            key = (spec.subject_code, work_item)
            actual_numbers = sorted(grouped.get(key, []))
            expected_numbers = list(range(1, expected_count + 1))
            if actual_numbers != expected_numbers:
                missing = sorted(set(expected_numbers) - set(actual_numbers))
                extra = sorted(set(actual_numbers) - set(expected_numbers))
                errors.append(
                    f"{key}: expected 1..{expected_count}, got {len(actual_numbers)}; "
                    f"missing={missing}, extra={extra}"
                )

    if len(question_list) != 1000:
        errors.append(f"expected 1000 total questions, got {len(question_list)}")
    return errors


def apply_scan_answer_cross_check(
    questions: list[dict[str, Any]], vision_dir: Path
) -> dict[str, int]:
    grouped: defaultdict[str, list[dict[str, Any]]] = defaultdict(list)
    for question in questions:
        locator = question["sourceLocator"]["scanCrossReference"]
        stem = f"pdf-{locator['pdfPage']:03d}-{locator['spreadSide']}"
        grouped[stem].append(question)

    summary = Counter()
    for stem, page_questions in grouped.items():
        text_path = vision_dir / f"{stem}.txt"
        if not text_path.is_file():
            for question in page_questions:
                question["transcription"]["scanAnswerMarkerStatus"] = (
                    "vision-page-missing"
                )
                question["transcription"]["scanPrintedAnswerNumber"] = None
                summary["vision-page-missing"] += 1
            continue

        text = text_path.read_text(encoding="utf-8")
        detected: defaultdict[int, list[int]] = defaultdict(list)
        for match in SCAN_QUESTION_RE.finditer(text):
            detected[int(match.group(1))].append(int(match.group(2)))

        expected_by_number: defaultdict[int, list[dict[str, Any]]] = defaultdict(list)
        for question in page_questions:
            expected_by_number[question["sourceLocator"]["questionNumber"]].append(
                question
            )

        for number, number_questions in expected_by_number.items():
            candidates = detected.get(number, [])
            for question in number_questions:
                official_answer = question["transcription"]["printedAnswerNumber"]
                if len(number_questions) > 1 or len(candidates) > 1:
                    status = "ambiguous-marker"
                    scan_answer = None
                elif not candidates:
                    status = "answer-marker-not-detected"
                    scan_answer = None
                else:
                    scan_answer = candidates[0]
                    status = (
                        "answer-marker-matches"
                        if scan_answer == official_answer
                        else "answer-marker-conflict"
                    )
                question["transcription"]["scanAnswerMarkerStatus"] = status
                question["transcription"]["scanPrintedAnswerNumber"] = scan_answer
                summary[status] += 1
    return dict(summary)


def apply_scan_manual_overrides(
    questions: list[dict[str, Any]], overrides_path: Path
) -> int:
    if not overrides_path.is_file():
        return 0
    payload = json.loads(overrides_path.read_text(encoding="utf-8"))
    by_id = {question["questionId"]: question for question in questions}
    applied = 0
    for item in payload.get("items", []):
        question_id = item["questionId"]
        if question_id not in by_id:
            raise ValueError(f"Unknown scan override questionId: {question_id}")
        question = by_id[question_id]
        scan_answer = int(item["scanPrintedAnswerNumber"])
        official_answer = question["transcription"]["printedAnswerNumber"]
        status = (
            "manual-scan-image-matches"
            if scan_answer == official_answer
            else "manual-scan-image-conflict"
        )
        question["transcription"]["scanPrintedAnswerNumber"] = scan_answer
        question["transcription"]["scanAnswerMarkerStatus"] = status
        question["transcription"]["scanManualReview"] = {
            "status": item.get("status", "source-image-reviewed"),
            "reviewedAt": item.get("reviewedAt", payload.get("reviewedAt", "")),
            "note": item.get("note", ""),
        }
        applied += 1
    return applied


def build_report(inventory: dict[str, Any], errors: list[str]) -> str:
    questions = inventory["questions"]
    counts = Counter(
        (question["subjectCode"], question["workItemCode"])
        for question in questions
    )
    visual = [question for question in questions if question["visual"]["required"]]
    option_review = [
        question
        for question in questions
        if question["transcription"]["optionParseStatus"] != "complete-text"
    ]
    officially_deleted = [
        question
        for question in questions
        if question["officialDisposition"] == "deleted-retained-for-completeness"
    ]
    lines = [
        "# Official question inventory report",
        "",
        f"- Generated: `{inventory['generatedAt']}`",
        f"- Total questions: **{len(questions)}**",
        f"- Visual/crop review: **{len(visual)}**",
        f"- Option parse review: **{len(option_review)}**",
        f"- Officially deleted, retained for completeness: **{len(officially_deleted)}**",
        f"- Structural validation errors: **{len(errors)}**",
        (
            "- Scan answer-marker comparison: `"
            + json.dumps(
                inventory["scanAnswerCrossCheck"], ensure_ascii=False, sort_keys=True
            )
            + "`"
        ),
        "",
        "## Coverage",
        "",
        "| Subject | Work item | Count |",
        "| --- | --- | ---: |",
    ]
    for (subject, work_item), count in sorted(counts.items()):
        lines.append(f"| {subject} | {work_item} | {count} |")
    lines.extend(["", "## Visual/crop review IDs", ""])
    if visual:
        lines.extend(f"- `{question['questionId']}`" for question in visual)
    else:
        lines.append("- None")
    lines.extend(["", "## Structural validation", ""])
    if errors:
        lines.extend(f"- {error}" for error in errors)
    else:
        lines.append("- PASS: IDs, answer indexes, section sequences, and 1,000 total.")
    lines.append("")
    return "\n".join(lines)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source-dir", type=Path, default=DEFAULT_SOURCE_DIR)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--report", type=Path, default=DEFAULT_REPORT)
    parser.add_argument(
        "--scan-vision-dir", type=Path, default=DEFAULT_SCAN_VISION_DIR
    )
    parser.add_argument(
        "--scan-overrides", type=Path, default=DEFAULT_SCAN_OVERRIDES
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    for path in (args.output, args.report):
        resolved = path.resolve()
        private_root = (PROJECT_ROOT / "PrivateResources").resolve()
        if private_root not in resolved.parents:
            print(f"Refusing non-private output: {resolved}", file=sys.stderr)
            return 2

    sources: list[dict[str, Any]] = []
    questions: list[dict[str, Any]] = []
    for spec in SOURCE_SPECS:
        source, source_questions = parse_source(spec, args.source_dir)
        sources.append(source)
        questions.extend(source_questions)

    apply_scan_answer_cross_check(questions, args.scan_vision_dir)
    manual_scan_reviews = apply_scan_manual_overrides(
        questions, args.scan_overrides
    )
    scan_answer_cross_check = dict(
        Counter(
            question["transcription"]["scanAnswerMarkerStatus"]
            for question in questions
        )
    )
    errors = validate_inventory(questions)
    inventory = {
        "schemaVersion": 2,
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "purpose": "private-intake-review-only",
        "officialSiteDisclaimer": (
            "學科參考資料僅供參考，不得做為測試試題或答案之依據"
        ),
        "releaseEligible": False,
        "sourceCount": len(sources),
        "questionCount": len(questions),
        "sources": sources,
        "questions": questions,
        "scanAnswerCrossCheck": scan_answer_cross_check,
        "manualScanReviews": manual_scan_reviews,
        "structuralValidation": {
            "status": "pass" if not errors else "fail",
            "errors": errors,
        },
    }

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(inventory, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    args.report.write_text(build_report(inventory, errors), encoding="utf-8")
    print(
        json.dumps(
            {
                "output": str(args.output),
                "report": str(args.report),
                "questions": len(questions),
                "sources": len(sources),
                "visualReview": sum(
                    1 for question in questions if question["visual"]["required"]
                ),
                "validation": "pass" if not errors else "fail",
                "errors": errors,
            },
            ensure_ascii=False,
            indent=2,
        )
    )
    return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
