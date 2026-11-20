---
name: analysis-models
description: Show how a Japanese listed company's ROE is built (DuPont 3-step decomposition) and how far net income is backed by operating cash flow (Sloan-style cash-flow accrual ratio) with get_company_financials, per fiscal year, with every input and its source filing. Use for "DuPont", "how is ROE built", "ROE breakdown", "accruals", "earnings quality", "net income vs cash flow"; also for 「デュポン分解」「ROEの分解」「ROEの内訳」「アクルーアル」「発生高」「利益の質」「営業キャッシュフローと純利益」.
---

# Analysis models: DuPont and cash-flow accruals

Input: one company name, ticker or EDINET entity code, and optionally the
number of fiscal years.

## Tool calls in order

1. Resolve the company to an entity code with `search_companies` (`query`)
   or `get_company` (`id`, `id_type: "ticker"`). If several companies match,
   ask the user to pick one.
2. Call `get_company_financials` with `entity_code` and
   `include: ["indicators", "dupont", "sloan"]`. Set `periods` (the number
   of periods) and `period_type` (`ANNUAL`, `INTERIM` or `ALL`) when the
   user wants more than the latest year.
3. Read `analysis_models.dupont` and `analysis_models.sloan` in each entry of
   `periods`. Every entry carries its own `doc_id` and `fiscal_year_end`.
   The ratios sit under `components`: `components.net_margin`,
   `asset_turnover`, `equity_multiplier` and `roe` for DuPont;
   `total_accruals`, `average_total_assets` and `accrual_ratio` for Sloan.
   Each component has `value`, `formula`, `omission_reason` and
   `missing_inputs`.

## Present the result

Give one row per fiscal year, each with its `doc_id` and fiscal year end.

- DuPont 3-step decomposition: `net_margin` (net income / revenue),
  `asset_turnover` (revenue / average total assets), `equity_multiplier`
  (average total assets / average equity). Their product is `roe`
  (net income / average equity).
- Sloan-style cash-flow accrual ratio: `total_accruals` (net income minus
  operating cash flow), `average_total_assets` and `accrual_ratio`, which is
  (net income - operating cash flow) / average total assets. A positive
  value means net income was larger than operating cash flow in that year.
  The ratio does not say why. Name the reason only when a filing figure shows it.
- Show the inputs (net income, revenue, total assets, equity, operating cash
  flow) next to the ratios, with the opening and closing balances.
- Ratios are fractions (`0.1047` is 10.47%).

## Reading the fields

- `averaging` says how each balance was averaged. `average_opening_closing`
  uses the mean of the opening and closing balance. `closing_only` means the
  opening balance was not available and the closing balance alone was used.
  Say so, because a closing-only figure is a different measure.
- `dupont.reported_roe` is the ROE the company reports.
  `dupont.components.difference_vs_reported` is the computed ROE minus the
  reported ROE. Show both. A difference does not mean either figure is wrong;
  the company may use another definition or averaging.
- A component with `value: null` has an `omission_reason`:
  - `input_missing`: `missing_inputs` names the inputs the filing did not
    provide. List them. Do not estimate.
  - `non_positive_denominator`: a balance was zero or negative, so the ratio
    is not computed. Say so.
- `notes` lists reading cautions for that year (for example a large balance
  movement, a ROE above 200%, or net income that includes non-controlling
  interests against owners' equity). Repeat each note in plain words.

## Not applicable

`applicability` is not `applicable` for banks, insurers and other statement
formats with a different balance sheet structure
(`not_applicable_to_statement_format`), and for interim filings
(`annual_filing_required`). For such a filing each component's
`omission_reason` equals `applicability`. Tell the user the model does not apply to that
filing and why. Do not compute it by hand.

## Attribution

- The DuPont idea of splitting return into margin and turnover is credited to
  Donaldson Brown of DuPont (1914) and has two factors. The 3-step ROE form
  with the equity multiplier is the textbook extension.
- Sloan (1996) measured accruals from balance sheet changes. The ratio here
  is a Sloan-style cash-flow accrual ratio: (net income - operating cash flow)
  / average total assets.

## Limits

- Net income is profit attributable to owners of the parent; equity is
  owners' equity.
- Both models split reported figures. They are descriptive, not forecasts.
  Do not label a company or a ratio good, bad, high-quality or low-quality.
  Compare companies only under the same accounting standard.
- To check one input, call `get_financial_facts` with the `doc_id` of that
  year.
- If a tool says a feature is not available for this account, tell the user
  that plainly and continue with the tools that work. Do not suggest plans,
  prices or links.
- Kabuken has no stock prices and gives no investment advice. Data is
  shown for information, not as investment advice.
- Guide: https://kabuken.intellics.ai/docs/en/guide/analysis-models/
  (日本語: https://kabuken.intellics.ai/docs/ja/guide/analysis-models/)
