---
name: company-snapshot
description: Build a financial snapshot of one Japanese listed company from its EDINET filings using Kabuken tools.
disable-model-invocation: true
---

# Company snapshot

Input: one company name, ticker, or EDINET entity code, given by the user
(in Claude Code, the command argument).

1. Resolve the company to an EDINET entity code (for example `E02144`):
   - name: call `search_companies` with `query`; matches are in
     `companies`. If several companies match, ask the user to pick one before continuing;
   - ticker: call `get_company` with `id` and `id_type: "ticker"`;
   - entity code: call `get_company` with `id` (`id_type` defaults to
     `entity_code`).
2. Call `get_company_financials` with `entity_code` (optional
   `period_type`: `ANNUAL` default, `INTERIM` or `ALL`; optional `periods`,
   default 3). If a tool says a feature is not available for this account,
   tell the user that plainly and continue with the tools that work. Do
   not suggest plans, prices or links. Do not guess figures.
3. Call `get_risk_context` with `entity_code` for BOJ rate-sensitivity and
   METI export-control notes.
4. Present a short snapshot: company name, industry, and for the
   latest period revenue, operating income, net income, total assets and
   equity, plus any risk-context notes. State the period and source filing
   for every figure.
5. If the user asks where the company has facilities, call `get_company`
   with `id` and `include_sites: true`. It returns counts of major
   facilities by country and by prefecture from the latest annual report,
   with the source filing. The counts are rows of the facilities tables,
   not size or value.
6. If the user asks about risks, outlook or the business, follow the
   `filing-text` skill (`get_filing_text`) and quote the filed text.
7. Do not add a stock price, market cap or P/E. Kabuken has no price data.
