-- ===========================================================================
-- Real Strategy - main file for Gathering Storm Expansion Pack
-- Author: Infixo
-- 2019-03-09: Created
-- ===========================================================================


-- ===========================================================================
-- GENERIC
-- ===========================================================================


-- FIXES


-- ===========================================================================
-- STRATEGIES
-- Diplomatic Victory - a new strategy
-- Wonders, techs, civics - easy
-- Yields - gold
-- Pseudoyields - favor, envoys
-- Military, science, culture, faith - no changes here?
-- Culture a bit more - need envoys, and few wonders.
-- WC - to do.
-- This could be sort of „reference” civ. Small tweaks only.
-- Peaceful play - go for alliances.
-- ===========================================================================

INSERT OR REPLACE INTO Types (Type, Kind) VALUES
('VICTORY_STRATEGY_DIPLO_VICTORY', 'KIND_VICTORY_STRATEGY');

INSERT OR REPLACE INTO Strategies (StrategyType,VictoryType,NumConditionsNeeded) VALUES
('VICTORY_STRATEGY_DIPLO_VICTORY', 'VICTORY_DIPLOMATIC', 1);

-- not for minors
INSERT INTO StrategyConditions (StrategyType, ConditionFunction, Disqualifier) VALUES
('VICTORY_STRATEGY_DIPLO_VICTORY', 'Is Not Major', 1);

INSERT INTO StrategyConditions (StrategyType, ConditionFunction, StringValue) VALUES
('VICTORY_STRATEGY_DIPLO_VICTORY', 'Call Lua Function', 'ActiveStrategyDiplo');


INSERT INTO AiListTypes (ListType) VALUES
('DiploVictoryAgendas'), -- Victory strategies can now add a preference to various random agendas. This only applies if the agenda can be chosen (era or civic)
('DiploVictoryAlliances'),
('DiploVictoryCivics'),
('DiploVictoryDiplomacy'),
('DiploVictoryDiscussions'),
('DiploVictoryCommemorations'),
('DiploVictoryProjects'),
('DiploVictoryPseudoYields'),
('DiploVictoryResolutions'),
('DiploVictoryTechs'),
('DiploVictoryWonders'),
('DiploVictoryYields');

INSERT INTO AiLists (ListType, System) VALUES
('DiploVictoryAgendas',      'Agendas'),
('DiploVictoryAlliances',    'Alliances'),
('DiploVictoryCivics',       'Civics'),
('DiploVictoryDiplomacy',    'DiplomaticActions'),
('DiploVictoryDiscussions',  'Discussions'),
('DiploVictoryCommemorations', 'Commemorations'),
('DiploVictoryProjects',     'Projects'),
('DiploVictoryPseudoYields', 'PseudoYields'),
('DiploVictoryResolutions',  'Resolutions'),
('DiploVictoryTechs',        'Technologies'),
('DiploVictoryWonders',      'Buildings'),
('DiploVictoryYields',       'Yields');

