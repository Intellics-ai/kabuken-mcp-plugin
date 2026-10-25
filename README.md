# Kabuken — EDINET MCP server for Claude and ChatGPT

Kabuken is an EDINET MCP server. It gives Claude, ChatGPT and other MCP
clients the financial statements, segment breakdowns and major shareholders
of Japanese listed companies, taken from their official EDINET filings. Each
figure comes with its source filing and its period. Connect your client to
`https://kabuken.intellics.ai/mcp`. Kabuken returns individual XBRL facts
with English and Japanese taxonomy labels and calculation-linkbase trees.
Kabuken does not provide stock prices or investment advice.

KabukenはEDINET MCPサーバーです。Claude、ChatGPTなどのMCPクライアントから、
日本の上場企業がEDINETに提出した書類の財務諸表、セグメント情報、大株主を
取得できます。各数値には出典となる提出書類と対象期間を示します。接続先は
`https://kabuken.intellics.ai/mcp` です。株価や投資助言は提供しません。

EDINET MCP guide: [English](https://kabuken.intellics.ai/docs/en/edinet-mcp/) ·
[日本語](https://kabuken.intellics.ai/docs/ja/edinet-mcp/)

Signup is required. Get an account and a `kbk_` API key (or use OAuth) at
[kabuken.intellics.ai](https://kabuken.intellics.ai).

## What Kabuken provides

- **Source filing and period with each figure.** Each value names the
  EDINET filing it comes from and the period it covers, so you can check it
  against the original document.
- **Calculation trees.** `get_calculation_tree` returns the XBRL calculation
  linkbase of a filing as a tree, so you can see how a total breaks down into
  its components and their weights.
- **Segment breakdowns.** `get_segment_breakdown` returns business,
  geographic and consolidation-scope figures by dimension axis and member.
- **Major shareholders.** `get_major_shareholders` returns holders, holding
  ratios and reporting dates from large-shareholding reports (大量保有報告書).
- **OAuth sign-in for Claude and ChatGPT.** Claude and ChatGPT connect with
  OAuth sign-in, with no API key to copy. MCP clients without OAuth can
  connect with an API key.
- **Skill pack.** This repository is a plugin for Claude Code and a plugin
  package for ChatGPT and Codex, with skills for common tasks (company
  snapshot, peer comparison, segment breakdown).

## Install

This plugin declares a remote MCP server in `.mcp.json`
(`https://kabuken.intellics.ai/mcp`, streamable HTTP). Enable the plugin,
then see [SETUP.md](./SETUP.md) or ask Claude "set up Kabuken" to
authenticate.

Claude Code without the plugin:

```
claude mcp add --transport http kabuken https://kabuken.intellics.ai/mcp
```

### ChatGPT (developer mode, beta)

1. Download the latest plugin package:
   [kabuken-plugin.zip](https://github.com/Intellics-ai/kabuken-mcp-plugin/releases/latest/download/kabuken-plugin.zip).
2. Open [chatgpt.com/plugins](https://chatgpt.com/plugins), select **+**, then
   **Create custom MCP server**.
3. Upload the ZIP.
4. Sign in with Google when ChatGPT asks you to connect Kabuken.

The same repository is also an Agent Plugins package for ChatGPT and
Codex: `plugin.json` and `mcp.json` at the root. Claude Code reads
`.claude-plugin/plugin.json` and `.mcp.json`. See
[Plugin package](#plugin-package).

## Tools

Read-only tools, grouped by purpose. None write or modify data.

**Company and industry discovery**
- `search_companies` — search Japanese listed companies by name (EN or JA, partial match)
- `get_company` — full company record by any identifier (entity code, ticker, name)
- `list_industries` — TSE industry classification taxonomy (bilingual)

**Filings**
- `list_documents` — EDINET filing list for a company, with submission dates, period coverage, and XBRL/PDF availability

**Financial facts**
- `get_financial_facts` — structured XBRL facts for a single filing, bilingual labels
- `get_calculation_tree` — XBRL calculation linkbase as a tree (how totals decompose into components)
- `get_segment_breakdown` — segment/geography/consolidation-scope dimensional data, bilingual axis and member labels
- `get_company_financials` — multi-period income statement, balance sheet, and cash flow, grouped by statement type

**Comparison and screening**
- `compare_companies` — side-by-side financial matrix for 2-5 companies from their latest annual securities report
- `screen_companies` — filter companies by financial ratio (ROE, ROA, operating margin, current ratio, debt-to-equity); no price-based screens
- `get_industry_overview` — mean/median/count per ratio for an industry, plus top/bottom 3 companies

**Ownership and risk**
- `get_major_shareholders` — large-shareholding report (大量保有報告書) data: holder, percentage, shares, filing date
- `get_risk_context` — BOJ policy-rate sensitivity and METI export-control classification for a company

**AI-powered analysis**
- `get_document_summary` — AI-generated summary of a filing
- `analyze_document` — free-text Q&A grounded in a specific filing

**Account**
- `get_account_quota` — caller's current daily quota usage, limit, and reset time; does not itself consume quota

## Account

Get an account and a `kbk_` API key (or use OAuth) at
[kabuken.intellics.ai](https://kabuken.intellics.ai). See
[SETUP.md](./SETUP.md) for the connection walkthrough.

## Slash commands

- `/kabuken:company-snapshot <company>` — revenue, income, assets, equity, and risk context for one company
- `/kabuken:peer-comparison <company, company, ...>` — side-by-side financials for 2-5 companies
- `/kabuken:segment-breakdown <company>` — business/geographic segment breakdown for a filing

## Attribution

EDINET content (filings, facts, dimensions) is used under Japan's Public
Data License 1.0 (PDL 1.0):

> Source: EDINET (https://disclosure2.edinet-fsa.go.jp/), PDL 1.0
> (https://www.digital.go.jp/resources/open_data/public_data_license_v1.0).
> Data is processed by Kabuken, not raw unprocessed FSA data.

The EDINET Taxonomy (concept labels, calculation-linkbase relationships,
dimension axis/member labels) is excluded from PDL 1.0 and separately
licensed under the FSA EDINET Taxonomy Legal Statement
(https://www.fsa.go.jp/search/EDINET_Taxonomy_Legal_Statement.html), which
requires the notice "© Copyright 2014 Financial Services Agency, The
Japanese Government" on redistribution. Tools that surface taxonomy content
(`get_calculation_tree`, `get_segment_breakdown`) carry this notice.

Figures returned by `screen_companies`, `get_industry_overview`,
`compare_companies`, and `get_company_financials` are calculated by Kabuken
from EDINET filings, not reported directly by EDINET. Output from
`analyze_document` is AI-generated and may contain errors; it is not
investment advice.

## Privacy policy

https://kabuken.intellics.ai/privacy

## Documentation

https://kabuken.intellics.ai/docs

## Plugin package

`scripts/build-package.sh` builds `dist/kabuken-plugin-<version>.zip` with
`plugin.json` at the ZIP root, plus `mcp.json`, `skills/` (without the
Claude Code-only `kabuken-setup` skill), `assets/` and `LICENSE`.
`README.md` is not packaged. `scripts/validate-package.sh` checks the
manifests, skills, README and SETUP.md, and `scripts/tests/run-tests.sh` tests those
checks.
The `Plugin package` workflow runs both on every pull request and push to
`main`, and attaches the ZIP to a GitHub release when a `v*` tag is pushed.
The tag must match the `version` in `plugin.json`.

## Versioning

One version number covers the Claude plugin (`.claude-plugin/plugin.json`),
the ChatGPT/Codex package (`plugin.json`) and the MCP Registry entry
(`server.json`). `scripts/validate-package.sh` fails if the three differ.
To release: bump all three to the same `X.Y.Z`, merge to `main`, push tag
`vX.Y.Z`, then run the **Publish to MCP Registry** workflow manually from
that tag. The workflow refuses to publish unless tag `v<server.json version>`
is on the checked-out commit.

## Registry manifest

`server.json` describes the hosted Kabuken MCP server (`https://kabuken.intellics.ai/mcp`)
in the [official MCP registry](https://registry.modelcontextprotocol.io) format and is
published from this repo under the `io.github.intellics-ai/kabuken` namespace. The server's
own source runs in a separate, private repository; this public repo is the registry's
companion listing and the home for the plugin package documented above. Publishing runs via
`.github/workflows/publish-registry.yml` (manual `workflow_dispatch`, GitHub OIDC
authentication, no stored secrets).
