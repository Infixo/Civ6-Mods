--------------------------------------------------------------
-- Real Fixes
-- Author: Infixo
-- 2019-03-27: Fixes and tweaks for Start Biases (lower number = stronger bias)
-- 2023-04-04: Review, on/off option, support for BBS
--------------------------------------------------------------
-- Set to '0' to disable Start Bias changes
INSERT INTO GlobalParameters (Name, Value) VALUES ('RFX_OPTION_STARTS', '1');
--------------------------------------------------------------

-- AUSTRALIA
UPDATE StartBiasResources SET Tier = 4 WHERE CivilizationType = 'CIVILIZATION_AUSTRALIA' -- IMPROVEMENT_PASTURE: RESOURCE_CATTLE, RESOURCE_HORSES, RESOURCE_SHEEP
AND EXISTS (SELECT 1 FROM GlobalParameters WHERE Name = 'RFX_OPTION_STARTS' AND Value = '1');

-- ENGLAND
UPDATE StartBiasResources SET Tier = 4 WHERE CivilizationType = 'CIVILIZATION_ENGLAND' -- RESOURCE_COAL, RESOURCE_IRON
AND EXISTS (SELECT 1 FROM GlobalParameters WHERE Name = 'RFX_OPTION_STARTS' AND Value = '1');

-- GEORGIA
INSERT OR IGNORE INTO StartBiasTerrains (CivilizationType, TerrainType, Tier)
SELECT 'CIVILIZATION_GEORGIA', TerrainType, 4
FROM Terrains
WHERE Hills = 1 AND TerrainType <> 'TERRAIN_SNOW_HILLS' AND EXISTS (SELECT 1 FROM Civilizations WHERE CivilizationType = 'CIVILIZATION_GEORGIA')
AND EXISTS (SELECT 1 FROM GlobalParameters WHERE Name = 'RFX_OPTION_STARTS' AND Value = '1');

-- INDIA
INSERT OR IGNORE INTO StartBiasTerrains (CivilizationType, TerrainType, Tier)
SELECT 'CIVILIZATION_INDIA', TerrainType, 5
FROM Improvement_ValidTerrains
WHERE ImprovementType = 'IMPROVEMENT_STEPWELL' AND TerrainType <> 'TERRAIN_SNOW'
AND EXISTS (SELECT 1 FROM GlobalParameters WHERE Name = 'RFX_OPTION_STARTS' AND Value = '1');

-- NORWAY
INSERT OR IGNORE INTO StartBiasFeatures (CivilizationType, FeatureType, Tier)
SELECT 'CIVILIZATION_NORWAY', 'FEATURE_FOREST', 5
FROM Civilizations
WHERE EXISTS (SELECT 1 FROM GlobalParameters WHERE Name = 'RFX_OPTION_STARTS' AND Value = '1');

-- SCOTLAND
INSERT OR IGNORE INTO StartBiasTerrains (CivilizationType, TerrainType, Tier)
SELECT 'CIVILIZATION_SCOTLAND', TerrainType, 4
FROM Terrains
WHERE Hills = 1 AND TerrainType <> 'TERRAIN_SNOW_HILLS' AND EXISTS (SELECT * FROM Civilizations WHERE CivilizationType = 'CIVILIZATION_SCOTLAND')
AND EXISTS (SELECT 1 FROM GlobalParameters WHERE Name = 'RFX_OPTION_STARTS' AND Value = '1');

-- SPAIN
UPDATE StartBiasTerrains SET Tier = 4 WHERE CivilizationType = 'CIVILIZATION_SPAIN' AND TerrainType = 'TERRAIN_COAST'
AND EXISTS (SELECT 1 FROM GlobalParameters WHERE Name = 'RFX_OPTION_STARTS' AND Value = '1');

-- SUMERIA
INSERT OR IGNORE INTO StartBiasTerrains (CivilizationType, TerrainType, Tier)
SELECT 'CIVILIZATION_SUMERIA', TerrainType, 5
FROM Improvement_ValidTerrains
WHERE ImprovementType = 'IMPROVEMENT_ZIGGURAT' AND TerrainType <> 'TERRAIN_SNOW'
AND EXISTS (SELECT 1 FROM GlobalParameters WHERE Name = 'RFX_OPTION_STARTS' AND Value = '1');
