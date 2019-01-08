-- ===========================================================================
-- Real Strategy - main file for Rise & Fall Expansion Pack
-- Author: Infixo
-- 2019-01-05: Created
-- ===========================================================================


-- FIXES

-- 2018-03-25 Rise & Fall only
INSERT INTO Types (Type, Kind) VALUES ('PSEUDOYIELD_GOLDENAGE_POINT', 'KIND_PSEUDOYIELD');
UPDATE AiFavoredItems SET Item = 'TECH_SAILING' WHERE Item = 'TECH_SALING'; -- GenghisTechs
UPDATE AiFavoredItems SET Item = 'DIPLOACTION_ALLIANCE_MILITARY' WHERE Item = 'DIPLOACTION_ALLIANCE_MILITARY_EMERGENCY(NOT_IN_YET)'; -- WilhelminaEmergencyAllianceList, REMOVE IF IMPLEMENTED PROPERLY!
UPDATE AiFavoredItems SET Item = 'DIPLOACTION_ALLIANCE' WHERE Item = 'DIPLOACTION_ALLIANCE_TEAMUP'; -- IronConfederacyDiplomacy, does not exists in Diplo Actions, REMOVE IF IMPLEMENTED PROPERLY!

/*
This System is not tested, so no changes here yet. Also, it seems ok.

DELETE FROM AiFavoredItems WHERE ListType IN (
'ClassicalSensitivity',
'MedievalSensitivity',
'ModernSensitivity');

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
-- CLASSICAL
('ClassicalSensitivity', 'YIELD_SCIENCE', 1, 10),
-- MEDIEVAL
('MedievalSensitivity',	'YIELD_CULTURE', 1, 10),
-- MODERN
('ModernSensitivity', 'YIELD_CULTURE', 1, 10),
('ModernSensitivity', 'YIELD_SCIENCE', 1, 10),
*/


-- LEADERS
INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES -- generated from Excel
('LEADER_CHANDRAGUPTA', 'LEADER', '', 'CONQUEST', 6),
('LEADER_CHANDRAGUPTA', 'LEADER', '', 'SCIENCE',  4),
('LEADER_CHANDRAGUPTA', 'LEADER', '', 'CULTURE',  4),
('LEADER_CHANDRAGUPTA', 'LEADER', '', 'RELIGION', 4),
('LEADER_GENGHIS_KHAN', 'LEADER', '', 'CONQUEST', 8),
('LEADER_GENGHIS_KHAN', 'LEADER', '', 'SCIENCE',  4),
('LEADER_GENGHIS_KHAN', 'LEADER', '', 'CULTURE',  2),
('LEADER_GENGHIS_KHAN', 'LEADER', '', 'RELIGION', 2),
('LEADER_LAUTARO', 'LEADER', '', 'CONQUEST', 5),
('LEADER_LAUTARO', 'LEADER', '', 'SCIENCE',  2),
('LEADER_LAUTARO', 'LEADER', '', 'CULTURE',  5),
('LEADER_LAUTARO', 'LEADER', '', 'RELIGION', 1),
('LEADER_POUNDMAKER', 'LEADER', '', 'CONQUEST', 1),
('LEADER_POUNDMAKER', 'LEADER', '', 'SCIENCE',  5),
('LEADER_POUNDMAKER', 'LEADER', '', 'CULTURE',  5),
('LEADER_POUNDMAKER', 'LEADER', '', 'RELIGION', 4),
('LEADER_ROBERT_THE_BRUCE', 'LEADER', '', 'CONQUEST', 3),
('LEADER_ROBERT_THE_BRUCE', 'LEADER', '', 'SCIENCE',  8),
('LEADER_ROBERT_THE_BRUCE', 'LEADER', '', 'CULTURE',  5),
('LEADER_ROBERT_THE_BRUCE', 'LEADER', '', 'RELIGION', 1),
('LEADER_SEONDEOK', 'LEADER', '', 'CONQUEST', 4),
('LEADER_SEONDEOK', 'LEADER', '', 'SCIENCE',  9),
('LEADER_SEONDEOK', 'LEADER', '', 'CULTURE',  3),
('LEADER_SEONDEOK', 'LEADER', '', 'RELIGION', 1),
('LEADER_SHAKA', 'LEADER', '', 'CONQUEST', 9),
('LEADER_SHAKA', 'LEADER', '', 'SCIENCE',  2),
('LEADER_SHAKA', 'LEADER', '', 'CULTURE',  2),
('LEADER_SHAKA', 'LEADER', '', 'RELIGION', 1),
('LEADER_TAMAR', 'LEADER', '', 'CONQUEST', 4),
('LEADER_TAMAR', 'LEADER', '', 'SCIENCE',  1),
('LEADER_TAMAR', 'LEADER', '', 'CULTURE',  4),
('LEADER_TAMAR', 'LEADER', '', 'RELIGION', 6),
('LEADER_WILHELMINA', 'LEADER', '', 'CONQUEST', 3),
('LEADER_WILHELMINA', 'LEADER', '', 'SCIENCE',  6),
('LEADER_WILHELMINA', 'LEADER', '', 'CULTURE',  6),
('LEADER_WILHELMINA', 'LEADER', '', 'RELIGION', 1);


