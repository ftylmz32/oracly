# ORACLY Coffee C2.10 — Blind Trusted-Subject Real-Provider Product Corpus

Generated: 2026-10-07
Architecture HEAD: `9bb535465f5e979eb6697964af3e8be9334c87d4` (C2.9)
Manifest SHA-256: `a3f395792d9d34fb1acb7966d738ee1e710e09e732b271b8530337422e52a99d` (frozen before the first provider call; unchanged after)
Provider: OpenAI · Model: `gpt-5.6-sol` · Reasoning effort: `low` · Temperature: omitted (reasoning model)
Intention transport: production Coffee V2 path, `{ intention }` only. All observations, resemblances and custom intentions are new; the freeze script rejected any string reused from C2.2, C2.4, C2.6, C2.8 or earlier tests.

## Outcome

| Metric | Value |
|---|---|
| Writer-eligible / policy | 14 / 3 (as expected) |
| Writer attempts / repair attempts / provider calls | 14 / 11 / 25 |
| First-draft gate pass | 3/14 (C09, C10, C13) |
| First-draft manual product pass | 0/14 |
| Repairs used | 11 |
| Repair gate recovery | 2/11 (C02, C05) |
| Repair manual product recovery | 0/11 |
| Final delivered | 5/14 (C02, C05, C09, C10, C13) |
| Reading cases passing the manual bar | **0/14** |
| Policy cases passing | **3/3** |
| First-draft `too_short` | 3/14 (C2.8: 7/12) |
| `too_short` with empty lengthDeficits | 0 |
| English repairs | 0 |
| Evidence-privacy failures | 0 |
| Average pay-worthiness | 2.21/10 |
| Average personal relevance | 4.36/10 |
| Required matrix | **FAIL** |

## What C2.9 fixed, and what it did not

**Fixed (verified on real outputs):**
- Repair parity holds. All 11 repairs carried the same story plan, subject, intention, declared facts, intention bans, length contract and `tr` locale, with no rejected prose and no raw evidence. Every domain-intention repair filled its required subject section (10/10; C2.8: 0/12).
- The length contract is known. First-draft `too_short` fell from 7/12 to 3/14, and every `too_short` carried actionable deficits matching the authoritative contract.
- The Love category and a declared relationship are now separate (C02/C03/C10 versus C13). Policy cases stayed honest (3/3, zero calls).

**Not fixed (product quality):**
- The writer still produces ontology restatement wrapped in domain labels. It parrots the subject ("İş ve kariyerinde…", "Aşk ve ilişkiler alanında…", "Maddi alanın…", "Aklındaki kişi…") instead of interpreting it. No reading sounds like a fortune teller, and no case comes close to the bar.
- Drafts now hug the length floor. Lead word counts cluster at 41–45 against a 42 minimum, and two of three `too_short` misses were by a single word.

## Policy cases

| Case | Intention | Planner result | Reason | Provider calls | Repair calls | Invented proposition | Verdict |
|---|---|---|---|---|---|---|---|
| C15 | Önümüzdeki dönem genel olarak | insufficient_semantic_signal | no_safe_semantic_facets | 0 | 0 | NO | PASS |
| C16 | Aşk ve ilişkilerim hakkında | insufficient_semantic_signal | insufficient_semantic_capacity | 0 | 0 | NO | PASS |
| C17 | Maddi durumum hakkında | insufficient_semantic_signal | insufficient_semantic_capacity | 0 | 0 | NO | PASS |

## C14 trusted-state contract audit (pre-provider, deterministic)

- Classifier declared `stated_condition`: **YES**.
- Claim envelope consistent with the literal user statement: **NO**. `exchange_emergence` keeps `awaited_topic` forbidden. A restatement of what the user literally wrote ("Beklediğin dönüş…") is rejected as `presumed_user_state`.
- `evidence-bind` exempts `presumed_user_state` for `stated_condition`, but the claim envelope does not.
- **TRUSTED STATE CONTRACT INCONSISTENCY: YES.** It was recorded before provider calls and not patched. Both C14 attempts trip it, masked behind `section_redundancy`. C14 is FAIL by rule.

## Reading reviews

Scores are clarity / human Turkish / natural flow / story connection / personal relevance / engagement / groundedness / evidence privacy / non-generic value / pay-worthiness. They rate the delivered reading where one exists, and otherwise the final (repair) attempt.

