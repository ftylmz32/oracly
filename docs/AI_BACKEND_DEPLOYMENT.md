# ORACLY AI backend deployment

```
LOCAL / STAGING / PRODUCTION are separate. Nothing here has been deployed.
```

**Phase E2:** Cloud Run preparation assets live in `backend/Dockerfile`,  
`backend/scripts/deploy-cloud-run.sh` (do not run until authorized), and  
[`docs/CLOUD_RUN_E2_RUNBOOK.md`](./CLOUD_RUN_E2_RUNBOOK.md).  
No Cloud Run service was created from this repository in E2.

```
Flutter  →  HTTPS ingress  →  Fastify AI proxy  →  OpenAI
```

**Status:** backend code + Docker + Firebase JWKS adapter exist in `/backend`.  
**No ORACLY AI proxy was deployed from this repository. No ORACLY TLS endpoint. No production `OPENAI_API_KEY` injected into a public host from this environment.**

Note: DNS for `api.oracly.app` may resolve, but it is **not** this Fastify service (probed `/health` and `/v1/ai/complete` return unrelated 404 HTML). Do not point Flutter production builds at it until an ORACLY proxy is actually hosted there.

Stack: **Node.js 20+ · TypeScript · Fastify**

Auth architecture: [`docs/AI_AUTH.md`](./AI_AUTH.md)

Simplest practical production path: **existing `backend/Dockerfile`**, one container, platform HTTPS ingress, Firebase ID tokens.

Backend code does **not** need changes before that deploy. Missing pieces are external: host, TLS, and secrets.

## Environments

### LOCAL

```
APP_ENV=development
HOST=127.0.0.1
PORT=8787
AI_DEV_AUTH_BYPASS=true          # optional, local only
ORACLY_AI_PROXY_URL=http://127.0.0.1:8787/v1/ai/complete
```

Android device → PC: set `HOST=0.0.0.0` and use the PC LAN IP in Flutter. Or `adb reverse tcp:8787 tcp:8787`.

### STAGING

Treat like production for auth: no bypass, Firebase JWKS required, HTTPS URL in Flutter.

```
APP_ENV=staging
HOST=0.0.0.0
PORT=<platform>
OPENAI_API_KEY=<staging secret>
FIREBASE_PROJECT_ID=oracly-7f613
```

Flutter: `APP_ENV=staging` + `ORACLY_AI_PROXY_URL=https://<staging-host>/v1/ai/complete`  
Never `http://`, `127.0.0.1`, or `localhost` in a staging/production app binary.

### PRODUCTION

```
APP_ENV=production
HOST=0.0.0.0                    # default when APP_ENV=production
PORT=<platform-provided-port>
OPENAI_API_KEY=<server-side secret>
OPENAI_MODEL=gpt-4o
FIREBASE_PROJECT_ID=oracly-7f613
FIREBASE_PROJECT_NUMBER=<firebase-project-number>
AI_DEV_AUTH_BYPASS=false         # ignored even if set
ORACLY_APP_CHECK_REQUIRED=true   # always on in production/staging
ORACLY_GLOBAL_AI_RPM=60          # process-wide; single instance only
ORACLY_GLOBAL_AI_CONCURRENCY=8   # process-wide; single instance only
```

### Single-instance requirement (cost safety valves)

Subject rate limits and the **global** RPM / concurrency ceilings are **in-memory and process-local**.

**Initial production deployment MUST run with a maximum of ONE backend instance** unless/until a shared or edge rate-limit store is introduced. Do not scale horizontally and assume these valves still protect OpenAI spend — each instance would have its own counters.

This is an operational deployment constraint, not a hosting-vendor choice.

`FIREBASE_PROJECT_ID=oracly-7f613` is enough for ID-token verification. It expands to:

```
AI_JWKS_URL=https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com
AI_JWT_ISSUER=https://securetoken.google.com/oracly-7f613
AI_JWT_AUDIENCE=oracly-7f613
```

Do not invent a second IdP. Explicit `AI_JWKS_URL` / `AI_JWT_ISSUER` / `AI_JWT_AUDIENCE` remain optional overrides.

