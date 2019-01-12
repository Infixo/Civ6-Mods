print("Loading RealStrategy_GreatPeople.lua from Real Strategy version "..GlobalParameters.RST_VERSION_MAJOR.."."..GlobalParameters.RST_VERSION_MINOR);
-- ===========================================================================
-- Real Strategy - support for Great People
-- Author: Infixo
-- 2019-01-12: Created
-- ===========================================================================


-- InGame functions exposed here
if not ExposedMembers.RST then ExposedMembers.RST = {} end;
local RST = ExposedMembers.RST;




function PlayerGetWMDWeaponCount(ePlayerID:number, sWeaponType:string)
	--print("FUN GetWMDWeaponCount", ePlayerID, sWeaponType);
	if Players[ePlayerID] == nil or GameInfo.WMDs[sWeaponType] == nil then return 0; end
	return Players[ePlayerID]:GetWMDs():GetWeaponCount( GameInfo.WMDs[sWeaponType].Index );
end

function PlayerGetNumWMDs(ePlayerID:number)
	local iNum:number = 0;
	for wmd in GameInfo.WMDs() do
		iNum = iNum + Players[ePlayerID]:GetWMDs():GetWeaponCount( wmd.Index )
	end
	return iNum;
end

function PlayerGetGreatWorkCount(ePlayerID:number, sGreatWorkObjectType:string)
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
function CityGetGreatWorkObjectType(iCityX:number, iCityY:number, iGreatWorkIndex:number)
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

-- wrapper - get number of researched techs
function PlayerGetNumTechsResearched(ePlayerID:number)
	return Players[ePlayerID]:GetStats():GetNumTechsResearched();
end

-- wrapper - find out military strength
function PlayerGetMilitaryStrength(ePlayerID:number)
	return Players[ePlayerID]:GetStats():GetMilitaryStrengthWithoutTreasury(); -- WorldRankings window uses this function, GetMilitaryStrength() is used in ARXManager and some scenarios
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
	return Players[ePlayerID]:GetCulture():GetCurrentGovernment();
end

--  get a list of slotted (active) policies
function PlayerGetSlottedPolicies(ePlayerID:number)
	--print("FUN GetSlottedPolicies", ePlayerID);
	local pPlayer:table = Players[ePlayerID];
	local pPlayerCulture:table = pPlayer:GetCulture();
	local tPolicies:table = {};
	for i = 0, pPlayerCulture:GetNumPolicySlots()-1 do
		local ePolicyID:number = pPlayerCulture:GetSlotPolicy(i);
		--print("...slot", i, "has policy", ePolicyID);
		if ePolicyID > -1 then
			table.insert(tPolicies, GameInfo.Policies[ePolicyID].PolicyType);
			--print("...slotted", GameInfo.Policies[ePolicyID].PolicyType);
		end
	end
	return tPolicies;
end

-- get a list of recruited Great People
-- returns a simple table with GreatPersonClassType
function PlayerGetRecruitedGreatPeopleClasses(ePlayerID:number)
	--print("FUN PlayerGetRecruitedGreatPeopleClasses", ePlayerID);
	local tGPs:table = {};
	for _,person in ipairs(Game.GetGreatPeople():GetPastTimeline()) do
		-- person.Claimant - player ID, person.Class - GP class ID
		if person.Claimant == ePlayerID then
			local sGPClass:string = GameInfo.GreatPersonClasses[person.Class].GreatPersonClassType;
			--print("...recruited", sGPClass);
			table.insert(tGPs, sGPClass);
		end
	end
	return tGPs;
end

-- get number of captured capitals
function PlayerGetNumCapturedCapitals(ePlayerID:number)
	--print("FUN PlayerGetNumCapturedCapitals", ePlayerID);
	local iNum:number = 0;
	for _,city in Players[ePlayerID]:GetCities():Members() do
		if city:IsOriginalCapital() then
			if city:GetOriginalOwner() ~= ePlayerID and Players[city:GetOriginalOwner()]:IsMajor() then iNum = iNum + 1; end
		end
	end
	return iNum;
end

