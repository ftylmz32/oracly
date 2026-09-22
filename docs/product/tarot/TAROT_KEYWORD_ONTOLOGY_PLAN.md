# Tarot Keyword Ontology Plan — Phase 3C.5D / FR-M04

**Status:** DESIGN ONLY — not implemented  
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

| CURRENT | Issue | Provisional |
|---|---|---|
| `envy` | Distinct concept vs merge into `attachment`? | **NEEDS-HUMAN-DECISION** — provisional `attachment` |
| `pressure` SPLIT | Confirm per-card specialization table | Draft specialization exists; review each card |
| `balance`→`stability` | Sometimes balance is active equilibration, not stability | Acceptable? or KEEP `balance` in lexicon |
| `inquiry` vs `curiosity` | Closely related; both kept — confirm court Pages don’t collapse |
| `delay` as keyword + transform | Content vs mechanism double-marking | Allow with lint exception |
| High-frequency `scatter`/`haste` | Soft-weight floors for engine scoring | Confirm weight curve |

**Ambiguous count for hard stop:** **1** primary (`envy`) + **5** review notes above.

---

## 17. Implementation scope recommendation

**Next task (after ChatGPT review):** FR-M04 implementation only:

- Apply keywordId remaps on all 78 profiles (upright + reversed)  
- Add ontology constants module (canonical id list + optional docs)  
- Add enforcement tests for gates in §15  
- **Do not** start Narrative Evidence Engine in the same phase  
- **Do not** modify prose, symbolTags, or transforms unless a blocking contradiction appears (then STOP)

**Deck ready for Evidence Engine after successful FR-M04 implementation + review:** still requires explicit readiness decision; this design alone does **not** flip readiness to YES.

---

## Appendix A — Canonical lexicon


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
| `courage` | willingness to face risk |
| `craft` | skilled making / practiced ability |
| `creation` | bringing something into form |
| `curiosity` | open desire to learn |
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
| `imbalance` | lost equilibrium |
| `impatience` | intolerance of waiting |
| `indecision` | inability to choose |
| `inquiry` | asking to understand |
| `instability` | unsteady ground |
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
| `mystery` | what remains unknown |
| `notListening` | refusal or failure to hear |
| `nurture` | care that sustains growth |
| `opening` | first soft beginning |
| `overflow` | feeling beyond what can be held |
| `pause` | chosen stilling |
| `perspective` | shifted vantage |
| `pressure` | external or internal force to perform |
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
| `stability` | steady lasting ground |
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


## Appendix B — Full 78×orientation mapping

