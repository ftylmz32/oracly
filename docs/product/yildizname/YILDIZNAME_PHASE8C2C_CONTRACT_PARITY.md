# YILDIZNAME Phase 8C.2c — body grounding closure + wire contract parity audit

**Status:** IMPLEMENTED (client only — backend, result schema and contract version untouched)
**Backend reference:** candidate `oracly-api-y8c1-169c514a`, commit `169c514a`
(`backend/src/ai/narrative-yildizname-limits.ts`, `narrative-yildizname-contract.ts`,
`narrative-yildizname-result.ts`). Backend source diff vs the frozen candidate: **0**.

## Issue A — body tokens were a prefix match, not a word

`YildiznameQualityBodyGrounding` matched a body token at a word START only, with no end
boundary, so a longer suffix silently continued the same "word": the Turkish Moon token
`ay` matched inside `ayrıca` ("also"), `ayrıntı` ("detail"), `ayrı` ("separate"), turning a
correct **"Ayrıca Aslan burcunda…"** into a false Moon-in-Leo claim. The same shape defect
existed for every other body token (`güneşli` "sunny" read as a Sun claim via
`sun.{0,6}sign burcunda`; `sunum`/`sunucu`/`sunuş` — Turkish words for "presentation" /
"presenter" — read as the English body token `sun`) and, separately, in the naive
substring `YildiznameBodyMatch.has` used by house/aspect grounding.

**Fix — one shared, boundary-aware body matcher** (`YildiznameLexicalToken.body`):

- **`ay`** (Moon, TR): closed suffix set `ı, ın, a, da, dan` — the same list the previous
  dedicated Moon regex used. `in` is deliberately excluded: `ayin` ("rite / ceremony") is a
  real unrelated Turkish word.
- **`sun`** (Sun, EN): whole word only. English possessive (`Sun's`) already ends the word
  at the apostrophe, which is not a word character.
- **every other body token** (`güneş`, `merkür`, `venüs`, `mars`, `satürn`, `uranüs`,
  `neptün`, `plüton`, `moon`, `mercury`, `venus`, `jupiter`, `saturn`, `uranus`, `neptune`,
  `pluto`): whole word, or one Turkish case suffix from a closed list
  (`ın/in/un/ün · ı/i/u/ü · a/e · da/de/ta/te · dan/den/tan/ten`) — long enough that no
  suffix from this list can form another real Turkish word, unlike `ay`/`sun`.
- Cyrillic bodies reuse `sign()`'s case-ending handling (already boundary-safe).
- `YildiznameBodyMatch` (house/aspect grounding) now compiles the same `anyBody` pattern
  per body, cached, instead of an unbounded substring search.

**Preserved:** `Ay'ın Aslan burcundaki…`, `Ayın Aslan burcundaki…` (no apostrophe),
`Aslan Ayı` (sign precedes body), `Güneş'in`/`Güneşin`, `Merkür'ün`, TR/EN/RU planet+sign
and Ascendant/Midheaven claims, and genuine wrong-sign rejection (a real wrong Moon sign
still fails, apostrophe or not). 36 tests, `test/features/star_map/narrative/
phase8c2c_body_collision_test.dart`; 10 of 36 fail if the fix is reverted.

**Documented, not "fixed":** a body token can still match as a mid-word PREFIX inside the
`.{0,6}` gap of the `<body>…<sign> burcunda` form (e.g. `ay` inside `ayrıca` immediately
before a sign — see the `_pairAspect` aspect-pair regex, untouched, out of scope for this
issue; residual risk is narrow and requires a specific dash/aspect-word alignment that
does not occur in ordinary prose).

## Issue B — client/backend contract bounds audit

Every ceiling in `lib/features/star_map/narrative/versions.dart` was compared against the
frozen backend and classified. **WIRE** = governs whether a request is sent/accepted;
tightened/loosened only where getting it wrong could cause a real accept/reject
disagreement. **QUALITY** = a deliberate client policy, kept even though it disagrees with
backend's raw ceiling, because loosening it would weaken a genuine safeguard.

