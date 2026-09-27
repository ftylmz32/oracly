# Dream Phase 4A — Grounded Longitudinal Personalization

Status: Phase 4A. Builds on Phase 1 (owner/privacy), Phase 2 (provenance,
multilingual identity, evidence, lexical) and Phase 3 (safety firewall)
without changing their contracts.

ORACLY may say that an image has appeared before only when the dreamer's own
saved Dreams show it. History is counted, never inferred. It describes and
never predicts.

## What counts as history

History is derived from the current owner's analyzed, saved Dreams at request
time. Nothing is cached or persisted, and no prior narrative leaves the
device.

| Kind | Canonical key | Source |
|---|---|---|
| `symbol` | `symbol:<catalogue token>` (TR and EN words of one catalogue entry share a key) or `symbol:<normalized lexicon token>` | `understanding.symbols` |
| `location` | `location:<normalized label>` | `understanding.locations` |
| `relationship` | `relationship:<normalized label>` | `understanding.relationships` |
| `emotion` | `emotion:<DreamEmotionId>` | selected emotion chips |
| `entry` | `entry:<DreamEntryChipId>` | Phase 2 entry chips |

Free-form legacy tags and prose are never parsed. A legacy record takes part
only through its structured fields. Keys use strict normalization (Turkish
fold, trim, collapsed whitespace), with no fuzzy or stem matching.

## Rules

- **Current evidence first.** A key is counted only when the current dream also holds it. Old, unrelated history is never sent.
- **Levels.** A match in one distinct prior Dream is `seen_before`. Two or more distinct prior Dreams is `recurring`. Nothing else is a recurrence.
- **Eligible priors.** A prior must be analyzed, recorded strictly before the current dream, and have a unique id other than the current one. Priors that the Phase 3 policy marks sensitive are excluded from history but not deleted. A sensitive current dream is routed to safety before history is read.
- **Bounds.** The newest 40 priors are scanned. At most 5 items are sent, and each item keeps at most 3 prior ids on device. Order is prior count desc, then last seen desc, then kind, then key. Labels are deduplicated.
- **Owner.** History is read for one owner snapshot. The snapshot is checked before and after the read, so A→B and A→B→A (epoch) fail closed before the provider is called.
- **Deletion and clear.** Because history is recomputed on every analyze, reinterpret and open, a deleted or privacy-cleared Dream disappears from counts immediately. There is no ghost recurrence.

## Provider contract

`DreamAiContext.history` is a list of
`{kind, key, label, level: seen_before|recurring, priorCount}`. It carries no
ids, dates or prose. It is separate from the cross-feature `memorySummary`,
which never includes Dream memories for a Dream request.

- **Identity.** History joins the client request identity and the backend fingerprint/replay namespace, in prompt order, but only when non-empty. A no-history request keeps its previous identity. Exact retries are stable, and any count, level or item change gets a new identity and a new replay slot.
- **Validator.** The backend accepts only exact fields, known kinds, `kind:` key prefixes, fixed emotion/entry ids, short plain labels, integer counts 1..40, a level that matches the count, at most 5 items and unique keys. Anything else is `invalid_request`.
- **Prompt.** A separate section: TR "Önceki rüya örüntüleri", EN "Prior dream patterns", RU "Повторяющиеся элементы прошлых снов". The rules are always present. Use history only when it relates to this dream directly. Recurrence is descriptive, not predictive: never invent a reason, never frame it as a diagnosis or fate, and never attribute it to a real event. No "always", at most one or two links, and ignore history that adds nothing. No counts or dates.
- **Output schema.** Unchanged (Phase 2 canonical keys).
- **Claim gate.** `dreamHistoryClaimViolation` runs after the unchanged Phase 2 quality gate and returns one of these codes:
  - `history_unsupported`: a recurrence claim that does not name a supplied history item in the same sentence (Phase 4A.1, below).
  - `history_absolute`: "always" or "all your dreams" inflation.
  - `history_count`: a count that is neither supplied nor told by the dreamer.
  - `history_fate`: recurrence framed as fate or trauma.
  - `history_date`: a date the narrative does not contain.

  Negated claims and the dreamer's own recurrence statements pass. A rejection is `invalid_response` after exactly one provider call.

### Phase 4A.1 — strict claim binding

A provider sentence about prior dreams is accepted only when it names a supplied history item. Naming uses the frozen strict matcher `sameStrict` (the same word, or a real inflection in the request language) plus the fixed entry-chip aliases. There is no prefix fallback:

| History | Accepted | Rejected (`history_unsupported`) |
|---|---|---|
| rain | rain, rains | rainbow |
| door | door, doors | doorway |
| kapı | kapı, kapıda, kapıyı, kapının | kapıcı |
| deniz | deniz, denizde, denize, denizin | denizci |

With history supplied, a claim that names no supplied item ("this image has appeared in your earlier dreams") is also rejected. The provider cannot bootstrap its own evidence. Phase 2 general grounding (`sameWord`) is unchanged.

## Visible section

`DreamInsightKind.recurringPattern` is a local, deterministic insight. Its
title is "Tekrar eden iz / Recurring thread / Повторяющаяся нить" when any
shown item is recurring, and "Tanıdık bir iz / A familiar thread / Знакомая
нить" otherwise. It shows at most 3 lines. Each line comes from saved records:
the label, the exact total including this dream ("in 3 of your recent
dreams"), and the last-seen date of the saved record.

- It is attached to the live reading after commit and when a Dream is opened. It is never stored in the record or its versions.
- It sits after `personalConnection` in `DreamReadingPresentation`, so the provider's `dailyLifeReflection` keeps its place. If the provider already said the same line, it is shown once.
- It is rendered in the result view by `DreamResultHistoryCard`, which reuses `DreamResultPremiumCard` and renders nothing without history.
- It does not change reading provenance.
- `DreamPatternService` (lowercased labels and localized tags) and the inferential `dream.read.you.pattern` copy were removed.

## Performance

Measured in `dream_phase4a_history_builder_test.dart` (test O) with 50
analyzed priors: the build scans 40, returns 5 items and serializes to 448
bytes. Build time was about 5.6–6.0 ms in a debug test VM (JIT, cold start).
It is one pass per prior with no repeated regex, the work is bounded by
constants, and it runs once per analyze, reinterpret or open, never per frame.