Flutter production binary:

```
--dart-define=APP_ENV=production
--dart-define=ORACLY_AI_PROXY_URL=https://<real-production-host>/v1/ai/complete
```

Must **not** contain `OPENAI_API_KEY`. Must not use mock tokens. Must not put the OpenAI key in Flutter `.env` assets or any client-side config.


## AI request gate order

```
request
→ validation (handler)
→ Firebase Auth (ID token)
→ Firebase App Check (X-Firebase-AppCheck)
→ subject abuse / rate / concurrency
→ global cost valves (RPM + concurrency)
→ AI provider
→ sanitized response
```

`/health` and `/ready` are not gated by App Check client tokens.

## Endpoints

| Method | Path | Auth | Purpose |
|---|---|---|---|
| `GET` | `/health` | none | Liveness `{ "status": "ok" }`. No OpenAI. No secrets. |
| `GET` | `/ready` | none | Readiness `{ "status": "ready" }` or `503 { "status": "not_ready" }`. No config dump. |
| `POST` | `/v1/ai/complete` | required in prod/staging | AI proxy |

`/ready` is ready only when `OPENAI_API_KEY` is set, an auth verifier exists (JWKS via `FIREBASE_PROJECT_ID`, explicit JWKS, or HS256), **and** App Check can initialize when required (needs `FIREBASE_PROJECT_ID`). Health/ready never require an App Check client token. Missing any of those → `503`.

## Start / Docker

From the repo:

```bash
cd backend
npm ci
npm test
npm run typecheck
npm run build
npm start                 # node dist/index.js
```

Local health after `npm start` or `npm run dev`:

```bash
curl -sS http://127.0.0.1:8787/health
curl -sS http://127.0.0.1:8787/ready
```

Container (preferred production artifact):

```bash
docker build -t oracly-ai-proxy ./backend
docker run --rm -p 8787:8787 \
  -e APP_ENV=production \
  -e PORT=8787 \
  -e FIREBASE_PROJECT_ID=oracly-7f613 \
  -e OPENAI_API_KEY \
  oracly-ai-proxy
```

`-e OPENAI_API_KEY` injects the host/process secret. Do not bake it into the image. Do not commit it.

Graceful shutdown: `SIGTERM` / `SIGINT` close the Fastify server.

Platform `PORT` is honored. Production default bind is `0.0.0.0`. Development default bind is `127.0.0.1`.

Image `HEALTHCHECK` probes `/health` (liveness). Route traffic with `/ready`.

## Required production environment

| Variable | Required | Secret? | Notes |
|---|---|---|---|
| `APP_ENV` | yes | no | `production` |
| `PORT` | yes (platform) | no | Default `8787` if unset |
| `HOST` | optional | no | Default `0.0.0.0` in production |
| `OPENAI_API_KEY` | yes | **yes** | Server secret only. Never Flutter / dart-define / assets |
| `FIREBASE_PROJECT_ID` | yes (simplest path) | no | `oracly-7f613` — public project id |
| `OPENAI_MODEL` | recommended | no | Default `gpt-4o` |
| `OPENAI_ALLOWED_MODELS` | optional | no | Default `gpt-4o,gpt-4o-mini` |
| `OPENAI_TIMEOUT_SECONDS` | optional | no | Default `45` (clamped 1–90). Fastify request timeout = this + 5s |
| `OPENAI_VISION` | optional | no | Default `true` |
| `AI_JWKS_URL` | optional override | no | HTTPS required in production. Filled by Firebase project id |
| `AI_JWT_ISSUER` | optional override | no | Filled by Firebase project id |
| `AI_JWT_AUDIENCE` | optional override | no | Filled by Firebase project id |
| `AI_JWT_SECRET` | alternative to JWKS | **yes** | HS256 only if an IdP actually signs HS256. Not used with Firebase |
| `AI_DEV_AUTH_BYPASS` | must stay false | no | Ignored in production/staging |
| `AI_RATE_LIMIT_MAX` | optional | no | Default `20` / window. In-memory, single instance |
| `AI_RATE_LIMIT_WINDOW_MS` | optional | no | Default 15 minutes |
| `AI_MAX_CONCURRENT` | optional | no | Default `2` per verified identity |
| `AI_MIN_IMAGE_BYTES` / `AI_MAX_IMAGE_BYTES` / `AI_MAX_BODY_BYTES` | optional | no | Coffee / body limits (8 KB–12 MB image, ~14 MB body) |

