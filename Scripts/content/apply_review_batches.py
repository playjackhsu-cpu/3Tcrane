#!/usr/bin/env python3
"""Apply private human/source review batches to the private inventory."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any


PROJECT_ROOT = Path(__file__).resolve().parents[2]
PRIVATE_ROOT = PROJECT_ROOT / "PrivateResources/QuestionBank-Inbox"
DEFAULT_INVENTORY = PRIVATE_ROOT / "official-question-inventory.json"
DEFAULT_BATCH_DIR = PRIVATE_ROOT
SPACE_RE = re.compile(r"\s+")


def compact(value: str) -> str:
    return SPACE_RE.sub("", value).replace("？", "").replace("?", "")


def prompt_is_compatible(batch_prompt: str, inventory_prompt: str) -> bool:
    batch = compact(batch_prompt)
    inventory = compact(inventory_prompt)
    if batch == inventory:
        return True
    editorial_suffixes = ("哪一部法規", "哪一種規定")
    for suffix in editorial_suffixes:
        if batch.endswith(suffix) and batch[: -len(suffix)] == inventory:
            return True
    return False


def ensure_private(path: Path) -> None:
    private = PRIVATE_ROOT.resolve()
    resolved = path.resolve()
    if resolved != private and private not in resolved.parents:
        raise ValueError(f"Refusing non-private path: {resolved}")


def apply_batch(
    inventory_by_id: dict[str, dict[str, Any]],
    batch_path: Path,
) -> tuple[int, list[str]]:
    batch = json.loads(batch_path.read_text(encoding="utf-8"))
    applied = 0
    warnings: list[str] = []
    for reviewed in batch.get("questions", []):
        question_id = reviewed["questionId"]
        if question_id not in inventory_by_id:
            raise ValueError(f"{batch_path.name}: unknown questionId {question_id}")
        question = inventory_by_id[question_id]
        transcription = question["transcription"]
        if reviewed["options"] != transcription["options"]:
            raise ValueError(f"{question_id}: options differ from official extraction")
        if reviewed["printedAnswerIndex"] != transcription["printedAnswerIndex"]:
            raise ValueError(f"{question_id}: printed answer differs")
        if not prompt_is_compatible(reviewed["prompt"], transcription["prompt"]):
            raise ValueError(f"{question_id}: prompt differs from official extraction")
        if reviewed["prompt"] != transcription["prompt"]:
            warnings.append(f"{question_id}: editorial prompt expansion retained in batch only")

        source = {
            "title": reviewed.get("publicSource", ""),
            "url": reviewed.get("publicSourceUrl", ""),
            "checkedAt": reviewed.get("publicSourceCheckedAt", ""),
        }
        verification = question["verification"]
        verification["currentAnswerIndex"] = reviewed.get("currentAnswerIndex")
        verification["answerStatus"] = reviewed.get("answerStatus", "needs-review")
        verification["answerConflict"] = reviewed.get("answerConflict", "")
        verification["publicSources"] = [source] if source["url"] else []
        verification["publicSourceCheckedAt"] = source["checkedAt"]

        editorial = question["editorial"]
        editorial["explanation"] = reviewed.get("explanation", "")
        editorial["alternativeAnswer"] = reviewed.get("alternativeAnswer", "")
        editorial["choiceRationales"] = reviewed.get(
            "choiceRationales", ["", "", "", ""]
        )
        transcription["scanLineReviewStatus"] = reviewed.get(
            "lineReviewStatus", transcription["scanLineReviewStatus"]
        )
        question["reviewStatus"] = reviewed.get(
            "reviewStatus", question["reviewStatus"]
        )
        question["rightsStatus"] = reviewed.get(
            "rightsStatus", question["rightsStatus"]
        )
        question["releaseEligible"] = bool(
            reviewed.get("releaseEligible", False)
        )
        question["reviewBatch"] = {
            "batchId": batch.get("batchId", batch_path.stem),
            "batchFile": batch_path.name,
            "reviewedAt": batch.get("reviewedAt", ""),
        }
        applied += 1
    return applied, warnings


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--inventory", type=Path, default=DEFAULT_INVENTORY)
    parser.add_argument("--batch-dir", type=Path, default=DEFAULT_BATCH_DIR)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    ensure_private(args.inventory)
    ensure_private(args.batch_dir)
    if not args.inventory.is_file():
        print("Question inventory is missing.", file=sys.stderr)
        return 2

    inventory = json.loads(args.inventory.read_text(encoding="utf-8"))
    by_id = {question["questionId"]: question for question in inventory["questions"]}
    batch_paths = sorted(args.batch_dir.glob("review-batch-*.json"))
    total = 0
    warnings: list[str] = []
    for batch_path in batch_paths:
        applied, batch_warnings = apply_batch(by_id, batch_path)
        total += applied
        warnings.extend(batch_warnings)
    inventory["reviewBatchApplication"] = {
        "batchCount": len(batch_paths),
        "questionCount": total,
        "warnings": warnings,
    }
    args.inventory.write_text(
        json.dumps(inventory, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(
        json.dumps(
            {
                "batches": len(batch_paths),
                "questions": total,
                "warnings": warnings,
            },
            ensure_ascii=False,
            indent=2,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
