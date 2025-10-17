# 7. Sécurité

## 7.1 Surface d’attaque
- API publique sans auth (template)
- Form POST sur `/api/people`

## 7.2 Recommandations
- **Auth** : intégrer NextAuth (credentials/OAuth)
- **Validation** : Zod côté API
- **Ratelimit** : via reverse proxy (Nginx/Traefik) ou middleware
- **CORS** : restreindre domaines si SPA externe
- **Headers** : `X-Frame-Options`, `Content-Security-Policy` (via proxy)
- **Logs** : centraliser stdout Docker, ajouter traces d’erreur

## 7.3 RBAC & Multi-tenant (optionnel)
- `role` utilisateur (ADMIN/DOCTOR/…)
- `organizationId` sur entités + filtrage systématique