| Constant | Was | Now | Backend | Class | Why |
|---|---|---|---|---|---|
| `kYildiznameMaxSummaryChars` | 900 | **1200** | 1200 | WIRE MISMATCH → closed | client was stricter than backend; could have rejected a genuine 901–1200-char summary |
| `kYildiznameMaxSectionChars` | 1400 | **1600** | 1600 | WIRE MISMATCH → closed | same, for sections |
| `kYildiznameMaxClosingChars` | 500 | **600** | 600 | WIRE MISMATCH → closed | same, for `closingMessage` |
| `kYildiznameMaxReflectionChars` | 400 | 400 | 400 | already matched | — |
| `kYildiznameMaxRefsPerBlock` (removed) | 16 (shared) | split | — | WIRE MISMATCH → closed | backend enforces `factRefs`/`themeRefs` **separately** |
| `kYildiznameMaxFactRefsPerBlock` (new) | — | **12** | 12 | WIRE MISMATCH → closed | |
| `kYildiznameMaxThemeRefsPerBlock` (new) | — | **3** | 3 | WIRE MISMATCH → closed | |
| `kYildiznameMaxFactRefChars` | 72 | **80** | 80 | WIRE MISMATCH → closed | client was stricter; no real factRef ever approaches 72, but the ceiling itself must agree |
| `kYildiznameMaxThemeRefChars` (new) | — (was 72, shared) | **64** | 64 | WIRE MISMATCH → closed | backend distinguishes this from `maxFactRefChars` |
| `kYildiznameMaxThemes` | 3 | 3 | 3 | WIRE, already matched | enforced building the outgoing request |
| `kYildiznameMaxSections` | 12 | 12 | 10 | QUALITY (dead slack) | the parser separately rejects a **duplicate** kind, and only 10 kinds exist, so no response can ever have more than 10 distinct sections regardless of this number; kept looser than backend so it can never be the rejection reason |
| `kYildiznameMinSummaryChars` / `kYildiznameMinSectionChars` | 40 / 40 | unchanged | none (backend requires only non-empty) | QUALITY, not a backend mirror | rejects suspiciously short prose; **not loosened** |
| `kYildiznameMaxThemeLabelChars` | 64 | unchanged | `maxLabelChars` 120 | QUALITY, safe direction | client trims outgoing labels well under backend's ceiling |
| `kYildiznameMaxPlacements` | 12 | unchanged | 10 | UNUSED CONSTANT | never enforced; natural ceiling is exactly 10 (`NatalBody.values.length`) |
| `kYildiznameMaxHouses` | 12 | unchanged | 12 | UNUSED CONSTANT, matches | whole-sign house system always yields exactly 12 |
| `kYildiznameMaxAspects` | 40 | unchanged | 48 | UNUSED CONSTANT | never enforced; natural ceiling is C(10,2) = 45 ≤ 48 |
| `kYildiznameMaxAngles` | 2 | unchanged | 2 | UNUSED CONSTANT, matches | only Ascendant + Midheaven exist |
| `maxOrb` (backend 12) | — | — | 12 | INTENTIONALLY SAFE | `AspectType.defaultOrb` ∈ {6, 8} for every type, always ≤ 12 |
| `maxBodyChars`/`maxSignChars` (backend 24/24) | — | — | 24 / 24 | INTENTIONALLY SAFE | wire body/sign strings are fixed enum `.name`s, longest 11 chars |
| `maxCalculationVersionChars` (backend 64) | — | — | 64 | INTENTIONALLY SAFE | client sends the fixed string `yildizname-natal-v1` (20 chars) |
| house systems (backend `['wholeSign']`) | — | — | — | matches exactly | `NatalHouseSystem` has exactly one value |
| certainties (backend `['exact','intervalStable']`) | — | — | — | matches exactly | ambiguous/unavailable/unsupported placements are dropped before serialization |
| policy rules | — | — | — | matches exactly, in order | `YildiznameNarrativePolicy.rules` — new parity test pins this |
| `totalVisible` (backend 9000) | — | — | 9000 | backend-only safeguard | enforced server-side before the client ever sees a response; no client mirror needed |
| `maxOmittedLayers`/`maxOmittedLayerChars` (backend 20/40) | — | — | 20 / 40 | INTENTIONALLY SAFE | reduced/full omission lists never exceed ~7 short fixed-vocabulary entries |

### A genuine wire defect found and fixed: the `ambiguous.<body>` omitted-layer marker

`YildiznameRequestExtras.omittedLayers` recorded a per-placement ambiguous/unavailable
drop (e.g. an interval-unstable Moon in a REDUCED reading) as a synthetic
`'ambiguous.<body>'` string. The frozen backend's `omittedLayers` enum has no such value
(only fixed category names, or a bare body name) — `parseOmitted` rejects anything else —
so **any live REDUCED reading whose Moon (or any placement) was ambiguous would have been
rejected outright by the backend**, before the provider was ever called. This is a live
defect, not a dead code path: REDUCED live requests are sent (unlike LEGACY, see below).

