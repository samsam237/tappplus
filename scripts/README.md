# TappPlus - Scripts Utilitaires

Collection de scripts pour faciliter le déploiement et la configuration de TappPlus.

---

## 📜 Scripts Disponibles

### 1. generate-secrets.js (Node.js)

Génère des secrets JWT cryptographiquement sécurisés pour l'authentification.

#### Utilisation

```bash
# Format par défaut (coloré et formaté)
node scripts/generate-secrets.js

# Format .env (pour copier-coller directement)
node scripts/generate-secrets.js --env

# Format Docker Compose
node scripts/generate-secrets.js --docker

# Format Dockploy
node scripts/generate-secrets.js --dockploy

# Tous les formats
node scripts/generate-secrets.js --all

# Aide
node scripts/generate-secrets.js --help
```

#### Exemple de sortie

```bash
$ node scripts/generate-secrets.js

✓ Secure JWT Secrets Generated!
──────────────────────────────────────────────────────────────────────

Copy these secrets to your .env file:

JWT_SECRET=KLaURZOWDZhV7dg6x2dcx364bA+UzrKxna5/cYd5YvM=
JWT_REFRESH_SECRET=j4gIsj3GE5RBuX44/ggSX26fQDVKowQTi8Yfr/3JKjo=

──────────────────────────────────────────────────────────────────────

Security Recommendations:

  1. ✓ Never commit .env file to Git
  2. ✓ Use different secrets for staging and production
  3. ✓ Rotate secrets periodically (every 90 days)
  4. ✓ Store production secrets in a password manager
  5. ✓ Never share secrets via email or chat
```

---

### 2. generate-secrets.ps1 (PowerShell)

Version PowerShell du générateur de secrets (pour Windows).

#### Utilisation

```powershell
# Format par défaut
.\scripts\generate-secrets.ps1

# Format .env
.\scripts\generate-secrets.ps1 -Format env

# Format Docker Compose
.\scripts\generate-secrets.ps1 -Format docker

# Format Dockploy
.\scripts\generate-secrets.ps1 -Format dockploy

# Tous les formats
.\scripts\generate-secrets.ps1 -Format all
```

#### Note pour Windows

Si vous rencontrez l'erreur "Execution of scripts is disabled on this system", exécutez :

```powershell
# Option 1 : Bypass temporaire
powershell -ExecutionPolicy Bypass -File .\scripts\generate-secrets.ps1

# Option 2 : Changer la politique (Admin requis)
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

### 3. init-db.js

Initialise la base de données SQLite avec le schéma Prisma et les données de seed (optionnel).

#### Utilisation

```bash
# Initialiser sans données de test
node scripts/init-db.js

# Initialiser avec données de test (seed)
node scripts/init-db.js --seed

# Réinitialiser complètement (supprime et recrée)
node scripts/init-db.js --force

# Afficher l'aide
node scripts/init-db.js --help
```

#### Options

- `--seed` : Ajoute des données de démonstration (utilisateurs, patients, interventions)
- `--force` : Supprime la base existante avant de recréer
- `--help` : Affiche l'aide

---

## 🔐 Génération de Secrets JWT

### Pourquoi générer des secrets sécurisés ?

Les secrets JWT sont utilisés pour :
1. **Signer les tokens d'accès** (JWT_SECRET) - Durée de vie : 15 minutes
2. **Signer les tokens de rafraîchissement** (JWT_REFRESH_SECRET) - Durée de vie : 7 jours

**IMPORTANT** : Utilisez des secrets différents et forts en production !

### Méthodes alternatives

#### Avec OpenSSL (Linux/Mac)

```bash
# Générer JWT_SECRET
openssl rand -base64 32

# Générer JWT_REFRESH_SECRET
openssl rand -base64 32
```

#### Avec Node.js en une ligne

```bash
node -e "console.log('JWT_SECRET=' + require('crypto').randomBytes(32).toString('base64'))"
node -e "console.log('JWT_REFRESH_SECRET=' + require('crypto').randomBytes(32).toString('base64'))"
```

#### Avec Python

```python
import secrets
import base64

jwt_secret = base64.b64encode(secrets.token_bytes(32)).decode('utf-8')
jwt_refresh_secret = base64.b64encode(secrets.token_bytes(32)).decode('utf-8')

