-- ===========================================================================
-- Real Strategy - Tweaks to Tactics
-- Author: Infixo
-- 2019-01-04: Created
-- ===========================================================================


-- 2019-01-01: "Make Military Formation" in AllowedMoves is set as IsHomeland, but used in Tactics lists for both Majors and Minors
UPDATE AllowedMoves SET IsHomeland = 0, IsTactical = 1 WHERE AllowedMoveType = 'Make Military Formation';

-- 2019-01-01: AiOperationList Default_List is defined but never used (not causing problems, however)
UPDATE Leaders SET OperationList = 'Default_List' WHERE InheritFrom = 'LEADER_DEFAULT';

-- 2019-01-01: "Plunder Trader" is only used by Barbarians, Majors and Minors don't use it
-- I am not sure if this is an error, as apparently majors DO plunder TRs nonetheless
-- BH trees have nodes for Pillaging but only for Districts and Improvements
INSERT OR REPLACE INTO AiFavoredItems (ListType, Item, Favored) VALUES
('Default Tactical', 'Plunder Trader', 1);
--('Minor Civ Tactical', 'Plunder Trader', 1); -- later
--('FreeCitiesTactics', 'Plunder Trader', 1); R&F


-- ===========================================================================
-- UNIT TYPES
-- ===========================================================================

-- why is Scientist a Leader???
DELETE FROM UnitAiInfos WHERE UnitType = 'UNIT_GREAT_SCIENTIST' AND AiType = 'UNITAI_LEADER';

-- planes actually use "Ranged Strength" and "Bombard Strength", so they could be treated as Ranged and Siege units respectively
-- ships are registered in that way, too
-- siege units like Catapult, Artillery are also Ranged

INSERT INTO UnitAiInfos (UnitType, AiType)
SELECT UnitType, 'UNITTYPE_RANGED'
FROM Units
WHERE Domain = 'DOMAIN_AIR';

-- UNITTYPE_SIEGE - core - used in Simple City Attack Force, City Attack Force, City Defense and Aid Ally Attack Force

INSERT INTO UnitAiInfos (UnitType, AiType) VALUES
('UNIT_BATTERING_RAM', 'UNITTYPE_SIEGE'),
('UNIT_SIEGE_TOWER', 'UNITTYPE_SIEGE'),
('UNIT_BOMBER', 'UNITTYPE_SIEGE'),
('UNIT_JET_BOMBER', 'UNITTYPE_SIEGE');

-- UNITTYPE_SIEGE_ALL - core + UNIT_BATTERING_RAM, UNIT_SIEGE_TOWER, UNIT_ANTIAIR_GUN, UNIT_MOBILE_SAM, UNIT_SUPPLY_CONVOY - used only ONCE in "City Attack Force" team def, min. 1

DELETE FROM UnitAiInfos WHERE AiType = 'UNITTYPE_SIEGE_ALL' AND UnitType = 'UNIT_SUPPLY_CONVOY';

INSERT INTO UnitAiInfos (UnitType, AiType)
SELECT 'UNIT_BOMBER', 'UNITTYPE_SIEGE_ALL' -- iOS compatibility
FROM UnitAiTypes
WHERE AiType = 'UNITTYPE_SIEGE_ALL';

INSERT INTO UnitAiInfos (UnitType, AiType)
SELECT 'UNIT_JET_BOMBER', 'UNITTYPE_SIEGE_ALL' -- iOS compatibility
FROM UnitAiTypes
WHERE AiType = 'UNITTYPE_SIEGE_ALL';


-- UNITTYPE_SIEGE_SUPPORT - ram, tower, medic, engi, baloon, drone, etc.
-- needs to stay this way until BH is modified - it uses this to make a formation

--DELETE FROM UnitAiInfos WHERE AiType = 'UNITTYPE_SIEGE_SUPPORT' AND UnitType IN ('UNIT_BATTERING_RAM', 'UNIT_SIEGE_TOWER'); -- moved to SIEGE