**Fix:** stop recording it. The dropped placement's absence from `placements` already says
everything truthfully; nothing in production ever read the marker's content (confirmed by
search); and the only backend-valid alternative — the bare body name (`'moon'`) — would
have wrongly collided with the frozen Phase 7B scope-resolver's *separate* legacy-detection
heuristic (`_omissionCap`), which reads bare `'moon'`/`'personalPlanets'` to mean "this
omission list looks like a whole LEGACY build," not "one placement was ambiguous." Simply
not recording anything is backend-compliant and does not touch that frozen resolver file.
Regression: `phase8c2c_contract_parity_test.dart` — a request built from
`NarrativeEvidenceFixtures.reducedAmbiguousMoon()` now has every `omittedLayers` value
inside the backend's accepted set.

### `personalPlanets` (LEGACY only) — theoretical mismatch, provably unreachable

LEGACY's own `omittedLayers` list still contains `'personalPlanets'`, which is *also* not
a backend-enum value. Unlike the reduced case above, this is **not live**: legacy-scope
evidence never leaves the device — `YildiznameLivePlanBuilder.build` short-circuits to
`YildiznameLivePlan.legacyLocal()` (which carries `request: null`) before any wire payload
is ever built for that scope. `personalPlanets` is a meaningful *internal-only* marker,
read by the same frozen resolver (`_omissionCap`) to recognize legacy-shaped evidence — not
a mistake, and changing it would touch frozen Phase 7B logic for no reachable benefit.
Left as is; proven unreachable by a regression test (`plan.kind == legacyLocal`,
`plan.request == null`).

## Contract-parity regression suite

`test/features/star_map/narrative/phase8c2c_contract_parity_test.dart` (23 tests):
constant-equality pins, house-system/orb/policy-rule pins, result-parser boundary values
(ceiling passes, ceiling+1 rejects) for summary/section/reflection/closing/factRefs count
and length/themeRefs count and length, the section-kind-uniqueness finding above, real
production-evidence request generation staying within every backend ceiling (FULL: E4
engine evidence; REDUCED: E2 engine evidence and the ambiguous-Moon fixture), the LEGACY
unreachability proof, and theme-label/theme-count boundaries. Mutation-tested: reverting
either the parser-ceiling fix or the `ambiguous.<body>` fix fails this suite (1 and 1 test
respectively).

### Offline frozen-backend validator proof (no provider call)

The actual FINAL-code FULL wire payload, built from the real on-device stored chart used in
Phase 8C.2b (`YildiznameRequestFactory.fromEvidence` → `YildiznameWireContract.payload`),
was validated against the extracted frozen `169c514a` `validateAiBody`:

```
FROZEN-169c514a-VALIDATOR PASS | operation=yildizname_reading scope=full
placements=10 aspects=17 omittedLayers=[]
```

The prior successful 8C.2b real backend response was also replayed through the corrected
FINAL code end to end (parser → quality → artifact save → presentation → cold reopen, in
isolated ephemeral storage): PARSER PASS · QUALITY PASS · ARTIFACT PASS (canonical
`reflectionPrompt: string`, `closingMessage: string`) · PRESENTATION PASS · REOPEN PASS
(same hash, same payload) · 0 provider calls.

## Performance

The Issue A rewrite reuses the same per-(body,sign) compiled-and-cached pattern strategy
from Phase 8C.2b (`711389cc`) — no new per-call regex compilation was introduced. A guard
test (`phase8c2c_body_collision_test.dart`, "performance guard") times three repeated
validations of a ~4 KB synthetic reading and asserts well under 3 seconds.

## Files

Production: `lib/features/star_map/narrative/versions.dart`,
`quality/yildizname_lexical_token.dart`, `quality/yildizname_quality_body_grounding.dart`,
`quality/yildizname_body_match.dart`, `result/yildizname_result_parse_parts.dart`,
`request/yildizname_request_extras.dart`.

Tests: `test/features/star_map/narrative/phase8c2c_body_collision_test.dart`,
`phase8c2c_contract_parity_test.dart`; updated `narrative_flag_request_test.dart` and
`test/support/yildizname_result_fixtures.dart` for the `ambiguous.<body>` removal.

Backend / astronomy / result schema / contract version: **unchanged**.
