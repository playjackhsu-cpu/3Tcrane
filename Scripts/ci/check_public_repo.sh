#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$repo_root"

file_list="$(mktemp)"
trap 'rm -f "$file_list"' EXIT

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  # Scan every file that could be committed: tracked files plus untracked files
  # not excluded by .gitignore. Ignored private inputs and local deliverables
  # stay outside the public-candidate set even before the repository's first commit.
  git ls-files --cached --others --exclude-standard -z > "$file_list"
else
  find . -type f \
    -not -path './.git/*' \
    -not -path './PrivateResources/*' \
    -not -path './DerivedData/*' \
    -not -path './build/*' \
    -print0 > "$file_list"
fi

failed=0

while IFS= read -r -d '' path; do
  path="${path#./}"
  lower="$(printf '%s' "$path" | tr '[:upper:]' '[:lower:]')"

  case "$lower" in
    privateresources/readme.md) continue ;;
    privateresources/*|*.env|*.p12|*.p8|*.cer|*.mobileprovision|*.provisionprofile|*.key|*.pem|*.sqlite|*.sqlite3|*.db|*.db-shm|*.db-wal|*.xcarchive|*.ipa|*.xcresult|*.zip|*.7z|*.rar|*.pdf|*.doc|*.docx|*.xls|*.xlsx)
      printf 'BLOCKED public file: %s\n' "$path"
      failed=1
      ;;
  esac

  case "$lower" in
    */xcuserdata/*|*.xcuserstate|*/deriveddata/*|*/.ds_store)
      printf 'BLOCKED generated/user file: %s\n' "$path"
      failed=1
      ;;
  esac
done < "$file_list"

scan_list="$(mktemp)"
trap 'rm -f "$file_list" "$scan_list"' EXIT
while IFS= read -r -d '' path; do
  path="${path#./}"
  [[ "$path" == "Scripts/ci/check_public_repo.sh" ]] && continue
  [[ "$path" == Assets/* ]] && continue
  file "$path" | grep -q 'text\|JSON\|XML\|script\|empty' && printf '%s\0' "$path" >> "$scan_list" || true
done < "$file_list"

if [[ -s "$scan_list" ]]; then
  patterns=(
    '-----BEGIN ([A-Z ]+ )?PRIVATE KEY-----'
    'AKIA[0-9A-Z]{16}'
    'gh[pousr]_[A-Za-z0-9_]{20,}'
    'github_pat_[A-Za-z0-9_]{20,}'
    '/Users/[^[:space:]<>)]+'
    '(^|[^0-9])(10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|192\.168\.[0-9]{1,3}\.[0-9]{1,3})([^0-9]|$)'
  )
  for pattern in "${patterns[@]}"; do
    if xargs -0 grep -IEn -- "$pattern" < "$scan_list"; then
      printf 'BLOCKED sensitive pattern: %s\n' "$pattern"
      failed=1
    fi
  done
fi

if [[ "$failed" -ne 0 ]]; then
  printf 'Public repository governance check failed.\n'
  exit 1
fi

printf 'Public repository governance check passed.\n'
