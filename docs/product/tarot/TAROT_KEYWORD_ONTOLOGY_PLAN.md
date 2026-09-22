# Tarot Keyword Ontology Plan — Phase 3C.5D / FR-M04

**Status:** DESIGN ONLY — not implemented
**Active mapping revision:** Phase **3C.5D.1** (semantic repair)
**Branch tip at design start:** `bc9ff060801d941c16ed32b32d8708177fa20c21`
**Worktree:** `D:/oracly_final_r1`
**Production `keywordIds`:** **UNCHANGED**
**FR-M04:** remains **OPEN** until a later ChatGPT-reviewed implementation task

Machine-readable companion (local worktree aid, not production):
`tool/qa/phase3c5d_ontology_design.json` · inventory `tool/qa/phase3c5d_keyword_inventory.json`

---

## 1. Executive decision

Current orientation `keywordIds` are **too fragmented** (397 unique / 352 singletons ≈ **88.7%**) to serve as reliable soft grouping signals for a future Narrative Evidence Engine.

**Decision:** adopt a **shared canonical keyword lexicon** (~120–130 language-agnostic lowerCamelCase ids) derived from the existing 78-card deck, with a complete CURRENT→CANONICAL migration map for all upright and reversed orientations.

**This task does not apply the map.** Implementation requires a separate reviewed prompt.

**Evidence Engine readiness remains NO** while FR-M04 is OPEN.

---

## 2. Current inventory

Reproduced programmatically from all 78 Narrative profiles (not copied from 3C.4 alone):

| Metric | Value |
|---|---:|
| Profiles | 78 |
| Total keyword assignments | **468** |
| Unique keyword ids | **397** |
| Singleton ids | **352** |
| Singleton % | **88.66%** |
| Appear exactly 2× | 29 |
| Appear 3–4× | 15 |
| Appear 5+× | 1 (`scatter` ×7) |
| Upright unique | 219 |
| Reversed unique | 181 |
| Upright ∩ Reversed vocabulary | 3 (`release`, `silence`, `strain`) |

**Per-suit unique counts:** major 104 · wands 75 · cups 81 · swords 83 · pentacles 84

**Top usage today:** scatter(7), denial/doubt/haste/indecision/resistance/notListening(4), then several at 3×.

**Density today:** almost always 3 ids per orientation (78×2×3 = 468).

---

## 3. Problem statement

1. **Singleton monoculture** — most ids are card-private labels (`catastropheDream`, `fertileHand`, `shopWindow`), so overlap detection almost never fires.
2. **Imagery as metadata** — many ids encode card picture language rather than reusable semantics.
3. **Synonym scatter** — same concept appears as `mindLoad` / `nightThought` / `mindBurden`-class prose without a shared id.
4. **Layer confusion risk** — some ids echo `ReversedTransformKind` (`avoidance`, `delay`, `release`) or `symbolTags` without a clear division of labor.
5. **Unsafe if over-trusted** — a future engine must not treat a single keyword match as relationship or recurrence proof.

---

## 4. Ontology principles

### Naming

- `lowerCamelCase` stable ids
- Language-agnostic (not TR/EN/RU strings)
- No sentence fragments, no card names/numbers, no suit names as ids
- No medical/diagnostic/legal accusation labels

### Layers (do not merge)

| Layer | Role | Examples |
|---|---|---|
| **keywordId** | Specific reusable semantic concept | `clarity`, `belonging`, `scatter` |
| **symbolTag** | Broader motif family | `movement`, `threshold`, `nurture` |
| **ReversedTransformKind** | How reversed energy bends | `excess`, `distortion`, `internalization` |

Rule: prefer **not** duplicating a transform enum as the sole keyword for an orientation. Keywords name **what**; transforms name **how**.

### Merge vs keep

- **Merge** only true synonyms / imagery variants of one concept.
- **Do not merge** useful distinctions (`clarity`≠`certainty`, `boundary`≠`coldness`, `grief`≠`release`, `belonging`≠`dependence`, `pause`≠`delay`, `care/nurture`≠`rescue`).

### Granularity

Target: **shared enough to group**, **specific enough to preserve card identity**.

Rejected extremes:

- ~90% singletons (status quo)
- ~10 ultra-generic labels for the whole deck

Chosen band: **~110–130 canonical ids**, projected singleton rate **~20–30%**, with many ids used 3–8 times.

### Density

Recommend **2–4 keyword ids per orientation** (current practice is 3; projected averages ≈2.7–2.9).

### Orientation

Upright and reversed proposed sets must **not be identical** for any card. Shared keywords across orientations are allowed when genuinely true; full-set collapse is forbidden.

### Stability / versioning

- After first production persistence/use: ids are **immutable** except via explicit migration.
- Document ontology revision separately from `profileRevision`.
- Never silently rename in place once Evidence Engine or storage depends on ids.

### Recurrence authority (locked)

Keywords may **help** soft theme inference.
They **never** authorize:

- “appeared N times”
- “theme keeps returning”

Those require `TarotRecurringCardEvidence` / `TarotRecurringThemeEvidence` only.

---

## 5. Proposed canonical lexicon

**Size:** **124** ids (see Appendix A).

Concept families (illustrative, not exhaustive):

- Agency / craft / fire: `agency`, `craft`, `focus`, `direction`, `will`, `spark`, `enthusiasm`, `mastery`, `vitality`, `courage`, `creation`
- Belonging / emotion: `belonging`, `nurture`, `compassion`, `holding`, `receptivity`, `intimacy`, `joy`, `grief`, `enough`, `flow`, `overflow`, `attachment`, `union`, `reciprocity`
- Mind / speech: `clarity`, `truth`, `inquiry`, `curiosity`, `discernment`, `judgment`, `boundary`, `restraint`, `communication`, `harshSpeech`, `notListening`, `mindBurden`, `confusion`, `bias`
- Structure / material: `structure`, `stability`, `accountability`, `discipline`, `tradition`, `roots`, `resource`, `labor`, `stewardship`, `abundance`, `scarcity`
- Process / time: `pause`, `delay`, `timing`, `threshold`, `change`, `ending`, `release`, `renewal`, `integration`, `completion`, `cycles`, `stagnation`
- Difficult dynamics: `control`, `pressure`, `haste`, `rigidity`, `scatter`, `escape`, `avoidance`, `denial`, `doubt`, `resistance`, `withdrawal`, `isolation`, `suppression`, `projection`, `boast`, `display`, `imbalance`, `instability`, `exhaustion`, `strain`, `burden`, `fear`, `despair`, `anger`, `discord`, …
- Roles / openings: `messenger`, `learning`, `listening`, `opening`, `closing`, `principle`, `fairness`, `authority`, `socialExpectation`, `externalDemand`, `internalStrain`

Each id has a short definition in Appendix A. Example cards are recoverable from the full mapping (Appendix B).

**Near-concepts that must NOT be merged** (selected):

| Keep distinct | Do not collapse into |
|---|---|
| `clarity` | certainty / prediction |
| `boundary` | `coldness` |
| `grief` | `release` |
| `belonging` | `dependence` |
| `nurture` | `rescue` |
| `pause` | `delay` |
| `inquiry` | `curiosity` (related but not identical) |
| `structure` | `control` |
| `fear` | clinical anxiety diagnosis |

---

## 6. Full 78×orientation mapping

**COMPLETE** — 78 upright + 78 reversed = **156** rows.

See **Appendix B** (`tool/qa/phase3c5d_mapping_table.md` content embedded below).

Every row lists CURRENT ids → PROPOSED canonical ids with a short rationale class.

Identical upright/reversed proposed sets: **0**.

---

## 7. Current→canonical migration table

**COMPLETE** — **397** CURRENT ids classified.

| Class | Count |
|---|---:|
| KEEP | 95 |
| MERGE | 94 |
| RENAME | 204 |
| SPLIT | 1 (`pressure`) |
| DROP-AS-DECORATIVE | 2 (`air`, `breath`) |
| NEEDS-HUMAN-DECISION | 1 (`envy`) |

See **Appendix C**.

### SPLIT — `pressure`

May specialize by context:

| Context | Canonical |
|---|---|
| Outer force / push | `externalDemand` |
| Inner self-push | `internalStrain` |
| Role / lineage / household expectation | `socialExpectation` |
| Ambiguous | keep `pressure` |

Default mapping in the projected table applies specialization for selected cards; implementers must re-check each occurrence.

### DROP-AS-DECORATIVE

| Id | Why |
|---|---|
| `air` | Elemental label redundant with suit identity |
| `breath` | Local imagery; no reusable grouping signal |

Meaning remains in prose / suit / imagery — not deleted from the card experience.

---

## 8. Suit / rank / court audit

### Suit identity — **PASS (with watchpoints)**

| Suit | Preserved dimensions | Watchpoint |
|---|---|---|
| Wands | spark, direction, will, scatter, haste, display | Do not let every Wand share only `will` |
| Cups | belonging, receptivity, flow, overflow, intimacy | Do not flatten 09 vs 10 (`enough`/`holding` vs `belonging`) |
| Swords | clarity, inquiry, truth, harshSpeech, mindBurden | Keep speech vs mind-burden distinct |
| Pentacles | structure, stewardship, labor, roots, scarcity | Avoid making all courts `accountability` clones |
| Major | threshold, change, agency, ending, integration | Major must stay archetypal, not suit clones |

### Rank identity — **PASS / light CONCERNS**

No forced Ace→Ten taxonomy. Accidental cross-suit rank rhyme (e.g. “first/opening” on Aces) is allowed only when real. Do **not** invent a numeric rank ontology to improve reuse stats.

### Court identity — **PASS**

