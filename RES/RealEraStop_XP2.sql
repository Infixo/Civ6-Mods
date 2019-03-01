-- ===========================================================================
-- Real Era Stop - Gathering Storm changes
-- Author: Infixo
-- 2019-02-21: Created
-- ===========================================================================

-- Table Resolutions
-- EarliestEra / LatestEra - not referenced - but Eras are not removed, so it should work ok

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
