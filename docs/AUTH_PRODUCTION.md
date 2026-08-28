# ORACLY — Production authentication

**Status: Android and iOS Firebase client config files are present. Auth is not live in production.**

Do not treat this as store-ready or deployed authentication.

```
Flutter AuthService
  → FirebaseAuthService (when Firebase initializes)
  → Firebase ID token
  → Authorization: Bearer <token>
  → ORACLY proxy AuthenticationService
  → Google JWKS (RS256)
  → verified `sub`
  → rate limiter
  → OpenAI
```

Firebase **Analytics** (`NoOpFirebaseAnalytics`) is unrelated to Firebase **Authentication**.

Native `Firebase.initializeApp()` (no invented `firebase_options.dart`):

- Android: `google-services.json` + Google Services Gradle plugin
- iOS: `GoogleService-Info.plist` in the Runner target resources

## What exists in the repo

| Item | Status |
|---|---|
| `AuthService` / `FirebaseAuthService` / `MockAuthService` | Code ready |
| `firebase_core` / `firebase_auth` packages | Added |
| Android `google-services.json` | **Present** — project `oracly-7f613`, package `com.example.oracly_new` |
| Google Services Gradle plugin | Applied (`android/settings.gradle.kts` + `android/app/build.gradle.kts`) |
| iOS `GoogleService-Info.plist` | **Present** — project `oracly-7f613`, bundle `com.example.oraclyNew` |
| iOS Runner resources | `GoogleService-Info.plist` in Copy Bundle Resources |
| `firebase_options.dart` | **Not used** (not invented) |
| Backend JWKS verifier | Ready for Firebase-shaped tokens |
| Backend `FIREBASE_PROJECT_ID` | Set in deploy env: `oracly-7f613` |

## Environments

### LOCAL

`MockAuthService` may be used for tests and debug development when Firebase is not initialized (e.g. Windows desktop / unit tests).

On an Android or iOS device/emulator with the matching client file, `FirebaseAuthBootstrap` should initialize and select `FirebaseAuthService`.

`AI_DEV_AUTH_BYPASS=true` may be used on the **backend** only when `APP_ENV=development`.

### STAGING

Firebase Authentication required. MockAuth forbidden. Backend JWKS required (`FIREBASE_PROJECT_ID=oracly-7f613` or explicit JWKS/issuer/audience).

### PRODUCTION

Firebase Authentication required. Real Firebase ID token required. Backend verifies via JWKS. `MockAuthService` forbidden. `AI_DEV_AUTH_BYPASS` ignored / forbidden.

Production without Firebase init → `UnconfiguredAuthService` (typed failure, no mock tokens, no AI fallback).

## Flutter selection

| Build | Firebase initialized | Auth implementation |
|---|---|---|
| Debug / `APP_ENV=development` | no | `MockAuthService` |
| Debug / development | yes | `FirebaseAuthService` |
| Staging / production / release | yes | `FirebaseAuthService` |
| Staging / production / release | no | `UnconfiguredAuthService` |

Release binaries throw if `MockAuthService` is constructed.

Screens (Dream, Coffee, Tarot, Astrology, Birth Chart, AI Chat, Profile) use `AuthService` only.

## Token lifecycle

- ID tokens come from `user.getIdToken()` (Firebase SDK refresh).
- `TokenManager.getAccessToken(forceRefresh: true)` forces refresh.
- ID tokens are **not** persisted as passwords or custom JWTs.
- Logout: Firebase `signOut` + clear session + clear any stored token leftovers.
- Production `ProxyAiTransport` never sends `mock_*` or `sk-` tokens.
- Production `ProxyAiTransport` requires `X-Firebase-AppCheck` (fail-closed if missing).

## Backend Firebase JWKS

```
APP_ENV=production
FIREBASE_PROJECT_ID=oracly-7f613
```

This expands to:

```
AI_JWKS_URL=https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com
AI_JWT_ISSUER=https://securetoken.google.com/oracly-7f613
AI_JWT_AUDIENCE=oracly-7f613
```

Verifier checks signature, exp, iss, aud, and `sub`. Rate limit key is `sub:<hash(sub)>`. Body `userId` is ignored.

## External setup still required

1. ~~Create a Firebase project~~ — `oracly-7f613` exists.
2. ~~Register the Android app~~ — package `com.example.oracly_new` (placeholder ID — change before store release and re-download `google-services.json`).
3. ~~Register the **iOS** app~~ — bundle `com.example.oraclyNew` (placeholder ID — change before store release and re-download `GoogleService-Info.plist`).
4. ~~Download Android `google-services.json` / iOS `GoogleService-Info.plist`~~ — present.
5. ~~Apply the Google Services Gradle plugin~~ — done.
6. Do **not** invent `firebase_options.dart`. Optional later: `flutterfire configure` from the real project only.
7. Enable Firebase Authentication providers in Console (not verifiable from this repo):
   - Anonymous (maps to `signInAnonymously` / guest)
   - Email/password
   - Google / Apple — Android `oauth_client` is empty; iOS plist has no `CLIENT_ID` / `REVERSED_CLIENT_ID`. Add OAuth clients (and Android SHA-1/SHA-256) before Google Sign-In works
8. Set backend `FIREBASE_PROJECT_ID=oracly-7f613` (or explicit JWKS/issuer/audience). **Not deployed yet.**
9. Deploy HTTPS proxy. Point Flutter `ORACLY_AI_PROXY_URL` at `https://<real-host>/v1/ai/complete`.
10. Build Flutter **without** `OPENAI_API_KEY`. Confirm MockAuth is not selected.

## Security / logging

Do not log: Firebase ID tokens, Authorization, refresh tokens, passwords, Firebase private/service-account keys, OpenAI keys, full dream text, chat history, coffee images.

Firebase **client** config values (apiKey, appId) in `google-services.json` are not server secrets. Do not copy them into docs or logs. Never commit service-account JSON.

## Classification

| | |
|---|---|
| CODE READY | Yes |
| AUTH INTEGRATION READY | Yes |
| FIREBASE ANDROID CONFIGURED | Yes (native client file + Gradle plugin) |
| FIREBASE IOS CONFIGURED | Yes (native plist in Runner resources; iOS build not verified on Windows) |
| FIREBASE CONFIGURED (production live) | **No** |
| DEPLOYED | **No** |
| STORE READY | **No** |

## Firebase App Check (AI proxy)

Production AI requests attach both:

```
Authorization: Bearer <Firebase ID token>
X-Firebase-AppCheck: <App Check token>
```

Flutter activates App Check after Firebase Core:

- **Release / staging / production:** Android `PlayIntegrity`, Apple `AppAttest` with DeviceCheck fallback
- **Debug development only:** Android/Apple debug providers (never in release)

Token lifecycle is owned by the Firebase App Check SDK (`getToken` + auto-refresh). Do not invent a client-side long-lived cache.

### Debug token registration (local / staging)

1. Run a **debug** build with Firebase initialized.
2. Read the App Check debug token from logcat / Xcode console (SDK prints it once).
3. Firebase Console → App Check → your app → Manage debug tokens → register that token.
4. Do **not** commit debug tokens to git or hardcode them in Flutter source.

Play Integrity / DeviceCheck / App Attest provider enrollment in Firebase Console is EXTERNAL and done after this client wiring is green.
