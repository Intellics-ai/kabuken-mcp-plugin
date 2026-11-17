# Kabuken: EDINET MCP server for Japanese stocks (Claude and ChatGPT)

[![mcptry](https://mcptry.com/badge/io.github.Intellics-ai/kabuken)](https://mcptry.com/servers/io.github.Intellics-ai/kabuken)

Kabuken is an MCP server for Japanese stocks (日本株) built on EDINET, Japan's
disclosure system. It gives Claude, ChatGPT, Cursor and other MCP clients the
financial statements, segment breakdowns and major shareholders of Japanese
listed companies, taken from their official filings, including the annual
securities reports (有価証券報告書). Each figure comes with the filing it was
taken from and the period it covers, so you can check it against the original
document.

Kabuken does not provide stock prices, market data or investment advice. It
answers questions about what a company reported. Connect your client to
`https://kabuken.intellics.ai/mcp` (Streamable HTTP). An account is required:
Claude and ChatGPT connect with OAuth sign-in, and other MCP clients can use an
API key. Kabuken returns individual XBRL facts with taxonomy labels and
calculation-linkbase trees.

Kabukenは、EDINETをもとにした日本株向けのMCPサーバーです。Claude、ChatGPTなどの
MCPクライアントから、日本の上場企業が提出した有価証券報告書などの財務諸表、
セグメント情報、大株主を取得できます。各数値には出典となる提出書類と対象期間を
示します。株価、市場データ、投資助言は提供しません。接続先は
`https://kabuken.intellics.ai/mcp` です。

EDINET MCP guide: [English](https://kabuken.intellics.ai/docs/en/edinet-mcp/) ·
[日本語](https://kabuken.intellics.ai/docs/ja/edinet-mcp/)

## What Kabuken provides

- **Source filing and period with each figure.** Each value names the
  EDINET filing it comes from and the period it covers, so you can check it
  against the original document.
- **Calculation trees.** `get_calculation_tree` returns the XBRL calculation
  linkbase of a filing as a tree, so you can see how a total breaks down into
  its components and their weights.
- **Segment breakdowns.** `get_segment_breakdown` returns business,
  geographic and consolidation-scope figures by dimension axis and member.
- **Ownership.** `get_major_shareholders` returns large-shareholding reports
  (大量保有報告書), and from the latest annual securities report the top
  shareholders (大株主の状況), the owner categories (所有者別状況) and the
  policy holdings (政策保有株式). See [Ownership](#ownership).
- **Officers and human capital.** `get_company_financials` returns the
  officers, officer pay, AGM candidates and 人的資本 metrics of the latest
  annual securities report. See [Include values](#include-values).
- **One fact at a time.** `get_financial_facts` finds one figure in a filing
  by keyword, or step by step from the filing outline down to the fact.
- **OAuth sign-in for Claude and ChatGPT.** Claude and ChatGPT connect with
  OAuth sign-in, with no API key to copy. MCP clients without OAuth can
  connect with an API key.
- **Skill pack.** This repository is a plugin for Claude Code and a plugin
  package for ChatGPT and Codex, with skills for common tasks (company
  snapshot, peer comparison, segment breakdown, finding a fact, people and
  governance, ownership).

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

## Update to the latest version

What changed in each release: [What's new](https://kabuken.intellics.ai/docs/en/whats-new/).

- **Tools and data, all clients.** The MCP server is hosted, so tool and
  data changes reach every client at once. No action is needed. Only the
  skills come from the plugin.
- **Claude (claude.ai, Cowork, Claude Code) from Anthropic's directory.** A
  new plugin version reaches your account when Anthropic publishes it.
  Claude Code downloads it at the next start; run `/reload-plugins` to load
  it in an open session.
- **Claude Code with a local clone (`claude --plugin-dir`).** Run `git pull`
  in the clone, then start a new session.
- **Claude Code without the plugin (`claude mcp add`).** No action is needed.
- **ChatGPT, plugin from the directory.** A new version replaces the old one
  when it is published. No action is needed.
- **ChatGPT, developer mode.** Do the steps in
  [ChatGPT (developer mode, beta)](#chatgpt-developer-mode-beta) again with
  the latest `kabuken-plugin.zip`.

## Tools

Read-only tools, grouped by purpose. None write or modify data.

**Company and industry discovery**
- `search_companies` — search Japanese listed companies by name (EN or JA, partial match)
- `get_company` — full company record by any identifier (entity code, ticker, name). With `include_sites: true`, it also returns a summary of the company's major facilities from its latest annual report: counts by country and by prefecture, with the source filing.
- `list_industries` — TSE industry classification taxonomy

**Filings**
- `list_documents` — EDINET filing list for a company, with submission dates, period coverage, and XBRL/PDF availability
- `get_filing_text` — narrative sections of an annual securities report (risk factors, management discussion) as filed, in Japanese, without AI processing

**Financial facts**
- `get_financial_facts` — structured XBRL facts for a single filing. Find one fact step by step: `outline: true` lists the sections, `section` with `outline: true` lists its headings (100 per page), `section` with `parent` returns the children with values (`context: "primary"` keeps only facts with no dimension member and not non-consolidated); every outline node has a `next` field with the arguments of the next call. `query` searches labels and concept names. Sections: `BalanceSheet`, `IncomeStatement`, `CashFlows`, `ChangesInEquity`, `ComprehensiveIncome`, `Notes`, `Other`, `CoverPage`, `Unclassified`; document-entity (`jpdei_cor`) facts are not returned
- `get_calculation_tree` — XBRL calculation linkbase as a tree (how totals decompose into components)
- `get_segment_breakdown` — segment/geography/consolidation-scope dimensional data, axis and member labels
- `get_company_financials` — headline figures and a fiscal-year series by default; full statements with `include: ["statements"]`; officers and human-capital metrics with `include: ["officers"]` and `["human_capital"]` (see [Include values](#include-values)); `detail: "summary"` (default) or `"full"`

**Comparison and screening**
- `compare_companies` — side-by-side financial matrix for 2-5 companies from their latest annual securities report
- `screen_companies` — filter companies by financial ratio (ROE, ROA, operating margin, current ratio, debt-to-equity); no price-based screens
- `get_industry_overview` — mean/median/count per ratio for an industry, plus top/bottom 3 companies

**Ownership and risk**
- `get_major_shareholders` — large-shareholding report (大量保有報告書) data: holder, percentage, shares, filing date; with `include`, also the top shareholders, owner categories and policy holdings of the latest annual securities report (see [Ownership](#ownership))
- `get_risk_context` — BOJ policy-rate sensitivity and METI export-control classification for a company

**AI-powered analysis**
- `get_document_summary` — AI-generated summary of a filing
- `analyze_document` — free-text Q&A grounded in a specific filing

**Data quality**
- `report_data_issue` — report a figure that looks wrong, with the filing it came from

**Account**
- `get_account_quota` — caller's current daily quota usage, limit, and reset time; does not itself consume quota

## Include values

`get_company_financials` takes `include`, a list of sections beyond the
headline figures. An explicit list replaces the default `["indicators"]`.

| Value | What it adds |
| --- | --- |
| `indicators` | The 主要な経営指標等の推移 figures per fiscal year (default) |
| `statements` | Income statement, balance sheet and cash flow per period |
| `omitted_concepts` | Statement concepts with no consolidated current-period value |
| `human_capital` | 人的資本 metrics of the latest annual report: female managers ratio; male childcare-leave ratio for all, regular and non-regular employees, by legal basis (`male_childcare_leave_ratio`, `male_childcare_and_childcare_purpose_leave_ratio`, `male_childcare_leave_ratio_womens_act`); gender wage gap. For the reporting company and each consolidated subsidiary row (up to 100 rows, with the filed company `name`) |
| `officers` | 役員 of the latest annual report: `name_ja`, `title_ja`, `role` (`director_or_auditor`, `executive_officer`, `director_and_executive_officer`), `in_officer_table`, individually disclosed pay and shares held; `total` and `paid_only_count`; AGM `candidates` (the officers expected after the AGM, as filed); pay by officer category with head counts (`unmatched_person_counts`); board gender composition |

`detail: "summary"` (default) keeps every figure and moves its source
(`doc_id`, concept, context) up to the section and block level; long lists
are tables (`columns`, `rows`). `detail: "full"` puts the source on every
figure and is several times larger. Ratios are fractions as filed (`0.04`
is 4%). A filed `0` is `0`; a blank cell is `null`.

## Ownership

`get_major_shareholders` takes `include`:

| Value | What it returns |
| --- | --- |
| `large_holdings` | Large-shareholding reports (大量保有報告書), newest first (default) |
| `top_holders` | 大株主の状況: rank, holder name and address as filed, shares held, shareholding ratio |
| `holder_categories` | 所有者別状況: shareholder count, units held and ratio for the seven EDINET owner categories, per share class |
| `policy_holdings` | 政策保有株式: 特定投資株式 and みなし保有株式 rows with issuer name, shares held and book value for the current and prior year end, holding purpose; `holder_scope` and `scope_counts` separate the company's own holdings from those of its largest holding subsidiaries |

`policy_holdings` pages at most 40 rows; send `next_cursor` back as
`cursor` for the next page. Cursor pages return only the paged lists, so read
`top_holders` and `holder_categories` from the first page. Rows with
`held_at_year_end: false` were no longer held at year end; `scope_counts`
gives `held_specified_count` and `held_deemed_count`. A year that the filer marked '＊' (below the
disclosure threshold) carries `not_disclosed_below_threshold: true` with
null figures. Names are as filed.

## Account

Get an account and a `kbk_` API key (or use OAuth) at
[kabuken.intellics.ai](https://kabuken.intellics.ai). See
[SETUP.md](./SETUP.md) for the connection walkthrough.

## Slash commands

- `/kabuken:company-snapshot <company>` — revenue, income, assets, equity, and risk context for one company
- `/kabuken:peer-comparison <company, company, ...>` — side-by-side financials for 2-5 companies
- `/kabuken:segment-breakdown <company>` — business/geographic segment breakdown for a filing

The `filing-text` skill loads when you ask for risk factors, management discussion or the original filing text; it reads them as filed with `get_filing_text`.

These skills load when the question matches (English or Japanese):

- `find-a-fact` — one line item, note figure or cover-page item of a filing, by keyword or step by step with `get_financial_facts`
- `people-and-governance` — officers, officer pay, AGM candidates, board gender mix and human-capital metrics with `get_company_financials`
- `ownership` — large-shareholding reports, top shareholders, owner categories and policy holdings with `get_major_shareholders`

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
from EDINET filings, not reported directly by EDINET. Text from
`get_filing_text` is reproduced verbatim from the filing; the filing company
holds the rights to its text. Output from
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
