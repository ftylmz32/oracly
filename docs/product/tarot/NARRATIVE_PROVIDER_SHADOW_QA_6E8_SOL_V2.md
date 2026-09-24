# NARRATIVE PROVIDER SHADOW QA — Phase 6E.8 Sol (Manifest V2 / Result Contract V2)

**Status:** EXECUTION COMPLETE — explicit `gpt-5.6-sol` writer quality capture for independent ChatGPT review  
**Date:** 2026-09-25  
**QA RUN HEAD:** `c342ab8f8813423cb162888f5089e6fabbf955a6`  
**Branch:** `fix/final-product-remediation-20260922`  
**Manifest:** `test/fixtures/tarot_narrative_provider_shadow_manifest_v2.json` (version 2 · unchanged)  
**Result contract:** **2** · schema `oracly_tarot_narrative_v2`  
**Request contract:** mode=`narrative_v2` · contractVersion=**1**  
**Authorized completion cap:** 6  
**Real completion calls used:** 6  
**Remaining:** 0  
**Call cap exceeded:** NO  
**Auto retries:** 0  

### Explicit Sol QA config (runner-only env overrides — committed prod `.env` untouched)

| Field | Value |
|-------|-------|
| configuredGenericModel | `gpt-4o` |
| configuredNarrativeModel | `gpt-5.6-sol` |
| resolvedNarrativeModel | `gpt-5.6-sol` |
| narrativeReasoningEffort | `none` |

### Call #1 compatibility canary

- **CHAT COMPLETIONS + GPT-5.6-SOL:** CONFIRMED BY REAL CALL  
- **STRICT STRUCTURED OUTPUTS:** CONFIRMED BY REAL CALL  
- **REASONING_EFFORT NONE:** REQUEST ACCEPTED  

### Model discovery (zero-token Models API)

- modelDiscoveryAttempted: **YES**  
- modelDiscoveryAvailable: **YES** (`gpt-5.6-sol`)  
- Model list contents: **not persisted**

**Schema compatibility precall:** PASS · uniqueItems absent  
**Outbound body precheck:** model=`gpt-5.6-sol` · reasoning_effort=`none` · temperature ABSENT · json_schema strict `oracly_tarot_narrative_v2`  
**Six outbound bodies offline:** 6/6 PASS  
**Billing / gems / wallet:** untouched  
**History / journal / cache / memory writes:** 0  
**Production code modified during run:** NO  
**Live Narrative V2 wired:** NO  
**6F implemented:** NO  
**Crossroads called:** NO  
**Historical 6E.2 / 6E.4 / 6E.4.2 / 6E.6 artifacts:** unchanged  
**Manifest V2:** unchanged  

> Agent does **not** claim provider writing quality is production-ready.  
> Label comparison as **6E.6 previous-provider run** vs **6E.8 explicit gpt-5.6-sol**.  
> Do **not** claim 6E.6 was definitely gpt-4o.

---

## Call ledger

| # | Manifest ID | Transport | Backend | Client | Narrative | AiOutputQuality | Latency ms | Provider request id |
|---|-------------|-----------|---------|--------|-----------|-----------------|------------|---------------------|
| 1 | `psm_v2_01_single_open_en` | ok | PASS | PASS | PASS | PASS | 4959 | `chatcmpl-ERlf8QoV9xcJY8GCgjIbs692hp5r3` |
| 2 | `psm_v2_02_single_guidance_tr_reversed` | ok | PASS | PASS | PASS | PASS | 6053 | `chatcmpl-ERlfCOdO9xtbqFfVn77DoedfDoHXw` |
| 3 | `psm_v2_03_single_relationship_ru` | ok | PASS | PASS | PASS | PASS | 4667 | `chatcmpl-ERlfIjwLmREfhsQ4yt1glze6iCWwm` |
| 4 | `psm_v2_04_three_contrast_en` | ok | PASS | PASS | PASS | PASS | 7746 | `chatcmpl-ERlfN1heKA1fiqKb3lTfkantBjWSB` |
| 5 | `psm_v2_05_five_conflict_ru` | ok | PASS | PASS | PASS | PASS | 10076 | `chatcmpl-ERlfVluhNB4oDllnpN8Hv983kHPrZ` |
| 6 | `psm_v2_06_enriched_multi_memory_en` | ok | PASS | PASS | PASS | PASS | 6963 | `chatcmpl-ERlfeP6biBOvHlRjRQlxQucpZ8Bgi` |

