# NARRATIVE PROVIDER SHADOW QA — Phase 6E.6 (Manifest V2 / Result Contract V2)

**Status:** EXECUTION COMPLETE — writing-quality capture for independent ChatGPT review  
**Date:** 2026-09-25  
**QA RUN HEAD:** `8a33915e0462438f21c3b74c0d6fd7f787c78730`  
**Branch:** `fix/final-product-remediation-20260922`  
**Manifest:** `test/fixtures/tarot_narrative_provider_shadow_manifest_v2.json` (version 2 · unchanged)  
**Result contract:** **2** · schema `oracly_tarot_narrative_v2`  
**Request contract:** mode=`narrative_v2` · contractVersion=**1**  
**Authorized call cap:** 6  
**Real provider calls used:** 6  
**Remaining:** 0  
**Call cap exceeded:** NO  
**Auto retries:** 0  
**Schema compatibility precall:** PASS · uniqueItems absent  
**Six outbound bodies offline:** 6/6 PASS  
**Billing / gems / wallet:** untouched  
**History / journal / cache / memory writes:** 0  
**Production code modified during run:** NO  
**Live Narrative V2 wired:** NO  
**6F implemented:** NO  
**Crossroads called:** NO  
**Historical 6E.4 / 6E.4.2 artifacts:** unchanged  

> Agent does **not** claim provider writing quality is production-ready.  
> Structural/contract gates may PASS while prose still needs independent review.

---

## Call ledger

| # | Manifest ID | Transport | Backend | Client | Narrative | AiOutputQuality | Latency ms | Provider request id |
|---|-------------|-----------|---------|--------|-----------|-----------------|------------|---------------------|
| 1 | `psm_v2_01_single_open_en` | ok | PASS | PASS | PASS | PASS | 3367 | `chatcmpl-ERl9UAJxIgQsYwp4dU2I8fVAl7x2e` |
| 2 | `psm_v2_02_single_guidance_tr_reversed` | ok | PASS | PASS | PASS | PASS | 3463 | `chatcmpl-ERl9XrNyhVO3cjvH2O2Gc6HoXnBol` |
| 3 | `psm_v2_03_single_relationship_ru` | ok | PASS | PASS | PASS | PASS | 5994 | `chatcmpl-ERl9akX7eQrPOvClyj8BihssPs2Eo` |
| 4 | `psm_v2_04_three_contrast_en` | ok | PASS | PASS | PASS | PASS | 4708 | `chatcmpl-ERl9gbD8oK1aJr0SdpWzymC1KzRWP` |
| 5 | `psm_v2_05_five_conflict_ru` | ok | PASS | PASS | PASS | PASS | 4808 | `chatcmpl-ERl9lALIXcSnhDQBTaoorgo6NeQPo` |
| 6 | `psm_v2_06_enriched_multi_memory_en` | ok | PASS | PASS | PASS | PASS | 4079 | `chatcmpl-ERl9qMVKZgAhVt5lmdmU757vjP0I1` |

## Aggregate gates

- Transport successes: **6**
- Backend structured passes: **6**
- Backend quality rejections: **0**
- Client parser passes: **6**
- Narrative evidence quality passes: **6**
- AiOutputQuality passes: **6**
- Internal id leaks found: **NO**
- Deterministic-future automated hits: **0**
- Memory provenance failures: **0**
- Fake recurrence / fake memory / unsupported relationships: **0** (automated)

## QA-only section distinctness (`tool/qa/narrative_section_distinctness.mjs`)

Lexical Jaccard only — **not** a production gate. Human semantic judgment overrides.

| # | maxOverlap | band | priorObservation (replay) |
|---|------------|------|---------------------------|
| 1 | 0.0455 | low | distinct |
| 2 | 0.1176 | low | distinct |
| 3 | 0.1000 | low | distinct |
| 4 | 0.2083 | low | mildly repetitive |
| 5 | 0.1600 | low | distinct |
| 6 | 0.2222 | low | mildly repetitive |

**Human repetition note:** Call #3 still theme-repeats anxiety across optional fields despite low Jaccard. Call #4 still recycles balance/accountability/alignment. Call #6 still recycles relationship/new-experience language across memory/theme/lifeArea.

---

## Before / after vs 6E.4.2 (defect-focused)

