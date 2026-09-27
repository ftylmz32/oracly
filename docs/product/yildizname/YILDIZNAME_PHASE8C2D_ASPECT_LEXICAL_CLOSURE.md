# Yıldızname Phase 8C.2d — Aspect-Pair Lexical Grounding Closure

**Status:** FROZEN when gates green  
**Scope:** client grounding only (`lib/features/star_map/narrative/quality/`). Backend, astronomy,
request/result contract, schema and versions: **unchanged**.

## Defect

Phase 8C.2c documented one residual: the aspect-pair detector `_pairAspect` in
`yildizname_quality_aspect_grounding.dart` was a raw alternation of body and aspect words with no
lexical boundaries, canonicalised by substring `contains`. Consequences:

| Input (synthetic) | Old reading | Truth |
|---|---|---|
| `Bu detay—Mars kare gibi anlatıldı.` | Moon–Mars square (`ay` inside `detay`) | no claim |
| `olay—Mars`, `Kolay—Mars` | Moon–Mars … | no claim |
| `Sunum—Mars`, `Sunset—Mars` | Sun–Mars … | no claim |
| `… doctrine`, `kareli`, `karekök`, `üçgensel` | trine / square | no claim |
| `Солнце — Луна: тринадцать` | trine (`трин` prefix) | no claim |
| `Солнце — Луна квадрат` | **missed** — Dart `\w` is ASCII, `солнц\w*` never consumed Cyrillic | genuine square |

A false claim fails an honest reading (`aspect:moon|mars|square`); the RU miss let unsupported RU
aspect claims through unchecked.

## Fix

- `YildiznamePairAspectMatcher` (new) — one static pattern compiled once. Body alternatives come
  from `YildiznameGroundingLexicon.bodies` through `YildiznameLexicalToken.anyBody` (no second body
  spelling list); each body and aspect type is a named group, so canonicalisation is the matched
  group name — deterministic, no substring `contains`.
- `YildiznameLexicalToken.aspect` / `anyAspect` — boundary-aware aspect words with a closed suffix
  set (`YildiznameLexicalSuffixes`): TR case/possessive endings and EN plural for Latin stems, a
  closed noun/adjective ending set for Russian stems (`квадрате`, `оппозиции`, `соединение`). RU sextile stem is `секстил` so `секстиль` and its inflections share one form.
- `_pairAspect`, `_canonBody`, `_canonType` removed. Aspect validation itself is unchanged: every
  detected pair claim must still exist in the request aspects (either body order), otherwise
  `aspect:<a>|<b>|<type>`.

## Full grounding lexical audit

| Detector | Finding | Action |
|---|---|---|
| Pair aspect (bodies, types, canon) | raw substrings, RU `\w` miss | fixed (above) |
| Midheaven body grounding | bare `gökyüzü` prefix: `Gökyüzünde Aslan …` read as MC in Leo | now requires `gökyüzü ortas…`; MC / midheaven unchanged |
| House claim `(\d+)\s*\.?\s*(?:ev\|house\|доме)` | raw `ev` prefix: `7. evre`, `evren`, `evet`, `household` read as house claims | `YildiznameLexicalToken.house()` — closed `ev` endings (`evde`, `evindeki`, …), `house(s)`, whole `доме` |
| `YildiznameBodyMatch`, body/sign grounding | already boundary-aware since 8C.2b/8C.2c | none |
| `YildiznameQualityGuards` sentinels | degree / unsupported / privacy guards, not grounding claims | none |

Semantic (not lexical) notes, unchanged by design: `yükselen` / `rising` are also generic words;
`ay` also means "month" (whole word); `10th house` / `10-м доме` are not detected as house claims
(pre-existing narrowness, not broadened here).

## Tests

- `phase8c2d_aspect_lexical_test.dart` — 15 collision inputs yield no claim; 14 genuine TR/EN/RU
  claims (`Ay—Mars kare`, `Ay – Mars kare`, `Güneş—Ay karşıt`, `Sun-Moon trine`,
  `Venus — Mars square`, RU inflections …) produce the exact canonical claim, pass when present in
  evidence (either order) and fail when absent; wrong-type and absent-pair rejection; masking of a
  false claim next to a real one; false-conjunction corpus entry still fails.
- `phase8c2d_grounding_audit_test.dart` — Midheaven and house-word regressions (false positives pass,
  wrong genuine claims still fail: `house:moon:4`, `house:venus:7`, `house:mars:3`), helper unit
  tests, performance guard.
- `phase8c2d_support.dart` — synthetic FULL request builder. Synthetic prose only.

**Mutation proof:** restoring the raw `_pairAspect` fails 14 of the new tests (collisions, RU true
positives); reverting the Midheaven and house fixes fails 3. Both mutations restored, never
committed.

## Offline replay (scratch storage, never committed)

The prior successful real 8C.2c response was replayed through the final code: request rebuilt and
byte-equal to the recorded wire payload → `AiProxyResponseParser` → `YildiznameResultParser` →
`YildiznameQualityValidator` → `YildiznameNarrativeLiveService` path → artifact save + integrity →
serialization round-trip → presentation (live == artifact) → fresh-repository reopen (same id, hash,
payload). All PASS · provider calls 0.

The same recorded FULL wire payload passes the extracted frozen `169c514a` `validateAiBody`
(`operation=yildizname_reading scope=full placements=10 aspects=17 omittedLayers=[]`); a mutated
aspect certainty is rejected (negative control).

## Performance

Patterns are compiled once (static finals), preserving the cached strategy of `711389cc` /
`f6cee8df`. Guard: five full body/house/aspect grounding passes over a ~7.4 KB collision-dense reading
in ~0.7 s including one-time compilation (asserted < 3 s).

## Files

Production: `quality/yildizname_pair_aspect_matcher.dart` (new),
`quality/yildizname_lexical_suffixes.dart` (new), `quality/yildizname_lexical_token.dart`,
`quality/yildizname_quality_aspect_grounding.dart`, `quality/yildizname_quality_body_grounding.dart`,
`quality/yildizname_grounding_lexicon.dart`.