-- check if player is still an owner of his original capital
function PlayerHasOriginalCapital(ePlayerID:number)
	print("FUN PlayerHasOriginalCapital", ePlayerID);
	local pCapital:table = Players[ePlayerID]:GetCities():GetCapitalCity();
	if pCapital == nil then return true; end -- no capital yet
	return pCapital:IsOriginalCapital();
end

-- Returns the Average num of Techs researched for all known Players in the game
function GameGetAverageNumTechsResearched(ePlayerID:number) --, bIncludeMe:boolean, bIncludeOnlyKnown:boolean)
	--print("FUN GameGetAverageNumTechsResearched", ePlayerID, bIncludeMe, bIncludeOnlyKnown);
	local iTotalTechs:number = 0;
	local iNumAlivePlayers:number = 0;
	-- Sum up the num of techs of all known majors
	for _,otherID in ipairs(PlayerManager.GetAliveMajorIDs()) do
		--if bIncludeMe or otherID ~= ePlayerID then
			--if not bIncludeOnlyKnown or Players[ePlayerID]:GetDiplomacy():HasMet(otherID) then
			if otherID == ePlayerID or Players[ePlayerID]:GetDiplomacy():HasMet(otherID) then -- HasMet returns false for ourselves, so must add ourselves separately
				iNumAlivePlayers = iNumAlivePlayers + 1;
				iTotalTechs = iTotalTechs + Players[otherID]:GetStats():GetNumTechsResearched();
			end
		--end
	end
	return iNumAlivePlayers == 0 and 0 or iTotalTechs/iNumAlivePlayers;
end

-- Returns the Average Military Might of all known Players in the game
function GameGetAverageMilitaryStrength(ePlayerID:number) --, bIncludeMe:boolean, bIncludeOnlyKnown:boolean)
	--print("FUN GameGetAverageMilitaryStrength", ePlayerID); --, bIncludeMe, bIncludeOnlyKnown);
	local iWorldMilitaryStrength:number = 0;
	local iNumAlivePlayers:number = 0;
	-- Sum up the military strength of all known majors
	for _,otherID in ipairs(PlayerManager.GetAliveMajorIDs()) do
		--if bIncludeMe or otherID ~= ePlayerID then
			--if not bIncludeOnlyKnown or Players[ePlayerID]:GetDiplomacy():HasMet(otherID) then
			if otherID == ePlayerID or Players[ePlayerID]:GetDiplomacy():HasMet(otherID) then -- HasMet returns false for ourselves, so must add ourselves separately
				iNumAlivePlayers = iNumAlivePlayers + 1;
				iWorldMilitaryStrength = iWorldMilitaryStrength + Players[otherID]:GetStats():GetMilitaryStrengthWithoutTreasury();
			end
		--end
	end
	return iNumAlivePlayers == 0 and 0 or iWorldMilitaryStrength/iNumAlivePlayers;
end


-- Culture Victory progress in % (0..100)
-- Determine number of tourist needed for victory
-- Has to be one more than every other players number of domestic tourists
function PlayerGetCultureVictoryProgress(ePlayerID:number)
	--print("FUN PlayerGetCultureVictoryProgress", ePlayerID);
	local iNumVisitingUs:number = Players[ePlayerID]:GetCulture():GetTouristsTo();
	local iNumRequiredTourists:number = 0;
	for _,playerID in ipairs(PlayerManager.GetAliveMajorIDs()) do
		if playerID ~= ePlayerID then
			local iStaycationers:number = Players[playerID]:GetCulture():GetStaycationers();
			if iStaycationers > iNumRequiredTourists then iNumRequiredTourists = iStaycationers; end
		end
	end
	iNumRequiredTourists = iNumRequiredTourists + 1;
	return 100 * iNumVisitingUs / iNumRequiredTourists;
end

-- wrapper
function PlayerGetNumProjectsAdvanced(ePlayerID:number, eProjectID:number)
	return Players[ePlayerID]:GetStats():GetNumProjectsAdvanced(eProjectID);
end

-- check if player has a spaceport
local eDistrictSpaceportIndex:number = GameInfo.Districts["DISTRICT_SPACEPORT"].Index;
function PlayerHasSpaceport(ePlayerID:number)
	--print("FUN PlayerHasSpaceport", ePlayerID);
	for _,district in Players[ePlayerID]:GetDistricts():Members() do
		if district ~= nil and district:GetType() == eDistrictSpaceportIndex and district:IsComplete() then
			return true;
		end
	end
	return false;
