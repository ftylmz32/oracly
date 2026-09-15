# R5 retention matrix

No period below is a legal assertion. It is the shortest operational period supported by the current architecture; legal review may shorten or supersede it.

| Record | Purpose / owner key | Retention and deletion | User deletion | Content / identity |
|---|---|---|---|---|
| `readingOperations` | Durable lifecycle / `ownerUserId` | Ready: 30 days; failed/expired: 7 days; sweeper/TTL `expiresAt` | Delete | Metadata; pseudonymous owner |
| `readingOperationResults` | Deliver completed reading / `ownerUserId` | 30 days, `expiresAt` | Delete | Generated user content; pseudonymous |
| `readingOperationActive` | Resume active work / `ownerUserId` | Until terminal, then immediate delete | Delete | Metadata; pseudonymous |
| `readingOperationStagedImages` | Locate temporary image / `ownerUserId` | Active only; abandoned/terminal max 24 hours | Delete | Image metadata; pseudonymous |
| staged GCS objects | Temporary provider input / path contains pseudonymous owner | Success immediately; terminal/abandoned max 24 hours by sweeper | Delete | Private image content; pseudonymous path |
| `readingOperationInputs` | Resume structured operation / `ownerUserId` | Bounded fallback TTL 30 days; normal deletion follows operation/account lifecycle | Delete | User input; pseudonymous |
| `readingProviderStages` | Prevent duplicate provider calls / `ownerUserId` | Transient/unknown 7 days; completed aligned to result, max 30 days; `expiresAt` | Delete | Generated output checkpoint; pseudonymous |
| `responseReplay` | Cross-instance exact response replay / identity hash | 10 minutes, Firestore TTL `expiresAt` | Delete where attributable; otherwise TTL | Generated user content; pseudonymous |
| `gemBalances` | Authoritative wallet / owner hash | Account lifetime | Delete | Financial-like metadata; pseudonymous |
| `gemTransactions` | Integrity, refund and dispute audit / `ownerUserId` | No automatic TTL pending accounting/fraud policy | Pseudonymize, do not blindly erase | No user content; pseudonymous after deletion |
| `gemTransactionKeys` | Prevent double debit / `ownerUserId` | Same as referenced transaction | Pseudonymize/retain with transaction | No content; pseudonymous |
| `purchaseBindings` | Prevent dual entitlement / token hash | Active ownership lifetime plus minimum fraud/accounting need; no TTL | Remove current UID; retain pseudonymous history | No user content; pseudonymous |
| ownership history | Rebind/fraud evidence / purchase-binding hash | Same as binding | Survives, pseudonymized | No user content; pseudonymous |
| `accountDeletionReceipts` | Retry-safe deletion proof / receipt hash | 30 days, `expiresAt` | Survives as pseudonymous receipt | No content; pseudonymous |
| `readingNotificationTokens` | FCM delivery / `ownerUserId` | Until logout, switch, deletion, refresh replacement, or invalid-token response | Delete | Device token; pseudonymous owner but token is sensitive |
| OR/Luna memory | Personalization / `ownerUserId` | Account lifetime | Delete | User content; pseudonymous owner |
| `securityRateWindows` | Distributed abuse control / hashed key | Two windows maximum; TTL `expiresAt` | TTL | No content; pseudonymous |
| logs/audit metadata | Reliability/security diagnosis / request/operation IDs | Log-platform policy required; recommend 30 days operational default | Not directly deleted; never log content/tokens | Metadata only; pseudonymous |

## Future cloud action

After review, enable Firestore TTL policies on `expiresAt` for `securityRateWindows`, `responseReplay`, `accountDeletionReceipts`, `readingOperations`, `readingOperationKeys`, `readingOperationInputs`, `readingOperationStagedImages`, `readingProviderStages`, and `readingOperationResults`. This R5 task does not mutate Firestore configuration.
