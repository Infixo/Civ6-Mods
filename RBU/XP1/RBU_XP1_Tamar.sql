--------------------------------------------------------------
-- Real Building Upgrades
-- Author: Infixo
-- 2018-03-04: Created
-- 2018-12-15: New file format (each building is changed separately)
-- 2019-03-18: Separate file
--------------------------------------------------------------


--------------------------------------------------------------
-- TSIKHE

INSERT INTO BuildingReplaces (CivUniqueBuildingType, ReplacesBuildingType) VALUES
('BUILDING_TSIKHE_UPGRADE', 'BUILDING_STAR_FORT_UPGRADE');

UPDATE Buildings SET TraitType = 'TRAIT_CIVILIZATION_BUILDING_TSIKHE'
WHERE BuildingType = 'BUILDING_TSIKHE_UPGRADE';

-- +1 Amenity & Housing, +50 Defense
UPDATE Buildings
SET PurchaseYield = NULL, OuterDefenseHitPoints = 50, OuterDefenseStrength = 1, Entertainment = 1, Housing = 1
WHERE BuildingType = 'BUILDING_TSIKHE_UPGRADE';

-- +1 Faith
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange) VALUES -- generated from Excel
('BUILDING_TSIKHE_UPGRADE', 'YIELD_FAITH', 1);
