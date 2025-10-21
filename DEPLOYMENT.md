# TappPlus - Guide de Déploiement

Guide complet pour déployer TappPlus sur n'importe quel serveur avec Docker.

## Table des Matières

1. [Architecture](#architecture)
2. [Prérequis](#prérequis)
3. [Déploiement Rapide](#déploiement-rapide)
4. [Configuration](#configuration)
5. [Accès à l'Application](#accès-à-lapplication)
6. [Gestion des Processus](#gestion-des-processus)
7. [Sauvegarde et Restauration](#sauvegarde-et-restauration)
8. [Dépannage](#dépannage)
9. [Mise à Jour](#mise-à-jour)
10. [SSL en Production](#ssl-en-production)

---

## Architecture

TappPlus utilise une **architecture monolithique professionnelle** :

### Un Seul Conteneur Docker Contenant :

```
Port 80 (HTTP)
    ↓
[Nginx Reverse Proxy]  ← Point d'entrée unique
    ├─ /          → Frontend Next.js (port interne 5500)
    ├─ /api/v1/*  → API NestJS (port interne 5550)
    └─ /health    → Health check
        ↓
[Redis] (port interne 6379)
[SQLite] (/app/data/meditache.db)
[Worker] (background jobs)
```

### Processus Gérés par PM2

1. **nginx** - Reverse proxy HTTP (port 80)
2. **redis** - Queue de messages pour rappels
3. **api** - Backend NestJS (port interne 5550)
4. **web** - Frontend Next.js (port interne 5500)
5. **worker** - Traitement arrière-plan des rappels

---

## Prérequis

### Sur le Serveur

- **Docker** >= 20.10
- **Docker Compose** >= 2.0
- **Minimum 1 GB RAM** (2 GB recommandé)
- **Minimum 5 GB stockage**
- **Port disponible** : 80 (ou configurable via HTTP_PORT)

### Installation Docker

#### Sur Ubuntu/Debian
```bash
# Installer Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Ajouter votre utilisateur au groupe docker
sudo usermod -aG docker $USER

# Installer Docker Compose
sudo apt install docker-compose-plugin

# Vérifier
docker --version
docker compose version
```

#### Sur CentOS/RHEL
```bash
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo systemctl start docker
sudo systemctl enable docker
```

---

## Déploiement Rapide

### 1. Cloner le Projet

```bash
git clone <your-repository-url> tappplus
cd tappplus
```

### 2. Configurer l'Environnement

```bash
# Copier le fichier d'exemple
cp .env.example .env

# Éditer les variables (IMPORTANT !)
nano .env
```

**Changez au minimum** :

```env
# Générer des secrets sécurisés
JWT_SECRET=$(openssl rand -base64 32)
JWT_REFRESH_SECRET=$(openssl rand -base64 32)

# Port HTTP (80 par défaut, changez si occupé)
HTTP_PORT=80

# Timezone
TZ=Africa/Douala
```

### 3. Construire et Lancer

```bash
# Option 1 : Script automatique (recommandé)
chmod +x deploy.sh
./deploy.sh --seed

# Option 2 : Manuel
docker compose build
docker compose up -d
```

### 4. Initialiser la Base de Données

```bash
# Automatique (si vous avez utilisé deploy.sh)
# Sinon, manuellement :
docker exec tappplus-app node scripts/init-db.js --seed
```

### 5. Vérifier le Déploiement

```bash
# État des processus
docker exec tappplus-app pm2 status

# Health check
curl http://localhost/health

# Logs
docker compose logs -f
```

---

## Configuration

### Variables d'Environnement Essentielles

| Variable | Description | Défaut | Requis |
|----------|-------------|--------|---------|
| `HTTP_PORT` | Port HTTP exposé | `80` | Non |
| `DATABASE_URL` | Chemin SQLite | `file:/app/data/meditache.db` | Oui |
| `REDIS_URL` | URL Redis interne | `redis://127.0.0.1:6379` | Oui |
| `JWT_SECRET` | Secret tokens JWT | - | **OUI** |
| `JWT_REFRESH_SECRET` | Secret refresh tokens | - | **OUI** |
| `TZ` | Timezone serveur | `Africa/Douala` | Non |

### Changer le Port HTTP

Si le port 80 est occupé :

```env
# Dans .env
HTTP_PORT=8080
```

Puis redémarrez :
```bash
docker compose down
docker compose up -d
```

---

## Accès à l'Application

### En Local

```bash
# Frontend
http://localhost

# API Documentation (Swagger)
http://localhost/api/v1/docs

# Health Check
http://localhost/health
```

### Depuis un Autre Ordinateur

```bash
# Remplacez YOUR_SERVER_IP par l'IP de votre serveur
http://YOUR_SERVER_IP

# Exemples :
http://192.168.1.100
http://10.0.0.5
```

**IMPORTANT** : Le frontend utilisera automatiquement la même IP/domaine pour l'API grâce au reverse proxy Nginx.

---

## Gestion des Processus

TappPlus utilise PM2 pour gérer 5 processus :

### Commandes PM2

```bash
# Voir tous les processus
docker exec tappplus-app pm2 status

# Logs en temps réel
docker exec tappplus-app pm2 logs

# Logs d'un processus spécifique
docker exec tappplus-app pm2 logs nginx
docker exec tappplus-app pm2 logs api
docker exec tappplus-app pm2 logs web

# Redémarrer un processus
docker exec tappplus-app pm2 restart api

# Redémarrer tous les processus
docker exec tappplus-app pm2 restart all

# Métriques (CPU, RAM)
docker exec tappplus-app pm2 monit
```

### État Normal des Processus

```
┌────┬────────┬─────────┬─────────┬──────────┐
│ id │ name   │ status  │ restart │ uptime   │
├────┼────────┼─────────┼─────────┼──────────┤
│ 0  │ nginx  │ online  │ 0       │ 2h       │
│ 1  │ redis  │ online  │ 0       │ 2h       │
│ 2  │ api    │ online  │ 0       │ 2h       │
│ 3  │ web    │ online  │ 0       │ 2h       │
│ 4  │ worker │ online  │ 0       │ 2h       │
└────┴────────┴─────────┴─────────┴──────────┘
```

---

## Sauvegarde et Restauration

### Sauvegarder la Base de Données

```bash
# Backup manuel
docker exec tappplus-app sqlite3 /app/data/meditache.db ".backup /app/data/backup-$(date +%Y%m%d).db"

# Copier sur le host
docker cp tappplus-app:/app/data/backup-$(date +%Y%m%d).db ./backups/

# Backup automatique quotidien (cron)
# Ajoutez dans crontab -e :
0 2 * * * docker exec tappplus-app sqlite3 /app/data/meditache.db ".backup /app/data/backup-$(date +\%Y\%m\%d).db"
```

### Restaurer la Base de Données

```bash
# Copier le backup dans le conteneur
docker cp ./backups/backup-20250101.db tappplus-app:/app/data/restore.db

# Restaurer
docker exec tappplus-app bash -c "
  rm -f /app/data/meditache.db &&
  cp /app/data/restore.db /app/data/meditache.db
"

# Redémarrer
docker compose restart
```

---

## Dépannage

### L'application ne démarre pas

```bash
# Vérifier les logs
docker compose logs

# Vérifier les processus PM2
docker exec tappplus-app pm2 logs

# Redémarrer complètement
docker compose down
docker compose up -d
```

### Nginx ne démarre pas

```bash
# Tester la configuration Nginx
docker exec tappplus-app nginx -t

# Voir les logs Nginx
docker exec tappplus-app cat /app/logs/nginx-error.log

# Redémarrer Nginx
docker exec tappplus-app pm2 restart nginx
```

### API non accessible via /api/v1/

```bash
# Vérifier que l'API tourne
docker exec tappplus-app pm2 logs api

# Test direct (sans Nginx)
docker exec tappplus-app curl http://localhost:5550/api/v1/health

# Vérifier la config Nginx
docker exec tappplus-app cat /etc/nginx/sites-enabled/tappplus.conf
```

### Erreur "Cannot GET /"

Le frontend ne répond pas. Vérifiez :

```bash
# État du processus web
docker exec tappplus-app pm2 logs web

# Test direct
docker exec tappplus-app curl http://localhost:5500
```

---

## Mise à Jour

```bash
# 1. Sauvegarder la base de données
docker exec tappplus-app sqlite3 /app/data/meditache.db ".backup /app/data/backup-before-update.db"

# 2. Arrêter l'application
docker compose down

# 3. Récupérer les mises à jour
git pull origin main

# 4. Reconstruire
docker compose build --no-cache

# 5. Redémarrer
docker compose up -d

# 6. Appliquer les migrations
docker exec tappplus-app npx prisma migrate deploy --schema=/app/apps/api/prisma/schema.prisma

# 7. Vérifier
docker exec tappplus-app pm2 status
curl http://localhost/health
```

---

## SSL en Production

### Option 1 : Nginx Externe (Recommandé)

Installez Nginx sur le serveur hôte comme reverse proxy SSL :

```nginx
# /etc/nginx/sites-available/tappplus

server {
    listen 443 ssl http2;
    server_name your-domain.com;

    # Certificats SSL (Let's Encrypt)
    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;

    # Sécurité SSL
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    # Proxy vers le conteneur Docker
    location / {
        proxy_pass http://localhost:80;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}

# Redirection HTTP → HTTPS
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$server_name$request_uri;
}
```

Activez le site et obtenez un certificat SSL :

```bash
# Activer le site
sudo ln -s /etc/nginx/sites-available/tappplus /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

# Obtenir un certificat SSL gratuit
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
```

### Option 2 : Traefik (Docker)

Créez un fichier `docker-compose.prod.yml` :

```yaml
version: '3.8'

services:
  traefik:
    image: traefik:v2.10
    container_name: traefik
    command:
      - "--providers.docker=true"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.letsencrypt.acme.email=your-email@example.com"
      - "--certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json"
      - "--certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web"
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./letsencrypt:/letsencrypt

  tappplus:
    extends:
      file: docker-compose.yml
      service: tappplus
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.tappplus.rule=Host(`your-domain.com`)"
      - "traefik.http.routers.tappplus.entrypoints=websecure"
      - "traefik.http.routers.tappplus.tls.certresolver=letsencrypt"
      - "traefik.http.services.tappplus.loadbalancer.server.port=80"
```

Déployez :

```bash
docker compose -f docker-compose.prod.yml up -d
```

---

## Architecture Complète en Production

```
Internet (HTTPS 443)
    ↓
[Nginx Externe / Traefik]  ← SSL Termination
    ↓ (HTTP)
[Docker Container - Port 80]
    ↓
[Nginx Interne]  ← Reverse Proxy
    ├─ /          → Frontend Next.js (5500)
    └─ /api/v1/*  → API NestJS (5550)
```

**Avantages** :
- ✅ Image Docker portable (pas de certificats hardcodés)
- ✅ Renouvellement SSL automatique (Let's Encrypt)
- ✅ Aucun rebuild nécessaire pour changer les certificats
- ✅ Architecture microservices standard
- ✅ Facile à déployer sur n'importe quel serveur

---

## Support

Pour toute question :

1. Vérifier les logs : `docker compose logs -f`
2. État PM2 : `docker exec tappplus-app pm2 status`
3. Consulter la section [Dépannage](#dépannage)

---

**TappPlus - Architecture Professionnelle, Déploiement Simplifié** 🚀