-- POLICIES
INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES -- generated from Excel
('POLICY_AFTER_ACTION_REPORTS', 'POLICY', 'MILITARY', 'CONQUEST', 5),
('POLICY_CIVIL_PRESTIGE', 'POLICY', 'ECONOMIC', 'CONQUEST', 1),
('POLICY_CIVIL_PRESTIGE', 'POLICY', 'ECONOMIC', 'SCIENCE', 1),
('POLICY_CIVIL_PRESTIGE', 'POLICY', 'ECONOMIC', 'CULTURE', 1),
('POLICY_CIVIL_PRESTIGE', 'POLICY', 'ECONOMIC', 'RELIGION', 1),
('POLICY_COLLECTIVISM', 'POLICY', 'DARKAGE', 'CONQUEST', 2),
('POLICY_COLLECTIVISM', 'POLICY', 'DARKAGE', 'SCIENCE', 1),
('POLICY_COLLECTIVISM', 'POLICY', 'DARKAGE', 'CULTURE', -2),
('POLICY_COMMUNICATIONS_OFFICE', 'POLICY', 'DIPLOMATIC', 'CONQUEST', 3),
('POLICY_ELITE_FORCES', 'POLICY', 'DARKAGE', 'CONQUEST', 5),
('POLICY_INQUISITION', 'POLICY', 'DARKAGE', 'SCIENCE', -2),			
('POLICY_ISOLATIONISM', 'POLICY', 'DARKAGE', 'CONQUEST', 2),
('POLICY_ISOLATIONISM', 'POLICY', 'DARKAGE', 'SCIENCE', 2),
('POLICY_ISOLATIONISM', 'POLICY', 'DARKAGE', 'CULTURE', 1),
('POLICY_LETTERS_OF_MARQUE', 'POLICY', 'DARKAGE', 'CONQUEST', 5),
('POLICY_LIMITANEI', 'POLICY', 'MILITARY', 'CONQUEST', 4),
('POLICY_MONASTICISM', 'POLICY', 'DARKAGE', 'SCIENCE', 4),
('POLICY_MONASTICISM', 'POLICY', 'DARKAGE', 'CULTURE', -2),		
('POLICY_PRAETORIUM', 'POLICY', 'DIPLOMATIC', 'CONQUEST', 1),
('POLICY_ROBBER_BARONS', 'POLICY', 'DARKAGE', 'CONQUEST', 4),
('POLICY_ROBBER_BARONS', 'POLICY', 'DARKAGE', 'SCIENCE', 4),
('POLICY_ROGUE_STATE', 'POLICY', 'DARKAGE', 'CONQUEST', 5),
('POLICY_SECOND_STRIKE_CAPABILITY', 'POLICY', 'MILITARY', 'CONQUEST', 6),
('POLICY_TWILIGHT_VALOR', 'POLICY', 'DARKAGE', 'CONQUEST', 3),
('POLICY_WISSELBANKEN', 'POLICY', 'DIPLOMATIC', 'CONQUEST', 2),
('POLICY_WISSELBANKEN', 'POLICY', 'DIPLOMATIC', 'SCIENCE', 2),
('POLICY_WISSELBANKEN', 'POLICY', 'DIPLOMATIC', 'CULTURE', 1),
('POLICY_WISSELBANKEN', 'POLICY', 'DIPLOMATIC', 'RELIGION', 1);

-- removed in Rise & Fall
DELETE FROM RSTFlavors WHERE ObjectType = 'POLICY_MERITOCRACY';
DELETE FROM RSTFlavors WHERE ObjectType = 'POLICY_SACK';

