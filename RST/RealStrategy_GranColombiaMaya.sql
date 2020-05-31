-- ===========================================================================
-- Real Strategy - main file for GranColombia & Maya DLC
-- Author: Infixo
-- 2020-05-31: Created
-- ===========================================================================


-- LEADER_LADY_SIX_SKY / MAYA

INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES
('LEADER_LADY_SIX_SKY', 'LEADER', '', 'CONQUEST', 1),
('LEADER_LADY_SIX_SKY', 'LEADER', '', 'SCIENCE',  8),
('LEADER_LADY_SIX_SKY', 'LEADER', '', 'CULTURE',  4),
('LEADER_LADY_SIX_SKY', 'LEADER', '', 'RELIGION', 1),
('LEADER_LADY_SIX_SKY', 'LEADER', '', 'DIPLO',    5);

INSERT INTO AiListTypes (ListType) VALUES
--MayanObservatory
('LadySixSkyWonders'),
('LadySixSkyTechs'), 
('LadySixSkyCivics'),
('LadySixSkyPseudoYields'),
('LadySixSkyUnitBuilds'),
('LadySixSkyAlliances'),
('LadySixSkyDiplomacy');

INSERT INTO AiLists (ListType, LeaderType, System) VALUES
--MayanObservatory -- Yields
('LadySixSkyWonders',      'TRAIT_LEADER_MUTAL', 'Buildings'),
('LadySixSkyTechs',        'TRAIT_LEADER_MUTAL', 'Technologies'),
('LadySixSkyCivics',       'TRAIT_LEADER_MUTAL', 'Civics'),
('LadySixSkyPseudoYields', 'TRAIT_LEADER_MUTAL', 'PseudoYields'),
('LadySixSkyUnitBuilds',   'TRAIT_LEADER_MUTAL', 'UnitPromotionClasses'),
('LadySixSkyAlliances',    'TRAIT_LEADER_MUTAL', 'Alliances'),
('LadySixSkyDiplomacy',    'TRAIT_LEADER_MUTAL', 'DiplomaticActions');

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('MayanObservatory', 'YIELD_FOOD', 1, 10), -- bigger cities, farms
('LadySixSkyWonders', 'BUILDING_CASA_DE_CONTRATACION', 0, 0), -- disfavored wonders
('LadySixSkyTechs', 'TECH_WRITING', 1, 0), -- Observatory
('LadySixSkyTechs', 'TECH_ARCHERY', 1, 0), -- unique unit
('LadySixSkyTechs', 'TECH_IRRIGATION', 1, 0), -- plantations for Observatory adjacency
('LadySixSkyCivics', 'CIVIC_DRAMA_POETRY', 1, 0), -- for Great Library
('LadySixSkyPseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, 10), -- farms & plantations
('LadySixSkyUnitBuilds', 'PROMOTION_CLASS_RANGED', 1, 10),
('LadySixSkyUnitBuilds', 'PROMOTION_CLASS_SIEGE', 1, -25),
('LadySixSkyAlliances', 'ALLIANCE_SCIENTIFIC', 1, 0),
('LadySixSkyDiplomacy', 'DIPLOACTION_ALLIANCE', 1, 0),
('LadySixSkyDiplomacy', 'DIPLOACTION_RENEW_ALLIANCE', 1, 0),
('LadySixSkyDiplomacy', 'DIPLOACTION_DECLARE_SURPRISE_WAR', 0, 0),
('LadySixSkyDiplomacy', 'DIPLOACTION_KEEP_PROMISE_DONT_SETTLE_TOO_NEAR', 0, 0); -- this may be necessary for a proper settling

-- for unknown reason Mayan trait has 0 as Favored YIELD_SCIENCE, the only case in the entire game, super weird
UPDATE AiFavoredItems
SET Favored = 1
WHERE ListType = 'MayanObservatory' AND Item = 'YIELD_SCIENCE';


-- LEADER_SIMON_BOLIVAR / GRAN_COLOMBIA

INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES
('LEADER_SIMON_BOLIVAR', 'LEADER', '', 'CONQUEST', 9),
('LEADER_SIMON_BOLIVAR', 'LEADER', '', 'SCIENCE',  2),
('LEADER_SIMON_BOLIVAR', 'LEADER', '', 'CULTURE',  2),
('LEADER_SIMON_BOLIVAR', 'LEADER', '', 'RELIGION', 1),
('LEADER_SIMON_BOLIVAR', 'LEADER', '', 'DIPLO',    1);

-- AggressivePseudoYields for non-XP leaders
INSERT OR REPLACE INTO LeaderTraits(LeaderType, TraitType) VALUES ('LEADER_SIMON_BOLIVAR', 'TRAIT_LEADER_AGGRESSIVE_MILITARY');

INSERT INTO AiListTypes (ListType) VALUES
('SimonBolivarWonders'),
('SimonBolivarTechs'), 
('SimonBolivarCivics'),
('SimonBolivarPseudoYields'),
('SimonBolivarUnitBuilds'),
('SimonBolivarDiplomacy');

INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('SimonBolivarWonders',      'TRAIT_LEADER_CAMPANA_ADMIRABLE', 'Buildings'),
('SimonBolivarTechs',        'TRAIT_LEADER_CAMPANA_ADMIRABLE', 'Technologies'),
('SimonBolivarCivics',       'TRAIT_LEADER_CAMPANA_ADMIRABLE', 'Civics'),
('SimonBolivarPseudoYields', 'TRAIT_LEADER_CAMPANA_ADMIRABLE', 'PseudoYields'),
('SimonBolivarUnitBuilds',   'TRAIT_LEADER_CAMPANA_ADMIRABLE', 'UnitPromotionClasses'),
('SimonBolivarDiplomacy',    'TRAIT_LEADER_CAMPANA_ADMIRABLE', 'DiplomaticActions');

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('SimonBolivarWonders', 'BUILDING_JEBEL_BARKAL', 1, 0), -- for Iron
('SimonBolivarWonders', 'BUILDING_STONEHENGE', 0, 0), -- disfavored
('SimonBolivarTechs', 'TECH_MILITARY_SCIENCE', 1, 0), -- unique unit
('SimonBolivarCivics', 'CIVIC_MERCANTILISM', 1, 0), -- Hacienda
('SimonBolivarPseudoYields', 'PSEUDOYIELD_STANDING_ARMY_NUMBER', 1, 10),
('SimonBolivarPseudoYields', 'PSEUDOYIELD_STANDING_ARMY_VALUE', 1, 10),
('SimonBolivarUnitBuilds', 'PROMOTION_CLASS_LIGHT_CAVALRY', 1, 10), -- Llanero
('SimonBolivarUnitBuilds', 'PROMOTION_CLASS_SIEGE', 1, 10),
('SimonBolivarDiplomacy', 'DIPLOACTION_DECLARE_FRIENDSHIP', 0, 0), -- nope
('SimonBolivarDiplomacy', 'DIPLOACTION_DENOUNCE', 1, 0),
('SimonBolivarDiplomacy', 'DIPLOACTION_DECLARE_SURPRISE_WAR', 1, 0),
('SimonBolivarDiplomacy', 'DIPLOACTION_DECLARE_FORMAL_WAR', 1, 0);
