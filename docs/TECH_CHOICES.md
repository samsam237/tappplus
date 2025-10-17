# 2. Choix techniques

## 2.1 Next.js 14 — App Router
- **Server Components** par défaut (moins de JS côté client)
- **Layouts imbriqués**, **streaming**, **data fetching** sur serveur
- **API routes** co-localisées avec l’UI

## 2.2 Base de données — SQLite + Prisma
- **SQLite** : simple, léger, parfait pour mono-nœud et PoC/PMV
- **Prisma** : migrations, client typé, DX excellente

> Évolution possible : Postgres/MySQL en changeant `datasource db` dans `schema.prisma` + URL et migrations.

## 2.3 Docker
- **Multi-stage build** : image finale minimale
- **Volume** `/data` pour persister la base
- `CMD` exécute **migrations** + `next start`

## 2.4 Simplicité > complexité
- Pas d’auth par défaut (facile à ajouter : NextAuth)
- UI minimale (peut accueillir Tailwind/Design System)
