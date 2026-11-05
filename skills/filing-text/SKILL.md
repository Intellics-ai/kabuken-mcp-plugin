---
name: filing-text
description: Read the narrative sections of a Japanese company's annual securities report as filed, using get_filing_text. Use when the user asks for risk factors, 事業等のリスク, MD&A, management discussion, outlook narrative, or the original or as-filed text.
---

# Filing text

Input: one company name, ticker, EDINET entity code, or a filing `doc_id`,
given by the user.

1. Identify the filing:
   - `doc_id` given: use it;
   - otherwise resolve the company to an entity code with `search_companies`
     (`query`) or `get_company` (`id`, `id_type: "ticker"`). If several
     companies match, ask the user to pick one.
2. Call `get_filing_text` with `doc_id` or `entity_code` (the entity code
   reads the latest annual report). Set `sections`: `business_risks` for
   事業等のリスク (default) or `md_and_a` for management discussion and
   outlook. Optional `max_chars` limits the size of each page.
3. Each item in `sections` has `section`, `source_element`, `label_ja`,
   `label_en` and `text`. The text is the filer's own Japanese wording,
   verbatim, with no AI summary from Kabuken. State the company, the filing
   and the period for what you show.
4. Present the text as filed, in Japanese. If `next_cursor` is set and the
   user wants more, call again with `cursor` set to `next_cursor` and the
   same `doc_id` or `entity_code` and `sections`. Name every entry in
   `missing_sections`.
5. Translate or summarise only if the user asks. Say that the translation
   or summary is your own work, not part of the filing, and quote the
   original Japanese for each key sentence.
6. If the tool returns `not_found`, say that no narrative text is stored for
   that filing. Do not guess or fill in from memory.
7. Keep the attribution notice from the response (EDINET / FSA, PDL1.0, and
   the note that the text is the filer's).
8. Kabuken has no stock prices and gives no investment advice. If a tool
   says a feature is not available for this account, tell the user that
   plainly and continue with the tools that work. Do not suggest plans,
   prices or links.
