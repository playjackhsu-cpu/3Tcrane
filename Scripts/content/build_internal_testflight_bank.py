#!/usr/bin/env python3
"""Build the ignored Internal TestFlight question package from governed private inputs.

The output remains under PrivateResources and must never be committed. Only public-facing
question fields and stable resource names are written to the app candidate package.
"""

from __future__ import annotations

import argparse
import json
import shutil
from collections import OrderedDict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_INBOX = ROOT / "PrivateResources" / "QuestionBank-Inbox"
DEFAULT_OUTPUT = ROOT / "PrivateResources" / "TestFlightBundle"
EXPECTED_FULL_COUNT = 1_000
EXPECTED_EXCLUSION_COUNT = 17
EXPECTED_CANDIDATE_COUNT = 983
EXPECTED_VISUAL_COUNT = 9
EXPECTED_EXCEPTION_CATEGORY_COUNTS = {
    "official-deleted": 8,
    "hard-answer-conflict": 5,
    "regulatory-transition-hold": 4,
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--inbox", type=Path, default=DEFAULT_INBOX)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--content-version", default="0.2.1")
    return parser.parse_args()


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def safe_resource_name(question_id: str, role: str, index: int | None, suffix: str) -> str:
    part = f"-{index + 1}" if index is not None else ""
    return f"{question_id}-{role}{part}{suffix.lower()}"


def exception_prompt(value: str) -> str:
    return value.replace("(本題刪題 )", "").replace("(本題刪題)", "").strip()


