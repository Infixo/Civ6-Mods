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
--------------------------------------------------------------

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
('AIRPORT','TELECOMMUNICATIONS',NULL,480,'AERODROME',3,'CONQUEST'),
('AMPHITHEATER',NULL,'RECORDED_HISTORY',90,'THEATER',1,'CULTURE'),
('ARENA',NULL,'MILITARY_TRAINING',90,'ENTERTAINMENT_COMPLEX',1,'GENERIC'),
('ARMORY','GUNPOWDER',NULL,155,'ENCAMPMENT',3,'CONQUEST'),
('BANK','SCIENTIFIC_THEORY',NULL,230,'COMMERCIAL_HUB',0,'GENERIC'),
('BARRACKS','CONSTRUCTION',NULL,70,'ENCAMPMENT',1,'CONQUEST'),
('BASILIKOI_PAIDES','CONSTRUCTION',NULL,55,'ENCAMPMENT',1,'CONQUEST'),
('BROADCAST_CENTER','COMPUTERS',NULL,580,'THEATER',4,'CULTURE'),
('CASTLE','PRINTING',NULL,110,'CITY_CENTER',1,'GENERIC'),
--('CATHEDRAL',NULL,'REFORMED_CHURCH',150,'HOLY_SITE',0,NULL),
--('DAR_E_MEHR',NULL,'REFORMED_CHURCH',150,'HOLY_SITE',0,NULL),
('ELECTRONICS_FACTORY','STEAM_POWER',NULL,310,'INDUSTRIAL_ZONE',3,'GENERIC'),
('FACTORY','STEAM_POWER',NULL,310,'INDUSTRIAL_ZONE',3,'GENERIC'),
('FILM_STUDIO','COMPUTERS',NULL,580,'THEATER',4,'CULTURE'),
('GRANARY','IRRIGATION',NULL,40,'CITY_CENTER',1,'GENERIC'),
--('GURDWARA',NULL,'REFORMED_CHURCH',150,'HOLY_SITE',0,NULL),
('HANGAR','RADIO',NULL,280,'AERODROME',1,'CONQUEST'),
('LIBRARY','CURRENCY',NULL,55,'CAMPUS',1,'TECHNOLOGY'),
('LIGHTHOUSE','SHIPBUILDING',NULL,70,'HARBOR',1,'GENERIC'),
('MADRASA',NULL,'DIVINE_RIGHT',200,'CAMPUS',3,'TECHNOLOGY'),
('MARKET','MATHEMATICS',NULL,70,'COMMERCIAL_HUB',0,'GENERIC'),
--('MEETING_HOUSE',NULL,'REFORMED_CHURCH',150,'HOLY_SITE',0,NULL),
('MILITARY_ACADEMY',NULL,'MOBILIZATION',390,'ENCAMPMENT',3,'CONQUEST'),
('MONUMENT','WRITING',NULL,35,'CITY_CENTER',1,'CULTURE'),
--('MOSQUE',NULL,'REFORMED_CHURCH',150,'HOLY_SITE',0,NULL),
('MUSEUM_ART',NULL,'THE_ENLIGHTENMENT',230,'THEATER',0,'CULTURE'),
('MUSEUM_ARTIFACT',NULL,'THE_ENLIGHTENMENT',230,'THEATER',0,'CULTURE'),
--('PAGODA',NULL,'REFORMED_CHURCH',150,'HOLY_SITE',0,NULL),
('PALACE',NULL,'CODE_OF_LAWS',150,'CITY_CENTER',0,'GENERIC'),
('POWER_PLANT','NUCLEAR_FISSION',NULL,580,'INDUSTRIAL_ZONE',4,'GENERIC'),
('PRASAT',NULL,'DIVINE_RIGHT',95,'HOLY_SITE',3,'RELIGIOUS'),
('RESEARCH_LAB','NUCLEAR_FISSION',NULL,580,'CAMPUS',4,'TECHNOLOGY'),
('SEAPORT','COMPUTERS',NULL,580,'HARBOR',0,'GENERIC'),
('SEWER','CHEMISTRY',NULL,100,'CITY_CENTER',1,'GENERIC'),
('SHIPYARD','SQUARE_RIGGING',NULL,230,'HARBOR',3,'GENERIC'),
('SHRINE',NULL,'MYSTICISM',40,'HOLY_SITE',1,'RELIGIOUS'),
('STABLE','ENGINEERING',NULL,70,'ENCAMPMENT',1,'CONQUEST'),
('STADIUM',NULL,'SOCIAL_MEDIA',660,'ENTERTAINMENT_COMPLEX',4,'GENERIC'),
('STAR_FORT','BALLISTICS',NULL,150,'CITY_CENTER',1,'GENERIC'),
('STAVE_CHURCH',NULL,'DIVINE_RIGHT',95,'HOLY_SITE',3,'RELIGIOUS'),
('STOCK_EXCHANGE','COMPUTERS',NULL,390,'COMMERCIAL_HUB',0,'GENERIC'),
--('STUPA',NULL,'REFORMED_CHURCH',150,'HOLY_SITE',0,NULL),
('SUKIENNICE','MATHEMATICS',NULL,70,'COMMERCIAL_HUB',0,NULL),
--('SYNAGOGUE',NULL,'REFORMED_CHURCH',150,'HOLY_SITE',0,NULL),
('TEMPLE',NULL,'DIVINE_RIGHT',95,'HOLY_SITE',3,'RELIGIOUS'),
('TLACHTLI',NULL,'MILITARY_TRAINING',80,'ENTERTAINMENT_COMPLEX',1,NULL),
('UNIVERSITY','PRINTING',NULL,200,'CAMPUS',3,'TECHNOLOGY'),
('WALLS','CONSTRUCTION',NULL,40,'CITY_CENTER',1,'GENERIC'),
--('WAT',NULL,'REFORMED_CHURCH',150,'HOLY_SITE',0,NULL),
('WATER_MILL','ENGINEERING',NULL,50,'CITY_CENTER',1,'GENERIC'),
('WORKSHOP','MASS_PRODUCTION',NULL,115,'INDUSTRIAL_ZONE',1,'GENERIC'),
('ZOO',NULL,'CONSERVATION',355,'ENTERTAINMENT_COMPLEX',3,'GENERIC');

-- DLC: Poland - remove upgrade if base building is not there
DELETE FROM RBUConfig
WHERE BType = 'SUKIENNICE' AND NOT EXISTS (SELECT * FROM Buildings WHERE BuildingType = 'BUILDING_SUKIENNICE');

-- DLC: Aztecs - remove upgrade if base building is not there
DELETE FROM RBUConfig
WHERE BType = 'TLACHTLI' AND NOT EXISTS (SELECT * FROM Buildings WHERE BuildingType = 'BUILDING_TLACHTLI');

-- DLC: Macedon - remove upgrade if base building is not there
DELETE FROM RBUConfig
WHERE BType = 'BASILIKOI_PAIDES' AND NOT EXISTS (SELECT * FROM Buildings WHERE BuildingType = 'BUILDING_BASILIKOI_PAIDES');

-- DLC: Khmer - remove upgrade if base building is not there
DELETE FROM RBUConfig
WHERE BType = 'PRASAT' AND NOT EXISTS (SELECT * FROM Buildings WHERE BuildingType = 'BUILDING_PRASAT');


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


--------------------------------------------------------------
-- 2018-03-27 City Center
--------------------------------------------------------------

-------------------------------------------------------------
-- PALACE

-- +1 Housing
UPDATE Buildings
SET MaxPlayerInstances = 1, PurchaseYield = NULL, Housing = 1  --, Capital = 1
WHERE BuildingType = 'BUILDING_PALACE_UPGRADE';

-- +2 Gold, +1 Production, +1 Science
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange) VALUES
('BUILDING_PALACE_UPGRADE', 'YIELD_GOLD', 2),
('BUILDING_PALACE_UPGRADE', 'YIELD_PRODUCTION', 1),
('BUILDING_PALACE_UPGRADE', 'YIELD_SCIENCE', 1);

-------------------------------------------------------------
-- MONUMENT

-- +1 Culture
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange) VALUES
('BUILDING_MONUMENT_UPGRADE', 'YIELD_CULTURE', 1);

-- +3 Strength when fighting Barbs
INSERT INTO Types (Type, Kind) VALUES  -- hash value generated automatically
('MODIFIER_CITY_TRAINED_UNITS_ADJUST_BARBARIAN_COMBAT', 'KIND_MODIFIER');

INSERT INTO DynamicModifiers (ModifierType, CollectionType, EffectType) VALUES
('MODIFIER_CITY_TRAINED_UNITS_ADJUST_BARBARIAN_COMBAT', 'COLLECTION_CITY_TRAINED_UNITS', 'EFFECT_ADJUST_UNIT_BARBARIAN_COMBAT');

INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_MONUMENT_UPGRADE', 'MONUMENT_UPGRADE_ADJUST_BARBARIAN_COMBAT');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('MONUMENT_UPGRADE_ADJUST_BARBARIAN_COMBAT', 'MODIFIER_CITY_TRAINED_UNITS_ADJUST_BARBARIAN_COMBAT', 0, 0, NULL, NULL);

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('MONUMENT_UPGRADE_ADJUST_BARBARIAN_COMBAT', 'Amount',    '3');

-------------------------------------------------------------
-- GRANARY

-- +1 Housing
UPDATE Buildings SET Housing = 1
WHERE BuildingType = 'BUILDING_GRANARY_UPGRADE';

-- +1 Food
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange) VALUES
('BUILDING_GRANARY_UPGRADE', 'YIELD_FOOD', 1);

-- +2 Food from RESOURCE_BANANAS, RESOURCE_WINE
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_GRANARY_UPGRADE', 'GRANARY_UPGRADE_ADD_RESOURCE_FOOD');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('GRANARY_UPGRADE_ADD_RESOURCE_FOOD', 'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD', 0, 0, NULL, 'RESOURCES_FOR_GRANARY_UPGRADE');

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('GRANARY_UPGRADE_ADD_RESOURCE_FOOD', 'YieldType', 'YIELD_FOOD'),
('GRANARY_UPGRADE_ADD_RESOURCE_FOOD', 'Amount',    '2');

INSERT INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES
('RESOURCES_FOR_GRANARY_UPGRADE', 'REQUIREMENTSET_TEST_ANY');

INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES
('RESOURCES_FOR_GRANARY_UPGRADE', 'REQUIRES_BANANAS_IN_PLOT'),
('RESOURCES_FOR_GRANARY_UPGRADE', 'REQUIRES_WINE_IN_PLOT');

INSERT INTO Requirements (RequirementId, RequirementType) VALUES
('REQUIRES_BANANAS_IN_PLOT', 'REQUIREMENT_PLOT_RESOURCE_TYPE_MATCHES'),
('REQUIRES_WINE_IN_PLOT',    'REQUIREMENT_PLOT_RESOURCE_TYPE_MATCHES');

INSERT INTO RequirementArguments (RequirementId, Name, Value) VALUES
('REQUIRES_BANANAS_IN_PLOT', 'ResourceType', 'RESOURCE_BANANAS'),
('REQUIRES_WINE_IN_PLOT',    'ResourceType', 'RESOURCE_WINE');

-------------------------------------------------------------
-- WATER_MILL

-- River
UPDATE Buildings SET RequiresAdjacentRiver = 1
WHERE BuildingType = 'BUILDING_WATER_MILL_UPGRADE';

-- + 1 Production
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange) VALUES
('BUILDING_WATER_MILL_UPGRADE', 'YIELD_PRODUCTION', 1);

