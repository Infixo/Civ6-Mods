-- ===========================================================================
-- Real Strategy - Naval strategies
-- Author: Infixo
-- 2018-01-18: Created
-- ===========================================================================

/* 
	-- existing data for reference
    <Row Type="STRATEGY_NAVAL" Kind="KIND_VICTORY_STRATEGY" />
    <Row StrategyType="STRATEGY_NAVAL" NumConditionsNeeded="1"/>
    <Row StrategyType="STRATEGY_NAVAL" ConditionFunction="Is On Island"/>
    <Row StrategyType="STRATEGY_NAVAL" ListType="NavalUnitPreferences"/>
    <Row ListType="NavalUnitPreferences" System="PseudoYields"/>
    <Row ListType="NavalUnitPreferences" Item="PSEUDOYIELD_UNIT_NAVAL_COMBAT" Value="150"/>
    <Row ListType="NavalUnitPreferences" Item="PSEUDOYIELD_UNIT_COMBAT" Value="-90" />
    <Row StrategyType="STRATEGY_NAVAL" ListType="NavalSettlementPreferences"/>
    <Row ListType="NavalSettlementPreferences" System="PlotEvaluations"/>
    <Row ListType="NavalSettlementPreferences" Item="Coastal" Favored="false" Value="10"/>
    <Row ListType="NavalSettlementPreferences" Item="Specific Resource" Value="-3" StringVal="RESOURCE_HORSES"/>
    <Row ListType="NavalSettlementPreferences" Item="Specific Resource" Value="-5" StringVal="RESOURCE_IRON"/>
    <Row ListType="NavalSettlementPreferences" Item="Foreign Continent" Favored="true" Value="4"/>
    <Row ListType="NavalSettlementPreferences" Item="Nearest Friendly City" Favored="false" Value="4"/>
    <Row StrategyType="STRATEGY_NAVAL" ListType="NavalSettlementBoost"/>
    <Row ListType="NavalSettlementBoost" System="SettlementPreferences"/>
    <Row ListType="NavalSettlementBoost" Item="SETTLEMENT_CITY_MINIMUM_VALUE" Value="100"/>
    <Row ListType="NavalSettlementBoost" Item="SETTLEMENT_CITY_VALUE_MULTIPLIER" Value="2"/>
    <Row StrategyType="STRATEGY_NAVAL" ListType="NavalPreferredTechs"/>
    <Row ListType="NavalPreferredTechs" System="Technologies"/>
    <Row ListType="NavalPreferredTechs" Item="TECH_SAILING" Favored="true"/>
    <Row ListType="NavalPreferredTechs" Item="TECH_CELESTIAL_NAVIGATION" Favored="true"/>
    <Row ListType="NavalPreferredTechs" Item="TECH_SHIPBUILDING" Favored="true"/>
    <Row ListType="NavalPreferredTechs" Item="TECH_CARTOGRAPHY" Favored="true"/>
*/



-- ===========================================================================
-- NAVAL STRATEGIES
-- These strategies activate based on a geo-situation assessed from revealed plots.
-- The default situation (i.e. land with some coast only) does NOT trigger any specific strategy.
-- Minors are eligible.
-- Existing STRATEGY_NAVAL with all associated items will be reused as Coastal strategy
-- ===========================================================================

-- thresholds for the detection algorithm
INSERT INTO GlobalParameters (Name, Value) VALUES
('RST_NAVAL_NUM_TURNS', 4), -- frequency of the check
('RST_NAVAL_THRESHOLD_PANGEA',  20), -- Pangea if LESS than
('RST_NAVAL_THRESHOLD_COASTAL', 45), -- Coastal if MORE than
('RST_NAVAL_THRESHOLD_ISLAND',  80), -- Island if MORE than
('RST_NAVAL_MAP_SIZE_DEFAULT', 8), -- the above parameters are valid for this map size
('RST_NAVAL_MAP_SIZE_SHIFT', -100); -- bigger maps tend to have more land (obvious), and smaller the opposite; this is to counter that effect; this is a percentage of the map size difference

