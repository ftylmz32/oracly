# Monitoring and support contract

Never log prompts, generated bodies, raw images, auth/App Check tokens, purchase tokens, notification tokens, API keys, or credentials.

| Signal | Event/source | Severity / threshold concept | Group by | Safe fields |
|---|---|---|---|---|
| 5xx spike | request status / `unhandled_error` | critical; sustained ratio above baseline | revision, route | requestId, revision, status, errorCode |
| Reading failures | `reading_task_stage_failed` | high; failure ratio/window | readingType, stage, revision | operationId, stage, retryable, errorCode |
| Unknown provider result | `provider_outcome_unknown` | high; any burst, page if sustained | readingType, revision | operationId, attemptId, timestamps |
| Task retry/backlog | Cloud Tasks queue metrics | high; oldest age/retry count exceeds SLO | queue, revision | task name suffix, attempt count |
| Poison task | max-attempt/dead task metric | critical; any | queue, error category | operationId where available |
| Billing failure | `billing_verify` | high; elevated error/unverified rate | platform, reason, revision | purchase-binding hash, status, reason |
| Rebind failure | `purchase_rebind_failed` | high; any sustained count | platform, reason | binding hash, reason; never token |
| Gem compensation | `gem_compensation` | medium; trend/anomaly | reason, readingType | operationId, transactionId, amount |
| Account deletion | `account_deletion_failed` | critical; any repeated failure | stage, revision | receiptId, stage, errorCode |
| Staged cleanup | `staged_cleanup_failed` | high; any aged backlog | object/metadata stage | operationId, readingType, safe path hash |
| Provider failures | existing provider error/timeout events | high; ratio/window | model, operation, revision | requestId, operationId, errorCode |
| Notification failure | `notification_send_failed` | medium; invalid tokens separately | reason, revision | operationId, readingType; never token |

Threshold numbers must be set from observed traffic and SLOs; this source contract deliberately does not invent production baselines.

## Support correlation

Ask users only for the in-app operation/reference ID and approximate UTC time. Operators correlate `operationId`, pseudonymous identity, purchase-binding hash, Gem transaction/idempotency ID, reading type, revision, transitions, timestamps and error category.

- “Premium did not open”: locate billing event by support time/identity, then binding hash and rebind outcome. Never request the purchase token.
- “Gem disappeared”: locate operation, debit transaction and matching refund/compensation ID.
- “Reading never completed”: inspect operation timeline, provider-stage state, task attempts, result persistence and cleanup state.

Escalation artifacts must never include tokens, secret defines, raw images or provider response bodies.