Pages → `learning` / `messenger` / `curiosity` flavors
Knights → motion / direction / haste risks
Queens → holding / boundary / nurture / discernment
Kings → principle / accountability / structure / stewardship

**Forbidden encodings avoided:** Page≠weak child, King≠superior masculine authority, Queen≠feminine-only care.

---

## 9. Upright / reversed distinction audit

| Check | Result |
|---|---|
| Identical proposed upright/reversed sets | **0** |
| Shared keywords across orientations | Allowed when true |
| Reversed content vs transforms | Keywords describe content; transforms remain mechanism |

**ORIENTATION DISTINCTNESS: PASS**

---

## 10. SymbolTag relationship

| Verdict | Detail |
|---|---|
| Complementary | Tags stay broad motifs; keywords stay sharper concepts |
| Overlap examples | `belonging`, `clarity`, `curiosity`, `accountability` exist in both layers |
| Rule | Overlap is OK if keyword is the discriminative atom and tag is the family |
| Action this phase | **Do not modify symbolTags** (FR symbol-tag concern remains non-blocking / separate) |

**Concise verdict:** useful complementarity; do not replace keyword ontology with tags alone (tags are too broad).

---

## 11. ReversedTransform relationship

| Verdict | Detail |
|---|---|
| Do not keyword-clone transforms | Avoid sole keyword = `excess` / `distortion` / … |
| Contentful cousins allowed | `delay`, `avoidance`, `release` may remain keywords when they name **semantic content**, not merely the enum |
| Transforms unchanged | **No transform edits in FR-M04 implementation either, unless separately justified** |

**Concise verdict:** layers stay separate; implementation must lint against transform-only keyword lists.

---

## 12. Evidence Engine usage contract

### Allowed soft uses

- Candidate theme overlap hints
- Soft relationship / support / contrast scoring inputs
- Profile similarity hints
- Question-relevance hints

### Forbidden

- Future prediction from keywords
- Mind-reading
- Recurrence counts (“keeps returning”)
- Automatic conclusion from a **single** shared keyword
- Overriding contradictory card meaning / orientation / spread position

### Scoring safeguards (design only — not implemented)

1. One shared keyword alone ≠ relationship.
2. High-frequency keywords (`scatter`, `haste`, …) receive **lower discriminative weight**.
3. Confidence rises with **multiple independent** signals (keywords + transforms + prose anchors + positions).
4. Canonical relations / spread position / orientation remain separate inputs.
5. Keyword overlap never overrides contradictory profile semantics.

**ENGINE USAGE CONTRACT: READY FOR CHATGPT REVIEW**

---

## 13. Safety rules

Do **not** include accusation / certainty labels such as:

`cheating`, `liar`, `disease`, `pregnancy`, `deathPrediction`, `guaranteedProfit`, `criminal`, `soulmate`, `destinedPartner`

Symbolic fear/grief/shame/anger are allowed only as **non-diagnostic** concepts.

`theftFeeling` maps to soft `fear` (feeling robbed) — **not** an accusation of theft.

**SAFETY: PASS** (with implementer duty to reject any new unsafe ids)

---

## 14. Quantitative projected metrics

From applying the proposed map (design simulation only):

| Metric | Current | Projected |
|---|---:|---:|
| Vocabulary size | 397 | **118** used / **124** defined |
| Singleton ids | 352 | **29** |
| Singleton % | 88.66% | **24.58%** |
| Exactly 2× | 29 | 18 |
| 3–4× | 15 | 37 |
| 5+× | 1 | 34 |
| Total assignments | 468 | 436 |
| Avg upright keywords | ~3.0 | **2.73** |
| Avg reversed keywords | ~3.0 | **2.86** |
| Identical upright/reversed sets | (not gated) | **0** |

**Top projected keywords:** `scatter` / `haste` (14, 3.21%), `withdrawal` (12, 2.75%), `escape` / `stability` (10, 2.29%).

**Over-genericity check:** top ids are real recurring difficult dynamics (scatter/haste/withdrawal) across suits — acceptable if weighted down in scoring. They must not erase card identity (prose + remaining keywords still differ).

---

## 15. Proposed implementation gates

For the future implementation task (not this task):

1. **No production change without ChatGPT approval of this plan.**
2. After apply: singleton % ≤ **35%** (target ~25%).
3. Canonical vocabulary size between **90 and 150**.
4. Identical upright/reversed keyword sets = **0**.
5. Each orientation has **2–4** keyword ids.
6. No keyword id equals a `ReversedTransformKind` name **unless** documented exception (`delay`/`avoidance`/`release` content cases).
7. No unsafe accusation ids present.
8. Full migration table applied with zero CURRENT ids left unmapped (except explicit DROP).
9. Existing FR-B01 / FR-M01 / FR-M02 / FR-M03 / RT-M01 / RT-M02 regressions remain green.
10. Keyword change is **ids only** — no prose/TR/RU/transforms/symbolTags edits in the same commit unless separately scoped.

---

## 16. Ambiguous mappings requiring ChatGPT review

**After 3C.5D.1:** **AMBIGUOUS MAPPINGS = 0**.

Previous provisional envy→attachment is **rejected**. envy is KEEP.

Review notes that remain as implementation discipline (not unresolved mappings):

- pressure specialization must be re-checked against prose at implement time
- high-frequency scatter/haste soft-weighting belongs to Evidence Engine planning later
- delay dual-layer lint at implement time

## 17. Implementation scope recommendation

**Next task (after ChatGPT review):** FR-M04 implementation only:

- Apply keywordId remaps on all 78 profiles (upright + reversed)
- Add ontology constants module (canonical id list + optional docs)
- Add enforcement tests for gates in §15
- **Do not** start Narrative Evidence Engine in the same phase
- **Do not** modify prose, symbolTags, or transforms unless a blocking contradiction appears (then STOP)

**Deck ready for Evidence Engine after successful FR-M04 implementation + review:** still requires explicit readiness decision; this design alone does **not** flip readiness to YES.

---



---

## Phase 3C.5D.1 — semantic mapping repair

**Status:** DESIGN ONLY — ACTIVE IMPLEMENTATION TARGET
**Start SHA:** 9b7086cc92709abe3d3aea11f1f6ee3b6ab34b8b
**Machine companion:** `tool/qa/phase3c5d1_ontology_design.json`
**Production keywordIds:** still **UNCHANGED**

### Why

Independent ChatGPT review approved architecture but found **semantic inversions / over-merges** in the first mapping pass (heuristic normalization over semantic review).

Metric hierarchy is now locked:

1. semantic fidelity
2. orientation fidelity
3. card identity
4. layer separation
5. reuse/groupability
6. singleton rate

### Confirmed defects repaired

| Defect | Before | After |
|---|---|---|
| wands_08 upright speed→haste | INVERSION | momentum, messenger, flow |
| pentacles_02 upright twoWeights/practicalBalance/juggle→ imbalance/stability/scatter | INVERSION | coordination, balance, focus |
| balance→stability | LOSS | **KEEP** balance distinct |
| instability→stability | INVERSION | **KEEP** instability distinct |
| envy→attachment | LOSS | **KEEP** envy |
| swords_12 upright fastMind→haste | INVERSION | momentum, communication, clarity |
| hastyUnion→union | LOSS | →haste |
| diminishedJoy→joy | INVERSION | →withdrawal |
| overcare→nurture | LOSS | →rescue |

### Decision log (LOCKED)

| Topic | Decision |
|---|---|
| envy | **KEEP** as canonical id (symbolic only; never mind-reading) |
| balance | **KEEP** distinct from stability |
| instability | **KEEP** distinct from stability |
| neutral rapid motion | **momentum** — directed forward motion not inherently premature |
| inquiry vs curiosity | **KEEP both** |
| delay | conditional keyword+transform dual-use allowed when expression concerns postponement AND another content keyword identifies WHAT is delayed |
| pressure | contextual split only where evidence supports; else KEEP pressure |

### Pre-repair baseline (3C.5D projection)

| Metric | Value |
|---|---:|
| Defined lexicon | 124 |
| Used | 118 |
| Singleton % | 24.58% |
| Semantic inversions found by review | ≥5 classes (see table) |

### Post-repair projection (ACTIVE)

| Metric | Value |
|---|---:|
| Defined lexicon | 128 |
| Used | 122 |
| Total assignments | 439 |
| Singleton ids | 30 |
| Singleton % | 24.59% |
| Avg upright / reversed | 2.76 / 2.87 |
| Identical upright/reversed sets | 0 |
| Ambiguous mappings | 0 |
| Audit inversions/losses after repair | 0 |

### Forced example upright sets

| Card | Proposed upright |
|---|---|
| wands_08 | momentum, messenger, flow |
| swords_12 | momentum, communication, clarity |
| pentacles_02 | coordination, balance, focus |
| major_11 | balance, truth, accountability |
| major_14 | balance, integration, restraint |

### Revised implementation gates (ACTIVE)

Hard gates:

- 78 profiles / 156 orientations mapped
- 2–4 ids per orientation
- identical upright/reversed sets = 0
- no semantic inversion / semantic loss / orientation collapse
- no unmapped current ids except documented DROP
- no unsafe accusation/certainty ids
- no duplicate id inside one orientation
- no transform-only orientation semantics
- singleton % target ≤35%, **never** via false merge
- all ids exist in canonical ontology
- prior FR/RT regressions remain green

Vocabulary: **expected review band 90–160**; exceeding allowed if required by semantic fidelity.

### Ontology plan approved for implementation?

**YES — pending ChatGPT confirmation of this 3C.5D.1 repair.**
FR-M04 remains OPEN until a separate implementation task applies ids.

