-- ===========================================================================
-- Real Strategy - Main file with Strategies and Leaders
-- Author: Infixo
-- 2018-12-14: Created
-- ===========================================================================
-- TODO: generic change - make sure DiplomaticActions are connected to Agendas!
-- TODO: R&F usage - Commemorations, Gov Buildings!
-- TODO: some ideas are common - thnk about making TRAITS, like "more TRs", "more wonders", etc.
-- improvements are unique, so they SHOULD be built nonetheless - see Ziggurats!
-- TRAIT_RST_MORE_TRADE_ROUTES
-- TRAIT_RST_MORE_IMPROVEMENTS
-- TRAIT_RST_MORE_WONDERS
-- TRAIT_RST_MORE_DISTRICTS

/* Comments and observations based on AI+

Military
	DISTRICT_AERODROME
		PSEUDOYIELD_UNIT_COMBAT +200
		PSEUDOYIELD_UNIT_AIR_COMBAT 100
		PSEUDOYIELD_DIPLOMATIC_BONUS -5
		PSEUDOYIELD_GPP_MERCHANT +35
		PSEUDOYIELD_GPP_GENERAL +35
		PSEUDOYIELD_CITY_BASE +110
		PSEUDOYIELD_CITY_DEFENDING_UNITS -5
		PSEUDOYIELD_CITY_ORIGINAL_CAPITAL +50
	
Early Military
	Settle Iron, Horses +4
	UNIT_KNIGHT +1
	some techs are NOT favored (e.g. sea, pottery, writing, etc.)

Late Military
	Settle Niter +6, Oil +2, Uranium +1
	
Growth
	YIELD_FOOD +8
	PSEUDOYIELD_HAPPINESS +250
	PSEUDOYIELD_DISTRICT +40
	PSEUDOYIELD_IMPROVEMENT +200
	PSEUDOYIELD_UNIT_TRADE +200
	PSEUDOYIELD_ENVIRONMENT +100

Scientfic
	Yields: science +8, faith/culture -2, food +4
	DIPLOACTION_RESEARCH_AGREEMENT
	PSEUDOYIELD_GPP_SCIENTIST +100
	Settle near RESOURCE_ALUMINUM +2
	COMMEMORATION_SCIENTIFIC

Wonder civ
	PSEUDOYIELD_WONDER +250

Semi-cultural
	Culture +1.5, Tourism +30
	GPP writer, artist, musician +20
	
Industrial
	COMMEMORATION_INDUSTRIAL
	GPP Engineer +60, Production +10
	GPP Merchant, Admiral +50, Unit Trader +200
	
Economic
	Settle Coastal +3
	COMMEMORATION_ECONOMIC
	
Defensive Civ
	PROMOTION_CLASS_RANGED +1
	PROMOTION_CLASS_SIEGE -1
	TECH_ARCHERY
	TECH_MASONRY
	TECH_CASTLES
	TECH_SIEGE_TACTICS
	BUILD_CITY_DEFENSES +2
	PSEUDOYIELD_CITY_BASE -80 <!--Reduces desire to attack cities-->
	PSEUDOYIELD_UNIT_COMBAT +100 <!--Can't defend without some units-->


*/

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

UPDATE AiFavoredItems SET Value = 40 WHERE ListType = 'CultureVictoryYields'       AND Item = 'YIELD_CULTURE'; -- def. 25

UPDATE AiFavoredItems SET Value = 15 WHERE ListType = 'CultureVictoryPseudoYields' AND Item LIKE 'PSEUDOYIELD_GREATWORK_%'; -- def. 10
UPDATE AiFavoredItems SET Value = 50 WHERE ListType = 'CultureVictoryPseudoYields' AND Item = 'PSEUDOYIELD_TOURISM'; -- def. 25

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('CultureVictoryPseudoYields', 'PSEUDOYIELD_CITY_DEFENSES', 1, 100), -- base 300
('CultureVictoryPseudoYields', 'PSEUDOYIELD_CITY_DEFENDING_UNITS', 1, 30), -- base 100
('CultureVictoryPseudoYields', 'PSEUDOYIELD_CIVIC', 1, 100), -- base 3
('CultureVictoryPseudoYields', 'PSEUDOYIELD_SPACE_RACE', 1, -100), -- base 100, so it should be 100*100 by logic???
('CultureVictoryPseudoYields', 'PSEUDOYIELD_WONDER', 1, 50), -- base 1.2
('CultureVictoryPseudoYields', 'PSEUDOYIELD_UNIT_ARCHAEOLOGIST', 1, 150); -- base 3

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

--UPDATE AiFavoredItems SET Value = 40 WHERE ListType = 'ScienceVictoryYields' AND Item = 'YIELD_SCIENCE'; -- def. 50

UPDATE AiFavoredItems SET Value =  40 WHERE ListType = 'ScienceVictoryPseudoYields' AND Item = 'PSEUDOYIELD_GPP_SCIENTIST'; -- base 1.0
UPDATE AiFavoredItems SET Value = 100 WHERE ListType = 'ScienceVictoryPseudoYields' AND Item = 'PSEUDOYIELD_TECHNOLOGY'; -- def 25

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('ScienceVictoryYields', 'YIELD_FAITH', 1, -15),
('ScienceVictoryPseudoYields', 'PSEUDOYIELD_CITY_DEFENSES', 1, 50), -- base 300
('ScienceVictoryPseudoYields', 'PSEUDOYIELD_CITY_DEFENDING_UNITS', 1, 20), -- base 100
('ScienceVictoryPseudoYields', 'PSEUDOYIELD_GPP_PROPHET', 1, -15), -- base 0.8
('ScienceVictoryPseudoYields', 'PSEUDOYIELD_UNIT_ARCHAEOLOGIST', 1, -150), -- base 3
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
('ScienceVictoryWonders', 'BUILDING_AMUNDSEN_SCOTT_RESEARCH_STATION', 1, 0),
('ScienceVictoryWonders', 'BUILDING_GREAT_LIBRARY', 1, 0),
('ScienceVictoryWonders', 'BUILDING_OXFORD_UNIVERSITY', 1, 0),
('ScienceVictoryWonders', 'BUILDING_RUHR_VALLEY', 1, 0);


-- ===========================================================================
-- VICTORY_STRATEGY_RELIGIOUS_VICTORY
--ReligiousVictoryFavoredCommemorations
--ReligiousVictoryBehaviors

UPDATE AiFavoredItems SET Value = 50 WHERE ListType = 'ReligiousVictoryYields' AND Item = 'YIELD_FAITH'; -- def. 75

