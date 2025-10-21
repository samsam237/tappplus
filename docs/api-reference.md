# Référence API TappPlus

Documentation complète de l'API REST TappPlus.

## 📖 Table des matières

1. [Introduction](#introduction)
2. [Authentification](#authentification)
3. [Endpoints](#endpoints)
   - [Auth](#auth)
   - [Organizations](#organizations)
   - [People (Patients)](#people-patients)
   - [Consultations](#consultations)
   - [Interventions](#interventions)
   - [Reminders](#reminders)
   - [Notifications](#notifications)
4. [Codes de réponse](#codes-de-réponse)
5. [Gestion des erreurs](#gestion-des-erreurs)

---

## Introduction

### URL de base

```
http://votre-domaine.com/api/v1
```

### Format des réponses

Toutes les réponses sont au format JSON.

**Succès :**
```json
{
  "id": "clx123abc",
  "name": "Exemple"
}
```

**Erreur :**
```json
{
  "statusCode": 400,
  "message": "Validation failed",
  "error": "Bad Request"
}
```

### Documentation interactive

Swagger UI disponible à :
```
http://votre-domaine.com/api/docs
```

---

## Authentification

### JWT Bearer Token

Toutes les routes (sauf login/register) requièrent un token JWT.

**Header requis :**
```
Authorization: Bearer <access_token>
```

### Obtenir un token

**Endpoint :** `POST /api/v1/auth/login`

**Request :**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response :**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "clx123",
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "role": "DOCTOR"
  }
}
```

### Rafraîchir un token

**Endpoint :** `POST /api/v1/auth/refresh`

**Request :**
```json
{
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response :**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": { ... }
}
```

---

## Endpoints

### Auth

#### Inscription

```http
POST /api/v1/auth/register
```

**Request Body :**
```json
{
  "email": "newuser@example.com",
  "password": "SecurePass123!",
  "firstName": "Jane",
  "lastName": "Smith",
  "role": "DOCTOR"
}
```

**Response:** `201 Created`
```json
{
  "id": "clx456",
  "email": "newuser@example.com",
  "firstName": "Jane",
  "lastName": "Smith",
  "role": "DOCTOR"
}
```

#### Profil utilisateur

```http
GET /api/v1/auth/profile
Authorization: Bearer <token>
```

**Response:** `200 OK`
```json
{
  "id": "clx123",
  "email": "user@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "role": "DOCTOR"
}
```

---

### Organizations

#### Lister les organisations

```http
GET /api/v1/organizations
Authorization: Bearer <token>
```

**Response:** `200 OK`
```json
[
  {
    "id": "org1",
    "name": "Hôpital Central",
    "type": "HOSPITAL",
    "address": "123 Rue Principale",
    "phone": "+237600000000",
    "email": "contact@hospital.cm"
  }
]
```

#### Obtenir une organisation

```http
GET /api/v1/organizations/:id
Authorization: Bearer <token>
```

#### Statistiques d'une organisation

```http
GET /api/v1/organizations/:id/stats
Authorization: Bearer <token>
```

**Response:** `200 OK`
```json
{
  "totalPatients": 150,
  "totalConsultations": 320,
  "totalInterventions": 45,
  "activeReminders": 12
}
```

#### Créer une organisation

```http
POST /api/v1/organizations
Authorization: Bearer <token>
```

**Request Body :**
```json
{
  "name": "Clinique Nouvelle",
  "type": "CLINIC",
  "address": "456 Avenue Santé",
  "phone": "+237600000001",
  "email": "info@clinic.cm"
}
```

#### Mettre à jour

```http
PATCH /api/v1/organizations/:id
Authorization: Bearer <token>
```

#### Supprimer

```http
DELETE /api/v1/organizations/:id
Authorization: Bearer <token>
```

---

### People (Patients)

#### Lister les patients

```http
GET /api/v1/people
Authorization: Bearer <token>
```

**Query Parameters :**
- `search` (string) : Recherche par nom/email/téléphone
- `organizationId` (string) : Filtrer par organisation
- `page` (number) : Numéro de page (défaut: 1)
- `limit` (number) : Résultats par page (défaut: 50)

**Exemple :**
```
GET /api/v1/people?search=dupont&page=1&limit=20
```

**Response:** `200 OK`
```json
{
  "data": [
    {
      "id": "person1",
      "firstName": "Marie",
      "lastName": "Dupont",
      "dateOfBirth": "1985-05-15T00:00:00.000Z",
      "phone": "+237677777777",
      "email": "marie.dupont@example.com",
      "address": "789 Rue Liberté",
      "bloodType": "O+",
      "medicalNotes": "Allergique à la pénicilline"
    }
  ],
  "meta": {
    "total": 1,
    "page": 1,
    "limit": 20
  }
}
```

#### Obtenir un patient

```http
GET /api/v1/people/:id
Authorization: Bearer <token>
```

#### Créer un patient

```http
POST /api/v1/people
Authorization: Bearer <token>
```

**Request Body :**
```json
{
  "firstName": "Paul",
  "lastName": "Martin",
  "dateOfBirth": "1990-12-25",
  "phone": "+237688888888",
  "email": "paul.martin@example.com",
  "address": "321 Avenue Paix",
  "bloodType": "A+",
  "medicalNotes": "Diabète de type 2"
}
```

#### Mettre à jour un patient

```http
PATCH /api/v1/people/:id
Authorization: Bearer <token>
```

#### Supprimer un patient

```http
DELETE /api/v1/people/:id
Authorization: Bearer <token>
```

#### Associer à une organisation

```http
POST /api/v1/people/:id/organizations/:organizationId
Authorization: Bearer <token>
```

#### Dissocier d'une organisation

```http
DELETE /api/v1/people/:id/organizations/:organizationId
Authorization: Bearer <token>
```

---

### Consultations

#### Lister les consultations

```http
GET /api/v1/consultations
Authorization: Bearer <token>
```

**Query Parameters :**
- `personId` (string) : Filtrer par patient
- `doctorId` (string) : Filtrer par médecin
- `startDate` (ISO date) : Date de début
- `endDate` (ISO date) : Date de fin

#### Historique d'un patient

```http
GET /api/v1/consultations/history/:personId
Authorization: Bearer <token>
```

**Query Parameters :**
- `doctorId` (string) : Filtrer par médecin

**Response:** `200 OK`
```json
[
  {
    "id": "consult1",
    "date": "2025-10-15T10:00:00.000Z",
    "reason": "Contrôle annuel",
    "diagnosis": "Bon état général",
    "treatment": "Aucun traitement",
    "notes": "Revoir dans 1 an",
    "person": { ... },
    "doctor": { ... }
  }
]
```

#### Créer une consultation

```http
POST /api/v1/consultations
Authorization: Bearer <token>
```

**Request Body :**
```json
{
  "personId": "person1",
  "doctorId": "doctor1",
  "date": "2025-10-21T14:30:00.000Z",
  "reason": "Douleurs abdominales",
  "diagnosis": "Gastrite",
  "treatment": "Omeprazole 20mg, 2x/jour",
  "notes": "Revoir si symptômes persistent après 7 jours"
}
```

#### Mettre à jour une consultation

```http
PATCH /api/v1/consultations/:id
Authorization: Bearer <token>
```

#### Supprimer une consultation

```http
DELETE /api/v1/consultations/:id
Authorization: Bearer <token>
```

---

### Interventions

#### Lister les interventions

```http
GET /api/v1/interventions
Authorization: Bearer <token>
```

**Query Parameters :**
- `personId` (string)
- `organizationId` (string)
- `type` (string)
- `status` (string) : SCHEDULED | COMPLETED | CANCELLED
- `startDate` (ISO date)
- `endDate` (ISO date)

#### Interventions à venir

```http
GET /api/v1/interventions/upcoming
Authorization: Bearer <token>
```

**Query Parameters :**
- `days` (number) : Nombre de jours (défaut: 7)

**Response:** `200 OK`
```json
[
  {
    "id": "interv1",
    "type": "SURGERY",
    "scheduledAt": "2025-10-25T09:00:00.000Z",
    "description": "Appendicectomie",
    "status": "SCHEDULED",
    "person": {
      "id": "person1",
      "firstName": "Marie",
      "lastName": "Dupont"
    },
    "organization": {
      "id": "org1",
      "name": "Hôpital Central"
    }
  }
]
```

#### Créer une intervention

```http
POST /api/v1/interventions
Authorization: Bearer <token>
```

**Request Body :**
```json
{
  "type": "SURGERY",
  "scheduledAt": "2025-11-05T08:00:00.000Z",
  "personId": "person1",
  "organizationId": "org1",
  "description": "Opération du genou",
  "notes": "Patient à jeun",
  "reminders": [
    {
      "type": "EMAIL",
      "daysBefore": 7
    },
    {
      "type": "SMS",
      "daysBefore": 1
    }
  ]
}
```

**Response:** `201 Created`
```json
{
  "id": "interv2",
  "type": "SURGERY",
  "scheduledAt": "2025-11-05T08:00:00.000Z",
  "description": "Opération du genou",
  "status": "SCHEDULED",
  "person": { ... },
  "organization": { ... },
  "reminders": [
    {
      "id": "rem1",
      "type": "EMAIL",
      "scheduledAt": "2025-10-29T08:00:00.000Z",
      "status": "SCHEDULED"
    },
    {
      "id": "rem2",
      "type": "SMS",
      "scheduledAt": "2025-11-04T08:00:00.000Z",
      "status": "SCHEDULED"
    }
  ]
}
```

#### Mettre à jour une intervention

```http
PATCH /api/v1/interventions/:id
Authorization: Bearer <token>
```

#### Supprimer une intervention

```http
DELETE /api/v1/interventions/:id
Authorization: Bearer <token>
```

---

### Reminders

#### Lister les rappels

```http
GET /api/v1/reminders
Authorization: Bearer <token>
```

**Query Parameters :**
- `interventionId` (string)
- `status` (string) : SCHEDULED | SENT | FAILED | CONFIRMED
- `type` (string) : EMAIL | SMS | PUSH

**Response:** `200 OK`
```json
[
  {
    "id": "rem1",
    "type": "EMAIL",
    "scheduledAt": "2025-10-29T08:00:00.000Z",
    "status": "SCHEDULED",
    "sentAt": null,
    "intervention": { ... }
  }
]
```

#### Statistiques des rappels

```http
GET /api/v1/reminders/stats
Authorization: Bearer <token>
```

**Query Parameters :**
- `startDate` (ISO date)
- `endDate` (ISO date)

**Response:** `200 OK`
```json
{
  "total": 150,
  "byStatus": {
    "SCHEDULED": 50,
    "SENT": 80,
    "FAILED": 15,
    "CONFIRMED": 5
  },
  "byType": {
    "EMAIL": 60,
    "SMS": 70,
    "PUSH": 20
  },
  "successRate": 0.90
}
```

#### Réessayer un rappel échoué

```http
POST /api/v1/reminders/:id/retry
Authorization: Bearer <token>
```

**Response:** `200 OK`
```json
{
  "id": "rem1",
  "status": "SCHEDULED",
  "scheduledAt": "2025-10-21T12:00:00.000Z"
}
```

#### Créer un rappel manuel

```http
POST /api/v1/reminders
Authorization: Bearer <token>
```

**Request Body :**
```json
{
  "interventionId": "interv1",
  "type": "SMS",
  "scheduledAt": "2025-10-22T14:00:00.000Z"
}
```

#### Mettre à jour un rappel

```http
PATCH /api/v1/reminders/:id
Authorization: Bearer <token>
```

#### Supprimer un rappel

```http
DELETE /api/v1/reminders/:id
Authorization: Bearer <token>
```

---

### Notifications

#### Statistiques des notifications

```http
GET /api/v1/notifications/stats
Authorization: Bearer <token>
```

**Query Parameters :**
- `interventionId` (string)

#### Tester l'envoi d'email

```http
POST /api/v1/notifications/test/email
Authorization: Bearer <token>
```

**Request Body :**
```json
{
  "to": "test@example.com"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "messageId": "msg_123xyz"
}
```

#### Tester l'envoi de SMS

```http
POST /api/v1/notifications/test/sms
Authorization: Bearer <token>
```

**Request Body :**
```json
{
  "to": "+237600000000"
}
```

#### Tester notification push

```http
POST /api/v1/notifications/test/push
Authorization: Bearer <token>
```

**Request Body :**
```json
{
  "token": "fcm_device_token_here"
}
```

---

## Codes de réponse

| Code | Description |
|------|-------------|
| **200** | OK - Requête réussie |
| **201** | Created - Ressource créée |
| **204** | No Content - Suppression réussie |
| **400** | Bad Request - Données invalides |
| **401** | Unauthorized - Non authentifié |
| **403** | Forbidden - Non autorisé |
| **404** | Not Found - Ressource introuvable |
| **409** | Conflict - Conflit (ex: email déjà utilisé) |
| **422** | Unprocessable Entity - Validation échouée |
| **429** | Too Many Requests - Rate limit dépassé |
| **500** | Internal Server Error - Erreur serveur |

---

## Gestion des erreurs

### Format standard

```json
{
  "statusCode": 400,
  "message": "Validation failed",
  "error": "Bad Request",
  "details": [
    {
      "field": "email",
      "message": "email must be an email"
    }
  ]
}
```

### Erreur d'authentification

```json
{
  "statusCode": 401,
  "message": "Invalid credentials",
  "error": "Unauthorized"
}
```

### Erreur de validation

```json
{
  "statusCode": 422,
  "message": "Validation failed",
  "error": "Unprocessable Entity",
  "details": [
    {
      "field": "firstName",
      "message": "firstName should not be empty"
    },
    {
      "field": "email",
      "message": "email must be an email"
    }
  ]
}
```

### Rate limiting

```json
{
  "statusCode": 429,
  "message": "Too many requests",
  "error": "Too Many Requests",
  "retryAfter": 60
}
```

---

## Exemples d'utilisation

### cURL

```bash
# Login
curl -X POST http://localhost/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"password123"}'

# Obtenir les patients (avec token)
curl -X GET http://localhost/api/v1/people \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

# Créer une intervention
curl -X POST http://localhost/api/v1/interventions \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "type":"SURGERY",
    "scheduledAt":"2025-11-05T08:00:00Z",
    "personId":"person1",
    "organizationId":"org1"
  }'
```

### JavaScript (Axios)

```javascript
import axios from 'axios';

const api = axios.create({
  baseURL: 'http://localhost/api/v1',
});

// Interceptor pour ajouter le token
api.interceptors.request.use(config => {
  const token = localStorage.getItem('access_token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Login
const { data } = await api.post('/auth/login', {
  email: 'admin@example.com',
  password: 'password123',
});
localStorage.setItem('access_token', data.access_token);

// Obtenir les patients
const { data: patients } = await api.get('/people');

// Créer une intervention
const { data: intervention } = await api.post('/interventions', {
  type: 'SURGERY',
  scheduledAt: '2025-11-05T08:00:00Z',
  personId: 'person1',
  organizationId: 'org1',
});
```

---

**Dernière mise à jour :** 2025-10-21
**Version API :** v1
