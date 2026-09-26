# YILDIZNAME PHASE 8B.1 — Prepared Transaction + Primary Route Failure Firewall

**Start HEAD:** `935f388264b0572dd4adae06b736811df93f7cdb`  
**Flag:** `yildizname_narrative_v1` — default `false`, not remotely enabled.

## Defects closed

**A — preflight failure fell to legacy.** `StarMapPrimaryLeafOpen.open()` routed to the legacy sky leaf on `legacyLocal || !plan.isNarrativeEligible`, so `ownerUnavailable` and `invalidEvidence` became a successful legacy reading.

**B — prepare and execute used different owner snapshots.** The route preflighted under snapshot A, then the live screen called `execute()`, which recaptured owner/epoch. An account switch between the two let the same tap start a new operation under owner B.

## Prepared transaction

`YildiznamePreparedLiveExecution` (immutable): `ownerSnapshot` (owner + `accountSwitchEpoch`) · `languageCode` · final Phase 8A `plan`. No provider output, no BuildContext, no Riverpod refs.

- `prepare(languageCode)` — flag check, owner/epoch captured **once**, local preflight (one repair). No provider, no save.
- `executePrepared(prepared)` — uses `prepared.ownerSnapshot` as the authority; never recaptures.
- `execute(languageCode)` = `prepare` → `executePrepared` (one transaction path).
- `preflight(languageCode)` = `(await prepare(...)).plan` (compatibility projection).

### Classification in `executePrepared`

| Prepared plan | Result |
|---|---|
| `legacyLocal` | `legacyLocal` |
| `ownerUnavailable` | `ownerUnavailable` |
| `invalidEvidence` | `invalidEvidence` |
| `narrativeReduced` / `narrativeFull` | generation, after snapshot + flag recheck |

Before the provider: snapshot mismatch (owner **or** epoch) → `ownerChanged`, provider 0. Flag false → `flagDisabled`, provider 0, no legacy for that transaction. A → B → A with a changed epoch does not match.

## Primary route

- Flag false → legacy (unchanged).
- Flag true → `prepare`. **Only** `legacyLocal` routes to the legacy sky leaf.
- Every other plan pushes `StarMapNarrativeLiveScreen(prepared: prepared)`. Typed failures render `StarMapErrorState`; they never become legacy.

## Live host retry

- The first run consumes the prepared transaction once (`executePrepared`).
- Generation failure, `ownerChanged`, `invalidEvidence`, `ownerUnavailable` → Retry starts a **fresh** `execute` under the current owner.
- `persistencePending` → Retry calls `retryPersistence(pending)` only; provider count unchanged.
- One in-flight retry at a time.

## Semantic memory note

Unchanged: `semanticFingerprint = YildiznameRequestFingerprint.of(final request)`.

Phase 6 continuity self-exclusion uses the stored current artifact's semantic identity. Pre-generation artifact-memory request enrichment uses prior accepted history before a current artifact exists. 8B.1 does not add a circular/fixed-point semantic exclusion; a stronger pre-generation operation-exclusion contract, if wanted, must be designed separately.

## Unchanged

`YildiznameNarrativeLiveService`, attempts, parser, quality, wire payload, AI service, artifact completion, astronomy, Phase 7 result screen, goldens.

## Tests

`phase8b1_primary_failure_route_test` · `phase8b1_prepared_owner_test` · `phase8b1_epoch_aba_test` · `phase8b1_prepared_flag_test` · `phase8b1_retry_transaction_test` · `phase8b1_retry_preparation_test` · strengthened `phase8b_primary_route_test`. Fake generate only — **REAL PROVIDER CALLS: 0.**
