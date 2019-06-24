--------------------------------------------------------------
-- Real Building Upgrades
-- Author: Infixo
-- 2019-02-18: Created
-- 2019-04-06: Added GS buildings
--------------------------------------------------------------


--------------------------------------------------------------
-- 2019-02-18 Changes to upgrades of Vanilla and R&F buildings
--------------------------------------------------------------

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

--UPDATE Buildings SET OuterDefenseHitPoints =  50 WHERE BuildingType = 'BUILDING_WALLS_UPGRADE';
--UPDATE Buildings SET OuterDefenseHitPoints =  50 WHERE BuildingType = 'BUILDING_CASTLE_UPGRADE';
--UPDATE Buildings SET OuterDefenseHitPoints =  50 WHERE BuildingType = 'BUILDING_STAR_FORT_UPGRADE';
UPDATE Buildings SET OuterDefenseHitPoints = 100 WHERE BuildingType = 'BUILDING_TSIKHE_UPGRADE';


-- Rearrange a bit so the techs will not get overcrowded
UPDATE Buildings SET PrereqTech = 'TECH_REPLACEABLE_PARTS'   WHERE BuildingType = 'BUILDING_FACTORY_UPGRADE';
UPDATE Buildings SET PrereqTech = 'TECH_NUCLEAR_FUSION'      WHERE BuildingType = 'BUILDING_POWER_PLANT_UPGRADE';
UPDATE Buildings SET PrereqTech = 'TECH_SYNTHETIC_MATERIALS' WHERE BuildingType = 'BUILDING_RESEARCH_LAB_UPGRADE';
UPDATE Buildings SET PrereqTech = 'TECH_COMBINED_ARMS'       WHERE BuildingType = 'BUILDING_SEAPORT_UPGRADE';
UPDATE Buildings SET PrereqTech = 'TECH_TELECOMMUNICATIONS'  WHERE BuildingType = 'BUILDING_BROADCAST_CENTER_UPGRADE';
UPDATE Buildings SET PrereqCivic = 'CIVIC_MASS_MEDIA'       WHERE BuildingType = 'BUILDING_FERRIS_WHEEL_UPGRADE';
UPDATE Buildings SET PrereqCivic = 'CIVIC_MASS_MEDIA'       WHERE BuildingType = 'BUILDING_AQUARIUM_UPGRADE';
UPDATE Buildings SET PrereqCivic = 'CIVIC_ENVIRONMENTALISM' WHERE BuildingType = 'BUILDING_AQUATICS_CENTER_UPGRADE';


--------------------------------------------------------------
-- 2019-04-06 Industrial Zone - power plants
-- Can’t give more power from resources because they consume dynamically. Focus on other effects.
--------------------------------------------------------------

-- Nuclear Power Plant needs a new name
UPDATE Buildings SET Cost = 450, Name = 'LOC_BUILDING_NUCLEAR_POWER_PLANT_UPGRADE_NAME', Description = 'LOC_BUILDING_NUCLEAR_POWER_PLANT_UPGRADE_DESCRIPTION' WHERE BuildingType = 'BUILDING_POWER_PLANT_UPGRADE';

-- I can't do +1 from a resource, etc. because there is only EFFECT_ADJUST_CITY_EXTRA_ACCUMULATION_SPECIFIC_RESOURCE available
-- thus I can only grant extra accumulation on a CITY level for city-level owners, like Buildings or Districts
-- a) there is no EFFECT_ADJUST_EXTRA_ACCUMULATION_IMPROVEMENT nor EFFECT_ADJUST_EXTRA_ACCUMULATION_RESOURCE
-- b) there is no requirement to check if a city has a specific plot or improvement
-- new modifier type to adjust a specific strategic resource accumulation for a single city
--INSERT INTO Types (Type, Kind)  -- hash value generated automatically
--VALUES ('MODIFIER_SINGLE_CITY_ADJUST_EXTRA_ACCUMULATION_SPECIFIC_RESOURCE', 'KIND_MODIFIER');
--INSERT INTO DynamicModifiers (ModifierType, CollectionType, EffectType)
--VALUES ('MODIFIER_SINGLE_CITY_ADJUST_EXTRA_ACCUMULATION_SPECIFIC_RESOURCE', 'COLLECTION_OWNER', 'EFFECT_ADJUST_CITY_EXTRA_ACCUMULATION_SPECIFIC_RESOURCE');

