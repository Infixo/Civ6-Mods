--------------------------------------------------------------
-- Real Building Upgrades
-- Author: Infixo
-- 2019-03-18: Separate file
--------------------------------------------------------------


--------------------------------------------------------------
-- TLACHTLI (Aztecs DLC)

UPDATE Buildings SET TraitType = 'TRAIT_CIVILIZATION_BUILDING_TLACHTLI' WHERE BuildingType = 'BUILDING_TLACHTLI_UPGRADE';

INSERT INTO BuildingReplaces (CivUniqueBuildingType, ReplacesBuildingType)
SELECT 'BUILDING_TLACHTLI_UPGRADE', 'BUILDING_ARENA_UPGRADE'
FROM Buildings
WHERE BuildingType = 'BUILDING_TLACHTLI';

-- +1 Amenity
UPDATE Buildings SET Entertainment = 1
WHERE BuildingType = 'BUILDING_TLACHTLI_UPGRADE';

-- +2 Culture
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange)
SELECT 'BUILDING_TLACHTLI_UPGRADE', 'YIELD_CULTURE', 2
FROM Buildings
WHERE BuildingType = 'BUILDING_TLACHTLI';

-- +1 Faith
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange)
SELECT 'BUILDING_TLACHTLI_UPGRADE', 'YIELD_FAITH', 1
FROM Buildings
WHERE BuildingType = 'BUILDING_TLACHTLI';

-- same as Arena
INSERT INTO BuildingModifiers (BuildingType, ModifierId)
SELECT 'BUILDING_TLACHTLI_UPGRADE', 'ARENA_UPGRADE_ADD_RESOURCE_CULTURE'
FROM Buildings
WHERE BuildingType = 'BUILDING_TLACHTLI';
