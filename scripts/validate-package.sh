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
listing=$(jq -r '.description, (.extensions["com.openai"] | .interface, .review, .publication | .. | strings)' plugin.json)
if printf '%s\n' "$listing" | grep -nE '\$[0-9]|[0-9]+(\.[0-9]+)? ?(USD|JPY)|¥|￥|円'; then
  err "plugin.json listing text contains a price"
fi
if printf '%s\n' "$listing" | grep -nwE 'BASIC|INVESTOR|DEVELOPER'; then
  err "plugin.json listing text contains a plan name (BASIC/INVESTOR/DEVELOPER)"
fi
[ "$fail" -ne 0 ] || echo "ok   listing text has no prices or plan names"

# jq counts characters, not bytes, so this works in any locale.
ja_len=$(jq "$oai.publication.translations[\"ja-JP\"].subtitle // \"\" | length" plugin.json)
[ "$ja_len" -le 30 ] || err "ja-JP subtitle is longer than 30 characters ($ja_len)"

v_root=$(jq -r '.version' plugin.json)
v_claude=$(jq -r '.version' .claude-plugin/plugin.json)
if [ "$v_root" = "$v_claude" ]; then
  echo "ok   version $v_root (plugin.json = .claude-plugin/plugin.json)"
else
  err "version mismatch: plugin.json $v_root, .claude-plugin/plugin.json $v_claude"
fi

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