INSERT INTO Types (Type, Kind) VALUES
('RST_STRATEGY_PANGEA', 'KIND_VICTORY_STRATEGY'), -- heavy land, typical Pangea maps
('RST_STRATEGY_ISLAND', 'KIND_VICTORY_STRATEGY'); -- heavy water, small lands or islands, typical Islands or Archipelago maps
-- STRATEGY_NAVAL -- land with lots of coast, peninsulas, etc. Earth is such a map or small continents

INSERT INTO Strategies (StrategyType, VictoryType, NumConditionsNeeded) VALUES
('RST_STRATEGY_PANGEA', NULL, 1),
('RST_STRATEGY_ISLAND', NULL, 1);

DELETE FROM StrategyConditions WHERE StrategyType = 'STRATEGY_NAVAL';
INSERT INTO StrategyConditions (StrategyType, ConditionFunction, StringValue, ThresholdValue) VALUES
('RST_STRATEGY_PANGEA', 'Call Lua Function', 'ActiveStrategyNaval', 0),
(    'STRATEGY_NAVAL',  'Call Lua Function', 'ActiveStrategyNaval', 2),
('RST_STRATEGY_ISLAND', 'Call Lua Function', 'ActiveStrategyNaval', 3);


--------------------------------------------------------------
-- RST_STRATEGY_PANGEA

INSERT INTO AiListTypes (ListType) VALUES
('RSTPangeaSettlement'),
('RSTPangeaPseudoYields');
INSERT INTO AiLists (ListType, System) VALUES
('RSTPangeaSettlement',   'PlotEvaluations'),
('RSTPangeaPseudoYields', 'PseudoYields');
INSERT INTO Strategy_Priorities (StrategyType, ListType) VALUES
('RST_STRATEGY_PANGEA', 'RSTPangeaSettlement'),
('RST_STRATEGY_PANGEA', 'RSTPangeaPseudoYields');

-- Settlement
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value, StringVal) VALUES
('RSTPangeaSettlement', 'Coastal', 0, -6, NULL); -- coasts less important

-- Pangea
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('RSTPangeaPseudoYields', 'PSEUDOYIELD_GPP_ADMIRAL', 1, -25),
('RSTPangeaPseudoYields', 'PSEUDOYIELD_UNIT_NAVAL_COMBAT', 1, -50);


--------------------------------------------------------------
-- STRATEGY_NAVAL (aka Coastal)
-- existing lists: NavalUnitPreferences, NavalSettlementPreferences, NavalSettlementBoost, NavalPreferredTechs

INSERT INTO AiListTypes (ListType) VALUES
('RSTNavalDistricts'),
('RSTNavalScoutUses'),
('RSTNavalCivics'),
('RSTNavalWonders');
INSERT INTO AiLists (ListType, System) VALUES
('RSTNavalDistricts',  'Districts'),
('RSTNavalScoutUses',  'AiScoutUses'),
('RSTNavalCivics',     'Civics'),
('RSTNavalWonders',    'Buildings');
INSERT INTO Strategy_Priorities (StrategyType, ListType) VALUES
('STRATEGY_NAVAL', 'RSTNavalDistricts'),
('STRATEGY_NAVAL', 'RSTNavalScoutUses'),
('STRATEGY_NAVAL', 'RSTNavalCivics'),
('STRATEGY_NAVAL', 'RSTNavalWonders');

UPDATE AiFavoredItems SET Value = -25 WHERE ListType = 'NavalUnitPreferences' AND Item = 'PSEUDOYIELD_UNIT_COMBAT'; -- def. -90
UPDATE AiFavoredItems SET Value =  50 WHERE ListType = 'NavalUnitPreferences' AND Item = 'PSEUDOYIELD_UNIT_NAVAL_COMBAT'; -- def. 150

