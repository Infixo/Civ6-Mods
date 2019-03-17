-- ===========================================================================
-- Real Strategy - Main file with Leaders
-- Author: Infixo
-- 2019-01-04: Created
-- ===========================================================================
-- TODO: generic change - make sure DiplomaticActions are connected to Agendas!
-- TODO: R&F usage - Commemorations, Gov Buildings!
-- TODO: some ideas are common - thnk about making TRAITS, like "more TRs", "more wonders", etc.
-- improvements are unique, so they SHOULD be built nonetheless - see Ziggurats!
-- TRAIT_RST_MORE_TRADE_ROUTES (trade?/gold?)
-- TRAIT_RST_MORE_IMPROVEMENTS (infra?)
-- TRAIT_RST_MORE_WONDERS
-- TRAIT_RST_MORE_DISTRICTS (infra?)
-- TRAIT_RST_NAVAL_CIV

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
-- FIXES
-- ===========================================================================

-- 2019-01-03: Some AiLists are assigned to Agenda Traits but registered in AiLists in a wrong column (for leaders, not agendas)
UPDATE AiLists SET LeaderType = NULL, AgendaType = 'TRAIT_AGENDA_BACKSTABBER'      WHERE LeaderType = 'TRAIT_AGENDA_BACKSTABBER';
UPDATE AiLists SET LeaderType = NULL, AgendaType = 'TRAIT_AGENDA_LAST_VIKING_KING' WHERE LeaderType = 'TRAIT_AGENDA_LAST_VIKING_KING';
UPDATE AiLists SET LeaderType = NULL, AgendaType = 'TRAIT_AGENDA_WITH_SHIELD'      WHERE LeaderType = 'TRAIT_AGENDA_WITH_SHIELD';

-- 2018-03-25: AiFavoredItems
UPDATE AiFavoredItems SET Item = 'CIVIC_NAVAL_TRADITION' WHERE Item = 'CIVIC_NAVAL_TRADITIION';


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

-- districts
DELETE FROM AiFavoredItems WHERE ListType = 'MinorCivDistricts' AND Item IN ('DISTRICT_AQUEDUCT', 'DISTRICT_ENTERTAINMENT_COMPLEX', 'DISTRICT_WATER_ENTERTAINMENT_COMPLEX');
UPDATE AiFavoredItems SET Favored = 1 WHERE ListType = 'MinorCivDistricts' AND Item IN ('DISTRICT_AERODROME', 'DISTRICT_ENCAMPMENT');

INSERT INTO AiListTypes (ListType) VALUES
('MinorFavorWalls');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('MinorFavorWalls', 'MINOR_CIV_DEFAULT_TRAIT', 'Buildings');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('MinorFavorWalls', 'BUILDING_WALLS', 1, 100), -- notice that Minors have a hidden bonus to build Walls 200%
('MinorFavorWalls', 'BUILDING_CASTLE', 1, 100),
('MinorFavorWalls', 'BUILDING_STAR_FORT', 1, 100),
('MinorCivUnitBuilds', 'PROMOTION_CLASS_AIR_FIGHTER', 1, 15),
('MinorCivUnitBuilds', 'PROMOTION_CLASS_ANTI_CAVALRY', 1, 15),
('MinorCivUnitBuilds', 'PROMOTION_CLASS_LIGHT_CAVALRY', 1, 15),
('MinorCivUnitBuilds', 'PROMOTION_CLASS_HEAVY_CAVALRY', 1, -50),
('MinorCivUnitBuilds', 'PROMOTION_CLASS_RANGED', 1, 15),
('MinorCivUnitBuilds', 'PROMOTION_CLASS_SIEGE', 1, -50),
('MinorCivUnitBuilds', 'PROMOTION_CLASS_SUPPORT', 1, -50),
--('MinorCivPseudoYields', 'PSEUDOYIELD_CITY_DEFENSES', 1, 200),
--('MinorCivPseudoYields', 'PSEUDOYIELD_CITY_DEFENDING_UNITS', 1, 50),
('MinorCivPseudoYields', 'PSEUDOYIELD_CLEAR_BANDIT_CAMPS', 1, 25),
('MinorCivPseudoYields', 'PSEUDOYIELD_UNIT_AIR_COMBAT', 1, 20),
('MinorCivPseudoYields', 'PSEUDOYIELD_UNIT_NAVAL_COMBAT', 1, -15),
('MinorCivPseudoYields', 'PSEUDOYIELD_UNIT_COMBAT', 1, 15);


/*
INSERT INTO AiListTypes (ListType) VALUES
('MinorCivOperations');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('MinorCivOperations', 'MINOR_CIV_DEFAULT_TRAIT', 'AiOperationTypes');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('MinorCivOperations', 'OP_DEFENSE', 1, 2);
*/


-- ===========================================================================
-- Changes to existing leaders and civs
-- ===========================================================================


-- LEADER_BARBAROSSA / GERMANY
-- TRAIT_RST_MORE_DISTRICTS

-- remove 23 favored Civics, insane!
DELETE FROM AiFavoredItems WHERE ListType = 'BarbarossaCivics';