INSERT INTO MutuallyExclusiveBuildings (Building, MutuallyExclusiveBuilding) VALUES
('BUILDING_COAL_POWER_PLANT_UPGRADE', 'BUILDING_FOSSIL_FUEL_POWER_PLANT'),
('BUILDING_COAL_POWER_PLANT_UPGRADE', 'BUILDING_FOSSIL_FUEL_POWER_PLANT_UPGRADE'),
('BUILDING_COAL_POWER_PLANT_UPGRADE', 'BUILDING_POWER_PLANT'),
('BUILDING_COAL_POWER_PLANT_UPGRADE', 'BUILDING_POWER_PLANT_UPGRADE'),
('BUILDING_FOSSIL_FUEL_POWER_PLANT_UPGRADE', 'BUILDING_COAL_POWER_PLANT'),
('BUILDING_FOSSIL_FUEL_POWER_PLANT_UPGRADE', 'BUILDING_COAL_POWER_PLANT_UPGRADE'),
('BUILDING_FOSSIL_FUEL_POWER_PLANT_UPGRADE', 'BUILDING_POWER_PLANT'),
('BUILDING_FOSSIL_FUEL_POWER_PLANT_UPGRADE', 'BUILDING_POWER_PLANT_UPGRADE'),
('BUILDING_POWER_PLANT_UPGRADE', 'BUILDING_FOSSIL_FUEL_POWER_PLANT'),
('BUILDING_POWER_PLANT_UPGRADE', 'BUILDING_FOSSIL_FUEL_POWER_PLANT_UPGRADE'),
('BUILDING_POWER_PLANT_UPGRADE', 'BUILDING_COAL_POWER_PLANT'),
('BUILDING_POWER_PLANT_UPGRADE', 'BUILDING_COAL_POWER_PLANT_UPGRADE');

--------------------------------------------------------------
-- Projects to decomission power plants

INSERT INTO Project_BuildingCosts (ProjectType, ConsumedBuildingType) VALUES
('PROJECT_DECOMMISSION_COAL_POWER_PLANT',    'BUILDING_COAL_POWER_PLANT_UPGRADE'),
('PROJECT_DECOMMISSION_OIL_POWER_PLANT',     'BUILDING_FOSSIL_FUEL_POWER_PLANT_UPGRADE'),
('PROJECT_DECOMMISSION_NUCLEAR_POWER_PLANT', 'BUILDING_POWER_PLANT_UPGRADE');


--------------------------------------------------------------
-- COAL_POWER_PLANT, base: 1 prod, 1 GEP, 4 power, rr6

-- RR=9
UPDATE Buildings SET RegionalRange = 9
WHERE BuildingType = 'BUILDING_COAL_POWER_PLANT_UPGRADE';

-- +1 production
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange) VALUES
('BUILDING_COAL_POWER_PLANT_UPGRADE', 'YIELD_PRODUCTION', 1);

-- +1 Production for each specialty district constructed
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_COAL_POWER_PLANT_UPGRADE', 'POWER_PLANT_UPGRADE_1_PRODUCTION_PER_DISTRICT');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('POWER_PLANT_UPGRADE_1_PRODUCTION_PER_DISTRICT', 'MODIFIER_SINGLE_CITY_ADJUST_CITY_YIELD_PER_DISTRICT', 0, 0, NULL, NULL);

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('POWER_PLANT_UPGRADE_1_PRODUCTION_PER_DISTRICT', 'YieldType', 'YIELD_PRODUCTION'),
('POWER_PLANT_UPGRADE_1_PRODUCTION_PER_DISTRICT', 'Amount',    '1');

-- Coal Mines: +3 Production
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_COAL_POWER_PLANT_UPGRADE', 'COAL_POWER_PLANT_UPGRADE_ADD_COAL_MINE_PRODUCTION');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('COAL_POWER_PLANT_UPGRADE_ADD_COAL_MINE_PRODUCTION', 'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD', 0, 0, NULL, 'PLOT_HAS_COAL_MINE_REQUIREMENTS');

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('COAL_POWER_PLANT_UPGRADE_ADD_COAL_MINE_PRODUCTION', 'YieldType', 'YIELD_PRODUCTION'),
('COAL_POWER_PLANT_UPGRADE_ADD_COAL_MINE_PRODUCTION', 'Amount',    '3');

INSERT OR REPLACE INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES
('PLOT_HAS_COAL_MINE_REQUIREMENTS', 'REQUIREMENTSET_TEST_ALL');

INSERT OR REPLACE INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES
('PLOT_HAS_COAL_MINE_REQUIREMENTS', 'REQUIRES_COAL_IN_PLOT'),
('PLOT_HAS_COAL_MINE_REQUIREMENTS', 'REQUIRES_PLOT_HAS_MINE'); -- exists

