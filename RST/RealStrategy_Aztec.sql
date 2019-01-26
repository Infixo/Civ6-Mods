-- ===========================================================================
-- Real Strategy - main file for Aztec DLC
-- Author: Infixo
-- 2019-01-05: Created
-- ===========================================================================

INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES -- generated from Excel
('LEADER_MONTEZUMA', 'LEADER', '', 'CONQUEST', 8),
('LEADER_MONTEZUMA', 'LEADER', '', 'SCIENCE',  2),
('LEADER_MONTEZUMA', 'LEADER', '', 'CULTURE',  2),
('LEADER_MONTEZUMA', 'LEADER', '', 'RELIGION', 4),
('BUILDING_HUEY_TEOCALLI', 'Wonder', '', 'CONQUEST', 2),
('BUILDING_HUEY_TEOCALLI', 'Wonder', '', 'SCIENCE',  2),
('BUILDING_HUEY_TEOCALLI', 'Wonder', '', 'CULTURE',  1),
('BUILDING_HUEY_TEOCALLI', 'Wonder', '', 'RELIGION', 1);


-- LEADER_MONTEZUMA / AZTEC

DELETE FROM AiFavoredItems WHERE ListType = 'MontezumaTechs' AND Item = 'TECH_ASTROLOGY';

INSERT INTO AiListTypes (ListType) VALUES
('MontezumaSettlement'),
('MontezumaPseudoYields'),
('MontezumaUnits'),
('MontezumaUnitBuilds');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('MontezumaSettlement',   'TRAIT_LEADER_GIFTS_FOR_TLATOANI', 'PlotEvaluations'),
('MontezumaPseudoYields', 'TRAIT_LEADER_GIFTS_FOR_TLATOANI', 'PseudoYields'),
('MontezumaUnits',        'TRAIT_LEADER_GIFTS_FOR_TLATOANI', 'Units'),
('MontezumaUnitBuilds',   'TRAIT_LEADER_GIFTS_FOR_TLATOANI', 'UnitPromotionClasses');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('MontezumaTechs', 'TECH_MINING', 1, 0), -- most luxes are here -- !BUGGED!
('MontezumaTechs', 'TECH_IRRIGATION', 1, 0), -- most luxes are here -- !BUGEGD!
('MontezumaPseudoYields', 'PSEUDOYIELD_CITY_BASE', 1, 100), -- this.. is.. MONTY! +100%
('MontezumaPseudoYields', 'PSEUDOYIELD_CITY_DEFENDING_UNITS', 1, -25), -- we need those builders -25%
--('MontezumaPseudoYields', 'PSEUDOYIELD_CITY_ORIGINAL_CAPITAL', 1, 50),
('MontezumaPseudoYields', 'PSEUDOYIELD_UNIT_COMBAT', 1, 15),
('MontezumaPseudoYields', 'PSEUDOYIELD_UNIT_NAVAL_COMBAT', 1, -15),
('MontezumaPseudoYields', 'PSEUDOYIELD_GPP_ADMIRAL', 1, -10),
('MontezumaPseudoYields', 'PSEUDOYIELD_GPP_GENERAL', 1, 15),
('MontezumaPseudoYields', 'PSEUDOYIELD_GPP_PROPHET', 1, -25),
('MontezumaPseudoYields', 'PSEUDOYIELD_DISTRICT', 1, 15), -- more districts
('MontezumaPseudoYields', 'PSEUDOYIELD_UNIT_SETTLER', 1, 10), -- vanilla 1, RFX 1.2
('MontezumaWonders',      'BUILDING_HUEY_TEOCALLI', 1, 0), -- who else?
('MontezumaUnits',        'UNIT_BUILDER', 1, 15),
('MontezumaUnits',        'UNIT_MILITARY_ENGINEER', 1, -50);
-- There is a bug in BH Node that makes him build Engis instead of Builders, probably because they both have tag UNITAI_BUILD
-- Seems that BH is actually working good, because one can use Engi to speed up the District.
-- So, the bug is in the ability. Anyway, he produces dozens of them, so at least slow it down a bit.
--('MontezumaUnitBuilds',   'PROMOTION_CLASS_SIEGE', 1, 10);

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value, StringVal) VALUES
('MontezumaSettlement', 'Fresh Water',           0,-6,                   NULL), -- 16
('MontezumaSettlement', 'Coastal',               0,-3,                   NULL), -- 7
('MontezumaSettlement', 'Nearest Friendly City', 0, 2,                   NULL), -- a bit of forward settling
('MontezumaSettlement', 'New Resources',         0, 3,                   NULL), -- vanilla 4, RFX 5
('MontezumaSettlement', 'Resource Class',        0, 2, 'RESOURCECLASS_LUXURY'); -- vanilla 2, RFX 3
--('MontezumaSettlement', 'Cultural Pressure',     0, 1,                   NULL); -- careful not to loose new cities - I am not sure this works as intended