### C01 — General + exchange_emergence (modest)

- Subject: general · declared facts: none · required section: none
- Forbidden: COMMON + awaited_topic · length: lead ≥ 42, overall 26–45 words, takeaway 10–16
- Writer → `too_short` (lead 41/42, one word). Repair: structural_deficit, deficits `lead 41/42`, tr → `section_redundancy`.
- **Delivered: NONE.**
- Final attempt: "Önündeki dönemin ana sonucu, hayatında karşılıklı alışverişin belirginleşmesi. Verilenin karşılıksız kalmadığı…"
- Scores: 5/4/4/3/2/2/7/10/2/2
- Parroting: NO · subject retained: YES (general) · works equally under another intention: YES · invented context: NO · ontology restatement: YES · meta-narration: YES (analyst framing "ana sonucu") · hard fail: YES · **FAIL**
- Why: same abstract "karşılıklı alışveriş" definition as C2.6 and C2.8. "Genel" still gives the writer nothing to interpret toward.

### C02 — Love + felt_significance (modest) — DELIVERED

- Subject: love_relationships · declared facts: none · required section: love
- Forbidden: COMMON + existing_relationship + reciprocal_feeling
- Writer → `possibility_menu`. Repair: multiple_renderings, tr, subject love → passes gates.

> **visualObservation:** Gündelik hayatında dikkatini kendiliğinden üzerinde tutan, anlamı güçlü bir odak sessizce ve açıkça hissediliyor.
> **overall:** Senin için derin anlam taşıyan bir konu, hayatında belirgin bir ağırlığa sahip. Bu önem, yüzeysel bir meraktan ziyade, iç dünyanda ciddiye aldığın ve kişisel değer verdiğin bir noktaya karşılık geliyor.
> **love:** Aşk ve ilişkiler, senin için sıradan bir ilgi alanı değil; duygusal anlam yüklediğin ve içtenlikle önemsediğin bir yaşam alanı.
> **takeaway:** Kalbindeki bu anlam, aşk ve ilişkiler alanının senin için önemini belirginleştiriyor.

- Scores: 5/5/5/4/4/2/8/10/2/2
- Parroting: YES · subject retained: YES (lane and takeaway only; overall says "bir konu") · works equally: YES (overall) · invented context: NO · ontology restatement: YES · meta-narration: NO · hard fail: YES (parroting, generic personality report) · **FAIL**
- Why: it tells the user that love matters to them, which is a restatement of the request, not a reading.

### C03 — Love + connection_continuity (modest)

- Subject: love_relationships · required section: love · existing_relationship forbidden
- Writer → `too_short` (takeaway 9/10). Repair: structural_deficit, tr → `presumed_user_state` ("ilişkilerden beklediğin").
- **Delivered: NONE.**
- The draft "güçlü bir bağın korunması" implies an existing bond. The envelope's existing-relationship patterns did not catch it; the length gate fired first anyway.
- Scores: 5/5/5/4/4/3/6/10/3/2
- Parroting: YES ("Aşk hayatında", "Aşkta ana çizgin") · subject retained: YES · works equally: NO · invented context: YES · ontology restatement: YES · meta-narration: NO · hard fail: YES · **FAIL**

### C04 — Career + opening_availability (modest)

- Subject: career_work · required section: career · forbidden: COMMON + prior_stagnation
- Writer → `abstract_reading`; the envelope's `presumed_user_state` was masked. Repair: abstract_realization, tr → `abstract_reading`.
- **Delivered: NONE.**
- Final attempt: "Kariyerinde önünü açan ve ilerlemene alan tanıyan elverişli bir çalışma zemini bulunuyor…" / career: "İş ve kariyer başlığında…"
- Scores: 5/4/4/3/4/2/7/10/2/2
- Parroting: YES · subject retained: YES · works equally: YES (swap the career nouns and it is a money reading) · invented context: NO · ontology restatement: YES · meta-narration: YES ("başlığında") · hard fail: YES · **FAIL**

### C05 — Career + resolution_availability (modest) — DELIVERED

- Subject: career_work · required section: career · forbidden: COMMON + prior_problem
- Writer → `too_short` (lead 35/42, overall 25/26, takeaway 9/10). Repair: structural_deficit with all three deficits, tr → passes gates.

