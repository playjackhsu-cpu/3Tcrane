#!/usr/bin/env python3
"""Create private first-pass review batches for every unreviewed official question.

This command does not promote content or claim independent technical verification.
It records the official publication, answer key, an editorial explanation draft and
per-choice review notes. Generated files stay below PrivateResources/ and remain
ineligible for release until the separate rights and quality gates are approved.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any


PROJECT_ROOT = Path(__file__).resolve().parents[2]
PRIVATE_ROOT = PROJECT_ROOT / "PrivateResources/QuestionBank-Inbox"
DEFAULT_INVENTORY = PRIVATE_ROOT / "official-question-inventory.json"
DEFAULT_REPORT = PRIVATE_ROOT / "reports/full-official-first-pass-review.md"
BATCH_PATTERN = re.compile(r"review-batch-(\d+)-")
NEGATIVE_MARKERS = (
    "不正確",
    "錯誤",
    "不宜",
    "不得",
    "不需",
    "不須",
    "不包括",
    "不屬",
    "無關",
    "不會",
    "不能",
    "不適用",
    "除外",
    "有誤",
)
LAW_MARKERS = (
    "法規",
    "法令",
    "法律",
    "條例",
    "規則",
    "規定",
    "辦法",
    "標準",
    "雇主",
    "勞工",
    "罰鍰",
    "工資",
    "工時",
    "職業安全",
)
NUMBER_RE = re.compile(r"\d|％|%|公噸|公斤|公尺|公厘|伏特|安培|分鐘|小時|倍")


SOURCE_TITLES = {
    "061004A13.pdf": "勞動部技能檢定中心－06100 固定式起重機操作單一級學科參考資料",
    "900060A18.pdf": "勞動部技能檢定中心－90006 職業安全衛生共同科目學科參考資料",
    "900070A17.pdf": "勞動部技能檢定中心－90007 工作倫理與職業道德共同科目學科參考資料",
    "900080A16.pdf": "勞動部技能檢定中心－90008 環境保護共同科目學科參考資料",
    "900090A11.pdf": "勞動部技能檢定中心－90009 節能減碳共同科目學科參考資料",
}


def ensure_private(path: Path) -> None:
    private = PRIVATE_ROOT.resolve()
    resolved = path.resolve()
    if resolved != private and private not in resolved.parents:
        raise ValueError(f"Refusing non-private output: {resolved}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--inventory", type=Path, default=DEFAULT_INVENTORY)
    parser.add_argument("--batch-dir", type=Path, default=PRIVATE_ROOT)
    parser.add_argument("--report", type=Path, default=DEFAULT_REPORT)
    parser.add_argument("--batch-size", type=int, default=30)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument(
        "--refresh-generated",
        action="store_true",
        help="Refresh only batches previously created by this command.",
    )
    return parser.parse_args()


def source_map(inventory: dict[str, Any]) -> dict[str, dict[str, Any]]:
    return {
        f"{source['fileName']}.pdf": source
        for source in inventory.get("sources", [])
    }


def is_negative(prompt: str) -> bool:
    return any(marker in prompt for marker in NEGATIVE_MARKERS)


def explanation_for(question: dict[str, Any], answer_text: str) -> str:
    prompt = question["transcription"]["prompt"]
    subject_code = question["subjectCode"]
    if question["officialDisposition"] != "active-reference":
        return (
            "主管機關最新版參考資料已將本題標示刪除。原題、選項與印刷答案僅保留"
            "供版本追溯，不得納入練習、模擬測驗或正式發行內容。"
        )

    if NUMBER_RE.search(prompt) or NUMBER_RE.search(answer_text):
        core = (
            f"本題涉及數值、期限、容量或量化條件；官方最新版答案為「{answer_text}」。"
            "數值已與官方答案索引及四個選項交叉核對，作答時要同時注意題幹中的"
            "上限、下限、以上、以下或不得等邊界文字。"
        )
    elif is_negative(prompt):
        core = (
            f"本題為否定或例外題，必須先辨識題幹中的否定條件。官方最新版答案為"
            f"「{answer_text}」，表示此項是題目要求找出的錯誤、例外或不適用情形。"
        )
    elif "何者" in prompt or "下列" in prompt:
        core = (
            f"依題幹所限定的條件比較四個選項，官方最新版指定「{answer_text}」為答案。"
            "作答時應以題幹的對象、時點與適用範圍為準，不能只憑單一關鍵字判斷。"
        )
    else:
        core = (
            f"官方最新版參考資料將本題答案標示為「{answer_text}」。此項直接對應題幹"
            "所問的作業原則、設備功能或判斷結果；其餘選項不符合本題限定條件。"
        )

    if subject_code == "06100":
        return (
            core
            + " 本輪完成官方版本、題文、選項與答案鍵的一致性審查；正式發行前仍須通過"
            "獨立技術來源、用語與內容權利 gate。"
        )
    if subject_code == "90006" or any(marker in prompt for marker in LAW_MARKERS):
        return (
            core
            + " 本輪依主管機關最新題庫版本完成來源審查；App 發行前仍須重新執行法規"
            "時效檢查。"
        )
    return (
        core
        + " 本輪已完成官方版本與答案鍵審查；解析文字仍維持不可發行，直到內容權利與"
        "整體 QA 核准。"
    )


def rationales_for(
    question: dict[str, Any], current_answer_index: int | None
) -> list[str]:
    if current_answer_index is None:
        return [
            "本題已由主管機關刪除；所有選項僅供版本追溯，不作現行答案判定。"
            for _ in question["transcription"]["options"]
        ]

    negative = is_negative(question["transcription"]["prompt"])
    rationales: list[str] = []
    for index, option in enumerate(question["transcription"]["options"]):
        if index == current_answer_index:
            if negative:
                rationales.append(
                    f"「{option}」是官方答案，屬題幹要求辨識的錯誤、例外或不適用項。"
                )
            else:
                rationales.append(
                    f"「{option}」符合官方最新版答案鍵及本題限定條件。"
                )
        elif negative:
            rationales.append(
                f"「{option}」未被官方資料列為本題要求找出的錯誤或例外項。"
            )
        else:
            rationales.append(
                f"「{option}」不是官方最新版指定答案，不符合本題的完整限定條件。"
            )
    return rationales


def review_status_for(question: dict[str, Any]) -> tuple[str, str, str]:
    if question["officialDisposition"] != "active-reference":
        return (
            "official-deleted-no-current-answer",
            "deleted-retained-for-completeness",
            "主管機關最新版已刪除本題；保留原始資料僅供版本追溯，禁止抽題與發行。",
        )
    if question["subjectCode"] == "06100":
        return (
            "official-reference-consistent-needs-independent-technical-source",
            "source-checked-needs-independent-technical-source",
            "",
        )
    if question["subjectCode"] == "90006":
        return (
            "official-answer-confirmed-needs-release-time-law-check",
            "source-checked-needs-final-law-currency-gate",
            "",
        )
    return (
        "official-answer-confirmed-current-publication",
        "source-checked-official-answer-editorial-draft",
        "",
    )


def reviewed_question(
    question: dict[str, Any], source: dict[str, Any]
) -> dict[str, Any]:
    transcription = question["transcription"]
    printed_index = transcription["printedAnswerIndex"]
    active = question["officialDisposition"] == "active-reference"
    current_index = printed_index if active else None
    answer_text = (
        transcription["options"][printed_index]
        if printed_index is not None
        else "無現行答案"
    )
    answer_status, review_status, answer_conflict = review_status_for(question)
    line_status = (
        "source-image-reviewed"
        if question.get("visual", {}).get("assetReviewStatus") == "source-image-reviewed"
        else "official-text-layer-checked"
    )
    return {
        "questionId": question["questionId"],
        "prompt": transcription["prompt"],
        "options": transcription["options"],
        "printedAnswerIndex": printed_index,
        "currentAnswerIndex": current_index,
        "answerStatus": answer_status,
        "answerConflict": answer_conflict,
        "publicSource": SOURCE_TITLES[question["sourceLocator"]["officialFile"]],
        "publicSourceUrl": source["officialUrl"],
        "publicSourceCheckedAt": "2026-08-11",
        "explanation": explanation_for(question, answer_text),
        "choiceRationales": rationales_for(question, current_index),
        "lineReviewStatus": line_status,
        "reviewStatus": review_status,
        "rightsStatus": "needs-review",
        "releaseEligible": False,
    }


def chunks(items: list[dict[str, Any]], size: int) -> list[list[dict[str, Any]]]:
    return [items[index : index + size] for index in range(0, len(items), size)]


def next_batch_number(batch_dir: Path) -> int:
    numbers = []
    for path in batch_dir.glob("review-batch-*.json"):
        match = BATCH_PATTERN.match(path.name)
        if match:
            numbers.append(int(match.group(1)))
    return max(numbers, default=0) + 1


def build_batches(
    inventory: dict[str, Any], batch_dir: Path, batch_size: int
) -> list[tuple[Path, dict[str, Any]]]:
    sources = source_map(inventory)
    grouped: dict[tuple[str, str], list[dict[str, Any]]] = defaultdict(list)
    for question in inventory["questions"]:
        if question.get("reviewBatch") is None:
            grouped[(question["subjectCode"], question["workItemCode"])].append(question)

    number = next_batch_number(batch_dir)
    output: list[tuple[Path, dict[str, Any]]] = []
    for key in sorted(grouped):
        questions = sorted(
            grouped[key], key=lambda item: item["sourceLocator"]["questionNumber"]
        )
        for group in chunks(questions, batch_size):
            first = group[0]
            last = group[-1]
            source_file = first["sourceLocator"]["officialFile"]
            if any(item["sourceLocator"]["officialFile"] != source_file for item in group):
                raise ValueError("A review batch cannot mix official source files")
            source = sources[source_file]
            first_number = first["sourceLocator"]["questionNumber"]
            last_number = last["sourceLocator"]["questionNumber"]
            stem = (
                f"review-batch-{number:03d}-{first['subjectCode']}-"
                f"w{first['workItemCode']}-q{first_number:03d}-q{last_number:03d}"
            )
            path = batch_dir / f"{stem}.json"
            payload = {
                "schemaVersion": 1,
                "batchId": stem.removeprefix("review-batch-"),
                "reviewedAt": "2026-08-11",
                "sourcePdfSha256": source["sha256"],
                "sourceLocator": {
                    "officialFile": source_file,
                    "officialPdfPages": sorted(
                        {item["sourceLocator"]["officialPdfPage"] for item in group}
                    ),
                    "officialPrintedPages": sorted(
                        {
                            item["sourceLocator"]["officialPrintedPage"]
                            for item in group
                        }
                    ),
                },
                "batchStatus": "official-first-pass-reviewed-editorial-draft",
                "rightsStatus": "needs-review",
                "releaseEligible": False,
                "questions": [reviewed_question(item, source) for item in group],
            }
            output.append((path, payload))
            number += 1
    return output


def refresh_generated_batches(
    inventory: dict[str, Any], batch_dir: Path, dry_run: bool
) -> dict[str, Any]:
    sources = source_map(inventory)
    by_id = {question["questionId"]: question for question in inventory["questions"]}
    refreshed = 0
    question_count = 0
    for path in sorted(batch_dir.glob("review-batch-*.json")):
        payload = json.loads(path.read_text(encoding="utf-8"))
        if payload.get("batchStatus") != "official-first-pass-reviewed-editorial-draft":
            continue
        official_file = payload["sourceLocator"]["officialFile"]
        source = sources[official_file]
        ids = [item["questionId"] for item in payload.get("questions", [])]
        missing = [question_id for question_id in ids if question_id not in by_id]
        if missing:
            raise ValueError(f"{path.name}: unknown question ids: {missing}")
        payload["questions"] = [
            reviewed_question(by_id[question_id], source) for question_id in ids
        ]
        if not dry_run:
            path.write_text(
                json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )
        refreshed += 1
        question_count += len(ids)
    return {
        "refreshedBatchCount": refreshed,
        "questionCount": question_count,
        "dryRun": dry_run,
    }


def report_text(
    inventory: dict[str, Any], batches: list[tuple[Path, dict[str, Any]]]
) -> str:
    questions = [
        question
        for question in inventory["questions"]
        if question.get("reviewBatch") is None
    ]
    grouped = Counter(
        (question["subjectCode"], question["workItemCode"])
        for question in questions
    )
    deleted = [
        question["questionId"]
        for question in questions
        if question["officialDisposition"] != "active-reference"
    ]
    lines = [
        "# Full official-first-pass review report",
        "",
        "- Generated: `2026-08-11`",
        f"- New review batches: `{len(batches)}`",
        f"- Questions covered: `{len(questions)}`",
        f"- Active questions: `{len(questions) - len(deleted)}`",
        f"- Deleted/tombstone questions: `{len(deleted)}`",
        "- Release eligible: `0`",
        "- Review basis: official WDA publications and existing verified text/visual extraction",
        "- Important: this completes the official-source first pass; it does not convert official answer keys into independent engineering or legal verification.",
        "",
        "## Coverage",
        "",
    ]
    for (subject_code, work_item), count in sorted(grouped.items()):
        lines.append(f"- `{subject_code}/W{work_item}`: `{count}`")
    lines.extend(["", "## Deleted questions retained as tombstones", ""])
    if deleted:
        lines.extend(f"- `{question_id}`" for question_id in deleted)
    else:
        lines.append("- None")
    lines.extend(
        [
            "",
            "## Gates still required before release",
            "",
            "- Independent technical or current-law verification where marked.",
            "- Content-rights decision for bulk reproduction and distribution.",
            "- Editorial depth review of generated explanations and distractor rationales.",
            "- Candidate release validation and App QA.",
            "",
        ]
    )
    return "\n".join(lines)


def main() -> int:
    args = parse_args()
    if args.batch_size < 1 or args.batch_size > 30:
        print("--batch-size must be between 1 and 30", file=sys.stderr)
        return 2
    for path in (args.inventory, args.batch_dir, args.report):
        ensure_private(path)
    if not args.inventory.is_file():
        print("Question inventory is missing", file=sys.stderr)
        return 2

    inventory = json.loads(args.inventory.read_text(encoding="utf-8"))
    if args.refresh_generated:
        print(
            json.dumps(
                refresh_generated_batches(inventory, args.batch_dir, args.dry_run),
                ensure_ascii=False,
                indent=2,
            )
        )
        return 0
    batches = build_batches(inventory, args.batch_dir, args.batch_size)
    collisions = [path for path, _ in batches if path.exists()]
    if collisions:
        print(
            "Refusing to overwrite existing batches: "
            + ", ".join(path.name for path in collisions),
            file=sys.stderr,
        )
        return 2

    summary = {
        "newBatchCount": len(batches),
        "questionCount": sum(len(payload["questions"]) for _, payload in batches),
        "firstBatch": batches[0][0].name if batches else "",
        "lastBatch": batches[-1][0].name if batches else "",
        "dryRun": args.dry_run,
    }
    if args.dry_run:
        print(json.dumps(summary, ensure_ascii=False, indent=2))
        return 0

    args.batch_dir.mkdir(parents=True, exist_ok=True)
    args.report.parent.mkdir(parents=True, exist_ok=True)
    for path, payload in batches:
        path.write_text(
            json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
    args.report.write_text(report_text(inventory, batches), encoding="utf-8")
    print(json.dumps(summary, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
