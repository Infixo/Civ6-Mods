-- ===========================================================================
-- Real Strategy - main file for Gathering Storm content (leaders and wonders)
-- Author: Infixo
-- 2019-03-09: Created
-- ===========================================================================


-- ===========================================================================
-- FLAVORS
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
('SuliemanYields'),
('SuliemanPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('SuliemanDiplomacy',    'TRAIT_LEADER_SULEIMAN_GOVERNOR', 'DiplomaticActions'),
('SuliemanYields',       'TRAIT_LEADER_SULEIMAN_GOVERNOR', 'Yields'),
('SuliemanPseudoYields', 'TRAIT_LEADER_SULEIMAN_GOVERNOR', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('SuliemanDiplomacy', 'DIPLOACTION_DECLARE_TERRITORIAL_WAR', 1, 0),
('SuliemanDiplomacy', 'DIPLOACTION_DECLARE_FORMAL_WAR', 1, 0),
('SuliemanDiplomacy', 'DIPLOACTION_DECLARE_IDEOLOGICAL_WAR', 1, 0),
('SuliemanYields', 'YIELD_FAITH', 1, -20),
('SuliemanPseudoYields', 'PSEUDOYIELD_GPP_PROPHET', 1, -20),
('SuliemanPseudoYields', 'PSEUDOYIELD_HAPPINESS', 1, 20),
('SuliemanPseudoYields', 'PSEUDOYIELD_CITY_BASE', 1, 100), -- siege cities
('SuliemanPseudoYields', 'PSEUDOYIELD_CITY_DEFENSES', 1, -15), -- we have bombards
('SuliemanPseudoYields', 'PSEUDOYIELD_UNIT_COMBAT', 1, 15);
