-- ===========================================================================
-- Real Strategy - main file for Macedonia & Persia DLC
-- Author: Infixo
-- 2019-01-05: Created
-- ===========================================================================

INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES -- generated from Excel
('LEADER_ALEXANDER', 'LEADER', '', 'CONQUEST', 8),
('LEADER_ALEXANDER', 'LEADER', '', 'SCIENCE',  5),
('LEADER_ALEXANDER', 'LEADER', '', 'CULTURE',  3),
('LEADER_ALEXANDER', 'LEADER', '', 'RELIGION', 1),
('LEADER_ALEXANDER', 'LEADER', '', 'DIPLO',    1),
('LEADER_CYRUS', 'LEADER', '', 'CONQUEST', 7),
('LEADER_CYRUS', 'LEADER', '', 'SCIENCE',  3),
('LEADER_CYRUS', 'LEADER', '', 'CULTURE',  5),
('LEADER_CYRUS', 'LEADER', '', 'RELIGION', 1),
('LEADER_CYRUS', 'LEADER', '', 'DIPLO',    2),
('BUILDING_APADANA', 'Wonder', '', 'CULTURE', 3),
('BUILDING_APADANA', 'Wonder', '', 'DIPLO',   4),
('BUILDING_HALICARNASSUS_MAUSOLEUM', 'Wonder', '', 'CONQUEST', 2),
('BUILDING_HALICARNASSUS_MAUSOLEUM', 'Wonder', '', 'SCIENCE',  3);



-- ALEXANDER / MACEDON
-- can't use DarwinistIgnoreWarmongerValue - others use it too

-- 2018-03-26: AiLists Alexander's trait
UPDATE AiLists SET LeaderType = 'TRAIT_LEADER_TO_WORLDS_END' WHERE LeaderType = 'TRAIT_LEADER_CITADEL_CIVILIZATION' AND ListType IN ('AlexanderCivics', 'AlexanderTechs', 'AlexanderWonders');

INSERT INTO AiListTypes (ListType) VALUES
('AlexanderPseudoYields'),
('AlexanderUnitBuilds');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('AlexanderPseudoYields', 'TRAIT_LEADER_TO_WORLDS_END', 'PseudoYields'),
('AlexanderUnitBuilds',   'TRAIT_LEADER_TO_WORLDS_END', 'UnitPromotionClasses');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('AlexanderPseudoYields', 'PSEUDOYIELD_CITY_BASE', 1, 150), -- because cities give boosts!
('AlexanderPseudoYields', 'PSEUDOYIELD_CITY_DEFENSES', 1, -15), -- because cities give boosts!
('AlexanderPseudoYields', 'PSEUDOYIELD_WONDER', 1, 15), -- because he has a ton of Wonders as favored and heals when captures one
('AlexanderPseudoYields', 'PSEUDOYIELD_UNIT_COMBAT', 1, 15), -- obvious
('AlexanderPseudoYields', 'PSEUDOYIELD_UNIT_EXPLORER', 1, 10), -- because he needs to know neighbors fast
('AlexanderPseudoYields', 'PSEUDOYIELD_GPP_GENERAL', 1, 15), -- obvious
('AlexanderUnitBuilds', 'PROMOTION_CLASS_SIEGE', 1, 10); -- for cities


-- CYRUS / PERSIA
-- TRAIT_RST_MORE_TRADE_ROUTES

INSERT INTO AiListTypes (ListType) VALUES
('CyrusYields'),
('CyrusPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('CyrusYields',       'TRAIT_LEADER_FALL_BABYLON', 'Yields'),
('CyrusPseudoYields', 'TRAIT_LEADER_FALL_BABYLON', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('CyrusYields', 'YIELD_CULTURE', 1, 10),
('CyrusYields', 'YIELD_GOLD', 1, 10),
('CyrusPseudoYields', 'PSEUDOYIELD_DISTRICT', 1, 15),
('CyrusPseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, 15), -- pairidaeza
('CyrusPseudoYields', 'PSEUDOYIELD_TOURISM', 1, 10),
('CyrusPseudoYields', 'PSEUDOYIELD_UNIT_COMBAT', 1, 15),
('CyrusPseudoYields', 'PSEUDOYIELD_UNIT_TRADE', 1, 50);
