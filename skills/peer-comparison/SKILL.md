---
name: peer-comparison
description: Compare 2-5 Japanese listed companies side by side from their latest annual reports using Kabuken tools.
disable-model-invocation: true
---

# Peer comparison

Input: 2 to 5 company names, tickers, or EDINET entity codes, separated by
commas, given by the user (in Claude Code, the command argument).

1. Split the input into individual companies. If there are fewer than 2 or
   more than 5, ask the user to adjust before continuing.
2. Resolve each company to an EDINET entity code (for example `E02144`):
   `search_companies` with `query` for a name, or `get_company` with `id`
   and `id_type: "ticker"` for a ticker. Ask the user if a name is
   ambiguous.
3. Call `compare_companies` with `entity_codes` set to the list of entity
   codes (not names or tickers). It returns revenue, net income, total
   assets, equity, operating income and the period-end date from each
   company's latest annual securities report (有価証券報告書).
4. If a tool says it is available on other plans, tell the user which plan
   it needs and share https://kabuken.intellics.ai/pricing as plan details,
   then stop. Do not approximate the comparison from other tools.
5. Present a table, one row per metric and one column per company. Show the
   period-end date for each company, because fiscal year-ends can differ.
   If a metric is null, show its `omission_reason` instead of a number.
6. Do not rank companies by a price-based metric (P/E, market cap, dividend
   yield). Kabuken has no price data.