## Appendix A — Canonical lexicon (ACTIVE — 3C.5D.1)

| ID | Definition |
|---|---|
| `abundance` | plentiful provision |
| `accountability` | answerable responsibility |
| `agency` | capacity to act with intention |
| `anger` | heated reactive force |
| `attachment` | clinging bond |
| `authority` | legitimate standing to decide |
| `avoidance` | sidestepping what needs facing |
| `awakening` | stirring into awareness |
| `balance` | active equilibration between competing forces, needs, weights, or standards |
| `belonging` | shared place among others |
| `bias` | slanted reading of evidence |
| `boast` | self-display over substance |
| `bondage` | constraint that binds |
| `boundary` | humane limit |
| `burden` | weight carried |
| `change` | shift of condition |
| `choice` | act of selecting a path |
| `clarity` | clear seeing / clean thought |
| `closing` | shutting that ends access |
| `coldness` | warmth withdrawn into distance |
| `communication` | exchange of meaning |
| `compassion` | warm understanding toward suffering |
| `completion` | work brought to finish |
| `conformity` | yielding to external mold |
| `confusion` | mixed or unclear thought |
| `control` | dominating grip |
| `coordination` | holding multiple demands in workable relation |
| `courage` | willingness to face risk |
| `craft` | skilled making / practiced ability |
| `creation` | bringing something into form |
| `curiosity` | the desire / openness to learn |
| `cycles` | repeating pattern over time |
| `delay` | postponement of action or clarity |
| `denial` | refusing to acknowledge |
| `dependence` | leaning that collapses autonomy |
| `desire` | wanting that moves toward |
| `despair` | loss of hopeful orientation |
| `direction` | chosen course or heading |
| `discernment` | separating signal from noise |
| `discipline` | practiced self-governance |
| `discord` | relational disharmony |
| `display` | showing for effect |
| `doubt` | uncertain trust in self or path |
| `ending` | closing of a chapter |
| `enough` | sufficiency without excess demand |
| `enthusiasm` | warm eager engagement |
| `envy` | painful comparison / possessive jealousy around another's value, attention, warmth, or standing (symbolic only; never mind-reading) |
| `escape` | leaving instead of meeting |
| `exhaustion` | depleted capacity |
| `externalDemand` | pressure arriving from outside |
| `fairness` | even-handed measure |
| `fear` | anticipatory dread (symbolic, not diagnosis) |
| `flow` | unforced emotional movement |
| `focus` | sustained directed attention |
| `freedom` | unbinding from constraint |
| `grief` | mourning / heart-loss |
| `guidance` | offered directional help |
| `harshSpeech` | cutting / bitter language |
| `haste` | rushing ahead of readiness |
| `holding` | containing feeling without forcing |
| `hope` | forward-leaning expectation |
| `illusion` | mis-seen appearance |
| `imbalance` | lost equilibrium between competing forces or standards |
| `impatience` | intolerance of waiting |
| `indecision` | inability to choose |
| `inquiry` | the act/process of questioning or examining to understand |
| `instability` | unsteady ground; loss of reliable footing |
| `integration` | bringing parts into one whole |
| `internalStrain` | pressure felt from within |
| `intimacy` | close mutual emotional contact |
| `intuition` | felt knowing without proof |
| `isolation` | separated aloneness |
| `joy` | felt gladness |
| `judgment` | evaluative decision (neutral) |
| `labor` | sustained work effort |
| `learning` | beginner / student growth |
| `listening` | receptive attention to another |
| `mastery` | earned command of skill (not superiority) |
| `messenger` | bringing news without claiming mastery |
| `mindBurden` | heavy mental load / night worry weight |
| `misdirection` | aim turned away from true object |
| `momentum` | directed forward motion or rapid movement that is not inherently premature |
| `mystery` | what remains unknown |
| `notListening` | refusal or failure to hear |
| `nurture` | care that sustains growth |
| `opening` | first soft beginning |
| `overflow` | feeling beyond what can be held |
| `pause` | chosen stilling |
| `perspective` | shifted vantage |
| `pressure` | force to perform when source is unspecified |
| `principle` | rule held as fair measure |
| `projection` | placing inner content onto others |
| `receptivity` | openness to receive |
| `reciprocity` | mutual give-and-receive |
| `release` | letting go |
| `renewal` | return of life after loss |
| `rescue` | over-saving another |
| `resistance` | pushing against movement |
| `resource` | material means / practical supply |
| `restraint` | held-back force |
| `rigidity` | inflexible hardening |
| `roots` | lineage / lasting foundation |
| `scarcity` | sense of not-enough means |
| `scatter` | energy split across too many points |
| `shadow` | unacknowledged difficult aspect |
| `shame` | painful contracted self-regard (symbolic, not clinical) |
| `silence` | quiet / unspoken field |
| `socialExpectation` | role pressure from others |
| `solitude` | chosen or forced aloneness |
| `spark` | fresh beginning impulse |
| `stability` | steady lasting ground / continuity |
| `stagnation` | stuck non-movement |
| `stewardship` | caretaking of what is held |
| `strain` | stressed tension under load |
| `structure` | ordered supporting frame |
| `suppression` | forcing feeling down |
| `teaching` | passing understanding on |
| `threshold` | crossing into a new state |
| `timing` | when something ripens |
| `tradition` | inherited shared pattern |
| `truth` | honest naming of what is |
| `uncertainty` | unknown outcome space |
| `union` | joining of lives or wills |
| `values` | what is held as important |
| `vitality` | living energy / aliveness |
| `will` | deliberate drive |
| `wisdom` | integrated understanding |
| `withdrawal` | pulling inward from contact |


## Appendix B — Full 78×orientation mapping (ACTIVE — 3C.5D.1)

