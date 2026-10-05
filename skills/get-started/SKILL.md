---
name: get-started
description: Look up a Japanese listed company in Kabuken and get figures from its official EDINET filings. Use when the user first asks about a Japanese company's financials, filings or segments.
---

# Get started with Kabuken

1. Call `search_companies` with `query` set to the company name (English or
   Japanese). Note the company's EDINET entity code (for example `E02144`
   for Toyota). If several companies match, ask the user to pick one.
2. Call `get_company_financials` with `entity_code` for revenue, profit,
   assets, equity and cash flow from recent annual reports.
3. For other questions, use the entity code with:
   - `list_documents` (`entity_code`) to find a filing and its `doc_id`;
   - `get_segment_breakdown` (`doc_id`) for figures by segment or region;
   - `compare_companies` (`entity_codes`, 2 to 5 codes) for peers.
4. State the period and the source filing for every figure.
5. Kabuken has no stock prices and gives no investment advice. Do not add
   a price, market cap or valuation ratio.
6. If a tool returns an upgrade message, tell the user that their account
   does not include that tool. Do not estimate the figure.