-- 2018-01-06: UNIT_WARRIOR_MONK is not in UnitAiInfos, so he is basically chilling around, doing nothing
INSERT INTO UnitAiInfos (UnitType, AiType) VALUES
('UNIT_RANGER', 'UNITAI_COMBAT'),
('UNIT_WARRIOR_MONK', 'UNITAI_EXPLORE'),
('UNIT_WARRIOR_MONK', 'UNITAI_COMBAT'),
('UNIT_WARRIOR_MONK', 'UNITTYPE_LAND_COMBAT'),
('UNIT_WARRIOR_MONK', 'UNITTYPE_MELEE');


-- ===========================================================================
-- OP DEFINITIONS
-- Make probabilities a git higher, so AI will try to perform more successful attacks
-- Lower MaxTargetDistInArea so AI won't try to attack targets half across the map
-- Strengthen teams a bit
-- ===========================================================================

UPDATE AiOperationDefs SET MaxTargetDistInArea = 15, MaxTargetDistInWorld = 15, MinOddsOfSuccess = 0.6, MustHaveUnits = 7 WHERE OperationName = 'Attack Enemy City'; -- early, no walls 50%, 5
UPDATE AiOperationDefs SET MaxTargetDistInArea = 15, MaxTargetDistInWorld = 15, MinOddsOfSuccess = 0.4, MustHaveUnits = 4 WHERE OperationName = 'Wartime Attack Enemy City'; -- early no walls 25%, 3
UPDATE AiOperationDefs SET MaxTargetDistInArea = 10, MaxTargetDistInWorld = 10, MinOddsOfSuccess = 0.7, MustHaveUnits =10 WHERE OperationName = 'Attack Walled City'; -- 60%, 10
UPDATE AiOperationDefs SET MaxTargetDistInArea = 10, MaxTargetDistInWorld = 10, MinOddsOfSuccess = 0.6, MustHaveUnits = 7 WHERE OperationName = 'Wartime Attack Walled City'; -- 40%, 6

UPDATE AiOperationDefs SET MinOddsOfSuccess = 0.3, MustHaveUnits = 4 WHERE OperationName = 'City Defense'; -- 0%, 6

UPDATE AiOperationDefs SET MinOddsOfSuccess = 0.4, MustHaveUnits = 3, EnemyType = 'WAR' WHERE OperationName = 'Naval Superiority'; -- 0%, -1 -- this is NOT city attack, just naval wars and patrol?

------------------------------------------------------------------------------
-- A new op - City Defense Unwalled

INSERT INTO AiOperationDefs (OperationName,TargetType,TargetParameter,EnemyType,BehaviorTree,Priority,MaxTargetDistInRegion,MaxTargetDistInArea,MaxTargetDistInWorld,MinOddsOfSuccess,SelfStart,MustHaveUnits,OperationType) VALUES
('City Defense Unwalled', 'TARGET_FRIENDLY_CITY', 0, 'NONE', 'Simple City Defense', 4, -1, -1, 0, 0.2, 0, 3, 'OP_DEFENSE');

INSERT INTO AllowedOperations (ListType, OperationDef) VALUES
('Default_List', 'City Defense Unwalled');

INSERT INTO AiFavoredItems (ListType, Item, StringVal) VALUES
('DefaultCityBuilds',  'CITY_UNDER_THREAT', 'City Defense Unwalled'),
('MinorCivCityBuilds', 'CITY_UNDER_THREAT', 'City Defense Unwalled');

------------------------------------------------------------------------------
-- A new op - Naval Op Early - this is Naval Superiority but with Ranged ships optional (they are available in Ancient, and difficult to get in Classical)

