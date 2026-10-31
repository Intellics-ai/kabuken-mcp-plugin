#!/usr/bin/env bash
# Validate the plugin manifests and skills. Needs bash and jq.
set -euo pipefail

cd "$(dirname "$0")/.."
fail=0
err() { echo "ERROR: $*" >&2; fail=1; }

for f in plugin.json mcp.json .mcp.json .claude-plugin/plugin.json server.json; do
  if jq empty "$f" 2>/dev/null; then
    echo "ok   JSON $f"
  else
    err "invalid JSON: $f"
  fi
done
[ "$fail" -eq 0 ] || exit 1

# Every ./path referenced anywhere in plugin.json must exist.
while IFS= read -r p; do
  if [ -e "$p" ]; then
    echo "ok   path $p"
  else
    err "plugin.json references missing path: $p"
  fi
done < <(jq -r '.. | strings | select(startswith("./"))' plugin.json)

display=$(jq -r '.extensions["com.openai"].interface.displayName // empty' plugin.json)
[ -n "$display" ] || err "displayName is missing"
if printf '%s' "$display" | grep -qiE 'mcp|plugin'; then
  err "displayName must not contain MCP or Plugin: $display"
fi
[ "${#display}" -le 30 ] || err "displayName is longer than 30 characters"
short=$(jq -r '.extensions["com.openai"].interface.shortDescription // empty' plugin.json)
[ "${#short}" -le 30 ] || err "shortDescription is longer than 30 characters"

# Review cases: OpenAI requires exactly 5 positive and 3 negative cases.
oai='.extensions["com.openai"]'
n_pos=$(jq "$oai.review.test_cases.positive | length" plugin.json)
n_neg=$(jq "$oai.review.test_cases.negative | length" plugin.json)
[ "$n_pos" -eq 5 ] || err "review needs exactly 5 positive test cases, found $n_pos"
[ "$n_neg" -eq 3 ] || err "review needs exactly 3 negative test cases, found $n_neg"
[ "$fail" -ne 0 ] || echo "ok   review cases: $n_pos positive, $n_neg negative"

missing=$(jq -r "$oai.review.test_cases.positive[] | select((.description // \"\") == \"\" or (.prompt // \"\") == \"\" or (.tools_triggered // \"\") == \"\" or (.expected_behavior // \"\") == \"\") | .prompt" plugin.json)
[ -z "$missing" ] || err "positive case missing description, prompt, tools_triggered or expected_behavior: $missing"

# Every tools_triggered name must be a real server tool (scripts/tool-names.txt).
[ -s scripts/tool-names.txt ] || err "scripts/tool-names.txt is missing or empty"
while IFS= read -r t; do
  [ -n "$t" ] || continue
  if grep -qxF "$t" scripts/tool-names.txt; then
    echo "ok   tool $t"
  else
    err "tools_triggered names an unknown tool: $t"
  fi
done < <(jq -r "$oai.review.test_cases | (.positive + .negative)[] | .tools_triggered // empty" plugin.json | tr ',' '\n' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | sort -u)

# Never put credentials or reviewer instructions in the package.
for k in test_credentials reviewer_instructions; do
  if jq -e --arg k "$k" '[.. | objects | has($k)] | any' plugin.json >/dev/null; then
    err "plugin.json must not contain $k"
  fi
done

# Listing text must not contain prices or plan names.
# Review cases are reviewer-only and may quote filed yen amounts, so the price
# check covers the listing (description, interface, publication) only. The
# plan-name check also covers the review cases.
listing=$(jq -r '.description, (.extensions["com.openai"] | .interface, .publication | .. | strings)' plugin.json)
all_text=$(jq -r '.description, (.extensions["com.openai"] | .interface, .review, .publication | .. | strings)' plugin.json)
if printf '%s\n' "$listing" | grep -nE '\$[0-9]|[0-9]+(\.[0-9]+)? ?(USD|JPY)|¥|￥|円'; then
  err "plugin.json listing text contains a price"
