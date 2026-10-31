#!/usr/bin/env bash
# Tests for scripts/validate-package.sh. Needs bash, jq and tar.
set -uo pipefail

cd "$(dirname "$0")/../.."
fixtures=scripts/tests/fixtures
failures=0
pass() { echo "PASS $*"; }
fail() { echo "FAIL $*"; failures=$((failures + 1)); }

commerce_re=$(sed -n "s/^commerce_re='\(.*\)'\$/\1/p" scripts/validate-package.sh)
[ -n "$commerce_re" ] || { echo "FAIL commerce_re not found in validate-package.sh"; exit 1; }

lines() { grep -vE '^(#[^#]|$)' "$1"; }

# 1. Filing text must not be flagged.
while IFS= read -r line; do
  if printf '%s\n' "$line" | grep -qiE "$commerce_re"; then
    fail "finance text flagged as commerce: $line"
  else
    pass "finance text not flagged: $line"
  fi
done < <(lines "$fixtures/finance-ok.txt")

# 2. Commerce text (EN and JA) must be flagged.
for f in "$fixtures/commerce-en.txt" "$fixtures/commerce-ja.txt"; do
  while IFS= read -r line; do
    if printf '%s\n' "$line" | grep -qiE "$commerce_re"; then
      pass "commerce text flagged: $line"
    else
      fail "commerce text not flagged: $line"
    fi
  done < <(lines "$f")
done

# Run validate-package.sh on a copy of the repo changed by a jq/cp step.
copy_repo() {
  local dir
  dir=$(mktemp -d)
  tar --exclude=.git --exclude=dist -cf - . | tar -xf - -C "$dir"
  echo "$dir"
}

# 3. README.md with plan wording must fail validation.
dir=$(copy_repo)
cp "$fixtures/readme-paid-plans.md" "$dir/README.md"
out=$(bash "$dir/scripts/validate-package.sh" 2>&1)
if [ $? -ne 0 ] && printf '%s\n' "$out" | grep -q 'README.md contains plan, pricing or upgrade wording'; then
  pass "README.md with paid-plan wording fails validation"
else
  fail "README.md with paid-plan wording passes validation"
fi
rm -rf "$dir"

# 3b. SETUP.md with plan wording must fail validation.
dir=$(copy_repo)
cp "$fixtures/setup-paid-plans.md" "$dir/SETUP.md"
out=$(bash "$dir/scripts/validate-package.sh" 2>&1)
if [ $? -ne 0 ] && printf '%s\n' "$out" | grep -q 'SETUP.md contains plan, pricing or upgrade wording'; then
  pass "SETUP.md with paid-plan wording fails validation"
else
  fail "SETUP.md with paid-plan wording passes validation"
fi
rm -rf "$dir"

# 4. release_notes that name another version must fail validation.
dir=$(copy_repo)
jq '.extensions["com.openai"].publication.release_notes = "Kabuken 0.0.1: old notes."' plugin.json > "$dir/plugin.json"
out=$(bash "$dir/scripts/validate-package.sh" 2>&1)
rc=$?
v=$(jq -r '.version' plugin.json)
if [ "$rc" -ne 0 ] && printf '%s\n' "$out" | grep -qxF "ERROR: release_notes must start with \"Kabuken $v:\", found: Kabuken 0.0.1: old notes."; then
  pass "release_notes for another version fail validation"
else
  fail "release_notes for another version pass validation"
fi
rm -rf "$dir"

# 4b. Unverified bilingual-label wording must fail validation (Claude description, OpenAI text, README).
dir=$(copy_repo)
jq '.description += " with bilingual EN/JA labels"' .claude-plugin/plugin.json > "$dir/.claude-plugin/plugin.json"
out=$(bash "$dir/scripts/validate-package.sh" 2>&1)
if [ $? -ne 0 ] && printf '%s\n' "$out" | grep -q 'bilingual-label claim'; then
  pass "bilingual-label wording in the Claude description fails validation"
else
  fail "bilingual-label wording in the Claude description passes validation"
fi
rm -rf "$dir"

dir=$(copy_repo)
printf '\nLabels are available in English and Japanese.\n' >> "$dir/README.md"
out=$(bash "$dir/scripts/validate-package.sh" 2>&1)
if [ $? -ne 0 ] && printf '%s\n' "$out" | grep -q 'README.md contains a bilingual-label claim'; then
  pass "bilingual-label wording in README.md fails validation"
else
  fail "bilingual-label wording in README.md passes validation"
fi
rm -rf "$dir"

# 4c. build-package.sh must not name the assets directory; it stages the files the manifest references.
if grep -qi 'assets' scripts/build-package.sh; then
  fail "build-package.sh names the assets directory"
else
  pass "build-package.sh does not name the assets directory"
fi

# 5. The repository itself must pass validation.
if out=$(bash scripts/validate-package.sh 2>&1); then
  pass "repository passes validate-package.sh"
else
  fail "repository fails validate-package.sh"
  printf '%s\n' "$out" | grep -E '^ERROR' | sed 's/^/     /'
fi

if [ "$failures" -ne 0 ]; then
  echo "$failures test(s) failed." >&2
  exit 1
fi
echo "All tests passed."