INSERT INTO AiOperationDefs (   OperationName,                 TargetType, TargetParameter, EnemyType,             BehaviorTree, Priority, MaxTargetDistInRegion, MaxTargetDistInArea, MaxTargetDistInWorld, MinOddsOfSuccess, SelfStart, MustHaveUnits,    OperationType)
VALUES                      ('Naval Op Early', 'TARGET_NAVAL_SUPERIORITY',               0,     'WAR', 'Naval Superiority Tree',        2,                    -1,                  -1,                   -1,              0.5,         1,             2, 'NAVAL_OP_EARLY');

INSERT INTO AllowedOperations (ListType, OperationDef) VALUES
('Default_List', 'Naval Op Early');


-- ===========================================================================
-- OP TEAMS
-- AiOperationTeams
-- AiOperationDefs
-- AI will want to match the city's strength, so capping one type should force it to get other units
-- ===========================================================================

/*
Simple Early Attack Force - used for:
	- Attack Barb Camp 0, 0.5     =>  50%, TARGET_BARBARIAN_CAMP ATTACK_BARBARIANS, no min units
	- Barb Camp Tech Boost 0, 1.0 => any%, same as above, no min units
*/
-- seems OK

/*
-- Simple City Attack Force - I assume the city doesn't have walls
Simple City Attack Force - used for:
	- Attack Enemy City 1.5, 3.0         => 50%, TARGET_ENEMY_COMBAT_DISTRICT, CITY_ASSAULT, BehaviorTree="Early City Assault", MustHaveUnits="5"
	- Wartime Attack Enemy City 0.5, 3.0 => 25%, same as above, but MustBeAtWar="true" MustHaveUnits="3"
*/
-- strength
UPDATE AiOperationTeams SET InitialStrengthAdvantage = 1.0, OngoingStrengthAdvantage = 2.0 WHERE TeamName = 'Simple City Attack Force' AND OperationName = 'Attack Enemy City';
UPDATE AiOperationTeams SET InitialStrengthAdvantage = 0.5, OngoingStrengthAdvantage = 1.0 WHERE TeamName = 'Simple City Attack Force' AND OperationName = 'Wartime Attack Enemy City';
-- Seems OK, up to 3 UNITTYPE_SIEGE, so Rams & Towers should count now
UPDATE OpTeamRequirements SET MinNumber = 2, MaxNumber = 6 WHERE TeamName = 'Simple City Attack Force' AND AiType = 'UNITTYPE_MELEE';
UPDATE OpTeamRequirements SET MinNumber = 1, MaxNumber = 6 WHERE TeamName = 'Simple City Attack Force' AND AiType = 'UNITTYPE_RANGED';
UPDATE OpTeamRequirements SET MinNumber = 0, MaxNumber = 3 WHERE TeamName = 'Simple City Attack Force' AND AiType = 'UNITTYPE_SIEGE';

/*
City Attack Force - used for:
	- Attack Walled City 2.0, 4.0          => 60%, TARGET_ENEMY_COMBAT_DISTRICT CITY_ASSAULT BehaviorTree="Siege City Assault" MustHaveUnits="10"
	- Wartime Attack Walled City 1.0, 6.0  => 40%, same as above, but MustBeAtWar="true" MustHaveUnits="6"
*/
-- strength
UPDATE AiOperationTeams SET InitialStrengthAdvantage = 1.0, OngoingStrengthAdvantage = 2.5 WHERE TeamName = 'City Attack Force' AND OperationName = 'Attack Walled City';
UPDATE AiOperationTeams SET InitialStrengthAdvantage = 0.5, OngoingStrengthAdvantage = 1.5 WHERE TeamName = 'City Attack Force' AND OperationName = 'Wartime Attack Walled City';
-- composition
UPDATE OpTeamRequirements SET MinNumber = 7                WHERE TeamName = 'City Attack Force' AND AiType = 'UNITAI_COMBAT';
UPDATE OpTeamRequirements SET MinNumber = 2, MaxNumber = 6 WHERE TeamName = 'City Attack Force' AND AiType = 'UNITTYPE_MELEE';
UPDATE OpTeamRequirements SET MinNumber = 3, MaxNumber = 6 WHERE TeamName = 'City Attack Force' AND AiType = 'UNITTYPE_RANGED';
UPDATE OpTeamRequirements SET MinNumber = 0, MaxNumber = 3 WHERE TeamName = 'City Attack Force' AND AiType = 'UNITTYPE_AIR';
UPDATE OpTeamRequirements SET MinNumber = 0, MaxNumber = 4 WHERE TeamName = 'City Attack Force' AND AiType = 'UNITTYPE_AIR_SIEGE';
UPDATE OpTeamRequirements SET MinNumber = 2, MaxNumber = 4 WHERE TeamName = 'City Attack Force' AND AiType = 'UNITTYPE_SIEGE';
UPDATE OpTeamRequirements SET MinNumber = 2, MaxNumber = 6 WHERE TeamName = 'City Attack Force' AND AiType = 'UNITTYPE_SIEGE_ALL';
UPDATE OpTeamRequirements SET MinNumber = 1, MaxNumber = 2 WHERE TeamName = 'City Attack Force' AND AiType = 'UNITTYPE_SIEGE_SUPPORT';

