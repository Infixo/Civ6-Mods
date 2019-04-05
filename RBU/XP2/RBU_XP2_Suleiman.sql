--------------------------------------------------------------
-- Real Building Upgrades
-- Author: Infixo
-- 2019-04-06: Created
--------------------------------------------------------------


--------------------------------------------------------------
-- GRAND_BAZAAR
/*

Routes and resources - like bank
Tourist attraction - 4 tourism with some civic or tech
Improved luxuries +2 gold

INSERT INTO BuildingReplaces (CivUniqueBuildingType, ReplacesBuildingType) VALUES
('BUILDING_TSIKHE_UPGRADE', 'BUILDING_STAR_FORT_UPGRADE');

UPDATE Buildings SET TraitType = (SELECT TraitType FROM Buildings WHERE BuildingType = 'BUILDING_TSIKHE') -- TRAIT_CIVILIZATION_BUILDING_TSIKHE
WHERE BuildingType = 'BUILDING_TSIKHE_UPGRADE';

-- +1 Amenity & Housing, +25 Defense
UPDATE Buildings
SET PurchaseYield = NULL, OuterDefenseHitPoints = 25, OuterDefenseStrength = 1, Entertainment = 1, Housing = 1
WHERE BuildingType = 'BUILDING_TSIKHE_UPGRADE';

-- +1 Faith
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange) VALUES -- generated from Excel
('BUILDING_TSIKHE_UPGRADE', 'YIELD_FAITH', 1);
*/