-- Fulling or walk mills were used for a finishing process on woollen cloth - 10th cent.
-- +1 Production to RESOURCE_SHEEP / RESOURCE_COTTON / RESOURCE_FURS
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_WATER_MILL_UPGRADE', 'WATER_MILL_UPGRADE_ADD_RESOURCE_PRODUCTION');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('WATER_MILL_UPGRADE_ADD_RESOURCE_PRODUCTION', 'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD', 0, 0, NULL, 'RESOURCES_FOR_WATER_MILL_UPGRADE');

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('WATER_MILL_UPGRADE_ADD_RESOURCE_PRODUCTION', 'YieldType', 'YIELD_PRODUCTION'),
('WATER_MILL_UPGRADE_ADD_RESOURCE_PRODUCTION', 'Amount',    '1');

INSERT INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES
('RESOURCES_FOR_WATER_MILL_UPGRADE', 'REQUIREMENTSET_TEST_ANY');

INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES
('RESOURCES_FOR_WATER_MILL_UPGRADE', 'REQUIRES_COTTON_IN_PLOT'),
('RESOURCES_FOR_WATER_MILL_UPGRADE', 'REQUIRES_FURS_IN_PLOT'),
('RESOURCES_FOR_WATER_MILL_UPGRADE', 'REQUIRES_SHEEP_IN_PLOT');

INSERT INTO Requirements (RequirementId, RequirementType) VALUES
('REQUIRES_COTTON_IN_PLOT', 'REQUIREMENT_PLOT_RESOURCE_TYPE_MATCHES'),
('REQUIRES_FURS_IN_PLOT',   'REQUIREMENT_PLOT_RESOURCE_TYPE_MATCHES'),
('REQUIRES_SHEEP_IN_PLOT',  'REQUIREMENT_PLOT_RESOURCE_TYPE_MATCHES');

INSERT INTO RequirementArguments (RequirementId, Name, Value) VALUES
('REQUIRES_COTTON_IN_PLOT', 'ResourceType', 'RESOURCE_COTTON'),
('REQUIRES_FURS_IN_PLOT',   'ResourceType', 'RESOURCE_FURS'),
('REQUIRES_SHEEP_IN_PLOT',  'ResourceType', 'RESOURCE_SHEEP');

-------------------------------------------------------------
-- SEWER (exception!)

-- +1 Housing
UPDATE Buildings SET Housing = 1
WHERE BuildingType = 'BUILDING_SEWER_UPGRADE';

-------------------------------------------------------------
-- WALLS / CASTLE / STAR_FORT (exceptions!)

-- +1 Housing, +25 HP
UPDATE Buildings SET PurchaseYield = NULL, OuterDefenseHitPoints = 25, OuterDefenseStrength = 2, Housing = 1
WHERE BuildingType IN ('BUILDING_CASTLE_UPGRADE', 'BUILDING_STAR_FORT_UPGRADE', 'BUILDING_WALLS_UPGRADE');


--------------------------------------------------------------
-- 2018-03-26 Theater Square
--------------------------------------------------------------

-------------------------------------------------------------
-- AMPHITHEATER

-- +1 Amenity
UPDATE Buildings SET Entertainment = 1
WHERE BuildingType = 'BUILDING_AMPHITHEATER_UPGRADE';

-- +1 Culture
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange) VALUES
('BUILDING_AMPHITHEATER_UPGRADE', 'YIELD_CULTURE', 1);

--------------------------------------------------------------
-- MUSEUM_ART / MUSEUM_ARTIFACT

-- +2 Culture
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange) VALUES
('BUILDING_MUSEUM_ART_UPGRADE',      'YIELD_CULTURE', 2),
('BUILDING_MUSEUM_ARTIFACT_UPGRADE', 'YIELD_CULTURE', 2);

-- +1 GAP
INSERT INTO Building_GreatPersonPoints (BuildingType, GreatPersonClassType, PointsPerTurn) VALUES
('BUILDING_MUSEUM_ART_UPGRADE',      'GREAT_PERSON_CLASS_ARTIST', 1),
('BUILDING_MUSEUM_ARTIFACT_UPGRADE', 'GREAT_PERSON_CLASS_ARTIST', 1);

-- 2018-03-05 Mutually exclusive buildings (so they won't appear in production list)
INSERT INTO MutuallyExclusiveBuildings (Building, MutuallyExclusiveBuilding) VALUES
('BUILDING_MUSEUM_ART_UPGRADE', 'BUILDING_MUSEUM_ARTIFACT'),
('BUILDING_MUSEUM_ART_UPGRADE', 'BUILDING_MUSEUM_ARTIFACT_UPGRADE'),
('BUILDING_MUSEUM_ARTIFACT_UPGRADE', 'BUILDING_MUSEUM_ART'),
('BUILDING_MUSEUM_ARTIFACT_UPGRADE', 'BUILDING_MUSEUM_ART_UPGRADE');

-- Museums +1 Gold for each GW in the City except religious
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
-- Art can only hold GREATWORKSLOT_ART = GREATWORKOBJECT_SCULPTURE + GREATWORKOBJECT_PORTRAIT + GREATWORKOBJECT_LANDSCAPE + GREATWORKOBJECT_RELIGIOUS
('BUILDING_MUSEUM_ART_UPGRADE', 'MUSEUMSUPGRADE_GREAT_WORK_ARTIFACT_GOLD'),
('BUILDING_MUSEUM_ART_UPGRADE', 'MUSEUMSUPGRADE_GREAT_WORK_LANDSCAPE_GOLD'),
('BUILDING_MUSEUM_ART_UPGRADE', 'MUSEUMSUPGRADE_GREAT_WORK_MUSIC_GOLD'),
('BUILDING_MUSEUM_ART_UPGRADE', 'MUSEUMSUPGRADE_GREAT_WORK_PORTRAIT_GOLD'),
('BUILDING_MUSEUM_ART_UPGRADE', 'MUSEUMSUPGRADE_GREAT_WORK_SCULPTURE_GOLD'),
('BUILDING_MUSEUM_ART_UPGRADE', 'MUSEUMSUPGRADE_GREAT_WORK_WRITING_GOLD'),
-- Artifact can only hold GREATWORKSLOT_ARTIFACT = GREATWORKOBJECT_ARTIFACT
('BUILDING_MUSEUM_ARTIFACT_UPGRADE', 'MUSEUMSUPGRADE_GREAT_WORK_ARTIFACT_GOLD'),
('BUILDING_MUSEUM_ARTIFACT_UPGRADE', 'MUSEUMSUPGRADE_GREAT_WORK_LANDSCAPE_GOLD'),
('BUILDING_MUSEUM_ARTIFACT_UPGRADE', 'MUSEUMSUPGRADE_GREAT_WORK_MUSIC_GOLD'),
('BUILDING_MUSEUM_ARTIFACT_UPGRADE', 'MUSEUMSUPGRADE_GREAT_WORK_PORTRAIT_GOLD'),
('BUILDING_MUSEUM_ARTIFACT_UPGRADE', 'MUSEUMSUPGRADE_GREAT_WORK_SCULPTURE_GOLD'),
('BUILDING_MUSEUM_ARTIFACT_UPGRADE', 'MUSEUMSUPGRADE_GREAT_WORK_WRITING_GOLD');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('MUSEUMSUPGRADE_GREAT_WORK_ARTIFACT_GOLD',  'MODIFIER_SINGLE_CITY_ADJUST_GREATWORK_YIELD', 0, 0, NULL, NULL),
('MUSEUMSUPGRADE_GREAT_WORK_LANDSCAPE_GOLD', 'MODIFIER_SINGLE_CITY_ADJUST_GREATWORK_YIELD', 0, 0, NULL, NULL),
('MUSEUMSUPGRADE_GREAT_WORK_MUSIC_GOLD',     'MODIFIER_SINGLE_CITY_ADJUST_GREATWORK_YIELD', 0, 0, NULL, NULL),
('MUSEUMSUPGRADE_GREAT_WORK_PORTRAIT_GOLD',  'MODIFIER_SINGLE_CITY_ADJUST_GREATWORK_YIELD', 0, 0, NULL, NULL),
('MUSEUMSUPGRADE_GREAT_WORK_SCULPTURE_GOLD', 'MODIFIER_SINGLE_CITY_ADJUST_GREATWORK_YIELD', 0, 0, NULL, NULL),
('MUSEUMSUPGRADE_GREAT_WORK_WRITING_GOLD',   'MODIFIER_SINGLE_CITY_ADJUST_GREATWORK_YIELD', 0, 0, NULL, NULL);
	
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('MUSEUMSUPGRADE_GREAT_WORK_ARTIFACT_GOLD', 'GreatWorkObjectType', 'GREATWORKOBJECT_ARTIFACT'),
('MUSEUMSUPGRADE_GREAT_WORK_ARTIFACT_GOLD', 'YieldType',           'YIELD_GOLD'),
('MUSEUMSUPGRADE_GREAT_WORK_ARTIFACT_GOLD', 'YieldChange',         '1'),
('MUSEUMSUPGRADE_GREAT_WORK_LANDSCAPE_GOLD', 'GreatWorkObjectType', 'GREATWORKOBJECT_LANDSCAPE'),
('MUSEUMSUPGRADE_GREAT_WORK_LANDSCAPE_GOLD', 'YieldType',           'YIELD_GOLD'),
('MUSEUMSUPGRADE_GREAT_WORK_LANDSCAPE_GOLD', 'YieldChange',         '1'),
('MUSEUMSUPGRADE_GREAT_WORK_MUSIC_GOLD', 'GreatWorkObjectType', 'GREATWORKOBJECT_MUSIC'),
('MUSEUMSUPGRADE_GREAT_WORK_MUSIC_GOLD', 'YieldType',           'YIELD_GOLD'),
('MUSEUMSUPGRADE_GREAT_WORK_MUSIC_GOLD', 'YieldChange',         '1'),
('MUSEUMSUPGRADE_GREAT_WORK_PORTRAIT_GOLD', 'GreatWorkObjectType', 'GREATWORKOBJECT_PORTRAIT'),
('MUSEUMSUPGRADE_GREAT_WORK_PORTRAIT_GOLD', 'YieldType',           'YIELD_GOLD'),
('MUSEUMSUPGRADE_GREAT_WORK_PORTRAIT_GOLD', 'YieldChange',         '1'),
('MUSEUMSUPGRADE_GREAT_WORK_SCULPTURE_GOLD', 'GreatWorkObjectType', 'GREATWORKOBJECT_SCULPTURE'),
('MUSEUMSUPGRADE_GREAT_WORK_SCULPTURE_GOLD', 'YieldType',           'YIELD_GOLD'),
('MUSEUMSUPGRADE_GREAT_WORK_SCULPTURE_GOLD', 'YieldChange',         '1'),
('MUSEUMSUPGRADE_GREAT_WORK_WRITING_GOLD', 'GreatWorkObjectType', 'GREATWORKOBJECT_WRITING'),
('MUSEUMSUPGRADE_GREAT_WORK_WRITING_GOLD', 'YieldType',           'YIELD_GOLD'),
('MUSEUMSUPGRADE_GREAT_WORK_WRITING_GOLD', 'YieldChange',         '1');

--------------------------------------------------------------
-- BROADCAST_CENTER

-- Amenity with RR=6 effect (wider range of broadcast)
UPDATE Buildings SET Entertainment = 1, RegionalRange = 6
WHERE BuildingType = 'BUILDING_BROADCAST_CENTER_UPGRADE';

-- +2 Culture
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange) VALUES
('BUILDING_BROADCAST_CENTER_UPGRADE', 'YIELD_CULTURE', 2);

-- +1 GMP
INSERT INTO Building_GreatPersonPoints (BuildingType, GreatPersonClassType, PointsPerTurn) VALUES
('BUILDING_BROADCAST_CENTER_UPGRADE', 'GREAT_PERSON_CLASS_MUSICIAN', 1);

