# ORACLY AI proxy contract

**Status: Backend implemented in `/backend`. Not deployed. Production readiness pending.**

The Flutter client calls this contract. OpenAI lives only on the server.

```
Production (required):
  Flutter → ORACLY backend proxy → OpenAI
  Missing ORACLY_AI_PROXY_URL → typed noConfiguration (fail closed).
  No local responder, no direct OpenAI, no client OPENAI_API_KEY.

Development (explicit only):
  Flutter → proxy   (ORACLY_AI_PROXY_URL, including LAN device testing)
  Flutter → OpenAI  (OPENAI_API_KEY only via optional debug dotenv notes /
                     never store builds; preferred: backend/.env + local proxy)
  Local catalogue responders only when unconfigured + debug development.

Flutter boot loads `.env.example` only in non-release (optional). Release uses
`--dart-define` for APP_ENV / ORACLY_AI_PROXY_URL. Real OpenAI keys live in
`backend/.env` (gitignored), never in Flutter assets.
```

The OpenAI secret must exist **only** on the server. Never in Dart source,
widgets, providers, repositories, git-tracked config, Flutter assets, or
`--dart-define` on a production mobile build.

## Endpoint

Configure the Flutter client with the full URL:

```
ORACLY_AI_PROXY_URL=https://api.oracly.app/v1/ai/complete
```

Method: `POST`  
Content-Type: `application/json`  
Optional: `Authorization: Bearer <user access token>` when the app has a
**real** stored token. Do not invent tokens. Today ORACLY auth is mock-only
(`MockAuthService`); the proxy **must** still be authenticated and/or
rate-limited before store release.

Suggested path matches the unused Flutter registry `ApiEndpoints.aiComplete`.

## Request

```json
{
  "operation": "chat | oracle | dream_analysis | coffee_analysis | palm_analysis | soulmate_draw | tts",
  "model": "gpt-4o",
  "payload": {}
}
```

`model` is a hint. The backend chooses the provider model and builds prompts.
Do not expect the client to send OpenAI `messages`.

### `chat`

```json
{
  "operation": "chat",
  "model": "gpt-4o",
  "payload": {
    "userMessage": "…",
    "priorUser": ["…"]
  }
}
```

### `oracle` (OR'a Sor)

```json
{
  "operation": "oracle",
  "payload": {
    "userMessage": "…",
    "priorUser": ["…"],
    "context": {
      "kind": "tarot | dream | astrology | birthChart | coffee | palm",
      "…structured fields only…"
    }
  }
}
```

Kinds must not be mixed. Context is typed JSON, not a concatenated UI blob.

### `dream_analysis`

```json
{
  "operation": "dream_analysis",
  "payload": {
    "narrative": "…",
    "symbols": ["…"],
    "emotions": ["…"]
  }
}
```

### `coffee_analysis`

```json
{
  "operation": "coffee_analysis",
  "payload": {
    "mimeType": "image/jpeg | image/png | image/webp",
    "imageBase64": "…",
    "byteLength": 12345
  }
}
```

Image limits (client + required on server):

| Rule | Value |
|---|---|
| Allowed MIME | `image/jpeg`, `image/jpg`, `image/png`, `image/webp` |
| Min size | 8 KB |
| Max size | 12 MB |

Do **not** log coffee images. Do **not** permanently store them unless the
product later requires it.

## Response

Success:

```json
{
  "success": true,
  "data": {}
}
```

Failure:

```json
{
  "success": false,
  "error": {
    "code": "rate_limit",
    "message": "optional internal note — never shown in the app"
  }
}
```

The Flutter client maps `error.code` (and HTTP status) to typed `AiFailure`.
User-facing copy is always Turkish `AiFailure` text. Never display raw
backend/OpenAI bodies, keys, headers, or stack traces.

### Success `data` by operation

**chat / oracle**

```json
{ "text": "…" }
```

Minimum ~12 characters of real text. No fabricated filler.

**dream_analysis**

```json
{
  "summary": "…",
  "symbols": ["…"],
  "emotionalTheme": "…",
  "interpretation": "…",
  "dailyLifeReflection": "…",
  "conclusion": "…"
}
```

Only symbols present in the dream text. No invented symbols. No fake analysis
if the provider is unavailable.

**coffee_analysis**

```json
{
  "visualObservation": "…",
  "overall": "…",
  "love": "…",
  "career": "…",
  "money": "…",
  "nearFuture": "…",
  "takeaway": "…",
  "symbols": [
    {
      "name": "…",
      "meaning": "…",
      "interpretation": "…",
      "focus": { "x": 0.2, "y": 0.3, "w": 0.18, "h": 0.16 }
    }
  ]
}
```