INSERT INTO Strategy_Priorities (StrategyType, ListType) VALUES
('VICTORY_STRATEGY_DIPLO_VICTORY', 'DiploVictoryAgendas'),
('VICTORY_STRATEGY_DIPLO_VICTORY', 'DiploVictoryAlliances'),
('VICTORY_STRATEGY_DIPLO_VICTORY', 'DiploVictoryCivics'),
('VICTORY_STRATEGY_DIPLO_VICTORY', 'DiploVictoryDiplomacy'),
('VICTORY_STRATEGY_DIPLO_VICTORY', 'DiploVictoryDiscussions'),
('VICTORY_STRATEGY_DIPLO_VICTORY', 'DiploVictoryCommemorations'),
('VICTORY_STRATEGY_DIPLO_VICTORY', 'DiploVictoryProjects'),
('VICTORY_STRATEGY_DIPLO_VICTORY', 'DiploVictoryPseudoYields'),
('VICTORY_STRATEGY_DIPLO_VICTORY', 'DiploVictoryResolutions'),
('VICTORY_STRATEGY_DIPLO_VICTORY', 'DiploVictoryTechs'),
('VICTORY_STRATEGY_DIPLO_VICTORY', 'DiploVictoryWonders'),
('VICTORY_STRATEGY_DIPLO_VICTORY', 'DiploVictoryYields');

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
--('DiploVictoryAgendas'), -- Victory strategies can now add a preference to various random agendas. This only applies if the agenda can be chosen (era or civic)
--('DiploVictoryAlliances'),
--('DiploVictoryCivics'),
--('DiploVictoryDiplomacy'),
--('DiploVictoryDiscussions'),
--('DiploVictoryCommemorations'),
--('DiploVictoryProjects'),
--('DiploVictoryPseudoYields'),
--('DiploVictoryResolutions'),
--('DiploVictoryTechs'),
-- Wonders & Buildings
('DiploVictoryWonders','BUILDING_ORSZAGHAZ',      1, 0),
('DiploVictoryWonders','BUILDING_POTALA_PALACE',  1, 0),
('DiploVictoryWonders','BUILDING_STATUE_LIBERTY', 1, 0);
--('DiploVictoryYields');


-- support for Government Plaza buildings - uses Wonders because it is easy - it is the same system
/*
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
-- Tier 1 BUILDING_GOV_TALL BUILDING_GOV_WIDE BUILDING_GOV_CONQUEST
('MilitaryVictoryWonders', 'BUILDING_GOV_TALL', 0, 0), --  tall play, more housing when governor
('MilitaryVictoryWonders', 'BUILDING_GOV_CONQUEST', 1, 0),
-- Tier 2 BUILDING_GOV_CITYSTATES BUILDING_GOV_SPIES BUILDING_GOV_FAITH
('ReligiousVictoryWonders', 'BUILDING_GOV_FAITH', 1, 0),
-- Tier 3 BUILDING_GOV_MILITARY BUILDING_GOV_CULTURE BUILDING_GOV_SCIENCE
('MilitaryVictoryWonders', 'BUILDING_GOV_MILITARY', 1, 0),
('CultureVictoryWonders', 'BUILDING_GOV_CULTURE', 1, 0),
('ScienceVictoryWonders', 'BUILDING_GOV_SCIENCE', 1, 0);
*/




-- ===========================================================================
-- PARAMETERS
-- ===========================================================================


-- LEADERS

-- these leaders were changed in GS and need updating
DELETE FROM RSTFlavors WHERE ObjectType IN ('LEADER_TAMAR', 'LEADER_VICTORIA');

INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES -- generated from Excel
-- pre-GS
('LEADER_TAMAR', 'LEADER', '', 'CONQUEST', 4),	('LEADER_TAMAR', 'LEADER', '', 'SCIENCE', 1),	('LEADER_TAMAR', 'LEADER', '', 'CULTURE', 5),	('LEADER_TAMAR', 'LEADER', '', 'RELIGION', 7),	('LEADER_TAMAR', 'LEADER', '', 'DIPLO', 5),
('LEADER_VICTORIA', 'LEADER', '', 'CONQUEST', 6),	('LEADER_VICTORIA', 'LEADER', '', 'SCIENCE', 4),	('LEADER_VICTORIA', 'LEADER', '', 'CULTURE', 3),	('LEADER_VICTORIA', 'LEADER', '', 'RELIGION', 1),	('LEADER_VICTORIA', 'LEADER', '', 'DIPLO', 2),
-- Gathering Storm
('LEADER_DIDO', 'LEADER', '', 'CONQUEST', 5),	('LEADER_DIDO', 'LEADER', '', 'SCIENCE', 5),	('LEADER_DIDO', 'LEADER', '', 'CULTURE', 3),	('LEADER_DIDO', 'LEADER', '', 'RELIGION', 1),	('LEADER_DIDO', 'LEADER', '', 'DIPLO', 4),
('LEADER_ELEANOR_ENGLAND', 'LEADER', '', 'CONQUEST', 3),	('LEADER_ELEANOR_ENGLAND', 'LEADER', '', 'SCIENCE', 4),	('LEADER_ELEANOR_ENGLAND', 'LEADER', '', 'CULTURE', 5),	('LEADER_ELEANOR_ENGLAND', 'LEADER', '', 'RELIGION', 1),	('LEADER_ELEANOR_ENGLAND', 'LEADER', '', 'DIPLO', 3),
('LEADER_ELEANOR_FRANCE', 'LEADER', '', 'CONQUEST', 2),	('LEADER_ELEANOR_FRANCE', 'LEADER', '', 'SCIENCE', 3),	('LEADER_ELEANOR_FRANCE', 'LEADER', '', 'CULTURE', 8),	('LEADER_ELEANOR_FRANCE', 'LEADER', '', 'RELIGION', 3),	('LEADER_ELEANOR_FRANCE', 'LEADER', '', 'DIPLO', 4),
('LEADER_KRISTINA', 'LEADER', '', 'CONQUEST', 2),	('LEADER_KRISTINA', 'LEADER', '', 'SCIENCE', 4),	('LEADER_KRISTINA', 'LEADER', '', 'CULTURE', 6),	('LEADER_KRISTINA', 'LEADER', '', 'RELIGION', 2),	('LEADER_KRISTINA', 'LEADER', '', 'DIPLO', 7),
('LEADER_KUPE', 'LEADER', '', 'CONQUEST', 4),	('LEADER_KUPE', 'LEADER', '', 'SCIENCE', 1),	('LEADER_KUPE', 'LEADER', '', 'CULTURE', 5),	('LEADER_KUPE', 'LEADER', '', 'RELIGION', 4),	('LEADER_KUPE', 'LEADER', '', 'DIPLO', 4),
('LEADER_LAURIER', 'LEADER', '', 'CONQUEST', 1),	('LEADER_LAURIER', 'LEADER', '', 'SCIENCE', 4),	('LEADER_LAURIER', 'LEADER', '', 'CULTURE', 7),	('LEADER_LAURIER', 'LEADER', '', 'RELIGION', 1),	('LEADER_LAURIER', 'LEADER', '', 'DIPLO', 7),
('LEADER_MANSA_MUSA', 'LEADER', '', 'CONQUEST', 3),	('LEADER_MANSA_MUSA', 'LEADER', '', 'SCIENCE', 4),	('LEADER_MANSA_MUSA', 'LEADER', '', 'CULTURE', 3),	('LEADER_MANSA_MUSA', 'LEADER', '', 'RELIGION', 3),	('LEADER_MANSA_MUSA', 'LEADER', '', 'DIPLO', 5),
('LEADER_MATTHIAS_CORVINUS', 'LEADER', '', 'CONQUEST', 6),	('LEADER_MATTHIAS_CORVINUS', 'LEADER', '', 'SCIENCE', 2),	('LEADER_MATTHIAS_CORVINUS', 'LEADER', '', 'CULTURE', 3),	('LEADER_MATTHIAS_CORVINUS', 'LEADER', '', 'RELIGION', 2),	('LEADER_MATTHIAS_CORVINUS', 'LEADER', '', 'DIPLO', 6),
('LEADER_PACHACUTI', 'LEADER', '', 'CONQUEST', 5),	('LEADER_PACHACUTI', 'LEADER', '', 'SCIENCE', 6),	('LEADER_PACHACUTI', 'LEADER', '', 'CULTURE', 3),	('LEADER_PACHACUTI', 'LEADER', '', 'RELIGION', 1),	('LEADER_PACHACUTI', 'LEADER', '', 'DIPLO', 1),
('LEADER_SULEIMAN', 'LEADER', '', 'CONQUEST', 8),	('LEADER_SULEIMAN', 'LEADER', '', 'SCIENCE', 4),	('LEADER_SULEIMAN', 'LEADER', '', 'CULTURE', 4),	('LEADER_SULEIMAN', 'LEADER', '', 'RELIGION', 2),	('LEADER_SULEIMAN', 'LEADER', '', 'DIPLO', 1);


