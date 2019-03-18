--------------------------------------------------------------
-- Real Building Upgrades
-- Author: Infixo
-- 2019-03-18: Separate file
--------------------------------------------------------------


--------------------------------------------------------------
-- SUKIENNICE (Poland DLC)

UPDATE Buildings SET TraitType = 'TRAIT_CIVILIZATION_BUILDING_SUKIENNICE' WHERE BuildingType = 'BUILDING_SUKIENNICE_UPGRADE';

INSERT INTO BuildingReplaces (CivUniqueBuildingType, ReplacesBuildingType)
SELECT 'BUILDING_SUKIENNICE_UPGRADE', 'BUILDING_MARKET_UPGRADE'
FROM Buildings
WHERE BuildingType = 'BUILDING_SUKIENNICE';

-- +2 Gold
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange)
SELECT 'BUILDING_SUKIENNICE_UPGRADE', 'YIELD_GOLD', 2
FROM Buildings
WHERE BuildingType = 'BUILDING_SUKIENNICE';

-- +1 GMP
INSERT INTO Building_GreatPersonPoints (BuildingType, GreatPersonClassType, PointsPerTurn)
SELECT 'BUILDING_SUKIENNICE_UPGRADE', 'GREAT_PERSON_CLASS_MERCHANT', 1
FROM Buildings
WHERE BuildingType = 'BUILDING_SUKIENNICE';

-- Same as Market
INSERT INTO BuildingModifiers (BuildingType, ModifierId)
SELECT 'BUILDING_SUKIENNICE_UPGRADE', 'MARKET_UPGRADE_ADD_RESOURCE_GOLD'
FROM Buildings
WHERE BuildingType = 'BUILDING_SUKIENNICE';
