#!/usr/bin/env python3
"""Build the governed public App Store question package.

The source inventory and exclusion evidence remain private. The generated package contains
only the fields needed by the app, public source links, and the public license attribution.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from build_internal_testflight_bank import (
    DEFAULT_INBOX,
    EXPECTED_CANDIDATE_COUNT,
    EXPECTED_EXCLUSION_COUNT,
    EXPECTED_FULL_COUNT,
    ROOT,
    build_package,
    load_json,
    validate_no_private_fields,
)


DEFAULT_OUTPUT = ROOT / "Content" / "Releases"
LICENSE_NAME = "勞動力發展署技能檢定中心政府網站資料開放宣告"
LICENSE_URL = "https://www.wdasec.gov.tw/cp.aspx?n=EAB483BB24D56F64"
LICENSE_ATTRIBUTION = "資料來源：勞動部勞動力發展署技能檢定中心"
LICENSE_CHECKED_AT = "2026-08-11"
BLOCKED_REVIEW_STATUS_FRAGMENTS = (
    "deleted-retained",
    "answer-conflict-release-blocked",
    "release-blocked-by-pending-law-change",
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--inbox", type=Path, default=DEFAULT_INBOX)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--content-version", default="1.0.0")
    return parser.parse_args()


def validate_release_selection(inventory: dict, exclusions: dict) -> None:
    questions = inventory.get("questions", [])
    excluded_rows = exclusions.get("exclusions", [])
    excluded_ids = {row.get("questionId") for row in excluded_rows}

    if len(questions) != EXPECTED_FULL_COUNT:
        raise ValueError(f"full inventory count must be {EXPECTED_FULL_COUNT}, got {len(questions)}")
    if len(excluded_ids) != EXPECTED_EXCLUSION_COUNT:
        raise ValueError(
            f"exclusion count must be {EXPECTED_EXCLUSION_COUNT}, got {len(excluded_ids)}"
        )

    included = [question for question in questions if question.get("questionId") not in excluded_ids]
    if len(included) != EXPECTED_CANDIDATE_COUNT:
        raise ValueError(
            f"candidate count must be {EXPECTED_CANDIDATE_COUNT}, got {len(included)}"
        )

    leaked_blocked = [
        question.get("questionId")
        for question in included
        if any(
            fragment in str(question.get("reviewStatus") or "")
            for fragment in BLOCKED_REVIEW_STATUS_FRAGMENTS
        )
    ]
    if leaked_blocked:
        raise ValueError(f"release-blocked questions entered the active pool: {leaked_blocked}")

    for row in excluded_rows:
        if row.get("includeInCandidatePool") is not False:
            raise ValueError(f"{row.get('questionId')}: exclusion must stay outside candidate pool")
        if row.get("retainedInFullInventory") is not True:
            raise ValueError(f"{row.get('questionId')}: exclusion must remain in full inventory")


def main() -> int:
    args = parse_args()
    inbox = args.inbox.resolve()
    output = args.output.resolve()
    inventory = load_json(inbox / "official-question-inventory.json")
    exclusions = load_json(inbox / "review-exclusions.json")
    validate_release_selection(inventory, exclusions)

    package = build_package(inbox, output, args.content_version)
    package["sourceSystem"] = "3Tcrane"
    package["license"] = {
        "name": LICENSE_NAME,
        "url": LICENSE_URL,
        "attribution": LICENSE_ATTRIBUTION,
        "checkedAt": LICENSE_CHECKED_AT,
    }
    for question in package["questions"]:
        question["accuracyStatus"] = "official-reference-reviewed"
        question["rightsStatus"] = "official-open-data"

    validate_no_private_fields(package)
    serialized = json.dumps(package, ensure_ascii=False, indent=2) + "\n"
    target = output / "question-bank.release.json"
    target.write_text(serialized, encoding="utf-8")
    digest = hashlib.sha256(serialized.encode("utf-8")).hexdigest()
    print(
        f"Built {target}: {len(package['questions'])} active questions, "
        f"{len(package['reviewExceptions'])} review exceptions, sha256={digest}."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
