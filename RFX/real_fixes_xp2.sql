--------------------------------------------------------------
-- Real Fixes
-- Author: Infixo
-- 2021-05-14: Separate file for GS
--------------------------------------------------------------

-- 2021-05-14 Public Transport policy has been redefined but still has a modifier from R&F
DELETE FROM PolicyModifiers WHERE PolicyType = 'POLICY_PUBLIC_TRANSPORT' AND ModifierId = 'PUBLICTRANSPORT_FARMREPLACEGOLD';

-- 2021-06-08 "The Last Best West" is giving 1 instead of 2 production in some cases
-- Fixed in Nov 2022 patch
--UPDATE ModifierArguments SET Value = 2 WHERE ModifierId = 'SNOW_MINES_PRODUCTION';
--UPDATE ModifierArguments SET Value = 2 WHERE ModifierId = 'TUNDRA_HILLS_LUMBER_MILLS_PRODUCTION';

-- 2023-03-28 Not used AIList
DELETE FROM AiFavoredItems WHERE ListType = 'PatronOfArtsDiscussions';
DELETE FROM AiListTypes    WHERE ListType = 'PatronOfArtsDiscussions';