INSERT OR REPLACE INTO Requirements (RequirementId, RequirementType) VALUES
('REQUIRES_COAL_IN_PLOT', 'REQUIREMENT_PLOT_RESOURCE_TYPE_MATCHES');

INSERT OR REPLACE INTO RequirementArguments (RequirementId, Name, Value) VALUES
('REQUIRES_COAL_IN_PLOT', 'ResourceType', 'RESOURCE_COAL');


--------------------------------------------------------------
-- FOSSIL_FUEL_POWER_PLANT, base: 2 prod, 1 GEP, 4 power, rr6

-- RR=9
UPDATE Buildings SET RegionalRange = 9
WHERE BuildingType = 'BUILDING_FOSSIL_FUEL_POWER_PLANT_UPGRADE';

-- +1 Production
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange) VALUES
('BUILDING_FOSSIL_FUEL_POWER_PLANT_UPGRADE', 'YIELD_PRODUCTION', 1);

-- +1 Production for each specialty district constructed
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_FOSSIL_FUEL_POWER_PLANT_UPGRADE', 'POWER_PLANT_UPGRADE_1_PRODUCTION_PER_DISTRICT'); -- defined for a Coal Power Plant Upgrade

-- +3 Production from Oil Wells
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_FOSSIL_FUEL_POWER_PLANT_UPGRADE', 'POWER_PLANT_UPGRADE_ADD_OILWELL_PRODUCTION'); -- defined for the vanilla Power Plant, re-used here


--------------------------------------------------------------
-- NUCLEAR_POWER_PLANT, base: Nuclear 4 prod, 3 science, 1 GEP, 16 power, rr6

-- RR=9 - already defined
-- +2 Production - already defined

-- +2 Production, +1 Science
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange) VALUES
('BUILDING_POWER_PLANT_UPGRADE', 'YIELD_SCIENCE', 1);

-- +2 Production for each specialty district constructed - already defined

-- +3 prod from Oil Well - remove, as it is now for Oil Power Plant Upgrade
DELETE FROM BuildingModifiers WHERE BuildingType = 'BUILDING_POWER_PLANT_UPGRADE' AND ModifierId = 'POWER_PLANT_UPGRADE_ADD_OILWELL_PRODUCTION';

-- +4 Production, +2 Science from Uranium Mines
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_POWER_PLANT_UPGRADE', 'POWER_PLANT_UPGRADE_ADD_URANIUM_MINE_PRODUCTION'),
('BUILDING_POWER_PLANT_UPGRADE', 'POWER_PLANT_UPGRADE_ADD_URANIUM_MINE_SCIENCE');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('POWER_PLANT_UPGRADE_ADD_URANIUM_MINE_PRODUCTION', 'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD', 0, 0, NULL, 'PLOT_HAS_URANIUM_MINE_REQUIREMENTS'),
('POWER_PLANT_UPGRADE_ADD_URANIUM_MINE_SCIENCE',    'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD', 0, 0, NULL, 'PLOT_HAS_URANIUM_MINE_REQUIREMENTS');

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('POWER_PLANT_UPGRADE_ADD_URANIUM_MINE_PRODUCTION', 'YieldType', 'YIELD_PRODUCTION'),
('POWER_PLANT_UPGRADE_ADD_URANIUM_MINE_PRODUCTION', 'Amount',    '4'),
('POWER_PLANT_UPGRADE_ADD_URANIUM_MINE_SCIENCE', 'YieldType', 'YIELD_SCIENCE'),
('POWER_PLANT_UPGRADE_ADD_URANIUM_MINE_SCIENCE', 'Amount',    '2');

INSERT OR REPLACE INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES
('PLOT_HAS_URANIUM_MINE_REQUIREMENTS', 'REQUIREMENTSET_TEST_ALL');

INSERT OR REPLACE INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES
('PLOT_HAS_URANIUM_MINE_REQUIREMENTS', 'REQUIRES_URANIUM_IN_PLOT'), -- defined for BUILDING_RESEARCH_LAB_UPGRADE
('PLOT_HAS_URANIUM_MINE_REQUIREMENTS', 'REQUIRES_PLOT_HAS_MINE'); -- exists



--------------------------------------------------------------
-- 2019-04-06 Dam
--------------------------------------------------------------

--------------------------------------------------------------
-- HYDROELECTRIC_DAM

-- +2 power
-- Merchant's promo does not apply to the upgrade (because there is no new source in the city)
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_HYDROELECTRIC_DAM_UPGRADE', 'HYDROELECTRIC_DAM_UPGRADE_FREE_POWER');

