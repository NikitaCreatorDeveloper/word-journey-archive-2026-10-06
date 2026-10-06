# Personal vocabulary catalog

The learning unit is one meaning/use, identified by immutable `id` and `senseKey`.
Concepts are stored once; packs and collections reference the same IDs. The 100
previous Café IDs and bilingual forms are retained. `still (water)` and
`still (continuing)` have distinct visible context and distinct histories.

`assets/vocabulary/catalog-v1.json` contains 1000 unique concepts: 200 at each
editorial level A1–C1, 17 packs per level (85 total), 12 categories per level.
Most new packs contain 12 concepts. Two Café packs per level contain 12 IDs each
with four references shared between them; pack membership must not be counted
as additional concepts. Coverage snapshots after each authored level are in
coverage-a1.md through coverage-c1.md.

All translations and examples are original authored material. `tool/content/*.txt`
and `tool/build_catalog.py` retain the authoring source. Generated example patterns
are simple practice sentences; schema validity does not certify naturalness.

CEFR is an editorial content preference for the exact sense, not a proficiency
score. Two C1 lemmas, *abundance* and *accountability*, were checked in the public
[Oxford 3000/5000 list](https://www.oxfordlearnersdictionaries.com/wordlists/oxford3000-5000)
on 2026-10-01. Their provenance explicitly says `cefrEvidenceScope: lemma` and
`reviewStatus: lemmaChecked`. **Exact senses independently verified: zero.**
The other 998 concepts remain editorial; all 1000 sense-level assignments need
language review before claims of certified educational coverage.

[Oxford selection principles](https://www.oxfordlearnersdictionaries.com/about/wordlists/oxford3000-5000)
and [British Council topical organization](https://learnenglish.britishcouncil.org/free-resources/vocabulary)
guided selection and organization. No external dictionary definition, exercise
or example corpus was bulk-copied. English Vocabulary Profile was identified as
a sense-level reference; inaccessible entries were not marked verified.

Validator checks schema version, unique IDs, required forms/examples/senses,
nonempty accepted variants, CEFR/category/pack references, provenance date/URL,
visible label limits and ambiguity within packs. Cross-pack review additionally
filters conflicting visible answers. Recall accepts listed variants after case,
whitespace, apostrophe and trailing punctuation normalization; there is no fuzzy
spelling acceptance.

Changing CEFR writes the new SQLite settings row and preserves the original
SharedPreferences migration key. It never clears word history or alters a running
round. Ordinary new-word selection uses only the selected level. Review can
return already-seen words from earlier levels, while personal words may have no
CEFR. No lower/higher level is silently substituted to enlarge a Match board.

New-word budgets 2/4/8, onboarding pool 12, recognition criteria, rank thresholds
and independent 1/3/7/14/30/60-day ladders are transparent product heuristics,
not validated probabilities or a scientifically optimal schedule.
