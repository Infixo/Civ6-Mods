-- ===========================================================================
-- Real Strategy - Main file with Strategies and Leaders
-- Author: Infixo
-- 2018-12-14: Created
-- ===========================================================================

/* Faith & Religion conundrum
Problem here is that PSEUDOYIELD_DISTRICT is quite high and when a Civ goes to TECH_ASTROLOGY then it builds a Holy Site.
Items in play:				can't	can		has
YIELD_FAITH					-4		+32		+38
PSEUDOYIELD_GPP_PROPHET		0		+50		+50
BUILDING_STONEHENGE			0

Available conditions: Founded Religion, Cannot Found Religion, Religion Destroyed
Used ONLY in definition of VICTORY_STRATEGY_RELIGIOUS_VICTORY

START: everyone except Kongo can found - but should they? I need some "more/less faith early" param - OR this should be set on an individual level
IF a Civ has a Religion - it should behave a bit different, but it does NOT mean that it will go for a Religious Victory
IF a Civ doesn't have a Religion - it still CAN use faith, but priority should be less

The Game defines LowReligiousPreference as a set of Lists - maybe add, similar to Flavors - Medium, High
						faith	prophet		stonehenge
- VeryLow 1..2 (17)		-25		-50			0
- Low 3..4 (6)			-10		-25			-
- Medium 5..6 (7)		+10		+25			1
- High 7..9 (6)			+25		+50			1

Plus strategies			faith	prophet		stonehenge
Founded Religion		+10		+10			0
Religion not possible	-15		-15			0
Religion possible		+20		+20			-
*/


-- ===========================================================================
-- Strategies
-- ===========================================================================

-- remove old conditions, leave only relevant
UPDATE Strategies SET NumConditionsNeeded = 1 WHERE StrategyType LIKE 'VICTORY_STRATEGY_%';
DELETE FROM StrategyConditions WHERE StrategyType LIKE 'VICTORY_STRATEGY_%' AND ConditionFunction NOT IN ('Is Not Major'); --, 'Cannot Found Religion', 'Religion Destroyed');

-- register new conditions
INSERT INTO StrategyConditions (StrategyType, ConditionFunction, StringValue, ThresholdValue) VALUES
('VICTORY_STRATEGY_MILITARY_VICTORY', 'Call Lua Function', 'ActiveStrategyConquest', 0),
('VICTORY_STRATEGY_SCIENCE_VICTORY',  'Call Lua Function', 'ActiveStrategyScience',  0),
('VICTORY_STRATEGY_CULTURAL_VICTORY', 'Call Lua Function', 'ActiveStrategyCulture',  0),
('VICTORY_STRATEGY_RELIGIOUS_VICTORY','Call Lua Function', 'ActiveStrategyReligion', 0);

-- remove Strategies AiLists - they mess up the conditions badly!
DELETE FROM AiFavoredItems WHERE ListType IN (SELECT ListType FROM AiLists WHERE System = 'Strategies');
DELETE FROM AiListTypes    WHERE ListType IN (SELECT ListType FROM AiLists WHERE System = 'Strategies');
DELETE FROM AiLists        WHERE System = 'Strategies';

/*
INSERT INTO Types (Type, Kind) VALUES
('RST_STRATEGY_CONQUEST', 'KIND_VICTORY_STRATEGY'),
('RST_STRATEGY_SCIENCE',  'KIND_VICTORY_STRATEGY'),
('RST_STRATEGY_CULTURE',  'KIND_VICTORY_STRATEGY'),
('RST_STRATEGY_RELIGION', 'KIND_VICTORY_STRATEGY');

INSERT INTO Strategies (StrategyType, VictoryType, NumConditionsNeeded) VALUES
('RST_STRATEGY_CONQUEST', 'VICTORY_CONQUEST',   1),
('RST_STRATEGY_SCIENCE',  'VICTORY_TECHNOLOGY', 1),
('RST_STRATEGY_CULTURE',  'VICTORY_CULTURE',    1),
('RST_STRATEGY_RELIGION', 'VICTORY_RELIGIOUS',  1);
 
-- forbid non-majors first - thery are called in the order as registered in DB, so this prevents from unnecessary calls on the 1st turn
INSERT INTO StrategyConditions (StrategyType, ConditionFunction, Disqualifier) VALUES
('RST_STRATEGY_CONQUEST', 'Is Not Major', 1),
('RST_STRATEGY_SCIENCE',  'Is Not Major', 1),
('RST_STRATEGY_CULTURE',  'Is Not Major', 1),
('RST_STRATEGY_RELIGION', 'Is Not Major', 1);

INSERT INTO StrategyConditions (StrategyType, ConditionFunction, StringValue, ThresholdValue) VALUES
('RST_STRATEGY_CONQUEST','Call Lua Function', 'ActiveStrategyConquest', 0),
('RST_STRATEGY_SCIENCE', 'Call Lua Function', 'ActiveStrategyScience',  0),
('RST_STRATEGY_CULTURE', 'Call Lua Function', 'ActiveStrategyCulture',  0),
('RST_STRATEGY_RELIGION','Call Lua Function', 'ActiveStrategyReligion', 0);
*/
/*
INSERT INTO Types (Type, Kind) VALUES
('STRATEGY_TEST_TURN_3', 'KIND_VICTORY_STRATEGY'),
('STRATEGY_TEST_TURN_5', 'KIND_VICTORY_STRATEGY'),
('STRATEGY_TEST_TURN_7', 'KIND_VICTORY_STRATEGY');

INSERT INTO Strategies (StrategyType, VictoryType, NumConditionsNeeded) VALUES
('STRATEGY_TEST_TURN_3', NULL, 1),
('STRATEGY_TEST_TURN_5', NULL, 1),
('STRATEGY_TEST_TURN_7', NULL, 1);

INSERT INTO StrategyConditions (StrategyType, ConditionFunction, StringValue, ThresholdValue) VALUES
('STRATEGY_TEST_TURN_3','Call Lua Function','CheckTurnNumber',3),
('STRATEGY_TEST_TURN_5','Call Lua Function','CheckTurnNumber',5),
('STRATEGY_TEST_TURN_7','Call Lua Function','CheckTurnNumber',7);
*/

