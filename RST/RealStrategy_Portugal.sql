-- ===========================================================================
-- Real Strategy - main file for Portugal DLC
-- Author: Infixo
-- 2021-06-15: Created
-- ===========================================================================


-- Wonders
INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES -- generated from Excel
('BUILDING_TORRE_DE_BELEM', 'Wonder', '', 'CONQUEST', 2),
('BUILDING_TORRE_DE_BELEM', 'Wonder', '', 'SCIENCE',  2),
('BUILDING_TORRE_DE_BELEM', 'Wonder', '', 'CULTURE',  2),
('BUILDING_TORRE_DE_BELEM', 'Wonder', '', 'RELIGION', 2),
('BUILDING_TORRE_DE_BELEM', 'Wonder', '', 'DIPLO',    2),
('BUILDING_ETEMENANKI', 'Wonder', '', 'CONQUEST', 2),
('BUILDING_ETEMENANKI', 'Wonder', '', 'SCIENCE',  5);


-- LEADER_JOAO_III / PORTUGAL
-- TRAIT_LEADER_JOAO_III

INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES
('LEADER_JOAO_III', 'LEADER', '', 'CONQUEST', 3),
('LEADER_JOAO_III', 'LEADER', '', 'SCIENCE',  6),
('LEADER_JOAO_III', 'LEADER', '', 'CULTURE',  3),
('LEADER_JOAO_III', 'LEADER', '', 'RELIGION', 1),
('LEADER_JOAO_III', 'LEADER', '', 'DIPLO',    5);

INSERT INTO AiListTypes (ListType) VALUES
('JoaoWonders'),
('JoaoTechs'), 
('JoaoYields'),
('JoaoUnitBuilds');

INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('JoaoWonders',      'TRAIT_LEADER_JOAO_III', 'Buildings'),
('JoaoTechs',        'TRAIT_LEADER_JOAO_III', 'Technologies'),
('JoaoYields',       'TRAIT_LEADER_JOAO_III', 'Yields'),
('JoaoUnitBuilds',   'TRAIT_LEADER_JOAO_III', 'UnitPromotionClasses');

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('JoaoWonders', 'BUILDING_COLOSSUS', 1, 0),
('JoaoWonders', 'BUILDING_TORRE_DE_BELEM', 1, 0),
('JoaoWonders', 'BUILDING_VENETIAN_ARSENAL', 1, 0),
('JoaoTechs', 'TECH_WRITING', 1, 0),
('JoaoTechs', 'TECH_EDUCATION', 1, 0),
('JoaoTechs', 'TECH_CARTOGRAPHY', 1, 0),
('JoaoYields', 'YIELD_GOLD', 1, 10), -- traders
('JoaoExplorationObsessed', 'PSEUDOYIELD_GPP_ADMIRAL', 1, 10), -- harbors & nav school
('JoaoExplorationObsessed', 'PSEUDOYIELD_UNIT_NAVAL_COMBAT', 1, 10), -- caravels, etc.
('JoaoExplorationObsessed', 'PSEUDOYIELD_UNIT_TRADE',  1, 20), -- traders
('JoaoUnitBuilds', 'PROMOTION_CLASS_NAVAL_MELEE', 1, 10); -- nau

UPDATE AiFavoredItems SET Value = 20 WHERE ListType = 'JoaoExplorationObsessed' AND Item = 'PSEUDOYIELD_UNIT_EXPLORER';
