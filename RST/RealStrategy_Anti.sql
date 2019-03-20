-- ===========================================================================
-- Real Strategy - File with anti-strategies i.e. strategies activated when a specific victory type is disabled
-- Author: Infixo
-- 2019-03-20: Created
-- ===========================================================================

-- ===========================================================================
-- ANTI-STRATEGIES
-- ===========================================================================

INSERT INTO Types (Type, Kind) VALUES
('RST_STRATEGY_ANTI_MILITARY',  'KIND_VICTORY_STRATEGY'),
('RST_STRATEGY_ANTI_SCIENCE',   'KIND_VICTORY_STRATEGY'),
('RST_STRATEGY_ANTI_CULTURAL',  'KIND_VICTORY_STRATEGY'),
('RST_STRATEGY_ANTI_RELIGIOUS', 'KIND_VICTORY_STRATEGY');

INSERT INTO Strategies (StrategyType, VictoryType, NumConditionsNeeded) VALUES
('RST_STRATEGY_ANTI_MILITARY',  NULL, 1),
('RST_STRATEGY_ANTI_SCIENCE',   NULL, 1),
('RST_STRATEGY_ANTI_CULTURAL',  NULL, 1),
('RST_STRATEGY_ANTI_RELIGIOUS', NULL, 1);

INSERT INTO StrategyConditions (StrategyType, ConditionFunction, StringValue) VALUES
('RST_STRATEGY_ANTI_MILITARY',  'Call Lua Function', 'ActiveStrategyAntiConquest'),
('RST_STRATEGY_ANTI_SCIENCE',   'Call Lua Function', 'ActiveStrategyAntiScience'),
('RST_STRATEGY_ANTI_CULTURAL',  'Call Lua Function', 'ActiveStrategyAntiCulture'),
('RST_STRATEGY_ANTI_RELIGIOUS', 'Call Lua Function', 'ActiveStrategyAntiReligion');


------------------------------------------------------------------------------
-- RST_STRATEGY_ANTI_CULTURAL

INSERT INTO AiListTypes (ListType) VALUES
('AntiCultureYields'),
('AntiCulturePseudoYields'),
('AntiCultureWonders');
INSERT INTO AiLists (ListType, System) VALUES
('AntiCultureYields',       'Yields'),
('AntiCulturePseudoYields', 'PseudoYields'),
('AntiCultureWonders',      'Buildings');
INSERT INTO Strategy_Priorities (StrategyType, ListType) VALUES
('RST_STRATEGY_ANTI_CULTURAL', 'AntiCultureYields'),
('RST_STRATEGY_ANTI_CULTURAL', 'AntiCulturePseudoYields'),
('RST_STRATEGY_ANTI_CULTURAL', 'AntiCultureWonders');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('AntiCultureYields', 'YIELD_CULTURE', 1, -20),
('AntiCulturePseudoYields', 'PSEUDOYIELD_CIVIC', 1, -20),
('AntiCulturePseudoYields', 'PSEUDOYIELD_GPP_WRITER', 1, -20),
('AntiCulturePseudoYields', 'PSEUDOYIELD_GPP_ARTIST', 1, -20),
('AntiCulturePseudoYields', 'PSEUDOYIELD_GPP_MUSICIAN', 1, -20),
('AntiCulturePseudoYields', 'PSEUDOYIELD_TOURISM', 1, -50),
('AntiCulturePseudoYields', 'PSEUDOYIELD_WONDER', 1, -20),
('AntiCulturePseudoYields', 'PSEUDOYIELD_UNIT_ARCHAEOLOGIST', 1, -50),
-- disfavored wonders
('AntiCultureWonders', 'BUILDING_BOLSHOI_THEATRE',    0, 0),
('AntiCultureWonders', 'BUILDING_BROADWAY',           0, 0),
('AntiCultureWonders', 'BUILDING_CRISTO_REDENTOR',    0, 0),
('AntiCultureWonders', 'BUILDING_HERMITAGE',          0, 0),
('AntiCultureWonders', 'BUILDING_SYDNEY_OPERA_HOUSE', 0, 0);

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value)
SELECT 'AntiCulturePseudoYields', PseudoYieldType, 1, -25
FROM PseudoYields
WHERE PseudoYieldType LIKE 'PSEUDOYIELD_GREATWORK_%';


