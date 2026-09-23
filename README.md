# Kabuken MCP plugin

Kabuken is an MCP server that gives Claude and other MCP clients direct
access to Japanese statutory filings on EDINET. It returns individual XBRL
facts with bilingual (English/Japanese) taxonomy labels, calculation-linkbase
trees, and segment breakdowns, all traceable to the filing they came from —
not a flattened summary table.

**Coverage, as of 2026-09-21**: 99 of 99 currently-tracked TOPIX-100
constituents, 1,967 filings, fully extracted with zero missing facts on the
current read path. Coverage beyond this set is broader but partial, and
remediation is in progress. Kabuken has no stock prices or market data, and
no history before FY2025 — earlier years appear only as comparatives inside
2025+ filings.

Signup is required. A free BASIC tier is available; see [Tiers](#tiers)
below.

## Install

This plugin declares a remote MCP server in `.mcp.json`
(`https://kabuken.intellics.ai/mcp`, streamable HTTP). Enable the plugin,
then see [SETUP.md](./SETUP.md) or ask Claude "set up Kabuken" to
authenticate.

## Tools

16 read-only tools, grouped by purpose. None write or modify data.

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
- `get_account_quota` — caller's current daily quota usage, limit, and reset time; available to all tiers and does not itself consume quota

## Tiers

| Tier | Price | Daily call limit | Tool access |
|---|---|---|---|
| BASIC | Free | 50/day | 5 tools: `search_companies`, `get_company`, `list_industries`, `get_risk_context`, `get_account_quota` |
| INVESTOR | ¥1,980/month or ¥19,800/year | 500/day | All 16 tools |
| MCP DEVELOPER | ¥4,980/month | 1,000/day | All 16 tools |

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
