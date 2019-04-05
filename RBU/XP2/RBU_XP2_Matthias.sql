--------------------------------------------------------------
-- Real Building Upgrades
-- Author: Infixo
-- 2019-04-06: Created
--------------------------------------------------------------


--------------------------------------------------------------
-- THERMAL_BATH
/*

Thermal Bath inst. Zoo
People get better - 10% faster growth rate in the city?
0.1 prod per pop in the city!
GeoFissure gets tourism and gold? 
GeoFissure gets +5 gold with some late tech or civic?

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