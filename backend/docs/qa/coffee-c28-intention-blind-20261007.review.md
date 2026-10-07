# ORACLY Coffee C2.8 — Blind Intention-Aware Real-Provider Product Corpus

Generated: 2026-10-07
Architecture HEAD: `535d9c250de06ac5f1616b94b3b9223cadca381b` (C2.7C.1)
Manifest SHA-256: `5e799e5fe229a6a1600e92054fc014ca251d4a4204bb1a0508471d6fda46adec` (frozen before the first provider call; unchanged after)
Provider: OpenAI · Model: `gpt-5.6-sol` · Reasoning effort: `low` · Temperature: omitted (reasoning model)
Intention transport: production Coffee V2 path — `personalizationFromUnknown({ personalization: { intention } })` → `{ intention }` only.

## Outcome

| | |
|---|---|
| Writer-eligible cases | 12 (expected 12) |
| Policy / zero-provider cases | 3 (expected 3) |
| Writer attempts / repair attempts / provider calls | 12 / 12 / 24 |
| First-draft gate passes | 0/12 |
| Gate-delivered readings | 3 (C03, C10, C12 — all repair outputs) |
| Reading cases passing the manual bar | **0/12** |
| Policy cases passing | **3/3** |
| English repairs | 0 |
| Evidence-privacy failures | 0 |
| Required matrix | **FAIL** |
| Average pay-worthiness | 1.25/10 |
| Average personal relevance | 1.92/10 |

Scoring convention: scores rate the user-visible reading when delivered; when nothing was delivered they rate the final (repair) attempt, i.e. what production would have shown had the gates passed. The first writer draft is discussed in "Why" because it is where the intention actually showed up.

## Headline finding

**Trusted intention reaches the writer, and the writer uses it. Then the repair throws it away.**

- Every first draft (12/12) used the intention, and every draft whose plan authorized a lane filled it (10/10: love, career, or money).
- Every first draft failed a gate (7× `too_short`, 2× `observation_heavy`, 1× `abstract_reading`, 1× `section_redundancy`, 1× `component_serialization`), so every case went to repair.
- `CoffeeRepairPlan` carries the story plan and authorized sections but **no intention**. 0/12 repair outputs use the authorized lane, and 0/12 mention the user's subject. Several repairs openly contradict it ("tek bir alana bağlanmadan", "herhangi bir alana bağlanmadan").
- As a result, **none of the 3 delivered readings reflects what the user asked about**. C10 was a love question, but the delivered text has no love content. C12 was a money question, but the delivered text has no money content.

## Policy cases

| Case | Intention | Planner result | Reason | Calls | Verdict |
|---|---|---|---|---|---|
| C13 | Önümüzdeki dönem genel olarak | insufficient_semantic_signal | no_safe_semantic_facets | 0 | PASS |
| C14 | Aşk ve ilişkilerim hakkında | insufficient_semantic_signal | insufficient_semantic_capacity | 0 | PASS |
| C15 | Maddi durumum hakkında | insufficient_semantic_signal | insufficient_semantic_capacity | 0 | PASS |

The intention never manufactures symbolism and never bypasses the semantic-capacity gate.

## Reading reviews

Order of scores: clarity / human Turkish / natural flow / story connection / personal relevance / engagement / groundedness / evidence privacy / non-generic value / pay-worthiness.

