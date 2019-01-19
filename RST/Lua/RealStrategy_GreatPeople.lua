print("Loading RealStrategy_GreatPeople.lua from Real Strategy version "..GlobalParameters.RST_VERSION_MAJOR.."."..GlobalParameters.RST_VERSION_MINOR);
-- ===========================================================================
-- Real Strategy - support for Great People and Great Works
-- Author: Infixo
-- 2019-01-12: Created
-- ===========================================================================


-- InGame functions exposed here
if not ExposedMembers.RST then ExposedMembers.RST = {} end;
local RST = ExposedMembers.RST;


-- configuration options
local bLogDebug:boolean = ( GlobalParameters.RST_OPTION_LOG_DEBUG == 1 );
local bLogOther:boolean = ( GlobalParameters.RST_OPTION_LOG_OTHER == 1 );


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
	--print("FUN GetNumEmptyGreatWorkSlots", ePlayerID);
	local iNumSlotWriting:number, iNumSlotArt:number, iNumSlotMusic:number = 0, 0, 0;

	local function AddSlotType(sGWSlotType:string)
		--print("   ...adding slot type", sGWSlotType);
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
		--print("   ...adding building", sBuildingType);
		for row in GameInfo.Building_GreatWorks() do
			if row.BuildingType == sBuildingType then
				for i = 1, row.NumSlots do AddSlotType(row.GreatWorkSlotType); end
			end
		end
	end

	for _,city in Players[ePlayerID]:GetCities():Members() do
		--print("..checking city", city:GetName());
		
		-- check existing buildings -- just iterate through buildings that can have GWs -- nope, Modifiers can give slots anywhere, e.g. Medici gives  2 slots to a bank
		local cityBuildings:table = city:GetBuildings();
		for building in GameInfo.Buildings() do
		--for row in GameInfo.Building_GreatWorks() do		
		--for _,row in ipairs(DB.Query("select distinct BuildingType from Building_GreatWorks where GreatWorkSlotType <> 'GREATWORKSLOT_RELIC' and GreatWorkSlotType <> 'GREATWORKSLOT_ARTIFACT'")) do
			local eBuilding:number = building.Index;
			if cityBuildings:HasBuilding(eBuilding) then
				--print("   ...checking building", building.BuildingType);
				for i = 0, cityBuildings:GetNumGreatWorkSlots(eBuilding)-1 do
					--print("      ...checking slot", i);
					-- get great work
					local eGWIndex:number = cityBuildings:GetGreatWorkInSlot(eBuilding, i);
					local eGWSlotType:number = cityBuildings:GetGreatWorkSlotType(eBuilding, i);
					--print("      ...slot", i, "type", eGWSlotType, "gw_index", eGWIndex, "building", building.BuildingType);
					if eGWIndex == -1 then -- empty slot
						AddSlotType( GameInfo.GreatWorkSlotTypes[eGWSlotType].GreatWorkSlotType );
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
			if pDistrictDef.DistrictType == "DISTRICT_THEATER" or pDistrictDef.DistrictType == "DISTRICT_ACROPOLIS" then
				AddSlotTypesFromBuilding("BUILDING_AMPHITHEATER");
				AddSlotTypesFromBuilding("BUILDING_MUSEUM_ART");
				AddSlotTypesFromBuilding("BUILDING_BROADCAST_CENTER");
			end
		end

	end -- cities
	
	--print("Total empty slots found", iNumSlotWriting, iNumSlotArt, iNumSlotMusic);
	return iNumSlotWriting, iNumSlotArt, iNumSlotMusic;
end


-- helper - check if great work has been created
-- awfully complex, Lua support is minimal here
-- there is no function that simply says if a GW was created or not - must review all GWs
-- assumption here is that if the GW is created, then it has an index

function GetPlayerWhoCreatedGreatWork(eGWType:number)
	--print("FUN GetPlayerWhoCreatedGreatWork", eGWType, GameInfo.GreatWorks[eGWType].GreatWorkType);
	local iGWIndex:number = 0;
	while Game.GetGreatWorkPlayer(iGWIndex) ~= -1 do
		if Game.GetGreatWorkTypeFromIndex(iGWIndex) == eGWType then return Game.GetGreatWorkPlayer(iGWIndex), iGWIndex; end
		iGWIndex = iGWIndex + 1;
	end
	return -1;
end

function GetNumGreatWorksToCreate(eGPIndividual:number)
	--print("FUN GetNumGreatWorksToCreate", eGPIndividual, GameInfo.GreatPersonIndividuals[eGPIndividual].GreatPersonIndividualType);
	local sGPIndType:string = GameInfo.GreatPersonIndividuals[eGPIndividual].GreatPersonIndividualType;
	local iNum:number = 0;
	for row in GameInfo.GreatWorks() do
		if row.GreatPersonIndividualType == sGPIndType and GetPlayerWhoCreatedGreatWork(row.Index) == -1 then iNum = iNum + 1; end
	end
	return iNum;
