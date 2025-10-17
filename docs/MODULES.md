# 4. Modules & Services

## 4.1 UI
- `app/page.tsx` : accueil
- `app/people/page.tsx` : liste/ajout simple des patients (Server Component)

## 4.2 API
- `app/api/health/route.ts` : healthcheck
- `app/api/people/route.ts` : GET/POST patients (form-data & JSON)

## 4.3 Data Access Layer
- `src/lib/prisma.ts` : singleton Prisma Client

## 4.4 Schéma actuel
- Entité **Person** : `id, firstName, lastName, createdAt`

## 4.5 Extensions prévues (exemple)
- `Organization`, `User/Doctor`, `Intervention`, `Reminder`, `NotificationLog`, `AuditLog`
- Guards/ACL applicatives si multi-tenant
