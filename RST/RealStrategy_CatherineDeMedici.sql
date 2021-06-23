-- ===========================================================================
-- Real Strategy - main file for Catherine de Medici DLC (aka Persona Pack)
-- Author: Infixo
-- 2021-06-15: Created
-- ===========================================================================


-- LEADER_CATHERINE_DE_MEDICI_ALT / FRANCE
-- TRAIT_LEADER_MAGNIFICENCES
-- court festival project -> grants Culture & Tourism => Theater Square => Drama & Poetry
-- +2 culture from improved Luxes
-- France: chateau UI, garde imperiale UU
-- +20% for wonders medieval-renaissance-industrial

INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES
('LEADER_CATHERINE_DE_MEDICI_ALT', 'LEADER', '', 'CONQUEST', 3),
('LEADER_CATHERINE_DE_MEDICI_ALT', 'LEADER', '', 'SCIENCE',  3),
('LEADER_CATHERINE_DE_MEDICI_ALT', 'LEADER', '', 'CULTURE',  9),
('LEADER_CATHERINE_DE_MEDICI_ALT', 'LEADER', '', 'RELIGION', 2),
('LEADER_CATHERINE_DE_MEDICI_ALT', 'LEADER', '', 'DIPLO',    2);

DELETE FROM LeaderTraits WHERE LeaderType = 'LEADER_CATHERINE_DE_MEDICI_ALT' AND TraitType = 'TRAIT_LEADER_CULTURAL_MAJOR_CIV'; -- 210623 not needed

-- reuse as much of existing Catherin as possible

INSERT INTO AiListTypes (ListType) VALUES
('CatherineAltCivics'),
('CatherineAltProjects');
--resolutions?
--diplo actions?

INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('CatherineWonders',      'TRAIT_LEADER_MAGNIFICENCES', 'Buildings'),
('CatherineTechs',        'TRAIT_LEADER_MAGNIFICENCES', 'Technologies'),
--('CatherineCivics',       'TRAIT_LEADER_MAGNIFICENCES', 'Civics'), -- black queen's civics are weird
('CatherineAltCivics',    'TRAIT_LEADER_MAGNIFICENCES', 'Civics'),
('CatherineAltProjects',  'TRAIT_LEADER_MAGNIFICENCES', 'Projects'),
('CatherineYields',       'TRAIT_LEADER_MAGNIFICENCES', 'Yields'),
('CatherinePseudoYields', 'TRAIT_LEADER_MAGNIFICENCES', 'PseudoYields');

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('CatherineAltCivics', 'CIVIC_DRAMA_POETRY', 1, 0),
('CatherineAltCivics', 'CIVIC_HUMANISM',     1, 0),
('CatherineAltCivics', 'CIVIC_CONSERVATION', 1, 0),
('CatherineAltProjects', 'PROJECT_COURT_FESTIVAL', 1, 0);
