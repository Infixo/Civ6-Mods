--------------------------------------------------------------
-- Real Building Upgrades
-- Author: Infixo
-- 2019-04-06: Created
--------------------------------------------------------------


--------------------------------------------------------------
-- MARAE

INSERT INTO BuildingReplaces (CivUniqueBuildingType, ReplacesBuildingType) VALUES
('BUILDING_MARAE_UPGRADE', 'BUILDING_AMPHITHEATER_UPGRADE');

UPDATE Buildings SET TraitType = 'TRAIT_CIVILIZATION_BUILDING_MARAE'
WHERE BuildingType = 'BUILDING_MARAE_UPGRADE';

-- +1 Amenity
UPDATE Buildings SET Entertainment = 1
WHERE BuildingType = 'BUILDING_MARAE_UPGRADE';

-- +0.2 culture per pop as Amphitheater
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_MARAE_UPGRADE', 'AMPHITHEATER_UPGRADE_ADJUST_CULTURE_PER_POP');

-- +1 Loyalty, central to identity
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_MARAE_UPGRADE', 'MARAE_UPGRADE_LOYALTY');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('MARAE_UPGRADE_LOYALTY', 'MODIFIER_SINGLE_CITY_ADJUST_IDENTITY_PER_TURN', 0, 0, NULL, NULL);

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('MARAE_UPGRADE_LOYALTY', 'Amount', '1');

-- +1 Production from Marsh and unimproved Woods and Rainforest
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_MARAE_UPGRADE', 'MARAE_UPGRADE_ADD_FOREST_PRODUCTION'),
('BUILDING_MARAE_UPGRADE', 'MARAE_UPGRADE_ADD_JUNGLE_PRODUCTION'),
('BUILDING_MARAE_UPGRADE', 'MARAE_UPGRADE_ADD_MARSH_PRODUCTION');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('MARAE_UPGRADE_ADD_FOREST_PRODUCTION', 'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD', 0, 0, NULL, 'PLOT_HAS_FOREST_NO_IMPROVEMENT_REQUIREMENTS'),
('MARAE_UPGRADE_ADD_JUNGLE_PRODUCTION', 'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD', 0, 0, NULL, 'PLOT_HAS_JUNGLE_NO_IMPROVEMENT_REQUIREMENTS'),
('MARAE_UPGRADE_ADD_MARSH_PRODUCTION',  'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD', 0, 0, NULL, 'ZOO_MARSH_REQUIREMENTS'); -- !!!ZOO!!!

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('MARAE_UPGRADE_ADD_FOREST_PRODUCTION', 'YieldType', 'YIELD_PRODUCTION'),
('MARAE_UPGRADE_ADD_FOREST_PRODUCTION', 'Amount',    '1'),
('MARAE_UPGRADE_ADD_JUNGLE_PRODUCTION', 'YieldType', 'YIELD_PRODUCTION'),
('MARAE_UPGRADE_ADD_JUNGLE_PRODUCTION', 'Amount',    '1'),
('MARAE_UPGRADE_ADD_MARSH_PRODUCTION',  'YieldType', 'YIELD_PRODUCTION'),
('MARAE_UPGRADE_ADD_MARSH_PRODUCTION',  'Amount',    '1');

-- +2 Gold from FEATURE_REEF
INSERT INTO BuildingModifiers (BuildingType, ModifierId) VALUES
('BUILDING_MARAE_UPGRADE', 'MARAE_UPGRADE_ADD_REEF_GOLD');

INSERT INTO Modifiers (ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId, SubjectRequirementSetId) VALUES
('MARAE_UPGRADE_ADD_REEF_GOLD', 'MODIFIER_CITY_PLOT_YIELDS_ADJUST_PLOT_YIELD', 0, 0, NULL, 'AQUARIUM_REEF_REQUIREMENTS'); -- !!!AQUARIUM!!!

INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('MARAE_UPGRADE_ADD_REEF_GOLD', 'YieldType', 'YIELD_GOLD'),
('MARAE_UPGRADE_ADD_REEF_GOLD', 'Amount',    '2');
