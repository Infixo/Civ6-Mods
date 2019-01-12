print("Loading RealStrategy_GreatPeople.lua from Real Strategy version "..GlobalParameters.RST_VERSION_MAJOR.."."..GlobalParameters.RST_VERSION_MINOR);
-- ===========================================================================
-- Real Strategy - support for Great People and Great Works
-- Author: Infixo
-- 2019-01-12: Created
-- ===========================================================================


-- InGame functions exposed here
if not ExposedMembers.RST then ExposedMembers.RST = {} end;
local RST = ExposedMembers.RST;


------------------------------------------------------------------------------
-- STRATEGY MORE GREAT WORKS SLOTS
-- This strategy activates when we are lacking slots for Great Works. This happens quite often, especially with heavy-oriented GP civs (Kongo, Peter).
-- GW support in Lua is quite messy - have to go to the city level, etc. so this check will NOT be performed each turn.
-- The function counts unused GWAMs and their respective GWs, then counts available slots for those GWs.
-- Important! Buildings and Districts that contain GWs are also counted when they are being built
-- It returns TRUE if we are lacking at least 2 slots

-- helper - counts all types in one pass
-- there's no function that simply returns number of great works... thx Firaxis!
function GetNumEmptyGreatWorkSlots(ePlayerID:number)
	print("FUN GetNumEmptyGreatWorkSlots", ePlayerID);
	local iNumSlotWriting:number, iNumSlotArt:number, iNumSlotMusic:number = 0, 0, 0;

	local function AddSlotType(sGWSlotType:string)
		print("   ...adding slot type", sGWSlotType);
		-- TODO: make it not hardcoded
		if     sGWSlotType == "GREATWORKSLOT_ART"       then iNumSlotArt = iNumSlotArt + 1;
		elseif sGWSlotType == "GREATWORKSLOT_CATHEDRAL" then iNumSlotArt = iNumSlotArt + 1; -- holds Religious
		elseif sGWSlotType == "GREATWORKSLOT_MUSIC"     then iNumSlotMusic = iNumSlotMusic + 1;
		elseif sGWSlotType == "GREATWORKSLOT_PALACE"    then iNumSlotWriting = iNumSlotWriting + 1; iNumSlotArt = iNumSlotArt + 1; iNumSlotMusic = iNumSlotMusic + 1;
		elseif sGWSlotType == "GREATWORKSLOT_WRITING"   then iNumSlotWriting = iNumSlotWriting + 1;
		else -- ignore GREATWORKSLOT_RELIC & GREATWORKSLOT_ARTIFACT
		end
	end
	
	local function AddSlotTypesFromBuilding(sBuildingType:string)
		print("   ...adding building", sBuildingType);
		for row in GameInfo.Building_GreatWorks() do
			if row.BuildingType == sBuildingType then
				for i = 1, row.NumSlots do AddSlotType(row.GreatWorkSlotType); end
			end
		end
	end

	for _,city in Players[ePlayerID]:GetCities():Members() do
		
		-- check existing buildings
		local cityBuildings:table = city:GetBuildings();
		for building in GameInfo.Buildings() do
			local eBuilding:number = building.Index;
			if cityBuildings:HasBuilding(eBuilding) then
				print("   ...checking building", building.BuildingType);
				for i = 0, cityBuildings:GetNumGreatWorkSlots(building.Index)-1 do
					print("      ...checking slot", i);
					-- get great work
					local eGWIndex:number = cityBuildings:GetGreatWorkInSlot(eBuilding, i);
					local eGWSlotType:number = cityBuildings:GetGreatWorkSlotType(eBuilding, i);
					print("      ...slot", i, "type", eGWSlotType, "gw_index", eGWIndex);
					if eGWIndex == -1 then -- empty slot
						AddSlotType( GameInfo.GreatWorkSlotTypes[eGWSlotType] );
					end
				end
			end
		end -- all buildings
		
		-- check production queue - districts and buildings
		local currentProductionHash:number = city:GetBuildQueue():GetCurrentProductionTypeHash();
		local pBuildingDef:table;
		local pDistrictDef:table;
		-- Attempt to obtain a hash for each item
		if currentProductionHash ~= 0 then
			pBuildingDef = GameInfo.Buildings[currentProductionHash];
			pDistrictDef = GameInfo.Districts[currentProductionHash];
		end
		if pBuildingDef ~= nil then
			-- ok, we're building a building
			AddSlotTypesFromBuilding(pBuildingDef.BuildingType);
		elseif pDistrictDef ~= nil then
			-- ok, we're building a district
			-- TODO: hardcoded as of now
			if pDistrictDef.DistrictType == "DISTRICT_THEATER" or pDistrictDef.DistrictType = "DISTRICT_ACROPOLIS" then
				AddSlotTypesFromBuilding("BUILDING_AMPHITHEATER");
				AddSlotTypesFromBuilding("BUILDING_MUSEUM_ART");
				AddSlotTypesFromBuilding("BUILDING_BROADCAST_CENTER");
			end
		end

	end -- cities
	
	print("Total empty slots found", iNumSlotWriting, iNumSlotArt, iNumSlotMusic);
	return iNumSlotWriting, iNumSlotArt, iNumSlotMusic;
