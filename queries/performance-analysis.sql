-- =========================================
-- PERFORMANCE ANALYSIS - AIKAN ANALYTICS
-- Analyse complète des performances système
-- Auteur: Rémi Chenouri
-- Date: Septembre 2025
-- =========================================

-- 1. ANALYSE DES TEMPS D'EXECUTION
-- =========================================

-- Benchmark des requêtes principales
SELECT 
    'Analyse Sinistralité Portefeuille' as requete,
    COUNT(*) as nb_resultats,
    BENCHMARK(1000, (
        SELECT COUNT(*) FROM vue_sinistralite_portefeuille
    )) as performance_score
FROM vue_sinistralite_portefeuille
UNION ALL
SELECT 
    'Performance Gestionnaires' as requete,
    COUNT(*) as nb_resultats,
    BENCHMARK(1000, (
        SELECT COUNT(*) FROM vue_performance_gestionnaires
    )) as performance_score
FROM vue_performance_gestionnaires;

-- 2. ANALYSE DE L'UTILISATION DES INDEX
-- =========================================

-- Vérification de l'efficacité des index
EXPLAIN FORMAT=JSON
SELECT 
    c.type_contrat,
    COUNT(s.sinistre_id) as nb_sinistres,
    SUM(s.cout_reel) as cout_total,
    ROUND(SUM(s.cout_reel) / SUM(c.prime_annuelle) * 100, 2) as ratio_SP
FROM contrats c
LEFT JOIN sinistres s ON c.contrat_id = s.contrat_id AND s.statut = 'CLOS'
WHERE c.statut = 'ACTIF'
GROUP BY c.type_contrat;

-- Analyse des index manquants potentiels
SELECT 
    table_name,
    column_name,
    cardinality,
    CASE WHEN cardinality > 1000 THEN 'INDEX_RECOMMANDE' ELSE 'INDEX_OPTIONNEL' END as recommandation
FROM information_schema.statistics
WHERE table_schema = 'aikan_analytics'
ORDER BY cardinality DESC;

-- 3. OPTIMISATION DES JOINTURES
-- =========================================

-- Performance des jointures complexes
SET profiling = 1;

-- Requête optimisée avec index hints
SELECT /*+ USE_INDEX(c, idx_contrats_composite) USE_INDEX(s, idx_sinistres_analytics) */
    c.type_contrat,
    s.type_sinistre,
    COUNT(*) as nb_occurrences,
    AVG(s.delai_reglement) as delai_moyen,
    SUM(s.cout_reel) as cout_total
FROM contrats c
INNER JOIN sinistres s ON c.contrat_id = s.contrat_id
WHERE c.statut = 'ACTIF' 
    AND s.statut IN ('CLOS', 'EN_COURS')
    AND s.date_declaration >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
GROUP BY c.type_contrat, s.type_sinistre
ORDER BY cout_total DESC;

SHOW PROFILES;
SET profiling = 0;

-- 4. ANALYSE DE LA CARDINALITE DES DONNEES
-- =========================================

-- Distribution des données pour optimisation
SELECT 
    'assures' as table_name,
    'age' as colonne,
    MIN(age) as valeur_min,
    MAX(age) as valeur_max,
    AVG(age) as valeur_moyenne,
    COUNT(DISTINCT age) as cardinalite
FROM assures
UNION ALL
SELECT 
    'sinistres' as table_name,
    'cout_reel' as colonne,
    MIN(cout_reel) as valeur_min,
    MAX(cout_reel) as valeur_max,
    AVG(cout_reel) as valeur_moyenne,
    COUNT(DISTINCT ROUND(cout_reel, -2)) as cardinalite
FROM sinistres
WHERE cout_reel > 0;

-- 5. SURVEILLANCE DES PERFORMANCES TEMPS REEL
-- =========================================

-- Vue de monitoring des requêtes lentes
CREATE VIEW monitoring_performances AS
SELECT 
    SUBSTRING(sql_text, 1, 100) as requete_tronquee,
    exec_count as nb_executions,
    avg_timer_wait/1000000 as temps_moyen_ms,
    max_timer_wait/1000000 as temps_max_ms,
    sum_lock_time/1000000 as temps_attente_total_ms,
    sum_rows_examined as lignes_examinees_total,
    sum_rows_sent as lignes_retournees_total