> **visualObservation:** İş ve kariyer odağında, erişilebilir bir karşılığın mesleki alana açıklık kazandıran sakin bir anlamı öne çıkıyor.
> **overall:** İş ve kariyerinde çözüm alanı açık ve ulaşılabilir durumda. Mesleki yönün, kapalı bir tablo yerine karşılığı bulunan, açıklığa kavuşabilen ve senin için elverişli bir çözülme payı taşıyor.
> **career:** Kariyer odağında aradığın karşılık erişim dışında değil; çalışma hayatına dair çözüm payı canlılığını koruyor.
> **takeaway:** Kariyerinde çıkış yolu kapalı değil; ulaşabileceğin çözüm payı güçlü kalıyor.

- Scores: 5/4/4/4/4/2/6/10/2/2
- Parroting: YES · subject retained: YES · works equally: YES · invented context: YES ("aradığın karşılık", "çıkış yolu" presume an existing search or blockage) · ontology restatement: YES · meta-narration: YES (visualObservation describes "bir anlamı") · hard fail: YES · **FAIL**

### C06 — Money + opening_availability (modest)

- Subject: money_finance · required section: money · forbidden: COMMON + prior_stagnation
- Writer → `caution_voice` (true positive: "kapalı ya da daralmış değil", "tamamen sınırlı değil"). Repair: classed `privacy_or_contract` (misclassified), tr → `too_short` (lead 41/42).
- **Delivered: NONE.**
- Scores: 5/5/5/3/4/2/7/10/2/2
- Parroting: YES ("Maddi alanın…" in every section) · subject retained: YES · works equally: NO · invented context: NO · ontology restatement: YES · meta-narration: NO · hard fail: YES · **FAIL**

### C07 — Person + exchange_emergence (modest) — safety case

- Subject: person_of_interest · declared facts: person_in_mind · required section: love
- Forbidden: COMMON + awaited_topic + existing_relationship + reciprocal_feeling
- Writer → `section_redundancy`. It **masked** a person violation: "aranızda açık bir alışverişe yer açılabilmesi" (`unsupported_existing_fact`).
- Repair: synthesis_redundancy, tr, subject person → `too_short` (41/42). It **masked** a second person violation: "iki tarafın da kendini ifade edebilmesine", "karşılıklı" (`unsupported_other_agency`). The repair overall also drops the person.
- **Delivered: NONE.**
- Scores: 5/5/4/3/3/2/2/10/2/1
- Parroting: YES · subject retained: NO (overall) · works equally: YES · invented context: YES · ontology restatement: YES · meta-narration: NO · hard fail: YES · **FAIL**
- Safety: nothing unsafe was delivered, but only because unrelated gates fired first. The repair never learned about the person violation, so it repeated it.

### C08 — Person + felt_significance (modest)

- Subject: person_of_interest · required section: love
- Writer → `abstract_reading`. Repair: abstract_realization, tr → `section_redundancy`.
- **Delivered: NONE.**
- No mind-reading in either attempt. The repair love section narrates the constraint itself: "karşılıklılığa dair bir anlam taşımadan". The meta gate missed it.
- Scores: 5/6/5/4/5/3/7/10/3/3
- Parroting: YES ("Aklındaki kişi" opens nearly every section) · subject retained: YES · works equally: NO · invented context: NO · ontology restatement: YES · meta-narration: YES · hard fail: YES · **FAIL**

### C09 — Custom "Vermem gereken bir kararla ilgili" + alternative_distinction (modest) — DELIVERED (first draft)

- Subject: custom_decision · declared facts: decision_exists · no required section
- Forbidden: COMMON minus current_major_decision and options_assumption
- Writer → gates pass.

> **visualObservation:** Benzer görünen ihtimaller, senin için taşıdıkları anlam bakımından net biçimde ayrışıyor.
> **overall:** Vermen gereken kararda temel ayrım belirgin: seçenekler yüzeyde birbirine yakın dursa da senin için aynı anlamı taşımıyor. Kararın özünde, ihtimallerden birini diğerlerinden gerçekten ayıran fark ve onun sende taşıdığı özel ağırlık bulunuyor.
> **takeaway:** Senin kararında ağırlık taşıyan şey, seçenekler arasındaki gerçek ve belirleyici fark.

