-- ===========================================================================
-- Real Strategy - Main file with Strategies and Leaders
-- Author: Infixo
-- 2018-12-14: Created
-- ===========================================================================


-- ===========================================================================
-- GENERAL CHANGES
-- ===========================================================================

--------------------------------------------------------------
-- 2018-12-22 PlotEvaluations

DELETE FROM AiFavoredItems WHERE ListType = 'StandardSettlePlot';
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value, StringVal) VALUES
('StandardSettlePlot', 'Foreign Continent', 0, -4, NULL), -- def
('StandardSettlePlot', 'Nearest Friendly City', 0, -8, NULL), -- def, be careful - expansion gives +3, naval +2/4
('StandardSettlePlot', 'Fresh Water', 0, 20, NULL), -- +7
('StandardSettlePlot', 'Coastal', 0, 6, NULL), -- -2
('StandardSettlePlot', 'Total Yield', 0, 1, 'YIELD_PRODUCTION'), -- def
('StandardSettlePlot', 'Inner Ring Yield', 0, 1, 'YIELD_FOOD'), -- def
('StandardSettlePlot', 'Inner Ring Yield', 0, 2, 'YIELD_PRODUCTION'), -- def
('StandardSettlePlot', 'Inner Ring Yield', 0, 1, 'YIELD_GOLD'), -- new
('StandardSettlePlot', 'Inner Ring Yield', 0, 2, 'YIELD_SCIENCE'), -- new
('StandardSettlePlot', 'Inner Ring Yield', 0, 2, 'YIELD_CULTURE'), -- new
('StandardSettlePlot', 'Inner Ring Yield', 0, 2, 'YIELD_FAITH'), -- new
('StandardSettlePlot', 'New Resources', 0, 6, NULL), -- +2
('StandardSettlePlot', 'Resource Class', 0, 2, 'RESOURCECLASS_BONUS'), -- new
('StandardSettlePlot', 'Resource Class', 0, 3, 'RESOURCECLASS_LUXURY'), -- +1
('StandardSettlePlot', 'Resource Class', 0, 4, 'RESOURCECLASS_STRATEGIC'), -- +2
('StandardSettlePlot', 'Specific Resource', 0, 2, 'RESOURCE_HORSES'), -- -1
('StandardSettlePlot', 'Specific Resource', 0, 4, 'RESOURCE_IRON'), -- -1
('StandardSettlePlot', 'Specific Resource', 0, 2, 'RESOURCE_NITER'), -- def
--('StandardSettlePlot', 'Specific Resource', 0, 0, 'RESOURCE_COAL'), -- plenty
--('StandardSettlePlot', 'Specific Resource', 0, 0, 'RESOURCE_OIL'), -- plenty
('StandardSettlePlot', 'Specific Resource', 0, 2, 'RESOURCE_ALUMINUM'), -- new
('StandardSettlePlot', 'Specific Resource', 0, 10, 'RESOURCE_URANIUM'), -- new
('StandardSettlePlot', 'Specific Feature', 0, -5, 'FEATURE_ICE');
-- put Natural Wonders as generally good to be around
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value, StringVal)
SELECT 'StandardSettlePlot', 'Specific Feature', 0, 3, FeatureType -- +1
FROM Features
WHERE NaturalWonder = 1;

UPDATE AiFavoredItems SET Value = 50 WHERE ListType = 'DefaultCitySettlement' AND Item = 'SETTLEMENT_MIN_VALUE_NEEDED';


--------------------------------------------------------------
-- Yield biases

--UPDATE AiFavoredItems SET Value = 25 WHERE ListType = 'DefaultYieldBias' AND Item = 'YIELD_PRODUCTION'; -- 25
--UPDATE AiFavoredItems SET Value = 20 WHERE ListType = 'DefaultYieldBias' AND Item = 'YIELD_SCIENCE'; -- 10
--UPDATE AiFavoredItems SET Value = 20 WHERE ListType = 'DefaultYieldBias' AND Item = 'YIELD_CULTURE'; -- 10
UPDATE AiFavoredItems SET Value = -15 WHERE ListType = 'DefaultYieldBias' AND Item = 'YIELD_GOLD';  -- 20
--UPDATE AiFavoredItems SET Value = -25 WHERE ListType = 'DefaultYieldBias' AND Item = 'YIELD_FAITH'; -- -25


--------------------------------------------------------------
-- Yields - default values are 1.0 except for Gold = 0.5
-- Not used - I think it should be tuned by using AiLists (DefaultYieldBias - see above)

--UPDATE Yields SET DefaultValue = 0.8 WHERE YieldType = 'YIELD_FOOD';
--UPDATE Yields SET DefaultValue = 1.2 WHERE YieldType = 'YIELD_PRODUCTION';
--UPDATE Yields SET DefaultValue = 0.6 WHERE YieldType = 'YIELD_GOLD';
--UPDATE Yields SET DefaultValue = 1.1 WHERE YieldType = 'YIELD_SCIENCE';
--UPDATE Yields SET DefaultValue = 1.1 WHERE YieldType = 'YIELD_CULTURE';
--UPDATE Yields SET DefaultValue = 0.9 WHERE YieldType = 'YIELD_FAITH';


--------------------------------------------------------------
-- PseudoYields - default value is shown at the end

/*
Comment about PSEUDOYIELD_CITY_* from AI+
These values appear to determine not just how to value cities to attack, but also how likely it is we attack any.
Based on testing:
- PSEUDOYIELD_CITY_BASE  if positive makes it more likely we'll attack
- PSEUDOYIELD_CITY_DEFENSES   if positive makes it LESS likely we'll attack (times city defence? maybe walls?)
- PSEUDOYIELD_CITY_DEFENDING_UNITS   if positive makes it LESS likely we'll attack (times unit count?)
- PSEUDOYIELD_CITY_ORIGINAL_CAPITAL   if positive, increases desire to attack capitals
- PSEUDOYIELD_CITY_POPULATION   if positive, probably increases desire (too lazy to check)

I determined that:
- Bias value is always a percentage and it is bottom-capped at -95%.
- BASE and ORIGINAL_CAPITAL - just plainly add the value modified by bias_percentage
- POPULATION formula: Value += floor(CityPop/5) * (base * (1+bias_percentage)) - notice that it changes every 5 pop
- DEFENSES - it subtracts the value depending on city's Defense Strength, Value -= base * (city_defense+11)/37 * (1+bias_percentage)
	- also, this applies only when city_def >25 if city has walls, and >20 if city has no walls;
	- if def is less than that, a standard factor is applied which is not affected by pseudo value at all
- DEFENDING_UNITS - it subtracts the value depending on how many units are defending the city; I couldn't determined an exact formula for that, just hints:
	- it seems to account for units within Range 3, garrisoned unit is treated differently
	- the stronger the units, the more is subtracted
	- basically 2-3 units around decrease the valuation quite signifcantly, 4-5 almost make it 0
*/

--UPDATE PseudoYields SET DefaultValue = 450 WHERE PseudoYieldType = 'PSEUDOYIELD_CITY_BASE'; -- 	450, important mostly early game, later valuations are in thousands (5000+)...
UPDATE PseudoYields SET DefaultValue =  60 WHERE PseudoYieldType = 'PSEUDOYIELD_CITY_DEFENDING_UNITS'; -- 	80 -- very important, especially late game, causes huge jumps in city valuation
UPDATE PseudoYields SET DefaultValue = 300 WHERE PseudoYieldType = 'PSEUDOYIELD_CITY_DEFENSES'; -- 	400 - very important for aggression mgmt!
UPDATE PseudoYields SET DefaultValue = 150 WHERE PseudoYieldType = 'PSEUDOYIELD_CITY_ORIGINAL_CAPITAL'; -- 	200, lower value should save Minors a bit, Conquest will boost it anyway
UPDATE PseudoYields SET DefaultValue =  75 WHERE PseudoYieldType = 'PSEUDOYIELD_CITY_POPULATION'; -- 	50, not so important overall


