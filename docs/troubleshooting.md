# Guide de Dépannage TappPlus

Solutions aux problèmes courants et guide de débogage.

## 📖 Table des matières

1. [Problèmes de déploiement](#problèmes-de-déploiement)
2. [Erreurs réseau et connectivité](#erreurs-réseau-et-connectivité)
3. [Problèmes de base de données](#problèmes-de-base-de-données)
4. [Erreurs d'authentification](#erreurs-dauthentification)
5. [Problèmes de notifications](#problèmes-de-notifications)
6. [Performance et lenteur](#performance-et-lenteur)
7. [Logs et débogage](#logs-et-débogage)
8. [FAQ](#faq)

---

## Problèmes de déploiement

### ❌ Erreur : "docker: command not found"

**Cause :** Docker n'est pas installé

**Solution :**
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install docker.io docker-compose-plugin

# Vérifier
docker --version
```

### ❌ Erreur : "Permission denied" lors de docker compose

**Cause :** Utilisateur pas dans le groupe docker

**Solution :**
```bash
# Ajouter l'utilisateur au groupe docker
sudo usermod -aG docker $USER

# Redémarrer la session
newgrp docker

# Ou se déconnecter/reconnecter
```

### ❌ Erreur : "Port 80 already in use"

**Cause :** Un autre service utilise le port 80

**Solution :**
```bash
# Identifier le processus
sudo lsof -i :80
# Ou
sudo netstat -tulpn | grep :80

# Option 1 : Arrêter le service
sudo systemctl stop nginx  # Ou apache2

# Option 2 : Changer le port TappPlus
# Dans .env
HTTP_PORT=8080

# Dans docker-compose.yml
ports:
  - "${HTTP_PORT:-8080}:80"
```

### ❌ Build Docker échoue avec "network timeout"

**Cause :** Problème de connexion réseau

**Solution :**
```bash
# Augmenter le timeout npm
docker compose build --build-arg NPM_TIMEOUT=300000

# Ou modifier le Dockerfile
RUN npm config set fetch-timeout 300000
```

---

## Erreurs réseau et connectivité

### ❌ Erreur 502 Bad Gateway

**Causes possibles :**
1. Processus backend non démarrés
2. Configuration nginx incorrecte
3. Ports internes incorrects

**Diagnostic :**
```bash
# 1. Vérifier les processus PM2
docker exec tappplus-app pm2 status

# 2. Vérifier les logs
docker exec tappplus-app pm2 logs --lines 50

# 3. Tester les backends directement
docker exec tappplus-app curl http://127.0.0.1:5550/api/v1/health
docker exec tappplus-app curl http://127.0.0.1:5500
```

**Solutions :**
```bash
# Si processus crashés
docker exec tappplus-app pm2 restart all

# Si problème de configuration
docker compose down
docker compose build --no-cache
docker compose up -d
```

### ❌ CORS Error dans le navigateur

**Erreur :** "Access to fetch at '...' has been blocked by CORS policy"

**Solution :**
```bash
# Vérifier la configuration CORS dans .env
CORS_ORIGINS=

# Ou spécifier les origines
CORS_ORIGINS=https://votredomaine.com,https://app.votredomaine.com

# Redémarrer
docker compose restart
```

### ❌ Cannot connect to Redis

**Erreur :** "Error: connect ECONNREFUSED 127.0.0.1:6379"

**Diagnostic :**
```bash
# Vérifier que Redis tourne
docker exec tappplus-app pm2 status | grep redis

# Tester la connexion Redis
docker exec tappplus-app redis-cli ping
# Doit retourner : PONG
```

**Solution :**
```bash
# Redémarrer Redis
docker exec tappplus-app pm2 restart redis

# Vérifier les logs
docker exec tappplus-app pm2 logs redis
```

---

## Problèmes de base de données

### ❌ Database locked

**Erreur :** "SQLITE_BUSY: database is locked"

**Cause :** Écriture concurrente dépassant les capacités SQLite

**Solution immédiate :**
```bash
# Redémarrer l'application
docker compose restart
```

**Solution à long terme :**
- Migrer vers PostgreSQL si > 1000 écritures/min
- Optimiser les requêtes (utiliser transactions)
- Augmenter le timeout SQLite

### ❌ Migrations Prisma échouent

**Erreur :** "Migration failed to apply"

**Solution :**
```bash
# Voir l'état des migrations
docker exec tappplus-app npx prisma migrate status

# Appliquer les migrations en attente
docker exec tappplus-app npx prisma migrate deploy

# En dernier recours (⚠️ perte de données)
docker exec tappplus-app npx prisma migrate reset
```

### ❌ Base de données corrompue

**Symptômes :** Erreurs SQLite aléatoires, crashs fréquents

**Diagnostic :**
```bash
# Vérifier l'intégrité
docker exec tappplus-app sqlite3 /app/data/meditache.db "PRAGMA integrity_check;"
# Doit retourner : ok
```

**Solution :**
```bash
# Si corruption détectée, restaurer depuis backup
docker compose down
# Restaurer le backup (voir deployment.md)
docker compose up -d
```

---

## Erreurs d'authentification

### ❌ "Invalid credentials" lors du login

**Cause :** Email/mot de passe incorrect

**Solution :**
```bash
# Réinitialiser le mot de passe admin via console
docker exec -it tappplus-app node
> const { PrismaClient } = require('@prisma/client');
> const bcrypt = require('bcryptjs');
> const prisma = new PrismaClient();
> const password = await bcrypt.hash('NewPassword123!', 10);
> await prisma.user.update({
    where: { email: 'admin@tappplus.com' },
    data: { password }
  });
> process.exit();
```

### ❌ "Token expired" immédiatement après login

**Cause :** Différence d'horloge serveur/client

**Solution :**
```bash
# Synchroniser l'horloge serveur
sudo timedatectl set-ntp true
sudo systemctl restart systemd-timesyncd

# Vérifier
date
```

### ❌ JWT malformed

**Cause :** Secret JWT changé, tokens existants invalides

**Solution :**
- Normal après changement de secrets
- Les utilisateurs doivent se reconnecter
- Vider le localStorage (côté client)

---

## Problèmes de notifications

### ❌ Emails ne partent pas (SendGrid)

**Diagnostic :**
```bash
# Tester l'envoi
curl -X POST http://localhost/api/v1/notifications/test/email \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{"to": "votre-email@example.com"}'
```

**Solutions :**
1. Vérifier la clé API SendGrid
2. Vérifier que l'email expéditeur est validé
3. Consulter les logs SendGrid : https://app.sendgrid.com/email_activity

**Logs :**
```bash
docker exec tappplus-app pm2 logs api | grep -i "sendgrid\|email"
```

### ❌ SMS ne partent pas (Twilio)

**Vérifications :**
```bash
# Vérifier les credentials
echo $TWILIO_ACCOUNT_SID
echo $TWILIO_AUTH_TOKEN
echo $TWILIO_PHONE_NUMBER

# Vérifier le solde Twilio Console
# https://console.twilio.com/
```

**Erreur courante :** "Unverified number"
- En mode test Twilio, seuls les numéros vérifiés reçoivent les SMS
- Passer en mode production après tests

### ❌ Push notifications ne fonctionnent pas

**Checklist :**
- [ ] Credentials Firebase corrects
- [ ] Token FCM valide côté client
- [ ] Service account a les permissions
- [ ] Le device token n'a pas expiré

---

## Performance et lenteur

### ❌ Application lente

**Diagnostic :**
```bash
# Vérifier l'utilisation CPU/RAM
docker stats tappplus-app

# Vérifier l'espace disque
docker exec tappplus-app df -h

# Vérifier la taille de la DB
docker exec tappplus-app du -h /app/data/meditache.db
```

**Solutions :**

**Si CPU élevé :**
```bash
# Vérifier les processus
docker exec tappplus-app pm2 monit

# Redémarrer les processus gourmands
docker exec tappplus-app pm2 restart api
```

**Si RAM saturée :**
```bash
# Augmenter la RAM allouée à Docker
# Docker Desktop → Settings → Resources → Memory

# Ou limiter la mémoire PM2
# Dans ecosystem.config.js
max_memory_restart: '500M'
```

**Si disque plein :**
```bash
# Nettoyer les logs
docker exec tappplus-app pm2 flush

# Nettoyer Docker
docker system prune -a
```

### ❌ Requêtes API lentes

**Diagnostic :**
```bash
# Activer les logs de requêtes lentes
LOG_LEVEL=debug

# Analyser les requêtes
docker exec tappplus-app pm2 logs api | grep "slow"
```

**Solutions :**
- Ajouter des index sur colonnes fréquemment requêtées
- Utiliser la pagination
- Activer le cache Redis
- Optimiser les requêtes Prisma (include, select)

---

## Logs et débogage

### Accéder aux logs

```bash
# Logs Docker
docker compose logs -f --tail=100

# Logs PM2 (tous)
docker exec tappplus-app pm2 logs --lines 100

# Logs d'un processus spécifique
docker exec tappplus-app pm2 logs api --lines 50
docker exec tappplus-app pm2 logs web --lines 50
docker exec tappplus-app pm2 logs worker --lines 50

# Logs Nginx
docker exec tappplus-app tail -f /app/logs/nginx-access.log
docker exec tappplus-app tail -f /app/logs/nginx-error.log
```

### Augmenter le niveau de logs

```bash
# Dans .env
LOG_LEVEL=debug

# Redémarrer
docker compose restart
```

### Exporter les logs pour analyse

```bash
# Tous les logs PM2
docker exec tappplus-app pm2 logs --raw > logs_$(date +%Y%m%d).txt

# Logs nginx
docker exec tappplus-app cat /app/logs/nginx-error.log > nginx_errors.txt
```

---

## FAQ

### Comment réinitialiser complètement l'application ?

```bash
# ⚠️ ATTENTION : Supprime toutes les données
docker compose down -v
docker compose up -d
docker exec tappplus-app node scripts/init-db.js --seed
```

### Comment changer le port HTTP ?

```bash
# Dans .env
HTTP_PORT=8080

# Dans docker-compose.yml
ports:
  - "${HTTP_PORT:-8080}:80"

# Redéployer
docker compose down
docker compose up -d
```

### Comment accéder à la base de données ?

```bash
# SQLite CLI
docker exec -it tappplus-app sqlite3 /app/data/meditache.db

# Prisma Studio (GUI)
docker exec -it tappplus-app npx prisma studio
# Ouvrir http://localhost:5555
```

### Comment sauvegarder manuellement ?

```bash
# Backup de la DB
docker exec tappplus-app sqlite3 /app/data/meditache.db ".backup '/tmp/backup.db'"
docker cp tappplus-app:/tmp/backup.db ./backup_$(date +%Y%m%d).db
```

### Comment voir les requêtes SQL exécutées ?

```bash
# Activer les logs Prisma
# Dans apps/api/src/common/prisma/prisma.service.ts
log: ['query', 'info', 'warn', 'error']

# Rebuild et redémarrer
docker compose build
docker compose restart
```

### L'application ne démarre pas, que faire ?

```bash
# 1. Vérifier les logs
docker compose logs --tail=50

# 2. Vérifier les processus
docker exec tappplus-app pm2 status

# 3. Restart complet
docker compose down
docker compose up -d

# 4. Rebuild si nécessaire
docker compose build --no-cache
docker compose up -d
```

### Comment tester si tout fonctionne ?

```bash
# Health check
curl http://localhost/health

# Test API
curl http://localhost/api/v1/organizations

# PM2 status
docker exec tappplus-app pm2 status

# Tous les processus doivent être "online"
```

---

## Support technique

Si vous ne trouvez pas de solution :

1. Consultez les logs complets
2. Vérifiez la [documentation technique](./architecture.md)
3. Créez une issue sur GitHub avec :
   - Version de TappPlus
   - Logs d'erreur complets
   - Étapes pour reproduire
   - Configuration système

---

**Dernière mise à jour :** 2025-10-21
