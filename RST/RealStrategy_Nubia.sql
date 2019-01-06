-- ===========================================================================
-- Real Strategy - main file for Nubia DLC
-- Author: Infixo
-- 2019-01-05: Created
-- ===========================================================================

INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES -- generated from Excel
('LEADER_AMANITORE', 'LEADER', '', 'CONQUEST', 5),
('LEADER_AMANITORE', 'LEADER', '', 'SCIENCE',  4),
('LEADER_AMANITORE', 'LEADER', '', 'CULTURE',  4),
('LEADER_AMANITORE', 'LEADER', '', 'RELIGION', 6),
('BUILDING_JEBEL_BARKAL', 'Wonder', '', 'CONQUEST', 3),
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
('AmanitoreYields', 'YIELD_FOOD', 1, 20),
('AmanitorePseudoYields', 'PSEUDOYIELD_DISTRICT', 1, 50), -- more districts
('AmanitorePseudoYields', 'PSEUDOYIELD_HAPPINESS', 0, 25),
('AmanitorePseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, 50), -- more improvements
('AmanitoreWonders', 'BUILDING_JEBEL_BARKAL', 1, 0); -- who else?
--('AmanitoreUnits', 'UNIT_BUILDER', 1, 20); -- more improvements - should be handled by PSEUDOYIELD_IMPROVEMENT

-- Rise & Fall
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value)
SELECT 'AmanitoreWonders', 'BUILDING_KOTOKU_IN', 1, 0
FROM Types WHERE Type = 'BUILDING_KOTOKU_IN';