UPDATE AiFavoredItems SET Value = 50 WHERE ListType = 'ReligiousVictoryPseudoYields' AND Item = 'PSEUDOYIELD_GPP_PROPHET'; -- base 0.8

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('ReligiousVictoryDiplomacy',    'DIPLOACTION_ALLIANCE_RELIGIOUS', 1, 0),
('ReligiousVictoryPseudoYields', 'PSEUDOYIELD_SPACE_RACE', 1, -100); -- base 100, so it should be 100*100 by logic???
--('ReligiousVictoryPseudoYields', 'PSEUDOYIELD_UNIT_RELIGIOUS', 1, 50); -- base 0.8 -- this includes Guru and Naturalist!


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

--UPDATE AiFavoredItems SET Value = 50 WHERE ListType = 'MilitaryVictoryYields' AND Item = 'YIELD_FAITH'; -- def. 25

UPDATE AiFavoredItems SET Value =  40 WHERE ListType = 'MilitaryVictoryPseudoYields' AND Item = 'PSEUDOYIELD_NUCLEAR_WEAPON'; -- def. 25
UPDATE AiFavoredItems SET Value =  50 WHERE ListType = 'MilitaryVictoryPseudoYields' AND Item = 'PSEUDOYIELD_UNIT_AIR_COMBAT'; -- def. 25
UPDATE AiFavoredItems SET Value =  50 WHERE ListType = 'MilitaryVictoryPseudoYields' AND Item = 'PSEUDOYIELD_UNIT_COMBAT'; -- def. 25
UPDATE AiFavoredItems SET Value =  15 WHERE ListType = 'MilitaryVictoryPseudoYields' AND Item = 'PSEUDOYIELD_UNIT_NAVAL_COMBAT'; -- def. 25 -- leave it for Naval strategies
UPDATE AiFavoredItems SET Value = 150 WHERE ListType = 'MilitaryVictoryPseudoYields' AND Item = 'PSEUDOYIELD_CITY_ORIGINAL_CAPITAL'; -- def. 100
UPDATE AiFavoredItems SET Value = -50 WHERE ListType = 'MilitaryVictoryPseudoYields' AND Item = 'PSEUDOYIELD_CITY_DEFENSES'; -- def. -25

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('MilitaryVictoryYields', 'YIELD_SCIENCE', 1,  15),
('MilitaryVictoryYields', 'YIELD_FAITH',   1, -25),
('MilitaryVictoryPseudoYields', 'PSEUDOYIELD_CITY_BASE', 1, 250), -- base 350 - or maybe 15000????
--('MilitaryVictoryPseudoYields', 'PSEUDOYIELD_CITY_ORIGINAL_CAPITAL', 1, 150), -- base 100
--('MilitaryVictoryPseudoYields', 'PSEUDOYIELD_CITY_DEFENSES', 1, -50), -- base 200
('MilitaryVictoryPseudoYields', 'PSEUDOYIELD_CITY_DEFENDING_UNITS', 1, -20), -- base 100
('MilitaryVictoryPseudoYields', 'PSEUDOYIELD_SPACE_RACE', 1, -100), -- base 100, so it should be 100*100 by logic???
('MilitaryVictoryPseudoYields', 'PSEUDOYIELD_CLEAR_BANDIT_CAMPS', 1, 15), -- base 1.0, agenda lover uses 5, but it means probably 0.05
('MilitaryVictoryPseudoYields', 'PSEUDOYIELD_GPP_SCIENTIST', 1, 15), -- base 1.0
('MilitaryVictoryPseudoYields', 'PSEUDOYIELD_GPP_PROPHET', 1, -25), -- base 0.8
('MilitaryVictoryPseudoYields', 'PSEUDOYIELD_GPP_ADMIRAL', 1, 25), -- base 0.8
('MilitaryVictoryPseudoYields', 'PSEUDOYIELD_GPP_GENERAL', 1, 50), -- base 0.8
('MilitaryVictoryPseudoYields', 'PSEUDOYIELD_TOURISM', 1, -50), -- base 1
('MilitaryVictoryPseudoYields', 'PSEUDOYIELD_TECHNOLOGY', 1, 50), -- base 3
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
--('MilitaryVictoryDiplomacy', 'DIPLOACTION_DECLARE_WAR_OF_RETRIBUTION', 1, 0),
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
('MilitaryVictoryCivics', 'CIVIC_TOTALITARIANISM', 1, 0),
('MilitaryVictoryCivics', 'CIVIC_RAPID_DEPLOYMENT', 1, 0),
('MilitaryVictoryWonders', 'BUILDING_TERRACOTTA_ARMY', 1, 0),
('MilitaryVictoryWonders', 'BUILDING_ALHAMBRA', 1, 0),
('MilitaryVictoryProjects', 'PROJECT_MANHATTAN_PROJECT', 1, 0),
('MilitaryVictoryProjects', 'PROJECT_OPERATION_IVY', 1, 0),
('MilitaryVictoryProjects', 'PROJECT_BUILD_NUCLEAR_DEVICE', 1, 0),
('MilitaryVictoryProjects', 'PROJECT_BUILD_THERMONUCLEAR_DEVICE', 1, 0),
('MilitaryVictoryUnitBuilds', 'PROMOTION_CLASS_SIEGE', 1, 25);


-- ===========================================================================
-- Changes to MINORS
-- ===========================================================================

-- extend possible war ops?
INSERT INTO AiFavoredItems (ListType, Item, Favored) VALUES
('Minor Civ Homeland', 'Attack Civilians', 1),
('Minor Civ Tactical', 'Attack Camps', 1), -- not sure about that?
('Minor Civ Tactical', 'Coastal Raid', 1),
('Minor Civ Tactical', 'Pillage District', 1),
('Minor Civ Tactical', 'Pillage Improvement', 1),
('Minor Civ Tactical', 'Plunder Trader', 1);

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('MinorCivUnitBuilds', 'PROMOTION_CLASS_ANTI_CAVALRY', 1, 20),
('MinorCivUnitBuilds', 'PROMOTION_CLASS_RANGED', 1, 15),
('MinorCivUnitBuilds', 'PROMOTION_CLASS_SIEGE', 1, -50),
('MinorCivUnitBuilds', 'PROMOTION_CLASS_SUPPORT', 1, -25),
('MinorCivPseudoYields', 'PSEUDOYIELD_CITY_DEFENSES', 1, 200),
('MinorCivPseudoYields', 'PSEUDOYIELD_CITY_DEFENDING_UNITS', 1, 50),
('MinorCivPseudoYields', 'PSEUDOYIELD_CLEAR_BANDIT_CAMPS', 1, 10);
/*
INSERT INTO AiListTypes (ListType) VALUES
('MinorCivOperations');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('MinorCivOperations', 'MINOR_CIV_DEFAULT_TRAIT', 'AiOperationTypes');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('MinorCivOperations', 'OP_DEFENSE', 1, 2);
*/

-- ===========================================================================
-- Changes to existing leaders and civs --> move to a separate file eventually
-- ===========================================================================

