# Guide de Déploiement TappPlus

Guide complet pour déployer TappPlus en production.

## 📖 Table des matières

1. [Prérequis](#prérequis)
2. [Installation rapide](#installation-rapide)
3. [Déploiement pas à pas](#déploiement-pas-à-pas)
4. [Configuration production](#configuration-production)
5. [Initialisation de la base de données](#initialisation-de-la-base-de-données)
6. [Gestion des processus](#gestion-des-processus)
7. [Sauvegarde et restauration](#sauvegarde-et-restauration)
8. [Mise à jour](#mise-à-jour)
9. [Monitoring](#monitoring)

---

## Prérequis

### Système d'exploitation

TappPlus peut être déployé sur :
- ✅ Linux (Ubuntu 20.04+, Debian 11+, CentOS 8+)
- ✅ Windows Server 2019+
- ✅ macOS (pour développement)

### Ressources matérielles recommandées

| Usage | CPU | RAM | Stockage | Patients |
|-------|-----|-----|----------|----------|
| **Petite clinique** | 2 cores | 2 GB | 20 GB | < 1,000 |
| **Clinique moyenne** | 4 cores | 4 GB | 50 GB | < 5,000 |
| **Grand hôpital** | 8 cores | 8 GB | 100 GB | < 10,000 |

### Logiciels requis

1. **Docker** (version 24.0+)
   ```bash
   # Vérifier l'installation
   docker --version
   ```

2. **Docker Compose** (version 2.0+)
   ```bash
   # Vérifier l'installation
   docker compose version
   ```

### Installation de Docker

#### Ubuntu/Debian
```bash
# Mettre à jour les paquets
sudo apt-get update

# Installer les dépendances
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Ajouter la clé GPG officielle Docker
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Configurer le repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Installer Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Ajouter l'utilisateur au groupe docker
sudo usermod -aG docker $USER

# Redémarrer la session
newgrp docker
```

#### Windows
1. Télécharger Docker Desktop : https://www.docker.com/products/docker-desktop
2. Installer et redémarrer
3. Activer WSL 2 si demandé

### Réseau

Ports à ouvrir :
- **Port 80** (HTTP) - Obligatoire
- Port 443 (HTTPS) - Recommandé pour production

---

## Installation rapide

### 1. Cloner ou télécharger le projet

```bash
# Option A : Git
git clone https://github.com/votre-org/tappplus.git
cd tappplus

# Option B : Téléchargement ZIP
# Extraire et naviguer dans le dossier
cd tappplus
```

### 2. Configurer l'environnement

```bash
# Copier le fichier d'exemple
cp .env.example .env

# Éditer le fichier .env
nano .env
```

**Minimum à configurer :**
```bash
# Générer des secrets JWT sécurisés
JWT_SECRET=$(openssl rand -base64 32)
JWT_REFRESH_SECRET=$(openssl rand -base64 32)
```

### 3. Déployer

```bash
# Linux/macOS
./deploy.sh

# Windows PowerShell
.\deploy.ps1
```

### 4. Vérifier

```bash
# Tester l'API
curl http://localhost/health

# Ouvrir dans le navigateur
open http://localhost
```

---

## Déploiement pas à pas

### Étape 1 : Vérification des prérequis

```bash
# Script de vérification
docker --version || echo "❌ Docker non installé"
docker compose version || echo "❌ Docker Compose non installé"
```

### Étape 2 : Configuration des secrets

**IMPORTANT** : Ne jamais utiliser les secrets par défaut en production !

```bash
# Générer des secrets forts (32+ caractères)
openssl rand -base64 32  # Pour JWT_SECRET
openssl rand -base64 32  # Pour JWT_REFRESH_SECRET
```

Éditer `.env` :
```bash
JWT_SECRET=<secret-généré-1>
JWT_REFRESH_SECRET=<secret-généré-2>
```

### Étape 3 : Configuration du port

Par défaut, TappPlus utilise le port 80. Pour changer :

```bash
# .env
HTTP_PORT=8080  # Ou tout autre port disponible
```

Puis modifier `docker-compose.yml` :
```yaml
ports:
  - "${HTTP_PORT:-8080}:80"
```

### Étape 4 : Build de l'image

```bash
# Build sans cache (recommandé pour production)
docker compose build --no-cache

# Build normal (plus rapide)
docker compose build
```

Durée estimée : 5-10 minutes selon la connexion

### Étape 5 : Démarrage des conteneurs

```bash
# Démarrer en arrière-plan
docker compose up -d

# Suivre les logs pendant le démarrage
docker compose logs -f
```

Attendre environ 30 secondes que tous les services démarrent.

### Étape 6 : Vérification du déploiement

```bash
# Vérifier les conteneurs
docker compose ps

# Vérifier les processus PM2
docker exec tappplus-app pm2 status

# Tester le health endpoint
curl http://localhost/health
```

Résultat attendu :
```
healthy
```

---

## Configuration production

### Sécurité

#### 1. Changer les secrets JWT

```bash
# .env
JWT_SECRET=un-secret-tres-long-et-complexe-32-caracteres-minimum
JWT_REFRESH_SECRET=un-autre-secret-different-32-caracteres-minimum
```

#### 2. Configurer HTTPS (recommandé)

**Option A : Nginx externe + Certbot**

```bash
# Installer Nginx sur l'hôte
sudo apt install nginx certbot python3-certbot-nginx

# Configurer le domaine
sudo nano /etc/nginx/sites-available/tappplus

# Contenu :
server {
    server_name votredomaine.com;

    location / {
        proxy_pass http://localhost:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# Activer
sudo ln -s /etc/nginx/sites-available/tappplus /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

# Obtenir certificat SSL
sudo certbot --nginx -d votredomaine.com
```

**Option B : Cloudflare (recommandé)**
- Plus simple
- SSL automatique
- Protection DDoS gratuite
- CDN global

#### 3. Configurer un firewall

```bash
# UFW (Ubuntu)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

### Performance

#### 1. Augmenter les limites de fichiers

```bash
# /etc/security/limits.conf
* soft nofile 65536
* hard nofile 65536
```

#### 2. Optimiser Docker

```bash
# /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}

sudo systemctl restart docker
```

---

## Initialisation de la base de données

### Première initialisation

Le script de déploiement initialise automatiquement la base de données.

Pour initialiser manuellement :

```bash
# Sans données de test
docker exec tappplus-app node scripts/init-db.js

# Avec données de test
docker exec tappplus-app node scripts/init-db.js --seed
```

### Charger des données de test

```bash
# Script de seeding
docker exec tappplus-app node scripts/seed-db.js
```

Cela crée :
- 1 utilisateur admin : `admin@tappplus.com` / `Admin123!`
- 3 organisations
- 50 patients
- 20 consultations
- 10 interventions programmées

### Migrations Prisma

```bash
# Appliquer les migrations
docker exec tappplus-app npx prisma migrate deploy

# Générer le client Prisma
docker exec tappplus-app npx prisma generate

# Reset complet (⚠️ DANGER : supprime toutes les données)
docker exec tappplus-app npx prisma migrate reset
```

---

## Gestion des processus

### PM2 Status

```bash
# Voir l'état des processus
docker exec tappplus-app pm2 status

# Voir les logs
docker exec tappplus-app pm2 logs

# Logs d'un processus spécifique
docker exec tappplus-app pm2 logs api
docker exec tappplus-app pm2 logs web
```

### Redémarrer des processus

```bash
# Redémarrer tous les processus
docker exec tappplus-app pm2 restart all

# Redémarrer un processus spécifique
docker exec tappplus-app pm2 restart api
docker exec tappplus-app pm2 restart web
docker exec tappplus-app pm2 restart worker
```

### Arrêt et démarrage

```bash
# Arrêter l'application
docker compose down

# Démarrer l'application
docker compose up -d

# Redémarrer l'application
docker compose restart
```

---

## Sauvegarde et restauration

### Sauvegarde automatique

```bash
# Script de sauvegarde journalière
#!/bin/bash
BACKUP_DIR="/backups/tappplus"
DATE=$(date +%Y%m%d_%H%M%S)

# Créer le répertoire de backup
mkdir -p $BACKUP_DIR

# Copier la base de données
docker exec tappplus-app sqlite3 /app/data/meditache.db ".backup '/tmp/backup.db'"
docker cp tappplus-app:/tmp/backup.db $BACKUP_DIR/meditache_$DATE.db

# Compression
gzip $BACKUP_DIR/meditache_$DATE.db

# Nettoyage (garder 30 jours)
find $BACKUP_DIR -name "*.gz" -mtime +30 -delete

echo "✅ Backup créé : meditache_$DATE.db.gz"
```

Configurer un cron :
```bash
# Éditer crontab
crontab -e

# Ajouter (backup quotidien à 2h du matin)
0 2 * * * /path/to/backup-script.sh
```

### Restauration

```bash
# Arrêter l'application
docker compose down

# Décompresser le backup
gunzip meditache_20251021_020000.db.gz

# Copier dans le volume Docker
docker run --rm -v tappplus_data:/data -v $(pwd):/backup \
  alpine cp /backup/meditache_20251021_020000.db /data/meditache.db

# Redémarrer
docker compose up -d
```

---

## Mise à jour

### Mise à jour mineure (sans changement de schéma)

```bash
# Récupérer la dernière version
git pull origin main

# Rebuild et redéployer
docker compose down
docker compose build --no-cache
docker compose up -d
```

### Mise à jour majeure (avec migrations)

```bash
# Sauvegarder d'abord !
./backup-script.sh

# Récupérer la nouvelle version
git pull origin main

# Rebuild
docker compose build --no-cache

# Démarrer
docker compose up -d

# Appliquer les migrations
docker exec tappplus-app npx prisma migrate deploy
```

### Rollback en cas de problème

```bash
# Arrêter la nouvelle version
docker compose down

# Revenir à la version précédente
git checkout <version-précédente>

# Restaurer le backup
# (voir section Restauration)

# Redémarrer
docker compose up -d
```

---

## Monitoring

### Logs

```bash
# Logs Docker
docker compose logs -f --tail=100

# Logs PM2
docker exec tappplus-app pm2 logs --lines 100

# Logs Nginx
docker exec tappplus-app tail -f /app/logs/nginx-access.log
docker exec tappplus-app tail -f /app/logs/nginx-error.log

# Logs API
docker exec tappplus-app tail -f /app/logs/api-out.log
docker exec tappplus-app tail -f /app/logs/api-error.log
```

### Métriques

```bash
# Utilisation ressources Docker
docker stats tappplus-app

# Espace disque
docker exec tappplus-app df -h

# Taille de la base de données
docker exec tappplus-app du -h /app/data/meditache.db

# PM2 Monitoring
docker exec tappplus-app pm2 monit
```

### Health checks

```bash
# Script de monitoring
#!/bin/bash
API_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/health)

if [ $API_HEALTH -eq 200 ]; then
    echo "✅ Application healthy"
else
    echo "❌ Application down - HTTP $API_HEALTH"
    # Envoyer alerte (email, SMS, etc.)
fi
```

### Alertes (optionnel)

Intégration avec :
- **Uptime Robot** - Monitoring gratuit
- **Sentry** - Error tracking
- **Datadog** - APM complet
- **Prometheus + Grafana** - Métriques avancées

---

## Déploiement multi-environnement

### Développement local

```bash
# .env.development
NODE_ENV=development
HTTP_PORT=3000
```

### Staging

```bash
# .env.staging
NODE_ENV=staging
HTTP_PORT=8080
DATABASE_URL=file:/app/data/meditache-staging.db
```

### Production

```bash
# .env.production
NODE_ENV=production
HTTP_PORT=80
# Secrets forts, services configurés
```

---

## Checklist de déploiement

Avant de mettre en production :

- [ ] Secrets JWT changés
- [ ] Variables d'environnement configurées
- [ ] HTTPS configuré
- [ ] Firewall activé
- [ ] Backup automatique configuré
- [ ] Monitoring en place
- [ ] Tests effectués
- [ ] Documentation à jour
- [ ] Accès SSH sécurisé
- [ ] Logs configurés

---

**Dernière mise à jour :** 2025-10-21
