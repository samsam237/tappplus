# 6. Référence API

Base URL : `https://<host>`

## 6.1 Health
`GET /api/health` → `{ ok: true }`

## 6.2 People
### GET `/api/people`
- 200: `[{ id, firstName, lastName, createdAt }]`

### POST `/api/people`
- **JSON**:
  ```json
  { "firstName": "Ada", "lastName": "Lovelace" }
  ```
- **Form-data**: `firstName`, `lastName`
- 201: objet créé
- 400: `Invalid` si champs manquants

> Sécurité: aucun contrôle par défaut (template). À durcir avant exposition publique.
