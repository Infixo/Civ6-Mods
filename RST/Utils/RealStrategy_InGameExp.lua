print("Loading RealStrategy_InGameExp.lua from Real Strategy version "..GlobalParameters.RST_VERSION_MAJOR.."."..GlobalParameters.RST_VERSION_MINOR);
-- ===========================================================================
-- Real Strategy
-- Author: Infixo
-- 2018-12-14: Created
-- Expose UI context function to use them in other scripts
-- ===========================================================================


if not ExposedMembers.RST then ExposedMembers.RST = {} end;


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

-- find out military strength
function GetPlayerNumTechsResearched(ePlayerID:number)
	if Players[ePlayerID] then
		return Players[ePlayerID]:GetStats():GetNumTechsResearched();
	end
	return 0;
end
function GetPlayerMilitaryStrength(ePlayerID:number)
	if Players[ePlayerID] then
		return Players[ePlayerID]:GetStats():GetMilitaryStrength();
	end
	return 0;
end
function GetPlayerMilitaryStrengthWithoutTreasury(ePlayerID:number)
	if Players[ePlayerID] then
		return Players[ePlayerID]:GetStats():GetMilitaryStrengthWithoutTreasury();
	end
	return 0;
end

-- wrapper
function GameIsVictoryEnabled( sVictoryType:string )
	return Game.IsVictoryEnabled( sVictoryType );
end

-- wrapper
function GameGetMaxGameTurns()
	return Game.GetMaxGameTurns();
end

-- wrapper
function PlayerGetCurrentGovernment(ePlayerID:number)
	local pPlayer:table = Players[ePlayerID];
	return pPlayer:GetCulture():GetCurrentGovernment();
end

--  get a list of slotted (active) policies
function PlayerGetSlottedPolicies(ePlayerID:number)
	print("FUN GetSlottedPolicies", ePlayerID);
	local pPlayer:table = Players[ePlayerID];
	local pPlayerCulture:table = pPlayer:GetCulture();
	local tPolicies:table = {};
	for i = 0, pPlayerCulture:GetNumPolicySlots()-1 do
		local ePolicyID:number = pPlayerCulture:GetSlotPolicy(i);
		--print("...slot", i, "has policy", ePolicyID);
		if ePolicyID > -1 then
			table.insert(tPolicies, GameInfo.Policies[ePolicyID].PolicyType);
			print("...slotted", GameInfo.Policies[ePolicyID].PolicyType);
		end
	end
	return tPolicies;
end


function Initialize()
	-- functions
	ExposedMembers.RST.GetWMDWeaponCount           = GetWMDWeaponCount;
	ExposedMembers.RST.GetGreatWorkCount           = GetGreatWorkCount;
	ExposedMembers.RST.GetGreatWorkObjectType      = GetGreatWorkObjectType;
	ExposedMembers.RST.GetPlayerNumTechsResearched = GetPlayerNumTechsResearched;
	ExposedMembers.RST.GetPlayerMilitaryStrength   = GetPlayerMilitaryStrength;
	ExposedMembers.RST.GetPlayerMilitaryStrengthWithoutTreasury = GetPlayerMilitaryStrengthWithoutTreasury;
	ExposedMembers.RST.GameIsVictoryEnabled        = GameIsVictoryEnabled;
	ExposedMembers.RST.GameGetMaxGameTurns         = GameGetMaxGameTurns;
	ExposedMembers.RST.PlayerGetSlottedPolicies    = PlayerGetSlottedPolicies;
	ExposedMembers.RST.PlayerGetCurrentGovernment  = PlayerGetCurrentGovernment;
	
	-- objects
	--ExposedMembers.RND.Calendar				= Calendar;
end
Initialize();

print("OK loaded RealStrategy_InGameExp.lua from Real Strategy");