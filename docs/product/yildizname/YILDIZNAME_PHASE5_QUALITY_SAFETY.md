# YILDIZNAME Phase 5 — Quality & Safety

**Status:** FROZEN  
**Client:** `YildiznameQualityValidator`  
**Backend:** contract + result parse + light prose safety + frozen writer

## Validation order

1. contract / version  
2. language + scope match  
3. factRefs (known, no invent)  
4. themeRefs  
5. scope honesty (legacy/reduced firewalls)  
6. grounding (body+sign, house, aspect)  
7. privacy (no machine ids / factRef strings in prose)  
8. safety (deterministic / medical / fatalism / …)  
9. prose quality (JSON leak, repetition, genericity)  
10. coverage / synthesis (full E4 evidence usage)

## Grounding

Explicit natal claims in TR/EN/RU must match request facts:

- Planet + sign mismatch → FAIL  
- Asc without evidence → FAIL  
- “Venus in 7th” without Venus.house==7 → FAIL  
- Named aspect without matching aspect fact → FAIL  
- Numerical degree claims in narrative prose (`23°`, `23 derece`, `23 degrees`) → FAIL  

## Unsupported constructs (reject)

North/South Node · Chiron · Lilith · Part of Fortune · stellium · grand trine · T-square · yod · chart ruler — unless a future deterministic engine supplies them (Phase 4 does not).

## Coverage

| Scope | Requirement |
|-------|-------------|
| Legacy | Modest; Sun OK; explicit limited scope honesty |
| Reduced | Use available intervalStable facts; evidence-relative |
| Full | Sun + Moon + Asc + ≥2 of Merc/Venus/Mars/Jup/Sat + ≥1 aspect (if any) + ≥1 house/angle + ≥1 multi-fact synthesis section |

Generic “Sun-sign only” full results → FAIL.

## Safety (TR/EN/RU)

Reject certainty around: death/lifespan · medical diagnosis · pregnancy · crime · financial/legal guarantees · guaranteed soulmate/event · unavoidable destiny · factual past-life karma · psychological diagnoses · absolutist “always/never”.

Allow reflective metaphor; prefer tendency language.

## Attempts & cache

Max **2** provider attempts. Attempt number is transport-only (not in semantic fingerprint).

Cache key = semantic fingerprint. Cache **only** quality-approved results. Rejected/mutant → not cached / invalidated.

Both attempts fail → typed `YildiznameLiveFailure` — **no** StarMapCopy canned success.

## Policy rules (frozen)

`USE_ONLY_SUPPLIED_FACTS` · `DO_NOT_CALCULATE_ASTRONOMY` · `DO_NOT_INVENT_MEMORY` · `DO_NOT_INVENT_PLACEMENTS` · `DO_NOT_INVENT_HOUSES` · `DO_NOT_INVENT_ASPECTS` · `DO_NOT_TREAT_SYMBOLIC_INTERPRETATION_AS_CERTAINTY` · `NO_DETERMINISTIC_FUTURE` · `NO_FATALISM` · `NO_MEDICAL_DIAGNOSIS` · `NO_PREGNANCY_CERTAINTY` · `NO_LEGAL_FINANCIAL_GUARANTEE` · `NO_GUARANTEED_SOULMATE` · `KARMIC_LANGUAGE_METAPHOR_ONLY`
