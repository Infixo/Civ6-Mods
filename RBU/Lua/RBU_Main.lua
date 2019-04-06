print("Loading RBU_Main.lua from Real Building Upgrades version "..GlobalParameters.RBU_VERSION_MAJOR.."."..GlobalParameters.RBU_VERSION_MINOR);
--------------------------------------------------------------
-- Real Building Upgrades
-- Author: Infixo
-- 2018-03-30: Created
-- 2019-04-06: Conversion projects for Power Plants
--------------------------------------------------------------


-- helper
function GetTableIndex(sTable:string, sType:string)
	return GameInfo[sTable][sType] and GameInfo[sTable][sType].Index or -1;
end


-- remove PALACE_UPGRADE if exists

local BUILDING_PALACE_UPGRADE:number = GetTableIndex("Buildings", "BUILDING_PALACE_UPGRADE");

function OnCityConquered(capturerID:number,  ownerID:number, cityID:number, cityX:number, cityY:number) -- cityID is already owned by capturerID
	--print("FUN OnCityConquered",capturerID,ownerID,cityID,cityX,cityY);
	local pCity:table = Cities.GetCityInPlot(cityX, cityY);
	if not pCity then print("ERROR: OnCityConquered City not found", cityX, cityY); return; end
	pCity:GetBuildings():RemoveBuilding(BUILDING_PALACE_UPGRADE);
	pCity:GetBuildQueue():RemoveBuilding(BUILDING_PALACE_UPGRADE);
	--print("City has PU", pCity:GetBuildings():HasBuilding(GameInfo.Buildings.BUILDING_PALACE_UPGRADE.Index));
end
GameEvents.CityConquered.Add(OnCityConquered);


-- 2019-04-06: Conversion projects for Power Plants
-- CityProjectCompleted = { "player", "iCityID", "Project", "Building", "iX", "iY", "bCanceled" },

-- projects
local PROJECT_CONVERT_REACTOR_TO_COAL:number          = GetTableIndex("Projects", "PROJECT_CONVERT_REACTOR_TO_COAL");
local PROJECT_CONVERT_REACTOR_TO_OIL:number           = GetTableIndex("Projects", "PROJECT_CONVERT_REACTOR_TO_OIL");
local PROJECT_CONVERT_REACTOR_TO_URANIUM:number       = GetTableIndex("Projects", "PROJECT_CONVERT_REACTOR_TO_URANIUM");
--local PROJECT_DECOMMISSION_COAL_POWER_PLANT:number    = GetTableIndex("Projects", "PROJECT_DECOMMISSION_COAL_POWER_PLANT");
--local PROJECT_DECOMMISSION_OIL_POWER_PLANT:number     = GetTableIndex("Projects", "PROJECT_DECOMMISSION_OIL_POWER_PLANT");
--local PROJECT_DECOMMISSION_NUCLEAR_POWER_PLANT:number = GetTableIndex("Projects", "PROJECT_DECOMMISSION_NUCLEAR_POWER_PLANT");

-- power plants
local BUILDING_COAL_POWER_PLANT_UPGRADE:number        = GetTableIndex("Buildings", "BUILDING_COAL_POWER_PLANT_UPGRADE");
local BUILDING_FOSSIL_FUEL_POWER_PLANT_UPGRADE:number = GetTableIndex("Buildings", "BUILDING_FOSSIL_FUEL_POWER_PLANT_UPGRADE");
local BUILDING_POWER_PLANT_UPGRADE:number             = GetTableIndex("Buildings", "BUILDING_POWER_PLANT_UPGRADE");

function OnCityProjectCompleted(playerID:number, cityID:number, projectID:number)
	--print("FUN OnCityProjectCompleted", playerID, cityID, projectID);
	local pCity:table = Players[playerID]:GetCities():FindID(cityID);
	if pCity == nil then print("ERROR: OnCityProjectCompleted city not found", playerID, cityID); return; end
	local pCityBuildings:table = pCity:GetBuildings();
	--print("... power plants upgrades BEFORE", pCityBuildings:HasBuilding(BUILDING_COAL_POWER_PLANT_UPGRADE), pCityBuildings:HasBuilding(BUILDING_FOSSIL_FUEL_POWER_PLANT_UPGRADE), pCityBuildings:HasBuilding(BUILDING_POWER_PLANT_UPGRADE));
	if projectID == PROJECT_CONVERT_REACTOR_TO_COAL then
		if pCityBuildings:HasBuilding(BUILDING_FOSSIL_FUEL_POWER_PLANT_UPGRADE) or pCityBuildings:HasBuilding(BUILDING_POWER_PLANT_UPGRADE) then
			pCity:GetBuildQueue():CreateBuilding(BUILDING_COAL_POWER_PLANT_UPGRADE);
			pCityBuildings:RemoveBuilding(BUILDING_FOSSIL_FUEL_POWER_PLANT_UPGRADE);
			pCityBuildings:RemoveBuilding(BUILDING_POWER_PLANT_UPGRADE);
		end
	elseif projectID == PROJECT_CONVERT_REACTOR_TO_OIL then
		if pCityBuildings:HasBuilding(BUILDING_COAL_POWER_PLANT_UPGRADE) or pCityBuildings:HasBuilding(BUILDING_POWER_PLANT_UPGRADE) then
			pCityBuildings:RemoveBuilding(BUILDING_COAL_POWER_PLANT_UPGRADE);
			pCity:GetBuildQueue():CreateBuilding(BUILDING_FOSSIL_FUEL_POWER_PLANT_UPGRADE);
			pCityBuildings:RemoveBuilding(BUILDING_POWER_PLANT_UPGRADE);
		end
	elseif projectID == PROJECT_CONVERT_REACTOR_TO_URANIUM then
		if pCityBuildings:HasBuilding(BUILDING_COAL_POWER_PLANT_UPGRADE) or pCityBuildings:HasBuilding(BUILDING_FOSSIL_FUEL_POWER_PLANT_UPGRADE) then
			pCityBuildings:RemoveBuilding(BUILDING_COAL_POWER_PLANT_UPGRADE);
			pCityBuildings:RemoveBuilding(BUILDING_FOSSIL_FUEL_POWER_PLANT_UPGRADE);
			pCity:GetBuildQueue():CreateBuilding(BUILDING_POWER_PLANT_UPGRADE);
		end
	end
	--print("... power plants upgrades AFTER", pCityBuildings:HasBuilding(BUILDING_COAL_POWER_PLANT_UPGRADE), pCityBuildings:HasBuilding(BUILDING_FOSSIL_FUEL_POWER_PLANT_UPGRADE), pCityBuildings:HasBuilding(BUILDING_POWER_PLANT_UPGRADE));
end
Events.CityProjectCompleted.Add(OnCityProjectCompleted);

print("OK loaded RBU_Main.lua from Real Building Upgrades");