end

function ActiveStrategyMoreGreatWorkSlots(ePlayerID:number, iThreshold:number)
	--print(Game.GetCurrentGameTurn(), "FUN ActiveStrategyMoreGreatWorkSlots", ePlayerID, iThreshold);
	local data:table = RST.Data[ePlayerID];
	--if data.Data.ElapsedTurns < GlobalParameters.RST_STRATEGY_COMPARE_OTHERS_NUM_TURNS then return false; end -- don't compare yet

	-- active turns with game speed scaling
	local iNumTurnsActive:number = RST.GameGetNumTurnsScaled(Game.GetCurrentGameTurn() - data.TurnRefreshSlots); -- we'll use Naval counter for convinience
	if iNumTurnsActive < GlobalParameters.RST_NAVAL_NUM_TURNS then return data.ActiveMoreGWSlots; end
	
	-- Iterate through units and look for GWs to be created
	local iNumGWWriting:number, iNumGWArt:number, iNumGWMusic:number = 0, 0, 0; -- note that we don't bother with Artifacts - game assures that number of slots matches number of Archaelogists
	for _,unit in Players[ePlayerID]:GetUnits():Members() do
		local pUnitGP:table = unit:GetGreatPerson();
		if pUnitGP ~= nil and pUnitGP:IsGreatPerson() then
			local sGPClass:string = GameInfo.GreatPersonClasses[ pUnitGP:GetClass() ].GreatPersonClassType;
			--print("...found GP of class", sGPClass);
			if     sGPClass == "GREAT_PERSON_CLASS_WRITER"   then iNumGWWriting = iNumGWWriting + GetNumGreatWorksToCreate(pUnitGP:GetIndividual());
			elseif sGPClass == "GREAT_PERSON_CLASS_ARTIST"   then iNumGWArt     = iNumGWArt     + GetNumGreatWorksToCreate(pUnitGP:GetIndividual());
			elseif sGPClass == "GREAT_PERSON_CLASS_MUSICIAN" then iNumGWMusic   = iNumGWMusic   + GetNumGreatWorksToCreate(pUnitGP:GetIndividual());
			end
			--print("...num of works to be created", iNumGWWriting, iNumGWArt, iNumGWMusic);
		end
	end
	local iTotWorks = iNumGWWriting + iNumGWArt + iNumGWMusic;
	if bLogDebug then print(Game.GetCurrentGameTurn(), "...num of works to create", iNumGWWriting, iNumGWArt, iNumGWMusic); end

	-- Check on each GW class separately - this is safe approach to avoid blocking, i.e. when we have slots for Art but not for Writing
	local iNumSlotWriting:number, iNumSlotArt:number, iNumSlotMusic:number = GetNumEmptyGreatWorkSlots(ePlayerID);
	if bLogDebug then print(Game.GetCurrentGameTurn(), "...num of available slots", iNumSlotWriting, iNumSlotArt, iNumSlotMusic); end
	local iTotSlots = iNumSlotWriting + iNumSlotArt + iNumSlotMusic;
	
	data.ActiveMoreGWSlots = false;
	data.ActiveMoreGWSlots = ( data.ActiveMoreGWSlots or (iNumGWWriting > iNumSlotWriting + 1) ); -- enabler, need it quickly; will acivate if 2 works
	data.ActiveMoreGWSlots = ( data.ActiveMoreGWSlots or (iNumGWArt > iNumSlotArt + 2) ); -- they come in 3, so missing only 1 is not enough; will activate if 3 works
	data.ActiveMoreGWSlots = ( data.ActiveMoreGWSlots or (iNumGWMusic > iNumSlotMusic + 2) ); -- music comes late, maybe it is not worth it to build a district just for 1 GW of Music; will activate if 3 works
	data.TurnRefreshSlots = Game.GetCurrentGameTurn();
	
	if bLogOther then print(Game.GetCurrentGameTurn(),"RSTMGWSL", ePlayerID, iThreshold, "...works/slots", iTotWorks, iTotSlots, "active?", data.ActiveMoreGWSlots); end
	return data.ActiveMoreGWSlots;
end
GameEvents.ActiveStrategyMoreGreatWorkSlots.Add(ActiveStrategyMoreGreatWorkSlots);


function Initialize()
	--print("FUN Initialize");
end
Initialize();

print("OK loaded RealStrategy_GreatPeople.lua from Real Strategy");