# TappPlus — Next.js 14 + Prisma (SQLite) — Docker ready

## Démarrage local (sans Docker)
```bash
cp .env.example .env
npm i
npm run db:migrate:dev
npm run dev
```

## Build Docker
```bash
docker build -t tappplus:latest .
```

## Run Docker (image seule)
```bash
docker run --rm -p 3000:3000   -e DATABASE_URL=file:/data/dev.db   -v tappplus_data:/data   tappplus:latest
# http://localhost:3000
```

## Run avec docker-compose
```bash
docker compose up --build
```

Le conteneur exécute automatiquement `prisma migrate deploy` au démarrage et stocke la base SQLite dans **/data** (volume nommé `tappplus_data`).

### Endpoints
- UI: `/` et `/people`
- API: `/api/health`, `/api/people`

```bash
curl http://localhost:3000/api/health
curl -X POST http://localhost:3000/api/people -H "content-type: application/json" -d '{"firstName":"Ada","lastName":"Lovelace"}'
```
