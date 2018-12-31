--------------------------------------------------------------
-- Real Fixes
-- Author: Infixo
-- 2018-03-25: Created, Typos in Traits and AiFavoredItems, integrated existing mods
-- 2018-03-26: Alexander's trait
-- 2018-12-03: Balance section starts with Govs
--------------------------------------------------------------

-- 2018-03-25 Traits
UPDATE Traits SET Name = 'LOC_TRAIT_LEADER_UNIT_ENGLISH_REDCOAT_NAME'      WHERE Name = 'LOC_TRAIT_LEADER_TRAIT_LEADER_UNIT_ENGLISH_REDCOAT_NAME'; -- typo
UPDATE Traits SET Name = 'LOC_TRAIT_LEADER_UNIT_NORWEGIAN_LONGSHIP_NAME'   WHERE Name = 'LOC_TRAIT_LEADER_TRAIT_LEADER_UNIT_NORWEGIAN_LONGSHIP_NAME'; -- typo
UPDATE Traits SET Name = 'LOC_TRAIT_LEADER_UNIT_AMERICAN_ROUGH_RIDER_NAME' WHERE Name = 'LOC_TRAIT_LEADER_TRAIT_LEADER_UNIT_AMERICAN_ROUGH_RIDER_NAME'; -- typo
UPDATE Traits SET Name = 'LOC_TRAIT_CIVILIZATION_UNIT_HETAIROI_NAME'       WHERE Name = 'LOC_TRAIT_LEADER_UNIT_HETAIROI_NAME'; -- different LOC defined

-- 2018-03-25: AiFavoredItems
UPDATE AiFavoredItems SET Item = 'CIVIC_NAVAL_TRADITION' WHERE Item = 'CIVIC_NAVAL_TRADITIION';
DELETE FROM AiFavoredItems WHERE ListType = 'BaseListTest' AND Item = 'CIVIC_IMPERIALISM'; -- this is the only item defined for that list, and it is not existing in Civics, no idea what the author had in mind

-- Ai Strategy Medieval Fixes
UPDATE StrategyConditions SET ConditionFunction = 'Is Medieval' WHERE StrategyType = 'STRATEGY_MEDIEVAL_CHANGES' AND Disqualifier = 0; -- Fixed in Spring 2018 Patch (left for iOS)
--INSERT INTO Strategy_Priorities (StrategyType, ListType) VALUES ('STRATEGY_MEDIEVAL_CHANGES', 'MedievalSettlements');
-- The following will allow for AI+ to remove this strategy
INSERT INTO Strategy_Priorities (StrategyType, ListType)
SELECT 'STRATEGY_MEDIEVAL_CHANGES', 'MedievalSettlements'
FROM Strategies
WHERE StrategyType = 'STRATEGY_MEDIEVAL_CHANGES';

-- Ai Yield Bias
-- Fixed in Spring 2018 Patch (left for iOS)
UPDATE AiFavoredItems SET Item = 'YIELD_PRODUCTION' WHERE Item = 'YEILD_PRODUCTION';
UPDATE AiFavoredItems SET Item = 'YIELD_SCIENCE'    WHERE Item = 'YEILD_SCIENCE';
UPDATE AiFavoredItems SET Item = 'YIELD_CULTURE'    WHERE Item = 'YEILD_CULTURE';
UPDATE AiFavoredItems SET Item = 'YIELD_GOLD'       WHERE Item = 'YEILD_GOLD';
UPDATE AiFavoredItems SET Item = 'YIELD_FAITH'      WHERE Item = 'YEILD_FAITH';

-- 2018-03-25 Rise & Fall only (move later to a separate file)
/* moved on 2018-12-09
INSERT INTO Types (Type, Kind) VALUES ('PSEUDOYIELD_GOLDENAGE_POINT', 'KIND_PSEUDOYIELD');
UPDATE AiFavoredItems SET Item = 'TECH_SAILING' WHERE Item = 'TECH_SALING'; -- GenghisTechs
UPDATE AiFavoredItems SET Item = 'DIPLOACTION_ALLIANCE_MILITARY' WHERE Item = 'DIPLOACTION_ALLIANCE_MILITARY_EMERGENCY(NOT_IN_YET)'; -- WilhelminaEmergencyAllianceList, REMOVE IF IMPLEMENTED PROPERLY!
UPDATE AiFavoredItems SET Item = 'DIPLOACTION_ALLIANCE' WHERE Item = 'DIPLOACTION_ALLIANCE_TEAMUP'; -- IronConfederacyDiplomacy, does not exists in Diplo Actions, REMOVE IF IMPLEMENTED PROPERLY!
*/

