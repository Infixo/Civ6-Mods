-- ===========================================================================
-- Real Era Stop - Gathering Storm changes
-- Author: Infixo
-- 2019-02-21: Created
-- 2019-03-08: Version 2.7 Flood Barrier fix
-- 2019-08-07: Version 2.8 Patronage Resolution fix
-- ===========================================================================

-- Table Resolutions
-- EarliestEra / LatestEra - not referenced - but Eras are not removed, so it should work ok

--------------------------------------------------------------
-- 2019-08-07 Version 2.8
-- Workaround for an issue with Patronage Resolution selected when all GPs have been recruited

UPDATE Resolutions SET LatestEra = 'ERA_CLASSICAL'   WHERE ResolutionType = 'WC_RES_PATRONAGE' AND EXISTS (SELECT * FROM GlobalParameters WHERE Name = 'RES_MAX_ERA' AND Value = '3');
UPDATE Resolutions SET LatestEra = 'ERA_MEDIEVAL'    WHERE ResolutionType = 'WC_RES_PATRONAGE' AND EXISTS (SELECT * FROM GlobalParameters WHERE Name = 'RES_MAX_ERA' AND Value = '4');
UPDATE Resolutions SET LatestEra = 'ERA_RENAISSANCE' WHERE ResolutionType = 'WC_RES_PATRONAGE' AND EXISTS (SELECT * FROM GlobalParameters WHERE Name = 'RES_MAX_ERA' AND Value = '5');
UPDATE Resolutions SET LatestEra = 'ERA_INDUSTRIAL'  WHERE ResolutionType = 'WC_RES_PATRONAGE' AND EXISTS (SELECT * FROM GlobalParameters WHERE Name = 'RES_MAX_ERA' AND Value = '6');


--------------------------------------------------------------
-- 2019-02-21 Railroad (GS)
-- Route_ValidBuildUnits - auto-delete
-- Routes_XP2 -- auto-delete
--------------------------------------------------------------

DELETE FROM Route_ResourceCosts WHERE RouteType = 'ROUTE_RAILROAD' AND EXISTS (
	SELECT *
	FROM Routes_XP2, RESTechnologies
	WHERE Routes_XP2.RouteType = 'ROUTE_RAILROAD' AND Routes_XP2.PrereqTech = RESTechnologies.TechnologyType);

DELETE FROM Routes WHERE RouteType = 'ROUTE_RAILROAD' AND EXISTS (
	SELECT *
	FROM Routes_XP2, RESTechnologies
	WHERE Routes_XP2.RouteType = 'ROUTE_RAILROAD' AND Routes_XP2.PrereqTech = RESTechnologies.TechnologyType);


--------------------------------------------------------------
-- 2019-02-25 Version 2.6

DELETE FROM RandomAgendas WHERE AgendaType IN (
	SELECT AgendaType FROM RandomAgendas_XP2 WHERE AgendaTag = 'AGENDA_LATE_ERA_ONLY' AND
		EXISTS (SELECT * FROM RandomAgendaCivicTags WHERE AgendaTag = 'AGENDA_LATE_ERA_ONLY' AND CivicType IN (SELECT CivicType FROM RESCivics)));
DELETE FROM AgendaTags WHERE AgendaTagType = 'AGENDA_LATE_ERA_ONLY' AND
	EXISTS (SELECT * FROM RandomAgendaCivicTags WHERE AgendaTag = 'AGENDA_LATE_ERA_ONLY' AND CivicType IN (SELECT CivicType FROM RESCivics));
	
--------------------------------------------------------------
-- 2019-02-25 Version 2.6 Sweden Fix
-- Game crashes with Kristina and last era before Modern.

--DELETE FROM EmergencyAlliances WHERE TargetRequirementSet = 'NOBEL_PRIZE_TARGET_REQUIREMENTS' AND EXISTS (SELECT * FROM GlobalParameters WHERE Name = 'RES_MAX_ERA' AND Value < '6');


--------------------------------------------------------------
-- 2019-03-08 Version 2.7
-- For Industrial and Modern - move Flood Barrier earlier. Industrial - Sanitation. Modern - Electricity. Also adjust cost.

UPDATE Buildings
SET PrereqTech = 'TECH_SANITATION', Cost = 0.70 * Cost
WHERE BuildingType = 'BUILDING_FLOOD_BARRIER' AND EXISTS (SELECT * FROM GlobalParameters WHERE Name = 'RES_MAX_ERA' AND Value = '5');

UPDATE Buildings
SET PrereqTech = 'TECH_ELECTRICITY', Cost = 0.85 * Cost
WHERE BuildingType = 'BUILDING_FLOOD_BARRIER' AND EXISTS (SELECT * FROM GlobalParameters WHERE Name = 'RES_MAX_ERA' AND Value = '6');
