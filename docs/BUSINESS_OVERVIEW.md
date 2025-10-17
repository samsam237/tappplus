# 9. Documentation non technique (Business)

## 9.1 Valeur proposée
- **Simplicité** : interface légère pour gérer une liste de patients.
- **Rapidité** : déploiement en 5 minutes via Docker.
- **Évolutivité** : base prête à intégrer des modules médicaux (interventions, rappels).

## 9.2 Cas d’usage
- PMV de gestion patient minimal
- Démonstration produit pour futurs modules (rappels, notifications, tableau de bord médical)

## 9.3 Rôles (ciblage futur)
- **Administrateur** : pilotage organisation, utilisateurs
- **Médecin/Personnel** : gestion patients, interventions, rappels
- **Direction** : reporting

## 9.4 Roadmap conseillée
1. **Sécurité/Accès** : ajouter authentification & rôles
2. **Données** : étendre modèle (Intervention, Reminder, Audit)
3. **Flux** : rappels automatiques (email/sms), journaux d’envoi
4. **Observabilité** : métriques, traces
5. **Conformité** : RGPD (consentement, minimisation, portabilité)

## 9.5 Indicateurs business (exemples)
- Temps moyen d’enregistrement patient
- Taux de rappels envoyés / reçus
- Délai médian avant intervention
