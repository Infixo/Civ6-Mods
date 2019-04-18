--------------------------------------------------------------
-- Real Balanced Pantheons
-- LOCs created dynamically for compatibility with resource mods
-- Author: Infixo
-- 2019-04-16: Created
-- 2019-04-18: Russian localization by MiAMi
--------------------------------------------------------------

-- Pantheon - Local Resource Bonuses

UPDATE LocalizedText
SET Text = Text||'[NEWLINE]Дополнительно в эпоху Древнего мира: +1 [ICON_Food] пищи от этих ресурсов без улучшений.'
WHERE Language = 'ru_RU' AND Tag = 'LOC_BELIEF_GODDESS_OF_FESTIVALS_DESCRIPTION';

UPDATE LocalizedText
SET Text = Text||'[NEWLINE]Дополнительно в эпоху Древнего мира: +1 [ICON_Culture] культуры от этих ресурсов без улучшений.'
WHERE Language = 'ru_RU' AND Tag = 'LOC_BELIEF_ORAL_TRADITION_DESCRIPTION';
