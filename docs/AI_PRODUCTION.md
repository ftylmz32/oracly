# ORACLY — AI production integration

Canonical service: `OraclyAiService` in `lib/features/ai/production/`.

Used by AI Sohbet, OR'a Sor, Dream Analysis, and Coffee Reading.

```
Flutter → OraclyAiService → AiTransport
                              ├─ ProxyAiTransport          (production — required)
                              └─ DirectOpenAiTransport     (DEV only, explicit)
```

Screens never construct OpenAI HTTP and never read API keys.

Legacy unused `ChatScreen`, `AiService`, `MemoryExtractor`, `TarotAiService`,
and `TarotReadingScreen` were removed. They read `OPENAI_API_KEY` and called
OpenAI directly. They were not on the live navigation path.

## Fail-closed (production)

`APP_ENV=production` (also staging / `kReleaseMode`) **without**
`ORACLY_AI_PROXY_URL`:

- typed `AiFailure.noConfiguration` (Turkish: `ResilienceCopy.aiConfigMissing`)
- no local reflective responder
- no catalogue AI reply presented as live AI
- no mock AI
- no direct OpenAI (`api.openai.com` is not called)
- no silent provider downgrade
- stray `OPENAI_API_KEY` is ignored and never becomes `Authorization`

Development-only local responders exist (`CompanionResponder`,
`OracleConversationResponder`, `DreamReflectionGenerator`) and run **only**
when `OraclyAiService.allowsLocalFallback` is true (debug + `APP_ENV=development`
+ unconfigured). They are unreachable in production.

## DEV vs PRODUCTION

### DEVELOPMENT

- Proxy **may** be used (`ORACLY_AI_PROXY_URL`).
- Direct OpenAI **may** be used **only** when explicitly configured in debug
  (optional dotenv notes — never a real key in `.env.example` assets;
  never `--dart-define` on a store build). Prefer `backend/.env` + local proxy.
- Local test / catalogue responders may run only when explicitly marked
  (`allowsLocalFallback`) — unconfigured debug development.

### PRODUCTION

- Proxy **mandatory**: `ORACLY_AI_PROXY_URL=https://<real-production-host>/v1/ai/complete`
- No direct OpenAI from the device
- No local fake / reflective AI fallback
- No client-side OpenAI secret (`OPENAI_API_KEY` must not be in the Flutter build)

## Authoritative production checklist

### Production Flutter

```
APP_ENV=production
ORACLY_AI_PROXY_URL=https://<real-production-host>/v1/ai/complete
```

Must **NOT** contain:

```
OPENAI_API_KEY
```

### Production backend

```
OPENAI_API_KEY=<server environment secret>
OPENAI_MODEL=<server-selected model>
APP_ENV=production
```

Never commit or copy the actual secret automatically. Never put it in Flutter.

Until a HTTPS proxy is deployed, a real IdP is wired, the server secret is
injected, and this Flutter config is used on a real production build:

> **CODE READY ≠ DEPLOYMENT READY ≠ STORE READY.**

## Provider / model

Default live model hint: **OpenAI `gpt-4o`**.

Override with `ORACLY_AI_MODEL` (env or `--dart-define`). The backend may
ignore the hint and choose the server-side model.

## Configuration

### Development

| Variable | Use |
|---|---|
| `OPENAI_API_KEY` | Prefer `backend/.env` only. Flutter debug may read optional dotenv notes — never ship a real key in `.env.example`. Never a store build. |
| `ORACLY_AI_PROXY_URL` | Optional local/LAN proxy. |
| `ORACLY_AI_MODEL` | Optional, default `gpt-4o`. |
| `ORACLY_AI_TIMEOUT_SECONDS` | Optional, default `45` (clamped 15–90). |
| `ORACLY_AI_VISION` | Optional, default `true`. |

Direct OpenAI (`Flutter → OpenAI`) is an **explicit development fallback**.
`.env` / `.env.*` are gitignored. Only `.env.example` may be a Flutter asset
(comments/placeholders — no live secrets). Release never loads dotenv.

`OPENAI_API_KEY` is **not** read from `--dart-define`, so a production compile
cannot embed the secret that way.

### Production / staging / release

| Variable | Use |
|---|---|
| `ORACLY_AI_PROXY_URL` | **Required.** Full URL. |
| `ORACLY_AI_MODEL` | Optional hint. |
| `ORACLY_AI_TIMEOUT_SECONDS` | Optional. |
| `APP_ENV` | `production` or `staging`. |

Release binaries (`kReleaseMode`) also forbid client keys even if `APP_ENV`
was left as development.

When `ORACLY_AI_PROXY_URL` is set, **all** AI requests go through
`ProxyAiTransport`. A stray client key is never sent.

## Modes (honest)

