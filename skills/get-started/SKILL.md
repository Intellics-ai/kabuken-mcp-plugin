---
name: get-started
description: Look up a Japanese listed company in Kabuken and get figures from its official EDINET filings. Use when the user first asks about a Japanese company's financials, filings or segments.
---

# Get started with Kabuken

1. Call `search_companies` with `query` set to the company name (English or
   Japanese). Matches are in `companies`. Note the company's EDINET entity
   code (`company_entity_code`, for example `E02144` for Toyota). If
   several companies match, ask the user to pick one.
   Before calling a data tool for a company, check
   `available_on_this_account` in the `search_companies` result; if it
   is false, choose another company, or read the refusal's `message`,
   which may list available companies in the same industry.
2. Call `get_company_financials` with `entity_code` for revenue, profit,
   assets and equity from recent annual reports. For cash flow or full
   statements, also pass `include: ["statements"]`.
3. For other questions, use the entity code with:
   - `list_documents` (`entity_code`) to find a filing and its `doc_id`
     in `documents`. The list also has PDF-only filings, such as amended
     shelf registrations (訂正発行登録書), with `doc_xbrl_flag: false`;
     no financial figures are taken from them;
   - `get_segment_breakdown` (`doc_id`) for figures by segment or region;
   - `compare_companies` (`entity_codes`, 2 to 5 codes) for peers;
   - `get_company` (`id`, `include_sites: true`) for a summary of the
     company's major facilities from its latest annual report: counts by
     country and by prefecture, with the source filing. Add
     `sites_detail: true` for one row per listed facility, paged with
     `sites_limit` and `sites_offset`. A row with `is_group: true` stands
     for several sites (a store group such as 「他19店舗」, a region, or a
     head office with a count of branches), not one place;
   - `get_filing_text` (`entity_code` or `doc_id`) to read the risk factors
     (`business_risks`) or management discussion (`md_and_a`) of an annual
     report as filed (see the `filing-text` skill). It returns the filer's
     own Japanese text, not a summary;
   - `get_financial_facts` (`doc_id`) for one line item or note figure of a
     filing, by keyword (`query`) or step by step (`outline`, `section`,
     `parent`); see the `find-a-fact` skill;
   - `get_company_financials` with `include: ["officers"]` or
     `["human_capital"]` for officers, officer pay, AGM candidates and
     人的資本 metrics; see the `people-and-governance` skill;
   - `get_major_shareholders` (`entity_code`, optional `include`) for
     large-shareholding reports, the top shareholders, owner categories and
     policy holdings; see the `ownership` skill.
4. State the period and the source filing for every figure.
5. Kabuken has no stock prices and gives no investment advice. Do not add
   a price, market cap or valuation ratio.
6. If a tool says a feature is not available for this account, tell the
   user that plainly and continue with the tools that work. Do not suggest
   plans, prices or links. Do not estimate the figure.