-- POLICIES
INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES -- generated from Excel
('POLICY_GOV_AUTOCRACY', 'POLICY', 'WILDCARD', 'CONQUEST', 2),
('POLICY_GOV_AUTOCRACY', 'POLICY', 'WILDCARD', 'SCIENCE',  2),
('POLICY_GOV_AUTOCRACY', 'POLICY', 'WILDCARD', 'CULTURE',  2),
('POLICY_GOV_AUTOCRACY', 'POLICY', 'WILDCARD', 'RELIGION', 2),
('POLICY_GOV_CLASSICAL_REPUBLIC', 'POLICY', 'WILDCARD', 'CONQUEST', 1),
('POLICY_GOV_CLASSICAL_REPUBLIC', 'POLICY', 'WILDCARD', 'SCIENCE',  3),
('POLICY_GOV_CLASSICAL_REPUBLIC', 'POLICY', 'WILDCARD', 'CULTURE',  3),
('POLICY_GOV_CLASSICAL_REPUBLIC', 'POLICY', 'WILDCARD', 'RELIGION', 1),
('POLICY_GOV_COMMUNISM', 'POLICY', 'WILDCARD', 'CONQUEST', 3),
('POLICY_GOV_COMMUNISM', 'POLICY', 'WILDCARD', 'SCIENCE',  5),
('POLICY_GOV_COMMUNISM', 'POLICY', 'WILDCARD', 'CULTURE',  3),
('POLICY_GOV_COMMUNISM', 'POLICY', 'WILDCARD', 'RELIGION', 1),
('POLICY_GOV_DEMOCRACY', 'POLICY', 'WILDCARD', 'CONQUEST', 3),
('POLICY_GOV_DEMOCRACY', 'POLICY', 'WILDCARD', 'SCIENCE',  3),
('POLICY_GOV_DEMOCRACY', 'POLICY', 'WILDCARD', 'CULTURE',  3),
('POLICY_GOV_DEMOCRACY', 'POLICY', 'WILDCARD', 'RELIGION', 1),
('POLICY_GOV_FASCISM', 'POLICY', 'WILDCARD', 'CONQUEST', 8),
('POLICY_GOV_MERCHANT_REPUBLIC', 'POLICY', 'WILDCARD', 'CONQUEST', 2),
('POLICY_GOV_MERCHANT_REPUBLIC', 'POLICY', 'WILDCARD', 'SCIENCE',  2),
('POLICY_GOV_MERCHANT_REPUBLIC', 'POLICY', 'WILDCARD', 'CULTURE',  2),
('POLICY_GOV_MERCHANT_REPUBLIC', 'POLICY', 'WILDCARD', 'RELIGION', 1),
('POLICY_GOV_MONARCHY', 'POLICY', 'WILDCARD', 'CONQUEST', 1),
('POLICY_GOV_MONARCHY', 'POLICY', 'WILDCARD', 'SCIENCE',  2),
('POLICY_GOV_MONARCHY', 'POLICY', 'WILDCARD', 'CULTURE',  2),
('POLICY_GOV_MONARCHY', 'POLICY', 'WILDCARD', 'RELIGION', 1),
('POLICY_GOV_OLIGARCHY', 'POLICY', 'WILDCARD', 'CONQUEST', 6),
('POLICY_GOV_THEOCRACY', 'POLICY', 'WILDCARD', 'RELIGION', 7);

