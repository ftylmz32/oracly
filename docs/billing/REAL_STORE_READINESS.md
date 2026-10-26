# Billing — real store readiness (Google Play)

**Status (24 Oct 2026):** source preparation only, on `qa/billing-pending-resolution-20261024`.
No Google Cloud, Play Console, Pub/Sub, IAM or DNS resource was created or changed. The commands
below are a plan and have **not** been executed. Nothing in this document is proof that a live
payment, acknowledgement or notification works.

## 1. Acknowledgement retries on a dedicated queue

The backend acknowledges a Play purchase right after it verifies the purchase and binds it to the
account. If that call fails, the purchase goes into the Firestore outbox `billingAckOutbox`
(server only; `firestore.rules` denies clients). A Cloud Task then retries it at
`/internal/billing/acknowledge-retry`.

On this branch the retries use **only** the `BILLING_ACK_*` settings. There is no fallback to
`reading-operations`.

| Env | Meaning |
|-----|---------|
| `BILLING_ACK_QUEUE` | `billing-acknowledge` |
| `BILLING_ACK_LOCATION` | `europe-west1` (default) |
| `BILLING_ACK_TARGET_URL` | `https://<service-url>/internal/billing/acknowledge-retry` |
| `BILLING_ACK_AUDIENCE` | `https://<service-url>` |
| `BILLING_ACK_SERVICE_ACCOUNT` | `oracly-billing-tasks@oracly-7f613.iam.gserviceaccount.com` |

- `verifyBillingTask` (`backend/src/billing/billing-task-auth.ts`) checks every call to a billing
  task endpoint.
  - It accepts only a Google-signed ID token for `BILLING_ACK_AUDIENCE` whose email is
    `BILLING_ACK_SERVICE_ACCOUNT` and is verified.
  - It rejects the reading task identity.
  - If the billing identity is not configured, it rejects every call.
- If the queue settings are missing, `createAckRetryScheduler` returns a scheduler that **throws**
  `ack_retry_scheduler_unconfigured`. Each attempt is then marked (`scheduleFailed`) and logged at
  ERROR, never dropped silently.
- **Deploy order matters.** If this code ships before the queue, identity and env exist, every
  failed first acknowledgement ends up in the outbox marked `scheduleFailed` and logs
  `billing_ack_schedule_failed` until the sweep can run.

### Planned setup (NOT executed — needs owner approval)

```sh
PROJECT=oracly-7f613; REGION=europe-west1
RUNTIME_SA=<current Cloud Run runtime SA>
BILLING_SA=oracly-billing-tasks@$PROJECT.iam.gserviceaccount.com

gcloud iam service-accounts create oracly-billing-tasks --project $PROJECT \
  --display-name "Oracly billing task OIDC"
gcloud tasks queues create billing-acknowledge --project $PROJECT --location $REGION \
  --max-dispatches-per-second=5 --max-concurrent-dispatches=5 \
  --max-attempts=5 --min-backoff=30s --max-backoff=600s
# Runtime SA creates tasks that run as the billing SA:
gcloud tasks queues add-iam-policy-binding billing-acknowledge --project $PROJECT \
  --location $REGION --member serviceAccount:$RUNTIME_SA --role roles/cloudtasks.enqueuer
gcloud iam service-accounts add-iam-policy-binding $BILLING_SA --project $PROJECT \
  --member serviceAccount:$RUNTIME_SA --role roles/iam.serviceAccountUser
# The billing SA may invoke the service (only needed if ingress requires IAM):
gcloud run services add-iam-policy-binding oracly-api --project $PROJECT --region $REGION \
  --member serviceAccount:$BILLING_SA --role roles/run.invoker
```

The env is set with `gcloud run services update ... --update-env-vars BILLING_ACK_...`. That is a
deploy and needs separate approval.

### Acknowledgement order (Android Premium)

