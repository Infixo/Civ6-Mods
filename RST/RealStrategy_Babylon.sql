-- ===========================================================================
-- Real Strategy - main file for Babylon DLC
-- Author: Infixo
-- 2021-06-15: Created
-- ===========================================================================


-- LEADER_HAMMURABI / BABYLON
-- TRAIT_LEADER_HAMMURABI
-- Palgum @ Irrigation, Sabum Kibittum @ 

INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES
('LEADER_HAMMURABI', 'LEADER', '', 'CONQUEST', 1),
('LEADER_HAMMURABI', 'LEADER', '', 'SCIENCE',  8),
('LEADER_HAMMURABI', 'LEADER', '', 'CULTURE',  5),
('LEADER_HAMMURABI', 'LEADER', '', 'RELIGION', 1),
('LEADER_HAMMURABI', 'LEADER', '', 'DIPLO',    3);

INSERT INTO AiListTypes (ListType) VALUES
('HammurabiWonders'),
('HammurabiTechs'), 
('HammurabiCivics'),
('HammurabiPseudoYields'),
--('HammurabiUnitBuilds'),
('HammurabiAlliances'),
('HammurabiDiploActions');

INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('HammurabiWonders',      'TRAIT_LEADER_HAMMURABI', 'Buildings'),
('HammurabiTechs',        'TRAIT_LEADER_HAMMURABI', 'Technologies'),
('HammurabiCivics',       'TRAIT_LEADER_HAMMURABI', 'Civics'),
('HammurabiPseudoYields', 'TRAIT_LEADER_HAMMURABI', 'PseudoYields'),
--('HammurabiUnitBuilds',   'TRAIT_LEADER_HAMMURABI', 'UnitPromotionClasses'),
('HammurabiAlliances',    'TRAIT_LEADER_HAMMURABI', 'Alliances'),
('HammurabiDiploActions', 'TRAIT_LEADER_HAMMURABI', 'DiplomaticActions');

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('HammurabiWonders', 'BUILDING_GREAT_LIBRARY',     1, 0), -- gives boosts!
('HammurabiWonders', 'BUILDING_OXFORD_UNIVERSITY', 1, 0),
('HammurabiTechs', 'TECH_WRITING',    1, 0), -- for Campus and Library
('HammurabiTechs', 'TECH_IRRIGATION', 1, 0), -- for Campus and Library
('HammurabiCivics', 'CIVIC_RECORDED_HISTORY',  1, 0), -- for Great Library
('HammurabiPseudoYields', 'PSEUDOYIELD_GPP_SCIENTIST', 1, 15), -- compete for boosts here
--('HammurabiUnitBuilds', 'PROMOTION_CLASS_LIGHT_CAVALRY', 1, 10),
('HammurabiAlliances', 'ALLIANCE_RESEARCH', 1, 0), -- need more boosts
('HammurabiDiploActions', 'DIPLOACTION_ALLIANCE_RESEARCH', 1, 0); -- need more boosts
