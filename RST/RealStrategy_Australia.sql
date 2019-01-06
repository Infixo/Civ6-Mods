-- ===========================================================================
-- Real Strategy - main file for Australia DLC
-- Author: Infixo
-- 2019-01-05: Created
-- ===========================================================================

INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES -- generated from Excel
('LEADER_JOHN_CURTIN', 'LEADER', '', 'CONQUEST', 4),
('LEADER_JOHN_CURTIN', 'LEADER', '', 'SCIENCE',  5),
('LEADER_JOHN_CURTIN', 'LEADER', '', 'CULTURE',  6),
('LEADER_JOHN_CURTIN', 'LEADER', '', 'RELIGION', 1);


-- LEADER_JOHN_CURTIN / AUSTRALIA

INSERT INTO AiListTypes (ListType) VALUES
('CurtinSettlement'),
('CurtinDiplomacy'),
('CurtinPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('CurtinSettlement',   'TRAIT_LEADER_CITADEL_CIVILIZATION', 'PlotEvaluations'),
('CurtinDiplomacy',    'TRAIT_LEADER_CITADEL_CIVILIZATION', 'DiplomaticActions'),
('CurtinPseudoYields', 'TRAIT_LEADER_CITADEL_CIVILIZATION', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('CurtinSettlement', 'Coastal', 0, 10),
('CurtinDiplomacy', 'DIPLOACTION_DECLARE_LIBERATION_WAR', 1, 0),
('CurtinDiplomacy', 'DIPLOACTION_DECLARE_PROTECTORATE_WAR', 1, 0),
('CurtinDiplomacy', 'DIPLOACTION_DECLARE_RECONQUEST_WAR', 1, 0),
('CurtinDiplomacy', 'DIPLOACTION_LIBERATE_CITY', 1, 0),
('CurtinPseudoYields', 'PSEUDOYIELD_TOURISM', 1, 10),
('CurtinPseudoYields', 'PSEUDOYIELD_ENVIRONMENT', 1, 20);