-- infrastructure & various
UPDATE PseudoYields SET DefaultValue =  1.7 WHERE PseudoYieldType = 'PSEUDOYIELD_CLEAR_BANDIT_CAMPS'; -- 	0.5, Ai+ 1.6
--UPDATE PseudoYields SET DefaultValue =  0.15 WHERE PseudoYieldType = 'PSEUDOYIELD_DIPLOMATIC_BONUS'; -- 	0.25 -- let's not change diplomacy yet
--UPDATE PseudoYields SET DefaultValue = 4.0 WHERE PseudoYieldType = 'PSEUDOYIELD_DISTRICT'; -- 	3.5, AI+ = 6.7! check if this helps with Holy Sites - this is the earliest available district!
UPDATE PseudoYields SET DefaultValue =  0.8 WHERE PseudoYieldType = 'PSEUDOYIELD_ENVIRONMENT'; -- 	0.5, AI+ 0.75
--UPDATE PseudoYields SET DefaultValue = X.X WHERE PseudoYieldType = 'PSEUDOYIELD_GOLDENAGE_POINT'; -- 1, R&F
--UPDATE PseudoYields SET DefaultValue = X.X WHERE PseudoYieldType = 'PSEUDOYIELD_GOVERNOR'; -- 2, R&F
--UPDATE PseudoYields SET DefaultValue = X.X WHERE PseudoYieldType = 'PSEUDOYIELD_HAPPINESS'; -- 1
UPDATE PseudoYields SET DefaultValue = 4.0 WHERE PseudoYieldType = 'PSEUDOYIELD_IMPROVEMENT'; -- 	0.5, 13.5 too much
--UPDATE PseudoYields SET DefaultValue = 0.55 WHERE PseudoYieldType = 'PSEUDOYIELD_INFLUENCE'; -- 	0.5, envoys - Diplo?
UPDATE PseudoYields SET DefaultValue = 40 WHERE PseudoYieldType = 'PSEUDOYIELD_NUCLEAR_WEAPON'; -- 	25, AI+ 45
UPDATE PseudoYields SET DefaultValue = 100 WHERE PseudoYieldType = 'PSEUDOYIELD_SPACE_RACE'; -- 100
--UPDATE PseudoYields SET DefaultValue = X.X WHERE PseudoYieldType = 'PSEUDOYIELD_STANDING_ARMY_NUMBER'; -- 	1 -- controls size of the army
--UPDATE PseudoYields SET DefaultValue = X.X WHERE PseudoYieldType = 'PSEUDOYIELD_STANDING_ARMY_VALUE'; -- 	0.1 -- controls size of the army
--UPDATE PseudoYields SET DefaultValue = 1 WHERE PseudoYieldType = 'PSEUDOYIELD_TOURISM'; -- 	1
UPDATE PseudoYields SET DefaultValue = 0.6 WHERE PseudoYieldType = 'PSEUDOYIELD_WONDER'; -- 2, AI+ 0.55

-- GPP
UPDATE PseudoYields SET DefaultValue =  0.5 WHERE PseudoYieldType = 'PSEUDOYIELD_GPP_ADMIRAL'; -- 	0.5
UPDATE PseudoYields SET DefaultValue =  0.7 WHERE PseudoYieldType = 'PSEUDOYIELD_GPP_ARTIST'; -- 	0.5
UPDATE PseudoYields SET DefaultValue =  0.7 WHERE PseudoYieldType = 'PSEUDOYIELD_GPP_ENGINEER'; -- 	0.5
UPDATE PseudoYields SET DefaultValue =  0.6 WHERE PseudoYieldType = 'PSEUDOYIELD_GPP_GENERAL'; -- 	0.5
UPDATE PseudoYields SET DefaultValue =  0.5 WHERE PseudoYieldType = 'PSEUDOYIELD_GPP_MERCHANT'; -- 	0.5, AI+ 1.5 - why so high?
UPDATE PseudoYields SET DefaultValue =  0.5 WHERE PseudoYieldType = 'PSEUDOYIELD_GPP_MUSICIAN'; -- 	0.5
UPDATE PseudoYields SET DefaultValue =  0.7 WHERE PseudoYieldType = 'PSEUDOYIELD_GPP_PROPHET'; -- 	0.5
UPDATE PseudoYields SET DefaultValue =  0.7 WHERE PseudoYieldType = 'PSEUDOYIELD_GPP_SCIENTIST'; -- 	0.5, 1.6 vs. 0.75 disproportion Sci vs. Cul - not many Theater Districts
UPDATE PseudoYields SET DefaultValue =  0.8 WHERE PseudoYieldType = 'PSEUDOYIELD_GPP_WRITER'; -- 	0.5

-- great works
--UPDATE PseudoYields SET DefaultValue = 8 WHERE PseudoYieldType = 'PSEUDOYIELD_GREATWORK_ARTIFACT'; -- 	10
--UPDATE PseudoYields SET DefaultValue = 8 WHERE PseudoYieldType = 'PSEUDOYIELD_GREATWORK_LANDSCAPE'; -- 	10
--UPDATE PseudoYields SET DefaultValue = 8 WHERE PseudoYieldType = 'PSEUDOYIELD_GREATWORK_MUSIC'; -- 	10
--UPDATE PseudoYields SET DefaultValue = 8 WHERE PseudoYieldType = 'PSEUDOYIELD_GREATWORK_PORTRAIT'; -- 	10
--UPDATE PseudoYields SET DefaultValue = 8 WHERE PseudoYieldType = 'PSEUDOYIELD_GREATWORK_RELIC'; -- 	10
--UPDATE PseudoYields SET DefaultValue = 8 WHERE PseudoYieldType = 'PSEUDOYIELD_GREATWORK_RELIGIOUS'; -- 	10
--UPDATE PseudoYields SET DefaultValue = 8 WHERE PseudoYieldType = 'PSEUDOYIELD_GREATWORK_SCULPTURE'; -- 	10
--UPDATE PseudoYields SET DefaultValue = 8 WHERE PseudoYieldType = 'PSEUDOYIELD_GREATWORK_WRITING'; -- 	10

-- units
UPDATE PseudoYields SET DefaultValue =  3.0 WHERE PseudoYieldType = 'PSEUDOYIELD_UNIT_AIR_COMBAT'; -- 	2, 2.2 in AI+, 20 in AirpowerFix
--UPDATE PseudoYields SET DefaultValue =  3.0 WHERE PseudoYieldType = 'PSEUDOYIELD_UNIT_ARCHAEOLOGIST'; -- 4
UPDATE PseudoYields SET DefaultValue =  1.1 WHERE PseudoYieldType = 'PSEUDOYIELD_UNIT_COMBAT'; -- 1.0, AI+ 1.4
UPDATE PseudoYields SET DefaultValue =  0.7 WHERE PseudoYieldType = 'PSEUDOYIELD_UNIT_EXPLORER'; --	1
--UPDATE PseudoYields SET DefaultValue =  1.0 WHERE PseudoYieldType = 'PSEUDOYIELD_UNIT_NAVAL_COMBAT'; --	1 -- leave for naval strategies
UPDATE PseudoYields SET DefaultValue =  0.8 WHERE PseudoYieldType = 'PSEUDOYIELD_UNIT_RELIGIOUS'; -- 1
UPDATE PseudoYields SET DefaultValue =  1.1 WHERE PseudoYieldType = 'PSEUDOYIELD_UNIT_SETTLER'; -- 1 -- 1.4 seems to much, they build Settlers even with 0 army and undeveloped cities
--UPDATE PseudoYields SET DefaultValue = 15.0 WHERE PseudoYieldType = 'PSEUDOYIELD_UNIT_SPY'; -- 20
UPDATE PseudoYields SET DefaultValue = 4.0 WHERE PseudoYieldType = 'PSEUDOYIELD_UNIT_TRADE'; -- 1, AI+ 11 -- make sure they build them all

/*
These Pseudos affect the valuation of Civics and Technologies
However, each is applied to a separate tree respectively, and since the trees are separate they don't clash
Tweaking these probaby would result in a bit different ORDER of selecting civics and techs, but without the details
of the algorithm it is hard to predict results
I determined only that:
a) Each civic and tech has a residual valuation that can be seen when setting those Pseudos to 0
b) The pseudo default value is multiplied by a factor of 30..100 and added to the valuation
c) The bias value (from AiFavoredItems) affects this factor even further, so formula is: factor * def_value * ( 1 + bias_percentage )
UPDATE PseudoYields SET DefaultValue = 5 WHERE PseudoYieldType = 'PSEUDOYIELD_CIVIC';
UPDATE PseudoYields SET DefaultValue = 5 WHERE PseudoYieldType = 'PSEUDOYIELD_TECHNOLOGY';
*/

-- DISTRICT_AERODROME - drastic move, but maybe necessary?
-- not necessary - Aerodromes ARE built (on average 1 per 3-5 cities)
/*
INSERT OR REPLACE INTO AiListTypes (ListType) VALUES
('DefaultDistricts');
INSERT OR REPLACE INTO AiLists (ListType, LeaderType, System) VALUES
('DefaultDistricts', 'TRAIT_LEADER_MAJOR_CIV', 'Districts');
INSERT OR REPLACE INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('DefaultDistricts', 'DISTRICT_AERODROME', 1, 0);
*/


--------------------------------------------------------------
-- BaseOperationsLimits

UPDATE AiOperationDefs SET OperationType = 'OP_DEFENSE' WHERE OperationName = 'City Defense'; -- the only OP_ that is missing an assignment?

--Changes the amount of operations of these types that can run at the same time
UPDATE AiFavoredItems SET Value = 2 WHERE ListType = 'BaseOperationsLimits' AND Item = 'OP_DEFENSE'; -- def. 1 ?number of simultaneus ops?  TUNE ACCORDING TO PEACE/WAR
UPDATE AiFavoredItems SET Value = 2 WHERE ListType = 'BaseOperationsLimits' AND Item = 'OP_SETTLE'; -- def. 1 ?number of simultaneus ops?

-- Air City Defense - new op from RST
-- register a new op, they are numbered for an unknown reason
INSERT INTO AiOperationTypes (OperationType, Value)
SELECT 'OP_AIR_DEFENSE', MAX(Value)+1
FROM AiOperationTypes;

