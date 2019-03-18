--------------------------------------------------------------
-- Real Building Upgrades
-- Author: Infixo
-- 2019-03-18: Separate file
--------------------------------------------------------------


--------------------------------------------------------------
-- BASILIKOI_PAIDES (Macedon DLC)

UPDATE Buildings SET TraitType = 'TRAIT_CIVILIZATION_BUILDING_BASILIKOI_PAIDES'    WHERE BuildingType = 'BUILDING_BASILIKOI_PAIDES_UPGRADE';

INSERT INTO BuildingReplaces (CivUniqueBuildingType, ReplacesBuildingType)
SELECT 'BUILDING_BASILIKOI_PAIDES_UPGRADE', 'BUILDING_BARRACKS_UPGRADE'
FROM Buildings
WHERE BuildingType = 'BUILDING_BASILIKOI_PAIDES';

INSERT INTO MutuallyExclusiveBuildings (Building, MutuallyExclusiveBuilding)
SELECT 'BUILDING_BASILIKOI_PAIDES_UPGRADE', 'BUILDING_STABLE'
FROM Buildings
WHERE BuildingType = 'BUILDING_BASILIKOI_PAIDES';

INSERT INTO MutuallyExclusiveBuildings (Building, MutuallyExclusiveBuilding)
SELECT 'BUILDING_BASILIKOI_PAIDES_UPGRADE', 'BUILDING_STABLE_UPGRADE'
FROM Buildings
WHERE BuildingType = 'BUILDING_BASILIKOI_PAIDES';

-- +1 Production
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange)
SELECT 'BUILDING_BASILIKOI_PAIDES_UPGRADE', 'YIELD_PRODUCTION', 1
FROM Buildings
WHERE BuildingType = 'BUILDING_BASILIKOI_PAIDES';

-- +1 GSP
INSERT INTO Building_GreatPersonPoints (BuildingType, GreatPersonClassType, PointsPerTurn)
SELECT 'BUILDING_BASILIKOI_PAIDES_UPGRADE', 'GREAT_PERSON_CLASS_SCIENTIST', 1
FROM Buildings
WHERE BuildingType = 'BUILDING_BASILIKOI_PAIDES';

-- +2 Production from Camps
INSERT INTO BuildingModifiers (BuildingType, ModifierId)
SELECT 'BUILDING_BASILIKOI_PAIDES_UPGRADE', 'BARRACKSUPGRADE_ADDCAMPPRODUCTION' -- Barracks' replacement
FROM Buildings
WHERE BuildingType = 'BUILDING_BASILIKOI_PAIDES';