-- 2018-03-26: AiLists Alexander's trait
UPDATE AiLists SET LeaderType = 'TRAIT_LEADER_TO_WORLDS_END' WHERE LeaderType = 'TRAIT_LEADER_CITADEL_CIVILIZATION' AND ListType IN ('AlexanderCivics', 'AlexanderTechs', 'AlexanderWonders');

-- below are used by Poundmaker Iron Confederacy; why robert bruce (taken from AGENDA_FLOWER_OF_SCOTLAND_WAR_NEIGHBORS)
--AGENDA_IRON_CONFEDERACY_FEW_ALLIANCES	StatementKey	ARGTYPE_IDENTITY	LOC_DIPLO_WARNING_LEADER_ROBERT_THE_BRUCE_REASON_ANY
--AGENDA_IRON_CONFEDERACY_MANY_ALLIANCES	StatementKey	ARGTYPE_IDENTITY	LOC_DIPLO_WARNING_LEADER_ROBERT_THE_BRUCE_REASON_ANY


-- ModifierArguments
-- The below Values of AGENDA_xxx do not exist anywhere
/*
AGENDA_AYYUBID_DYNASTY	StatementKey	ARGTYPE_IDENTITY	AGENDA_AYYUBID_DYNASTY_WARNING
AGENDA_BLACK_QUEEN	StatementKey	ARGTYPE_IDENTITY	AGENDA_BLACK_QUEEN_WARNING
AGENDA_BUSHIDO	StatementKey	ARGTYPE_IDENTITY	AGENDA_BUSHIDO_WARNING
AGENDA_LAST_VIKING_KING	StatementKey	ARGTYPE_IDENTITY	AGENDA_LAST_VIKING_KING_WARNING
AGENDA_OPTIMUS_PRINCEPS	StatementKey	ARGTYPE_IDENTITY	AGENDA_OPTIMUS_PRINCEPS_WARNING
AGENDA_PARANOID	StatementKey	ARGTYPE_IDENTITY	AGENDA_PARANOID_WARNING
AGENDA_QUEEN_OF_NILE	StatementKey	ARGTYPE_IDENTITY	AGENDA_QUEEN_OF_NILE_WARNING
*/

-- 2018-05-19 AIRPOWER AI FIX:
--UPDATE PseudoYields SET DefaultValue = 5 WHERE PseudoYieldType="PSEUDOYIELD_UNIT_AIR_COMBAT"; --DefaultValue=2 +50trait=52
--UPDATE AiFavoredItems SET Value = 30 WHERE ListType = "AirpowerLoverAirpowerPreference"; --Value=50 30+22=52

-- 2018-12-09
-- <Row ListType="KoreaScienceBiase"/> - it is used 3x, but in all cases the name is spelled the same, so it is's not a problem

-- 2018-12-09: Missing entries in Types for Victory Strategies
-- The only one that exists is Religious one
INSERT INTO Types (Type, Kind) VALUES
('VICTORY_STRATEGY_CULTURAL_VICTORY', 'KIND_VICTORY_STRATEGY'),
('VICTORY_STRATEGY_MILITARY_VICTORY', 'KIND_VICTORY_STRATEGY'),
('VICTORY_STRATEGY_SCIENCE_VICTORY', 'KIND_VICTORY_STRATEGY');

-- 2018-12-15: Double Wonder production bonus for Apadana and Halicarnassus from Corvee and Monument of the Gods, Huey from Gothic Architecture
DELETE FROM PolicyModifiers WHERE PolicyType = 'POLICY_CORVEE' AND ModifierId = 'CORVEE_APADANAPRODUCTION';
DELETE FROM PolicyModifiers WHERE PolicyType = 'POLICY_CORVEE' AND ModifierId = 'CORVEE_MAUSOLEUMPRODUCTION';
DELETE FROM BeliefModifiers WHERE BeliefType = 'BELIEF_MONUMENT_TO_THE_GODS' AND ModifierId = 'MONUMENT_TO_THE_GODS_APADANA';
DELETE FROM BeliefModifiers WHERE BeliefType = 'BELIEF_MONUMENT_TO_THE_GODS' AND ModifierId = 'MONUMENT_TO_THE_GODS_MAUSOLEUM';
DELETE FROM PolicyModifiers WHERE PolicyType = 'POLICY_GOTHIC_ARCHITECTURE' AND ModifierId = 'GOTHICARCHITECTURE_HUEYPRODUCTION';

