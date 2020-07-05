--------------------------------------------------------------
-- Real Fixes
-- Author: Infixo
-- 2018-03-25: Created, Typos in Traits and AiFavoredItems, integrated existing mods
-- 2018-03-26: Alexander's trait
-- 2018-12-03: Balance section starts with Govs
-- 2019-01-12: Added some fixes from Delnar's mod
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
INSERT OR REPLACE INTO Strategy_Priorities (StrategyType, ListType)
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


-- 2018-03-26: AiLists Alexander's trait
-- Fixed with Gathering Storm Patch (left for iOS)
UPDATE AiLists SET LeaderType = 'TRAIT_LEADER_TO_WORLDS_END' WHERE LeaderType = 'TRAIT_LEADER_CITADEL_CIVILIZATION' AND ListType IN ('AlexanderCivics', 'AlexanderTechs', 'AlexanderWonders');


-- ModifierArguments
-- The below Values of AGENDA_xxx do not exist anywhere
-- Seems deliberate because there is a comment:
-- <!-- Note: Value not actually used, just has to have something so we know this is a kudo/warning -->
/*
AGENDA_AYYUBID_DYNASTY	StatementKey	ARGTYPE_IDENTITY	AGENDA_AYYUBID_DYNASTY_WARNING
AGENDA_BLACK_QUEEN	StatementKey	ARGTYPE_IDENTITY	AGENDA_BLACK_QUEEN_WARNING
AGENDA_BUSHIDO	StatementKey	ARGTYPE_IDENTITY	AGENDA_BUSHIDO_WARNING
AGENDA_LAST_VIKING_KING	StatementKey	ARGTYPE_IDENTITY	AGENDA_LAST_VIKING_KING_WARNING
AGENDA_OPTIMUS_PRINCEPS	StatementKey	ARGTYPE_IDENTITY	AGENDA_OPTIMUS_PRINCEPS_WARNING
AGENDA_PARANOID	StatementKey	ARGTYPE_IDENTITY	AGENDA_PARANOID_WARNING
AGENDA_QUEEN_OF_NILE	StatementKey	ARGTYPE_IDENTITY	AGENDA_QUEEN_OF_NILE_WARNING
*/


-- 2018-05-19 AIRPOWER AI FIX: imho, it uses too big values, forcing AI to create too many units; balanced values used in RFX_AI file
--UPDATE PseudoYields SET DefaultValue = 5 WHERE PseudoYieldType="PSEUDOYIELD_UNIT_AIR_COMBAT"; --DefaultValue=2 +50trait=52
--UPDATE AiFavoredItems SET Value = 30 WHERE ListType = "AirpowerLoverAirpowerPreference"; --Value=50 30+22=52


-- 2018-12-09: Mispelled name <Row ListType="KoreaScienceBiase"/>
-- it is used 3x, but in all cases the name is spelled the same, so it's not a problem


-- 2018-12-09: Missing entries in Types for Victory Strategies
-- The only one that exists is Religious one
INSERT OR REPLACE INTO Types (Type, Kind) VALUES
('VICTORY_STRATEGY_CULTURAL_VICTORY', 'KIND_VICTORY_STRATEGY'),
('VICTORY_STRATEGY_MILITARY_VICTORY', 'KIND_VICTORY_STRATEGY'),
('VICTORY_STRATEGY_SCIENCE_VICTORY',  'KIND_VICTORY_STRATEGY');


-- 2018-12-15: Double Wonder production bonus for Apadana and Halicarnassus from Corvee and Monument of the Gods, Huey from Gothic Architecture
-- Fixed with Gathering Storm Patch (left for iOS)
DELETE FROM PolicyModifiers WHERE PolicyType = 'POLICY_CORVEE' AND ModifierId = 'CORVEE_APADANAPRODUCTION';
DELETE FROM PolicyModifiers WHERE PolicyType = 'POLICY_CORVEE' AND ModifierId = 'CORVEE_MAUSOLEUMPRODUCTION';
DELETE FROM BeliefModifiers WHERE BeliefType = 'BELIEF_MONUMENT_TO_THE_GODS' AND ModifierId = 'MONUMENT_TO_THE_GODS_APADANA';
DELETE FROM BeliefModifiers WHERE BeliefType = 'BELIEF_MONUMENT_TO_THE_GODS' AND ModifierId = 'MONUMENT_TO_THE_GODS_MAUSOLEUM';
DELETE FROM PolicyModifiers WHERE PolicyType = 'POLICY_GOTHIC_ARCHITECTURE' AND ModifierId = 'GOTHICARCHITECTURE_HUEYPRODUCTION';


