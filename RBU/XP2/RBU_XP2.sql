--------------------------------------------------------------
-- Real Building Upgrades
-- Author: Infixo
-- 2019-02-18: Created
--------------------------------------------------------------


--------------------------------------------------------------
-- 2019-02-18 Changes to upgrades of Vanilla and R&F buildings
--------------------------------------------------------------

-- 2019-02-18 Remove Power Plant Upgrade (temporarily, will be restored as an upgrade to the Nuclear Power Plant)
DELETE FROM Buildings WHERE BuildingType = 'BUILDING_POWER_PLANT_UPGRADE';

INSERT INTO Buildings_XP2 (BuildingType, RequiredPower, EntertainmentBonusWithPower) VALUES
('BUILDING_FACTORY_UPGRADE',             1, 0),
('BUILDING_ELECTRONICS_FACTORY_UPGRADE', 1, 0),
('BUILDING_STOCK_EXCHANGE_UPGRADE',   2, 0),
('BUILDING_RESEARCH_LAB_UPGRADE',     2, 0),
('BUILDING_STADIUM_UPGRADE',          2, 1),
('BUILDING_AQUATICS_CENTER_UPGRADE',  2, 1),
('BUILDING_BROADCAST_CENTER_UPGRADE', 2, 0),
('BUILDING_FILM_STUDIO_UPGRADE',      2, 0);

INSERT INTO Building_TourismBombs_XP2 (BuildingType, TourismBombValue) VALUES
('BUILDING_TLACHTLI_UPGRADE',     150),
--('BUILDING_MARAE_UPGRADE',        150),
('BUILDING_AMPHITHEATER_UPGRADE', 150),
('BUILDING_ARENA_UPGRADE',        150),
('BUILDING_FERRIS_WHEEL_UPGRADE', 150),
('BUILDING_SHIPYARD_UPGRADE',   300),
('BUILDING_UNIVERSITY_UPGRADE', 300),
('BUILDING_MADRASA_UPGRADE',    300),
('BUILDING_STADIUM_UPGRADE',          450),
('BUILDING_BROADCAST_CENTER_UPGRADE', 450),
('BUILDING_FILM_STUDIO_UPGRADE',      450),
('BUILDING_AQUATICS_CENTER_UPGRADE',  450);

UPDATE Buildings SET OuterDefenseHitPoints =  50 WHERE BuildingType = 'BUILDING_WALLS_UPGRADE';
UPDATE Buildings SET OuterDefenseHitPoints =  50 WHERE BuildingType = 'BUILDING_CASTLE_UPGRADE';
UPDATE Buildings SET OuterDefenseHitPoints =  50 WHERE BuildingType = 'BUILDING_STAR_FORT_UPGRADE';
UPDATE Buildings SET OuterDefenseHitPoints = 100 WHERE BuildingType = 'BUILDING_TSIKHE_UPGRADE';
