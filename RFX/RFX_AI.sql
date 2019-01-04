--------------------------------------------------------------
-- Real Fixes - AI
-- Author: Infixo
-- 2018-12-10: Separate file for AI changes
--------------------------------------------------------------

-- 2018-05-19 AIRPOWER AI FIX:
--UPDATE PseudoYields SET DefaultValue = 5 WHERE PseudoYieldType="PSEUDOYIELD_UNIT_AIR_COMBAT"; --DefaultValue=2 +50trait=52
--UPDATE AiFavoredItems SET Value = 30 WHERE ListType = "AirpowerLoverAirpowerPreference"; --Value=50 30+22=52


--------------------------------------------------------------
-- 2018-12-22 PlotEvaluations

DELETE FROM AiFavoredItems WHERE ListType = 'StandardSettlePlot';
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value, StringVal) VALUES
('StandardSettlePlot', 'Foreign Continent', 0, -5, NULL), -- def
('StandardSettlePlot', 'Nearest Friendly City', 0, -8, NULL), -- def, be careful - expansion gives +6, naval +4
('StandardSettlePlot', 'Fresh Water', 0, 16, NULL), -- +3
('StandardSettlePlot', 'Coastal', 0, 7, NULL), -- -1
('StandardSettlePlot', 'Total Yield', 0, 1, 'YIELD_PRODUCTION'), -- def
('StandardSettlePlot', 'Inner Ring Yield', 0, 2, 'YIELD_FOOD'), -- +1
('StandardSettlePlot', 'Inner Ring Yield', 0, 2, 'YIELD_PRODUCTION'), -- +1
('StandardSettlePlot', 'Inner Ring Yield', 0, 1, 'YIELD_GOLD'), -- new
('StandardSettlePlot', 'Inner Ring Yield', 0, 1, 'YIELD_SCIENCE'), -- new
('StandardSettlePlot', 'Inner Ring Yield', 0, 1, 'YIELD_CULTURE'), -- new
('StandardSettlePlot', 'Inner Ring Yield', 0, 1, 'YIELD_FAITH'), -- new
('StandardSettlePlot', 'New Resources', 0, 5, NULL), -- +1
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
('StandardSettlePlot', 'Specific Feature', 0, -3, 'FEATURE_ICE'); -- def
-- put Natural Wonders as generally good to be around
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value, StringVal)
SELECT 'StandardSettlePlot', 'Specific Feature', 0, 3, FeatureType -- +1
FROM Features
WHERE NaturalWonder = 1;


--------------------------------------------------------------
-- Settlement preferences

UPDATE AiFavoredItems SET Favored = 0, Value = 10 WHERE ListType = 'LastVikingKingCoastSettlement' AND Item = 'Coastal'; -- Harald, def. 30
UPDATE AiFavoredItems SET Favored = 0, Value = 20 WHERE ListType = 'SettleAllContinents' AND Item = 'Foreign Continent'; -- Victoria, down from 120 (!)
UPDATE AiFavoredItems SET Favored = 0, Value = 20 WHERE ListType = 'PhilipForeignSettlement' AND Item = 'Foreign Continent'; -- Philip II, def. 60

-- Temporary: AI Leader Victoria
-- Remove drive to settle other continents to improve standard settling - see above
--DELETE FROM AiLists WHERE ListType = 'SettleAllContinents' AND AgendaType = 'TRAIT_AGENDA_SUN_NEVER_SETS';


--------------------------------------------------------------
-- Victories - not sure what it does - could be a parameter saying when somebody enters "critical" stage (exclusive) or when the diplo "close to victory" starts working
/*
UPDATE Victories SET CriticalPercentage = 50 WHERE VictoryType = 'VICTORY_SCORE'; -- 110
UPDATE Victories SET CriticalPercentage = 90 WHERE VictoryType = 'VICTORY_DEFAULT'; -- 110
UPDATE Victories SET CriticalPercentage = 80 WHERE VictoryType = 'VICTORY_CONQUEST'; -- 50
UPDATE Victories SET CriticalPercentage = 70 WHERE VictoryType = 'VICTORY_CULTURE'; -- 75
UPDATE Victories SET CriticalPercentage = 60 WHERE VictoryType = 'VICTORY_RELIGIOUS'; -- 80
UPDATE Victories SET CriticalPercentage = 90 WHERE VictoryType = 'VICTORY_TECHNOLOGY'; -- 60
*/

