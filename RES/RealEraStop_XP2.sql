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
