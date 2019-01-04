-- ===========================================================================
-- Real Strategy - Tweaks to Tactics
-- Author: Infixo
-- 2019-01-04: Created
-- ===========================================================================


--    <Row DefnId="0" NodeId="1" TreeName="Simple City Tree" DefaultData="UNITTYPE_SIEGE" />
--UNITTYPE_SIEGE - core - used in "Simple City Tree"?????? - looks like some testing?
-- this tree just attacks enemies nearby, but why Siege unit?
UPDATE TreeData SET DefaultData = 'UNITTYPE_RANGED' WHERE TreeName = 'Simple City Tree' AND NodeId = 1 AND DefnId = 0;


-- ===========================================================================
-- UNIT TYPES
-- ===========================================================================

-- why is Scientist a Leader???
DELETE FROM UnitAiInfos WHERE UnitType = 'UNIT_GREAT_SCIENTIST' AND AiType = 'UNITAI_LEADER';
	
-- why is UNIT_KOREAN_HWACHA siege?
DELETE FROM UnitAiInfos WHERE UnitType = 'UNIT_KOREAN_HWACHA' AND (AiType = 'UNITTYPE_SIEGE' OR AiType = 'UNITTYPE_SIEGE_ALL');

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

INSERT INTO UnitAiInfos (UnitType, AiType) VALUES
('UNIT_BOMBER', 'UNITTYPE_SIEGE_ALL'),
('UNIT_JET_BOMBER', 'UNITTYPE_SIEGE_ALL'),
('UNIT_KHMER_DOMREY', 'UNITTYPE_SIEGE_ALL');

-- UNITTYPE_SIEGE_SUPPORT - ram, tower, medic, engi, baloon, drone, etc.
-- needs to stay this way until BH is modified - it uses this to make a formation


-- ===========================================================================
-- OP TEAMS
-- AiOperationTeams
-- AiOperationDefs
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
-- Seems OK, up to 3 UNITTYPE_SIEGE, so Rams & Towers should count now


/*
City Attack Force - used for:
	- Attack Walled City 2.0, 4.0          => 60%, TARGET_ENEMY_COMBAT_DISTRICT CITY_ASSAULT BehaviorTree="Siege City Assault" MustHaveUnits="10"
	- Wartime Attack Walled City 1.0, 6.0  => 40%, same as above, but MustBeAtWar="true" MustHaveUnits="6"
City Attack Force	UNITAI_COMBAT	5	16
City Attack Force	UNITTYPE_AIR		0
City Attack Force	UNITTYPE_AIR_SIEGE	0	1
City Attack Force	UNITTYPE_CIVILIAN		0
City Attack Force	UNITTYPE_CIVILIAN_LEADER		1
City Attack Force	UNITTYPE_MELEE	2	
City Attack Force	UNITTYPE_NAVAL		0
City Attack Force	UNITTYPE_RANGED	1	
City Attack Force	UNITTYPE_SIEGE	0	3
City Attack Force	UNITTYPE_SIEGE_ALL	1	
City Attack Force	UNITTYPE_SIEGE_SUPPORT	0	2
*/
UPDATE OpTeamRequirements SET MinNumber = 0, MaxNumber = 4 WHERE TeamName = 'City Attack Force' AND AiType = 'UNITTYPE_AIR';
UPDATE OpTeamRequirements SET MinNumber = 0, MaxNumber = 4 WHERE TeamName = 'City Attack Force' AND AiType = 'UNITTYPE_AIR_SIEGE';
UPDATE OpTeamRequirements SET MinNumber = 2                WHERE TeamName = 'City Attack Force' AND AiType = 'UNITTYPE_RANGED';
UPDATE OpTeamRequirements SET MinNumber = 1, MaxNumber = 4 WHERE TeamName = 'City Attack Force' AND AiType = 'UNITTYPE_SIEGE';
UPDATE OpTeamRequirements SET MinNumber = 1, MaxNumber = 3 WHERE TeamName = 'City Attack Force' AND AiType = 'UNITTYPE_SIEGE_SUPPORT';


