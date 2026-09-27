# Dream Phase 3 — Safety Firewall Contract

Status: Phase 3. Builds on Phase 1 (owner/privacy) and Phase 2 (provenance,
multilingual, identity, evidence, lexical) without changing their contracts.

ORACLY does not diagnose, predict or confirm. This firewall classifies only
what the dreamer **states in words**. It is a routing rule, not a clinical
assessment, and it makes no claim about the person.

## Categories

| Code | Blocked when the dreamer states… |
|---|---|
| `crisis` | current self-harm / suicidal intent or plan (present or future, first person) |
| `acute_distress` | immediate danger or loss of safety right now |
| `trauma` | a real-life trauma, marked as having actually happened |
| `delusion` | a request for the dream to prove or confirm an outside threat, spirit, alien, surveillance, or waking voices giving orders |
| `diagnosis` | a request for the dream to diagnose a psychiatric or medical condition |

Priority when several apply: crisis → acute_distress → trauma → delusion → diagnosis.

## Dream content vs waking disclosure

Dream imagery is allowed. This includes death, suicide seen in a dream, violence, blood, a hospital, medication, spirits or cin, aliens, being watched or chased, a diagnosis given inside the dream, and the nightmare and fearful chips.

| Allowed (dream content) | Blocked (waking disclosure / request) |
|---|---|
| Rüyamda öldüğümü gördüm. | Uyandım ve şimdi kendimi öldürmek istiyorum. |
| I dreamed that someone committed suicide on a bridge. | I want to kill myself now. |
| Во сне за мной следили инопланетяне. | Сон доказывает, что за мной следят. |
| Rüyada şizofreni teşhisi konduğunu gördüm. | Bu rüya şizofren olduğumu gösteriyor mu? |

Mechanics:
- **Segmentation.** Text is folded (lowercase, `ı→i`, `ё→е`, apostrophes unified) and split into segments on sentence punctuation, `;`, `:`, newlines and brackets. Guided answers always stay separate segments.
- **Crisis.** Only present or future first-person intent patterns count ("…istiyorum", "I want to…", "хочу…"). Past-tense dream narration ("istiyordum", "I wanted to") never matches. Crisis is **never** excused by dream framing.
- **Acute distress, waking voices and diagnosis terms.** These are excused only inside dream framing: a dream marker ("rüyamda", "in my dream", "во сне") earlier in the same segment, with no waking marker ("şimdi", "uyandığımda", "now", "сейчас") in between.
- **Trauma.** Needs an abuse term *and* a reality marker ("gerçekten", "çocukken", "in real life", "на самом деле"). "Rüyamda taciz edildim" alone is dream content.
- **Delusion.** Needs a proof verb (kanıtlıyor / proves / доказывает) *and* an outside agent. Waking voices giving orders also count.
- **Diagnosis.** Needs a condition term *and* a question or a link verb (gösteriyor, anlayabilir, do I have, значит, …).

Classifier inputs are the narrative, the raw guided answers (`DreamEntrySelection.guided`), and stored tags **only** for legacy records without structured entry. App-owned chip labels never establish a concern. Generated prose is never input-classified.

## Client ordering (fail closed)

1. `DreamPaidSubmit.run` → `DreamSafetyPolicy.forDream` first. On a concern: `controller.presentSafety` and stop.
2. Nothing else runs:
   - no `DreamAttemptStore.resolveId`, so no attempt row and no narrative hash;
   - no `GemSpendGuard.beginPaid` and no Gem operation, so charge is 0;
   - no `PaidAiOperationBinder` and no provider call.

   The balance is never read, so the result is the same at any balance and does not depend on Dream cost.
3. Defense in depth: `DreamExperienceService.analyze` and `.reinterpret` call `DreamSafetyPolicy.ensureSafe` independently, before any provider, repository or version work, and throw `DreamSafetyException`. The unused `OpenAiDreamAnalysis` adapter is gated too.
4. Reinterpret re-checks the stored record (narrative + guided answers, or legacy tags). A legacy sensitive record shows safety. The stored copy is not mutated and no version is added.

## Safety delivery state

`DreamJourneyPhase.safety` holds an ephemeral `DreamSafetyPresentation`: concern plus operation language, and **no narrative**.
- It is not a `Dream`; it has no `fromAi` or local provenance.
- It is never saved, versioned, favorited, journaled, shared or reinterpreted, and carries no AI footnote.
- It is cleared on reset, New dream, a new submit, `openSaved`, owner change and sign-out (the provider rebuilds on the owner epoch), and on Discovery clear.

