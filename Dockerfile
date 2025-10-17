# --- Builder ---
FROM node:20-alpine AS builder
WORKDIR /app
ENV NEXT_TELEMETRY_DISABLED=1

# Certificats + openssl (utile pour Prisma) + git pour certaines deps
RUN apk add --no-cache ca-certificates openssl git

# Copie des manifests + Prisma avant install (évite les erreurs prisma)
COPY package.json package-lock.json* pnpm-lock.yaml* yarn.lock* ./
COPY prisma ./prisma

# Réglages npm plus tolérants aux réseaux instables
ENV npm_config_loglevel=notice \
    npm_config_fetch_retries=5 \
    npm_config_fetch_retry_maxtimeout=600000 \
    npm_config_fetch_retry_mintimeout=20000 \
    npm_config_legacy_peer_deps=true

# BuildKit cache pour npm (accélère et évite de retélécharger)
# Activer BuildKit: DOCKER_BUILDKIT=1 docker build ...
RUN --mount=type=cache,target=/root/.npm \
    if [ -f pnpm-lock.yaml ]; then corepack enable && pnpm i --frozen-lockfile; \
    elif [ -f yarn.lock ]; then yarn install --frozen-lockfile; \
    elif [ -f package-lock.json ]; then npm ci --no-audit --no-fund; \
    else npm i --no-audit --no-fund; fi

# Copie du reste + Prisma + Build Next
COPY . .
RUN npx prisma generate
RUN npm run build

# --- Runner (inchangé) ---
FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV DATABASE_URL="file:/data/dev.db"
ENV PORT=3000
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/prisma ./prisma
RUN mkdir -p /data
VOLUME ["/data"]
CMD ["/bin/sh", "-c", "npx prisma migrate deploy && node node_modules/next/dist/bin/next start -p ${PORT}"]
EXPOSE 3000