------------------------------------------------------------------------------
-- RST_STRATEGY_ANTI_SCIENCE

INSERT INTO AiListTypes (ListType) VALUES
('AntiScienceYields'),
('AntiSciencePseudoYields'),
('AntiScienceDistricts'),
('AntiScienceProjects'),
('AntiScienceWonders');
INSERT INTO AiLists (ListType, System) VALUES
('AntiScienceYields',       'Yields'),
('AntiSciencePseudoYields', 'PseudoYields'),
('AntiScienceDistricts',    'Districts'),
('AntiScienceProjects',     'Projects'),
('AntiScienceWonders',      'Buildings');
INSERT INTO Strategy_Priorities (StrategyType, ListType) VALUES
('RST_STRATEGY_ANTI_SCIENCE', 'AntiScienceYields'),
('RST_STRATEGY_ANTI_SCIENCE', 'AntiSciencePseudoYields'),
('RST_STRATEGY_ANTI_SCIENCE', 'AntiScienceDistricts'),
('RST_STRATEGY_ANTI_SCIENCE', 'AntiScienceProjects'),
('RST_STRATEGY_ANTI_SCIENCE', 'AntiScienceWonders');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('AntiScienceYields', 'YIELD_SCIENCE', 1, -20),
('AntiSciencePseudoYields', 'PSEUDOYIELD_TECHNOLOGY', 1, -20),
('AntiSciencePseudoYields', 'PSEUDOYIELD_SPACE_RACE', 1, -100),
('AntiSciencePseudoYields', 'PSEUDOYIELD_GPP_SCIENTIST', 1, -20),
('AntiSciencePseudoYields', 'PSEUDOYIELD_GPP_ENGINEER', 1, -10),
('AntiScienceDistricts', 'DISTRICT_SPACEPORT', 0, 0),
-- projects, disfavored all except Satellite (knowing the map is good) PROJECT_LAUNCH_EARTH_SATELLITE
('AntiScienceProjects', 'PROJECT_LAUNCH_MOON_LANDING',     0, 0), -- well, I actually don't know if "disfavor" works here
('AntiScienceProjects', 'PROJECT_LAUNCH_MARS_REACTOR',     0, 0),
('AntiScienceProjects', 'PROJECT_LAUNCH_MARS_HABITATION',  0, 0),
('AntiScienceProjects', 'PROJECT_LAUNCH_MARS_HYDROPONICS', 0, 0);


------------------------------------------------------------------------------
-- RST_STRATEGY_ANTI_RELIGIOUS