The UI (`DreamReferenceSafetyView`) reuses `OraclyErrorState`: title, body, "Back to my words" and "New dream". There are no summary cards, symbols, interpretation cards, `ReadingVersionHost`, favorite, reinterpret, share or provenance footer.

## Copy (TR/EN/RU, `table_dream_safety.dart`)

Calm, brief, non-diagnostic, non-fortune, non-dependent. There are no country-specific numbers. The crisis and acute copy says "yerel acil yardım hizmeti" / "local emergency services" / "местная экстренная помощь", and points to a trusted person who can be physically present.
- **Delusion:** "A dream cannot confirm that this is happening in the outside world."
- **Trauma:** never symbol, lesson, fate or karma; "what happened was not your fault".
- **Diagnosis:** a dream cannot diagnose; a qualified professional can evaluate.

## Backend ordering

`/v1/ai/complete` for `dream_analysis`, in this order:
1. Validation, then auth, App Check and rate gates.
2. **`assertDreamInputSafe`**.
3. Replay claim, duplicate check, expensive-request check, then provider.

Safety wins over replay: a sensitive request under a key that already holds a replay entry gets `dream_safety_blocked`, never the cached reading. The replay store is not consulted and the provider is called 0 times. A safe exact retry replays unchanged (Phase 2 identity untouched).

`AiProxyService.dream` also runs `assertDreamInputSafe` before `transport.complete`, so a direct call is gated too. The envelope exposes only the code: no regex, narrative or diagnostics. Logs carry operation, request id, error code and status only.

## Memory omission

If the current input is safe but the retrieved connected memory is sensitive, `memorySummary` is left out of the request. Sensitive means a classifier concern or a self-harm, trauma or diagnosis term. The user is not routed to safety and nothing is deleted from storage. This happens on the client (`DreamInsightBuilder`) and again on the backend (prompt build).

## Prompt hardening

For normal requests only, the single existing call gets these TR/EN/RU clauses:
- a dream is not evidence of an outside threat, surveillance, spirit, alien, government or hidden force;
- no delusion reinforcement and no diagnosis;
- do not infer unstated trauma; no blame; no destiny, karma or lesson framing of abuse;
- never encourage self-harm;
- never advise stopping medication or avoiding care;
- death imagery is not a prediction;
- symbolism stays tentative.

The Phase 2 contract (one language directive, canonical JSON keys) is unchanged.

## Output firewall

It checks all fields (summary, symbols, emotionalTheme, interpretation, dailyLifeReflection, conclusion). It rejects:
- self-harm encouragement;
- unsafe medical directives;
- diagnosis stated as fact;
- delusion or surveillance stated as real;
- trauma blame or fatalism;
- death certainty.

Every check is negation-aware:
- **Preceding negators and hedges:** not, never, no, if, не, ли, eğer, and similar.
- **Turkish post-negation:** değil, gelmez, kanıtlamaz, göstermez.

So safe negations pass, for example "A dream cannot diagnose PTSD.", "This does not prove someone is watching you." and "Rüyada ölüm görmek gerçek hayatta öleceğin anlamına gelmez."

- **Backend:** runs after parse and before success. On failure it returns `invalid_response`, with no success body, no retry and no second call.
- **Client:** `DreamOutputSafety` runs before `DreamAiInsightMapper` and persistence. On failure it throws `AiFailure.invalidResponse`, so nothing is shown, saved or versioned, and there is no second call.

Existing Fortune certainty handling in `DreamAnalysisGuard` is unchanged.

## Canonical corpus

`backend/tests/fixtures/dream_safety/input_corpus.json` and `output_corpus.json` are synthetic TR/EN/RU rows (`language`, `text`, `expected`, `concern`/`check`). They include false-positive controls (dream death, suicide imagery, spirits, aliens, a diagnosis inside the dream, nightmare, fear, violence, blood, hospital, medication) and safe negations. Flutter tests (`test/features/dream/dream_phase3_*`) and backend tests (`backend/tests/dream-phase3-safety.test.ts`) both consume them. The lexicons are mirrored verbatim:
- Dart: `lib/features/dream/safety/`
- TS: `backend/src/ai/dream-safety-lexicon.ts`

## Limitations

- **Lexical, not semantic.** Paraphrases outside the lexicon, other languages, heavy misspelling or sarcasm may pass. Wording that quotes intent inside a dream ("rüyamda 'ölmek istiyorum' dedim") is blocked on purpose, because crisis is never excused by framing.
- **False positives are possible and cheap.** The user sees calm guidance and can edit; nothing is charged, sent or stored.
- **Output checks are conservative.** A rejected reading shows the standard calm failure, with no retry.
- **Nothing in this contract is a diagnosis or a risk score.**