| Card | Ori | CURRENT | PROPOSED | Rationale |
|---|---|---|---|---|
| `cups_01` | upright | `firstWater`, `heldCup`, `softOpening` | `opening`, `holding` | map current→canonical; density 2–4; orientation-distinct |
| `cups_01` | reversed | `overflow`, `closing`, `feelingFlee` | `overflow`, `closing`, `escape` | map current→canonical; preserve transform content without duplicating transform enums |
| `cups_02` | upright | `twoCups`, `reciprocity`, `offeredCup` | `intimacy`, `reciprocity`, `opening` | map current→canonical; density 2–4; orientation-distinct |
| `cups_02` | reversed | `imbalance`, `projection`, `hastyUnion` | `imbalance`, `projection`, `union` | map current→canonical; preserve transform content without duplicating transform enums |
| `cups_03` | upright | `sharedTable`, `friendship`, `gathering` | `belonging`, `ending` | map current→canonical; density 2–4; orientation-distinct |
| `cups_03` | reversed | `surface`, `exclusion`, `noise` | `illusion`, `isolation`, `confusion` | map current→canonical; preserve transform content without duplicating transform enums |
| `cups_04` | upright | `stillCup`, `enough`, `inwardPause` | `pause`, `enough` | map current→canonical; density 2–4; orientation-distinct |
| `cups_04` | reversed | `ingratitude`, `escape`, `feelingBlind` | `discord`, `escape`, `confusion` | map current→canonical; preserve transform content without duplicating transform enums |
| `cups_05` | upright | `spilledCups`, `mourning`, `whatStands` | `overflow`, `grief`, `stability` | map current→canonical; density 2–4; orientation-distinct |
| `cups_05` | reversed | `onlyLoss`, `despair`, `denial` | `despair`, `denial` | map current→canonical; preserve transform content without duplicating transform enums |
| `cups_06` | upright | `oldCup`, `memory`, `simplicity` | `roots`, `clarity` | map current→canonical; density 2–4; orientation-distinct |
| `cups_06` | reversed | `pastLock`, `childRole`, `missingNow` | `bondage`, `socialExpectation`, `escape` | map current→canonical; preserve transform content without duplicating transform enums |
| `cups_07` | upright | `manyCups`, `options`, `touchOne` | `overflow`, `choice`, `focus` | map current→canonical; density 2–4; orientation-distinct |
| `cups_07` | reversed | `escapeDream`, `indecision`, `mirage` | `escape`, `indecision`, `illusion` | map current→canonical; preserve transform content without duplicating transform enums |
| `cups_08` | upright | `cupLeft`, `deeperSearch`, `turning` | `withdrawal`, `inquiry`, `change` | map current→canonical; density 2–4; orientation-distinct |
| `cups_08` | reversed | `burnLeave`, `escape`, `halfSearch` | `escape`, `inquiry` | map current→canonical; preserve transform content without duplicating transform enums |
| `cups_09` | upright | `fullCup`, `innerEnough`, `quietTaste` | `enough`, `joy` | map current→canonical; density 2–4; orientation-distinct |
| `cups_09` | reversed | `inflation`, `loneVictory`, `display` | `boast`, `isolation`, `display` | map current→canonical; preserve transform content without duplicating transform enums |
| `cups_10` | upright | `fullTable`, `sharedCircle`, `calmBelonging` | `belonging`, `union` | map current→canonical; density 2–4; orientation-distinct |
| `cups_10` | reversed | `idealStage`, `forcedJoy`, `hiddenCracks` | `illusion`, `display`, `denial` | map current→canonical; preserve transform content without duplicating transform enums |
| `cups_11` | upright | `waterMessenger`, `softCuriosity`, `feelingLanguage` | `messenger`, `curiosity`, `receptivity` | map current→canonical; density 2–4; orientation-distinct |
| `cups_11` | reversed | `overSensitivity`, `escapeDream`, `oracleFeeling` | `overflow`, `escape`, `illusion` | map current→canonical; preserve transform content without duplicating transform enums |
| `cups_12` | upright | `cupOnRoad`, `offer`, `flow` | `threshold`, `opening`, `flow` | map current→canonical; density 2–4; orientation-distinct |
| `cups_12` | reversed | `scatteredHeart`, `escapeRomance`, `flungOffer` | `scatter`, `escape`, `haste` | map current→canonical; preserve transform content without duplicating transform enums |
| `cups_13` | upright | `matureVessel`, `compassion`, `holding` | `stewardship`, `compassion`, `holding` | map current→canonical; density 2–4; orientation-distinct |
| `cups_13` | reversed | `overflow`, `noBoundary`, `rescuing` | `overflow`, `boundary`, `rescue` | map current→canonical; preserve transform content without duplicating transform enums |
| `cups_14` | upright | `steeringWater`, `measuredFlow`, `calmStance` | `direction`, `flow`, `restraint` | map current→canonical; density 2–4; orientation-distinct |
| `cups_14` | reversed | `coldness`, `suppression`, `frozenStance` | `coldness`, `suppression`, `rigidity` | map current→canonical; preserve transform content without duplicating transform enums |
| `major_00` | upright | `threshold`, `curiosity`, `freedom` | `threshold`, `curiosity`, `freedom` | map current→canonical; density 2–4; orientation-distinct |
| `major_00` | reversed | `haste`, `scatter`, `avoidance` | `haste`, `scatter`, `avoidance` | map current→canonical; preserve transform content without duplicating transform enums |
| `major_01` | upright | `craft`, `focus`, `agency` | `craft`, `focus`, `agency` | map current→canonical; density 2–4; orientation-distinct |
| `major_01` | reversed | `scatter`, `control`, `doubt` | `scatter`, `control`, `doubt` | map current→canonical; preserve transform content without duplicating transform enums |
| `major_02` | upright | `silence`, `intuition`, `mystery` | `silence`, `intuition`, `mystery` | map current→canonical; density 2–4; orientation-distinct |
| `major_02` | reversed | `secrecy`, `confusion`, `withdrawal` | `silence`, `confusion`, `withdrawal` | map current→canonical; preserve transform content without duplicating transform enums |
| `major_03` | upright | `nurture`, `abundance`, `creation` | `nurture`, `abundance`, `creation` | map current→canonical; density 2–4; orientation-distinct |
| `major_03` | reversed | `depletion`, `overcare`, `neglect` | `exhaustion`, `nurture`, `withdrawal` | map current→canonical; preserve transform content without duplicating transform enums |
| `major_04` | upright | `structure`, `authority`, `stability` | `structure`, `authority`, `stability` | map current→canonical; density 2–4; orientation-distinct |
| `major_04` | reversed | `rigidity`, `control`, `instability` | `rigidity`, `control`, `stability` | map current→canonical; preserve transform content without duplicating transform enums |
| `major_05` | upright | `teaching`, `tradition`, `values` | `teaching`, `tradition`, `values` | map current→canonical; density 2–4; orientation-distinct |
| `major_05` | reversed | `conformity`, `dogma`, `questioning` | `conformity`, `rigidity`, `learning` | map current→canonical; preserve transform content without duplicating transform enums |
| `major_06` | upright | `choice`, `union`, `values` | `choice`, `union`, `values` | map current→canonical; density 2–4; orientation-distinct |
| `major_06` | reversed | `discord`, `indecision`, `misalignment` | `discord`, `indecision`, `imbalance` | map current→canonical; preserve transform content without duplicating transform enums |
| `major_07` | upright | `movement`, `will`, `direction` | `direction`, `will` | map current→canonical; density 2–4; orientation-distinct |
| `major_07` | reversed | `stall`, `drift`, `overcontrol` | `delay`, `scatter`, `control` | map current→canonical; preserve transform content without duplicating transform enums |
| `major_08` | upright | `courage`, `compassion`, `restraint` | `courage`, `compassion`, `restraint` | map current→canonical; density 2–4; orientation-distinct |
| `major_08` | reversed | `selfDoubt`, `suppression`, `strain` | `doubt`, `suppression`, `strain` | map current→canonical; preserve transform content without duplicating transform enums |
| `major_09` | upright | `solitude`, `wisdom`, `inquiry` | `solitude`, `wisdom`, `inquiry` | map current→canonical; density 2–4; orientation-distinct |
| `major_09` | reversed | `isolation`, `withdrawal`, `silence` | `isolation`, `withdrawal`, `silence` | map current→canonical; preserve transform content without duplicating transform enums |
| `major_10` | upright | `cycles`, `change`, `timing` | `cycles`, `change`, `timing` | map current→canonical; density 2–4; orientation-distinct |
| `major_10` | reversed | `resistance`, `delay`, `instability` | `resistance`, `delay`, `stability` | map current→canonical; preserve transform content without duplicating transform enums |
| `major_11` | upright | `balance`, `truth`, `accountability` | `stability`, `truth`, `accountability` | map current→canonical; density 2–4; orientation-distinct |
| `major_11` | reversed | `bias`, `denial`, `imbalance` | `bias`, `denial`, `imbalance` | map current→canonical; preserve transform content without duplicating transform enums |
| `major_12` | upright | `surrender`, `perspective`, `pause` | `ending`, `perspective`, `pause` | map current→canonical; density 2–4; orientation-distinct |
| `major_12` | reversed | `stagnation`, `resistance`, `sacrifice` | `stagnation`, `resistance`, `release` | map current→canonical; preserve transform content without duplicating transform enums |
| `major_13` | upright | `transformation`, `release`, `ending` | `change`, `release`, `ending` | map current→canonical; density 2–4; orientation-distinct |
| `major_13` | reversed | `resistance`, `stagnation`, `grief` | `resistance`, `stagnation`, `grief` | map current→canonical; preserve transform content without duplicating transform enums |
| `major_14` | upright | `balance`, `integration`, `alchemy` | `stability`, `integration` | map current→canonical; density 2–4; orientation-distinct |
| `major_14` | reversed | `imbalance`, `haste`, `extremes` | `imbalance`, `haste` | map current→canonical; preserve transform content without duplicating transform enums |
| `major_15` | upright | `attachment`, `desire`, `bondage` | `attachment`, `desire`, `bondage` | map current→canonical; density 2–4; orientation-distinct |
| `major_15` | reversed | `release`, `denial`, `compulsion` | `release`, `denial`, `control` | map current→canonical; preserve transform content without duplicating transform enums |
| `major_16` | upright | `upheaval`, `truth`, `breakthrough` | `change`, `truth`, `threshold` | map current→canonical; density 2–4; orientation-distinct |
| `major_16` | reversed | `resistance`, `instability`, `avoidance` | `resistance`, `stability`, `avoidance` | map current→canonical; preserve transform content without duplicating transform enums |
| `major_17` | upright | `hope`, `guidance`, `renewal` | `hope`, `guidance`, `renewal` | map current→canonical; density 2–4; orientation-distinct |
| `major_17` | reversed | `discouragement`, `doubt`, `disconnection` | `despair`, `doubt`, `isolation` | map current→canonical; preserve transform content without duplicating transform enums |
| `major_18` | upright | `illusion`, `subconscious`, `uncertainty` | `illusion`, `mystery`, `uncertainty` | map current→canonical; density 2–4; orientation-distinct |
| `major_18` | reversed | `confusion`, `projection`, `fear` | `confusion`, `projection`, `fear` | map current→canonical; preserve transform content without duplicating transform enums |
| `major_19` | upright | `clarity`, `vitality`, `joy` | `clarity`, `vitality`, `joy` | map current→canonical; density 2–4; orientation-distinct |
| `major_19` | reversed | `diminishedJoy`, `delay`, `overexposure` | `joy`, `delay`, `overflow` | map current→canonical; preserve transform content without duplicating transform enums |
| `major_20` | upright | `awakening`, `accountability`, `renewal` | `awakening`, `accountability`, `renewal` | map current→canonical; density 2–4; orientation-distinct |
| `major_20` | reversed | `selfJudgment`, `avoidance`, `doubt` | `judgment`, `avoidance`, `doubt` | map current→canonical; preserve transform content without duplicating transform enums |
| `major_21` | upright | `completion`, `belonging`, `integration` | `completion`, `belonging`, `integration` | map current→canonical; density 2–4; orientation-distinct |
| `major_21` | reversed | `incompletion`, `delay`, `disconnection` | `completion`, `delay`, `isolation` | map current→canonical; preserve transform content without duplicating transform enums |
| `pentacles_01` | upright | `firstSeed`, `matterInHand`, `plant` | `spark`, `resource`, `stewardship` | map current→canonical; density 2–4; orientation-distinct |
| `pentacles_01` | reversed | `rushedYield`, `emptyCount`, `unplanted` | `haste`, `scarcity`, `delay` | map current→canonical; preserve transform content without duplicating transform enums |
| `pentacles_02` | upright | `twoWeights`, `practicalBalance`, `juggle` | `imbalance`, `stability`, `scatter` | map current→canonical; density 2–4; orientation-distinct |
| `pentacles_02` | reversed | `scatter`, `indecision`, `overGrip` | `scatter`, `indecision`, `control` | map current→canonical; preserve transform content without duplicating transform enums |
| `pentacles_03` | upright | `sharedCraft`, `workshop`, `wovenWork` | `craft`, `belonging` | map current→canonical; density 2–4; orientation-distinct |
| `pentacles_03` | reversed | `visibilityRace`, `deniedShare`, `unwoven` | `display`, `withdrawal`, `instability` | map current→canonical; preserve transform content without duplicating transform enums |
| `pentacles_04` | upright | `closedHand`, `thresholdGuard`, `holding` | `scarcity`, `holding` | map current→canonical; density 2–4; orientation-distinct |
| `pentacles_04` | reversed | `lockedGrip`, `refusal`, `fearHold` | `control`, `resistance`, `fear` | map current→canonical; preserve transform content without duplicating transform enums |
| `pentacles_05` | upright | `outsideThreshold`, `feltScarcity`, `strain` | `holding`, `scarcity`, `strain` | map current→canonical; density 2–4; orientation-distinct |
| `pentacles_05` | reversed | `shame`, `unworthiness`, `closedHelp` | `shame`, `doubt`, `withdrawal` | map current→canonical; preserve transform content without duplicating transform enums |
| `pentacles_06` | upright | `giveReceive`, `weighedScales`, `share` | `reciprocity`, `fairness`, `belonging` | map current→canonical; density 2–4; orientation-distinct |
| `pentacles_06` | reversed | `mercyDisplay`, `loadedDebt`, `shameReceive` | `display`, `burden`, `shame` | map current→canonical; preserve transform content without duplicating transform enums |
| `pentacles_07` | upright | `notYetRipe`, `cultivation`, `patience` | `timing`, `stewardship`, `pause` | map current→canonical; density 2–4; orientation-distinct |
| `pentacles_07` | reversed | `frozenWait`, `prematurePull`, `blindDelay` | `coldness`, `haste`, `delay` | map current→canonical; preserve transform content without duplicating transform enums |
| `pentacles_08` | upright | `repeatingHand`, `mastery`, `discipline` | `cycles`, `mastery`, `discipline` | map current→canonical; density 2–4; orientation-distinct |
| `pentacles_08` | reversed | `mechanicalLoop`, `exhaustion`, `noAdvance` | `cycles`, `exhaustion`, `stagnation` | map current→canonical; preserve transform content without duplicating transform enums |
| `pentacles_09` | upright | `enoughness`, `ownLabor`, `sufficiency` | `enough`, `craft` | map current→canonical; density 2–4; orientation-distinct |
| `pentacles_09` | reversed | `shopWindow`, `shutSolitude`, `refuseShare` | `display`, `solitude`, `withdrawal` | map current→canonical; preserve transform content without duplicating transform enums |
| `pentacles_10` | upright | `lastingLineage`, `sharedStructure`, `roots` | `roots`, `structure` | map current→canonical; density 2–4; orientation-distinct |
| `pentacles_10` | reversed | `forcedRole`, `petrifiedRoots`, `lineagePressure` | `socialExpectation`, `rigidity` | map current→canonical; preserve transform content without duplicating transform enums |
| `pentacles_11` | upright | `studentHand`, `practicalCuriosity`, `matterMessenger` | `learning`, `curiosity`, `messenger` | map current→canonical; density 2–4; orientation-distinct |
| `pentacles_11` | reversed | `rushSell`, `shallowCopy`, `postponeLearn` | `haste`, `display`, `delay` | map current→canonical; preserve transform content without duplicating transform enums |
| `pentacles_12` | upright | `slowRoad`, `fieldTempo`, `steadfastness` | `pause`, `timing`, `stability` | map current→canonical; density 2–4; orientation-distinct |
| `pentacles_12` | reversed | `rigidity`, `fearOfSpeed`, `noTurn` | `rigidity`, `stability` | map current→canonical; preserve transform content without duplicating transform enums |
| `pentacles_13` | upright | `practicalCare`, `stewardship`, `fertileHand` | `nurture`, `stewardship` | map current→canonical; density 2–4; orientation-distinct |
| `pentacles_13` | reversed | `smotherControl`, `selfExhaust`, `overTake` | `control`, `exhaustion` | map current→canonical; preserve transform content without duplicating transform enums |
| `pentacles_14` | upright | `rootedMeans`, `accountability`, `materialDirection` | `roots`, `accountability`, `direction` | map current→canonical; density 2–4; orientation-distinct |
| `pentacles_14` | reversed | `rigidAuthority`, `pressure`, `castLoad` | `rigidity`, `socialExpectation`, `burden` | map current→canonical; preserve transform content without duplicating transform enums |
| `swords_01` | upright | `firstEdge`, `clearIdea`, `air` | `opening`, `clarity` | map current→canonical; density 2–4; orientation-distinct |
| `swords_01` | reversed | `harshWord`, `scatteredMind`, `cuttingToCut` | `harshSpeech`, `scatter` | map current→canonical; preserve transform content without duplicating transform enums |
| `swords_02` | upright | `stalemate`, `twoThoughts`, `closedEyes` | `stagnation`, `indecision`, `denial` | map current→canonical; density 2–4; orientation-distinct |
| `swords_02` | reversed | `decisionFlight`, `denial`, `freeze` | `escape`, `denial`, `coldness` | map current→canonical; preserve transform content without duplicating transform enums |
| `swords_03` | upright | `brokenWord`, `painfulClarity`, `heartEdge` | `truth`, `clarity`, `boundary` | map current→canonical; density 2–4; orientation-distinct |
| `swords_03` | reversed | `dramaticPain`, `blame`, `unclosed` | `grief`, `projection`, `closing` | map current→canonical; preserve transform content without duplicating transform enums |
| `swords_04` | upright | `rest`, `mindPause`, `sheath` | `pause`, `restraint` | map current→canonical; density 2–4; orientation-distinct |
| `swords_04` | reversed | `escapeSleep`, `defer`, `numbness` | `escape`, `delay`, `withdrawal` | map current→canonical; preserve transform content without duplicating transform enums |
| `swords_05` | upright | `hollowWin`, `warOfWords`, `hurting` | `illusion`, `harshSpeech`, `grief` | map current→canonical; density 2–4; orientation-distinct |
| `swords_05` | reversed | `humiliation`, `revenge`, `beingLeft` | `shame`, `anger`, `fear` | map current→canonical; preserve transform content without duplicating transform enums |
| `swords_06` | upright | `crossing`, `calmWater`, `carrying` | `threshold`, `flow`, `burden` | map current→canonical; density 2–4; orientation-distinct |
| `swords_06` | reversed | `escape`, `pastCargo`, `arrivalFear` | `escape`, `burden`, `fear` | map current→canonical; preserve transform content without duplicating transform enums |
| `swords_07` | upright | `hiding`, `strategy`, `unseenDraw` | `withdrawal`, `discernment`, `ending` | map current→canonical; density 2–4; orientation-distinct |
| `swords_07` | reversed | `theftFeeling`, `mistrust`, `lonePlan` | `fear`, `doubt`, `isolation` | map current→canonical; preserve transform content without duplicating transform enums |
| `swords_08` | upright | `tightness`, `boundMind`, `ownSword` | `strain`, `bondage`, `harshSpeech` | map current→canonical; density 2–4; orientation-distinct |
| `swords_08` | reversed | `victimStory`, `immobility`, `fearWeb` | `projection`, `stagnation`, `fear` | map current→canonical; preserve transform content without duplicating transform enums |
| `swords_09` | upright | `nightThought`, `mindLoad`, `worry` | `mindBurden`, `shadow` | map current→canonical; density 2–4; orientation-distinct |
| `swords_09` | reversed | `catastropheDream`, `insomniaIdentity`, `guilt` | `fear`, `mindBurden`, `burden` | map current→canonical; preserve transform content without duplicating transform enums |
| `swords_10` | upright | `mentalEnding`, `finishedWar`, `enough` | `ending`, `enough` | map current→canonical; density 2–4; orientation-distinct |
| `swords_10` | reversed | `disasterIdentity`, `notRising`, `allOverStory` | `despair`, `stagnation` | map current→canonical; preserve transform content without duplicating transform enums |
| `swords_11` | upright | `airMessenger`, `sharpStudent`, `question` | `messenger`, `learning`, `inquiry` | map current→canonical; density 2–4; orientation-distinct |
| `swords_11` | reversed | `gossip`, `hastyVerdict`, `notListening` | `harshSpeech`, `haste`, `notListening` | map current→canonical; preserve transform content without duplicating transform enums |
| `swords_12` | upright | `fastMind`, `wordHorse`, `forwardCut` | `haste`, `harshSpeech`, `clarity` | map current→canonical; density 2–4; orientation-distinct |
| `swords_12` | reversed | `thoughtlessSpeed`, `attackSpeech`, `notListening` | `haste`, `harshSpeech`, `notListening` | map current→canonical; preserve transform content without duplicating transform enums |
| `swords_13` | upright | `honestBoundary`, `sharpKindness`, `clearWord` | `boundary`, `restraint`, `communication` | map current→canonical; density 2–4; orientation-distinct |
| `swords_13` | reversed | `coldVerdict`, `distanceWeapon`, `bitterTongue` | `harshSpeech`, `coldness` | map current→canonical; preserve transform content without duplicating transform enums |
| `swords_14` | upright | `principle`, `calmJudgement`, `mindSpine` | `principle`, `judgment` | map current→canonical; density 2–4; orientation-distinct |
| `swords_14` | reversed | `rigidity`, `heartlessRule`, `distanceIdol` | `rigidity`, `coldness` | map current→canonical; preserve transform content without duplicating transform enums |
| `wands_01` | upright | `spark`, `intent`, `motion` | `spark`, `agency`, `direction` | map current→canonical; density 2–4; orientation-distinct |
| `wands_01` | reversed | `dulling`, `scatter`, `defer` | `withdrawal`, `scatter`, `delay` | map current→canonical; preserve transform content without duplicating transform enums |
| `wands_02` | upright | `twoPaths`, `waiting`, `horizon` | `choice`, `pause`, `perspective` | map current→canonical; density 2–4; orientation-distinct |
| `wands_02` | reversed | `indecision`, `hastyPick`, `apathy` | `indecision`, `haste`, `withdrawal` | map current→canonical; preserve transform content without duplicating transform enums |
| `wands_03` | upright | `growth`, `horizon`, `firstFruit` | `renewal`, `perspective`, `opening` | map current→canonical; density 2–4; orientation-distinct |
| `wands_03` | reversed | `impatience`, `scatter`, `boast` | `impatience`, `scatter`, `boast` | map current→canonical; preserve transform content without duplicating transform enums |
| `wands_04` | upright | `thresholdFeast`, `root`, `pause` | `holding`, `roots`, `pause` | map current→canonical; density 2–4; orientation-distinct |
| `wands_04` | reversed | `earlyFeast`, `scatter`, `unsettled` | `haste`, `scatter`, `instability` | map current→canonical; preserve transform content without duplicating transform enums |
| `wands_05` | upright | `trial`, `friction`, `honor` | `strain`, `discord`, `values` | map current→canonical; density 2–4; orientation-distinct |
| `wands_05` | reversed | `defeatStory`, `anger`, `givingUp` | `despair`, `anger` | map current→canonical; preserve transform content without duplicating transform enums |
| `wands_06` | upright | `crossing`, `notice`, `breath` | `threshold`, `inquiry` | map current→canonical; density 2–4; orientation-distinct |
| `wands_06` | reversed | `boast`, `stuckInPast`, `stage` | `boast`, `bondage`, `display` | map current→canonical; preserve transform content without duplicating transform enums |
| `wands_07` | upright | `stance`, `boundary`, `fireAlone` | `boundary`, `isolation` | map current→canonical; density 2–4; orientation-distinct |
| `wands_07` | reversed | `siegeFeeling`, `harshness`, `isolation` | `pressure`, `harshSpeech`, `isolation` | map current→canonical; preserve transform content without duplicating transform enums |
| `wands_08` | upright | `speed`, `news`, `flow` | `haste`, `messenger`, `flow` | map current→canonical; density 2–4; orientation-distinct |
| `wands_08` | reversed | `haste`, `scatter`, `impatience` | `haste`, `scatter`, `impatience` | map current→canonical; preserve transform content without duplicating transform enums |
| `wands_09` | upright | `lastFire`, `watch`, `endurance` | `ending`, `restraint` | map current→canonical; density 2–4; orientation-distinct |
| `wands_09` | reversed | `exhaustion`, `doubt`, `loneWar` | `exhaustion`, `doubt`, `isolation` | map current→canonical; preserve transform content without duplicating transform enums |
| `wands_10` | upright | `load`, `tooMuchFire`, `duty` | `burden`, `scatter`, `accountability` | map current→canonical; density 2–4; orientation-distinct |
| `wands_10` | reversed | `heroPlay`, `collapseFear`, `cannotDelegate` | `display`, `fear`, `control` | map current→canonical; preserve transform content without duplicating transform enums |
| `wands_11` | upright | `message`, `studentFire`, `curiosity` | `messenger`, `learning`, `curiosity` | map current→canonical; density 2–4; orientation-distinct |
| `wands_11` | reversed | `scatteredZeal`, `boast`, `notListening` | `scatter`, `boast`, `notListening` | map current→canonical; preserve transform content without duplicating transform enums |
| `wands_12` | upright | `journey`, `passion`, `forwardFire` | `threshold`, `desire`, `direction` | map current→canonical; density 2–4; orientation-distinct |
| `wands_12` | reversed | `haste`, `scatteredPassion`, `seekingBattle` | `haste`, `scatter`, `anger` | map current→canonical; preserve transform content without duplicating transform enums |
| `wands_13` | upright | `warmHouse`, `matureFire`, `invitation` | `nurture`, `mastery`, `opening` | map current→canonical; density 2–4; orientation-distinct |
| `wands_13` | reversed | `control`, `envy`, `dimming` | `control`, `attachment`, `withdrawal` | map current→canonical; preserve transform content without duplicating transform enums |
| `wands_14` | upright | `directingFire`, `responsibleSpark`, `vision` | `direction`, `spark`, `perspective` | map current→canonical; density 2–4; orientation-distinct |
| `wands_14` | reversed | `pressure`, `ego`, `notListening` | `externalDemand`, `boast`, `notListening` | map current→canonical; preserve transform content without duplicating transform enums |