The Android app never acknowledges a Play purchase before the backend has verified it.
On Android, `completePurchase` acknowledges, so after a delivery the app only saves the receipt and holds the transaction.
`/v1/billing/verify` acknowledges the purchase after Play verification and the atomic owner binding.
For an active Android purchase, the answer carries `acknowledgement`:

| Value | Meaning | App behavior |
|-------|---------|--------------|
| `acknowledged` | Play state says acknowledged, or our acknowledge call succeeded | Finishes nothing |
| `pending` | Our acknowledge failed; the outbox/queue retries it | Acknowledges the verified, bound purchase itself, once |
| field absent (older backend) | Unknown | Acknowledges after verify itself, once |

- No other answer causes an acknowledgement or a grant.
- A purchase left unacknowledged when the app dies is still listed by Play. The load-time store scan finds it, including for an account that is already Premium, and it is verified before it is acknowledged.
- The outbox entry closes when a later verify, or the retry task, sees Play report it acknowledged.

Compatibility:
- Old apps (store build 26093014) acknowledge before verify and ignore the new field. Unchanged.
- New apps against the old backend acknowledge after verify, because the field is absent.
- The request shape is unchanged.
- iOS StoreKit finishing is unchanged.

Real-store proof still requires a license test. A backend 200 is not proof: the backend `billing_acknowledge` log and Play's `acknowledgementState` must be read for that token.

## 2. Nothing is lost silently: sweep, alarms, recovery

| Failure | What happens now | Signal |
|---------|------------------|--------|
| Task creation fails (Cloud Tasks down, IAM, unconfigured) | The entry stays `pending` with `scheduleFailed: true` and `nextAttemptAtMs`. The verify answer to the user is unchanged. | ERROR `billing_ack_schedule_failed` |
| A task is created but never runs, or runs out of its queue attempts | The sweep finds the entry because it is pending and more than `ACK_LOST_GRACE_MS` (15 min) past `nextAttemptAtMs`, then re-creates the task under a **new name** (`…-s<time>`). A reused name would get a 409 for a recently used task, and the retry would be lost. | sweep `rescheduled` count |
| Outbox write fails | Logged | ERROR `outbox_unavailable` |
| Still pending after `ACK_OVERDUE_MS` (60 h; Play refunds unacknowledged purchases at about 72 h) | The sweep counts it | ERROR `billing_ack_overdue` |
| All 8 retries used | The entry is closed as `gave_up` and stays in Firestore for support | ERROR `billing_ack_retry` errorCode `gave_up` |

The sweep is `POST /internal/billing/acknowledge-sweep`. It is billing-identity only, scans up to
500 pending entries per run, and returns counts only (`{pending, rescheduled, overdue}`), never
tokens.

### Planned scheduler and alerts (NOT executed)

The Cloud Scheduler API is currently **disabled** in the project. Enabling it needs approval.

```sh
gcloud services enable cloudscheduler.googleapis.com --project $PROJECT
gcloud scheduler jobs create http billing-ack-sweep --project $PROJECT --location $REGION \
  --schedule "*/15 * * * *" --http-method POST \
  --uri https://<service-url>/internal/billing/acknowledge-sweep \
  --oidc-service-account-email $BILLING_SA --oidc-token-audience https://<service-url>
# Log-based metrics, one alert policy each (threshold > 0 in 15 min):
gcloud logging metrics create billing_ack_schedule_failed --project $PROJECT \
  --log-filter 'resource.type="cloud_run_revision" severity>=ERROR jsonPayload.errorCode="billing_ack_schedule_failed"'
gcloud logging metrics create billing_ack_overdue --project $PROJECT \
  --log-filter 'resource.type="cloud_run_revision" severity>=ERROR jsonPayload.errorCode="billing_ack_overdue"'
gcloud logging metrics create billing_ack_gave_up --project $PROJECT \
  --log-filter 'resource.type="cloud_run_revision" severity>=ERROR jsonPayload.errorCode="gave_up"'
gcloud logging metrics create billing_ack_outbox_unavailable --project $PROJECT \
  --log-filter 'resource.type="cloud_run_revision" severity>=ERROR jsonPayload.errorCode="outbox_unavailable"'
```

