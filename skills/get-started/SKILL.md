---
name: get-started
description: Look up a Japanese listed company in Kabuken and get figures from its official EDINET filings. Use when the user first asks about a Japanese company's financials, filings or segments.
---

# Get started with Kabuken

1. Call `search_companies` with `query` set to the company name (English or
   Japanese). Matches are in `companies`. Note the company's EDINET entity
   code (`company_entity_code`, for example `E02144` for Toyota). If
   several companies match, ask the user to pick one.
2. Call `get_company_financials` with `entity_code` for revenue, profit,
   assets and equity from recent annual reports. For cash flow or full
   statements, also pass `include: ["statements"]`.
3. For other questions, use the entity code with:
   - `list_documents` (`entity_code`) to find a filing and its `doc_id`
     in `documents`;
   - `get_segment_breakdown` (`doc_id`) for figures by segment or region;
   - `compare_companies` (`entity_codes`, 2 to 5 codes) for peers;
   - `get_company` (`id`, `include_sites: true`) for a summary of the
     company's major facilities from its latest annual report: counts by
     country and by prefecture, with the source filing;
   - `get_filing_text` (`entity_code` or `doc_id`) to read the risk factors
     (`business_risks`) or management discussion (`md_and_a`) of an annual
     report as filed (see the `filing-text` skill). It returns the filer's
     own Japanese text, not a summary.
4. State the period and the source filing for every figure.
5. Kabuken has no stock prices and gives no investment advice. Do not add
   a price, market cap or valuation ratio.
6. If a tool says a feature is not available for this account, tell the
   user that plainly and continue with the tools that work. Do not suggest
   plans, prices or links. Do not estimate the figure.
