--------------------------------------------------------------
-- Real Fixes
-- Author: Infixo
-- 2019-03-27: Fixes for Start Biases (lower number = stronger bias)
--------------------------------------------------------------

-- AUSTRALIA
UPDATE StartBiasResources SET Tier = 4 WHERE CivilizationType = 'CIVILIZATION_AUSTRALIA'; -- IMPROVEMENT_PASTURE: RESOURCE_CATTLE, RESOURCE_HORSES, RESOURCE_SHEEP
INSERT OR REPLACE INTO StartBiasTerrains (CivilizationType, TerrainType, Tier)
SELECT 'CIVILIZATION_AUSTRALIA', TerrainType, 5
FROM Improvement_ValidTerrains
WHERE ImprovementType = 'IMPROVEMENT_OUTBACK_STATION';

-- 2023-04-02 Removed, I don't know why I added that :)
-- CANADA late-game strategic resources
--INSERT OR REPLACE INTO StartBiasResources (CivilizationType, ResourceType, Tier)
--SELECT 'CIVILIZATION_CANADA', ResourceType, 5
--FROM Resources
--WHERE ResourceType IN ('RESOURCE_URANIUM', 'RESOURCE_OIL', 'RESOURCE_NITER') AND EXISTS (SELECT * FROM Civilizations WHERE CivilizationType = 'CIVILIZATION_CANADA');

-- ENGLAND
UPDATE StartBiasResources SET Tier = 4 WHERE CivilizationType = 'CIVILIZATION_ENGLAND'; -- RESOURCE_COAL, RESOURCE_IRON

-- GEORGIA
INSERT OR REPLACE INTO StartBiasTerrains (CivilizationType, TerrainType, Tier)
SELECT 'CIVILIZATION_GEORGIA', TerrainType, 4
FROM Terrains
WHERE Hills = 1 AND TerrainType <> 'TERRAIN_SNOW_HILLS' AND EXISTS (SELECT * FROM Civilizations WHERE CivilizationType = 'CIVILIZATION_GEORGIA');

-- HUNGARY
UPDATE StartBiasFeatures SET Tier = 4 WHERE CivilizationType = 'CIVILIZATION_HUNGARY' AND FeatureType = 'FEATURE_GEOTHERMAL_FISSURE';

-- INCA
INSERT OR REPLACE INTO StartBiasTerrains (CivilizationType, TerrainType, Tier)
SELECT 'CIVILIZATION_INCA', TerrainType, 5
FROM Improvement_ValidTerrains
WHERE ImprovementType = 'IMPROVEMENT_TERRACE_FARM';

-- INDIA
INSERT OR REPLACE INTO StartBiasTerrains (CivilizationType, TerrainType, Tier)
SELECT 'CIVILIZATION_INDIA', TerrainType, 5
FROM Improvement_ValidTerrains
WHERE ImprovementType = 'IMPROVEMENT_STEPWELL' AND TerrainType <> 'TERRAIN_SNOW';

-- INDONESIA
UPDATE StartBiasTerrains SET Tier = 1 WHERE CivilizationType = 'CIVILIZATION_INDONESIA' AND TerrainType = 'TERRAIN_COAST';

-- JAPAN
INSERT OR REPLACE INTO StartBiasTerrains (CivilizationType, TerrainType, Tier) VALUES
('CIVILIZATION_JAPAN', 'TERRAIN_COAST', 5);

-- MALI
DELETE FROM StartBiasResources WHERE CivilizationType = 'CIVILIZATION_MALI';
INSERT INTO StartBiasResources (CivilizationType, ResourceType, Tier)
SELECT 'CIVILIZATION_MALI', ResourceType, 5
FROM Improvement_ValidResources
WHERE ImprovementType = 'IMPROVEMENT_MINE' AND EXISTS (SELECT * FROM Civilizations WHERE CivilizationType = 'CIVILIZATION_MALI');

-- MONGOLIA
UPDATE StartBiasResources SET Tier = 3 WHERE CivilizationType = 'CIVILIZATION_MONGOLIA' AND ResourceType = 'RESOURCE_HORSES';

-- NETHERLANDS
UPDATE StartBiasTerrains SET Tier = 2 WHERE CivilizationType = 'CIVILIZATION_NETHERLANDS' AND TerrainType = 'TERRAIN_COAST';

-- NORWAY
INSERT OR REPLACE INTO StartBiasFeatures (CivilizationType, FeatureType, Tier) VALUES
('CIVILIZATION_NORWAY', 'FEATURE_FOREST', 5);

-- NUBIA
INSERT OR REPLACE INTO StartBiasFeatures (CivilizationType, FeatureType, Tier)
SELECT CivilizationType, 'FEATURE_FLOODPLAINS', 5
FROM Civilizations
WHERE CivilizationType = 'CIVILIZATION_NUBIA';
--
DELETE FROM StartBiasResources WHERE CivilizationType = 'CIVILIZATION_NUBIA';
INSERT INTO StartBiasResources (CivilizationType, ResourceType, Tier)
SELECT 'CIVILIZATION_NUBIA', ResourceType, 5
FROM Improvement_ValidResources
WHERE ImprovementType = 'IMPROVEMENT_MINE' AND EXISTS (SELECT * FROM Civilizations WHERE CivilizationType = 'CIVILIZATION_NUBIA');

-- SCOTLAND
INSERT OR REPLACE INTO StartBiasTerrains (CivilizationType, TerrainType, Tier)
SELECT 'CIVILIZATION_SCOTLAND', TerrainType, 4
FROM Terrains
WHERE Hills = 1 AND TerrainType <> 'TERRAIN_SNOW_HILLS' AND EXISTS (SELECT * FROM Civilizations WHERE CivilizationType = 'CIVILIZATION_SCOTLAND');
--
INSERT OR REPLACE INTO StartBiasFeatures (CivilizationType, FeatureType, Tier)
SELECT CivilizationType, 'FEATURE_FOREST', 5
FROM Civilizations
WHERE CivilizationType = 'CIVILIZATION_SCOTLAND';

-- SCYTHIA
UPDATE StartBiasResources SET Tier = 4 WHERE CivilizationType = 'CIVILIZATION_SCYTHIA' AND ResourceType = 'RESOURCE_HORSES';

-- SPAIN
UPDATE StartBiasTerrains SET Tier = 4 WHERE CivilizationType = 'CIVILIZATION_SPAIN' AND TerrainType = 'TERRAIN_COAST';

-- SUMERIA
INSERT OR REPLACE INTO StartBiasTerrains (CivilizationType, TerrainType, Tier)
SELECT 'CIVILIZATION_SUMERIA', TerrainType, 5
FROM Improvement_ValidTerrains
WHERE ImprovementType = 'IMPROVEMENT_ZIGGURAT' AND TerrainType <> 'TERRAIN_SNOW';