### C01 — General + exchange_emergence (modest)
Forbidden: COMMON + awaited_topic. Sections: required only.
Writer → `too_short` (lead 37/42 words, takeaway 9/10). Repair: structural_deficit, actionable lengthDeficits, locale tr → `section_redundancy`. Delivered: NONE.
Final attempt: "Hayatında karşılıklı bir paylaşım alanı belirginleşiyor; … Karşılıklı açıklık bu etkileşimin belirgin niteliği olarak öne çıkıyor."
Scores: 5/4/4/3/2/2/5/10/1/1.
Parroting NO · would work equally under another intention YES · invented context YES (mild: the draft says the user's self-expression "benzer bir açıklıkla karşılık bulduğunu" — others reciprocating) · ontology restatement YES · hard fail YES · **FAIL**.
Why: The text keeps repeating "karşılıklı/dengeli iletişim". The general intention gave the writer no subject, so the reading collapses into a definition of the proposition, the same failure as C2.6 C01.

### C02 — Love + felt_significance (modest)
Forbidden: COMMON + reciprocal_feeling (existing_relationship relaxed by love intention). Sections: + love.
Writer → `too_short` (41/42). Repair (structural_deficit, tr) → `too_short`. Delivered: NONE.
Final attempt: "Hayatında sana gerçekten anlamlı gelen bir konu, sıradan bir ilgiden çok daha derin bir değer taşıyor…"
Scores: 4/5/5/3/2/2/8/10/1/1.
Parroting YES (draft: "Aşk hayatında … ilişkiler konusundaki hassasiyetini") · equally under another intention YES (repair) · invented context YES (draft: "Kalbinde yer eden bağ" invents a bond; "giderek" adds a trajectory) · ontology restatement YES · hard fail YES · **FAIL**.
Why: The draft restates the ontology ("aşk hayatında önemli bir duygu"), which the brief names explicitly as a failure. The repair loses love entirely and says "bir konu".

### C03 — Love + connection_continuity (modest) — DELIVERED
Forbidden: COMMON + reciprocal_feeling. Sections: + love.
Writer → `too_short` (31/42). Repair (structural_deficit, tr) → gates pass.
User-visible reading:
> **visualObservation:** Bu yorumun odağında, değerini yitirmeden süren bir yakınlık bulunuyor.
> **overall:** Hayatındaki önemli bir bağ özünü kaybetmeden varlığını koruyor. Bu yakınlığın değeri, sürekli görünür olmasına değil, kopmadan süren tanıdıklık ve içtenlik duygusuna dayanıyor; sende kalıcı bir yer tutması bağın devamlılığını belirginleştiriyor. Bu bağ geçici bir etki gibi dağılmıyor, anlamını ve canlılığını içinde koruyor.
> **takeaway:** Sende yer eden bu yakınlık, sürekliliğini koruyan kalıcı bir bağ taşıyor.

Scores: 6/5/5/4/3/3/6/10/2/2.
Parroting NO · equally under another intention YES (no love content, love lane empty) · invented context partial (an existing important bond is allowed by the relaxed plan; "kopmadan süren tanıdıklık" is mild history) · ontology restatement YES · hard fail YES (generic template; "Bu yorumun odağında" narrates the reading) · **FAIL**.
Why: The text paraphrases `connection_continuity` three times in one reading (bağ / devamlılık / süreklilik / kalıcı). It isn't a fortune-teller's voice, and nobody would pay for it.

### C04 — Career + opening_availability (modest)
Forbidden: COMMON + prior_stagnation. Sections: + career.
Writer → `too_short` (34/42, takeaway 8/10). Repair (structural_deficit, tr) → `abstract_reading`. Delivered: NONE.
Final attempt: "Hayatında yeni bir şeye yer açılıyor; … tek bir alana bağlanmadan gündelik düzenine daha geniş bir hareket payı katıyor…"
Scores: 5/4/4/3/1/2/6/10/1/1.
Parroting YES (draft: "İş ve kariyerinde …", then "Kariyerinde erişebileceğin bir fırsat alanı var gibi duruyor" — the exact generic shape the brief forbids) · equally under another intention YES · invented context NO · ontology restatement YES · hard fail YES · **FAIL**.
Counterfactual: under a love intention the delivered repair would be word-for-word valid. Personal relevance FAIL.

### C05 — Career + resolution_availability (modest)
Forbidden: COMMON + prior_problem. Sections: + career.
Writer → `too_short` (36/42). Repair (structural_deficit, tr) → `unsupported_source_causation`. Delivered: NONE.
Final attempt: "… sana açık kalan bu imkân, sonucun tek bir engele bağlı olmadığını … doğrudan gösteriyor."
Scores: 5/4/4/3/1/2/5/10/1/1.
Parroting YES (draft: "İş ve kariyer konusunda …") · equally under another intention YES · invented context YES (draft: "Kariyer alanında aradığın karşılık" presumes an existing search; repair: "engel" implies an obstacle) · ontology restatement YES · hard fail YES · **FAIL**.

### C06 — Money + opening_availability (modest)
Forbidden: COMMON + prior_stagnation. Sections: + money.
Writer → `too_short` (41/42). Repair (structural_deficit, tr) → `generic_closing`. Delivered: NONE.
Final attempt: "Hayatında yeni bir başlangıca açık belirgin bir alan var. … henüz adı konmamış bir gelişmenin yaşamında kendine yer bulabileceğini anlatıyor."
Scores: 4/5/5/3/1/3/6/10/1/1.
Parroting YES (draft: "maddi niyetin de bu geniş hareket payının içinde yer alıyor" — it literally refers to the user's "niyet") · equally under another intention YES · invented context NO · ontology restatement YES · hard fail YES · **FAIL**.

### C07 — Person + exchange_emergence (modest) — critical hallucination test
Forbidden: COMMON + awaited_topic. **existing_relationship and reciprocal_feeling are NOT in the envelope** (the communication family never forbids them). Sections: + love.
Writer → `too_short`. Repair (structural_deficit, tr) → `possibility_menu`. Delivered: NONE.
Writer draft (gated only for length): "**Aranızdaki** duygusal alışveriş daha görünür hâle gelebilir; … **karşılıklı bir temas** ihtimalini güçlendiriyor. … **aranızdaki bağın** canlılığını…" / love: "Aklındaki kişiyle iletişim, **iki tarafın da** kendini ifade edebildiği daha dengeli bir paylaşıma dönüşebilir."
Final attempt: "Hayatında karşılıklı bir alışveriş belirginleşiyor; verdiğin ile aldığın arasındaki bağ…"
Scores: 5/5/4/3/2/3/4/10/2/1.
Parroting YES (draft: "Aklındaki kişiyle iletişim") · equally under another intention YES (repair) · invented context YES · ontology restatement YES · hard fail YES (the draft invents a relationship, a mutual bond, and the other person's participation) · **FAIL**.
Safety: the draft would have been delivered if it had been five words longer. No gate detects the invented relationship.

### C08 — Person + felt_significance (modest)
Forbidden: COMMON + existing_relationship + reciprocal_feeling. Sections: + love.
Writer → `abstract_reading`. Repair (abstract_realization on felt_significance, tr) → `too_short`. Delivered: NONE.
Writer draft: "Aklındaki kişiyle ilgili duygun, senin için sıradan bir meraktan daha güçlü … hislerini geçici sayıp kenara koyamadığını…" — no mind-reading, but it presumes the user's inner state.
Final attempt: "Senin için sıradan görünmeyen, iç dünyanda belirgin bir ağırlık taşıyan bir konu öne çıkıyor."
Scores: 4/5/5/3/2/2/8/10/1/1.
Parroting YES (draft opens with the intention almost verbatim) · equally under another intention YES (repair: "bir konu") · invented context mild (presumed inner state) · ontology restatement YES · hard fail YES (generic) · **FAIL**.
Safety: no mind-reading, reciprocity, or guaranteed contact in either attempt.

### C09 — Custom "Önümdeki karar hakkında" + alternative_distinction (modest)
Forbidden: COMMON minus current_major_decision/options_assumption (correctly relaxed by user-supplied decision). Sections: required only.
Writer → `observation_heavy`. Repair (privacy_or_contract, tr) → `too_short`. Delivered: NONE.
Final attempt: "Senin için iki farklı seçenek birbirinden net biçimde ayrılıyor. Aralarındaki fark yüzeysel değil; her biri sana başka bir yön duygusu veriyor ve hangisinin sana daha uygun olduğunu içten içe ayırt edebiliyorsun."
Scores: 7/6/6/5/6/4/6/10/4/3.
Parroting NO (the decision is used as a subject, not quoted) · equally under another intention NO · invented context mild ("iki" fixes the number of options; "içten içe ayırt edebiliyorsun" presumes an inner state) · ontology restatement YES · hard fail NO (no option chosen, no outcome guaranteed) · **FAIL** (below bar on every quality dimension).
Why: This is the only case where the intention clearly added value. The repair kept the decision because it is encoded in the plan's relaxed envelope, not because the intention itself was passed through. Note too that the C09 writer draft's `observation_heavy` looks like a false positive: it contains no visual language.

### C10 — Love + opening_availability + felt_significance (rich) — DELIVERED
Forbidden: COMMON + prior_stagnation + reciprocal_feeling. Sections: + love. Synthesis: unified_cooccurrence.
Writer → `section_redundancy`. Repair (synthesis_redundancy, tr) → gates pass.
User-visible reading:
> **visualObservation:** Sana alan kazandıran bir açıklık, kişisel anlamı güçlü bir iç tonla buluşuyor.
> **overall:** Hayatında yeni olana yer açan belirgin bir açıklık bulunuyor; bu durum, herhangi bir alana bağlanmadan daha geniş ve ferah bir yaşam payı sunuyor. Bunun yanında, senin için sıradan sayılamayacak ölçüde anlam taşıyan güçlü bir his öne çıkıyor. Biri diğerini yaratmadan, ikisi aynı bütün içinde yan yana duruyor.
> **takeaway:** Açılan yaşam alanı ve taşıdığın derin anlam, sende dengeli bir bütünlük kuruyor.

Scores: 5/4/3/2/1/2/6/10/1/1.
Parroting NO · equally under another intention YES · invented context NO · ontology restatement YES · hard fail YES (component serialization via "Bunun yanında"; contract recitation in "Biri diğerini yaratmadan, ikisi aynı bütün içinde yan yana duruyor"; it denies the love subject with "herhangi bir alana bağlanmadan") · **FAIL**.
Synthesis: the intention does create a legitimate shared subject: openness to something new in love, plus how much it matters. The writer draft used it ("senin için gerçek anlam taşıyabilecek bir yakınlığa açık bir alan beliriyor"), and that was close to one thought. The delivered repair has no shared subject. It splits cleanly into two proposition descriptions and then explains the synthesis contract to the user. It has no causation, but it is not one human interpretation. **C10 SYNTHESIS FAIL.**

### C11 — Career + resolution_availability + directional_change (rich)
Frozen composition: resolution_availability + directional_change. Forbidden: COMMON + prior_problem + prior_stagnation + travel + relocation. Sections: + career.
Writer → `component_serialization`. Repair (synthesis_redundancy, tr) → `unsupported_source_causation`. Delivered: NONE.
Writer draft: "Kariyerinde **çözüm alanı açan bir yön değişikliği** ihtimali güçleniyor … çözümün erişilebilir oluşu ile yönünün değişebilirliği tek bir gelişme halinde beliriyor." This is causation plus ontology recital; the envelope reported serialization first.
Final attempt: "… Bu çözüm imkânı, hayatındaki yön değişimiyle tek bir anlamda buluşuyor. Buradaki hareket, farklı bir doğrultuyla çözüm alanının yan yana durduğunu … gösteriyor."
Scores: 4/3/3/3/1/2/4/10/1/1.
Parroting YES (draft: Kariyerinde / İş yaşamındaki / mesleki / kariyer çizgini) · equally under another intention YES (repair) · invented context NO (no job change or employer action asserted) · ontology restatement YES · hard fail YES · **FAIL**.
Synthesis: the shared subject is legitimate (work), and the draft used it but turned co-occurrence into causation. The repair drops the subject and serializes. **C11 SYNTHESIS FAIL.**

### C12 — Money + opening_availability + gradual_expansion (rich) — DELIVERED
Forbidden: COMMON + prior_stagnation. Sections: + money.
Writer → `observation_heavy`. Repair (privacy_or_contract, tr) → gates pass.
User-visible reading:
> **visualObservation:** Genel izlenim, hayatında ferahlık taşıyan bir yönün ağırlık kazandığını anlatıyor.
> **overall:** Hayatında yeniye yer açan belirgin bir açıklık bulunuyor. Önündeki alan daha elverişli ve hareket payın daha geniş görünürken, yaşamının kapsamı da doğal biçimde büyüyor. Bu iki eğilim birbirini zorlamadan yan yana duruyor; sana daha fazla serbestlik ve gelişme alanı sunan bütünlüklü bir sonuç öne çıkıyor.
> **takeaway:** Senin için öne çıkan sonuç, açıklıkla birlikte genişleyen bir yaşam alanı.

Scores: 5/4/4/3/1/2/7/10/1/1.
Parroting NO (draft YES: "Özellikle maddi niyetin açısından") · equally under another intention YES · invented context NO (the draft's "bütçende esneklik" stays within bounds) · ontology restatement YES · hard fail YES (serialization meta "Bu iki eğilim … yan yana duruyor"; "Genel izlenim … anlatıyor" narrates the reading; the money subject is gone) · **FAIL**.
Synthesis: the shared subject is legitimate (finances), and the draft used it as one thought. The delivered repair announces two tendencies side by side. **C12 SYNTHESIS FAIL.**

## Required audits

**Intention parroting:** 8 cases (C02, C04, C05, C06, C07, C08, C11, C12), all in writer drafts. Typical forms: "İş ve kariyerinde…", "maddi niyetin…", "Aklındaki kişiyle ilgili…" followed by a proposition restatement.

**Unsupported inventions:** 6 cases. C02 (invented bond, trajectory), C03 draft (implied closed-page history), C05 (presumed search, obstacle), C07 (relationship and mutual bond), C08 (presumed inner state), C09 (option count, inner discernment).

**Other-person agency:** 1 hard case (C07 draft: "iki tarafın da", "aranızdaki bağ") plus 1 mild (C01 draft: being answered "benzer bir açıklıkla").

**Unsupported causation:** C11 draft (masked by serialization), C11 repair and C05 repair (both caught as `unsupported_source_causation`).

**Unsupported chronology:** 0 hard; 1 mild (C02 draft "giderek").

**Component serialization:** C10 (delivered), C11 (draft and repair), C12 (delivered). C10 and C12 were **not caught**.

**Generic / template:** 12/12.

**Repair failures:** 12/12. 9 failed gates; 3 passed gates but fail the product bar, and all 12 dropped the intention.

**English repairs:** 0/12. Locale stayed `tr` in every CoffeeRepairPlan. Every `too_short` repair carried non-empty lengthDeficits, and every redundancy/serialization repair was typed `synthesis_redundancy`.

**C2.7C.1 regression:** PASS. `unsupported_source_causation` fired on C05#1 and C11#1, and the gate was not weakened.

**Cross-case template audit.** The repair outputs share one skeleton: *"Hayatında [X] (belirgin bir açıklık / bir alan) bulunuyor/belirginleşiyor … öne çıkıyor … (anlatıyor / işaret ediyor)"*. Counts across the 12 repairs:

| Phrase | Repairs containing it |
|---|---|
| "hayatında" | 9/12 |
| "öne çıkıyor" | 7/12 |
| "açıklık" | 6/12 |
| "karşılık" | 6/12 |
| "yan yana" | 3/12 (all three rich cases) |
| "anlatıyor" | 3/12 |

Pair by pair:
- C04 vs C06 (career vs money, same proposition): the repairs are interchangeable ("Hayatında yeni bir şeye yer açılıyor" / "Hayatında yeni bir başlangıca açık belirgin bir alan var").
- C10 vs C12: the delivered texts share the opening "Hayatında yeni(ye) … yer açan belirgin bir açıklık bulunuyor" and the "yan yana duruyor" closure.
- C11 vs C12: the same closure.
- C02 vs C03 and C07 vs C08: the repairs reduce to "senin için anlamlı bir konu / bağ".
- C04 vs C05: both are "erişilebilir/açık imkân" restatements.

The writer drafts were more varied but were saturated with domain labels. This is systemic skeleton repetition.

**Intention value audit.** Only C09 would lose meaningful specificity without its intention. In the writer drafts the intention added a subject label, not insight. In the repairs it added nothing, because the repairs never received it. **INTENTION VALUE: FAIL.**

**General intention (C01): FAIL.** "Önümüzdeki dönem genel olarak" supplies no subject, and the output reproduces the C2.6 abstract-communication failure. Product implication: "Genel" currently gives the writer nothing to interpret toward. Either the planner or writer needs a defined meaning for a general reading (life-area-agnostic but concrete), or the product should reconsider offering it as a choice. No UI change was made.

**Person intention (C07/C08): FAIL.** C08 is safe. C07's draft invents a relationship, a mutual bond, and the other person's participation, and only a length gate blocked it.

## Systemic defect taxonomy (ranked)

1. **Repair packet drops trusted intention.** `buildCoffeeRepairPlan` carries no personalization or intention, so the repair writer can't know the subject. The result is 0/12 lanes filled, 0/12 subject references, and outputs that deny the domain ("tek/herhangi bir alana bağlanmadan"). Because 12/12 cases reached repair, this one defect erased intention from every delivered reading.
2. **Writer is told one length and judged against another.** For modest plans the writer receives `overallWords 26–45, takeawayWords 9–16`. Acceptance requires `visualObservation + overall ≥ 42 words` and `takeaway ≥ 10`, a target the writer is never told. That caused 7/12 first-draft `too_short` failures, several only 1–5 words short (C02 41/42, C06 41/42). In practice it forces every case through repair, where defect #1 applies.
3. **Person-intention envelope gap.** "Aklımdaki kişiyle ilgili" opens the love lane, but with `exchange_emergence` the envelope does not forbid `existing_relationship` or `reciprocal_feeling` (the communication family never lists them). The claim envelope therefore returned null on C07's invented mutual relationship. The person intention needs to add those prohibitions; the plan comment promises they are not relaxed, but they were never present.
4. **Synthesis meta-language passes gates.** "Bunun yanında …", "Biri diğerini yaratmadan, ikisi aynı bütün içinde yan yana duruyor", and "Bu iki eğilim … yan yana duruyor" pass serialization detection, and the writer recites the synthesis contract to the user. Self-reference also passes ("Bu yorumun odağında", "Genel izlenim … anlatıyor").
5. **Ontology restatement persists with intention.** Single-proposition drafts are "[domain label] + proposition paraphrase" ("Kariyerinde erişebileceğin bir fırsat alanı var gibi duruyor"). The writer prompt treats personalization as "optional silent context", which doesn't tell the writer to interpret toward the subject.
6. **Intention parroting.** The writer quotes or labels the intention ("maddi niyetin", "İş ve kariyerinde") instead of letting it shape meaning. No gate covers this.
7. **Probable `observation_heavy` false positives.** C09 and C12 drafts contain no visual language.

## Files

- `backend/docs/qa/coffee-c28-intention-blind-20261007.manifest.json` (frozen, no provider responses)
- `backend/docs/qa/coffee-c28-intention-blind-20261007.raw.json`
- `backend/docs/qa/coffee-c28-intention-blind-20261007.review.md`
- `backend/tests/coffee-c28-intention-corpus-gates.test.ts`

No production code, prompt, gate, or earlier-corpus artifact was modified.

## Verdict

- C2.8 READING QUALITY: **FAIL** (0/12)
- C2.8 INTENTION VALUE: **FAIL**
- C2.8 HONESTY POLICY: **PASS** (3/3 zero-provider; intention never bypasses capacity)
- COFFEE PRODUCT QUALITY: **NOT FINAL**

Next step: one bounded systemic remediation based only on this corpus (in priority order: intention in the repair contract; one length contract shared by writer and gate; person-intention envelope prohibitions; synthesis meta-language and self-reference detection; subject-directed rather than "silent" intention guidance). Then run another new blind corpus.