-- Settlement
UPDATE AiFavoredItems SET Value =  5 WHERE ListType = 'NavalSettlementPreferences' AND Item = 'Coastal'; -- def. 10
UPDATE AiFavoredItems SET Value =  2 WHERE ListType = 'NavalSettlementPreferences' AND Item = 'Nearest Friendly City'; -- def. 4
UPDATE AiFavoredItems SET Value =  4 WHERE ListType = 'NavalSettlementPreferences' AND Item = 'Foreign Continent'; -- def. 4
UPDATE AiFavoredItems SET Value = -1 WHERE ListType = 'NavalSettlementPreferences' AND Item = 'Specific Resource' AND StringVal = 'RESOURCE_HORSES'; -- def. -3
UPDATE AiFavoredItems SET Value = -2 WHERE ListType = 'NavalSettlementPreferences' AND Item = 'Specific Resource' AND StringVal = 'RESOURCE_IRON'; -- def. -5
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value, StringVal) VALUES
('NavalSettlementPreferences', 'Fresh Water', 0, -5, NULL),
('NavalSettlementPreferences', 'Specific Resource', 0, 3, 'RESOURCE_COAL'); -- needed

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('RSTNavalDistricts', 'DISTRICT_HARBOR', 1, 0), -- DISTRICT_ENTERTAINMENT_COMPLEX / DISTRICT_WATER_ENTERTAINMENT_COMPLEX
('RSTNavalScoutUses', 'DEFAULT_NAVAL_SCOUTS', 1, 100),
('NavalPreferredTechs', 'TECH_SQUARE_RIGGING', 1, 0), -- !BUGGED!
('NavalPreferredTechs', 'TECH_STEAM_POWER', 1, 0), -- !BUGGED!
('NavalPreferredTechs', 'TECH_STEEL', 1, 0), -- !BUGGED!
('NavalPreferredTechs', 'TECH_COMBINED_ARMS', 1, 0), -- !BUGGED!
('RSTNavalCivics', 'CIVIC_FOREIGN_TRADE', 1, 0),
('RSTNavalCivics', 'CIVIC_NAVAL_TRADITION', 1, 0),
('RSTNavalWonders', 'BUILDING_GREAT_LIGHTHOUSE', 1, 0),
('RSTNavalWonders', 'BUILDING_HALICARNASSUS_MAUSOLEUM', 1, 0),
('NavalUnitPreferences', 'PSEUDOYIELD_GPP_ADMIRAL', 1, 15),
('NavalUnitPreferences', 'PSEUDOYIELD_GPP_GENERAL', 1, -15);


--------------------------------------------------------------
-- RST_STRATEGY_ISLAND

INSERT INTO AiListTypes (ListType) VALUES
('RSTIslandPlotEvals'),
('RSTIslandSettlement'),
('RSTIslandScoutUses'),
('RSTIslandDistricts'),
('RSTIslandTechs'),
('RSTIslandCivics'),
('RSTIslandWonders'),
('RSTIslandPseudoYields');
INSERT INTO AiLists (ListType, System) VALUES
('RSTIslandPlotEvals',   'PlotEvaluations'),
('RSTIslandSettlement',  'SettlementPreferences'),
('RSTIslandScoutUses',   'AiScoutUses'),
('RSTIslandDistricts',   'Districts'),
('RSTIslandTechs',       'Technologies'),
('RSTIslandCivics',      'Civics'),
('RSTIslandWonders',     'Buildings'),
('RSTIslandPseudoYields','PseudoYields');
INSERT INTO Strategy_Priorities (StrategyType, ListType) VALUES
('RST_STRATEGY_ISLAND', 'RSTIslandPlotEvals'),
('RST_STRATEGY_ISLAND', 'RSTIslandSettlement'),
('RST_STRATEGY_ISLAND', 'RSTIslandScoutUses'),
('RST_STRATEGY_ISLAND', 'RSTIslandDistricts'),
('RST_STRATEGY_ISLAND', 'RSTIslandTechs'),
('RST_STRATEGY_ISLAND', 'RSTIslandCivics'),
('RST_STRATEGY_ISLAND', 'RSTIslandWonders'),
('RST_STRATEGY_ISLAND', 'RSTIslandPseudoYields');