FROM performance_schema.events_statements_summary_by_digest
WHERE db = 'aikan_analytics'
    AND avg_timer_wait/1000000 > 100  -- Requêtes > 100ms
ORDER BY avg_timer_wait DESC
LIMIT 20;

-- 6. PROCEDURES D'OPTIMISATION AUTOMATIQUE
-- =========================================

DELIMITER //
CREATE PROCEDURE OptimizePerformances()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE table_name VARCHAR(64);
    DECLARE cur CURSOR FOR 
        SELECT TABLE_NAME FROM information_schema.tables 
        WHERE table_schema = 'aikan_analytics' AND table_type = 'BASE TABLE';
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    -- Mise à jour des statistiques
    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO table_name;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        SET @sql = CONCAT('ANALYZE TABLE ', table_name);
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        
    END LOOP;
    CLOSE cur;
    
    -- Nettoyage du cache de requêtes
    RESET QUERY CACHE;
    
    -- Mise à jour du cache des KPI
    CALL RefreshDashboardCache();
    
    SELECT 'Optimisation terminée' as status, NOW() as timestamp;
END //
DELIMITER ;

-- 7. TESTS DE CHARGE
-- =========================================

-- Simulation de charge avec requêtes concurrentes
DELIMITER //
CREATE PROCEDURE TestCharge(IN nb_iterations INT)
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE start_time TIMESTAMP DEFAULT NOW();
    
    WHILE i <= nb_iterations DO
        -- Test requête complexe
        SELECT COUNT(*) INTO @result 
        FROM vue_sinistralite_portefeuille v1
        JOIN vue_performance_gestionnaires v2 ON v1.type_contrat = 'AUTO';
        
        -- Test procédure stockée
        CALL GetSinistresStats('month');
        
        SET i = i + 1;
    END WHILE;
    
    SELECT 
        nb_iterations as iterations_executees,
        TIMESTAMPDIFF(MICROSECOND, start_time, NOW())/1000 as temps_total_ms,
        ROUND(TIMESTAMPDIFF(MICROSECOND, start_time, NOW())/1000/nb_iterations, 2) as temps_moyen_par_iteration_ms;
END //
DELIMITER ;

-- 8. RAPPORT DE PERFORMANCE GLOBAL
-- =========================================

-- Vue synthétique des performances
CREATE VIEW rapport_performance_global AS
SELECT 
    'Base de données' as composant,
    ROUND(
        (SELECT SUM(data_length + index_length) / 1024 / 1024 
         FROM information_schema.tables 
         WHERE table_schema = 'aikan_analytics'), 2
    ) as taille_mb,
    (SELECT COUNT(*) FROM assures) as nb_assures,
    (SELECT COUNT(*) FROM contrats) as nb_contrats,
    (SELECT COUNT(*) FROM sinistres) as nb_sinistres,
    (SELECT COUNT(*) FROM timeline_sinistres) as nb_events,
    ROUND(
        (SELECT AVG(avg_timer_wait/1000000) 
         FROM performance_schema.events_statements_summary_by_digest 
         WHERE db = 'aikan_analytics'), 2
    ) as temps_reponse_moyen_ms;

-- Affichage du rapport final
SELECT * FROM rapport_performance_global;

-- 9. RECOMMANDATIONS D'OPTIMISATION
-- =========================================

SELECT 
    'RECOMMANDATIONS PERFORMANCE' as titre,
    CASE 
        WHEN (SELECT temps_reponse_moyen_ms FROM rapport_performance_global) < 100 
        THEN '✅ Performance excellente'
        WHEN (SELECT temps_reponse_moyen_ms FROM rapport_performance_global) < 500 
        THEN '🟡 Performance correcte - optimisations mineures possibles'
        ELSE '🔴 Performance à améliorer - optimisations requises'
    END as evaluation_globale,
    CONCAT(
        'Taille base: ', 
        (SELECT taille_mb FROM rapport_performance_global), 
        ' MB | Temps moyen: ', 
        (SELECT temps_reponse_moyen_ms FROM rapport_performance_global), 
        ' ms'
    ) as metriques_cles;
