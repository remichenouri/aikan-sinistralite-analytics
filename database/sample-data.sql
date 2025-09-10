-- Génération des contrats
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
WHERE a.assure_id <= 15000;

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