-- +1 GWoM slot to Broadcast Center (EFFECT_ADJUST_EXTRA_GREAT_WORK_SLOTS)
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_BROADCAST_CENTER_UPGRADE', 'BROADCAST_CENTER_UPGRADE_ADD_GREAT_WORK_SLOTS');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('BROADCAST_CENTER_UPGRADE_ADD_GREAT_WORK_SLOTS', 'MODIFIER_SINGLE_CITY_ADJUST_EXTRA_GREAT_WORK_SLOTS', 1, 1, NULL, NULL);

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('BROADCAST_CENTER_UPGRADE_ADD_GREAT_WORK_SLOTS', 'BuildingType',      'BUILDING_BROADCAST_CENTER'),
('BROADCAST_CENTER_UPGRADE_ADD_GREAT_WORK_SLOTS', 'GreatWorkSlotType', 'GREATWORKSLOT_MUSIC'),
('BROADCAST_CENTER_UPGRADE_ADD_GREAT_WORK_SLOTS', 'Amount',            '1');

--------------------------------------------------------------
-- FILM_STUDIO

INSERT INTO BuildingReplaces (CivUniqueBuildingType, ReplacesBuildingType) VALUES
('BUILDING_FILM_STUDIO_UPGRADE', 'BUILDING_BROADCAST_CENTER_UPGRADE');

UPDATE Buildings SET TraitType = (SELECT TraitType FROM Buildings WHERE BuildingType = 'BUILDING_FILM_STUDIO') -- TRAIT_CIVILIZATION_BUILDING_FILM_STUDIO
WHERE BuildingType = 'BUILDING_FILM_STUDIO_UPGRADE';

-- +2 Amenity with RR=9 effect (wider and stronger)
UPDATE Buildings SET Entertainment = 2, RegionalRange = 9
WHERE BuildingType = 'BUILDING_FILM_STUDIO_UPGRADE';

-- +2 Culture
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange) VALUES
('BUILDING_FILM_STUDIO_UPGRADE', 'YIELD_CULTURE', 2);

-- +2 GMP
INSERT INTO Building_GreatPersonPoints (BuildingType, GreatPersonClassType, PointsPerTurn) VALUES
('BUILDING_FILM_STUDIO_UPGRADE', 'GREAT_PERSON_CLASS_MUSICIAN', 2);

-- +2 GWoM slot to Broadcast Center (EFFECT_ADJUST_EXTRA_GREAT_WORK_SLOTS)
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_FILM_STUDIO_UPGRADE', 'FILM_STUDIO_UPGRADE_ADD_GREAT_WORK_SLOTS');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('FILM_STUDIO_UPGRADE_ADD_GREAT_WORK_SLOTS', 'MODIFIER_SINGLE_CITY_ADJUST_EXTRA_GREAT_WORK_SLOTS', 1, 1, NULL, NULL);

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('FILM_STUDIO_UPGRADE_ADD_GREAT_WORK_SLOTS', 'BuildingType',      'BUILDING_FILM_STUDIO'),
('FILM_STUDIO_UPGRADE_ADD_GREAT_WORK_SLOTS', 'GreatWorkSlotType', 'GREATWORKSLOT_MUSIC'),
('FILM_STUDIO_UPGRADE_ADD_GREAT_WORK_SLOTS', 'Amount',            '2');

--------------------------------------------------------------
-- 2018-03-26 Harbor
--------------------------------------------------------------

--------------------------------------------------------------
-- LIGHTHOUSE

-- +1 Housing
UPDATE Buildings SET Housing = 1
WHERE BuildingType = 'BUILDING_LIGHTHOUSE_UPGRADE';

-- Add +1 Food from IMPROVEMENT_FISHING_BOATS and IMPROVEMENT_FISHERY
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_LIGHTHOUSE_UPGRADE', 'LIGHTHOUSE_UPGRADE_ADD_FISHING_BOATS_FOOD'),
('BUILDING_LIGHTHOUSE_UPGRADE', 'LIGHTHOUSE_UPGRADE_ADD_FISHERY_FOOD');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('LIGHTHOUSE_UPGRADE_ADD_FISHING_BOATS_FOOD', 'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD', 0, 0, NULL, 'PLOT_HAS_FISHINGBOATS_REQUIREMENTS'),
('LIGHTHOUSE_UPGRADE_ADD_FISHERY_FOOD',       'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD', 0, 0, NULL, 'PLOT_HAS_FISHERY_REQUIREMENTS');

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('LIGHTHOUSE_UPGRADE_ADD_FISHING_BOATS_FOOD', 'YieldType', 'YIELD_FOOD'),
('LIGHTHOUSE_UPGRADE_ADD_FISHING_BOATS_FOOD', 'Amount',    '1'),
('LIGHTHOUSE_UPGRADE_ADD_FISHERY_FOOD', 'YieldType', 'YIELD_FOOD'),
('LIGHTHOUSE_UPGRADE_ADD_FISHERY_FOOD', 'Amount',    '1');

INSERT INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES
('PLOT_HAS_FISHERY_REQUIREMENTS', 'REQUIREMENTSET_TEST_ALL');
	
INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES
('PLOT_HAS_FISHERY_REQUIREMENTS', 'REQUIRES_PLOT_HAS_FISHERY');

INSERT INTO Requirements (RequirementId, RequirementType) VALUES
('REQUIRES_PLOT_HAS_FISHERY', 'REQUIREMENT_PLOT_IMPROVEMENT_TYPE_MATCHES');
	
INSERT INTO RequirementArguments (RequirementId, Name, Value) VALUES
('REQUIRES_PLOT_HAS_FISHERY', 'ImprovementType', 'IMPROVEMENT_FISHERY');

--------------------------------------------------------------
-- SHIPYARD

-- +1 Housing
UPDATE Buildings SET Housing = 1
WHERE BuildingType = 'BUILDING_SHIPYARD_UPGRADE';

-- +1 prod
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange) VALUES
('BUILDING_SHIPYARD_UPGRADE', 'YIELD_PRODUCTION', 1);

-- +1 Production for each Era since constructed!
INSERT INTO Building_YieldsPerEra (BuildingType, YieldType, YieldChange) VALUES
('BUILDING_SHIPYARD_UPGRADE', 'YIELD_PRODUCTION', 1);

-- +1 GAP
INSERT INTO Building_GreatPersonPoints (BuildingType, GreatPersonClassType, PointsPerTurn) VALUES
('BUILDING_SHIPYARD_UPGRADE', 'GREAT_PERSON_CLASS_ADMIRAL', 1);

-- +3 Strength for all naval units trained here (via Ability)
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_SHIPYARD_UPGRADE', 'SHIPYARD_UPGRADE_ATTACK');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('SHIPYARD_UPGRADE_ATTACK', 'MODIFIER_SINGLE_CITY_GRANT_ABILITY_FOR_TRAINED_UNITS', 0, 0, NULL, 'SHIPYARD_SEA_REQUIREMENTS');

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('SHIPYARD_UPGRADE_ATTACK', 'AbilityType', 'ABILITY_SHIPYARD_UPGRADE_ATTACK_BUFF');

INSERT INTO Types (Type, Kind) VALUES  -- hash value generated automatically
('ABILITY_SHIPYARD_UPGRADE_ATTACK_BUFF', 'KIND_ABILITY');

INSERT INTO UnitAbilities (UnitAbilityType, Name, Description, Inactive) VALUES
('ABILITY_SHIPYARD_UPGRADE_ATTACK_BUFF', 'LOC_ABILITY_SHIPYARD_UPGRADE_ATTACK_BUFF_NAME', 'LOC_ABILITY_SHIPYARD_UPGRADE_ATTACK_BUFF_DESCRIPTION', 1);

INSERT INTO UnitAbilityModifiers (UnitAbilityType, ModifierId) VALUES
('ABILITY_SHIPYARD_UPGRADE_ATTACK_BUFF', 'SHIPYARD_UPGRADE_ATTACK_BUFF');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('SHIPYARD_UPGRADE_ATTACK_BUFF', 'MODIFIER_UNIT_ADJUST_COMBAT_STRENGTH', 0, 0, NULL, NULL);

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('SHIPYARD_UPGRADE_ATTACK_BUFF', 'Amount', '3');

INSERT INTO TypeTags (Type, Tag) VALUES
('ABILITY_SHIPYARD_UPGRADE_ATTACK_BUFF', 'CLASS_NAVAL_MELEE'),
('ABILITY_SHIPYARD_UPGRADE_ATTACK_BUFF', 'CLASS_NAVAL_RANGED'),
('ABILITY_SHIPYARD_UPGRADE_ATTACK_BUFF', 'CLASS_NAVAL_RAIDER');
--('ABILITY_FASCISM_ATTACK_BUFF', 'CLASS_AIRCRAFT'),

--------------------------------------------------------------
-- SEAPORT

-- +2 Gold
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange) VALUES
('BUILDING_SEAPORT_UPGRADE', 'YIELD_GOLD', 2);

-- Additonal Production same as Adjacency Bonus
INSERT INTO Building_YieldDistrictCopies (BuildingType, OldYieldType, NewYieldType) VALUES
('BUILDING_SEAPORT_UPGRADE', 'YIELD_GOLD', 'YIELD_PRODUCTION');

-- +1 TR
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_SEAPORT_UPGRADE', 'SEAPORT_UPGRADE_TRADE_ROUTE_CAPACITY');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('SEAPORT_UPGRADE_TRADE_ROUTE_CAPACITY', 'MODIFIER_PLAYER_ADJUST_TRADE_ROUTE_CAPACITY', 0, 0, NULL, NULL);

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('SEAPORT_UPGRADE_TRADE_ROUTE_CAPACITY', 'Amount', '1');

-- +1 gold from Fishing Boats and Fishery, +3 prod from Oil Rigs
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_SEAPORT_UPGRADE', 'SEAPORT_UPGRADE_ADD_FISHING_BOATS_GOLD'),
('BUILDING_SEAPORT_UPGRADE', 'SEAPORT_UPGRADE_ADD_FISHERY_GOLD'),
('BUILDING_SEAPORT_UPGRADE', 'SEAPORT_UPGRADE_ADD_OILRIG_PRODUCTION');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('SEAPORT_UPGRADE_ADD_FISHING_BOATS_GOLD', 'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD', 0, 0, NULL, 'PLOT_HAS_FISHINGBOATS_REQUIREMENTS'),
('SEAPORT_UPGRADE_ADD_FISHERY_GOLD',       'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD', 0, 0, NULL, 'PLOT_HAS_FISHERY_REQUIREMENTS'),
('SEAPORT_UPGRADE_ADD_OILRIG_PRODUCTION',  'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD', 0, 0, NULL, 'PLOT_HAS_OILRIG_REQUIREMENTS');

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('SEAPORT_UPGRADE_ADD_FISHING_BOATS_GOLD', 'YieldType', 'YIELD_GOLD'),
('SEAPORT_UPGRADE_ADD_FISHING_BOATS_GOLD', 'Amount',    '1'),
('SEAPORT_UPGRADE_ADD_FISHERY_GOLD', 'YieldType', 'YIELD_GOLD'),
('SEAPORT_UPGRADE_ADD_FISHERY_GOLD', 'Amount',    '1'),
('SEAPORT_UPGRADE_ADD_OILRIG_PRODUCTION', 'YieldType', 'YIELD_PRODUCTION'),
('SEAPORT_UPGRADE_ADD_OILRIG_PRODUCTION', 'Amount',    '3');

INSERT INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES
('PLOT_HAS_OILRIG_REQUIREMENTS', 'REQUIREMENTSET_TEST_ALL');

INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES
('PLOT_HAS_OILRIG_REQUIREMENTS', 'REQUIRES_PLOT_HAS_OILRIG');

INSERT INTO Requirements (RequirementId, RequirementType) VALUES
('REQUIRES_PLOT_HAS_OILRIG', 'REQUIREMENT_PLOT_IMPROVEMENT_TYPE_MATCHES');

INSERT INTO RequirementArguments (RequirementId, Name, Value) VALUES
('REQUIRES_PLOT_HAS_OILRIG', 'ImprovementType', 'IMPROVEMENT_OFFSHORE_OIL_RIG');


