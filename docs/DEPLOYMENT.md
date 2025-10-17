# 3. Déploiement & Ops

## 3.1 Build & Run (image seule)
```bash
docker build -t tappplus:latest .
docker run -d --name tappplus   -p 3000:3000   -e DATABASE_URL=file:/data/dev.db   -e PORT=3000   -v tappplus_data:/data   tappplus:latest
curl http://localhost:3000/api/health
```

## 3.2 docker-compose
```yaml
services:
  tappplus:
    build: .
    image: tappplus:latest
    ports: ["3000:3000"]
    environment:
      - DATABASE_URL=file:/data/dev.db
      - PORT=3000
    volumes:
      - tappplus_data:/data
volumes:
  tappplus_data:
```

## 3.3 Reverse proxy (recommandé)
- Nginx/Caddy/Traefik
- Ouvrir seulement 80/443
- Proxy vers `http://127.0.0.1:3000`

## 3.4 Variables d’environnement
- `DATABASE_URL=file:/data/dev.db`
- `PORT=3000`

## 3.5 Stratégie de migration
- `prisma migrate deploy` au démarrage
- Rebuild image après modification du schéma

## 3.6 Sauvegardes
- Sauvegarder le volume `/data` (fichier `dev.db`)
- Stratégie : snapshot quotidien + rétention 7/30 jours
