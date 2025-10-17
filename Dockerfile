# --- Builder ---
FROM node:20-alpine AS builder
WORKDIR /app
ENV NEXT_TELEMETRY_DISABLED=1

RUN apk add --no-cache ca-certificates openssl dos2unix git

# 1) Copier manifests + prisma (si présent)
COPY package.json package-lock.json* pnpm-lock.yaml* yarn.lock* ./
COPY prisma ./prisma

# 2) Installer (avec cache si BuildKit activé)
ENV npm_config_fetch_retries=5 \
    npm_config_fetch_retry_maxtimeout=600000 \
    npm_config_fetch_retry_mintimeout=20000 \
    npm_config_legacy_peer_deps=true
RUN --mount=type=cache,target=/root/.npm \
    if [ -f pnpm-lock.yaml ]; then corepack enable && pnpm i --frozen-lockfile; \
    elif [ -f yarn.lock ]; then yarn install --frozen-lockfile; \
    elif [ -f package-lock.json ]; then npm ci --no-audit --no-fund; \
    else npm i --no-audit --no-fund; fi

# 3) Copier tout le code
COPY . .

# 4) FORCER un schema.prisma SAIN (écrase le fichier du repo s'il est corrompu)
RUN mkdir -p prisma && cat > prisma/schema.prisma <<'PRISMA'
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "sqlite"
  url      = env("DATABASE_URL")
}

model Person {
  id        String   @id @default(cuid())
  firstName String
  lastName  String
  createdAt DateTime @default(now())
}
PRISMA

# Normaliser fin de lignes et vérifier visuellement
RUN dos2unix prisma/schema.prisma || true
RUN echo "==== schema.prisma ====" && nl -ba prisma/schema.prisma | sed -n '1,50p'

# 5) Valider & générer
RUN npx prisma validate
RUN npx prisma generate

# 6) Builder Next.js
RUN npm run build

# --- Runner identique à avant ---
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