--------------------------------------------------------------
-- Yield biases

--UPDATE AiFavoredItems SET Value = 25 WHERE ListType = 'DefaultYieldBias' AND Item = 'YIELD_PRODUCTION'; -- 25
--UPDATE AiFavoredItems SET Value = 20 WHERE ListType = 'DefaultYieldBias' AND Item = 'YIELD_SCIENCE'; -- 10
--UPDATE AiFavoredItems SET Value = 20 WHERE ListType = 'DefaultYieldBias' AND Item = 'YIELD_CULTURE'; -- 10
UPDATE AiFavoredItems SET Value = -10 WHERE ListType = 'DefaultYieldBias' AND Item = 'YIELD_GOLD';  -- 20
--UPDATE AiFavoredItems SET Value = -25 WHERE ListType = 'DefaultYieldBias' AND Item = 'YIELD_FAITH'; -- -25
--UPDATE AiFavoredItems SET Value = 25 WHERE ListType = 'ScienceLoverSciencePreference' AND Item = 'YIELD_SCIENCE';  -- 20
--UPDATE AiFavoredItems SET Value = 20 WHERE ListType = 'GilgameshSciencePreference' AND Item = 'YIELD_SCIENCE';  -- 10
--UPDATE AiFavoredItems SET Value = 25 WHERE ListType = 'CultureLoverCulturePreference' AND Item = 'YIELD_CULTURE';  -- 20
--UPDATE AiFavoredItems SET Value = 20 WHERE ListType = 'GreeceYields' AND Item = 'YIELD_CULTURE';  -- 20
UPDATE AiFavoredItems SET Value = 10 WHERE ListType = 'ClassicalYields' AND Item = 'YIELD_GOLD';  -- 20
UPDATE AiFavoredItems SET Value = 10 WHERE ListType = 'MedievalYields' AND Item = 'YIELD_GOLD';  -- 15
UPDATE AiFavoredItems SET Value = 10 WHERE ListType = 'RenaissanceYields' AND Item = 'YIELD_GOLD';  -- 15
UPDATE AiFavoredItems SET Value = 10 WHERE ListType = 'IndustrialYields' AND Item = 'YIELD_GOLD';  -- 15


--------------------------------------------------------------
-- Yields - default values are 1.0 except for Gold = 0.5
-- Slight change to see the effects - I think it should be tuned by using AiLists
/*
UPDATE Yields SET DefaultValue = 0.8 WHERE YieldType = 'YIELD_FOOD';
UPDATE Yields SET DefaultValue = 1.2 WHERE YieldType = 'YIELD_PRODUCTION';
UPDATE Yields SET DefaultValue = 0.6 WHERE YieldType = 'YIELD_GOLD';
UPDATE Yields SET DefaultValue = 1.1 WHERE YieldType = 'YIELD_SCIENCE';
UPDATE Yields SET DefaultValue = 1.1 WHERE YieldType = 'YIELD_CULTURE';
UPDATE Yields SET DefaultValue = 0.9 WHERE YieldType = 'YIELD_FAITH';
*/

--------------------------------------------------------------
-- This part was originally taken from AI+ mod with the comment:
-- Note, these pseudoyields are the base values, but are heavily influenced by strategies
-- They don't accurately describe relative desire, because most of the desire calculations are internal
-- A pseudoyield of 10 for PSEUDOYIELD_IMPROVEMENT, doesn't mean it'll be as likely to build workers as units if PSEUDOYIELD_UNIT_COMBAT is also set at 10
-- Default value is shown at the end
/*
		<!--These values appear to determine not just how to value cities to attack, but also how likely it is we attack any.
		Based on testing:
		- PSEUDOYIELD_CITY_BASE  if positive makes it more likely we'll attack
		- PSEUDOYIELD_CITY_DEFENSES   if positive makes it LESS likely we'll attack (times city defence? maybe walls?)
		- PSEUDOYIELD_CITY_DEFENDING_UNITS   if positive makes it LESS likely we'll attack (times unit count?)
		- PSEUDOYIELD_CITY_ORIGINAL_CAPITAL   if positive, increases desire to attack capitals
		- PSEUDOYIELD_CITY_POPULATION   if positive, probably increases desire (too lazy to check)
*/