/*
City Naval Attack Force - used for:
	- all 4 types of attack (war/no war, normal/walled), Condition="IsCoastalTarget"
-- 100% naval
UNITTYPE_RANGED	0	-- can't change that because Ranged are not available in Ancient Era
*/
-- strength
UPDATE AiOperationTeams SET InitialStrengthAdvantage = 1.0, OngoingStrengthAdvantage = 2.0 WHERE TeamName = 'City Naval Attack Force' AND OperationName = 'Attack Enemy City'; --         AND Condition = 'IsCoastalTarget';
UPDATE AiOperationTeams SET InitialStrengthAdvantage = 0.5, OngoingStrengthAdvantage = 1.0 WHERE TeamName = 'City Naval Attack Force' AND OperationName = 'Wartime Attack Enemy City'; -- AND Condition = 'IsCoastalTarget';
-- composition
INSERT INTO OpTeamRequirements (TeamName, AiType, MinNumber, MaxNumber, MinPercentage, MaxPercentage) VALUES
('City Naval Attack Force', 'UNITTYPE_LAND_COMBAT',  0, 3, 0, 0.5);
UPDATE OpTeamRequirements SET MinNumber = 3, MaxNumber = 7, MinPercentage = 0.5 WHERE TeamName = 'City Naval Attack Force' AND AiType = 'UNITTYPE_NAVAL';
UPDATE OpTeamRequirements SET MinNumber = 2, MaxNumber = 6                      WHERE TeamName = 'City Naval Attack Force' AND AiType = 'UNITTYPE_MELEE';

/*
Walled City Naval Attack Force
-- define a different team for walled cities
*/
INSERT INTO AiTeams (TeamName) VALUES
('Walled City Naval Attack Force');
UPDATE  AiOperationTeams SET TeamName = 'Walled City Naval Attack Force', InitialStrengthAdvantage = 1.0, OngoingStrengthAdvantage = 2.5 WHERE OperationName = 'Attack Walled City'         AND Condition = 'IsCoastalTarget';
UPDATE  AiOperationTeams SET TeamName = 'Walled City Naval Attack Force', InitialStrengthAdvantage = 0.5, OngoingStrengthAdvantage = 1.5 WHERE OperationName = 'Wartime Attack Walled City' AND Condition = 'IsCoastalTarget';
INSERT INTO OpTeamRequirements (TeamName,AiType,MinNumber,MaxNumber,MinPercentage,MaxPercentage) VALUES
('Walled City Naval Attack Force', 'UNITTYPE_NAVAL',           3, 9, 0.5, 1), -- some naval
('Walled City Naval Attack Force', 'UNITTYPE_LAND_COMBAT',     0, 5, 0, 0.5), -- some land
('Walled City Naval Attack Force', 'UNITTYPE_CIVILIAN_LEADER', 0, 1, 0, 1), -- admiral/general
('Walled City Naval Attack Force', 'UNITTYPE_MELEE',           2, 4, 0, 1),
('Walled City Naval Attack Force', 'UNITTYPE_RANGED',          4, 9, 0, 1),
('Walled City Naval Attack Force', 'UNITTYPE_SIEGE',           0, 2, 0, 1),
('Walled City Naval Attack Force', 'UNITTYPE_SIEGE_SUPPORT',   0, 1, 0, 1);
INSERT INTO OpTeamRequirements (TeamName,AiType,MinNumber,MaxNumber,MinPercentage,MaxPercentage)
SELECT 'Walled City Naval Attack Force', 'UNITTYPE_SIEGE_ALL', 0, 2, 0, 1 -- iOS compatibility
FROM UnitAiTypes
WHERE AiType = 'UNITTYPE_SIEGE_ALL';


