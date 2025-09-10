-- Indexes pour performance
CREATE INDEX idx_sinistres_composite ON sinistres(statut, date_declaration, type_sinistre);
CREATE INDEX idx_contrats_composite ON contrats(statut, type_contrat, assure_id);
CREATE INDEX idx_assures_score ON assures(score_risque, age);

-- Statistiques des tables
ANALYZE TABLE assures, contrats, sinistres, timeline_sinistres;

-- Vue matérialisée simulée pour dashboard temps réel
CREATE TABLE dashboard_cache AS
SELECT * FROM dashboard_kpi;

-- Procédure de refresh du cache
DELIMITER //
CREATE PROCEDURE RefreshDashboardCache()
BEGIN
    DELETE FROM dashboard_cache;
    INSERT INTO dashboard_cache SELECT * FROM dashboard_kpi;
END //
DELIMITER ;