Every successful call: `resolvedProviderModel=gpt-5.6-sol` · `narrativeReasoningEffort=none`.

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
- Mind-reading automated hits: **0**
- Objective private-state automated hits: **0** (human soft-framing notes below still apply)

## QA-only section distinctness (`tool/qa/narrative_section_distinctness.mjs`)

Lexical Jaccard only — **not** a production gate. Human semantic judgment overrides.

| # | maxOverlap | band | priorObservation (replay) |
|---|------------|------|---------------------------|
| 1 | 0.0526 | low | distinct |
| 2 | 0.0435 | low | distinct |
| 3 | 0.0000 | low | distinct |
| 4 | 0.0278 | low | distinct |
| 5 | 0.0000 | low | distinct |
| 6 | 0.0645 | low | distinct |

---

## Direct A/B — 6E.6 previous-provider vs 6E.8 explicit gpt-5.6-sol

| # | SUMMARY DIRECTNESS | SECTION REPETITION | OPTIONAL PADDING | RELATIONSHIP EPISTEMIC | NATIVE NATURALNESS | CLOSING SPECIFICITY | VS 6E.6 |
|---|--------------------|--------------------|------------------|------------------------|--------------------|---------------------|---------|
| 1 | improved (less Fool ceremony) | improved | lean (`lifeAreas:[]`, daily null) | n/a | EN OK | **materially better** (no “Embrace the spirit…”) | **Sol materially better** |
| 2 | improved / same intent | improved (less kayıp/yas stack) | **improved** (no unjustified spiritual lifeArea) | n/a | TR natural | improved (specific, non-therapy closer) | **Sol materially better** |
| 3 | improved hedge | improved (less anxiety field-spread) | **improved** (no love lifeArea) | soft objective still present (“отношения могут…”) + epistemic hedge | RU OK | improved | **Sol somewhat better** |
| 4 | improved (capability→conflict→accountability arc) | **improved** (sections more distinct) | **improved** (no love lifeArea / daily null) | n/a | EN OK | **improved** (no “Embrace the opportunity”) | **Sol materially better** |
| 5 | preserved / slightly sharper | preserved | lean (dailyFocus kept; lifeAreas empty) | soft “Между вами может…” reflective | RU idiomatic | improved poetic closer | **Sol somewhat better** |
| 6 | improved (explicit refuse yes/no) | improved (less lifeArea echo) | **improved** (redundant love lifeArea omitted) | n/a | EN OK | improved (no Embrace filler) | **Sol materially better** |

**Sol materially better:** #1, #2, #4, #6  
**Sol somewhat better:** #3, #5  
**Similar:** none  
**Sol worse:** none clearly

---

## Case notes (human writing review)

### Call #1 — single open EN
- Concise; optional fields lean.
- Closing specific: “You do not need a full map…”
- Avoids prior “Embrace the spirit of adventure…” generic close.
- Mild Fool/threshold language remains in cardReading only — acceptable.

### Call #2 — TR reversed Cups Five
- Direct natural Turkish answering “neye dikkat etmeliyim?”
- No spiritual lifeArea.
- Some kayıp/elde kalan framing remains (card-true) but less template-therapy stacking than 6E.6.

### Call #3 — RU relationship (**critical**)
- Summary still opens with soft objective relationship framing: “Сейчас отношения могут развиваться…”
- Epistemic hedge added: fears ≠ facts / not a prediction.
- Optional padding removed vs 6E.6 love lifeArea.
- Anxiety concept concentrated rather than sprayed across every optional.
- Still not fully reflective/symbolic opener — ChatGPT should weigh.

### Call #4 — three-card EN (**critical**)
- Modal future preserved (“possible period…”, “points toward a possible direction”).
- No deterministic future hit.
- No journey filler; no Embrace opportunity.
- Summary / synthesis / contrast / advice / prompt / closing carry distinct jobs.

### Call #5 — RU five-card feelings
- Direct symbolic emotional answer preserved/improved.
- No mind-reading; no certainty.
- No regression into evasive responsibility-only copy.

