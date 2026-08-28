# ORACLY AI proxy

Real production backend for Flutter AI:

`Flutter → POST /v1/ai/complete → this service → OpenAI`

This is **not** a mock. The OpenAI secret lives only here.

## Why Fastify + TypeScript

The Flutter repo had no backend. One small TypeScript Fastify service was chosen because it is production-capable, schema-friendly, easy to test with a mocked `fetch`, and simple to deploy. There is only this backend.

## Local run

```bash
cd backend
cp .env.example .env   # set OPENAI_API_KEY locally, never commit it
# Local Flutter without a real IdP: set AI_DEV_AUTH_BYPASS=true yourself
# (ignored in production). Never commit OPENAI_API_KEY.
npm install
npm test
npm run typecheck
npm run dev
```

Health: `GET http://127.0.0.1:8787/health`  
Ready: `GET http://127.0.0.1:8787/ready`  
AI: `POST http://127.0.0.1:8787/v1/ai/complete`

Production start: `npm run build && npm start` (honors platform `PORT`).  
Container (from repo root): `docker build -t oracly-ai-proxy ./backend` then run with `APP_ENV=production`, `FIREBASE_PROJECT_ID=oracly-7f613`, and `OPENAI_API_KEY` injected at runtime. See [`docs/AI_BACKEND_DEPLOYMENT.md`](../docs/AI_BACKEND_DEPLOYMENT.md).

Auth: [`docs/AUTH_PRODUCTION.md`](../docs/AUTH_PRODUCTION.md). Firebase project is `oracly-7f613` (Android + iOS client files). Set `FIREBASE_PROJECT_ID=oracly-7f613` in production. MockAuth is Flutter debug/test only.

Flutter local proxy:

```
APP_ENV=development
ORACLY_AI_PROXY_URL=http://127.0.0.1:8787/v1/ai/complete
```

Do not put `OPENAI_API_KEY` in the Flutter app for this path.

## Android device → this PC

Default bind is `127.0.0.1` (emulator / same machine only).

For a physical device on the same LAN, **explicitly** set in `backend/.env`:

```
HOST=0.0.0.0
```

Flutter (do not hardcode the IP in source):

```
APP_ENV=development
ORACLY_AI_PROXY_URL=http://<DEVELOPER-PC-LAN-IP>:8787/v1/ai/complete
```

Allow inbound TCP 8787 on the Windows Private firewall profile if needed. Do not disable the firewall. Do not expose this port publicly.

USB alternative: `adb reverse tcp:8787 tcp:8787` and keep Flutter on `http://127.0.0.1:8787/v1/ai/complete` (no `HOST=0.0.0.0`).

Production Flutter config is unchanged by this. Missing `ORACLY_AI_PROXY_URL` in production still fail-closes.

Full deployment notes: [`docs/AI_BACKEND_DEPLOYMENT.md`](../docs/AI_BACKEND_DEPLOYMENT.md).

**Initial production deploy: maximum ONE backend instance** until a shared rate-limit store exists.\n\n**Backend implementation is complete, but production deployment/readiness is still pending.**
