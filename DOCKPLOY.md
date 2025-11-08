# TappPlus - Guide de Migration vers Dockploy

Guide complet pour déployer TappPlus sur Dockploy depuis GitHub en quelques clics.

---

## Table des Matières

1. [Qu'est-ce que Dockploy ?](#quest-ce-que-dockploy-)
2. [Pourquoi Dockploy pour TappPlus ?](#pourquoi-dockploy-pour-tappplus-)
3. [Prérequis](#prérequis)
4. [Préparation du Repository GitHub](#préparation-du-repository-github)
5. [Installation de Dockploy](#installation-de-dockploy)
6. [Déploiement sur Dockploy](#déploiement-sur-dockploy)
7. [Configuration Avancée](#configuration-avancée)
8. [Déploiements Automatiques](#déploiements-automatiques)
9. [Monitoring et Logs](#monitoring-et-logs)
10. [Sauvegarde et Rollback](#sauvegarde-et-rollback)
11. [SSL et Domaine Personnalisé](#ssl-et-domaine-personnalisé)
12. [Dépannage](#dépannage)

---

## Qu'est-ce que Dockploy ?

**Dockploy** est une plateforme moderne de déploiement d'applications conteneurisées, similaire à :
- Heroku (mais self-hosted)
- Railway
- Render
- Vercel (pour backend)

### Fonctionnalités Clés

✅ **Déploiements Git** - Push to deploy depuis GitHub/GitLab
✅ **Zero-downtime** - Pas d'interruption lors des mises à jour
✅ **Rollback instantané** - Retour à une version précédente en 1 clic
✅ **SSL automatique** - Let's Encrypt intégré
✅ **Monitoring** - Métriques CPU/RAM/Réseau en temps réel
✅ **Logs centralisés** - Tous les logs au même endroit
✅ **Webhooks** - Déploiements automatiques sur git push

---

## Pourquoi Dockploy pour TappPlus ?

### Avantages vs Docker Compose Manuel

| Fonctionnalité | Docker Compose | Dockploy |
|----------------|----------------|----------|
| Déploiement initial | Complexe (SSH, git clone, build) | 1 clic depuis GitHub |
| Mises à jour | Manuel (git pull, rebuild, redeploy) | Automatique sur git push |
| Rollback | Complexe (git revert, rebuild) | 1 clic (instant) |
| SSL/HTTPS | Configuration manuelle | Automatique (Let's Encrypt) |
| Monitoring | Nécessite des outils externes | Intégré (dashboard) |
| Logs | `docker logs` en CLI | Interface web centralisée |
| Zero-downtime | Non (sauf config avancée) | Oui (par défaut) |
| Multi-environnements | Nécessite plusieurs serveurs | Staging + Production faciles |

### Cas d'Usage Idéaux

✅ **Production** - Déploiements professionnels avec monitoring
✅ **Staging** - Environnement de test avant production
✅ **Équipes** - Plusieurs développeurs, déploiements fréquents
✅ **Clients** - Besoin d'une interface simple pour gérer l'app

---

## Prérequis

### Sur Votre Machine Locale

- **Git** installé
- **Compte GitHub** avec repository TappPlus
- Accès au code source de TappPlus

### Sur le Serveur de Déploiement

- **OS** : Ubuntu 20.04+ / Debian 11+ / CentOS 8+
- **RAM** : Minimum 2 GB (4 GB recommandé)
- **Stockage** : Minimum 20 GB
- **CPU** : 1 core minimum (2+ recommandé)
- **Accès root** : Oui (pour installation initiale)
- **Ports** : 80 (HTTP), 443 (HTTPS) ouverts

### Fournisseurs Cloud Compatibles

✅ **DigitalOcean** - Droplet ($12/mois pour 2 GB RAM)
✅ **Hetzner** - VPS Cloud (€4.15/mois pour 2 GB RAM)
✅ **AWS EC2** - t3.small ou mieux
✅ **Google Cloud** - e2-small ou mieux
✅ **Azure** - B2s ou mieux
✅ **Scaleway** - DEV1-S ou mieux
✅ **Vultr** - $12/mois pour 2 GB RAM
✅ **Serveur dédié** - N'importe quel serveur Linux

---

## Préparation du Repository GitHub

### 1. Vérifier les Fichiers Requis

Votre projet TappPlus contient déjà tous les fichiers nécessaires :

```bash
# Structure vérifiée
tappplus/
├── Dockerfile              ✅ Build instructions
├── docker-compose.yml      ✅ Configuration (optionnel avec Dockploy)
├── .env.example            ✅ Template de configuration
├── ecosystem.config.js     ✅ PM2 process manager
├── nginx/                  ✅ Reverse proxy config
├── apps/
│   ├── api/               ✅ Backend NestJS
│   └── web/               ✅ Frontend Next.js
└── scripts/
    └── init-db.js         ✅ Database initialization
```

### 2. Pousser sur GitHub

```bash
# Si ce n'est pas déjà fait
cd /path/to/tappplus

# Initialiser git (si nécessaire)
git init
git add .
git commit -m "Initial commit - Ready for Dockploy"

# Ajouter le remote GitHub
git remote add origin https://github.com/VOTRE-USERNAME/tappplus.git

# Pousser vers GitHub
git branch -M main
git push -u origin main
```

### 3. Configurer le Repository GitHub

**Important** : Assurez-vous que :

- ✅ Le repository est **public** OU vous avez configuré une clé SSH/token
- ✅ Le fichier `.gitignore` exclut `.env` (pas `.env.example`)
- ✅ Aucun secret n'est commité (vérifier avec `git log --all`)

---

## Installation de Dockploy

### Installation Rapide (One-Liner)

```bash
# SSH sur votre serveur
ssh root@your-server-ip

# Installer Dockploy (installation automatique)
curl -sSL https://dockploy.com/install.sh | bash
```

Cette commande va :
1. Installer Docker si nécessaire
2. Installer Dockploy
3. Démarrer le service Dockploy
4. Afficher l'URL d'accès

### Configuration Post-Installation

```bash
# Vérifier que Dockploy tourne
docker ps | grep dockploy

# Accéder à l'interface web
# URL: http://YOUR_SERVER_IP:3000
```

### Premier Accès

1. Ouvrez `http://YOUR_SERVER_IP:3000` dans votre navigateur
2. Créez votre compte admin (première connexion)
3. Configurez votre profil

---

## Déploiement sur Dockploy

### Méthode 1 : Déploiement via Interface Web (Recommandé)

#### Étape 1 : Créer un Nouveau Projet

1. **Connectez-vous à Dockploy** → Cliquez sur **"New Application"**

2. **Informations de Base**
   ```
   Nom du projet: tappplus
   Description: Application de rappels d'interventions médicales
   ```

3. **Source du Code**
   - Type: **GitHub**
   - Repository URL: `https://github.com/VOTRE-USERNAME/tappplus`
   - Branche: `main`
   - Auto-deploy: ✅ **Activé** (déploiement automatique sur git push)

#### Étape 2 : Configuration du Build

**Build Method** : Sélectionnez **"Dockerfile"**

```yaml
Build Configuration:
  Context: . (racine du projet)
  Dockerfile: ./Dockerfile
  Build Args: (laisser vide)
```

#### Étape 3 : Variables d'Environnement

**Générer des secrets JWT sécurisés** (CRITIQUE !) :

```bash
# Méthode 1 : Utiliser le script fourni (recommandé)
node scripts/generate-secrets.js --dockploy

# Méthode 2 : OpenSSL (si disponible)
openssl rand -base64 32  # Pour JWT_SECRET
openssl rand -base64 32  # Pour JWT_REFRESH_SECRET

# Méthode 3 : Node.js en une ligne
node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"
```

**Copier les variables dans Dockploy** :

```env
# Essentielles - SECRETS GÉNÉRÉS CI-DESSUS
NODE_ENV=production
JWT_SECRET=<VOTRE_SECRET_GÉNÉRÉ>
JWT_REFRESH_SECRET=<VOTRE_REFRESH_SECRET_GÉNÉRÉ>

# Base de données (SQLite interne)
DATABASE_URL=file:/app/data/meditache.db

# Redis (interne au conteneur)
REDIS_URL=redis://127.0.0.1:6379

# Configuration
TZ=Africa/Douala
API_PORT=5550
WEB_PORT=5500
HTTP_PORT=80

# Frontend (laisser vide pour auto-détection)
NEXT_PUBLIC_API_URL=
```

**Important** : Voir [scripts/README.md](./scripts/README.md) pour plus d'options de génération de secrets.

#### Étape 4 : Configuration des Ports

```yaml
Port Mappings:
  Container Port: 80
  Public Port: 80 (ou un port libre si 80 est occupé)
  Protocol: HTTP
```

#### Étape 5 : Volumes Persistants

**IMPORTANT** : Configurer les volumes pour ne pas perdre les données !

```yaml
Volumes:
  1. /app/data → Volume Name: tappplus-data
     Description: Base de données SQLite

  2. /app/logs → Volume Name: tappplus-logs
     Description: Logs PM2 et Nginx
```

#### Étape 6 : Health Check

```yaml
Health Check:
  Endpoint: /health
  Method: GET
  Interval: 30s
  Timeout: 10s
  Retries: 3
  Start Period: 60s
```

#### Étape 7 : Déployer !

1. Cliquez sur **"Create & Deploy"**
2. Dockploy va :
   - Cloner le repository GitHub
   - Builder l'image Docker (cela prend 5-10 minutes)
   - Lancer le conteneur
   - Vérifier le health check

3. **Suivez les logs en temps réel** dans l'interface

#### Étape 8 : Post-Déploiement

Une fois le déploiement réussi :

**1. Initialiser la base de données**

```bash
# Via l'interface Dockploy → Terminal
node scripts/init-db.js --seed
```

OU depuis votre machine :

```bash
# Trouver le nom du conteneur
docker ps | grep tappplus

# Exécuter le script
docker exec <container-name> node scripts/init-db.js --seed
```

**2. Vérifier l'application**

```bash
# Health check
curl http://your-server-ip/health

# Devrait retourner : {"status":"ok"}
```

**3. Accéder à l'application**

```
Frontend: http://your-server-ip
API Docs: http://your-server-ip/api/v1/docs
```

---

### Méthode 2 : Déploiement avec dockploy.json (Configuration as Code)

Créez un fichier `dockploy.json` à la racine du projet :

```json
{
  "name": "tappplus",
  "description": "Application de rappels d'interventions médicales",
  "source": {
    "type": "github",
    "repository": "https://github.com/VOTRE-USERNAME/tappplus",
    "branch": "main",
    "autoDeploy": true
  },
  "build": {
    "type": "dockerfile",
    "context": ".",
    "dockerfile": "Dockerfile"
  },
  "deployment": {
    "port": 80,
    "env": {
      "NODE_ENV": "production",
      "DATABASE_URL": "file:/app/data/meditache.db",
      "REDIS_URL": "redis://127.0.0.1:6379",
      "TZ": "Africa/Douala",
      "API_PORT": "5550",
      "WEB_PORT": "5500",
      "HTTP_PORT": "80"
    },
    "volumes": [
      {
        "name": "tappplus-data",
        "mountPath": "/app/data"
      },
      {
        "name": "tappplus-logs",
        "mountPath": "/app/logs"
      }
    ],
    "healthCheck": {
      "path": "/health",
      "interval": 30,
      "timeout": 10,
      "retries": 3,
      "startPeriod": 60
    }
  }
}
```

**Déployer avec ce fichier** :

```bash
# Via CLI Dockploy
dockploy deploy --config dockploy.json

# OU via l'interface web : Import Configuration
```

---

## Configuration Avancée

### Environnements Multiples (Staging + Production)

#### 1. Créer une Branche Staging

```bash
# Sur votre machine locale
git checkout -b staging
git push -u origin staging
```

#### 2. Créer Deux Applications dans Dockploy

**Application 1 - Staging**
```yaml
Nom: tappplus-staging
Branche: staging
Port: 8080
Domaine: staging.yourdomain.com
```

**Application 2 - Production**
```yaml
Nom: tappplus-production
Branche: main
Port: 80
Domaine: yourdomain.com
```

### Variables d'Environnement par Environnement

**Staging** :
```env
NODE_ENV=staging
DATABASE_URL=file:/app/data/meditache-staging.db
# ... autres configs de test
```

**Production** :
```env
NODE_ENV=production
DATABASE_URL=file:/app/data/meditache.db
# ... configs sécurisées
```

### Limites de Ressources

Dans Dockploy, configurez les limites :

```yaml
Resources:
  Memory Limit: 1024 MB
  Memory Reservation: 512 MB
  CPU Limit: 1.0 (1 core)
  CPU Reservation: 0.5 (50% d'un core)
```

---

## Déploiements Automatiques

### Configurer les Webhooks GitHub

#### Méthode Automatique (Recommandé)

1. Dans Dockploy → Votre Projet → **Settings** → **Webhooks**
2. Cliquez sur **"Configure GitHub Webhook"**
3. Autorisez Dockploy sur GitHub (OAuth)
4. Le webhook est configuré automatiquement ✅

#### Méthode Manuelle

**1. Copier l'URL du Webhook dans Dockploy**

```
https://your-dockploy-server.com/hooks/github/tappplus
```

**2. Configurer dans GitHub**

1. Allez sur votre repository GitHub
2. **Settings** → **Webhooks** → **Add webhook**
3. Payload URL: `https://your-dockploy-server.com/hooks/github/tappplus`
4. Content type: `application/json`
5. Secret: (copié depuis Dockploy)
6. Events: **Just the push event**
7. Active: ✅

**3. Tester le Webhook**

```bash
# Faites un changement et push
echo "# Test" >> README.md
git add README.md
git commit -m "Test auto-deploy"
git push origin main

# Le déploiement devrait se lancer automatiquement dans Dockploy
```

### Workflow de Déploiement Continu

```
Développeur              GitHub              Dockploy            Serveur
    |                       |                     |                  |
    |-- git push main -->   |                     |                  |
    |                       |-- webhook -->       |                  |
    |                       |                     |-- clone -->      |
    |                       |                     |-- build -->      |
    |                       |                     |-- test -->       |
    |                       |                     |-- deploy -->     |
    |                       |                     |                  |
    |                       |                     |<-- success ---   |
    |<-- notification ------|--------------------- |                  |
```

---

## Monitoring et Logs

### Dashboard Dockploy

Dans l'interface Dockploy, vous avez accès à :

**Métriques en Temps Réel** :
- CPU Usage (%)
- RAM Usage (MB)
- Network I/O
- Disk Usage
- Request Rate

**Graphiques** :
- Historique sur 1h, 24h, 7j, 30j
- Courbes de charge
- Temps de réponse

### Logs Centralisés

**Via l'Interface Web** :

1. Dockploy → Votre Projet → **Logs**
2. Filtres disponibles :
   - Par processus (nginx, api, web, worker, redis)
   - Par niveau (info, warn, error)
   - Par date/heure
   - Recherche full-text

**Via CLI** :

```bash
# Logs en temps réel
dockploy logs tappplus --follow

# Logs d'un processus spécifique
dockploy logs tappplus --service api

# Logs avec filtre
dockploy logs tappplus --level error --since 1h
```

### Logs PM2 Internes

```bash
# Accéder au terminal du conteneur
dockploy exec tappplus bash

# Voir les processus
pm2 status

# Logs PM2
pm2 logs
pm2 logs api
pm2 logs web
```

### Alertes

Configurez des alertes dans Dockploy :

```yaml
Alerts:
  High CPU: > 80% pendant 5 minutes
  High Memory: > 90% pendant 5 minutes
  Service Down: Health check fail x3

Notifications:
  Email: admin@yourdomain.com
  Slack: #alerts
  Webhook: https://your-webhook-url.com
```

---

## Sauvegarde et Rollback

### Rollback Instantané

**En cas de problème après un déploiement** :

1. Dockploy → Votre Projet → **Deployments**
2. Liste de tous les déploiements passés
3. Cliquez sur **"Rollback"** à côté d'une version stable
4. Confirmation → Rollback en **30 secondes** ⚡

```
Déploiements:
┌─────────────────────────────────────────┐
│ #42 - 2025-01-07 14:32 (current) [Bug] │ ← Rollback possible
│ #41 - 2025-01-07 10:15 (stable)  ✅    │ ← Version stable
│ #40 - 2025-01-06 18:45                  │
│ #39 - 2025-01-06 09:20                  │
└─────────────────────────────────────────┘
```

### Sauvegarde de la Base de Données

#### Automatique via Dockploy

Configurez des backups automatiques :

```yaml
Backups:
  Schedule: Daily at 2:00 AM
  Retention: 7 days
  Location:
    - Dockploy Internal Storage
    - S3: s3://your-bucket/tappplus-backups/
    - FTP: ftp://backup-server.com/tappplus/
```

#### Manuel

```bash
# Via l'interface Dockploy → Terminal
sqlite3 /app/data/meditache.db ".backup /app/data/backup-$(date +%Y%m%d).db"

# Télécharger le backup
dockploy download tappplus:/app/data/backup-20250107.db ./backups/
```

#### Restauration

```bash
# Upload du backup
dockploy upload ./backups/backup-20250107.db tappplus:/app/data/restore.db

# Restaurer
dockploy exec tappplus bash
> rm -f /app/data/meditache.db
> cp /app/data/restore.db /app/data/meditache.db
> pm2 restart api

# OU via Dockploy UI → Restart Application
```

---

## SSL et Domaine Personnalisé

### Configurer un Domaine

#### 1. Pointer votre Domaine vers le Serveur

**DNS A Record** :
```
Type: A
Name: @ (ou www)
Value: YOUR_SERVER_IP
TTL: 3600
```

**Exemple avec Cloudflare** :
```
yourdomain.com       A    YOUR_SERVER_IP
www.yourdomain.com   A    YOUR_SERVER_IP
```

#### 2. Configurer dans Dockploy

1. Dockploy → Votre Projet → **Settings** → **Domains**
2. Cliquez sur **"Add Domain"**
3. Entrez : `yourdomain.com`
4. SSL: ✅ **Enable Let's Encrypt**
5. Redirect HTTP → HTTPS: ✅ **Enabled**
6. Sauvegarder

Dockploy va automatiquement :
- Vérifier que le DNS pointe vers le serveur
- Générer un certificat SSL Let's Encrypt
- Configurer le reverse proxy
- Activer le HTTPS

**Temps estimé** : 2-5 minutes ⚡

#### 3. Vérifier

```bash
# Tester le domaine
curl https://yourdomain.com/health

# Devrait retourner : {"status":"ok"}
```

### Renouvellement SSL Automatique

Dockploy renouvelle automatiquement les certificats Let's Encrypt :
- Vérification : tous les jours
- Renouvellement : 30 jours avant expiration
- **Aucune action manuelle requise** ✅

---

## Dépannage

### Build Échoue

**Symptôme** : Le build Docker échoue dans Dockploy

**Solutions** :

1. **Vérifier les logs de build**
   ```bash
   # Dans Dockploy → Build Logs
   # Cherchez l'erreur exacte
   ```

2. **Problème de mémoire** (erreur "killed")
   ```bash
   # Augmenter la RAM du serveur
   # OU optimiser le Dockerfile

   # Dans Dockploy → Settings → Resources
   Memory Limit: 2048 MB (au lieu de 1024)
   ```

3. **Dépendances npm timeout**
   ```dockerfile
   # Déjà configuré dans votre Dockerfile :
   RUN npm config set fetch-retry-mintimeout 20000 && \
       npm config set fetch-retry-maxtimeout 120000
   ```

4. **Build localement pour tester**
   ```bash
   # Sur votre machine
   docker build -t tappplus-test .
   docker run -p 80:80 tappplus-test

   # Si ça fonctionne localement, le problème est sur le serveur
   ```

### Application Ne Démarre Pas

**Symptôme** : Le build réussit mais l'application ne démarre pas

**Solutions** :

1. **Vérifier les logs runtime**
   ```bash
   # Dockploy → Logs → Runtime
   # Cherchez les erreurs au démarrage
   ```

2. **Vérifier PM2**
   ```bash
   dockploy exec tappplus pm2 status

   # Si un processus est en erreur :
   dockploy exec tappplus pm2 logs <process-name>
   ```

3. **Problème de ports**
   ```bash
   # Vérifier que les ports internes ne sont pas en conflit
   dockploy exec tappplus netstat -tulpn | grep -E '5500|5550|6379'
   ```

4. **Base de données corrompue**
   ```bash
   # Réinitialiser la DB
   dockploy exec tappplus node scripts/init-db.js --force
   ```

### Health Check Échoue

**Symptôme** : "Health check failing" dans Dockploy

**Solutions** :

1. **Tester manuellement**
   ```bash
   dockploy exec tappplus curl http://localhost/health

   # Devrait retourner : {"status":"ok"}
   ```

2. **Vérifier Nginx**
   ```bash
   dockploy exec tappplus nginx -t
   dockploy exec tappplus pm2 logs nginx
   ```

3. **Augmenter le start period**
   ```yaml
   # L'app peut mettre du temps à démarrer
   Health Check:
     Start Period: 120s (au lieu de 60s)
   ```

### Webhook GitHub Ne Fonctionne Pas

**Symptôme** : git push ne déclenche pas de déploiement

**Solutions** :

1. **Vérifier le webhook dans GitHub**
   ```
   GitHub → Settings → Webhooks → Recent Deliveries

   Regardez les réponses (200 = OK, 500 = erreur)
   ```

2. **Vérifier l'URL du webhook**
   ```bash
   # Doit être accessible depuis GitHub
   curl https://your-dockploy-server.com/hooks/github/tappplus
   ```

3. **Firewall**
   ```bash
   # Vérifier que les ports sont ouverts
   sudo ufw status

   # Autoriser si nécessaire
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   ```

### Volumes Perdus Après Redémarrage

**Symptôme** : Base de données vide après redémarrage

**Cause** : Volumes non configurés correctement

**Solution** :

```bash
# Vérifier les volumes
docker volume ls | grep tappplus

# Si absents, reconfigurer dans Dockploy :
# Settings → Volumes → Add Volume
/app/data → tappplus-data (persistent)
```

---

## Comparaison : Docker Compose vs Dockploy

### Déploiement Initial

**Docker Compose** :
```bash
# 15-20 minutes
1. SSH sur le serveur
2. Installer Docker
3. Cloner le repository
4. Configurer .env manuellement
5. docker compose build (5-10 min)
6. docker compose up -d
7. Initialiser la DB
8. Configurer Nginx externe pour SSL
```

**Dockploy** :
```bash
# 10 minutes
1. Installer Dockploy (1 commande)
2. Créer l'app dans l'interface (2 min)
3. Configurer les variables d'env (copier-coller)
4. Deploy (auto-build, 5-10 min)
5. SSL automatique (Let's Encrypt)
```

### Mise à Jour

**Docker Compose** :
```bash
# 10-15 minutes + risque de downtime
ssh server
cd /app/tappplus
git pull origin main
docker compose down          # ⚠️ DOWNTIME
docker compose build --no-cache
docker compose up -d
docker exec tappplus npx prisma migrate deploy
```

**Dockploy** :
```bash
# 5-10 minutes, zero downtime ✅
git push origin main
# Dockploy fait tout automatiquement :
# - Build nouvelle image
# - Lance nouveau conteneur
# - Health check
# - Switch traffic (zero downtime)
# - Garde l'ancien conteneur en backup (rollback)
```

### Rollback

**Docker Compose** :
```bash
# 10-15 minutes
ssh server
cd /app/tappplus
git log                          # Trouver le commit
git checkout <commit-hash>
docker compose down              # ⚠️ DOWNTIME
docker compose build --no-cache
docker compose up -d
```

**Dockploy** :
```bash
# 30 secondes ⚡
1. Interface web → Deployments
2. Click "Rollback" sur version stable
3. Confirmez
# Zero downtime !
```

---

## Checklist de Migration

### Avant la Migration

- [ ] Code TappPlus sur GitHub (branche `main`)
- [ ] Fichiers requis présents (Dockerfile, .env.example, etc.)
- [ ] Secrets retirés du repository (pas de .env commité)
- [ ] Serveur avec 2+ GB RAM disponible
- [ ] Accès root au serveur

### Installation Dockploy

- [ ] Dockploy installé : `curl -sSL https://dockploy.com/install.sh | bash`
- [ ] Interface accessible : `http://SERVER_IP:3000`
- [ ] Compte admin créé

### Configuration Application

- [ ] Application créée dans Dockploy
- [ ] Repository GitHub connecté
- [ ] Variables d'environnement configurées (surtout JWT_SECRET)
- [ ] Volumes persistants configurés (/app/data, /app/logs)
- [ ] Health check configuré (/health)
- [ ] Port 80 exposé

### Premier Déploiement

- [ ] Build réussi (5-10 minutes)
- [ ] Conteneur démarré
- [ ] Health check OK
- [ ] DB initialisée : `node scripts/init-db.js --seed`
- [ ] Frontend accessible : `http://SERVER_IP`
- [ ] API accessible : `http://SERVER_IP/api/v1/docs`

### Configuration Avancée

- [ ] Domaine configuré (si applicable)
- [ ] SSL Let's Encrypt activé
- [ ] Webhook GitHub configuré
- [ ] Test auto-deploy (git push → déploiement)
- [ ] Backups configurés (quotidien recommandé)
- [ ] Alertes configurées (email/Slack)

### Post-Migration

- [ ] Documentation mise à jour
- [ ] Équipe formée sur Dockploy
- [ ] Procédure de rollback testée
- [ ] Monitoring vérifié (CPU, RAM, logs)

---

## Ressources

### Documentation Officielle

- **Dockploy Docs** : https://docs.dockploy.com
- **Docker** : https://docs.docker.com
- **Let's Encrypt** : https://letsencrypt.org/docs

### Communauté

- **Dockploy Discord** : https://discord.gg/dockploy
- **GitHub Issues** : https://github.com/dockploy/dockploy/issues

### Support TappPlus

- **Documentation** : Voir `README.md` et `DEPLOYMENT.md`
- **Issues** : Votre repository GitHub

---

## Conclusion

Dockploy transforme le déploiement de TappPlus :

✅ **Déploiement initial** : 10 minutes au lieu de 30+
✅ **Mises à jour** : Automatiques et sans interruption
✅ **Rollback** : 30 secondes au lieu de 15 minutes
✅ **SSL** : Automatique avec Let's Encrypt
✅ **Monitoring** : Dashboard intégré
✅ **Coût** : Gratuit (self-hosted) ou $10/mois (cloud)

**Prêt à migrer ?** Suivez ce guide étape par étape ! 🚀

---

**TappPlus + Dockploy = Déploiement Professionnel Simplifié**