/*
City Defense - used for:
	- OperationName="City Defense", TARGET_FRIENDLY_CITY, BehaviorTree="Simple City Defense"
UNITTYPE_NAVAL		0 -- what if this a naval attack? there is no "naval defense" at all !!!!!
*/
INSERT INTO OpTeamRequirements (TeamName, AiType, MinNumber, MaxNumber) VALUES
('City Defense', 'UNITTYPE_RANGED',  2, 6), -- could use ranged - WARNING!!!!!!!!!!!
('City Defense', 'UNITTYPE_MELEE',   1, 3),
('City Defense', 'UNITTYPE_CAVALRY', 1, 3);
UPDATE OpTeamRequirements SET MinNumber = 4, MaxNumber = NULL WHERE TeamName = 'City Defense' AND AiType = 'UNITAI_COMBAT'; -- WARNING!!!!! check if this works at all!!!!
UPDATE OpTeamRequirements SET MinNumber = 0, MaxNumber = 0    WHERE TeamName = 'City Defense' AND AiType = 'UNITAI_EXPLORE'; -- no Scouts pls
UPDATE OpTeamRequirements SET MinNumber = 0, MaxNumber = 0, MaxPercentage = 0 WHERE TeamName = 'City Defense' AND AiType = 'UNITTYPE_NAVAL'; -- there is no naval defense op - Korea recruited a submarine for a land war... yeah...
UPDATE OpTeamRequirements SET MinNumber = 0, MaxNumber = 0, MaxPercentage = 0 WHERE TeamName = 'City Defense' AND AiType = 'UNITTYPE_SIEGE';
UPDATE OpTeamRequirements SET MinNumber = 0, MaxNumber = 3    WHERE TeamName = 'City Defense' AND AiType = 'UNITTYPE_AIR'; -- pls use fighters
UPDATE OpTeamRequirements SET MinNumber = 0, MaxNumber = 3    WHERE TeamName = 'City Defense' AND AiType = 'UNITTYPE_AIR_SIEGE'; -- ok, no bombers - can we use bombers?

/*
City Defense Unwalled
-- (new) special team for unwalled cities - more melee
*/

INSERT INTO AiTeams (TeamName) VALUES
('City Defense Unwalled');

INSERT INTO AiOperationTeams (TeamName,OperationName,InitialStrengthAdvantage,OngoingStrengthAdvantage) VALUES
('City Defense Unwalled', 'City Defense Unwalled', -1, 1);

INSERT INTO OpTeamRequirements (TeamName, AiType, MinNumber, MaxNumber) VALUES
('City Defense Unwalled', 'UNITAI_COMBAT',     3, 6),
('City Defense Unwalled', 'UNITTYPE_MELEE',    2, 4),
('City Defense Unwalled', 'UNITTYPE_RANGED',   0, 3),
('City Defense Unwalled', 'UNITTYPE_CAVALRY',  0, 2),
('City Defense Unwalled', 'UNITTYPE_CIVILIAN', 0, 0),
('City Defense Unwalled', 'UNITTYPE_CIVILIAN_LEADER', 0, 1);