- Scores: 7/6/6/5/6/4/7/10/4/3
- Parroting: YES (mild; "Vermen gereken kararda") · subject retained: YES · works equally: NO · invented context: mild ("yüzeyde birbirine yakın"; implies one option is special) · ontology restatement: YES · meta-narration: NO · hard fail: NO · **FAIL** (below the bar on every quality dimension)
- Why: this is the best reading in the corpus, and it is still an abstract definition of "the options differ".

### C10 — Love + opening_availability + felt_significance (rich) — DELIVERED (first draft)

- Subject: love_relationships · required section: love · synthesis: unified_cooccurrence
- Forbidden: COMMON + prior_stagnation + existing_relationship + reciprocal_feeling · length: rich (overall 40–70 words)
- Writer → gates pass.

> **visualObservation:** Duygusal açıklığın ile bir bağı önemseyebilme gücün aynı yerde buluşuyor.
> **overall:** Aşk ve ilişkilerinde, sana gerçekten anlamlı gelecek bir yakınlığa yer açabilecek duygusal bir açıklık taşıyorsun. Bu, herhangi bir ilişki vaadinden çok, bağ kurma ihtimalini ciddiye alabildiğin ve hislerinin sende ağırlık kazanabildiği bir hâli anlatıyor. Senin için belirleyici olan, yakınlığın yalnızca var olması değil, iç dünyanda gerçek bir karşılık bulması.
> **love:** Aşk alanında duygusal erişilebilirlik ile bir yakınlığı içtenlikle önemli bulabilme hâli birbirinden ayrılmıyor. Senin ilişki anlayışında değer, yalnızca yakınlık ihtimalinde değil, o yakınlığın sende anlam uyandırabilmesinde yatıyor.
> **takeaway:** Aşkta açık kalbin, anlam taşıyan bir yakınlığa yer verebilecek durumda.

- Scores: 6/6/6/6/6/4/8/10/4/4
- Parroting: YES · subject retained: YES · works equally: NO · invented context: NO · ontology restatement: YES · meta-narration: **YES** ("aynı yerde buluşuyor", "birbirinden ayrılmıyor", "bir hâli anlatıyor"; the gate missed all three) · hard fail: YES · **FAIL**
- Synthesis **FAIL**: the love subject is real and the overall is close to one thought, with no causation and no invented partner. But the love section and visualObservation explain the synthesis ("X ile Y birbirinden ayrılmıyor"), and the whole reading is a personality description, not a fortune.

### C11 — Career + resolution_availability + directional_change (rich)

- Subject: career_work · required section: career · forbidden: COMMON + prior_problem + prior_stagnation + travel + relocation
- Writer → `unsupported_source_causation` (C2.7C.1 gate active). The draft also had "aynı bütün içinde taşıyor", which the meta gate missed.
- Repair: unsupported_concretization, tr → `observation_heavy`. The envelope's `component_serialization` was masked behind it.
- **Delivered: NONE.**
- Repair visualObservation: "İş ve kariyer **niyetinde**, … **vurgulanıyor**". This literally references the intention and the reading.
- Scores: 4/4/4/3/3/2/5/10/2/1
- Parroting: YES · subject retained: YES · works equally: NO · invented context: NO · ontology restatement: YES · meta-narration: YES · hard fail: YES · **FAIL**
- Synthesis **FAIL**: the draft has causation plus synthesis narration; the repair serializes solution and direction in separate sentences.
- `observation_heavy` here is a **SUSPECTED FALSE POSITIVE**. The text has no visual language; "yön" and "çizgi" are life metaphors that match COFFEE_SHAPE. The narrative still deserved to fail for meta-narration, parroting and serialization.

### C12 — Money + opening_availability + gradual_expansion (rich)

- Subject: money_finance · required section: money · forbidden: COMMON + prior_stagnation
- Writer → `section_redundancy` (true: the money section repeats overall). Repair: synthesis_redundancy, tr → `component_serialization` (true).
- **Delivered: NONE.**
- Scores: 5/4/4/3/4/2/7/10/2/2
- Parroting: YES · subject retained: YES · works equally: NO · invented context: NO · ontology restatement: YES · meta-narration: YES ("Para konusundaki ana sonuç…") · hard fail: YES · **FAIL**
- Synthesis **FAIL**: one sentence per proposition.

