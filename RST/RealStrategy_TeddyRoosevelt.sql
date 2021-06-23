-- ===========================================================================
-- Real Strategy - main file for Teddy Roosevelt DLC (aka Persona Pack)
-- Author: Infixo
-- 2021-06-15: Created
-- ===========================================================================


-- LEADER_T_ROOSEVELT (Bull Moose) / AMERICA
-- TRAIT_LEADER_ANTIQUES_AND_PARKS

DELETE FROM RSTFlavors WHERE ObjectType = 'LEADER_T_ROOSEVELT';

INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES
('LEADER_T_ROOSEVELT', 'LEADER', '', 'CONQUEST', 3),
('LEADER_T_ROOSEVELT', 'LEADER', '', 'SCIENCE',  3),
('LEADER_T_ROOSEVELT', 'LEADER', '', 'CULTURE',  8),
('LEADER_T_ROOSEVELT', 'LEADER', '', 'RELIGION', 1),
('LEADER_T_ROOSEVELT', 'LEADER', '', 'DIPLO',    6);

-- reuse existing AiLists
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('RooseveltWonders',      'TRAIT_LEADER_ANTIQUES_AND_PARKS', 'Buildings'),
('RooseveltTechs',        'TRAIT_LEADER_ANTIQUES_AND_PARKS', 'Technologies'),
('RooseveltCivics',       'TRAIT_LEADER_ANTIQUES_AND_PARKS', 'Civics'),
('RooseveltPseudoYields', 'TRAIT_LEADER_ANTIQUES_AND_PARKS', 'PseudoYields'),
('RooseveltUnits',        'TRAIT_LEADER_ANTIQUES_AND_PARKS', 'UnitPromotionClasses');

DELETE FROM AiFavoredItems WHERE ListType = 'RooseveltPseudoYields' AND Item = 'PSEUDOYIELD_ENVIRONMENT'; -- Bull Moose agenda has it


-- LEADER_T_ROOSEVELT_ROUGHRIDER / AMERICA
-- TRAIT_LEADER_ROOSEVELT_COROLLARY is assigned here

INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES
('LEADER_T_ROOSEVELT_ROUGHRIDER', 'LEADER', '', 'CONQUEST', 3),
('LEADER_T_ROOSEVELT_ROUGHRIDER', 'LEADER', '', 'SCIENCE',  3),
('LEADER_T_ROOSEVELT_ROUGHRIDER', 'LEADER', '', 'CULTURE',  6),
('LEADER_T_ROOSEVELT_ROUGHRIDER', 'LEADER', '', 'RELIGION', 1),
('LEADER_T_ROOSEVELT_ROUGHRIDER', 'LEADER', '', 'DIPLO',    8);

DELETE FROM LeaderTraits WHERE LeaderType = 'LEADER_T_ROOSEVELT_ROUGHRIDER' AND TraitType = 'TRAIT_LEADER_CULTURAL_MAJOR_CIV'; -- 210623 not needed

DELETE FROM AiLists WHERE ListType = 'RooseveltUnits' AND LeaderType = 'TRAIT_LEADER_ROOSEVELT_COROLLARY';
DELETE FROM AiLists WHERE ListType = 'RooseveltPseudoYields' AND LeaderType = 'TRAIT_LEADER_ROOSEVELT_COROLLARY';

INSERT INTO AiListTypes (ListType) VALUES
('RooseveltAltPseudoYields'),
('RooseveltAltUnitBuilds'),
('RooseveltAltDiploActions');

INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('RooseveltAltPseudoYields', 'TRAIT_LEADER_ROOSEVELT_COROLLARY', 'PseudoYields'),
('RooseveltAltUnitBuilds',   'TRAIT_LEADER_ROOSEVELT_COROLLARY', 'UnitPromotionClasses'),
('RooseveltAltDiploActions', 'TRAIT_LEADER_ROOSEVELT_COROLLARY', 'DiplomaticActions');

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('RooseveltAltPseudoYields', 'PSEUDOYIELD_DIPLOMATIC_FAVOR', 1, 15), -- favor
('RooseveltAltPseudoYields', 'PSEUDOYIELD_INFLUENCE', 1, 15), -- envoys
('RooseveltAltPseudoYields', 'PSEUDOYIELD_DIPLOMATIC_BONUS', 1, 15), -- good relations
('RooseveltAltUnitBuilds', 'PSEUDOYIELD_UNIT_TRADE',  1, 25), -- traders
('RooseveltAltDiploActions', 'DIPLOACTION_GRANT_INFLUENCE_TOKEN', 1, 0); -- suze all city states!
