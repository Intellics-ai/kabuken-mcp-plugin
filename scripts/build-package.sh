#!/usr/bin/env bash
# Build the ChatGPT/Codex plugin ZIP (Agent Plugins format).
# Output: dist/kabuken-plugin-<version>.zip and dist/kabuken-plugin.zip
# plugin.json is at the ZIP root.
#
# Not packaged:
#   .claude-plugin/, .mcp.json   Claude Code files. OpenAI reads mcp.json;
#                                .mcp.json uses Claude's "type": "http".
#   skills/kabuken-setup/        Claude Code setup steps (/mcp, claude mcp add).
#   README.md                    GitHub page only; it lists plan prices, which
#                                OpenAI does not allow in listing context.
#   server.json, SETUP.md, .github/, scripts/
set -euo pipefail

cd "$(dirname "$0")/.."
command -v zip >/dev/null || { echo "ERROR: zip is not installed" >&2; exit 1; }
command -v jq >/dev/null || { echo "ERROR: jq is not installed" >&2; exit 1; }

version=$(jq -r '.version' plugin.json)
out=dist
stage="$out/stage"
rm -rf "$out"
mkdir -p "$stage"

cp plugin.json mcp.json LICENSE "$stage/"
cp -R assets "$stage/assets"
mkdir -p "$stage/skills"
for d in skills/*/; do
  name=$(basename "$d")
  [ "$name" = "kabuken-setup" ] && continue
  cp -R "$d" "$stage/skills/$name"
done
find "$stage" -name '.DS_Store' -delete

while IFS= read -r p; do
  [ -e "$stage/$p" ] || { echo "ERROR: $p is referenced in plugin.json but not packaged" >&2; exit 1; }
done < <(jq -r '.. | strings | select(startswith("./"))' plugin.json)

if [ -n "$(find "$stage" -iname 'README*' -print -quit)" ]; then
  echo "ERROR: a README file is staged; it must not be packaged" >&2
  exit 1
fi

zipfile="kabuken-plugin-$version.zip"
(cd "$stage" && TZ=UTC find . -exec touch -t 202601010000 {} + && zip -X -r -q "../$zipfile" .)
cp "$out/$zipfile" "$out/kabuken-plugin.zip"
rm -rf "$stage"

echo "Built $out/$zipfile and $out/kabuken-plugin.zip"
