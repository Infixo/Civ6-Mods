--------------------------------------------------------------
-- Real Building Upgrades
-- Author: Infixo
-- Mar 20th, 2017 - Version 1 created
-- Aug 2nd, 2017 - Version 1.3, fix for summer patch
-- Sep 10th, 2017 - Version 1.3.1, tech fix for column names
-- Sep 18th, 2017 - Version 1.4, fix for Aztecs DLC
-- Nov 13th, 2017 - Version 1.5, fix for Apadana crash
-- 2018-03-04: Added Dar-e Mehr and Stupa
-- 2018-03-05: Removed all EnabledByReligion=1 Upgrades (game only allows for 1), removed Apadana fix (no longer necessary)
--             Added Basilikoi Paides and Prasat, some tweaks
-- 2018-03-26: Version 3.0, major updates to many upgrades, new file format (each building is changed separately)
-- 2019-03-18: Version 3.3, mod restructured for better DLCs support
-- 2019-04-05: Version 4.0, Gathering Storm buildings added
--------------------------------------------------------------


-- just to make versioning easier
INSERT INTO GlobalParameters (Name, Value) VALUES ('RBU_VERSION_MAJOR', '4');
INSERT INTO GlobalParameters (Name, Value) VALUES ('RBU_VERSION_MINOR', '0');


-- Version 1.5 Fix for Apadana crash; 2018-03-05 no longer necessary (tested)
--UPDATE Buildings SET AdjacentCapital = 0 WHERE BuildingType = 'BUILDING_APADANA';


-- first, some balance fixes
-- Research Lab 5->6, so later Upgrade can get 3; cost increased proportionally by 15%
--UPDATE Building_YieldChanges SET YieldChange = 6 WHERE BuildingType = 'BUILDING_RESEARCH_LAB' AND YieldType = 'YIELD_SCIENCE';
--UPDATE Buildings SET Cost = Cost * (115/100) WHERE BuildingType = 'BUILDING_RESEARCH_LAB';


-- The AI doesn't want to build Stables, but builds loads of Barracks probably because they are available
-- earlier and are cheaper; so lets make them comparable
UPDATE Buildings
SET Cost = (SELECT Cost FROM Buildings WHERE BuildingType = 'BUILDING_STABLE'),
	PrereqTech = 'TECH_IRON_WORKING'
WHERE BuildingType = 'BUILDING_BARRACKS';


--------------------------------------------------------------
-- Table with new parameters for buildings - the rest will be default
--------------------------------------------------------------
CREATE TABLE RBUConfig (
	BType	TEXT	NOT NULL,  	-- BuildingType
	PTech	TEXT,  				-- PrereqTech
	PCivic	TEXT,  				-- PrereqCivic
	UCost	INTEGER	NOT NULL,
	PDist	TEXT	NOT NULL,  	-- PrereqDistrict
	UMain	INTEGER NOT NULL DEFAULT 0, -- Maintenance
	Advis	TEXT,  				-- AdvisorType
	PRIMARY KEY (BType)
);

