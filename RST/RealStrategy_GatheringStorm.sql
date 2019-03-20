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
('DiploVictoryAlliances'), -- AI can be set to favor or disfavor specific alliances by leader or civ trait - very rarely used
('DiploVictoryCivics'),
('DiploVictoryDiplomacy'),
('DiploVictoryCommemorations'),
('DiploVictoryProjects'),
('DiploVictoryPseudoYields'),
('DiploVictoryTechs'),
('DiploVictoryWonders'),
('DiploVictoryYields');

INSERT INTO AiLists (ListType, System) VALUES
('DiploVictoryAgendas',      'Agendas'),
('DiploVictoryAlliances',    'Alliances'),
('DiploVictoryCivics',       'Civics'),
('DiploVictoryDiplomacy',    'DiplomaticActions'),
('DiploVictoryCommemorations', 'Commemorations'),
('DiploVictoryProjects',     'Projects'),
('DiploVictoryPseudoYields', 'PseudoYields'),
('DiploVictoryTechs',        'Technologies'),
('DiploVictoryWonders',      'Buildings'),
('DiploVictoryYields',       'Yields');

INSERT INTO Strategy_Priorities (StrategyType, ListType) VALUES
('VICTORY_STRATEGY_DIPLO_VICTORY', 'DiploVictoryAgendas'),
('VICTORY_STRATEGY_DIPLO_VICTORY', 'DiploVictoryAlliances'),
('VICTORY_STRATEGY_DIPLO_VICTORY', 'DiploVictoryCivics'),
('VICTORY_STRATEGY_DIPLO_VICTORY', 'DiploVictoryDiplomacy'),
('VICTORY_STRATEGY_DIPLO_VICTORY', 'DiploVictoryCommemorations'),
('VICTORY_STRATEGY_DIPLO_VICTORY', 'DiploVictoryProjects'),
('VICTORY_STRATEGY_DIPLO_VICTORY', 'DiploVictoryPseudoYields'),
('VICTORY_STRATEGY_DIPLO_VICTORY', 'DiploVictoryTechs'),
('VICTORY_STRATEGY_DIPLO_VICTORY', 'DiploVictoryWonders'),
('VICTORY_STRATEGY_DIPLO_VICTORY', 'DiploVictoryYields');

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
--('DiploVictoryAgendas'), -- Victory strategies can now add a preference to various random agendas. This only applies if the agenda can be chosen (era or civic)
--('DiploVictoryAlliances'),
--('DiploVictoryCivics'),
('DiploVictoryCivics', 'CIVIC_CIVIL_SERVICE',     1, 0),
('DiploVictoryCivics', 'CIVIC_CIVIL_ENGINEERING', 1, 0),
('DiploVictoryCivics', 'CIVIC_SUFFRAGE',          1, 0),
-- DiplomaticActions
('DiploVictoryDiplomacy', 'DIPLOACTION_ALLIANCE',         1, 0),
('DiploVictoryDiplomacy', 'DIPLOACTION_RESIDENT_EMBASSY', 1, 0),
('DiploVictoryDiplomacy', 'DIPLOACTION_RENEW_ALLIANCE',   1, 0),
('DiploVictoryDiplomacy', 'DIPLOACTION_DECLARE_WAR_MINOR_CIV', 0, 0),
--('DiploVictoryCommemorations'),
-- Projects
('DiploVictoryProjects', 'PROJECT_CARBON_RECAPTURE', 1, 0),
('DiploVictoryProjects', 'PROJECT_SEND_AID',         1, 0),
-- PseudoYields
('DiploVictoryPseudoYields', 'PSEUDOYIELD_DIPLOMATIC_FAVOR', 1, 50),
('DiploVictoryPseudoYields', 'PSEUDOYIELD_DIPLOMATIC_BONUS', 1, 25),
('DiploVictoryPseudoYields', 'PSEUDOYIELD_INFLUENCE',        1, 25),
('DiploVictoryPseudoYields', 'PSEUDOYIELD_UNIT_TRADE',       1, 15),
('DiploVictoryPseudoYields', 'PSEUDOYIELD_SPACE_RACE',       1,-50),
--('DiploVictoryTechs'),
-- Wonders & Buildings
('DiploVictoryWonders', 'BUILDING_ORSZAGHAZ',      1, 0),
('DiploVictoryWonders', 'BUILDING_POTALA_PALACE',  1, 0),
('DiploVictoryWonders', 'BUILDING_STATUE_LIBERTY', 1, 0),
-- Yields
('DiploVictoryYields', 'YIELD_GOLD', 1, 20);