-- Settlement
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value, StringVal) VALUES
('RSTIslandPlotEvals', 'Coastal', 0, 10, NULL),
('RSTIslandPlotEvals', 'Fresh Water', 0, -10, NULL),
('RSTIslandPlotEvals', 'Nearest Friendly City', 0, 4, NULL),
('RSTIslandPlotEvals', 'Foreign Continent', 0, 8, NULL),
('RSTIslandPlotEvals', 'Specific Resource', 0, 6, 'RESOURCE_COAL'), -- much needed
('RSTIslandPlotEvals', 'Specific Resource', 0, -2, 'RESOURCE_HORSES'), -- not needed
('RSTIslandPlotEvals', 'Specific Resource', 0, -4, 'RESOURCE_IRON'), -- not needed
('RSTIslandPlotEvals', 'Specific Resource', 0, -2, 'RESOURCE_NITER'), -- not needed
('RSTIslandPlotEvals', 'Specific Feature', 0, -5, 'FEATURE_ICE');

-- Island
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('RSTIslandSettlement', 'SETTLEMENT_CITY_MINIMUM_VALUE', 1, 100), -- copied from original Naval
('RSTIslandSettlement', 'SETTLEMENT_CITY_VALUE_MULTIPLIER', 1, 2), -- copied from original Naval
('RSTIslandScoutUses', 'DEFAULT_NAVAL_SCOUTS', 1, 200),
('RSTIslandDistricts', 'DISTRICT_HARBOR', 1, 0), -- DISTRICT_ENTERTAINMENT_COMPLEX / DISTRICT_WATER_ENTERTAINMENT_COMPLEX
('RSTIslandTechs', 'TECH_SAILING', 1, 0), -- !BUGGED!
('RSTIslandTechs', 'TECH_CELESTIAL_NAVIGATION', 1, 0), -- !BUGGED!
('RSTIslandTechs', 'TECH_SHIPBUILDING', 1, 0), -- !BUGGED!
('RSTIslandTechs', 'TECH_CARTOGRAPHY', 1, 0), -- !BUGGED!
('RSTIslandTechs', 'TECH_SQUARE_RIGGING', 1, 0), -- !BUGGED!
('RSTIslandTechs', 'TECH_STEAM_POWER', 1, 0), -- !BUGGED!
('RSTIslandTechs', 'TECH_STEEL', 1, 0), -- !BUGGED!
('RSTIslandTechs', 'TECH_COMBINED_ARMS', 1, 0), -- !BUGGED!
('RSTIslandCivics', 'CIVIC_FOREIGN_TRADE', 1, 0),
('RSTIslandCivics', 'CIVIC_NAVAL_TRADITION', 1, 0),
('RSTIslandWonders', 'BUILDING_GREAT_LIGHTHOUSE', 1, 0),
('RSTIslandWonders', 'BUILDING_HALICARNASSUS_MAUSOLEUM', 1, 0),
('RSTIslandPseudoYields', 'PSEUDOYIELD_GPP_ADMIRAL', 1, 50),
('RSTIslandPseudoYields', 'PSEUDOYIELD_GPP_GENERAL', 1, -50),
('RSTIslandPseudoYields', 'PSEUDOYIELD_UNIT_AIR_COMBAT', 1, 25),
('RSTIslandPseudoYields', 'PSEUDOYIELD_UNIT_COMBAT', 1, -50),
('RSTIslandPseudoYields', 'PSEUDOYIELD_UNIT_NAVAL_COMBAT', 1, 75);




