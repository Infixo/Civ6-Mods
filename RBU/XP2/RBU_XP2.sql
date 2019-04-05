--------------------------------------------------------------
-- Real Building Upgrades
-- Author: Infixo
-- 2019-02-18: Created
--------------------------------------------------------------


--------------------------------------------------------------
-- 2019-02-18 Changes to upgrades of Vanilla and R&F buildings
--------------------------------------------------------------

-- 2019-02-18 Remove Power Plant Upgrade (temporarily, will be restored as an upgrade to the Nuclear Power Plant)
--DELETE FROM Buildings WHERE BuildingType = 'BUILDING_POWER_PLANT_UPGRADE';

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


--------------------------------------------------------------
-- 2019-04-06 Industrial Zone
-- Can’t give more power from resources because they consume dynamically. Focus on other effects.
--------------------------------------------------------------

-- Nuclear Power Plant needs a new name
UPDATE Buildings SET Cost = 450, Name = 'LOC_BUILDING_NUCLEAR_POWER_PLANT_UPGRADE_NAME', Description = 'LOC_BUILDING_NUCLEAR_POWER_PLANT_UPGRADE_DESCRIPTION' WHERE BuildingType = 'BUILDING_POWER_PLANT_UPGRADE';
-- Rearrange a bit so the techs will not get overcrowded
UPDATE Buildings SET PrereqTech = 'TECH_REPLACEABLE_PARTS'   WHERE BuildingType = 'BUILDING_FACTORY_UPGRADE';
UPDATE Buildings SET PrereqTech = 'TECH_NUCLEAR_FUSION'      WHERE BuildingType = 'BUILDING_POWER_PLANT_UPGRADE';
UPDATE Buildings SET PrereqTech = 'TECH_SYNTHETIC_MATERIALS' WHERE BuildingType = 'BUILDING_RESEARCH_LAB_UPGRADE';
UPDATE Buildings SET PrereqTech = 'TECH_COMBINED_ARMS'       WHERE BuildingType = 'BUILDING_SEAPORT_UPGRADE';
UPDATE Buildings SET PrereqTech = 'TECH_TELECOMMUNICATIONS'  WHERE BuildingType = 'BUILDING_BROADCAST_CENTER_UPGRADE';
UPDATE Buildings SET PrereqCivic = 'CIVIC_MASS_MEDIA'       WHERE BuildingType = 'BUILDING_FERRIS_WHEEL_UPGRADE';
UPDATE Buildings SET PrereqCivic = 'CIVIC_MASS_MEDIA'       WHERE BuildingType = 'BUILDING_AQUARIUM_UPGRADE';
UPDATE Buildings SET PrereqCivic = 'CIVIC_ENVIRONMENTALISM' WHERE BuildingType = 'BUILDING_AQUATICS_CENTER_UPGRADE';

/*
Coal 1 prod, 1 GEP, 4 power, rr6
1 prod rr9 no, if RR possible :)
2 prod from coal mines Or/and +1 coal generated
Or, if possible, 1 prod from each tile with a RailRoad !
Oil 2 peod, 1 GEP, 4 power, rr6
1/prod rr9
1 prod per district
3 prod from oil wells, +1 oil accumulated
Nuclear 4 prod, 3 science, 1 GEP, 16 power, rr6
2 prod, 1 sci rr9
2 prod per district
4 prod from uranium mines, +1 uranium accumulated
*/


--------------------------------------------------------------
-- 2019-04-06 Dam
--------------------------------------------------------------

/*
Hydro 6 power
+2 power
Production to all river tiles? Check RND.
*/
