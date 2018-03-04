--------------------------------------------------------------
-- Real Building Upgrades
-- Author: Infixo
-- 2018-03-04: Created
--------------------------------------------------------------


--------------------------------------------------------------
-- Table with new parameters for buildings - the rest will be default
--------------------------------------------------------------
/* created in the vanilla file
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
*/

DELETE FROM RBUConfig; -- remove vanilla rows so they will not get duplicated

INSERT INTO RBUConfig (BType, PTech, PCivic, UCost, PDist, UMain, Advis)
VALUES  -- generated from Excel
('AQUARIUM',NULL,'CONSERVATION',330,'WATER_ENTERTAINMENT_COMPLEX',3,'GENERIC'),
('AQUATICS_CENTER',NULL,'SOCIAL_MEDIA',825,'WATER_ENTERTAINMENT_COMPLEX',4,'GENERIC'),
('FERRIS_WHEEL',NULL,'CONSERVATION',145,'WATER_ENTERTAINMENT_COMPLEX',1,'GENERIC'),
('FOOD_MARKET','PLASTICS',NULL,350,'NEIGHBORHOOD',3,'GENERIC'),
('ORDU','CONSTRUCTION',NULL,60,'ENCAMPMENT',1,'CONQUEST'),
('SHOPPING_MALL',NULL,'CULTURAL_HERITAGE',430,'NEIGHBORHOOD',3,'CULTURE'),
('TSIKHE','BALLISTICS',NULL,330,'CITY_CENTER',1,'GENERIC');


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

-- Tsikhe
UPDATE Buildings
SET PurchaseYield = NULL, OuterDefenseHitPoints = 25, OuterDefenseStrength = 1, RegionalRange = 6
WHERE BuildingType = 'BUILDING_TSIKHE_UPGRADE';

-- Buildings with Regional Effects
UPDATE Buildings
SET RegionalRange = 9
WHERE BuildingType IN (
	'BUILDING_AQUARIUM_UPGRADE',
	'BUILDING_AQUATICS_CENTER_UPGRADE');

-- Buildings that add Housing
--UPDATE Buildings SET Housing = 2
--WHERE BuildingType IN = 'BUILDING_AIRPORT_UPGRADE';

-- Buildings that add Amenities
UPDATE Buildings
SET Entertainment = 1
WHERE BuildingType IN (
	'BUILDING_AQUARIUM_UPGRADE',
	'BUILDING_AQUATICS_CENTER_UPGRADE');
	
-- Buildings enabled by Religion
/*
UPDATE Buildings
SET EnabledByReligion = 1, PurchaseYield = 'YIELD_FAITH'
WHERE BuildingType IN (
	'BUILDING_CATHEDRAL_UPGRADE');
*/

-- Additonal Food same as Adjacency Bonuses
/*
INSERT INTO Building_YieldDistrictCopies (BuildingType, OldYieldType, NewYieldType)
VALUES
	('BUILDING_POWER_PLANT_UPGRADE', 'YIELD_PRODUCTION', 'YIELD_GOLD'),
	('BUILDING_SEAPORT_UPGRADE', 'YIELD_GOLD', 'YIELD_FOOD');
*/

-- Unique Buildings' Upgrades
UPDATE Buildings SET TraitType = 'TRAIT_CIVILIZATION_BUILDING_ORDU' WHERE BuildingType = 'BUILDING_ORDU_UPGRADE';
UPDATE Buildings SET TraitType = 'TRAIT_CIVILIZATION_BUILDING_TSIKHE' WHERE BuildingType = 'BUILDING_TSIKHE_UPGRADE';

-- Great Person Points
INSERT INTO Building_GreatPersonPoints (BuildingType, GreatPersonClassType, PointsPerTurn) VALUES
('BUILDING_AQUARIUM_UPGRADE', 'GREAT_PERSON_CLASS_SCIENTIST', 1),
('BUILDING_ORDU_UPGRADE', 'GREAT_PERSON_CLASS_GENERAL', 1);

INSERT INTO BuildingReplaces (CivUniqueBuildingType, ReplacesBuildingType)
SELECT CivUniqueBuildingType||'_UPGRADE', ReplacesBuildingType||'_UPGRADE'
FROM BuildingReplaces
WHERE CivUniqueBuildingType IN (
	'BUILDING_ORDU',
	'BUILDING_TSIKHE');

