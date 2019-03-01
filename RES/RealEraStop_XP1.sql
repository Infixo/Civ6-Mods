--------------------------------------------------------------
-- Real Era Stop - Rise & Fall changes
-- Author: Infixo
-- 2019-03-01: Created
--------------------------------------------------------------


--------------------------------------------------------------
-- 2019-03-01 Game Eras
-- Must remove eras after last one and update the last to "last" forever
-- Otherwise the game era will progress beyond the last era
-- This may be harmful whenever "min" era is used somewhere
-- Like World Congress - can trigger resolutions from later eras

DELETE FROM Eras_XP1 WHERE EraType IN (SELECT EraType FROM RESEras);

UPDATE Eras_XP1 SET GameEraMinimumTurns = NULL, GameEraMaximumTurns = NULL
WHERE EraType = (SELECT EraType FROM Eras WHERE ChronologyIndex = (SELECT Value FROM GlobalParameters WHERE Name = 'RES_MAX_ERA'));
