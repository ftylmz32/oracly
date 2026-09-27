# YILDIZNAME Phase 8C.2b — client result contract alignment + boundary-safe grounding

**Status:** IMPLEMENTED (client only — backend, result schema and contract version untouched)  
**Found by:** the Phase 8C.2 physical real-provider run (two real gpt-5.6-sol responses, HTTP 200, backend `parsedOk`,
both rejected by the Flutter client).

## Defect 1 — result shape

The FROZEN Phase 5 contract (`YILDIZNAME_PHASE5_RESULT_CONTRACT.md`, `narrative-yildizname-result-schema.ts`,
`narrative-yildizname-result.ts`, candidate `169c514a`):

| Field | Frozen type |
|---|---|
| `summary` | `{ text, factRefs[], themeRefs[] }` |
| `sections[]` | `{ kind, text, factRefs[], themeRefs[] }` |
| `reflectionPrompt` | `string \| null` |
| `closingMessage` | `string` |

The client wrongly modelled `reflectionPrompt` / `closingMessage` as evidence blocks (parser, model, artifact payload,
artifact presentation), so every real response failed with `schema: block`. Aligned:

- `YildiznameNarrativeStructuredResult`: `String? reflectionPrompt`, `String closingMessage`.
  `allFactRefs` / `allThemeRefs` come only from summary + sections; reflection / closing own no refs.
  `visibleProse` includes reflection only when non-empty (never a literal `null`).
- `YildiznameResultParser`: reflection = `null` or a non-empty bounded string; closing = a non-empty bounded string.
  A block/map for either is rejected — the live parser is not redefined around the old client-only form.
  Existing client bounds (400 / 500) are kept; they are stricter than the backend (400 / 600), never looser.
- Canonical NEW artifacts store `"reflectionPrompt": <string|null>`, `"closingMessage": <string>` exactly as accepted.
  `acceptedThemeRefs` reads refs only from summary + sections.
- Presentation projects the strings to `YildiznameSectionRole.reflection` / `.closing`.

### Historical block-shaped artifacts (deliberate, display-only)

Narrative live persistence has existed only behind `yildizname_narrative_v1` (default `false`, never enabled), so no
production artifact should carry the old shape; but internal/dev builds could. Reopen therefore **display-reads** an
old block by its `text` only. Nothing is migrated or rewritten, `contentHash` is untouched, and the old block's
`factRefs` / `themeRefs` gain no authority (`acceptedThemeRefs` ignores them). Tested.

## Defect 2 — sign tokens were raw regex substrings

`yildizname_quality_body_grounding.dart` spliced sign/body tokens into regexes with no lexical boundary, so the
Sagittarius token `yay` matched inside `dünyaya`, failing a correct "Terazi yükselen, dünyaya …" with
`ascendant expected libra got sagittarius`.

One shared helper, `YildiznameLexicalToken`, now builds every body/sign pattern:

- **Explicit Turkish / Latin / Cyrillic word class** (Latin incl. `ğüşıöç İ`, Cyrillic, digits, combining marks),
  not ASCII `\b`. (The first version used `\p{L}` with the `unicode` flag; see *Performance* below.)
- **Sign** = a WHOLE word: `yay` ≠ `dünyaya` / `yayın` / `yaygın` / `kayayı`, `koç` ≠ `koçluk`, `leo` ≠ `Leonardo`.
  Apostrophe forms (`Aslan'da`, `Yay’da`) are word ends. Cyrillic stems keep a case-ending tail
  (`Скорпион-е`, `-ом`), so Russian claims stay detectable; `лев` ≠ `левый`.
- **Body** = a word START (inflection may follow: `güneşin`, `асцендента`); the moon token `ay` no longer starts
  inside `olay`.
- `İ` is normalised for runtimes that lowercase it to `i` + U+0307.

Wrong-sign detection is preserved (tested TR / EN / RU, both claim orders, planet + angle claims).

### Performance (found on the phone, fixed)

The first version of this fix compiled thousands of Unicode / lookbehind patterns on EVERY validation: the client
quality gate went from ~100 ms to ~9.7 s on a PC and froze the UI for ~50 s on the physical device (the result appeared
about a minute after the provider answered). Fixed with an explicit letter class (no `unicode` flag) and ONE
consolidated pattern per (body, sign), compiled once and cached. Validation of the real responses is back to
~90-200 ms. A guard test fails if per-call recompilation ever returns.

### Observations, not changed

- Client summary / section maxima (900 / 1400) are stricter than the backend (1200 / 1600). Never looser, so never
  unsafe; not part of this repair.
- Body tokens still match as prefixes (`ay` in `ayrıca`) inside the `.{0,6}` window of the
  "`<body> … <sign> burcunda`" pattern; not a sign-token defect, left as is.

## Offline replay of the two real responses (scratchpad only, never committed)

Both prior real responses were replayed through the corrected production path in isolated ephemeral storage:
`AiProxyResponseParser` → `YildiznameResultParser` → `YildiznameQualityValidator` →
`YildiznameNarrativeCompletionService` (artifact + integrity) → serialization → `YildiznameArtifactPresentation` →
fresh-repository reopen. Result for both: parser PASS · quality PASS · artifact PASS (stored `reflectionPrompt` string,
`closingMessage` string, byte-equal to the response) · presentation PASS · reopen PASS (same id, same hash, same payload)
· provider calls 0. No response text is stored in the repo.

## Tests

`test/features/star_map/narrative/phase8c2b_result_contract_test.dart` and `phase8c2b_sign_boundary_test.dart`
(synthetic content only). Narrative corpus / fixtures were converted from the incorrect block form to the frozen
shape; the quality corpus was not weakened.