-- this is for compatibility with RTT when Monarchy is moved to another civic
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value)
SELECT 'DiploVictoryCivics', PrereqCivic, 1, 0
FROM Governments
WHERE GovernmentType = 'GOVERNMENT_MONARCHY';

-- support for Government Plaza buildings - uses Wonders because it is easy - it is the same system
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
-- Tier 1 BUILDING_GOV_TALL BUILDING_GOV_WIDE BUILDING_GOV_CONQUEST
('DiploVictoryWonders', 'BUILDING_GOV_CONQUEST', 0, 0),
-- Tier 2 BUILDING_GOV_CITYSTATES BUILDING_GOV_SPIES BUILDING_GOV_FAITH
('DiploVictoryWonders', 'BUILDING_GOV_CITYSTATES', 1, 0),
-- Tier 3 BUILDING_GOV_MILITARY BUILDING_GOV_CULTURE BUILDING_GOV_SCIENCE
('DiploVictoryWonders', 'BUILDING_GOV_MILITARY', 0, 0);



-- ===========================================================================
-- STRATEGIES - new GS systems
-- ===========================================================================

INSERT INTO AiListTypes (ListType) VALUES
('CultureVictoryDiscussions'),
('CultureVictoryResolutions'),
('DiploVictoryDiscussions'),
('DiploVictoryResolutions'),
('MilitaryVictoryDiscussions'),
('MilitaryVictoryResolutions'),
('ReligiousVictoryDiscussions'),
('ReligiousVictoryResolutions'),
('ScienceVictoryDiscussions'),
('ScienceVictoryResolutions');

INSERT INTO AiLists (ListType, System) VALUES
('CultureVictoryDiscussions', 'Discussions'),
('CultureVictoryResolutions', 'Resolutions'),
('DiploVictoryDiscussions',  'Discussions'),
('DiploVictoryResolutions',  'Resolutions'),
('MilitaryVictoryDiscussions', 'Discussions'),
('MilitaryVictoryResolutions', 'Resolutions'),
('ReligiousVictoryDiscussions', 'Discussions'),
('ReligiousVictoryResolutions', 'Resolutions'),
('ScienceVictoryDiscussions', 'Discussions'),
('ScienceVictoryResolutions', 'Resolutions');

INSERT INTO Strategy_Priorities (StrategyType, ListType) VALUES
('VICTORY_STRATEGY_CULTURAL_VICTORY', 'CultureVictoryDiscussions'),
('VICTORY_STRATEGY_CULTURAL_VICTORY', 'CultureVictoryResolutions'),
('VICTORY_STRATEGY_DIPLO_VICTORY', 'DiploVictoryDiscussions'),
('VICTORY_STRATEGY_DIPLO_VICTORY', 'DiploVictoryResolutions'),
('VICTORY_STRATEGY_MILITARY_VICTORY', 'MilitaryVictoryDiscussions'),
('VICTORY_STRATEGY_MILITARY_VICTORY', 'MilitaryVictoryResolutions'),
('VICTORY_STRATEGY_RELIGIOUS_VICTORY', 'ReligiousVictoryDiscussions'),
('VICTORY_STRATEGY_RELIGIOUS_VICTORY', 'ReligiousVictoryResolutions'),
('VICTORY_STRATEGY_SCIENCE_VICTORY', 'ScienceVictoryDiscussions'),
('VICTORY_STRATEGY_SCIENCE_VICTORY', 'ScienceVictoryResolutions');