print(f"JWT_SECRET={jwt_secret}")
print(f"JWT_REFRESH_SECRET={jwt_refresh_secret}")
```

---

## 🛡️ Bonnes Pratiques de Sécurité

### Gestion des Secrets

1. **Ne jamais commiter les secrets** dans Git
   ```bash
   # Vérifier que .env est dans .gitignore
   cat .gitignore | grep .env
   ```

2. **Utiliser des secrets différents** par environnement
   ```
   Development:   JWT_SECRET=dev_secret_123...
   Staging:       JWT_SECRET=staging_secret_456...
   Production:    JWT_SECRET=prod_secret_789...
   ```

3. **Stocker les secrets de production** de manière sécurisée
   - Password manager (1Password, Bitwarden, LastPass)
   - Vault (HashiCorp Vault)
   - Cloud Secret Manager (AWS Secrets Manager, Azure Key Vault, GCP Secret Manager)

4. **Rotation des secrets** (recommandé tous les 90 jours)
   ```bash
   # Générer de nouveaux secrets
   node scripts/generate-secrets.js --env > .env.new

   # Comparer avec l'ancien
   diff .env .env.new

   # Remplacer après validation
   mv .env .env.backup
   mv .env.new .env

   # Redémarrer l'application
   docker compose restart
   ```

5. **Ne jamais partager via email/chat**
   - Utilisez des outils de partage sécurisé (1Password Shared Vaults, etc.)
   - Ou partagez en personne

### Audit de Sécurité

```bash
# Vérifier qu'aucun secret n'est commité
git log --all -p | grep -i "jwt_secret"

# Scanner le repository pour des secrets
# Installer truffleHog
docker run --rm -v "$PWD:/src" trufflesecurity/trufflehog:latest filesystem /src

# Ou utiliser git-secrets
git secrets --scan
```

---

## 🚀 Workflow de Déploiement

### 1. Local Development

```bash
# 1. Cloner le projet
git clone https://github.com/YOUR_USERNAME/tappplus
cd tappplus

# 2. Générer les secrets
node scripts/generate-secrets.js --env > .env

# 3. Éditer .env pour ajouter d'autres variables si nécessaire
nano .env

# 4. Initialiser la base de données
node scripts/init-db.js --seed

# 5. Démarrer en développement
npm run dev
```

### 2. Docker Compose Deployment

```bash
# 1. Générer les secrets pour production
node scripts/generate-secrets.js --docker

# 2. Ajouter dans docker-compose.yml sous environment:

# 3. Build et déployer
docker compose build
docker compose up -d

# 4. Initialiser la DB
docker exec tappplus-app node scripts/init-db.js --seed
```

### 3. Dockploy Deployment

```bash
# 1. Générer les secrets
node scripts/generate-secrets.js --dockploy

# 2. Dans l'interface Dockploy :
#    - Environment Variables → Add Variable
#    - Copier-coller les secrets générés

# 3. Deploy depuis l'interface Dockploy
```

---

## 📝 Scripts Personnalisés

### Créer votre propre script

Les scripts dans ce dossier utilisent Node.js. Pour créer un nouveau script :

```javascript
#!/usr/bin/env node

// Votre code ici
console.log('Hello from custom script!');

// Accès aux modules du projet
const path = require('path');
const fs = require('fs');

// Accès à la configuration
const envPath = path.join(__dirname, '..', '.env');
if (fs.existsSync(envPath)) {
  require('dotenv').config({ path: envPath });
}

// Vos fonctions ici
async function main() {
  // ...
}

main();
```

### Rendre le script exécutable (Linux/Mac)

```bash
chmod +x scripts/your-script.js

# Exécuter
./scripts/your-script.js
```

---

## 🆘 Dépannage

### Erreur : "Cannot find module 'crypto'"

Le module `crypto` est intégré à Node.js. Vérifiez votre version :

```bash
node --version  # Doit être >= 18.0.0
```

### Erreur PowerShell : "Execution of scripts is disabled"

```powershell
# Solution temporaire
powershell -ExecutionPolicy Bypass -File .\scripts\generate-secrets.ps1

# Solution permanente (en tant qu'Admin)
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Les secrets générés ne fonctionnent pas

1. **Vérifier qu'ils sont bien dans .env**
   ```bash
   cat .env | grep JWT_SECRET
   ```

2. **Vérifier qu'il n'y a pas d'espaces**
   ```env
   # ❌ Incorrect
   JWT_SECRET = abc123...

   # ✅ Correct
   JWT_SECRET=abc123...
   ```

3. **Redémarrer l'application**
   ```bash
   docker compose restart
   ```

---

## 📚 Documentation

- **Guide complet de déploiement** : [DEPLOYMENT.md](../DEPLOYMENT.md)
- **Guide Dockploy** : [DOCKPLOY.md](../DOCKPLOY.md)
- **README principal** : [README.md](../README.md)

---

**TappPlus Scripts - Simplifiant le Déploiement** 🚀