| # | SUMMARY DIRECTNESS | SECTION REPETITION | OPTIONAL FIELD PADDING | RELATIONSHIP EPISTEMIC | NATIVE NATURALNESS | CLOSING SPECIFICITY | OVERALL |
|---|--------------------|--------------------|------------------------|------------------------|--------------------|---------------------|---------|
| 1 | same | improved | same (reflection still filled) | n-a | same | same/mildly worse (“Embrace the spirit…”) | same |
| 2 | same | same (kayıp/yas/elde kalan still recur) | worse (lifeArea filled) | n-a | same (TR OK) | same | same |
| 3 | same | same (anxiety theme still distributed) | worse (lifeArea + dailyFocus filled) | worse/same (“Ваши отношения могут…”) | same/partial | same | same |
| 4 | same | same (balance/accountability recycle) | same/worse (lifeArea+daily filled) | n-a | same | same (“Embrace the opportunity…”) | same |
| 5 | **improved** (symbolic emotional mix) | improved | **improved** (`lifeAreas:[]`, reflection/daily null) | improved (still soft “между вами”) | same/partial | improved | **improved** |
| 6 | same | mildly improved | same (lifeArea still filled) | n-a | same | same | **improved** on count=2 language |

Calls improved vs 6E.4.2: **#5**, **#6** (recurrence calibration)  
Calls same: **#1**, **#2**, **#3**, **#4**  
Calls worse: **none clearly** (optional padding sometimes denser)

---

## Q1 / Q2 confirmation

- **Q1 deterministic future:** RESOLVED remains — Call #4 future uses possibility/potential/may; automated hit **NO**
- **Q2 memory provenance:** RESOLVED remains — Call #6 `memoryIndices: [0,1]`
- **Call #6 recurrence calibration:** “The Fool has **appeared twice**…” — preferred calibrated language

---

## Relationship epistemic (#3 / #5 / #6)

| Case | MIND-READING | OBJECTIVE PRIVATE-STATE | DIRECTLY ANSWERS QUESTION |
|------|--------------|-------------------------|---------------------------|
| #3 | NO (auto) · soft relationship framing present | soft YES (human): “Ваши отношения могут быть омрачены…” | PARTIAL — anxiety theme, not spread-reflective opener |
| #5 | NO | soft framing “Между вами присутствует…” | **YES** — emotional saturation + impulse + caution |
| #6 | NO | NO | YES for decision/openness (love/decision) |

---

## Native language