--------------------------------------------------------------
-- 2018-03-26 Campus
--------------------------------------------------------------

--------------------------------------------------------------
-- LIBRARY

-- +1 Amenity
UPDATE Buildings SET Entertainment = 1
WHERE BuildingType = 'BUILDING_LIBRARY_UPGRADE';

-- +1 Science
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange) VALUES
('BUILDING_LIBRARY_UPGRADE', 'YIELD_SCIENCE', 1);

--------------------------------------------------------------
-- UNIVERSITY

-- +2 Culture / +2 Science
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange) VALUES
('BUILDING_UNIVERSITY_UPGRADE', 'YIELD_CULTURE', 2),
('BUILDING_UNIVERSITY_UPGRADE', 'YIELD_SCIENCE', 2);

-- +1 GWP / +1 GSP
INSERT INTO Building_GreatPersonPoints (BuildingType, GreatPersonClassType, PointsPerTurn) VALUES
('BUILDING_UNIVERSITY_UPGRADE', 'GREAT_PERSON_CLASS_SCIENTIST', 1),
('BUILDING_UNIVERSITY_UPGRADE', 'GREAT_PERSON_CLASS_WRITER', 1);

--------------------------------------------------------------
-- MADRASA

INSERT INTO BuildingReplaces (CivUniqueBuildingType, ReplacesBuildingType) VALUES
('BUILDING_MADRASA_UPGRADE', 'BUILDING_UNIVERSITY_UPGRADE');

UPDATE Buildings SET TraitType = (SELECT TraitType FROM Buildings WHERE BuildingType = 'BUILDING_MADRASA') --'TRAIT_CIVILIZATION_BUILDING_MADRASA'
WHERE BuildingType = 'BUILDING_MADRASA_UPGRADE';

UPDATE Buildings SET Housing = 1
WHERE BuildingType = 'BUILDING_MADRASA_UPGRADE';

-- +1 GWP / +1 GSP
INSERT INTO Building_GreatPersonPoints (BuildingType, GreatPersonClassType, PointsPerTurn) VALUES
('BUILDING_MADRASA_UPGRADE', 'GREAT_PERSON_CLASS_SCIENTIST', 1),
('BUILDING_MADRASA_UPGRADE', 'GREAT_PERSON_CLASS_WRITER', 1);

-- +2 Culture / +2 Science
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange) VALUES
('BUILDING_MADRASA_UPGRADE', 'YIELD_CULTURE', 2),
('BUILDING_MADRASA_UPGRADE', 'YIELD_SCIENCE', 2);

--------------------------------------------------------------
-- RESEARCH_LAB

-- RR=9
UPDATE Buildings SET RegionalRange = 9
WHERE BuildingType = 'BUILDING_RESEARCH_LAB_UPGRADE';

-- +2 Science
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange) VALUES
('BUILDING_RESEARCH_LAB_UPGRADE', 'YIELD_SCIENCE', 2);

-- +1/+2/+3 Science to specific resources 
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_RESEARCH_LAB_UPGRADE', 'RESEARCH_LAB_UPGRADE_ADD_ALUMINUM_SCIENCE'),
--('BUILDING_RESEARCH_LAB_UPGRADE', 'RESEARCH_LAB_UPGRADE_ADD_AMBER_SCIENCE'),
('BUILDING_RESEARCH_LAB_UPGRADE', 'RESEARCH_LAB_UPGRADE_ADD_COPPER_SCIENCE'),
('BUILDING_RESEARCH_LAB_UPGRADE', 'RESEARCH_LAB_UPGRADE_ADD_OIL_SCIENCE'),
('BUILDING_RESEARCH_LAB_UPGRADE', 'RESEARCH_LAB_UPGRADE_ADD_URANIUM_SCIENCE');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('RESEARCH_LAB_UPGRADE_ADD_ALUMINUM_SCIENCE', 'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD', 0, 0, NULL, 'RESOURCE_IS_ALUMINUM'),
--('RESEARCH_LAB_UPGRADE_ADD_AMBER_SCIENCE',    'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD', 0, 0, NULL, 'RESOURCE_IS_AMBER'),
('RESEARCH_LAB_UPGRADE_ADD_COPPER_SCIENCE',   'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD', 0, 0, NULL, 'RESOURCE_IS_COPPER'),
('RESEARCH_LAB_UPGRADE_ADD_OIL_SCIENCE',      'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD', 0, 0, NULL, 'RESOURCE_IS_OIL'),
('RESEARCH_LAB_UPGRADE_ADD_URANIUM_SCIENCE',  'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD', 0, 0, NULL, 'RESOURCE_IS_URANIUM');

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('RESEARCH_LAB_UPGRADE_ADD_ALUMINUM_SCIENCE', 'YieldType', 'YIELD_SCIENCE'),
('RESEARCH_LAB_UPGRADE_ADD_ALUMINUM_SCIENCE', 'Amount',    '3'),
--('RESEARCH_LAB_UPGRADE_ADD_AMBER_SCIENCE', 'YieldType', 'YIELD_SCIENCE'),
--('RESEARCH_LAB_UPGRADE_ADD_AMBER_SCIENCE', 'Amount',    '1'),
('RESEARCH_LAB_UPGRADE_ADD_COPPER_SCIENCE', 'YieldType', 'YIELD_SCIENCE'),
('RESEARCH_LAB_UPGRADE_ADD_COPPER_SCIENCE', 'Amount',    '3'),
('RESEARCH_LAB_UPGRADE_ADD_OIL_SCIENCE', 'YieldType', 'YIELD_SCIENCE'),
('RESEARCH_LAB_UPGRADE_ADD_OIL_SCIENCE', 'Amount',    '2'),
('RESEARCH_LAB_UPGRADE_ADD_URANIUM_SCIENCE', 'YieldType', 'YIELD_SCIENCE'),
('RESEARCH_LAB_UPGRADE_ADD_URANIUM_SCIENCE', 'Amount',    '4');

INSERT INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES
('RESOURCE_IS_ALUMINUM', 'REQUIREMENTSET_TEST_ALL'),
('RESOURCE_IS_AMBER',    'REQUIREMENTSET_TEST_ALL'),
('RESOURCE_IS_COPPER',   'REQUIREMENTSET_TEST_ALL'),
('RESOURCE_IS_OIL',      'REQUIREMENTSET_TEST_ALL'),
('RESOURCE_IS_URANIUM',  'REQUIREMENTSET_TEST_ALL');

INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES
('RESOURCE_IS_ALUMINUM', 'REQUIRES_ALUMINUM_IN_PLOT'),
('RESOURCE_IS_AMBER',    'REQUIRES_AMBER_IN_PLOT'),
('RESOURCE_IS_COPPER',   'REQUIRES_COPPER_IN_PLOT'),
('RESOURCE_IS_OIL',      'REQUIRES_OIL_IN_PLOT'),
('RESOURCE_IS_URANIUM',  'REQUIRES_URANIUM_IN_PLOT');

INSERT INTO Requirements (RequirementId, RequirementType) VALUES
('REQUIRES_ALUMINUM_IN_PLOT', 'REQUIREMENT_PLOT_RESOURCE_TYPE_MATCHES'),
('REQUIRES_AMBER_IN_PLOT',    'REQUIREMENT_PLOT_RESOURCE_TYPE_MATCHES'),
('REQUIRES_COPPER_IN_PLOT',   'REQUIREMENT_PLOT_RESOURCE_TYPE_MATCHES'),
('REQUIRES_OIL_IN_PLOT',      'REQUIREMENT_PLOT_RESOURCE_TYPE_MATCHES'),
('REQUIRES_URANIUM_IN_PLOT',  'REQUIREMENT_PLOT_RESOURCE_TYPE_MATCHES');

INSERT INTO RequirementArguments (RequirementId, Name, Value) VALUES
('REQUIRES_ALUMINUM_IN_PLOT', 'ResourceType', 'RESOURCE_ALUMINUM'),
('REQUIRES_AMBER_IN_PLOT',    'ResourceType', 'RESOURCE_AMBER'),
('REQUIRES_COPPER_IN_PLOT',   'ResourceType', 'RESOURCE_COPPER'),
('REQUIRES_OIL_IN_PLOT',      'ResourceType', 'RESOURCE_OIL'),
('REQUIRES_URANIUM_IN_PLOT',  'ResourceType', 'RESOURCE_URANIUM');


--------------------------------------------------------------
-- 2018-03-27 Commercial Hub
--------------------------------------------------------------

--------------------------------------------------------------
-- MARKET

-- +2 Gold
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange) VALUES
('BUILDING_MARKET_UPGRADE', 'YIELD_GOLD', 2);

-- +2 Gold from RESOURCE_CITRUS, RESOURCE_COCOA, RESOURCE_OLIVES, RESOURCE_SPICES, RESOURCE_SUGAR, RESOURCE_TEA
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_MARKET_UPGRADE', 'MARKET_UPGRADE_ADD_RESOURCE_GOLD');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('MARKET_UPGRADE_ADD_RESOURCE_GOLD', 'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD', 0, 0, NULL, 'RESOURCES_FOR_MARKET_UPGRADE');

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('MARKET_UPGRADE_ADD_RESOURCE_GOLD', 'YieldType', 'YIELD_GOLD'),
('MARKET_UPGRADE_ADD_RESOURCE_GOLD', 'Amount',    '2');

INSERT INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES
('RESOURCES_FOR_MARKET_UPGRADE', 'REQUIREMENTSET_TEST_ANY');

INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES
('RESOURCES_FOR_MARKET_UPGRADE', 'REQUIRES_CITRUS_IN_PLOT'),
('RESOURCES_FOR_MARKET_UPGRADE', 'REQUIRES_COCOA_IN_PLOT'),
('RESOURCES_FOR_MARKET_UPGRADE', 'REQUIRES_OLIVES_IN_PLOT'),
('RESOURCES_FOR_MARKET_UPGRADE', 'REQUIRES_SPICES_IN_PLOT'),
('RESOURCES_FOR_MARKET_UPGRADE', 'REQUIRES_SUGAR_IN_PLOT'),
('RESOURCES_FOR_MARKET_UPGRADE', 'REQUIRES_TEA_IN_PLOT');

INSERT INTO Requirements (RequirementId, RequirementType) VALUES
('REQUIRES_CITRUS_IN_PLOT', 'REQUIREMENT_PLOT_RESOURCE_TYPE_MATCHES'),
('REQUIRES_COCOA_IN_PLOT',  'REQUIREMENT_PLOT_RESOURCE_TYPE_MATCHES'),
('REQUIRES_OLIVES_IN_PLOT', 'REQUIREMENT_PLOT_RESOURCE_TYPE_MATCHES'),
('REQUIRES_SPICES_IN_PLOT', 'REQUIREMENT_PLOT_RESOURCE_TYPE_MATCHES'),
('REQUIRES_SUGAR_IN_PLOT',  'REQUIREMENT_PLOT_RESOURCE_TYPE_MATCHES'),
('REQUIRES_TEA_IN_PLOT',    'REQUIREMENT_PLOT_RESOURCE_TYPE_MATCHES');

INSERT INTO RequirementArguments (RequirementId, Name, Value) VALUES
('REQUIRES_CITRUS_IN_PLOT', 'ResourceType', 'RESOURCE_CITRUS'),
('REQUIRES_COCOA_IN_PLOT',  'ResourceType', 'RESOURCE_COCOA'),
('REQUIRES_OLIVES_IN_PLOT', 'ResourceType', 'RESOURCE_OLIVES'),
('REQUIRES_SPICES_IN_PLOT', 'ResourceType', 'RESOURCE_SPICES'),
('REQUIRES_SUGAR_IN_PLOT',  'ResourceType', 'RESOURCE_SUGAR'),
('REQUIRES_TEA_IN_PLOT',    'ResourceType', 'RESOURCE_TEA');


--------------------------------------------------------------
-- SUKIENNICE (Poland DLC)

