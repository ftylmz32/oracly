# F1 — Coffee daily quota after gem acceleration (Büyük Final Aşama 01)

**Date:** 26 Oct 2026. Branch `qa/coffee-f1-quota-20261026`, base `3bfa02c8`. Tests and docs only; no source changed.

**Verdict:**

- Economics and state: **PASS**.
- Observability: **FAIL**. The outcome is not logged.
- The two prod operations: **UNKNOWN**. Prod data was not read.

## What the current code does (measured)

The tests use the real `ReadingProcessor`, `ReadingFlow`, `GemLedger` and ritual quota code over the in-memory store. The AI provider is a counting fake.

| Requirement | Result | Test |
|---|---|---|
| Ends `failed` with `failureCode: daily_quota`. The public status shows it, with no result. | PASS | `backend/tests/coffee-daily-quota-accelerated.test.ts` |
| AI provider never reached (legacy and V3) | PASS | same |
| Gem debit refunded in full, exactly once (one `spend`, one `refund`) | PASS | same |
| Worker retry and concurrent workers: no second refund or debit | PASS | same |
| Repeated acceleration (same key and new key) on the failed reading: no debit | PASS | same |
| Another account: balance untouched, quota not shared | PASS | same |
| V3 2 cups + 1 saucer: same outcome, the three views cleaned | PASS | same |
| App decodes `daily_quota` and shows the coffee quota message, never a generic failure or success | PASS | `test/features/coffee/coffee_daily_quota_message_test.dart` |
| The outcome is logged | **FAIL** | `it.fails('[F1 FAIL] …')` in the backend test |

Mutation check: each of these makes the tests fail.

- Quota not wired.
- `failFinal` skips the refund.
- Quota reply mapped to `unavailable`.

## The defect

In `backend/src/reading/reading-processor-execute.ts`, the ritual `reply` branch calls `failFinal(daily_quota)` and returns without a log event. Every other terminal exit logs one (`coffee_v3_terminal_failure`, `spend_guard_rejected`, `provider_outcome_unknown`). The refund that follows is not logged either.

The worker log for this path is exactly:

`reading_task_claim_acquired, staged_fetch_started, staged_fetch_succeeded, provider_started, validation_started`

That is the same sequence seen for the two prod operations of 23 Oct (~21:17, ~21:18). This is consistent with the quota path, but not proof. Their stored state and gem refund were not read: the prod Firestore read was refused by policy.

## Further observations (not failures)

- The quota is checked only in the worker. A user who already had today's coffee can upload three photos and pay gems before being refused. The gems are refunded.
- The quota message (`resilience.coffee_daily_quota`) does not say the gems were refunded.

## Smallest safe fix (needs explicit approval; the file is frozen reading code)

Add one log line in the ritual `reply` branch, before `failFinal`:

`log.info({ event: 'ritual_quota_rejected', operationId, feature, failureCode })`

This is logging only, with no behavior change. Then flip the `it.fails` test to `it`.

Optional, as a separate product decision: check the quota before staging or acceleration, and mention the refund in the quota message.