-- 2018-12-25: Norwegian Longship has no PseudoYield assigned and Harald has a boost for that in his strategy!
-- Fixed with Gathering Storm Patch (left for iOS)
UPDATE Units SET PseudoYieldType = 'PSEUDOYIELD_UNIT_NAVAL_COMBAT' WHERE UnitType = 'UNIT_NORWEGIAN_LONGSHIP';


-- 2018-12-25: Some items in AiFavoredItems have values 1 and -1, which doesn't have any effect;
-- after some testnig: it doesn't mean that they should be 100 and -100, more like 1 and -1 have no effect, values should be just tuned properly
/* all moved to RST
UPDATE AiFavoredItems SET Value = -100 WHERE ListType = 'GandhiUnitBuilds' AND Item = 'PROMOTION_CLASS_INQUISITOR'; -- was -1 -- this should be India, anyway
UPDATE AiFavoredItems SET Value =   25 WHERE ListType = 'TomyrisiUnitBuilds' AND Item = 'PROMOTION_CLASS_LIGHT_CAVALRY'; -- was 1
UPDATE AiFavoredItems SET Value =  -10 WHERE ListType = 'AmanitoreUnitBuilds' AND Item = 'PROMOTION_CLASS_RANGED'; -- was 1
UPDATE AiFavoredItems SET Value =   10 WHERE ListType = 'CounterReformerInquisitorPreference' AND Item = 'UNIT_INQUISITOR'; -- was 1 -- Philip II
UPDATE AiFavoredItems SET Value =   25 WHERE ListType = 'JadwigaUnitBuilds' AND Item = 'UNIT_MILITARY_ENGINEER'; -- was 1
UPDATE AiFavoredItems SET Value =   25 WHERE ListType = 'JayavarmanUnitBuilds' AND Item = 'UNIT_MISSIONARY'; -- was 1
-- the below list is assigned as default to ALL major civs, so be careful; there is also PseudoYield for that, AI+ set it to 1.4
UPDATE AiFavoredItems SET Value =   20 WHERE ListType = 'UnitPriorityBoosts' AND Item = 'UNIT_SETTLER'; -- was 1 
*/

-- 2019-01-01: "Make Military Formation" in AllowedMoves is set as IsHomeland, but used in Tactics lists for both Majors and Minors
UPDATE AllowedMoves SET IsHomeland = 0, IsTactical = 1 WHERE AllowedMoveType = 'Make Military Formation';


-- 2019-01-01: "Plunder Trader" is only used by Barbarians, Majors and Minors don't use it
-- I am not sure if this is an error, as apparently majors DO plunder TRs nonetheless
-- BH trees have nodes for Pillaging but only for Districts and Improvements
INSERT OR REPLACE INTO AiFavoredItems (ListType, Item, Favored) VALUES
('Default Tactical', 'Plunder Trader', 1);
--('Minor Civ Tactical', 'Plunder Trader', 1); -- later
--('FreeCitiesTactics', 'Plunder Trader', 1); R&F


-- 2019-01-01: AiOperationList Default_List is defined but never used (not causing problems, however)
UPDATE Leaders SET OperationList = 'Default_List' WHERE InheritFrom = 'LEADER_DEFAULT';


-- 2019-01-02: Wrong assignment of PseudoYield to Wonders for Pericles
-- Fixed with Gathering Storm Patch (left for iOS)
--		<Row ListType="PericlesWonders" Item="PSEUDOYIELD_INFLUENCE" Favored="true"/>
--		<Row ListType="PericlesEnvoys" Item="BUILDING_POTALA_PALACE" Value="30"/>
UPDATE AiFavoredItems SET Item = 'BUILDING_POTALA_PALACE' WHERE ListType = 'PericlesWonders' AND Item = 'PSEUDOYIELD_INFLUENCE';
UPDATE AiFavoredItems SET Item = 'PSEUDOYIELD_INFLUENCE'  WHERE ListType = 'PericlesEnvoys'  AND Item = 'BUILDING_POTALA_PALACE';


-- 2019-01-03: Some AiLists are assigned to Agenda Traits but registered in AiLists in a wrong column (for leaders, not agendas)
UPDATE AiLists SET LeaderType = NULL, AgendaType = 'TRAIT_AGENDA_BACKSTABBER'      WHERE LeaderType = 'TRAIT_AGENDA_BACKSTABBER';
UPDATE AiLists SET LeaderType = NULL, AgendaType = 'TRAIT_AGENDA_LAST_VIKING_KING' WHERE LeaderType = 'TRAIT_AGENDA_LAST_VIKING_KING'; -- Fixed with Gathering Storm Patch (left for iOS)
UPDATE AiLists SET LeaderType = NULL, AgendaType = 'TRAIT_AGENDA_WITH_SHIELD'      WHERE LeaderType = 'TRAIT_AGENDA_WITH_SHIELD'; -- Fixed with Gathering Storm Patch (left for iOS)


