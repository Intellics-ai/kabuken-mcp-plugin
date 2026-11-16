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

# 4d. The real server.json description_ja that carried a bilingual-label claim must fail validation.
dir=$(copy_repo)
jq '._meta["io.modelcontextprotocol.registry/publisher-provided"].description_ja = "EDINET開示書類のXBRLデータを、ファクト単位でAIクライアントに提供。日英バイリンガルラベル、財務データ、スクリーニング。株価は含みません。利用にはサインアップが必要です。"' server.json > "$dir/server.json"
out=$(bash "$dir/scripts/validate-package.sh" 2>&1)
if [ $? -ne 0 ] && printf '%s\n' "$out" | grep -q 'server.json contains a bilingual-label claim'; then
  pass "bilingual-label wording in server.json description_ja fails validation"
else
  fail "bilingual-label wording in server.json description_ja passes validation"
fi
rm -rf "$dir"

# 4e. A skill that names a tool missing from tool-names.txt must fail validation.
dir=$(copy_repo)
printf '\nCall `get_nonexistent_text` for the text.\n' >> "$dir/skills/get-started/SKILL.md"
out=$(bash "$dir/scripts/validate-package.sh" 2>&1)
if [ $? -ne 0 ] && printf '%s\n' "$out" | grep -q 'skills/get-started/SKILL.md names an unknown tool: get_nonexistent_text'; then
  pass "skill naming an unknown tool fails validation"
else
  fail "skill naming an unknown tool passes validation"
fi
rm -rf "$dir"

# 4e2. A skill that names an unknown report_* tool must fail validation.
dir=$(copy_repo)
printf '\nCall `report_nonexistent_issue` to flag it.\n' >> "$dir/skills/get-started/SKILL.md"
out=$(bash "$dir/scripts/validate-package.sh" 2>&1)
if [ $? -ne 0 ] && printf '%s\n' "$out" | grep -q 'skills/get-started/SKILL.md names an unknown tool: report_nonexistent_issue'; then
  pass "skill naming an unknown report_ tool fails validation"
else
  fail "skill naming an unknown report_ tool passes validation"
fi
rm -rf "$dir"

# 4f. The filing text tool must be an allowed tool name and be taught by a skill.
if grep -qxF get_filing_text scripts/tool-names.txt; then
  pass "get_filing_text is in tool-names.txt"
else
  fail "get_filing_text is missing from tool-names.txt"
fi
if grep -q 'get_filing_text' skills/company-snapshot/SKILL.md skills/get-started/SKILL.md; then
  pass "company-snapshot and get-started teach get_filing_text"
else
  fail "get_filing_text is not taught in company-snapshot or get-started"
fi

