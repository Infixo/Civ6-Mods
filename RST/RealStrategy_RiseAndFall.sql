-- ===========================================================================
-- Real Strategy - main file for Rise & Fall Expansion Pack
-- Author: Infixo
-- 2019-01-05: Created
-- ===========================================================================


-- ===========================================================================
-- GENERIC
-- ===========================================================================

--------------------------------------------------------------
-- 2018-12-22 PlotEvaluations
-- I recreate original entries from R&F however I am not convinced that they work
-- My tests show that 2nd value (-6) is ignored

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('StandardSettlePlot', 'Cultural Pressure', 0, 1),
('StandardSettlePlot', 'Cultural Pressure', 1,-6);


-- FIXES

-- 2018-03-25 Rise & Fall only
INSERT OR REPLACE INTO Types (Type, Kind) VALUES ('PSEUDOYIELD_GOLDENAGE_POINT', 'KIND_PSEUDOYIELD');
UPDATE AiFavoredItems SET Item = 'TECH_SAILING' WHERE Item = 'TECH_SALING'; -- GenghisTechs
DELETE FROM AiFavoredItems WHERE ListType = 'WilhelminaEmergencyAllianceList' AND Item = 'DIPLOACTION_ALLIANCE_MILITARY_EMERGENCY(NOT_IN_YET)'; -- WilhelminaEmergencyAllianceList, REMOVE IF IMPLEMENTED PROPERLY!
DELETE FROM AiFavoredItems WHERE ListType = 'IronConfederacyDiplomacy' AND Item = 'DIPLOACTION_ALLIANCE_TEAMUP'; -- IronConfederacyDiplomacy, does not exists in Diplo Actions, REMOVE IF IMPLEMENTED PROPERLY!

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


-- ===========================================================================
-- STRATEGIES
-- ===========================================================================

-- support for Government Plaza buildings - uses Wonders because it is easy - it is the same system
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


------------------------------------------------------------------------------
-- Anti-Strategies

-- support for Government Plaza buildings - opposites of strategies
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
-- Tier 1 BUILDING_GOV_TALL BUILDING_GOV_WIDE BUILDING_GOV_CONQUEST
('AntiMilitaryWonders', 'BUILDING_GOV_CONQUEST', 0, 0),
-- Tier 2 BUILDING_GOV_CITYSTATES BUILDING_GOV_SPIES BUILDING_GOV_FAITH
('AntiReligiousWonders', 'BUILDING_GOV_FAITH', 0, 0),
-- Tier 3 BUILDING_GOV_MILITARY BUILDING_GOV_CULTURE BUILDING_GOV_SCIENCE
('AntiMilitaryWonders', 'BUILDING_GOV_MILITARY', 0, 0),
('AntiCultureWonders', 'BUILDING_GOV_CULTURE', 0, 0),
('AntiScienceWonders', 'BUILDING_GOV_SCIENCE', 0, 0);



-- ===========================================================================
-- FLAVORS
-- ===========================================================================

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
('POLICY_ROGUE_STATE', 'POLICY', 'DARKAGE', 'DIPLO', -2),
('POLICY_SECOND_STRIKE_CAPABILITY', 'POLICY', 'MILITARY', 'CONQUEST', 6),
('POLICY_TWILIGHT_VALOR', 'POLICY', 'DARKAGE', 'CONQUEST', 3),
('POLICY_WISSELBANKEN', 'POLICY', 'DIPLOMATIC', 'CONQUEST', 2),
('POLICY_WISSELBANKEN', 'POLICY', 'DIPLOMATIC', 'SCIENCE', 2),
('POLICY_WISSELBANKEN', 'POLICY', 'DIPLOMATIC', 'CULTURE', 1),
('POLICY_WISSELBANKEN', 'POLICY', 'DIPLOMATIC', 'RELIGION', 1),
('POLICY_WISSELBANKEN', 'POLICY', 'DIPLOMATIC', 'DIPLO', 4);

-- removed in Rise & Fall
DELETE FROM RSTFlavors WHERE ObjectType = 'POLICY_MERITOCRACY';
DELETE FROM RSTFlavors WHERE ObjectType = 'POLICY_SACK';