INSERT INTO AiListTypes (ListType) VALUES
--('BarbarossaDiplomacy'),
('BarbarossaYields'),
('BarbarossaPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
--('BarbarossaDiplomacy',    'TRAIT_LEADER_HOLY_ROMAN_EMPEROR', 'DiplomaticActions'),
('BarbarossaYields',       'TRAIT_LEADER_HOLY_ROMAN_EMPEROR', 'Yields'),
('BarbarossaPseudoYields', 'TRAIT_LEADER_HOLY_ROMAN_EMPEROR', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
--('BarbarossaDiplomacy', 'DIPLOACTION_DECLARE_WAR_MINOR_CIV', 1, 0), -- sorry guys :(
('BarbarossaTechs', 'TECH_INDUSTRIALIZATION', 1, 0), -- !BUGGED!
('BarbarossaCivics', 'CIVIC_GAMES_RECREATION', 1, 0),
('BarbarossaCivics', 'CIVIC_GUILDS', 1, 0),
('BarbarossaCivics', 'CIVIC_EXPLORATION', 1, 0),
('BarbarossaCivics', 'CIVIC_URBANIZATION', 1, 0),
('BarbarossaYields', 'YIELD_FAITH', 1, -15),
('BarbarossaYields', 'YIELD_GOLD', 1, 5),
('BarbarossaYields', 'YIELD_PRODUCTION', 1, 5),
('BarbarossaPseudoYields', 'PSEUDOYIELD_CITY_BASE', 1, -25),
('BarbarossaPseudoYields', 'PSEUDOYIELD_CITY_ORIGINAL_CAPITAL', 1, 100), -- more focus on Minors
('BarbarossaPseudoYields', 'PSEUDOYIELD_DISTRICT', 1, 15), -- more districts
('BarbarossaPseudoYields', 'PSEUDOYIELD_GPP_PROPHET',  1,-25),
('BarbarossaPseudoYields', 'PSEUDOYIELD_GPP_MERCHANT', 1, 10), -- boost comm hubs
('BarbarossaPseudoYields', 'PSEUDOYIELD_GPP_ENGINEER', 1, 15); -- boost hansas


-- LEADER_CATHERINE_DE_MEDICI / FRANCE
-- TRAIT_RST_MORE_IMPROVEMENTS
-- TRAIT_RST_MORE_WONDERS

DELETE FROM AiFavoredItems WHERE ListType = 'CatherineCivics' AND Item = 'CIVIC_DIVINE_RIGHT';

INSERT INTO AiListTypes (ListType) VALUES
('CatherineYields'),
('CatherinePseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('CatherineYields', 'FLYING_SQUADRON_TRAIT', 'Yields'),
('CatherinePseudoYields', 'FLYING_SQUADRON_TRAIT', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('CatherineCivics', 'CIVIC_DIPLOMATIC_SERVICE', 1, 0),
('CatherineYields', 'YIELD_CULTURE', 1, 15),
('CatherineYields', 'YIELD_PRODUCTION', 1, 10),
('CatherineYields', 'YIELD_FAITH', 1, -15),
('CatherinePseudoYields', 'PSEUDOYIELD_GPP_PROPHET', 1, -25),
('CatherinePseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, 25),
('CatherinePseudoYields', 'PSEUDOYIELD_TOURISM', 1, 25),
('CatherinePseudoYields', 'PSEUDOYIELD_WONDER', 1, 25);


-- LEADER_GANDHI / INDIA

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
('IndiaTechs', 'TECH_IRRIGATION', 1, 0), -- !BUGGED!
('IndiaYields', 'YIELD_FOOD',  1, 20),
('IndiaYields', 'YIELD_FAITH', 1, 10),
('IndiaYields', 'YIELD_GOLD',  1,-15),
('IndiaYields', 'YIELD_PRODUCTION', 1, -10),
('IndiaPseudoYields', 'PSEUDOYIELD_GPP_PROPHET', 1, 15), -- holy sites
('IndiaPseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, 15); -- stepwell

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
('GandhiPseudoYields', 'PSEUDOYIELD_CITY_BASE', 1, -100), -- do NOT conquer neighbors
('GandhiPseudoYields', 'PSEUDOYIELD_CITY_POPULATION', 1, -100), -- do NOT conquer neighbors
('GandhiPseudoYields', 'PSEUDOYIELD_HAPPINESS', 1, 20),
('GandhiPseudoYields', 'PSEUDOYIELD_GPP_PROPHET', 1, 10),
('GandhiPseudoYields', 'PSEUDOYIELD_UNIT_COMBAT', 1, -15), -- obvious
('GandhiPseudoYields', 'PSEUDOYIELD_UNIT_RELIGIOUS', 1, 15), -- to differ from CHANDRAGUPTA
('GandhiPseudoYields', 'PSEUDOYIELD_DIPLOMATIC_BONUS', 1, 25), -- peace!
-- nukes, because... Gandhi
('PeacekeeperWarLimits', 'DIPLOACTION_USE_NUCLEAR_WEAPON', 1, 0),
('GandhiPseudoYields', 'PSEUDOYIELD_NUCLEAR_WEAPON', 1, 20),
('GandhiProjects', 'PROJECT_MANHATTAN_PROJECT', 1, 0),
('GandhiProjects', 'PROJECT_OPERATION_IVY', 1, 0),
('GandhiProjects', 'PROJECT_BUILD_NUCLEAR_DEVICE', 1, 0),
('GandhiProjects', 'PROJECT_BUILD_THERMONUCLEAR_DEVICE', 1, 0);


-- LEADER_CLEOPATRA / EGYPT
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
('CleopatraYields', 'YIELD_SCIENCE', 1, -10),
('CleopatraWonders', 'BUILDING_ORACLE', 1, 0),
('CleopatraPseudoYields', 'PSEUDOYIELD_CITY_BASE', 1, -100), -- do NOT conquer neighbors
('CleopatraPseudoYields', 'PSEUDOYIELD_CITY_POPULATION', 1, -100), -- do NOT conquer neighbors
('CleopatraPseudoYields', 'PSEUDOYIELD_GPP_MERCHANT', 1, 15),
--('CleopatraPseudoYields', 'PSEUDOYIELD_GPP_ADMIRAL', 1, 15),
('CleopatraPseudoYields', 'PSEUDOYIELD_GPP_PROPHET', 1, 10),
('CleopatraPseudoYields', 'PSEUDOYIELD_UNIT_TRADE', 1, 50),
('CleopatraPseudoYields', 'PSEUDOYIELD_WONDER', 1, 25),
('CleopatraPseudoYields', 'PSEUDOYIELD_TOURISM', 1, 15),
('CleopatraPseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, 15), -- sphinx
('CleopatraPseudoYields', 'PSEUDOYIELD_DISTRICT', 1, 15);


-- LEADER_GILGAMESH / SUMERIA
-- Ziggurat has no tech req... so broken! - it is the ONLY unique improvement like this

INSERT INTO AiListTypes (ListType) VALUES
('GilgameshTechs'),
('GilgameshCivics'),
('GilgameshWonders'),
('GilgameshPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('GilgameshTechs',        'TRAIT_LEADER_ADVENTURES_ENKIDU', 'Technologies'),
('GilgameshCivics',       'TRAIT_LEADER_ADVENTURES_ENKIDU', 'Civics'),
('GilgameshWonders',      'TRAIT_LEADER_ADVENTURES_ENKIDU', 'Buildings'),
('GilgameshPseudoYields', 'TRAIT_LEADER_ADVENTURES_ENKIDU', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('GilgameshDiplomacy', 'DIPLOACTION_ALLIANCE' , 1, 0),
('GilgameshDiplomacy', 'DIPLOACTION_JOINT_WAR' , 1, 0),
('GilgameshDiplomacy', 'DIPLOACTION_RENEW_ALLIANCE' , 1, 0),
('GilgameshDiplomacy', 'DIPLOACTION_DECLARE_WAR_MINOR_CIV' , 0, 0), -- friend of CS
('GilgameshTechs', 'TECH_STIRRUPS' , 1, 0), -- !BUGGED!
('GilgameshTechs', 'TECH_WRITING' , 1, 0), -- !BUGGED!
('GilgameshTechs', 'TECH_EDUCATION' , 1, 0), -- !BUGGED!
('GilgameshCivics', 'CIVIC_FOREIGN_TRADE' , 1, 0), -- joint war
('GilgameshCivics', 'CIVIC_CIVIL_SERVICE' , 1, 0), -- alliance
('GilgameshPseudoYields', 'PSEUDOYIELD_GPP_SCIENTIST' , 1, 25),
('GilgameshPseudoYields', 'PSEUDOYIELD_CLEAR_BANDIT_CAMPS' , 1, 25), -- +15%
('GilgameshPseudoYields', 'PSEUDOYIELD_IMPROVEMENT' , 1, -15), -- he builds Ziggurats EVERYWHERE
('GilgameshPseudoYields', 'PSEUDOYIELD_INFLUENCE' , 1, 15); -- friend of CS

-- Rise & Fall
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value)
SELECT 'GilgameshWonders', 'BUILDING_KILWA_KISIWANI', 1, 0
FROM Types WHERE Type = 'BUILDING_KILWA_KISIWANI';


-- LEADER_GORGO & LEADER_PERICLES / GREECE
-- GREECE has an extra Wildcard slot & Acropolis, boosted Culture - nothing to add here
-- GORGO seems OK
-- PERICLES seems OK, CS ally, low faith

-- There is a mixup with Pericles's lists
UPDATE AiFavoredItems SET Item = 'BUILDING_POTALA_PALACE' WHERE ListType = 'PericlesWonders' AND Item = 'PSEUDOYIELD_INFLUENCE';
UPDATE AiFavoredItems SET Item = 'PSEUDOYIELD_INFLUENCE'  WHERE ListType = 'PericlesEnvoys'  AND Item = 'BUILDING_POTALA_PALACE';

-- Rise & Fall
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value)
SELECT 'PericlesWonders', 'BUILDING_KILWA_KISIWANI', 1, 0
FROM Types WHERE Type = 'BUILDING_KILWA_KISIWANI';


-- LEADER_HARDRADA / NORWAY
-- high forest & coast, 

-- 2018-12-25: Norwegian Longship has no PseudoYield assigned and Harald has a boost for that in his strategy!
UPDATE Units SET PseudoYieldType = 'PSEUDOYIELD_UNIT_NAVAL_COMBAT' WHERE UnitType = 'UNIT_NORWEGIAN_LONGSHIP';

DELETE FROM AiFavoredItems WHERE ListType = 'LastVikingKingCoastSettlement';
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value, StringVal) VALUES
('LastVikingKingCoastSettlement', 'Coastal',           0, 15,             NULL), -- vanilla def. 30
('LastVikingKingCoastSettlement', 'Foreign Continent', 0, 20,             NULL), -- try to settle other continents before others
('LastVikingKingCoastSettlement', 'Specific Feature',  0,  3, 'FEATURE_FOREST'); -- close to forests

UPDATE AiFavoredItems SET Value = 25 WHERE ListType = 'LastVikingKingNavalPreference' AND Item = 'PSEUDOYIELD_UNIT_NAVAL_COMBAT'; -- def. 100

INSERT INTO AiListTypes (ListType) VALUES
('HaraldYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('HaraldYields', 'TRAIT_AGENDA_LAST_VIKING_KING', 'Yields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('HaraldTechs', 'TECH_MINING', 1, 0), -- !BUGGED!
('HaraldCivics', 'CIVIC_MYSTICISM', 1, 0),
('HaraldCivics', 'CIVIC_FOREIGN_TRADE', 1, 0),
('HaraldYields', 'YIELD_FAITH', 1, 10),
('LastVikingKingNavalPreference', 'PSEUDOYIELD_CLEAR_BANDIT_CAMPS', 1, 15), -- get rid of barb ships asap
('LastVikingKingNavalPreference', 'PSEUDOYIELD_GPP_PROPHET', 1, 10), -- get the Holy Site asap
('LastVikingKingNavalPreference', 'PSEUDOYIELD_ENVIRONMENT', 1, 20), -- don't chop forests
('LastVikingKingNavalPreference', 'PSEUDOYIELD_UNIT_COMBAT', 1, -15), -- more ships, less land
('LastVikingKingNavalPreference', 'PSEUDOYIELD_UNIT_RELIGIOUS', 1, 10),
('LastVikingKingNavalPreference', 'PSEUDOYIELD_UNIT_SETTLER', 1, 10); -- more cities


-- LEADER_HOJO / JAPAN

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
('HoJoSettlement', 'Foreign Continent', 0, -8),
('HoJoSettlement', 'Nearest Friendly City', 0, -2), -- compact empire
('HoJoSettlement', 'Coastal', 0, 20),
('HoJoTechs', 'TECH_APPRENTICESHIP', 1, 0), -- !BUGGED!
('HoJoTechs', 'TECH_INDUSTRIALIZATION', 1, 0), -- !BUGGED!
('HoJoYields', 'YIELD_FOOD',       1, 10),
('HoJoYields', 'YIELD_FAITH',      1,  5),
('HoJoYields', 'YIELD_CULTURE',    1, 10),
('HoJoYields', 'YIELD_PRODUCTION', 1, 10),
('HoJoYields', 'YIELD_GOLD',       1,-15), -- balance
('HoJoYields', 'YIELD_SCIENCE',    1,-10), -- balance
('HoJoPseudoYields', 'PSEUDOYIELD_DISTRICT', 1, 15),
('HoJoPseudoYields', 'PSEUDOYIELD_GPP_ENGINEER', 1, 20),
('HoJoPseudoYields', 'PSEUDOYIELD_HAPPINESS', 1, 20),
('HoJoPseudoYields', 'PSEUDOYIELD_UNIT_COMBAT', 1, 15);


-- LEADER_MVEMBA / KONGO

INSERT INTO AiListTypes (ListType) VALUES
('KongoYields'),
('KongoPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('KongoYields',       'TRAIT_CIVILIZATION_NKISI', 'Yields'),
('KongoPseudoYields', 'TRAIT_CIVILIZATION_NKISI', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('KongoYields',       'YIELD_CULTURE', 1,  5),
('KongoYields',       'YIELD_FOOD',    1, 10),
('KongoYields',       'YIELD_SCIENCE', 1,-10),
('KongoPseudoYields', 'PSEUDOYIELD_GPP_MERCHANT', 1, 10),
('KongoPseudoYields', 'PSEUDOYIELD_GPP_WRITER', 1, 10), -- to build Theater Squares
('KongoPseudoYields', 'PSEUDOYIELD_GPP_ARTIST', 1, 10),
('KongoPseudoYields', 'PSEUDOYIELD_GPP_MUSICIAN', 1, 10),
('KongoPseudoYields', 'PSEUDOYIELD_GREATWORK_ARTIFACT',  1, 25),
('KongoPseudoYields', 'PSEUDOYIELD_GREATWORK_LANDSCAPE', 1,-15),
('KongoPseudoYields', 'PSEUDOYIELD_GREATWORK_MUSIC',     1,-15),
('KongoPseudoYields', 'PSEUDOYIELD_GREATWORK_PORTRAIT',  1,-15),
('KongoPseudoYields', 'PSEUDOYIELD_GREATWORK_RELIC',     1, 25),
('KongoPseudoYields', 'PSEUDOYIELD_GREATWORK_RELIGIOUS', 1,-15),
('KongoPseudoYields', 'PSEUDOYIELD_GREATWORK_SCULPTURE', 1, 25),
('KongoPseudoYields', 'PSEUDOYIELD_GREATWORK_WRITING',   1,-15),
('KongoPseudoYields', 'PSEUDOYIELD_ENVIRONMENT', 1, 20), -- leave jungle
('KongoPseudoYields', 'PSEUDOYIELD_UNIT_ARCHAEOLOGIST', 1, 25);


-- LEADER_PEDRO / BRAZIL
-- lower a bit GP obsession, balance defense

DELETE FROM AiFavoredItems WHERE ListType = 'PedroCivics' AND Item = 'CIVIC_CAPITALISM';
DELETE FROM AiFavoredItems WHERE ListType = 'PedroCivics' AND Item = 'CIVIC_GUILDS';
DELETE FROM AiFavoredItems WHERE ListType = 'PedroCivics' AND Item = 'CIVIC_NATIONALISM';
DELETE FROM AiFavoredItems WHERE ListType = 'PedroTechs'  AND Item = 'TECH_ASTROLOGY';

DELETE FROM AiFavoredItems WHERE ListType = 'GreatPersonObsessedGreatPeople' AND Item = 'PSEUDOYIELD_GPP_PROPHET'; -- don't be obsessed with him - there is only one!
UPDATE AiFavoredItems SET Value =  25 WHERE ListType = 'GreatPersonObsessedGreatPeople'; -- def. 50

INSERT INTO AiListTypes (ListType) VALUES
('PedroPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('PedroPseudoYields', 'TRAIT_LEADER_MAGNANIMOUS', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('PedroCivics', 'CIVIC_NATURAL_HISTORY', 1, 0),
('PedroPseudoYields', 'PSEUDOYIELD_CITY_BASE', 1, -100), -- do NOT conquer neighbors
('PedroPseudoYields', 'PSEUDOYIELD_CITY_POPULATION', 1, -100), -- do NOT conquer neighbors
('PedroPseudoYields', 'PSEUDOYIELD_ENVIRONMENT', 1, 20), -- leave jungle
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
('PeterPseudoYields', 'PSEUDOYIELD_GPP_ARTIST', 1, 10),
('PeterPseudoYields', 'PSEUDOYIELD_GPP_MUSICIAN', 1, 10),
('PeterPseudoYields', 'PSEUDOYIELD_GPP_WRITER', 1, 10),
('PeterWonders', 'BUILDING_STONEHENGE', 0, 0), -- don't build it, build Lavra!
('PeterWonders', 'BUILDING_BOLSHOI_THEATRE', 1, 0),
('PeterWonders', 'BUILDING_HERMITAGE', 1, 0);

-- Rise & Fall
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value)
SELECT 'PeterWonders', 'BUILDING_ST_BASILS_CATHEDRAL', 1, 0
FROM Types WHERE Type = 'BUILDING_ST_BASILS_CATHEDRAL';


-- LEADER_PHILIP_II / SPAIN

UPDATE AiFavoredItems SET Favored = 0, Value = 40 WHERE ListType = 'PhilipForeignSettlement' AND Item = 'Foreign Continent'; -- Philip II, def. 60
UPDATE AiFavoredItems SET Value = 10 WHERE ListType = 'CounterReformerInquisitorPreference' AND Item = 'UNIT_INQUISITOR'; -- was 1 -- Philip II

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
('PhilipPseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, 15), -- mission
('PhilipPseudoYields', 'PSEUDOYIELD_UNIT_RELIGIOUS', 1, 10),
('PhilipPseudoYields', 'PSEUDOYIELD_GPP_PROPHET', 1, 10),
('PhilipPseudoYields', 'PSEUDOYIELD_GPP_ADMIRAL', 1, 15),
('PhilipPseudoYields', 'PSEUDOYIELD_UNIT_NAVAL_COMBAT', 1, 15);

-- Rise & Fall
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value)
SELECT 'PhilipWonders', 'BUILDING_STATUE_LIBERTY', 1, 0
FROM Types WHERE Type = 'BUILDING_STATUE_LIBERTY';


-- LEADER_QIN / CHINA

INSERT INTO AiListTypes (ListType) VALUES
('QinPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('QinPseudoYields', 'FIRST_EMPEROR_TRAIT', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
--('QinCivics', 'CIVIC_CRAFTSMANSHIP', 1, 0),
('QinPseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, 25), -- great wall
('QinPseudoYields', 'PSEUDOYIELD_TOURISM', 1, 15);


-- LEADER_SALADIN / ARABIA

INSERT INTO AiListTypes (ListType) VALUES
('SaladinYields'),
('SaladinPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('SaladinYields',       'TRAIT_LEADER_RIGHTEOUSNESS_OF_FAITH', 'Yields'),
('SaladinPseudoYields', 'TRAIT_LEADER_RIGHTEOUSNESS_OF_FAITH', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('SaladinYields', 'YIELD_FAITH', 1, 15), -- we are still religious, nonetheless
('SaladinTechs', 'TECH_WRITING', 1, 0), -- get Campus first, then Holy Site -- !BUGGED!
('SaladinPseudoYields', 'PSEUDOYIELD_GPP_PROPHET', 1, -10),
('SaladinPseudoYields', 'PSEUDOYIELD_GPP_SCIENTIST', 1, 10);


-- LEADER_TOMYRIS / SCYTHIA
-- can we make her build Stables instead of Barracks?
-- Kurgan

-- Scythian Horse Archer is a Ranged Units, but since this is a UU, so it should be boosted already
UPDATE AiFavoredItems SET Value = 20 WHERE ListType = 'TomyrisiUnitBuilds' AND Item = 'PROMOTION_CLASS_LIGHT_CAVALRY'; -- was 1

INSERT INTO AiListTypes (ListType) VALUES
('ScythiaFavorStable');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('ScythiaFavorStable', 'TRAIT_CIVILIZATION_EXTRA_LIGHT_CAVALRY', 'Buildings');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('TomyrisDiplomacy', 'DIPLOACTION_DECLARE_FRIENDSHIP', 1, 0),
('TomyrisTechs', 'TECH_ASTROLOGY', 1, 0), -- religion as a backup plan -- !BUGGED!
('ScythiaFavorStable', 'BUILDING_STABLE', 1, 0);


-- LEADER_TRAJAN / ROME
-- expansionist, but no changes to PlotEvaluations - does it actually work?
-- they should be within trade range of the capital - how many tiles is that? - 15 tiles, well enough...
-- baths allow for crappy cities (less water)
-- Roman Fort

INSERT INTO AiListTypes (ListType) VALUES
('TrajanSettlement'),
('TrajanPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('TrajanSettlement',   'TRAIT_LEADER_EXPANSIONIST', 'PlotEvaluations'), -- Trajan only
('TrajanPseudoYields', 'TRAIT_LEADER_EXPANSIONIST', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('TrajanWonders', 'BUILDING_STONEHENGE', 0, 0),
('TrajanSettlement', 'Nearest Friendly City', 0, -1),
('TrajanSettlement', 'Fresh Water', 0, -10),
('TrajanPseudoYields', 'PSEUDOYIELD_CITY_BASE', 1, 50),
('TrajanPseudoYields', 'PSEUDOYIELD_CITY_POPULATION', 1, -25),
('TrajanPseudoYields', 'PSEUDOYIELD_CITY_ORIGINAL_CAPITAL', 1, -50),
('TrajanPseudoYields', 'PSEUDOYIELD_CITY_DEFENSES', 1, -15),
('TrajanPseudoYields', 'PSEUDOYIELD_CITY_DEFENDING_UNITS', 1, -15),
('TrajanPseudoYields', 'PSEUDOYIELD_HAPPINESS', 1, 20),
('TrajanPseudoYields', 'PSEUDOYIELD_UNIT_SETTLER', 1, 10); -- more crappy cities

-- Rise & Fall
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value)
SELECT 'TrajanWonders', 'BUILDING_TEMPLE_ARTEMIS', 1, 0
FROM Types WHERE Type = 'BUILDING_TEMPLE_ARTEMIS';


-- LEADER_T_ROOSEVELT / AMERICA
-- culture, Film Studio

-- LowReligiousPreferenceYields - but we need faith for National Parks!
DELETE FROM LeaderTraits WHERE LeaderType = 'LEADER_T_ROOSEVELT' AND TraitType = 'TRAIT_LEADER_LOW_RELIGIOUS_PREFERENCE';

DELETE FROM AiFavoredItems WHERE ListType = 'RooseveltCivics' AND Item = 'CIVIC_DIVINE_RIGHT' OR Item = 'CIVIC_POLITICAL_PHILOSOPHY';

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value)
SELECT 'RooseveltCivics', PrereqCivic, 1, 0
FROM Governments WHERE GovernmentType = 'GOVERNMENT_CLASSICAL_REPUBLIC';

INSERT INTO AiListTypes (ListType) VALUES
('RooseveltUnits'),
('RooseveltPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('RooseveltUnits',        'TRAIT_LEADER_ROOSEVELT_COROLLARY', 'Units'),
('RooseveltPseudoYields', 'TRAIT_LEADER_ROOSEVELT_COROLLARY', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('RooseveltTechs', 'TECH_POTTERY', 1, 0), -- !BUGGED!
('RooseveltCivics', 'CIVIC_EXPLORATION', 1, 0),
('RooseveltUnits', 'UNIT_NATURALIST', 1, 25),
('RooseveltWonders', 'BUILDING_STONEHENGE', 0, 0), -- low religion
('RooseveltPseudoYields', 'PSEUDOYIELD_UNIT_AIR_COMBAT', 1, 25),
('RooseveltPseudoYields', 'PSEUDOYIELD_GPP_PROPHET', 1, -50),
('RooseveltPseudoYields', 'PSEUDOYIELD_GPP_WRITER', 1, 10),
('RooseveltPseudoYields', 'PSEUDOYIELD_ENVIRONMENT', 1, 20), -- national parks?
('RooseveltPseudoYields', 'PSEUDOYIELD_TOURISM', 1, 15), -- national parks?
('RooseveltPseudoYields', 'PSEUDOYIELD_UNIT_RELIGIOUS', 1, -25); -- get only Naturalists

-- Rise & Fall
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value)
SELECT 'RooseveltWonders', 'BUILDING_STATUE_LIBERTY', 1, 0 -- who else if not him???
FROM Types WHERE Type = 'BUILDING_STATUE_LIBERTY';


-- LEADER_VICTORIA / ENGLAND

UPDATE AiFavoredItems SET Favored = 0, Value = 40 WHERE ListType = 'SettleAllContinents' AND Item = 'Foreign Continent'; -- Victoria, down from 120 (!)

INSERT INTO AiListTypes (ListType) VALUES
('EnglandPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('EnglandPseudoYields', 'TRAIT_CIVILIZATION_DOUBLE_ARCHAEOLOGY_SLOTS', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('VictoriaWonders', 'BUILDING_BIG_BEN', 1, 0),
('EnglandPseudoYields', 'PSEUDOYIELD_GREATWORK_ARTIFACT',  1, 50),
('EnglandPseudoYields', 'PSEUDOYIELD_GREATWORK_LANDSCAPE', 1,-25),
('EnglandPseudoYields', 'PSEUDOYIELD_GREATWORK_PORTRAIT',  1,-25),
('EnglandPseudoYields', 'PSEUDOYIELD_GREATWORK_RELIGIOUS', 1,-25),
('EnglandPseudoYields', 'PSEUDOYIELD_GREATWORK_SCULPTURE', 1,-25),
('EnglandPseudoYields', 'PSEUDOYIELD_UNIT_ARCHAEOLOGIST', 1, 100);

-- Rise & Fall
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value)
SELECT 'VictoriaWonders', 'BUILDING_STATUE_LIBERTY', 1, 0
FROM Types WHERE Type = 'BUILDING_STATUE_LIBERTY';


/*
Can this be used to gain army size (catch up mechanic)?
StandingArmyPseudoYields -> TRAIT_AGENDA_PREFER_STANDING_ARMY -> AGENDA_STANDING_ARMY (random)
Always tries to keep a large standing army. Respects other civilizations with large armies. 
exclusive with: AGENDA_QUEEN_OF_NILE (Likes civilizations with powerful militaries, and will try to ally with them to avoid conflict.), AGENDA_BUSHIDO (Likes civilizations that have both a strong military)
StandingArmyPseudoYields	PSEUDOYIELD_STANDING_ARMY_NUMBER	1	33   -- def. 1
StandingArmyPseudoYields	PSEUDOYIELD_STANDING_ARMY_VALUE	1	50 -- def. 0.1
*/


-- ===========================================================================
-- RANDOM AGENDAS
-- These agendas are no longer in use
-- AGENDA_BARBARIAN_LOVER / TRAIT_AGENDA_BARBARIAN_LOVER (Sympathizes with the barbarians.  Does not like civilizations that destroy barbarian outposts.)
-- AGENDA_NATURALISTT / RAIT_AGENDA_NATURALIST (Tries to find all natural wonders.  Likes civilizations that keep Woods and Rainforest unchopped, and those that establish National Parks.)
-- ===========================================================================


-- AGENDA_AIRPOWER / TRAIT_AGENDA_PREFER_AIRPOWER / OK
--		<Row ListType="AirpowerLoverAirpowerPreference" AgendaType="TRAIT_AGENDA_PREFER_AIRPOWER" System="PseudoYields"/>
--		<Row ListType="AirpowerLoverAirpowerPreference" Item="PSEUDOYIELD_UNIT_AIR_COMBAT" Value="50"/>


-- AGENDA_CITY_STATE_ALLY / TRAIT_AGENDA_CITY_STATE_ALLY / OK
--		<Row ListType="CityStateAllyInfluencePreference" AgendaType="TRAIT_AGENDA_CITY_STATE_ALLY" System="PseudoYields"/>
--		<Row ListType="CityStateAllyInfluencePreference" Item="PSEUDOYIELD_INFLUENCE" Value="25"/>
--		<Row ListType="CityStateAllyNoWarPreference" AgendaType="TRAIT_AGENDA_CITY_STATE_ALLY" System="DiplomaticActions"/>
--		<Row ListType="CityStateAllyNoWarPreference" Item="DIPLOACTION_DECLARE_WAR_MINOR_CIV" Favored="false"/>


-- AGENDA_CITY_STATE_PROTECTOR / TRAIT_AGENDA_PREFER_CITY_STATE_PROTECTOR / OK
-- Emphasizes protectorate wars. Admires civilizations that start protectorate wars. Dislikes civilizations that attack city states.
--		<Row ListType="CitySateProtectionLoverCityStateProtectionPreference" AgendaType="TRAIT_AGENDA_PREFER_CITY_STATE_PROTECTOR" System="DiplomaticActions"/>
--		<Row ListType="CitySateProtectionLoverCityStateProtectionPreference" Item="DIPLOACTION_DECLARE_PROTECTORATE_WAR" Favored="true"/>


-- AGENDA_CIVILIZED / TRAIT_AGENDA_PREFER_CLEAR_BANDIT_CAMPS / OK
-- Hates barbarians. Likes civilizations that clear out barbarian outposts. Does not like civilizations that ignore barbarian outposts.
--		<Row ListType="ClearingBarbCampLoverClearingBarbCampPreference" AgendaType="TRAIT_AGENDA_PREFER_CLEAR_BANDIT_CAMPS" System="PseudoYields"/>
--		<Row ListType="ClearingBarbCampLoverClearingBarbCampPreference" Item="PSEUDOYIELD_CLEAR_BANDIT_CAMPS" Value="5"/>

UPDATE AiFavoredItems SET Value = 25 WHERE ListType = 'ClearingBarbCampLoverClearingBarbCampPreference' AND Item = 'PSEUDOYIELD_CLEAR_BANDIT_CAMPS';


-- AGENDA_CULTURED / TRAIT_AGENDA_PREFER_CULTURE / OK
--Tries to build up [ICON_Culture] Culture, and likes civilizations that also focus on [ICON_Culture] Culture.
--		<Row ListType="CultureLoverCulturePreference" AgendaType="TRAIT_AGENDA_PREFER_CULTURE" System="Yields"/>
--		<Row ListType="CultureLoverCulturePreference" Item="YIELD_CULTURE" Value="20"/>


-- AGENDA_DARWINIST / TRAIT_AGENDA_ENJOYS_WAR / TRAIT_AGENDA_IGNORE_WARMONGERING / OK
-- Likes to see civilizations at war, and believes in constant struggle.
--		<Row ListType="DarwinistIgnoreWarmongerValue" AgendaType="TRAIT_AGENDA_IGNORE_WARMONGERING" System="PseudoYields"/>
--		<Row ListType="DarwinistIgnoreWarmongerValue" Item="PSEUDOYIELD_DIPLOMATIC_BONUS" Value="-100"/>

INSERT INTO AiListTypes (ListType) VALUES
('DarwinistEnjoysWarDiplomacy'),
('DarwinistEnjoysWarPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('DarwinistEnjoysWarDiplomacy',    'TRAIT_AGENDA_ENJOYS_WAR', 'DiplomaticActions'),
('DarwinistEnjoysWarPseudoYields', 'TRAIT_AGENDA_ENJOYS_WAR', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('DarwinistEnjoysWarDiplomacy', 'DIPLOACTION_DENOUNCE', 1, 0),
('DarwinistEnjoysWarDiplomacy', 'DIPLOACTION_DECLARE_WAR_MINOR_CIV', 1, 0),
('DarwinistEnjoysWarDiplomacy', 'DIPLOACTION_DECLARE_SURPRISE_WAR', 1, 0),
('DarwinistEnjoysWarDiplomacy', 'DIPLOACTION_JOINT_WAR', 1, 0),
('DarwinistEnjoysWarDiplomacy', 'DIPLOACTION_THIRD_PARTY_WAR', 1, 0),
('DarwinistEnjoysWarPseudoYields', 'PSEUDOYIELD_CITY_DEFENSES', 1, -15),
('DarwinistEnjoysWarPseudoYields', 'PSEUDOYIELD_CITY_DEFENDING_UNITS', 1, -15),
('DarwinistEnjoysWarPseudoYields', 'PSEUDOYIELD_STANDING_ARMY_NUMBER', 1, 10),
('DarwinistEnjoysWarPseudoYields', 'PSEUDOYIELD_STANDING_ARMY_VALUE', 1, 15);
INSERT INTO AiFavoredItems (ListType, Item, Favored)
SELECT 'DarwinistEnjoysWarDiplomacy', DiplomaticActionType, 1
FROM DiplomaticActions
WHERE UIGroup = 'FORMALWAR';


-- AGENDA_DEVOUT / TRAIT_AGENDA_PREFER_FAITH / OK
--		<Row ListType="FaithLoverFaithPreference" AgendaType="TRAIT_AGENDA_PREFER_FAITH" System="Yields"/>
--		<Row ListType="FaithLoverFaithPreference" Item="YIELD_FAITH" Value="20"/>


-- AGENDA_ENVIRONMENTALIST / TRAIT_AGENDA_PREFER_ENVIRONMENT / OK
-- LEADER_T_ROOSEVELT has 33% chance
-- Builds National Parks, doesn't clear features, plants forests. Likes civilizations that plant forests or found National Parks. Dislikes civilizations that clear features.
--		<Row ListType="EnvironmentLoverEnvironmentPreference" AgendaType="TRAIT_AGENDA_PREFER_ENVIRONMENT" System="PseudoYields"/>
--		<Row ListType="EnvironmentLoverEnvironmentPreference" Item="PSEUDOYIELD_ENVIRONMENT" Value="5"/>

UPDATE AiFavoredItems SET Value = 25 WHERE ListType = 'EnvironmentLoverEnvironmentPreference' AND Item = 'PSEUDOYIELD_ENVIRONMENT';
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('EnvironmentLoverEnvironmentPreference', 'PSEUDOYIELD_IMPROVEMENT', 1, -25);


-- AGENDA_EXPLOITATIVE / TRAIT_AGENDA_PREFER_EXPLOITATION
--Clears all features and improves all possible tiles. Likes civilizations with a high percentage of improved tiles. Dislikes civilizations with low percentage of improved tiles or that found National Parks.
--		<Row ListType="ExploitationLoverExploitationPreference" AgendaType="TRAIT_AGENDA_PREFER_EXPLOITATION" System="PseudoYields"/>
--		<Row ListType="ExploitationLoverExploitationPreference" Item="PSEUDOYIELD_IMPROVEMENT" Value="5"/>
		
UPDATE AiFavoredItems SET Value = 25 WHERE ListType = 'ExploitationLoverExploitationPreference' AND Item = 'PSEUDOYIELD_IMPROVEMENT';
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('ExploitationLoverExploitationPreference', 'PSEUDOYIELD_ENVIRONMENT', 1, -25);


-- AGENDA_EXPLORER / TRAIT_AGENDA_EXPLORATION_OBSESSED
-- Tries to explore the map, and likes civilizations that have explored less of the map than itself and dislikes civilizations that have explored more of the map than itself.
--		<Row ListTYpe="ExplorationObsessedExplorers" AgendaType="TRAIT_AGENDA_EXPLORATION_OBSESSED" System="PseudoYields"/>
--		<Row ListType="ExplorationObsessedExplorers" Item="PSEUDOYIELD_UNIT_EXPLORER" Value="50"/>

INSERT INTO AiListTypes (ListType) VALUES
('ExplorationObsessedScoutUses');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('ExplorationObsessedScoutUses', 'TRAIT_AGENDA_EXPLORATION_OBSESSED', 'AiScoutUses');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('ExplorationObsessedScoutUses', 'DEFAULT_LAND_SCOUTS', 1, 100),
('ExplorationObsessedScoutUses', 'DEFAULT_NAVAL_SCOUTS', 1, 100),
('ExplorationObsessedScoutUses', 'NAVAL_SCOUTS_FOR_WORLD_EXPLORATION', 1, 100);


-- AGENDA_FUN_LOVING / TRAIT_AGENDA_PREFER_HAPPINESS / OK
-- Tries to make the citizens in each city as happy as possible. Likes civilizations that also develop in this fashion

INSERT INTO AiListTypes (ListType) VALUES
('PreferHappinessPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('PreferHappinessPseudoYields', 'TRAIT_AGENDA_PREFER_HAPPINESS', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('PreferHappinessPseudoYields', 'PSEUDOYIELD_HAPPINESS', 1, 25);


-- AGENDA_GREAT_PERSON_ADVOCATE / TRAIT_AGENDA_GREAT_PERSON_ADVOCATE / OK
-- Likes civilizations who are not competing for [ICON_GreatPerson] Great People, and will recruit [ICON_GreatPerson] Great People whenever possible.
--		<Row ListType="GreatPersonObsessedGreatPeople" AgendaType="TRAIT_AGENDA_GREAT_PERSON_OBSESSED" System="PseudoYields"/> -> this is for LEADER_PEDRO
--		<Row ListType="GreatPersonObsessedGreatPeople" AgendaType="TRAIT_AGENDA_GREAT_PERSON_ADVOCATE" System="PseudoYields"/> -> this is for Random Agenda
-- OK, this list is updated with LEADER_PEDRO

	
-- AGENDA_IDEOLOGUE / TRAIT_AGENDA_PREFER_SAME_GOVERNMENT / OK
-- Favors civilizations with the same type of government, dislikes civilizations that have different governments, and really dislikes civilizations with different governments of the same era as its own.
-- Can't influence anything here


-- AGENDA_INDUSTRIALIST / TRAIT_AGENDA_PREFER_INDUSTRY / OK
--		<Row ListType="IndustryLoverIndustryPreference" AgendaType="TRAIT_AGENDA_PREFER_INDUSTRY" System="Yields"/>
--		<Row ListType="IndustryLoverIndustryPreference" Item="YIELD_PRODUCTION" Value="20"/>


-- AGENDA_MONEY_GRUBBER / TRAIT_AGENDA_PREFER_INCOME / OK
--		<Row ListType="MoneyGrubberGoldPreference" AgendaType="TRAIT_AGENDA_PREFER_INCOME" System="Yields"/>
--		<Row ListType="MoneyGrubberGoldPreference" Item="YIELD_GOLD" Value="20"/>

		
-- AGENDA_NUKE_LOVER / TRAIT_AGENDA_PREFER_NUKES / OK
-- LEADER_GANDHI has 70%
--		<Row ListType="NukeLoverNukePreference" AgendaType="TRAIT_AGENDA_PREFER_NUKES" System="PseudoYields"/>
--		<Row ListType="NukeLoverNukePreference" Item="PSEUDOYIELD_NUCLEAR_WEAPON" Value="20"/>
--		<Row ListType="NukeLoverUseNukePreference" AgendaType="TRAIT_AGENDA_PREFER_NUKES" System="DiplomaticActions"/>
--		<Row ListType="NukeLoverUseNukePreference" Item="DIPLOACTION_USE_NUCLEAR_WEAPON" Favored="true"/>


-- AGENDA_PARANOID / TRAIT_AGENDA_PARANOID / OK
-- Likes civilizations who pose no threat. Dislikes civilizations with strong militaries or ones with nearby cities.
-- Can't influence anything here


-- AGENDA_POPULOUS / TRAIT_AGENDA_PREFER_POPULATION / OK
-- Tries to have the highest overall population.  Respects other high population civilizations.

INSERT INTO AiListTypes (ListType) VALUES
('PreferPopulationYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('PreferPopulationYields', 'TRAIT_AGENDA_PREFER_POPULATION', 'Yields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('PreferPopulationYields', 'YIELD_FOOD', 1, 20);


-- AGENDA_STANDING_ARMY / TRAIT_AGENDA_PREFER_STANDING_ARMY / OK
--	<Row ListType="StandingArmyPseudoYields" AgendaType="TRAIT_AGENDA_PREFER_STANDING_ARMY" System="PseudoYields"/>
--    <Row ListType="StandingArmyPseudoYields" Item="PSEUDOYIELD_STANDING_ARMY_NUMBER" Value="33"/>
--    <Row ListType="StandingArmyPseudoYields" Item="PSEUDOYIELD_STANDING_ARMY_VALUE" Value="50"/>



-- AGENDA_TECHNOPHILE / TRAIT_AGENDA_PREFER_SCIENCE / OK
--		<Row ListType="ScienceLoverSciencePreference" AgendaType="TRAIT_AGENDA_PREFER_SCIENCE" System="Yields"/>
--		<Row ListType="ScienceLoverSciencePreference" Item="YIELD_SCIENCE" Value="20"/>


-- AGENDA_WONDER_ADVOCATE / TRAIT_AGENDA_WONDER_ADVOCATE / OK
--Likes civilizations not competing for wonders, and builds wonders whenever possible. Dislikes losing a wonder to another civilization.
--		<Row ListType="WonderObsessedWonders" AgendaType="TRAIT_AGENDA_WONDER_ADVOCATE" System="PseudoYields"/>
--		<Row ListType="WonderObsessedWonders" AgendaType="TRAIT_AGENDA_WONDER_OBSESSED" System="PseudoYields"/> -> this is for LEADER_QIN
--		<Row ListType="WonderObsessedWonders" Item="PSEUDOYIELD_WONDER" Value="25"/>
