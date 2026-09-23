---
description: Build a financial snapshot of one Japanese listed company using Kabuken MCP tools.
disable-model-invocation: true
---

# Company snapshot

Argument: a company name, ticker, or EDINET entity code — "$ARGUMENTS".

1. Call `get_company` to resolve "$ARGUMENTS" to a company record. If the
   name is ambiguous, call `search_companies` first and ask the user to
   pick one before continuing.
2. Call `get_company_financials` for that company to get multi-period
   income statement, balance sheet, and cash flow figures. If the account
   is BASIC tier and this call is rejected with an upgrade message, say so
   plainly and stop rather than guessing at figures.
3. Call `get_risk_context` for the same company to surface any BOJ
   rate-sensitivity or METI export-control notes.
4. Present a short snapshot: company name (EN/JA), industry, latest period
   revenue, operating income, net income, total assets, and equity, plus
   any risk-context notes. State the filing period and EDINET source for
   every figure — never present a number without its period and source.
5. Do not add a stock price, market cap, or P/E figure — Kabuken has no
   price data.
