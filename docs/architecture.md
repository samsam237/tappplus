# Architecture TappPlus

Documentation technique de l'architecture du système TappPlus.

## 📖 Table des matières

1. [Vue d'ensemble](#vue-densemble)
2. [Stack technologique](#stack-technologique)
3. [Architecture système](#architecture-système)
4. [Architecture applicative](#architecture-applicative)
5. [Base de données](#base-de-données)
6. [Sécurité](#sécurité)
7. [Scalabilité](#scalabilité)
8. [Décisions d'architecture](#décisions-darchitecture)

---

## Vue d'ensemble

TappPlus est une application web full-stack conçue avec une architecture **monolithique conteneurisée** optimisée pour :
- Déploiement simple et portable
- Faible empreinte mémoire
- Performances élevées
- Facilité de maintenance

### Principes architecturaux

1. **Portabilité** - Déploiement sur n'importe quel serveur (IP/domaine)
2. **Isolation** - Conteneurisation Docker complète
3. **Scalabilité verticale** - Optimisé pour un seul serveur performant
4. **Simplicité** - Architecture monolithique unifiée

---

## Stack technologique

### Frontend

| Composant | Technologie | Version | Rôle |
|-----------|-------------|---------|------|
| Framework | **Next.js** | 14.x | Framework React avec SSR/SSG |
| UI Library | **React** | 18.x | Bibliothèque UI composants |
| Langage | **TypeScript** | 5.x | Typage statique |
| Styles | **Tailwind CSS** | 3.x | Framework CSS utility-first |
| Gestion d'état | **React Query** | 3.x | Cache et synchronisation serveur |
| Formulaires | **React Hook Form** | 7.x | Gestion de formulaires |
| Validation | **Zod** | 3.x | Schémas de validation |
| HTTP Client | **Axios** | 1.x | Requêtes HTTP |
| Icons | **Heroicons** | 2.x | Icônes SVG |
| Animations | **Framer Motion** | 10.x | Animations fluides |
| Graphiques | **Recharts** | 2.x | Visualisation de données |
| Notifications | **React Hot Toast** | 2.x | Messages toast |

### Backend

| Composant | Technologie | Version | Rôle |
|-----------|-------------|---------|------|
| Framework | **NestJS** | 10.x | Framework Node.js enterprise |
| Runtime | **Node.js** | 18.x | Environnement d'exécution |
| Langage | **TypeScript** | 5.x | Typage statique |
| ORM | **Prisma** | 5.x | Object-Relational Mapping |
| Base de données | **SQLite** | 3.x | Base de données fichier |
| Queue | **Bull** | 4.x | Gestion de files de tâches |
| Cache/Queue | **Redis** | 7.x | Store en mémoire |
| Authentication | **Passport.js** | 0.6.x | Stratégies d'authentification |
| JWT | **@nestjs/jwt** | 10.x | Tokens JSON Web |
| Validation | **class-validator** | 0.14.x | Validation DTO |
| Documentation | **Swagger** | 7.x | Documentation API OpenAPI |
| Rate Limiting | **@nestjs/throttler** | 5.x | Protection contre abus |

### Infrastructure

| Composant | Technologie | Version | Rôle |
|-----------|-------------|---------|------|
| Conteneurisation | **Docker** | 24.x | Isolation applicative |
| Orchestration | **Docker Compose** | 2.x | Multi-conteneurs |
| Process Manager | **PM2** | 5.x | Gestion de processus |
| Reverse Proxy | **Nginx** | 1.22.x | Proxy inverse et load balancer |
| Build System | **Turbo** | 1.x | Monorepo build system |

### Notifications

| Composant | Technologie | Rôle |
|-----------|-------------|------|
| Email | **SendGrid** | Envoi d'emails transactionnels |
| SMS | **Twilio** | Envoi de SMS |
| Push | **Firebase Cloud Messaging** | Notifications push mobiles |

---

## Architecture système

### Conteneur Docker unifié

```
┌─────────────────────────────────────────────────────────┐
│                  CONTAINER: tappplus-app                │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │              NGINX :80                           │  │
│  │         (Reverse Proxy)                          │  │
│  └────────┬─────────────────────────────┬───────────┘  │
│           │                             │              │
│           │ /api/v1/*                   │ /*           │
│           ▼                             ▼              │
│  ┌─────────────────┐          ┌──────────────────┐    │
│  │   API :5550     │          │   WEB :5500      │    │
│  │   (NestJS)      │◄────────►│   (Next.js)      │    │
│  └────────┬────────┘          └──────────────────┘    │
│           │                                            │
│           │                                            │
│           ▼                                            │
│  ┌──────────────────┐         ┌──────────────────┐    │
│  │  REDIS :6379     │         │  WORKER          │    │
│  │  (Queue/Cache)   │◄────────┤  (Background)    │    │
│  └──────────────────┘         └──────────────────┘    │
│                                                        │
│  ┌──────────────────────────────────────────────────┐ │
│  │         SQLite Database                          │ │
│  │         /app/data/meditache.db                   │ │
│  └──────────────────────────────────────────────────┘ │
│                                                        │
└────────────────────────────────────────────────────────┘
          │
          │ Volume persistant
          ▼
   ┌──────────────┐
   │  tappplus_   │
   │  data        │
   └──────────────┘
```

### Processus PM2

PM2 gère 5 processus dans le conteneur :

1. **nginx** - Reverse proxy (port 80)
2. **redis** - Cache et queue (port 6379)
3. **api** - API NestJS (port 5550)
4. **web** - Frontend Next.js (port 5500)
5. **worker** - Traitement background jobs

---

## Architecture applicative

### Flux de requête utilisateur

```
┌──────────┐
│ Browser  │
└────┬─────┘
     │ 1. GET http://domain.com/
     ▼
┌─────────────┐
│ NGINX :80   │
└────┬────────┘
     │ 2. Proxy → WEB :5500
     ▼
┌─────────────┐
│ Next.js     │
└────┬────────┘
     │ 3. Return HTML + JS
     │
     │ 4. Client-side: POST /api/v1/auth/login
     ▼
┌─────────────┐
│ NGINX :80   │
└────┬────────┘
     │ 5. Proxy → API :5550/api/v1/
     ▼
┌─────────────┐
│ NestJS API  │
└────┬────────┘
     │ 6. Authenticate
     ▼
┌─────────────┐
│ SQLite DB   │
└─────────────┘
```

### Architecture backend (NestJS)

```
apps/api/src/
├── main.ts                    # Bootstrap application
├── app.module.ts              # Module racine
├── auth/                      # Module authentification
│   ├── auth.module.ts
│   ├── auth.controller.ts
│   ├── auth.service.ts
│   ├── strategies/
│   │   ├── jwt.strategy.ts
│   │   └── local.strategy.ts
│   └── guards/
│       └── jwt-auth.guard.ts
├── organizations/             # Module organisations
│   ├── organizations.module.ts
│   ├── organizations.controller.ts
│   └── organizations.service.ts
├── people/                    # Module patients
│   ├── people.module.ts
│   ├── people.controller.ts
│   └── people.service.ts
├── consultations/             # Module consultations
│   ├── consultations.module.ts
│   ├── consultations.controller.ts
│   └── consultations.service.ts
├── interventions/             # Module interventions
│   ├── interventions.module.ts
│   ├── interventions.controller.ts
│   └── interventions.service.ts
├── reminders/                 # Module rappels
│   ├── reminders.module.ts
│   ├── reminders.controller.ts
│   ├── reminders.service.ts
│   └── reminders.processor.ts  # Bull queue processor
├── notifications/             # Module notifications
│   ├── notifications.module.ts
│   ├── notifications.service.ts
│   └── providers/
│       ├── email.service.ts   # SendGrid
│       ├── sms.service.ts     # Twilio
│       └── push.service.ts    # FCM
└── common/                    # Modules communs
    ├── prisma/
    │   ├── prisma.module.ts
    │   └── prisma.service.ts
    ├── decorators/
    └── filters/
```

### Architecture frontend (Next.js)

```
apps/web/src/
├── pages/                     # Pages Next.js (routing)
│   ├── _app.tsx              # Application wrapper
│   ├── _document.tsx         # Document HTML
│   ├── index.tsx             # Page d'accueil
│   ├── auth/
│   │   ├── login.tsx
│   │   └── register.tsx
│   ├── patients/
│   │   ├── index.tsx
│   │   └── [id].tsx
│   ├── consultations/
│   ├── interventions/
│   └── reminders/
├── components/                # Composants réutilisables
│   ├── layout/
│   │   ├── Layout.tsx
│   │   ├── Header.tsx
│   │   ├── Sidebar.tsx
│   │   └── Footer.tsx
│   ├── forms/
│   ├── tables/
│   └── ui/
├── lib/                       # Bibliothèques utilitaires
│   ├── api.ts                # Client API Axios
│   └── utils.ts
├── hooks/                     # Hooks React personnalisés
│   ├── useAuth.ts
│   └── useApi.ts
├── types/                     # Types TypeScript
│   └── index.ts
└── styles/                    # Styles globaux
    └── globals.css
```

---

## Base de données

### Schéma Prisma

Le schéma complet est défini dans `apps/api/prisma/schema.prisma`

#### Modèles principaux

**User** - Utilisateurs du système
```prisma
model User {
  id          String   @id @default(cuid())
  email       String   @unique
  password    String
  firstName   String
  lastName    String
  role        UserRole
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt
}
```

**Person** - Patients
```prisma
model Person {
  id            String   @id @default(cuid())
  firstName     String
  lastName      String
  dateOfBirth   DateTime?
  phone         String?
  email         String?
  address       String?
  bloodType     String?
  medicalNotes  String?
  consultations Consultation[]
  interventions Intervention[]
}
```

**Intervention** - Interventions médicales
```prisma
model Intervention {
  id              String   @id @default(cuid())
  type            String
  scheduledAt     DateTime
  personId        String
  organizationId  String
  description     String?
  reminders       Reminder[]
  person          Person   @relation(...)
  organization    Organization @relation(...)
}
```

**Reminder** - Rappels
```prisma
model Reminder {
  id             String   @id @default(cuid())
  interventionId String
  type           ReminderType
  scheduledAt    DateTime
  status         ReminderStatus
  sentAt         DateTime?
  intervention   Intervention @relation(...)
}
```

### Relations

```
Organization (1) ──── (N) Intervention
                            │
Person (1) ──── (N) Intervention
                            │
Intervention (1) ──── (N) Reminder
                            │
Person (1) ──── (N) Consultation
```

---

## Sécurité

### Authentification

**JWT (JSON Web Tokens)**
- Access Token : durée de vie 15min
- Refresh Token : durée de vie 7 jours
- Stockage sécurisé : localStorage (frontend)
- Algorithme : HS256

### Autorisation

**Guards NestJS**
- `JwtAuthGuard` : Protection des routes API
- Vérification des tokens à chaque requête
- Extraction des informations utilisateur

### Protection CORS

Configuration CORS flexible :
- Par défaut : accepte toutes origines (reverse proxy)
- Configurable via `CORS_ORIGINS` pour restriction

### Rate Limiting

**@nestjs/throttler**
- 100 requêtes par minute par IP
- Protection contre brute force
- Protection contre DoS

### Validation des données

**class-validator + Zod**
- Backend : validation DTO avec decorators
- Frontend : validation formulaires avec Zod
- Sanitization automatique

### Secrets

Stockage sécurisé :
- Variables d'environnement
- Secrets JWT minimum 32 caractères
- Rotation recommandée tous les 90 jours

---

## Scalabilité

### Scalabilité actuelle (Verticale)

L'architecture monolithique permet :
- Jusqu'à **10,000 patients** actifs
- **1,000 requêtes/minute**
- **500 Go** de données SQLite

### Optimisations performances

1. **Caching Redis**
   - Cache de requêtes fréquentes
   - TTL configuré par type de données

2. **Connection pooling**
   - Prisma connection pool
   - Nginx keepalive

3. **Compression**
   - Gzip activé (niveau 6)
   - Assets minifiés

4. **Index database**
   - Index sur colonnes fréquemment requêtées
   - Optimisation des requêtes Prisma

### Évolution future (Horizontale)

Pour scaler au-delà :
1. Séparer les services (microservices)
2. PostgreSQL au lieu de SQLite
3. Load balancer multi-instances
4. CDN pour assets statiques
5. Service mesh (Kubernetes)

---

## Décisions d'architecture

### Pourquoi un monolithe ?

**Avantages**
- Déploiement simple (1 commande)
- Debugging facile
- Transactions ACID garanties
- Faible latence inter-services
- Coûts d'infrastructure réduits

**Inconvénients**
- Scalabilité limitée
- Point unique de défaillance
- Couplage des composants

**Décision** : Adapté pour PME/Cliniques (< 10k patients)

### Pourquoi SQLite ?

**Avantages**
- Zéro configuration
- Fichier unique
- Performances excellentes (lecture)
- Backup simple (copie fichier)
- Pas de serveur supplémentaire

**Inconvénients**
- Concurrence limitée (écritures)
- Pas de réplication native
- Taille maximale ~281 TB (suffisant)

**Décision** : Parfait pour charge < 1000 req/min

### Pourquoi Next.js ?

**Avantages**
- SSR/SSG pour SEO
- Routing file-based
- API routes intégrées
- Image optimization
- Excellent DX

**Décision** : Standard industrie pour React

### Pourquoi NestJS ?

**Avantages**
- Architecture modulaire
- TypeScript natif
- Decorators élégants
- Écosystème riche
- Enterprise-ready

**Décision** : Scalabilité future garantie

### Pourquoi Docker unifié ?

**Avantages**
- Déploiement ultra-simple
- Portable (toute machine)
- Isolation garantie
- Reproduction exacte dev/prod

**Inconvénients**
- Pas de scaling horizontal immédiat

**Décision** : Priorité à la simplicité

---

## Diagrammes

### Diagramme de déploiement

```
┌─────────────────────────────────────┐
│         Serveur Physique/VM         │
│                                     │
│  ┌───────────────────────────────┐ │
│  │      Docker Engine            │ │
│  │                               │ │
│  │  ┌─────────────────────────┐ │ │
│  │  │  tappplus-app           │ │ │
│  │  │  (Conteneur)            │ │ │
│  │  │                         │ │ │
│  │  │  ├── Nginx              │ │ │
│  │  │  ├── Redis              │ │ │
│  │  │  ├── NestJS API         │ │ │
│  │  │  ├── Next.js Web        │ │ │
│  │  │  └── Worker             │ │ │
│  │  └─────────────────────────┘ │ │
│  │                               │ │
│  │  ┌─────────────────────────┐ │ │
│  │  │  Volume: tappplus_data  │ │ │
│  │  │  └── meditache.db       │ │ │
│  │  └─────────────────────────┘ │ │
│  └───────────────────────────────┘ │
└─────────────────────────────────────┘
         │
         ▼
    ┌────────┐
    │ Port 80│
    └────────┘
```

### Diagramme de séquence (Création d'intervention)

```
User → Web → API → DB → Queue → Worker → Notification

1. User clique "Créer intervention"
2. Web envoie POST /api/v1/interventions
3. API valide les données
4. API crée l'intervention (DB)
5. API crée les rappels (DB)
6. API ajoute jobs à Redis Queue
7. Worker traite jobs en background
8. Worker envoie notifications à l'heure programmée
```

---

**Dernière mise à jour :** 2025-10-21