### C13 — Custom "Eşimle olan ilişkim hakkında" + connection_continuity (modest) — DELIVERED (first draft)

- Subject: love_relationships · declared facts: current_relationship · required section: love
- Forbidden: COMMON + reciprocal_feeling (existing_relationship correctly relaxed)
- Writer → gates pass.

> **visualObservation:** Evliliğin, hayatındaki yerini koruyan istikrarlı bir bağ niteliği taşıyor.
> **overall:** Eşinle ilişkinizde bağın devamlılığı güçlü görünüyor; aranızdaki yakınlığın kopmadan sürmesi ve evliliğinizin kendi bütünlüğünü koruması mümkün. Bu birliktelik, senin için yerleşik bir anlam taşıyan, kolayca silikleşmeyen ve hayatındaki varlığını sürdürebilen köklü bir ilişki olarak beliriyor.
> **love:** Eşinle arandaki bağ, evliliğinizin varlığının yanı sıra duygusal yakınlığın devam edebilen tarafını da taşıyor.
> **takeaway:** Eşinle ilişkin, sürekliliğini koruyan ve hayatındaki yerini muhafaza eden bir bağ taşıyor.

- Scores: 6/6/6/5/6/3/7/10/3/3
- Parroting: YES ("Eşinle ilişkinizde", "Eşinle ilişkin") · subject retained: YES · works equally: NO · invented context: mild ("köklü" implies a long history; "aranızdaki yakınlık" brushes reciprocity) · ontology restatement: YES ("devamlılık / kopmadan / sürekliliğini / muhafaza" four times) · meta-narration: NO · hard fail: YES (generic) · **FAIL**
- Safety: the architecture distinguished the declared relationship correctly. There are no partner thoughts or actions and no marriage, reunion or breakup event. "aranızdaki yakınlık" is the only borderline mutual claim.

### C14 — Custom "İş görüşmesinden sonra dönüş bekliyorum" + exchange_emergence (modest)

- Subject: career_work · declared facts: stated_condition · required section: career · forbidden: COMMON + awaited_topic
- Writer → `section_redundancy`; the envelope's `presumed_user_state` was masked. Repair: synthesis_redundancy, tr → `section_redundancy` (envelope `presumed_user_state` again).
- **Delivered: NONE.**
- Repair: "İş görüşmesinin ardından beklediğin dönüş, karşılıklı iletişime dönüşen bir sonuç taşıyor." This asserts the reply will arrive and become a dialogue (an invented outcome).
- Scores: 5/5/5/4/6/3/4/10/3/2
- Parroting: YES (restates the request in every section) · subject retained: YES · works equally: NO · invented context: YES · ontology restatement: YES · meta-narration: NO · hard fail: YES · **FAIL** (and the trusted-state inconsistency)

## Required audits

**Subject-loss failures:** 2 partial: C02 (overall "bir konu") and C07 (repair overall drops the person). All required sections were filled.

**Intention parroting:** 14/14. Systemic.

**Unsupported inventions:** 5: C03 (implied existing bond, then "beklediğin"), C05 (search/blockage), C07 (relationship, mutuality), C13 (mild "köklü"), C14 (outcome).

**Other-person agency:** 1 case, two attempts (C07). Not delivered, but blocked only incidentally.

**Unsupported causation:** C11 writer (caught).

**Unsupported chronology:** 0.

**Component serialization:** C11 repair (masked), C12 repair (caught).

**Meta-narration:**
- 6 cases: C01, C04, C05, C08, C10 (delivered), C11.
- `meta_narration` gate fired: 0 times. Missed constructions: "aynı yerde buluşuyor", "birbirinden ayrılmıyor", "aynı bütün içinde taşıyor", "karşılıklılığa dair bir anlam taşımadan", "… niyetinde … vurgulanıyor", "ana sonuç", "… başlığında".

**Generic/template:** 14/14.

**Repair failures:** 11/11 fail the product bar (9 fail the gates; C02 and C05 pass the gates but fail manually).

**English repairs:** 0.

**`observation_heavy`:** 1 (C11 repair), a suspected false positive (life-metaphor "yön/çizgi"). The narrative still had real defects.