def build_package(inbox: Path, output: Path, content_version: str) -> dict:
    inventory = load_json(inbox / "official-question-inventory.json")
    exclusions = load_json(inbox / "review-exclusions.json")

    questions = inventory.get("questions", [])
    excluded_rows = exclusions.get("exclusions", [])
    excluded_ids = {row["questionId"] for row in excluded_rows}
    if len(questions) != EXPECTED_FULL_COUNT:
        raise ValueError(f"full inventory count must be {EXPECTED_FULL_COUNT}, got {len(questions)}")
    if len(excluded_ids) != EXPECTED_EXCLUSION_COUNT:
        raise ValueError(f"exclusion count must be {EXPECTED_EXCLUSION_COUNT}, got {len(excluded_ids)}")

    included = [question for question in questions if question["questionId"] not in excluded_ids]
    if len(included) != EXPECTED_CANDIDATE_COUNT:
        raise ValueError(f"candidate count must be {EXPECTED_CANDIDATE_COUNT}, got {len(included)}")

    questions_by_id = {question["questionId"]: question for question in questions}
    review_exceptions: list[dict] = []
    category_counts = {key: 0 for key in EXPECTED_EXCEPTION_CATEGORY_COUNTS}
    for row in excluded_rows:
        question_id = row["questionId"]
        source = questions_by_id.get(question_id)
        if source is None:
            raise ValueError(f"{question_id}: exclusion does not match the official inventory")
        category = str(row.get("category") or "").strip()
        if category not in category_counts:
            raise ValueError(f"{question_id}: unsupported exception category {category}")
        category_counts[category] += 1
        reviewed_answer = str(row.get("reviewedAnswer") or "").strip()
        if not reviewed_answer:
            raise ValueError(f"{question_id}: reviewedAnswer is required")
        public_sources = source["verification"].get("publicSources") or []
        if not public_sources:
            raise ValueError(f"{question_id}: exception public source missing")
        public_source = public_sources[0]
        review_exceptions.append(
            {
                "id": question_id,
                "publicCode": source["publicCode"],
                "category": category,
                "subjectTitle": source["subjectName"],
                "chapterTitle": source["workItemName"],
                "prompt": exception_prompt(row["prompt"]),
                "officialPrintedAnswer": str(row["printedAnswer"]).strip(),
                "reviewedAnswer": reviewed_answer,
                "reason": str(row["reason"]).strip(),
                "publicSource": str(public_source.get("title") or "").strip(),
                "publicSourceUrl": str(public_source.get("url") or "").strip(),
                "publicSourceCheckedAt": str(
                    public_source.get("checkedAt")
                    or source["verification"].get("publicSourceCheckedAt")
                    or ""
                ).strip(),
            }
        )
    if category_counts != EXPECTED_EXCEPTION_CATEGORY_COUNTS:
        raise ValueError(
            f"exception category counts must be {EXPECTED_EXCEPTION_CATEGORY_COUNTS}, "
            f"got {category_counts}"
        )

    output.mkdir(parents=True, exist_ok=True)
    asset_output = output / "QuestionBankAssets"
    if asset_output.exists():
        shutil.rmtree(asset_output)
    asset_output.mkdir(parents=True)

    subject_titles: OrderedDict[str, str] = OrderedDict()
    chapter_titles: OrderedDict[tuple[str, str], str] = OrderedDict()
    public_questions: list[dict] = []
    visual_count = 0

    for source in included:
        question_id = source["questionId"]
        subject_code = source["subjectCode"]
        work_item_code = source["workItemCode"]
        chapter_id = f"crane-{subject_code}-w{work_item_code}"
        subject_titles.setdefault(subject_code, source["subjectName"])
        chapter_titles.setdefault((subject_code, work_item_code), source["workItemName"])

        transcription = source["transcription"]
        verification = source["verification"]
        editorial = source["editorial"]
        answer_index = verification.get("currentAnswerIndex")
        if not isinstance(answer_index, int) or answer_index not in range(4):
            raise ValueError(f"{question_id}: invalid currentAnswerIndex")

        options = [str(value).strip() for value in transcription.get("options", [])]
        if len(options) != 4:
            raise ValueError(f"{question_id}: expected four options")

        visual = source.get("visual") or {}
        assets = visual.get("assets") or []
        image_resource: str | None = None
        image_accessibility_label: str | None = None
        option_image_resources: list[str | None] | None = None
        if visual.get("required"):
            visual_count += 1
            option_image_resources = [None, None, None, None]
            for asset in assets:
                relative_source = Path(asset["outputPath"])
                source_path = inbox / relative_source
                if not source_path.is_file():
                    raise ValueError(f"{question_id}: missing visual asset {relative_source}")
                role = asset.get("role", "diagram")
                option_index = asset.get("optionIndex") if role == "option" else None
                resource_name = safe_resource_name(question_id, role, option_index, source_path.suffix)
                # Copy bytes only. Finder/provenance metadata from reviewed source files must
                # not enter a signed app bundle or the public repository.
                shutil.copyfile(source_path, asset_output / resource_name)
                if role == "option":
                    if not isinstance(option_index, int) or option_index not in range(4):
                        raise ValueError(f"{question_id}: invalid option image index")
                    option_image_resources[option_index] = resource_name
                else:
                    image_resource = resource_name
                    image_accessibility_label = f"{source['publicCode']} 題目圖示"

            if all(not value for value in options):
                if not option_image_resources or any(value is None for value in option_image_resources):
                    raise ValueError(f"{question_id}: image-only options are incomplete")
                options = [f"圖示 {label}" for label in "ABCD"]
            if option_image_resources and all(value is None for value in option_image_resources):
                option_image_resources = None

        if len(set(options)) != 4 or any(not value for value in options):
            raise ValueError(f"{question_id}: options must be non-empty and unique")

        public_sources = verification.get("publicSources") or []
        if not public_sources:
            raise ValueError(f"{question_id}: public source missing")
        public_source = public_sources[0]
        answer = options[answer_index]
        answer_caveat = str(verification.get("answerConflict") or "").strip()
        explanation = str(editorial.get("explanation") or "").strip()
        if answer_caveat:
            explanation = f"{explanation}\n\n注意：{answer_caveat}".strip()

        public_questions.append(
            {
                "id": question_id,
                "publicCode": source["publicCode"],
                "subjectId": subject_code,
                "chapterId": chapter_id,
                "kind": "choice",
                "prompt": transcription["prompt"].strip(),
                "options": options,
                "answerIndex": answer_index,
                "answer": answer,
                "explanation": explanation,
                "alternativeAnswer": str(editorial.get("alternativeAnswer") or "").strip(),
                "publicSource": str(public_source.get("title") or "").strip(),
                "publicSourceUrl": str(public_source.get("url") or "").strip(),
                "publicSourceCheckedAt": str(public_source.get("checkedAt") or verification.get("publicSourceCheckedAt") or "").strip(),
                "accuracyStatus": "needs-review",
                "rightsStatus": str(source.get("rightsStatus") or "needs-review"),
                "imageResource": image_resource,
                "imageAccessibilityLabel": image_accessibility_label,
                "optionImageResources": option_image_resources,
            }
        )

    if visual_count != EXPECTED_VISUAL_COUNT:
        raise ValueError(f"visual question count must be {EXPECTED_VISUAL_COUNT}, got {visual_count}")

    subjects = [
        {"id": code, "title": title, "order": index + 1}
        for index, (code, title) in enumerate(subject_titles.items())
    ]
    chapters = [
        {
            "id": f"crane-{subject_code}-w{work_item_code}",
            "subjectId": subject_code,
            "title": title,
            "order": index + 1,
        }
        for index, ((subject_code, work_item_code), title) in enumerate(chapter_titles.items())
    ]
    package = {
        "schemaVersion": 1,
        "contentVersion": content_version,
        "generatedAt": inventory.get("generatedAt"),
        "sourceSystem": "governed Internal TestFlight candidate; bundled with app; not approved for public release",
        "isSynthetic": False,
        "subjects": subjects,
        "chapters": chapters,
        "questions": public_questions,
        "reviewExceptions": review_exceptions,
    }
    return package


def validate_no_private_fields(package: dict) -> None:
    serialized = json.dumps(package, ensure_ascii=False)
    forbidden = [
        "sourceLocator",
        "officialPdfPage",
        "scanCrossReference",
        "reviewBatch",
        "PrivateResources",
        str(ROOT),
    ]
    leaked = [token for token in forbidden if token in serialized]
    if leaked:
        raise ValueError(f"private governance fields leaked into candidate package: {leaked}")


def main() -> int:
    args = parse_args()
    package = build_package(args.inbox.resolve(), args.output.resolve(), args.content_version)
    validate_no_private_fields(package)
    target = args.output / "question-bank.internal.json"
    target.write_text(json.dumps(package, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(
        f"Built {target}: {len(package['questions'])} questions, "
        f"{len(package['subjects'])} subjects, {len(package['chapters'])} chapters, "
        f"{len(package['reviewExceptions'])} review exceptions."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
