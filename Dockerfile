# --- Builder ---
FROM node:20-alpine AS builder
WORKDIR /app
ENV NEXT_TELEMETRY_DISABLED=1

# Outils utiles (certifs, openssl pour Prisma, dos2unix pour normaliser, git si besoin)
RUN apk add --no-cache ca-certificates openssl dos2unix git

# 1) Copie des manifests + (éventuel) dossier prisma
COPY package.json package-lock.json* pnpm-lock.yaml* yarn.lock* ./
COPY prisma ./prisma

# 2) Réglages npm un peu plus tolérants (réseau)
ENV npm_config_fetch_retries=5 \
    npm_config_fetch_retry_maxtimeout=600000 \
    npm_config_fetch_retry_mintimeout=20000 \
    npm_config_legacy_peer_deps=true

# 3) Install (avec cache si BuildKit actif)
#    Lance le build avec: DOCKER_BUILDKIT=1 docker build --progress=plain ...
RUN --mount=type=cache,target=/root/.npm \
    if [ -f pnpm-lock.yaml ]; then corepack enable && pnpm i --frozen-lockfile; \
    elif [ -f yarn.lock ]; then yarn install --frozen-lockfile; \
    elif [ -f package-lock.json ]; then npm ci --no-audit --no-fund; \
    else npm i --no-audit --no-fund; fi

# 4) Copie du reste du code
COPY . .

# 5) ECRASE ET RÉÉCRIT un schema.prisma SAIN (UTF-8, LF, quotes droits)
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

# 6) Normalisation & affichage pour contrôle
RUN dos2unix prisma/schema.prisma || true
RUN echo "==== schema.prisma (head) ====" && nl -ba prisma/schema.prisma | sed -n '1,40p'

# 7) Donner un DATABASE_URL au BUILDER (juste pour validate/generate)
ENV DATABASE_URL="file:./dev.db"

# 8) Valider puis générer Prisma
RUN npx prisma validate
RUN npx prisma generate

# 9) Build Next.js
RUN npm run build

# --- Runner ---
FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
# Valeur finale en prod: base dans le volume /data
ENV DATABASE_URL="file:/data/dev.db"
ENV PORT=3000

# Artifacts
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/prisma ./prisma

# Volume data SQLite
RUN mkdir -p /data
VOLUME ["/data"]

# Migrations au démarrage puis Next
CMD ["/bin/sh", "-c", "npx prisma migrate deploy && node node_modules/next/dist/bin/next start -p ${PORT}"]
EXPOSE 3000