# 4g. A dedicated skill must name get_filing_text in its description, in the Claude plugin and in the built ZIP.
filing_skill=""
for f in skills/*/SKILL.md; do
  desc=$(sed -n '/^---$/,/^---$/p' "$f" | grep -E '^description:' || true)
  if [[ "$desc" == *get_filing_text* ]]; then
    filing_skill=$(basename "$(dirname "$f")")
  fi
done
if [ -n "$filing_skill" ]; then
  pass "skill $filing_skill names get_filing_text in its description"
else
  fail "no skill names get_filing_text in its frontmatter description"
fi
if [ -n "$filing_skill" ] && [ "$filing_skill" != "kabuken-setup" ]; then
  dir=$(copy_repo)
  zip_list=""
  if (cd "$dir" && bash scripts/build-package.sh >/dev/null 2>&1); then
    zip_list=$(unzip -Z1 "$dir/dist/kabuken-plugin.zip")
  fi
  if printf '%s\n' "$zip_list" | grep -qxF "skills/$filing_skill/SKILL.md"; then
    pass "built ZIP contains skills/$filing_skill/SKILL.md"
  else
    fail "built ZIP does not contain skills/$filing_skill/SKILL.md"
  fi
  rm -rf "$dir"
else
  fail "built ZIP has no filing text skill"
fi

# 4b. Skill tool-name check (kabuken-cloudflare#1960): a backticked field that
# shares a tool prefix passes; an unknown tool name in tool position fails.
old_tool_re="\`($(cut -d_ -f1 scripts/tool-names.txt | sort -u | paste -sd'|' -))_[a-z_]+\`"
old_flagged=$(grep -oE "$old_tool_re" "$fixtures/skill-field-names.md" | tr -d '`' | grep -vxFf scripts/tool-names.txt)
if printf '%s\n' "$old_flagged" | grep -qxF report_date; then
  pass "old prefix check flags report_date (the false positive)"
else
  fail "old prefix check does not flag report_date; the fixture no longer shows the false positive"
fi
dir=$(copy_repo)
mkdir -p "$dir/skills/field-names"
cp "$fixtures/skill-field-names.md" "$dir/skills/field-names/SKILL.md"
if out=$(bash "$dir/scripts/validate-package.sh" 2>&1); then
  pass "field names report_date, list_... and get_... in a skill pass validation"
else
  fail "field names in a skill fail validation"
  printf '%s\n' "$out" | grep -E '^ERROR' | sed 's/^/     /'
fi
rm -rf "$dir"
dir=$(copy_repo)
mkdir -p "$dir/skills/unknown-tool"
cp "$fixtures/skill-unknown-tool.md" "$dir/skills/unknown-tool/SKILL.md"
out=$(bash "$dir/scripts/validate-package.sh" 2>&1)
if [ $? -ne 0 ] && printf '%s\n' "$out" | grep -q 'names an unknown tool: get_stock_price'; then
  pass "unknown tool get_stock_price in a skill fails validation"
else
  fail "unknown tool get_stock_price in a skill passes validation"
fi
rm -rf "$dir"

# 4h. OpenAI portal: "Add no more than three prompts" (Intellics-ai/kabuken-cloudflare#1981).
# The real 2.2.0 manifest had five defaultPrompt entries and six JA example questions.
dir=$(copy_repo)
jq '.extensions["com.openai"].interface.defaultPrompt += ["What is Toyota'"'"'s EDINET entity code?"]' plugin.json > "$dir/plugin.json"
out=$(bash "$dir/scripts/validate-package.sh" 2>&1)
if [ $? -ne 0 ] && printf '%s\n' "$out" | grep -q 'defaultPrompt has 4 prompts; OpenAI allows at most 3'; then
  pass "four defaultPrompt entries fail validation"
else
  fail "four defaultPrompt entries pass validation"
fi
rm -rf "$dir"
dir=$(copy_repo)
jq '.extensions["com.openai"].publication.translations["ja-JP"].description += "\n・任天堂の大株主は？"' plugin.json > "$dir/plugin.json"
out=$(bash "$dir/scripts/validate-package.sh" 2>&1)
if [ $? -ne 0 ] && printf '%s\n' "$out" | grep -q 'ja-JP description lists 4 example questions; OpenAI allows at most 3'; then
  pass "four ja-JP example questions fail validation"
else
  fail "four ja-JP example questions pass validation"
fi
rm -rf "$dir"

# 4i. OpenAI field lengths (developers.openai.com/plugins/deploy/submission):
# starter prompts at most 128 characters. The portal rejected 2.2.1 with
# "Conversation starter 1: Prompt must be 128 characters or fewer" (#1117).
long_prompt=$(printf 'x%.0s' $(seq 1 129))
dir=$(copy_repo)
jq --arg p "$long_prompt" '.extensions["com.openai"].interface.defaultPrompt[0] = $p' plugin.json > "$dir/plugin.json"
out=$(bash "$dir/scripts/validate-package.sh" 2>&1)
if [ $? -ne 0 ] && printf '%s\n' "$out" | grep -q 'defaultPrompt entry is 129 characters; OpenAI allows at most 128'; then
  pass "a 129-character defaultPrompt fails validation"
else
  fail "a 129-character defaultPrompt passes validation"
fi
rm -rf "$dir"

# The real 2.2.1 manifest (commit c972f837) that the portal rejected must fail on prompt 1.
if git cat-file -e c972f837:plugin.json 2>/dev/null; then
  dir=$(copy_repo)
  git show c972f837:plugin.json > "$dir/plugin.json"
  out=$(bash "$dir/scripts/validate-package.sh" 2>&1)
  if [ $? -ne 0 ] && printf '%s\n' "$out" | grep -q 'defaultPrompt entry is 129 characters; OpenAI allows at most 128: Screen Japanese electronics companies'; then
    pass "the rejected 2.2.1 plugin.json fails on prompt 1 (129 characters)"
  else
    fail "the rejected 2.2.1 plugin.json passes the prompt length check"
  fi
  rm -rf "$dir"
else
  echo "SKIP c972f837 is not in this clone"
fi

# ja-JP example questions: characters, not bytes. 128 kana pass, 129 fail.
for n in 128 129; do
  q=$(printf 'あ%.0s' $(seq 1 "$n"))
  dir=$(copy_repo)
  jq --arg q "$q" '.extensions["com.openai"].publication.translations["ja-JP"].description |= (split("\n") | (length - 1) as $l | .[$l] = "・" + $q | join("\n"))' plugin.json > "$dir/plugin.json"
  out=$(bash "$dir/scripts/validate-package.sh" 2>&1)
  rc=$?
  if [ "$n" -eq 128 ]; then
    if [ "$rc" -eq 0 ]; then pass "a 128-character ja-JP example question passes validation"
    else fail "a 128-character ja-JP example question fails validation"; printf '%s\n' "$out" | grep -E '^ERROR' | sed 's/^/     /'; fi
  else
    if [ "$rc" -ne 0 ] && printf '%s\n' "$out" | grep -q 'ja-JP example question is 129 characters; OpenAI allows at most 128'; then
      pass "a 129-character ja-JP example question fails validation"
    else fail "a 129-character ja-JP example question passes validation"; fi
  fi
  rm -rf "$dir"
done

# Other documented limits: shortDescription 30, capability label 120, ja-JP subtitle 30.
dir=$(copy_repo)
jq '.extensions["com.openai"].interface.shortDescription = "Japanese company filings data!!" | .extensions["com.openai"].interface.capabilities[0] = ("c" * 121) | .extensions["com.openai"].publication.translations["ja-JP"].subtitle = ("あ" * 31)' plugin.json > "$dir/plugin.json"
out=$(bash "$dir/scripts/validate-package.sh" 2>&1)
if [ $? -ne 0 ] && printf '%s\n' "$out" | grep -q 'shortDescription is 31 characters' \
  && printf '%s\n' "$out" | grep -q 'capability label is 121 characters' \
  && printf '%s\n' "$out" | grep -q 'ja-JP subtitle is 31 characters'; then
  pass "over-length shortDescription, capability label and ja-JP subtitle fail validation"
else
  fail "over-length shortDescription, capability label or ja-JP subtitle passes validation"
fi
rm -rf "$dir"

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
