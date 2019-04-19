--------------------------------------------------------------
-- Real Game Balance
-- Author: Infixo
-- 2019-04-18: Created
--------------------------------------------------------------

--------------------------------------------------------------
-- Districts

UPDATE LocalizedText
SET Text = Text||' +2 [ICON_Gold] Gold from the adjacent Oasis.'
WHERE Language = 'en_US' AND Tag = 'LOC_DISTRICT_SUGUBA_DESCRIPTION';