-- POLICIES
INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES -- generated from Excel
('POLICY_GOV_AUTOCRACY', 'POLICY', 'WILDCARD', 'CONQUEST', 2),
('POLICY_GOV_AUTOCRACY', 'POLICY', 'WILDCARD', 'SCIENCE', 2),
('POLICY_GOV_AUTOCRACY', 'POLICY', 'WILDCARD', 'CULTURE', 2),
('POLICY_GOV_AUTOCRACY', 'POLICY', 'WILDCARD', 'RELIGION', 2),
('POLICY_GOV_AUTOCRACY', 'POLICY', 'WILDCARD', 'DIPLO', 2),
('POLICY_GOV_CLASSICAL_REPUBLIC', 'POLICY', 'WILDCARD', 'CONQUEST', 2),
('POLICY_GOV_CLASSICAL_REPUBLIC', 'POLICY', 'WILDCARD', 'SCIENCE', 2),
('POLICY_GOV_CLASSICAL_REPUBLIC', 'POLICY', 'WILDCARD', 'CULTURE', 2),
('POLICY_GOV_CLASSICAL_REPUBLIC', 'POLICY', 'WILDCARD', 'RELIGION', 2),
('POLICY_GOV_CLASSICAL_REPUBLIC', 'POLICY', 'WILDCARD', 'DIPLO', 2),
('POLICY_GOV_COMMUNISM', 'POLICY', 'WILDCARD', 'CONQUEST', 3),
('POLICY_GOV_COMMUNISM', 'POLICY', 'WILDCARD', 'SCIENCE', 3),
('POLICY_GOV_COMMUNISM', 'POLICY', 'WILDCARD', 'CULTURE', 3),
('POLICY_GOV_COMMUNISM', 'POLICY', 'WILDCARD', 'RELIGION', 1),	
('POLICY_GOV_DEMOCRACY', 'POLICY', 'WILDCARD', 'CONQUEST', 2),
('POLICY_GOV_DEMOCRACY', 'POLICY', 'WILDCARD', 'SCIENCE', 3),
('POLICY_GOV_DEMOCRACY', 'POLICY', 'WILDCARD', 'CULTURE', 3),
('POLICY_GOV_DEMOCRACY', 'POLICY', 'WILDCARD', 'RELIGION', 1),	
('POLICY_GOV_FASCISM', 'POLICY', 'WILDCARD', 'CONQUEST', 8),				
('POLICY_GOV_MERCHANT_REPUBLIC', 'POLICY', 'WILDCARD', 'CONQUEST', 2),
('POLICY_GOV_MERCHANT_REPUBLIC', 'POLICY', 'WILDCARD', 'SCIENCE', 2),
('POLICY_GOV_MERCHANT_REPUBLIC', 'POLICY', 'WILDCARD', 'CULTURE', 2),
('POLICY_GOV_MERCHANT_REPUBLIC', 'POLICY', 'WILDCARD', 'RELIGION', 2),
('POLICY_GOV_MERCHANT_REPUBLIC', 'POLICY', 'WILDCARD', 'DIPLO', 2),
('POLICY_GOV_MONARCHY', 'POLICY', 'WILDCARD', 'CONQUEST', 2),
('POLICY_GOV_MONARCHY', 'POLICY', 'WILDCARD', 'SCIENCE', 2),
('POLICY_GOV_MONARCHY', 'POLICY', 'WILDCARD', 'CULTURE', 2),
('POLICY_GOV_MONARCHY', 'POLICY', 'WILDCARD', 'RELIGION', 2),
('POLICY_GOV_MONARCHY', 'POLICY', 'WILDCARD', 'DIPLO', 2),
('POLICY_GOV_OLIGARCHY', 'POLICY', 'WILDCARD', 'CONQUEST', 6),				
('POLICY_GOV_THEOCRACY', 'POLICY', 'WILDCARD', 'RELIGION', 7);


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

INSERT INTO AiListTypes (ListType) VALUES
('SycophantPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('SycophantPseudoYields', 'TRAIT_AGENDA_SYCOPHANT', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('SycophantPseudoYields', 'PSEUDOYIELD_GOLDENAGE_POINT', 1, 20);


-- AGENDA_SYMPATHIZER / TRAIT_AGENDA_SYMPATHIZER / OK (R&F)
-- Feels bad for those going through Dark Ages. Dislikes those in Golden Ages.
-- Can't influence anything here