-- 2018-12-25: Norwegian Longship has no PseudoYield assigned and Harald has a boost for that in his strategy!
UPDATE Units SET PseudoYieldType = 'PSEUDOYIELD_UNIT_NAVAL_COMBAT' WHERE UnitType = 'UNIT_NORWEGIAN_LONGSHIP';

-- 2018-12-25: Some items in AiFavoredItems have values 1 and -1, which doesn't have any effect; it should be 100 and -100
UPDATE AiFavoredItems SET Value = -100 WHERE ListType = 'GandhiUnitBuilds' AND Item = 'PROMOTION_CLASS_INQUISITOR'; -- was -1
UPDATE AiFavoredItems SET Value =  100 WHERE ListType = 'TomyrisiUnitBuilds' AND Item = 'PROMOTION_CLASS_LIGHT_CAVALRY'; -- was 1
UPDATE AiFavoredItems SET Value =  100 WHERE ListType = 'AmanitoreUnitBuilds' AND Item = 'PROMOTION_CLASS_RANGED'; -- was 1
UPDATE AiFavoredItems SET Value =  100 WHERE ListType = 'CounterReformerInquisitorPreference' AND Item = 'UNIT_INQUISITOR'; -- was 1
UPDATE AiFavoredItems SET Value =  100 WHERE ListType = 'JadwigaUnitBuilds' AND Item = 'UNIT_MILITARY_ENGINEER'; -- was 1
UPDATE AiFavoredItems SET Value =  100 WHERE ListType = 'JayavarmanUnitBuilds' AND Item = 'UNIT_MISSIONARY'; -- was 1
UPDATE AiFavoredItems SET Value =  100 WHERE ListType = 'UnitPriorityBoosts' AND Item = 'UNIT_SETTLER'; -- was 1



--------------------------------------------------------------
-- BALANCE SECTION

-- 1st Tier Governments' placement
UPDATE Governments SET PrereqCivic = 'CIVIC_GAMES_RECREATION' WHERE GovernmentType = 'GOVERNMENT_AUTOCRACY';
UPDATE Governments SET PrereqCivic = 'CIVIC_DRAMA_POETRY'     WHERE GovernmentType = 'GOVERNMENT_CLASSICAL_REPUBLIC';
INSERT INTO CivicPrereqs (Civic, PrereqCivic) VALUES
('CIVIC_GAMES_RECREATION', 'CIVIC_FOREIGN_TRADE'),
('CIVIC_DRAMA_POETRY',     'CIVIC_CRAFTSMANSHIP');


-- Monarchy
UPDATE Governments SET PrereqCivic = 'CIVIC_DIPLOMATIC_SERVICE' WHERE GovernmentType = 'GOVERNMENT_MONARCHY';
--UPDATE Government_SlotCounts SET NumSlots = 2 WHERE GovernmentType = 'GOVERNMENT_MONARCHY' AND GovernmentSlotType = 'SLOT_MILITARY';

-- Rise & Fall changes
UPDATE GlobalParameters SET Value = '10'  WHERE Name = 'COMBAT_HEAL_CITY_OUTER_DEFENSES'; -- def. 1
UPDATE GlobalParameters SET Value = '50'  WHERE Name = 'SCIENCE_PERCENTAGE_YIELD_PER_POP'; -- def. 70
UPDATE GlobalParameters SET Value = '200' WHERE Name = 'TOURISM_TOURISM_TO_MOVE_CITIZEN'; -- def. 150
--UPDATE GlobalParameters SET Value = '20'  WHERE Name = 'CIVIC_COST_PERCENT_CHANGE_AFTER_GAME_ERA'; -- R&F only
--UPDATE GlobalParameters SET Value = '-20' WHERE Name = 'CIVIC_COST_PERCENT_CHANGE_BEFORE_GAME_ERA'; -- R&F only
--UPDATE GlobalParameters SET Value = '20'  WHERE Name = 'TECH_COST_PERCENT_CHANGE_AFTER_GAME_ERA'; -- R&F only
--UPDATE GlobalParameters SET Value = '-20' WHERE Name = 'TECH_COST_PERCENT_CHANGE_BEFORE_GAME_ERA'; -- R&F only


--------------------------------------------------------------
-- MISC SECTION

--------------------------------------------------------------
-- 2018-12-22 From More Natural Beauty mod, increase number of Natural Wonders on maps	
UPDATE Maps SET NumNaturalWonders = DefaultPlayers; -- default is 2,3,4,5,6,7 => will be 2,4,6,8,10,12
UPDATE Features SET MinDistanceNW = 6 WHERE NaturalWonder = 1; -- default is 8
