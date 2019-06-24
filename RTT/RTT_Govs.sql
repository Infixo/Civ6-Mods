--------------------------------------------------------------
-- Real Tech Tree
-- Optional - placement of Governments
-- Author: Infixo
-- 2019-01-02: Created
--------------------------------------------------------------

-- Change this parameter to '1' to activate balanced Government placement
INSERT INTO GlobalParameters (Name, Value) VALUES ('RTT_OPTION_GOVS', '0');

--UPDATE GlobalParameters SET Value = '1' WHERE Name = 'GOVERNMENT_ALLOW_EMPTY_POLICY_SLOTS' AND EXISTS (SELECT * FROM GlobalParameters WHERE Name = 'RTT_OPTION_GOVS' AND Value = '1');

-- Autocracy
--UPDATE Governments SET PrereqCivic = 'CIVIC_GAMES_RECREATION' WHERE GovernmentType = 'GOVERNMENT_AUTOCRACY' AND EXISTS (SELECT * FROM GlobalParameters WHERE Name = 'RTT_OPTION_GOVS' AND Value = '1');

-- Classical Republic
--UPDATE Governments SET PrereqCivic = 'CIVIC_DRAMA_POETRY' WHERE GovernmentType = 'GOVERNMENT_CLASSICAL_REPUBLIC' AND EXISTS (SELECT * FROM GlobalParameters WHERE Name = 'RTT_OPTION_GOVS' AND Value = '1');

-- Monarchy
UPDATE Governments SET PrereqCivic = 'CIVIC_DIPLOMATIC_SERVICE' WHERE GovernmentType = 'GOVERNMENT_MONARCHY' AND EXISTS (SELECT * FROM GlobalParameters WHERE Name = 'RTT_OPTION_GOVS' AND Value = '1');
