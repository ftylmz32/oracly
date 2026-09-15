# ORACLY — Release runtime configuration

Canonical Flutter client keys live in `OraclyRuntimeConfig` / `OraclyRuntimeKeys`.
Do **not** invent production hosts. Do **not** put secrets in dart-defines.

## Local development (real device or emulator against the local backend)

The client never reads the developer's own `.env` file at runtime — `main.dart`
deliberately only loads the checked-in `.env.example` (safe placeholders only,
e.g. `ORACLY_DEV_PREMIUM`), so a real backend URL in a personal `.env` is never
picked up by `flutter run` on its own. Config always flows through
`--dart-define` (directly or via `--dart-define-from-file`), the same as
staging/production.

The ONE supported local command:

```bash
flutter run --dart-define-from-file=tool/dart_defines.development.json
```

`tool/dart_defines.development.json` already ships with `APP_ENV=development`
and `ORACLY_AI_PROXY_URL=http://127.0.0.1:8787/v1/ai/complete`. For a real
Android device (not the emulator), forward the port first:

```bash
adb reverse tcp:8787 tcp:8787
```

For the Android **emulator** specifically, edit the file's
`ORACLY_AI_PROXY_URL` to `http://10.0.2.2:8787/v1/ai/complete` (the emulator's
alias for the host loopback) — or omit `ORACLY_AI_PROXY_URL` entirely and use
`--dart-define=APP_ENV=local` instead, which auto-guesses the right loopback
URL per platform with zero other configuration
(`AiRuntimeConfig.devProxyAutoDefaultUrl`).

`APP_ENV=development` (this file's value) and `APP_ENV=local` both allow a
loopback `ORACLY_AI_PROXY_URL` — the difference is only that `local` will also
auto-guess one when none is explicitly set. Neither is ever honored once
release-locked (see below).

Confirm it worked: the app logs
`[ProxyAiTransport] configured=true usesProxy=true vision=true
endpoint=http://127.0.0.1:8787/v1/ai/complete` on startup (debug builds only).
`configured=false` means no proxy URL resolved — check the dart-define file
path and that the backend is actually listening on that port.

## Mandatory for store release

| Key | Notes |
|-----|--------|
| `APP_ENV` | `production` (release also implies production-like) |
| `ORACLY_AI_PROXY_URL` | Public `https://…/v1/ai/complete` |
| `ORACLY_BILLING_VERIFY_URL` | Public `https://…` billing verify endpoint |

Missing / localhost / LAN / plain HTTP values are **rejected** in release (fail closed). AI does not fabricate answers; Premium does not invent remote verification.

## Optional (public)

| Key | Notes |
|-----|--------|
| `ORACLY_AI_MODEL` | Default `gpt-4o` |
| `ORACLY_AI_TIMEOUT_SECONDS` | Default `45` (15–90) |
| `ORACLY_AI_VISION` | Default `true` |
| `ORACLY_PRIVACY_POLICY_URL` | Public HTTPS privacy policy |
| `ORACLY_TERMS_OF_USE_URL` | Public HTTPS terms |
| `ORACLY_DATA_DELETION_URL` | Public HTTPS data deletion instructions |

## Debug-only (never in store builds)

| Key | Notes |
|-----|--------|
| `ORACLY_DEV_PREMIUM` | Ignored in release / non-development |
| `OPENAI_API_KEY` | Dotenv / local only — **never** `--dart-define` |

## Android App Bundle (template)

Copy `tool/dart_defines.production.example.json` → gitignored
`tool/dart_defines.production.json`, replace every `REPLACE_WITH_*` with real hosts,
then:

```bash
flutter build appbundle --release \
  --dart-define-from-file=tool/dart_defines.production.json
```

Equivalent explicit form (placeholders only):

```bash
flutter build appbundle --release \
  --dart-define=APP_ENV=production \
  --dart-define=ORACLY_AI_PROXY_URL=https://<REQUIRED_REAL_HOST>/v1/ai/complete \
  --dart-define=ORACLY_BILLING_VERIFY_URL=https://<REQUIRED_REAL_HOST>/v1/billing/verify \
  --dart-define=ORACLY_AI_MODEL=gpt-4o \
  --dart-define=ORACLY_AI_VISION=true \
  --dart-define=ORACLY_AI_TIMEOUT_SECONDS=45 \
  --dart-define=ORACLY_PRIVACY_POLICY_URL=https://<REQUIRED_PUBLIC_HOST>/privacy \
  --dart-define=ORACLY_TERMS_OF_USE_URL=https://<REQUIRED_PUBLIC_HOST>/terms \
  --dart-define=ORACLY_DATA_DELETION_URL=https://<REQUIRED_PUBLIC_HOST>/data-deletion
```

APK:

```bash
flutter build apk --release \
  --dart-define-from-file=tool/dart_defines.production.json
```

## iOS (template)

On macOS with Xcode signing configured externally:

```bash
flutter build ipa --release \
  --dart-define-from-file=tool/dart_defines.production.json
```

Team ID, certificates, and provisioning profiles are **external** — not in this repo.

## Validation

`OraclyRuntimeConfig.resolve(releaseLocked: true).missingMandatoryReleaseKeys`
lists absent mandatory HTTPS endpoints after sanitization.