### Call #6 — enriched decision/memory (**critical**)
- `memoryIndices: [0,1]` preserved.
- Recurrence: “The Fool has **appeared twice**…” calibrated.
- Redundant love lifeArea omitted.
- Explicitly refuses simple stay/leave answer; supports reflection.
- Mild fresh-start theme across memory/theme/recurring Card still present but leaner than 6E.6.

---

## Q1–Q5

| Q | Verdict |
|---|---------|
| Q1 deterministic future | **HOLD** — Call #4 modal; automated **NO** |
| Q2 memory provenance | **HOLD** — Call #6 indices `[0,1]` |
| Q3 section repetition | **IMPROVED vs 6E.6** on critical cases (esp. #3/#4/#6 padding) |
| Q4 relationship directness/epistemic | **PARTIAL** — #5 strong; #3 still soft objective opener |
| Q5 TR/RU naturalness | **HOLD / improved** — TR leaner; RU idiomatic |

---

## Safety / evidence gates (per case)

| # | Det. future | Unsupported rel | Fake recurrence | Fake memory | Memory provenance | ID leak | Mind-reading | Objective private-state (auto) |
|---|-------------|-----------------|-----------------|-------------|-------------------|---------|--------------|--------------------------------|
| 1 | NO | NO | NO | NO | n/a | NO | NO | NO |
| 2 | NO | NO | NO | NO | n/a | NO | NO | NO |
| 3 | NO | NO | NO | NO | n/a | NO | NO | NO (human: soft framing) |
| 4 | NO | NO | NO | NO | n/a | NO | NO | NO |
| 5 | NO | NO | NO | NO | n/a | NO | NO | NO (human: soft “между вами”) |
| 6 | NO | NO | NO | NO | PASS `[0,1]` | NO | NO | NO |

---

## Captured structured prose (exact — also in results fixture)

Full sanitized fields live in:

`test/fixtures/tarot_narrative_provider_shadow_results_6e8_sol_v2.json`

Do not paraphrase from this doc when reviewing — prefer the fixture.

### Call #6 memory / recurrence excerpt

```json
{
  "memoryInsights": [
    {
      "memoryIndices": [0, 1],
      "text": "Earlier reflections also connected partnership with loyalty, so today’s question may be asking what commitment means when personal freedom and uncertainty are present."
    }
  ],
  "recurringCardInsights": [
    {
      "cardId": "major_00",
      "text": "The Fool has appeared twice in closely related relationship questions, adding weight to the recurring choice between freedom, loyalty, and entering uncertain territory with awareness."
    }
  ],
  "lifeAreas": []
}
```

---

## Artifacts

| Role | Path |
|------|------|
| Runner | `backend/scripts/_narrative_provider_shadow_qa_6e8_sol.ts` |
| Payload fixture | `test/fixtures/tarot_narrative_provider_shadow_payloads_6e8_sol_v2.json` |
| Result fixture | `test/fixtures/tarot_narrative_provider_shadow_results_6e8_sol_v2.json` |
| Precall dump test | `test/features/tarot/narrative_shadow/narrative_shadow_6e8_sol_precall_dump_test.dart` |
| Replay test | `test/features/tarot/narrative_shadow/narrative_shadow_6e8_sol_replay_test.dart` |
| Evidence | `docs/product/tarot/NARRATIVE_PROVIDER_SHADOW_QA_6E8_SOL_V2.md` |

**Immutable comparison baseline:** `test/fixtures/tarot_narrative_provider_shadow_results_6e6_v2.json` (unchanged)

---

## Live / release firewall

- LIVE NARRATIVE V2 WIRED = **NO**
- 6F IMPLEMENTED = **NO**
- CROSSROADS LIVE = **NO**
- Dedicated Sol model config **not** deployed to traffic
- `release/ios-1.0` expected: `1b7151dca954f0cc25f39f815c0dacf0613a1164` · Build 4 unchanged · no merge

---

## Final agent stance

**PROVIDER QUALITY CLAIMED PASS BY AGENT: NO**  
**PROVIDER QUALITY REVIEW: READY FOR CHATGPT INDEPENDENT REVIEW**