-- Fast Pillage - new op from Delnar - trying to make it work
-- register a new op, they are numbered for an unknown reason
INSERT INTO AiOperationTypes (OperationType, Value)
SELECT 'OP_PILLAGE', MAX(Value)+1
FROM AiOperationTypes;

INSERT INTO AiFavoredItems(ListType, Item, Value) VALUES
('BaseOperationsLimits',   'OP_AIR_DEFENSE', 2),
('PerWarOperationsLimits', 'OP_AIR_DEFENSE', 1),
('BaseOperationsLimits',   'OP_PILLAGE', 1),
('PerWarOperationsLimits', 'OP_PILLAGE', 1);


-- Units are put after Slush fund, weird...
UPDATE AiFavoredItems SET Value = 2 WHERE ListType = 'DefaultSavings' AND Item = 'SAVING_UNITS';


--------------------------------------------------------------
-- UNITS - in some cases civs produce too many or too few specific units

UPDATE AiFavoredItems SET Value =  10 WHERE ListType = 'UnitPriorityBoosts' AND Item = 'UNIT_SETTLER'; -- was 1
INSERT INTO AiFavoredItems(ListType, Item, Value) VALUES
('UnitPriorityBoosts', 'UNIT_INQUISITOR', -15),
('UnitPriorityBoosts', 'UNIT_NATURALIST', 10),
('UnitPriorityBoosts', 'UNIT_MILITARY_ENGINEER', -15);


--------------------------------------------------------------
-- UNIT PROMOTON CLASSES - in some cases civs produce too many or too few specific units

-- Planes balance 80 vs 90 => 12% / 85 vs. 100 => +18%
INSERT OR REPLACE INTO AiListTypes (ListType) VALUES
('DefaultUnitBuilds');
INSERT OR REPLACE INTO AiLists (ListType, LeaderType, System) VALUES
('DefaultUnitBuilds', 'TRAIT_LEADER_MAJOR_CIV', 'UnitPromotionClasses');
INSERT INTO AiFavoredItems (ListType, Item, Value) VALUES
('DefaultUnitBuilds', 'PROMOTION_CLASS_AIR_FIGHTER', 10),
--('DefaultUnitBuilds', 'PROMOTION_CLASS_AIR_BOMBER',  -5),
('MinorCivUnitBuilds', 'PROMOTION_CLASS_AIR_FIGHTER', 10);
--('MinorCivUnitBuilds', 'PROMOTION_CLASS_AIR_BOMBER',  -5);