INSERT INTO RBUConfig (BType, PTech, PCivic, UCost, PDist, UMain, Advis)
VALUES  -- generated from Excel
('AIRPORT','TELECOMMUNICATIONS',NULL,360,'AERODROME',2,'CONQUEST'),
('AMPHITHEATER',NULL,'RECORDED_HISTORY',70,'THEATER',1,'CULTURE'),
('ARENA',NULL,'MILITARY_TRAINING',70,'ENTERTAINMENT_COMPLEX',1,'GENERIC'),
('ARMORY','GUNPOWDER',NULL,115,'ENCAMPMENT',2,'CONQUEST'),
('BANK','SCIENTIFIC_THEORY',NULL,175,'COMMERCIAL_HUB',0,'GENERIC'),
('BARRACKS','CONSTRUCTION',NULL,55,'ENCAMPMENT',1,'CONQUEST'),
('BASILIKOI_PAIDES','CONSTRUCTION',NULL,40,'ENCAMPMENT',1,'CONQUEST'),
('BROADCAST_CENTER','COMPUTERS',NULL,435,'THEATER',3,'CULTURE'),
('CASTLE','PRINTING',NULL,115,'CITY_CENTER',1,'GENERIC'),
--('CATHEDRAL',NULL,'REFORMED_CHURCH',115,'HOLY_SITE',0,NULL),
--('DAR_E_MEHR',NULL,'REFORMED_CHURCH',115,'HOLY_SITE',0,NULL),
('ELECTRONICS_FACTORY','STEAM_POWER',NULL,235,'INDUSTRIAL_ZONE',2,'GENERIC'),
('FACTORY','STEAM_POWER',NULL,235,'INDUSTRIAL_ZONE',2,'GENERIC'),
('FILM_STUDIO','COMPUTERS',NULL,435,'THEATER',3,'CULTURE'),
('GRANARY','IRRIGATION',NULL,40,'CITY_CENTER',1,'GENERIC'),
--('GURDWARA',NULL,'REFORMED_CHURCH',115,'HOLY_SITE',0,NULL),
('HANGAR','RADIO',NULL,210,'AERODROME',1,'CONQUEST'),
('LIBRARY','CURRENCY',NULL,40,'CAMPUS',1,'TECHNOLOGY'),
('LIGHTHOUSE','SHIPBUILDING',NULL,55,'HARBOR',1,'GENERIC'),
('MADRASA',NULL,'DIVINE_RIGHT',150,'CAMPUS',2,'TECHNOLOGY'),
('MARKET','MATHEMATICS',NULL,55,'COMMERCIAL_HUB',0,'GENERIC'),
--('MEETING_HOUSE',NULL,'REFORMED_CHURCH',115,'HOLY_SITE',0,NULL),
('MILITARY_ACADEMY',NULL,'MOBILIZATION',295,'ENCAMPMENT',3,'CONQUEST'),
('MONUMENT','WRITING',NULL,40,'CITY_CENTER',1,'CULTURE'),
--('MOSQUE',NULL,'REFORMED_CHURCH',115,'HOLY_SITE',0,NULL),
('MUSEUM_ART',NULL,'THE_ENLIGHTENMENT',175,'THEATER',0,'CULTURE'),
('MUSEUM_ARTIFACT',NULL,'THE_ENLIGHTENMENT',175,'THEATER',0,'CULTURE'),
--('PAGODA',NULL,'REFORMED_CHURCH',115,'HOLY_SITE',0,NULL),
('PALACE',NULL,'CODE_OF_LAWS',100,'CITY_CENTER',0,'GENERIC'),
('POWER_PLANT','NUCLEAR_FISSION',NULL,435,'INDUSTRIAL_ZONE',3,'GENERIC'),
('PRASAT',NULL,'DIVINE_RIGHT',70,'HOLY_SITE',2,'RELIGIOUS'),
('RESEARCH_LAB','NUCLEAR_FISSION',NULL,435,'CAMPUS',3,'TECHNOLOGY'),
('SEAPORT','COMPUTERS',NULL,435,'HARBOR',0,'GENERIC'),
('SEWER','CHEMISTRY',NULL,100,'CITY_CENTER',1,'GENERIC'),
('SHIPYARD','SQUARE_RIGGING',NULL,175,'HARBOR',2,'GENERIC'),
('SHRINE',NULL,'MYSTICISM',30,'HOLY_SITE',1,'RELIGIOUS'),
('STABLE','ENGINEERING',NULL,55,'ENCAMPMENT',1,'CONQUEST'),
('STADIUM',NULL,'SOCIAL_MEDIA',495,'ENTERTAINMENT_COMPLEX',3,'GENERIC'),
('STAR_FORT','BALLISTICS',NULL,155,'CITY_CENTER',1,'GENERIC'),
('STAVE_CHURCH',NULL,'DIVINE_RIGHT',70,'HOLY_SITE',2,'RELIGIOUS'),
('STOCK_EXCHANGE','COMPUTERS',NULL,295,'COMMERCIAL_HUB',0,'GENERIC'),
--('STUPA',NULL,'REFORMED_CHURCH',115,'HOLY_SITE',0,NULL),
('SUKIENNICE','MATHEMATICS',NULL,55,'COMMERCIAL_HUB',0,NULL),
--('SYNAGOGUE',NULL,'REFORMED_CHURCH',115,'HOLY_SITE',0,NULL),
('TEMPLE',NULL,'DIVINE_RIGHT',70,'HOLY_SITE',2,'RELIGIOUS'),
('TLACHTLI',NULL,'MILITARY_TRAINING',60,'ENTERTAINMENT_COMPLEX',1,NULL),
('UNIVERSITY','PRINTING',NULL,150,'CAMPUS',2,'TECHNOLOGY'),
('WALLS','CONSTRUCTION',NULL,40,'CITY_CENTER',1,'GENERIC'),
--('WAT',NULL,'REFORMED_CHURCH',115,'HOLY_SITE',0,NULL),
('WATER_MILL','ENGINEERING',NULL,40,'CITY_CENTER',1,'GENERIC'),
('WORKSHOP','MASS_PRODUCTION',NULL,90,'INDUSTRIAL_ZONE',1,'GENERIC'),
('ZOO',NULL,'CONSERVATION',265,'ENTERTAINMENT_COMPLEX',2,'GENERIC'),
-- Rise & Fall buildings
('AQUARIUM',NULL,'CONSERVATION',265,'WATER_ENTERTAINMENT_COMPLEX',2,'GENERIC'),
('AQUATICS_CENTER',NULL,'SOCIAL_MEDIA',495,'WATER_ENTERTAINMENT_COMPLEX',3,'GENERIC'),
('FERRIS_WHEEL',NULL,'CONSERVATION',130,'WATER_ENTERTAINMENT_COMPLEX',1,'GENERIC'),
('FOOD_MARKET','PLASTICS',NULL,280,'NEIGHBORHOOD',2,'GENERIC'),
('ORDU','CONSTRUCTION',NULL,55,'ENCAMPMENT',1,'CONQUEST'),
('SHOPPING_MALL',NULL,'CULTURAL_HERITAGE',350,'NEIGHBORHOOD',2,'CULTURE'),
('TSIKHE','BALLISTICS',NULL,200,'CITY_CENTER',1,'GENERIC'),
-- Gathering Storm buildings
('COAL_POWER_PLANT','REPLACEABLE_PARTS',NULL,180,'INDUSTRIAL_ZONE',2,'GENERIC'), -- T2, 300
('FOSSIL_FUEL_POWER_PLANT','ADVANCED_BALLISTICS',NULL,340,'INDUSTRIAL_ZONE',3,'GENERIC'), -- T3, 450
-- 'NUCLEAR_POWER_PLANT', 450 -- this is still POWER_PLANT -- T3, 600
('HYDROELECTRIC_DAM','COMPUTERS',NULL,435,'DAM',3,'GENERIC'), -- 580
('GRAND_BAZAAR','SCIENTIFIC_THEORY',NULL,130,'COMMERCIAL_HUB',0,'GENERIC'), -- T2, 220
('THERMAL_BATH',NULL,'CONSERVATION',265,'ENTERTAINMENT_COMPLEX',2,'GENERIC'), -- T2, 445
('MARAE',NULL,'RECORDED_HISTORY',70,'THEATER',1,'CULTURE'); -- T1, 150


-- 2019-03-18 Remove all upgrades that don't have a respective base buildings
DELETE FROM RBUConfig
WHERE 'BUILDING_'||BType NOT IN (SELECT BuildingType FROM Buildings);


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
