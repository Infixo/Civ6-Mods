-- ===========================================================================
-- Real Strategy - main file for Nubia DLC
-- Author: Infixo
-- 2019-01-05: Created
-- ===========================================================================

-- iOS compatibility
-- AmanitoreWonders was added in later versions of the game

INSERT OR REPLACE INTO AiListTypes (ListType) VALUES
('AmanitoreWonders');
INSERT OR REPLACE INTO AiLists (ListType, LeaderType, System) VALUES
('AmanitoreWonders', 'TRAIT_LEADER_KANDAKE_OF_MEROE', 'Buildings');
INSERT OR REPLACE INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('AmanitoreWonders', 'BUILDING_PETRA', 1, 0),
('AmanitoreWonders', 'BUILDING_RUHR_VALLEY', 1, 0);


INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES -- generated from Excel
('LEADER_AMANITORE', 'LEADER', '', 'CONQUEST', 5),
('LEADER_AMANITORE', 'LEADER', '', 'SCIENCE',  7),
('LEADER_AMANITORE', 'LEADER', '', 'CULTURE',  3),
('LEADER_AMANITORE', 'LEADER', '', 'RELIGION', 5),
('LEADER_AMANITORE', 'LEADER', '', 'DIPLO',    1),
('BUILDING_JEBEL_BARKAL', 'Wonder', '', 'CONQUEST', 5),
('BUILDING_JEBEL_BARKAL', 'Wonder', '', 'RELIGION', 4);


-- LEADER_AMANITORE / NUBIA
-- she likes to build, improvements and districts

UPDATE AiFavoredItems SET Value = -10 WHERE ListType = 'AmanitoreUnitBuilds' AND Item = 'PROMOTION_CLASS_RANGED'; -- was 1 -- they build too many

INSERT INTO AiListTypes (ListType) VALUES
('AmanitoreYields'),
('AmanitorePseudoYields');
--('AmanitoreUnits');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('AmanitoreYields',       'TRAIT_LEADER_KANDAKE_OF_MEROE', 'Yields'),
('AmanitorePseudoYields', 'TRAIT_LEADER_KANDAKE_OF_MEROE', 'PseudoYields');
--('AmanitoreUnits',        'TRAIT_LEADER_KANDAKE_OF_MEROE', 'Units');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('AmanitoreYields', 'YIELD_FOOD', 1, 10),
('AmanitoreYields', 'YIELD_SCIENCE', 1, 10), -- 2019-04-04 Firaxis wants her more sciency
('AmanitorePseudoYields', 'PSEUDOYIELD_DISTRICT', 1, 15), -- more districts
('AmanitorePseudoYields', 'PSEUDOYIELD_HAPPINESS', 1, 20),
('AmanitorePseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, 15), -- nubian pyramid
('AmanitorePseudoYields', 'PSEUDOYIELD_GPP_SCIENTIST', 1, 15), -- 2019-04-04 Firaxis wants her more sciency
('AmanitoreWonders', 'BUILDING_JEBEL_BARKAL', 1, 0); -- who else?
--('AmanitoreUnits', 'UNIT_BUILDER', 1, 20); -- more improvements - should be handled by PSEUDOYIELD_IMPROVEMENT

-- Rise & Fall
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value)
SELECT 'AmanitoreWonders', 'BUILDING_KOTOKU_IN', 1, 0
FROM Types WHERE Type = 'BUILDING_KOTOKU_IN';

-- 2019-04-04 start bias
INSERT OR REPLACE INTO StartBiasFeatures (CivilizationType, FeatureType, Tier)
SELECT CivilizationType, 'FEATURE_FLOODPLAINS', 5
FROM Civilizations
WHERE CivilizationType = 'CIVILIZATION_NUBIA'
	AND EXISTS (SELECT * FROM GlobalParameters WHERE Name = 'RST_OPTION_BIASES' AND Value = 1);
--
DELETE FROM StartBiasResources WHERE CivilizationType = 'CIVILIZATION_NUBIA'
	AND EXISTS (SELECT * FROM GlobalParameters WHERE Name = 'RST_OPTION_BIASES' AND Value = 1);
INSERT INTO StartBiasResources (CivilizationType, ResourceType, Tier)
SELECT 'CIVILIZATION_NUBIA', ResourceType, 5
FROM Improvement_ValidResources
WHERE ImprovementType = 'IMPROVEMENT_MINE'
	AND EXISTS (SELECT * FROM GlobalParameters WHERE Name = 'RST_OPTION_BIASES' AND Value = 1);
