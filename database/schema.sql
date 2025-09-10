-- Création de la base de données
CREATE DATABASE aikan_analytics;
USE aikan_analytics;

-- Table Assurés
CREATE TABLE assures (
    assure_id INT PRIMARY KEY AUTO_INCREMENT,
    civilite ENUM('M', 'Mme'),
    nom VARCHAR(100),
    prenom VARCHAR(100),
    age INT,
    profession VARCHAR(100),
    code_postal VARCHAR(5),
    anciennete_client INT,
    score_risque DECIMAL(3,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_age (age),
    INDEX idx_score_risque (score_risque)
);

-- Table Contrats
CREATE TABLE contrats (
    contrat_id INT PRIMARY KEY AUTO_INCREMENT,
    assure_id INT,
    type_contrat ENUM('AUTO', 'MRH', 'MRP', 'RC_PRO'),
    prime_annuelle DECIMAL(10,2),
    franchise DECIMAL(8,2),
    somme_assuree DECIMAL(12,2),
    date_souscription DATE,
    statut ENUM('ACTIF', 'RESILIE', 'SUSPENDU'),
    FOREIGN KEY (assure_id) REFERENCES assures(assure_id),
    INDEX idx_type_contrat (type_contrat),
    INDEX idx_statut (statut)
);

-- Table Sinistres
CREATE TABLE sinistres (
    sinistre_id INT PRIMARY KEY AUTO_INCREMENT,
    contrat_id INT,
    date_declaration DATE,
    type_sinistre VARCHAR(50),
    cause_sinistre VARCHAR(100),
    cout_estime DECIMAL(10,2),
    cout_reel DECIMAL(10,2),
    provision DECIMAL(10,2),
    statut ENUM('OUVERT', 'EN_COURS', 'CLOS', 'CONTESTE'),
    delai_reglement INT,
    gestionnaire_id INT,
    FOREIGN KEY (contrat_id) REFERENCES contrats(contrat_id),
    INDEX idx_statut (statut),
    INDEX idx_date_declaration (date_declaration)
);

-- Table Timeline
CREATE TABLE timeline_sinistres (
    timeline_id INT PRIMARY KEY AUTO_INCREMENT,
    sinistre_id INT,
    date_evenement DATETIME,
    type_evenement ENUM('DECLARATION', 'EXPERTISE', 'PROVISION', 'REGLEMENT', 'APPEL', 'EMAIL'),
    description TEXT,
    acteur VARCHAR(50),
    FOREIGN KEY (sinistre_id) REFERENCES sinistres(sinistre_id)
);
