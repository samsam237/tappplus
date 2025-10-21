# ===================================
# UNIFIED DOCKERFILE - TappPlus
# API + Web + Worker + Redis in one container
# ===================================

# ===================================
# Stage 1: Base image with dependencies
# ===================================
FROM node:18-slim AS base

# Install required system dependencies
RUN apt-get update && apt-get install -y \
    openssl \
    ca-certificates \
    redis-server \
    sqlite3 \
    nginx \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# ===================================
# Stage 2: Install workspace dependencies
# ===================================
FROM base AS dependencies

# Copy workspace configuration
COPY package.json package-lock.json* turbo.json ./
COPY apps/api/package.json ./apps/api/
COPY apps/web/package.json ./apps/web/

# Install all dependencies with retry logic and increased timeout
RUN npm config set fetch-retry-mintimeout 20000 && \
    npm config set fetch-retry-maxtimeout 120000 && \
    npm config set fetch-timeout 300000 && \
    npm ci --prefer-offline --no-audit

# ===================================
# Stage 3: Build API
# ===================================
FROM dependencies AS build-api

# Copy API source
COPY apps/api ./apps/api

# Generate Prisma client
WORKDIR /app/apps/api
RUN npx prisma generate

# Build API
RUN npm run build

# Verify build
RUN ls -la dist/ && echo "✓ API build successful"

# ===================================
# Stage 4: Build Web
# ===================================
FROM dependencies AS build-web

# Copy Web source
COPY apps/web ./apps/web

WORKDIR /app/apps/web

# Build Next.js application
RUN npm run build

# Verify build
RUN ls -la .next/ && echo "✓ Web build successful"

# ===================================
# Stage 5: Production Runtime
# ===================================
FROM base AS runtime

# Install PM2 globally for process management
RUN npm install -g pm2

WORKDIR /app

# Create data, logs, and nginx directories
RUN mkdir -p /app/data /app/logs /etc/nginx/sites-enabled && chmod 777 /app/data /app/logs

# Copy built API
COPY --from=build-api /app/apps/api/dist ./apps/api/dist
COPY --from=build-api /app/apps/api/prisma ./apps/api/prisma
COPY --from=build-api /app/apps/api/package.json ./apps/api/
COPY --from=build-api /app/node_modules ./node_modules

# Copy built Web (standalone output)
COPY --from=build-web /app/apps/web/.next/standalone ./apps/web
COPY --from=build-web /app/apps/web/.next/static ./apps/web/.next/static
COPY --from=build-web /app/apps/web/public ./apps/web/public

# Copy PM2 ecosystem config
COPY ecosystem.config.js ./

# Copy root package.json
COPY package.json ./

# Copy scripts directory
COPY scripts ./scripts
RUN chmod +x ./scripts/*.js

# Copy Nginx configuration
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/tappplus.conf /etc/nginx/sites-enabled/tappplus.conf

# Expose only port 80 (Nginx reverse proxy)
EXPOSE 80

# Health check via Nginx
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD curl -f http://localhost/health || exit 1

# Set environment
ENV NODE_ENV=production
ENV DATABASE_URL=file:/app/data/meditache.db
ENV REDIS_URL=redis://127.0.0.1:6379

# Start all processes with PM2
CMD ["pm2-runtime", "start", "ecosystem.config.js"]
