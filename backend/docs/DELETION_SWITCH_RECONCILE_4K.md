# 4K — account deletion across the traffic switch

## Root cause

1. `deleteForIdentity` returned at once when the receipt was `accepted`
   (`c58a773d`, `account-deletion.ts`). An older revision (`5c1090a0`) writes
   `accepted` without sweeping `freeTextQuota*`, `ritualDailyQuota*`,
   `speechGrants`, `speechPreviewDay`, `readingLegacyDirectAi` and
   `speech-clips/`, so its leftovers could never be removed by a retry.
2. Reading tasks are pinned to the `rc5c1090a0` tag
   (`READING_TASK_PINNED_TARGET_URL`). Until that tag moves, and for every
   execution already running on the old revision after it moves, the old
   worker calls `admitRitualQuota` / `finishRitualQuota` / `failRitualQuota`
   without a deletion barrier and can write after the sweep.

## Fix (smallest)

- `deleteForIdentity`: an `accepted` receipt now re-runs the same idempotent,
  owner-scoped sweep (the barrier already exists) and answers with the
  original receipt. If anything was removed, the receipt gets
  `reconciledAt` / `reconciled*` counters; its TTL is unchanged. Failures
  propagate (nothing is reported as cleaned).
- `reconcileDeletedIdentity(identity)`: the same re-sweep for the tool; it
  refuses identities without an `accepted` receipt.
- `scripts/deletion-reconcile.ts` + `deletion-reconcile-plan.ts`: dry-run by
  default; exact match `sha256("account-delete\0"+identity)` → receipt id;
  prints counts only. Every run (dry run too) needs `FIREBASE_PROJECT_ID`,
  `FIRESTORE_DATABASE_ID` and `READING_STAGING_BUCKET` set explicitly AND
  repeated as `--project`, `--database`, `--bucket` (4L: QA and production
  share the project; nothing falls back to `(default)`). Apply also needs
  `--apply` and `ORACLY_DELETION_RECONCILE_APPROVED=yes`; cap
  `--max-identities` (25). Logic: `src/account/deletion-reconcile-cli.ts`
  (in the image: `node dist/account/deletion-reconcile-cli.js`). Run it
  under a service account whose IAM is limited to the target environment.
- Not matchable (reported): `speech-clips/<owner>/` objects with no record
  left — covered by the age-based speech cleanup (lifecycle `age: 2`).

The worker / reading code is not changed.

## Switch-window procedure (each step read-only unless stated)

1. **Before** (T0): note `accountDeletionReceipts` count and the newest
   `completedAt`; `gcloud tasks list --queue=reading-operations
   --location=europe-west1` → number of pending tasks; the queue's dispatch
   deadline (`gcloud tasks queues describe`).
2. **Switch** (PO approval): one command that moves 100 % and the
   `rc5c1090a0` tag to the new revision.
3. **Drain** (T1): wait until both hold, not just a fixed delay:
   - no task created before T1 is still listed in the queue (pending or
     being dispatched; retries included);
   - Cloud Logging shows no new request on the old revision
     (`resource.labels.revision_name="oracly-api-00104-roc"`) for at least
     the queue dispatch deadline and the Cloud Run timeout (180 s).
4. **Detect**: run `scripts/deletion-reconcile.ts` (dry run). Any
   `identitiesToReconcile > 0` means an accepted deletion has leftovers
   (older revision or late write).
5. **Reconcile** (PO approval): the same tool with `--apply`.
6. **Repeat** steps 4–5 after 24 h and well before 30 days (receipts expire
   after 30 days; afterwards leftovers can no longer be tied to a deletion).

Running the tool needs credentials the tool can use (ADC); this machine has
none today — creating them is a separate decision.