/*
-- ===========================================================================
-- NAVAL OPERATIONS
-- The issue here is that Ranged ships are NOT available in Ancient Era.
-- Quadrireme is with Shipbuilding, which is 2nd column of Classical, so quite late
-- Idea: make 2 different types of OpTeams
-- * melee, ranged optional -> will be used in Ancient & Classical -> 'Is Medieval' = Disqualifier [NAVAL_OP_EARLY]
-- * melee, ranged required -> will be used from Medieval onwards  -> 'Is Medieval' = required condition [NAVAL_SUPERIORITY]
-- However, the ONLY way to influence team composition from AiFavoredItems is by usage of AiOperationTypes list
-- Right now, there is only NAVAL_SUPERIORITY defined - another one needs to be defined (NAVAL_OP_EARLY)
-- Note: BaseOperationsLimits is connected to TRAIT_LEADER_MAJOR_CIV and MINOR_CIV_DEFAULT_TRAIT
--       We have to exclude Minors from Naval Ops, because they end-up building a ton? Or just +1 for Naval/Island
-- ===========================================================================

               NAVAL_OP_EARLY   NAVAL_SUPERIORITY
GeoStrat   DefGame    ANC-CLA   MED+       Minors
Pangea      1-1=0       0        0          1 / 1
Default     1 (base)    1        1          1 / 1
Naval       1+1=2       2        2          1 / 1
Island      1+2=3       3        3          1 / 1

Steps:
1. Remove Naval Ops from BaseOperationsLimits
2. Add separate list for Minors for Naval Ops (=1)
3. Create 8 strategies, 4 per Geo * 2 per time
4. Create and populate 8 AiLists.
*/

-- register a new op, they are numbered for an unknown reason
INSERT INTO AiOperationTypes (OperationType, Value)
SELECT 'NAVAL_OP_EARLY', MAX(Value)+1
FROM AiOperationTypes;

-- remove NAVAL_SUPERIORITY from current usage
DELETE FROM AiFavoredItems WHERE ListType = 'BaseOperationsLimits' AND Item = 'NAVAL_SUPERIORITY';


INSERT INTO Types (Type, Kind) VALUES
('RST_STRATEGY_NAVOP_EARLY_PANGEA',  'KIND_VICTORY_STRATEGY'), -- 1 condition, 1 disqualifier
('RST_STRATEGY_NAVOP_EARLY_DEFAULT', 'KIND_VICTORY_STRATEGY'),
('RST_STRATEGY_NAVOP_EARLY_NAVAL',   'KIND_VICTORY_STRATEGY'),
('RST_STRATEGY_NAVOP_EARLY_ISLAND',  'KIND_VICTORY_STRATEGY'),
('RST_STRATEGY_NAVOP_LATE_PANGEA',  'KIND_VICTORY_STRATEGY'), -- 2 conditons
('RST_STRATEGY_NAVOP_LATE_DEFAULT', 'KIND_VICTORY_STRATEGY'),
('RST_STRATEGY_NAVOP_LATE_NAVAL',   'KIND_VICTORY_STRATEGY'),
('RST_STRATEGY_NAVOP_LATE_ISLAND',  'KIND_VICTORY_STRATEGY'),
-- minors - same for all geos
('RST_STRATEGY_MINOR_NAVOP_EARLY', 'KIND_VICTORY_STRATEGY'),
('RST_STRATEGY_MINOR_NAVOP_LATE',  'KIND_VICTORY_STRATEGY');

INSERT INTO Strategies (StrategyType, VictoryType, NumConditionsNeeded) VALUES
('RST_STRATEGY_NAVOP_EARLY_PANGEA',  NULL, 1), -- 1 condition, 1 disqualifier
('RST_STRATEGY_NAVOP_EARLY_DEFAULT', NULL, 1),
('RST_STRATEGY_NAVOP_EARLY_NAVAL',   NULL, 1),
('RST_STRATEGY_NAVOP_EARLY_ISLAND',  NULL, 1),
('RST_STRATEGY_NAVOP_LATE_PANGEA',  NULL, 2), -- 2 conditons
('RST_STRATEGY_NAVOP_LATE_DEFAULT', NULL, 2),
('RST_STRATEGY_NAVOP_LATE_NAVAL',   NULL, 2),
('RST_STRATEGY_NAVOP_LATE_ISLAND',  NULL, 2),
-- minors
('RST_STRATEGY_MINOR_NAVOP_EARLY', NULL, 1),
('RST_STRATEGY_MINOR_NAVOP_LATE',  NULL, 2);

-- not for minors
INSERT INTO StrategyConditions (StrategyType, ConditionFunction, Disqualifier)
SELECT Type, 'Is Not Major', 1
FROM Types WHERE Kind = 'KIND_VICTORY_STRATEGY' AND Type LIKE 'RST_STRATEGY_NAVOP%';

