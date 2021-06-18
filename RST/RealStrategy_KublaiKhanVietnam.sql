-- ===========================================================================
-- Real Strategy - main file for Kublai Khan & Vietnam DLC
-- Author: Infixo
-- 2021-06-18: Created
-- ===========================================================================


-- Kublai Khan
-- TRAIT_LEADER_KUBLAI
-- trade routes, gold, rather peaceful

INSERT INTO AiListTypes (ListType) VALUES
('KublaiWonders'),
('KublaiTechs'), 
('KublaiCivics'),
('KublaiDiplomacy');

INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('KublaiWonders',      'TRAIT_LEADER_KUBLAI', 'Buildings'),
('KublaiTechs',        'TRAIT_LEADER_KUBLAI', 'Technologies'),
('KublaiCivics',       'TRAIT_LEADER_KUBLAI', 'Civics'),
('KublaiDiplomacy',    'TRAIT_LEADER_KUBLAI', 'DiplomaticActions');

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('KublaiWonders', 'BUILDING_COLOSSUS', 1, 0),
('KublaiWonders', 'BUILDING_GREAT_ZIMBABWE', 1, 0),
('KublaiTechs', 'TECH_CURRENCY', 1, 0),
('KublaiTechs', 'TECH_CELESTIAL_NAVIGATION', 1, 0),
('KublaiCivics', 'CIVIC_FOREIGN_TRADE', 1, 0),
('KublaiCivics', 'CIVIC_CIVIL_SERVICE', 1, 0),
('KublaiDiplomacy', 'DIPLOACTION_ALLIANCE', 1, 0),
('KublaiDiplomacy', 'DIPLOACTION_DECLARE_FRIENDSHIP',  1, 0);

UPDATE AiFavoredItems SET Value = 25 WHERE ListType = 'KublaiKhanPseudoYieldPreferences' AND Item = 'PSEUDOYIELD_UNIT_TRADE';

-- LEADER_KUBLAI_KHAN_CHINA / CHINA
-- TRAIT_LEADER_KUBLAI
-- wonders!

INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES
('LEADER_KUBLAI_KHAN_CHINA', 'LEADER', '', 'CONQUEST', 1),
('LEADER_KUBLAI_KHAN_CHINA', 'LEADER', '', 'SCIENCE',  4),
('LEADER_KUBLAI_KHAN_CHINA', 'LEADER', '', 'CULTURE',  6),
('LEADER_KUBLAI_KHAN_CHINA', 'LEADER', '', 'RELIGION', 1),
('LEADER_KUBLAI_KHAN_CHINA', 'LEADER', '', 'DIPLO',    4);

INSERT INTO Types (Type, Kind) VALUES
('TRAIT_LEADER_KUBLAI_CHINA', 'KIND_TRAIT');

INSERT INTO Traits (TraitType, InternalOnly) VALUES
('TRAIT_LEADER_KUBLAI_CHINA', 0);

INSERT INTO LeaderTraits (LeaderType, TraitType) VALUES
('LEADER_KUBLAI_KHAN_CHINA', 'TRAIT_LEADER_KUBLAI_CHINA');

INSERT INTO AiListTypes (ListType) VALUES
('KublaiChinaPseudoYields');

INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('KublaiChinaPseudoYields', 'TRAIT_LEADER_KUBLAI_CHINA', 'PseudoYields');

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('KublaiChinaPseudoYields', 'PSEUDOYIELD_WONDER', 1, 25),
('KublaiChinaPseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, 20);



-- LEADER_KUBLAI_KHAN_MONGOLIA / MONGOLIA
-- TRAIT_LEADER_KUBLAI
-- give him a bit bigger army + keshigs

INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES
('LEADER_KUBLAI_KHAN_MONGOLIA', 'LEADER', '', 'CONQUEST', 1),
('LEADER_KUBLAI_KHAN_MONGOLIA', 'LEADER', '', 'SCIENCE',  6),
('LEADER_KUBLAI_KHAN_MONGOLIA', 'LEADER', '', 'CULTURE',  4),
('LEADER_KUBLAI_KHAN_MONGOLIA', 'LEADER', '', 'RELIGION', 1),
('LEADER_KUBLAI_KHAN_MONGOLIA', 'LEADER', '', 'DIPLO',    4);

INSERT INTO Types (Type, Kind) VALUES
('TRAIT_LEADER_KUBLAI_MONGOLIA', 'KIND_TRAIT');

INSERT INTO Traits (TraitType, InternalOnly) VALUES
('TRAIT_LEADER_KUBLAI_MONGOLIA', 0);

INSERT INTO LeaderTraits (LeaderType, TraitType) VALUES
('LEADER_KUBLAI_KHAN_MONGOLIA', 'TRAIT_LEADER_KUBLAI_MONGOLIA');

INSERT INTO AiListTypes (ListType) VALUES
('KublaiMongoliaTechs'), 
('KublaiMongoliaPseudoYields'),
('KublaiMongoliaUnitBuilds');

INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('KublaiMongoliaTechs',        'TRAIT_LEADER_KUBLAI_MONGOLIA', 'Technologies'),
('KublaiMongoliaPseudoYields', 'TRAIT_LEADER_KUBLAI_MONGOLIA', 'PseudoYields'),
('KublaiMongoliaUnitBuilds',   'TRAIT_LEADER_KUBLAI_MONGOLIA', 'DiplomaticActions');

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('KublaiMongoliaTechs', 'TECH_STIRRUPS', 1, 0),
('KublaiMongoliaTechs', 'TECH_HORSEBACK_RIDING', 1, 0),
('KublaiMongoliaPseudoYields', 'PSEUDOYIELD_STANDING_ARMY_NUMBER', 1, 20),
('KublaiMongoliaPseudoYields', 'PSEUDOYIELD_STANDING_ARMY_VALUE', 1, 20),
('KublaiMongoliaPseudoYields', 'PSEUDOYIELD_UNIT_COMBAT', 1, 20),
('KublaiMongoliaUnitBuilds', 'PROMOTION_CLASS_RANGED', 1, 20);



-- LEADER_LADY_TRIEU / VIETNAM
-- TRAIT_LEADER_TRIEU

INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES
('LEADER_LADY_TRIEU', 'LEADER', '', 'CONQUEST', 1),
('LEADER_LADY_TRIEU', 'LEADER', '', 'SCIENCE',  5),
('LEADER_LADY_TRIEU', 'LEADER', '', 'CULTURE',  5),
('LEADER_LADY_TRIEU', 'LEADER', '', 'RELIGION', 1),
('LEADER_LADY_TRIEU', 'LEADER', '', 'DIPLO',    5);

INSERT INTO AiListTypes (ListType) VALUES
('LadyTrieuWonders'),
('LadyTrieuTechs'), 
('LadyTrieuCivics'),
('LadyTrieuDistricts'),
('LadyTrieuPseudoYields'),
('LadyTrieuUnitBuilds'),
('LadyTrieuDiplomacy');

INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('LadyTrieuWonders',      'TRAIT_LEADER_TRIEU', 'Buildings'),
('LadyTrieuTechs',        'TRAIT_LEADER_TRIEU', 'Technologies'),
('LadyTrieuCivics',       'TRAIT_LEADER_TRIEU', 'Civics'),
('LadyTrieuDistricts',    'TRAIT_LEADER_TRIEU', 'Districts'),
('LadyTrieuPseudoYields', 'TRAIT_LEADER_TRIEU', 'PseudoYields'),
('LadyTrieuUnitBuilds',   'TRAIT_LEADER_TRIEU', 'UnitPromotionClasses'),
('LadyTrieuDiplomacy',    'TRAIT_LEADER_TRIEU', 'DiplomaticActions');

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('LadyTrieuWonders', 'BUILDING_CHICHEN_ITZA', 1, 0), -- we are in the rainforest
('LadyTrieuTechs', 'TECH_BRONZE_WORKING', 1, 0), -- thahn
('LadyTrieuCivics', 'CIVIC_DEFENSIVE_TACTICS', 1, 0), -- turtling
('LadyTrieuDistricts', 'DISTRICT_THANH', 1, 0), -- it doesn't provide GPP so not sure how to make sure she will build it
('LadyTrieuPseudoYields', 'PSEUDOYIELD_ENVIRONMENT', 1, 25), -- preservce features!
('LadyTrieuPseudoYields', 'PSEUDOYIELD_DISTRICT', 1, 15),
('LadyTrieuUnitBuilds', 'PROMOTION_CLASS_RANGED', 1, 10),
('LadyTrieuDiplomacy', 'DIPLOACTION_ALLIANCE', 1, 0),
('LadyTrieuDiplomacy', 'DIPLOACTION_DECLARE_FRIENDSHIP',  1, 0);



/* NOTES FOR MONGOLIA AND CHINA
===============================================

MONGOLIA                                     CHINA
TRAIT_CIVILIZATION_MONGOLIAN_ORTOO          TRAIT_CIVILIZATION_DYNASTIC_CYCLE
OrtooResolutions                            ---
TRAIT_CIVILIZATION_BUILDING_ORDU            TRAIT_CIVILIZATION_IMPROVEMENT_GREAT_WALL
MongoliaDisfavorBarracks                    GreatWallResolutions

TRAIT_CIVILIZATION_UNIT_MONGOLIAN_KESHIG    TRAIT_CIVILIZATION_UNIT_CHINESE_CROUCHING_TIGER
---                                         ---

                          
KUBLAI KHAN    =>  CHINA + MONGOLIA
TRAIT_LEADER_KUBLAI                  
KublaiKhanPseudoYieldPreferences
KublaiKhanYieldPreferences
                        
                        
GENGIS                                      QIN
TRAIT_LEADER_GENGHIS_KHAN_ABILITY           FIRST_EMPEROR_TRAIT
GenghisKhanCavalryLoverList                  
CavalryLoverCitySettlement     
GenghisCivics                               QinCivics
GenghisTechs                                QinTechs
GenghisWonders                              QinWonders
GenghisPseudoYields                         QinPseudoYields

TRAIT_LEADER_LOW_RELIGIOUS_PREFERENCE         TRAIT_LEADER_LOW_RELIGIOUS_PREFERENCE
LowReligiousPreferencePseudoYields
LowReligiousPreferenceYields

TRAIT_LEADER_AGGRESSIVE_MILITARY              TRAIT_LEADER_CULTURAL_MAJOR_CIV
AgressiveDiplomacy                            FavorCulturalVictory (removed)
AggressivePseudoYields

=============================================
*/