- **TR (#2):** Contemporary Turkish with diacritics; mild therapy-like kayıp/yas repetition remains.
- **RU (#3/#5):** Readable; #3 still anxiety-template; #5 more idiomatic emotional dynamic. Some Tarot-generic constructions remain for ChatGPT review.
- **EN closings (#1/#4/#6):** Still use “Embrace…” filler patterns — review.

---

## Enriched memory QA context (Call #6)

- Memory 0 · sourceType=`coffee` · `[INTERPRETATION][coffee] shared loyalty partner reflection coffee`
- Memory 1 · sourceType=`dream` · `[INTERPRETATION][dream] shared loyalty partner reflection dream`

Provider memoryInsights:
```json
[
  {
    "memoryIndices": [0, 1],
    "text": "Previous interpretations from coffee and dream readings have shared themes of loyalty and reflection on partnership, indicating that this question has been a consistent focus in your introspection."
  }
]
```

Recurring card: “The Fool has appeared twice…”

---

## Per-case structured results (exact provider prose)

### CALL #1 — `psm_v2_01_single_open_en`

- Language: `en` · Spread: `classical.single` · cards: 1 · Display: The Fool
- Transport: ok · latencyMs: 3367 · id: `chatcmpl-ERl9UAJxIgQsYwp4dU2I8fVAl7x2e`
- Client / Narrative / AiOutputQuality: PASS / PASS / PASS
- Deterministic future: NO · Memory provenance: n/a · Mind-reading: NO · Objective private-state: NO
- Repetition (human): distinct · Naturalness: EN OK · Optional padding: reflectionPrompt filled · Closing: still “Embrace…” ceremony
- Before/after: same

```json
{
  "contractVersion": 2,
  "languageCode": "en",
  "summary": "The Fool suggests embracing new beginnings with an open mind and readiness to explore.",
  "cardReadings": [
    {
      "cardId": "major_00",
      "positionKey": "sign",
      "text": "The Fool in this position signals a time to approach new beginnings with curiosity and openness. It encourages stepping beyond familiar boundaries while remaining flexible and cautious about potential consequences."
    }
  ],
  "synthesis": "The central tension is between the desire to leap into new experiences and the need to remain grounded and mindful of potential risks.",
  "relationshipInsights": [],
  "recurringCardInsights": [],
  "recurringThemeInsights": [],
  "memoryInsights": [],
  "lifeAreas": [],
  "advice": "Consider where you can introduce more openness and curiosity into your current situation.",
  "reflectionPrompt": "What new opportunities are you ready to embrace with an open heart?",
  "dailyFocus": null,
  "closingMessage": "Embrace the spirit of adventure with both enthusiasm and mindfulness."
}
```

### CALL #2 — `psm_v2_02_single_guidance_tr_reversed`

- Question: `Bu dönemde neye dikkat etmeliyim?`
- Transport: ok · latencyMs: 3463 · id: `chatcmpl-ERl9XrNyhVO3cjvH2O2Gc6HoXnBol`
- Client / Narrative / AiOutputQuality: PASS / PASS / PASS
- Repetition (human): mildly repetitive on kayıp/yas/elde kalan · Naturalness: TR OK · lifeAreas: 1 (padding risk)
- Before/after: same

```json
{
  "contractVersion": 2,
  "languageCode": "tr",
  "summary": "Bu dönemde kayıplarınızı onurlandırırken, kalanları da görmeyi ihmal etmeyin.",
  "cardReadings": [
    {
      "cardId": "cups_05",
      "positionKey": "sign",
      "text": "Kupa Beşlisi ters olarak karşımıza çıkıyor ve bu dönemde kayıplara odaklanmanın getirdiği umutsuzluk ve inkâr duygularına dikkat etmemiz gerektiğini gösteriyor. Bu kart, yas tutmanın önemini hatırlatırken, aynı zamanda elimizde kalanları da görmemizi öneriyor."
    }
  ],
  "synthesis": "Kayıplar ve elimizde kalanlar arasında bir denge kurma ihtiyacı öne çıkıyor.",
  "relationshipInsights": [],
  "recurringCardInsights": [],
  "recurringThemeInsights": [],
  "memoryInsights": [],
  "lifeAreas": [
    {
      "kind": "spiritual",
      "text": "Bu kart, manevi olarak kayıplarınızla yüzleşip, onları onurlandırarak ruhsal bir denge kurmanızı öneriyor."
    }
  ],
  "advice": "Kayıplarınızı kabul edip yas tutarken, sahip olduklarınızı da değerlendirin.",
  "reflectionPrompt": "Kayıplarımı onurlandırırken, elimde kalanları nasıl daha iyi değerlendirebilirim?",
  "dailyFocus": null,
  "closingMessage": "Kayıplarınız ve sahip olduklarınız arasında denge kurmak, ruhsal sağlığınıza katkıda bulunabilir."
}
```

### CALL #3 — `psm_v2_03_single_relationship_ru` (Q3/Q4/Q5 primary)

- Question: `Как развиваются наши отношения?`
- Transport: ok · latencyMs: 5994 · id: `chatcmpl-ERl9akX7eQrPOvClyj8BihssPs2Eo`
- Client / Narrative / AiOutputQuality: PASS / PASS / PASS
- Mind-reading (auto): NO · Objective private-state (human): soft YES · Directly answers: PARTIAL
- Repetition (human): **repetitive** anxiety theme across summary/synthesis/advice/closing/daily despite low Jaccard
- Optional padding: lifeAreas + dailyFocus + reflection filled
- Before/after: same (defect not cleared)

```json
{
  "contractVersion": 2,
  "languageCode": "ru",
  "summary": "Ваши отношения могут быть омрачены тревогами и беспокойством, особенно в ночное время.",
  "cardReadings": [
    {
      "cardId": "swords_09",
      "positionKey": "sign",
      "text": "Девятка Мечей в перевёрнутом положении указывает на усиление тревожных мыслей и страхов, которые могут принимать катастрофические формы ночью. Это может выражаться в личных переживаниях, бессоннице и чувстве вины, которые на самом деле могут быть менее реальны, чем кажутся в тёмное время суток."
    }
  ],
  "synthesis": "В отношениях может присутствовать напряжение из-за тревожных мыслей и разговоров, которые усиливаются ночью и могут казаться более значительными, чем они есть на самом деле.",
  "relationshipInsights": [],
  "recurringCardInsights": [],
  "recurringThemeInsights": [],
  "memoryInsights": [],
  "lifeAreas": [
    {
      "kind": "love",
      "text": "Отношения могут испытывать напряжение из-за ночных тревог и страхов, которые воспринимаются более серьёзно, чем они есть на самом деле."
    }
  ],
  "advice": "Постарайтесь обсудить свои страхи и тревоги в спокойной обстановке, чтобы уменьшить их влияние на ваши отношения.",
  "reflectionPrompt": "Что в ваших отношениях вызывает наибольшую тревогу и почему?",
  "dailyFocus": "Сосредоточьтесь на том, чтобы не позволять ночным страхам управлять вашими действиями днём.",
  "closingMessage": "Помните, что ночные страхи не всегда соответствуют реальности."
}
```

### CALL #4 — `psm_v2_04_three_contrast_en` (Q1 preserve + Q3)

- Transport: ok · latencyMs: 4708 · id: `chatcmpl-ERl9gbD8oK1aJr0SdpWzymC1KzRWP`
- Deterministic future: NO (future = possibility / potential / may)
- Repetition (human): mildly repetitive — balance/accountability/alignment still shared across sections
- Closing: “Embrace the opportunity…”
- Before/after: same on repetition; Q1 still good

```json
{
  "contractVersion": 2,
  "languageCode": "en",
  "summary": "This season of your life involves navigating imbalances in relationships and making choices that align with personal values, leading towards a future of accountability and balance.",
  "cardReadings": [
    {
      "cardId": "major_01",
      "positionKey": "past",
      "text": "In the past, you have had the ability to channel your skills and focus into concrete actions, turning ideas into reality with intention and creativity."
    },
    {
      "cardId": "major_06",
      "positionKey": "present",
      "text": "Currently, there may be discord or indecision in relationships, with a tendency for connections to drift from their true integrity. This period might involve overlooking differences or delaying critical decisions."
    },
    {
      "cardId": "major_11",
      "positionKey": "future",
      "text": "Looking ahead, there is a possibility of achieving balance and accountability by carefully weighing facts and recognizing consequences. This involves establishing fair standards and remaining honest in assessments."
    }
  ],
  "synthesis": "The spread suggests a journey from past mastery and creative focus, through present relational imbalances, towards a future that emphasizes fairness and accountability.",
  "relationshipInsights": [
    {
      "leftCardId": "major_06",
      "rightCardId": "major_11",
      "kind": "contrast",
      "text": "There is a contrast between the current indecision and imbalance in relationships and the future potential for balance and accountability, highlighting a journey from discord to fairness."
    }
  ],
  "recurringCardInsights": [],
  "recurringThemeInsights": [],
  "memoryInsights": [],
  "lifeAreas": [
    {
      "kind": "love",
      "text": "The Lovers card reversed in the present position suggests potential challenges in relationships, where imbalance and indecision may be prevalent."
    }
  ],
  "advice": "Reflect on your current relationships and consider where imbalances exist, aiming to make choices that align with your values and integrity.",
  "reflectionPrompt": "What choices in your relationships align with your true values and integrity?",
  "dailyFocus": "Focus on maintaining balance and honesty in your interactions.",
  "closingMessage": "Embrace the opportunity to bring fairness and accountability into your future choices."
}
```

### CALL #5 — `psm_v2_05_five_conflict_ru` (Q4 primary)

- Question: `Что за чувства между нами?`
- Transport: ok · latencyMs: 4808 · id: `chatcmpl-ERl9lALIXcSnhDQBTaoorgo6NeQPo`
- Directly answers feelings question: **YES** (emotional saturation + forward impulse + caution)
- Mind-reading: NO · Optional padding: improved (`lifeAreas: []`, reflection/daily null)
- Before/after: **improved**

```json
{
  "contractVersion": 2,
  "languageCode": "ru",
  "summary": "Между вами присутствует эмоциональная насыщенность и стремление к движению вперёд, но важно избегать поспешности и легкомысленности.",
  "cardReadings": [
    {
      "cardId": "major_00",
      "positionKey": "situation",
      "text": "Шут в перевёрнутом положении в контексте ситуации символизирует свежесть в отношениях, но предупреждает о возможной легкомысленности и необдуманной спешке."
    },
    {
      "cardId": "major_11",
      "positionKey": "hidden_influence",
      "text": "Справедливость указывает на необходимость внимательного взвешивания фактов и ответственности, что может означать взаимность и честность в отношениях."
    },
    {
      "cardId": "wands_01",
      "positionKey": "challenge",
      "text": "Туз Жезлов представляет первую искру и энтузиазм, но в качестве вызова это требует осторожности, чтобы сохранить этот пыл, не позволяя ему угаснуть."
    },
    {
      "cardId": "wands_12",
      "positionKey": "strength",
      "text": "Рыцарь Жезлов в позиции поддержки говорит о сильном стремлении и энергии, которые лучше направлять, избегая излишней поспешности."
    },
    {
      "cardId": "cups_09",
      "positionKey": "direction",
      "text": "Девятка Кубков в будущем предлагает обретение личной эмоциональной полноты, не зависящей от внешних обстоятельств."
    }
  ],
  "synthesis": "Между вами есть желание двигаться вперёд и развивать отношения, но важно сохранять баланс между внутренней эмоциональной полнотой и стремлением к новым началам.",
  "relationshipInsights": [
    {
      "leftCardId": "major_00",
      "rightCardId": "wands_01",
      "kind": "conflict",
      "text": "Конфликт между Шутом и Тузом Жезлов указывает на напряжение между желанием двигаться вперёд и необходимостью осторожности, чтобы не растерять первоначальный импульс."
    }
  ],
  "recurringCardInsights": [],
  "recurringThemeInsights": [],
  "memoryInsights": [],
  "lifeAreas": [],
  "advice": "Сосредоточьтесь на балансе между внутренней наполненностью и внешними устремлениями, избегая поспешных решений.",
  "reflectionPrompt": null,
  "dailyFocus": null,
  "closingMessage": "Сохранение внутреннего спокойствия поможет избежать ненужной суеты."
}
```

### CALL #6 — `psm_v2_06_enriched_multi_memory_en`

- Transport: ok · latencyMs: 4079 · id: `chatcmpl-ERl9qMVKZgAhVt5lmdmU757vjP0I1`
- Memory indices: `[0,1]` · Recurrence count calibrated: YES (“appeared twice”)
- Redundant lifeArea omitted: **NO** (lifeAreas still length 1)
- Repetition (human): mildly repetitive across summary/theme/memory/lifeArea
- Before/after: improved on frequency language; repetition only partial

Exact structured result:

```json
{
  "contractVersion": 2,
  "languageCode": "en",
  "summary": "The Fool suggests an openness to new experiences, inviting a fresh perspective on your relationship decision.",
  "cardReadings": [
    {
      "cardId": "major_00",
      "positionKey": "sign",
      "text": "The Fool symbolizes a new beginning and a willingness to explore unknown territories. In the context of your relationship question, it encourages curiosity and freedom, suggesting that approaching the situation with an open mind could lead to new insights. However, it also warns of the potential risks of acting impulsively without considering the consequences."
    }
  ],
  "synthesis": "The central tension involves balancing the desire for new experiences with the need for careful consideration in your relationship decision.",
  "relationshipInsights": [],
  "recurringCardInsights": [
    {
      "cardId": "major_00",
      "text": "The Fool has appeared twice in the context of relationship loyalty and deciding whether to stay, highlighting the ongoing theme of exploring new possibilities while assessing commitments."
    }
  ],
  "recurringThemeInsights": [
    {
      "themeIdOrLabel": "ilişki",
      "text": "The recurring theme of 'relationship' suggests that the question of staying or leaving is a significant and ongoing concern in your life, encouraging a deeper exploration of your feelings and the dynamics at play."
    }
  ],
  "memoryInsights": [
    {
      "memoryIndices": [0, 1],
      "text": "Previous interpretations from coffee and dream readings have shared themes of loyalty and reflection on partnership, indicating that this question has been a consistent focus in your introspection."
    }
  ],
  "lifeAreas": [
    {
      "kind": "love",
      "text": "The reading is directly concerned with your romantic relationship and the decision about whether to stay in it, inviting exploration of new dynamics or perspectives."
    }
  ],
  "advice": "Consider what new experiences or perspectives could be gained by staying or leaving, and weigh them against the potential consequences.",
  "reflectionPrompt": "What new possibilities or perspectives might you explore if you approached your relationship decision with curiosity and openness?",
  "dailyFocus": null,
  "closingMessage": "Embrace the opportunity to explore your feelings and the potential for growth within your relationship decision."
}
```

---

## Agent quality claim

**PROVIDER QUALITY CLAIMED PASS BY AGENT: NO**

READY FOR CHATGPT INDEPENDENT REVIEW