-- 2019-04-09 Warrior Monks don't have bonuses from Great Generals
-- They are not counted as Medieval units - must be added to a ReqSet that selects subjects (GGs from Classical and Medieval eras)
INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES ('AOE_CLASSICAL_REQUIREMENTS', 'AOE_REQUIRES_CLASS_WARRIOR_MONK');
INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES ('AOE_MEDIEVAL_REQUIREMENTS',  'AOE_REQUIRES_CLASS_WARRIOR_MONK');
INSERT INTO Requirements (RequirementId, RequirementType)                VALUES ('AOE_REQUIRES_CLASS_WARRIOR_MONK', 'REQUIREMENT_UNIT_TAG_MATCHES');
INSERT INTO RequirementArguments (RequirementId, Name, Value)            VALUES ('AOE_REQUIRES_CLASS_WARRIOR_MONK', 'Tag', 'CLASS_WARRIOR_MONK');

--------------------------------------------------------------
-- 2019-08-30
-- Units_Trained_Hotfix_Gameplay
-- Author: JNR
-- Infixo: All fixed in September 2019 Patch
--------------------------------------------------------------
UPDATE Modifiers SET ModifierType='MODIFIER_PLAYER_UNIT_ADJUST_SEA_MOVEMENT' WHERE ModifierId='ROYAL_DOCKYARD_MOVEMENT_BONUS';
UPDATE Modifiers SET ModifierType='MODIFIER_PLAYER_UNIT_ADJUST_UNIT_EXPERIENCE_MODIFIER' WHERE ModifierId='BARRACKS_TRAINED_UNIT_XP';
UPDATE Modifiers SET ModifierType='MODIFIER_PLAYER_UNIT_ADJUST_UNIT_EXPERIENCE_MODIFIER' WHERE ModifierId='STABLE_TRAINED_UNIT_XP';
UPDATE Modifiers SET ModifierType='MODIFIER_PLAYER_UNIT_ADJUST_UNIT_EXPERIENCE_MODIFIER' WHERE ModifierId='ARMORY_TRAINED_UNIT_XP';
UPDATE Modifiers SET ModifierType='MODIFIER_PLAYER_UNIT_ADJUST_UNIT_EXPERIENCE_MODIFIER' WHERE ModifierId='MILITARY_ACADEMY_TRAINED_UNIT_XP';
UPDATE Modifiers SET ModifierType='MODIFIER_PLAYER_UNIT_ADJUST_UNIT_EXPERIENCE_MODIFIER' WHERE ModifierId='LIGHTHOUSE_TRAINED_UNIT_XP';
UPDATE Modifiers SET ModifierType='MODIFIER_PLAYER_UNIT_ADJUST_UNIT_EXPERIENCE_MODIFIER' WHERE ModifierId='SHIPYARD_TRAINED_UNIT_XP';
UPDATE Modifiers SET ModifierType='MODIFIER_PLAYER_UNIT_ADJUST_UNIT_EXPERIENCE_MODIFIER' WHERE ModifierId='SEAPORT_TRAINED_UNIT_XP';
UPDATE Modifiers SET ModifierType='MODIFIER_PLAYER_UNIT_ADJUST_UNIT_EXPERIENCE_MODIFIER' WHERE ModifierId='HANGAR_TRAINED_AIRCRAFT_XP';
UPDATE Modifiers SET ModifierType='MODIFIER_PLAYER_UNIT_ADJUST_UNIT_EXPERIENCE_MODIFIER' WHERE ModifierId='AIRPORT_TRAINED_AIRCRAFT_XP';
UPDATE Modifiers SET ModifierType='MODIFIER_PLAYER_UNIT_ADJUST_UNIT_EXPERIENCE_MODIFIER' WHERE ModifierId='BASILIKOI_TRAINED_UNIT_XP';
UPDATE Modifiers SET ModifierType='MODIFIER_PLAYER_UNIT_ADJUST_UNIT_EXPERIENCE_MODIFIER' WHERE ModifierId='ORDU_TRAINED_XP';


--------------------------------------------------------------
-- 2020-06-14 WC resolution nor working correctly
-- This is technically GS but I am using UPDATE, so no effect if WC is not there

UPDATE Modifiers
SET ModifierType = 'MODIFIER_PLAYER_CITIES_ADJUST_TRADE_ROUTE_YIELD_TO_OTHERS'
WHERE ModifierId = 'INCREASES_TRADE_TO_GOLD' AND ModifierType = 'MODIFIER_PLAYER_CITIES_ADJUST_TRADE_ROUTE_YIELD_FROM_OTHERS';


--------------------------------------------------------------
-- 2020-06-16 Netherland's +50% towards Flood Barrier not working

