# Gate B2 — device test protocol (QA Play build)

**Status (26 Oct 2026):** QA APK installed on the test phone (TECNO KN8). Launch smoke passed. UI tests are blocked until the phone is physically available. No purchases have been made.

## Fixed setup (verify, do not change)

| Item | Value |
|------|-------|
| App on device | `app.oracly` versionCode `26102601`, debug-signed (cert `40cbad11…`) |
| APK | `D:\oracly_qa_artifacts\gate_b1_20261026\oracly-qa-play-0318a147-vc26102601-debug.apk`, SHA-256 `61874df6…7d39f3a0` |
| QA backend | `oracly-api-play-qa`, revision `oracly-api-play-qa-00004-hop`, Firestore DB `oracly-play-qa` |
| Rollback | `--to-revisions oracly-api-play-qa-00003-lxp=100` |
| Ack queue | `oracly-billing-ack-qa` (europe-west1); OIDC identity `oracly-billing-ack-qa@…` |
| Prod | `oracly-api-00104-roc` at 100%. Never targeted, never changed. |

- Accounts: a separate license-tester Gmail on the phone's Play Store, and a separate Firebase test user. Never a personal account.
- The tester unlocks the phone. The agent never enters a PIN or dismisses a secure lock.
- During the session, `svc power stayon usb` may be turned on. Turn it off afterwards with `svc power stayon false`.

## Step 1: UI and routing (no payment)

1. Launch the app. Capture a screenshot of splash and onboarding, and the app logcat with `--pid`. Expect no FATAL entries and no Flutter exceptions.
2. Complete onboarding with the test user (the tester types any credentials).
3. Read the QA server logs (`service_name="oracly-api-play-qa"`) from the launch time onward. Expect the app's requests there, authenticated with 2xx status codes. Do not log user identifiers.
4. Read prod logs (`service_name="oracly-api"`) for the same minutes. Expect no request from this test user. Compare request IDs and timing only; never print identifiers.
5. Open Premium. The store returns monthly, yearly and lifetime with prices. Do not tap Buy.

Pass: 1–5 all hold. Any request reaching prod: stop and report.

## Step 2: license purchase (only after a separate, explicit approval)

Use one license-test payment method per run. Order: "Test card, always approves", then the slow-approve card, then the slow-decline card.

For each run, record:

- **Client:** the purchase result, and the app event order (no `complete` before `verify`).
- **Server:** the `billing_verify` result. Look for `billing_acknowledge` at INFO (server acknowledged), or WARN plus an outbox entry plus a task on `oracly-billing-ack-qa` (queued).
- **Play (via the QA backend's Play read):** `acknowledgementState = ACKNOWLEDGED` within 3 minutes. License-test purchases left unacknowledged are refunded after about 3 minutes.
- **Entitlement:** Premium is active only for the test user. The binding exists in `oracly-play-qa` only.

Pass: verified → bound → acknowledged, exactly once, and no second charge. A backend 200 alone is not a pass.

## Out of scope here

RTDN, Scheduler sweep job, alerts, iOS, prod rollout. Real (non-test) payment is never made.
