# Guide Développeur TappPlus

Guide complet pour développer et contribuer au projet TappPlus.

## 📖 Table des matières

1. [Configuration de l'environnement](#configuration-de-lenvironnement)
2. [Structure du projet](#structure-du-projet)
3. [Conventions de code](#conventions-de-code)
4. [Développement local](#développement-local)
5. [Tests](#tests)
6. [Contribution](#contribution)

---

## Configuration de l'environnement

### Prérequis développeur

- **Node.js** 18.x ou supérieur
- **npm** 9.x ou supérieur
- **Git** 2.x ou supérieur
- **VSCode** (recommandé)
- **Docker** (optionnel mais recommandé)

### Installation locale

```bash
# Cloner le repository
git clone https://github.com/votre-org/tappplus.git
cd tappplus

# Installer les dépendances
npm install

# Copier la configuration
cp .env.example .env.local

# Générer le client Prisma
cd apps/api
npx prisma generate
cd ../..
```

### Configuration VSCode

Extensions recommandées (`.vscode/extensions.json`) :

```json
{
  "recommendations": [
    "dbaeumer.vscode-eslint",
    "esbenp.prettier-vscode",
    "prisma.prisma",
    "bradlc.vscode-tailwindcss",
    "ms-azuretools.vscode-docker"
  ]
}
```

Settings VSCode (`.vscode/settings.json`) :

```json
{
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true
  },
  "typescript.tsdk": "node_modules/typescript/lib"
}
```

---

## Structure du projet

### Architecture monorepo

```
tappplus/
├── apps/                      # Applications
│   ├── api/                   # Backend NestJS
│   │   ├── src/
│   │   ├── prisma/
│   │   ├── package.json
│   │   └── tsconfig.json
│   └── web/                   # Frontend Next.js
│       ├── src/
│       ├── public/
│       ├── package.json
│       └── next.config.js
├── docs/                      # Documentation
├── scripts/                   # Scripts utilitaires
├── nginx/                     # Configuration Nginx
├── .env.example              # Variables d'environnement
├── docker-compose.yml        # Orchestration Docker
├── Dockerfile                # Image Docker unifiée
├── ecosystem.config.js       # Configuration PM2
├── turbo.json                # Configuration Turbo
└── package.json              # Racine workspace
```

### Backend (apps/api/src/)

```
apps/api/src/
├── main.ts                    # Point d'entrée
├── app.module.ts              # Module racine
├── auth/                      # Authentification JWT
│   ├── auth.module.ts
│   ├── auth.controller.ts
│   ├── auth.service.ts
│   ├── dto/                   # Data Transfer Objects
│   ├── strategies/            # Passport strategies
│   └── guards/                # Auth guards
├── organizations/             # Module organisations
├── people/                    # Module patients
├── consultations/             # Module consultations
├── interventions/             # Module interventions
├── reminders/                 # Module rappels
│   ├── reminders.processor.ts # Bull queue processor
│   └── reminders.service.ts
├── notifications/             # Module notifications
│   ├── notifications.service.ts
│   └── providers/             # Email, SMS, Push
├── common/                    # Code partagé
│   ├── prisma/               # Service Prisma
│   ├── decorators/           # Decorators personnalisés
│   └── filters/              # Exception filters
└── worker.ts                 # Worker background jobs
```

### Frontend (apps/web/src/)

```
apps/web/src/
├── pages/                     # Pages Next.js (routing automatique)
│   ├── _app.tsx              # Wrapper global
│   ├── _document.tsx         # Document HTML
│   ├── index.tsx             # Page d'accueil
│   ├── auth/
│   │   ├── login.tsx
│   │   └── register.tsx
│   ├── patients/
│   ├── consultations/
│   ├── interventions/
│   └── reminders/
├── components/                # Composants React
│   ├── layout/               # Layout components
│   ├── forms/                # Form components
│   ├── tables/               # Table components
│   └── ui/                   # UI primitives
├── lib/                       # Bibliothèques
│   ├── api.ts                # Client API Axios
│   └── utils.ts              # Fonctions utilitaires
├── hooks/                     # Custom React hooks
│   ├── useAuth.ts
│   └── useApi.ts
├── types/                     # TypeScript types
└── styles/                    # Styles globaux
```

---

## Conventions de code

### TypeScript

```typescript
// ✅ Bon
interface User {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
}

async function getUser(id: string): Promise<User> {
  // ...
}

// ❌ Mauvais
async function getUser(id) {  // Pas de typage
  // ...
}
```

### Naming conventions

- **Fichiers** : kebab-case (`user-service.ts`)
- **Classes** : PascalCase (`UserService`)
- **Fonctions/variables** : camelCase (`getUserById`)
- **Constantes** : UPPER_SNAKE_CASE (`MAX_RETRIES`)
- **Interfaces** : PascalCase sans préfixe I (`User`, pas `IUser`)
- **Types** : PascalCase (`UserRole`)

### NestJS - Controllers

```typescript
@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get()
  @UseGuards(JwtAuthGuard)
  async findAll(): Promise<User[]> {
    return this.usersService.findAll();
  }

  @Post()
  @UseGuards(JwtAuthGuard)
  async create(@Body() createUserDto: CreateUserDto): Promise<User> {
    return this.usersService.create(createUserDto);
  }
}
```

### NestJS - Services

```typescript
@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  async findAll(): Promise<User[]> {
    return this.prisma.user.findMany();
  }

  async findOne(id: string): Promise<User | null> {
    return this.prisma.user.findUnique({ where: { id } });
  }
}
```

### React - Components

```typescript
// ✅ Bon - Functional component avec TypeScript
interface UserCardProps {
  user: User;
  onEdit: (id: string) => void;
}

export const UserCard: React.FC<UserCardProps> = ({ user, onEdit }) => {
  return (
    <div className="card">
      <h3>{user.firstName} {user.lastName}</h3>
      <button onClick={() => onEdit(user.id)}>Edit</button>
    </div>
  );
};

// ❌ Mauvais - Pas de typage
export const UserCard = ({ user, onEdit }) => {
  // ...
};
```

### Prisma - Models

```prisma
model User {
  id        String   @id @default(cuid())
  email     String   @unique
  password  String
  firstName String
  lastName  String
  role      UserRole @default(USER)
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  @@map("users")
}
```

---

## Développement local

### Mode développement séparé

Développer API et Web séparément pour hot reload :

```bash
# Terminal 1 - API
cd apps/api
npm run dev

# Terminal 2 - Web
cd apps/web
npm run dev

# Terminal 3 - Redis (si nécessaire)
redis-server
```

Accès :
- **Frontend** : http://localhost:5500
- **API** : http://localhost:5550
- **Swagger** : http://localhost:5550/api/docs

### Mode développement Docker

```bash
# Build et start
docker compose -f docker-compose.dev.yml up --build

# Avec watch (rebuild auto)
docker compose -f docker-compose.dev.yml watch
```

### Variables d'environnement dev

Créer `.env.local` :

```bash
NODE_ENV=development
DATABASE_URL=file:./dev.db
REDIS_URL=redis://localhost:6379
JWT_SECRET=dev-secret-not-for-production
JWT_REFRESH_SECRET=dev-refresh-not-for-production
LOG_LEVEL=debug
```

### Base de données de développement

```bash
# Créer/appliquer migrations
cd apps/api
npx prisma migrate dev --name description_migration

# Seed la base
npx prisma db seed

# Ouvrir Prisma Studio
npx prisma studio
# → http://localhost:5555
```

### Hot reload

- **NestJS** : Hot reload activé par défaut avec `npm run dev`
- **Next.js** : Fast Refresh automatique

---

## Tests

### Tests unitaires (Backend)

```typescript
// user.service.spec.ts
import { Test, TestingModule } from '@nestjs/testing';
import { UsersService } from './users.service';
import { PrismaService } from '../common/prisma/prisma.service';

describe('UsersService', () => {
  let service: UsersService;
  let prisma: PrismaService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [UsersService, PrismaService],
    }).compile();

    service = module.get<UsersService>(UsersService);
    prisma = module.get<PrismaService>(PrismaService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should return all users', async () => {
    const result = [{ id: '1', email: 'test@example.com' }];
    jest.spyOn(prisma.user, 'findMany').mockResolvedValue(result);

    expect(await service.findAll()).toBe(result);
  });
});
```

Exécuter :
```bash
cd apps/api
npm run test              # Tous les tests
npm run test:watch        # Mode watch
npm run test:cov          # Avec coverage
```

### Tests E2E (Backend)

```typescript
// auth.e2e-spec.ts
import { Test } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../src/app.module';

describe('AuthController (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleRef.createNestApplication();
    await app.init();
  });

  it('/api/v1/auth/login (POST)', () => {
    return request(app.getHttpServer())
      .post('/api/v1/auth/login')
      .send({ email: 'test@example.com', password: 'password123' })
      .expect(201);
  });

  afterAll(async () => {
    await app.close();
  });
});
```

Exécuter :
```bash
cd apps/api
npm run test:e2e
```

### Tests Frontend (React)

```typescript
// UserCard.test.tsx
import { render, screen } from '@testing-library/react';
import { UserCard } from './UserCard';

describe('UserCard', () => {
  it('renders user name', () => {
    const user = {
      id: '1',
      firstName: 'John',
      lastName: 'Doe',
      email: 'john@example.com',
    };

    render(<UserCard user={user} onEdit={() => {}} />);

    expect(screen.getByText('John Doe')).toBeInTheDocument();
  });
});
```

Exécuter :
```bash
cd apps/web
npm run test
```

---

## Contribution

### Workflow Git

```bash
# 1. Créer une branche
git checkout -b feature/nouvelle-fonctionnalite

# 2. Développer et commiter
git add .
git commit -m "feat: ajouter fonctionnalité X"

# 3. Pousser
git push origin feature/nouvelle-fonctionnalite

# 4. Créer une Pull Request sur GitHub
```

### Convention de commits

Format : `type(scope): message`

**Types :**
- `feat`: Nouvelle fonctionnalité
- `fix`: Correction de bug
- `docs`: Documentation
- `style`: Formatage (pas de changement de code)
- `refactor`: Refactoring
- `test`: Ajout de tests
- `chore`: Tâches de maintenance

**Exemples :**
```bash
git commit -m "feat(auth): ajouter authentification OAuth"
git commit -m "fix(api): corriger erreur 500 sur /users"
git commit -m "docs(readme): mettre à jour instructions installation"
```

### Pull Request

Template de PR :

```markdown
## Description
Brève description des changements

## Type de changement
- [ ] Bug fix
- [ ] Nouvelle fonctionnalité
- [ ] Breaking change
- [ ] Documentation

## Checklist
- [ ] Tests ajoutés/mis à jour
- [ ] Documentation mise à jour
- [ ] Code formatté (Prettier)
- [ ] Pas d'erreurs ESLint
- [ ] Build réussit
```

### Code Review

Critères de validation :
- ✅ Code fonctionnel et testé
- ✅ TypeScript strict respecté
- ✅ Pas de console.log en production
- ✅ Gestion d'erreurs appropriée
- ✅ Performance acceptable
- ✅ Sécurité vérifiée

---

## Scripts utiles

```bash
# Backend
cd apps/api
npm run dev              # Développement
npm run build            # Build production
npm run start:prod       # Démarrer en prod
npm run test             # Tests unitaires
npm run test:e2e         # Tests E2E
npm run lint             # Linter
npm run format           # Prettier

# Frontend
cd apps/web
npm run dev              # Développement
npm run build            # Build production
npm run start            # Démarrer en prod
npm run lint             # Linter
npm run type-check       # Vérifier types

# Prisma
npx prisma generate      # Générer client
npx prisma migrate dev   # Créer migration
npx prisma migrate deploy # Appliquer migrations
npx prisma studio        # GUI base de données
npx prisma db seed       # Seed données
```

---

**Dernière mise à jour :** 2025-10-21
