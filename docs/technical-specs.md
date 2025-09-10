# Spécifications Techniques - Aikan Sinistralité Analytics

## Architecture Système

### Infrastructure
- **Base de données** : MySQL 8.0+
- **Moteur de stockage** : InnoDB
- **Encodage** : UTF-8
- **Collation** : utf8mb4_unicode_ci

### Structure de Données

#### Tables Principales
assures (10 000 enregistrements)
├── assure_id (PK, AUTO_INCREMENT)
├── civilite (ENUM: M, Mme)
├── nom, prenom (VARCHAR)
├── age (INT, INDEX)
├── profession (VARCHAR)
├── code_postal (CHAR(5))
├── anciennete_client (INT)
├── score_risque (DECIMAL(3,2), INDEX)
contrats (15 000 enregistrements)
├── contrat_id (PK, AUTO_INCREMENT)
├── assure_id (FK → assures)
├── type_contrat (ENUM: AUTO, MRH, MRP, RC_PRO, INDEX)
├── prime_annuelle (DECIMAL(10,2))
├── franchise (DECIMAL(8,2))
├── somme_assuree (DECIMAL(12,2))
├── date_souscription (DATE)
sinistres (25 000 enregistrements)
├── sinistre_id (PK, AUTO_INCREMENT)
├── contrat_id (FK → contrats)
├── date_declaration (DATE, INDEX)
├── type_sinistre (VARCHAR(50))
├── cause_sinistre (VARCHAR(100))
├── cout_estime (DECIMAL(10,2))
├── cout_reel (DECIMAL(10,2))
├── provision (DECIMAL(10,2))
├── statut (ENUM: OUVERT, EN_COURS, CLOS, CONTESTE, INDEX)
├── delai_reglement (INT)
timeline_sinistres (100 000+ enregistrements)
├── timeline_id (PK, AUTO_INCREMENT)
├── sinistre_id (FK → sinistres)
├── date_evenement (DATETIME)
├── type_evenement (ENUM: DECLARATION, EXPERTISE, PROVISION, REGLEMENT, APPEL, EMAIL)
├── description (TEXT)

### Optimisation des Performances

#### Index Composites
-- Performance des requêtes analytiques
CREATE INDEX idx_sinistres_analytics ON sinistres(statut, date_declaration, type_sinistre);
CREATE INDEX idx_contrats_analytics ON contrats(statut, type_contrat, assure_id);

#### Vues Matérialisées (Simulées)
-- Cache des KPI temps réel
CREATE TABLE dashboard_cache AS

-- Procédure de refresh automatique
DELIMITER //
CREATE EVENT refresh_dashboard_cache
ON SCHEDULE EVERY 15 MINUTE
DO CALL RefreshDashboardCache();
//


### API Simulation Framework

#### Endpoints Disponibles
-- GET /sinistres/stats/{periode}
CALL GetSin

-- GET /contrats/portfolio
C

-- POST /predictions/risk-score
CALL PredictRiskScore(age, profes

-- GET /gestionnaires/performance
C

-- GET /provisions/accuracy
C


### Algorithmes Métier

#### Score de Risque Client
score_risque = base_score + age_factor + profession_factor + anciennete_factor + historique_factor

Où :

base_score = 2.5

age_factor = [-0.3, +0.8] selon tranche d'âge

profession_factor = [-0.3, +0.4] selon métier

anciennete_factor = [-0.4, +0.3] selon fidélité

historique_factor = [1.0, 5.0] selon sinistralité passée


#### Optimisation Affectation Dossiers
charge_optimale = CASE
WHEN performance_score > 0.8 THEN dossiers_actuels
1.2 WHEN performance_score > 0.6 THEN dossiers_actu
ls * 1.1 ELSE dossiers_
performance_score = (taux_cloture * 0.4) + ((100 - delai_moyen_normalise) * 0.3) + (precision_estimation * 0.3)


### Métriques de Performance

#### Temps de Réponse Cibles
- **Requêtes KPI** : < 500ms
- **Analyses prédictives** : < 2s
- **Génération de rapports** : < 5s
- **Procédures complexes** : < 10s

#### Volumétrie Supportée
- **Assurés** : 100 000+
- **Contrats** : 150 000+
- **Sinistres** : 500 000+
- **Événements timeline** : 2 000 000+

### Intégration Sydia

#### Points d'Intégration
Data Sources:

Sydia API (40 endpoints)

Base contrats existante

Système de gestion sinistres

Timeline événements

Data Flow:
Extract → Transform → Load → Analyz

Real-time Updates:

Trigger-based updates

Batch processing (nightly)

Event-driven refresh

### Sécurité et Conformité

#### Accès aux Données
- **Authentification** : MySQL users avec privileges limités
- **Audit trail** : Logs des requêtes sens```es
- **Anonymisation** : Masquage des données personn```es en développ```nt
- **RGPD** : Respect du droit à l'oubli via```océdures dé```es

#### Backup et Recovery
- **Backup quotidien** : mysqldump automatisé
- **Point-in-time recovery** : Binary logs activés
- **Tests de restauration** : Procédure```nsuelle

### Roadmap Technique

#### Phase 1 - POC (3 mois)
- ✅ Structure de données
- ✅ Requêtes analytiques
- ✅ Procédures stockées
- ✅ Tests de performance

#### Phase 2 - Intégration (2 mois)
- [ ] Connexion APIs Sydia
- [ ] ETL automatisé
- [ ] Interface utilisateur
- [ ] Tests d'intégration

#### Phase 3 - Production (1 mois)
- [ ] Monitoring avancé
- [ ] Alertes métier
- [ ] Formation utilisateurs
- [ ] Documentation complète