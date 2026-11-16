---
name: people-and-governance
description: Report the officers, officer pay, AGM candidates, board gender mix and human-capital metrics (female managers, male childcare leave, gender pay gap) of a Japanese listed company from its latest annual securities report, with get_company_financials include human_capital and officers. Use for "who are the directors", "CEO pay", "gender pay gap", "women in management"; also for 「役員一覧」「役員報酬」「個別開示の役員報酬」「取締役候補」「女性管理職比率」「男性育休取得率」「男女の賃金の差異」「人的資本」.
---

# People and governance

Input: one company name, ticker or EDINET entity code, and the question
(officers, officer pay, candidates, human capital, or all of them).

## Tool calls in order

1. Resolve the company to an entity code with `search_companies` (`query`)
   or `get_company` (`id`, `id_type: "ticker"`). If several companies match,
   ask the user to pick one.
2. Call `get_company_financials` with `entity_code` and `include` set to
   what the user asked for:
   - `["officers"]` for officers, pay and candidates;
   - `["human_capital"]` for 人的資本 metrics;
   - `["human_capital", "officers"]` for both.
   Leave `detail` at `summary` (the default). With only these sections in
   `include`, the response has no `periods` or `fiscal_years` block.
3. Use `detail: "full"` only when the user needs the concept, context, unit
   and period of each figure. It is several times larger.
4. Both sections come from the latest annual securities report. State its
   `doc_id` and `period_end`.

## Reading the summary shape

- The section carries `doc_id`, `period_end`, a `concepts` table and
  `concept_ids`. The officers section has `units` (for `remuneration`,
  `shares_held` and `head_counts`); the human-capital section has `unit` and
  `value_format`. Each block (the reporting company, a subsidiary row, an
  officer, a pay category, the board) carries `ctx`, its context.
- A figure is a plain number when it follows its block and section. If it
  differs, it is `{v, c, ctx, d}`: `v` is the value, `c` indexes `concepts`,
  `ctx` is its own context and `d` its own `doc_id`.
- `officers`, `candidates` and `consolidated_subsidiaries` are tables:
  `{columns, rows}`. `columns` names each position in a row. A blank cell is
  `null`.
- Blank cells are left out of keyed records. `labels` lists the keys that
  are present.

## Officers

- Each officer has `name_ja` and `title_ja` as filed, and `name_en` (from the
  XBRL label, or the member name split at capitals).
- `role` names the 役員の状況 table: `director_or_auditor` (取締役・監査役),
  `executive_officer` (執行役 of a company with a nomination committee) or
  `director_and_executive_officer` (both tables; listed once).
- `in_officer_table` is `true` for a person in office at the filing date.
  It is `false` for a person who is only in the individual pay table (paid
  in the year, no office at the filing date); `role` is then `null`. `total`
  counts the people in office once each; `paid_only_count` counts the
  others.
- `remuneration_total` is disclosed per person only for officers paid
  100 million yen or more. For others it is `null`: say "not disclosed
  individually", not zero. `shares_held` is `null` where the filing shows
  「－」.
- `candidates` (`name_ja`, `title_ja`, `term_ja`, `role`) are the officers
  expected after the annual general meeting, as filed. The list can include
  continuing officers who are not up for election, so do not report it as
  the number elected. Candidates are not in `total`.
- If `notes` say an officer's pay is filed in a prior-year context, state
  that the value is as filed and may be the current-year pay.
- `remuneration_by_category` gives per category (directors, outside
  directors, auditors and so on) `officer_count`, the filed `total` and the
  pay `components` (fixed, bonus, share awards and so on). A component can
  carry `persons`, the head count the filer tagged for that pay type.
  `unmatched_person_counts` holds tagged head counts that match no single
  component. Do not add up components yourself.
- `board_composition` gives the male and female officer counts and the
  female ratio.
- Terms of office, dates of birth and career summaries are not returned.

## Human capital

- `reporting_company` holds the filer's own figures.
  `consolidated_subsidiaries` holds one row per subsidiary row of the filing,
  numbered as in the filing, at most 100 rows. Each row carries `name`, the
  filed company name (`null` when the filer did not tag it);
  `subsidiaries_total` and `subsidiaries_truncated` say when there are more.
- `female_managers_ratio`: ratio of women in managerial positions.
- Male childcare leave, by the legal basis the filer used, each for all
  employees and with `_regular` and `_non_regular` suffixes:
  - `male_childcare_leave_ratio`: the rate under 育児・介護休業法施行規則
    第71条の6 第1号;
  - `male_childcare_and_childcare_purpose_leave_ratio`: the rate under
    育児・介護休業法施行規則 第71条の6 第2号, which also counts leave for
    childcare purposes;
  - `male_childcare_leave_ratio_womens_act`: the rate under the Act on the
    Promotion of Women's Active Engagement (女性活躍推進法).
  Name the basis when you quote a rate. Do not compare rates of different
  bases as if they were the same measure.
- Gender wage gap: `gender_wage_gap_all`, `gender_wage_gap_regular` and
  `gender_wage_gap_non_regular`.
- Ratios are fractions as filed: `0.04` is 4%. A filed `0` is `0`. A blank
  cell (「－」) is `null` or left out; say "not filed", not zero.
- `extension_metrics` and `reporting_company_extension_metrics` hold the
  filer's own concepts of the same families, apart from the standard keys.

## Limits

- Only the latest annual securities report is read. For earlier years, say
  that this tool returns the latest report only.
- When an amendment (訂正) blanks a cell, the blank replaces the original
  figure.
- If a tool says a feature is not available for this account, tell the user
  that plainly and continue with the tools that work. Do not suggest plans,
  prices or links.
- State the company, `doc_id` and period for every figure. Kabuken gives no
  investment advice.
