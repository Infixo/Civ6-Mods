-- ===========================================================================
-- Better Loading Screen
-- Author: Infixo
-- 2023-04-15: Created
-- ===========================================================================


-- options
INSERT INTO GlobalParameters (Name, Value) VALUES ('BLS_OPTION_PLAY_DOM_AUDIO', '1'); -- '1' is default (plays), '0' turns off


-- ===========================================================================

-- Add missing leaders to the config table
INSERT OR IGNORE INTO LoadingInfo (LeaderType,ForegroundImage,BackgroundImage,LeaderText,DawnOfManLeaderId)
SELECT LeaderType, LeaderType||'_NEUTRAL', LeaderType||'_BACKGROUND', 'LOC_LOADING_INFO_'||LeaderType, LeaderType
FROM Leaders
WHERE InheritFrom = 'LEADER_DEFAULT' AND LeaderType NOT IN (SELECT LeaderType FROM LoadingInfo);

-- Turn on/off Dawn of Man audio
UPDATE LoadingInfo
SET PlayDawnOfManAudio = 0
WHERE EXISTS (SELECT * FROM GlobalParameters WHERE Name = 'BLS_OPTION_PLAY_DOM_AUDIO' AND Value = '0');