INSERT INTO AiFavoredItems (ListType, Item, Favored) VALUES
-- Discussions
('MilitaryVictoryDiscussions',  'WC_EMERGENCY_MILITARY', 0),
('DiploVictoryDiscussions',     'WC_EMERGENCY_CITY_STATE', 1),
('ReligiousVictoryDiscussions', 'WC_EMERGENCY_RELIGIOUS', 0),
('CultureVictoryDiscussions',   'WC_EMERGENCY_NUCLEAR', 1),
('DiploVictoryDiscussions',     'WC_EMERGENCY_NUCLEAR', 1),
('ReligiousVictoryDiscussions', 'WC_EMERGENCY_NUCLEAR', 1),
('ScienceVictoryDiscussions',   'WC_EMERGENCY_NUCLEAR', 1),
('CultureVictoryDiscussions',   'WC_EMERGENCY_BACKSTAB', 1),
('DiploVictoryDiscussions',     'WC_EMERGENCY_BACKSTAB', 1),
('ReligiousVictoryDiscussions', 'WC_EMERGENCY_BACKSTAB', 1),
('ScienceVictoryDiscussions',   'WC_EMERGENCY_BACKSTAB', 1),
('DiploVictoryDiscussions',     'WC_EMERGENCY_REQUEST_AID', 1),
('CultureVictoryDiscussions',   'WC_EMERGENCY_NOBEL_PRIZE_LITERATURE', 1),
('ScienceVictoryDiscussions',   'WC_EMERGENCY_NOBEL_PRIZE_LITERATURE', 0),
('MilitaryVictoryDiscussions',  'WC_EMERGENCY_NOBEL_PRIZE_LITERATURE', 0),
('DiploVictoryDiscussions',     'WC_EMERGENCY_NOBEL_PRIZE_PEACE', 1),
('MilitaryVictoryDiscussions',  'WC_EMERGENCY_NOBEL_PRIZE_PEACE', 0),
('ScienceVictoryDiscussions',   'WC_EMERGENCY_NOBEL_PRIZE_PHYSICS', 1),
('CultureVictoryDiscussions',   'WC_EMERGENCY_NOBEL_PRIZE_PHYSICS', 0),
('ReligiousVictoryDiscussions', 'WC_EMERGENCY_NOBEL_PRIZE_PHYSICS', 0),
-- WC_EMERGENCY_CLIMATE_ACCORDS let AIs decide
('CultureVictoryDiscussions',   'WC_EMERGENCY_WORLD_GAMES', 1),
('ScienceVictoryDiscussions',   'WC_EMERGENCY_WORLD_GAMES', 0),
('MilitaryVictoryDiscussions',  'WC_EMERGENCY_WORLD_GAMES', 0),
('ScienceVictoryDiscussions',   'WC_EMERGENCY_SPACE_STATION', 1),
('CultureVictoryDiscussions',   'WC_EMERGENCY_SPACE_STATION', 0),
('ReligiousVictoryDiscussions', 'WC_EMERGENCY_SPACE_STATION', 0),
('CultureVictoryDiscussions',   'WC_EMERGENCY_WORLD_FAIR', 1),
('ScienceVictoryDiscussions',   'WC_EMERGENCY_WORLD_FAIR', 1),
('ReligiousVictoryDiscussions', 'WC_EMERGENCY_WORLD_FAIR', 0),
('MilitaryVictoryDiscussions',  'WC_EMERGENCY_WORLD_FAIR', 0),
-- Resolutions
('DiploVictoryResolutions',     'WC_RES_DIPLOVICTORY', 1), -- +2 DVP
-- WC_RES_LUXURY  can't ban crabs... :(
('ReligiousVictoryResolutions', 'WC_RES_WORLD_RELIGION', 1), -- world religion
('ScienceVictoryResolutions',   'WC_RES_WORLD_RELIGION', 0), -- condemn religion
('MilitaryVictoryResolutions',  'WC_RES_MERCENARY_COMPANIES', 0), -- OptionA +100% cost of units, OptionB -50%
('DiploVictoryResolutions',     'WC_RES_MERCENARY_COMPANIES', 1), -- units +100% cost
('CultureVictoryResolutions',   'WC_RES_MERCENARY_COMPANIES', 1), -- units +100% cost
('DiploVictoryResolutions',     'WC_RES_ARMS_CONTROL', 0), -- no nukes
('CultureVictoryResolutions',   'WC_RES_ARMS_CONTROL', 0), -- no nukes
('CultureVictoryResolutions',   'WC_RES_HERITAGE_ORG', 1), -- tourism x2
('ScienceVictoryResolutions',   'WC_RES_HERITAGE_ORG', 0), -- no tourism
('DiploVictoryResolutions',     'WC_RES_POLICY_TREATY', 1), -- favor from policy
-- WC_RES_WORLD_IDEOLOGY too generic
-- WC_RES_URBAN_DEVELOPMENT too generic
-- WC_RES_BORDER_CONTROL too generic
('DiploVictoryResolutions',     'WC_RES_PUBLIC_WORKS', 1), -- +100% for the project
('ScienceVictoryResolutions',   'WC_RES_PUBLIC_WORKS', 1),
('CultureVictoryResolutions',   'WC_RES_PATRONAGE', 1), -- 2x GPP
('ScienceVictoryResolutions',   'WC_RES_PATRONAGE', 1),
('ReligiousVictoryResolutions', 'WC_RES_PATRONAGE', 0), -- no GPP
('DiploVictoryResolutions',     'WC_RES_PATRONAGE', 0), -- no GPP
('DiploVictoryResolutions',     'WC_RES_TREATY_ORGANIZATION', 1), -- 2x favor from CS
('MilitaryVictoryResolutions',  'WC_RES_TREATY_ORGANIZATION', 0), -- no favor from CS
('DiploVictoryResolutions',     'WC_RES_GOVERNANCE_DOCTRINE', 1), -- 15 favor from governors
-- WC_RES_GLOBAL_ENERGY_TREATY -- only Power Plants are considered
('ReligiousVictoryResolutions', 'WC_RES_GLOBAL_ENERGY_TREATY', 0), -- ban production
('MilitaryVictoryResolutions',  'WC_RES_GLOBAL_ENERGY_TREATY', 0), -- ban production
('ScienceVictoryResolutions',   'WC_RES_GLOBAL_ENERGY_TREATY', 0), -- 50% discount
-- WC_RES_SOVEREIGNTY too generic
('MilitaryVictoryResolutions',  'WC_RES_MIGRATION_TREATY', 0); -- +5 loyalty helps with conquest
-- WC_RES_DEFORESTATION_TREATY too generic


