print("Loading RBU_Main.lua from Real Building Upgrades version "..GlobalParameters.RBU_VERSION_MAJOR.."."..GlobalParameters.RBU_VERSION_MINOR);
--------------------------------------------------------------
-- Real Building Upgrades
-- Author: Infixo
-- 2018-03-30: Created
--------------------------------------------------------------

-- remove PALACE_UPGRADE if exists
function OnCityConquered(capturerID:number,  ownerID:number, cityID:number, cityX:number, cityY:number) -- cityID is already owned by capturerID
	--print("OnCityConquered",capturerID,ownerID,cityID,cityX,cityY);
	local pCity:table = Cities.GetCityInPlot(cityX, cityY);
	if not pCity then print("ERROR: OnCityConquered City not found", cityX, cityY); return; end
	pCity:GetBuildings():RemoveBuilding(GameInfo.Buildings.BUILDING_PALACE_UPGRADE.Index);
	--print("City has PU", pCity:GetBuildings():HasBuilding(GameInfo.Buildings.BUILDING_PALACE_UPGRADE.Index));
end
GameEvents.CityConquered.Add(OnCityConquered);

print("OK loaded RBU_Main.lua from Real Building Upgrades");