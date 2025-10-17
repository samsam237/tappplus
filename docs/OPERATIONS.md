# 8. Exploitation (Monitoring, Backups, SRE)

## 8.1 Monitoring
- `docker logs -f tappplus`
- Healthcheck `/api/health`
- Intégration Prometheus/Grafana via sidecar (option)

## 8.2 Backups
- Volume `/data` (SQLite) à sauvegarder
- Stratégie : quotidien + rétention 7/30 j

## 8.3 Scalabilité
- Mono-nœud suffisant (SQLite). Pour HA → Postgres géré, plusieurs réplicas applicatifs
- CDN statique (images/assets)

## 8.4 Incident response
- Rollback : redeployer image précédente
- Restaurer DB : remettre fichier `dev.db` depuis backup
