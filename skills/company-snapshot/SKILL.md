---
name: company-snapshot
description: Build a financial snapshot of one Japanese listed company from its EDINET filings using Kabuken tools.
disable-model-invocation: true
---

# Company snapshot

Input: one company name, ticker, or EDINET entity code, given by the user
(in Claude Code, the command argument).

1. Resolve the company to an EDINET entity code (for example `E02144`):
   - name: call `search_companies` with `query`. If several companies
     match, ask the user to pick one before continuing;
   - ticker: call `get_company` with `id` and `id_type: "ticker"`;
   - entity code: call `get_company` with `id` (`id_type` defaults to
     `entity_code`).
2. Call `get_company_financials` with `entity_code` (optional
   `period_type`: `ANNUAL` default, `INTERIM` or `ALL`; optional `periods`,
   default 3). If the call returns an upgrade message, say so plainly and
   stop. Do not guess figures.
3. Call `get_risk_context` with `entity_code` for BOJ rate-sensitivity and
   METI export-control notes.
4. Present a short snapshot: company name (EN/JA), industry, and for the
   latest period revenue, operating income, net income, total assets and
   equity, plus any risk-context notes. State the period and source filing
   for every figure.
5. Do not add a stock price, market cap or P/E. Kabuken has no price data.
