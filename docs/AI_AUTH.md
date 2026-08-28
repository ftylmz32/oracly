# ORACLY AI authentication architecture

**Status: Android and iOS Firebase client config is present (`oracly-7f613`). Production deploy is not.**

This is not live production authentication. See [`docs/AUTH_PRODUCTION.md`](./AUTH_PRODUCTION.md).

Flutter uses `AuthService` → `FirebaseAuthService` when Firebase initializes, otherwise
`MockAuthService` (dev) or `UnconfiguredAuthService` (production/release).

```
Flutter TokenManager (real access token, when one exists)
  → Authorization: Bearer <token>
  → Fastify AuthenticationService
  → verified subject
  → rate limit / AI proxy
```

## What currently exists

| Piece | Status |
|---|---|
| Flutter `AuthService` | Interface only |
| Flutter `MockAuthService` | Dev/test only. Forbidden in release. |
| Flutter `TokenManager` / `SecureTokenManager` | Stores tokens if a real login ever saves them |
| Flutter `SessionManager` | In-memory session + token persistence |
| Flutter `AuthInterceptor` / `ProxyAiTransport` | Sends Bearer only when `TokenManager` has a token. Production never sends `mock_*` or `sk-` tokens |
| Backend `AuthenticationService` | Abstraction used by `/v1/ai/complete` |
| Backend HS256 JWT | Implemented (`AI_JWT_SECRET` + optional issuer/audience) |
| Backend JWKS (RS256/ES256) | Implemented (`AI_JWKS_URL` + optional issuer/audience) |
| Firebase Authentication adapter | Code ready. Android + iOS native client files present (`oracly-7f613`). |
| Account / user backend | **None** |

Do not treat `MockAuthService` as a production identity provider.

## Backend `AuthenticationService`

```
authenticate(Authorization header)
  → AuthenticatedIdentity { subject, identityKey }
  or typed unauthorized
```

The AI route depends on this abstraction, not on `MockAuthService`.

Modes:

| `authMode` | When | Identity |
|---|---|---|
| `bypass` | `APP_ENV=development` + `AI_DEV_AUTH_BYPASS=true` | Hashed request IP. Dev only |
| `opaque` | Development, auth required, no JWT/JWKS | Hashed Bearer token. Dev only. Not verified |
| `hs256` | `AI_JWT_SECRET` set | JWT `sub` after HS256 + exp (+ iss/aud if configured) |
| `jwks` | `AI_JWKS_URL` set | JWT `sub` after JWKS RS256/ES256 + exp (+ iss/aud) |
| `fail_closed` | production/staging without JWT/JWKS | Every request unauthorized |

Production and staging:

- ignore `AI_DEV_AUTH_BYPASS`
- never use opaque bearer
- never use MockAuth tokens
- never trust `userId` / `user_id` / `sub` in the JSON body

## What a future identity provider must provide

ORACLY does not invent an IdP. When one is chosen, it must issue user access tokens that the proxy can verify:

1. `Authorization: Bearer <access_token>`
2. JWT with `sub` (stable user id) and `exp`
3. Either:
   - **JWKS (preferred):** `AI_JWKS_URL=https://<idp>/.well-known/jwks.json` plus `AI_JWT_ISSUER` and `AI_JWT_AUDIENCE`, or
   - **HS256:** `AI_JWT_SECRET` shared with the issuer (only if the IdP actually signs HS256)
4. Flutter must store that access token in `TokenManager` after real sign-in — replacing `MockAuthService`

Rejected automatically:

- missing / malformed Bearer
- expired JWT
- invalid signature
- wrong issuer / audience (when configured)
- tokens starting with `sk-` (OpenAI keys)
- `alg: none`
- client-supplied user ids in the body

Verification failures return only:

```json
{ "success": false, "error": { "code": "unauthorized" } }
```

No JWT internals, issuer details, or stack traces.

## Rate limiting identity

After successful verification, rate limit and concurrency keys are:

`sub:<sha256(sub)[0..24]>`

Not the raw Authorization header. Not a body `userId`. Not IP (except development bypass).

The limiter is **in-memory, single instance**. Multi-instance production needs Redis or an equivalent shared store.

## Flutter

`authServiceProvider` selects Firebase when initialized, MockAuth in development only, and fail-closed unconfigured auth in production without Firebase.

`ProxyAiTransport` will not send `mock_*` or `sk-` tokens when `APP_ENV` is production/staging or the binary is release.
