# Guide de Configuration TappPlus

Configuration détaillée de toutes les variables d'environnement et services.

## 📖 Table des matières

1. [Variables d'environnement](#variables-denvironnement)
2. [Configuration JWT](#configuration-jwt)
3. [Configuration base de données](#configuration-base-de-données)
4. [Configuration Redis](#configuration-redis)
5. [Configuration notifications](#configuration-notifications)
6. [Configuration CORS et sécurité](#configuration-cors-et-sécurité)
7. [Configuration frontend](#configuration-frontend)

---

## Variables d'environnement

Toutes les variables sont définies dans le fichier `.env` à la racine du projet.

### Variables obligatoires

```bash
# Environnement
NODE_ENV=production              # development | staging | production

# JWT Secrets (⚠️ À CHANGER OBLIGATOIREMENT)
JWT_SECRET=<32+ caractères>
JWT_REFRESH_SECRET=<32+ caractères>

# Base de données
DATABASE_URL=file:/app/data/meditache.db

# Redis
REDIS_URL=redis://127.0.0.1:6379
```

### Variables optionnelles

```bash
# Ports (ne pas changer en production)
API_PORT=5550
WEB_PORT=5500
HTTP_PORT=80

# Timezone
TZ=Africa/Douala                 # Format IANA timezone

# Frontend
NEXT_PUBLIC_API_URL=             # Vide = URLs relatives

# CORS
CORS_ORIGINS=                    # Vide = toutes origines acceptées

# Images
IMAGE_DOMAINS=                   # Domaines autorisés pour images

# Logs
LOG_LEVEL=info                   # error | warn | info | debug
```

---

## Configuration JWT

### Génération des secrets

```bash
# Générer un secret sécurisé (32+ caractères)
openssl rand -base64 32
```

### Durée de vie des tokens

Par défaut :
- **Access Token** : 15 minutes
- **Refresh Token** : 7 jours

Pour modifier (dans `apps/api/src/auth/auth.service.ts`) :

```typescript
// Access token
expiresIn: '15m'  // Changez ici

// Refresh token
expiresIn: '7d'   // Changez ici
```

### Rotation des secrets

**Recommandations de sécurité :**
- Changer tous les 90 jours
- Ne jamais commiter dans Git
- Utiliser un gestionnaire de secrets en production

**Procédure :**
1. Générer nouveaux secrets
2. Mettre à jour `.env`
3. Redémarrer l'application
4. ⚠️ Tous les utilisateurs devront se reconnecter

---

## Configuration base de données

### SQLite (par défaut)

```bash
DATABASE_URL=file:/app/data/meditache.db
```

**Avantages :**
- Simple, pas de configuration
- Backup facile (copie fichier)
- Parfait < 10k patients

**Limites :**
- Concurrence limitée en écriture
- Pas de réplication

### PostgreSQL (migration future)

Pour plus de 10k patients :

```bash
DATABASE_URL=postgresql://user:password@host:5432/tappplus?schema=public
```

Puis :
```bash
# Migrer le schéma
npx prisma migrate deploy

# Migrer les données (script personnalisé nécessaire)
```

### Connexion pool

Configuration dans `apps/api/src/common/prisma/prisma.service.ts` :

```typescript
connection_limit: 10  // Ajuster selon charge
```

---

## Configuration Redis

### Mode standalone (défaut)

```bash
REDIS_URL=redis://127.0.0.1:6379
```

### Redis externe

```bash
REDIS_URL=redis://username:password@redis-host:6379
```

Ou configuration séparée :
```bash
REDIS_HOST=redis.example.com
REDIS_PORT=6379
REDIS_PASSWORD=secret123
```

### Redis Sentinel (haute disponibilité)

```bash
REDIS_SENTINELS=sentinel1:26379,sentinel2:26379,sentinel3:26379
REDIS_MASTER_NAME=mymaster
```

Configuration dans `apps/api/src/app.module.ts` :

```typescript
BullModule.forRoot({
  redis: {
    sentinels: process.env.REDIS_SENTINELS.split(','),
    name: process.env.REDIS_MASTER_NAME,
  },
})
```

---

## Configuration notifications

### Email (SendGrid)

```bash
# Activer Email
SENDGRID_API_KEY=SG.xxxxxxxxxxxxxxxx
SENDGRID_FROM_EMAIL=noreply@votredomaine.com
SENDGRID_FROM_NAME=TappPlus
```

**Obtenir une clé API :**
1. Créer compte sur https://sendgrid.com
2. Settings → API Keys → Create API Key
3. Permissions : Full Access
4. Copier la clé (une seule fois !)

**Test :**
```bash
curl -X POST http://localhost/api/v1/notifications/test/email \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{"to": "test@example.com"}'
```

### SMS (Twilio)

```bash
# Activer SMS
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=xxxxxxxxxxxxxxxx
TWILIO_PHONE_NUMBER=+1234567890
```

**Obtenir les identifiants :**
1. Créer compte sur https://www.twilio.com
2. Console → Account Info
3. Acheter un numéro de téléphone
4. Copier Account SID et Auth Token

**Test :**
```bash
curl -X POST http://localhost/api/v1/notifications/test/sms \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{"to": "+237600000000"}'
```

### Push notifications (Firebase)

```bash
# Activer Push
FIREBASE_PROJECT_ID=votre-project-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@votre-project.iam.gserviceaccount.com
```

**Obtenir les credentials :**
1. Firebase Console → Project Settings
2. Service Accounts → Generate new private key
3. Télécharger le fichier JSON
4. Extraire les valeurs

**Format de la clé privée :**
```bash
# La clé doit contenir les \n pour les retours à la ligne
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIIEv...\n-----END PRIVATE KEY-----\n"
```

---

## Configuration CORS et sécurité

### CORS

**Production avec reverse proxy (recommandé) :**
```bash
# Accepter toutes origines (Nginx gère la sécurité)
CORS_ORIGINS=
```

**Production sans reverse proxy :**
```bash
# Liste blanche d'origines
CORS_ORIGINS=https://app.votredomaine.com,https://votredomaine.com
```

**Développement :**
```bash
CORS_ORIGINS=http://localhost:5500,http://localhost:3000
```

### Rate limiting

Configuration dans `apps/api/src/app.module.ts` :

```typescript
ThrottlerModule.forRoot([
  {
    ttl: 60000,      // 60 secondes
    limit: 100,      // 100 requêtes max
  },
])
```

Ajuster selon votre trafic :
- API publique : 10-20 req/min
- API privée : 100-200 req/min
- API interne : 500+ req/min

### Headers de sécurité

Dans `nginx/tappplus.conf` :

```nginx
# Déjà configurés par défaut :
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;

# Optionnel (HTTPS uniquement) :
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
```

---

## Configuration frontend

### Variables publiques

Toutes les variables `NEXT_PUBLIC_*` sont exposées au navigateur.

```bash
# API URL (vide = URLs relatives)
NEXT_PUBLIC_API_URL=

# Domaines d'images autorisés
IMAGE_DOMAINS=cdn.votredomaine.com,images.example.com

# Google Analytics (optionnel)
NEXT_PUBLIC_GA_ID=G-XXXXXXXXXX

# Sentry (optionnel)
NEXT_PUBLIC_SENTRY_DSN=https://xxxxx@sentry.io/xxxxx
```

### Configuration Next.js

Fichier `apps/web/next.config.js` :

```javascript
module.exports = {
  // Build en mode standalone
  output: 'standalone',

  // Images
  images: {
    domains: process.env.IMAGE_DOMAINS?.split(',') || [],
    remotePatterns: [
      { protocol: 'https', hostname: '**' },
      { protocol: 'http', hostname: '**' },
    ],
  },

  // Compression
  compress: true,

  // Headers personnalisés
  async headers() {
    return [
      {
        source: '/:path*',
        headers: [
          { key: 'X-DNS-Prefetch-Control', value: 'on' },
        ],
      },
    ]
  },
}
```

---

## Configuration avancée

### Logs

```bash
# Niveau de logs
LOG_LEVEL=info                   # error | warn | info | debug | verbose

# Logs structurés (JSON)
LOG_FORMAT=json                  # json | text

# Destination des logs
LOG_OUTPUT=file                  # console | file | both
```

### Timezone

**Important pour les rappels :**

```bash
# Timezone de votre région
TZ=Africa/Douala                 # UTC+1
TZ=Europe/Paris                  # UTC+1/+2 (été)
TZ=America/New_York              # UTC-5/-4 (été)
```

Liste complète : https://en.wikipedia.org/wiki/List_of_tz_database_time_zones

### Limites de requêtes

```bash
# Timeout des requêtes HTTP
HTTP_TIMEOUT=30000               # 30 secondes (millisecondes)

# Taille max des requêtes
MAX_REQUEST_SIZE=100mb           # 100 mégaoctets
```

### Cache

```bash
# Durée de cache Redis (secondes)
CACHE_TTL=3600                   # 1 heure

# Activer/désactiver le cache
CACHE_ENABLED=true               # true | false
```

---

## Exemples de configuration

### Configuration développement local

```bash
NODE_ENV=development
DATABASE_URL=file:./dev.db
REDIS_URL=redis://localhost:6379
JWT_SECRET=dev-secret-not-for-production
JWT_REFRESH_SECRET=dev-refresh-not-for-production
TZ=Africa/Douala
LOG_LEVEL=debug
```

### Configuration production

```bash
NODE_ENV=production
DATABASE_URL=file:/app/data/meditache.db
REDIS_URL=redis://127.0.0.1:6379
JWT_SECRET=<généré-avec-openssl-rand>
JWT_REFRESH_SECRET=<généré-avec-openssl-rand>
TZ=Africa/Douala
HTTP_PORT=80

# Notifications
SENDGRID_API_KEY=SG.xxxxx
SENDGRID_FROM_EMAIL=noreply@votredomaine.com
TWILIO_ACCOUNT_SID=ACxxxxx
TWILIO_AUTH_TOKEN=xxxxx
TWILIO_PHONE_NUMBER=+237xxxxxxxx

# Sécurité
CORS_ORIGINS=
LOG_LEVEL=info
```

---

**Dernière mise à jour :** 2025-10-21
