--------------------------------------------------------------
-- Real Building Upgrades
-- Author: Infixo
-- 2018-03-04: Created
-- 2018-12-15: New file format (each building is changed separately)
-- 2019-03-18: Separate file
--------------------------------------------------------------


--------------------------------------------------------------
-- ORDU

INSERT INTO BuildingReplaces (CivUniqueBuildingType, ReplacesBuildingType) VALUES
('BUILDING_ORDU_UPGRADE', 'BUILDING_STABLE_UPGRADE');
	
UPDATE Buildings SET TraitType = (SELECT TraitType FROM Buildings WHERE BuildingType = 'BUILDING_ORDU') -- TRAIT_CIVILIZATION_BUILDING_ORDU
WHERE BuildingType = 'BUILDING_ORDU_UPGRADE';

-- 2018-03-05 Mutually exclusive buildings (so they won't appear in production list)
INSERT INTO MutuallyExclusiveBuildings (Building, MutuallyExclusiveBuilding) VALUES
('BUILDING_ORDU_UPGRADE', 'BUILDING_BARRACKS'),
('BUILDING_ORDU_UPGRADE', 'BUILDING_BARRACKS_UPGRADE');

-- +1 Production
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange) VALUES
('BUILDING_ORDU_UPGRADE', 'YIELD_PRODUCTION', 1);

-- +1 GGP
INSERT INTO Building_GreatPersonPoints (BuildingType, GreatPersonClassType, PointsPerTurn) VALUES
('BUILDING_ORDU_UPGRADE', 'GREAT_PERSON_CLASS_GENERAL', 1);

-- +2 Production from Pastures
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_ORDU_UPGRADE', 'STABLEUPGRADE_ADDPASTUREPRODUCTION'); -- the same effect as Stable Upgrade