INSERT INTO StrategyConditions (StrategyType, ConditionFunction, StringValue, ThresholdValue, Disqualifier) VALUES
-- early
('RST_STRATEGY_NAVOP_EARLY_PANGEA',  'Is Medieval', NULL, 0, 1),
('RST_STRATEGY_NAVOP_EARLY_DEFAULT', 'Is Medieval', NULL, 0, 1),
('RST_STRATEGY_NAVOP_EARLY_NAVAL',   'Is Medieval', NULL, 0, 1),
('RST_STRATEGY_NAVOP_EARLY_ISLAND',  'Is Medieval', NULL, 0, 1),
('RST_STRATEGY_NAVOP_EARLY_PANGEA',  'Call Lua Function', 'ActiveStrategyNaval', 0, 0),
('RST_STRATEGY_NAVOP_EARLY_DEFAULT', 'Call Lua Function', 'ActiveStrategyNaval', 1, 0),
('RST_STRATEGY_NAVOP_EARLY_NAVAL',   'Call Lua Function', 'ActiveStrategyNaval', 2, 0),
('RST_STRATEGY_NAVOP_EARLY_ISLAND',  'Call Lua Function', 'ActiveStrategyNaval', 3, 0),
-- late
('RST_STRATEGY_NAVOP_LATE_PANGEA',  'Is Medieval', NULL, 0, 0),
('RST_STRATEGY_NAVOP_LATE_DEFAULT', 'Is Medieval', NULL, 0, 0),
('RST_STRATEGY_NAVOP_LATE_NAVAL',   'Is Medieval', NULL, 0, 0),
('RST_STRATEGY_NAVOP_LATE_ISLAND',  'Is Medieval', NULL, 0, 0),
('RST_STRATEGY_NAVOP_LATE_PANGEA',  'Call Lua Function', 'ActiveStrategyNaval', 0, 0),
('RST_STRATEGY_NAVOP_LATE_DEFAULT', 'Call Lua Function', 'ActiveStrategyNaval', 1, 0),
('RST_STRATEGY_NAVOP_LATE_NAVAL',   'Call Lua Function', 'ActiveStrategyNaval', 2, 0),
('RST_STRATEGY_NAVOP_LATE_ISLAND',  'Call Lua Function', 'ActiveStrategyNaval', 3, 0);

-- minors specific
INSERT INTO StrategyConditions (StrategyType, ConditionFunction, StringValue, ThresholdValue, Disqualifier) VALUES
('RST_STRATEGY_MINOR_NAVOP_EARLY', 'Is Not Major', NULL, 0, 0),
('RST_STRATEGY_MINOR_NAVOP_EARLY', 'Is Medieval',  NULL, 0, 1),
('RST_STRATEGY_MINOR_NAVOP_LATE',  'Is Not Major', NULL, 0, 0),
('RST_STRATEGY_MINOR_NAVOP_LATE',  'Is Medieval',  NULL, 0, 0);


INSERT INTO AiListTypes (ListType) VALUES
('RSTNavalOpsEarlyPangea'),
('RSTNavalOpsEarlyDefault'),
('RSTNavalOpsEarlyNaval'),
('RSTNavalOpsEarlyIsland'),
('RSTNavalOpsLatePangea'),
('RSTNavalOpsLateDefault'),
('RSTNavalOpsLateNaval'),
('RSTNavalOpsLateIsland'),
('RSTNavalOpsMinorEarly'),
('RSTNavalOpsMinorLate');

INSERT INTO AiLists (ListType, System)
SELECT ListType, 'AiOperationTypes'
FROM AiListTypes WHERE ListType LIKE 'RSTNavalOps%';

