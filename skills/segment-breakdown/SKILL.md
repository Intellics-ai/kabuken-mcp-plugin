---
description: Show the business-segment or geographic breakdown for a Japanese listed company's filing using Kabuken MCP tools.
disable-model-invocation: true
---

# Segment breakdown

Argument: a company name, ticker, or EDINET entity code, optionally
followed by a fiscal period — "$ARGUMENTS".

1. Call `get_company` to resolve the company. If ambiguous, call
   `search_companies` first and ask the user to pick one.
2. Call `list_documents` for that company to find its filings. If the user
   named a specific period, pick the matching filing; otherwise use the
   most recent annual securities report (有価証券報告書).
3. Call `get_segment_breakdown` for that filing's `doc_id`. If the account
   is BASIC tier and the call is rejected with an upgrade message, say so
   plainly and stop.
4. Present the breakdown grouped by axis (business segment, geographic
   segment, or consolidation scope), with bilingual EN/JA member labels and
   the reported figures. Note that this tool surfaces EDINET Taxonomy
   content, which carries its own attribution requirement separate from
   the filing data itself — mention the source filing and period for every
   number.