-- Connect Upgrades to Base Buildings
INSERT INTO BuildingPrereqs (Building, PrereqBuilding)
SELECT 'BUILDING_'||BType||'_UPGRADE', 'BUILDING_'||BType
FROM RBUConfig;

--------------------------------------------------------------
-- Populate basic parameters (i.e. Yields)
--------------------------------------------------------------
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange)
VALUES  -- generated from Excel
('BUILDING_ORDU_UPGRADE', 'YIELD_PRODUCTION', 1),
('BUILDING_TSIKHE_UPGRADE', 'YIELD_FAITH', 1);


--------------------------------------------------------------
-- MODIFIERS
--------------------------------------------------------------

/* TODO

INSERT INTO BuildingModifiers (BuildingType, ModifierId)
VALUES
	('BUILDING_ELECTRONICS_FACTORY_UPGRADE', 'ELECTRONICSFACTORYUPGRADE_CULTURE'),
	('BUILDING_WATER_MILL_UPGRADE', 'WATERMILLUPGRADE_ADDPLANTATIONFOOD'),
	('BUILDING_MUSEUM_ART_UPGRADE', 'MUSEUMSUPGRADE_GREAT_WORK_ARTIFACT_GOLD'),
	('BUILDING_MUSEUM_ART_UPGRADE', 'MUSEUMSUPGRADE_GREAT_WORK_LANDSCAPE_GOLD'),
	('BUILDING_MUSEUM_ART_UPGRADE', 'MUSEUMSUPGRADE_GREAT_WORK_MUSIC_GOLD'),
	('BUILDING_MUSEUM_ART_UPGRADE', 'MUSEUMSUPGRADE_GREAT_WORK_PORTRAIT_GOLD'),
	('BUILDING_MUSEUM_ART_UPGRADE', 'MUSEUMSUPGRADE_GREAT_WORK_SCULPTURE_GOLD'),
	('BUILDING_MUSEUM_ART_UPGRADE', 'MUSEUMSUPGRADE_GREAT_WORK_WRITING_GOLD'),
	('BUILDING_MUSEUM_ARTIFACT_UPGRADE', 'MUSEUMSUPGRADE_GREAT_WORK_ARTIFACT_GOLD'),
	('BUILDING_MUSEUM_ARTIFACT_UPGRADE', 'MUSEUMSUPGRADE_GREAT_WORK_LANDSCAPE_GOLD'),
	('BUILDING_MUSEUM_ARTIFACT_UPGRADE', 'MUSEUMSUPGRADE_GREAT_WORK_MUSIC_GOLD'),
	('BUILDING_MUSEUM_ARTIFACT_UPGRADE', 'MUSEUMSUPGRADE_GREAT_WORK_PORTRAIT_GOLD'),
	('BUILDING_MUSEUM_ARTIFACT_UPGRADE', 'MUSEUMSUPGRADE_GREAT_WORK_SCULPTURE_GOLD'),
	('BUILDING_MUSEUM_ARTIFACT_UPGRADE', 'MUSEUMSUPGRADE_GREAT_WORK_WRITING_GOLD'),
	('BUILDING_STADIUM_UPGRADE', 'STADIUMUPGRADE_BOOST_ALL_TOURISM');

--INSERT INTO Types (Type, Kind)  -- hash value generated automatically
--VALUES ('MODIFIER_XXX_MODIFIER', 'KIND_MODIFIER');

--INSERT INTO DynamicModifiers (ModifierType, CollectionType, EffectType)
--VALUES ('MODIFIER_XXX_MODIFIER', 'COLLECTION_OWNER', 'EFFECT_ADJUST_BUILDING_YIELD_MODIFIER');

-- New requirements
INSERT INTO RequirementSets (RequirementSetId, RequirementSetType)
VALUES
	('PLOT_HAS_PLANTATION_REQUIREMENTS', 'REQUIREMENTSET_TEST_ALL'),
	('PLOT_HAS_LUMBER_MILL_REQUIREMENTS', 'REQUIREMENTSET_TEST_ALL');
	
INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId)
VALUES
	('PLOT_HAS_PLANTATION_REQUIREMENTS', 'REQUIRES_PLOT_HAS_PLANTATION'),
	('PLOT_HAS_LUMBER_MILL_REQUIREMENTS', 'REQUIRES_PLOT_HAS_LUMBER_MILL');

INSERT INTO Requirements (RequirementId, RequirementType)
VALUES ('REQUIRES_PLOT_HAS_LUMBER_MILL', 'REQUIREMENT_PLOT_IMPROVEMENT_TYPE_MATCHES');
	
INSERT INTO RequirementArguments (RequirementId, Name, Value)
VALUES ('REQUIRES_PLOT_HAS_LUMBER_MILL', 'ImprovementType', 'IMPROVEMENT_LUMBER_MILL');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId)
VALUES
	('ELECTRONICSFACTORYUPGRADE_CULTURE', 'MODIFIER_BUILDING_YIELD_CHANGE', 0, 1, 'PLAYER_HAS_ELECTRICITYTECHNOLOGY_REQUIREMENTS', NULL),
	('BARRACKSUPGRADE_ADDCAMPPRODUCTION', 'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD', 0, 0, NULL, 'PLOT_HAS_CAMP_REQUIREMENTS'),
	('STABLEUPGRADE_ADDPASTUREPRODUCTION', 'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD', 0, 0, NULL, 'PLOT_HAS_PASTURE_REQUIREMENTS'),
	('WATERMILLUPGRADE_ADDPLANTATIONFOOD', 'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD', 0, 0, NULL, 'PLOT_HAS_PLANTATION_REQUIREMENTS'),
	('WORKSHOPUPGRADE_ADDQUARRYPRODUCTION', 'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD', 0, 0, NULL, 'PLOT_HAS_QUARRY_REQUIREMENTS'),
	('STAVECHURCHUPGRADE_ADDLUMBERMILLFAITH', 'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD', 0, 0, NULL, 'PLOT_HAS_LUMBER_MILL_REQUIREMENTS'),
	('HANGARUPGRADE_BONUS_AIR_SLOTS', 'MODIFIER_PLAYER_DISTRICT_GRANT_AIR_SLOTS', 0, 1, NULL, NULL),
	('AIRPORTUPGRADE_BONUS_AIR_SLOTS', 'MODIFIER_PLAYER_DISTRICT_GRANT_AIR_SLOTS', 0, 1, NULL, NULL),
	('MUSEUMSUPGRADE_GREAT_WORK_ARTIFACT_GOLD', 'MODIFIER_SINGLE_CITY_ADJUST_GREATWORK_YIELD', 0, 0, NULL, NULL),
	('MUSEUMSUPGRADE_GREAT_WORK_LANDSCAPE_GOLD', 'MODIFIER_SINGLE_CITY_ADJUST_GREATWORK_YIELD', 0, 0, NULL, NULL),
	('MUSEUMSUPGRADE_GREAT_WORK_MUSIC_GOLD', 'MODIFIER_SINGLE_CITY_ADJUST_GREATWORK_YIELD', 0, 0, NULL, NULL),
	('MUSEUMSUPGRADE_GREAT_WORK_PORTRAIT_GOLD', 'MODIFIER_SINGLE_CITY_ADJUST_GREATWORK_YIELD', 0, 0, NULL, NULL),
	('MUSEUMSUPGRADE_GREAT_WORK_SCULPTURE_GOLD', 'MODIFIER_SINGLE_CITY_ADJUST_GREATWORK_YIELD', 0, 0, NULL, NULL),
	('MUSEUMSUPGRADE_GREAT_WORK_WRITING_GOLD', 'MODIFIER_SINGLE_CITY_ADJUST_GREATWORK_YIELD', 0, 0, NULL, NULL),
	('STADIUMUPGRADE_BOOST_ALL_TOURISM', 'MODIFIER_PLAYER_ADJUST_TOURISM', 0, 0, NULL, NULL);
	
INSERT INTO ModifierArguments (ModifierId, Name, Value)
VALUES
	-- Electronics Factory Upgrade +2 Culture
	('ELECTRONICSFACTORYUPGRADE_CULTURE', 'BuildingType', 'BUILDING_ELECTRONICS_FACTORY_UPGRADE'),
	('ELECTRONICSFACTORYUPGRADE_CULTURE', 'Amount', '2'),
	('ELECTRONICSFACTORYUPGRADE_CULTURE', 'YieldType', 'YIELD_CULTURE'),
	-- Barracks Upgrade +1 Production from Camps
	('BARRACKSUPGRADE_ADDCAMPPRODUCTION', 'Amount', '1'),
	('BARRACKSUPGRADE_ADDCAMPPRODUCTION', 'YieldType', 'YIELD_PRODUCTION'),
	-- Stable Upgrade +1 Production from Pastures
	('STABLEUPGRADE_ADDPASTUREPRODUCTION', 'Amount', '1'),
	('STABLEUPGRADE_ADDPASTUREPRODUCTION', 'YieldType', 'YIELD_PRODUCTION'),
	-- Water Mill Upgrade +1 Food from Plantations
	('WATERMILLUPGRADE_ADDPLANTATIONFOOD', 'Amount', '1'),
	('WATERMILLUPGRADE_ADDPLANTATIONFOOD',	'YieldType', 'YIELD_FOOD'),
	-- Workshop Upgrade +1 Production from Quarries
	('WORKSHOPUPGRADE_ADDQUARRYPRODUCTION', 'Amount', '1'),
	('WORKSHOPUPGRADE_ADDQUARRYPRODUCTION', 'YieldType', 'YIELD_PRODUCTION'),
	-- Stave Church Upgrade +1 Faith from Lumber Mills
	('STAVECHURCHUPGRADE_ADDLUMBERMILLFAITH', 'Amount', '1'),
	('STAVECHURCHUPGRADE_ADDLUMBERMILLFAITH', 'YieldType', 'YIELD_FAITH'),
	-- Hangar & Airport +1 Air Slot
	('HANGARUPGRADE_BONUS_AIR_SLOTS', 'Amount', '1'),
	('AIRPORTUPGRADE_BONUS_AIR_SLOTS', 'Amount', '1'),
	-- Museums +1 Gold for each GW
	('MUSEUMSUPGRADE_GREAT_WORK_ARTIFACT_GOLD', 'GreatWorkObjectType', 'GREATWORKOBJECT_ARTIFACT'),
	('MUSEUMSUPGRADE_GREAT_WORK_ARTIFACT_GOLD', 'YieldType', 'YIELD_GOLD'),
	('MUSEUMSUPGRADE_GREAT_WORK_ARTIFACT_GOLD', 'YieldChange', '1'),
	('MUSEUMSUPGRADE_GREAT_WORK_LANDSCAPE_GOLD', 'GreatWorkObjectType', 'GREATWORKOBJECT_LANDSCAPE'),
	('MUSEUMSUPGRADE_GREAT_WORK_LANDSCAPE_GOLD', 'YieldType', 'YIELD_GOLD'),
	('MUSEUMSUPGRADE_GREAT_WORK_LANDSCAPE_GOLD', 'YieldChange', '1'),
	('MUSEUMSUPGRADE_GREAT_WORK_MUSIC_GOLD', 'GreatWorkObjectType', 'GREATWORKOBJECT_MUSIC'),
	('MUSEUMSUPGRADE_GREAT_WORK_MUSIC_GOLD', 'YieldType', 'YIELD_GOLD'),
	('MUSEUMSUPGRADE_GREAT_WORK_MUSIC_GOLD', 'YieldChange', '1'),
	('MUSEUMSUPGRADE_GREAT_WORK_PORTRAIT_GOLD', 'GreatWorkObjectType', 'GREATWORKOBJECT_PORTRAIT'),
	('MUSEUMSUPGRADE_GREAT_WORK_PORTRAIT_GOLD', 'YieldType', 'YIELD_GOLD'),
	('MUSEUMSUPGRADE_GREAT_WORK_PORTRAIT_GOLD', 'YieldChange', '1'),
	('MUSEUMSUPGRADE_GREAT_WORK_SCULPTURE_GOLD', 'GreatWorkObjectType', 'GREATWORKOBJECT_SCULPTURE'),
	('MUSEUMSUPGRADE_GREAT_WORK_SCULPTURE_GOLD', 'YieldType', 'YIELD_GOLD'),
	('MUSEUMSUPGRADE_GREAT_WORK_SCULPTURE_GOLD', 'YieldChange', '1'),
	('MUSEUMSUPGRADE_GREAT_WORK_WRITING_GOLD', 'GreatWorkObjectType', 'GREATWORKOBJECT_WRITING'),
	('MUSEUMSUPGRADE_GREAT_WORK_WRITING_GOLD', 'YieldType', 'YIELD_GOLD'),
	('MUSEUMSUPGRADE_GREAT_WORK_WRITING_GOLD', 'YieldChange', '1'),
	-- Stadium +10% for all Tourism
	('STADIUMUPGRADE_BOOST_ALL_TOURISM', 'Amount', '10');

--------------------------------------------------------------
-- AI
-- System Buildings contains only Wonders
-- Will use AiBuildSpecializations that contains only one list: DefaultCitySpecialization
--------------------------------------------------------------
*/