/*
Naval Superiority Force - used for:
	- OperationName="Naval Superiority", TARGET_NAVAL_SUPERIORITY, NAVAL_SUPERIORITY, Enemy NONE, BehaviorTree="Naval Superiority Tree"
This seems like a naval warfare, without attacking a city. Defend Units, Attack Unts, Pillage, Patrol.
Naval Superiority Force	UNITTYPE_NAVAL		-- 100% naval
Naval Superiority Force	UNITTYPE_MELEE	1	-- really, one ship only? this is called SUPERIORITY
Naval Superiority Force	UNITTYPE_RANGED	0	
Naval Superiority Force	UNITTYPE_CIVILIAN_LEADER		1
*/
-- strength
UPDATE AiOperationTeams SET InitialStrengthAdvantage = -0.5, OngoingStrengthAdvantage = 1.0 WHERE TeamName = 'Naval Superiority Force' AND OperationName = 'Naval Superiority';
-- composition
INSERT INTO OpTeamRequirements (TeamName, AiType, MinNumber, MaxNumber) VALUES 
('Naval Superiority Force', 'UNITTYPE_LAND_COMBAT', 0, 0), -- AI keeps recruiting land units, setting 100% naval doesn't prevent this
('Naval Superiority Force', 'UNITTYPE_AIR',         0, 0), -- I made planes Ranged, so AI tries to contract them
('Naval Superiority Force', 'UNITTYPE_AIR_SIEGE',   0, 0); -- I made planes Ranged, so AI tries to contract them
UPDATE OpTeamRequirements SET MinNumber = 4, MaxNumber = 9 WHERE TeamName = 'Naval Superiority Force' AND AiType = 'UNITTYPE_NAVAL';
UPDATE OpTeamRequirements SET MinNumber = 2, MaxNumber = 4 WHERE TeamName = 'Naval Superiority Force' AND AiType = 'UNITTYPE_MELEE';
UPDATE OpTeamRequirements SET MinNumber = 2, MaxNumber = 6 WHERE TeamName = 'Naval Superiority Force' AND AiType = 'UNITTYPE_RANGED';
UPDATE OpTeamRequirements SET MinNumber = 0, MaxNumber = 1 WHERE TeamName = 'Naval Superiority Force' AND AiType = 'UNITTYPE_CIVILIAN_LEADER';

/*
Naval Op Early Force - used for "Naval Op Early"
(new) Basically the same as Naval Superiority, but Ranged ships are optional
*/

INSERT INTO AiTeams (TeamName) VALUES
('Naval Op Early Force');

INSERT INTO AiOperationTeams (TeamName,OperationName,InitialStrengthAdvantage,OngoingStrengthAdvantage) VALUES
('Naval Op Early Force', 'Naval Op Early', -0.5, 1.0);

INSERT INTO OpTeamRequirements (TeamName, AiType, MinNumber, MaxNumber) VALUES
('Naval Op Early Force', 'UNITTYPE_NAVAL',       3, 6),
('Naval Op Early Force', 'UNITTYPE_MELEE',       2, 5),
('Naval Op Early Force', 'UNITTYPE_RANGED',      0, 3),
('Naval Op Early Force', 'UNITTYPE_CIVILIAN_LEADER',  0, 1),
('Naval Op Early Force', 'UNITTYPE_LAND_COMBAT', 0, 0);
UPDATE OpTeamRequirements SET MinPercentage = 1, MaxPercentage = 1 WHERE TeamName = 'Naval Op Early Force' AND AiType = 'UNITTYPE_NAVAL';