| Card | Ori | CURRENT | PROPOSED |
|---|---|---|---|
| `cups_01` | upright | `firstWater`, `heldCup`, `softOpening` | `opening`, `holding` |
| `cups_01` | reversed | `overflow`, `closing`, `feelingFlee` | `overflow`, `closing`, `escape` |
| `cups_02` | upright | `twoCups`, `reciprocity`, `offeredCup` | `intimacy`, `reciprocity`, `opening` |
| `cups_02` | reversed | `imbalance`, `projection`, `hastyUnion` | `imbalance`, `projection`, `haste` |
| `cups_03` | upright | `sharedTable`, `friendship`, `gathering` | `belonging`, `ending` |
| `cups_03` | reversed | `surface`, `exclusion`, `noise` | `illusion`, `isolation`, `confusion` |
| `cups_04` | upright | `stillCup`, `enough`, `inwardPause` | `pause`, `enough` |
| `cups_04` | reversed | `ingratitude`, `escape`, `feelingBlind` | `discord`, `escape`, `confusion` |
| `cups_05` | upright | `spilledCups`, `mourning`, `whatStands` | `overflow`, `grief`, `stability` |
| `cups_05` | reversed | `onlyLoss`, `despair`, `denial` | `despair`, `denial` |
| `cups_06` | upright | `oldCup`, `memory`, `simplicity` | `roots`, `clarity` |
| `cups_06` | reversed | `pastLock`, `childRole`, `missingNow` | `bondage`, `socialExpectation`, `escape` |
| `cups_07` | upright | `manyCups`, `options`, `touchOne` | `overflow`, `choice`, `focus` |
| `cups_07` | reversed | `escapeDream`, `indecision`, `mirage` | `escape`, `indecision`, `illusion` |
| `cups_08` | upright | `cupLeft`, `deeperSearch`, `turning` | `withdrawal`, `inquiry`, `change` |
| `cups_08` | reversed | `burnLeave`, `escape`, `halfSearch` | `escape`, `inquiry` |
| `cups_09` | upright | `fullCup`, `innerEnough`, `quietTaste` | `enough`, `joy` |
| `cups_09` | reversed | `inflation`, `loneVictory`, `display` | `boast`, `isolation`, `display` |
| `cups_10` | upright | `fullTable`, `sharedCircle`, `calmBelonging` | `belonging`, `union` |
| `cups_10` | reversed | `idealStage`, `forcedJoy`, `hiddenCracks` | `illusion`, `display`, `denial` |
| `cups_11` | upright | `waterMessenger`, `softCuriosity`, `feelingLanguage` | `messenger`, `curiosity`, `receptivity` |
| `cups_11` | reversed | `overSensitivity`, `escapeDream`, `oracleFeeling` | `overflow`, `escape`, `illusion` |
| `cups_12` | upright | `cupOnRoad`, `offer`, `flow` | `threshold`, `opening`, `flow` |
| `cups_12` | reversed | `scatteredHeart`, `escapeRomance`, `flungOffer` | `scatter`, `escape`, `haste` |
| `cups_13` | upright | `matureVessel`, `compassion`, `holding` | `stewardship`, `compassion`, `holding` |
| `cups_13` | reversed | `overflow`, `noBoundary`, `rescuing` | `overflow`, `boundary`, `rescue` |
| `cups_14` | upright | `steeringWater`, `measuredFlow`, `calmStance` | `direction`, `flow`, `restraint` |
| `cups_14` | reversed | `coldness`, `suppression`, `frozenStance` | `coldness`, `suppression`, `rigidity` |
| `major_00` | upright | `threshold`, `curiosity`, `freedom` | `threshold`, `curiosity`, `freedom` |
| `major_00` | reversed | `haste`, `scatter`, `avoidance` | `haste`, `scatter`, `avoidance` |
| `major_01` | upright | `craft`, `focus`, `agency` | `craft`, `focus`, `agency` |
| `major_01` | reversed | `scatter`, `control`, `doubt` | `scatter`, `control`, `doubt` |
| `major_02` | upright | `silence`, `intuition`, `mystery` | `silence`, `intuition`, `mystery` |
| `major_02` | reversed | `secrecy`, `confusion`, `withdrawal` | `silence`, `confusion`, `withdrawal` |
| `major_03` | upright | `nurture`, `abundance`, `creation` | `nurture`, `abundance`, `creation` |
| `major_03` | reversed | `depletion`, `overcare`, `neglect` | `exhaustion`, `rescue`, `withdrawal` |
| `major_04` | upright | `structure`, `authority`, `stability` | `structure`, `authority`, `stability` |
| `major_04` | reversed | `rigidity`, `control`, `instability` | `rigidity`, `control`, `instability` |
| `major_05` | upright | `teaching`, `tradition`, `values` | `teaching`, `tradition`, `values` |
| `major_05` | reversed | `conformity`, `dogma`, `questioning` | `conformity`, `rigidity`, `learning` |
| `major_06` | upright | `choice`, `union`, `values` | `choice`, `union`, `values` |
| `major_06` | reversed | `discord`, `indecision`, `misalignment` | `discord`, `indecision`, `imbalance` |
| `major_07` | upright | `movement`, `will`, `direction` | `momentum`, `will`, `direction` |
| `major_07` | reversed | `stall`, `drift`, `overcontrol` | `delay`, `scatter`, `control` |
| `major_08` | upright | `courage`, `compassion`, `restraint` | `courage`, `compassion`, `restraint` |
| `major_08` | reversed | `selfDoubt`, `suppression`, `strain` | `doubt`, `suppression`, `strain` |
| `major_09` | upright | `solitude`, `wisdom`, `inquiry` | `solitude`, `wisdom`, `inquiry` |
| `major_09` | reversed | `isolation`, `withdrawal`, `silence` | `isolation`, `withdrawal`, `silence` |
| `major_10` | upright | `cycles`, `change`, `timing` | `cycles`, `change`, `timing` |
| `major_10` | reversed | `resistance`, `delay`, `instability` | `resistance`, `delay`, `instability` |
| `major_11` | upright | `balance`, `truth`, `accountability` | `balance`, `truth`, `accountability` |
| `major_11` | reversed | `bias`, `denial`, `imbalance` | `bias`, `denial`, `imbalance` |
| `major_12` | upright | `surrender`, `perspective`, `pause` | `ending`, `perspective`, `pause` |
| `major_12` | reversed | `stagnation`, `resistance`, `sacrifice` | `stagnation`, `resistance`, `release` |
| `major_13` | upright | `transformation`, `release`, `ending` | `change`, `release`, `ending` |
| `major_13` | reversed | `resistance`, `stagnation`, `grief` | `resistance`, `stagnation`, `grief` |
| `major_14` | upright | `balance`, `integration`, `alchemy` | `balance`, `integration`, `restraint` |
| `major_14` | reversed | `imbalance`, `haste`, `extremes` | `imbalance`, `haste`, `scatter` |
| `major_15` | upright | `attachment`, `desire`, `bondage` | `attachment`, `desire`, `bondage` |
| `major_15` | reversed | `release`, `denial`, `compulsion` | `release`, `denial`, `control` |
| `major_16` | upright | `upheaval`, `truth`, `breakthrough` | `change`, `truth`, `threshold` |
| `major_16` | reversed | `resistance`, `instability`, `avoidance` | `resistance`, `instability`, `avoidance` |
| `major_17` | upright | `hope`, `guidance`, `renewal` | `hope`, `guidance`, `renewal` |
| `major_17` | reversed | `discouragement`, `doubt`, `disconnection` | `despair`, `doubt`, `isolation` |
| `major_18` | upright | `illusion`, `subconscious`, `uncertainty` | `illusion`, `mystery`, `uncertainty` |
| `major_18` | reversed | `confusion`, `projection`, `fear` | `confusion`, `projection`, `fear` |
| `major_19` | upright | `clarity`, `vitality`, `joy` | `clarity`, `vitality`, `joy` |
| `major_19` | reversed | `diminishedJoy`, `delay`, `overexposure` | `withdrawal`, `delay`, `overflow` |
| `major_20` | upright | `awakening`, `accountability`, `renewal` | `awakening`, `accountability`, `renewal` |
| `major_20` | reversed | `selfJudgment`, `avoidance`, `doubt` | `judgment`, `avoidance`, `doubt` |
| `major_21` | upright | `completion`, `belonging`, `integration` | `completion`, `belonging`, `integration` |
| `major_21` | reversed | `incompletion`, `delay`, `disconnection` | `completion`, `delay`, `isolation` |
| `pentacles_01` | upright | `firstSeed`, `matterInHand`, `plant` | `spark`, `resource`, `stewardship` |
| `pentacles_01` | reversed | `rushedYield`, `emptyCount`, `unplanted` | `haste`, `scarcity`, `delay` |
| `pentacles_02` | upright | `twoWeights`, `practicalBalance`, `juggle` | `coordination`, `balance`, `focus` |
| `pentacles_02` | reversed | `scatter`, `indecision`, `overGrip` | `scatter`, `indecision`, `control` |
| `pentacles_03` | upright | `sharedCraft`, `workshop`, `wovenWork` | `craft`, `belonging` |
| `pentacles_03` | reversed | `visibilityRace`, `deniedShare`, `unwoven` | `display`, `withdrawal`, `instability` |
| `pentacles_04` | upright | `closedHand`, `thresholdGuard`, `holding` | `scarcity`, `holding` |
| `pentacles_04` | reversed | `lockedGrip`, `refusal`, `fearHold` | `control`, `resistance`, `fear` |
| `pentacles_05` | upright | `outsideThreshold`, `feltScarcity`, `strain` | `holding`, `scarcity`, `strain` |
| `pentacles_05` | reversed | `shame`, `unworthiness`, `closedHelp` | `shame`, `doubt`, `withdrawal` |
| `pentacles_06` | upright | `giveReceive`, `weighedScales`, `share` | `reciprocity`, `fairness`, `belonging` |
| `pentacles_06` | reversed | `mercyDisplay`, `loadedDebt`, `shameReceive` | `display`, `burden`, `shame` |
| `pentacles_07` | upright | `notYetRipe`, `cultivation`, `patience` | `timing`, `stewardship`, `pause` |
| `pentacles_07` | reversed | `frozenWait`, `prematurePull`, `blindDelay` | `coldness`, `haste`, `delay` |
| `pentacles_08` | upright | `repeatingHand`, `mastery`, `discipline` | `cycles`, `mastery`, `discipline` |
| `pentacles_08` | reversed | `mechanicalLoop`, `exhaustion`, `noAdvance` | `cycles`, `exhaustion`, `stagnation` |
| `pentacles_09` | upright | `enoughness`, `ownLabor`, `sufficiency` | `enough`, `craft` |
| `pentacles_09` | reversed | `shopWindow`, `shutSolitude`, `refuseShare` | `display`, `solitude`, `withdrawal` |
| `pentacles_10` | upright | `lastingLineage`, `sharedStructure`, `roots` | `roots`, `structure` |
| `pentacles_10` | reversed | `forcedRole`, `petrifiedRoots`, `lineagePressure` | `socialExpectation`, `rigidity` |
| `pentacles_11` | upright | `studentHand`, `practicalCuriosity`, `matterMessenger` | `learning`, `curiosity`, `messenger` |
| `pentacles_11` | reversed | `rushSell`, `shallowCopy`, `postponeLearn` | `haste`, `display`, `delay` |
| `pentacles_12` | upright | `slowRoad`, `fieldTempo`, `steadfastness` | `pause`, `timing`, `stability` |
| `pentacles_12` | reversed | `rigidity`, `fearOfSpeed`, `noTurn` | `rigidity`, `stability` |
| `pentacles_13` | upright | `practicalCare`, `stewardship`, `fertileHand` | `nurture`, `stewardship` |
| `pentacles_13` | reversed | `smotherControl`, `selfExhaust`, `overTake` | `control`, `exhaustion` |
| `pentacles_14` | upright | `rootedMeans`, `accountability`, `materialDirection` | `roots`, `accountability`, `direction` |
| `pentacles_14` | reversed | `rigidAuthority`, `pressure`, `castLoad` | `rigidity`, `socialExpectation`, `burden` |
| `swords_01` | upright | `firstEdge`, `clearIdea`, `air` | `opening`, `clarity` |
| `swords_01` | reversed | `harshWord`, `scatteredMind`, `cuttingToCut` | `harshSpeech`, `scatter` |
| `swords_02` | upright | `stalemate`, `twoThoughts`, `closedEyes` | `stagnation`, `indecision`, `denial` |
| `swords_02` | reversed | `decisionFlight`, `denial`, `freeze` | `escape`, `denial`, `coldness` |
| `swords_03` | upright | `brokenWord`, `painfulClarity`, `heartEdge` | `truth`, `clarity`, `boundary` |
| `swords_03` | reversed | `dramaticPain`, `blame`, `unclosed` | `grief`, `projection`, `closing` |
| `swords_04` | upright | `rest`, `mindPause`, `sheath` | `pause`, `restraint` |
| `swords_04` | reversed | `escapeSleep`, `defer`, `numbness` | `escape`, `delay`, `withdrawal` |
| `swords_05` | upright | `hollowWin`, `warOfWords`, `hurting` | `illusion`, `harshSpeech`, `grief` |
| `swords_05` | reversed | `humiliation`, `revenge`, `beingLeft` | `shame`, `anger`, `fear` |
| `swords_06` | upright | `crossing`, `calmWater`, `carrying` | `threshold`, `flow`, `burden` |
| `swords_06` | reversed | `escape`, `pastCargo`, `arrivalFear` | `escape`, `burden`, `fear` |
| `swords_07` | upright | `hiding`, `strategy`, `unseenDraw` | `withdrawal`, `discernment`, `ending` |
| `swords_07` | reversed | `theftFeeling`, `mistrust`, `lonePlan` | `fear`, `doubt`, `isolation` |
| `swords_08` | upright | `tightness`, `boundMind`, `ownSword` | `strain`, `bondage`, `harshSpeech` |
| `swords_08` | reversed | `victimStory`, `immobility`, `fearWeb` | `projection`, `stagnation`, `fear` |
| `swords_09` | upright | `nightThought`, `mindLoad`, `worry` | `mindBurden`, `shadow` |
| `swords_09` | reversed | `catastropheDream`, `insomniaIdentity`, `guilt` | `fear`, `mindBurden`, `burden` |
| `swords_10` | upright | `mentalEnding`, `finishedWar`, `enough` | `ending`, `enough` |
| `swords_10` | reversed | `disasterIdentity`, `notRising`, `allOverStory` | `despair`, `stagnation` |
| `swords_11` | upright | `airMessenger`, `sharpStudent`, `question` | `messenger`, `learning`, `inquiry` |
| `swords_11` | reversed | `gossip`, `hastyVerdict`, `notListening` | `harshSpeech`, `haste`, `notListening` |
| `swords_12` | upright | `fastMind`, `wordHorse`, `forwardCut` | `momentum`, `communication`, `clarity` |
| `swords_12` | reversed | `thoughtlessSpeed`, `attackSpeech`, `notListening` | `haste`, `harshSpeech`, `notListening` |
| `swords_13` | upright | `honestBoundary`, `sharpKindness`, `clearWord` | `boundary`, `restraint`, `communication` |
| `swords_13` | reversed | `coldVerdict`, `distanceWeapon`, `bitterTongue` | `harshSpeech`, `coldness` |
| `swords_14` | upright | `principle`, `calmJudgement`, `mindSpine` | `principle`, `judgment` |
| `swords_14` | reversed | `rigidity`, `heartlessRule`, `distanceIdol` | `rigidity`, `coldness` |
| `wands_01` | upright | `spark`, `intent`, `motion` | `spark`, `agency`, `momentum` |
| `wands_01` | reversed | `dulling`, `scatter`, `defer` | `withdrawal`, `scatter`, `delay` |
| `wands_02` | upright | `twoPaths`, `waiting`, `horizon` | `choice`, `pause`, `perspective` |
| `wands_02` | reversed | `indecision`, `hastyPick`, `apathy` | `indecision`, `haste`, `withdrawal` |
| `wands_03` | upright | `growth`, `horizon`, `firstFruit` | `renewal`, `perspective`, `opening` |
| `wands_03` | reversed | `impatience`, `scatter`, `boast` | `impatience`, `scatter`, `boast` |
| `wands_04` | upright | `thresholdFeast`, `root`, `pause` | `holding`, `roots`, `pause` |
| `wands_04` | reversed | `earlyFeast`, `scatter`, `unsettled` | `haste`, `scatter`, `instability` |
| `wands_05` | upright | `trial`, `friction`, `honor` | `strain`, `discord`, `values` |
| `wands_05` | reversed | `defeatStory`, `anger`, `givingUp` | `despair`, `anger` |
| `wands_06` | upright | `crossing`, `notice`, `breath` | `threshold`, `inquiry` |
| `wands_06` | reversed | `boast`, `stuckInPast`, `stage` | `boast`, `bondage`, `display` |
| `wands_07` | upright | `stance`, `boundary`, `fireAlone` | `boundary`, `isolation` |
| `wands_07` | reversed | `siegeFeeling`, `harshness`, `isolation` | `pressure`, `harshSpeech`, `isolation` |
| `wands_08` | upright | `speed`, `news`, `flow` | `momentum`, `messenger`, `flow` |
| `wands_08` | reversed | `haste`, `scatter`, `impatience` | `haste`, `scatter`, `impatience` |
| `wands_09` | upright | `lastFire`, `watch`, `endurance` | `ending`, `restraint` |
| `wands_09` | reversed | `exhaustion`, `doubt`, `loneWar` | `exhaustion`, `doubt`, `isolation` |
| `wands_10` | upright | `load`, `tooMuchFire`, `duty` | `burden`, `scatter`, `accountability` |
| `wands_10` | reversed | `heroPlay`, `collapseFear`, `cannotDelegate` | `display`, `fear`, `control` |
| `wands_11` | upright | `message`, `studentFire`, `curiosity` | `messenger`, `learning`, `curiosity` |
| `wands_11` | reversed | `scatteredZeal`, `boast`, `notListening` | `scatter`, `boast`, `notListening` |
| `wands_12` | upright | `journey`, `passion`, `forwardFire` | `threshold`, `desire`, `direction` |
| `wands_12` | reversed | `haste`, `scatteredPassion`, `seekingBattle` | `haste`, `scatter`, `anger` |
| `wands_13` | upright | `warmHouse`, `matureFire`, `invitation` | `nurture`, `mastery`, `opening` |
| `wands_13` | reversed | `control`, `envy`, `dimming` | `control`, `envy`, `withdrawal` |
| `wands_14` | upright | `directingFire`, `responsibleSpark`, `vision` | `direction`, `spark`, `perspective` |
| `wands_14` | reversed | `pressure`, `ego`, `notListening` | `externalDemand`, `boast`, `notListening` |