-- ===========================================================================
-- STRATEGIES - changes to existing ones
-- ===========================================================================


------------------------------------------------------------------------------
-- VICTORY_STRATEGY_SCIENCE_VICTORY

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('ScienceVictoryProjects', 'PROJECT_ORBITAL_LASER',     1, 0),
('ScienceVictoryProjects', 'PROJECT_TERRESTRIAL_LASER', 1, 0);


------------------------------------------------------------------------------
-- RST_STRATEGY_ANTI_SCIENCE

DELETE FROM AiFavoredItems WHERE ListType = 'AntiScienceProjects' AND Item IN ('PROJECT_LAUNCH_MARS_REACTOR', 'PROJECT_LAUNCH_MARS_HABITATION', 'PROJECT_LAUNCH_MARS_HYDROPONICS');

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
-- projects, disfavored all except Satellite (knowing the map is good) PROJECT_LAUNCH_EARTH_SATELLITE
('AntiScienceProjects', 'PROJECT_LAUNCH_MARS_BASE',  0, 0), -- well, I actually don't know if "disfavor" works here
('AntiScienceProjects', 'PROJECT_LAUNCH_EXOPLANET_EXPEDITION', 0, 0),
('AntiScienceProjects', 'PROJECT_ORBITAL_LASER',     0, 0),
('AntiScienceProjects', 'PROJECT_TERRESTRIAL_LASER', 0, 0);


------------------------------------------------------------------------------
-- RST_STRATEGY_ANTI_RELIGIOUS

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('AntiReligiousPseudoYields', 'PSEUDOYIELD_RELIGIOUS_CONVERT_EMPIRE', 1, -50);


------------------------------------------------------------------------------
-- RST_STRATEGY_ANTI_DIPLO

