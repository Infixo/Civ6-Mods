--------------------------------------------------------------
-- Real Eurekas
-- Author: Infixo
-- Mar 15, 2017: Version 1
--			Rand module - a core module that randomizes Boosts
--------------------------------------------------------------

-- Intermediary table will keep ACTUAL FINAL mappings
CREATE TABLE REurFinalMapping (
    BoostID		INTEGER NOT NULL, -- each Tech and Civic has a unique BoostID assigned
	BoostTypeID	INTEGER NOT NULL DEFAULT 0, -- final Boost to use
	BoostSeq	INTEGER NOT NULL DEFAULT 0, -- randomly generated number 0..4
	FOREIGN KEY (BoostID) REFERENCES Boosts(BoostID) ON DELETE CASCADE ON UPDATE CASCADE,
	FOREIGN KEY (BoostTypeID) REFERENCES REurBoostDefs(BoostTypeID) ON DELETE CASCADE ON UPDATE CASCADE);
	
-- View used to update data in Boosts
CREATE VIEW REurBoostsView AS
SELECT Boosts.*, REurBoostDefs.*
FROM Boosts
LEFT JOIN REurFinalMapping
ON Boosts.BoostID = REurFinalMapping.BoostID
LEFT JOIN REurBoostDefs
ON REurFinalMapping.BoostTypeID = REurBoostDefs.BoostTypeID;

-- some training - clear Boosts and recreate it from BoostDefs
/*
UPDATE Boosts
SET 
	BoostClass = 'BOOST_TRIGGER_NONE_LATE_GAME_CRITICAL_TECH',
	TriggerDescription = 'LOC_BOOST_TRIGGER_MUST_STEAL',
	TriggerLongDescription = 'Cleared',
	Unit1Type = NULL,
	BuildingType = NULL,
	ImprovementType = NULL,
	BoostingTechType = NULL,
	ResourceType = NULL,
	NumItems = 0,
	DistrictType = NULL,
	RequiresResource = 0,
	BoostingCivicType = NULL;
*/

--------------------------------------------------------------
-- RANDOMIZE BOOSTS
--------------------------------------------------------------
-- 1. get all IDs from Boosts
INSERT INTO REurFinalMapping (BoostID)
SELECT BoostID FROM Boosts;
-- 2. assign random seq nums
UPDATE REurFinalMapping SET BoostSeq = ABS(RANDOM()%5);
-- 3. get BoostTypeIDs from mapping table
UPDATE REurFinalMapping
SET BoostTypeID = (
	SELECT BoostTypeID FROM REurMapping
	WHERE REurFinalMapping.BoostID = REurMapping.BoostID AND
		REurFinalMapping.BoostSeq = REurMapping.BoostSeq);

--------------------------------------------------------------
-- RECREATE BOOSTS TABLE
-- Do not change: BoostID, TechnologyType, CivicType, Boost, TriggerID, Unit2Type, RequirementSetId, GovernmentSlotType
--------------------------------------------------------------

--INSERT OR REPLACE INTO 
UPDATE Boosts SET BoostClass = 				(SELECT 'BOOST_TRIGGER_'||BClass				FROM REurBoostsView WHERE Boosts.BoostID = REurBoostsView.BoostID);
UPDATE Boosts SET TriggerDescription = 		(SELECT 'LOC_BOOST_TRIGGER_'||TDesc 			FROM REurBoostsView WHERE Boosts.BoostID = REurBoostsView.BoostID);
UPDATE Boosts SET TriggerLongDescription = 	(SELECT 'LOC_BOOST_TRIGGER_LONGDESC_'||TLDesc 	FROM REurBoostsView WHERE Boosts.BoostID = REurBoostsView.BoostID);
UPDATE Boosts SET NumItems = 		(SELECT NItems 	FROM REurBoostsView WHERE Boosts.BoostID = REurBoostsView.BoostID);
UPDATE Boosts SET RequiresResource =(SELECT RRes 	FROM REurBoostsView WHERE Boosts.BoostID = REurBoostsView.BoostID);
UPDATE Boosts SET Unit1Type = 		(SELECT CASE WHEN U1Type IS NULL THEN NULL ELSE 'UNIT_'||U1Type END 	FROM REurBoostsView WHERE Boosts.BoostID = REurBoostsView.BoostID);
UPDATE Boosts SET BuildingType = 	(SELECT CASE WHEN BType  IS NULL THEN NULL ELSE 'BUILDING_'||BType END 	FROM REurBoostsView WHERE Boosts.BoostID = REurBoostsView.BoostID);
UPDATE Boosts SET ImprovementType = (SELECT CASE WHEN IType  IS NULL THEN NULL ELSE 'IMPROVEMENT_'||IType END FROM REurBoostsView WHERE Boosts.BoostID = REurBoostsView.BoostID);
UPDATE Boosts SET BoostingTechType =(SELECT CASE WHEN BTType IS NULL THEN NULL ELSE 'TECH_'||BTType END 	FROM REurBoostsView WHERE Boosts.BoostID = REurBoostsView.BoostID);
UPDATE Boosts SET ResourceType = 	(SELECT CASE WHEN RType  IS NULL THEN NULL ELSE 'RESOURCE_'||RType END 	FROM REurBoostsView WHERE Boosts.BoostID = REurBoostsView.BoostID);
UPDATE Boosts SET DistrictType = 	(SELECT CASE WHEN DType  IS NULL THEN NULL ELSE 'DISTRICT_'||DType END 	FROM REurBoostsView WHERE Boosts.BoostID = REurBoostsView.BoostID);
UPDATE Boosts SET BoostingCivicType=(SELECT CASE WHEN BCType IS NULL THEN NULL ELSE 'CIVIC_'||BCType END 	FROM REurBoostsView WHERE Boosts.BoostID = REurBoostsView.BoostID);

--------------------------------------------------------------
-- CLEAN-UP
--------------------------------------------------------------

DROP VIEW REurBoostsView;
DROP TABLE REurFinalMapping;
DROP TABLE REurMapping;
DROP TABLE REurBoostDefs;
