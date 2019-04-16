--------------------------------------------------------------
-- Real Balanced Pantheons
-- LOCs created dynamically for compatibility with resource mods
-- Author: Infixo
-- 2019-04-16: Created
--------------------------------------------------------------

-- Pantheon - Local Resource Bonuses

UPDATE LocalizedText
SET Text = Text||'[NEWLINE]Additionally, in Ancient Era: +1 [ICON_Food] Food from these resources when unimproved.'
WHERE Language = 'en_US' AND Tag = 'LOC_BELIEF_GODDESS_OF_FESTIVALS_DESCRIPTION';

UPDATE LocalizedText
SET Text = Text||'[NEWLINE]Additionally, in Ancient Era: +1 [ICON_Culture] Culture from these resources when unimproved.'
WHERE Language = 'en_US' AND Tag = 'LOC_BELIEF_ORAL_TRADITION_DESCRIPTION';