fi
if printf '%s\n' "$all_text" | grep -nwE 'BASIC|INVESTOR|DEVELOPER'; then
  err "plugin.json listing text contains a plan name (BASIC/INVESTOR/DEVELOPER)"
fi
[ "$fail" -ne 0 ] || echo "ok   listing text has no prices or plan names"

# The Claude listing, every skill (packaged or not), README.md and SETUP.md must not contain prices
# or plan names either.
price_re='\$[0-9]|[0-9]+(\.[0-9]+)? ?(USD|JPY)|¥|￥|円'
plan_re='BASIC|INVESTOR|DEVELOPER'
claude_desc=$(jq -r '.description // empty' .claude-plugin/plugin.json)
if printf '%s\n' "$claude_desc" | grep -nE "$price_re"; then
  err ".claude-plugin/plugin.json description contains a price"
fi
if printf '%s\n' "$claude_desc" | grep -nwE "$plan_re"; then
  err ".claude-plugin/plugin.json description contains a plan name (BASIC/INVESTOR/DEVELOPER)"
fi
while IFS= read -r s; do
  if grep -nHE "$price_re" "$s"; then
    err "$s contains a price"
  fi
  if grep -nHwE "$plan_re" "$s"; then
    err "$s contains a plan name (BASIC/INVESTOR/DEVELOPER)"
  fi
done < <(find skills -name SKILL.md | sort; echo README.md; echo SETUP.md)
[ "$fail" -ne 0 ] || echo "ok   Claude description, skills, README and SETUP have no prices or plan names"

# Packaged files, every skill (packaged or not), README.md and SETUP.md must not promote
# paid plans (OpenAI commerce rule; neutral text for all clients): no pricing
# links, upgrades, subscriptions, checkout or purchases, and no text that tells
# the model to name a plan. A plugin may only say that a feature is not
# available for this account. The patterns name commerce contexts only, so
# filing terms such as "medium-term plan", "transfer pricing", "purchase of
# treasury stock", "subscription rights", 電気料金, 課金収入 or 有料老人ホーム
# pass. scripts/tests/run-tests.sh checks both sides.
# This is a best-effort net for plugin, skill and README text, not a full
# commerce classifier; scripts/tests/fixtures lists the sentences it covers.
commerce_re='/pricing([^-a-z]|$)|pricing (page|plans?|details|tiers?)|upgrade (your|now|for (higher|more)|to (a )?(paid|pro)( plan| tier)?([^a-z]|$))|upgrade (plan|tier|account)|unlock|buy credits?|free trial|pay per (request|call|use|query)|billing|subscribe (now|(to|for) (a |the |this )?(plan|kabuken|tier|service))|subscription (plans?|tiers?)|premium (subscription|members?(hip)?|accounts?|features?|tiers?|plans?)|(paid|premium|pro|higher|enterprise) tiers?|tier required|(paid|premium|pro|enterprise) plans?|plan: *(pro|free|basic|premium|paid|enterprise)|(switch|change) plans|(switch|change|upgrade) your plan|paid (users|accounts|members|customers|subscribers)|contact (our )?sales|go pro([^a-z]|$)|(go to|proceed to|complete) (the )?checkout|checkout (page|link|session)|purchase (a |an |the |this |your )?(plan|subscription|licen[cs]e|upgrade|tier|credits?)|which plan (you|they|the user|is|are)|plan details:|(see|view|compare) (other |our )?plans|^#+ *(plans|pricing|plans (and|&) pricing) *$|(有料|料金|上位|有償|課金|プレミアム)プラン|プラン(の詳細|一覧|変更|を変更)|有料(版|会員|機能)|プレミアム会員|アップグレード(してください|が必要|すると|して利用)|月額|無料トライアル|ご購入|購入はこちら|お支払い|ティア'
checked=(plugin.json mcp.json LICENSE .claude-plugin/plugin.json README.md SETUP.md)
while IFS= read -r f; do checked+=("$f"); done < <(find skills -type f | sort)
for f in "${checked[@]}"; do
  if grep -nHiE "$commerce_re" "$f"; then
    err "$f contains plan, pricing or upgrade wording"
  fi
