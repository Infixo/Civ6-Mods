--------------------------------------------------------------
-- Real Building Upgrades
-- Author: Infixo
-- 2018-03-04: Created
--------------------------------------------------------------


--------------------------------------------------------------
-- Table with new parameters for buildings - the rest will be default
-- Created in the vanilla file
--------------------------------------------------------------

DELETE FROM RBUConfig; -- remove vanilla rows so they will not get duplicated

INSERT INTO RBUConfig (BType, PTech, PCivic, UCost, PDist, UMain, Advis)
VALUES  -- generated from Excel
('AQUARIUM',NULL,'CONSERVATION',330,'WATER_ENTERTAINMENT_COMPLEX',3,'GENERIC'),
('AQUATICS_CENTER',NULL,'SOCIAL_MEDIA',820,'WATER_ENTERTAINMENT_COMPLEX',4,'GENERIC'),
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
SET PurchaseYield = NULL, OuterDefenseHitPoints = 25, OuterDefenseStrength = 1, Entertainment = 1, Housing = 1
WHERE BuildingType = 'BUILDING_TSIKHE_UPGRADE';

-- Buildings with Regional Effects
UPDATE Buildings
SET RegionalRange = 9
WHERE BuildingType IN (
	'BUILDING_AQUARIUM_UPGRADE',
	'BUILDING_AQUATICS_CENTER_UPGRADE');

-- Buildings that add Housing

-- Buildings that add Amenities
UPDATE Buildings
SET Entertainment = 1
WHERE BuildingType IN (
	'BUILDING_AQUARIUM_UPGRADE',
	'BUILDING_AQUATICS_CENTER_UPGRADE');
	
-- Buildings enabled by Religion

-- Additonal Food same as Adjacency Bonuses

-- Unique Buildings' Upgrades
UPDATE Buildings SET TraitType = 'TRAIT_CIVILIZATION_BUILDING_ORDU'   WHERE BuildingType = 'BUILDING_ORDU_UPGRADE';
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

-- 2018-03-05 Mutually exclusive buildings (so they won't appear in production list)
INSERT INTO MutuallyExclusiveBuildings (Building, MutuallyExclusiveBuilding) VALUES
('BUILDING_ORDU_UPGRADE', 'BUILDING_BARRACKS'),
('BUILDING_ORDU_UPGRADE', 'BUILDING_BARRACKS_UPGRADE'),
('BUILDING_FOOD_MARKET_UPGRADE', 'BUILDING_SHOPPING_MALL'),
('BUILDING_FOOD_MARKET_UPGRADE', 'BUILDING_SHOPPING_MALL_UPGRADE'),
('BUILDING_SHOPPING_MALL_UPGRADE', 'BUILDING_FOOD_MARKET'),
('BUILDING_SHOPPING_MALL_UPGRADE', 'BUILDING_FOOD_MARKET_UPGRADE');


--------------------------------------------------------------
-- Populate basic parameters (i.e. Yields)
--------------------------------------------------------------
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange) VALUES -- generated from Excel
('BUILDING_TSIKHE_UPGRADE', 'YIELD_FAITH', 1);


--------------------------------------------------------------
-- MODIFIERS
--------------------------------------------------------------

INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_ORDU_UPGRADE', 'STABLEUPGRADE_ADDPASTUREPRODUCTION'), -- the same effect as Stable Upgrade
('BUILDING_SHOPPING_MALL_UPGRADE', 'SHOPPING_MALL_UPGRADE_TOURISM'),
('BUILDING_SHOPPING_MALL_UPGRADE', 'SHOPPING_MALL_UPGRADE_ADD_LUXURY_GOLD'),
('BUILDING_FERRIS_WHEEL_UPGRADE', 'FERRIS_WHEEL_UPGRADE_TOURISM'),
('BUILDING_FERRIS_WHEEL_UPGRADE', 'FERRIS_WHEEL_UPGRADE_APPEAL'),
('BUILDING_AQUATICS_CENTER_UPGRADE', 'AQUATICS_CENTER_UPGRADE_BOOST_ALL_TOURISM'),
('BUILDING_FOOD_MARKET_UPGRADE', 'FOOD_MARKET_UPGRADE_ADD_PASTURE_FOOD'),
('BUILDING_FOOD_MARKET_UPGRADE', 'FOOD_MARKET_UPGRADE_ADD_CAMP_FOOD'),
('BUILDING_FOOD_MARKET_UPGRADE', 'FOOD_MARKET_UPGRADE_ADD_PLANTATION_FOOD');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('SHOPPING_MALL_UPGRADE_TOURISM',         'MODIFIER_PLAYER_DISTRICT_ADJUST_TOURISM_CHANGE', 0, 0, NULL, NULL),
('SHOPPING_MALL_UPGRADE_ADD_LUXURY_GOLD', 'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD',    0, 0, NULL, 'PLOT_HAS_LUXURY_RESOURCE'),
('FERRIS_WHEEL_UPGRADE_TOURISM', 'MODIFIER_PLAYER_DISTRICT_ADJUST_TOURISM_CHANGE', 0, 0, NULL, NULL),
('FERRIS_WHEEL_UPGRADE_APPEAL',  'MODIFIER_SINGLE_CITY_ADJUST_CITY_APPEAL',        1, 1, NULL, NULL),
('AQUATICS_CENTER_UPGRADE_BOOST_ALL_TOURISM', 'MODIFIER_PLAYER_ADJUST_TOURISM', 0, 0, NULL, NULL),
('FOOD_MARKET_UPGRADE_ADD_PASTURE_FOOD',    'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD', 0, 0, NULL, 'PLOT_HAS_PASTURE_REQUIREMENTS'),
('FOOD_MARKET_UPGRADE_ADD_CAMP_FOOD',       'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD', 0, 0, NULL, 'PLOT_HAS_CAMP_REQUIREMENTS'),
('FOOD_MARKET_UPGRADE_ADD_PLANTATION_FOOD', 'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD', 0, 0, NULL, 'PLOT_HAS_PLANTATION_REQUIREMENTS');

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
-- Shopping Mall Upgrade +2 Tourism, +2 Gold from Lux resources
('SHOPPING_MALL_UPGRADE_TOURISM', 'Amount', '2'),
('SHOPPING_MALL_UPGRADE_ADD_LUXURY_GOLD', 'Amount', '2'),
('SHOPPING_MALL_UPGRADE_ADD_LUXURY_GOLD', 'YieldType', 'YIELD_GOLD'),
-- Ferris Wheel Upgrade +1 Tourism, +1 Appeal
('FERRIS_WHEEL_UPGRADE_TOURISM', 'Amount', '1'),
('FERRIS_WHEEL_UPGRADE_APPEAL',  'Amount', '1'),
-- Aquatics Center Upgrade +10% to all Tourism
('AQUATICS_CENTER_UPGRADE_BOOST_ALL_TOURISM', 'Amount', '10'),
-- Food Market Upgrade Add +1 FOOD from PASTURE and FISHING_BOATS and CAMP
('FOOD_MARKET_UPGRADE_ADD_PASTURE_FOOD', 'Amount', '1'),
('FOOD_MARKET_UPGRADE_ADD_PASTURE_FOOD', 'YieldType', 'YIELD_FOOD'),
('FOOD_MARKET_UPGRADE_ADD_CAMP_FOOD', 'Amount', '1'),
('FOOD_MARKET_UPGRADE_ADD_CAMP_FOOD', 'YieldType', 'YIELD_FOOD'),
('FOOD_MARKET_UPGRADE_ADD_PLANTATION_FOOD', 'Amount', '1'),
('FOOD_MARKET_UPGRADE_ADD_PLANTATION_FOOD', 'YieldType', 'YIELD_FOOD');

INSERT INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES
('PLOT_HAS_LUXURY_RESOURCE', 'REQUIREMENTSET_TEST_ALL');

INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES
('PLOT_HAS_LUXURY_RESOURCE', 'REQUIRES_PLOT_HAS_LUXURY');


--------------------------------------------------------------
-- AI
-- System Buildings contains only Wonders
-- Will use AiBuildSpecializations that contains only one list: DefaultCitySpecialization
--------------------------------------------------------------
