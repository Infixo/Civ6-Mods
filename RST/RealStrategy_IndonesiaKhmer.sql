-- ===========================================================================
-- Real Strategy - main file for Indonesia & Khmer DLC
-- Author: Infixo
-- 2019-01-05: Created
-- ===========================================================================

-- iOS compatibility
-- GitarjaWonders was added in later versions of the game

INSERT OR REPLACE INTO AiListTypes (ListType) VALUES
('GitarjaWonders');
INSERT OR REPLACE INTO AiLists (ListType, LeaderType, System) VALUES
('GitarjaWonders', 'TRAIT_LEADER_EXALTED_GODDESS', 'Buildings');
INSERT OR REPLACE INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('GitarjaWonders', 'BUILDING_GREAT_LIGHTHOUSE', 1, 0);


INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES -- generated from Excel
('LEADER_GITARJA', 'LEADER', '', 'CONQUEST', 1),
('LEADER_GITARJA', 'LEADER', '', 'SCIENCE',  4),
('LEADER_GITARJA', 'LEADER', '', 'CULTURE',  4),
('LEADER_GITARJA', 'LEADER', '', 'RELIGION', 6),
('LEADER_JAYAVARMAN', 'LEADER', '', 'CONQUEST', 2),
('LEADER_JAYAVARMAN', 'LEADER', '', 'SCIENCE',  1),
('LEADER_JAYAVARMAN', 'LEADER', '', 'CULTURE',  5),
('LEADER_JAYAVARMAN', 'LEADER', '', 'RELIGION', 8),
('BUILDING_ANGKOR_WAT', 'Wonder', '', 'SCIENCE',  2),
('BUILDING_ANGKOR_WAT', 'Wonder', '', 'CULTURE',  2),
('BUILDING_ANGKOR_WAT', 'Wonder', '', 'RELIGION', 3);


-- LEADER_GITARJA / INDONESIA
-- TRAIT_RST_MORE_NAVAL
-- TRAIT_RST_MORE_IMPROVEMENTS

INSERT INTO AiListTypes (ListType) VALUES
('GitarjaSettlement'),
('GitarjaYields'),
('GitarjaPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('GitarjaSettlement',   'TRAIT_LEADER_EXALTED_GODDESS', 'PlotEvaluations'),
('GitarjaYields',       'TRAIT_LEADER_EXALTED_GODDESS', 'Yields'),
('GitarjaPseudoYields', 'TRAIT_LEADER_EXALTED_GODDESS', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('GitarjaSettlement', 'Coastal', 0, 10),
('GitarjaYields', 'YIELD_FAITH',      1, 10),
('GitarjaYields', 'YIELD_FOOD',       1, 10),
('GitarjaYields', 'YIELD_PRODUCTION', 1,  5),
('GitarjaYields', 'YIELD_GOLD',       1,-10),
('GitarjaYields', 'YIELD_CULTURE',    1,  5),
('GitarjaYields', 'YIELD_SCIENCE',    1, -5),
('GitarjaWonders', 'BUILDING_ANGKOR_WAT', 1, 0),
('GitarjaPseudoYields', 'PSEUDOYIELD_CITY_BASE', 1, -100), -- do NOT conquer neighbors
('GitarjaPseudoYields', 'PSEUDOYIELD_CITY_POPULATION', 1, -100), -- do NOT conquer neighbors
('GitarjaPseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, 20), -- kampung
('GitarjaPseudoYields', 'PSEUDOYIELD_HAPPINESS', 1, 20),
('GitarjaPseudoYields', 'PSEUDOYIELD_GPP_ADMIRAL', 1, 5),
('GitarjaPseudoYields', 'PSEUDOYIELD_UNIT_NAVAL_COMBAT', 1, 5);


-- LEADER_JAYAVARMAN / KHMER

UPDATE AiFavoredItems SET Value = 25 WHERE ListType = 'JayavarmanUnitBuilds' AND Item = 'UNIT_MISSIONARY'; -- was 1

INSERT INTO AiListTypes (ListType) VALUES
('JayavarmanDistricts'),
('JayavarmanYields'),
('JayavarmanPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('JayavarmanDistricts',    'TRAIT_LEADER_MONASTERIES_KING', 'Districts'),
('JayavarmanYields',       'TRAIT_LEADER_MONASTERIES_KING', 'Yields'),
('JayavarmanPseudoYields', 'TRAIT_LEADER_MONASTERIES_KING', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('JayavarmanDistricts', 'DISTRICT_AQUEDUCT', 1, 0), -- risky???
('JayavarmanDistricts', 'DISTRICT_HOLY_SITE', 1, 0), -- risky???
('JayavarmanYields', 'YIELD_FAITH',   1, 10),
('JayavarmanYields', 'YIELD_FOOD',    1, 15),
('JayavarmanYields', 'YIELD_SCIENCE', 1, -5),
('JayavarmanYields', 'YIELD_GOLD',    1,-10),
('JayavarmanPseudoYields', 'PSEUDOYIELD_GPP_PROPHET', 1, 20),
('JayavarmanPseudoYields', 'PSEUDOYIELD_GREATWORK_RELIC', 0, 25),
('JayavarmanPseudoYields', 'PSEUDOYIELD_HAPPINESS', 0, 25),
('JayavarmanPseudoYields', 'PSEUDOYIELD_UNIT_COMBAT', 1, -10),
('JayavarmanPseudoYields', 'PSEUDOYIELD_UNIT_NAVAL_COMBAT', 1, -10);


-- tactics
INSERT INTO UnitAiInfos (UnitType, AiType)
SELECT 'UNIT_KHMER_DOMREY', 'UNITTYPE_SIEGE_ALL' -- iOS compatibility
FROM UnitAiTypes
WHERE AiType = 'UNITTYPE_SIEGE_ALL';