UPDATE Buildings SET TraitType = 'TRAIT_CIVILIZATION_BUILDING_SUKIENNICE' WHERE BuildingType = 'BUILDING_SUKIENNICE_UPGRADE';

INSERT INTO BuildingReplaces (CivUniqueBuildingType, ReplacesBuildingType) VALUES
('BUILDING_SUKIENNICE_UPGRADE', 'BUILDING_MARKET_UPGRADE');

-- +2 Gold
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange)
SELECT 'BUILDING_SUKIENNICE_UPGRADE', 'YIELD_GOLD', 2
FROM Buildings
WHERE BuildingType = 'BUILDING_SUKIENNICE';

-- +1 GMP
INSERT INTO Building_GreatPersonPoints (BuildingType, GreatPersonClassType, PointsPerTurn)
SELECT 'BUILDING_SUKIENNICE_UPGRADE', 'GREAT_PERSON_CLASS_MERCHANT', 1
FROM Buildings
WHERE BuildingType = 'BUILDING_SUKIENNICE';

-- Same as Market
INSERT INTO BuildingModifiers (BuildingType, ModifierId)
SELECT 'BUILDING_SUKIENNICE_UPGRADE', 'MARKET_UPGRADE_ADD_RESOURCE_GOLD'
FROM Buildings
WHERE BuildingType = 'BUILDING_SUKIENNICE';

--------------------------------------------------------------
-- BANK

-- +2 Gold
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange) VALUES
('BUILDING_BANK_UPGRADE', 'YIELD_GOLD', 2);

-- +1 GMP
INSERT INTO Building_GreatPersonPoints (BuildingType, GreatPersonClassType, PointsPerTurn) VALUES
('BUILDING_BANK_UPGRADE', 'GREAT_PERSON_CLASS_MERCHANT', 1);

-- +2/+4 to outgoing domestic/international TR in the City
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_BANK_UPGRADE', 'BANK_UPGRADE_DOMESTIC_GOLD'),
('BUILDING_BANK_UPGRADE', 'BANK_UPGRADE_INTERNATIONAL_GOLD');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('BANK_UPGRADE_DOMESTIC_GOLD',      'MODIFIER_SINGLE_CITY_ADJUST_TRADE_ROUTE_YIELD_FOR_DOMESTIC',      0, 0, NULL, NULL),
('BANK_UPGRADE_INTERNATIONAL_GOLD', 'MODIFIER_SINGLE_CITY_ADJUST_TRADE_ROUTE_YIELD_FOR_INTERNATIONAL', 0, 0, NULL, NULL);

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('BANK_UPGRADE_DOMESTIC_GOLD', 'YieldType', 'YIELD_GOLD'),
('BANK_UPGRADE_DOMESTIC_GOLD', 'Amount',    '2'),
('BANK_UPGRADE_INTERNATIONAL_GOLD', 'YieldType', 'YIELD_GOLD'),
('BANK_UPGRADE_INTERNATIONAL_GOLD', 'Amount',    '4');

-- +2 Gold from RESOURCE_DIAMONDS, RESOURCE_GOLD, RESOURCE_SILVER
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_BANK_UPGRADE', 'BANK_UPGRADE_ADD_RESOURCE_GOLD');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('BANK_UPGRADE_ADD_RESOURCE_GOLD', 'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD', 0, 0, NULL, 'RESOURCES_FOR_BANK_UPGRADE');

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('BANK_UPGRADE_ADD_RESOURCE_GOLD', 'YieldType', 'YIELD_GOLD'),
('BANK_UPGRADE_ADD_RESOURCE_GOLD', 'Amount',    '2');

INSERT INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES
('RESOURCES_FOR_BANK_UPGRADE', 'REQUIREMENTSET_TEST_ANY');

INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES
('RESOURCES_FOR_BANK_UPGRADE', 'REQUIRES_DIAMONDS_IN_PLOT'),
('RESOURCES_FOR_BANK_UPGRADE', 'REQUIRES_GOLD_IN_PLOT'),
('RESOURCES_FOR_BANK_UPGRADE', 'REQUIRES_SILVER_IN_PLOT');

INSERT INTO Requirements (RequirementId, RequirementType) VALUES
('REQUIRES_DIAMONDS_IN_PLOT', 'REQUIREMENT_PLOT_RESOURCE_TYPE_MATCHES'),
('REQUIRES_GOLD_IN_PLOT',     'REQUIREMENT_PLOT_RESOURCE_TYPE_MATCHES'),
('REQUIRES_SILVER_IN_PLOT',   'REQUIREMENT_PLOT_RESOURCE_TYPE_MATCHES');

INSERT INTO RequirementArguments (RequirementId, Name, Value) VALUES
('REQUIRES_DIAMONDS_IN_PLOT', 'ResourceType', 'RESOURCE_DIAMONDS'),
('REQUIRES_GOLD_IN_PLOT',     'ResourceType', 'RESOURCE_GOLD'),
('REQUIRES_SILVER_IN_PLOT',   'ResourceType', 'RESOURCE_SILVER');

--------------------------------------------------------------
-- STOCK_EXCHANGE

-- RR=9
UPDATE Buildings SET RegionalRange = 9
WHERE BuildingType = 'BUILDING_STOCK_EXCHANGE_UPGRADE';

-- +2 Gold
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange) VALUES
('BUILDING_STOCK_EXCHANGE_UPGRADE', 'YIELD_GOLD', 2);

-- +2 Gold for each specialty district constructed
INSERT INTO Types (Type, Kind)  -- hash value generated automatically
VALUES ('MODIFIER_SINGLE_CITY_ADJUST_CITY_YIELD_PER_DISTRICT', 'KIND_MODIFIER');

INSERT INTO DynamicModifiers (ModifierType, CollectionType, EffectType)
VALUES ('MODIFIER_SINGLE_CITY_ADJUST_CITY_YIELD_PER_DISTRICT', 'COLLECTION_OWNER', 'EFFECT_ADJUST_CITY_YIELD_PER_DISTRICT');

INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_STOCK_EXCHANGE_UPGRADE', 'STOCK_EXCHANGE_UPGRADE_GOLD_PER_DISTRICT');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('STOCK_EXCHANGE_UPGRADE_GOLD_PER_DISTRICT', 'MODIFIER_SINGLE_CITY_ADJUST_CITY_YIELD_PER_DISTRICT', 0, 0, NULL, NULL);

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('STOCK_EXCHANGE_UPGRADE_GOLD_PER_DISTRICT', 'YieldType', 'YIELD_GOLD'),
('STOCK_EXCHANGE_UPGRADE_GOLD_PER_DISTRICT', 'Amount',    '2');

/* NOT USED
-- +2 Gold from each yield-producing civilian district in the city (except CH), additional +1 from unique districts
-- CULTURE    - DISTRICT_THEATER / DISTRICT_ACROPOLIS
-- SCIENCE    - DISTRICT_CAMPUS / DISTRICT_SEOWON
-- PRODUCTION - DISTRICT_INDUSTRIAL_ZONE / DISTRICT_HANSA
-- FAITH      - DISTRICT_HOLY_SITE / DISTRICT_LAVRA
-- DISTRICT_HARBOR / DISTRICT_ROYAL_NAVY_DOCKYARD
-- DISTRICT_AERODROME

INSERT INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES
('CITY_HAS_DISTRICT_AERODROME', 'REQUIREMENTSET_TEST_ALL'),
('CITY_HAS_DISTRICT_CAMPUS',    'REQUIREMENTSET_TEST_ALL'),
('CITY_HAS_DISTRICT_HARBOR',    'REQUIREMENTSET_TEST_ALL');

INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES
('CITY_HAS_DISTRICT_AERODROME', 'REQUIRES_CITY_HAS_AERODROME'),
('CITY_HAS_DISTRICT_CAMPUS',    'REQUIRES_CITY_HAS_CAMPUS'),
('CITY_HAS_DISTRICT_HARBOR',    'REQUIRES_CITY_HAS_HARBOR');

INSERT INTO Requirements (RequirementId, RequirementType) VALUES
('REQUIRES_CITY_HAS_AERODROME', 'REQUIREMENT_CITY_HAS_DISTRICT');

INSERT INTO RequirementArguments (RequirementId, Name, Value) VALUES
('REQUIRES_CITY_HAS_AERODROME', 'DistrictType', 'DISTRICT_AERODROME');
-- exists
--REQUIRES_CITY_HAS_THEATER_DISTRICT - will it count Acropolis as well?
--REQUIRES_CITY_HAS_CAMPUS
--REQUIRES_CITY_HAS_COMMERCIAL_HUB
--REQUIRES_CITY_HAS_HARBOR
--REQUIRES_CITY_HAS_INDUSTRIAL_ZONE
*/


--------------------------------------------------------------
-- 2018-03-27 Holy Site
--------------------------------------------------------------

--------------------------------------------------------------
-- SHRINE

-- +1 Faith
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange) VALUES
('BUILDING_SHRINE_UPGRADE', 'YIELD_FAITH', 1);

-- +1 GPP
INSERT INTO Building_GreatPersonPoints (BuildingType, GreatPersonClassType, PointsPerTurn) VALUES
('BUILDING_SHRINE_UPGRADE', 'GREAT_PERSON_CLASS_PROPHET', 1);

--------------------------------------------------------------
-- TEMPLE

-- +2 Faith, +1 Food
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange) VALUES
('BUILDING_TEMPLE_UPGRADE', 'YIELD_FAITH', 2),
('BUILDING_TEMPLE_UPGRADE', 'YIELD_FOOD', 1);

-- +1 GWR slot to Temple (EFFECT_ADJUST_EXTRA_GREAT_WORK_SLOTS)
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_TEMPLE_UPGRADE', 'TEMPLE_UPGRADE_ADD_GREAT_WORK_SLOTS');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('TEMPLE_UPGRADE_ADD_GREAT_WORK_SLOTS', 'MODIFIER_SINGLE_CITY_ADJUST_EXTRA_GREAT_WORK_SLOTS', 1, 1, NULL, NULL);

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('TEMPLE_UPGRADE_ADD_GREAT_WORK_SLOTS', 'BuildingType',      'BUILDING_TEMPLE'),
('TEMPLE_UPGRADE_ADD_GREAT_WORK_SLOTS', 'GreatWorkSlotType', 'GREATWORKSLOT_RELIC'),
('TEMPLE_UPGRADE_ADD_GREAT_WORK_SLOTS', 'Amount',            '1');

-- +2 Faith from RESOURCE_DYES, RESOURCE_INCENSE, RESOURCE_TOBACCO
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_TEMPLE_UPGRADE', 'TEMPLE_UPGRADE_ADD_RESOURCE_FAITH');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('TEMPLE_UPGRADE_ADD_RESOURCE_FAITH', 'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD', 0, 0, NULL, 'RESOURCES_FOR_TEMPLE_UPGRADE');

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('TEMPLE_UPGRADE_ADD_RESOURCE_FAITH', 'YieldType', 'YIELD_FAITH'),
('TEMPLE_UPGRADE_ADD_RESOURCE_FAITH', 'Amount',    '2');

INSERT INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES
('RESOURCES_FOR_TEMPLE_UPGRADE', 'REQUIREMENTSET_TEST_ANY');

INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES
('RESOURCES_FOR_TEMPLE_UPGRADE', 'REQUIRES_DYES_IN_PLOT'),
('RESOURCES_FOR_TEMPLE_UPGRADE', 'REQUIRES_INCENSE_IN_PLOT'),
('RESOURCES_FOR_TEMPLE_UPGRADE', 'REQUIRES_TOBACCO_IN_PLOT');