## Appendix C — Current→canonical migration table (ACTIVE — 3C.5D.1)

| CURRENT | CLASS | PROPOSED | NOTE |
|---|---|---|---|
| `abundance` | KEEP | `abundance` |  / polarity-checked |
| `accountability` | KEEP | `accountability` |  |
| `agency` | KEEP | `agency` |  / polarity-checked |
| `air` | DROP-AS-DECORATIVE | — | elemental label redundant with suit |
| `airMessenger` | MERGE | `messenger` | suit messenger → messenger / polarity-checked |
| `alchemy` | MERGE | `integration` | imagery merge to integration |
| `allOverStory` | MERGE | `despair` | synonym merge / polarity-checked |
| `anger` | KEEP | `anger` |  / polarity-checked |
| `apathy` | MERGE | `withdrawal` | synonym merge / polarity-checked |
| `arrivalFear` | MERGE | `fear` | synonym merge / polarity-checked |
| `attachment` | KEEP | `attachment` |  |
| `attackSpeech` | RENAME | `harshSpeech` | harmful speech |
| `authority` | KEEP | `authority` |  / polarity-checked |
| `avoidance` | KEEP | `avoidance` |  / polarity-checked |
| `awakening` | KEEP | `awakening` |  / polarity-checked |
| `balance` | KEEP | `balance` | KEEP distinct from stability |
| `beingLeft` | MERGE | `fear` | synonym merge / polarity-checked |
| `belonging` | KEEP | `belonging` |  / polarity-checked |
| `bias` | KEEP | `bias` |  |
| `bitterTongue` | MERGE | `harshSpeech` | synonym merge / polarity-checked |
| `blame` | RENAME | `projection` | heuristic rename blame→projection / polarity-checked |
| `blindDelay` | MERGE | `delay` | synonym merge / polarity-checked |
| `boast` | KEEP | `boast` |  / polarity-checked |
| `bondage` | KEEP | `bondage` |  / polarity-checked |
| `boundMind` | MERGE | `bondage` | synonym merge / polarity-checked |
| `boundary` | KEEP | `boundary` |  / polarity-checked |
| `breakthrough` | RENAME | `threshold` | crossing into new state / polarity-checked |
| `breath` | DROP-AS-DECORATIVE | — | local imagery; no reusable theme signal |
| `brokenWord` | MERGE | `truth` | broken word → truth violated; use truth / polarity-checked |
| `burnLeave` | MERGE | `escape` | synonym merge / polarity-checked |
| `calmBelonging` | MERGE | `belonging` | shared calm belonging collapses to belonging / polarity-checked |
| `calmJudgement` | MERGE | `judgment` | synonym merge / polarity-checked |
| `calmStance` | MERGE | `restraint` | synonym merge / polarity-checked |
| `calmWater` | MERGE | `flow` | calm water → emotional flow / polarity-checked |
| `cannotDelegate` | MERGE | `control` | synonym merge / polarity-checked |
| `carrying` | MERGE | `burden` | synonym merge / polarity-checked |
| `castLoad` | MERGE | `burden` | casting load onto others → burden misdirection; keep burden / polarity-checked |
| `catastropheDream` | MERGE | `fear` | catastrophe scenario → fear (symbolic) / polarity-checked |
| `change` | KEEP | `change` |  / polarity-checked |
| `childRole` | MERGE | `socialExpectation` | synonym merge / polarity-checked |
| `choice` | KEEP | `choice` |  / polarity-checked |
| `clarity` | KEEP | `clarity` |  |
| `clearIdea` | MERGE | `clarity` | synonym merge / polarity-checked |
| `clearWord` | MERGE | `communication` | synonym merge / polarity-checked |
| `closedEyes` | MERGE | `denial` | synonym merge / polarity-checked |
| `closedHand` | MERGE | `scarcity` | synonym merge / polarity-checked |
| `closedHelp` | MERGE | `withdrawal` | synonym merge / polarity-checked |
| `closing` | KEEP | `closing` |  / polarity-checked |
| `coldVerdict` | MERGE | `harshSpeech` | cold verdict speech → harshSpeech / polarity-checked |
| `coldness` | KEEP | `coldness` |  / polarity-checked |
| `collapseFear` | MERGE | `fear` | synonym merge / polarity-checked |
| `compassion` | KEEP | `compassion` |  / polarity-checked |
| `completion` | KEEP | `completion` |  / polarity-checked |
| `compulsion` | MERGE | `control` | compulsive grip — borderline / polarity-checked |
| `conformity` | KEEP | `conformity` |  / polarity-checked |
| `confusion` | KEEP | `confusion` |  / polarity-checked |
| `control` | KEEP | `control` |  |
| `courage` | KEEP | `courage` |  / polarity-checked |
| `craft` | KEEP | `craft` |  / polarity-checked |
| `creation` | KEEP | `creation` |  / polarity-checked |
| `crossing` | MERGE | `threshold` | synonym merge / polarity-checked |
| `cultivation` | MERGE | `stewardship` | synonym merge / polarity-checked |
| `cupLeft` | MERGE | `withdrawal` | synonym merge / polarity-checked |
| `cupOnRoad` | MERGE | `threshold` | synonym merge / polarity-checked |
| `curiosity` | KEEP | `curiosity` |  |
| `cuttingToCut` | MERGE | `harshSpeech` | synonym merge / polarity-checked |
| `cycles` | KEEP | `cycles` |  / polarity-checked |
| `decisionFlight` | MERGE | `escape` | synonym merge / polarity-checked |
| `deeperSearch` | MERGE | `inquiry` | synonym merge / polarity-checked |
| `defeatStory` | MERGE | `despair` | synonym merge / polarity-checked |
| `defer` | MERGE | `delay` | synonym merge / polarity-checked |
| `delay` | KEEP | `delay` |  / polarity-checked |
| `denial` | KEEP | `denial` |  |
| `deniedShare` | MERGE | `withdrawal` | synonym merge / polarity-checked |
| `depletion` | MERGE | `exhaustion` | synonym merge / polarity-checked |
| `desire` | KEEP | `desire` |  / polarity-checked |
| `despair` | KEEP | `despair` |  / polarity-checked |
| `diminishedJoy` | RENAME | `withdrawal` | do not map to joy; diminished state → withdrawal/strain family |
| `dimming` | RENAME | `withdrawal` | warmth dimming |
| `directingFire` | MERGE | `direction` | synonym merge / polarity-checked |
| `direction` | KEEP | `direction` |  |
| `disasterIdentity` | MERGE | `despair` | synonym merge / polarity-checked |
| `discipline` | KEEP | `discipline` |  / polarity-checked |
| `disconnection` | MERGE | `isolation` | synonym merge / polarity-checked |
| `discord` | KEEP | `discord` |  / polarity-checked |
| `discouragement` | MERGE | `despair` | synonym merge / polarity-checked |
| `display` | KEEP | `display` |  |
| `distanceIdol` | MERGE | `coldness` | idolized distance → coldness / polarity-checked |
| `distanceWeapon` | MERGE | `coldness` | weaponized distance → coldness / polarity-checked |
| `dogma` | RENAME | `rigidity` | rigid belief frame / polarity-checked |
| `doubt` | KEEP | `doubt` |  / polarity-checked |
| `dramaticPain` | RENAME | `grief` | heightened pain display → grief register; review if display / polarity-checked |
| `drift` | RENAME | `scatter` | undirected drift / polarity-checked |
| `dulling` | RENAME | `withdrawal` | dulled response / polarity-checked |
| `duty` | RENAME | `accountability` | duty as accountable obligation / polarity-checked |
| `earlyFeast` | RENAME | `haste` | celebration before readiness / polarity-checked |
| `ego` | RENAME | `boast` | self-centering display / polarity-checked |
| `emptyCount` | RENAME | `scarcity` | counting emptiness / polarity-checked |
| `ending` | RENAME | `ending` | heuristic rename ending→ending / polarity-checked |
| `endurance` | RENAME | `ending` | heuristic rename endurance→ending / polarity-checked |
| `enough` | KEEP | `enough` |  / polarity-checked |
| `enoughness` | RENAME | `enough` | heuristic rename enoughness→enough / polarity-checked |
| `envy` | KEEP | `envy` | KEEP distinct from attachment; symbolic only |
| `escape` | KEEP | `escape` |  / polarity-checked |
| `escapeDream` | MERGE | `escape` | dream-escape → escape / polarity-checked |
| `escapeRomance` | MERGE | `escape` | romance-as-escape → escape / polarity-checked |
| `escapeSleep` | RENAME | `escape` | heuristic rename escapeSleep→escape / polarity-checked |
| `exclusion` | RENAME | `isolation` | being shut out / polarity-checked |
| `exhaustion` | KEEP | `exhaustion` |  / polarity-checked |
| `extremes` | RENAME | `imbalance` | polarized extremes |
| `fastMind` | RENAME | `momentum` | directed rapid thought ≠ haste |
| `fear` | KEEP | `fear` |  / polarity-checked |
| `fearHold` | RENAME | `fear` | heuristic rename fearHold→fear / polarity-checked |
| `fearOfSpeed` | MERGE | `rigidity` | synonym merge / polarity-checked |
| `fearWeb` | RENAME | `fear` | heuristic rename fearWeb→fear / polarity-checked |
| `feelingBlind` | RENAME | `confusion` | unable to read feeling / polarity-checked |
| `feelingFlee` | MERGE | `escape` | feeling flees → escape / polarity-checked |
| `feelingLanguage` | MERGE | `receptivity` | synonym merge / polarity-checked |
| `feltScarcity` | RENAME | `scarcity` | heuristic rename feltScarcity→scarcity / polarity-checked |
| `fertileHand` | RENAME | `stewardship` | capable cultivating hand / polarity-checked |
| `fieldTempo` | RENAME | `timing` | pace of the field / polarity-checked |
| `finishedWar` | RENAME | `ending` | conflict concluded / polarity-checked |
| `fireAlone` | RENAME | `isolation` | drive without company / polarity-checked |
| `firstEdge` | RENAME | `opening` | first sharp beginning / polarity-checked |
| `firstFruit` | RENAME | `opening` | first yield / polarity-checked |
| `firstSeed` | RENAME | `spark` | first planted impulse / polarity-checked |
| `firstWater` | MERGE | `opening` | ace water → opening / polarity-checked |
| `flow` | KEEP | `flow` |  |
| `flungOffer` | MERGE | `haste` | synonym merge / polarity-checked |
| `focus` | KEEP | `focus` |  / polarity-checked |
| `forcedJoy` | MERGE | `display` | forced joy → display / polarity-checked |
| `forcedRole` | MERGE | `socialExpectation` | synonym merge / polarity-checked |
| `forwardCut` | RENAME | `clarity` | cutting forward to clear — constructive |
| `forwardFire` | RENAME | `direction` | fire aimed forward / polarity-checked |
| `freedom` | KEEP | `freedom` |  / polarity-checked |
| `freeze` | RENAME | `coldness` | heuristic rename freeze→coldness / polarity-checked |
| `friction` | RENAME | `discord` | relational rub / polarity-checked |
| `friendship` | RENAME | `ending` | heuristic rename friendship→ending / polarity-checked |
| `frozenStance` | MERGE | `rigidity` | synonym merge / polarity-checked |
| `frozenWait` | RENAME | `coldness` | heuristic rename frozenWait→coldness / polarity-checked |
| `fullCup` | RENAME | `enough` | cup already full / polarity-checked |
| `fullTable` | MERGE | `belonging` | table motif → belonging / polarity-checked |
| `gathering` | RENAME | `belonging` | people gathering / polarity-checked |
| `giveReceive` | RENAME | `reciprocity` | give and receive / polarity-checked |
| `givingUp` | RENAME | `despair` | ceding hope / polarity-checked |
| `gossip` | MERGE | `harshSpeech` | gossip as misdirected speech / polarity-checked |
| `grief` | KEEP | `grief` |  / polarity-checked |
| `growth` | RENAME | `renewal` | developmental growth / polarity-checked |
| `guidance` | KEEP | `guidance` |  / polarity-checked |
| `guilt` | MERGE | `burden` | private guilt-load → burden / polarity-checked |
| `halfSearch` | RENAME | `inquiry` | heuristic rename halfSearch→inquiry / polarity-checked |
| `harshWord` | RENAME | `harshSpeech` | heuristic rename harshWord→harshSpeech / polarity-checked |
| `harshness` | RENAME | `harshSpeech` | harsh tone / polarity-checked |
| `haste` | KEEP | `haste` |  |
| `hastyPick` | RENAME | `haste` | choosing too fast / polarity-checked |
| `hastyUnion` | RENAME | `haste` | do not map to union; premature bonding is haste (+ intimacy via other ids) |
| `hastyVerdict` | MERGE | `haste` | synonym merge / polarity-checked |
| `heartEdge` | RENAME | `boundary` | heart-aware edge / polarity-checked |
| `heartlessRule` | MERGE | `rigidity` | synonym merge / polarity-checked |
| `heldCup` | MERGE | `holding` | held cup → holding / polarity-checked |
| `heroPlay` | RENAME | `display` | heroic self-staging / polarity-checked |
| `hiddenCracks` | MERGE | `denial` | synonym merge / polarity-checked |
| `hiding` | RENAME | `withdrawal` | concealing self / polarity-checked |
| `holding` | KEEP | `holding` |  / polarity-checked |
| `hollowWin` | RENAME | `illusion` | victory without substance / polarity-checked |
| `honestBoundary` | MERGE | `boundary` | synonym merge / polarity-checked |
| `honor` | RENAME | `values` | honorable standing / polarity-checked |
| `hope` | KEEP | `hope` |  / polarity-checked |
| `horizon` | MERGE | `perspective` | synonym merge / polarity-checked |
| `humiliation` | RENAME | `shame` | needs lexicon shame / polarity-checked |
| `hurting` | RENAME | `grief` | being hurt / polarity-checked |
| `idealStage` | MERGE | `illusion` | staged belonging → illusion / polarity-checked |
| `illusion` | KEEP | `illusion` |  / polarity-checked |
| `imbalance` | KEEP | `imbalance` | KEEP distinct from balance |
| `immobility` | RENAME | `stagnation` | cannot move / polarity-checked |
| `impatience` | KEEP | `impatience` |  |
| `incompletion` | RENAME | `completion` | heuristic rename incompletion→completion / polarity-checked |
| `indecision` | KEEP | `indecision` |  |
| `inflation` | RENAME | `boast` | inflated self-image / polarity-checked |
| `ingratitude` | RENAME | `discord` | refusal of thanks / polarity-checked |
| `innerEnough` | RENAME | `enough` | heuristic rename innerEnough→enough / polarity-checked |
| `inquiry` | KEEP | `inquiry` |  |
| `insomniaIdentity` | MERGE | `mindBurden` | identifying with sleepless worry → mindBurden / polarity-checked |
| `instability` | KEEP | `instability` | KEEP distinct from stability — no antonym collapse |
| `integration` | KEEP | `integration` |  |
| `intent` | RENAME | `agency` | directed intention / polarity-checked |
| `intuition` | KEEP | `intuition` |  / polarity-checked |
| `invitation` | RENAME | `opening` |  |
| `inwardPause` | RENAME | `pause` | heuristic rename inwardPause→pause / polarity-checked |
| `isolation` | KEEP | `isolation` |  / polarity-checked |
| `journey` | RENAME | `threshold` | path of passage / polarity-checked |
| `joy` | KEEP | `joy` |  |
| `juggle` | RENAME | `coordination` | managing multiple demands upright; not scatter |
| `lastFire` | RENAME | `ending` | final burn / polarity-checked |
| `lastingLineage` | MERGE | `roots` | synonym merge / polarity-checked |
| `lineagePressure` | MERGE | `socialExpectation` | synonym merge / polarity-checked |
| `load` | RENAME | `burden` | heuristic rename load→burden / polarity-checked |
| `loadedDebt` | RENAME | `burden` | heuristic rename loadedDebt→burden / polarity-checked |
| `lockedGrip` | RENAME | `control` | cannot release grip / polarity-checked |
| `lonePlan` | RENAME | `isolation` | planning alone / polarity-checked |
| `loneVictory` | RENAME | `isolation` | winning alone / polarity-checked |
| `loneWar` | RENAME | `isolation` | fighting alone / polarity-checked |
| `manyCups` | RENAME | `overflow` | too many cups / polarity-checked |
| `mastery` | KEEP | `mastery` |  |
| `materialDirection` | RENAME | `direction` | heuristic rename materialDirection→direction / polarity-checked |
| `matterInHand` | RENAME | `resource` | concrete matter present / polarity-checked |
| `matterMessenger` | RENAME | `messenger` | heuristic rename matterMessenger→messenger / polarity-checked |
| `matureFire` | RENAME | `mastery` |  |
| `matureVessel` | RENAME | `stewardship` | seasoned container / polarity-checked |
| `measuredFlow` | RENAME | `flow` | heuristic rename measuredFlow→flow / polarity-checked |
| `mechanicalLoop` | RENAME | `cycles` | compulsive repetition / polarity-checked |
| `memory` | RENAME | `roots` | what is remembered / polarity-checked |
| `mentalEnding` | RENAME | `ending` | heuristic rename mentalEnding→ending / polarity-checked |
| `mercyDisplay` | RENAME | `display` | heuristic rename mercyDisplay→display / polarity-checked |
| `message` | MERGE | `messenger` | message role → messenger / polarity-checked |
| `mindLoad` | MERGE | `mindBurden` | synonym merge / polarity-checked |
| `mindPause` | RENAME | `pause` | heuristic rename mindPause→pause / polarity-checked |
| `mindSpine` | MERGE | `principle` | synonym merge / polarity-checked |
| `mirage` | RENAME | `illusion` | false appearance / polarity-checked |
| `misalignment` | RENAME | `imbalance` | parts not aligned / polarity-checked |
| `missingNow` | RENAME | `escape` | absent from present / polarity-checked |
| `mistrust` | RENAME | `doubt` | distrust / polarity-checked |
| `motion` | RENAME | `momentum` | active motion → momentum |
| `mourning` | RENAME | `grief` | mourning / polarity-checked |
| `movement` | RENAME | `momentum` | active movement → momentum when forward; review if static motion |
| `mystery` | KEEP | `mystery` |  / polarity-checked |
| `neglect` | RENAME | `withdrawal` | failing to tend / polarity-checked |
| `news` | RENAME | `messenger` | brought news |
| `nightThought` | MERGE | `mindBurden` | synonym merge / polarity-checked |
| `noAdvance` | RENAME | `stagnation` | cannot advance / polarity-checked |
| `noBoundary` | RENAME | `boundary` | heuristic rename noBoundary→boundary / polarity-checked |
| `noTurn` | RENAME | `rigidity` | will not turn / polarity-checked |
| `noise` | RENAME | `confusion` | mental noise / polarity-checked |
| `notListening` | KEEP | `notListening` |  |
| `notRising` | RENAME | `stagnation` | fails to rise / polarity-checked |
| `notYetRipe` | RENAME | `timing` | not ready yet / polarity-checked |
| `notice` | RENAME | `inquiry` | noticing / polarity-checked |
| `numbness` | RENAME | `withdrawal` | feeling numbed / polarity-checked |
| `nurture` | KEEP | `nurture` |  |
| `offer` | RENAME | `opening` | offering / polarity-checked |
| `offeredCup` | RENAME | `opening` | cup offered / polarity-checked |
| `oldCup` | RENAME | `roots` | past emotional vessel / polarity-checked |
| `onlyLoss` | RENAME | `despair` | loss-only narrative / polarity-checked |
| `options` | RENAME | `choice` | multiple options / polarity-checked |
| `oracleFeeling` | MERGE | `illusion` | treating feeling as oracle → illusion risk / polarity-checked |
| `outsideThreshold` | RENAME | `holding` | heuristic rename outsideThreshold→holding / polarity-checked |
| `overGrip` | RENAME | `control` | gripping too hard |
| `overSensitivity` | MERGE | `overflow` | excess sensitivity → overflow register / polarity-checked |
| `overTake` | RENAME | `control` | taking over / polarity-checked |
| `overcare` | RENAME | `rescue` | do not map to nurture; overcare is rescue/control-adjacent |
| `overcontrol` | RENAME | `control` | heuristic rename overcontrol→control / polarity-checked |
| `overexposure` | RENAME | `overflow` | too much exposure / polarity-checked |
| `overflow` | KEEP | `overflow` |  / polarity-checked |
| `ownLabor` | RENAME | `craft` | heuristic rename ownLabor→craft / polarity-checked |
| `ownSword` | RENAME | `harshSpeech` | heuristic rename ownSword→harshSpeech / polarity-checked |
| `painfulClarity` | RENAME | `clarity` | heuristic rename painfulClarity→clarity / polarity-checked |
| `passion` | RENAME | `desire` | heated wanting / polarity-checked |
| `pastCargo` | RENAME | `burden` | past weight carried / polarity-checked |
| `pastLock` | RENAME | `bondage` | locked to past / polarity-checked |
| `patience` | RENAME | `pause` | patient waiting / polarity-checked |
| `pause` | KEEP | `pause` |  / polarity-checked |
| `perspective` | KEEP | `perspective` |  / polarity-checked |
| `petrifiedRoots` | MERGE | `rigidity` | roots turned stone → rigidity / polarity-checked |
| `plant` | RENAME | `stewardship` | planting / polarity-checked |
| `postponeLearn` | RENAME | `delay` | heuristic rename postponeLearn→delay / polarity-checked |
| `practicalBalance` | RENAME | `balance` | dynamic practical balance ≠ static stability |
| `practicalCare` | RENAME | `nurture` | heuristic rename practicalCare→nurture / polarity-checked |
| `practicalCuriosity` | RENAME | `curiosity` | heuristic rename practicalCuriosity→curiosity / polarity-checked |
| `prematurePull` | RENAME | `haste` | pulling too soon / polarity-checked |
| `pressure` | SPLIT | `pressure`, `externalDemand`, `internalStrain`, `socialExpectation` | Specialize only where prose clearly supports; else KEEP pressure |
| `principle` | KEEP | `principle` |  / polarity-checked |
| `projection` | KEEP | `projection` |  / polarity-checked |
| `question` | MERGE | `inquiry` | question act → inquiry / polarity-checked |
| `questioning` | RENAME | `learning` | heuristic rename questioning→learning / polarity-checked |
| `quietTaste` | RENAME | `enough` | quiet sufficiency / polarity-checked |
| `reciprocity` | KEEP | `reciprocity` | mutual give-receive / polarity-checked |
| `refusal` | RENAME | `resistance` | refusing / polarity-checked |
| `refuseShare` | RENAME | `withdrawal` | refusing to share / polarity-checked |
| `release` | KEEP | `release` |  / polarity-checked |
| `renewal` | KEEP | `renewal` |  / polarity-checked |
| `repeatingHand` | RENAME | `cycles` | repeating action / polarity-checked |
| `rescuing` | MERGE | `rescue` | synonym merge / polarity-checked |
| `resistance` | KEEP | `resistance` |  / polarity-checked |
| `responsibleSpark` | RENAME | `spark` | heuristic rename responsibleSpark→spark / polarity-checked |
| `rest` | RENAME | `pause` | resting / polarity-checked |
| `restraint` | KEEP | `restraint` |  / polarity-checked |
| `revenge` | RENAME | `anger` | retaliatory heat / polarity-checked |
| `rigidAuthority` | MERGE | `rigidity` | synonym merge / polarity-checked |
| `rigidity` | KEEP | `rigidity` |  / polarity-checked |
| `root` | RENAME | `roots` | heuristic rename root→roots / polarity-checked |
| `rootedMeans` | RENAME | `roots` | heuristic rename rootedMeans→roots / polarity-checked |
| `roots` | KEEP | `roots` |  / polarity-checked |
| `rushSell` | RENAME | `haste` | heuristic rename rushSell→haste / polarity-checked |
| `rushedYield` | RENAME | `haste` | heuristic rename rushedYield→haste / polarity-checked |
| `sacrifice` | RENAME | `release` | giving up for path / polarity-checked |
| `scatter` | KEEP | `scatter` |  |
| `scatteredHeart` | RENAME | `scatter` | heuristic rename scatteredHeart→scatter / polarity-checked |
| `scatteredMind` | RENAME | `scatter` | heuristic rename scatteredMind→scatter / polarity-checked |
| `scatteredPassion` | MERGE | `scatter` | synonym merge / polarity-checked |
| `scatteredZeal` | MERGE | `scatter` | synonym merge / polarity-checked |
| `secrecy` | RENAME | `silence` | kept hidden / polarity-checked |
| `seekingBattle` | MERGE | `anger` | synonym merge / polarity-checked |
| `selfDoubt` | RENAME | `doubt` | heuristic rename selfDoubt→doubt / polarity-checked |
| `selfExhaust` | RENAME | `exhaustion` | heuristic rename selfExhaust→exhaustion / polarity-checked |
| `selfJudgment` | RENAME | `judgment` | heuristic rename selfJudgment→judgment / polarity-checked |
| `shallowCopy` | RENAME | `display` | imitation surface / polarity-checked |
| `shame` | KEEP | `shame` | painful self-regard / polarity-checked |
| `shameReceive` | RENAME | `shame` | receiving shame / polarity-checked |
| `share` | RENAME | `belonging` | sharing / polarity-checked |
| `sharedCircle` | MERGE | `belonging` | circle imagery → belonging / polarity-checked |
| `sharedCraft` | RENAME | `craft` | heuristic rename sharedCraft→craft / polarity-checked |
| `sharedStructure` | MERGE | `structure` | synonym merge / polarity-checked |
| `sharedTable` | RENAME | `belonging` | heuristic rename sharedTable→belonging / polarity-checked |
| `sharpKindness` | MERGE | `restraint` | kind sharpness → restraint / polarity-checked |
| `sharpStudent` | MERGE | `learning` | sharp student → learning / polarity-checked |
| `sheath` | RENAME | `restraint` | sheathing the blade / polarity-checked |
| `shopWindow` | RENAME | `display` | shown for looking / polarity-checked |
| `shutSolitude` | RENAME | `solitude` | heuristic rename shutSolitude→solitude / polarity-checked |
| `siegeFeeling` | RENAME | `pressure` | feeling besieged / polarity-checked |
| `silence` | KEEP | `silence` |  / polarity-checked |
| `simplicity` | RENAME | `clarity` | simple clarity / polarity-checked |
| `slowRoad` | RENAME | `pause` | slow road / polarity-checked |
| `smotherControl` | RENAME | `control` | heuristic rename smotherControl→control / polarity-checked |
| `softCuriosity` | MERGE | `curiosity` | synonym merge / polarity-checked |
| `softOpening` | MERGE | `opening` | soft opening → opening / polarity-checked |
| `solitude` | KEEP | `solitude` |  / polarity-checked |
| `spark` | KEEP | `spark` |  / polarity-checked |
| `speed` | RENAME | `momentum` | neutral rapid motion ≠ haste |
| `spilledCups` | RENAME | `overflow` | cups spilled / polarity-checked |
| `stability` | KEEP | `stability` | KEEP distinct from balance/instability |
| `stage` | RENAME | `display` | staged scene / polarity-checked |
| `stagnation` | KEEP | `stagnation` |  / polarity-checked |
| `stalemate` | RENAME | `stagnation` | no side advances / polarity-checked |
| `stall` | RENAME | `delay` | stalling / polarity-checked |
| `stance` | RENAME | `boundary` | taken stance / polarity-checked |
| `steadfastness` | RENAME | `stability` | holding steady / polarity-checked |
| `steeringWater` | RENAME | `direction` | steering feeling / polarity-checked |
| `stewardship` | KEEP | `stewardship` |  / polarity-checked |
| `stillCup` | RENAME | `pause` | cup held still / polarity-checked |
| `strain` | KEEP | `strain` |  / polarity-checked |
| `strategy` | RENAME | `discernment` | planned discernment / polarity-checked |
| `structure` | KEEP | `structure` |  / polarity-checked |
| `stuckInPast` | RENAME | `bondage` | stuck in past / polarity-checked |
| `studentFire` | MERGE | `learning` | page fire student → learning / polarity-checked |
| `studentHand` | RENAME | `learning` | heuristic rename studentHand→learning / polarity-checked |
| `subconscious` | RENAME | `mystery` | below awareness / polarity-checked |
| `sufficiency` | RENAME | `enough` | enoughness / polarity-checked |
| `suppression` | KEEP | `suppression` |  / polarity-checked |
| `surface` | RENAME | `illusion` | surface only / polarity-checked |
| `surrender` | RENAME | `ending` | heuristic rename surrender→ending / polarity-checked |
| `teaching` | KEEP | `teaching` |  / polarity-checked |
| `theftFeeling` | RENAME | `fear` | feeling robbed — symbolic not accusation / polarity-checked |
| `thoughtlessSpeed` | RENAME | `haste` | reversed thoughtless speed = haste |
| `threshold` | KEEP | `threshold` |  / polarity-checked |
| `thresholdFeast` | RENAME | `holding` | heuristic rename thresholdFeast→holding / polarity-checked |
| `thresholdGuard` | RENAME | `holding` | heuristic rename thresholdGuard→holding / polarity-checked |
| `tightness` | RENAME | `strain` | tight strained hold / polarity-checked |
| `timing` | KEEP | `timing` |  / polarity-checked |
| `tooMuchFire` | RENAME | `scatter` | excess fire energy as scatter — VALID for excess contexts |
| `touchOne` | RENAME | `focus` | touch one thing / polarity-checked |
| `tradition` | KEEP | `tradition` |  / polarity-checked |
| `transformation` | RENAME | `change` | transforming / polarity-checked |
| `trial` | RENAME | `strain` | being tested / polarity-checked |
| `truth` | KEEP | `truth` |  |
| `turning` | RENAME | `change` | turning point / polarity-checked |
| `twoCups` | RENAME | `intimacy` | pair of cups / polarity-checked |
| `twoPaths` | RENAME | `choice` | forked path / polarity-checked |
| `twoThoughts` | RENAME | `indecision` | split thought / polarity-checked |
| `twoWeights` | RENAME | `coordination` | carrying two demands — not imbalance |
| `uncertainty` | KEEP | `uncertainty` |  / polarity-checked |
| `unclosed` | RENAME | `closing` | heuristic rename unclosed→closing / polarity-checked |
| `union` | KEEP | `union` |  |
| `unplanted` | RENAME | `delay` | not yet planted / polarity-checked |
| `unseenDraw` | RENAME | `ending` | heuristic rename unseenDraw→ending / polarity-checked |
| `unsettled` | RENAME | `instability` | not settled / polarity-checked |
| `unworthiness` | RENAME | `doubt` | sense of not deserving / polarity-checked |
| `unwoven` | RENAME | `instability` | coming apart / polarity-checked |
| `upheaval` | RENAME | `change` | sudden upheaval / polarity-checked |
| `values` | KEEP | `values` |  / polarity-checked |
| `victimStory` | RENAME | `projection` | story that assigns victimhood — soft / polarity-checked |
| `visibilityRace` | RENAME | `display` | racing to be seen / polarity-checked |
| `vision` | RENAME | `perspective` | seen future image — non-predictive / polarity-checked |
| `vitality` | KEEP | `vitality` |  / polarity-checked |
| `waiting` | RENAME | `pause` | waiting / polarity-checked |
| `warOfWords` | RENAME | `harshSpeech` | heuristic rename warOfWords→harshSpeech / polarity-checked |
| `warmHouse` | RENAME | `nurture` |  |
| `watch` | RENAME | `restraint` | watching without acting / polarity-checked |
| `waterMessenger` | MERGE | `messenger` | suit messenger → messenger / polarity-checked |
| `weighedScales` | RENAME | `fairness` | scales weighed / polarity-checked |
| `whatStands` | RENAME | `stability` | what still stands / polarity-checked |
| `will` | KEEP | `will` |  / polarity-checked |
| `wisdom` | KEEP | `wisdom` |  / polarity-checked |
| `withdrawal` | KEEP | `withdrawal` |  |
| `wordHorse` | RENAME | `communication` | speech in motion — not harshSpeech |
| `workshop` | RENAME | `craft` | heuristic rename workshop→craft / polarity-checked |
| `worry` | RENAME | `mindBurden` | heuristic rename worry→mindBurden / polarity-checked |
| `wovenWork` | RENAME | `craft` | heuristic rename wovenWork→craft / polarity-checked |