--------------------------------------------------------------
/* TODO: Faith & Religion conundrum
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
-- STRATEGIES
-- ===========================================================================

-- 2018-12-09: Missing entries in Types for Victory Strategies
-- The only one that exists is Religious one
INSERT OR REPLACE INTO Types (Type, Kind) VALUES
('VICTORY_STRATEGY_CULTURAL_VICTORY', 'KIND_VICTORY_STRATEGY'),
('VICTORY_STRATEGY_MILITARY_VICTORY', 'KIND_VICTORY_STRATEGY'),
('VICTORY_STRATEGY_SCIENCE_VICTORY', 'KIND_VICTORY_STRATEGY');

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
-- AiOperationTypes - num of ops (OP_SETTLE, OP_DEFENSE, etc.)
-- AiScoutUses
-- CityEvents - manages event-related ops for the city (building things, default attack, under threat) -> OperationName
-- Homeland - AllowedMoves
-- PerWarOperationTypes - ops per war
-- PlotEvaluations - static settling
-- SavingTypes - what the gold is for
-- SettlementPreferences - dynamic settling
-- NO! Strategies - don't use it, messes up conditions
-- Tactics - AllowedMoves
-- TechBoosts - pre-configured
-- TriggeredTrees - manages event-related trees
-- ===========================================================================


-- ===========================================================================
-- VICTORY_STRATEGY_CULTURAL_VICTORY
--CultureSensitivity
--CultureVictoryFavoredCommemorations
-- ===========================================================================

UPDATE AiFavoredItems SET Value = 35 WHERE ListType = 'CultureVictoryYields'       AND Item = 'YIELD_CULTURE'; -- def. 25

UPDATE AiFavoredItems SET Value = 15 WHERE ListType = 'CultureVictoryPseudoYields' AND Item LIKE 'PSEUDOYIELD_GREATWORK_%'; -- def. 10
UPDATE AiFavoredItems SET Value = 35 WHERE ListType = 'CultureVictoryPseudoYields' AND Item = 'PSEUDOYIELD_TOURISM'; -- def. 25

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('CultureVictoryYields', 'YIELD_GOLD', 1, -10),
('CultureVictoryYields', 'YIELD_SCIENCE', 1, -10),
('CultureVictoryPseudoYields', 'PSEUDOYIELD_CITY_BASE', 1, -100), -- base 350
('CultureVictoryPseudoYields', 'PSEUDOYIELD_CITY_DEFENSES', 1, 25), -- base 300
('CultureVictoryPseudoYields', 'PSEUDOYIELD_CITY_DEFENDING_UNITS', 1, 25), -- base 80
('CultureVictoryPseudoYields', 'PSEUDOYIELD_DIPLOMATIC_BONUS', 1, 15), -- base 0.25
--('CultureVictoryPseudoYields', 'PSEUDOYIELD_CIVIC', 1, 100), -- see explaination above
--('CultureVictoryPseudoYields', 'PSEUDOYIELD_TECHNOLOGY', 1, -100), -- base 5
('CultureVictoryPseudoYields', 'PSEUDOYIELD_SPACE_RACE', 1, -50), -- base 50
('CultureVictoryPseudoYields', 'PSEUDOYIELD_HAPPINESS', 1, 10),
('CultureVictoryPseudoYields', 'PSEUDOYIELD_WONDER', 1, 50), -- base 0.8
('CultureVictoryPseudoYields', 'PSEUDOYIELD_UNIT_ARCHAEOLOGIST', 1, 50); -- base 4

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
('CultureVictoryTechs', 'TECH_PRINTING', 1, 0), -- !BUGGED!
('CultureVictoryTechs', 'TECH_RADIO', 1, 0), -- !BUGGED!
('CultureVictoryTechs', 'TECH_COMPUTERS', 1, 0), -- !BUGGED!
('CultureVictoryCivics', 'CIVIC_DRAMA_POETRY', 1, 0),
('CultureVictoryCivics', 'CIVIC_HUMANISM', 1, 0),
('CultureVictoryCivics', 'CIVIC_OPERA_BALLET', 1, 0),
('CultureVictoryCivics', 'CIVIC_NATURAL_HISTORY', 1, 0),
('CultureVictoryCivics', 'CIVIC_MASS_MEDIA', 1, 0),
('CultureVictoryCivics', 'CIVIC_CULTURAL_HERITAGE', 1, 0),
('CultureVictoryCivics', 'CIVIC_SOCIAL_MEDIA', 1, 0),
('CultureVictoryCivics', 'CIVIC_SUFFRAGE', 1, 0), -- Democracy, yes
('CultureVictoryCivics', 'CIVIC_TOTALITARIANISM', 0, 0), -- Fascism, no -- probably doesn't work
('CultureVictoryCivics', 'CIVIC_CLASS_STRUGGLE', 0, 0), -- Communism, no -- probably doesn't work
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

UPDATE AiFavoredItems SET Value = 35 WHERE ListType = 'ScienceVictoryYields' AND Item = 'YIELD_SCIENCE'; -- def. 50

UPDATE AiFavoredItems SET Value =  35 WHERE ListType = 'ScienceVictoryPseudoYields' AND Item = 'PSEUDOYIELD_GPP_SCIENTIST'; -- base 1.0
--UPDATE AiFavoredItems SET Value = 100 WHERE ListType = 'ScienceVictoryPseudoYields' AND Item = 'PSEUDOYIELD_TECHNOLOGY'; -- def 25

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('ScienceVictoryYields', 'YIELD_FAITH', 1, -20),
('ScienceVictoryYields', 'YIELD_CULTURE', 1, -10),
('ScienceVictoryPseudoYields', 'PSEUDOYIELD_CITY_BASE', 1, -50), -- base 350
('ScienceVictoryPseudoYields', 'PSEUDOYIELD_CITY_DEFENSES', 1, -10), -- base 300 -10%
('ScienceVictoryPseudoYields', 'PSEUDOYIELD_CITY_DEFENDING_UNITS', 1, -15), -- base 100 -10%
--('ScienceVictoryPseudoYields', 'PSEUDOYIELD_CIVIC', 1, -100), -- see explanation above
('ScienceVictoryPseudoYields', 'PSEUDOYIELD_GPP_ENGINEER', 1, 20), -- need for infra
('ScienceVictoryPseudoYields', 'PSEUDOYIELD_GPP_PROPHET', 1, -25), -- base 0.8
('ScienceVictoryPseudoYields', 'PSEUDOYIELD_TOURISM', 1, -10), -- base 1
('ScienceVictoryPseudoYields', 'PSEUDOYIELD_UNIT_ARCHAEOLOGIST', 1, -50), -- base 4
('ScienceVictoryTechs', 'TECH_WRITING', 1, 0), -- !BUGGED!
('ScienceVictoryTechs', 'TECH_EDUCATION', 1, 0), -- !BUGGED!
('ScienceVictoryTechs', 'TECH_CHEMISTRY', 1, 0); -- !BUGGED!

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
('ScienceVictoryCivics', 'CIVIC_SUFFRAGE', 0, 0), -- Democracy, no -- probably doesn't work
('ScienceVictoryCivics', 'CIVIC_TOTALITARIANISM', 0, 0), -- Fascism, no -- probably doesn't work
('ScienceVictoryCivics', 'CIVIC_CLASS_STRUGGLE', 1, 0), -- Communism, yes
('ScienceVictoryWonders', 'BUILDING_GREAT_LIBRARY', 1, 0),
('ScienceVictoryWonders', 'BUILDING_OXFORD_UNIVERSITY', 1, 0),
('ScienceVictoryWonders', 'BUILDING_RUHR_VALLEY', 1, 0);

-- Rise & Fall
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value)
SELECT 'ScienceVictoryWonders', 'BUILDING_AMUNDSEN_SCOTT_RESEARCH_STATION', 1, 0
FROM Types WHERE Type = 'BUILDING_AMUNDSEN_SCOTT_RESEARCH_STATION';


-- ===========================================================================
-- VICTORY_STRATEGY_RELIGIOUS_VICTORY
--ReligiousVictoryFavoredCommemorations
--ReligiousVictoryBehaviors
-- ===========================================================================

UPDATE AiFavoredItems SET Value = 40 WHERE ListType = 'ReligiousVictoryYields' AND Item = 'YIELD_FAITH'; -- def. 75

UPDATE AiFavoredItems SET Value = 50 WHERE ListType = 'ReligiousVictoryPseudoYields' AND Item = 'PSEUDOYIELD_GPP_PROPHET'; -- base 0.8

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('ReligiousVictoryYields', 'YIELD_GOLD', 1, -10),
('ReligiousVictoryYields', 'YIELD_SCIENCE', 1, -10),
('ReligiousVictoryDiplomacy',    'DIPLOACTION_ALLIANCE_RELIGIOUS', 1, 0),
('ReligiousVictoryDiplomacy',    'DIPLOACTION_ALLIANCE_RELIGIOUS', 1, 0),
('ReligiousVictoryDiplomacy',    'DIPLOACTION_DECLARE_HOLY_WAR', 1, 0),
('ReligiousVictoryPseudoYields', 'PSEUDOYIELD_SPACE_RACE', 1, -50), -- base 100
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
('ReligiousVictoryTechs', 'TECH_ASTROLOGY', 1, 0), -- !BUGGED!
('ReligiousVictoryTechs', 'TECH_NUCLEAR_FISSION', 1, 0), -- !BUGGED!
('ReligiousVictoryTechs', 'TECH_NUCLEAR_FUSION', 1, 0), -- !BUGGED!
('ReligiousVictoryCivics', 'CIVIC_MYSTICISM', 1, 0),
('ReligiousVictoryCivics', 'CIVIC_THEOLOGY', 1, 0),
('ReligiousVictoryCivics', 'CIVIC_REFORMED_CHURCH', 1, 0),
-- we should stay with Theocracy, but probably won't be possible?
('ReligiousVictoryCivics', 'CIVIC_SUFFRAGE', 0, 0), -- Democracy, no  -- probably doesn't work
('ReligiousVictoryCivics', 'CIVIC_TOTALITARIANISM', 0, 0), -- Fascism, no  -- probably doesn't work
('ReligiousVictoryCivics', 'CIVIC_CLASS_STRUGGLE', 0, 0), -- Communism, no  -- probably doesn't work
('ReligiousVictoryWonders', 'BUILDING_HAGIA_SOPHIA', 1, 0),
('ReligiousVictoryWonders', 'BUILDING_STONEHENGE', 1, 0),
('ReligiousVictoryWonders', 'BUILDING_MAHABODHI_TEMPLE', 1, 0),
('ReligiousVictoryUnits', 'UNIT_MISSIONARY', 1, 25),
('ReligiousVictoryUnits', 'UNIT_APOSTLE', 1, 25),
('ReligiousVictoryUnits', 'UNIT_NATURALIST', 1, -25);
--('ReligiousVictoryUnits', 'UNIT_INQUISITOR', 1, -10);


-- ===========================================================================
-- VICTORY_STRATEGY_MILITARY_VICTORY
--MilitaryVictoryFavoredCommemorations
--MilitaryVictoryOperations
-- ===========================================================================

UPDATE AiFavoredItems SET Value = 20 WHERE ListType = 'MilitaryVictoryYields' AND Item = 'YIELD_PRODUCTION'; -- def. 25 -- will get more if at war

UPDATE AiFavoredItems SET Value = 20 WHERE ListType = 'MilitaryVictoryPseudoYields' AND Item = 'PSEUDOYIELD_NUCLEAR_WEAPON'; -- def. 25
--UPDATE AiFavoredItems SET Value = 25 WHERE ListType = 'MilitaryVictoryPseudoYields' AND Item = 'PSEUDOYIELD_UNIT_AIR_COMBAT'; -- def. 25
--UPDATE AiFavoredItems SET Value = 25 WHERE ListType = 'MilitaryVictoryPseudoYields' AND Item = 'PSEUDOYIELD_UNIT_COMBAT'; -- def. 25
UPDATE AiFavoredItems SET Value = 15 WHERE ListType = 'MilitaryVictoryPseudoYields' AND Item = 'PSEUDOYIELD_UNIT_NAVAL_COMBAT'; -- def. 25 -- leave it for Naval strategies
--UPDATE AiFavoredItems SET Value = 150 WHERE ListType = 'MilitaryVictoryPseudoYields' AND Item = 'PSEUDOYIELD_CITY_ORIGINAL_CAPITAL'; -- def. 100
UPDATE AiFavoredItems SET Value = -50 WHERE ListType = 'MilitaryVictoryPseudoYields' AND Item = 'PSEUDOYIELD_CITY_DEFENSES'; -- def. -25
UPDATE AiFavoredItems SET Value = -25 WHERE ListType = 'MilitaryVictoryPseudoYields' AND Item = 'PSEUDOYIELD_DIPLOMATIC_BONUS'; -- def. -50

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('MilitaryVictoryYields', 'YIELD_SCIENCE', 1,  5),
('MilitaryVictoryYields', 'YIELD_CULTURE', 1, -5),
('MilitaryVictoryYields', 'YIELD_FAITH',   1,-15),
('MilitaryVictoryPseudoYields', 'PSEUDOYIELD_CITY_BASE', 1, 100), -- +100%
('MilitaryVictoryPseudoYields', 'PSEUDOYIELD_CITY_POPULATION', 1, 50), -- base 50 +50%
('MilitaryVictoryPseudoYields', 'PSEUDOYIELD_CITY_DEFENSES', 1, -25), -- -25% - this is quite a lot, should trigger more wars
('MilitaryVictoryPseudoYields', 'PSEUDOYIELD_CITY_DEFENDING_UNITS', 1, -20), -- base 80, -20%
('MilitaryVictoryPseudoYields', 'PSEUDOYIELD_SPACE_RACE', 1, -25), -- base 100, leave that as an option
('MilitaryVictoryPseudoYields', 'PSEUDOYIELD_CLEAR_BANDIT_CAMPS', 1, 15), -- base 1.5, agenda lover uses +5%
('MilitaryVictoryPseudoYields', 'PSEUDOYIELD_GPP_SCIENTIST', 1, 10), -- base 0.7
('MilitaryVictoryPseudoYields', 'PSEUDOYIELD_GPP_PROPHET', 1, -25), -- base 0.8
('MilitaryVictoryPseudoYields', 'PSEUDOYIELD_GPP_ADMIRAL', 1, 10), -- base 0.5
('MilitaryVictoryPseudoYields', 'PSEUDOYIELD_GPP_GENERAL', 1, 20), -- base 0.6
('MilitaryVictoryPseudoYields', 'PSEUDOYIELD_TOURISM', 1, -50), -- base 1
--('MilitaryVictoryPseudoYields', 'PSEUDOYIELD_TECHNOLOGY', 1, 50), -- base 5
('MilitaryVictoryPseudoYields', 'PSEUDOYIELD_STANDING_ARMY_NUMBER', 1, 15), -- def. 1
('MilitaryVictoryPseudoYields', 'PSEUDOYIELD_STANDING_ARMY_VALUE', 1, 25), -- def. 0.1
('MilitaryVictoryPseudoYields', 'PSEUDOYIELD_UNIT_ARCHAEOLOGIST', 1, -50), -- base 4
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
('MilitaryVictoryTechs', 'TECH_BRONZE_WORKING', 1, 0), -- !BUGGED!
('MilitaryVictoryTechs', 'TECH_STIRRUPS', 1, 0), -- !BUGGED!
('MilitaryVictoryTechs', 'TECH_MILITARY_ENGINEERING', 1, 0), -- !BUGGED!
('MilitaryVictoryTechs', 'TECH_GUNPOWDER', 1, 0), -- !BUGGED!
('MilitaryVictoryTechs', 'TECH_MILITARY_SCIENCE', 1, 0), -- !BUGGED!
('MilitaryVictoryTechs', 'TECH_COMBUSTION', 1, 0), -- !BUGGED!
('MilitaryVictoryTechs', 'TECH_NUCLEAR_FISSION', 1, 0), -- !BUGGED!
('MilitaryVictoryTechs', 'TECH_NUCLEAR_FUSION', 1, 0), -- !BUGGED!
('MilitaryVictoryCivics', 'CIVIC_MILITARY_TRADITION', 1, 0),
('MilitaryVictoryCivics', 'CIVIC_MILITARY_TRAINING', 1, 0),
('MilitaryVictoryCivics', 'CIVIC_MERCENARIES', 1, 0),
('MilitaryVictoryCivics', 'CIVIC_NATIONALISM', 1, 0),
('MilitaryVictoryCivics', 'CIVIC_MOBILIZATION', 1, 0),
('MilitaryVictoryCivics', 'CIVIC_RAPID_DEPLOYMENT', 1, 0),
('MilitaryVictoryCivics', 'CIVIC_SUFFRAGE', 0, 0), -- Democracy, no -- probably doesn't work
('MilitaryVictoryCivics', 'CIVIC_TOTALITARIANISM', 1, 0), -- Fascism, yes
('MilitaryVictoryCivics', 'CIVIC_CLASS_STRUGGLE', 0, 0), -- Communism, no -- probably doesn't work
('MilitaryVictoryWonders', 'BUILDING_TERRACOTTA_ARMY', 1, 0),
('MilitaryVictoryWonders', 'BUILDING_ALHAMBRA', 1, 0),
('MilitaryVictoryProjects', 'PROJECT_MANHATTAN_PROJECT', 1, 0),
('MilitaryVictoryProjects', 'PROJECT_OPERATION_IVY', 1, 0),
('MilitaryVictoryProjects', 'PROJECT_BUILD_NUCLEAR_DEVICE', 1, 0),
('MilitaryVictoryProjects', 'PROJECT_BUILD_THERMONUCLEAR_DEVICE', 1, 0),
('MilitaryVictoryUnitBuilds', 'PROMOTION_CLASS_AIR_BOMBER', 1, 15),
('MilitaryVictoryUnitBuilds', 'PROMOTION_CLASS_HEAVY_CAVALRY', 1, 15),
('MilitaryVictoryUnitBuilds', 'PROMOTION_CLASS_SIEGE', 1, 15);


-- ===========================================================================
-- TIME STRATEGIES - they are CUMULATIVE
-- ===========================================================================

-- iOS compatibility
-- 4 AiLists where added in later versions of the game

INSERT OR REPLACE INTO AiListTypes (ListType) VALUES
('ClassicalPseudoYields'),
('MedievalPseudoYields'),
('RenaissancePseudoYields'),
('IndustrialPseudoYields');
INSERT OR REPLACE INTO AiLists (ListType, System) VALUES
('ClassicalPseudoYields',   'PseudoYields'),
('MedievalPseudoYields',    'PseudoYields'),
('RenaissancePseudoYields', 'PseudoYields'),
('IndustrialPseudoYields',  'PseudoYields');
INSERT OR REPLACE INTO Strategy_Priorities (StrategyType, ListType) VALUES
('STRATEGY_CLASSICAL_CHANGES',   'ClassicalPseudoYields'),
('STRATEGY_MEDIEVAL_CHANGES',    'MedievalPseudoYields'),
('STRATEGY_RENAISSANCE_CHANGES', 'RenaissancePseudoYields'),
('STRATEGY_INDUSTRIAL_CHANGES',  'IndustrialPseudoYields');


-- fix
INSERT OR REPLACE INTO Strategy_Priorities (StrategyType, ListType) VALUES ('STRATEGY_MEDIEVAL_CHANGES', 'MedievalSettlements');


INSERT OR REPLACE INTO Types (Type, Kind) VALUES
('STRATEGY_ATOMIC_CHANGES',      'KIND_VICTORY_STRATEGY'), -- chances are, it will be added in GS
('STRATEGY_INFORMATION_CHANGES', 'KIND_VICTORY_STRATEGY');

INSERT OR REPLACE INTO Strategies (StrategyType, VictoryType, NumConditionsNeeded) VALUES
('STRATEGY_ATOMIC_CHANGES',      NULL, 1),
('STRATEGY_INFORMATION_CHANGES', NULL, 1);

-- not for minors
INSERT OR REPLACE INTO StrategyConditions (StrategyType, ConditionFunction, Disqualifier) VALUES
('STRATEGY_ATOMIC_CHANGES',      'Is Not Major', 1),
('STRATEGY_INFORMATION_CHANGES', 'Is Not Major', 1);

INSERT INTO StrategyConditions (StrategyType, ConditionFunction, StringValue, ThresholdValue) VALUES
('STRATEGY_ATOMIC_CHANGES',      'Is Atomic',      NULL, 0), -- need to test
('STRATEGY_INFORMATION_CHANGES', 'Is Information', NULL, 0); -- need to test

INSERT OR REPLACE INTO AiListTypes (ListType) VALUES
('ModernPseudoYields'),
('AtomicYields'),
('AtomicPseudoYields'),
('InformationYields'),
('InformationPseudoYields');
INSERT OR REPLACE INTO AiLists (ListType, System) VALUES
('ModernPseudoYields', 'PseudoYields'),
('AtomicYields',       'Yields'),
('AtomicPseudoYields', 'PseudoYields'),
('InformationYields',       'Yields'),
('InformationPseudoYields', 'PseudoYields');
INSERT OR REPLACE INTO Strategy_Priorities (StrategyType, ListType) VALUES
('STRATEGY_MODERN_CHANGES', 'ModernPseudoYields'),
('STRATEGY_ATOMIC_CHANGES', 'AtomicYields'),
('STRATEGY_ATOMIC_CHANGES', 'AtomicPseudoYields'),
('STRATEGY_INFORMATION_CHANGES', 'InformationYields'),
('STRATEGY_INFORMATION_CHANGES', 'InformationPseudoYields');

-- easier to recreate those than do updates...
DELETE FROM AiFavoredItems WHERE ListType IN (
--'ClassicalSensitivity',
'ClassicalPseudoYields',
'ClassicalYields',
--'MedievalSensitivity',
'MedievalPseudoYields',
'MedievalYields',
'RenaissancePseudoYields',
'RenaissanceYields',
'IndustrialPseudoYields',
'IndustrialYields',
--'ModernSensitivity',
'ModernYields');

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
-- CLASSICAL
--('ClassicalSensitivity', 'YIELD_SCIENCE', 1, 10),
('ClassicalYields', 'YIELD_CULTURE',  1, 15),
('ClassicalYields', 'YIELD_FAITH', 1, 10),
('ClassicalYields', 'YIELD_FOOD',  1, 10),
('ClassicalYields', 'YIELD_GOLD',  1, 15),
('ClassicalPseudoYields', 'PSEUDOYIELD_CITY_BASE', 1, 25),
('ClassicalPseudoYields', 'PSEUDOYIELD_CITY_POPULATION', 1, 15),
('ClassicalPseudoYields', 'PSEUDOYIELD_CITY_DEFENSES', 1, -10),
('ClassicalPseudoYields', 'PSEUDOYIELD_GPP_MERCHANT', 1, 10),
('ClassicalPseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, -10),
-- MEDIEVAL
--('MedievalSensitivity',	'YIELD_CULTURE', 1, 10),
('MedievalYields', 'YIELD_CULTURE',    1,-15),
('MedievalYields', 'YIELD_FAITH',      1, 20),
('MedievalYields', 'YIELD_FOOD',       1, 20),
('MedievalYields', 'YIELD_GOLD',       1,-10),
('MedievalYields', 'YIELD_PRODUCTION', 1, 10),
('MedievalYields', 'YIELD_SCIENCE',    1,-10),
('MedievalPseudoYields', 'PSEUDOYIELD_CITY_BASE', 1, 50),
('MedievalPseudoYields', 'PSEUDOYIELD_CITY_POPULATION', 1, 25),
('MedievalPseudoYields', 'PSEUDOYIELD_CITY_DEFENSES', 1, -10),
('MedievalPseudoYields', 'PSEUDOYIELD_GPP_ENGINEER', 1, 10),
('MedievalPseudoYields', 'PSEUDOYIELD_GPP_MERCHANT', 1, 10),
('MedievalPseudoYields', 'PSEUDOYIELD_GPP_SCIENTIST', 1, -15),
('MedievalPseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, -10),
('MedievalPseudoYields', 'PSEUDOYIELD_UNIT_SETTLER', 1, -15),
-- RENAISSANCE
('RenaissanceYields', 'YIELD_CULTURE',    1, 15),
('RenaissanceYields', 'YIELD_FAITH',      1,-20),
('RenaissanceYields', 'YIELD_FOOD',       1,-15),
('RenaissanceYields', 'YIELD_GOLD',       1, 10),
('RenaissanceYields', 'YIELD_PRODUCTION', 1,-10),
('RenaissanceYields', 'YIELD_SCIENCE',    1, 10),
('RenaissancePseudoYields', 'PSEUDOYIELD_CITY_BASE', 1, -50),
('RenaissancePseudoYields', 'PSEUDOYIELD_CITY_POPULATION', 1, -25),
('RenaissancePseudoYields', 'PSEUDOYIELD_CITY_DEFENSES', 1, 25),
('RenaissancePseudoYields', 'PSEUDOYIELD_GPP_ARTIST', 1, 10),
('RenaissancePseudoYields', 'PSEUDOYIELD_GPP_ENGINEER', 1, 10),
('RenaissancePseudoYields', 'PSEUDOYIELD_GPP_PROPHET', 1, -100),
('RenaissancePseudoYields', 'PSEUDOYIELD_GPP_SCIENTIST', 1, 20),
('RenaissancePseudoYields', 'PSEUDOYIELD_GPP_WRITER', 1, 10),
('RenaissancePseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, -10),
('RenaissancePseudoYields', 'PSEUDOYIELD_UNIT_NAVAL_COMBAT', 1, 15), -- exploration time
-- INDUSTRIAL
('IndustrialYields', 'YIELD_CULTURE',	1, -10),
('IndustrialYields', 'YIELD_FAITH',	1, -10),
('IndustrialYields', 'YIELD_GOLD',	1, -10),
('IndustrialYields', 'YIELD_PRODUCTION', 1, 20),
('IndustrialPseudoYields', 'PSEUDOYIELD_CITY_BASE', 1, 50),
('IndustrialPseudoYields', 'PSEUDOYIELD_CITY_POPULATION', 1, 15),
('IndustrialPseudoYields', 'PSEUDOYIELD_CITY_DEFENSES', 1, -15),
('IndustrialPseudoYields', 'PSEUDOYIELD_GPP_MERCHANT', 1, -15),
('IndustrialPseudoYields', 'PSEUDOYIELD_GPP_ENGINEER', 1, 20),
('IndustrialPseudoYields', 'PSEUDOYIELD_GPP_SCIENTIST', 1, 10),
('IndustrialPseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, -10),
('IndustrialPseudoYields', 'PSEUDOYIELD_UNIT_NAVAL_COMBAT', 1, 10),
('IndustrialPseudoYields', 'PSEUDOYIELD_UNIT_SETTLER', 1, -15),
-- MODERN
--('ModernSensitivity', 'YIELD_CULTURE', 1, 10),
--('ModernSensitivity', 'YIELD_SCIENCE', 1, 10),
('ModernYields', 'YIELD_CULTURE', 1, 10),
('ModernYields', 'YIELD_FOOD', 1, 10),
('ModernYields', 'YIELD_GOLD', 1, 10),
('ModernPseudoYields', 'PSEUDOYIELD_GPP_ENGINEER', 1, -15),
('ModernPseudoYields', 'PSEUDOYIELD_CITY_BASE', 1, 50), -- incenvite for ideological wars
('ModernPseudoYields', 'PSEUDOYIELD_CITY_POPULATION', 1, 25),
('ModernPseudoYields', 'PSEUDOYIELD_CITY_DEFENSES', 1, -10),
('ModernPseudoYields', 'PSEUDOYIELD_UNIT_NAVAL_COMBAT', 1, -15),
('ModernPseudoYields', 'PSEUDOYIELD_STANDING_ARMY_NUMBER', 1, 10), -- incenvite for ideological wars
('ModernPseudoYields', 'PSEUDOYIELD_STANDING_ARMY_VALUE', 1, 20),
('ModernPseudoYields', 'PSEUDOYIELD_UNIT_SETTLER', 1, -15),
-- ATOMIC
('AtomicYields', 'YIELD_FOOD', 1, -10),
('AtomicYields', 'YIELD_SCIENCE', 1, 15),
('AtomicYields', 'YIELD_PRODUCTION', 1, 10),
('AtomicPseudoYields', 'PSEUDOYIELD_GPP_SCIENTIST', 1, 10),
('AtomicPseudoYields', 'PSEUDOYIELD_CITY_BASE', 1, 50),
('AtomicPseudoYields', 'PSEUDOYIELD_CITY_POPULATION', 1, 15),
('AtomicPseudoYields', 'PSEUDOYIELD_CITY_DEFENSES', 1, -10),
--('AtomicPseudoYields', 'PSEUDOYIELD_UNIT_NAVAL_COMBAT', 1, -15),
('AtomicPseudoYields', 'PSEUDOYIELD_UNIT_AIR_COMBAT', 1, 25),
('AtomicPseudoYields', 'PSEUDOYIELD_UNIT_SETTLER', 1, -15),
-- INFORMATION
('InformationYields', 'YIELD_CULTURE', 1, -15),
('InformationYields', 'YIELD_FAITH', 1, -25),
('InformationYields', 'YIELD_FOOD', 1, -25), -- no need for bigger cities at that time
('InformationYields', 'YIELD_GOLD', 1, 15),
--('InformationYields', 'YIELD_SCIENCE', 1, -15),
('InformationPseudoYields', 'PSEUDOYIELD_CITY_BASE', 1, -100),
('InformationPseudoYields', 'PSEUDOYIELD_CITY_POPULATION', 1, -25),
('InformationPseudoYields', 'PSEUDOYIELD_CITY_DEFENSES', 1, 50),
('InformationPseudoYields', 'PSEUDOYIELD_STANDING_ARMY_NUMBER', 1, -20), -- peace time!
('InformationPseudoYields', 'PSEUDOYIELD_STANDING_ARMY_VALUE', 1, -40),
('InformationPseudoYields', 'PSEUDOYIELD_UNIT_NAVAL_COMBAT', 1, -15),
('InformationPseudoYields', 'PSEUDOYIELD_UNIT_AIR_COMBAT', 1, 25),
('InformationPseudoYields', 'PSEUDOYIELD_UNIT_SETTLER', 1, -15);


-- ===========================================================================
-- SUPPORTING STRATEGIES
-- ===========================================================================

INSERT INTO Types (Type, Kind) VALUES
('RST_STRATEGY_DEFENSE',  'KIND_VICTORY_STRATEGY'), -- Activates when we are at war and our military is lacking badly
('RST_STRATEGY_CATCHING', 'KIND_VICTORY_STRATEGY'), -- Activates when our military is lacking in comparison to other known civs
('RST_STRATEGY_ENOUGH',   'KIND_VICTORY_STRATEGY'), -- Activates when our military is rocking in comparison to other known civs (prevents from overinvestment into military)
('RST_STRATEGY_PEACE',    'KIND_VICTORY_STRATEGY'), -- Activates when at peace
('RST_STRATEGY_ATWAR',    'KIND_VICTORY_STRATEGY'), -- Activates when at war
('RST_STRATEGY_GWSLOTS',  'KIND_VICTORY_STRATEGY'), -- Activates when we need more slots for Great Works
('RST_STRATEGY_SCIENCE',  'KIND_VICTORY_STRATEGY'), -- Activates when we need more science
('RST_STRATEGY_CULTURE',  'KIND_VICTORY_STRATEGY'); -- Activates when we need more culture

INSERT INTO Strategies (StrategyType, VictoryType, NumConditionsNeeded) VALUES
('RST_STRATEGY_DEFENSE',  NULL, 1),
('RST_STRATEGY_CATCHING', NULL, 1),
('RST_STRATEGY_ENOUGH',   NULL, 1),
('RST_STRATEGY_PEACE',    NULL, 1),
('RST_STRATEGY_ATWAR',    NULL, 1),
('RST_STRATEGY_GWSLOTS',  NULL, 1),
('RST_STRATEGY_SCIENCE',  NULL, 1),
('RST_STRATEGY_CULTURE',  NULL, 1);

-- not for minors
INSERT INTO StrategyConditions (StrategyType, ConditionFunction, Disqualifier) VALUES
('RST_STRATEGY_DEFENSE',  'Is Not Major', 1), -- minors could use it too?
('RST_STRATEGY_CATCHING', 'Is Not Major', 1),
('RST_STRATEGY_ENOUGH',   'Is Not Major', 1),
('RST_STRATEGY_PEACE',    'Is Not Major', 1),
('RST_STRATEGY_ATWAR',    'Is Not Major', 1),
('RST_STRATEGY_GWSLOTS',  'Is Not Major', 1),
('RST_STRATEGY_SCIENCE',  'Is Not Major', 1),
('RST_STRATEGY_CULTURE',  'Is Not Major', 1);

INSERT INTO StrategyConditions (StrategyType, ConditionFunction, StringValue, ThresholdValue) VALUES
('RST_STRATEGY_DEFENSE',  'Call Lua Function', 'ActiveStrategyDefense',  70),
('RST_STRATEGY_CATCHING', 'Call Lua Function', 'ActiveStrategyCatching', 60),
('RST_STRATEGY_ENOUGH',   'Call Lua Function', 'ActiveStrategyEnough',  220),
('RST_STRATEGY_PEACE',    'Call Lua Function', 'ActiveStrategyPeace',     0),
('RST_STRATEGY_ATWAR',    'Call Lua Function', 'ActiveStrategyAtWar',     0),
('RST_STRATEGY_GWSLOTS',  'Call Lua Function', 'ActiveStrategyMoreGreatWorkSlots', 0),
('RST_STRATEGY_SCIENCE',  'Call Lua Function', 'ActiveStrategyMoreScience', 90),
('RST_STRATEGY_CULTURE',  'Call Lua Function', 'ActiveStrategyMoreCulture', 80);


INSERT INTO AiListTypes (ListType) VALUES
('RSTDefenseOperations'),
('RSTDefenseDiplomacy'),
('RSTDefenseTechs'),
('RSTDefenseCivics'),
('RSTDefenseProjects'),
('RSTDefenseYields'),
('RSTDefensePseudoYields'),
('RSTDefenseUnitBuilds'),
('RSTCatchingOperations'),
('RSTCatchingPseudoYields'),
('RSTEnoughPseudoYields'),
('RSTPeaceProjects'),
('RSTPeaceYields'),
('RSTPeacePseudoYields'),
('RSTAtWarYields'),
('RSTAtWarPseudoYields'),
('RSTGWSlotsDistricts'),
('RSTGWSlotsPseudoYields'),
('RSTScienceDistricts'),
('RSTScienceYields'),
('RSTSciencePseudoYields'),
('RSTCultureDistricts'),
('RSTCultureYields'),
('RSTCulturePseudoYields');

INSERT INTO AiLists (ListType, System) VALUES
('RSTDefenseOperations',  'AiOperationTypes'),
('RSTDefenseDiplomacy',   'DiplomaticActions'),
('RSTDefenseTechs',       'Technologies'),
('RSTDefenseCivics',      'Civics'),
('RSTDefenseProjects',    'Projects'),
('RSTDefenseYields',      'Yields'),
('RSTDefensePseudoYields','PseudoYields'),
('RSTDefenseUnitBuilds',  'UnitPromotionClasses'),
('RSTCatchingOperations',  'AiOperationTypes'),
('RSTCatchingPseudoYields','PseudoYields'),
('RSTEnoughPseudoYields', 'PseudoYields'),
('RSTPeaceProjects',      'Projects'),
('RSTPeaceYields',        'Yields'),
('RSTPeacePseudoYields',  'PseudoYields'),
('RSTAtWarYields',        'Yields'),
('RSTAtWarPseudoYields',  'PseudoYields'),
('RSTGWSlotsDistricts',    'Districts'),
('RSTGWSlotsPseudoYields', 'PseudoYields'),
('RSTScienceDistricts',    'Districts'),
('RSTScienceYields',       'Yields'),
('RSTSciencePseudoYields', 'PseudoYields'),
('RSTCultureDistricts',    'Districts'),
('RSTCultureYields',       'Yields'),
('RSTCulturePseudoYields', 'PseudoYields');

INSERT INTO Strategy_Priorities (StrategyType, ListType) VALUES
('RST_STRATEGY_DEFENSE', 'RSTDefenseOperations'),
('RST_STRATEGY_DEFENSE', 'RSTDefenseDiplomacy'),
('RST_STRATEGY_DEFENSE', 'RSTDefenseTechs'),
('RST_STRATEGY_DEFENSE', 'RSTDefenseCivics'),
('RST_STRATEGY_DEFENSE', 'RSTDefenseProjects'),
('RST_STRATEGY_DEFENSE', 'RSTDefenseYields'),
('RST_STRATEGY_DEFENSE', 'RSTDefensePseudoYields'),
('RST_STRATEGY_DEFENSE', 'RSTDefenseUnitBuilds'),
('RST_STRATEGY_CATCHING', 'RSTCatchingOperations'),
('RST_STRATEGY_CATCHING', 'RSTCatchingPseudoYields'),
('RST_STRATEGY_ENOUGH', 'RSTEnoughPseudoYields'),
('RST_STRATEGY_PEACE', 'RSTPeaceProjects'),
('RST_STRATEGY_PEACE', 'RSTPeaceYields'),
('RST_STRATEGY_PEACE', 'RSTPeacePseudoYields'),
('RST_STRATEGY_ATWAR', 'RSTAtWarYields'),
('RST_STRATEGY_ATWAR', 'RSTAtWarPseudoYields'),
('RST_STRATEGY_GWSLOTS', 'RSTGWSlotsDistricts'),
('RST_STRATEGY_GWSLOTS', 'RSTGWSlotsPseudoYields'),
('RST_STRATEGY_SCIENCE', 'RSTScienceDistricts'),
('RST_STRATEGY_SCIENCE', 'RSTScienceYields'),
('RST_STRATEGY_SCIENCE', 'RSTSciencePseudoYields'),
('RST_STRATEGY_CULTURE', 'RSTCultureDistricts'),
('RST_STRATEGY_CULTURE', 'RSTCultureYields'),
('RST_STRATEGY_CULTURE', 'RSTCulturePseudoYields');

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
-- Defense
('RSTDefenseOperations', 'CITY_ASSAULT', 1, -2), -- don't attack anybody
('RSTDefenseOperations', 'OP_DEFENSE', 1, 2), -- strengthen defenses
('RSTDefenseDiplomacy', 'DIPLOACTION_ALLIANCE', 1, 0),
('RSTDefenseDiplomacy', 'DIPLOACTION_ALLIANCE_MILITARY', 1, 0),
('RSTDefenseTechs', 'TECH_MASONRY', 1, 0), -- !BUGGED!
('RSTDefenseTechs', 'TECH_CASTLES', 1, 0), -- !BUGGED!
('RSTDefenseTechs', 'TECH_SIEGE_TACTICS', 1, 0), -- !BUGGED!
('RSTDefenseCivics', 'CIVIC_DEFENSIVE_TACTICS', 1, 0),
('RSTDefenseCivics', 'CIVIC_NATIONALISM', 1, 0),
('RSTDefenseCivics', 'CIVIC_MOBILIZATION', 1, 0),
('RSTDefenseProjects', 'PROJECT_REPAIR_OUTER_DEFENSES', 1, 0),
('RSTDefenseYields', 'YIELD_PRODUCTION', 1, 25), -- produce units
('RSTDefenseYields', 'YIELD_GOLD', 1, 25), -- or buy
('RSTDefenseYields', 'YIELD_CULTURE', 1, -15),
('RSTDefenseYields', 'YIELD_SCIENCE', 1, -15),
('RSTDefenseYields', 'YIELD_FAITH', 1, -15),
('RSTDefensePseudoYields', 'PSEUDOYIELD_CITY_BASE', 1, -100), -- don't attack anybody
('RSTDefensePseudoYields', 'PSEUDOYIELD_CITY_DEFENDING_UNITS', 1, 100), -- don't attack anybody
('RSTDefensePseudoYields', 'PSEUDOYIELD_CITY_DEFENSES', 1, 100), -- don't attack anybody
('RSTDefensePseudoYields', 'PSEUDOYIELD_CITY_ORIGINAL_CAPITAL', 1, -100), -- don't attack anybody
('RSTDefensePseudoYields', 'PSEUDOYIELD_UNIT_COMBAT', 1, 50),
('RSTDefensePseudoYields', 'PSEUDOYIELD_UNIT_AIR_COMBAT', 1, 25), -- until AI lears how to attack, these are not needed???
('RSTDefensePseudoYields', 'PSEUDOYIELD_UNIT_NAVAL_COMBAT', 1, -25), -- chances are that land units are more needed
('RSTDefensePseudoYields', 'PSEUDOYIELD_STANDING_ARMY_NUMBER', 1, 10),
('RSTDefensePseudoYields', 'PSEUDOYIELD_STANDING_ARMY_VALUE', 1, 20),
('RSTDefensePseudoYields', 'PSEUDOYIELD_WONDER', 1, -100), -- these cost too much
('RSTDefensePseudoYields', 'PSEUDOYIELD_UNIT_ARCHAEOLOGIST', 1, -100), -- these cost too much
('RSTDefensePseudoYields', 'PSEUDOYIELD_DISTRICT', 1, -100), -- no districts
('RSTDefensePseudoYields', 'PSEUDOYIELD_HAPPINESS', 1, -100), -- no zoos, etc.
('RSTDefensePseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, -100), -- no builders
('RSTDefensePseudoYields', 'PSEUDOYIELD_TOURISM', 1, -100), -- base 1
--('RSTDefensePseudoYields', 'PSEUDOYIELD_UNIT_SETTLER', 1, 25), -- we might need him! - without a settle spot there is no use
('RSTDefenseUnitBuilds', 'PROMOTION_CLASS_AIR_BOMBER', 1, -25),
('RSTDefenseUnitBuilds', 'PROMOTION_CLASS_AIR_FIGHTER', 1, 15),
('RSTDefenseUnitBuilds', 'PROMOTION_CLASS_ANTI_CAVALRY', 1, 15),
('RSTDefenseUnitBuilds', 'PROMOTION_CLASS_HEAVY_CAVALRY', 1, -25),
('RSTDefenseUnitBuilds', 'PROMOTION_CLASS_LIGHT_CAVALRY', 1, 15),
('RSTDefenseUnitBuilds', 'PROMOTION_CLASS_MELEE', 1, 15),
('RSTDefenseUnitBuilds', 'PROMOTION_CLASS_RANGED', 1, 15),
('RSTDefenseUnitBuilds', 'PROMOTION_CLASS_SIEGE', 1, -100),
('RSTDefenseUnitBuilds', 'PROMOTION_CLASS_SUPPORT', 1, -100), -- ex. Anti-Air Gun and SAM, if AI will come with Bombers
-- Catching Up
('RSTCatchingOperations', 'CITY_ASSAULT', 1, -1), -- don't attack anybody
('RSTCatchingOperations', 'OP_DEFENSE', 1, 1), -- strengthen defenses
('RSTCatchingPseudoYields', 'PSEUDOYIELD_CITY_BASE', 1, -100), -- don't attack anybody
('RSTCatchingPseudoYields', 'PSEUDOYIELD_CITY_DEFENDING_UNITS', 1, 50), -- don't attack anybody
('RSTCatchingPseudoYields', 'PSEUDOYIELD_CITY_DEFENSES', 1, 50), -- don't attack anybody
('RSTCatchingPseudoYields', 'PSEUDOYIELD_CITY_ORIGINAL_CAPITAL', 1, -100), -- don't attack anybody
('RSTCatchingPseudoYields', 'PSEUDOYIELD_UNIT_COMBAT', 1, 25),
('RSTCatchingPseudoYields', 'PSEUDOYIELD_UNIT_AIR_COMBAT', 1, 25),
('RSTCatchingPseudoYields', 'PSEUDOYIELD_UNIT_NAVAL_COMBAT', 1, 25),
('RSTCatchingPseudoYields', 'PSEUDOYIELD_STANDING_ARMY_NUMBER', 1, 15),
('RSTCatchingPseudoYields', 'PSEUDOYIELD_STANDING_ARMY_VALUE', 1, 25),
('RSTCatchingPseudoYields', 'PSEUDOYIELD_WONDER', 1, -50), -- slow down
('RSTCatchingPseudoYields', 'PSEUDOYIELD_UNIT_ARCHAEOLOGIST', 1, -50), -- slow down other builds
('RSTCatchingPseudoYields', 'PSEUDOYIELD_DISTRICT', 1, -50), -- slow down
('RSTCatchingPseudoYields', 'PSEUDOYIELD_HAPPINESS', 1, -50), -- slow down
('RSTCatchingPseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, -50), -- slow down
('RSTCatchingPseudoYields', 'PSEUDOYIELD_TOURISM', 1, -10), -- base 1
-- Enough
('RSTEnoughPseudoYields', 'PSEUDOYIELD_CITY_BASE', 1, 100), -- be more bold
('RSTEnoughPseudoYields', 'PSEUDOYIELD_CITY_DEFENDING_UNITS', 1, -25), -- be more bold
('RSTEnoughPseudoYields', 'PSEUDOYIELD_CITY_DEFENSES', 1, -25), -- be more bold
('RSTEnoughPseudoYields', 'PSEUDOYIELD_CITY_ORIGINAL_CAPITAL', 1, 100), -- be more bold
('RSTEnoughPseudoYields', 'PSEUDOYIELD_UNIT_COMBAT', 1, -75), -- opposite of the RSTCatchingPseudoYields
('RSTEnoughPseudoYields', 'PSEUDOYIELD_UNIT_AIR_COMBAT', 1, -75),
('RSTEnoughPseudoYields', 'PSEUDOYIELD_UNIT_NAVAL_COMBAT', 1, -75),
('RSTEnoughPseudoYields', 'PSEUDOYIELD_STANDING_ARMY_NUMBER', 1, -25),
('RSTEnoughPseudoYields', 'PSEUDOYIELD_STANDING_ARMY_VALUE', 1, -50),
-- Peace
('RSTPeaceProjects', 'PROJECT_REPAIR_OUTER_DEFENSES', 1, 0),
('RSTPeaceYields', 'YIELD_CULTURE',    1,   5),
('RSTPeaceYields', 'YIELD_FAITH',      1,   5),
('RSTPeaceYields', 'YIELD_FOOD',       1,  10),
('RSTPeaceYields', 'YIELD_GOLD',       1, -10),
('RSTPeaceYields', 'YIELD_PRODUCTION', 1,  -5),
('RSTPeaceYields', 'YIELD_SCIENCE',    1,  -5),
('RSTPeacePseudoYields', 'PSEUDOYIELD_DISTRICT', 1, 25), -- build infra
('RSTPeacePseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, 25), -- build infra
('RSTPeacePseudoYields', 'PSEUDOYIELD_STANDING_ARMY_NUMBER', 1, -5), -- shrink a bit
('RSTPeacePseudoYields', 'PSEUDOYIELD_STANDING_ARMY_VALUE', 1, -10), -- shrink a bit
('RSTPeacePseudoYields', 'PSEUDOYIELD_TOURISM', 1, 10), -- base 1
('RSTPeacePseudoYields', 'PSEUDOYIELD_UNIT_ARCHAEOLOGIST', 1, 25),
('RSTPeacePseudoYields', 'PSEUDOYIELD_UNIT_COMBAT', 1, -10),
('RSTPeacePseudoYields', 'PSEUDOYIELD_UNIT_NAVAL_COMBAT', 1, -10),
('RSTPeacePseudoYields', 'PSEUDOYIELD_UNIT_SETTLER', 1, 10),
('RSTPeacePseudoYields', 'PSEUDOYIELD_WONDER', 1, 15),
-- At War
('RSTAtWarYields', 'YIELD_CULTURE',    1, -10),
('RSTAtWarYields', 'YIELD_FAITH',      1, -10),
('RSTAtWarYields', 'YIELD_FOOD',       1, -10),
('RSTAtWarYields', 'YIELD_GOLD',       1,  10),
('RSTAtWarYields', 'YIELD_PRODUCTION', 1,  10),
('RSTAtWarYields', 'YIELD_SCIENCE',    1,   5),
('RSTAtWarPseudoYields', 'PSEUDOYIELD_DISTRICT', 1, -50), -- slow down infra
('RSTAtWarPseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, -50), -- slow down infra
('RSTAtWarPseudoYields', 'PSEUDOYIELD_STANDING_ARMY_NUMBER', 1, 5), -- expand
('RSTAtWarPseudoYields', 'PSEUDOYIELD_STANDING_ARMY_VALUE', 1, 10), -- expand
('RSTAtWarPseudoYields', 'PSEUDOYIELD_TOURISM', 1, -20), -- base 1
('RSTAtWarPseudoYields', 'PSEUDOYIELD_UNIT_ARCHAEOLOGIST', 1, -50),
('RSTAtWarPseudoYields', 'PSEUDOYIELD_UNIT_COMBAT', 1, 10),
('RSTAtWarPseudoYields', 'PSEUDOYIELD_UNIT_NAVAL_COMBAT', 1, 10),
('RSTAtWarPseudoYields', 'PSEUDOYIELD_WONDER', 1, -15),
-- More Great Work Slots - it should be a short boost until a Theater is placed
('RSTGWSlotsDistricts', 'DISTRICT_THEATER', 1, 50), -- I don't know if 2nd param works in Districts system, but it won't hurt to set it
('RSTGWSlotsPseudoYields', 'PSEUDOYIELD_GPP_ARTIST', 1, 25),
('RSTGWSlotsPseudoYields', 'PSEUDOYIELD_GPP_MUSICIAN', 1, 25),
('RSTGWSlotsPseudoYields', 'PSEUDOYIELD_GPP_WRITER', 1, 25),
-- More Science
('RSTScienceDistricts', 'DISTRICT_CAMPUS', 1, 0),
('RSTScienceYields', 'YIELD_SCIENCE',    1, 25),
--('RSTSciencePseudoYields', 'PSEUDOYIELD_TECHNOLOGY', 1, 25),
('RSTScienceYields', 'PSEUDOYIELD_GPP_SCIENTIST', 1, 25),
-- More Culture
('RSTCultureDistricts', 'DISTRICT_THEATER', 1, 0),
('RSTCultureYields', 'YIELD_CULTURE', 1, 25),
--('RSTCulturePseudoYields', 'PSEUDOYIELD_CIVIC', 1, 25), -- see explanation above
('RSTCulturePseudoYields', 'PSEUDOYIELD_GPP_ARTIST', 1, 15),
('RSTCulturePseudoYields', 'PSEUDOYIELD_GPP_MUSICIAN', 1, 15),
('RSTCulturePseudoYields', 'PSEUDOYIELD_GPP_WRITER', 1, 15);



-- ===========================================================================
-- CHANGES TO EXISTING STRATEGIES
-- ===========================================================================


-- STRATEGY_RAPID_EXPANSION
-- this is actually peace / small war strategy
-- important - it activates only when there is a settle spot

UPDATE AiFavoredItems SET Value = 8 WHERE ListType = 'ExpansionSettlementPreferences' AND Item = 'Foreign Continent'; -- def. 4
UPDATE AiFavoredItems SET Value = 3 WHERE ListType = 'ExpansionSettlementPreferences' AND Item = 'Nearest Friendly City'; -- def. 6

DELETE FROM AiFavoredItems WHERE ListType = 'ExpansionUnitPreferences'; -- remove old list that resulted in LESS combat units
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('ExpansionUnitPreferences', 'PSEUDOYIELD_UNIT_SETTLER', 1, 20);
