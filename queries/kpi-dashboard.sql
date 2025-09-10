-- 1. Analyse de Sinistralité par Portefeuille
CREATE VIEW vue_sinistralite_portefeuille AS
SELECT 
    c.type_contrat,
    COUNT(s.sinistre_id) as nb_sinistres,
    COUNT(DISTINCT c.contrat_id) as nb_contrats,
    SUM(c.prime_annuelle) as primes_totales,
    SUM(s.cout_reel) as sinistres_totaux,
    ROUND(SUM(s.cout_reel) / SUM(c.prime_annuelle) * 100, 2) as ratio_SP,
    CASE 
        WHEN ROUND(SUM(s.cout_reel) / SUM(c.prime_annuelle) * 100, 2) > 80 THEN '🔴 ALERTE'
        WHEN ROUND(SUM(s.cout_reel) / SUM(c.prime_annuelle) * 100, 2) > 60 THEN '🟡 SURVEILLANCE'
        ELSE '🟢 OK'
    END as statut_risque
FROM contrats c
LEFT JOIN sinistres s ON c.contrat_id = s.contrat_id AND s.statut = 'CLOS'
WHERE c.statut = 'ACTIF'
GROUP BY c.type_contrat
ORDER BY ratio_SP DESC;

-- 2. Performance des Gestionnaires
CREATE VIEW vue_performance_gestionnaires AS
SELECT 
    gestionnaire_id,
    COUNT(*) as dossiers_traites,
    AVG(delai_reglement) as delai_moyen,
    SUM(CASE WHEN statut = 'CLOS' THEN 1 ELSE 0 END) as dossiers_clos,
    ROUND(SUM(CASE WHEN statut = 'CLOS' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) as taux_cloture,
    AVG(cout_reel) as cout_moyen,
    RANK() OVER (ORDER BY AVG(delai_reglement) ASC) as rang_delai,
    RANK() OVER (ORDER BY SUM(CASE WHEN statut = 'CLOS' THEN 1 ELSE 0 END) / COUNT(*) DESC) as rang_cloture
FROM sinistres
WHERE gestionnaire_id IS NOT NULL
GROUP BY gestionnaire_id
HAVING dossiers_traites >= 10
ORDER BY taux_cloture DESC, delai_moyen ASC;

-- 3. Dashboard KPI Temps Réel
CREATE VIEW dashboard_kpi AS
SELECT 
    'SINISTRES_MOIS' as kpi,
    COUNT(*) as valeur,
    'sinistres' as unite,
    DATE_FORMAT(CURDATE(), '%Y-%m') as periode
FROM sinistres 
WHERE date_declaration >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
UNION ALL
SELECT 
    'RATIO_SP_GLOBAL' as kpi,
    ROUND(SUM(s.cout_reel) / SUM(c.prime_annuelle) * 100, 1) as valeur,
    '%' as unite,
    'Global' as periode
FROM contrats c
LEFT JOIN sinistres s ON c.contrat_id = s.contrat_id AND s.statut = 'CLOS'
WHERE c.statut = 'ACTIF';