-- generic (all)
UPDATE AiFavoredItems SET Value = 2 WHERE ListType = 'BaseOperationsLimits' AND Item = 'OP_DEFENSE'; -- def. 1 ?number of simultaneus ops?


-- ALEXANDER / MACEDON
-- can't use DarwinistIgnoreWarmongerValue - others use it too

INSERT INTO AiListTypes (ListType) VALUES
('AlexanderPseudoYields'),
('AlexanderUnitBuilds');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('AlexanderPseudoYields', 'TRAIT_LEADER_TO_WORLDS_END', 'PseudoYields'),
('AlexanderUnitBuilds', 'TRAIT_LEADER_TO_WORLDS_END', 'UnitPromotionClasses');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('AlexanderPseudoYields', 'PSEUDOYIELD_CITY_BASE', 1, 150), -- because cities give boosts!
('AlexanderPseudoYields', 'PSEUDOYIELD_WONDER', 1, 25), -- because he has a ton of Wonders as favored and heals when captures one
('AlexanderPseudoYields', 'PSEUDOYIELD_UNIT_COMBAT', 1, 15), -- obvious
('AlexanderPseudoYields', 'PSEUDOYIELD_UNIT_EXPLORER', 1, 25), -- because he needs to know neighbors fast
('AlexanderPseudoYields', 'PSEUDOYIELD_GPP_GENERAL', 1, 15), -- obvious
('AlexanderUnitBuilds', 'PROMOTION_CLASS_SIEGE', 1, 15); -- for cities


-- AMANITORE / NUBIA
-- TRAIT_RST_MORE_DISTRICTS
-- TRAIT_RST_MORE_IMPROVEMENTS
-- she likes to build, improvements and districts

UPDATE AiFavoredItems SET Value = 25 WHERE ListType = 'AmanitoreUnitBuilds' AND Item = 'PROMOTION_CLASS_RANGED'; -- was 1

