--------------------------------------------------------------
-- Real Building Upgrades
-- Author: Infixo
-- 2019-04-06: Created
--------------------------------------------------------------


--------------------------------------------------------------
-- THERMAL_BATH

INSERT INTO BuildingReplaces (CivUniqueBuildingType, ReplacesBuildingType) VALUES
('BUILDING_THERMAL_BATH_UPGRADE', 'BUILDING_ZOO_UPGRADE');

UPDATE Buildings SET TraitType = 'TRAIT_CIVILIZATION_BUILDING_THERMAL_BATH'
WHERE BuildingType = 'BUILDING_THERMAL_BATH_UPGRADE';

-- RR=6 (this is Tier2 building)
UPDATE Buildings SET RegionalRange = 6
WHERE BuildingType = 'BUILDING_THERMAL_BATH_UPGRADE';

-- +1 production
INSERT INTO Building_YieldChanges (BuildingType, YieldType, YieldChange) VALUES
('BUILDING_THERMAL_BATH_UPGRADE', 'YIELD_PRODUCTION', 1);

-- +4 Tourism
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_THERMAL_BATH_UPGRADE', 'ZOO_UPGRADE_TOURISM'); -- the same effect as ZOO

-- +15% city growth
INSERT INTO GameModifiers (ModifierId) VALUES
('THERMAL_BATH_UPGRADE_CITY_GROWTH');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('THERMAL_BATH_UPGRADE_CITY_GROWTH',          'MODIFIER_ALL_CITIES_ATTACH_MODIFIER',     0, 0, NULL, 'CITY_HAS_THERMAL_BATH_UPGRADE_REQUIREMENTS'),
('THERMAL_BATH_UPGRADE_CITY_GROWTH_MODIFIER', 'MODIFIER_SINGLE_CITY_ADJUST_CITY_GROWTH', 0, 0, NULL, NULL);

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('THERMAL_BATH_UPGRADE_CITY_GROWTH', 'ModifierId', 'THERMAL_BATH_UPGRADE_CITY_GROWTH_MODIFIER'),
('THERMAL_BATH_UPGRADE_CITY_GROWTH_MODIFIER', 'Amount', '15');

-- Requirement city has Thermal Bath Upgrade
INSERT INTO RequirementSets (RequirementSetId, RequirementSetType)		 VALUES ('CITY_HAS_THERMAL_BATH_UPGRADE_REQUIREMENTS', 'REQUIREMENTSET_TEST_ALL');
INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES ('CITY_HAS_THERMAL_BATH_UPGRADE_REQUIREMENTS', 'REQUIRES_CITY_HAS_THERMAL_BATH_UPGRADE');
INSERT INTO Requirements (RequirementId, RequirementType)				 VALUES ('REQUIRES_CITY_HAS_THERMAL_BATH_UPGRADE', 'REQUIREMENT_CITY_HAS_BUILDING');
INSERT INTO RequirementArguments (RequirementId, Name, Value)			 VALUES ('REQUIRES_CITY_HAS_THERMAL_BATH_UPGRADE', 'BuildingType', 'BUILDING_THERMAL_BATH_UPGRADE');

-- +4 Gold & Culture in the city when Geothermal Fissure is present
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_THERMAL_BATH_UPGRADE', 'THERMAL_BATH_UPGRADE_ADD_GOLD'),
('BUILDING_THERMAL_BATH_UPGRADE', 'THERMAL_BATH_UPGRADE_ADD_CULTURE');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('THERMAL_BATH_UPGRADE_ADD_GOLD',    'MODIFIER_SINGLE_CITY_ADJUST_YIELD_CHANGE', 0, 0, NULL, 'CITY_HAS_1_OR_MORE_GEOTHERMALFISSURE_REQUIREMENTS'),
('THERMAL_BATH_UPGRADE_ADD_CULTURE', 'MODIFIER_SINGLE_CITY_ADJUST_YIELD_CHANGE', 0, 0, NULL, 'CITY_HAS_1_OR_MORE_GEOTHERMALFISSURE_REQUIREMENTS');

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('THERMAL_BATH_UPGRADE_ADD_GOLD', 'YieldType', 'YIELD_GOLD'),
('THERMAL_BATH_UPGRADE_ADD_GOLD', 'Amount',    '4'),
('THERMAL_BATH_UPGRADE_ADD_CULTURE', 'YieldType', 'YIELD_CULTURE'),
('THERMAL_BATH_UPGRADE_ADD_CULTURE', 'Amount',    '4');
