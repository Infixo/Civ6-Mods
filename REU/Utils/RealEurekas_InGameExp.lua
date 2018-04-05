print("Loading RealEurekas_InGameExp.lua from Real Eurekas version "..GlobalParameters.REU_VERSION_MAJOR.."."..GlobalParameters.REU_VERSION_MINOR);
-- ===========================================================================
-- Real Eurekas
-- Author: Infixo
-- 2018-04-05: Created
-- Expose UI context function to use them in other scripts
-- ===========================================================================


if not ExposedMembers.REU then ExposedMembers.REU = {} end;


function GetWMDWeaponCount(ePlayerID:number, sWeaponType:string)
	--print("FUN GetWMDWeaponCount", ePlayerID, sWeaponType);
	if Players[ePlayerID] == nil or GameInfo.WMDs[sWeaponType] == nil then return 0; end
	return Players[ePlayerID]:GetWMDs():GetWeaponCount( GameInfo.WMDs[sWeaponType].Index );
end


function GetGreatWorkCount(ePlayerID:number, sGreatWorkObjectType:string)
	--print("FUN GetGreatWorkCount", ePlayerID, sGreatWorkObjectType);
	if Players[ePlayerID] == nil or GameInfo.GreatWorkObjectTypes[sGreatWorkObjectType] == nil then return 0; end
	-- there's no function that simply returns number of great works... thx Firaxis!
	local iNumGWs:number = 0;
	for _,city in Players[ePlayerID]:GetCities():Members() do
		local cityBuildings:table = city:GetBuildings();
		for building in GameInfo.Buildings() do
			if cityBuildings:HasBuilding(building.Index) then
				--print("   ...checking building", building.BuildingType);
				for i = 0, cityBuildings:GetNumGreatWorkSlots(building.Index)-1 do
					--print("      ...checking slot", i);
					-- get great work
					local iGreatWorkIndex:number = cityBuildings:GetGreatWorkInSlot(building.Index, i);
					--print("      ...gw_index in slot", i, "is", iGreatWorkIndex);
					if iGreatWorkIndex ~= -1 then
						local greatWorkInfo:table = GameInfo.GreatWorks[ cityBuildings:GetGreatWorkTypeFromIndex(iGreatWorkIndex) ];
						if greatWorkInfo ~= nil then
							--print("         ...found object", greatWorkInfo.GreatWorkType, greatWorkInfo.GreatWorkObjectType);
							if greatWorkInfo.GreatWorkObjectType == sGreatWorkObjectType then iNumGWs = iNumGWs + 1; end
						end
					end
				end
			end
		end
	end
	--print("Total objects found", sGreatWorkObjectType, iNumGWs);
	return iNumGWs;
end


-- find out what kind of an object is the specific GW
function GetGreatWorkObjectType(iCityX:number, iCityY:number, iGreatWorkIndex:number)
	--print("FUN GetGreatWorkObjectType", iCityX, iCityY, iGreatWorkIndex);
	-- get city
	local pCity:table = Cities.GetCityInPlot(iCityX, iCityY);
	if pCity == nil then return nil; end
	-- get great work
	local greatWorkInfo:table = GameInfo.GreatWorks[ pCity:GetBuildings():GetGreatWorkTypeFromIndex(iGreatWorkIndex) ];
	if greatWorkInfo == nil then return nil; end
	--print("...found object", greatWorkInfo.GreatWorkType, greatWorkInfo.GreatWorkObjectType);
	return greatWorkInfo.GreatWorkObjectType;
end


function Initialize()
	-- functions
	ExposedMembers.REU.GetWMDWeaponCount		= GetWMDWeaponCount;
	ExposedMembers.REU.GetGreatWorkCount		= GetGreatWorkCount;
	ExposedMembers.REU.GetGreatWorkObjectType	= GetGreatWorkObjectType;
	-- objects
	--ExposedMembers.RND.Calendar				= Calendar;
end
Initialize();

print("OK loaded RealEurekas_InGameExp.lua from Real Eurekas");