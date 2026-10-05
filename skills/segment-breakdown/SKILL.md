---
name: segment-breakdown
description: Show the business-segment or geographic breakdown from a Japanese listed company's EDINET filing using Kabuken tools.
disable-model-invocation: true
---

# Segment breakdown

Input: a company name, ticker, or EDINET entity code, optionally followed
by a fiscal period, given by the user (in Claude Code, the command
argument).

1. Resolve the company to an EDINET entity code (for example `E02144`):
   `search_companies` with `query` for a name, or `get_company` with `id`
   and `id_type: "ticker"` for a ticker. If a name is ambiguous, ask the
   user to pick one.
2. Call `list_documents` with `entity_code` to list the filings. If the
   user named a period, pick the matching filing. Otherwise use the most
   recent annual securities report (有価証券報告書). Note its `doc_id`.
3. Call `get_segment_breakdown` with that `doc_id` (optional `fact_name`
   to filter to one axis, optional `limit`, default 100). If a tool
   says it is available on other plans, tell the user which plan it needs
   and share https://kabuken.intellics.ai/pricing as plan details, then
   stop.
4. Present the breakdown grouped by axis (business segment, geographic
   segment, or consolidation scope), with EN/JA member labels and the
   reported figures. State the source filing and period for every number.
   Segment labels come from the EDINET Taxonomy, which has its own
   copyright notice; keep the notice the tool returns.