## Appendix C — Current→canonical migration table

| CURRENT | CLASS | PROPOSED | NOTE |
|---|---|---|---|
| `abundance` | KEEP | `abundance` |  |
| `accountability` | KEEP | `accountability` |  |
| `agency` | KEEP | `agency` |  |
| `air` | DROP-AS-DECORATIVE | — | elemental label redundant with suit |
| `airMessenger` | MERGE | `messenger` | suit messenger → messenger |
| `alchemy` | MERGE | `integration` | synonym merge |
| `allOverStory` | MERGE | `despair` | synonym merge |
| `anger` | KEEP | `anger` |  |
| `apathy` | MERGE | `withdrawal` | synonym merge |
| `arrivalFear` | MERGE | `fear` | synonym merge |
| `attachment` | KEEP | `attachment` |  |
| `attackSpeech` | MERGE | `harshSpeech` | synonym merge |
| `authority` | KEEP | `authority` |  |
| `avoidance` | KEEP | `avoidance` |  |
| `awakening` | KEEP | `awakening` |  |
| `balance` | MERGE | `stability` | balance → stability family unless contrasting |
| `beingLeft` | MERGE | `fear` | synonym merge |
| `belonging` | KEEP | `belonging` |  |
| `bias` | KEEP | `bias` |  |
| `bitterTongue` | MERGE | `harshSpeech` | synonym merge |
| `blame` | RENAME | `projection` | heuristic rename blame→projection |
| `blindDelay` | MERGE | `delay` | synonym merge |
| `boast` | KEEP | `boast` |  |
| `bondage` | KEEP | `bondage` |  |
| `boundMind` | MERGE | `bondage` | synonym merge |
| `boundary` | KEEP | `boundary` |  |
| `breakthrough` | RENAME | `threshold` | crossing into new state |
| `breath` | DROP-AS-DECORATIVE | — | local imagery; no reusable theme signal |
| `brokenWord` | MERGE | `truth` | broken word → truth violated; use truth |
| `burnLeave` | MERGE | `escape` | synonym merge |
| `calmBelonging` | MERGE | `belonging` | shared calm belonging collapses to belonging |
| `calmJudgement` | MERGE | `judgment` | synonym merge |
| `calmStance` | MERGE | `restraint` | synonym merge |
| `calmWater` | MERGE | `flow` | calm water → emotional flow |
| `cannotDelegate` | MERGE | `control` | synonym merge |
| `carrying` | MERGE | `burden` | synonym merge |
| `castLoad` | MERGE | `burden` | casting load onto others → burden misdirection; keep burden |
| `catastropheDream` | MERGE | `fear` | catastrophe scenario → fear (symbolic) |
| `change` | KEEP | `change` |  |
| `childRole` | MERGE | `socialExpectation` | synonym merge |
| `choice` | KEEP | `choice` |  |
| `clarity` | KEEP | `clarity` |  |
| `clearIdea` | MERGE | `clarity` | synonym merge |
| `clearWord` | MERGE | `communication` | synonym merge |
| `closedEyes` | MERGE | `denial` | synonym merge |
| `closedHand` | MERGE | `scarcity` | synonym merge |
| `closedHelp` | MERGE | `withdrawal` | synonym merge |
| `closing` | KEEP | `closing` |  |
| `coldVerdict` | MERGE | `harshSpeech` | cold verdict speech → harshSpeech |
| `coldness` | KEEP | `coldness` |  |
| `collapseFear` | MERGE | `fear` | synonym merge |
| `compassion` | KEEP | `compassion` |  |
| `completion` | KEEP | `completion` |  |
| `compulsion` | MERGE | `control` | compulsive grip — borderline |
| `conformity` | KEEP | `conformity` |  |
| `confusion` | KEEP | `confusion` |  |
| `control` | KEEP | `control` |  |
| `courage` | KEEP | `courage` |  |
| `craft` | KEEP | `craft` |  |
| `creation` | KEEP | `creation` |  |
| `crossing` | MERGE | `threshold` | synonym merge |
| `cultivation` | MERGE | `stewardship` | synonym merge |
| `cupLeft` | MERGE | `withdrawal` | synonym merge |
| `cupOnRoad` | MERGE | `threshold` | synonym merge |
| `curiosity` | KEEP | `curiosity` |  |
| `cuttingToCut` | MERGE | `harshSpeech` | synonym merge |
| `cycles` | KEEP | `cycles` |  |
| `decisionFlight` | MERGE | `escape` | synonym merge |
| `deeperSearch` | MERGE | `inquiry` | synonym merge |
| `defeatStory` | MERGE | `despair` | synonym merge |
| `defer` | MERGE | `delay` | synonym merge |
| `delay` | KEEP | `delay` |  |
| `denial` | RENAME | `denial` | heuristic rename denial→denial |
| `deniedShare` | MERGE | `withdrawal` | synonym merge |
| `depletion` | MERGE | `exhaustion` | synonym merge |
| `desire` | KEEP | `desire` |  |
| `despair` | KEEP | `despair` |  |
| `diminishedJoy` | MERGE | `joy` | note: reversed valence via orientation |
| `dimming` | MERGE | `withdrawal` | synonym merge |
| `directingFire` | MERGE | `direction` | synonym merge |
| `direction` | KEEP | `direction` |  |
| `disasterIdentity` | MERGE | `despair` | synonym merge |
| `discipline` | KEEP | `discipline` |  |
| `disconnection` | MERGE | `isolation` | synonym merge |
| `discord` | KEEP | `discord` |  |
| `discouragement` | MERGE | `despair` | synonym merge |
| `display` | KEEP | `display` |  |
| `distanceIdol` | MERGE | `coldness` | idolized distance → coldness |
| `distanceWeapon` | MERGE | `coldness` | weaponized distance → coldness |
| `dogma` | RENAME | `rigidity` | rigid belief frame |
| `doubt` | KEEP | `doubt` |  |
| `dramaticPain` | RENAME | `grief` | heightened pain display → grief register; review if display |
| `drift` | RENAME | `scatter` | undirected drift |
| `dulling` | RENAME | `withdrawal` | dulled response |
| `duty` | RENAME | `accountability` | duty as accountable obligation |
| `earlyFeast` | RENAME | `haste` | celebration before readiness |
| `ego` | RENAME | `boast` | self-centering display |
| `emptyCount` | RENAME | `scarcity` | counting emptiness |
| `ending` | RENAME | `ending` | heuristic rename ending→ending |
| `endurance` | RENAME | `ending` | heuristic rename endurance→ending |
| `enough` | KEEP | `enough` |  |
| `enoughness` | RENAME | `enough` | heuristic rename enoughness→enough |
| `envy` | NEEDS-HUMAN-DECISION | `attachment` | Keep envy distinct? Default merge to attachment pending review |
| `escape` | KEEP | `escape` |  |
| `escapeDream` | MERGE | `escape` | dream-escape → escape |
| `escapeRomance` | MERGE | `escape` | romance-as-escape → escape |
| `escapeSleep` | RENAME | `escape` | heuristic rename escapeSleep→escape |
| `exclusion` | RENAME | `isolation` | being shut out |
| `exhaustion` | KEEP | `exhaustion` |  |
| `extremes` | RENAME | `imbalance` | polarized extremes |
| `fastMind` | RENAME | `haste` | mind outrunning readiness |
| `fear` | KEEP | `fear` |  |
| `fearHold` | RENAME | `fear` | heuristic rename fearHold→fear |
| `fearOfSpeed` | MERGE | `rigidity` | synonym merge |
| `fearWeb` | RENAME | `fear` | heuristic rename fearWeb→fear |
| `feelingBlind` | RENAME | `confusion` | unable to read feeling |
| `feelingFlee` | MERGE | `escape` | feeling flees → escape |
| `feelingLanguage` | MERGE | `receptivity` | synonym merge |
| `feltScarcity` | RENAME | `scarcity` | heuristic rename feltScarcity→scarcity |
| `fertileHand` | RENAME | `stewardship` | capable cultivating hand |
| `fieldTempo` | RENAME | `timing` | pace of the field |
| `finishedWar` | RENAME | `ending` | conflict concluded |
| `fireAlone` | RENAME | `isolation` | drive without company |
| `firstEdge` | RENAME | `opening` | first sharp beginning |
| `firstFruit` | RENAME | `opening` | first yield |
| `firstSeed` | RENAME | `spark` | first planted impulse |
| `firstWater` | MERGE | `opening` | ace water → opening |
| `flow` | KEEP | `flow` |  |
| `flungOffer` | MERGE | `haste` | synonym merge |
| `focus` | KEEP | `focus` |  |
| `forcedJoy` | MERGE | `display` | forced joy → display |
| `forcedRole` | MERGE | `socialExpectation` | synonym merge |
| `forwardCut` | RENAME | `clarity` | cutting forward to clear |
| `forwardFire` | RENAME | `direction` | fire aimed forward |
| `freedom` | KEEP | `freedom` |  |
| `freeze` | RENAME | `coldness` | heuristic rename freeze→coldness |
| `friction` | RENAME | `discord` | relational rub |
| `friendship` | RENAME | `ending` | heuristic rename friendship→ending |
| `frozenStance` | MERGE | `rigidity` | synonym merge |
| `frozenWait` | RENAME | `coldness` | heuristic rename frozenWait→coldness |
| `fullCup` | RENAME | `enough` | cup already full |
| `fullTable` | MERGE | `belonging` | table motif → belonging |
| `gathering` | RENAME | `belonging` | people gathering |
| `giveReceive` | RENAME | `reciprocity` | give and receive |
| `givingUp` | RENAME | `despair` | ceding hope |
| `gossip` | MERGE | `harshSpeech` | gossip as misdirected speech |
| `grief` | KEEP | `grief` |  |
| `growth` | RENAME | `renewal` | developmental growth |
| `guidance` | KEEP | `guidance` |  |
| `guilt` | MERGE | `burden` | private guilt-load → burden |
| `halfSearch` | RENAME | `inquiry` | heuristic rename halfSearch→inquiry |
| `harshWord` | RENAME | `harshSpeech` | heuristic rename harshWord→harshSpeech |
| `harshness` | RENAME | `harshSpeech` | harsh tone |
| `haste` | KEEP | `haste` |  |
| `hastyPick` | RENAME | `haste` | choosing too fast |
| `hastyUnion` | RENAME | `union` | heuristic rename hastyUnion→union |
| `hastyVerdict` | MERGE | `haste` | synonym merge |
| `heartEdge` | RENAME | `boundary` | heart-aware edge |
| `heartlessRule` | MERGE | `rigidity` | synonym merge |
| `heldCup` | MERGE | `holding` | held cup → holding |
| `heroPlay` | RENAME | `display` | heroic self-staging |
| `hiddenCracks` | MERGE | `denial` | synonym merge |
| `hiding` | RENAME | `withdrawal` | concealing self |
| `holding` | KEEP | `holding` |  |
| `hollowWin` | RENAME | `illusion` | victory without substance |
| `honestBoundary` | MERGE | `boundary` | synonym merge |
| `honor` | RENAME | `values` | honorable standing |
| `hope` | KEEP | `hope` |  |
| `horizon` | MERGE | `perspective` | synonym merge |
| `humiliation` | RENAME | `shame` | needs lexicon shame |
| `hurting` | RENAME | `grief` | being hurt |
| `idealStage` | MERGE | `illusion` | staged belonging → illusion |
| `illusion` | KEEP | `illusion` |  |
| `imbalance` | KEEP | `imbalance` |  |
| `immobility` | RENAME | `stagnation` | cannot move |
| `impatience` | KEEP | `impatience` |  |
| `incompletion` | RENAME | `completion` | heuristic rename incompletion→completion |
| `indecision` | KEEP | `indecision` |  |
| `inflation` | RENAME | `boast` | inflated self-image |
| `ingratitude` | RENAME | `discord` | refusal of thanks |
| `innerEnough` | RENAME | `enough` | heuristic rename innerEnough→enough |
| `inquiry` | KEEP | `inquiry` |  |
| `insomniaIdentity` | MERGE | `mindBurden` | identifying with sleepless worry → mindBurden |
| `instability` | RENAME | `stability` | heuristic rename instability→stability |
| `integration` | KEEP | `integration` |  |
| `intent` | RENAME | `agency` | directed intention |
| `intuition` | KEEP | `intuition` |  |
| `invitation` | RENAME | `opening` | invite to begin |
| `inwardPause` | RENAME | `pause` | heuristic rename inwardPause→pause |
| `isolation` | KEEP | `isolation` |  |
| `journey` | RENAME | `threshold` | path of passage |
| `joy` | KEEP | `joy` |  |
| `juggle` | RENAME | `scatter` | too many held at once |
| `lastFire` | RENAME | `ending` | final burn |
| `lastingLineage` | MERGE | `roots` | synonym merge |
| `lineagePressure` | MERGE | `socialExpectation` | synonym merge |
| `load` | RENAME | `burden` | heuristic rename load→burden |
| `loadedDebt` | RENAME | `burden` | heuristic rename loadedDebt→burden |
| `lockedGrip` | RENAME | `control` | cannot release grip |
| `lonePlan` | RENAME | `isolation` | planning alone |
| `loneVictory` | RENAME | `isolation` | winning alone |
| `loneWar` | RENAME | `isolation` | fighting alone |
| `manyCups` | RENAME | `overflow` | too many cups |
| `mastery` | KEEP | `mastery` |  |
| `materialDirection` | RENAME | `direction` | heuristic rename materialDirection→direction |
| `matterInHand` | RENAME | `resource` | concrete matter present |
| `matterMessenger` | RENAME | `messenger` | heuristic rename matterMessenger→messenger |
| `matureFire` | RENAME | `mastery` | seasoned fire |
| `matureVessel` | RENAME | `stewardship` | seasoned container |
| `measuredFlow` | RENAME | `flow` | heuristic rename measuredFlow→flow |
| `mechanicalLoop` | RENAME | `cycles` | compulsive repetition |
| `memory` | RENAME | `roots` | what is remembered |
| `mentalEnding` | RENAME | `ending` | heuristic rename mentalEnding→ending |
| `mercyDisplay` | RENAME | `display` | heuristic rename mercyDisplay→display |
| `message` | MERGE | `messenger` | message role → messenger |
| `mindLoad` | MERGE | `mindBurden` | synonym merge |
| `mindPause` | RENAME | `pause` | heuristic rename mindPause→pause |
| `mindSpine` | MERGE | `principle` | synonym merge |
| `mirage` | RENAME | `illusion` | false appearance |
| `misalignment` | RENAME | `imbalance` | parts not aligned |
| `missingNow` | RENAME | `escape` | absent from present |
| `mistrust` | RENAME | `doubt` | distrust |
| `motion` | RENAME | `direction` | movement underway |
| `mourning` | RENAME | `grief` | mourning |
| `movement` | RENAME | `direction` | active movement |
| `mystery` | KEEP | `mystery` |  |
| `neglect` | RENAME | `withdrawal` | failing to tend |
| `news` | RENAME | `messenger` | brought news |
| `nightThought` | MERGE | `mindBurden` | synonym merge |
| `noAdvance` | RENAME | `stagnation` | cannot advance |
| `noBoundary` | RENAME | `boundary` | heuristic rename noBoundary→boundary |
| `noTurn` | RENAME | `rigidity` | will not turn |
| `noise` | RENAME | `confusion` | mental noise |
| `notListening` | MERGE | `notListening` | synonym merge |
| `notRising` | RENAME | `stagnation` | fails to rise |
| `notYetRipe` | RENAME | `timing` | not ready yet |
| `notice` | RENAME | `inquiry` | noticing |
| `numbness` | RENAME | `withdrawal` | feeling numbed |
| `nurture` | KEEP | `nurture` |  |
| `offer` | RENAME | `opening` | offering |
| `offeredCup` | RENAME | `opening` | cup offered |
| `oldCup` | RENAME | `roots` | past emotional vessel |
| `onlyLoss` | RENAME | `despair` | loss-only narrative |
| `options` | RENAME | `choice` | multiple options |
| `oracleFeeling` | MERGE | `illusion` | treating feeling as oracle → illusion risk |
| `outsideThreshold` | RENAME | `holding` | heuristic rename outsideThreshold→holding |
| `overGrip` | RENAME | `control` | gripping too hard |
| `overSensitivity` | MERGE | `overflow` | excess sensitivity → overflow register |
| `overTake` | RENAME | `control` | taking over |
| `overcare` | RENAME | `nurture` | heuristic rename overcare→nurture |
| `overcontrol` | RENAME | `control` | heuristic rename overcontrol→control |
| `overexposure` | RENAME | `overflow` | too much exposure |
| `overflow` | KEEP | `overflow` |  |
| `ownLabor` | RENAME | `craft` | heuristic rename ownLabor→craft |
| `ownSword` | RENAME | `harshSpeech` | heuristic rename ownSword→harshSpeech |
| `painfulClarity` | RENAME | `clarity` | heuristic rename painfulClarity→clarity |
| `passion` | RENAME | `desire` | heated wanting |
| `pastCargo` | RENAME | `burden` | past weight carried |
| `pastLock` | RENAME | `bondage` | locked to past |
| `patience` | RENAME | `pause` | patient waiting |
| `pause` | KEEP | `pause` |  |
| `perspective` | KEEP | `perspective` |  |
| `petrifiedRoots` | MERGE | `rigidity` | roots turned stone → rigidity |
| `plant` | RENAME | `stewardship` | planting |
| `postponeLearn` | RENAME | `delay` | heuristic rename postponeLearn→delay |
| `practicalBalance` | RENAME | `stability` | heuristic rename practicalBalance→stability |
| `practicalCare` | RENAME | `nurture` | heuristic rename practicalCare→nurture |
| `practicalCuriosity` | RENAME | `curiosity` | heuristic rename practicalCuriosity→curiosity |
| `prematurePull` | RENAME | `haste` | pulling too soon |
| `pressure` | SPLIT | `pressure`, `externalDemand`, `internalStrain`, `socialExpectation` | Specialize by card: lineage/role→socialExpectation; self-push→internalStrain; outer force→externalDemand |
| `principle` | KEEP | `principle` |  |
| `projection` | KEEP | `projection` |  |
| `question` | MERGE | `inquiry` | question act → inquiry |
| `questioning` | RENAME | `learning` | heuristic rename questioning→learning |
| `quietTaste` | RENAME | `enough` | quiet sufficiency |
| `reciprocity` | KEEP | `reciprocity` | mutual give-receive |
| `refusal` | RENAME | `resistance` | refusing |
| `refuseShare` | RENAME | `withdrawal` | refusing to share |
| `release` | KEEP | `release` |  |
| `renewal` | KEEP | `renewal` |  |
| `repeatingHand` | RENAME | `cycles` | repeating action |
| `rescuing` | MERGE | `rescue` | synonym merge |
| `resistance` | KEEP | `resistance` |  |
| `responsibleSpark` | RENAME | `spark` | heuristic rename responsibleSpark→spark |
| `rest` | RENAME | `pause` | resting |
| `restraint` | KEEP | `restraint` |  |
| `revenge` | RENAME | `anger` | retaliatory heat |
| `rigidAuthority` | MERGE | `rigidity` | synonym merge |
| `rigidity` | KEEP | `rigidity` |  |
| `root` | RENAME | `roots` | heuristic rename root→roots |
| `rootedMeans` | RENAME | `roots` | heuristic rename rootedMeans→roots |
| `roots` | KEEP | `roots` |  |
| `rushSell` | RENAME | `haste` | heuristic rename rushSell→haste |
| `rushedYield` | RENAME | `haste` | heuristic rename rushedYield→haste |
| `sacrifice` | RENAME | `release` | giving up for path |
| `scatter` | KEEP | `scatter` |  |
| `scatteredHeart` | RENAME | `scatter` | heuristic rename scatteredHeart→scatter |
| `scatteredMind` | RENAME | `scatter` | heuristic rename scatteredMind→scatter |
| `scatteredPassion` | MERGE | `scatter` | synonym merge |
| `scatteredZeal` | MERGE | `scatter` | synonym merge |
| `secrecy` | RENAME | `silence` | kept hidden |
| `seekingBattle` | MERGE | `anger` | synonym merge |
| `selfDoubt` | RENAME | `doubt` | heuristic rename selfDoubt→doubt |
| `selfExhaust` | RENAME | `exhaustion` | heuristic rename selfExhaust→exhaustion |
| `selfJudgment` | RENAME | `judgment` | heuristic rename selfJudgment→judgment |
| `shallowCopy` | RENAME | `display` | imitation surface |
| `shame` | KEEP | `shame` | painful self-regard |
| `shameReceive` | RENAME | `shame` | receiving shame |
| `share` | RENAME | `belonging` | sharing |
| `sharedCircle` | MERGE | `belonging` | circle imagery → belonging |
| `sharedCraft` | RENAME | `craft` | heuristic rename sharedCraft→craft |
| `sharedStructure` | MERGE | `structure` | synonym merge |
| `sharedTable` | RENAME | `belonging` | heuristic rename sharedTable→belonging |
| `sharpKindness` | MERGE | `restraint` | kind sharpness → restraint |
| `sharpStudent` | MERGE | `learning` | sharp student → learning |
| `sheath` | RENAME | `restraint` | sheathing the blade |
| `shopWindow` | RENAME | `display` | shown for looking |
| `shutSolitude` | RENAME | `solitude` | heuristic rename shutSolitude→solitude |
| `siegeFeeling` | RENAME | `pressure` | feeling besieged |
| `silence` | KEEP | `silence` |  |
| `simplicity` | RENAME | `clarity` | simple clarity |
| `slowRoad` | RENAME | `pause` | slow road |
| `smotherControl` | RENAME | `control` | heuristic rename smotherControl→control |
| `softCuriosity` | MERGE | `curiosity` | synonym merge |
| `softOpening` | MERGE | `opening` | soft opening → opening |
| `solitude` | KEEP | `solitude` |  |
| `spark` | KEEP | `spark` |  |
| `speed` | RENAME | `haste` | speed as haste risk |
| `spilledCups` | RENAME | `overflow` | cups spilled |
| `stability` | KEEP | `stability` |  |
| `stage` | RENAME | `display` | staged scene |
| `stagnation` | KEEP | `stagnation` |  |
| `stalemate` | RENAME | `stagnation` | no side advances |
| `stall` | RENAME | `delay` | stalling |
| `stance` | RENAME | `boundary` | taken stance |
| `steadfastness` | RENAME | `stability` | holding steady |
| `steeringWater` | RENAME | `direction` | steering feeling |
| `stewardship` | KEEP | `stewardship` |  |
| `stillCup` | RENAME | `pause` | cup held still |
| `strain` | KEEP | `strain` |  |
| `strategy` | RENAME | `discernment` | planned discernment |
| `structure` | KEEP | `structure` |  |
| `stuckInPast` | RENAME | `bondage` | stuck in past |
| `studentFire` | MERGE | `learning` | page fire student → learning |
| `studentHand` | RENAME | `learning` | heuristic rename studentHand→learning |
| `subconscious` | RENAME | `mystery` | below awareness |
| `sufficiency` | RENAME | `enough` | enoughness |
| `suppression` | KEEP | `suppression` |  |
| `surface` | RENAME | `illusion` | surface only |
| `surrender` | RENAME | `ending` | heuristic rename surrender→ending |
| `teaching` | KEEP | `teaching` |  |
| `theftFeeling` | RENAME | `fear` | feeling robbed — symbolic not accusation |
| `thoughtlessSpeed` | RENAME | `haste` | heuristic rename thoughtlessSpeed→haste |
| `threshold` | KEEP | `threshold` |  |
| `thresholdFeast` | RENAME | `holding` | heuristic rename thresholdFeast→holding |
| `thresholdGuard` | RENAME | `holding` | heuristic rename thresholdGuard→holding |
| `tightness` | RENAME | `strain` | tight strained hold |
| `timing` | KEEP | `timing` |  |
| `tooMuchFire` | RENAME | `scatter` | excess fire energy |
| `touchOne` | RENAME | `focus` | touch one thing |
| `tradition` | KEEP | `tradition` |  |
| `transformation` | RENAME | `change` | transforming |
| `trial` | RENAME | `strain` | being tested |
| `truth` | KEEP | `truth` |  |
| `turning` | RENAME | `change` | turning point |
| `twoCups` | RENAME | `intimacy` | pair of cups |
| `twoPaths` | RENAME | `choice` | forked path |
| `twoThoughts` | RENAME | `indecision` | split thought |
| `twoWeights` | RENAME | `imbalance` | uneven weights |
| `uncertainty` | KEEP | `uncertainty` |  |
| `unclosed` | RENAME | `closing` | heuristic rename unclosed→closing |
| `union` | KEEP | `union` |  |
| `unplanted` | RENAME | `delay` | not yet planted |
| `unseenDraw` | RENAME | `ending` | heuristic rename unseenDraw→ending |
| `unsettled` | RENAME | `instability` | not settled |
| `unworthiness` | RENAME | `doubt` | sense of not deserving |
| `unwoven` | RENAME | `instability` | coming apart |
| `upheaval` | RENAME | `change` | sudden upheaval |
| `values` | KEEP | `values` |  |
| `victimStory` | RENAME | `projection` | story that assigns victimhood — soft |
| `visibilityRace` | RENAME | `display` | racing to be seen |
| `vision` | RENAME | `perspective` | seen future image — non-predictive |
| `vitality` | KEEP | `vitality` |  |
| `waiting` | RENAME | `pause` | waiting |
| `warOfWords` | RENAME | `harshSpeech` | heuristic rename warOfWords→harshSpeech |
| `warmHouse` | RENAME | `nurture` | warm household |
| `watch` | RENAME | `restraint` | watching without acting |
| `waterMessenger` | MERGE | `messenger` | suit messenger → messenger |
| `weighedScales` | RENAME | `fairness` | scales weighed |
| `whatStands` | RENAME | `stability` | what still stands |
| `will` | KEEP | `will` |  |
| `wisdom` | KEEP | `wisdom` |  |
| `withdrawal` | KEEP | `withdrawal` |  |
| `wordHorse` | RENAME | `harshSpeech` | heuristic rename wordHorse→harshSpeech |
| `workshop` | RENAME | `craft` | heuristic rename workshop→craft |
| `worry` | RENAME | `mindBurden` | heuristic rename worry→mindBurden |
| `wovenWork` | RENAME | `craft` | heuristic rename wovenWork→craft |

