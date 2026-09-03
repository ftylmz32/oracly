# ORACLY — Release runtime configuration

Canonical Flutter client keys live in `OraclyRuntimeConfig` / `OraclyRuntimeKeys`.
Do **not** invent production hosts. Do **not** put secrets in dart-defines.

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
  --dart-define=ORACLY_TERMS_OF_USE_URL=https://<REQUIRED_PUBLIC_HOST>/terms
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