INSERT INTO Requirements (RequirementId, RequirementType) VALUES
('REQUIRES_DYES_IN_PLOT',    'REQUIREMENT_PLOT_RESOURCE_TYPE_MATCHES'),
('REQUIRES_INCENSE_IN_PLOT', 'REQUIREMENT_PLOT_RESOURCE_TYPE_MATCHES'),
('REQUIRES_TOBACCO_IN_PLOT', 'REQUIREMENT_PLOT_RESOURCE_TYPE_MATCHES');

INSERT INTO RequirementArguments (RequirementId, Name, Value) VALUES
('REQUIRES_DYES_IN_PLOT',    'ResourceType', 'RESOURCE_DYES'),
('REQUIRES_INCENSE_IN_PLOT', 'ResourceType', 'RESOURCE_INCENSE'),
('REQUIRES_TOBACCO_IN_PLOT', 'ResourceType', 'RESOURCE_TOBACCO');

--------------------------------------------------------------
-- STAVE_CHURCH

UPDATE Buildings SET TraitType = 'TRAIT_CIVILIZATION_BUILDING_STAVE_CHURCH' WHERE BuildingType = 'BUILDING_STAVE_CHURCH_UPGRADE';

INSERT INTO BuildingReplaces (CivUniqueBuildingType, ReplacesBuildingType) VALUES
('BUILDING_STAVE_CHURCH_UPGRADE', 'BUILDING_TEMPLE_UPGRADE');

-- +2 Faith, +1 Food
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange) VALUES
('BUILDING_STAVE_CHURCH_UPGRADE', 'YIELD_FAITH', 2),
('BUILDING_STAVE_CHURCH_UPGRADE', 'YIELD_FOOD', 1);

-- +1 GWR slot to Stave Church (EFFECT_ADJUST_EXTRA_GREAT_WORK_SLOTS)
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_STAVE_CHURCH_UPGRADE', 'STAVE_CHURCH_UPGRADE_ADD_GREAT_WORK_SLOTS');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('STAVE_CHURCH_UPGRADE_ADD_GREAT_WORK_SLOTS', 'MODIFIER_SINGLE_CITY_ADJUST_EXTRA_GREAT_WORK_SLOTS', 1, 1, NULL, NULL);

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('STAVE_CHURCH_UPGRADE_ADD_GREAT_WORK_SLOTS', 'BuildingType',      'BUILDING_STAVE_CHURCH'),
('STAVE_CHURCH_UPGRADE_ADD_GREAT_WORK_SLOTS', 'GreatWorkSlotType', 'GREATWORKSLOT_RELIC'),
('STAVE_CHURCH_UPGRADE_ADD_GREAT_WORK_SLOTS', 'Amount',            '1');

-- Same as Temple
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_STAVE_CHURCH_UPGRADE', 'TEMPLE_UPGRADE_ADD_RESOURCE_FAITH');

-- +1 Faith from Lumber Mills
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_STAVE_CHURCH_UPGRADE', 'STAVECHURCHUPGRADE_ADDLUMBERMILLFAITH');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('STAVECHURCHUPGRADE_ADDLUMBERMILLFAITH', 'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD', 0, 0, NULL, 'PLOT_HAS_LUMBER_MILL_REQUIREMENTS');
	
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('STAVECHURCHUPGRADE_ADDLUMBERMILLFAITH', 'YieldType', 'YIELD_FAITH'),
('STAVECHURCHUPGRADE_ADDLUMBERMILLFAITH', 'Amount',    '1');

INSERT INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES
('PLOT_HAS_LUMBER_MILL_REQUIREMENTS', 'REQUIREMENTSET_TEST_ALL');
	
INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES
('PLOT_HAS_LUMBER_MILL_REQUIREMENTS', 'REQUIRES_PLOT_HAS_LUMBER_MILL');

INSERT INTO Requirements (RequirementId, RequirementType) VALUES
('REQUIRES_PLOT_HAS_LUMBER_MILL', 'REQUIREMENT_PLOT_IMPROVEMENT_TYPE_MATCHES');
	
INSERT INTO RequirementArguments (RequirementId, Name, Value) VALUES
('REQUIRES_PLOT_HAS_LUMBER_MILL', 'ImprovementType', 'IMPROVEMENT_LUMBER_MILL');

--------------------------------------------------------------
-- PRASAT (Khmer DLC)

UPDATE Buildings SET TraitType = 'TRAIT_CIVILIZATION_BUILDING_PRASAT' WHERE BuildingType = 'BUILDING_PRASAT_UPGRADE';

INSERT INTO BuildingReplaces (CivUniqueBuildingType, ReplacesBuildingType)
SELECT 'BUILDING_PRASAT_UPGRADE', 'BUILDING_TEMPLE_UPGRADE'
FROM Buildings
WHERE BuildingType = 'BUILDING_PRASAT';

-- +2 Faith
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange)
SELECT 'BUILDING_PRASAT_UPGRADE', 'YIELD_FAITH', 2
FROM Buildings
WHERE BuildingType = 'BUILDING_PRASAT';

-- +1 Food
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange)
SELECT 'BUILDING_PRASAT_UPGRADE', 'YIELD_FOOD', 1
FROM Buildings
WHERE BuildingType = 'BUILDING_PRASAT';

-- +1 GWR slot to Prasat (EFFECT_ADJUST_EXTRA_GREAT_WORK_SLOTS)
INSERT INTO BuildingModifiers (BuildingType, ModifierId) 
SELECT 'BUILDING_PRASAT_UPGRADE', 'PRASAT_UPGRADE_ADD_GREAT_WORK_SLOTS'
FROM Buildings
WHERE BuildingType = 'BUILDING_PRASAT';

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) 
SELECT 'PRASAT_UPGRADE_ADD_GREAT_WORK_SLOTS', 'MODIFIER_SINGLE_CITY_ADJUST_EXTRA_GREAT_WORK_SLOTS', 1, 1, NULL, NULL
FROM Buildings
WHERE BuildingType = 'BUILDING_PRASAT';

INSERT INTO ModifierArguments (ModifierId, Name, Value) 
SELECT 'PRASAT_UPGRADE_ADD_GREAT_WORK_SLOTS', 'BuildingType', 'BUILDING_PRASAT'
FROM Buildings
WHERE BuildingType = 'BUILDING_PRASAT';

INSERT INTO ModifierArguments (ModifierId, Name, Value) 
SELECT 'PRASAT_UPGRADE_ADD_GREAT_WORK_SLOTS', 'GreatWorkSlotType', 'GREATWORKSLOT_RELIC'
FROM Buildings
WHERE BuildingType = 'BUILDING_PRASAT';

INSERT INTO ModifierArguments (ModifierId, Name, Value) 
SELECT 'PRASAT_UPGRADE_ADD_GREAT_WORK_SLOTS', 'Amount', '1'
FROM Buildings
WHERE BuildingType = 'BUILDING_PRASAT';

-- Same as Temple
INSERT INTO BuildingModifiers (BuildingType, ModifierId)
SELECT 'BUILDING_PRASAT_UPGRADE', 'TEMPLE_UPGRADE_ADD_RESOURCE_FAITH'
FROM Buildings
WHERE BuildingType = 'BUILDING_PRASAT';

-- +2 Tourism
INSERT INTO BuildingModifiers (BuildingType, ModifierId)
SELECT 'BUILDING_PRASAT_UPGRADE', 'PRASAT_UPGRADE_TOURISM'
FROM Buildings
WHERE BuildingType = 'BUILDING_PRASAT';

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId)
SELECT 'PRASAT_UPGRADE_TOURISM', 'MODIFIER_PLAYER_DISTRICT_ADJUST_TOURISM_CHANGE', 0, 0, NULL, NULL
FROM Buildings
WHERE BuildingType = 'BUILDING_PRASAT';

INSERT INTO ModifierArguments (ModifierId, Name, Value)
SELECT 'PRASAT_UPGRADE_TOURISM', 'Amount', '2'
FROM Buildings
WHERE BuildingType = 'BUILDING_PRASAT';

--------------------------------------------------------------
-- Buildings enabled by Religion - removed
-- 2018-03-05 Game only allows for 1 such building, so Upgrades cannot be built :(

--INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange) VALUES -- generated from Excel
--('BUILDING_CATHEDRAL_UPGRADE', 'YIELD_FAITH', 2),
--('BUILDING_CATHEDRAL_UPGRADE', 'YIELD_FOOD', 2),
--('BUILDING_DAR_E_MEHR_UPGRADE', 'YIELD_FAITH', 2),
--('BUILDING_DAR_E_MEHR_UPGRADE', 'YIELD_SCIENCE', 2),
--('BUILDING_GURDWARA_UPGRADE', 'YIELD_CULTURE', 1),
--('BUILDING_GURDWARA_UPGRADE', 'YIELD_FAITH', 2),
--('BUILDING_GURDWARA_UPGRADE', 'YIELD_FOOD', 1),
--('BUILDING_MEETING_HOUSE_UPGRADE', 'YIELD_FAITH', 2),
--('BUILDING_MEETING_HOUSE_UPGRADE', 'YIELD_PRODUCTION', 1),
--('BUILDING_MEETING_HOUSE_UPGRADE', 'YIELD_SCIENCE', 1),
--('BUILDING_MOSQUE_UPGRADE', 'YIELD_FAITH', 2),
--('BUILDING_MOSQUE_UPGRADE', 'YIELD_GOLD', 3),
--('BUILDING_PAGODA_UPGRADE', 'YIELD_CULTURE', 2),
--('BUILDING_PAGODA_UPGRADE', 'YIELD_FAITH', 2),
--('BUILDING_STABLE_UPGRADE', 'YIELD_PRODUCTION', 1),
--('BUILDING_STUPA_UPGRADE', 'YIELD_FAITH', 2),
--('BUILDING_STUPA_UPGRADE', 'YIELD_CULTURE', 1),
--('BUILDING_STUPA_UPGRADE', 'YIELD_FOOD', 1),
--('BUILDING_SYNAGOGUE_UPGRADE', 'YIELD_FAITH', 2),
--('BUILDING_SYNAGOGUE_UPGRADE', 'YIELD_PRODUCTION', 1),
--('BUILDING_SYNAGOGUE_UPGRADE', 'YIELD_GOLD', 2),
--('BUILDING_WAT_UPGRADE', 'YIELD_FAITH', 2),
--('BUILDING_WAT_UPGRADE', 'YIELD_PRODUCTION', 1),
--('BUILDING_WAT_UPGRADE', 'YIELD_SCIENCE', 1);


--------------------------------------------------------------
-- 2018-03-27 Entertainment Complex
--------------------------------------------------------------

--------------------------------------------------------------
-- ARENA

-- +2 Culture
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange) VALUES
('BUILDING_ARENA_UPGRADE', 'YIELD_CULTURE', 2);

-- +2 Culture from RESOURCE_COFFEE, RESOURCE_JADE, RESOURCE_MARBLE, RESOURCE_SILK
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_ARENA_UPGRADE', 'ARENA_UPGRADE_ADD_RESOURCE_CULTURE');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('ARENA_UPGRADE_ADD_RESOURCE_CULTURE', 'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD', 0, 0, NULL, 'RESOURCES_FOR_ARENA_UPGRADE');

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('ARENA_UPGRADE_ADD_RESOURCE_CULTURE', 'YieldType', 'YIELD_CULTURE'),
('ARENA_UPGRADE_ADD_RESOURCE_CULTURE', 'Amount',    '2');

INSERT INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES
('RESOURCES_FOR_ARENA_UPGRADE', 'REQUIREMENTSET_TEST_ANY');

INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES
('RESOURCES_FOR_ARENA_UPGRADE', 'REQUIRES_COFFEE_IN_PLOT'),
('RESOURCES_FOR_ARENA_UPGRADE', 'REQUIRES_JADE_IN_PLOT'),
('RESOURCES_FOR_ARENA_UPGRADE', 'REQUIRES_MARBLE_IN_PLOT'),
('RESOURCES_FOR_ARENA_UPGRADE', 'REQUIRES_SILK_IN_PLOT');