`visualObservation` = detected marks only. `symbols` = only what vision
actually identified. Never claim a symbol that was not seen. Optional
`focus` / `bbox` (normalized 0–1) is spatial grounding for UI markers —
pass through only when reliable; never invent coordinates. If vision is
unavailable, return code `vision_unavailable` / `image_analysis_unavailable`.

### `tts`

Server-side speech for OR replies. Flutter sends **text + personality +
language + `voiceId` + `speechSpeed`**. Never send OpenAI voices, models,
or keys from the client. `voiceId` is OR identity only:

`warm | calm | deep | bright`

`speechSpeed` is tempo only (default `normal`):

`slow | normal | fast`

Fast stays within a natural band (provider speed ≤ ~1.15) so speech remains
intelligible. Legacy voice values map: `female_natural`→`warm`,
`male_calm`→`calm`, `male_natural`→`deep`, `female_soft`→`bright`. Unknown
values fall back to `warm` / `normal`.

```json
{
  "operation": "tts",
  "payload": {
    "text": "…",
    "personality": "gentle | mystical | poetic | direct",
    "voiceId": "warm | calm | deep | bright",
    "speechSpeed": "slow | normal | fast",
    "language": "tr | en"
  }
}
```

SAKİN → `gentle`, MİSTİK → `mystical`, SAMİMİ → `poetic`, DİREKT → `direct`.

Minimum 1 character (`selam` is valid). Maximum 1200 characters.

Success `data`:

```json
{
  "audioBase64": "…",
  "mimeType": "audio/mpeg",
  "operation": "tts"
}
```

Do **not** synthesize silent or fake audio. If the speech provider is missing
or returns unusable bytes, fail with a typed error — the app shows an honest
unavailable note and keeps the written reply.

Do **not** log `audioBase64`.

### Error codes → `AiFailure`

| Backend `error.code` or HTTP | `AiFailure` |
|---|---|
| `no_configuration`, `unauthorized`, `forbidden`, 401, 403 | `noConfiguration` |
| `network` | `network` |
| `timeout`, 408 | `timeout` |
| `rate_limit`, `rate_limited`, 429 | `rateLimit` |
| `invalid_response`, `invalid_request`, `validation_error` | `invalidResponse` |
| `vision_unavailable`, `image_unavailable`, `image_analysis_unavailable` | `imageAnalysisUnavailable` |
| `provider_error`, 5xx, unknown | `providerError` |

## Authentication

Flutter auth is still mock (`MockAuthService`). See [`docs/AI_AUTH.md`](./AI_AUTH.md).

The proxy authenticates via `AuthenticationService`:

- Production/staging: JWKS or HS256 JWT required. Bypass ignored. Fail closed if unconfigured.
- Development: optional `AI_DEV_AUTH_BYPASS=true`, or opaque Bearer for local mock tokens.
- Rejects OpenAI `sk-` tokens, expired/invalid JWTs, and body `userId` spoofing.

This is **not** production-ready identity. A real IdP still needs to issue
tokens and Flutter must store them in `TokenManager`.

When a real access token exists in `TokenManager`, Flutter sends
`Authorization: Bearer <token>`. It never sends `OPENAI_API_KEY`.

## Rate limiting & abuse (backend)

Implemented in-process (per hashed token / IP, concurrency cap, body/image
limits, OpenAI timeout). **Single instance only** — not distributed.

Do not rely on Flutter `AiRequestGuard` for security.

## Privacy / logging

Log only:

- operation type
- duration
- success / failure category
- non-sensitive error code

Never log:

- API keys
- Authorization headers
- complete prompts or AI responses
- coffee images / base64
- TTS `audioBase64`

Dreams, chat, and reading contexts can contain personal information.

## Deployment checklist (store release)

1. Deploy `/backend` with `OPENAI_API_KEY` only as a server secret.
2. Ship Flutter with `APP_ENV=production` and `ORACLY_AI_PROXY_URL=https://<real-production-host>/v1/ai/complete`.
3. Flutter must **not** contain `OPENAI_API_KEY`. Do **not** pass it via `--dart-define`.
4. Wire a real IdP and JWKS/HS256. `MockAuthService` is not production auth. Dev bypass must stay off.
5. Add a shared rate-limit store if running more than one instance.
6. Confirm production builds fail closed if the proxy URL is missing.

See [`docs/AI_BACKEND_DEPLOYMENT.md`](./AI_BACKEND_DEPLOYMENT.md).
