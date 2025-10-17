# 5. Modèle de données (Prisma)

## 5.1 Schéma actuel
```prisma
model Person {
  id        String   @id @default(cuid())
  firstName String
  lastName  String
  createdAt DateTime @default(now())
}
```

## 5.2 Relations (évolutions possibles)
- `Person` ←→ `Intervention` (1–N)
- `User` (Doctor) ←→ `Intervention` (1–N)
- `Organization` ←→ `Person`/`User`/`Intervention` (multi-tenant)
- `Reminder` lié à `Intervention`, `ReminderRule`
- `NotificationLog` pour tracer les envois

## 5.3 Migration vers Postgres (option)
- Changer `datasource db` et `DATABASE_URL`
- Lancer `prisma migrate dev`
