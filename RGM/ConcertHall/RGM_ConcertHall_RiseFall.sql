--------------------------------------------------------------
-- RGM_ConcertHall_RiseFall
-- Author: Infixo
-- 2018-03-28: Created
--------------------------------------------------------------

-- Policy Grand Opera was changed in R&F

-- remove old data
DELETE FROM PolicyModifiers    WHERE ModifierId = 'GRANDOPERA_DOUBLECONCERTHALL';
DELETE FROM Modifiers          WHERE ModifierId = 'GRANDOPERA_DOUBLECONCERTHALL';
DELETE FROM ModifierArguments  WHERE ModifierId = 'GRANDOPERA_DOUBLECONCERTHALL';

-- Policy Grand Opera
-- GRANDOPERA_BUILDING_YIELDS_HIGH_ADJACENCY -- automatic, works for all buildings in the district
-- GRANDOPERA_BUILDING_YIELDS_HIGH_POP -- same as above

-- Minor Civ Traits

INSERT INTO TraitModifiers (TraitType, ModifierId)
SELECT 'MINOR_CIV_CULTURAL_TRAIT', 'MINOR_CIV_CULTURAL_LARGE_INFLUENCE_BONUS_MUSIC'
FROM GlobalParameters WHERE Name = 'RGM_OPTION_CONCERT_HALL' AND Value = '1';

-- conditional modifier for large influence
INSERT INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId)
SELECT 'MINOR_CIV_CULTURAL_LARGE_INFLUENCE_BONUS_MUSIC', 'MODIFIER_ALL_PLAYERS_ATTACH_MODIFIER', 'PLAYER_HAS_LARGE_INFLUENCE'
FROM GlobalParameters WHERE Name = 'RGM_OPTION_CONCERT_HALL' AND Value = '1';

INSERT INTO ModifierArguments (ModifierId, Name, Value)
SELECT 'MINOR_CIV_CULTURAL_LARGE_INFLUENCE_BONUS_MUSIC', 'ModifierId', 'MINOR_CIV_CULTURAL_YIELD_FOR_MUSIC'
FROM GlobalParameters WHERE Name = 'RGM_OPTION_CONCERT_HALL' AND Value = '1';

-- the actual modifier that changes yields
INSERT INTO Modifiers (ModifierId, ModifierType)
SELECT 'MINOR_CIV_CULTURAL_YIELD_FOR_MUSIC', 'MODIFIER_PLAYER_CITIES_ADJUST_BUILDING_YIELD_CHANGE'
FROM GlobalParameters WHERE Name = 'RGM_OPTION_CONCERT_HALL' AND Value = '1';

INSERT INTO ModifierArguments (ModifierId, Name, Value)
SELECT 'MINOR_CIV_CULTURAL_YIELD_FOR_MUSIC', 'BuildingType', 'BUILDING_CONCERT_HALL'
FROM GlobalParameters WHERE Name = 'RGM_OPTION_CONCERT_HALL' AND Value = '1';

INSERT INTO ModifierArguments (ModifierId, Name, Value)
SELECT 'MINOR_CIV_CULTURAL_YIELD_FOR_MUSIC', 'YieldType', 'YIELD_CULTURE'
FROM GlobalParameters WHERE Name = 'RGM_OPTION_CONCERT_HALL' AND Value = '1';

INSERT INTO ModifierArguments (ModifierId, Name, Value)
SELECT 'MINOR_CIV_CULTURAL_YIELD_FOR_MUSIC', 'Amount', '2'
FROM GlobalParameters WHERE Name = 'RGM_OPTION_CONCERT_HALL' AND Value = '1';

INSERT INTO ModifierArguments (ModifierId, Name, Value)
SELECT 'MINOR_CIV_CULTURAL_YIELD_FOR_MUSIC', 'CityStatesOnly', '1'
FROM GlobalParameters WHERE Name = 'RGM_OPTION_CONCERT_HALL' AND Value = '1';