INSERT INTO AiListTypes (ListType) VALUES
('AmanitorePseudoYields'),
('AmanitoreUnits');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('AmanitorePseudoYields', 'TRAIT_LEADER_KANDAKE_OF_MEROE', 'PseudoYields'),
('AmanitoreUnits', 'TRAIT_LEADER_KANDAKE_OF_MEROE', 'Units');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('AmanitorePseudoYields', 'PSEUDOYIELD_CITY_POPULATION', 1, 15), -- more districts
('AmanitorePseudoYields', 'PSEUDOYIELD_DISTRICT', 1, 50), -- more districts
('AmanitorePseudoYields', 'PSEUDOYIELD_HAPPINESS', 0, 20),
('AmanitorePseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, 100), -- more improvements
('AmanitoreUnits', 'UNIT_BUILDER', 1, 20); -- more improvements


-- BARBAROSSA / GERMANY
-- TRAIT_RST_MORE_DISTRICTS

-- remove 23 favored Civics, insane!
DELETE FROM AiFavoredItems WHERE ListType = 'BarbarossaCivics';

INSERT INTO AiListTypes (ListType) VALUES
('BarbarossaPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('BarbarossaPseudoYields', 'TRAIT_LEADER_HOLY_ROMAN_EMPEROR', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('BarbarossaTechs', 'TECH_INDUSTRIALIZATION', 1, 0),
('BarbarossaCivics', 'CIVIC_GAMES_RECREATION', 1, 0),
('BarbarossaCivics', 'CIVIC_GUILDS', 1, 0),
('BarbarossaCivics', 'CIVIC_EXPLORATION', 1, 0),
('BarbarossaCivics', 'CIVIC_URBANIZATION', 1, 0),
('BarbarossaPseudoYields', 'PSEUDOYIELD_DISTRICT', 1, 50), -- more districts
('BarbarossaPseudoYields', 'PSEUDOYIELD_GPP_MERCHANT', 1, 15), -- boost comm hubs
('BarbarossaPseudoYields', 'PSEUDOYIELD_GPP_ENGINEER', 1, 15); -- boost hansas


-- CATHERINE_DE_MEDICI / FRANCE
-- TRAIT_RST_MORE_IMPROVEMENTS
-- TRAIT_RST_MORE_WONDERS

INSERT INTO AiListTypes (ListType) VALUES
('CatherineYields'),
('CatherinePseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('CatherineYields', 'FLYING_SQUADRON_TRAIT', 'Yields'),
('CatherinePseudoYields', 'FLYING_SQUADRON_TRAIT', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('CatherineYields', 'YIELD_CULTURE', 1, 25),
('CatherineYields', 'YIELD_PRODUCTION', 1, 10),
('CatherineYields', 'YIELD_FAITH', 1, -15),
('CatherinePseudoYields', 'PSEUDOYIELD_GPP_PROPHET', 1, -25),
('CatherinePseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, 100),
('CatherinePseudoYields', 'PSEUDOYIELD_TOURISM', 1, 25),
('CatherinePseudoYields', 'PSEUDOYIELD_WONDER', 1, 25),
('CatherinePseudoYields', 'PSEUDOYIELD_CITY_DEFENDING_UNITS', 1, 20),
('CatherinePseudoYields', 'PSEUDOYIELD_UNIT_SPY', 1, 500); -- 5 or 500????

-- CHANDRAGUPTA & GANDHI / INDIA

-- INDIA: GandhiUnitBuilds => this should be India-trait, so IndiaUnitBuilds
UPDATE AiListTypes    SET ListType = 'IndiaUnitBuilds' WHERE ListType = 'GandhiUnitBuilds';
--UPDATE AiLists        SET ListType = 'IndiaUnitBuilds', LeaderType = 'TRAIT_CIVILIZATION_DHARMA' WHERE ListType = 'GandhiUnitBuilds';
UPDATE AiLists        SET LeaderType = 'TRAIT_CIVILIZATION_DHARMA' WHERE ListType = 'IndiaUnitBuilds';
--UPDATE AiFavoredItems SET ListType = 'IndiaUnitBuilds' WHERE ListType = 'GandhiUnitBuilds';
UPDATE AiFavoredItems SET Value = -100 WHERE ListType = 'IndiaUnitBuilds' AND Item = 'PROMOTION_CLASS_INQUISITOR'; -- was -1

-- INDIA: stepwell
INSERT INTO AiListTypes (ListType) VALUES
('IndiaTechs'),
('IndiaYields'),
('IndiaPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('IndiaTechs', 'TRAIT_CIVILIZATION_IMPROVEMENT_STEPWELL', 'Technologies'),
('IndiaYields', 'TRAIT_CIVILIZATION_IMPROVEMENT_STEPWELL', 'Yields'),
('IndiaPseudoYields', 'TRAIT_CIVILIZATION_IMPROVEMENT_STEPWELL', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('IndiaTechs', 'TECH_IRRIGATION', 1, 0),
('IndiaYields', 'YIELD_FOOD', 1, 10),
('IndiaYields', 'YIELD_FAITH', 1, 10),
('IndiaPseudoYields', 'PSEUDOYIELD_CITY_POPULATION', 1, 25), -- more people!
('IndiaPseudoYields', 'PSEUDOYIELD_GPP_PROPHET', 1, 15), -- holy sites
('IndiaPseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, 100); -- stepwells

-- CHANDRAGUPTA: does not like his neighbors :(
-- TODO: similar expansionist trait to Trajan, to forward settle a bit more maybe?
INSERT INTO AiListTypes (ListType) VALUES
('ChandraguptaPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('ChandraguptaPseudoYields', 'TRAIT_LEADER_ARTHASHASTRA', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('ChandraguptaPseudoYields', 'PSEUDOYIELD_CITY_BASE', 1, 150), -- conquer neighbors
('ChandraguptaPseudoYields', 'PSEUDOYIELD_UNIT_COMBAT', 1, 15), -- obvious
('ChandraguptaPseudoYields', 'PSEUDOYIELD_GPP_PROPHET', 1, -10),
('ChandraguptaPseudoYields', 'PSEUDOYIELD_UNIT_RELIGIOUS', 1, -15), -- to differ from Gandhi
('ChandraguptaPseudoYields', 'PSEUDOYIELD_DIPLOMATIC_BONUS', 1, -15); -- conquer neighbors

-- GANDHI: hates warmongers, faith
DELETE FROM AiFavoredItems WHERE ListType = 'GandhiWonders' AND Item = 'BUILDING_OXFORD_UNIVERSITY'; -- really????
DELETE FROM AiFavoredItems WHERE ListType = 'GandhiTechs'   AND Item = 'TECH_IRRIGATION'; -- this is India now

INSERT INTO AiListTypes (ListType) VALUES
('GandhiPseudoYields'),
('GandhiProjects');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('GandhiPseudoYields', 'TRAIT_LEADER_SATYAGRAHA', 'PseudoYields'),
('GandhiProjects', 'TRAIT_LEADER_SATYAGRAHA', 'Projects');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('PeacekeeperWarLimits', 'DIPLOACTION_OPEN_BORDERS', 1, 0), -- get more religions
('PeacekeeperWarLimits', 'DIPLOACTION_ALLIANCE', 1, 0), -- peace!
('PeacekeeperWarLimits', 'DIPLOACTION_DECLARE_FRIENDSHIP', 1, 0), -- peace!
('PeacekeeperWarLimits', 'DIPLOACTION_RENEW_ALLIANCE', 1, 0), -- peace!
('PeacekeeperWarLimits', 'DIPLOACTION_RESIDENT_EMBASSY', 1, 0), -- peace
('GandhiPseudoYields', 'PSEUDOYIELD_CITY_BASE', 1, -150), -- conquer neighbors
('GandhiPseudoYields', 'PSEUDOYIELD_HAPPINESS', 1, 20),
('GandhiPseudoYields', 'PSEUDOYIELD_GPP_PROPHET', 1, 10),
('GandhiPseudoYields', 'PSEUDOYIELD_UNIT_COMBAT', 1, -15), -- obvious
('GandhiPseudoYields', 'PSEUDOYIELD_UNIT_RELIGIOUS', 1, 15), -- to differ from CHANDRAGUPTA
('GandhiPseudoYields', 'PSEUDOYIELD_DIPLOMATIC_BONUS', 1, 15), -- peace!
-- nukes, because... Gandhi
('PeacekeeperWarLimits', 'DIPLOACTION_USE_NUCLEAR_WEAPON', 1, 0),
('GandhiPseudoYields', 'PSEUDOYIELD_NUCLEAR_WEAPON', 1, 20),
('GandhiProjects', 'PROJECT_MANHATTAN_PROJECT', 1, 0),
('GandhiProjects', 'PROJECT_OPERATION_IVY', 1, 0),
('GandhiProjects', 'PROJECT_BUILD_NUCLEAR_DEVICE', 1, 0),
('GandhiProjects', 'PROJECT_BUILD_THERMONUCLEAR_DEVICE', 1, 0);


-- CLEOPATRA / EGYPT
-- TRAIT_RST_MORE_IMPROVEMENTS
-- TRAIT_RST_MORE_WONDERS

INSERT INTO AiListTypes (ListType) VALUES
('CleopatraDiplomacy'),
('CleopatraYields'),
('CleopatraPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('CleopatraDiplomacy', 'TRAIT_LEADER_MEDITERRANEAN', 'DiplomaticActions'),
('CleopatraYields', 'TRAIT_LEADER_MEDITERRANEAN', 'Yields'),
('CleopatraPseudoYields', 'TRAIT_LEADER_MEDITERRANEAN', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('CleopatraDiplomacy', 'DIPLOACTION_ALLIANCE', 1, 0),
('CleopatraDiplomacy', 'DIPLOACTION_ALLIANCE_MILITARY', 1, 0),
('CleopatraDiplomacy', 'DIPLOACTION_RENEW_ALLIANCE', 1, 0),
('CleopatraYields', 'YIELD_GOLD', 1, 10),
('CleopatraYields', 'YIELD_PRODUCTION', 1, 10),
('CleopatraPseudoYields', 'PSEUDOYIELD_GPP_MERCHANT', 1, 20),
('CleopatraPseudoYields', 'PSEUDOYIELD_GPP_ADMIRAL', 1, 20),
('CleopatraPseudoYields', 'PSEUDOYIELD_GPP_PROPHET', 1, 10),
('CleopatraPseudoYields', 'PSEUDOYIELD_UNIT_TRADE', 1, 500),
('CleopatraPseudoYields', 'PSEUDOYIELD_WONDER', 1, 25),
('CleopatraPseudoYields', 'PSEUDOYIELD_TOURISM', 1, 10),
('CleopatraPseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, 100),
('CleopatraPseudoYields', 'PSEUDOYIELD_DISTRICT', 1, 50);


-- CYRUS / PERSIA
-- TRAIT_RST_MORE_TRADE_ROUTES

INSERT INTO AiListTypes (ListType) VALUES
('CyrusYields'),
('CyrusPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('CyrusYields', 'TRAIT_LEADER_FALL_BABYLON', 'Yields'),
('CyrusPseudoYields', 'TRAIT_LEADER_FALL_BABYLON', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('CyrusYields', 'YIELD_CULTURE', 1, 15),
('CyrusYields', 'YIELD_GOLD', 1, 10),
('CyrusPseudoYields', 'PSEUDOYIELD_DISTRICT', 1, 50),
('CyrusPseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, 100),
('CyrusPseudoYields', 'PSEUDOYIELD_TOURISM', 1, 15),
('CyrusPseudoYields', 'PSEUDOYIELD_UNIT_COMBAT', 1, 10),
('CyrusPseudoYields', 'PSEUDOYIELD_UNIT_TRADE', 1, 500);


-- GENGHIS_KHAN / MONGOLIA
-- Genghis seems OK!
-- TRAIT_RST_PREFER_TRADE_ROUTES


-- GILGAMESH / SUMERIA
-- TRAIT_RST_MORE_IMPROVEMENTS
-- Ziggurat has no tech req... so broken! - it is the ONLY unique improvement like this

INSERT INTO AiListTypes (ListType) VALUES
('GilgameshTechs'),
('GilgameshCivics'),
--('GilgameshWonders'),
('GilgameshPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('GilgameshTechs', 'TRAIT_LEADER_ADVENTURES_ENKIDU', 'Technologies'),
('GilgameshCivics', 'TRAIT_LEADER_ADVENTURES_ENKIDU', 'Civics'),
--('GilgameshWonders', 'TRAIT_LEADER_ADVENTURES_ENKIDU', 'Buildings'),
('GilgameshPseudoYields', 'TRAIT_LEADER_ADVENTURES_ENKIDU', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('GilgameshDiplomacy', 'DIPLOACTION_ALLIANCE' , 1, 0),
('GilgameshDiplomacy', 'DIPLOACTION_JOINT_WAR' , 1, 0),
('GilgameshDiplomacy', 'DIPLOACTION_RENEW_ALLIANCE' , 1, 0),
('GilgameshDiplomacy', 'DIPLOACTION_DECLARE_WAR_MINOR_CIV' , 0, 0), -- friend of CS
('GilgameshTechs', 'TECH_STIRRUPS' , 1, 0),
('GilgameshTechs', 'TECH_WRITING' , 1, 0),
('GilgameshTechs', 'TECH_EDUCATION' , 1, 0),
('GilgameshCivics', 'CIVIC_FOREIGN_TRADE' , 1, 0), -- joint war
('GilgameshCivics', 'CIVIC_CIVIL_SERVICE' , 1, 0), -- alliance
('GilgameshPseudoYields', 'PSEUDOYIELD_CLEAR_BANDIT_CAMPS' , 1, 15), -- is it actually 0.25???
('GilgameshPseudoYields', 'PSEUDOYIELD_INFLUENCE' , 1, 15); -- friend of CS


-- GITARJA / INDONESIA
-- TRAIT_RST_MORE_NAVAL
-- TRAIT_RST_MORE_IMPROVEMENTS

INSERT INTO AiListTypes (ListType) VALUES
('GitarjaSettlement'),
('GitarjaYields'),
('GitarjaPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('GitarjaSettlement', 'TRAIT_LEADER_EXALTED_GODDESS', 'PlotEvaluations'),
('GitarjaYields', 'TRAIT_LEADER_EXALTED_GODDESS', 'Yields'),
('GitarjaPseudoYields', 'TRAIT_LEADER_EXALTED_GODDESS', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('GitarjaSettlement', 'Coastal', 0, 10),
('GitarjaYields', 'YIELD_FAITH', 1, 10),
('GitarjaYields', 'YIELD_PRODUCTION', 1, 10),
('GitarjaPseudoYields', 'PSEUDOYIELD_CITY_POPULATION', 1, 15),
('GitarjaPseudoYields', 'PSEUDOYIELD_HAPPINESS', 1, 20),
('GitarjaPseudoYields', 'PSEUDOYIELD_GPP_ADMIRAL', 1, 10),
('GitarjaPseudoYields', 'PSEUDOYIELD_UNIT_NAVAL_COMBAT', 1, 15);


-- LEADER_GORGO & LEADER_PERICLES / GREECE
-- GREECE has an extra Wildcard slot & Acropolis, boosted Culture - nothing to add here
-- GORGO seems OK
-- PERICLES seems OK, CS ally, low faith

-- 2019-01-02: Wrong assignment of PseudoYield to Wonders; remove, Pericles has Delian agenda which does that
DELETE FROM AiFavoredItems WHERE ListType = 'PericlesWonders' AND Item = 'PSEUDOYIELD_INFLUENCE';


-- HARDRADA / NORWAY
-- high forest & coast, 

DELETE FROM AiFavoredItems WHERE ListType = 'LastVikingKingCoastSettlement';
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value, StringVal) VALUES
('LastVikingKingCoastSettlement', 'Coastal',           0, 10,             NULL), -- vanilla def. 30
('LastVikingKingCoastSettlement', 'Foreign Continent', 0, 20,             NULL), -- try to settle other continents before others
('LastVikingKingCoastSettlement', 'Specific Feature',  0,  3, 'FEATURE_FOREST'); -- close to forests

UPDATE AiFavoredItems SET Value = 25 WHERE ListType = 'LastVikingKingNavalPreference' AND Item = 'PSEUDOYIELD_UNIT_NAVAL_COMBAT'; -- def. 100

INSERT INTO AiListTypes (ListType) VALUES
('HaraldYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('HaraldYields', 'TRAIT_AGENDA_LAST_VIKING_KING', 'Yields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('HaraldTechs', 'TECH_MINING', 1, 0),
('HaraldCivics', 'CIVIC_MYSTICISM', 1, 0),
('HaraldCivics', 'CIVIC_FOREIGN_TRADE', 1, 0),
('HaraldYields', 'YIELD_FAITH', 1, 10),
('LastVikingKingNavalPreference', 'PSEUDOYIELD_CITY_POPULATION', 1, 15),
('LastVikingKingNavalPreference', 'PSEUDOYIELD_CLEAR_BANDIT_CAMPS', 1, 15), -- get rid of barb ships asap
('LastVikingKingNavalPreference', 'PSEUDOYIELD_GPP_PROPHET', 1, 15), -- get the Holy Site asap
('LastVikingKingNavalPreference', 'PSEUDOYIELD_ENVIRONMENT', 1, 20), -- don't chop forests
('LastVikingKingNavalPreference', 'PSEUDOYIELD_UNIT_COMBAT', 1, -10), -- more ships, less land
('LastVikingKingNavalPreference', 'PSEUDOYIELD_UNIT_RELIGIOUS', 1, 20),
('LastVikingKingNavalPreference', 'PSEUDOYIELD_UNIT_SETTLER', 1, 20); -- more cities


-- HOJO / JAPAN

INSERT INTO StartBiasTerrains (CivilizationType, TerrainType, Tier) VALUES
('CIVILIZATION_JAPAN', 'TERRAIN_COAST', 2);
	
INSERT INTO AiListTypes (ListType) VALUES
('HoJoSettlement'),
('HoJoYields'),
('HoJoPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('HoJoSettlement', 'TRAIT_LEADER_DIVINE_WIND', 'PlotEvaluations'),
('HoJoYields', 'TRAIT_LEADER_DIVINE_WIND', 'Yields'),
('HoJoPseudoYields', 'TRAIT_LEADER_DIVINE_WIND', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('HoJoSettlement', 'Foreign Continent', 0, -10),
('HoJoSettlement', 'Nearest Friendly City', 0, -2), -- compact empire
('HoJoSettlement', 'Coastal', 0, 20),
('HoJoTechs', 'TECH_APPRENTICESHIP', 1, 0),
('HoJoTechs', 'TECH_INDUSTRIALIZATION', 1, 0),
('HoJoYields', 'YIELD_FAITH', 0, 10),
('HoJoYields', 'YIELD_CULTURE', 0, 10),
('HoJoYields', 'YIELD_PRODUCTION', 0, 10),
('HoJoYields', 'YIELD_GOLD', 0, -10), -- balance
('HoJoYields', 'YIELD_SCIENCE', 0, -10), -- balance
('HoJoPseudoYields', 'PSEUDOYIELD_CITY_DEFENDING_UNITS', 0, 20),
('HoJoPseudoYields', 'PSEUDOYIELD_CITY_DEFENSES', 0, 50),
('HoJoPseudoYields', 'PSEUDOYIELD_CITY_POPULATION', 0, 15),
('HoJoPseudoYields', 'PSEUDOYIELD_DISTRICT', 0, 50),
('HoJoPseudoYields', 'PSEUDOYIELD_GPP_ENGINEER', 0, 20),
('HoJoPseudoYields', 'PSEUDOYIELD_HAPPINESS', 0, 20),
('HoJoPseudoYields', 'PSEUDOYIELD_UNIT_COMBAT', 0, 15);


-- JADWIGA / POLAND

UPDATE AiFavoredItems SET Value = 25 WHERE ListType = 'JadwigaUnitBuilds' AND Item = 'UNIT_MILITARY_ENGINEER'; -- was 1

INSERT INTO AiListTypes (ListType) VALUES
('JadwigaDiplomacy'),
('JadwigaPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('JadwigaDiplomacy', 'TRAIT_LEADER_LITHUANIAN_UNION', 'DiplomaticActions'),
('JadwigaPseudoYields', 'TRAIT_LEADER_LITHUANIAN_UNION', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('JadwigaDiplomacy', 'DIPLOACTION_PROPOSE_TRADE', 1, 0),
('JadwigaDiplomacy', 'DIPLOACTION_ALLIANCE', 1, 0),
('JadwigaPseudoYields', 'PSEUDOYIELD_DIPLOMATIC_BONUS', 1, 5),
('JadwigaPseudoYields', 'PSEUDOYIELD_DISTRICT', 1, 50),
('JadwigaPseudoYields', 'PSEUDOYIELD_GPP_PROPHET', 1, 15),
('JadwigaPseudoYields', 'PSEUDOYIELD_GPP_MERCHANT', 1, 0),
('JadwigaPseudoYields', 'PSEUDOYIELD_GREATWORK_RELIC', 1, 12),
('JadwigaPseudoYields', 'PSEUDOYIELD_UNIT_RELIGIOUS', 1, 10);
/*
TODO: LuaScript
UNIT_MILITARY_ENGINEER
nothing special about him in the files - probably NOT used
		<Row UnitType="UNIT_MILITARY_ENGINEER" AiType="UNITTYPE_SIEGE_SUPPORT"/> (same as all Support Units), used ONLY in Siege City Assault => used in BH Trees
		<Row UnitType="UNIT_MILITARY_ENGINEER" AiType="UNITAI_BUILD"/> - flag that it can build on the map, same as Builder and Roman Legion => where is it used???
		<Row UnitType="UNIT_MILITARY_ENGINEER" AiType="UNITTYPE_CIVILIAN"/> => Used in BH Trees
		
Trees:
Build Trigger Improvement - generic, get unit, go to spot, clear, build - not used anywhere, no references!
Build City Improvement - same as above, but also reserves a plot, in DefaultCityBuilds and MinorCivBuilds, handles Boosts also

Also, Action 'Build Military Improvement' is available but only used during war time, so no Forts in peace time.
*/


-- JAYAVARMAN / KHMER

INSERT INTO AiListTypes (ListType) VALUES
('JayavarmanDistricts'),
('JayavarmanYields'),
('JayavarmanPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('JayavarmanDistricts',    'TRAIT_LEADER_MONASTERIES_KING', 'Districts'),
('JayavarmanYields',       'TRAIT_LEADER_MONASTERIES_KING', 'Yields'),
('JayavarmanPseudoYields', 'TRAIT_LEADER_MONASTERIES_KING', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('JayavarmanDistricts', 'DISTRICT_AQUEDUCT', 1, 0), -- risky???
('JayavarmanYields', 'YIELD_FAITH', 1, 10),
('JayavarmanYields', 'YIELD_FOOD', 1, 10),
('JayavarmanPseudoYields', 'PSEUDOYIELD_GPP_PROPHET', 1, 20),
('JayavarmanPseudoYields', 'PSEUDOYIELD_GREATWORK_RELIC', 0, 8),
('JayavarmanPseudoYields', 'PSEUDOYIELD_CITY_POPULATION', 0, 15),
('JayavarmanPseudoYields', 'PSEUDOYIELD_HAPPINESS', 0, 20),
('JayavarmanPseudoYields', 'PSEUDOYIELD_UNIT_COMBAT', 1, -10),
('JayavarmanPseudoYields', 'PSEUDOYIELD_UNIT_NAVAL_COMBAT', 1, -10);


-- LEADER_JOHN_CURTIN / AUSTRALIA

INSERT INTO AiListTypes (ListType) VALUES
('CurtinSettlement'),
('CurtinDiplomacy'),
('CurtinPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('CurtinSettlement', 'TRAIT_LEADER_CITADEL_CIVILIZATION', 'PlotEvaluations'),
('CurtinDiplomacy', 'TRAIT_LEADER_CITADEL_CIVILIZATION', 'DiplomaticActions'),
('CurtinPseudoYields', 'TRAIT_LEADER_CITADEL_CIVILIZATION', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('CurtinSettlement', 'Coastal', 0, 10),
('CurtinDiplomacy', 'DIPLOACTION_DECLARE_LIBERATION_WAR', 1, 0),
('CurtinDiplomacy', 'DIPLOACTION_DECLARE_PROTECTORATE_WAR', 1, 0),
('CurtinDiplomacy', 'DIPLOACTION_DECLARE_RECONQUEST_WAR', 1, 0),
('CurtinDiplomacy', 'DIPLOACTION_LIBERATE_CITY', 1, 0),
('CurtinPseudoYields', 'PSEUDOYIELD_CITY_POPULATION', 1, 15),
('CurtinPseudoYields', 'PSEUDOYIELD_TOURISM', 1, 10),
('CurtinPseudoYields', 'PSEUDOYIELD_ENVIRONMENT', 1, 20);


-- LEADER_LAUTARO / MAPUCHE

INSERT INTO AiListTypes (ListType) VALUES
('LautaroPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('LautaroPseudoYields', 'TRAIT_LEADER_LAUTARO_ABILITY', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('LautaroPseudoYields', 'PSEUDOYIELD_CITY_BASE', 1, 50),
('LautaroPseudoYields', 'PSEUDOYIELD_CITY_ORIGINAL_CAPITAL', 1, 50),
('LautaroPseudoYields', 'PSEUDOYIELD_ENVIRONMENT', 1, 20),
('LautaroPseudoYields', 'PSEUDOYIELD_UNIT_COMBAT', 1, 10);


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
('MontezumaTechs', 'TECH_MINING', 1, 0), -- most luxes are here
('MontezumaTechs', 'TECH_IRRIGATION', 1, 0), -- most luxes are here
('MontezumaPseudoYields', 'PSEUDOYIELD_CITY_BASE', 1, 150),
('MontezumaPseudoYields', 'PSEUDOYIELD_CITY_ORIGINAL_CAPITAL', 1, 50),
('MontezumaPseudoYields', 'PSEUDOYIELD_UNIT_COMBAT', 1, 15),
('MontezumaPseudoYields', 'PSEUDOYIELD_UNIT_NAVAL_COMBAT', 1, -15),
('MontezumaPseudoYields', 'PSEUDOYIELD_GPP_ADMIRAL', 1, -10),
('MontezumaPseudoYields', 'PSEUDOYIELD_GPP_GENERAL', 1, 10),
('MontezumaPseudoYields', 'PSEUDOYIELD_GPP_PROPHET', 1, -25),
('MontezumaPseudoYields', 'PSEUDOYIELD_DISTRICT', 1, 50), -- more districts
('MontezumaPseudoYields', 'PSEUDOYIELD_UNIT_SETTLER', 1, 20), -- vanilla 2, RFX 3
('MontezumaUnits',        'UNIT_BUILDER', 1, 20),
('MontezumaUnitBuilds',   'PROMOTION_CLASS_SIEGE', 1, 15); -- vanilla 2, RFX 3

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value, StringVal) VALUES
('MontezumaSettlement', 'Fresh Water',           0,-6,                   NULL), -- 16
('MontezumaSettlement', 'Coastal',               0,-3,                   NULL), -- 7
('MontezumaSettlement', 'Nearest Friendly City', 0, 2,                   NULL), -- a bit of forward settling
('MontezumaSettlement', 'New Resources',         0, 3,                   NULL), -- vanilla 4, RFX 5
('MontezumaSettlement', 'Resource Class',        0, 2, 'RESOURCECLASS_LUXURY'), -- vanilla 2, RFX 3
('MontezumaSettlement', 'Cultural Pressure',     0, 1,                   NULL); -- careful not to loose new cities


-- LEADER_MVEMBA / KONGO

INSERT INTO AiListTypes (ListType) VALUES
('KongoYields'),
('KongoPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('KongoYields',       'TRAIT_CIVILIZATION_NKISI', 'Yields'),
('KongoPseudoYields', 'TRAIT_CIVILIZATION_NKISI', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('KongoYields',       'YIELD_CULTURE', 1, 10),
('KongoPseudoYields', 'PSEUDOYIELD_GPP_MERCHANT', 1, 10),
('KongoPseudoYields', 'PSEUDOYIELD_GPP_WRITER', 1, 10), -- to build Theater Squares
('KongoPseudoYields', 'PSEUDOYIELD_GPP_ARTIST', 1, 10),
('KongoPseudoYields', 'PSEUDOYIELD_GPP_MUSICIAN', 1, 10),
('KongoPseudoYields', 'PSEUDOYIELD_GREATWORK_ARTIFACT', 1, 8),
('KongoPseudoYields', 'PSEUDOYIELD_GREATWORK_LANDSCAPE', 1, -2),
('KongoPseudoYields', 'PSEUDOYIELD_GREATWORK_MUSIC', 1, -2),
('KongoPseudoYields', 'PSEUDOYIELD_GREATWORK_PORTRAIT', 1, -2),
('KongoPseudoYields', 'PSEUDOYIELD_GREATWORK_RELIC', 1, 8),
('KongoPseudoYields', 'PSEUDOYIELD_GREATWORK_RELIGIOUS', 1, -2),
('KongoPseudoYields', 'PSEUDOYIELD_GREATWORK_SCULPTURE', 1, 8),
('KongoPseudoYields', 'PSEUDOYIELD_GREATWORK_WRITING', 1, -2),
('KongoPseudoYields', 'PSEUDOYIELD_CITY_POPULATION', 1, 20),
('KongoPseudoYields', 'PSEUDOYIELD_ENVIRONMENT', 1, 20), -- leave jungle
('KongoPseudoYields', 'PSEUDOYIELD_UNIT_ARCHAEOLOGIST', 1, 50);


-- LEADER_PEDRO / BRAZIL
-- lower a bit GP obsession, balance defense

DELETE FROM AiFavoredItems WHERE ListType = 'PedroCivics' AND Item = 'CIVIC_CAPITALISM';
DELETE FROM AiFavoredItems WHERE ListType = 'PedroCivics' AND Item = 'CIVIC_GUILDS';
DELETE FROM AiFavoredItems WHERE ListType = 'PedroCivics' AND Item = 'CIVIC_NATIONALISM';

DELETE FROM AiFavoredItems WHERE ListType = 'GreatPersonObsessedGreatPeople' AND Item = 'PSEUDOYIELD_GPP_PROPHET'; -- don't be obsessed with him - there is only one!
UPDATE AiFavoredItems SET Value =  25 WHERE ListType = 'GreatPersonObsessedGreatPeople'; -- def. 50

INSERT INTO AiListTypes (ListType) VALUES
('PedroPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('PedroPseudoYields', 'TRAIT_LEADER_MAGNANIMOUS', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('PedroCivics', 'CIVIC_NATURAL_HISTORY', 1, 0),
('PedroPseudoYields', 'PSEUDOYIELD_CITY_DEFENSES', 1, 100),
('PedroPseudoYields', 'PSEUDOYIELD_ENVIRONMENT', 1, 20), -- leave jungle
('PedroPseudoYields', 'PSEUDOYIELD_CITY_DEFENDING_UNITS', 1, 25), -- to build Theater Squares
--('PedroPseudoYields', 'PSEUDOYIELD_DISTRICT', 1, 50),
('PedroPseudoYields', 'PSEUDOYIELD_UNIT_RELIGIOUS', 1, -25), -- use faith for GP
('PedroPseudoYields', 'PSEUDOYIELD_WONDER', 1, -25);


-- LEADER_PETER_GREAT
-- almost empty...

DELETE FROM AiFavoredItems WHERE ListType = 'PeterWonders' AND Item = 'BUILDING_COLOSSUS'; -- there are cheaper ways to get +1 TR

INSERT INTO AiListTypes (ListType) VALUES
('PeterPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('PeterPseudoYields', 'TRAIT_LEADER_GRAND_EMBASSY', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('PeterCivics', 'CIVIC_MYSTICISM', 1, 0),
('PeterPseudoYields', 'PSEUDOYIELD_GPP_PROPHET', 1, 20), -- try to get religion asap
('PeterPseudoYields', 'PSEUDOYIELD_CITY_DEFENSES', 1, 50),
('PeterPseudoYields', 'PSEUDOYIELD_CITY_DEFENDING_UNITS', 1, 25),
('PeterPseudoYields', 'PSEUDOYIELD_GPP_ARTIST', 1, 10),
('PeterPseudoYields', 'PSEUDOYIELD_GPP_MUSICIAN', 1, 10),
('PeterPseudoYields', 'PSEUDOYIELD_GPP_WRITER', 1, 10),
('PeterWonders', 'BUILDING_STONEHENGE', 0, 0), -- don't build it, build Lavra!
('PeterWonders', 'BUILDING_ST_BASILS_CATHEDRAL', 1, 0),
('PeterWonders', 'BUILDING_BOLSHOI_THEATRE', 1, 0),
('PeterWonders', 'BUILDING_HERMITAGE', 1, 0);


-- LEADER_PHILIP_II / SPAIN

UPDATE AiFavoredItems SET Value = 20 WHERE ListType = 'CounterReformerInquisitorPreference' AND Item = 'UNIT_INQUISITOR'; -- was 1 -- Philip II

INSERT INTO AiListTypes (ListType) VALUES
('PhilipDiplomacy'),
('PhilipPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('PhilipDiplomacy',    'TRAIT_LEADER_EL_ESCORIAL', 'DiplomaticActions'),
('PhilipPseudoYields', 'TRAIT_LEADER_EL_ESCORIAL', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('PhilipCivics', 'CIVIC_MERCANTILISM', 1, 0),
('PhilipDiplomacy', 'DIPLOACTION_DECLARE_HOLY_WAR', 1, 0),
('PhilipDiplomacy', 'DIPLOACTION_KEEP_PROMISE_DONT_CONVERT', 0, 0), -- NOT favored
('PhilipPseudoYields', 'PSEUDOYIELD_UNIT_RELIGIOUS', 1, 10),
('PhilipPseudoYields', 'PSEUDOYIELD_GPP_PROPHET', 1, 10),
('PhilipPseudoYields', 'PSEUDOYIELD_GPP_ADMIRAL', 1, 10),
('PhilipPseudoYields', 'PSEUDOYIELD_UNIT_NAVAL_COMBAT', 1, 15);



/*

LEADER_POUNDMAKER
LEADER_QIN
LEADER_ROBERT_THE_BRUCE
LEADER_SALADIN
LEADER_SEONDEOK
LEADER_SHAKA
LEADER_TAMAR
LEADER_TOMYRIS
LEADER_TRAJAN
LEADER_T_ROOSEVELT
LEADER_VICTORIA
LEADER_WILHELMINA

underutilized wonders (2)
BUILDING_BOLSHOI_THEATRE
BUILDING_CASA_DE_CONTRATACION
BUILDING_ESTADIO_DO_MARACANA
BUILDING_FORBIDDEN_CITY
BUILDING_POTALA_PALACE
BUILDING_SYDNEY_OPERA_HOUSE
BUILDING_VENETIAN_ARSENAL

underutilized wonders (1)
BUILDING_AMUNDSEN_SCOTT_RESEARCH_STATION
BUILDING_ANGKOR_WAT
BUILDING_APADANA
BUILDING_BIG_BEN
BUILDING_HALICARNASSUS_MAUSOLEUM
BUILDING_KILWA_KISIWANI
BUILDING_KOTOKU_IN
BUILDING_TAJ_MAHAL
BUILDING_TEMPLE_ARTEMIS

not used wonders (0)
BUILDING_ST_BASILS_CATHEDRAL
BUILDING_STATUE_LIBERTY
BUILDING_HUEY_TEOCALLI
BUILDING_JEBEL_BARKAL

*/

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
-- MEDIEVAL
--('MedievalSensitivity',	'YIELD_CULTURE', 1, 10),
('MedievalYields', 'YIELD_CULTURE', 1, -10),
('MedievalYields', 'YIELD_FAITH', 1, 20),
('MedievalYields', 'YIELD_FOOD', 1, 25),
--('MedievalYields', 'YIELD_GOLD', 1, 10),
('MedievalYields', 'YIELD_PRODUCTION', 1, 15),
('MedievalYields', 'YIELD_SCIENCE', 1, -10),
('MedievalPseudoYields', 'PSEUDOYIELD_GPP_ENGINEER',	1, 20),
('MedievalPseudoYields', 'PSEUDOYIELD_GPP_MERCHANT',	1, 20),
('MedievalPseudoYields', 'PSEUDOYIELD_GPP_SCIENTIST', 1, 30),
-- RENAISSANCE
--('RenaissanceYields', 'YIELD_FOOD', 1, 10),
('RenaissanceYields', 'YIELD_CULTURE', 1, 15),
--('RenaissanceYields', 'YIELD_GOLD', 1, 10),
('RenaissanceYields', 'YIELD_FAITH', 1, -25),
('RenaissanceYields', 'YIELD_SCIENCE', 1, 10),
('RenaissancePseudoYields', 'PSEUDOYIELD_GPP_ARTIST', 1, 10),
('RenaissancePseudoYields', 'PSEUDOYIELD_GPP_ENGINEER', 1, 20),
('RenaissancePseudoYields', 'PSEUDOYIELD_GPP_PROPHET', 1, -100),
('RenaissancePseudoYields', 'PSEUDOYIELD_GPP_SCIENTIST', 1, 30),
('RenaissancePseudoYields', 'PSEUDOYIELD_GPP_WRITER', 1, 10),
-- INDUSTRIAL
--('IndustrialYields', 'YIELD_FAITH',	1, -40),
--('IndustrialYields', 'YIELD_GOLD',	1, 10),
('IndustrialYields', 'YIELD_PRODUCTION',	1, 15),
('IndustrialPseudoYields', 'PSEUDOYIELD_GPP_ENGINEER', 1, 20),
('IndustrialPseudoYields', 'PSEUDOYIELD_GPP_SCIENTIST', 1, 20),
-- MODERN
('ModernSensitivity', 'YIELD_CULTURE', 1, 10),
('ModernSensitivity', 'YIELD_SCIENCE', 1, 10),
('ModernYields', 'YIELD_FOOD', 1, 10),
('ModernYields', 'YIELD_GOLD', 1, 15);
