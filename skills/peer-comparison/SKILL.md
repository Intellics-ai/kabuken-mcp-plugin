---
description: Compare 2-5 Japanese listed companies side by side using Kabuken MCP tools.
disable-model-invocation: true
---

# Peer comparison

Argument: 2 to 5 company names, tickers, or EDINET entity codes, separated
by commas — "$ARGUMENTS".

1. Split "$ARGUMENTS" into individual company references. If there are
   fewer than 2 or more than 5, ask the user to adjust before continuing.
2. Resolve each ambiguous reference with `search_companies` or `get_company`
   before calling the comparison tool.
3. Call `compare_companies` with the resolved companies. It returns a
   side-by-side matrix from each company's latest annual securities report:
   revenue, net income, total assets, equity, operating income, and the
   period-end date.
4. If the account is BASIC tier and the call is rejected with an upgrade
   message, say so plainly and stop rather than approximating the
   comparison from other tools.
5. Present the result as a table, one row per metric, one column per
   company, with the period-end date shown for each company since fiscal
   year-ends can differ across the set.
6. Do not rank companies by a price-based metric (P/E, market cap,
   dividend yield) — Kabuken has no price data. Stick to the fundamentals
   the tool actually returns.
