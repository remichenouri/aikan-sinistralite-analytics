-- Endpoint : GET /sinistres/stats
DELIMITER //
CREATE PROCEDURE GetSinistresStats(IN periode VARCHAR(10))
BEGIN
    DECLARE date_debut DATE;
    
    CASE periode 
        WHEN 'month' THEN SET date_debut = DATE_SUB(CURDATE(), INTERVAL 1 MONTH);
        WHEN 'quarter' THEN SET date_debut = DATE_SUB(CURDATE(), INTERVAL 3 MONTH);
        WHEN 'year' THEN SET date_debut = DATE_SUB(CURDATE(), INTERVAL 1 YEAR);
        ELSE SET date_debut = DATE_SUB(CURDATE(), INTERVAL 1 MONTH);
    END CASE;
    
    SELECT 
        type_sinistre,
        COUNT(*) as volume,
        ROUND(AVG(cout_reel), 2) as cout_moyen,
        ROUND(SUM(cout_reel), 2) as cout_total,
        ROUND(AVG(delai_reglement), 1) as delai_moyen
    FROM sinistres 
    WHERE date_declaration >= date_debut
        AND statut IN ('CLOS', 'EN_COURS')
    GROUP BY type_sinistre
    ORDER BY cout_total DESC;
END //

-- Endpoint : GET /contrats/portfolio
CREATE PROCEDURE GetPortfolioAnalysis()
BEGIN
    SELECT 
        c.type_contrat,
        COUNT(*) as nb_contrats,
        ROUND(SUM(prime_annuelle), 2) as primes_totales,
        ROUND(AVG(prime_annuelle), 2) as prime_moyenne,
        COUNT(DISTINCT a.assure_id) as nb_assures_uniques,
        ROUND(AVG(a.score_risque), 2) as score_risque_moyen
    FROM contrats c
    JOIN assures a ON c.assure_id = a.assure_id
    WHERE c.statut = 'ACTIF'
    GROUP BY c.type_contrat
    ORDER BY primes_totales DESC;
END //

-- Endpoint : POST /predictions/risk-score
CREATE PROCEDURE PredictRiskScore(
    IN p_age INT, 
    IN p_profession VARCHAR(100),
    IN p_anciennete INT,
    IN p_type_contrat VARCHAR(10)
)
BEGIN
    DECLARE predicted_score DECIMAL(3,2);
    
    -- Algorithme simplifié de prédiction
    SET predicted_score = (
        -- Base score
        2.5 +
        -- Age factor
        CASE 
            WHEN p_age BETWEEN 25 AND 50 THEN 0.0
            WHEN p_age < 25 THEN 0.8
            WHEN p_age > 65 THEN 0.6
            ELSE 0.3
        END +
        -- Profession factor
        CASE 
            WHEN p_profession IN ('Fonctionnaire', 'Cadre') THEN -0.3
            WHEN p_profession IN ('Étudiant', 'Ouvrier') THEN 0.4
            ELSE 0.0
        END +
        -- Ancienneté factor
        CASE 
            WHEN p_anciennete > 5 THEN -0.4
            WHEN p_anciennete < 2 THEN 0.3
            ELSE 0.0
        END +
        -- Type contrat factor
        CASE 
            WHEN p_type_contrat = 'AUTO' THEN 0.2
            WHEN p_type_contrat = 'RC_PRO' THEN -0.1
            ELSE 0.0
        END
    );
    
    SET predicted_score = LEAST(5.0, GREATEST(1.0, predicted_score));
    
    SELECT 
        predicted_score as score_predit,
        CASE 
            WHEN predicted_score < 2.0 THEN 'FAIBLE'
            WHEN predicted_score < 3.5 THEN 'MOYEN'
            WHEN predicted_score < 4.5 THEN 'ELEVE'
            ELSE 'TRES_ELEVE'
        END as niveau_risque,
        'Prédiction basée sur profil statistique' as methode;
END //
DELIMITER ;