end

-- wrapper
function PlayerGetNumCitiesFollowingReligion(ePlayerID:number)
	return Players[ePlayerID]:GetStats():GetNumCitiesFollowingReligion();
end

-- wrapper
function PlayerGetTourism(ePlayerID:number)
	return Players[ePlayerID]:GetStats():GetTourism();
end

-- wrapper
function PlayerGetReligionTypeCreated(ePlayerID:number)
	return Players[ePlayerID]:GetReligion():GetReligionTypeCreated();
end

-- wrapper
function PlayerHasReligion(ePlayerID:number)
	local eReligionID:number = Players[ePlayerID]:GetReligion():GetReligionTypeCreated();
	return eReligionID ~= -1 and eReligionID ~= GameInfo.Religions.RELIGION_PANTHEON.Index;
end

-- wrapper
function PlayerGetNumBeliefsEarned(ePlayerID:number)
	return Players[ePlayerID]:GetReligion():GetNumBeliefsEarned();
end

-- get a table with Belief IDs
function PlayerGetBeliefs(ePlayerID:number)
	for _,religion in ipairs(Game.GetReligion():GetReligions()) do
		if religion.Founder == ePlayerID then return religion.Beliefs; end
	end
	return {};
end


function Initialize()
	-- functions: Game
	ExposedMembers.RST.GameIsVictoryEnabled         = GameIsVictoryEnabled;
	ExposedMembers.RST.GameGetMaxGameTurns          = GameGetMaxGameTurns;
	ExposedMembers.RST.GameGetAverageMilitaryStrength = GameGetAverageMilitaryStrength;
	ExposedMembers.RST.GameGetAverageNumTechsResearched = GameGetAverageNumTechsResearched;
	-- functions: City
	ExposedMembers.RST.CityGetGreatWorkObjectType   = CityGetGreatWorkObjectType;
	-- functions: Player
	ExposedMembers.RST.PlayerGetWMDWeaponCount      = PlayerGetWMDWeaponCount;
	ExposedMembers.RST.PlayerGetNumWMDs             = PlayerGetNumWMDs;
	ExposedMembers.RST.PlayerGetGreatWorkCount      = PlayerGetGreatWorkCount;
	ExposedMembers.RST.PlayerGetNumTechsResearched  = PlayerGetNumTechsResearched;
	ExposedMembers.RST.PlayerGetMilitaryStrength    = PlayerGetMilitaryStrength;
	ExposedMembers.RST.PlayerGetSlottedPolicies     = PlayerGetSlottedPolicies;
	ExposedMembers.RST.PlayerGetRecruitedGreatPeopleClasses = PlayerGetRecruitedGreatPeopleClasses;
	ExposedMembers.RST.PlayerGetCurrentGovernment   = PlayerGetCurrentGovernment;
	ExposedMembers.RST.PlayerGetNumCapturedCapitals = PlayerGetNumCapturedCapitals;
	ExposedMembers.RST.PlayerHasOriginalCapital     = PlayerHasOriginalCapital;
	ExposedMembers.RST.PlayerGetCultureVictoryProgress = PlayerGetCultureVictoryProgress;
	ExposedMembers.RST.PlayerGetNumProjectsAdvanced = PlayerGetNumProjectsAdvanced;
	ExposedMembers.RST.PlayerHasSpaceport           = PlayerHasSpaceport;
	ExposedMembers.RST.PlayerHasReligion            = PlayerHasReligion;
	ExposedMembers.RST.PlayerGetNumCitiesFollowingReligion = PlayerGetNumCitiesFollowingReligion;
	ExposedMembers.RST.PlayerGetTourism             = PlayerGetTourism;
	ExposedMembers.RST.PlayerGetReligionTypeCreated = PlayerGetReligionTypeCreated;
	ExposedMembers.RST.PlayerGetNumBeliefsEarned    = PlayerGetNumBeliefsEarned;
	ExposedMembers.RST.PlayerGetBeliefs             = PlayerGetBeliefs;
	
	-- objects
	--ExposedMembers.RND.Calendar				= Calendar;
end
Initialize();

print("OK loaded RealStrategy_GreatPeople.lua from Real Strategy");