INSERT INTO Requirements (RequirementId, RequirementType) VALUES
('REQUIRES_COFFEE_IN_PLOT', 'REQUIREMENT_PLOT_RESOURCE_TYPE_MATCHES'),
('REQUIRES_JADE_IN_PLOT',   'REQUIREMENT_PLOT_RESOURCE_TYPE_MATCHES'),
('REQUIRES_MARBLE_IN_PLOT', 'REQUIREMENT_PLOT_RESOURCE_TYPE_MATCHES'),
('REQUIRES_SILK_IN_PLOT',   'REQUIREMENT_PLOT_RESOURCE_TYPE_MATCHES');

INSERT INTO RequirementArguments (RequirementId, Name, Value) VALUES
('REQUIRES_COFFEE_IN_PLOT', 'ResourceType', 'RESOURCE_COFFEE'),
('REQUIRES_JADE_IN_PLOT',   'ResourceType', 'RESOURCE_JADE'),
('REQUIRES_MARBLE_IN_PLOT', 'ResourceType', 'RESOURCE_MARBLE'),
('REQUIRES_SILK_IN_PLOT',   'ResourceType', 'RESOURCE_SILK');

--------------------------------------------------------------
-- TLACHTLI (Aztecs DLC)

UPDATE Buildings SET TraitType = 'TRAIT_CIVILIZATION_BUILDING_TLACHTLI' WHERE BuildingType = 'BUILDING_TLACHTLI_UPGRADE';

INSERT INTO BuildingReplaces (CivUniqueBuildingType, ReplacesBuildingType)
SELECT 'BUILDING_TLACHTLI_UPGRADE', 'BUILDING_ARENA_UPGRADE'
FROM Buildings
WHERE BuildingType = 'BUILDING_TLACHTLI';

-- +1 Amenity
UPDATE Buildings SET Entertainment = 1
WHERE BuildingType = 'BUILDING_TLACHTLI_UPGRADE';

-- +2 Culture
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange)
SELECT 'BUILDING_TLACHTLI_UPGRADE', 'YIELD_CULTURE', 2
FROM Buildings
WHERE BuildingType = 'BUILDING_TLACHTLI';

-- +1 Faith
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange)
SELECT 'BUILDING_TLACHTLI_UPGRADE', 'YIELD_FAITH', 1
FROM Buildings
WHERE BuildingType = 'BUILDING_TLACHTLI';

-- same as Arena
INSERT INTO BuildingModifiers (BuildingType, ModifierId)
SELECT 'BUILDING_TLACHTLI_UPGRADE', 'ARENA_UPGRADE_ADD_RESOURCE_CULTURE'
FROM Buildings
WHERE BuildingType = 'BUILDING_TLACHTLI';

--------------------------------------------------------------
-- ZOO

-- +3 Tourism
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_ZOO_UPGRADE', 'ZOO_UPGRADE_TOURISM');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('ZOO_UPGRADE_TOURISM', 'MODIFIER_PLAYER_DISTRICT_ADJUST_TOURISM_CHANGE', 0, 0, NULL, NULL);

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('ZOO_UPGRADE_TOURISM', 'Amount', '3');

--------------------------------------------------------------
-- STADIUM

-- +1 Amenity, RR=9
UPDATE Buildings SET Entertainment = 1, RegionalRange = 9 
WHERE BuildingType = 'BUILDING_STADIUM_UPGRADE';

-- +10% to All Tourism
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_STADIUM_UPGRADE', 'STADIUM_UPGRADE_BOOST_ALL_TOURISM');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('STADIUM_UPGRADE_BOOST_ALL_TOURISM', 'MODIFIER_PLAYER_ADJUST_TOURISM', 0, 0, NULL, NULL);
	
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('STADIUM_UPGRADE_BOOST_ALL_TOURISM', 'Amount', '10');


--------------------------------------------------------------
-- 2018-03-28 Aerodrome
--------------------------------------------------------------

--------------------------------------------------------------
-- HANGAR

-- +2 Production
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange) VALUES
('BUILDING_HANGAR_UPGRADE', 'YIELD_PRODUCTION', 2);

-- +1 Air Slot
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_HANGAR_UPGRADE', 'HANGAR_UPGRADE_BONUS_AIR_SLOTS');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('HANGAR_UPGRADE_BONUS_AIR_SLOTS', 'MODIFIER_PLAYER_DISTRICT_GRANT_AIR_SLOTS', 0, 1, NULL, NULL);
	
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('HANGAR_UPGRADE_BONUS_AIR_SLOTS', 'Amount', '1');

-- +2 Tourism
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_HANGAR_UPGRADE', 'HANGAR_UPGRADE_TOURISM');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('HANGAR_UPGRADE_TOURISM', 'MODIFIER_PLAYER_DISTRICT_ADJUST_TOURISM_CHANGE', 0, 0, NULL, NULL);

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('HANGAR_UPGRADE_TOURISM', 'Amount', '2');

-- +3 Strength for all air units trained here (via Ability)
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_HANGAR_UPGRADE', 'HANGAR_UPGRADE_ATTACK');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('HANGAR_UPGRADE_ATTACK', 'MODIFIER_SINGLE_CITY_GRANT_ABILITY_FOR_TRAINED_UNITS', 0, 0, NULL, 'HANGAR_UNIT_REQUIREMENTS');

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('HANGAR_UPGRADE_ATTACK', 'AbilityType', 'ABILITY_HANGAR_UPGRADE_ATTACK_BUFF');

INSERT INTO Types (Type, Kind) VALUES  -- hash value generated automatically
('ABILITY_HANGAR_UPGRADE_ATTACK_BUFF', 'KIND_ABILITY');

INSERT INTO UnitAbilities (UnitAbilityType, Name, Description, Inactive) VALUES
('ABILITY_HANGAR_UPGRADE_ATTACK_BUFF', 'LOC_ABILITY_HANGAR_UPGRADE_ATTACK_BUFF_NAME', 'LOC_ABILITY_HANGAR_UPGRADE_ATTACK_BUFF_DESCRIPTION', 1);

INSERT INTO UnitAbilityModifiers (UnitAbilityType, ModifierId) VALUES
('ABILITY_HANGAR_UPGRADE_ATTACK_BUFF', 'HANGAR_UPGRADE_ATTACK_BUFF');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('HANGAR_UPGRADE_ATTACK_BUFF', 'MODIFIER_UNIT_ADJUST_COMBAT_STRENGTH', 0, 0, NULL, NULL);

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('HANGAR_UPGRADE_ATTACK_BUFF', 'Amount', '3');

INSERT INTO TypeTags (Type, Tag) VALUES
('ABILITY_HANGAR_UPGRADE_ATTACK_BUFF', 'CLASS_AIRCRAFT');

--------------------------------------------------------------
-- AIRPORT

-- +2 Housing
UPDATE Buildings SET Housing = 2
WHERE BuildingType = 'BUILDING_AIRPORT_UPGRADE';

-- +2 Production
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange) VALUES
('BUILDING_AIRPORT_UPGRADE', 'YIELD_PRODUCTION', 2);

-- +1 Air Slot
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_AIRPORT_UPGRADE', 'AIRPORT_UPGRADE_BONUS_AIR_SLOTS');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('AIRPORT_UPGRADE_BONUS_AIR_SLOTS', 'MODIFIER_PLAYER_DISTRICT_GRANT_AIR_SLOTS', 0, 1, NULL, NULL);
	
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('AIRPORT_UPGRADE_BONUS_AIR_SLOTS', 'Amount', '1');

-- +10% to All Tourism
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_AIRPORT_UPGRADE', 'AIRPORT_UPGRADE_BOOST_ALL_TOURISM');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('AIRPORT_UPGRADE_BOOST_ALL_TOURISM', 'MODIFIER_PLAYER_ADJUST_TOURISM', 0, 0, NULL, NULL);
	
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('AIRPORT_UPGRADE_BOOST_ALL_TOURISM', 'Amount', '10');


--------------------------------------------------------------
-- 2018-03-28 Encampment
--------------------------------------------------------------

-- 2018-03-05 Mutually exclusive buildings (so they won't appear in production list)
INSERT INTO MutuallyExclusiveBuildings (Building, MutuallyExclusiveBuilding) VALUES
('BUILDING_STABLE_UPGRADE', 'BUILDING_BARRACKS'),
('BUILDING_STABLE_UPGRADE', 'BUILDING_BARRACKS_UPGRADE'),
('BUILDING_BARRACKS_UPGRADE', 'BUILDING_STABLE'),
('BUILDING_BARRACKS_UPGRADE', 'BUILDING_STABLE_UPGRADE');

--------------------------------------------------------------
-- BARRACKS

-- +1 Production
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange) VALUES
('BUILDING_BARRACKS_UPGRADE', 'YIELD_PRODUCTION', 1);

-- +2 Production from Camps
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_BARRACKS_UPGRADE', 'BARRACKSUPGRADE_ADDCAMPPRODUCTION');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('BARRACKSUPGRADE_ADDCAMPPRODUCTION', 'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD', 0, 0, NULL, 'PLOT_HAS_CAMP_REQUIREMENTS');
	
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('BARRACKSUPGRADE_ADDCAMPPRODUCTION', 'YieldType', 'YIELD_PRODUCTION'),
('BARRACKSUPGRADE_ADDCAMPPRODUCTION', 'Amount',    '2');

--------------------------------------------------------------
-- BASILIKOI_PAIDES (Macedon DLC)

UPDATE Buildings SET TraitType = 'TRAIT_CIVILIZATION_BUILDING_BASILIKOI_PAIDES'    WHERE BuildingType = 'BUILDING_BASILIKOI_PAIDES_UPGRADE';

INSERT INTO BuildingReplaces (CivUniqueBuildingType, ReplacesBuildingType) VALUES
('BUILDING_BASILIKOI_PAIDES_UPGRADE', 'BUILDING_BARRACKS_UPGRADE');

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

--------------------------------------------------------------
-- STABLE

-- +1 Production
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange) VALUES
('BUILDING_STABLE_UPGRADE', 'YIELD_PRODUCTION', 1);

-- +2 Production from Pastures
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_STABLE_UPGRADE', 'STABLEUPGRADE_ADDPASTUREPRODUCTION');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('STABLEUPGRADE_ADDPASTUREPRODUCTION', 'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD', 0, 0, NULL, 'PLOT_HAS_PASTURE_REQUIREMENTS');
	
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('STABLEUPGRADE_ADDPASTUREPRODUCTION', 'YieldType', 'YIELD_PRODUCTION'),
('STABLEUPGRADE_ADDPASTUREPRODUCTION', 'Amount',    '2');

--------------------------------------------------------------
-- ARMORY

-- +2 Production
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange) VALUES
('BUILDING_ARMORY_UPGRADE', 'YIELD_PRODUCTION', 2);

-- +1 GGP
INSERT INTO Building_GreatPersonPoints (BuildingType, GreatPersonClassType, PointsPerTurn) VALUES
('BUILDING_ARMORY_UPGRADE', 'GREAT_PERSON_CLASS_GENERAL', 1);

-- +3 Strength for all land units trained here (via Ability)
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_ARMORY_UPGRADE', 'ARMORY_UPGRADE_ATTACK');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('ARMORY_UPGRADE_ATTACK', 'MODIFIER_SINGLE_CITY_GRANT_ABILITY_FOR_TRAINED_UNITS', 0, 0, NULL, 'ARMORY_LAND_REQUIREMENTS');

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('ARMORY_UPGRADE_ATTACK', 'AbilityType', 'ABILITY_ARMORY_UPGRADE_ATTACK_BUFF');

INSERT INTO Types (Type, Kind) VALUES  -- hash value generated automatically
('ABILITY_ARMORY_UPGRADE_ATTACK_BUFF', 'KIND_ABILITY');

