# Dream Phase 4C.1 — Live Findings Remediation (offline)

**Status:** remediated offline · Phase 4C.2 model A/B **designed, not run**
**Start HEAD:** `5ebed44c08cc3f71157726e2fbc0b3a58a35c473`
**Real provider calls:** 0 · **Production model changed:** no · **Deployed:** no

Phase 4C captured 36 real `gpt-4o` Dream readings (writer revision `4b`) and
recorded, without fixing, why only 2 passed the backend. Phase 4C.1 separates
the rejections into three kinds and fixes only the first and third:

- **Gate false positive** — the gate refused a truthful reading. Fixed.
- **Writer quality defect** — the reading is genuinely weak. Not hidden: the
  gate still refuses it; the writer contract was tightened for future output.
- **Infrastructure defect** — a pipeline mechanic, not a judgement. Fixed.

The frozen evidence is only read, never rewritten:
`evals/DREAM_PHASE4C_LIVE_RUN_20260928.json` and
`evals/DREAM_PHASE4C_CLIENT_REPLAY_20260928.json` (SHA-256 of both pinned in the
reclassification artifact and checked by test; `analyze.ts` now refuses to
rewrite an analysed artifact).

---

## 1. GATE FALSE POSITIVE FIXED

### 1.1 Phase 4A — history claim scope (`dream-history-claim-unit.ts`)

A recurring-motif claim was attributed to the whole sentence, so an appositive
or relative clause ("…, a recurring symbol in your dreams, …") made every other
word in the sentence part of the history claim.

| Run | Live sentence (frozen) |
|---|---|
| en-history | "The sea, a recurring symbol in your dreams, might represent a familiar space of reflection." |
| en-history#r2 | "The sea, a recurring element in your dreams, suggests a familiar source of calm and reflection." |
| tr-history#r2 | "Denizin tekrarlayan bir motif olması, belki de bu huzurun … ya da sık sık arandığını gösteriyor." |
| ru-history#r2 | "Спокойствие, которое повторяется в снах, может свидетельствовать о потребности в стабильности или отдыхе." |

Fix: the sentence is split on `, ( ) [ ] :` and dashes. A claim chunk with no
content word of its own binds only the chunk before it (the appositive/relative
head); a Turkish nominalised claim (`-ması/-mesi`) binds up to itself; any other
claim keeps the whole sentence. Saved-history wording and invented counts keep
whole-sentence scope, and bare TR "sık sık" / "defalarca" count as a claim only
before an appearance verb. Emotion history items (`emotion:peaceful`) are named
by an affirmed canonical feeling ("Спокойствие").

The Phase 4A.4 attribute bug stays closed: "red sea", "stormy sea",
"Kapıda beklemek", "Denizin sesi", "Свет в окне" still reject, and the count,
date, fate and absolute safeguards are unchanged (contract tests).

### 1.2 Emotion negation — TR / RU (`dream-emotion-contract.ts`)

| Run | Live `emotionalTheme` (frozen) |
|---|---|
| tr-negated-fear | "Merak ve sakinlik duygusu ön plandaydı; korku hissedilmiyordu." |
| ru-negated-fear | "Любопытство преобладает над страхом, открытие чего-то нового и светлого." |
| ru-negated-fear#r2 | "Любопытство и отсутствие страха." |

Fix: TR passive negation (`hissedilmiyordu`, `hissedilmedi`, `duyulmadı`) and
the fillers `hissi` / `duygusu` ("korku hissi yoktu"); RU `отсутствие` directly
before the feeling; a feeling subordinated by "преобладает над / prevails over /
outweighs" is neither affirmed nor negated. A true contradiction ("I was not
afraid" → "Fear dominates the dream.") still rejects.

### 1.3 Personal domains (`dream-personal-facts.ts`)

