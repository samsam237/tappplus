# 1. Architecture

## 1.1 Vue d’ensemble
- **Front + Back unifiés** : Next.js 14 (App Router)
- **API locales** : `app/api/**/route.ts`
- **Base de données** : SQLite via Prisma
- **Conteneurisation** : Docker multi-stage (builder / runner)
- **Stateless** côté app, **stateful** côté volume `/data` (fichier SQLite)

```
[Client] ⇄ [Next.js (Server Components, API routes)] ⇄ [Prisma] ⇄ [SQLite (/data/dev.db)]
```

## 1.2 Arborescence (résumé)
```
app/
  page.tsx
  people/page.tsx
  api/
    health/route.ts
    people/route.ts
prisma/
  schema.prisma
src/
  lib/prisma.ts
Dockerfile
docker-compose.yml
```

## 1.3 Flux clés
- Lecture/écriture patients via `prisma.person` dans Server Components et Routes API.
- Build Next au stade **builder**, exécution `next start` en **runner**.
- Migrations Prisma **au démarrage** du conteneur (`prisma migrate deploy`).