INSERT INTO AiListTypes (ListType) VALUES
('AntiReligiousYields'),
('AntiReligiousPseudoYields'),
('AntiReligiousWonders'),
('AntiReligiousUnits');
INSERT INTO AiLists (ListType, System) VALUES
('AntiReligiousYields',       'Yields'),
('AntiReligiousPseudoYields', 'PseudoYields'),
('AntiReligiousWonders',      'Buildings'),
('AntiReligiousUnits',        'Units');
INSERT INTO Strategy_Priorities (StrategyType, ListType) VALUES
('RST_STRATEGY_ANTI_RELIGIOUS', 'AntiReligiousYields'),
('RST_STRATEGY_ANTI_RELIGIOUS', 'AntiReligiousPseudoYields'),
('RST_STRATEGY_ANTI_RELIGIOUS', 'AntiReligiousWonders'),
('RST_STRATEGY_ANTI_RELIGIOUS', 'AntiReligiousUnits');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('AntiReligiousYields', 'YIELD_FAITH', 1, -20),
('AntiReligiousPseudoYields', 'PSEUDOYIELD_GPP_PROPHET', 1, -50), -- not to "0", religion may help a bit in other areas
--('AntiReligiousPseudoYields', 'PSEUDOYIELD_UNIT_RELIGIOUS', 1, -25), -- there are still naturalists and rock bands :(
('AntiReligiousWonders', 'BUILDING_STONEHENGE',       0, 0),
('AntiReligiousWonders', 'BUILDING_HAGIA_SOPHIA',     0, 0),
('AntiReligiousWonders', 'BUILDING_MAHABODHI_TEMPLE', 0, 0),
('AntiReligiousUnits', 'UNIT_MISSIONARY', 1, -25),
('AntiReligiousUnits', 'UNIT_APOSTLE',    1, -25),
('AntiReligiousUnits', 'UNIT_INQUISITOR', 1, -25);


------------------------------------------------------------------------------
-- RST_STRATEGY_ANTI_MILITARY
-- Nuclear weapons will be limited slightly as they can be used to hinder other victories

INSERT INTO AiListTypes (ListType) VALUES
('AntiMilitaryOperations'),
('AntiMilitaryYields'),
('AntiMilitaryPseudoYields'),
('AntiMilitaryWonders');
INSERT INTO AiLists (ListType, System) VALUES
('AntiMilitaryOperations',   'AiOperationTypes'),
('AntiMilitaryYields',       'Yields'),
('AntiMilitaryPseudoYields', 'PseudoYields'),
('AntiMilitaryWonders',      'Buildings');
INSERT INTO Strategy_Priorities (StrategyType, ListType) VALUES
('RST_STRATEGY_ANTI_MILITARY', 'AntiMilitaryOperations'),
('RST_STRATEGY_ANTI_MILITARY', 'AntiMilitaryYields'),
('RST_STRATEGY_ANTI_MILITARY', 'AntiMilitaryPseudoYields'),
('RST_STRATEGY_ANTI_MILITARY', 'AntiMilitaryWonders');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('AntiMilitaryOperations', 'CITY_ASSAULT', 1, -1), -- limit num of military ops
('AntiMilitaryYields', 'YIELD_SCIENCE', 1, -10),
('AntiMilitaryYields', 'YIELD_PRODUCTION', 1, -10),
('AntiMilitaryPseudoYields', 'PSEUDOYIELD_TECHNOLOGY', 1, -10),
('AntiMilitaryPseudoYields', 'PSEUDOYIELD_DIPLOMATIC_BONUS', 1, 15),
('AntiMilitaryPseudoYields', 'PSEUDOYIELD_UNIT_COMBAT', 1, -20),
('AntiMilitaryPseudoYields', 'PSEUDOYIELD_UNIT_NAVAL_COMBAT', 1, -10),
('AntiMilitaryPseudoYields', 'PSEUDOYIELD_UNIT_AIR_COMBAT', 1, -20),
('AntiMilitaryPseudoYields', 'PSEUDOYIELD_STANDING_ARMY_NUMBER', 1, -15),
('AntiMilitaryPseudoYields', 'PSEUDOYIELD_STANDING_ARMY_VALUE', 1, -25),
('AntiMilitaryPseudoYields', 'PSEUDOYIELD_CITY_ORIGINAL_CAPITAL', 1, -200),
('AntiMilitaryPseudoYields', 'PSEUDOYIELD_CITY_DEFENSES', 1, 10),
('AntiMilitaryPseudoYields', 'PSEUDOYIELD_CITY_DEFENDING_UNITS', 1, 10),
('AntiMilitaryPseudoYields', 'PSEUDOYIELD_GPP_ADMIRAL', 1, -20),
('AntiMilitaryPseudoYields', 'PSEUDOYIELD_GPP_GENERAL', 1, -20),
('AntiMilitaryWonders', 'BUILDING_TERRACOTTA_ARMY', 0, 0);