-- POLICIES

-- removed in Gathering Storm
DELETE FROM RSTFlavors WHERE ObjectType = 'POLICY_POLICE_STATE';
DELETE FROM RSTFlavors WHERE ObjectType = 'POLICY_ARSENAL_OF_DEMOCRACY';
DELETE FROM RSTFlavors WHERE ObjectType = 'POLICY_PATRIOTIC_WAR';

INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES -- generated from Excel
('POLICY_FUTURE_VICTORY_SCIENCE', 'POLICY', 'WILDCARD', 'CONQUEST', 4),	('POLICY_FUTURE_VICTORY_SCIENCE', 'POLICY', 'WILDCARD', 'SCIENCE', 9),			
	('POLICY_FUTURE_COUNTER_SCIENCE', 'POLICY', 'WILDCARD', 'SCIENCE', 3),	('POLICY_FUTURE_COUNTER_SCIENCE', 'POLICY', 'WILDCARD', 'CULTURE', 3),		('POLICY_FUTURE_COUNTER_SCIENCE', 'POLICY', 'WILDCARD', 'DIPLO', 3),
		('POLICY_FUTURE_VICTORY_CULTURE', 'POLICY', 'WILDCARD', 'CULTURE', 9),		
('POLICY_FUTURE_COUNTER_CULTURE', 'POLICY', 'WILDCARD', 'CONQUEST', 3),	('POLICY_FUTURE_COUNTER_CULTURE', 'POLICY', 'WILDCARD', 'SCIENCE', 3),		('POLICY_FUTURE_COUNTER_CULTURE', 'POLICY', 'WILDCARD', 'RELIGION', 2),	('POLICY_FUTURE_COUNTER_CULTURE', 'POLICY', 'WILDCARD', 'DIPLO', 3),
('POLICY_FUTURE_VICTORY_DOMINATION', 'POLICY', 'WILDCARD', 'CONQUEST', 9),				
	('POLICY_FUTURE_COUNTER_DOMINATION', 'POLICY', 'WILDCARD', 'SCIENCE', 3),	('POLICY_FUTURE_COUNTER_DOMINATION', 'POLICY', 'WILDCARD', 'CULTURE', 3),		('POLICY_FUTURE_COUNTER_DOMINATION', 'POLICY', 'WILDCARD', 'DIPLO', 3),
				('POLICY_FUTURE_VICTORY_DIPLOMATIC', 'POLICY', 'WILDCARD', 'DIPLO', 9),
	('POLICY_FUTURE_COUNTER_DIPLOMATIC', 'POLICY', 'WILDCARD', 'SCIENCE', 3),	('POLICY_FUTURE_COUNTER_DIPLOMATIC', 'POLICY', 'WILDCARD', 'CULTURE', 3),		('POLICY_FUTURE_COUNTER_DIPLOMATIC', 'POLICY', 'WILDCARD', 'DIPLO', 6),
('POLICY_EQUESTRIAN_ORDERS', 'POLICY', 'MILITARY', 'CONQUEST', 5),				
('POLICY_DRILL_MANUALS', 'POLICY', 'MILITARY', 'CONQUEST', 5);



-- GOVERNMENTS

-- these governments were changed in GS and need updating
DELETE FROM RSTFlavors WHERE ObjectType IN ('GOVERNMENT_COMMUNISM', 'GOVERNMENT_DEMOCRACY');

INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES -- generated from Excel
('GOVERNMENT_COMMUNISM', 'GOVERNMENT', 'TIER_3', 'CONQUEST', 4),	('GOVERNMENT_COMMUNISM', 'GOVERNMENT', 'TIER_3', 'SCIENCE', 8),	('GOVERNMENT_COMMUNISM', 'GOVERNMENT', 'TIER_3', 'CULTURE', 3),	('GOVERNMENT_COMMUNISM', 'GOVERNMENT', 'TIER_3', 'RELIGION', 1),	('GOVERNMENT_COMMUNISM', 'GOVERNMENT', 'TIER_3', 'DIPLO', 1),
('GOVERNMENT_DEMOCRACY', 'GOVERNMENT', 'TIER_3', 'CONQUEST', 1),	('GOVERNMENT_DEMOCRACY', 'GOVERNMENT', 'TIER_3', 'SCIENCE', 5),	('GOVERNMENT_DEMOCRACY', 'GOVERNMENT', 'TIER_3', 'CULTURE', 7),	('GOVERNMENT_DEMOCRACY', 'GOVERNMENT', 'TIER_3', 'RELIGION', 3),	('GOVERNMENT_DEMOCRACY', 'GOVERNMENT', 'TIER_3', 'DIPLO', 6),
('GOVERNMENT_CORPORATE_LIBERTARIANISM', 'GOVERNMENT', 'TIER_4', 'CONQUEST', 7),	('GOVERNMENT_CORPORATE_LIBERTARIANISM', 'GOVERNMENT', 'TIER_4', 'SCIENCE', 1),	('GOVERNMENT_CORPORATE_LIBERTARIANISM', 'GOVERNMENT', 'TIER_4', 'CULTURE', 3),	('GOVERNMENT_CORPORATE_LIBERTARIANISM', 'GOVERNMENT', 'TIER_4', 'RELIGION', 1),	('GOVERNMENT_CORPORATE_LIBERTARIANISM', 'GOVERNMENT', 'TIER_4', 'DIPLO', 1),
('GOVERNMENT_DIGITAL_DEMOCRACY', 'GOVERNMENT', 'TIER_4', 'CONQUEST', 3),	('GOVERNMENT_DIGITAL_DEMOCRACY', 'GOVERNMENT', 'TIER_4', 'SCIENCE', 1),			('GOVERNMENT_DIGITAL_DEMOCRACY', 'GOVERNMENT', 'TIER_4', 'DIPLO', 6),
('GOVERNMENT_SYNTHETIC_TECHNOCRACY', 'GOVERNMENT', 'TIER_4', 'CONQUEST', 3),				('GOVERNMENT_SYNTHETIC_TECHNOCRACY', 'GOVERNMENT', 'TIER_4', 'DIPLO', 3);


-- Wonders
INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES -- generated from Excel
('BUILDING_GREAT_BATH', 'Wonder', '', 'CONQUEST', 1),	('BUILDING_GREAT_BATH', 'Wonder', '', 'SCIENCE', 1),	('BUILDING_GREAT_BATH', 'Wonder', '', 'CULTURE', 1),	('BUILDING_GREAT_BATH', 'Wonder', '', 'RELIGION', 5),	('BUILDING_GREAT_BATH', 'Wonder', '', 'DIPLO', 1),
('BUILDING_MACHU_PICCHU', 'Wonder', '', 'CONQUEST', 1),	('BUILDING_MACHU_PICCHU', 'Wonder', '', 'SCIENCE', 1),	('BUILDING_MACHU_PICCHU', 'Wonder', '', 'CULTURE', 2),		
			('BUILDING_MEENAKSHI_TEMPLE', 'Wonder', '', 'RELIGION', 7),	
	('BUILDING_UNIVERSITY_SANKORE', 'Wonder', '', 'SCIENCE', 7),		('BUILDING_UNIVERSITY_SANKORE', 'Wonder', '', 'RELIGION', 2),	
		('BUILDING_ORSZAGHAZ', 'Wonder', '', 'CULTURE', 1),		('BUILDING_ORSZAGHAZ', 'Wonder', '', 'DIPLO', 7),