INSERT INTO UnitAbilities (UnitAbilityType, Name, Description, Inactive) VALUES
('ABILITY_ARMORY_UPGRADE_ATTACK_BUFF', 'LOC_ABILITY_ARMORY_UPGRADE_ATTACK_BUFF_NAME', 'LOC_ABILITY_ARMORY_UPGRADE_ATTACK_BUFF_DESCRIPTION', 1);

INSERT INTO UnitAbilityModifiers (UnitAbilityType, ModifierId) VALUES
('ABILITY_ARMORY_UPGRADE_ATTACK_BUFF', 'ARMORY_UPGRADE_ATTACK_BUFF');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('ARMORY_UPGRADE_ATTACK_BUFF', 'MODIFIER_UNIT_ADJUST_COMBAT_STRENGTH', 0, 0, NULL, NULL);

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('ARMORY_UPGRADE_ATTACK_BUFF', 'Amount', '3');

INSERT INTO TypeTags (Type, Tag) VALUES
('ABILITY_ARMORY_UPGRADE_ATTACK_BUFF', 'CLASS_RECON'),
('ABILITY_ARMORY_UPGRADE_ATTACK_BUFF', 'CLASS_MELEE'),
('ABILITY_ARMORY_UPGRADE_ATTACK_BUFF', 'CLASS_RANGED'),
('ABILITY_ARMORY_UPGRADE_ATTACK_BUFF', 'CLASS_SIEGE'),
('ABILITY_ARMORY_UPGRADE_ATTACK_BUFF', 'CLASS_HEAVY_CAVALRY'),
('ABILITY_ARMORY_UPGRADE_ATTACK_BUFF', 'CLASS_LIGHT_CAVALRY'),
('ABILITY_ARMORY_UPGRADE_ATTACK_BUFF', 'CLASS_RANGED_CAVALRY'),
('ABILITY_ARMORY_UPGRADE_ATTACK_BUFF', 'CLASS_ANTI_CAVALRY'),
('ABILITY_ARMORY_UPGRADE_ATTACK_BUFF', 'CLASS_HEAVY_CHARIOT'),
('ABILITY_ARMORY_UPGRADE_ATTACK_BUFF', 'CLASS_LIGHT_CHARIOT');
--('ABILITY_FASCISM_ATTACK_BUFF', 'CLASS_NAVAL_MELEE'),
--('ABILITY_FASCISM_ATTACK_BUFF', 'CLASS_NAVAL_RANGED'),
--('ABILITY_FASCISM_ATTACK_BUFF', 'CLASS_NAVAL_RAIDER'),
--('ABILITY_FASCISM_ATTACK_BUFF', 'CLASS_AIRCRAFT'),


--------------------------------------------------------------
-- MILITARY_ACADEMY

-- +1 Housing
UPDATE Buildings SET Housing = 1
WHERE BuildingType = 'BUILDING_MILITARY_ACADEMY_UPGRADE';

-- +3 Production
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange) VALUES
('BUILDING_MILITARY_ACADEMY_UPGRADE', 'YIELD_PRODUCTION', 3);

-- Flanking Bonus increased by 100%
INSERT INTO Types (Type, Kind) VALUES  -- hash value generated automatically
('MODIFIER_CITY_TRAINED_UNITS_ADJUST_FLANKING_BONUS', 'KIND_MODIFIER');

INSERT INTO DynamicModifiers (ModifierType, CollectionType, EffectType) VALUES
('MODIFIER_CITY_TRAINED_UNITS_ADJUST_FLANKING_BONUS', 'COLLECTION_CITY_TRAINED_UNITS', 'EFFECT_ADJUST_UNIT_FLANKING_BONUS_MODIFIER');

INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_MILITARY_ACADEMY_UPGRADE', 'MILITARY_ACADEMY_UPGRADE_ADJUST_FLANKING_BONUS');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('MILITARY_ACADEMY_UPGRADE_ADJUST_FLANKING_BONUS', 'MODIFIER_CITY_TRAINED_UNITS_ADJUST_FLANKING_BONUS', 0, 0, NULL, 'MILITARYACADEMY_XP_LAND_REQUIREMENTS');

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('MILITARY_ACADEMY_UPGRADE_ADJUST_FLANKING_BONUS', 'Percent', '100'); -- Percent = 100 means x2


--------------------------------------------------------------
-- 2018-03-28 Industrial Zone
--------------------------------------------------------------

--------------------------------------------------------------
-- WORKSHOP

-- +1 Housing
UPDATE Buildings SET Housing = 1
WHERE BuildingType = 'BUILDING_WORKSHOP_UPGRADE';

-- +1 Production
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange) VALUES
('BUILDING_WORKSHOP_UPGRADE', 'YIELD_PRODUCTION', 1);

-- +1 Production from Quarries and Mines with Visible Resources
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_WORKSHOP_UPGRADE', 'WORKSHOPUPGRADE_ADDMINEPRODUCTION'),
('BUILDING_WORKSHOP_UPGRADE', 'WORKSHOPUPGRADE_ADDQUARRYPRODUCTION');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('WORKSHOPUPGRADE_ADDMINEPRODUCTION',   'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD', 0, 0, NULL, 'PLOT_HAS_RESOURCE_MINE_REQUIREMENTS'),
('WORKSHOPUPGRADE_ADDQUARRYPRODUCTION', 'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD', 0, 0, NULL, 'PLOT_HAS_QUARRY_REQUIREMENTS');
	
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('WORKSHOPUPGRADE_ADDMINEPRODUCTION', 'YieldType', 'YIELD_PRODUCTION'),
('WORKSHOPUPGRADE_ADDMINEPRODUCTION', 'Amount',    '1'),
('WORKSHOPUPGRADE_ADDQUARRYPRODUCTION', 'YieldType', 'YIELD_PRODUCTION'),
('WORKSHOPUPGRADE_ADDQUARRYPRODUCTION', 'Amount',    '1');

INSERT INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES
('PLOT_HAS_RESOURCE_MINE_REQUIREMENTS', 'REQUIREMENTSET_TEST_ALL');

INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES
('PLOT_HAS_RESOURCE_MINE_REQUIREMENTS', 'REQUIRES_PLOT_HAS_VISIBLE_RESOURCE'),
('PLOT_HAS_RESOURCE_MINE_REQUIREMENTS', 'REQUIRES_PLOT_HAS_MINE');

--------------------------------------------------------------
-- FACTORY

-- +1 Housing, RR=6
UPDATE Buildings SET RegionalRange = 6, Housing = 1
WHERE BuildingType = 'BUILDING_FACTORY_UPGRADE';

-- +1 Production
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange) VALUES
('BUILDING_FACTORY_UPGRADE', 'YIELD_PRODUCTION', 1);

-- +2 Production for each Era since constructed!
INSERT INTO Building_YieldsPerEra (BuildingType, YieldType, YieldChange) VALUES
('BUILDING_FACTORY_UPGRADE', 'YIELD_PRODUCTION', 2);

-- +1 GEP
INSERT INTO Building_GreatPersonPoints (BuildingType, GreatPersonClassType, PointsPerTurn) VALUES
('BUILDING_FACTORY_UPGRADE', 'GREAT_PERSON_CLASS_ENGINEER', 1);

--------------------------------------------------------------
-- ELECTRONICS_FACTORY

UPDATE Buildings SET TraitType = 'TRAIT_CIVILIZATION_BUILDING_ELECTRONICS_FACTORY' WHERE BuildingType = 'BUILDING_ELECTRONICS_FACTORY_UPGRADE';

INSERT INTO BuildingReplaces (CivUniqueBuildingType, ReplacesBuildingType) VALUES
('BUILDING_ELECTRONICS_FACTORY_UPGRADE', 'BUILDING_FACTORY_UPGRADE');

-- +1 Housing, RR=9
UPDATE Buildings SET RegionalRange = 9, Housing = 1
WHERE BuildingType = 'BUILDING_ELECTRONICS_FACTORY_UPGRADE';

-- +2 Production
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange) VALUES
('BUILDING_ELECTRONICS_FACTORY_UPGRADE', 'YIELD_PRODUCTION', 2);

-- +3 Production for each Era since constructed!
INSERT INTO Building_YieldsPerEra (BuildingType, YieldType, YieldChange) VALUES
('BUILDING_ELECTRONICS_FACTORY_UPGRADE', 'YIELD_PRODUCTION', 3);

-- +1 GEP
INSERT INTO Building_GreatPersonPoints (BuildingType, GreatPersonClassType, PointsPerTurn) VALUES
('BUILDING_ELECTRONICS_FACTORY_UPGRADE', 'GREAT_PERSON_CLASS_ENGINEER', 1);

-- Electronics Factory Upgrade +2 Culture with Electricity
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_ELECTRONICS_FACTORY_UPGRADE', 'ELECTRONICSFACTORYUPGRADE_CULTURE');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('ELECTRONICSFACTORYUPGRADE_CULTURE', 'MODIFIER_BUILDING_YIELD_CHANGE', 0, 1, 'PLAYER_HAS_ELECTRICITYTECHNOLOGY_REQUIREMENTS', NULL);
	
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('ELECTRONICSFACTORYUPGRADE_CULTURE', 'BuildingType', 'BUILDING_ELECTRONICS_FACTORY_UPGRADE'),
('ELECTRONICSFACTORYUPGRADE_CULTURE', 'YieldType',    'YIELD_CULTURE'),
('ELECTRONICSFACTORYUPGRADE_CULTURE', 'Amount',       '2');

--------------------------------------------------------------
-- POWER_PLANT

-- Buildings with Regional Effects
UPDATE Buildings SET RegionalRange = 6
WHERE BuildingType = 'BUILDING_POWER_PLANT_UPGRADE';

INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange) VALUES
('BUILDING_POWER_PLANT_UPGRADE', 'YIELD_PRODUCTION', 2);

-- +2 Production for each specialty district constructed
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_POWER_PLANT_UPGRADE', 'POWER_PLANT_UPGRADE_PRODUCTION_PER_DISTRICT');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('POWER_PLANT_UPGRADE_PRODUCTION_PER_DISTRICT', 'MODIFIER_SINGLE_CITY_ADJUST_CITY_YIELD_PER_DISTRICT', 0, 0, NULL, NULL);

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('POWER_PLANT_UPGRADE_PRODUCTION_PER_DISTRICT', 'YieldType', 'YIELD_PRODUCTION'),
('POWER_PLANT_UPGRADE_PRODUCTION_PER_DISTRICT', 'Amount',    '2');

-- +3 prod from Oil Well
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_POWER_PLANT_UPGRADE', 'POWER_PLANT_UPGRADE_ADD_OILWELL_PRODUCTION');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('POWER_PLANT_UPGRADE_ADD_OILWELL_PRODUCTION',  'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD', 0, 0, NULL, 'PLOT_HAS_OILWELL_REQUIREMENTS');

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('POWER_PLANT_UPGRADE_ADD_OILWELL_PRODUCTION', 'YieldType', 'YIELD_PRODUCTION'),
('POWER_PLANT_UPGRADE_ADD_OILWELL_PRODUCTION', 'Amount',    '3');

INSERT INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES
('PLOT_HAS_OILWELL_REQUIREMENTS', 'REQUIREMENTSET_TEST_ALL');

INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES
('PLOT_HAS_OILWELL_REQUIREMENTS', 'REQUIRES_PLOT_HAS_OILWELL');

INSERT INTO Requirements (RequirementId, RequirementType) VALUES
('REQUIRES_PLOT_HAS_OILWELL', 'REQUIREMENT_PLOT_IMPROVEMENT_TYPE_MATCHES');

INSERT INTO RequirementArguments (RequirementId, Name, Value) VALUES
('REQUIRES_PLOT_HAS_OILWELL', 'ImprovementType', 'IMPROVEMENT_OIL_WELL');

--------------------------------------------------------------
-- AI
-- System Buildings contains only Wonders
-- Will use AiBuildSpecializations that contains only one list: DefaultCitySpecialization
--------------------------------------------------------------
