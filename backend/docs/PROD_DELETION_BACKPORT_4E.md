# Production backport 4E — account deletion + speech lifecycle

Base: production source `5c1090a0` (Cloud Run `oracly-api-00104-roc`, 100%).
Branch: `fix/prod-account-deletion-backport-20261101`. **Not deployed.**

## Ported

| From | What | How |
|---|---|---|
| `6352bb5e` | `readingLegacyDirectAi` in the owner sweep | Applied as-is (`account-deletion.ts` identical to its parent). Production has no writer for it yet → forward-compatible no-op |
| `e77838e6` | Identity sweep of `freeTextQuota`, `freeTextQuotaAttempts`, `ritualDailyQuota`, `ritualDailyQuotaAttempts`; `deletionBarrierExists`; barrier in quota admissions (throw) and settlements (no-op); AI route maps `AccountDeletedError` → 401 | Quota / barrier files applied as-is; `routes/ai.ts` hunk adapted by hand (import context differs) |
| `57cc56eb` (4C) | Speech TTL fields, barrier in speech claim / finish / grant issue, orphan-clip discard, speech sweep + `speech-clips/<owner>/` deletion, dry-run cleanup tool, docs | Applied; `routes/ai.ts` hunks applied with offsets |

## Not ported

- `6352bb5e` `reading-commerce-gate.ts` barrier: the pin writer (`admitOnce`, `0f960699`) does not exist in production.
- Everything else between `5c1090a0` and the RC / Freemium / AdMob / Coffee V3D heads (commerce gates, Freemium V1, ads, Flutter, engines).

## Gates (each needs PO approval)

1. **Source review:** `git diff 5c1090a0..<backport>` limited to the files listed in the commit; protected paths diff 0.
2. **Staging:** deploy to `oracly-api-play-qa` (own bucket `*-reading-staging-qa-ew1`, DB `oracly-play-qa`) or a no-traffic test service; run: chat → TTS → preview → account deletion → retry; confirm `speech-clips/` and the quota / speech collections are empty for the deleted test identity and untouched for a second one.
3. **Production revision, no traffic:** `gcloud run deploy ... --no-traffic --tag=<tag>`; verify the tagged URL (health, a test-account TTS and deletion); compare the revision image digest with the reviewed commit build.
4. **Traffic switch:** 100% to the new revision; rollback = traffic back to `oracly-api-00104-roc`. **Rollback restores code only; data deleted meanwhile is not restored** (Soft Delete 0 s, no versioning, Firestore PITR off).
5. **Firestore TTL:** `speechGrants.expiresAt`, `speechPreviewDay.expiresAt` (re-check `fields ttls list` first; re-run the aggregate inventory: new records may exist by then).
6. **GCS lifecycle:** merge the `speech-clips/` `age: 2` rule into the CURRENT config (re-`describe` immediately before; must still be exactly `reading-staging/` 1 day + `soulmate-portraits/` 30 days).
7. **Historical cleanup:** only if the re-run inventory is non-zero; dry run, PO review, then apply.
8. **Privacy text:** only after 4–6 are verified.

## Before any destructive step

There is no undo in this project today. Options to evaluate (PO decision, cost): a Firestore managed export (`gcloud firestore export gs://<backup-bucket> --collection-ids=...`) to a separate, access-restricted bucket with its own short retention; enabling GCS Soft Delete temporarily (it applies to deletions made while enabled); Firestore PITR (7 days). A backup of personal data is itself personal data: define its retention and deletion before taking it.