INSERT INTO Strategy_Priorities (StrategyType, ListType) VALUES
('RST_STRATEGY_NAVOP_EARLY_PANGEA',  'RSTNavalOpsEarlyPangea'),
('RST_STRATEGY_NAVOP_EARLY_DEFAULT', 'RSTNavalOpsEarlyDefault'),
('RST_STRATEGY_NAVOP_EARLY_NAVAL',   'RSTNavalOpsEarlyNaval'),
('RST_STRATEGY_NAVOP_EARLY_ISLAND',  'RSTNavalOpsEarlyIsland'),
('RST_STRATEGY_NAVOP_LATE_PANGEA',  'RSTNavalOpsLatePangea'),
('RST_STRATEGY_NAVOP_LATE_DEFAULT', 'RSTNavalOpsLateDefault'),
('RST_STRATEGY_NAVOP_LATE_NAVAL',   'RSTNavalOpsLateNaval'),
('RST_STRATEGY_NAVOP_LATE_ISLAND',  'RSTNavalOpsLateIsland'),
-- minors
('RST_STRATEGY_MINOR_NAVOP_EARLY', 'RSTNavalOpsMinorEarly'),
('RST_STRATEGY_MINOR_NAVOP_LATE',  'RSTNavalOpsMinorLate');

-- Note: Favored uses a default value 1
INSERT INTO AiFavoredItems (ListType, Item, Value) VALUES
('RSTNavalOpsEarlyPangea',  'NAVAL_OP_EARLY', 0),
('RSTNavalOpsEarlyDefault', 'NAVAL_OP_EARLY', 1),
('RSTNavalOpsEarlyNaval',   'NAVAL_OP_EARLY', 2),
('RSTNavalOpsEarlyIsland',  'NAVAL_OP_EARLY', 3),
('RSTNavalOpsLatePangea',  'NAVAL_SUPERIORITY', 0),
('RSTNavalOpsLateDefault', 'NAVAL_SUPERIORITY', 1),
('RSTNavalOpsLateNaval',   'NAVAL_SUPERIORITY', 2),
('RSTNavalOpsLateIsland',  'NAVAL_SUPERIORITY', 3),
-- minors
('RSTNavalOpsMinorEarly', 'NAVAL_OP_EARLY', 1),
('RSTNavalOpsMinorLate',  'NAVAL_SUPERIORITY', 1);



-- ===========================================================================
-- EXPLORATION
-- STRATEGY_EARLY_EXPLORATION - boosts only Land Scouts, so a condition needs to be added to exclude Coastal and Island
-- New strategies: Naval (aka Coastal) and Island exploration - will last entire Ancient Era
-- ===========================================================================

INSERT INTO Types (Type, Kind) VALUES
('RST_STRATEGY_EXPLORATION_LAND',  'KIND_VICTORY_STRATEGY'),
('RST_STRATEGY_EXPLORATION_NAVAL',  'KIND_VICTORY_STRATEGY'),
('RST_STRATEGY_EXPLORATION_ISLAND', 'KIND_VICTORY_STRATEGY');

INSERT INTO Strategies (StrategyType, VictoryType, NumConditionsNeeded) VALUES
('RST_STRATEGY_EXPLORATION_LAND',   NULL, 1),
('RST_STRATEGY_EXPLORATION_NAVAL',  NULL, 1),
('RST_STRATEGY_EXPLORATION_ISLAND', NULL, 1);

-- STRATEGY_EARLY_EXPLORATION
-- Please note that this strategy will start at turn T1 and cannot be turned off until T21.
-- This applies to any other strategy - they cannot be deactivated before T21.
-- Just disconnect it from AiLists
DELETE FROM Strategy_Priorities WHERE StrategyType = 'STRATEGY_EARLY_EXPLORATION';
--UPDATE Strategies SET NumConditionsNeeded = 2 WHERE StrategyType = 'STRATEGY_EARLY_EXPLORATION';
--UPDATE StrategyConditions SET ThresholdValue = 2 WHERE StrategyType = 'STRATEGY_EARLY_EXPLORATION' AND ConditionFunction = 'Fewer Cities'; -- 1
--DELETE FROM StrategyConditions WHERE StrategyType = 'STRATEGY_EARLY_EXPLORATION';