Public configuration (safe to set in platform config, not secret): `APP_ENV`, `HOST`, `PORT`, `FIREBASE_PROJECT_ID`, model/timeout/vision, rate-limit and body limits.

Secrets (platform secret store only): `OPENAI_API_KEY`. `AI_JWT_SECRET` only if HS256 is used instead of Firebase.

Never commit real secrets. Never copy them into Flutter. Never auto-create `.env` files.

Without `FIREBASE_PROJECT_ID` (or explicit JWKS/HS256) in production, every AI request is `unauthorized` (fail closed). `/ready` returns `503`.

## Authentication

See [`docs/AI_AUTH.md`](./AI_AUTH.md) and [`docs/AUTH_PRODUCTION.md`](./AUTH_PRODUCTION.md).

Flutter client files already use Firebase project **`oracly-7f613`**. Anonymous Auth bootstrap obtains a Firebase ID token. The proxy verifies that token with Google JWKS.

Production proxy:

- requires `Authorization: Bearer <Firebase ID token>`
- verifies RS256 signature, `exp`, issuer `https://securetoken.google.com/oracly-7f613`, audience `oracly-7f613`
- rejects OpenAI keys used as user tokens
- ignores `userId` in the request body
- never logs tokens, Authorization, prompts, responses, dreams, or images

`AI_DEV_AUTH_BYPASS` is ignored in production/staging. `MockAuthService` is not an IdP.

## Rate limiting / limits (already enabled)

Verified JWT `sub` → hashed identity key. In-memory sliding window + per-identity concurrency cap.

**Single instance only.** Multi-instance production needs Redis or a platform rate-limit service. Do not claim distributed protection.

Also already enabled: Fastify `bodyLimit`, OpenAI timeout, coffee magic-byte + size checks, Helmet, no CORS `*`.

## HTTPS / reverse proxy

Fastify does not terminate TLS. The platform ingress must:

```
Flutter → HTTPS → production ingress / TLS terminator → Fastify → OpenAI
```

Expected Flutter URL format:

```
https://<real-production-host>/v1/ai/complete
```

Do not invent or hardcode a fake host. HTTPS does not exist until a real deployment exists.

## CORS

No CORS plugin. Native Flutter HTTP does not need browser CORS. Do not enable `Access-Control-Allow-Origin: *`. If a browser client is added later, allow explicit origins only.

## Coffee images

JPEG / PNG / WebP. Magic-byte check. 8 KB–12 MB. Not logged. Not stored. No arbitrary provider params from Flutter.

## Logging

Startup may log: env, host, port, authMode, authRequired, vision, model, `openaiConfigured` boolean.

Must not log: API keys, Authorization, access/refresh tokens, prompts, AI responses, dream text, coffee images.

Pino redacts `req.headers.authorization` and similar paths.

## Health / ready verification (after a real host exists)

Replace `<real-production-host>` with the deployed hostname. Do not run these against a placeholder.

```bash
curl -sS -o - -w "\n%{http_code}\n" https://<real-production-host>/health
# expect 200  {"status":"ok"}

curl -sS -o - -w "\n%{http_code}\n" https://<real-production-host>/ready
# expect 200  {"status":"ready"}
# 503 {"status":"not_ready"} means missing OPENAI_API_KEY or Firebase/JWKS verifier
```

Or from `backend/` (refuses localhost / LAN / http):

```bash
ORACLY_PROD_BASE_URL=https://<real-production-host> \
ORACLY_PROD_BEARER=<firebase-id-token> \
npm run smoke:prod
```

Authenticated smoke (real Firebase ID token only — never an OpenAI key):