| Run | Live text (frozen) | Old flag |
|---|---|---|
| en-history, en-history#r2 | "a familiar space / source of …" | family |
| ru-domain-family | "…неустойчивости в семейных отношениях, особенно учитывая ваше желание наладить контакт с сестрой." | relationship |
| en-mixed-emotion(#r2) | "…your current relationships or situations…" / "past relationships" (dreamer: "an old friend") | relationship |
| tr-mixed-emotion | "Çocukluk evinin mutfağında…" (dreamer: "çocukken yaşadığım ev") | childhood |

Fix: `familiar` is no longer family (`famil\p{L}*` removed). "Relationship"
words resolve by their qualifier — family within two words → family; romantic
qualifier or singular "your relationship" → romantic; otherwise a new `social`
domain supported by family, romantic or friend evidence. A friend never supports
a romantic claim, and "Your relationship is entering a new phase." with no
domain evidence still rejects. `çocukken / ребенком / child` now count as
childhood evidence.

### 1.4 Plot recap (`dream-narrative-anchors.ts`)

| Run | Live `summary` (frozen) |
|---|---|
| en-mixed-emotion | "A bittersweet farewell at a train station with an old friend." |

The old detector rejected any summary whose words were mostly copied, so a
one-line compression was treated as a recap. `isPlotRecap` now also requires a
copied contiguous run ≥ 6 words or ≥ 6 distinct copied anchors. `RECAP_MAX_SHARE`
was not raised. Verbatim and scene-by-scene recaps still reject.

### 1.5 emotionalTheme role grounding (`dream-premium-quality.ts` + client)

The emotional theme's job is to name the stated feelings, yet it was held to the
same "must touch a dream image" rule as the summary. It is now grounded by a
dream anchor **or** a canonical feeling the dreamer stated (same stance).
Summary and interpretation stay strict. Client parity: `DreamGuardRole` on
`DreamAnalysisGuard`, `DreamStatedFeeling.shares`, and the composer passes the
provider evidence emotions. In the frozen replay this moved emotionalTheme from
local to AI in four diagnostic runs, the only client drift allowed by test.
`en-negated-fear` ("a sense of curiosity and calmness despite the unknown") is
still `ungrounded_section`, because the dreamer stated neither feeling.

## 2. INFRASTRUCTURE DEFECT FIXED

### 2.1 Provider symbol array (`dream-symbol-grounding.ts`, `dream-acceptance.ts`)

A single invented item in the `symbols` array rejected the whole reading.

| Run | Raw symbols | Removed |
|---|---|---|
| tr-domain-work | toplantı odası, slaytlar, sessizlik | sessizlik |
| en-negated-fear(#r2) | lake, darkness, ripples, pale light | darkness |
| en-mixed-emotion#r2 | train station, old friend, train, laughing, crying | crying |
| ru-no-domain(#r2) | платформа, поезд, часы, пустота | пустота |
| ru-memory | перекрёсток, туман, освещённая дорога, тёмная дорога | перекрёсток |

New order: parse → output safety on the **raw** body (raw symbols included) →
strict symbol filter (unchanged `sameStrict`) → Phase 2 → 4A → 4B on the
sanitized body; only the sanitized body is returned. A removed item that also
appears in prose rejects as `invented_symbol` (no hiding a prose
hallucination). An empty array is allowed; the client falls back to its local
symbol section.

#### 2.1a Safe derivation, not shared prefixes (Phase 4C.1a)

The first 4C.1 leak check treated a removed item as harmless when it shared
its first four letters with a told word. That re-opened prefix collisions:
told "door", provider `doorway`, prose "The doorway on the beach…" passed.
The prefix rule is removed. Since Phase 4C.1b a removed word is another form
of a told word only when `sameStrict` accepts it (same word or a grammatical
inflection), or both complete words reduce to the same root by one
recognised suffix (`derivationRoot`):

| Language | Recognised suffix | Min root | Passes | Still leaks |
|---|---|---|---|---|
| en | `-ness` (root not ending in i); `-ing/-ed/-es/-s` with i→y | 4 / 3 | dark ↔ darkness, cried ↔ crying | door → doorway, water → waterfall, rain → rainbow, fear → fearless |
| tr | adverb `-ca/-ce`, noun `-lık/-lik/-luk/-lük` | 4 | sessizce ↔ sessizlik | kapı → kapıcı, deniz → denizci |
| ru | adjective endings, abstract noun `-ота` | 4 | пустой ↔ пустота | стол → столица, красный → красота, вода → водопад, дверь → дворец |

This allowance only decides whether a removed item named in prose is a leak.
The array itself stays strict (`sameStrict`): `darkness` for a told "dark
lake" is still removed, while "The darkness beside the lake…" in prose is
accepted. The offline reclassification re-derived unchanged (36 runs, 7 PASS,
no verdict moved). Restoring the prefix rule fails 10 tests.

#### 2.1b The leak gate no longer uses `sameWord` (Phase 4C.1b)

4C.1a still accepted the general Phase 2 prose matcher `sameWord`, whose
shared six-letter lead let candle → candlestick, station → stationary,
window → windowsill and forest → forestry pass as "the same word". The leak
gate now uses only the rule above. `sameWord` itself is unchanged and still
relates those pairs for general prose grounding (pinned by test). Offline
reclassification unchanged; restoring `sameWord` in the leak matcher fails 7
tests.

#### 2.1c Known limit — invented images in prose only

The leak gate only sees images the provider also put in its `symbols` array.
An invented, non-catalogue concrete image that appears **only** in prose
(told "candle on the table", prose "A silver staircase rises behind the
candle…") can still ground through the told words and pass. This is not
solved and is not claimed to be: interpretation legitimately introduces
abstract words the dream never used (contrast, distance, tension,
stillness), and there is no reliable multilingual concrete-noun parser in
this pipeline, so a deterministic novel-noun rule would reject valid
readings. The writer prompt already forbids adding any image, symbol or
feeling not in the text (TR / EN / RU); the remaining risk is model
compliance, measured by the mandatory 4C.2 review field below.

### 2.2 Russian memory retrieval (`oracly_memory_retriever.dart`)

The retriever tokenizer was Latin/Turkish-only, so a Cyrillic Dream never
matched a Cyrillic memory; the 4C harness needed a recall fallback. The tokenizer
now includes `а-я` (ё folded) plus a Russian stop list. The RU payload is
byte-identical to the frozen fixture and now arrives through ordinary
retrieval; unrelated RU memory and Dream-to-Dream memory stay out.

### 2.3 Writer revision `4c1` (`dream-request-identity.ts`)

The prompt changed, so the replay slot changed: a stored `4b` body is never
replayed; an exact 4C.1 retry replays with zero provider calls. The request
fingerprint is unchanged.

## 3. WRITER QUALITY DEFECT STILL PRESENT

These readings are still refused, correctly. They are writer defects in the old
`4b` `gpt-4o` output, not gate errors:

| Verdict | Runs | Live example |
|---|---|---|
| invented_image (4B) | tr-mixed-emotion, tr-surreal, tr-domain-work, tr-negated-fear#r2 | an image the dreamer never told |
| ungrounded_section (4B) | tr-sparse, en-negated-fear, en-sparse, en-surreal, en-domain-partner, en-no-domain, en-memory, ru-no-domain, ru-memory, en-negated-fear#r2, ru-no-domain#r2 | "a sense of curiosity and calmness despite the unknown" |
| generic_reflection (4B) | tr-no-domain, en-mixed-emotion, ru-mixed-emotion, tr-mixed-emotion#r2, en-mixed-emotion#r2 | "This dream may invite a reflection on how you balance joy and sadness…" |
| weak_conclusion (4B) | tr-history, ru-history#r2 | "…bir anı daha sık yaşayabilir misin?" (yes/no) |
| extra_question (4B) | tr-no-domain#r2, en-no-domain#r2 | more than one question |
| thin_section (4B) | tr-history#r2 | a section below the premium minimum length |
| dictionary_style (2) | ru-domain-family, ru-mixed-emotion#r2 | dictionary-style phrasing |
| ungrounded (2) | ru-sparse, ru-surreal | no told detail |

Writer contract (`dream-prompt-roles.ts`, `dream-prompts.ts`): one "Field
rules" block per language — summary is one compressed sentence; symbols are
exact phrases from the text and may be empty; the emotional theme names only
stated feelings, keeping negation; interpretation relates details; daily-life
reflection is never empty; the conclusion is one open, non yes/no question.
Duplicated rules were removed; safety, history attribution and the JSON schema
are unchanged.

## 4. Offline reclassification

`evals/DREAM_PHASE4C1_OFFLINE_RECLASSIFICATION_20260928.json` (built by
`backend/scripts/dream-phase4c1/artifact.ts`, re-derived by test) and
`evals/DREAM_PHASE4C1_CLIENT_REPLAY_20260928.json`.

| | Count |
|---|---|
| Original runs | 36 |
| Old backend PASS | 2 |
| New offline backend PASS | 7 |
| Old → new changed | 15 (symbols 7 · history unit 4 · emotion negation 3 · recap 1) |
| New rejections | Phase 2: 4 · Phase 4A: 0 · Phase 4B: 25 |
| New backend PASS + client PASS | 7 |
| New backend PASS + client FAIL | 0 |

**Important:** the new pass count is not proof of writer quality. Every body
came from the old `4b` `gpt-4o` prompt; the count shows only which rejections
were gate false positives. No target pass rate was set.

## 5. Phase 4C.2 — model A/B design (not run)

- **Candidates:** `gpt-4o` (baseline, production config), `gpt-6-sol`,
  `gpt-6-astra`. Production model unchanged until an A/B verdict.
- **Subset:** 9 cases × 3 models × 1 run = **27 calls**, hard cap 27, no retries:
  tr-negated-fear, en-negated-fear, ru-negated-fear, en-mixed-emotion,
  tr-domain-work, ru-domain-family, ru-memory, en-history, tr-history.
- **Parameters:** `gpt-4o` keeps temperature 0.6, no reasoning effort. For the
  reasoning candidates, send `reasoning_effort` and omit `temperature`
  (`buildChatCompletionBody` already does this); confirm each model's accepted
  parameters from provider documentation before the run. A parameter rejection
  is an INFRA result, never a quality verdict.
- **Path:** same production route, writer revision `4c1`, same capture/budget
  wrapper and overwrite guard as 4C; new artifact file, never the 4C files.
- **Verdict:** backend stages + client replay per run, then independent human
  review; no pass-rate target.
- **Mandatory review field — `inventedConcreteSceneContent`:** `NONE` or
  `PRESENT`, recorded for **every** candidate response before any model
  verdict. When `PRESENT`, list each exact unsupported object, person,
  animal, place, setting, physical action or visual attribute the model
  introduced as if it existed in the dream. This is separate from
  symbol-array filtering, personal-biography hallucination and symbolic
  interpretation. Example (dream: door + beach): "The door creates a sense of
  distance." is symbolic commentary (`NONE`); "A black horse stands beside
  the door." is invented concrete scene content (`PRESENT`: black horse).