Before creating the metrics, confirm the exact JSON field names against a real log line from a
tagged test revision. The filters above follow the `logSafe` / `app.log` shape used in the source
and have not been checked against live logs.

The alert policies also need a notification channel, which does not exist yet. A
`destek@oracly.app` channel must not be used until that mailbox is proven to receive mail
(section 4).

**Recovery runbook.**

1. An `overdue` or `gave_up` alert fires.
2. Read the outbox entry by id (the log never contains the token).
3. Check the purchase state in Play Console.
4. If the purchase is still `PURCHASED` and unacknowledged, re-open the entry by setting `status`
   to `pending` and `attempts` to `0`; the next sweep re-creates its task.
5. If Play has already refunded it, nothing more is needed: the entitlement is driven by the
   re-verify.

## 3. RTDN plan (Real-time developer notifications) — plan only

**Rule kept:** a notification is only a hint that something changed. It is never proof of
payment. Every notification leads to a Play Developer API re-verify, and only that result changes
entitlement or outbox state.

1. Pub/Sub topic `play-billing-rtdn` in `oracly-7f613`.
2. Grant `google-play-developer-notifications@system.gserviceaccount.com` the
   `roles/pubsub.publisher` role on that topic. This is the only publisher.
3. Play Console → Monetization setup → Real-time developer notifications: topic
   `projects/oracly-7f613/topics/play-billing-rtdn`, then send a test notification. This is a
   Play Console change and needs approval.
4. Push subscription `play-billing-rtdn-push`:
   - Endpoint: `https://<service-url>/internal/billing/rtdn`.
   - Authenticated push with OIDC service account `oracly-pubsub-push@…` and audience
     `https://<service-url>`.
   - Ack deadline 30 s, retry policy with exponential backoff.
   - Dead-letter topic `play-billing-rtdn-dlq` with max delivery 10, plus an alert on its
     backlog.
   - The Pub/Sub service agent needs `roles/iam.serviceAccountTokenCreator` on the push SA, and
     `roles/pubsub.publisher` on the DLQ topic and `roles/pubsub.subscriber` on the subscription
     for dead-lettering.
5. Webhook (**not implemented**):
   - Verify the OIDC token: Google issuer, push SA email verified, audience matches. Otherwise
     return 401.
   - Decode `message.data` (base64 JSON). Require `packageName == "app.oracly"` and a known
     product id. Otherwise return 204: drop it, do not retry.
   - Treat `testNotification` as a no-op.
   - For `subscriptionNotification` or `oneTimeProductNotification`: re-verify the token with
     `subscriptionsv2` / `products` through the existing `GooglePlayVerifier`.
   - Never read entitlement from the notification itself.
   - Only update an **existing** binding. A notification must never create a binding or grant an
     unbound account; binding still happens only through authenticated `/v1/billing/verify`.
   - For a still-unacknowledged active purchase, enqueue it into the same ack outbox.
   - Return 2xx only after the work is persisted, so Pub/Sub retries a failure.
   - Dedupe on `messageId`. Log hashes only.
6. `voidedPurchaseNotification` needs the Voided Purchases API or the re-verify to revoke a
   refunded or charged-back entitlement. Revoke policy is a product decision and still open.

## 4. Support channel

| Location | Address |
|----------|---------|
| App (`lib/features/help/services/support_report_payload.dart`, `table_help.dart` TR/EN/RU, About contact, mail launcher) | `destek@oracly.app` |
| `docs/support.md` (public support page source) | a personal Gmail address |

- **DNS:** `oracly.app` MX points to `mx1/mx2.hostinger.com`, and SPF includes Hostinger mail.
  The domain can receive mail at the provider level.
