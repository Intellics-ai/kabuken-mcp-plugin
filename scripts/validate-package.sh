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