end


function ActiveStrategyMoreGreatWorkSlots(ePlayerID:number, iThreshold:number)
	print(Game.GetCurrentGameTurn(), "FUN ActiveStrategyMoreGreatWorkSlots", ePlayerID, iThreshold);
	--local pPlayer:table = Players[ePlayerID];
	--if not (pPlayer:IsAlive() and pPlayer:IsMajor()) then return false; end -- have faith in the engine
	local data:table = RST.tData[ePlayerID];
	--if data.Data.ElapsedTurns < GlobalParameters.RST_STRATEGY_COMPARE_OTHERS_NUM_TURNS then return false; end -- don't compare yet

	-- Iterate through units and look for GWs to be created
	local iNumGWWriting:number, iNumGWArt:number, iNumGWMusic:number = 0, 0, 0; -- note that we don't bother with Artifacts - game assures that number of slots matches number of Archaelogists
	for _,unit in Players[ePlayerID]:GetUnits():Members() do
		local pUnitGP:table = unit:GetGreatPerson();
		if pUnitGP ~= nil and pUnitGP:IsGreatPerson() then
			local sGPClass:string = GameInfo.GreatPersonClasses[ pUnitGP:GetClass() ].GreatPersonClassType;
			print("...found GP of class", sGPClass);
			if     sGPClass == "GREAT_PERSON_CLASS_WRITER"   then iNumGWWriting = iNumGWWriting + pUnitGP:GetActionCharges();
			elseif sGPClass == "GREAT_PERSON_CLASS_ARTIST"   then iNumGWArt     = iNumGWArt     + pUnitGP:GetActionCharges();
			elseif sGPClass == "GREAT_PERSON_CLASS_MUSICIAN" then iNumGWMusic   = iNumGWMusic   + pUnitGP:GetActionCharges();
			end
			print("...num of works to be created", iNumGWWriting, iNumGWArt, iNumGWMusic);
		end
	end
	local iTotWorks = iNumGWWriting + iNumGWArt + iNumGWMusic;

	-- Check on each GW class separately - this is safe approach to avoid blocking, i.e. when we have slots for Art but not for Writing
	local iNumSlotWriting:number, iNumSlotArt:number, iNumSlotMusic:number = GetNumEmptyGreatWorkSlots(ePlayerID);
	print("...num of available slots", iNumSlotWriting, iNumSlotArt, iNumSlotMusic);
	local iTotSlots = iNumSlotWriting + iNumSlotArt + iNumSlotMusic;
	
	data.ActiveMoreGWSlots = false;
	data.ActiveMoreGWSlots = ( data.ActiveMoreGWSlots or (iNumGWWriting > iNumSlotWriting + 1) ); -- enabler, need it quickly; will acivate if 2 works
	data.ActiveMoreGWSlots = ( data.ActiveMoreGWSlots or (iNumGWArt > iNumSlotArt + 2) ); -- they come in 3, so missing only 1 is not enough; will activate if 3 works
	data.ActiveMoreGWSlots = ( data.ActiveMoreGWSlots or (iNumGWMusic > iNumSlotMusic + 2) ); -- music comes late, maybe it is not worth it to build a district just for 1 GW of Music; will activate if 3 works

	if bLogOther then print(Game.GetCurrentGameTurn(),"RSTGWSLT", ePlayerID, iThreshold, "...works/slots", iTotWorks, iTotSlots, "active?", data.ActiveMoreGWSlots); end
	return data.ActiveMoreGWSlots;
end
GameEvents.ActiveStrategyMoreGreatWorkSlots.Add(ActiveStrategyMoreGreatWorkSlots);




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
	print("FUN Initialize");
end
Initialize();

print("OK loaded RealStrategy_GreatPeople.lua from Real Strategy");