INSERT INTO StrategyConditions (StrategyType, ConditionFunction, StringValue, ThresholdValue, Disqualifier) VALUES
-- apply existing strategy only for Pangea/Default
('RST_STRATEGY_EXPLORATION_LAND',      'Is Not Major',                        NULL, 0, 1),
('RST_STRATEGY_EXPLORATION_LAND', 'Call Lua Function', 'ActiveStrategyExploreLand', 2, 0),
-- Naval (aka Coastal)
('RST_STRATEGY_EXPLORATION_NAVAL',      'Is Not Major',                  NULL, 0, 1),
('RST_STRATEGY_EXPLORATION_NAVAL',       'Is Medieval',                  NULL, 0, 1),
('RST_STRATEGY_EXPLORATION_NAVAL', 'Call Lua Function', 'ActiveStrategyNaval', 2, 0),
-- Island
('RST_STRATEGY_EXPLORATION_ISLAND',      'Is Not Major',                  NULL, 0, 1),
('RST_STRATEGY_EXPLORATION_ISLAND',    'Is Renaissance',                  NULL, 0, 1),
('RST_STRATEGY_EXPLORATION_ISLAND', 'Call Lua Function', 'ActiveStrategyNaval', 3, 0);


/* AiScoutUses - All are put into in DefaultScoutUse with values in braces - values seem to show no. of units (100 = 1 unit)
Comment from Vikings:     <!-- Note: Scouting values are read in as percentages, so multiply desired numbers by 100 -->
Question: is it related to UNITAI_EXPLORE (many units) or PSEUDOYIELD_UNIT_EXPLORER (only UNIT_SCOUT)
DEFAULT_LAND_SCOUTS (100)        EarlyExplorationBoost (200)
DEFAULT_NAVAL_SCOUTS (100)       Vikings/NavalScoutingPreferences (200)
LAND_SCOUTS_PER_PRIMARY_REGION (100) not used
LAND_SCOUTS_PER_SECONDARY_REGION (50) not used
NAVAL_SCOUTS_FOR_WORLD_EXPLORATION (300) Vikings/NavalScoutingPreferences (200)
*/

INSERT INTO AiListTypes (ListType) VALUES
('RSTExplorationLandScoutUses'),
('RSTExplorationNavalScoutUses'),
('RSTExplorationIslandScoutUses');
INSERT INTO AiLists (ListType, System) VALUES
('RSTExplorationLandScoutUses',   'AiScoutUses'),
('RSTExplorationNavalScoutUses',  'AiScoutUses'),
('RSTExplorationIslandScoutUses', 'AiScoutUses');
INSERT INTO Strategy_Priorities (StrategyType, ListType) VALUES
('RST_STRATEGY_EXPLORATION_LAND',   'RSTExplorationLandScoutUses'),
('RST_STRATEGY_EXPLORATION_NAVAL',  'RSTExplorationNavalScoutUses'),
('RST_STRATEGY_EXPLORATION_ISLAND', 'RSTExplorationIslandScoutUses');

-- default data for reference
--    <Row StrategyType="STRATEGY_EARLY_EXPLORATION" ListType="EarlyExplorationBoost"/>
--    <Row ListType="EarlyExplorationBoost" System="AiScoutUses"/>
--    <Row ListType="EarlyExplorationBoost" Item="DEFAULT_LAND_SCOUTS" Value="200"/>
INSERT INTO AiFavoredItems (ListType, Item, Value) VALUES
('RSTExplorationLandScoutUses', 'DEFAULT_LAND_SCOUTS', 200), -- same as EarlyExplorationBoost
('RSTExplorationNavalScoutUses', 'DEFAULT_LAND_SCOUTS', 0),
('RSTExplorationNavalScoutUses', 'DEFAULT_NAVAL_SCOUTS', 100),
('RSTExplorationNavalScoutUses', 'NAVAL_SCOUTS_FOR_WORLD_EXPLORATION', 100),
('RSTExplorationIslandScoutUses', 'DEFAULT_LAND_SCOUTS', -100),
('RSTExplorationIslandScoutUses', 'DEFAULT_NAVAL_SCOUTS', 200),
('RSTExplorationIslandScoutUses', 'NAVAL_SCOUTS_FOR_WORLD_EXPLORATION', 200);