- **Not proven:** that the `destek@` mailbox or alias exists and gets delivered. No test mail was
  sent. Until a test message is sent and received, `destek@oracly.app` is the **target** channel,
  not a verified one.
- The release app already shows that address. No new link or address was added in this work.
- **Needed:** an owner-sent test mail to `destek@oracly.app` and a reply from it. Then align
  `docs/support.md` and the Play listing contact email to one verified address.

## 5. License-test requirements

| Need | State |
|------|-------|
| Play app `app.oracly` with the three products active | Unverified from here (needs Play Console read access) |
| License tester Gmail added (Play Console → Settings → License testing) | Unverified |
| Tester device signed in to that Gmail as the primary Play account | Unverified |
| Play Developer API access for the backend identity (`GOOGLE_PLAY_USE_ADC=true` on the live revision; the runtime SA must be invited in Play Console → Users and permissions with "View financial data" and "Manage orders and subscriptions") | Unverified. Needed for both verify and acknowledge. |
| Android device plus ADB | ADB at `D:\android\platform-tools\adb.exe`; **no device attached** |
| Separate test build | Must keep `applicationId app.oracly`. The `com.example.oracly_new` debug override cannot use Play billing products. A debug or profile build from this branch, pointed at a test backend, is needed. **Not built** (no build was allowed). |
| Backend under test | The live revision `oracly-api-00104-roc` runs `5c1090a0`, **without** this branch's owner tag, acknowledge, outbox or sweep code. Testing them needs a tagged, no-traffic revision of this branch, which is a deploy and needs approval. |

## 6. Real-device test matrix

Preconditions:

- A license tester on device A.
- A second Google account B on the same device.
- A test build pointed at a tagged, no-traffic backend revision of this branch.
- Logcat filtered to `flutter`.
- Backend logs filtered to `billing_*`.

For every row, the result is recorded from evidence (screen, log line, Firestore doc), never
assumed.

| # | Scenario | Steps | Expected |
|---|----------|-------|----------|
| D1 | Normal buy | A buys monthly with the "test card, always approves" option | Premium active. A verify log line. Outbox empty. Play order shows acknowledged. |
| D2 | Delayed payment | A buys with "slow test card, approves after a few minutes" | Pending panel, no premium. After approval: premium after "check later" / reopen. Acknowledged after verify. |
| D3 | Delayed payment declined | "slow test card, declines" | Pending clears, no premium, no outbox entry. |
| D4 | Tokenless lock | Start a purchase, kill the app before a token arrives, reopen | Pending kind `store`. Buttons locked. Same-plan retry hidden (default off). Clears after the 10-min clean check. |
| D5 | Account switch while pending | A starts a slow purchase, signs out, B signs in | B sees no pending or premium from A. A's receipt is parked and resolves only for A. |
| D6 | Restore | Reinstall, sign in as A, restore | Premium back for A. Restore while signed in as B → `owned_by_other`, no grant. |
| D7 | Backend ack fails | Make the Play acknowledge call fail on the tagged revision (test-only config or IAM) | Purchase answer still active. One outbox entry. Task on `billing-acknowledge`. Acknowledged on retry. |
| D8 | Queue failure | `BILLING_ACK_*` unset or enqueuer role missing | ERROR `billing_ack_schedule_failed`. Entry `scheduleFailed`. After the fix, the sweep reschedules it and it acknowledges. |
| D9 | Lost task | Delete the task from the queue | The next sweep re-creates it under a new name. |
| D10 | Refund before ack | Refund in Play Console while the entry is pending | Retry closes the entry (`inactive`/`expired`). Never acknowledged. |
| D11 | gave_up visibility | Force continued failures through the retry ladder (test-time clock not available live, so use a short test ladder only on a test revision) | Entry `closed/gave_up`. ERROR log. Alert fires. |
| D12 | Lifetime one-time product | A buys lifetime | Products path verify plus acknowledge. Owner bound. |

D7–D11 change backend configuration and need approval for each test revision. Live payments, if
ever wanted, are out of scope here.
