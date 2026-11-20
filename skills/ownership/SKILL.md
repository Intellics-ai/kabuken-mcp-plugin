---
name: ownership
description: Show who owns a Japanese listed company and which shares it holds itself, with get_major_shareholders: large-shareholding reports, the top shareholders, shareholder categories and cross-shareholdings (policy holdings). Use for "major shareholders", "largest holders", "foreign ownership", "cross-shareholdings"; also for 「大株主」「大量保有報告書」「所有者別状況」「外国人持株比率」「政策保有株式」「持ち合い株」「特定投資株式」「みなし保有株式」.
---

# Ownership

Input: one company name, ticker or EDINET entity code, and the question.

## Tool calls in order

1. Resolve the company to an entity code with `search_companies` (`query`)
   or `get_company` (`id`, `id_type: "ticker"`). If several companies match,
   ask the user to pick one.
2. Call `get_major_shareholders` with `entity_code` and `include` set to the
   parts that answer the question:
   - `large_holdings` (the default): large-shareholding reports
     (大量保有報告書), newest first;
   - `top_holders`: the 大株主の状況 table of the latest annual report;
   - `holder_categories`: the 所有者別状況 table (owner categories);
   - `policy_holdings`: the 政策保有株式 tables (shares the company holds in
     other companies).
   For "who owns it", use `["top_holders", "large_holdings"]`. For
   cross-shareholdings, use `["policy_holdings"]`.
   For `large_holdings`, `view` selects the shape. `view: "reports"` (the
   default) lists every report row. `view: "latest_per_filer"` returns one row
   per filer under `large_holdings.holders`: the latest ratio, the ratio on
   that filer's previous report and `change_pt`, the change in percentage
   points. `below_threshold` marks a filer now under 5%. This view is not paged.
3. Leave `detail` at `summary` (the default). Use `detail: "full"` only when
   the user needs `doc_id` and `period_end` on every row.
4. If `next_cursor` is set and the user wants more rows, call again with
   `cursor` set to `next_cursor` and the same `entity_code`, `include`,
   `limit` and `detail`. Cursor pages return only the paged lists; read
   `top_holders` and `holder_categories` from the first page.

## Reading the parts

- `large_holdings`: `filer_name` (the holder), `ownership_pct` (percent),
  `shares_held` and `report_date`. Identical reports are merged into one row; `doc_ids` lists
  every source filing. An empty list means no such reports are on EDINET for
  this company.
- `top_holders`: rank, `holder_name` and `holder_address` as filed,
  `shares_held`, `shareholding_ratio` as a fraction (`0.1384` is 13.84%), and
  the total row.
- `holder_categories`: shareholder count, units held and ratio for the seven
  EDINET owner categories, per share class, with totals and
  `shares_less_than_one_unit`. A blank cell is `null`; a filed 0 is 0.
- `policy_holdings`: rows with `holding_type` `specified` (特定投資株式) or
  `deemed` (みなし保有株式), `issuer_name` as filed, `shares_held` and
  `book_value` for the `current` and `prior` year end, `holding_purpose`, and
  `issuer_holds_reporting_company_shares` (the filing's own answer).
  - `holder_scope` is `REPORTER` for the company's own holdings, and
    `LARGEST_HOLDING_COMPANY` or `SECOND_LARGEST_HOLDING_COMPANY` for the
    holdings of those subsidiaries. Do not add these to the company's own
    holdings. `scope_counts` gives `specified_count` and `deemed_count` per
    scope; the top-level counts are the totals.
  - Rows with `held_at_year_end: false` were no longer held at year end.
    Count held positions with `held_specified_count` and
    `held_deemed_count` in `scope_counts`. A row marked '＊' (below the
    disclosure threshold) still counts as held.
  - The part carries `returned`, `total` and `truncated`. A page holds at
    most 40 rows, even with a higher `limit`.
  - A figure filed in another context (for example the filing date) is in
    `other_context_facts`, not in `current` or `prior`.
- `units` names the unit of each figure. `book_value` carries its currency.
- `source_filing` names the annual report. `amended_by` names an amendment
  (訂正) only when it changed a returned part.

## Limits

- A year whose figures the filer replaced by '＊' (below the disclosure
  threshold) has `not_disclosed_below_threshold: true` and `null` figures.
  Say "below the disclosure threshold", not zero or missing.
- Names are as filed, line breaks included. The EDINET codes of holders and
  issuers are not resolved; do not match a name to a company without
  checking it with `search_companies`.
- Large-shareholding reports and the annual-report tables have different
  dates. Give the date of each figure.
- If the company has no annual report, the annual-report parts are `null`
  with a note. Say so.
- If a tool says a feature is not available for this account, tell the user
  that plainly and continue with the tools that work. Do not suggest plans,
  prices or links.
- Kabuken has no stock prices or market values and gives no investment
  advice. Do not value a holding at market price.