| State | Meaning |
|---|---|
| Proxy configured | Real live AI via backend. |
| DEV client key, no proxy | Local testing only. |
| Unconfigured (production) | Typed `noConfiguration` / coffee unavailable. |
| Unconfigured (dev debug) | Local catalogue / reflective responder only. |

## Fallback audit

| Occurrence | Class | Notes |
|---|---|---|
| `CompanionResponder` via `CompanionExperienceService` | B development-only | Gated by `allowsLocalFallback`. |
| `OracleConversationResponder` via `OracleAiMessageSource` | B development-only | Same gate. |
| `DreamReflectionGenerator` via `DreamExperienceService` | B development-only | Same gate. |
| `DirectOpenAiTransport` / `OpenAiTransport` → `api.openai.com` | B development-only | `usesClientKey` only. |
| `EnvApiKeyProvider.openAiKey` / dotenv `OPENAI_API_KEY` | B development-only | Ignored in production resolve. |
| `UnconfiguredOraclyAiService` | A production-reachable | Typed `noConfiguration` only — not a fake AI. |
| `UnavailableCoffeeAnalysis` | A production-reachable | Typed unavailable — not fake vision. |
| `MockOpenAIService` / `MockAIRepository` / `MockAIResponses` | E dead/unused | Legacy OR-1110; not on live navigation. |
| `LocalInterpretationExecutor` / `ReflectiveIntelligence` | B product (not GPT) | Tarot local interpretation + tone. Not a live-AI fallback. |
| Backend `OPENAI_API_KEY` / `api.openai.com` | A server-only | Must stay off the device. |
| Docs / tests mentioning keys or OpenAI URLs | C / D | Tests and documentation only. |

## Device / LAN testing (Android → developer PC)

Do **not** hardcode a LAN IP in source. Do **not** change production config.

Flutter `.env` or `--dart-define` (development):

```
APP_ENV=development
ORACLY_AI_PROXY_URL=http://<DEVELOPER-PC-LAN-IP>:8787/v1/ai/complete
```

Backend (explicit opt-in, not the default):

```
HOST=0.0.0.0
PORT=8787
```

Default backend bind is `127.0.0.1` (emulator / same machine only).

See [`docs/AI_BACKEND_DEPLOYMENT.md`](./AI_BACKEND_DEPLOYMENT.md) § Device / LAN.

## Backend

Real proxy code lives in `/backend` (TypeScript + Fastify).

Contract: [`docs/AI_PROXY_CONTRACT.md`](./AI_PROXY_CONTRACT.md).  
Deploy: [`docs/AI_BACKEND_DEPLOYMENT.md`](./AI_BACKEND_DEPLOYMENT.md).

Until the proxy is deployed, authenticated against a real IdP, and given a
server-side `OPENAI_API_KEY`:

> Backend implementation is complete, but production deployment/readiness
> is still pending.

## Authentication / rate limits

Flutter auth: `AuthService` → Firebase when initialized, MockAuth in
development only. Canonical docs: [`docs/AUTH_PRODUCTION.md`](./AUTH_PRODUCTION.md),
[`docs/AI_AUTH.md`](./AI_AUTH.md). Android and iOS client config is present (`oracly-7f613`); production deploy is not.

The AI proxy uses `AuthenticationService`, not MockAuth. Production/staging
require JWKS or HS256 verification and ignore `AI_DEV_AUTH_BYPASS`. Without a
verifier, production AI requests fail closed (`unauthorized`).

Rate limits use the verified JWT `sub` (hashed). In-memory, single instance.
Multi-instance production needs a shared limiter. `AiRequestGuard` only
prevents duplicate taps.

## Coffee images

Client validates MIME (`jpeg` / `png` / `webp`) and size (8 KB–12 MB).
Backend enforces the same plus magic-byte checks. Images are not logged and
not stored. Vision off → typed `imageAnalysisUnavailable`. Flutter cannot
send arbitrary OpenAI vision parameters.

## Privacy / logging

Debug logs may include operation, latency, status, and proxy vs direct.
Never keys, Authorization headers, full prompts, full responses, or images.

## Timeouts / retry

Default timeout **45s**. No automatic multi-retry. UI offers one retry.
Duplicate taps share the in-flight request (`AiRequestGuard`).

## Behaviour

- **AI Sohbet / OR'a Sor:** live `OraclyAiService` when configured;
  production unconfigured → typed unavailable; development unconfigured →
  local reflective responder. Context kinds do not leak.
- **Dream:** live structured analysis when configured; production
  unconfigured → typed `noConfiguration`; development unconfigured → local
  catalogue; typed error if a live call fails.
- **Coffee:** real vision when configured + vision enabled; explicit
  unavailable otherwise. Visual detection is separate from symbolism.
