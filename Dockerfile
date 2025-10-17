# --- Builder ---
FROM node:20-alpine AS builder
WORKDIR /app
ENV NEXT_TELEMETRY_DISABLED=1

# 1) Copier les manifests + le schéma Prisma AVANT l'installation
COPY package.json package-lock.json* pnpm-lock.yaml* yarn.lock* ./
COPY prisma ./prisma

# (Optionnel) Évite l'avertissement Prisma sur OpenSSL
RUN apk add --no-cache openssl

# 2) Installer les dépendances
RUN if [ -f pnpm-lock.yaml ]; then corepack enable && pnpm i --frozen-lockfile; \
    elif [ -f yarn.lock ]; then yarn --frozen-lockfile; \
    elif [ -f package-lock.json ]; then npm ci; \
    else npm i; fi

# 3) Copier le reste du code et générer Prisma explicitement
COPY . .
RUN npx prisma generate

# 4) Builder Next.js
RUN npm run build

# --- Runner ---
FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV DATABASE_URL="file:/data/dev.db"
ENV PORT=3000

# Artifacts runtime
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/prisma ./prisma

# Volume pour SQLite
RUN mkdir -p /data
VOLUME ["/data"]

# Migrations au démarrage puis serveur Next
CMD ["/bin/sh", "-c", "npx prisma migrate deploy && node node_modules/next/dist/bin/next start -p ${PORT}"]

EXPOSE 3000
    