UPDATE PseudoYields SET DefaultValue = 300   WHERE PseudoYieldType = 'PSEUDOYIELD_CITY_BASE'; -- 	450
UPDATE PseudoYields SET DefaultValue = 100    WHERE PseudoYieldType = 'PSEUDOYIELD_CITY_DEFENDING_UNITS'; -- 	80
UPDATE PseudoYields SET DefaultValue = 300   WHERE PseudoYieldType = 'PSEUDOYIELD_CITY_DEFENSES'; -- 	400 -- imho, this one doesn't work as expected
UPDATE PseudoYields SET DefaultValue = 100   WHERE PseudoYieldType = 'PSEUDOYIELD_CITY_ORIGINAL_CAPITAL'; -- 	200 -- if this is used in Conquest, it should stay high
--UPDATE PseudoYields SET DefaultValue =  50    WHERE PseudoYieldType = 'PSEUDOYIELD_CITY_POPULATION'; -- 	50
UPDATE PseudoYields SET DefaultValue =  3    WHERE PseudoYieldType = 'PSEUDOYIELD_CIVIC'; -- 	5, 1 too little
UPDATE PseudoYields SET DefaultValue =  1.0  WHERE PseudoYieldType = 'PSEUDOYIELD_CLEAR_BANDIT_CAMPS'; -- 	0.5
--UPDATE PseudoYields SET DefaultValue =  0.15 WHERE PseudoYieldType = 'PSEUDOYIELD_DIPLOMATIC_BONUS'; -- 	0.25 -- let's not change diplomacy yet
UPDATE PseudoYields SET DefaultValue = 4.0 WHERE PseudoYieldType = 'PSEUDOYIELD_DISTRICT'; -- 	3.5, AI+ = 6.7! check if this helps with Holy Sites - this is the earliest available district!
UPDATE PseudoYields SET DefaultValue =  0.6 WHERE PseudoYieldType = 'PSEUDOYIELD_ENVIRONMENT'; -- 	0.5
--UPDATE PseudoYields SET DefaultValue = X.X WHERE PseudoYieldType = 'PSEUDOYIELD_GOLDENAGE_POINT'; -- 	1
--UPDATE PseudoYields SET DefaultValue = X.X WHERE PseudoYieldType = 'PSEUDOYIELD_GOVERNOR'; -- 	2
UPDATE PseudoYields SET DefaultValue =  0.5  WHERE PseudoYieldType = 'PSEUDOYIELD_GPP_ADMIRAL'; -- 	0.5
UPDATE PseudoYields SET DefaultValue =  0.7 WHERE PseudoYieldType = 'PSEUDOYIELD_GPP_ARTIST'; -- 	0.5
UPDATE PseudoYields SET DefaultValue =  0.7 WHERE PseudoYieldType = 'PSEUDOYIELD_GPP_ENGINEER'; -- 	0.5
UPDATE PseudoYields SET DefaultValue =  0.6 WHERE PseudoYieldType = 'PSEUDOYIELD_GPP_GENERAL'; -- 	0.5
UPDATE PseudoYields SET DefaultValue =  0.6 WHERE PseudoYieldType = 'PSEUDOYIELD_GPP_MERCHANT'; -- 	0.5 -- 1.5 - why so high?
UPDATE PseudoYields SET DefaultValue =  0.5 WHERE PseudoYieldType = 'PSEUDOYIELD_GPP_MUSICIAN'; -- 	0.5
UPDATE PseudoYields SET DefaultValue =  0.7 WHERE PseudoYieldType = 'PSEUDOYIELD_GPP_PROPHET'; -- 	0.5
UPDATE PseudoYields SET DefaultValue =  0.7 WHERE PseudoYieldType = 'PSEUDOYIELD_GPP_SCIENTIST'; -- 	0.5, 1.6 vs. 0.75 disproportion Sci vs. Cul - not many Theater Districts
UPDATE PseudoYields SET DefaultValue =  0.8 WHERE PseudoYieldType = 'PSEUDOYIELD_GPP_WRITER'; -- 	0.5
UPDATE PseudoYields SET DefaultValue = 8 WHERE PseudoYieldType = 'PSEUDOYIELD_GREATWORK_ARTIFACT'; -- 	10
UPDATE PseudoYields SET DefaultValue = 8 WHERE PseudoYieldType = 'PSEUDOYIELD_GREATWORK_LANDSCAPE'; -- 	10
UPDATE PseudoYields SET DefaultValue = 8 WHERE PseudoYieldType = 'PSEUDOYIELD_GREATWORK_MUSIC'; -- 	10
UPDATE PseudoYields SET DefaultValue = 8 WHERE PseudoYieldType = 'PSEUDOYIELD_GREATWORK_PORTRAIT'; -- 	10
UPDATE PseudoYields SET DefaultValue = 8 WHERE PseudoYieldType = 'PSEUDOYIELD_GREATWORK_RELIC'; -- 	10
UPDATE PseudoYields SET DefaultValue = 8 WHERE PseudoYieldType = 'PSEUDOYIELD_GREATWORK_RELIGIOUS'; -- 	10
UPDATE PseudoYields SET DefaultValue = 8 WHERE PseudoYieldType = 'PSEUDOYIELD_GREATWORK_SCULPTURE'; -- 	10
UPDATE PseudoYields SET DefaultValue = 12 WHERE PseudoYieldType = 'PSEUDOYIELD_GREATWORK_WRITING'; -- 	10
--UPDATE PseudoYields SET DefaultValue = X.X WHERE PseudoYieldType = 'PSEUDOYIELD_HAPPINESS'; -- 	1
UPDATE PseudoYields SET DefaultValue = 5  WHERE PseudoYieldType = 'PSEUDOYIELD_IMPROVEMENT'; -- 	0.5, 13.5 too much
--UPDATE PseudoYields SET DefaultValue = 0.55 WHERE PseudoYieldType = 'PSEUDOYIELD_INFLUENCE'; -- 	0.5
UPDATE PseudoYields SET DefaultValue = 40   WHERE PseudoYieldType = 'PSEUDOYIELD_NUCLEAR_WEAPON'; -- 	25
--UPDATE PseudoYields SET DefaultValue = X.X WHERE PseudoYieldType = 'PSEUDOYIELD_SPACE_RACE'; -- 	100
--UPDATE PseudoYields SET DefaultValue = X.X WHERE PseudoYieldType = 'PSEUDOYIELD_STANDING_ARMY_NUMBER'; -- 	1
--UPDATE PseudoYields SET DefaultValue = X.X WHERE PseudoYieldType = 'PSEUDOYIELD_STANDING_ARMY_VALUE'; -- 	0.1
UPDATE PseudoYields SET DefaultValue =  3   WHERE PseudoYieldType = 'PSEUDOYIELD_TECHNOLOGY'; -- 	5, 1 too little, they don't progress well with science
--UPDATE PseudoYields SET DefaultValue = 1 WHERE PseudoYieldType = 'PSEUDOYIELD_TOURISM'; -- 	1
UPDATE PseudoYields SET DefaultValue =  3.0 WHERE PseudoYieldType = 'PSEUDOYIELD_UNIT_AIR_COMBAT'; -- 	2, 2.2 in AI+, 20 in AirpowerFix
UPDATE PseudoYields SET DefaultValue =  3.0 WHERE PseudoYieldType = 'PSEUDOYIELD_UNIT_ARCHAEOLOGIST'; -- 4
UPDATE PseudoYields SET DefaultValue =  1.3 WHERE PseudoYieldType = 'PSEUDOYIELD_UNIT_COMBAT'; -- 1
UPDATE PseudoYields SET DefaultValue =  0.6 WHERE PseudoYieldType = 'PSEUDOYIELD_UNIT_EXPLORER'; --	1
--UPDATE PseudoYields SET DefaultValue =  1.0 WHERE PseudoYieldType = 'PSEUDOYIELD_UNIT_NAVAL_COMBAT'; --	1 -- leave for naval strategies
UPDATE PseudoYields SET DefaultValue =  0.8 WHERE PseudoYieldType = 'PSEUDOYIELD_UNIT_RELIGIOUS'; -- 1
UPDATE PseudoYields SET DefaultValue =  1.2 WHERE PseudoYieldType = 'PSEUDOYIELD_UNIT_SETTLER'; -- 1 -- 1.4 seems to much, they build Settlers even with 0 army and undeveloped cities
UPDATE PseudoYields SET DefaultValue = 15.0 WHERE PseudoYieldType = 'PSEUDOYIELD_UNIT_SPY'; -- 20
UPDATE PseudoYields SET DefaultValue = 10.0 WHERE PseudoYieldType = 'PSEUDOYIELD_UNIT_TRADE'; -- 1
UPDATE PseudoYields SET DefaultValue =  0.8 WHERE PseudoYieldType = 'PSEUDOYIELD_WONDER'; -- 2, 0.55 is too low, they don't build them!