-- ===========================================================================
-- Real Strategy - main file for Byzantium & Gaul DLC
-- Author: Infixo
-- 2021-06-15: Created
-- ===========================================================================


-- Wonders
INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES -- generated from Excel
('BUILDING_BIOSPHERE',      'Wonder', '', 'CULTURE',  8),
('BUILDING_STATUE_OF_ZEUS', 'Wonder', '', 'CONQUEST', 6);


-- LEADER_AMBIORIX / GAUL

INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES
('LEADER_AMBIORIX', 'LEADER', '', 'CONQUEST', 1),
('LEADER_AMBIORIX', 'LEADER', '', 'SCIENCE',  3),
('LEADER_AMBIORIX', 'LEADER', '', 'CULTURE',  6),
('LEADER_AMBIORIX', 'LEADER', '', 'RELIGION', 8),
('LEADER_AMBIORIX', 'LEADER', '', 'DIPLO',    3);

-- LEADER_BASIL / BYZANTIUM

INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES
('LEADER_BASIL', 'LEADER', '', 'CONQUEST', 1),
('LEADER_BASIL', 'LEADER', '', 'SCIENCE',  3),
('LEADER_BASIL', 'LEADER', '', 'CULTURE',  6),
('LEADER_BASIL', 'LEADER', '', 'RELIGION', 8),
('LEADER_BASIL', 'LEADER', '', 'DIPLO',    3);
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