/*	
How does the game decide which attack/tree to use?
	
BehaviorTree="Early City Assault"
- not using any specific Unit AI Types
- Operation Attack City
- Operation Attack Units
- Operation Pillage
- Operation Siege City
- Build Military Improvement

BehaviorTree="Siege City Assault"
- uses:
UNITTYPE_MELEE & UNITTYPE_SIEGE_SUPPORT - Node 11 (Make Formation) CombatUnit + SupportUnit  -> all support units are here, probably half not needed at all
UNITTYPE_AIR_SIEGE - Node 36 & 51
Node 36: BomberType=UNITTYPE_AIR_SIEGE, Priorities:CombatDistrict, Improvement, PassiveDistrict -> 2 units only qualify (Bomber, JetBomber) - can't require them, because they are not available most of the time!
- operations as above +
- Attack City (46, 52)
+ Operation Ait Assault (36, 51)
*/

---------------------- TEST ---------------------
-- I want to create a defense city with Fighters
-- Behavior tree - standard
-- Diferrent op team

-- assign to Modern strategy
INSERT OR REPLACE INTO AiListTypes (ListType) VALUES
('ModernCityBuilds'); -- when flight is available
INSERT OR REPLACE INTO AiLists (ListType, System) VALUES
('ModernCityBuilds', 'CityEvents');
INSERT OR REPLACE INTO Strategy_Priorities (StrategyType, ListType) VALUES
('STRATEGY_MODERN_CHANGES', 'ModernCityBuilds');
INSERT OR REPLACE INTO AiFavoredItems (ListType, Item, StringVal) VALUES
('ModernCityBuilds', 'CITY_UNDER_THREAT', 'Air City Defense');

-- define operation
INSERT INTO AllowedOperations (ListType, OperationDef) VALUES
('Default_List', 'Air City Defense');
INSERT INTO AiOperationDefs (OperationName,TargetType,TargetParameter,BehaviorTree,Priority,MaxTargetDistInRegion,MaxTargetDistInArea,MaxTargetDistInWorld,MustHaveUnits,OperationType) VALUES
('Air City Defense','TARGET_FRIENDLY_CITY',1,'Simple City Defense',4,-1,-1,0,2,'OP_DEFENSE');

-- define a team
INSERT INTO AiTeams (TeamName) VALUES
('Air City Defense');
INSERT INTO AiOperationTeams (TeamName,OperationName,InitialStrengthAdvantage,OngoingStrengthAdvantage) VALUES
('Air City Defense','Air City Defense',-1,1);
INSERT INTO OpTeamRequirements (TeamName, AiType, MinNumber, MaxNumber) VALUES
('Air City Defense', 'UNITTYPE_CIVILIAN', 0, 0),
('Air City Defense', 'UNITTYPE_NAVAL', 0, 0),
('Air City Defense', 'UNITAI_COMBAT', 0, 5),
('Air City Defense', 'UNITTYPE_AIR', 1, 4),
('Air City Defense', 'UNITTYPE_AIR_SIEGE', 0, 2);

/*
TARGET_FRIENDLY_CITY
- Civilian Builder Capture -> Escort Worker To Camp
- City Defense -> Simple City Defense
TARGET_ENEMY_COMBAT_DISTRICT
- various attacks, including Nuclear and Barbarian
TARGET_BARBARIAN_CAMP
- attack barb camp, tech boost, builder capture [where is Settler Capture???]
TARGET_NAVAL_SUPERIORITY - obvious
TARGET_SETTLE_LOCATION - settle new city
TARGET_ALLY_SUPPORT - aid ally

- not used
TARGET_ENEMY_PASSIVE_DISTRICT - not used
TARGET_NEUTRAL_CITY - not used
TARGET_NEUTRAL_CIVILIAN_UNIT - not used
TARGET_CIVILIAN_UNIT - not used
TARGET_RELIGIOUS_CIVILIAN - not used
TARGET_TRADER - not used
TARGET_LOW_PRIORITY_UNIT
TARGET_MEDIUM_PRIORITY_UNIT
TARGET_HIGH_PRIORITY_UNIT
TARGET_ENEMY_IMPROVEMENT
TARGET_GOODY_HUT

TARGET_AIR_UNIT - interesting - could be used to attack bombers?
*/