/*
City Naval Attack Force - used for:
	- all 4 types of attack (war/no war, normal/walled), Condition="IsCoastalTarget"
City Naval Attack Force	UNITTYPE_NAVAL		-- 100% naval
City Naval Attack Force	UNITTYPE_MELEE	0	
City Naval Attack Force	UNITTYPE_RANGED	0	-- can't change that because Ranged are not available in Ancient Era
City Naval Attack Force	UNITTYPE_CIVILIAN_LEADER		1
*/
INSERT INTO OpTeamRequirements (TeamName, AiType, MinNumber, MaxNumber) VALUES
('City Naval Attack Force', 'UNITAI_COMBAT',  3, 8);
UPDATE OpTeamRequirements SET MinNumber = 2 WHERE TeamName = 'City Naval Attack Force' AND AiType = 'UNITTYPE_MELEE';


/*
City Defense - used for:
	- OperationName="City Defense", TARGET_FRIENDLY_CITY, BehaviorTree="Simple City Defense"
City Defense	UNITTYPE_CIVILIAN		0
City Defense	UNITTYPE_CIVILIAN_LEADER		1
City Defense	UNITTYPE_NAVAL		0 -- what if this a naval attack? there is no "naval defense" at all !!!!!
City Defense	UNITAI_COMBAT	0	-- how exactly should we defend without any units?
City Defense	UNITAI_EXPLORE	0	
City Defense	UNITTYPE_SIEGE		0
City Defense	UNITTYPE_AIR		0
City Defense	UNITTYPE_AIR_SIEGE		0
*/
INSERT INTO OpTeamRequirements (TeamName, AiType, MinNumber, MaxNumber) VALUES
('City Defense', 'UNITTYPE_RANGED', 1, NULL), -- could use ranged - WARNING!!!!!!!!!!!
('City Defense', 'UNITTYPE_MELEE',  0, NULL);
UPDATE OpTeamRequirements SET MinNumber = 2, MaxNumber = NULL WHERE TeamName = 'City Defense' AND AiType = 'UNITAI_COMBAT'; -- WARNING!!!!! check if this works at all!!!!
UPDATE OpTeamRequirements SET MinNumber = 0, MaxNumber = 0    WHERE TeamName = 'City Defense' AND AiType = 'UNITAI_EXPLORE'; -- no Scouts pls
UPDATE OpTeamRequirements SET MinNumber = 0, MaxNumber = NULL WHERE TeamName = 'City Defense' AND AiType = 'UNITTYPE_NAVAL'; -- there is no naval defense op
UPDATE OpTeamRequirements SET MinNumber = 0, MaxNumber = NULL WHERE TeamName = 'City Defense' AND AiType = 'UNITTYPE_SIEGE';
UPDATE OpTeamRequirements SET MinNumber = 0, MaxNumber = NULL WHERE TeamName = 'City Defense' AND AiType = 'UNITTYPE_AIR'; -- pls use fighters
UPDATE OpTeamRequirements SET MinNumber = 0, MaxNumber = 0    WHERE TeamName = 'City Defense' AND AiType = 'UNITTYPE_AIR_SIEGE'; -- ok, no bombers


/*
Naval Superiority Force - used for:
	- OperationName="Naval Superiority", TARGET_NAVAL_SUPERIORITY, NAVAL_SUPERIORITY, Enemy NONE, BehaviorTree="Naval Superiority Tree"
This seems like a naval warfare, without attacking a city. Defend Units, Attack Unts, Pillage, Patrol.
Naval Superiority Force	UNITTYPE_NAVAL		-- 100% naval
Naval Superiority Force	UNITTYPE_MELEE	1	-- really, one ship only? this is called SUPERIORITY
Naval Superiority Force	UNITTYPE_RANGED	0	
Naval Superiority Force	UNITTYPE_CIVILIAN_LEADER		1
*/
INSERT INTO OpTeamRequirements (TeamName, AiType, MinNumber, MaxNumber) VALUES
('Naval Superiority Force', 'UNITAI_COMBAT',  2, 10); -- let's do this with at least 2 ships, later test for 3 ships


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