-- ===========================================================================
-- AiLists & AiFavoredItems
-- Systems to use:
-- YES Buildings (Wonders)
-- YES Civics
-- YES PseudoYields
-- YES Technologies
-- YES Yields
-- (R&F Commemorations)
-- (R&F YieldSensitivities - isn't it redundant?)
-- System to use partially:
-- AiBuildSpecializations
-- ??? Alliances
-- ??? DiplomaticActions
-- ??? Districts
-- ??? Projects
-- ??? UnitPromotionClasses
-- ??? Units
-- Not needed?
-- AiOperationTypes
-- AiScoutUses
-- CityEvents
-- Homeland
-- PerWarOperationTypes
-- PlotEvaluations
-- SavingTypes
-- SettlementPreferences
-- NO! Strategies - don't use it, messes up conditions
-- Tactics
-- TechBoosts
-- TriggeredTrees
-- ===========================================================================


-- ===========================================================================
-- VICTORY_STRATEGY_CULTURAL_VICTORY
--CultureSensitivity
--CultureVictoryFavoredCommemorations
-- ===========================================================================

UPDATE AiFavoredItems SET Value = 40 WHERE ListType = 'CultureVictoryYields'       AND Item = 'YIELD_CULTURE'; -- def. 25

UPDATE AiFavoredItems SET Value = 15 WHERE ListType = 'CultureVictoryPseudoYields' AND Item LIKE 'PSEUDOYIELD_GREATWORK_%'; -- def. 10
UPDATE AiFavoredItems SET Value = 50 WHERE ListType = 'CultureVictoryPseudoYields' AND Item = 'PSEUDOYIELD_TOURISM'; -- def. 25

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('CultureVictoryPseudoYields', 'PSEUDOYIELD_CITY_BASE', 1, -100), -- base 350
('CultureVictoryPseudoYields', 'PSEUDOYIELD_CITY_DEFENSES', 1, 100), -- base 300
--('CultureVictoryPseudoYields', 'PSEUDOYIELD_CITY_DEFENDING_UNITS', 1, 20), -- base 80
('CultureVictoryPseudoYields', 'PSEUDOYIELD_DIPLOMATIC_BONUS', 1, 10), -- base 0.25
('CultureVictoryPseudoYields', 'PSEUDOYIELD_CIVIC', 1, 100), -- base 5
('CultureVictoryPseudoYields', 'PSEUDOYIELD_TECHNOLOGY', 1, -100), -- base 5
('CultureVictoryPseudoYields', 'PSEUDOYIELD_SPACE_RACE', 1, -10000), -- base 100, so it should be 100*100 by logic???
('CultureVictoryPseudoYields', 'PSEUDOYIELD_WONDER', 1, 50), -- base 0.8
('CultureVictoryPseudoYields', 'PSEUDOYIELD_UNIT_ARCHAEOLOGIST', 1, 200); -- base 4

INSERT INTO AiListTypes (ListType) VALUES
--('CultureVictoryDistricts'),
('CultureVictoryDiplomacy'),
('CultureVictoryTechs'),
('CultureVictoryCivics'),
('CultureVictoryWonders');
INSERT INTO AiLists (ListType, System) VALUES
--('CultureVictoryDistricts', 'Districts'),
('CultureVictoryDiplomacy', 'DiplomaticActions'),
('CultureVictoryTechs',     'Technologies'),
('CultureVictoryCivics',    'Civics'),
('CultureVictoryWonders',   'Buildings');
INSERT INTO Strategy_Priorities (StrategyType, ListType) VALUES
--('VICTORY_STRATEGY_CULTURAL_VICTORY', 'CultureVictoryDistricts'),
('VICTORY_STRATEGY_CULTURAL_VICTORY', 'CultureVictoryDiplomacy'),
('VICTORY_STRATEGY_CULTURAL_VICTORY', 'CultureVictoryTechs'),
('VICTORY_STRATEGY_CULTURAL_VICTORY', 'CultureVictoryCivics'),
('VICTORY_STRATEGY_CULTURAL_VICTORY', 'CultureVictoryWonders');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
--('CultureVictoryDistricts', 'DISTRICT_THEATER', 1, 0),
('CultureVictoryDiplomacy', 'DIPLOACTION_ALLIANCE_CULTURAL', 1, 0),
('CultureVictoryDiplomacy', 'DIPLOACTION_KEEP_PROMISE_DONT_DIG_ARTIFACTS', 0, 0), -- notice! it is FALSE!
('CultureVictoryDiplomacy', 'DIPLOACTION_OPEN_BORDERS', 1, 0),
('CultureVictoryTechs', 'TECH_PRINTING', 1, 0),
('CultureVictoryTechs', 'TECH_RADIO', 1, 0),
('CultureVictoryTechs', 'TECH_COMPUTERS', 1, 0),
('CultureVictoryCivics', 'CIVIC_DRAMA_POETRY', 1, 0),
('CultureVictoryCivics', 'CIVIC_HUMANISM', 1, 0),
('CultureVictoryCivics', 'CIVIC_OPERA_BALLET', 1, 0),
('CultureVictoryCivics', 'CIVIC_NATURAL_HISTORY', 1, 0),
('CultureVictoryCivics', 'CIVIC_MASS_MEDIA', 1, 0),
('CultureVictoryCivics', 'CIVIC_CULTURAL_HERITAGE', 1, 0),
('CultureVictoryCivics', 'CIVIC_SOCIAL_MEDIA', 1, 0),
('CultureVictoryCivics', 'CIVIC_SUFFRAGE', 1, 0), -- Democracy, yes
('CultureVictoryCivics', 'CIVIC_TOTALITARIANISM', 0, 0), -- Fascism, no
('CultureVictoryCivics', 'CIVIC_CLASS_STRUGGLE', 0, 0), -- Communism, no
('CultureVictoryWonders', 'BUILDING_BOLSHOI_THEATRE', 1, 0),
('CultureVictoryWonders', 'BUILDING_BROADWAY', 1, 0),
('CultureVictoryWonders', 'BUILDING_CRISTO_REDENTOR', 1, 0),
('CultureVictoryWonders', 'BUILDING_HERMITAGE', 1, 0),
('CultureVictoryWonders', 'BUILDING_SYDNEY_OPERA_HOUSE', 1, 0);


-- ===========================================================================
-- VICTORY_STRATEGY_SCIENCE_VICTORY
--ScienceSensitivity
--ScienceVictoryFavoredCommemorations
--ScienceVictoryDistricts
--ScienceVictoryProjects
-- ===========================================================================

--UPDATE AiFavoredItems SET Value = 40 WHERE ListType = 'ScienceVictoryYields' AND Item = 'YIELD_SCIENCE'; -- def. 50

UPDATE AiFavoredItems SET Value =  40 WHERE ListType = 'ScienceVictoryPseudoYields' AND Item = 'PSEUDOYIELD_GPP_SCIENTIST'; -- base 1.0
UPDATE AiFavoredItems SET Value = 100 WHERE ListType = 'ScienceVictoryPseudoYields' AND Item = 'PSEUDOYIELD_TECHNOLOGY'; -- def 25

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('ScienceVictoryYields', 'YIELD_FAITH', 1, -15),
('ScienceVictoryPseudoYields', 'PSEUDOYIELD_CITY_BASE', 1, -50), -- base 350
('ScienceVictoryPseudoYields', 'PSEUDOYIELD_CITY_DEFENSES', 1, 50), -- base 300
--('ScienceVictoryPseudoYields', 'PSEUDOYIELD_CITY_DEFENDING_UNITS', 1, 20), -- base 100
('ScienceVictoryPseudoYields', 'PSEUDOYIELD_CIVIC', 1, -100), -- base 5
('ScienceVictoryPseudoYields', 'PSEUDOYIELD_GPP_ENGINEER', 1, 20), -- need for infra
('ScienceVictoryPseudoYields', 'PSEUDOYIELD_GPP_PROPHET', 1, -25), -- base 0.8
('ScienceVictoryPseudoYields', 'PSEUDOYIELD_TOURISM', 1, -10), -- base 1
('ScienceVictoryPseudoYields', 'PSEUDOYIELD_UNIT_ARCHAEOLOGIST', 1, -200), -- base 4
('ScienceVictoryTechs', 'TECH_WRITING', 1, 0),
('ScienceVictoryTechs', 'TECH_EDUCATION', 1, 0),
('ScienceVictoryTechs', 'TECH_CHEMISTRY', 1, 0);

INSERT INTO AiListTypes (ListType) VALUES
('ScienceVictoryDiplomacy'),
('ScienceVictoryCivics'),
('ScienceVictoryWonders');
INSERT INTO AiLists (ListType, System) VALUES
('ScienceVictoryDiplomacy', 'DiplomaticActions'),
('ScienceVictoryCivics',    'Civics'),
('ScienceVictoryWonders',   'Buildings');
INSERT INTO Strategy_Priorities (StrategyType, ListType) VALUES
('VICTORY_STRATEGY_SCIENCE_VICTORY', 'ScienceVictoryDiplomacy'),
('VICTORY_STRATEGY_SCIENCE_VICTORY', 'ScienceVictoryCivics'),
('VICTORY_STRATEGY_SCIENCE_VICTORY', 'ScienceVictoryWonders');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('ScienceVictoryDiplomacy', 'DIPLOACTION_ALLIANCE_RESEARCH', 1, 0),
('ScienceVictoryDiplomacy', 'DIPLOACTION_KEEP_PROMISE_DONT_DIG_ARTIFACTS', 1, 0),
('ScienceVictoryCivics', 'CIVIC_RECORDED_HISTORY', 1, 0),
('ScienceVictoryCivics', 'CIVIC_THE_ENLIGHTENMENT', 1, 0),
('ScienceVictoryCivics', 'CIVIC_SPACE_RACE', 1, 0),
('ScienceVictoryCivics', 'CIVIC_GLOBALIZATION', 1, 0),
('ScienceVictoryCivics', 'CIVIC_SUFFRAGE', 0, 0), -- Democracy, no
('ScienceVictoryCivics', 'CIVIC_TOTALITARIANISM', 0, 0), -- Fascism, no
('ScienceVictoryCivics', 'CIVIC_CLASS_STRUGGLE', 1, 0), -- Communism, yes
('ScienceVictoryWonders', 'BUILDING_AMUNDSEN_SCOTT_RESEARCH_STATION', 1, 0),
('ScienceVictoryWonders', 'BUILDING_GREAT_LIBRARY', 1, 0),
('ScienceVictoryWonders', 'BUILDING_OXFORD_UNIVERSITY', 1, 0),
('ScienceVictoryWonders', 'BUILDING_RUHR_VALLEY', 1, 0);


-- ===========================================================================
-- VICTORY_STRATEGY_RELIGIOUS_VICTORY
--ReligiousVictoryFavoredCommemorations
--ReligiousVictoryBehaviors
-- ===========================================================================

UPDATE AiFavoredItems SET Value = 50 WHERE ListType = 'ReligiousVictoryYields' AND Item = 'YIELD_FAITH'; -- def. 75

UPDATE AiFavoredItems SET Value = 50 WHERE ListType = 'ReligiousVictoryPseudoYields' AND Item = 'PSEUDOYIELD_GPP_PROPHET'; -- base 0.8

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('ReligiousVictoryDiplomacy',    'DIPLOACTION_ALLIANCE_RELIGIOUS', 1, 0),
('ReligiousVictoryPseudoYields', 'PSEUDOYIELD_SPACE_RACE', 1, -10000), -- base 100, so it should be 100*100 by logic???
('ReligiousVictoryPseudoYields', 'PSEUDOYIELD_TOURISM', 1, -10), -- base 1
('ReligiousVictoryPseudoYields', 'PSEUDOYIELD_UNIT_RELIGIOUS', 1, 25); -- base 0.8 -- this includes Guru and Naturalist!


INSERT INTO AiListTypes (ListType) VALUES
('ReligiousVictoryTechs'),
('ReligiousVictoryCivics'),
('ReligiousVictoryWonders'),
('ReligiousVictoryUnits');
INSERT INTO AiLists (ListType, System) VALUES
('ReligiousVictoryTechs',   'Technologies'),
('ReligiousVictoryCivics',  'Civics'),
('ReligiousVictoryWonders', 'Buildings'),
('ReligiousVictoryUnits',   'Units');
INSERT INTO Strategy_Priorities (StrategyType, ListType) VALUES
('VICTORY_STRATEGY_RELIGIOUS_VICTORY', 'ReligiousVictoryTechs'),
('VICTORY_STRATEGY_RELIGIOUS_VICTORY', 'ReligiousVictoryCivics'),
('VICTORY_STRATEGY_RELIGIOUS_VICTORY', 'ReligiousVictoryWonders'),
('VICTORY_STRATEGY_RELIGIOUS_VICTORY', 'ReligiousVictoryUnits');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('ReligiousVictoryTechs', 'TECH_ASTROLOGY', 1, 0),
('ReligiousVictoryTechs', 'TECH_NUCLEAR_FISSION', 1, 0),
('ReligiousVictoryTechs', 'TECH_NUCLEAR_FUSION', 1, 0),
('ReligiousVictoryCivics', 'CIVIC_MYSTICISM', 1, 0),
('ReligiousVictoryCivics', 'CIVIC_THEOLOGY', 1, 0),
('ReligiousVictoryCivics', 'CIVIC_REFORMED_CHURCH', 1, 0),
-- we should stay with Theocracy, but probably won't be possible?
('ReligiousVictoryCivics', 'CIVIC_SUFFRAGE', 0, 0), -- Democracy, no
('ReligiousVictoryCivics', 'CIVIC_TOTALITARIANISM', 0, 0), -- Fascism, no
('ReligiousVictoryCivics', 'CIVIC_CLASS_STRUGGLE', 0, 0), -- Communism, no
('ReligiousVictoryWonders', 'BUILDING_HAGIA_SOPHIA', 1, 0),
('ReligiousVictoryWonders', 'BUILDING_STONEHENGE', 1, 0),
('ReligiousVictoryWonders', 'BUILDING_MAHABODHI_TEMPLE', 1, 0),
('ReligiousVictoryUnits', 'UNIT_MISSIONARY', 1, 100),
('ReligiousVictoryUnits', 'UNIT_APOSTLE', 1, 100),
('ReligiousVictoryUnits', 'UNIT_INQUISITOR', 1, 50);


-- ===========================================================================
-- VICTORY_STRATEGY_MILITARY_VICTORY
--MilitaryVictoryFavoredCommemorations
--MilitaryVictoryOperations
-- ===========================================================================

--UPDATE AiFavoredItems SET Value = 50 WHERE ListType = 'MilitaryVictoryYields' AND Item = 'YIELD_FAITH'; -- def. 25

UPDATE AiFavoredItems SET Value =  40 WHERE ListType = 'MilitaryVictoryPseudoYields' AND Item = 'PSEUDOYIELD_NUCLEAR_WEAPON'; -- def. 25
UPDATE AiFavoredItems SET Value = 100 WHERE ListType = 'MilitaryVictoryPseudoYields' AND Item = 'PSEUDOYIELD_UNIT_AIR_COMBAT'; -- def. 25
UPDATE AiFavoredItems SET Value =  50 WHERE ListType = 'MilitaryVictoryPseudoYields' AND Item = 'PSEUDOYIELD_UNIT_COMBAT'; -- def. 25
UPDATE AiFavoredItems SET Value =  15 WHERE ListType = 'MilitaryVictoryPseudoYields' AND Item = 'PSEUDOYIELD_UNIT_NAVAL_COMBAT'; -- def. 25 -- leave it for Naval strategies
UPDATE AiFavoredItems SET Value = 150 WHERE ListType = 'MilitaryVictoryPseudoYields' AND Item = 'PSEUDOYIELD_CITY_ORIGINAL_CAPITAL'; -- def. 100
UPDATE AiFavoredItems SET Value = -50 WHERE ListType = 'MilitaryVictoryPseudoYields' AND Item = 'PSEUDOYIELD_CITY_DEFENSES'; -- def. -25
UPDATE AiFavoredItems SET Value = -25 WHERE ListType = 'MilitaryVictoryPseudoYields' AND Item = 'PSEUDOYIELD_DIPLOMATIC_BONUS'; -- def. -50

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('MilitaryVictoryYields', 'YIELD_SCIENCE', 1,  15),
('MilitaryVictoryYields', 'YIELD_FAITH',   1, -25),
('MilitaryVictoryPseudoYields', 'PSEUDOYIELD_CITY_BASE', 1, 150), -- base 350 - or maybe 15000????
('MilitaryVictoryPseudoYields', 'PSEUDOYIELD_CITY_DEFENDING_UNITS', 1, -20), -- base 80
('MilitaryVictoryPseudoYields', 'PSEUDOYIELD_CITY_POPULATION', 1, 25), -- base 25
('MilitaryVictoryPseudoYields', 'PSEUDOYIELD_SPACE_RACE', 1, -10000), -- base 100, so it should be 100*100 by logic???
('MilitaryVictoryPseudoYields', 'PSEUDOYIELD_CLEAR_BANDIT_CAMPS', 1, 25), -- base 1.5, agenda lover uses 5, but it means probably 0.05
('MilitaryVictoryPseudoYields', 'PSEUDOYIELD_GPP_SCIENTIST', 1, 10), -- base 0.7
('MilitaryVictoryPseudoYields', 'PSEUDOYIELD_GPP_PROPHET', 1, -25), -- base 0.8
('MilitaryVictoryPseudoYields', 'PSEUDOYIELD_GPP_ADMIRAL', 1, 15), -- base 0.5
('MilitaryVictoryPseudoYields', 'PSEUDOYIELD_GPP_GENERAL', 1, 25), -- base 0.6
('MilitaryVictoryPseudoYields', 'PSEUDOYIELD_TOURISM', 1, -50), -- base 1
('MilitaryVictoryPseudoYields', 'PSEUDOYIELD_TECHNOLOGY', 1, 50), -- base 5
('MilitaryVictoryPseudoYields', 'PSEUDOYIELD_STANDING_ARMY_NUMBER', 1, 15), -- def. 1
('MilitaryVictoryPseudoYields', 'PSEUDOYIELD_STANDING_ARMY_VALUE', 1, 25), -- def. 0.1
('MilitaryVictoryPseudoYields', 'PSEUDOYIELD_UNIT_ARCHAEOLOGIST', 1, -200), -- base 4
('MilitaryVictoryPseudoYields', 'PSEUDOYIELD_UNIT_EXPLORER', 1, 25); -- base 0.6


INSERT INTO AiListTypes (ListType) VALUES
('MilitaryVictoryDiplomacy'),
('MilitaryVictoryTechs'),
('MilitaryVictoryCivics'),
('MilitaryVictoryWonders'),
('MilitaryVictoryProjects'),
('MilitaryVictoryUnitBuilds');
INSERT INTO AiLists (ListType, System) VALUES
('MilitaryVictoryDiplomacy', 'DiplomaticActions'),
('MilitaryVictoryTechs',     'Technologies'),
('MilitaryVictoryCivics',    'Civics'),
('MilitaryVictoryWonders',   'Buildings'),
('MilitaryVictoryProjects',  'Projects'),
('MilitaryVictoryUnitBuilds','UnitPromotionClasses');
INSERT INTO Strategy_Priorities (StrategyType, ListType) VALUES
('VICTORY_STRATEGY_MILITARY_VICTORY', 'MilitaryVictoryDiplomacy'),
('VICTORY_STRATEGY_MILITARY_VICTORY', 'MilitaryVictoryTechs'),
('VICTORY_STRATEGY_MILITARY_VICTORY', 'MilitaryVictoryCivics'),
('VICTORY_STRATEGY_MILITARY_VICTORY', 'MilitaryVictoryWonders'),
('VICTORY_STRATEGY_MILITARY_VICTORY', 'MilitaryVictoryProjects'),
('VICTORY_STRATEGY_MILITARY_VICTORY', 'MilitaryVictoryUnitBuilds');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
--('MilitaryVictoryDiplomacy', 'DIPLOACTION_MAKE_PEACE', 0, 0), -- notice! it is FALSE
('MilitaryVictoryDiplomacy', 'DIPLOACTION_USE_NUCLEAR_WEAPON', 1, 0),
('MilitaryVictoryDiplomacy', 'DIPLOACTION_PROPOSE_PEACE_DEAL', 0, 0), -- notice! it is FALSE
--('MilitaryVictoryDiplomacy', 'DIPLOACTION_ALLIANCE_MILITARY', 1, 0),
('MilitaryVictoryDiplomacy', 'DIPLOACTION_DECLARE_SURPRISE_WAR', 1, 0),
('MilitaryVictoryDiplomacy', 'DIPLOACTION_DECLARE_FORMAL_WAR', 1, 0),
('MilitaryVictoryDiplomacy', 'DIPLOACTION_DECLARE_TERRITORIAL_WAR', 1, 0),
('MilitaryVictoryDiplomacy', 'DIPLOACTION_DECLARE_GOLDEN_AGE_WAR', 1, 0),
('MilitaryVictoryDiplomacy', 'DIPLOACTION_DECLARE_IDEOLOGICAL_WAR', 1, 0),
--('MilitaryVictoryDiplomacy', 'DIPLOACTION_DECLARE_RECONQUEST_WAR', 1, 0),
('MilitaryVictoryDiplomacy', 'DIPLOACTION_DECLARE_COLONIAL_WAR', 1, 0),
('MilitaryVictoryTechs', 'TECH_BRONZE_WORKING', 1, 0),
('MilitaryVictoryTechs', 'TECH_STIRRUPS', 1, 0),
('MilitaryVictoryTechs', 'TECH_MILITARY_ENGINEERING', 1, 0),
('MilitaryVictoryTechs', 'TECH_GUNPOWDER', 1, 0),
('MilitaryVictoryTechs', 'TECH_MILITARY_SCIENCE', 1, 0),
('MilitaryVictoryTechs', 'TECH_COMBUSTION', 1, 0),
('MilitaryVictoryTechs', 'TECH_NUCLEAR_FISSION', 1, 0),
('MilitaryVictoryTechs', 'TECH_NUCLEAR_FUSION', 1, 0),
('MilitaryVictoryCivics', 'CIVIC_MILITARY_TRADITION', 1, 0),
('MilitaryVictoryCivics', 'CIVIC_MILITARY_TRAINING', 1, 0),
('MilitaryVictoryCivics', 'CIVIC_MERCENARIES', 1, 0),
('MilitaryVictoryCivics', 'CIVIC_NATIONALISM', 1, 0),
('MilitaryVictoryCivics', 'CIVIC_MOBILIZATION', 1, 0),
('MilitaryVictoryCivics', 'CIVIC_RAPID_DEPLOYMENT', 1, 0),
('MilitaryVictoryCivics', 'CIVIC_SUFFRAGE', 0, 0), -- Democracy, no
('MilitaryVictoryCivics', 'CIVIC_TOTALITARIANISM', 1, 0), -- Fascism, yes
('MilitaryVictoryCivics', 'CIVIC_CLASS_STRUGGLE', 0, 0), -- Communism, no
('MilitaryVictoryWonders', 'BUILDING_TERRACOTTA_ARMY', 1, 0),
('MilitaryVictoryWonders', 'BUILDING_ALHAMBRA', 1, 0),
('MilitaryVictoryProjects', 'PROJECT_MANHATTAN_PROJECT', 1, 0),
('MilitaryVictoryProjects', 'PROJECT_OPERATION_IVY', 1, 0),
('MilitaryVictoryProjects', 'PROJECT_BUILD_NUCLEAR_DEVICE', 1, 0),
('MilitaryVictoryProjects', 'PROJECT_BUILD_THERMONUCLEAR_DEVICE', 1, 0),
('MilitaryVictoryUnitBuilds', 'PROMOTION_CLASS_SIEGE', 1, 25);


-- ===========================================================================
-- Time changes - they are CUMULATIVE
-- ===========================================================================

DELETE FROM AiFavoredItems WHERE ListType IN (
'ClassicalSensitivity',
'ClassicalPseudoYields',
'ClassicalYields',
'MedievalSensitivity',
'MedievalPseudoYields',
'MedievalYields',
'RenaissancePseudoYields',
'RenaissanceYields',
'IndustrialPseudoYields',
'IndustrialYields',
'ModernSensitivity',
'ModernYields');

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
-- CLASSICAL
('ClassicalSensitivity', 'YIELD_SCIENCE', 1, 10),
('ClassicalYields', 'YIELD_CULTURE',  1, 15),
('ClassicalYields', 'YIELD_FAITH', 1, 10),
('ClassicalYields', 'YIELD_FOOD',  1, 15),
('ClassicalYields', 'YIELD_GOLD',  1, 10),
('ClassicalPseudoYields', 'PSEUDOYIELD_GPP_MERCHANT', 1, 20),
('ClassicalPseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, -20), -- 2.8
-- MEDIEVAL
--('MedievalSensitivity',	'YIELD_CULTURE', 1, 10),
('MedievalYields', 'YIELD_CULTURE', 1, -10),
('MedievalYields', 'YIELD_FAITH', 1, 20),
('MedievalYields', 'YIELD_FOOD', 1, 25),
--('MedievalYields', 'YIELD_GOLD', 1, 10),
('MedievalYields', 'YIELD_PRODUCTION', 1, 15),
('MedievalYields', 'YIELD_SCIENCE', 1, -10),
('MedievalPseudoYields', 'PSEUDOYIELD_GPP_ENGINEER', 1, 10),
('MedievalPseudoYields', 'PSEUDOYIELD_GPP_MERCHANT', 1, 10),
('MedievalPseudoYields', 'PSEUDOYIELD_GPP_SCIENTIST', 1, -10),
('MedievalPseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, -20), -- 2.6
-- RENAISSANCE
--('RenaissanceYields', 'YIELD_FOOD', 1, 10),
('RenaissanceYields', 'YIELD_CULTURE', 1, 15),
--('RenaissanceYields', 'YIELD_GOLD', 1, 10),
('RenaissanceYields', 'YIELD_FAITH', 1, -25),
('RenaissanceYields', 'YIELD_SCIENCE', 1, 10),
('RenaissancePseudoYields', 'PSEUDOYIELD_GPP_ARTIST', 1, 10),
('RenaissancePseudoYields', 'PSEUDOYIELD_GPP_ENGINEER', 1, 10),
('RenaissancePseudoYields', 'PSEUDOYIELD_GPP_PROPHET', 1, -100),
('RenaissancePseudoYields', 'PSEUDOYIELD_GPP_SCIENTIST', 1, 20),
('RenaissancePseudoYields', 'PSEUDOYIELD_GPP_WRITER', 1, 10),
('RenaissancePseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, -20), -- 2.2
('RenaissancePseudoYields', 'PSEUDOYIELD_UNIT_SETTLER', 1, -20),
-- INDUSTRIAL
--('IndustrialYields', 'YIELD_FAITH',	1, -40),
--('IndustrialYields', 'YIELD_GOLD',	1, 10),
('IndustrialYields', 'YIELD_PRODUCTION',	1, 15),
('IndustrialPseudoYields', 'PSEUDOYIELD_GPP_ENGINEER', 1, 20),
('IndustrialPseudoYields', 'PSEUDOYIELD_GPP_SCIENTIST', 1, 10),
('IndustrialPseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, -20), -- 2.0
('IndustrialPseudoYields', 'PSEUDOYIELD_UNIT_NAVAL_COMBAT', 1, 15),
('IndustrialPseudoYields', 'PSEUDOYIELD_UNIT_AIR_COMBAT', 1, 15),
('IndustrialPseudoYields', 'PSEUDOYIELD_UNIT_SETTLER', 1, -20),
-- MODERN
('ModernSensitivity', 'YIELD_CULTURE', 1, 10),
('ModernSensitivity', 'YIELD_SCIENCE', 1, 10),
('ModernYields', 'YIELD_FOOD', 1, 10),
('ModernYields', 'YIELD_GOLD', 1, 15);


-- ===========================================================================
-- SUPPORTING STRATEGIES
-- ===========================================================================

INSERT INTO Types (Type, Kind) VALUES
('RST_STRATEGY_DEFENSE',  'KIND_VICTORY_STRATEGY'), -- Activates when we are at war and our military is lacking badly
('RST_STRATEGY_CATCHING', 'KIND_VICTORY_STRATEGY'), -- Activates when our military is lacking in comparison to other known civs
('RST_STRATEGY_ENOUGH',   'KIND_VICTORY_STRATEGY'), -- Activates when our military is rocking in comparison to other known civs (prevents from overinvestment into military)
('RST_STRATEGY_PEACE',    'KIND_VICTORY_STRATEGY'), -- Activates when at peace
('RST_STRATEGY_ATWAR',    'KIND_VICTORY_STRATEGY'); -- Activates when at war

INSERT INTO Strategies (StrategyType, VictoryType, NumConditionsNeeded) VALUES
('RST_STRATEGY_DEFENSE',  NULL, 1),
('RST_STRATEGY_CATCHING', NULL, 1),
('RST_STRATEGY_ENOUGH',   NULL, 1),
('RST_STRATEGY_PEACE',    NULL, 1),
('RST_STRATEGY_ATWAR',    NULL, 1);

-- not for minors
INSERT INTO StrategyConditions (StrategyType, ConditionFunction, Disqualifier) VALUES
--('RST_STRATEGY_DEFENSE',  'Is Not Major', 1), -- minors could use it too?
('RST_STRATEGY_CATCHING', 'Is Not Major', 1),
('RST_STRATEGY_ENOUGH',   'Is Not Major', 1);

INSERT INTO StrategyConditions (StrategyType, ConditionFunction, StringValue, ThresholdValue) VALUES
('RST_STRATEGY_DEFENSE',  'Call Lua Function', 'ActiveStrategyDefense',  50),
('RST_STRATEGY_CATCHING', 'Call Lua Function', 'ActiveStrategyCatching', 50),
('RST_STRATEGY_ENOUGH',   'Call Lua Function', 'ActiveStrategyEnough',  250),
('RST_STRATEGY_PEACE',    'Call Lua Function', 'ActiveStrategyPeace',     0),
('RST_STRATEGY_ATWAR',    'Call Lua Function', 'ActiveStrategyAtWar',     0);


INSERT INTO AiListTypes (ListType) VALUES
('RSTDefenseDiplomacy'),
('RSTDefenseTechs'),
('RSTDefenseCivics'),
('RSTDefenseProjects'),
('RSTDefensePseudoYields'),
--('RSTDefenseUnitBuilds'),
('RSTCatchingPseudoYields'),
('RSTEnoughPseudoYields'),
('RSTPeaceYields'),
('RSTPeacePseudoYields'),
('RSTAtWarYields'),
('RSTAtWarPseudoYields');
INSERT INTO AiLists (ListType, System) VALUES
('RSTDefenseDiplomacy',   'DiplomaticActions'),
('RSTDefenseTechs',       'Technologies'),
('RSTDefenseCivics',      'Civics'),
('RSTDefenseProjects',    'Projects'),
('RSTDefensePseudoYields','PseudoYields'),
--('RSTDefenseUnitBuilds',  'UnitPromotionClasses'),
('RSTCatchingPseudoYields','PseudoYields'),
('RSTEnoughPseudoYields', 'PseudoYields'),
('RSTPeaceYields',        'Yields'),
('RSTPeacePseudoYields',  'PseudoYields'),
('RSTAtWarYields',        'Yields'),
('RSTAtWarPseudoYields',  'PseudoYields');
INSERT INTO Strategy_Priorities (StrategyType, ListType) VALUES
('RST_STRATEGY_DEFENSE', 'RSTDefenseDiplomacy'),
('RST_STRATEGY_DEFENSE', 'RSTDefenseTechs'),
('RST_STRATEGY_DEFENSE', 'RSTDefenseCivics'),
('RST_STRATEGY_DEFENSE', 'RSTDefenseProjects'),
('RST_STRATEGY_DEFENSE', 'RSTDefensePseudoYields'),
--('RST_STRATEGY_DEFENSE', 'RSTDefenseUnitBuilds'),
('RST_STRATEGY_CATCHING', 'RSTCatchingPseudoYields'),
('RST_STRATEGY_ENOUGH', 'RSTEnoughPseudoYields'),
('RST_STRATEGY_PEACE', 'RSTPeaceYields'),
('RST_STRATEGY_PEACE', 'RSTPeacePseudoYields'),
('RST_STRATEGY_ATWAR', 'RSTAtWarYields'),
('RST_STRATEGY_ATWAR', 'RSTAtWarPseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
-- Defense
('RSTDefenseDiplomacy', 'DIPLOACTION_ALLIANCE', 1, 0),
('RSTDefenseDiplomacy', 'DIPLOACTION_ALLIANCE_MILITARY', 1, 0),
('RSTDefenseTechs', 'TECH_MASONRY', 1, 0),
('RSTDefenseTechs', 'TECH_CASTLES', 1, 0),
('RSTDefenseTechs', 'TECH_SIEGE_TACTICS', 1, 0),
('RSTDefenseCivics', 'CIVIC_DEFENSIVE_TACTICS', 1, 0),
('RSTDefenseCivics', 'CIVIC_NATIONALISM', 1, 0),
('RSTDefenseCivics', 'CIVIC_MOBILIZATION', 1, 0),
('RSTDefenseProjects', 'PROJECT_REPAIR_OUTER_DEFENSES', 1, 0),
('RSTDefensePseudoYields', 'PSEUDOYIELD_UNIT_COMBAT', 1, 50),
('RSTDefensePseudoYields', 'PSEUDOYIELD_UNIT_AIR_COMBAT', 1, 0), -- until AI lears how to attack, these are needed
('RSTDefensePseudoYields', 'PSEUDOYIELD_UNIT_NAVAL_COMBAT', 1, 15), -- chances are that land units are more needed
--('RSTDefensePseudoYields', 'PSEUDOYIELD_CITY_DEFENDING_UNITS', 1, 0),
--('RSTDefensePseudoYields', 'PSEUDOYIELD_CITY_DEFENSES', 1, 0),
('RSTDefensePseudoYields', 'PSEUDOYIELD_STANDING_ARMY_NUMBER', 1, 15),
('RSTDefensePseudoYields', 'PSEUDOYIELD_STANDING_ARMY_VALUE', 1, 25),
('RSTDefensePseudoYields', 'PSEUDOYIELD_WONDER', 1, -100), -- these cost too much
('RSTDefensePseudoYields', 'PSEUDOYIELD_UNIT_ARCHAEOLOGIST', 1, -200), -- these cost too much
('RSTDefensePseudoYields', 'PSEUDOYIELD_DISTRICT', 1, -250), -- no districts
('RSTDefensePseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, -200), -- no builders
('RSTDefensePseudoYields', 'PSEUDOYIELD_TOURISM', 1, -50), -- base 1
('RSTDefensePseudoYields', 'PSEUDOYIELD_UNIT_SETTLER', 1, 25), -- we might need him!
--('RSTDefenseUnitBuilds', 'PROMOTION_CLASS_AIR_FIGHTER', 1, 25),
--('RSTDefenseUnitBuilds', 'PROMOTION_CLASS_RANGED', 1, 25),
--('RSTDefenseUnitBuilds', 'PROMOTION_CLASS_MELEE', 1, 25),
--('RSTDefenseUnitBuilds', 'PROMOTION_CLASS_NAVAL_MELEE', 1, 25);
-- Catching Up
('RSTCatchingPseudoYields', 'PSEUDOYIELD_CITY_BASE', 1, -150), -- don't attack anybody
('RSTCatchingPseudoYields', 'PSEUDOYIELD_CITY_DEFENDING_UNITS', 1, 20), -- don't attack anybody
('RSTCatchingPseudoYields', 'PSEUDOYIELD_CITY_DEFENSES', 1, 50), -- don't attack anybody
('RSTCatchingPseudoYields', 'PSEUDOYIELD_CITY_ORIGINAL_CAPITAL', 1, -50), -- don't attack anybody
('RSTCatchingPseudoYields', 'PSEUDOYIELD_UNIT_COMBAT', 1, 25),
('RSTCatchingPseudoYields', 'PSEUDOYIELD_UNIT_AIR_COMBAT', 1, 25),
('RSTCatchingPseudoYields', 'PSEUDOYIELD_UNIT_NAVAL_COMBAT', 1, 25),
('RSTCatchingPseudoYields', 'PSEUDOYIELD_STANDING_ARMY_NUMBER', 1, 15),
('RSTCatchingPseudoYields', 'PSEUDOYIELD_STANDING_ARMY_VALUE', 1, 25),
('RSTCatchingPseudoYields', 'PSEUDOYIELD_WONDER', 1, -50), -- slow down
('RSTCatchingPseudoYields', 'PSEUDOYIELD_UNIT_ARCHAEOLOGIST', 1, -100), -- slow down other builds
('RSTCatchingPseudoYields', 'PSEUDOYIELD_DISTRICT', 1, -150), -- slow down
('RSTCatchingPseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, -100), -- slow down
('RSTCatchingPseudoYields', 'PSEUDOYIELD_TOURISM', 1, -10), -- base 1
-- Enough
('RSTEnoughPseudoYields', 'PSEUDOYIELD_CITY_BASE', 1, 150), -- be more bold
('RSTEnoughPseudoYields', 'PSEUDOYIELD_CITY_DEFENDING_UNITS', 1, -20), -- be more bold
('RSTEnoughPseudoYields', 'PSEUDOYIELD_CITY_DEFENSES', 1, -50), -- be more bold
('RSTEnoughPseudoYields', 'PSEUDOYIELD_CITY_ORIGINAL_CAPITAL', 1, 50), -- be more bold
('RSTEnoughPseudoYields', 'PSEUDOYIELD_UNIT_COMBAT', 1, -50), -- opposite of the RSTCatchingPseudoYields
('RSTEnoughPseudoYields', 'PSEUDOYIELD_UNIT_AIR_COMBAT', 1, -50),
('RSTEnoughPseudoYields', 'PSEUDOYIELD_UNIT_NAVAL_COMBAT', 1, -50),
('RSTEnoughPseudoYields', 'PSEUDOYIELD_STANDING_ARMY_NUMBER', 1, -15),
('RSTEnoughPseudoYields', 'PSEUDOYIELD_STANDING_ARMY_VALUE', 1, -25),
-- Peace
('RSTPeaceYields', 'YIELD_CULTURE',    1,   5),
('RSTPeaceYields', 'YIELD_FAITH',      1,   5),
('RSTPeaceYields', 'YIELD_FOOD',       1,  10),
('RSTPeaceYields', 'YIELD_GOLD',       1, -10),
('RSTPeaceYields', 'YIELD_PRODUCTION', 1,   0),
('RSTPeaceYields', 'YIELD_SCIENCE',    1,   5),
('RSTPeacePseudoYields', 'PSEUDOYIELD_DISTRICT', 1, 50), -- build infra
('RSTPeacePseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, 100), -- build infra
('RSTPeacePseudoYields', 'PSEUDOYIELD_STANDING_ARMY_NUMBER', 1, -5), -- shrink a bit
('RSTPeacePseudoYields', 'PSEUDOYIELD_STANDING_ARMY_VALUE', 1, -10), -- shrink a bit
('RSTPeacePseudoYields', 'PSEUDOYIELD_TOURISM', 1, 10), -- base 1
('RSTPeacePseudoYields', 'PSEUDOYIELD_UNIT_ARCHAEOLOGIST', 1, 50),
('RSTPeacePseudoYields', 'PSEUDOYIELD_UNIT_COMBAT', 1, -10),
('RSTPeacePseudoYields', 'PSEUDOYIELD_UNIT_NAVAL_COMBAT', 1, -5),
('RSTPeacePseudoYields', 'PSEUDOYIELD_UNIT_SETTLER', 1, 10),
('RSTPeacePseudoYields', 'PSEUDOYIELD_WONDER', 1, 20),
-- At War
('RSTAtWarYields', 'YIELD_CULTURE',    1, -10),
('RSTAtWarYields', 'YIELD_FAITH',      1, -10),
('RSTAtWarYields', 'YIELD_FOOD',       1, -10),
('RSTAtWarYields', 'YIELD_GOLD',       1,  10),
('RSTAtWarYields', 'YIELD_PRODUCTION', 1,  10),
('RSTAtWarYields', 'YIELD_SCIENCE',    1, -10),
('RSTAtWarPseudoYields', 'PSEUDOYIELD_DISTRICT', 1, -50), -- slow down infra
('RSTAtWarPseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, -50), -- slow down infra
('RSTAtWarPseudoYields', 'PSEUDOYIELD_STANDING_ARMY_NUMBER', 1, 5), -- expand
('RSTAtWarPseudoYields', 'PSEUDOYIELD_STANDING_ARMY_VALUE', 1, 10), -- expand
('RSTAtWarPseudoYields', 'PSEUDOYIELD_TOURISM', 1, -20), -- base 1
('RSTAtWarPseudoYields', 'PSEUDOYIELD_UNIT_ARCHAEOLOGIST', 1, -100),
('RSTAtWarPseudoYields', 'PSEUDOYIELD_UNIT_COMBAT', 1, 20),
('RSTAtWarPseudoYields', 'PSEUDOYIELD_UNIT_NAVAL_COMBAT', 1, 5),
('RSTAtWarPseudoYields', 'PSEUDOYIELD_WONDER', 1, -20);



-- ===========================================================================
-- CHANGES TO EXISTING STRATEGIES
-- ===========================================================================


-- STRATEGY_RAPID_EXPANSION
-- this is actually peace / small war strategy
-- important - it activates only when there is a settle spot

UPDATE AiFavoredItems SET Value = 8 WHERE ListType = 'ExpansionSettlementPreferences' AND Item = 'Foreign Continent'; -- def. 4
UPDATE AiFavoredItems SET Value = 5 WHERE ListType = 'ExpansionSettlementPreferences' AND Item = 'Nearest Friendly City'; -- def. 6

DELETE FROM AiFavoredItems WHERE ListType = 'ExpansionUnitPreferences'; -- remove old list that resulted in LESS combat units
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('ExpansionUnitPreferences', 'PSEUDOYIELD_UNIT_SETTLER', 1, 20);


-- STRATEGY_NAVAL

INSERT INTO AiListTypes (ListType) VALUES
('NavalPreferredCivics'),
('NavalPreferredWonders'),
('NavalPreferredUnitBuilds'); -- for future
INSERT INTO AiLists (ListType, System) VALUES
('NavalPreferredCivics',    'Civics'),
('NavalPreferredWonders',   'Buildings'),
('NavalPreferredUnitBuilds','UnitPromotionClasses'); -- for future
INSERT INTO Strategy_Priorities (StrategyType, ListType) VALUES
('STRATEGY_NAVAL', 'NavalPreferredCivics'),
('STRATEGY_NAVAL', 'NavalPreferredWonders'),
('STRATEGY_NAVAL', 'NavalPreferredUnitBuilds');

UPDATE AiFavoredItems SET Value = -25 WHERE ListType = 'NavalUnitPreferences' AND Item = 'PSEUDOYIELD_UNIT_COMBAT'; -- def. -90
UPDATE AiFavoredItems SET Value =  25 WHERE ListType = 'NavalUnitPreferences' AND Item = 'PSEUDOYIELD_UNIT_NAVAL_COMBAT'; -- def. 150

UPDATE AiFavoredItems SET Value =  5 WHERE ListType = 'NavalSettlementPreferences' AND Item = 'Coastal'; -- def. 10
UPDATE AiFavoredItems SET Value =  8 WHERE ListType = 'NavalSettlementPreferences' AND Item = 'Foreign Continent'; -- def. 4
UPDATE AiFavoredItems SET Value =  3 WHERE ListType = 'NavalSettlementPreferences' AND Item = 'Nearest Friendly City'; -- def. 4
UPDATE AiFavoredItems SET Value = -4 WHERE ListType = 'NavalSettlementPreferences' AND Item = 'Specific Resource' AND StringVal = 'RESOURCE_IRON'; -- def. -5	
UPDATE AiFavoredItems SET Value = -2 WHERE ListType = 'NavalSettlementPreferences' AND Item = 'Specific Resource' AND StringVal = 'RESOURCE_HORSES'; -- def. -3	

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('NavalPreferredTechs', 'TECH_SQUARE_RIGGING', 1, 0),
('NavalPreferredTechs', 'TECH_STEAM_POWER', 1, 0),
('NavalPreferredTechs', 'TECH_STEEL', 1, 0),
('NavalPreferredTechs', 'TECH_COMBINED_ARMS', 1, 0),
('NavalPreferredCivics', 'CIVIC_FOREIGN_TRADE', 1, 0),
('NavalPreferredCivics', 'CIVIC_NAVAL_TRADITION', 1, 0),
('NavalPreferredWonders', 'BUILDING_GREAT_LIGHTHOUSE', 1, 0),
('NavalPreferredWonders', 'BUILDING_HALICARNASSUS_MAUSOLEUM', 1, 0),
('NavalUnitPreferences', 'PSEUDOYIELD_GPP_ADMIRAL', 1, 15),
('NavalUnitPreferences', 'PSEUDOYIELD_GPP_GENERAL', 1, -10);
