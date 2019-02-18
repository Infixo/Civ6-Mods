--------------------------------------------------------------
-- Real Building Upgrades
-- Author: Infixo
-- 2019-02-18: Created
--------------------------------------------------------------


--------------------------------------------------------------
-- Table with new parameters for buildings - the rest will be default
-- Created in the vanilla file
--------------------------------------------------------------

DELETE FROM RBUConfig; -- remove vanilla rows so they will not get duplicated


--------------------------------------------------------------
-- BUILDINGS
--------------------------------------------------------------

-- New building Types	
INSERT INTO Types(Type, Kind)
SELECT 'BUILDING_'||BType||'_UPGRADE', 'KIND_BUILDING'
FROM RBUConfig;

-- New buildings
INSERT INTO Buildings
	(BuildingType, Name, PrereqTech, PrereqCivic, Cost, MaxPlayerInstances, MaxWorldInstances, Capital, PrereqDistrict, AdjacentDistrict, Description, 
	RequiresPlacement, RequiresRiver, OuterDefenseHitPoints, Housing, Entertainment, AdjacentResource, Coast, 
	EnabledByReligion, AllowsHolyCity, PurchaseYield, MustPurchase, Maintenance, IsWonder, TraitType, OuterDefenseStrength, CitizenSlots, 
	MustBeLake, MustNotBeLake, RegionalRange, AdjacentToMountain, ObsoleteEra, RequiresReligion,
	GrantFortification, DefenseModifier, InternalOnly, RequiresAdjacentRiver, Quote, QuoteAudio, MustBeAdjacentLand,
	AdvisorType, AdjacentCapital, AdjacentImprovement, CityAdjacentTerrain)
	-- UnlocksGovernmentPolicy, GovernmentTierRequirement
SELECT
	'BUILDING_'||BType||'_UPGRADE',
	'LOC_BUILDING_'||BType||'_UPGRADE_NAME',
	CASE WHEN PTech IS NULL THEN NULL ELSE 'TECH_'||PTech END,
	CASE WHEN PCivic IS NULL THEN NULL ELSE 'CIVIC_'||PCivic END,
	UCost, -1, -1, 0,  -- Cost, MaxPlayerInstances, MaxWorldInstances, Capital (PALACE!)
	'DISTRICT_'||PDist, NULL,
	'LOC_BUILDING_'||BType||'_UPGRADE_DESCRIPTION',
	0, 0, NULL, 0, 0, NULL, NULL, -- RequiresPlacement, RequiresRiver, OuterDefenseHitPoints, Housing, Entertainment, AdjacentResource, Coast
	0, 0, -- EnabledByReligion, AllowsHolyCity, 
	'YIELD_GOLD', 0,  -- PurchaseYield, MustPurchase
	UMain, 0, NULL, 0, NULL,  -- Maintenance, IsWonder, TraitType, OuterDefenseStrength, CitizenSlots
	0, 0, 0, 0, 'NO_ERA', 0,  -- MustBeLake, MustNotBeLake, RegionalRange, AdjacentToMountain, ObsoleteEra, RequiresReligion
	0, 0, 0, 0, NULL, NULL, 0,  -- GrantFortification, DefenseModifier, InternalOnly, RequiresAdjacentRiver, Quote, QuoteAudio, MustBeAdjacentLand
	CASE WHEN Advis IS NULL THEN NULL ELSE 'ADVISOR_'||Advis END, 0, NULL,  -- AdvisorType, AdjacentCapital, AdjacentImprovement
	NULL  -- CityAdjacentTerrain [Version 1.1, fix for summer patch]
FROM RBUConfig;

-- Connect Upgrades to Base Buildings
INSERT INTO BuildingPrereqs (Building, PrereqBuilding)
SELECT 'BUILDING_'||BType||'_UPGRADE', 'BUILDING_'||BType
FROM RBUConfig;


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
