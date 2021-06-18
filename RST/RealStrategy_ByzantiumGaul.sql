-- ===========================================================================
-- Real Strategy - main file for Byzantium & Gaul DLC
-- Author: Infixo
-- 2021-06-17: Created
-- ===========================================================================


-- Wonders
INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES -- generated from Excel
('BUILDING_BIOSPHERE',      'Wonder', '', 'CULTURE',  8),
('BUILDING_STATUE_OF_ZEUS', 'Wonder', '', 'CONQUEST', 6);



-- LEADER_AMBIORIX / GAUL
-- TRAIT_LEADER_AMBIORIX
-- Oppidum @ Iron Working
-- culture for training military units
-- melee, anti-cav, ranged

INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES
('LEADER_AMBIORIX', 'LEADER', '', 'CONQUEST', 8),
('LEADER_AMBIORIX', 'LEADER', '', 'SCIENCE',  5),
('LEADER_AMBIORIX', 'LEADER', '', 'CULTURE',  3),
('LEADER_AMBIORIX', 'LEADER', '', 'RELIGION', 1),
('LEADER_AMBIORIX', 'LEADER', '', 'DIPLO',    1);

INSERT INTO AiListTypes (ListType) VALUES
('AmbiorixTechs'),
('AmbiorixCivics'),
('AmbiorixPseudoYields'),
('AmbiorixUnitBuilds');

INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('AmbiorixTechs',        'TRAIT_LEADER_AMBIORIX', 'Technologies'),
('AmbiorixCivics',       'TRAIT_LEADER_AMBIORIX', 'Civics'),
('AmbiorixPseudoYields', 'TRAIT_LEADER_AMBIORIX', 'PseudoYields'),
('AmbiorixUnitBuilds',   'TRAIT_LEADER_AMBIORIX', 'UnitPromotionClasses');

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('AmbiorixTechs', 'TECH_IRON_WORKING', 1, 0), -- oppidum
('AmbiorixTechs', 'TECH_ARCHERY', 1, 0),
('AmbiorixCivics', 'CIVIC_MILITARY_TRADITION',  1, 0), -- flanking bonus
('AmbiorixCivics', 'CIVIC_MERCENARIES', 1, 0),
('AmbiorixPseudoYields', 'PSEUDOYIELD_UNIT_COMBAT', 1, 15),
('AmbiorixPseudoYields', 'PSEUDOYIELD_UNIT_NAVAL_COMBAT',  1, -20),
('AmbiorixPseudoYields', 'PSEUDOYIELD_STANDING_ARMY_NUMBER', 1, 15),
('AmbiorixPseudoYields', 'PSEUDOYIELD_STANDING_ARMY_VALUE', 1, 15),
('AmbiorixUnitBuilds', 'PROMOTION_CLASS_MELEE', 1, 15),
('AmbiorixUnitBuilds', 'PROMOTION_CLASS_RANGED', 1, 15),
('AmbiorixUnitBuilds', 'PROMOTION_CLASS_ANTI_CAVALRY', 1, 15);



-- LEADER_BASIL / BYZANTIUM
-- TRAIT_LEADER_BASIL
-- Tagma @ Divine Right
-- holy city converted, holy sites, heavy and light cav

INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES
('LEADER_BASIL', 'LEADER', '', 'CONQUEST', 7),
('LEADER_BASIL', 'LEADER', '', 'SCIENCE',  1),
('LEADER_BASIL', 'LEADER', '', 'CULTURE',  1),
('LEADER_BASIL', 'LEADER', '', 'RELIGION', 7),
('LEADER_BASIL', 'LEADER', '', 'DIPLO',    1);

INSERT INTO AiListTypes (ListType) VALUES
('BasilWonders'),
('BasilTechs'), 
('BasilCivics'),
('BasilPseudoYields'),
('BasilUnitBuilds'),
('BasilDiplomacy');

INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('BasilWonders',      'TRAIT_LEADER_BASIL', 'Buildings'),
('BasilTechs',        'TRAIT_LEADER_BASIL', 'Technologies'),
('BasilCivics',       'TRAIT_LEADER_BASIL', 'Civics'),
('BasilPseudoYields', 'TRAIT_LEADER_BASIL', 'PseudoYields'),
('BasilUnitBuilds',   'TRAIT_LEADER_BASIL', 'UnitPromotionClasses'),
('BasilDiplomacy',    'TRAIT_LEADER_BASIL', 'DiplomaticActions');

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('BasilWonders', 'BUILDING_HAGIA_SOPHIA', 1, 0), -- cheaper religious units
('BasilTechs', 'TECH_ASTROLOGY', 1, 0),
('BasilTechs', 'TECH_THE_WHEEL', 1, 0),
('BasilTechs', 'TECH_HORSEBACK_RIDING', 1, 0),
('BasilCivics', 'CIVIC_MYSTICISM',  1, 0),
('BasilCivics', 'CIVIC_GAMES_RECREATION',  1, 0),
('BasilCivics', 'CIVIC_DIVINE_RIGHT', 1, 0),
('BasilPseudoYields', 'PSEUDOYIELD_GPP_PROPHET', 1, 15),
('BasilPseudoYields', 'PSEUDOYIELD_UNIT_RELIGIOUS',  1, 15),
('BasilPseudoYields', 'PSEUDOYIELD_RELIGIOUS_CONVERT_EMPIRE',  1, 15),
('BasilUnitBuilds', 'PROMOTION_CLASS_HEAVY_CAVALRY', 1, 10),
('BasilUnitBuilds', 'PROMOTION_CLASS_LIGHT_CAVALRY', 1, 10),
('BasilDiplomacy', 'DIPLOACTION_DECLARE_HOLY_WAR', 1, 0),
('BasilDiplomacy', 'DIPLOACTION_KEEP_PROMISE_DONT_CONVERT', 0, 0);

-- why firaxis wants him to build walls???
DELETE FROM AiFavoredItems WHERE ListType = 'BasilFavoredBuildings';
DELETE FROM AiLists WHERE ListType = 'BasilFavoredBuildings';
DELETE FROM AiListTypes WHERE ListType = 'BasilFavoredBuildings';
