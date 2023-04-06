-- ===========================================================================
-- Real Fixes: Elizabeth
-- Author: Infixo
-- 2023-03-31: Created
-- ===========================================================================

DELETE FROM TraitModifiers WHERE TraitType = 'TRAIT_LEADER_ELIZABETH' AND ModifierId = 'ELIZABETH_TRADE_ROUTES_MODIFIER';
UPDATE Modifiers SET OwnerRequirementSetId = NULL WHERE ModifierId = 'ELIZABETH_TRADE_ROUTES_MODIFIER';


/*
-- Attempt 1

CREATE VIEW RFXTemp AS
SELECT SUBSTR(GreatPersonIndividualType,25) AS Name 
FROM GreatPersonIndividuals 
WHERE GreatPersonClassType = 'GREAT_PERSON_CLASS_ADMIRAL' 
	AND EraType IN ('ERA_CLASSICAL', 'ERA_MEDIEVAL', 'ERA_RENAISSANCE') 
	AND GreatPersonIndividualType NOT IN
	(
		SELECT Value FROM RequirementArguments WHERE RequirementId IN
		(
			SELECT RequirementId FROM Requirements WHERE RequirementType = 'REQUIREMENT_PLAYER_HAS_GREAT_PERSON'
		)
	);

INSERT INTO Requirements (RequirementId,RequirementType)
SELECT 'PLAYER_HAS_'||Name, 'REQUIREMENT_PLAYER_HAS_GREAT_PERSON'
FROM RFXTemp;

INSERT INTO RequirementSetRequirements (RequirementSetId,RequirementId)
SELECT 'PLAYER_HAS_GREAT_ADMIRAL_REQUIREMENTS', 'PLAYER_HAS_'||Name
FROM RFXTemp;

INSERT INTO RequirementArguments (RequirementId,Name,Value)
SELECT 'PLAYER_HAS_'||Name, 'GreatPersonIndividual', 'GREAT_PERSON_INDIVIDUAL_'||Name
FROM RFXTemp;

DROP VIEW RFXTemp;
*/

/*
-- Attempt 2

DELETE FROM RequirementSetRequirements WHERE RequirementSetId = 'PLAYER_HAS_GREAT_ADMIRAL_REQUIREMENTS';
DELETE FROM RequirementArguments WHERE Name = 'GreatPersonIndividual';
DELETE FROM Requirements WHERE RequirementType = 'REQUIREMENT_PLAYER_HAS_GREAT_PERSON';

INSERT INTO Requirements (RequirementId,RequirementType)
SELECT 'PLAYER_HAS_'||SUBSTR(GreatPersonIndividualType,25), 'REQUIREMENT_PLAYER_HAS_GREAT_PERSON'
FROM GreatPersonIndividuals 
WHERE GreatPersonClassType = 'GREAT_PERSON_CLASS_ADMIRAL' AND EraType IN ('ERA_CLASSICAL', 'ERA_MEDIEVAL', 'ERA_RENAISSANCE');

INSERT INTO RequirementSetRequirements (RequirementSetId,RequirementId)
SELECT 'PLAYER_HAS_GREAT_ADMIRAL_REQUIREMENTS', 'PLAYER_HAS_'||SUBSTR(GreatPersonIndividualType,25)
FROM GreatPersonIndividuals 
WHERE GreatPersonClassType = 'GREAT_PERSON_CLASS_ADMIRAL' AND EraType IN ('ERA_CLASSICAL', 'ERA_MEDIEVAL', 'ERA_RENAISSANCE');

INSERT INTO RequirementArguments (RequirementId,Name,Value)
SELECT 'PLAYER_HAS_'||SUBSTR(GreatPersonIndividualType,25), 'GreatPersonIndividual', GreatPersonIndividualType
FROM GreatPersonIndividuals 
WHERE GreatPersonClassType = 'GREAT_PERSON_CLASS_ADMIRAL' AND EraType IN ('ERA_CLASSICAL', 'ERA_MEDIEVAL', 'ERA_RENAISSANCE');
*/

/*
-- Attemp 3

INSERT OR IGNORE INTO Requirements (RequirementId,RequirementType) -- Macedonia DLC
VALUES ('REQUIREMENT_UNIT_IS_ADMIRAL','REQUIREMENT_GREAT_PERSON_TYPE_MATCHES');

INSERT OR IGNORE INTO RequirementArguments (RequirementId,Name,Value) -- Macedonia DLC
SELECT 'REQUIREMENT_UNIT_IS_ADMIRAL', 'GreatPersonClassType', 'GREAT_PERSON_CLASS_ADMIRAL';

UPDATE Modifiers SET OwnerRequirementSetId = 'UNIT_IS_ADMIRAL' WHERE ModifierId = 'ELIZABETH_TRADE_ROUTES_MODIFIER';
*/