INSERT INTO Types (Type, Kind) VALUES
('RST_STRATEGY_ANTI_DIPLO', 'KIND_VICTORY_STRATEGY');

INSERT INTO Strategies (StrategyType, VictoryType, NumConditionsNeeded) VALUES
('RST_STRATEGY_ANTI_DIPLO', NULL, 1);

INSERT INTO StrategyConditions (StrategyType, ConditionFunction, StringValue) VALUES
('RST_STRATEGY_ANTI_DIPLO', 'Call Lua Function', 'ActiveStrategyAntiDiplo');

INSERT INTO AiListTypes (ListType) VALUES
('AntiDiploYields'),
('AntiDiploPseudoYields'),
('AntiDiploProjects'),
('AntiDiploWonders');

INSERT INTO AiLists (ListType, System) VALUES
('AntiDiploYields',       'Yields'),
('AntiDiploPseudoYields', 'PseudoYields'),
('AntiDiploProjects',     'Projects'),
('AntiDiploWonders',      'Buildings');

INSERT INTO Strategy_Priorities (StrategyType, ListType) VALUES
('RST_STRATEGY_ANTI_DIPLO', 'AntiDiploYields'),
('RST_STRATEGY_ANTI_DIPLO', 'AntiDiploPseudoYields'),
('RST_STRATEGY_ANTI_DIPLO', 'AntiDiploProjects'),
('RST_STRATEGY_ANTI_DIPLO', 'AntiDiploWonders');

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('AntiDiploYields', 'YIELD_GOLD', 1, -10),
('AntiDiploPseudoYields', 'PSEUDOYIELD_DIPLOMATIC_FAVOR', 1, -25),
('AntiDiploPseudoYields', 'PSEUDOYIELD_DIPLOMATIC_BONUS', 1, -10),
('AntiDiploPseudoYields', 'PSEUDOYIELD_INFLUENCE', 1, -15),
('AntiDiploProjects', 'PROJECT_CARBON_RECAPTURE', 0, 0),
('AntiDiploWonders', 'BUILDING_ORSZAGHAZ',      0, 0),
('AntiDiploWonders', 'BUILDING_STATUE_LIBERTY', 0, 0);



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
-- to be updated
DELETE FROM RSTFlavors WHERE ObjectType = 'POLICY_SIMULTANEUM';

INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES -- generated from Excel
		('POLICY_SIMULTANEUM', 'POLICY', 'ECONOMIC', 'CULTURE', 4),	('POLICY_SIMULTANEUM', 'POLICY', 'ECONOMIC', 'RELIGION', 7),	
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


-- LEADER_DIDO

INSERT INTO AiListTypes (ListType) VALUES
('DidoPseudoYields'),
('DidoDistricts');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('DidoPseudoYields', 'TRAIT_LEADER_FOUNDER_CARTHAGE', 'PseudoYields'),
('DidoDistricts',    'TRAIT_LEADER_FOUNDER_CARTHAGE', 'Districts');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('DidoPseudoYields', 'PSEUDOYIELD_GPP_ADMIRAL', 1, 15),
('DidoDistricts', 'DISTRICT_GOVERNMENT', 1, 0),
-- the list is defined but no wonders defined
('DidoWonders', 'BUILDING_COLOSSUS', 1, 0),
('DidoWonders', 'BUILDING_GREAT_LIGHTHOUSE', 1, 0),
('DidoWonders', 'BUILDING_HALICARNASSUS_MAUSOLEUM', 1, 0),
('DidoWonders', 'BUILDING_PANAMA_CANAL', 1, 0);


-- LEADER_ELEANOR_ENGLAND
-- LEADER_ELEANOR_FRANCE
-- TODO: note that England and France fatures are not supported by Eleanor's AI in GS
-- TODO: England is just for Victoria and France for Catherine - must separate Civ from Leader!