('BUILDING_PANAMA_CANAL', 'Wonder', '', 'CONQUEST', 1),				
		('BUILDING_GOLDEN_GATE_BRIDGE', 'Wonder', '', 'CULTURE', 5);


-- ===========================================================================
-- LEADERS
-- ===========================================================================


--<Row Type="LEADER_DIDO" Kind="KIND_LEADER"/>
--<Row Type="LEADER_ELEANOR_ENGLAND" Kind="KIND_LEADER"/>
--<Row Type="LEADER_ELEANOR_FRANCE" Kind="KIND_LEADER"/>
--<Row Type="LEADER_KRISTINA" Kind="KIND_LEADER"/>
--<Row Type="LEADER_KUPE" Kind="KIND_LEADER"/>
--<Row Type="LEADER_LAURIER" Kind="KIND_LEADER"/>
--<Row Type="LEADER_MANSA_MUSA" Kind="KIND_LEADER"/>
--<Row Type="LEADER_MATTHIAS_CORVINUS" Kind="KIND_LEADER"/>
--<Row Type="LEADER_PACHACUTI" Kind="KIND_LEADER"/>
--<Row Type="LEADER_SULEIMAN" Kind="KIND_LEADER"/>

/*
-- LEADER_CHANDRAGUPTA / INDIA
-- CHANDRAGUPTA: does not like his neighbors :(
-- TODO: similar expansionist trait to Trajan, to forward settle a bit more maybe?

INSERT INTO AiListTypes (ListType) VALUES
('ChandraguptaPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('ChandraguptaPseudoYields', 'TRAIT_LEADER_ARTHASHASTRA', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('ChandraguptaPseudoYields', 'PSEUDOYIELD_CITY_BASE', 1, 50), -- conquer neighbors
('ChandraguptaPseudoYields', 'PSEUDOYIELD_CITY_POPULATION', 1, 50), -- conquer neighbors
('ChandraguptaPseudoYields', 'PSEUDOYIELD_CITY_DEFENSES', 1, -10), -- conquer neighbors
('ChandraguptaPseudoYields', 'PSEUDOYIELD_UNIT_COMBAT', 1, 15), -- obvious
('ChandraguptaPseudoYields', 'PSEUDOYIELD_GPP_PROPHET', 1, -10),
('ChandraguptaPseudoYields', 'PSEUDOYIELD_UNIT_RELIGIOUS', 1, -15), -- to differ from Gandhi
('ChandraguptaPseudoYields', 'PSEUDOYIELD_DIPLOMATIC_BONUS', 1, -25); -- conquer neighbors


-- GENGHIS_KHAN / MONGOLIA
-- TRAIT_RST_PREFER_TRADE_ROUTES

DELETE FROM AiFavoredItems WHERE ListType = 'GenghisCivics' AND Item = 'CIVIC_DIVINE_RIGHT';

INSERT INTO AiListTypes (ListType) VALUES
('GenghisPseudoYields'),
('MongoliaDisfavorBarracks');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('GenghisPseudoYields', 'TRAIT_LEADER_GENGHIS_KHAN_ABILITY', 'PseudoYields'),
('MongoliaDisfavorBarracks', 'TRAIT_CIVILIZATION_BUILDING_ORDU', 'Buildings');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('MongoliaDisfavorBarracks', 'BUILDING_BARRACKS', 0, 0), -- let him not build Barracks, so he will build Ordu
('GenghisPseudoYields', 'PSEUDOYIELD_CITY_BASE', 1, 50), -- DO conquer neighbors
('GenghisPseudoYields', 'PSEUDOYIELD_CITY_DEFENSES', 1, -10), -- DO conquer neighbors
('GenghisPseudoYields', 'PSEUDOYIELD_UNIT_TRADE', 1, 50),
('GenghisCivics', 'CIVIC_DIPLOMATIC_SERVICE', 1, 0);


-- LEADER_LAUTARO / MAPUCHE

INSERT INTO AiListTypes (ListType) VALUES
('LautaroPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('LautaroPseudoYields', 'TRAIT_LEADER_LAUTARO_ABILITY', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('LautaroPseudoYields', 'PSEUDOYIELD_CITY_BASE', 1, 50),
('LautaroPseudoYields', 'PSEUDOYIELD_CITY_DEFENSES', 1, -10),
('LautaroPseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, 15), -- chemamull
('LautaroPseudoYields', 'PSEUDOYIELD_ENVIRONMENT', 1, 20),
('LautaroPseudoYields', 'PSEUDOYIELD_UNIT_COMBAT', 1, 10);


-- LEADER_POUNDMAKER / CREE

INSERT INTO AiListTypes (ListType) VALUES
('PoundmakerYields'),
('PoundmakerPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('PoundmakerYields',       'TRAIT_LEADER_ALLIANCE_AND_TRADE', 'Yields'),
('PoundmakerPseudoYields', 'TRAIT_LEADER_ALLIANCE_AND_TRADE', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('PoundmakerYields', 'YIELD_FOOD', 1, 10),
('PoundmakerCivics', 'CIVIC_FOREIGN_TRADE', 1, 0),
('PoundmakerCivics', 'CIVIC_MERCENARIES', 1, 0),
('PoundmakerPseudoYields', 'PSEUDOYIELD_CITY_BASE', 1, -100), -- do NOT conquer neighbors
('PoundmakerPseudoYields', 'PSEUDOYIELD_CITY_DEFENSES', 1, 15), -- do NOT conquer neighbors
('PoundmakerPseudoYields', 'PSEUDOYIELD_UNIT_EXPLORER', 1, 10),
('PoundmakerPseudoYields', 'PSEUDOYIELD_UNIT_TRADE', 1, 50),
('PoundmakerPseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, 15), -- mekewap
('PoundmakerPseudoYields', 'PSEUDOYIELD_HAPPINESS', 1, 25);


-- LEADER_ROBERT_THE_BRUCE / SCOTLAND
-- seems well done, PSEUDOYIELD_HAPPINESS +100!
-- one of few leaders that have Favored PSEUDOYIELD_DISTRICT (Campus, Industrial Zone)
-- Golf Course


-- LEADER_SEONDEOK / KOREA
-- OK! science boosted, mines, etc.


-- LEADER_SHAKA / ZULU
-- OK!
-- UPDATE AiFavoredItems SET Value = 15 WHERE ListType = 'AggressivePseudoYields' AND Item = 'PSEUDOYIELD_UNIT_NAVAL_COMBAT'; -- used by Shaka & Genghis


-- LEADER_TAMAR / GEORGIA
-- she uses BUILDING_WALLS as Favored!
-- Georgia - she should NOT take normal Comms?
-- convert minors

--TamarCivics	CIVIC_DIVINE_RIGHT - I suppose this is for Monarchy!
UPDATE AiFavoredItems SET Item = (SELECT PrereqCivic FROM Governments WHERE GovernmentType = 'GOVERNMENT_MONARCHY')
WHERE ListType = 'TamarCivics' AND Item = 'CIVIC_DIVINE_RIGHT';

-- 2019-01-01: based on mod "Hill Start Bias for Georgia" (lower number, stronger bias)
DELETE FROM StartBiasTerrains WHERE CivilizationType = 'CIVILIZATION_GEORGIA';
INSERT INTO StartBiasTerrains (CivilizationType, TerrainType, Tier) VALUES
('CIVILIZATION_GEORGIA', 'TERRAIN_DESERT_HILLS', 3),
('CIVILIZATION_GEORGIA', 'TERRAIN_GRASS_HILLS',  3),
('CIVILIZATION_GEORGIA', 'TERRAIN_PLAINS_HILLS', 3);

--INSERT INTO AiListTypes (ListType) VALUES
--('TamarPseudoYields');
--INSERT INTO AiLists (ListType, LeaderType, System) VALUES
--('TamarPseudoYields', 'TRAIT_LEADER_RELIGION_CITY_STATES', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('TamarTechs', 'TECH_ASTROLOGY', 1, 0), -- get Holy Site first -- !BUGGED!
('TamarTechs', 'TECH_MINING', 1, 0), -- hills bias -- !BUGGED!
('TamarCivics', 'CIVIC_THEOLOGY', 1, 0),
('ProtectorateWarriorList', 'DIPLOACTION_DECLARE_WAR_MINOR_CIV', 0, 0), -- for now only Tamar uses it, might change in the future
('ProtectorateWarriorList', 'DIPLOACTION_DECLARE_LIBERATION_WAR', 1, 0);


-- LEADER_WILHELMINA / NETHERLANDS

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('WilhelminaYields', 'YIELD_FOOD', 1, 10), -- TRAIT_AGENDA_BILLIONAIRE
('WilhelminaWonders', 'BUILDING_BIG_BEN', 1, 0),
('WilhelminaPseudoYields', 'PSEUDOYIELD_GPP_ADMIRAL', 1, 15),
('WilhelminaPseudoYields', 'PSEUDOYIELD_GPP_MERCHANT', 1, 20),
('WilhelminaPseudoYields', 'PSEUDOYIELD_UNIT_NAVAL_COMBAT', 1, 15),
('WilhelminaPseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, 15), -- polder
('WilhelminaPseudoYields', 'PSEUDOYIELD_HAPPINESS', 1, 25);

*/

