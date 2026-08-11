#!/usr/bin/env python3
"""Validate public, app-bundled 3Tcrane question bank JSON files."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from urllib.parse import urlparse


ROOT = Path(__file__).resolve().parents[2]
TARGETS = [ROOT / "Content" / "Fixtures", ROOT / "Content" / "Releases"]
SEMVER = re.compile(r"^[0-9]+\.[0-9]+\.[0-9]+$")
STABLE_ID = re.compile(r"^[a-z0-9][a-z0-9._-]{2,63}$")
FORBIDDEN_KEYS = {
    "importSourcePath",
    "importSourceLocator",
    "sourceFilePath",
    "privateNote",
    "reviewerEmail",
}
QUESTION_KEYS = {
    "id",
    "publicCode",
    "subjectId",
    "chapterId",
    "kind",
    "prompt",
    "options",
    "answerIndex",
    "answer",
    "explanation",
    "alternativeAnswer",
    "publicSource",
    "publicSourceUrl",
    "publicSourceCheckedAt",
    "accuracyStatus",
    "rightsStatus",
    "imageResource",
    "imageAccessibilityLabel",
    "optionImageResources",
}
ACCURACY = {"unchecked", "checked", "needs-review", "deprecated"}
RIGHTS = {"cleared", "official-open-data", "public-domain", "synthetic"}


def require(condition: bool, message: str, errors: list[str]) -> None:
    if not condition:
        errors.append(message)


def validate(path: Path) -> list[str]:
    errors: list[str] = []
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:  # noqa: BLE001
        return [f"{path}: invalid JSON: {exc}"]

    prefix = str(path.relative_to(ROOT))
    require(payload.get("schemaVersion") == 1, f"{prefix}: schemaVersion must be 1", errors)
    require(bool(SEMVER.fullmatch(str(payload.get("contentVersion", "")))), f"{prefix}: invalid contentVersion", errors)

    subjects = payload.get("subjects")
    chapters = payload.get("chapters")
    questions = payload.get("questions")
    require(isinstance(subjects, list), f"{prefix}: subjects must be an array", errors)
    require(isinstance(chapters, list), f"{prefix}: chapters must be an array", errors)
    require(isinstance(questions, list), f"{prefix}: questions must be an array", errors)
    if not all(isinstance(value, list) for value in (subjects, chapters, questions)):
        return errors

    subject_ids = {item.get("id") for item in subjects if isinstance(item, dict)}
    chapter_ids = {item.get("id") for item in chapters if isinstance(item, dict)}
    require(len(subject_ids) == len(subjects), f"{prefix}: duplicate/invalid subject ids", errors)
    require(len(chapter_ids) == len(chapters), f"{prefix}: duplicate/invalid chapter ids", errors)

    question_ids: set[str] = set()
    public_codes: set[str] = set()
    for index, question in enumerate(questions):
        label = f"{prefix}: questions[{index}]"
        if not isinstance(question, dict):
            errors.append(f"{label}: must be an object")
            continue
        leaked = FORBIDDEN_KEYS.intersection(question)
        require(not leaked, f"{label}: forbidden private keys {sorted(leaked)}", errors)
        unexpected = set(question).difference(QUESTION_KEYS)
        require(not unexpected, f"{label}: unexpected public keys {sorted(unexpected)}", errors)

        question_id = question.get("id")
        public_code = question.get("publicCode")
        require(isinstance(question_id, str) and bool(STABLE_ID.fullmatch(question_id)), f"{label}: invalid stable id", errors)
        require(question_id not in question_ids, f"{label}: duplicate id {question_id}", errors)
        question_ids.add(question_id)
        require(isinstance(public_code, str) and bool(public_code.strip()), f"{label}: publicCode required", errors)
        require(public_code not in public_codes, f"{label}: duplicate publicCode {public_code}", errors)
        public_codes.add(public_code)

        require(question.get("subjectId") in subject_ids, f"{label}: unknown subjectId", errors)
        require(question.get("chapterId") in chapter_ids, f"{label}: unknown chapterId", errors)
        require(isinstance(question.get("prompt"), str) and bool(question["prompt"].strip()), f"{label}: prompt required", errors)
        require(question.get("accuracyStatus") in ACCURACY, f"{label}: invalid accuracyStatus", errors)
        require(question.get("rightsStatus") in RIGHTS, f"{label}: invalid rightsStatus", errors)

        kind = question.get("kind")
        require(kind in {"choice", "qa"}, f"{label}: kind must be choice or qa", errors)
        if kind == "choice":
            options = question.get("options")
            answer_index = question.get("answerIndex")
            require(isinstance(options, list) and len(options) == 4, f"{label}: choice requires exactly 4 options", errors)
            require(isinstance(answer_index, int) and 0 <= answer_index <= 3, f"{label}: answerIndex must be 0...3", errors)
            if isinstance(options, list):
                require(len(set(options)) == len(options), f"{label}: options must be unique", errors)
        else:
            require(isinstance(question.get("answer"), str) and bool(question["answer"].strip()), f"{label}: qa answer required", errors)

        source_url = question.get("publicSourceUrl", "")
        if source_url:
            parsed = urlparse(source_url)
            require(parsed.scheme == "https" and bool(parsed.netloc), f"{label}: publicSourceUrl must be HTTPS", errors)

        image_resource = question.get("imageResource")
        require(
            image_resource is None or (isinstance(image_resource, str) and bool(image_resource) and "/" not in image_resource),
            f"{label}: invalid imageResource",
            errors,
        )
        option_images = question.get("optionImageResources")
        require(
            option_images is None
            or (
                isinstance(option_images, list)
                and len(option_images) == 4
                and all(value is None or (isinstance(value, str) and bool(value) and "/" not in value) for value in option_images)
            ),
            f"{label}: invalid optionImageResources",
            errors,
        )

    return errors


def main() -> int:
    files = sorted(path for folder in TARGETS for path in folder.glob("*.json"))
    if not files:
        print("No question bank JSON files found.", file=sys.stderr)
        return 1
    errors = [error for path in files for error in validate(path)]
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print(f"Validated {len(files)} public question bank file(s).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
