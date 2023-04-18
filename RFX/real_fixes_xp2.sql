--------------------------------------------------------------
-- Real Fixes
-- Author: Infixo
-- 2021-05-14: Separate file for GS
--------------------------------------------------------------


--------------------------------------------------------------
-- 2021-05-14 Public Transport policy has been redefined but still has a modifier from R&F
DELETE FROM PolicyModifiers WHERE PolicyType = 'POLICY_PUBLIC_TRANSPORT' AND ModifierId = 'PUBLICTRANSPORT_FARMREPLACEGOLD';


--------------------------------------------------------------
-- 2021-06-08 "The Last Best West" is giving 1 instead of 2 production in some cases
-- Fixed in Nov 2022 patch
--UPDATE ModifierArguments SET Value = 2 WHERE ModifierId = 'SNOW_MINES_PRODUCTION';
--UPDATE ModifierArguments SET Value = 2 WHERE ModifierId = 'TUNDRA_HILLS_LUMBER_MILLS_PRODUCTION';


--------------------------------------------------------------
-- 2023-03-28 Not used AIList
DELETE FROM AiFavoredItems WHERE ListType = 'PatronOfArtsDiscussions';
DELETE FROM AiListTypes    WHERE ListType = 'PatronOfArtsDiscussions';


--------------------------------------------------------------
-- 2023-04-02 Buggy Keita's AI Lists
UPDATE AiLists SET LeaderType = 'TRAIT_LEADER_SUNDIATA_KEITA' WHERE ListType IN ('KeitaGreatWorks','KeitaCivics','KeitaTechs','KeitaWonders');


--------------------------------------------------------------
-- 2023-04-03 Buggy Suleiman's AI Lists
UPDATE AiFavoredItems SET ListType = 'SuliemanCivics' WHERE ListType = 'SuliemanTechs' AND Item = 'CIVIC_GAMES_RECREATION';
UPDATE AiLists SET System = 'PseudoYields' WHERE ListType = 'SuliemanGovernor' AND System = 'Buildings';


--------------------------------------------------------------
-- 2023-04-09 Strategic Air Force
-- will use only Information era
DELETE FROM ModifierArguments WHERE ModifierId = 'STRATEGICAIRFORCE_ATOMIC_NAVALCARRIER_PRODUCTION';
DELETE FROM Modifiers WHERE ModifierId = 'STRATEGICAIRFORCE_ATOMIC_NAVALCARRIER_PRODUCTION';
DELETE FROM PolicyModifiers WHERE PolicyType = 'POLICY_STRATEGIC_AIR_FORCE' AND ModifierId = 'STRATEGICAIRFORCE_ATOMIC_NAVALCARRIER_PRODUCTION';
-- make them non-era specific
UPDATE ModifierArguments
SET Value = 'NO_ERA'
WHERE Name = 'EraType' AND ModifierId IN
(
    SELECT ModifierId FROM PolicyModifiers WHERE PolicyType = 'POLICY_STRATEGIC_AIR_FORCE'
);


--------------------------------------------------------------
-- 2023-04-14 This should (I hope) help Toa and Mountie build their things
INSERT OR IGNORE INTO UnitAiInfos (UnitType, AiType) VALUES
('UNIT_MAORI_TOA',      'UNITAI_BUILD'),
('UNIT_CANADA_MOUNTIE', 'UNITAI_BUILD');
