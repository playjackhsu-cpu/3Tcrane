#!/usr/bin/env python3
"""Build private conflict and non-inclusion lists from the reviewed inventory."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any


PROJECT_ROOT = Path(__file__).resolve().parents[2]
PRIVATE_ROOT = PROJECT_ROOT / "PrivateResources/QuestionBank-Inbox"
INVENTORY_PATH = PRIVATE_ROOT / "official-question-inventory.json"
MANIFEST_PATH = PRIVATE_ROOT / "review-exclusions.json"
CONFLICT_REPORT_PATH = PRIVATE_ROOT / "reports/answer-and-law-conflicts.md"
NOT_INCLUDED_REPORT_PATH = PRIVATE_ROOT / "reports/not-included-question-list.md"


def markdown(value: str) -> str:
    return value.replace("|", "\\|").replace("\n", " ").strip()


def position(question: dict[str, Any]) -> str:
    locator = question["sourceLocator"]
    return (
        f"{locator['officialFile']} PDF p.{locator['officialPdfPage']} / "
        f"印刷 p.{locator['officialPrintedPage']} / 題 {locator['questionNumber']}"
    )


def printed_answer(question: dict[str, Any]) -> str:
    transcription = question["transcription"]
    index = transcription["printedAnswerIndex"]
    return transcription["options"][index] if index is not None else ""


def source_link(question: dict[str, Any]) -> str:
    sources = question["verification"].get("publicSources", [])
    if not sources or not sources[0].get("url"):
        return ""
    return f"[來源]({sources[0]['url']})"


def item(question: dict[str, Any], category: str, reason: str) -> dict[str, Any]:
    return {
        "questionId": question["questionId"],
        "category": category,
        "subjectCode": question["subjectCode"],
        "workItemCode": question["workItemCode"],
        "workItemName": question["workItemName"],
        "officialFile": question["sourceLocator"]["officialFile"],
        "officialPdfPage": question["sourceLocator"]["officialPdfPage"],
        "officialPrintedPage": question["sourceLocator"]["officialPrintedPage"],
        "questionNumber": question["sourceLocator"]["questionNumber"],
        "prompt": question["transcription"]["prompt"],
        "printedAnswer": printed_answer(question),
        "currentAnswerIndex": question["verification"]["currentAnswerIndex"],
        "reason": reason,
        "includeInCandidatePool": False,
        "retainedInFullInventory": True,
    }


def conflict_table(questions: list[dict[str, Any]], transition: bool) -> list[str]:
    lines = [
        "| ID | 私有來源定位 | 官方印刷答案 | 衝突／風險 | 現行處置 | 來源 |",
        "| --- | --- | --- | --- | --- | --- |",
    ]
    for question in questions:
        decision = (
            "條文目前有效，但發行前須重查施行日期；暫停納入候選抽題池。"
            if transition
            else "無現行答案；封鎖抽題與發行，保留完整證據。"
        )
        lines.append(
            "| {id} | {position} | {answer} | {conflict} | {decision} | {source} |".format(
                id=f"`{question['questionId']}`",
                position=markdown(position(question)),
                answer=markdown(printed_answer(question)),
                conflict=markdown(question["verification"].get("answerConflict", "")),
                decision=decision,
                source=source_link(question),
            )
        )
    return lines


def conflict_report(
    hard_conflicts: list[dict[str, Any]], transition_holds: list[dict[str, Any]]
) -> str:
    lines = [
        "# 答案與法規衝突清單",
        "",
        "本清單位於私有治理區。題目仍完整保留於 1,000 題總清冊，但下列項目不得在衝突解除前進入候選抽題池。",
        "",
        f"- 明確答案／題意衝突：`{len(hard_conflicts)}` 題",
        f"- 法規修正過渡期暫停：`{len(transition_holds)}` 題",
        "",
        "## 明確答案或題意衝突",
        "",
        *conflict_table(hard_conflicts, transition=False),
        "",
        "## 法規修正過渡期",
        "",
        *conflict_table(transition_holds, transition=True),
        "",
        "## 解除條件",
        "",
        "- 明確衝突題：主管機關更正版、可驗證的正式勘誤，或經 Owner 核准的新題文與新 revision。",
        "- 法規過渡題：每次 App 候選發行日重新查核施行日期與有效條文，必要時換題或建立新版 ID。",
        "- 不得直接用 AI 推測覆蓋官方印刷答案。",
        "",
    ]
    return "\n".join(lines)


def not_included_report(
    inventory: dict[str, Any],
    deleted: list[dict[str, Any]],
    hard_conflicts: list[dict[str, Any]],
    transition_holds: list[dict[str, Any]],
) -> str:
    excluded = deleted + hard_conflicts + transition_holds
    candidate_count = len(inventory["questions"]) - len(excluded)
    lines = [
        "# 未納入候選抽題池清單",
        "",
        f"- 完整私有清冊：`{len(inventory['questions'])}` 題",
        f"- 目前候選抽題池：`{candidate_count}` 題",
        f"- 暫不納入候選抽題池：`{len(excluded)}` 題",
        "- 所有未納入題仍保留穩定 ID、原題、答案、來源定位與審查歷程，不做實體刪除。",
        "",
        "## 官方刪題",
        "",
    ]
    for question in deleted:
        lines.append(
            f"- `{question['questionId']}` — {position(question)}；主管機關標示刪題。"
        )
    lines.extend(["", "## 明確答案／題意衝突", ""])
    for question in hard_conflicts:
        lines.append(
            f"- `{question['questionId']}` — {position(question)}；"
            f"{markdown(question['verification'].get('answerConflict', ''))}"
        )
    lines.extend(["", "## 法規修正過渡期暫停", ""])
    for question in transition_holds:
        lines.append(
            f"- `{question['questionId']}` — {position(question)}；"
            f"{markdown(question['verification'].get('answerConflict', ''))}"
        )
    lines.extend(
        [
            "",
            "## 其餘題目",
            "",
            f"其餘 `{candidate_count}` 題全部保留在候選抽題集合，不因尚待內容權利、獨立技術來源或發行 QA 而從完整資料集中刪除。正式 App release 仍須通過各項 gate。",
            "",
        ]
    )
    return "\n".join(lines)


def main() -> int:
    for path in (MANIFEST_PATH, CONFLICT_REPORT_PATH, NOT_INCLUDED_REPORT_PATH):
        if PRIVATE_ROOT.resolve() not in path.resolve().parents:
            print(f"Refusing non-private output: {path}", file=sys.stderr)
            return 2
    inventory = json.loads(INVENTORY_PATH.read_text(encoding="utf-8"))
    deleted = [
        question
        for question in inventory["questions"]
        if question["officialDisposition"] != "active-reference"
    ]
    hard_conflicts = [
        question
        for question in inventory["questions"]
        if question["officialDisposition"] == "active-reference"
        and question["verification"]["currentAnswerIndex"] is None
    ]
    transition_holds = [
        question
        for question in inventory["questions"]
        if question["reviewStatus"]
        == "source-checked-release-blocked-by-pending-law-change"
    ]
    all_ids = [
        question["questionId"]
        for question in deleted + hard_conflicts + transition_holds
    ]
    if len(all_ids) != len(set(all_ids)):
        print("Exception categories overlap", file=sys.stderr)
        return 2

    exclusions = [
        item(
            question,
            "official-deleted",
            "主管機關最新版標示刪題；只保留版本追溯。",
        )
        for question in deleted
    ]
    exclusions.extend(
        item(
            question,
            "hard-answer-conflict",
            question["verification"].get("answerConflict", ""),
        )
        for question in hard_conflicts
    )
    exclusions.extend(
        item(
            question,
            "regulatory-transition-hold",
            question["verification"].get("answerConflict", ""),
        )
        for question in transition_holds
    )
    manifest = {
        "schemaVersion": 1,
        "generatedAt": "2026-08-11",
        "fullInventoryCount": len(inventory["questions"]),
        "candidatePoolCount": len(inventory["questions"]) - len(exclusions),
        "exclusionCount": len(exclusions),
        "categoryCounts": {
            "officialDeleted": len(deleted),
            "hardAnswerConflict": len(hard_conflicts),
            "regulatoryTransitionHold": len(transition_holds),
        },
        "allQuestionsRetainedInFullInventory": True,
        "exclusions": exclusions,
    }
    MANIFEST_PATH.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    CONFLICT_REPORT_PATH.write_text(
        conflict_report(hard_conflicts, transition_holds), encoding="utf-8"
    )
    NOT_INCLUDED_REPORT_PATH.write_text(
        not_included_report(inventory, deleted, hard_conflicts, transition_holds),
        encoding="utf-8",
    )
    print(
        json.dumps(
            {
                "fullInventoryCount": len(inventory["questions"]),
                "candidatePoolCount": manifest["candidatePoolCount"],
                "exclusionCount": len(exclusions),
                "categoryCounts": manifest["categoryCounts"],
            },
            ensure_ascii=False,
            indent=2,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
