---
name: find-a-fact
description: Find one figure in a single EDINET filing of a Japanese company with get_financial_facts, step by step (outline, section, parent) or by keyword (query). Use when the user asks for a specific line item, a note figure, a cover-page item or "where is X in the filing"; also for 「有報の〇〇の数字」「注記の金額」「この勘定科目はどこ」「XBRLのタグ」「有報の〇〇はいくら」「XBRLで〇〇を探して」.
---

# Find a fact in one filing

Input: a company (name, ticker or EDINET entity code) or a filing `doc_id`,
and the item the user wants (for example "lease liabilities", 「退職給付債務」,
"number of employees").

## 1. Pick the filing

1. If the user gave a `doc_id`, use it.
2. Otherwise resolve the company with `search_companies` (`query`) or
   `get_company` (`id`, `id_type: "ticker"`). If several companies match,
   ask the user to pick one.
3. Call `list_documents` with `entity_code`. Pick the filing for the period
   the user named, or the most recent annual securities report
   (有価証券報告書). Note its `doc_id`.

## 2. Try a keyword first

Call `get_financial_facts` with `doc_id` and `query` (up to 100 characters,
case-insensitive). It matches the English label, the Japanese label and the
concept name across the whole filing. Use the term in the language of the
filing labels when you can, for example `query: "退職給付"` or
`query: "Lease"`.

- Add `section` (or `statement_type`) to keep the search inside one section.
- If `next_cursor` is set and the item is not on the page, call again with
  `cursor` set to `next_cursor` and the same `doc_id`, `query`, filters and
  `limit`.
- For document and entity information (EDINET code, filer name, fiscal
  year), use `get_company` or `list_documents`; `get_financial_facts` does
  not return `jpdei_cor` facts in any mode. Other cover-page items are in the
  `CoverPage` section and `query` finds them.

If the keyword finds nothing, or many facts with similar labels, descend.

## 3. Descend one level per call

Every node in an outline response has a `next` field. It holds the exact
changing arguments of the next call. Send it together with the `doc_id` and
`section` of the response. Do not invent values for `section` or `parent`.

1. Sections: call `get_financial_facts` with `doc_id` and `outline: true`.
   Each section has `fact_count`, `concept_count` and `next`. The sections
   can be `BalanceSheet`, `IncomeStatement`, `CashFlows`, `ChangesInEquity`,
   `ComprehensiveIncome`, `Notes`, `Other`, `CoverPage` and
   `Unclassified` (facts without a section). Most note figures are in
   `Notes`; many non-financial items (employees, governance) are in `Other`.
2. Headings: call with `doc_id`, `section` and `outline: true`. You get the
   top-level headings of that section, up to 100 per page, each with
   `child_count` and `next`. If `next_cursor` is set, call again with the
   same `doc_id`, `section`, `outline: true` and `cursor` set to
   `next_cursor` to read the next page.
3. Children: call with `doc_id`, `section` and `parent`. `parent` takes the
   value from a `next` field, or a concept name written `prefix:Name` (for
   example `jppfs_cor:Liabilities`). You get the direct children of that
   heading, with values. A child with `has_children: true` has its own
   `next`; repeat this step until you reach the fact.
   With `section` and `parent`, read `total` and `context_counts`. Send
   `context: "primary"` to keep only facts with no dimension member and not
   `NonConsolidatedMember`; it still includes prior periods and
   `FilingDateInstant` facts. Segment, non-consolidated and equity-component
   facts stay available with `context: "all"`. `concepts` cannot be combined
   with `parent`.
   Outline heading `concept` values are in the `prefix:Name` form. Send
   `next` as returned.
4. A node that is a fact and also has children carries `own_facts_next`.
   Use it to read the values of that node itself.

Outline calls return no values and stay small. Each step is one call.

## 4. Read and present the fact

- Each fact has `fact_name` (the concept), `label_en`, `label_ja`, the
  value, the unit, the decimals, `period_start`, `period_end` or
  `period_instant`, and `context_ref` (its name shows the period,
  `NonConsolidatedMember` and any dimension member). One concept can appear in several
  contexts: pick the one that matches the period and scope the user asked
  for, and say which one you used.
- When two facts share a standard label, they also carry
  `label_en_verbose` and `label_ja_verbose`. Use those to tell them apart.
- State the company, the `doc_id`, the period and the context for every
  figure. Keep the EDINET attribution notice the tool returns.

## Limits

- A heading with no fact of its own gets a label derived from its concept
  name. Such a node (and the `parent_label` of its children) carries
  `label_source: "derived_from_concept_name"`; `label_note` explains it.
  Call it a derived heading, not a filed label.
- A cursor from an earlier response is valid only with the same `doc_id`,
  filters and `limit`.
- For a breakdown by segment or region, use `get_segment_breakdown`. For how
  a total adds up, use `get_calculation_tree`. For headline figures across
  years, use `get_company_financials`.
- If a tool says a feature is not available for this account, tell the user
  that plainly and continue with the tools that work. Do not suggest plans,
  prices or links. Do not guess a figure that the filing does not carry.
- Kabuken has no stock prices and gives no investment advice.
