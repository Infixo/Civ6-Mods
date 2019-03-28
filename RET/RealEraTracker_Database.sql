-- ===========================================================================
-- Real Era Tracker
-- Author: Infixo
-- 2019-03-28: Created
-- ===========================================================================

-- just to make versioning easier
INSERT INTO GlobalParameters (Name, Value) VALUES ('RET_VERSION_MAJOR', '0');
INSERT INTO GlobalParameters (Name, Value) VALUES ('RET_VERSION_MINOR', '1');

-- options
INSERT INTO GlobalParameters (Name, Value) VALUES ('RET_OPTION_INCLUDE_OTHERS', '1'); -- set to 1 to detect historic moments that other players earned 
																					  -- please note that this is technically cheating as the game doesn't inform you about them (with few exceptions)
