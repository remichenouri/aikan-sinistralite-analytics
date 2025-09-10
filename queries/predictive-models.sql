-- Modèle de scoring des risques
UPDATE assures a
SET score_risque = (
    SELECT 
        LEAST(5.0, GREATEST(1.0,
        -- Base sur historique sinistres
        CASE 
            WHEN COUNT(s.sinistre_id) = 0 THEN 1.0
            WHEN COUNT(s.sinistre_id) BETWEEN 1 AND 2 THEN 2.5
            WHEN COUNT(s.sinistre_id) BETWEEN 3 AND 5 THEN 4.0
            ELSE 5.0
        END +
        -- Ajustement âge
        CASE 
            WHEN a.age BETWEEN 25 AND 50 THEN 0.0
            WHEN a.age < 25 OR a.age > 65 THEN 0.5
            ELSE 0.2
        END +
        -- Bonus fidélité
        CASE 
            WHEN a.anciennete_client > 5 THEN -0.3
            ELSE 0.1
        END))
    FROM contrats c
    LEFT JOIN sinistres s ON c.contrat_id = s.contrat_id
    WHERE c.assure_id = a.assure_id
);

-- Analyse précision des provisions
CREATE VIEW analyse_precision_provisions AS
WITH provision_accuracy AS (
    SELECT 
        sinistre_id,
        type_sinistre,
        provision,
        cout_reel,
        ABS(provision - cout_reel) as ecart_provision,
        ROUND(ABS(provision - cout_reel) / GREATEST(cout_reel, 1) * 100, 2) as ecart_pourcentage,
        CASE 
            WHEN ABS(provision - cout_reel) / GREATEST(cout_reel, 1) < 0.1 THEN 'EXCELLENT'
            WHEN ABS(provision - cout_reel) / GREATEST(cout_reel, 1) < 0.2 THEN 'BON'
            WHEN ABS(provision - cout_reel) / GREATEST(cout_reel, 1) < 0.3 THEN 'MOYEN'
            ELSE 'A_AMELIORER'
        END as precision_provision
    FROM sinistres 
    WHERE statut = 'CLOS' AND cout_reel > 0 AND provision > 0
)
SELECT 
    type_sinistre,
    precision_provision,
    COUNT(*) as nb_sinistres,
    ROUND(AVG(ecart_provision), 2) as ecart_moyen,
    ROUND(AVG(ecart_pourcentage), 2) as ecart_pourcentage_moyen,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY type_sinistre) * 100, 1) as pourcentage
FROM provision_accuracy
GROUP BY type_sinistre, precision_provision
ORDER BY type_sinistre, precision_provision;