done
[ "$fail" -ne 0 ] || echo "ok   packaged files, all skills, README and SETUP have no plan, pricing or upgrade wording"

# Public listing text must not state coverage counts or data status (owner rule
# 2026-10-13). server.json is imported by the MCP Registry and directories.
status_re='[0-9][0-9,]* of [0-9][0-9,]*|in progress|partial(ly)? (outside|coverage|data|set)|missing facts|remediation|recovery'
for f in server.json README.md; do
  if grep -niE "$status_re" "$f"; then
    err "$f contains a coverage count or data-status claim"
  fi
done
[ "$fail" -ne 0 ] || echo "ok   server.json and README have no coverage counts or status claims"

# Bilingual-label claims are unverified; keep them out of every public text.
label_re='bilingual|English and Japanese|英語と日本語|EN/JA'
claim_files=(plugin.json .claude-plugin/plugin.json server.json glama.json README.md SETUP.md)
while IFS= read -r f; do claim_files+=("$f"); done < <(find skills -type f | sort)
for f in "${claim_files[@]}"; do
  if grep -nHiE "$label_re" "$f"; then
    err "$f contains a bilingual-label claim"
  fi
done
[ "$fail" -ne 0 ] || echo "ok   no bilingual-label claims"

# jq counts characters, not bytes, so this works in any locale.
ja_len=$(jq "$oai.publication.translations[\"ja-JP\"].subtitle // \"\" | length" plugin.json)
[ "$ja_len" -le 30 ] || err "ja-JP subtitle is longer than 30 characters ($ja_len)"

# One version everywhere: Claude plugin, ChatGPT/Codex package, MCP Registry entry.
v_root=$(jq -r '.version // empty' plugin.json)
v_claude=$(jq -r '.version // empty' .claude-plugin/plugin.json)
v_server=$(jq -r '.version // empty' server.json)
if [ -z "$v_root" ] || [ -z "$v_claude" ] || [ -z "$v_server" ]; then
  err "version missing: plugin.json '$v_root', .claude-plugin/plugin.json '$v_claude', server.json '$v_server'"
elif [ "$v_root" = "$v_claude" ] && [ "$v_root" = "$v_server" ]; then
  echo "ok   version $v_root (plugin.json = .claude-plugin/plugin.json = server.json)"
else
  err "version mismatch: plugin.json $v_root, .claude-plugin/plugin.json $v_claude, server.json $v_server (all three must be identical)"
fi

# Release notes must describe this version.
release_notes=$(jq -r "$oai.publication.release_notes // empty" plugin.json)
case "$release_notes" in
  "Kabuken $v_root: "*) echo "ok   release_notes start with \"Kabuken $v_root:\"" ;;
  *) err "release_notes must start with \"Kabuken $v_root:\", found: ${release_notes:0:40}" ;;
esac

for s in skills/*/SKILL.md; do
  dir=$(basename "$(dirname "$s")")
  if [ "$(head -n 1 "$s")" != "---" ]; then
    err "$s: no YAML header"
    continue
  fi
  header=$(awk 'NR==1 {next} /^---$/ {exit} {print}' "$s")
  name=$(printf '%s\n' "$header" | sed -n 's/^name:[[:space:]]*//p')
  desc=$(printf '%s\n' "$header" | sed -n 's/^description:[[:space:]]*//p')
  [ -n "$name" ] || err "$s: missing name"
  [ -n "$desc" ] || err "$s: missing description"
  [ -z "$name" ] || [ "$name" = "$dir" ] || err "$s: name '$name' does not match directory '$dir'"
  [ "$fail" -ne 0 ] || echo "ok   skill $dir"
done

if [ "$fail" -ne 0 ]; then
  echo "Validation failed." >&2
  exit 1
fi
echo "Validation passed."
