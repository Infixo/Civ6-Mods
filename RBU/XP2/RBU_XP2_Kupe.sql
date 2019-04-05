--------------------------------------------------------------
-- Real Building Upgrades
-- Author: Infixo
-- 2019-04-06: Created
--------------------------------------------------------------


--------------------------------------------------------------
-- MARAE
/*

1 amenity like Amphi
+1 production for each feature that could be removed (woods, jungle, marshes, etc.), tourism and gold from non-removables
+1 tourism and +2 gold for each feature on tiles with high appeal and Reefs
Central to identity - +2 loyalty in the city


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