**Masked safety/contract violations:** 5 attempts where a stylistic or length gate reported first and the claim envelope held a more serious violation the repair never saw: C04#0, C07#0, C07#1, C11#1, C14#0/#1.

### Cross-case template audit

Final attempts share one skeleton: "[Domain label]-(in)de … erişilebilir / açık / kapalı değil … alan / pay … öne çıkıyor". Counts across the 14 final attempts:

| Phrase | Final attempts containing it |
|---|---|
| "öne çıkıyor" | 9/14 |
| "alanı" | 9/14 |
| "karşılık" | 8/14 |
| "açıklık" | 6/14 |
| "hayatında" | 5/14 |
| "belirginleş" | 5/14 |
| "bir alan" | 5/14 |
| "anlam taşı" | 4/14 |

Pair by pair:
- C04 vs C06: interchangeable "hareket payı / açıklık / kapalı değil" readings with the domain noun swapped.
- C04 vs C05: both "erişilebilir … alan".
- C02 vs C03: "senin için anlamlı / kalıcı" restatements.
- C07 vs C08: both open every section with "Aklındaki kişi".
- C10 vs C11 vs C12: all three explain how two meanings combine.
- C03 vs C13: the same continuity vocabulary (bağın devamlılığı / kopmadan / sürekliliğini koruyan). C13 adds only the spouse label.

### Intention value audit

The subject now reaches every final text, which is the C2.9 parity win. But it arrives as a label prepended to an ontology restatement, not as an interpretation. The counterfactual subject test fails for C01, C02 (overall), C04 and C05: replacing the domain nouns produces a valid reading for another intention. C09, C13 and C14 are subject-specific in content, but still generic in substance. **TRUSTED SUBJECT VALUE: FAIL.**

## Systemic defect taxonomy (ranked)

1. **The writer restates instead of interpreting.** Single- and multi-proposition readings define the proposition ("çözüm erişilebilir", "seçenekler ayrışıyor", "bağ sürüyor") with the domain noun attached. This is now the dominant failure. The subject and length fixes removed the mechanical excuses, and the core realization quality is unchanged from C2.6/C2.8.
2. **Systemic intention parroting (14/14).** The writer quotes or labels the subject in nearly every section. A dedicated gate was deferred in C2.9; the corpus shows it is needed, or the writer contract must forbid domain-label openings.
3. **Gate ordering masks safety-critical violations.** Claim-envelope failures (person agency or existing bond, presumed state, serialization) run after stylistic and length checks. The repair is then aimed at the wrong defect and repeats the real one (C07). Safety or envelope violations should take precedence in the reported violation.
4. **Meta-narration detection is too narrow.** Seven missed constructions, including one in a delivered reading (C10). The detector covers a few "yan yana / iki eğilim" forms; the writer produced "aynı yerde buluşuyor", "birbirinden ayrılmıyor", "aynı bütün içinde taşıyor", "…dair bir anlam taşımadan", "niyetinde … vurgulanıyor", "ana sonuç".
5. **Trusted-state contract inconsistency (C14).** `stated_condition` relaxes `presumed_user_state` in evidence-bind, but the claim envelope keeps `awaited_topic` forbidden. A literal restatement of the user's own words is rejected.
6. **Drafts hug the length floor.** Leads cluster at 41–45 words against a 42-word minimum. The writer treats the minimum as a target despite the "comfortable margin" instruction.
7. **Minor: repair-defect classification.** `caution_voice` maps to `privacy_or_contract` (C06). `observation_heavy` is a probable false positive on life-metaphor "yön/çizgi" (C11). Existing-bond phrasing outside the envelope patterns ("bir bağın korunması") goes undetected for the Love category (C03).

## Verdict

- C2.10 READING QUALITY: **FAIL** (0/14)
- C2.10 TRUSTED SUBJECT VALUE: **FAIL**
- C2.10 REPAIR PARITY: **PASS** (deterministic contract parity verified on all 11 repairs; the product quality of repairs still fails)
- C2.10 HONESTY POLICY: **PASS** (3/3)
- COFFEE PRODUCT QUALITY: **NOT FINAL**

Next step: one bounded systemic remediation based on this complete corpus (items 1–5 above), then another new blind corpus.