-- Wonders
INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES -- generated from Excel
('BUILDING_AMUNDSEN_SCOTT_RESEARCH_STATION', 'Wonder', '', 'SCIENCE', 8),
('BUILDING_CASA_DE_CONTRATACION', 'Wonder', '', 'SCIENCE', 2),
('BUILDING_CASA_DE_CONTRATACION', 'Wonder', '', 'RELIGION', 2),
('BUILDING_KILWA_KISIWANI', 'Wonder', '', 'CONQUEST', 3),
('BUILDING_KILWA_KISIWANI', 'Wonder', '', 'SCIENCE',  3),
('BUILDING_KILWA_KISIWANI', 'Wonder', '', 'CULTURE',  3),
('BUILDING_KILWA_KISIWANI', 'Wonder', '', 'RELIGION', 3),
('BUILDING_KOTOKU_IN', 'Wonder', '', 'CONQUEST', 6),
('BUILDING_KOTOKU_IN', 'Wonder', '', 'RELIGION', 3),
('BUILDING_STATUE_LIBERTY', 'Wonder', '', 'CONQUEST', 5),
('BUILDING_ST_BASILS_CATHEDRAL', 'Wonder', '', 'SCIENCE', 1),
('BUILDING_ST_BASILS_CATHEDRAL', 'Wonder', '', 'CULTURE', 7),
('BUILDING_TAJ_MAHAL', 'Wonder', '', 'CONQUEST', 2),
('BUILDING_TAJ_MAHAL', 'Wonder', '', 'SCIENCE',  2),
('BUILDING_TAJ_MAHAL', 'Wonder', '', 'CULTURE',  2),
('BUILDING_TAJ_MAHAL', 'Wonder', '', 'RELIGION', 2),
('BUILDING_TEMPLE_ARTEMIS', 'Wonder', '', 'CONQUEST', 1),
('BUILDING_TEMPLE_ARTEMIS', 'Wonder', '', 'SCIENCE',  3),
('BUILDING_TEMPLE_ARTEMIS', 'Wonder', '', 'CULTURE',  2),
('BUILDING_TEMPLE_ARTEMIS', 'Wonder', '', 'RELIGION', 1);


-- LEADER_CHANDRAGUPTA / INDIA
-- CHANDRAGUPTA: does not like his neighbors :(
-- TODO: similar expansionist trait to Trajan, to forward settle a bit more maybe?

INSERT INTO AiListTypes (ListType) VALUES
('ChandraguptaPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('ChandraguptaPseudoYields', 'TRAIT_LEADER_ARTHASHASTRA', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('ChandraguptaPseudoYields', 'PSEUDOYIELD_CITY_BASE', 1, 100), -- conquer neighbors
('ChandraguptaPseudoYields', 'PSEUDOYIELD_UNIT_COMBAT', 1, 15), -- obvious
('ChandraguptaPseudoYields', 'PSEUDOYIELD_GPP_PROPHET', 1, -10),
('ChandraguptaPseudoYields', 'PSEUDOYIELD_UNIT_RELIGIOUS', 1, -15), -- to differ from Gandhi
('ChandraguptaPseudoYields', 'PSEUDOYIELD_DIPLOMATIC_BONUS', 1, -15); -- conquer neighbors


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
('GenghisPseudoYields', 'PSEUDOYIELD_CITY_BASE', 1, 100), -- DO conquer neighbors
('GenghisPseudoYields', 'PSEUDOYIELD_UNIT_TRADE', 1, 250),
('GenghisCivics', 'CIVIC_DIPLOMATIC_SERVICE', 1, 0);


-- LEADER_LAUTARO / MAPUCHE

INSERT INTO AiListTypes (ListType) VALUES
('LautaroPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('LautaroPseudoYields', 'TRAIT_LEADER_LAUTARO_ABILITY', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('LautaroPseudoYields', 'PSEUDOYIELD_CITY_BASE', 1, 100),
--('LautaroPseudoYields', 'PSEUDOYIELD_CITY_ORIGINAL_CAPITAL', 1, 50),
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
('PoundmakerPseudoYields', 'PSEUDOYIELD_UNIT_EXPLORER', 1, 10),
('PoundmakerPseudoYields', 'PSEUDOYIELD_UNIT_TRADE', 1, 100),
('PoundmakerPseudoYields', 'PSEUDOYIELD_HAPPINESS', 1, 25);


-- LEADER_ROBERT_THE_BRUCE / SCOTLAND
-- seems well done, PSEUDOYIELD_HAPPINESS +100!
-- one of few leaders that have Favored PSEUDOYIELD_DISTRICT (Campus, Industrial Zone)


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
('TamarTechs', 'TECH_ASTROLOGY', 1, 0), -- get Holy Site first
('TamarTechs', 'TECH_MINING', 1, 0), -- hills bias
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
('WilhelminaPseudoYields', 'PSEUDOYIELD_HAPPINESS', 1, 25);


-- Tactics

-- why is UNIT_KOREAN_HWACHA siege?
DELETE FROM UnitAiInfos WHERE UnitType = 'UNIT_KOREAN_HWACHA' AND (AiType = 'UNITTYPE_SIEGE' OR AiType = 'UNITTYPE_SIEGE_ALL');