-- Important: MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD - tiles with Districts DON'T get any bonus (e.g. City Center nor IZ where Dam was built);	
INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('HYDROELECTRIC_DAM_UPGRADE_FREE_POWER', 'MODIFIER_SINGLE_CITY_ADJUST_FREE_POWER', 0, 0, NULL, NULL);

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('HYDROELECTRIC_DAM_UPGRADE_FREE_POWER', 'SourceType', 'FREE_POWER_SOURCE_WATER'),
('HYDROELECTRIC_DAM_UPGRADE_FREE_POWER', 'Amount',     '2');

-- +1 Production from tiles adjacent to the river
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_HYDROELECTRIC_DAM_UPGRADE', 'HYDROELECTRIC_DAM_UPGRADE_ADD_PRODUCTION');

-- Important: MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD - tiles with Districts DON'T get any bonus (e.g. City Center nor IZ where Dam was built);	
INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('HYDROELECTRIC_DAM_UPGRADE_ADD_PRODUCTION', 'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD', 0, 0, NULL, 'PLOT_ADJACENT_TO_RIVER_REQUIREMENTS'); -- can't set permanent because can be pillaged

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('HYDROELECTRIC_DAM_UPGRADE_ADD_PRODUCTION', 'YieldType', 'YIELD_PRODUCTION'),
('HYDROELECTRIC_DAM_UPGRADE_ADD_PRODUCTION', 'Amount',    '1');


--------------------------------------------------------------
-- 2019-06-24 June 2019 Patch cost changes
--------------------------------------------------------------

-- defense 50%
UPDATE Buildings SET Cost = 110 WHERE BuildingType = 'BUILDING_CASTLE_UPGRADE'; -- ->220
UPDATE Buildings SET Cost = 150 WHERE BuildingType = 'BUILDING_STAR_FORT_UPGRADE'; -- ->300

-- L1 45%
UPDATE Buildings SET Cost = 170 WHERE BuildingType = 'BUILDING_HANGAR_UPGRADE'; -- ->380

-- L2 60%
UPDATE Buildings SET Cost = 200 WHERE BuildingType = 'BUILDING_FACTORY_UPGRADE'; -- ->330
UPDATE Buildings SET Cost = 200 WHERE BuildingType = 'BUILDING_ELECTRONICS_FACTORY_UPGRADE'; -- ->330
UPDATE Buildings SET Cost = 220 WHERE BuildingType = 'BUILDING_ZOO_UPGRADE'; -- ->360
UPDATE Buildings SET Cost = 220 WHERE BuildingType = 'BUILDING_AQUARIUM_UPGRADE'; -- ->360
UPDATE Buildings SET Cost = 230 WHERE BuildingType = 'BUILDING_FOOD_MARKET_UPGRADE'; -- ->380
UPDATE Buildings SET Cost = 260 WHERE BuildingType = 'BUILDING_SHOPPING_MALL_UPGRADE'; -- ->440
UPDATE Buildings SET Cost = 290 WHERE BuildingType = 'BUILDING_AIRPORT_UPGRADE'; -- ->480

-- L3 75%
UPDATE Buildings SET Cost = 250 WHERE BuildingType = 'BUILDING_MILITARY_ACADEMY_UPGRADE'; -- ->330
UPDATE Buildings SET Cost = 250 WHERE BuildingType = 'BUILDING_STOCK_EXCHANGE_UPGRADE'; -- ->330
UPDATE Buildings SET Cost = 330 WHERE BuildingType = 'BUILDING_BROADCAST_CENTER_UPGRADE'; -- ->440
UPDATE Buildings SET Cost = 330 WHERE BuildingType = 'BUILDING_FILM_STUDIO_UPGRADE'; -- ->440
UPDATE Buildings SET Cost = 330 WHERE BuildingType = 'BUILDING_RESEARCH_LAB_UPGRADE'; -- ->440
UPDATE Buildings SET Cost = 330 WHERE BuildingType = 'BUILDING_SEAPORT_UPGRADE'; -- ->440
UPDATE Buildings SET Cost = 360 WHERE BuildingType = 'BUILDING_STADIUM_UPGRADE'; -- ->480
UPDATE Buildings SET Cost = 360 WHERE BuildingType = 'BUILDING_AQUATICS_CENTER_UPGRADE'; -- ->480
UPDATE Buildings SET Cost = 270 WHERE BuildingType = 'BUILDING_FOSSIL_FUEL_POWER_PLANT_UPGRADE'; -- 450->360, 75%
UPDATE Buildings SET Cost = 330 WHERE BuildingType = 'BUILDING_HYDROELECTRIC_DAM_UPGRADE'; -- 580->440, 75%
UPDATE Buildings SET Cost = 360 WHERE BuildingType = 'BUILDING_POWER_PLANT_UPGRADE'; -- ->480