-- ===========================================================================
-- TACTICS
-- ===========================================================================

-- recreate because it was removed in RealStrategy_Moves.xml
INSERT INTO AllowedMoves (AllowedMoveType,Value,IsHomeland) VALUES
('Rock Band Move', 35, 1);


-- ===========================================================================
-- RANDOM AGENDAS
-- These agendas are no longer in use
-- AGENDA_CURMUDGEON
-- AGENDA_FLIRTATIOUS
-- ===========================================================================


-- AGENDA_GOSSIP / TRAIT_AGENDA_GOSSIP / OK (R&F)
-- LEADER_CATHERINE_DE_MEDICI has 15%
-- Wants to know everything about everyone. Does not like civilizations who don't share information.
--		<Row ListType="GossipFavoredDiplomacy" AgendaType="TRAIT_AGENDA_GOSSIP" System="DiplomaticActions"/>
--		<Row ListType="GossipFavoredDiplomacy" Item="DIPLOACTION_RESIDENT_EMBASSY" Favored="true"/>
--		<Row ListType="GossipFavoredDiplomacy" Item="DIPLOACTION_OPEN_BORDERS" Favored="true"/>
--		<Row ListType="GossipFavoredDiplomacy" Item="DIPLOACTION_DIPLOMATIC_DELEGATION" Favored="true"/>
--		<Row ListType="GossipFavoredDiplomacy" Item="DIPLOACTION_KEEP_PROMISE_DONT_SPY" Favored="false"/>


-- AGENDA_SYCOPHANT / TRAIT_AGENDA_SYCOPHANT / OK (R&F)
-- Impressed by any civilization that earns a Golden Age. Dislikes those in Dark Ages
/*
INSERT INTO AiListTypes (ListType) VALUES
('SycophantPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('SycophantPseudoYields', 'TRAIT_AGENDA_SYCOPHANT', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('SycophantPseudoYields', 'PSEUDOYIELD_GOLDENAGE_POINT', 1, 20);
*/

-- AGENDA_SYMPATHIZER / TRAIT_AGENDA_SYMPATHIZER / OK (R&F)
-- Feels bad for those going through Dark Ages. Dislikes those in Golden Ages.
-- Can't influence anything here