UPDATE ModifierArguments
SET Name = 'BuildingType'
WHERE ModifierId = 'TRAIT_FLOOD_BARRIER_PRODUCTION' AND Value = 'BUILDING_FLOOD_BARRIER';


--------------------------------------------------------------
-- 2020-07-05 War-Carts don't get Alpine Training from Matterhorn

INSERT OR IGNORE INTO TypeTags (Type, Tag) VALUES ('UNIT_SUMERIAN_WAR_CART', 'CLASS_HEAVY_CAVALRY');


--------------------------------------------------------------
-- BALANCE SECTION

-- 2019-04-07 Yields per pop
--UPDATE GlobalParameters SET Value = '40' WHERE Name = 'SCIENCE_PERCENTAGE_YIELD_PER_POP'; -- base game 70, rise & fall 50
--UPDATE GlobalParameters SET Value = '25' WHERE Name = 'CULTURE_PERCENTAGE_YIELD_PER_POP'; -- default is 30

-- 2019-04-07 Boosts, base game 50, rise & fall 40, real tech tree 35
--UPDATE Boosts SET Boost = 30;


-- Rise & Fall changes
UPDATE GlobalParameters SET Value = '10'  WHERE Name = 'COMBAT_HEAL_CITY_OUTER_DEFENSES'; -- def. 1
--UPDATE GlobalParameters SET Value = '50'  WHERE Name = 'SCIENCE_PERCENTAGE_YIELD_PER_POP'; -- def. 70
UPDATE GlobalParameters SET Value = '200' WHERE Name = 'TOURISM_TOURISM_TO_MOVE_CITIZEN'; -- def. 150
--UPDATE GlobalParameters SET Value = '20'  WHERE Name = 'CIVIC_COST_PERCENT_CHANGE_AFTER_GAME_ERA'; -- R&F only
--UPDATE GlobalParameters SET Value = '-20' WHERE Name = 'CIVIC_COST_PERCENT_CHANGE_BEFORE_GAME_ERA'; -- R&F only
--UPDATE GlobalParameters SET Value = '20'  WHERE Name = 'TECH_COST_PERCENT_CHANGE_AFTER_GAME_ERA'; -- R&F only
--UPDATE GlobalParameters SET Value = '-20' WHERE Name = 'TECH_COST_PERCENT_CHANGE_BEFORE_GAME_ERA'; -- R&F only


-- 2018-01-05: Policy God King. AI values it very low (40-60), vs. e.g. Urban Planning 250+. Changed to: gives yields to all cities.
UPDATE Modifiers SET ModifierType = 'MODIFIER_PLAYER_CITIES_ADJUST_CITY_YIELD_CHANGE' WHERE ModifierId = 'GOD_KING_GOLD' OR ModifierId = 'GOD_KING_FAITH';
-- wow, it certainly works - comparable to Urban Planning now, but depends on situation highly (90-370)
-- comparison: Urban Planning (280-315), Seeds of Growth ~210

-- 2019-02-19: More XP from Barbarians
UPDATE GlobalParameters SET Value = '2' WHERE Name = 'EXPERIENCE_BARB_SOFT_CAP';  -- Default: 1, CANNOT be higher than 8
UPDATE GlobalParameters SET Value = '3' WHERE Name = 'EXPERIENCE_MAX_BARB_LEVEL'; -- Default: 2, CANNOT be higher than 6


--------------------------------------------------------------
-- MISC SECTION

--------------------------------------------------------------
-- 2018-12-22 From More Natural Beauty mod, increase number of Natural Wonders on maps	
UPDATE Maps SET NumNaturalWonders = DefaultPlayers; -- default is 2,3,4,5,6,7 => will be 2,4,6,8,10,12
UPDATE Features SET MinDistanceNW = 6 WHERE NaturalWonder = 1; -- default is 8


--------------------------------------------------------------
-- FIXES FROM DELNAR'S "AI CLEANUP" MOD
-- AICleanup_BehaviorTrees - not valid any more, the Upgrade Tree doesn't use any field for the Upgrade Units node
-- AICleanup_FavorHammerDistrict - too strong
-- AICleanup_FavorUniqueDistricts - not necessary, uniques are boosted by default
-- AICleanup_GlobalParameters - rejected
-- AICleanup_Operations - already done
-- AICleanup_SettlerLove - not needed
-- AICleanup_Units - in the game
-- AICleanup_Victories - in RST

-- This was an odd one. Gold for units was set to 4, gold for plots and GPs was set to 1, and gold for splurge was set to 3.
-- Splurge should always be last in the priority list, so I assumed priority went lowest->highest and set gold for units to 2. -->
UPDATE AiFavoredItems SET Value = 2 WHERE ListType = 'DefaultSavings' AND Item = 'SAVING_UNITS';