```bash
curl -sS https://<real-production-host>/v1/ai/complete \
  -H "Authorization: Bearer <firebase-id-token>" \
  -H "Content-Type: application/json" \
  -d '{"operation":"chat","payload":{"userMessage":"Merhaba","priorUser":[]}}'
```

## Flutter release configuration

After the proxy has a real HTTPS host:

1. Copy `tool/dart_defines.production.example.json` → `tool/dart_defines.production.json` (gitignored).
2. Replace `REPLACE_WITH_PRODUCTION_HOST` with the real hostname.
3. Build:

```bash
flutter build apk --release \
  --dart-define-from-file=tool/dart_defines.production.json
```

Equivalent:

```bash
flutter build appbundle --release \
  --dart-define=APP_ENV=production \
  --dart-define=ORACLY_AI_PROXY_URL=https://<real-production-host>/v1/ai/complete
```

Public-only keys allowed in the dart-define file: `APP_ENV`, `ORACLY_AI_PROXY_URL`, `ORACLY_AI_MODEL`, `ORACLY_AI_VISION`, `ORACLY_AI_TIMEOUT_SECONDS`.

Must **not** pass `--dart-define=OPENAI_API_KEY=...`. Must **not** ship a client `.env` with that key.

Production / staging / release binaries reject `localhost`, `127.0.0.1`, private LAN IPs, and plain `http://` proxy URLs (fail closed as unconfigured).

## Provider-neutral checklist

1. Create server / container from `backend/Dockerfile`
2. Set `OPENAI_API_KEY` as a **platform secret**
3. Set `FIREBASE_PROJECT_ID=oracly-7f613` (public config)
4. Configure HTTPS at ingress
5. Keep a **single instance** unless a shared rate-limit store is added
6. Configure a real domain / hostname
7. Deploy backend
8. Verify `GET /health` and `GET /ready`
9. Verify authenticated `POST /v1/ai/complete` with a Firebase ID token
10. Configure Flutter `ORACLY_AI_PROXY_URL=https://<real-production-host>/v1/ai/complete`
11. Build Flutter release **without** `OPENAI_API_KEY`
12. Perform real E2E tests
13. Verify logs contain no secrets

This repository cannot perform steps 1–9. They need an external host and secrets.

## Device / LAN (local only)

1. PC LAN IPv4 (do not commit it)
2. Backend: `HOST=0.0.0.0`, `APP_ENV=development`, optional `AI_DEV_AUTH_BYPASS=true`
3. Flutter: `ORACLY_AI_PROXY_URL=http://<DEVELOPER-PC-LAN-IP>:8787/v1/ai/complete`
4. Windows Firewall: allow inbound TCP 8787 on Private. Do not disable the firewall.

`adb reverse tcp:8787 tcp:8787` + `http://127.0.0.1:8787/v1/ai/complete` avoids LAN bind.

## Classification

| | |
|---|---|
| CODE READY | Yes (fail-closed AI + billing + Firebase JWKS + Docker + limits) |
| DEPLOYMENT PREPARED | Yes (docs, image, env, health/ready, shutdown) |
| DEPLOYED (isolated, 0% traffic) | **Yes** — see `docs/RELEASE_LEDGER.md` R1/R2 |
| PROMOTED TO PRODUCTION TRAFFIC | **No** — production still serves the pre-R1 revision |
| STORE READY | **No** |

Isolated, non-traffic-serving Cloud Run release-candidate revisions have been deployed from
this repository (`docs/RELEASE_LEDGER.md`, sections "R1 production AI backend consolidation"
and "R2 controlled dependency remediation"); their revision tags, image digests, and
health/ready checks are recorded there. **Production traffic is still 100% on the older,
un-promoted revision** — no canary or traffic promotion has occurred, and no Flutter endpoint
was changed to point at a candidate.
**Next manual step:** complete Firebase/billing/legal console work, then perform the
separately authorized canary/traffic promotion described in `docs/RELEASE_LEDGER.md`'s
"Exact ordered release roadmap" before finalizing Flutter production runtime defines.
