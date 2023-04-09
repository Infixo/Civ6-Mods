--------------------------------------------------------------
-- Real Fixes
-- Author: Infixo
-- 2023-04-09: Fix for Tokugawa ability
--------------------------------------------------------------

-- modifier to give all districts in a city +1 tourism
INSERT INTO Modifiers (ModifierId, ModifierType) VALUES
('BAKUHAN_TOURISM_DISTRICTS_MODIFIER', 'MODIFIER_CITY_DISTRICTS_ADJUST_TOURISM_CHANGE');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('BAKUHAN_TOURISM_DISTRICTS_MODIFIER', 'Amount', '2');

-- fix main modifier to attach the above one to cities within 6 tiles and when the player has flight
UPDATE Modifiers
SET ModifierType = 'MODIFIER_PLAYER_CITIES_ATTACH_MODIFIER', OwnerRequirementSetId = 'PLAYER_HAS_FLIGHT', SubjectRequirementSetId = 'PLAYER_HAS_BAKUHAN_REUIREMENTS'
WHERE ModifierId = 'TOKUGAWA_TOURISM_DISTRICTS';

DELETE FROM ModifierArguments WHERE ModifierId = 'TOKUGAWA_TOURISM_DISTRICTS'; -- clear old args
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
('TOKUGAWA_TOURISM_DISTRICTS', 'ModifierId', 'BAKUHAN_TOURISM_DISTRICTS_MODIFIER');
