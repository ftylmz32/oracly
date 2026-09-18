# ORACLY Data Deletion

**Effective date: September 18, 2026**

ORACLY provides ways to delete account-related and personal data.

## In-app deletion path

Exact current UI path (English labels):

1. Open **ORACLY**
2. Open **Settings** (from Home, Profile, or other entry points that open Settings)
3. Under the **PRIVACY** section, open **Privacy**
4. On the **My Data** screen, choose **Permanently delete account**
5. Confirm with **Delete account**

Turkish labels in the same flow: **Ayarlar** → **Gizlilik** → **Verilerim** → **Hesabı kalıcı olarak sil** → **Hesabı sil**.

## What deletion does

When the in-app flow succeeds:

### 1. Server deletion (accepted first)

ORACLY sends an authenticated deletion request to its backend. The server **accepts** deletion (HTTP **202** style workflow) and writes a deletion receipt **before** finishing cleanup. Acceptance means deletion is authoritative for retry and write-barrier purposes; some physical cleanup may continue afterward.

Server cleanup removes supported user-owned records associated with the current identity, including where present:

- reading operations, results, inputs, staged-image metadata, provider stages, admission counters;
- SoulMate portrait metadata and attributable GCS objects under reading-staging / soulmate-portraits prefixes;
- Gem balances and related Gem ledger / idempotency records (**hard-deleted**);
- notification token registrations;
- short-lived identity-scoped AI response-replay documents.

OR/Luna conversation history, memory/personalization summaries, reading-history/journal, and favorites are stored only on your device, not in server storage — they are cleared in the local-wipe step below, not by server cleanup.

### 2. Purchase ownership handling

Purchase-binding records used for Premium integrity are **anonymized** (active identity removed; hashed prior-owner history retained) so fraud/rebind integrity can continue without keeping ordinary user content under the deleted account. This is not a full erase of all purchase-integrity metadata.

**Apple App Store and Google Play purchase records remain under those stores’ control** and are separate from ORACLY account deletion.

### 3. Firebase identity and local wipe

After server acceptance:

- the current Firebase authentication identity is deleted;
- user-bound **local** data on the device is cleared (including applicable discovery history, favorites, memory/personalization, cached Premium state, and related preferences);
- local push-token cleanup is attempted as a best-effort step;
- a fresh anonymous session is started so the app can continue to launch cleanly.

### 4. Deletion receipts

A hashed **account deletion receipt** may remain for about **30 days** as retry-safe proof that deletion was accepted. It is not ordinary reading content.

### 5. Retention / TTL safety nets

Some residues may remain until configured expiry or background cleanup:

- Firestore TTL on `expiresAt` for eligible collections (physical delete is not always immediate);
- GCS lifecycle safety nets (about **24 hours** for `reading-staging/`, about **30 days** for `soulmate-portraits/`);
- very short-lived AI replay bodies (about **10 minutes**);
- inaccessible legacy short-lived residues without an owner key, if any, until TTL removes them.

ORACLY does **not** promise immediate physical erasure of every byte at the instant you confirm deletion.

## Timing (truthful expectation)

- **Logical acceptance:** when the in-app flow reports success after server acceptance and local wipe.
- **Sweep completion:** usually during the same deletion workflow; retries re-sweep if needed.
- **Physical TTL / lifecycle removal:** may take until the configured retention window elapses (hours to about 30 days depending on record type).

## Local-only clears (without deleting the account)

On **My Data**, you can also:

- **Clear my discovery history**
- **Clear my favorites**
- **Reset memory summary**

These remove selected data **from this device only** and do not by themselves delete the Firebase account or all server records.

Uninstalling the app removes remaining app-local data from that device but does not by itself complete server account deletion.

## If you cannot access the app

Email:

**destek@oracly.app**

Subject:

**ORACLY Data Deletion Request**

Include enough non-sensitive information to help locate the relevant ORACLY identity or request. Do **not** send passwords, payment-card details, purchase tokens, API keys, authentication tokens, or other secrets.

## Contact

**App:** ORACLY  
**Email:** destek@oracly.app

Privacy Policy:  
https://github.com/ftylmz32/oracly/blob/main/docs/privacy-policy.md
