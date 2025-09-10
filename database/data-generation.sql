-- Procédure pour générer des assurés
DELIMITER //
CREATE PROCEDURE GenerateAssures(IN nb_records INT)
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE random_nom VARCHAR(100);
    DECLARE random_prenom VARCHAR(100);
    
    WHILE i < nb_records DO
        INSERT INTO assures (
            civilite, nom, prenom, age, profession, code_postal, 
            anciennete_client, score_risque
        ) VALUES (
            ELT(FLOOR(1 + RAND() * 2), 'M', 'Mme'),
            CONCAT('Nom', LPAD(i, 5, '0')),
            CONCAT('Prenom', LPAD(i, 5, '0')),
            FLOOR(18 + RAND() * 62),
            ELT(FLOOR(1 + RAND() * 10), 'Cadre', 'Employé', 'Ouvrier', 'Retraité', 'Étudiant', 'Artisan', 'Commerçant', 'Profession libérale', 'Fonctionnaire', 'Sans profession'),
            LPAD(FLOOR(10000 + RAND() * 89999), 5, '0'),
            FLOOR(1 + RAND() * 15),
            ROUND(1.0 + RAND() * 4.0, 2)
        );
        SET i = i + 1;
    END WHILE;
END //
DELIMITER ;

-- Appel de la procédure
CALL GenerateAssures(10000);
-- Copiez-collez ceci dans MySQL command line :

INSERT INTO contrats (assure_id, type_contrat, prime_annuelle, franchise, somme_assuree, date_souscription, statut)
SELECT 
    a.assure_id,
    ELT(FLOOR(1 + RAND() * 4), 'AUTO', 'MRH', 'MRP', 'RC_PRO'),
    ROUND(300 + RAND() * 2000, 2),
    ROUND(150 + RAND() * 500, 2),
    ROUND(10000 + RAND() * 500000, 2),
    DATE_SUB(CURDATE(), INTERVAL FLOOR(RAND() * 1095) DAY),
    ELT(FLOOR(1 + RAND() * 10), 'ACTIF', 'ACTIF', 'ACTIF', 'ACTIF', 'ACTIF', 'ACTIF', 'ACTIF', 'RESILIE', 'SUSPENDU', 'ACTIF')
FROM assures a
WHERE a.assure_id <= 7500
UNION ALL
SELECT 
    a.assure_id,
    ELT(FLOOR(1 + RAND() * 4), 'AUTO', 'MRH', 'MRP', 'RC_PRO'),
    ROUND(300 + RAND() * 2000, 2),
    ROUND(150 + RAND() * 500, 2),
    ROUND(10000 + RAND() * 500000, 2),
    DATE_SUB(CURDATE(), INTERVAL FLOOR(RAND() * 1095) DAY),
    ELT(FLOOR(1 + RAND() * 10), 'ACTIF', 'ACTIF', 'ACTIF', 'ACTIF', 'ACTIF', 'ACTIF', 'ACTIF', 'RESILIE', 'SUSPENDU', 'ACTIF')
FROM assures a
WHERE a.assure_id > 7500 AND RAND() < 0.6;

-- Vérification
SELECT 'contrats générés' as status, COUNT(*) as nb_contrats FROM contrats;
-- Génération des sinistres (25% des contrats ont des sinistres)
INSERT INTO sinistres (contrat_id, date_declaration, type_sinistre, cause_sinistre, cout_estime, cout_reel, provision, statut, delai_reglement, gestionnaire_id)
SELECT 
    c.contrat_id,
    DATE_ADD(c.date_souscription, INTERVAL FLOOR(RAND() * 365) DAY),
    ELT(FLOOR(1 + RAND() * 8), 'Collision', 'Vol', 'Incendie', 'Dégât des eaux', 'Bris de glace', 'Catastrophe naturelle', 'Vandalisme', 'Autre'),
    ELT(FLOOR(1 + RAND() * 6), 'Accident de la route', 'Négligence', 'Intempéries', 'Défaillance matérielle', 'Acte de malveillance', 'Cause inconnue'),
    ROUND(500 + RAND() * 15000, 2),
    ROUND(400 + RAND() * 18000, 2),
    ROUND(450 + RAND() * 16000, 2),
    ELT(FLOOR(1 + RAND() * 6), 'CLOS', 'CLOS', 'CLOS', 'EN_COURS', 'OUVERT', 'CONTESTE'),
    FLOOR(15 + RAND() * 120),
    FLOOR(1 + RAND() * 20)
FROM contrats c
WHERE RAND() < 0.25;

-- Vérification
SELECT 'sinistres générés' as status, COUNT(*) as nb_sinistres FROM sinistres;
-- Génération des événements timeline (3-5 événements par sinistre)
INSERT INTO timeline_sinistres (sinistre_id, date_evenement, type_evenement, description, acteur)
SELECT 
    s.sinistre_id,
    DATE_ADD(s.date_declaration, INTERVAL FLOOR(RAND() * s.delai_reglement) DAY),
    ELT(FLOOR(1 + RAND() * 6), 'DECLARATION', 'EXPERTISE', 'PROVISION', 'REGLEMENT', 'APPEL', 'EMAIL'),
    CONCAT('Événement ', ELT(FLOOR(1 + RAND() * 5), 'initial', 'intermédiaire', 'de suivi', 'de clôture', 'administratif')),
    ELT(FLOOR(1 + RAND() * 4), 'Expert', 'Gestionnaire', 'Client', 'Système')
FROM sinistres s
CROSS JOIN (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) numbers
WHERE RAND() < 0.8;

-- Vérification finale
SELECT 'timeline générés' as status, COUNT(*) as nb_events FROM timeline_sinistres;
