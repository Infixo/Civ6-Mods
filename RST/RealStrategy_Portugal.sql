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

INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES
('LEADER_JOAO_III', 'LEADER', '', 'CONQUEST', 1),
('LEADER_JOAO_III', 'LEADER', '', 'SCIENCE',  3),
('LEADER_JOAO_III', 'LEADER', '', 'CULTURE',  6),
('LEADER_JOAO_III', 'LEADER', '', 'RELIGION', 8),
('LEADER_JOAO_III', 'LEADER', '', 'DIPLO',    3);
/*
INSERT INTO AiListTypes (ListType) VALUES
('MenelikWonders'),
('MenelikTechs'), 
('MenelikCivics'),
('MenelikPseudoYields'),
('MenelikUnitBuilds'),
('MenelikAlliances');
-- no specific diplomacy list

INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('MenelikWonders',      'TRAIT_LEADER_MENELIK', 'Buildings'),
('MenelikTechs',        'TRAIT_LEADER_MENELIK', 'Technologies'),
('MenelikCivics',       'TRAIT_LEADER_MENELIK', 'Civics'),
('MenelikPseudoYields', 'TRAIT_LEADER_MENELIK', 'PseudoYields'),
('MenelikUnitBuilds',   'TRAIT_LEADER_MENELIK', 'UnitPromotionClasses'),
('MenelikAlliances',    'TRAIT_LEADER_MENELIK', 'Alliances');

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('MenelikWonders', 'BUILDING_HAGIA_SOPHIA', 1, 0), -- cheaper religious units
('MenelikWonders', 'BUILDING_COLOSSUS',     1, 0), -- TRs
('MenelikTechs', 'TECH_CASTLES', 1, 0), -- unique unit
('MenelikCivics', 'CIVIC_DRAMA_POETRY',  1, 0), -- unique improvement
('MenelikCivics', 'CIVIC_FOREIGN_TRADE', 1, 0), -- traders
('MenelikPseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, 15), -- church & improved resources
('MenelikPseudoYields', 'PSEUDOYIELD_UNIT_TRADE',  1, 25), -- traders
('MenelikUnitBuilds', 'PROMOTION_CLASS_LIGHT_CAVALRY', 1, 10),
('MenelikAlliances', 'ALLIANCE_RELIGIOUS', 1, 0),
('MenelikAlliances', 'ALLIANCE_CULTURAL',  1, 0);
*/