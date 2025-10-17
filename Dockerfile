# --- Builder ---
FROM node:20-alpine AS builder
WORKDIR /app
ENV NEXT_TELEMETRY_DISABLED=1

RUN apk add --no-cache ca-certificates openssl dos2unix git

COPY package.json package-lock.json* pnpm-lock.yaml* yarn.lock* ./
COPY prisma ./prisma

# Install (avec cache si BuildKit)
ENV npm_config_fetch_retries=5 \
npm_config_fetch_retry_maxtimeout=600000 \
npm_config_fetch_retry_mintimeout=20000 \
npm_config_legacy_peer_deps=true
RUN --mount=type=cache,target=/root/.npm \
if [ -f pnpm-lock.yaml ]; then corepack enable && pnpm i --frozen-lockfile; \
elif [ -f yarn.lock ]; then yarn install --frozen-lockfile; \
elif [ -f package-lock.json ]; then npm ci --no-audit --no-fund; \
else npm i --no-audit --no-fund; fi

COPY . .

# (Optionnel) forcer un schema sain
# RUN mkdir -p prisma && cat > prisma/schema.prisma <<'PRISMA'
# ... (ton schema) ...
# PRISMA
RUN dos2unix prisma/schema.prisma || true
RUN echo "==== schema.prisma ====" && nl -ba prisma/schema.prisma | sed -n '1,50p'

# 🔑 Donner un DATABASE_URL au builder (spécifique build)
ENV DATABASE_URL="file:./dev.db"

# Valider & générer Prisma
RUN npx prisma validate
RUN npx prisma generate

# Build Next
RUN npm run build

# --- Runner ---
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
