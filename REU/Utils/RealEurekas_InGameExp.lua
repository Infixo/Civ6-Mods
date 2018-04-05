print("Loading RealEurekas_InGameExp.lua from Real Eurekas version "..GlobalParameters.REU_VERSION_MAJOR.."."..GlobalParameters.REU_VERSION_MINOR);
-- ===========================================================================
-- Real Eurekas
-- Author: Infixo
-- 2018-04-05: Created
-- Expose UI context function to use them in other scripts
-- ===========================================================================


if not ExposedMembers.REU then ExposedMembers.REU = {} end;


function GetWMDWeaponCount(ePlayerID:number, sWeaponType:string)
	print("FUN GetWMDWeaponCount", ePlayerID, sWeaponType);
	if Players[ePlayerID] == nil or GameInfo.WMDs[sWeaponType] == nil then return 0; end
	return Players[ePlayerID]:GetWMDs():GetWeaponCount( GameInfo.WMDs[sWeaponType].Index );
end


function GetGreatWorkCount(ePlayerID:number, sGreatWorkObjectType:string)
	print("FUN GetGreatWorkCount", ePlayerID, sGreatWorkObjectType);
	if Players[ePlayerID] == nil or GameInfo.GreatWorkObjectTypes[sGreatWorkObjectType] == nil then return 0; end
	local iNumGWs:number = 0;
	return iNumGWs;
end


-- find out what kind of an object is the specific GW
function GetGreatWorkObjectType(iCityX:number, iCityY:number, iGreatWorkIndex:number)
	print("FUN GetGreatWorkObjectType", iCityX, iCityY, iGreatWorkIndex);
	-- get city
	local pCity:table = Cities.GetCityInPlot(Map.GetPlot(iCityX, iCityY));
	if pCity == nil then return nil; end
	-- get great work
	local greatWorkInfo:number = GameInfo.GreatWorks[ pCity:GetBuildings():GetGreatWorkTypeFromIndex(iGreatWorkIndex) ];
	if greatWorkInfo == nil then return nil; end
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