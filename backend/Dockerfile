# ORACLY AI proxy — multi-stage production image.
# Secrets are injected at runtime (Secret Manager / env). Never COPY .env.

# ---- build ----
FROM node:22-alpine@sha256:c610fcdfb1d5b4740dd70c284ed3cb16bb857e0f7166196e36a5501df7a3aa32 AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY tsconfig.json tsconfig.prod.json ./
COPY src ./src
RUN npm run build:prod \
  && npm prune --omit=dev

# ---- runtime ----
FROM node:22-alpine@sha256:c610fcdfb1d5b4740dd70c284ed3cb16bb857e0f7166196e36a5501df7a3aa32 AS runtime
WORKDIR /app
ENV NODE_ENV=production \
    APP_ENV=production \
    HOST=0.0.0.0 \
    PORT=8080

RUN addgroup -S oracly && adduser -S oracly -G oracly

COPY package.json package-lock.json ./
RUN npm ci --omit=dev && chown -R oracly:oracly /app

COPY --from=build --chown=oracly:oracly /app/dist ./dist

USER oracly
EXPOSE 8080

# Liveness only — readiness (/ready) needs secrets and is checked by Cloud Run startup separately.
HEALTHCHECK --interval=30s --timeout=3s --start-period=15s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:'+(process.env.PORT||8080)+'/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

CMD ["node", "dist/index.js"]
