# R5 successor ownership

- Predecessor: `C:\Dev\oracly_backend_candidate_r4_freeze`
- Predecessor manifest SHA-256: `e235b98a910d8019b58c0b2cd26a7f5a2bfa9141a7a4ace7f02e8cf092bdadd4`
- Predecessor tree SHA-256: `29c42bf2ea19b27eb04907f433d9065618408c82cfa3de5e48e50218b7d53d41`
- Scope: P2 operations, retention, observability, supportability, traceability, rollback and recovery only.
- Client ownership: unchanged R4 client candidate; Coffee visual approval remains a separate gate.
- Cloud/provider/deployment mutation: prohibited and not part of this candidate.

## TTL activation runbook (future cloud action)

After change approval, run once for each TTL-eligible collection group that stores an `expiresAt` Firestore Timestamp:

`gcloud firestore fields ttls update expiresAt --collection-group=<COLLECTION_GROUP> --enable-ttl --database=<DATABASE_ID> --project=<PROJECT_ID>`

Eligible now: `readingOperationStagedImages`, `readingProviderStages`, `readingOperationResults`, `accountDeletionReceipts`, `responseReplay`, and the existing rate-window collection. Confirm exact deployed collection names from configuration before applying. Do not enable TTL on Gem ledgers, Gem idempotency/integrity records, or purchase bindings/history.

Schedule `FirestoreStagedImageRetentionSweeper.sweep()` through an authenticated maintenance job after deployment approval. Alert on nonzero `failed`, aged eligible backlog, and repeated `staged_cleanup_failed` events.