INSERT INTO AiListTypes (ListType) VALUES
('EleanorYields'),
('EleanorPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('EleanorYields',       'TRAIT_LEADER_ELEANOR_LOYALTY', 'Yields'),
('EleanorPseudoYields', 'TRAIT_LEADER_ELEANOR_LOYALTY', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('EleanorYields', 'YIELD_FOOD', 1, 15), -- more people -> more loyalty
('EleanorPseudoYields', 'PSEUDOYIELD_HAPPINESS', 1, 20),
('EleanorPseudoYields', 'PSEUDOYIELD_GOLDENAGE_POINT', 1, 50); -- more loyalty pressure


-- LEADER_KRISTINA

-- go for monarchy for more influence points, but no theocracy!
DELETE FROM AiFavoredItems WHERE ListType = 'KristinaCivics' AND Item IN ('CIVIC_DIVINE_RIGHT', 'CIVIC_REFORMED_CHURCH');

-- this is for compatibility with RTT when Monarchy is moved to another civic
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value)
SELECT 'KristinaCivics', PrereqCivic, 1, 0
FROM Governments
WHERE GovernmentType = 'GOVERNMENT_MONARCHY';

INSERT INTO AiListTypes (ListType) VALUES
('KristinaDiplomacy'),
('KristinaPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('KristinaDiplomacy',    'TRAIT_LEADER_KRISTINA_AUTO_THEME', 'DiplomaticActions'),
('KristinaPseudoYields', 'TRAIT_LEADER_KRISTINA_AUTO_THEME', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('KristinaDiplomacy', 'DIPLOACTION_RESIDENT_EMBASSY', 1, 0),
('KristinaDiplomacy', 'DIPLOACTION_ALLIANCE', 1, 0), -- alliances give favor
('KristinaDiplomacy', 'DIPLOACTION_RENEW_ALLIANCE', 1, 0),
('KristinaPseudoYields', 'PSEUDOYIELD_GPP_ENGINEER', 0, 25),
('KristinaPseudoYields', 'PSEUDOYIELD_GPP_SCIENTIST', 0, 25),
('KristinaPseudoYields', 'PSEUDOYIELD_INFLUENCE', 0, 25); -- envoys -> favor

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value)
SELECT 'KristinaPseudoYields', PseudoYieldType, 1, 25
FROM PseudoYields
WHERE PseudoYieldType LIKE 'PSEUDOYIELD_GREATWORK_%';


-- LEADER_KUPE

INSERT INTO AiListTypes (ListType) VALUES
('KupeSettlement'),
('KupeUnits'),
('KupePseudoYields'),
('KupeScoutUses');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('KupeSettlement',   'TRAIT_LEADER_KUPES_VOYAGE', 'PlotEvaluations'),
('KupeUnits',        'TRAIT_LEADER_KUPES_VOYAGE', 'Units'),
('KupePseudoYields', 'TRAIT_LEADER_KUPES_VOYAGE', 'PseudoYields'),
('KupeScoutUses',    'TRAIT_LEADER_KUPES_VOYAGE', 'AiScoutUses');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('KupeUnits', 'UNIT_NATURALIST', 1, 50),
('KupePseudoYields', 'PSEUDOYIELD_ENVIRONMENT', 1, 50),
('KupePseudoYields', 'PSEUDOYIELD_TOURISM', 1, 25),
('KupeScoutUses', 'DEFAULT_NAVAL_SCOUTS', 1, 100);

-- settlement
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value, StringVal) VALUES
('KupeSettlement', 'Specific Feature', 0, 3, 'FEATURE_FOREST'),
('KupeSettlement', 'Specific Feature', 0, 3, 'FEATURE_JUNGLE');


-- LEADER_LAURIER

UPDATE AiFavoredItems SET Value = -100 WHERE ListType = 'LaurierUnits' AND Item = 'UNIT_NATURALIST'; -- def. -1

INSERT INTO AiListTypes (ListType) VALUES
('LaurierDiplomacy'),
('LaurierPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('LaurierDiplomacy',    'TRAIT_LEADER_LAST_BEST_WEST', 'DiplomaticActions'),
('LaurierPseudoYields', 'TRAIT_LEADER_LAST_BEST_WEST', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('LaurierDiplomacy', 'DIPLOACTION_ALLIANCE', 1, 0),
('LaurierDiplomacy', 'DIPLOACTION_RENEW_ALLIANCE', 1, 0),
('LaurierDiplomacy', 'DIPLOACTION_RESIDENT_EMBASSY', 1, 0),
('LaurierPseudoYields', 'PSEUDOYIELD_DIPLOMATIC_FAVOR', 1, 25);


-- LEADER_MANSA_MUSA
-- golden ages, int. TRs, gold, GPP merchant, faith

INSERT INTO AiListTypes (ListType) VALUES
('MansaMusaDiplomacy'),
('MansaMusaYields'),
('MansaMusaPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('MansaMusaDiplomacy',    'TRAIT_LEADER_SAHEL_MERCHANTS', 'DiplomaticActions'),
('MansaMusaYields',       'TRAIT_LEADER_SAHEL_MERCHANTS', 'Yields'),
('MansaMusaPseudoYields', 'TRAIT_LEADER_SAHEL_MERCHANTS', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('MansaMusaDiplomacy', 'DIPLOACTION_ALLIANCE_ECONOMIC', 1, 0),
('MansaMusaDiplomacy', 'DIPLOACTION_ALLIANCE_RELIGIOUS', 1, 0),
('MansaMusaYields', 'YIELD_FAITH', 1, 20),
('MansaMusaPseudoYields', 'PSEUDOYIELD_GOLDENAGE_POINT', 1, 25),
('MansaMusaPseudoYields', 'PSEUDOYIELD_GPP_MERCHANT', 1, 25);


-- LEADER_MATTHIAS_CORVINUS
-- across river, geothermal fissure, alliances

INSERT INTO AiListTypes (ListType) VALUES
('MatthiasSettlement'),
('MatthiasBuildings'),
('MatthiasDiplomacy');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('MatthiasSettlement', 'TRAIT_LEADER_RAVEN_KING', 'PlotEvaluations'),
('MatthiasBuildings',  'TRAIT_LEADER_RAVEN_KING', 'Buildings'),
('MatthiasDiplomacy',  'TRAIT_LEADER_RAVEN_KING', 'DiplomaticActions');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('MatthiasBuildings', 'BUILDING_GOV_CITYSTATES', 1, 0), -- cheaper CS levy
('MatthiasDiplomacy', 'DIPLOACTION_ALLIANCE', 1, 0); -- huszar gets +3 CS for each alliance

-- settlement
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value, StringVal) VALUES
('MatthiasSettlement', 'Specific Feature', 0, 8, 'FEATURE_GEOTHERMAL_FISSURE'),
('MatthiasSettlement', 'Fresh Water',      0, 8, NULL);


-- LEADER_PACHACUTI
-- hmmm... nothing special here...


-- LEADER_SULEIMAN
-- happiness, loyalty

UPDATE AiFavoredItems SET Value = 15 WHERE ListType = 'SuliemanUnits' AND Item = 'PROMOTION_CLASS_SIEGE';

INSERT INTO AiListTypes (ListType) VALUES
('SuliemanDiplomacy'),
('SuliemanPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('SuliemanDiplomacy', 'TRAIT_LEADER_SULEIMAN_GOVERNOR', 'DiplomaticActions'),
('SuliemanPseudoYields', 'TRAIT_LEADER_SULEIMAN_GOVERNOR', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('SuliemanDiplomacy', 'DIPLOACTION_DECLARE_TERRITORIAL_WAR', 1, 0),
('SuliemanDiplomacy', 'DIPLOACTION_DECLARE_FORMAL_WAR', 1, 0),
('SuliemanDiplomacy', 'DIPLOACTION_DECLARE_IDEOLOGICAL_WAR', 1, 0),
('SuliemanPseudoYields', 'PSEUDOYIELD_HAPPINESS', 1, 20),
('SuliemanPseudoYields', 'PSEUDOYIELD_CITY_BASE', 1, 100), -- siege cities
('SuliemanPseudoYields', 'PSEUDOYIELD_CITY_DEFENSES', 1, -15), -- we have bombards
('SuliemanPseudoYields', 'PSEUDOYIELD_UNIT_COMBAT', 1, 15);



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
