print("Loading RealStrategy.lua from Real Strategy version "..GlobalParameters.RST_VERSION_MAJOR.."."..GlobalParameters.RST_VERSION_MINOR);
-- ===========================================================================
-- Real Strategy
-- 2018-12-14: Created by Infixo
-- ===========================================================================

-- InGame functions exposed here
if not ExposedMembers.RST then ExposedMembers.RST = {} end;
local RST = ExposedMembers.RST;

-- Rise & Fall check
--local bIsRiseFall:boolean = Modding.IsModActive("1B28771A-C749-434B-9053-D1380C553DE9"); -- Rise & Fall
--print("Rise & Fall", (bIsRiseFall and "YES" or "no"));

-- configuration options
local bOptionLogStrat:boolean = ( GlobalParameters.RST_OPTION_LOG_STRAT == 1 );
local bOptionLogGuess:boolean = ( GlobalParameters.RST_OPTION_LOG_GUESS == 1 );

local LL = Locale.Lookup;



-- ===========================================================================
-- DATA
-- ===========================================================================

local Strategies:table = {
	NONE     = 0,
	CONQUEST = 1,
	SCIENCE  = 2,  
	CULTURE  = 3, 
	RELIGION = 4,
	DIPLO    = 5, -- reserved for Gathering Storm
	DEFENSE  = 6, -- supporting
	NAVAL    = 7, -- supporting
	TRADE    = 8, -- supporting
};
--dshowtable(Strategies);

local tShowStrat:table = { "CONQUEST", "SCIENCE", "CULTURE", "RELIGION" }; -- only these will be shown in logs and debugs

local tData:table = {}; -- a table of data sets, one for each player
ExposedMembers.RST.Data = tData;
local tPriorities:table = {}; -- a table of Priorities tables (flavors); constructed from DB


-- ===========================================================================
-- DEBUG ROUTINES
-- ===========================================================================

-- debug output routine
function dprint(sStr,p1,p2,p3,p4,p5,p6)
	--if true then return; end
	local sOutStr = sStr;
	if p1 ~= nil then sOutStr = sOutStr.." [1] "..tostring(p1); end
	if p2 ~= nil then sOutStr = sOutStr.." [2] "..tostring(p2); end
	if p3 ~= nil then sOutStr = sOutStr.." [3] "..tostring(p3); end
	if p4 ~= nil then sOutStr = sOutStr.." [4] "..tostring(p4); end
	if p5 ~= nil then sOutStr = sOutStr.." [5] "..tostring(p5); end
	if p6 ~= nil then sOutStr = sOutStr.." [6] "..tostring(p6); end
	print(Game.GetCurrentGameTurn(), sOutStr);
end

-- debug routine - prints a table (no recursion)
function dshowtable(tTable:table)
	if tTable == nil then print("dshowtable: table is nil"); return; end
	for k,v in pairs(tTable) do
		print(k, type(v), tostring(v));
	end
end

-- debug routine - prints a table, and tables inside recursively (up to 5 levels)
function dshowrectable(tTable:table, iLevel:number)
	local level:number = 0;
	if iLevel ~= nil then level = iLevel; end
	for k,v in pairs(tTable) do
		print(string.rep("---:",level), k, type(v), tostring(v));
		if type(v) == "table" and level < 5 then dshowrectable(v, level+1); end
	end
end

-- debug routine - prints priorities table in a compacted form (1 line, formatted)
function dshowpriorities(pTable:table, sComment:string)
	local tOut:table = {};
	--for strat,value in pairs(pTable) do table.insert(tOut, string.format("%s %4.1f :", strat, value)); end
	for _,strat in ipairs(tShowStrat) do table.insert(tOut, string.format(" : %s %4.1f", strat, pTable[strat])); end
	print(Game.GetCurrentGameTurn(), string.format("%40s", sComment), table.concat(tOut, " "));
end


-- ===========================================================================
-- HELPFUL ENUMS
-- ===========================================================================

-- from MapEnums.lua
DirectionTypes = {
	DIRECTION_NORTHEAST = 0,
	DIRECTION_EAST 		= 1,
	DIRECTION_SOUTHEAST = 2,
	DIRECTION_SOUTHWEST = 3,
	DIRECTION_WEST		= 4,
	DIRECTION_NORTHWEST = 5,
	NUM_DIRECTION_TYPES = 6,
};

-- from MapEnums.lua
function GetGameInfoIndex(table_name, type_name) 
	local index = -1;
	local table = GameInfo[table_name];
	if(table) then
		local t = table[type_name];
		if(t) then
			index = t.Index;
		end
	end
	return index;
end

-- from MapEnums.lua, These come from the database.  Get the runtime index values.
g_TERRAIN_NONE				= -1;
g_TERRAIN_GRASS				= GetGameInfoIndex("Terrains", "TERRAIN_GRASS");
g_TERRAIN_GRASS_HILLS		= GetGameInfoIndex("Terrains", "TERRAIN_GRASS_HILLS");
g_TERRAIN_GRASS_MOUNTAIN	= GetGameInfoIndex("Terrains", "TERRAIN_GRASS_MOUNTAIN");
g_TERRAIN_PLAINS			= GetGameInfoIndex("Terrains", "TERRAIN_PLAINS");
g_TERRAIN_PLAINS_HILLS		= GetGameInfoIndex("Terrains", "TERRAIN_PLAINS_HILLS");
g_TERRAIN_PLAINS_MOUNTAIN	= GetGameInfoIndex("Terrains", "TERRAIN_PLAINS_MOUNTAIN");
g_TERRAIN_DESERT			= GetGameInfoIndex("Terrains", "TERRAIN_DESERT");
g_TERRAIN_DESERT_HILLS		= GetGameInfoIndex("Terrains", "TERRAIN_DESERT_HILLS");
g_TERRAIN_DESERT_MOUNTAIN	= GetGameInfoIndex("Terrains", "TERRAIN_DESERT_MOUNTAIN");
g_TERRAIN_TUNDRA			= GetGameInfoIndex("Terrains", "TERRAIN_TUNDRA");
g_TERRAIN_TUNDRA_HILLS		= GetGameInfoIndex("Terrains", "TERRAIN_TUNDRA_HILLS");
g_TERRAIN_TUNDRA_MOUNTAIN	= GetGameInfoIndex("Terrains", "TERRAIN_TUNDRA_MOUNTAIN");
g_TERRAIN_SNOW				= GetGameInfoIndex("Terrains", "TERRAIN_SNOW");
g_TERRAIN_SNOW_HILLS		= GetGameInfoIndex("Terrains", "TERRAIN_SNOW_HILLS");
g_TERRAIN_SNOW_MOUNTAIN		= GetGameInfoIndex("Terrains", "TERRAIN_SNOW_MOUNTAIN");
g_TERRAIN_COAST				= GetGameInfoIndex("Terrains", "TERRAIN_COAST");
g_TERRAIN_OCEAN				= GetGameInfoIndex("Terrains", "TERRAIN_OCEAN");
g_FEATURE_NONE				= -1;
g_FEATURE_FLOODPLAINS		= GetGameInfoIndex("Features", "FEATURE_FLOODPLAINS");
g_FEATURE_ICE				= GetGameInfoIndex("Features", "FEATURE_ICE");
g_FEATURE_JUNGLE			= GetGameInfoIndex("Features", "FEATURE_JUNGLE");
g_FEATURE_FOREST			= GetGameInfoIndex("Features", "FEATURE_FOREST");
g_FEATURE_OASIS				= GetGameInfoIndex("Features", "FEATURE_OASIS");
g_FEATURE_MARSH				= GetGameInfoIndex("Features", "FEATURE_MARSH");

-- new ones
--IMPROVEMENT_BARBARIAN_CAMP
--IMPROVEMENT_GOODY_HUT

-- ===========================================================================
-- TABLE FUNCTIONS AND HELPERS (INC. TABLE OF PLOT INDICES)
-- ===========================================================================

-- check if 'value' exists in table 'pTable'; should work for any type of 'value' and table indices
function IsInTable(pTable:table, value)
	for _, data in pairs(pTable) do
		if data == value then return true; end
	end
	return false;
end

-- returns 'key' at which a given 'value' is stored in table 'pTable'; nil if not found; should work for any type of 'value' and table indices
function GetTableKey(pTable:table, value)
	for key,data in pairs(pTable) do
		if data == value then return key; end
	end
	return nil;
end

-- ===========================================================================
-- PLOT FUNCTIONS AND HELPERS
-- ===========================================================================

-- table with new coors corresponding to given Direction
local tAdjCoors:table = {
	[DirectionTypes.DIRECTION_NORTHEAST] = { dx= 1, dy= 1 },  -- shifting +X, in some conditons dx=0 (rows with even Y-coor)
	[DirectionTypes.DIRECTION_EAST] 	 = { dx= 1, dy= 0 },
	[DirectionTypes.DIRECTION_SOUTHEAST] = { dx= 1, dy=-1 },  -- shifting +X, in some conditons dx=0
	[DirectionTypes.DIRECTION_SOUTHWEST] = { dx=-1, dy=-1 },  -- shifting -X, in some conditons dx=0 (rows with odd Y-coor)
	[DirectionTypes.DIRECTION_WEST]      = { dx=-1, dy= 0 },
	[DirectionTypes.DIRECTION_NORTHWEST] = { dx=-1, dy= 1 },  -- shifting -X, in some conditons dx=0
};

-- Returns coordinates (x,y) of a plot adjacent to the one tested in a specific direction
function GetAdjacentPlotXY(iX:number, iY:number, eDir:number)
	-- double-checking
	if tAdjCoors[eDir] == nil then
		print("ERROR: GetAdjacentXY() invalid direction - ", tostring(eDir));
		return iX, iY;
	end
	-- shifting X, in some conditons dx=-1 or dx=+1
	local idx = tAdjCoors[eDir].dx;
	if (eDir == DirectionTypes.DIRECTION_NORTHEAST or eDir ==  DirectionTypes.DIRECTION_SOUTHEAST) and (iY % 2 == 0) then idx = 0; end
	if (eDir == DirectionTypes.DIRECTION_NORTHWEST or eDir ==  DirectionTypes.DIRECTION_SOUTHWEST) and (iY % 2 == 1) then idx = 0; end
	-- get new coors
	local iAdjX = iX + idx;
	local iAdjY = iY + tAdjCoors[eDir].dy;
	-- wrap coordinates
	if iAdjX >= iMapWidth 	then iAdjX = 0; end
	if iAdjX < 0 			then iAdjX = iMapWidth-1; end
	if iAdjY >= iMapHeight 	then iAdjY = 0; end
	if iAdjY < 0 			then iAdjY = iMapHeight-1; end
	return iAdjX, iAdjY;
end

-- Returns Index of a plot adjacent to the one tested in a specific direction
function GetAdjacentPlotIndex(iIndex:number, eDir:number)
	local iAdjX, iAdjY = GetAdjacentPlotXY(iIndex % iMapWidth, math.floor(iIndex/iMapWidth), eDir);
	return iMapWidth * iAdjY + iAdjX;
end





-- ===========================================================================
-- BOOST CLASS FUNCTIONS
-- ===========================================================================


-- helper - returns a table of Plot objects that are owned by a given city
local iCitySettleRange:number = tonumber(GameInfo.GlobalParameters["CITY_MAX_BUY_PLOT_RANGE"].Value);
function GetCityPlots(tPlots:table, ePlayerID:number, iCityID:number)
	local pCity = Players[ePlayerID]:GetCities():FindID(iCityID);
	if pCity == nil then return; end
	local iX:number, iY:number = pCity:GetX(), pCity:GetY();
	for dx = -iCitySettleRange, iCitySettleRange, 1 do
		for dy = -iCitySettleRange, iCitySettleRange, 1 do
			local pPlot = Map.GetPlotXY(iX, iY, dx, dy);
			--dprint("  ...plot (id) owned by (owner)", pPlot:GetIndex(), pPlot:GetOwner());
			local pPlotCity = Cities.GetPlotPurchaseCity(pPlot);
			if pPlotCity ~= nil and pPlotCity:GetOwner() == ePlayerID and pPlotCity:GetID() == iCityID then
				table.insert(tPlots, pPlot);
			end
		end
	end
	dprint("FUNEND GetCityPlots() found plots", table.count(tPlots));
end

function CountCityTilesTerrain(tPlots:table, sTerrainType:string)
	dprint("FUN CountCityTilesTerrain()",sTerrainType);
	local iNum = 0;
	for _,plot in pairs(tPlots) do
		local pTerrain = GameInfo.Terrains[plot:GetTerrainType()];
		--dprint("  ...plot (id) is (terrain)", plot:GetIndex(), plot:GetTerrainType());
		if pTerrain ~= nil and string.find(pTerrain.TerrainType, sTerrainType) ~= nil then iNum = iNum + 1; end
	end
	dprint("  ...found", iNum, sTerrainType);
	return iNum;
end

function CountCityTilesFeature(tPlots:table, sFeatureType:string)
	dprint("FUN CountCityTilesFeature()",sFeatureType);
	local iNum = 0;
	for _,plot in pairs(tPlots) do
		local pFeature = GameInfo.Features[plot:GetFeatureType()];
		--dprint("  ...plot (id) is (feature)", plot:GetIndex(), plot:GetFeatureType());
		if pFeature ~= nil and pFeature.FeatureType == sFeatureType then iNum = iNum + 1; end
	end
	dprint("  ...found", iNum, sFeatureType);
	return iNum;
end


-- special additional resource visibility check is required
local tResourceVisible:table = {};
function UpdateResourceVisibility(ePlayerID:number)
	for res in GameInfo.Resources() do
		tResourceVisible[res.Index] = true;  -- most of them are visible from start
		if res.PrereqTechReference ~= nil then 
			tResourceVisible[res.Index] = Players[ePlayerID]:GetTechs():HasTech( res.PrereqTechReference.Index );
		end
		if res.PrereqCivicReference ~= nil then 
			tResourceVisible[res.Index] = Players[ePlayerID]:GetCulture():HasCivic( res.PrereqCivicReference.Index );
		end
	end
	--dprint("Resources NOT visible");
	--for res in GameInfo.Resources() do
		--if not tResourceVisible[res.Index] then dprint("  ... (type)", res.ResourceType); end
	--end
end


function CountCityTilesImprovableRes(tPlots:table, sImprovementType:string)
	dprint("FUN CountCityTilesImprovableRes()",sImprovementType);
	-- first prepare a table of valid resources (just Indices)
	local tResourceValid:table = {};
	for _,vres in pairs(GameInfo.Improvements[sImprovementType].ValidResources) do
		if tResourceVisible[vres.ResourceReference.Index] then
			tResourceValid[vres.ResourceReference.Index] = true;
		end
	end
	--dprint("Valid resources for improvement are", sImprovementType);
	--for id,_ in pairs(tResourceValid) do dprint("  ... (id,type)", id, GameInfo.Resources[id].ResourceType); end
	-- now check plots
	local iNum = 0;
	for _,plot in pairs(tPlots) do
		local pResource = GameInfo.Resources[plot:GetResourceType()];
		--dprint("  ...plot (id) is (res)", plot:GetIndex(), plot:GetResourceType());
		if pResource ~= nil and tResourceValid[pResource.Index] then iNum = iNum + 1; end
	end
	dprint("  ...found", iNum, sImprovementType);
	return iNum;
end

-- added 2018-02-13
function CountCityTilesHills(tPlots:table)
	dprint("FUN CountCityTilesHills()");
	local iNum = 0;
	for _,plot in pairs(tPlots) do
		if plot:IsHills() then iNum = iNum + 1; end
	end
	dprint("  ...found", iNum);
	return iNum;
end

-- added 2018-02-13
function CountCityTilesLake(tPlots:table)
	dprint("FUN CountCityTilesLake()");
	local iNum = 0;
	for _,plot in pairs(tPlots) do
		if plot:IsLake() then iNum = iNum + 1; end
	end
	dprint("  ...found", iNum);
	return iNum;
end


-- ===========================================================================
-- HELPERS
-- ===========================================================================

-- get a new table with all 0
function PriorityTableNew()
	local tNew:table = {};
	for strat,_ in pairs(Strategies) do tNew[ strat ] = 0; end
	return tNew;
end

-- set all values to 0
function PriorityTableClear(pTable:table)
	for strat,_ in pairs(Strategies) do pTable[ strat ] = 0; end
end

-- add two tables
function PriorityTableAdd(pTable:table, pTableToAdd:table)
	for strat,_ in pairs(Strategies) do pTable[ strat ] = pTable[ strat ] + pTableToAdd[ strat ]; end
end

-- multiply two tables
function PriorityTableMultiplyByTable(pTable:table, pTableToMult:table)
	for strat,_ in pairs(Strategies) do pTable[ strat ] = pTable[ strat ] * pTableToMult[ strat ]; end
end

-- multiply by a given number
function PriorityTableMultiply(pTable:table, fModifier:number)
	for strat,_ in pairs(Strategies) do pTable[ strat ] = pTable[ strat ] * fModifier; end
end

-- religion helper - counts us as well!
function PlayerGetNumCivsConverted(ePlayerID:number)
	--print("FUN PlayerGetNumCivsConverted", ePlayerID);
	local iNumCivsConverted = 0;
	--local pPlayerReligion:table = Players[ePlayerID]:GetReligion();
	local eReligionID:number = RST.PlayerGetReligionTypeCreated(ePlayerID); -- compatibility with vanilla pPlayerReligion:GetReligionTypeCreated();
	if eReligionID ~= -1 and eReligionID ~= GameInfo.Religions.RELIGION_PANTHEON.Index then
		-- are we converted?
		if Players[ePlayerID]:GetReligion():GetReligionInMajorityOfCities() == eReligionID then iNumCivsConverted = 1; end
		-- count others
		local pPlayerDiplomacy:table = Players[ePlayerID]:GetDiplomacy();
		for _,otherID in ipairs(PlayerManager.GetAliveMajorIDs()) do
			if pPlayerDiplomacy:HasMet(otherID) and Players[otherID]:GetReligion():GetReligionInMajorityOfCities() == eReligionID then
				iNumCivsConverted = iNumCivsConverted + 1;
			end
		end
	end
	return iNumCivsConverted;
end

-- IsMinor() is not available in Gameplay context!
-- see also CivilizationLevels table
function PlayerIsMinor(ePlayerID:number)
	if PlayerConfigurations[ePlayerID] == nil then return false; end
	return PlayerConfigurations[ePlayerID]:GetCivilizationLevelTypeName() == "CIVILIZATION_LEVEL_CITY_STATE";
end

-- get City State category (cultural, industrial, etc.)
-- this is tricky - this info is in TypeProperties table attached to CIVILIZATION_ type
function GetCityStateCategory(ePlayerID:number)
	if PlayerConfigurations[ePlayerID] == nil then print("ERROR: GetCityStateCategory cannot get configuration for", ePlayerID); return "(error)"; end
	local sCivilizationType:string = PlayerConfigurations[ePlayerID]:GetCivilizationTypeName();
	for row in GameInfo.TypeProperties() do
		if row.Type == sCivilizationType and row.Name == "CityStateCategory" then return row.Value; end
	end
	print("ERROR: GetCityStateCategory cannot find category for", sCivilizationType);
	return "(error)";
end


-- ===========================================================================
-- CORE FUNCTIONS
-- ===========================================================================

local iMaxNumReligions:number = 0; -- maximum number of religions on this map

------------------------------------------------------------------------------
-- Read flavors and parameters, initialize players
function InitializeData()
	--print("FUN InitializeData");
	
	-- get max religions
	local mapSizeType:string = GameInfo.Maps[Map.GetMapSize()].MapSizeType;
	for row in GameInfo.Map_GreatPersonClasses() do
		if row.MapSizeType == mapSizeType and row.GreatPersonClassType == "GREAT_PERSON_CLASS_PROPHET" then
			iMaxNumReligions = row.MaxWorldInstances;
			break;
		end
	end
	print("Max religions:", iMaxNumReligions);

	-- initialize players
	for _,playerID in ipairs(PlayerManager.GetAliveMajorIDs()) do
		local data:table = {
			PlayerID = playerID,
			LeaderType = PlayerConfigurations[playerID]:GetLeaderTypeName(),
			LeaderName = Locale.Lookup(PlayerConfigurations[playerID]:GetLeaderName()),
			--Dirty = true,
			TurnRefresh = -1, -- turn number when was it refreshed last time
			ActiveStrategy = "NONE",
			--NumTurnsActive = 0,
			Data = {}, -- this will be refreshed whenever needed, but only once per turn
			Stored = {}, -- this will be stored between turns (persistent) and eventually perhaps in the save file
		};
		tData[playerID] = data;
		print("...registering player", data.PlayerID, data.LeaderType, data.LeaderName); -- debug
	end
	
	-- initalize flavors
	for flavor in GameInfo.RSTFlavors() do
		local data:table = tPriorities[flavor.ObjectType];
		if data == nil then
			data = {
				ObjectType = flavor.ObjectType,
				Type = flavor.Type,
				Subtype = flavor.Subtype,
				Priorities = PriorityTableNew(),
			};
			tPriorities[flavor.ObjectType] = data;
		end
		data.Priorities[flavor.Strategy] = flavor.Value;
	end
	--[[
	print("Table of priorities:"); -- debug
	for objType,data in pairs(tPriorities) do
		--dprint("object,type,subtype", data.ObjectType, data.Type, data.Subtype);
		dshowpriorities(data.Priorities, data.ObjectType);
	end
	--]]
end

--[[
Data
- Each civ needs its own set of data - should be stored in the table []????
- Not needed, assuming that all is refreshed!
- However, it is possible that some data could be stored between turns, e.g. current strategy
- Weights should be parameters

Main function:
- uses bDirty to mark dirty data
- gather current data about ourselves
- store each element in a table of priorities, with the name and weight?
- recalculate (easy)
- log results (details)
- guess what others are doing
- AI logic?

Event functions
- There will be many or few, but they will be called for many strategies, so multiple times
- Recalculate only once and later just return quickly results
- Need bDirty to mark the need to recalculate



--]]

------------------------------------------------------------------------------
-- This function gathers data specific for a player that can be reused in many places, like Military Strength, Science Positions, Tourism, etc.
-- all data is stored in tData[player].Data
function RefreshPlayerData(data:table)
	print(Game.GetCurrentGameTurn(), "FUN RefreshPlayerData", data.PlayerID, data.LeaderType);
	
	local ePlayerID:number = data.PlayerID;
	local pPlayer:table = Players[ePlayerID];
	local tOut:table = {}; -- debug
	
	local tNewData:table = {
		Era = pPlayer:GetEra(), -- simple
		ElapsedTurns = 0, -- with game speed scaling
		NumMajorsAliveAndMet = 0, -- number of alive major civs that we've met
		NumMajorsWithReligion = (RST.PlayerHasReligion(ePlayerID) and 1 or 0), -- number of alive, met and with religion plus us if we have one
		MajorIDsAliveAndMet = {}, -- and their IDs
		ReligionID = RST.PlayerGetReligionTypeCreated(ePlayerID), -- pPlayer:GetReligion():GetReligionTypeCreated(),
		NumCivsConverted = PlayerGetNumCivsConverted(ePlayerID), -- must count ourselves also!
		-- world averages - must calculate only for known civs + us
		AvgMilStr  = RST.GameGetAverageMilitaryStrength(ePlayerID), -- MilitaryStrength
		AvgTechs   = RST.GameGetAverageNumTechsResearched(ePlayerID),
		AvgScience = pPlayer:GetTechs():GetScienceYield(),
		AvgCulture = pPlayer:GetCulture():GetCultureYield(),
		AvgTourism = RST.PlayerGetTourism(ePlayerID),
		AvgFaith   = pPlayer:GetReligion():GetFaithYield(),
		AvgCities  = RST.PlayerGetNumCitiesFollowingReligion(ePlayerID), -- start with us
	};
	
	-- elapsed turns with game speed scaling
	tNewData.ElapsedTurns = (Game.GetCurrentGameTurn() - GameConfiguration.GetStartTurn()) * 100 / GameInfo.GameSpeeds[GameConfiguration.GetGameSpeedType()].CostMultiplier;
	
	-- gather IDs and infos of major civs met
	local pPlayerDiplomacy:table = pPlayer:GetDiplomacy();
	for _,otherID in ipairs(PlayerManager.GetAliveMajorIDs()) do
		if pPlayerDiplomacy:HasMet(otherID) then -- HasMet returns false for ourselves, so no need for otherID ~= ePlayerID 
			tNewData.NumMajorsAliveAndMet = tNewData.NumMajorsAliveAndMet + 1;
			if RST.PlayerHasReligion(otherID) then tNewData.NumMajorsWithReligion = tNewData.NumMajorsWithReligion + 1; end
			table.insert(tNewData.MajorIDsAliveAndMet, otherID);
			-- calculate averages
			tNewData.AvgScience = tNewData.AvgScience + Players[otherID]:GetTechs():GetScienceYield();
			tNewData.AvgCulture = tNewData.AvgCulture + Players[otherID]:GetCulture():GetCultureYield();
			tNewData.AvgTourism = tNewData.AvgTourism + RST.PlayerGetTourism(otherID);
			tNewData.AvgFaith   = tNewData.AvgFaith   + Players[otherID]:GetReligion():GetFaithYield();
			tNewData.AvgCities  = tNewData.AvgCities  + RST.PlayerGetNumCitiesFollowingReligion(otherID);
		end
	end

	-- calculate averages
	tNewData.AvgScience = tNewData.AvgScience / (tNewData.NumMajorsAliveAndMet+1);
	tNewData.AvgCulture = tNewData.AvgCulture / (tNewData.NumMajorsAliveAndMet+1);
	tNewData.AvgTourism = tNewData.AvgTourism / (tNewData.NumMajorsAliveAndMet+1);
	tNewData.AvgFaith   = tNewData.AvgFaith   / (tNewData.NumMajorsAliveAndMet+1);
	if tNewData.NumMajorsWithReligion > 0 then
		tNewData.AvgCities  = tNewData.AvgCities  / tNewData.NumMajorsWithReligion;
	end
	
	-- replace the data
	data.Data = tNewData;
	--print("RefreshPlayerData:", ePlayerID)
	--dshowrectable(data.Data);
end	


------------------------------------------------------------------------------
-- Gather generic data like Leader, Policies, Beliefs, etc
function GetGenericPriorities(data:table)
	print(Game.GetCurrentGameTurn(), "FUN GetGenericPriorities", data.PlayerID, data.LeaderType);
	
	local ePlayerID:number = data.PlayerID;
	local pPlayer:table = Players[ePlayerID];
	
	-- POLICIES
	-- Add priority value based on flavors of policies we've acquired.
	--print("...generic: policies", data.LeaderName);
	local tPolicies:table = RST.PlayerGetSlottedPolicies(ePlayerID);
	local tPolicyPriorities:table = PriorityTableNew();
	for _,policy in ipairs(tPolicies) do
		if tPriorities[policy] then PriorityTableAdd(tPolicyPriorities, tPriorities[policy].Priorities);
		else                        print("WARNING: policy", policy, "not defined in Priorities"); end
	end
	PriorityTableMultiply(tPolicyPriorities, GlobalParameters.RST_WEIGHT_POLICY);
	dshowpriorities(tPolicyPriorities, "generic policies");
	
	-- GOVERNMENT
	--print("...generic: government", data.LeaderName);
	local sGovType:string = GameInfo.Governments[ RST.PlayerGetCurrentGovernment(ePlayerID) ].GovernmentType;
	local tGovPriorities:table = PriorityTableNew();
	if tPriorities[sGovType] then PriorityTableAdd(tGovPriorities, tPriorities[sGovType].Priorities);
	else                          print("WARNING: government", sGovType, "not defined in Priorities"); end
	PriorityTableMultiply(tGovPriorities, GlobalParameters.RST_WEIGHT_GOVERNMENT);
	dshowpriorities(tGovPriorities, "generic government "..string.gsub(sGovType, "GOVERNMENT_", ""));
	
	-- WONDERS
	-- probably the fastest way is to iterate through Flavors?
	--print("...generic: wonders", data.LeaderName);
	local tWonderPriorities:table = PriorityTableNew();
	for object,data in pairs(tPriorities) do
		if data.Type == "Wonder" and GameInfo.Buildings[data.ObjectType] ~= nil then -- make sure this Wonder is actually in-game
			-- now iterate through cities
			for _,city in pPlayer:GetCities():Members() do
				--print("...checking", data.ObjectType, "in", city:GetName());
				if city:GetBuildings():HasBuilding( GameInfo.Buildings[data.ObjectType].Index ) then
					--print("...player has", object);
					PriorityTableAdd(tWonderPriorities, data.Priorities);
				end
			end
		end
	end
	PriorityTableMultiply(tWonderPriorities, GlobalParameters.RST_WEIGHT_WONDER);
	dshowpriorities(tWonderPriorities, "generic wonders");
	
	-- CITY STATES
	--print("...generic: city states", data.LeaderName);
	local tMinorPriorities:table = PriorityTableNew();
	for _,minor in ipairs(PlayerManager.GetAliveMinors()) do
		if minor:GetInfluence():GetSuzerain() == ePlayerID then
			local sCategory:string = GetCityStateCategory(minor:GetID());
			--print("...suzerain of", sCategory);
			PriorityTableAdd(tMinorPriorities, tPriorities[sCategory].Priorities);
		end
	end
	PriorityTableMultiply(tMinorPriorities, GlobalParameters.RST_WEIGHT_MINOR);
	dshowpriorities(tMinorPriorities, "generic city states");

	-- BELIEFS
	-- Add priority value based on flavors of beliefs we've acquired.
	--print("...generic: beliefs", data.LeaderName);
	local tBeliefs:table = RST.PlayerGetBeliefs(ePlayerID);
	local tBeliefPriorities:table = PriorityTableNew();
	for _,beliefID in pairs(tBeliefs) do
		if GameInfo.Beliefs[beliefID] then
			local sBelief:string = GameInfo.Beliefs[beliefID].BeliefType;
			--print("..earned", sBelief);
			if tPriorities[sBelief] then PriorityTableAdd(tBeliefPriorities, tPriorities[sBelief].Priorities);
			else                         print("WARNING: belief", sBelief, "not defined in Priorities"); end
		end
	end
	PriorityTableMultiply(tBeliefPriorities, GlobalParameters.RST_WEIGHT_BELIEF);
	dshowpriorities(tBeliefPriorities, "generic beliefs");
	
	--print("...generic priorities for leader", data.LeaderName);
	local tGenericPriorities:table = PriorityTableNew();
	PriorityTableAdd(tGenericPriorities, tPolicyPriorities);
	PriorityTableAdd(tGenericPriorities, tGovPriorities);
	PriorityTableAdd(tGenericPriorities, tWonderPriorities);
	PriorityTableAdd(tGenericPriorities, tMinorPriorities);
	dshowpriorities(tGenericPriorities, "*** generic priorities "..data.LeaderType);
	return tGenericPriorities;
end


------------------------------------------------------------------------------
-- TODO: Add map analysis in the future
function ProcessGeographicData(ePlayerID:number)
	print("FUN ProcessGeographicData", ePlayerID);
end


------------------------------------------------------------------------------
-- functions to check if a player is close to a victory
-- check Game.GetVictoryProgressForPlayer - maybe it could be easier to use? - NOT EXISTS

function PlayerIsCloseToConquestVictory(ePlayerID:number)
	--print("FUN PlayerIsCloseToConquestVictory", ePlayerID);
	-- check for number of all capitals taken vs. total major players
	--print( "close to conquest? player", ePlayerID, "capitals, all players", RST.PlayerGetNumCapturedCapitals(ePlayerID), PlayerManager.GetWasEverAliveMajorsCount());
	return ( RST.PlayerGetNumCapturedCapitals(ePlayerID) / (PlayerManager.GetWasEverAliveMajorsCount()-1) ) > 0.6; -- size 4 after 2, size 6 after 3, size 8 after 5, size 10 after 6, size 12 after 7
end

-- return the number of completed space race projects
function PlayerGetNumProjectsSpaceRace(ePlayerID:number)
	--print("FUN PlayerGetNumProjectsSpaceRace", ePlayerID);
	-- count space race projects
	local iTot:number, iNum:number = 0, 0;
	for row in GameInfo.Projects() do
		if row.SpaceRace then
			iTot = iTot + 1;
			iNum = iNum + RST.PlayerGetNumProjectsAdvanced(ePlayerID, row.Index);
		end
	end
	--print("space race player, num/tot", ePlayerID, iNum, iTot);
	return iNum;
end

function PlayerIsCloseToScienceVictory(ePlayerID:number)
	--print("FUN PlayerIsCloseToScienceVictory", ePlayerID);
	return PlayerGetNumProjectsSpaceRace(ePlayerID) >= 2; -- 2 out of 5
end

function PlayerIsCloseToCultureVictory(ePlayerID:number)
	--print("FUN PlayerIsCloseToCultureVictory", ePlayerID);
	--print("close to culture? player", ePlayerID, "cultural progress", RST.PlayerGetCultureVictoryProgress(ePlayerID));
	return RST.PlayerGetCultureVictoryProgress(ePlayerID) > 60; -- it is in % (0..100)
end

function PlayerIsCloseToReligionVictory(ePlayerID:number)
	--print("FUN PlayerIsCloseToReligionVictory", ePlayerID);
	-- similar condition as for conquest
	--print("close to religion? player", ePlayerID, "converted, all civs", PlayerGetNumCivsConverted(ePlayerID), PlayerManager.GetWasEverAliveMajorsCount());
	return PlayerGetNumCivsConverted(ePlayerID) / PlayerManager.GetWasEverAliveMajorsCount() > 0.6 -- size 4 after 3, size 6 after 4, size 8 after 5, size 10 after 7, size 12 after 8
end

function PlayerIsCloseToDiploVictory(ePlayerID:number)
	--print("FUN PlayerIsCloseToDiploVictory", ePlayerID);
	return false;
end

function PlayerIsCloseToAnyVictory(ePlayerID:number)
	return PlayerIsCloseToConquestVictory(ePlayerID) or PlayerIsCloseToCultureVictory(ePlayerID) or PlayerIsCloseToDiploVictory(ePlayerID) or PlayerIsCloseToReligionVictory(ePlayerID) or PlayerIsCloseToScienceVictory(ePlayerID);
end


------------------------------------------------------------------------------
-- Specific: CONQUEST
function GetPriorityConquest(data:table)
	--print("FUN GetPriorityConquest", data.PlayerID, data.LeaderType);
	-- check if this victory type is enabled
	if not RST.GameIsVictoryEnabled("VICTORY_CONQUEST") then return -100; end
	
	local iPriority:number = 0;
	local ePlayerID:number = data.PlayerID;
	local pPlayer:table = Players[ePlayerID];
	local pPlayerDiplomacy:table = pPlayer:GetDiplomacy();
	
	-- first check is for Hostility, Deceptiveness, etc. - those are not supported in Civ6
	-- iPriority += ((GetPlayer()->GetDiplomacy()->GetBoldness() + iGeneralApproachModifier + GetPlayer()->GetDiplomacy()->GetMeanness()) * (10 - iEra)); // make a little less likely as time goes on
	-- try to use generic Flavor?
	--if tPriorities[data.LeaderType] then
	-- ???????? There is already Era Bias factor for each victory - is this really needed?
	iPriority = tPriorities[data.LeaderType].Priorities.CONQUEST;
	iPriority = iPriority * 2 * (1.0 - data.Data.Era/#GameInfo.Eras); -- PARAMETER???
	dprint("...era adjusted extra conquest, priority=", iPriority);
	--end

	-- early game, if we haven't met any Major Civs yet, then we probably shouldn't be planning on conquering the world
	--local iElapsedTurns:number = Game.GetCurrentGameTurn() - GameConfiguration.GetStartTurn(); -- TODO: GameSpeed scaling!
	if data.Data.ElapsedTurns >= GlobalParameters.RST_CONQUEST_NOBODY_MET_NUM_TURNS then -- def. 20, AI_GS_CONQUEST_NOBODY_MET_FIRST_TURN
		if data.Data.NumMajorsAliveAndMet == 0 then 
			iPriority = iPriority + GlobalParameters.RST_CONQUEST_NOBODY_MET_PRIORITY; -- def. -50, AI_GRAND_STRATEGY_CONQUEST_NOBODY_MET_WEIGHT
			print("...turn", Game.GetCurrentGameTurn(), "no majors met, priority=", iPriority);
		end
	end

	-- If we're at war, then boost the weight a bit (ignore minors)
	for _,otherID in ipairs(PlayerManager.GetAliveMajorIDs()) do
		if pPlayerDiplomacy:IsAtWarWith(otherID) then
			print("we are at war with", otherID);
			iPriority = iPriority + GlobalParameters.RST_CONQUEST_AT_WAR_PRIORITY;
		end
	end

	-- include captured capitals
	local iNumCapturedCapitals:number = RST.PlayerGetNumCapturedCapitals(ePlayerID);
	--if iNumCapturedCapitals > 1 then
	iPriority = iPriority + GlobalParameters.RST_CONQUEST_CAPTURED_CAPITAL_PRIORITY * iNumCapturedCapitals;
	--end
	print("...player has captured", iNumCapturedCapitals, "capitals; priority=", iPriority);
	
	-- How many turns must have passed before we test for us having a weak military?
	if data.Data.ElapsedTurns >= GlobalParameters.RST_STRATEGY_COMPARE_OTHERS_NUM_TURNS then -- AI_GS_CONQUEST_MILITARY_STRENGTH_FIRST_TURN, def. 60
		-- Compare our military strength to the rest of the world
		--local iWorldMilitaryStrength:number = RST.GameGetAverageMilitaryStrength(ePlayerID); -- include us and only known
		-- Reduce world average if we're rocking multiple capitals (VP specific)
		local iWorldMilitaryStrength:number = data.Data.AvgMilStr * 100 / (100 + iNumCapturedCapitals * 10); -- ??????
		if iWorldMilitaryStrength > 0 then
			local iMilitaryRatio:number = (RST.PlayerGetMilitaryStrength(ePlayerID) - iWorldMilitaryStrength) * GlobalParameters.RST_CONQUEST_POWER_RATIO_MULTIPLIER / iWorldMilitaryStrength; -- -100 = we are at 0, 0 = we are average, +100 = we are 2x as average, +200 = we are 3x as average, etc.
			-- Make the likelihood of BECOMING a warmonger lower than dropping the bad behavior
			--iMilitaryRatio = iMilitaryRatio * 0.5; -- should be the same as setting param to 50
			--if iMilitaryRatio > 0 then -- let's not use negative priorities as for now
			iPriority = iPriority + iMilitaryRatio; -- This will add between -100 and 100 depending on this player's MilitaryStrength relative the world average. The number will typically be near 0 though, as it's fairly hard to get away from the world average
			--end
			print("...military ratio", iMilitaryRatio, "player/world", RST.PlayerGetMilitaryStrength(ePlayerID), iWorldMilitaryStrength, "priority=", iPriority);
		end
	end
	
	-- Desperate factor
	--local iEra:number = pPlayer:GetEra();
	local bDesperate:boolean = not PlayerIsCloseToAnyVictory(ePlayerID);
	print("...era, desperate", data.Data.Era, bDesperate);
	local iPriorityDangerPlayers:number = 0;
	local iNumCities:number = 0;
	for _,otherID in ipairs(data.Data.MajorIDsAliveAndMet) do
		if PlayerIsCloseToAnyVictory(otherID) then
			print("player", otherID, "is close to a victory");
			iPriorityDangerPlayers = iPriorityDangerPlayers + (bDesperate and GlobalParameters.RST_CONQUEST_SOMEONE_CLOSE_TO_VICTORY or GlobalParameters.RST_CONQUEST_BOTH_CLOSE_TO_VICTORY);
		end
		iNumCities = iNumCities + Players[otherID]:GetCities():GetCount();
	end
	-- increase priority by desperate factor
	iPriority = iPriority + iPriorityDangerPlayers * data.Data.Era;
	if iPriorityDangerPlayers > 0 then print("iPriorityDangerPlayers", iPriorityDangerPlayers, "priority=", iPriority); end
	
	-- cramped factor - checks for all plots' ownership but it is cheating - use cities instead (available in deal screen)
	-- HNT: this can be used for Defense also - if we lack with cities, we need better defense
	-- but first it checks our current land and nearby plots - if there are any usable?
	local iOurCities:number = pPlayer:GetCities():GetCount();
	if data.Data.ElapsedTurns >= GlobalParameters.RST_STRATEGY_COMPARE_OTHERS_NUM_TURNS then
		local iAvgCities:number = (iNumCities + iOurCities) / (data.Data.NumMajorsAliveAndMet + 1);
		if iOurCities < iAvgCities then
			iPriority = iPriority + GlobalParameters.RST_CONQUEST_LESS_CITIES_WEIGHT * ( iAvgCities - iOurCities );
			print("our cities, on average", iOurCities, iAvgCities, "priority=", iPriority);
		end
	end

	-- if we do not have nukes and we know someone else who does... [CHEATING??? CHECK]
	if RST.PlayerGetNumWMDs(ePlayerID) == 0 then
		for _,otherID in ipairs(data.Data.MajorIDsAliveAndMet) do
			if RST.PlayerGetNumWMDs(otherID) > 0 then
				iPriority = iPriority + GlobalParameters.RST_CONQUEST_NUKE_THREAT;
				print("player", otherID, "has NUKES; priority=", iPriority);
				break;
			end
		end -- for
	end -- 0 nukes
	
	--print("GetPriorityConquest:", iPriority);
	return iPriority;
end


------------------------------------------------------------------------------
-- Specific: SCIENCE
function GetPriorityScience(data:table)
	--print("FUN GetPriorityScience", data.PlayerID, data.LeaderType);
	-- check if this victory type is enabled
	if not RST.GameIsVictoryEnabled("VICTORY_TECHNOLOGY") then return -100; end
	
	local iPriority:number = 0;
	local ePlayerID:number = data.PlayerID;
	local pPlayer:table = Players[ePlayerID];

	-- if I already completed some projects I am very likely to follow through
	local iSpaceRaceProjects:number = PlayerGetNumProjectsSpaceRace(ePlayerID);
	iPriority = iPriority + iSpaceRaceProjects * GlobalParameters.RST_SCIENCE_PROJECT_WEIGHT;
	if iSpaceRaceProjects > 0 then print("...space race projects", iSpaceRaceProjects, "priority=", iPriority); end
	
	-- Add in our base science value.
	--iPriority = iPriority + pPlayer:GetTechs():GetScienceYield() * GlobalParameters.RST_SCIENCE_YIELD_WEIGHT / 100.0;
	--iPriorityBonus += (m_pPlayer->GetScienceYield() / 250); -- VERY IMPORTANT! VP uses 250, but science in VP can be as high as Ks, so for 10000 (late game) it gives 40; in Civ6 it is usually in 00s, like 300-500?
	--print("...added science yield, yield", pPlayer:GetTechs():GetScienceYield(), "priority=", iPriority);

	-- How many turns must have passed before we test for us against others
	if data.Data.ElapsedTurns >= GlobalParameters.RST_STRATEGY_COMPARE_OTHERS_NUM_TURNS then
		-- Compare our science output to the rest of the world
		-- Reduce world average if we've completed some space race projects (VP specific)
		local iWorld:number = data.Data.AvgScience * 100 / (100 + iSpaceRaceProjects * 10); -- ??????
		if iWorld > 0 then
			local iRatio:number = (pPlayer:GetTechs():GetScienceYield() - iWorld) * GlobalParameters.RST_SCIENCE_YIELD_RATIO_MULTIPLIER / iWorld; -- -100 = we are at 0, 0 = we are average, +100 = we are 2x as average, +200 = we are 3x as average, etc.
			iPriority = iPriority + iRatio; -- This will add between -100 and 100 depending on this player's MilitaryStrength relative the world average. The number will typically be near 0 though, as it's fairly hard to get away from the world average
			print("...science ratio", iRatio, "player/world", pPlayer:GetTechs():GetScienceYield(), iWorld, "priority=", iPriority);
		end
	end

	
	-- VP uses an algorithm based on civ relative position in a pack by num of techs AI_GS_CULTURE_AHEAD_WEIGHT=50 - max that we can get from that
	-- seems ok however it doesn't account for how much we are ahead (or behind)
	-- similar approach to relative power - get average techs and if we are ahead, then add some weight
	-- also, account for late game - being ahead should be more valued then?
	-- num_techs_better_than_avg * per_tech
	-- no era adjustment here - if we are doing good, our position will only get better plus yield will matter more
	-- How many turns must have passed before we test for us having a weak military?
	if data.Data.ElapsedTurns >= GlobalParameters.RST_STRATEGY_COMPARE_OTHERS_NUM_TURNS then
		-- Compare our num techs to the rest of the world
		--local iWorld:number = RST.GameGetAverageNumTechsResearched(ePlayerID); --, true, true); -- include us and only known
		local iWorld:number = data.Data.AvgTechs;
		if iWorld > 0 then
			-- the PICKLE here: when we are behind, we get a negative value - it is not the case with Culture nor Religion
			--local iRatio:number = (RST.PlayerGetNumTechsResearched(ePlayerID) - iWorld) * GlobalParameters.RST_SCIENCE_TECH_WEIGHT;
			local iRatio:number = (RST.PlayerGetNumTechsResearched(ePlayerID) - iWorld) * (GlobalParameters.RST_SCIENCE_TECH_RATIO_MULTIPLIER + 3 * iWorld) / iWorld; -- slightly modified formula, adding 3*World prevents the diff from diminishing too quickly!
			--if iRatio > 0 then -- let's not use negatives yet
			iPriority = iPriority + iRatio;
			--end
			print("...tech ratio", iRatio, "player/world", RST.PlayerGetNumTechsResearched(ePlayerID), iWorld, "priority=", iPriority);
		end
	end
	
	-- check for spaceport
	if RST.PlayerHasSpaceport(ePlayerID) then
		iPriority = iPriority + GlobalParameters.RST_SCIENCE_HAS_SPACEPORT;
		print("...player has spaceport, priority=", iPriority)
	end
	
	--print("GetPriorityScience:", iPriority);
	return iPriority;
end


------------------------------------------------------------------------------
-- Specific: CULTURE
function GetPriorityCulture(data:table)
	--print("FUN GetPriorityCulture", data.PlayerID, data.LeaderType);
	-- check if this victory type is enabled
	if not RST.GameIsVictoryEnabled("VICTORY_CULTURE") then return -100; end
	
	local iPriority:number = 0;
	local ePlayerID:number = data.PlayerID;
	local pPlayer:table = Players[ePlayerID];
	
	-- the later the game the greater the chance
	--iPriority = tPriorities[data.LeaderType].Priorities.CULTURE * pPlayer:GetEra() * GlobalParameters.RST_CULTURE_ERA_BIAS / 100.0;
	--print("...science weight, era, science bias", tPriorities[data.LeaderType].Priorities.SCIENCE, pPlayer:GetEra(), iPriority);

	-- Add in our base culture and tourism value
	-- VP uses /240 for culture = 3,3%, late game is getting into 5000+ => 20 pts || Civ6 ~500
	-- VP uses /1040 for tourism = 0,8%, late game is getting into 1000+ => 1 pts (?) || Civ6 ~500
	--iPriority = iPriority + pPlayer:GetCulture():GetCultureYield() * GlobalParameters.RST_CULTURE_YIELD_WEIGHT / 100.0;
	--print("...added culture yield, yield", pPlayer:GetCulture():GetCultureYield(), "priority=", iPriority);
	
	-- How many turns must have passed before we test for us against others
	if data.Data.ElapsedTurns >= GlobalParameters.RST_STRATEGY_COMPARE_OTHERS_NUM_TURNS then
		-- Compare our culture output to the rest of the world
		local iWorld:number = data.Data.AvgCulture; -- * 100 / (100 + math.max(0,(data.Data.NumCivsConverted-1)) * 10); -- ??????
		if iWorld > 0 then
			local iRatio:number = (pPlayer:GetCulture():GetCultureYield() - iWorld) * GlobalParameters.RST_CULTURE_YIELD_RATIO_MULTIPLIER / iWorld; -- -100 = we are at 0, 0 = we are average, +100 = we are 2x as average, +200 = we are 3x as average, etc.
			iPriority = iPriority + iRatio; -- This will add between -100 and 100 depending on this player's MilitaryStrength relative the world average. The number will typically be near 0 though, as it's fairly hard to get away from the world average
			print("...culture ratio", iRatio, "player/world", pPlayer:GetCulture():GetCultureYield(), iWorld, "priority=", iPriority);
		end
	end
	
	--iPriority = iPriority + RST.PlayerGetTourism(ePlayerID) * GlobalParameters.RST_CULTURE_TOURISM_WEIGHT / 100.0;
	--print("...added tourism yield, yield", RST.PlayerGetTourism(ePlayerID), "priority=", iPriority);
	
	-- How many turns must have passed before we test for us against others
	-- Tourism is hard to come by early - maybe we should wait longer?
	if data.Data.ElapsedTurns >= GlobalParameters.RST_STRATEGY_COMPARE_OTHERS_NUM_TURNS then
		-- Compare our tourism output to the rest of the world
		local iWorld:number = data.Data.AvgTourism; -- * 100 / (100 + math.max(0,(data.Data.NumCivsConverted-1)) * 10); -- ??????
		if iWorld > 0 then
			local iRatio:number = (RST.PlayerGetTourism(ePlayerID) - iWorld) * GlobalParameters.RST_CULTURE_TOURISM_RATIO_MULTIPLIER / iWorld; -- -100 = we are at 0, 0 = we are average, +100 = we are 2x as average, +200 = we are 3x as average, etc.
			iPriority = iPriority + iRatio; -- This will add between -100 and 100 depending on this player's MilitaryStrength relative the world average. The number will typically be near 0 though, as it's fairly hard to get away from the world average
			print("...tourism ratio", iRatio, "player/world", RST.PlayerGetTourism(ePlayerID), iWorld, "priority=", iPriority);
		end
	end
	
	
	-- in Civ5 it is influential - 50 pts. per civ getAI_GS_CULTURE_INFLUENTIAL_CIV_MOD
	-- also similar algorithm to check if we are ahead or behind - it used pure yields however, not policies or similar
	-- can't use - no info on civics available! no cheating!
	-- simple idea - the more % we have, the more it adds
	iPriority = iPriority + GlobalParameters.RST_CULTURE_PROGRESS_MULTIPLIER * (math.exp(RST.PlayerGetCultureVictoryProgress(ePlayerID) * GlobalParameters.RST_CULTURE_PROGRESS_EXPONENT / 100.0) - 1.0);
	print("...added cultural progress, perc%", RST.PlayerGetCultureVictoryProgress(ePlayerID), "priority=", iPriority);
	
	-- PICKLE here: no holding back! what could be the negative?
	
	--print("GetPriorityCulture:", iPriority);
	return iPriority;
end


------------------------------------------------------------------------------
-- Specific: RELIGION
function GetPriorityReligion(data:table)
	--print("FUN GetPriorityReligion", data.PlayerID, data.LeaderType);
	-- check if this victory type is enabled
	if not RST.GameIsVictoryEnabled("VICTORY_RELIGIOUS") then return -100; end
	
	local iPriority:number = 0;
	local ePlayerID:number = data.PlayerID;
	local pPlayer:table = Players[ePlayerID];
	
	-- check if we can have a religion at all (Kongo)
	-- simple version, complex one should check ExcludedGreatPersonClasses and ExcludedDistricts, then Trait and then Leader :(
	if data.LeaderType == "LEADER_MVEMBA" then -- TRAIT_LEADER_RELIGIOUS_CONVERT
		print("This is Kongo - no religious victory");
		return -100;
	end
	
	-- first, check if we have a religion
	if data.Data.ReligionID == -1 or data.Data.ReligionID == GameInfo.Religions.RELIGION_PANTHEON.Index then
		print("...we don't have a religion");
		-- we don't have a religion - abandon this victory if we cannot get one
		if #Game.GetReligion():GetReligions() >= iMaxNumReligions then
			print("...and we cannot get one - no religious victory");
			return -100;
		end
	else
		--if data.Data.ReligionID ~= GameInfo.Religions.RELIGION_PANTHEON.Index then
		iPriority = iPriority + GlobalParameters.RST_RELIGION_RELIGION_WEIGHT;
		print("...religion founded", data.Data.ReligionID, "priority=", iPriority);
	end

	-- check number of beliefs - done even better in generic because it weights with flavors
	--iPriority = iPriority + RST.PlayerGetNumBeliefsEarned(ePlayerID) * GlobalParameters.RST_RELIGION_BELIEF_WEIGHT;
	--print("...added num beliefs, num", RST.PlayerGetNumBeliefsEarned(ePlayerID), "priority=", iPriority);
	
	-- faith yield - change to comparison to average?
	--iPriority = iPriority + pPlayer:GetReligion():GetFaithYield() * GlobalParameters.RST_RELIGION_FAITH_YIELD_WEIGHT / 100.0;
	--print("...added faith yield, yield", pPlayer:GetReligion():GetFaithYield(), "priority=", iPriority);

	-- How many turns must have passed before we test for us against others
	if data.Data.ElapsedTurns >= GlobalParameters.RST_STRATEGY_COMPARE_OTHERS_NUM_TURNS then
		-- Compare our faith output to the rest of the world
		-- Reduce world average if we're rocking multiple converts (VP specific) - not counting ourselves
		local iWorld:number = data.Data.AvgFaith * 100 / (100 + math.max(0,(data.Data.NumCivsConverted-1)) * 10); -- ??????
		if iWorld > 0 then
			local iRatio:number = (pPlayer:GetReligion():GetFaithYield() - iWorld) * GlobalParameters.RST_RELIGION_FAITH_RATIO_MULTIPLIER / iWorld; -- -100 = we are at 0, 0 = we are average, +100 = we are 2x as average, +200 = we are 3x as average, etc.
			iPriority = iPriority + iRatio; -- This will add between -100 and 100 depending on this player's MilitaryStrength relative the world average. The number will typically be near 0 though, as it's fairly hard to get away from the world average
			print("...faith ratio", iRatio, "player/world", pPlayer:GetReligion():GetFaithYield(), iWorld, "priority=", iPriority);
		end
		iWorld = data.Data.AvgCities;
		if iWorld > 0 then
			local iRatio:number = (RST.PlayerGetNumCitiesFollowingReligion(ePlayerID) - iWorld) * GlobalParameters.RST_RELIGION_CITIES_RATIO_MULTIPLIER / iWorld; -- -100 = we are at 0, 0 = we are average, +100 = we are 2x as average, +200 = we are 3x as average, etc.
			iPriority = iPriority + iRatio; -- This will add between -100 and 100 depending on this player's MilitaryStrength relative the world average. The number will typically be near 0 though, as it's fairly hard to get away from the world average
			print("...cities ratio", iRatio, "player/world", RST.PlayerGetNumCitiesFollowingReligion(ePlayerID) , iWorld, "priority=", iPriority);
		end
	end
	
	-- early game, if we haven't met any Major Civs yet, then we probably shouldn't be planning on conquering the world with our religion - see also Conquest
	if data.Data.ElapsedTurns >= GlobalParameters.RST_RELIGION_NOBODY_MET_NUM_TURNS then
		if data.Data.NumMajorsAliveAndMet == 0 then 
			iPriority = iPriority + GlobalParameters.RST_RELIGION_NOBODY_MET_PRIORITY;
			print("...turn", Game.GetCurrentGameTurn(), "no majors met, priority=", iPriority);
		end
	end

	
	-- WorldRankings displays how many civs were converted
	if data.Data.NumCivsConverted > 1 then
		iPriority = iPriority + (data.Data.NumCivsConverted-1) * GlobalParameters.RST_RELIGION_CONVERTED_WEIGHT;
		print("...converted >1 civs, num", data.Data.NumCivsConverted , "priority=", iPriority);
	end

	-- each inqusition launched decreases the priority [cheating?] - REMOVE????
	-- there is another way - since religious units may enter, then just OBSERVE if there are Inqusitors!
	-- need 2 checks, one on TurnBegin and then TurnEnd and this flag goes to Stored! once detected, there is no need to do so anymore
	-- HINT: this is like being at war with conquest??? - maybe we should boost it actually?
	for _,otherID in ipairs(data.Data.MajorIDsAliveAndMet) do
		if Players[otherID]:GetReligion():HasLaunchedInquisition() then
			print("...player", otherID, "has launched inqusition");
			iPriority = iPriority + GlobalParameters.RST_RELIGION_INQUISITION_WEIGHT;
		end
	end
	
	--print("GetPriorityReligion:", iPriority);
	return iPriority;
end


------------------------------------------------------------------------------
-- Specific: DIPLO
function GetPriorityDiplo(data:table)
	--print("FUN GetPriorityDiplo");
	
	-- VP alorithm
	-- Add in our base gold value. iPriorityBonus += (m_pPlayer->GetTreasury()->CalculateBaseNetGold() / 25);
	-- adds Paper from Alliances
	-- policies & buildings & religion
	-- votes controlled - checks for allied City States
	-- it compares with the 2nd highest 
	-- calculates votes needed to win
	-- if we control >50%, then boosts *5, >75% boosts *10

	return 0;
end

function GetPriorityDefense(data:table)
	--print("FUN GetPriorityDefense");
	return 0;
end


------------------------------------------------------------------------------
-- Get the base Priority for a Grand Strategy; these are elements common to ALL Grand Strategies
-- Base Priority looks at Personality Flavors (0 - 10) and multiplies * the Flavors attached to a Grand Strategy (0-10),
-- so expect a number between 0 and 100 back from this
function EstablishStrategyBasePriority(data:table)
	print(Game.GetCurrentGameTurn(), "FUN EstablishStrategyBasePriority", data.PlayerID, data.LeaderType);
	data.Priorities = PriorityTableNew();
	--if tPriorities["BasePriority"] == nil then
		--print("WARNING: BasePriority table not defined."); return;
	--end
	if tPriorities[data.LeaderType] == nil then
		print("WARNING: Priorities table for leader", data.LeaderType, "not defined."); return;
	end
	-- multiply Leader flavors by base priority weight
	PriorityTableAdd(data.Priorities, tPriorities[data.LeaderType].Priorities);
	PriorityTableMultiply(data.Priorities, GlobalParameters.RST_WEIGHT_LEADER);
	--print("...base priorities for leader", data.LeaderName);
	dshowpriorities(data.Priorities, "*** base priorities "..data.LeaderType);
	
	-- the later the game the greater the chance
	local tEraBiasPriorities:table = PriorityTableNew();
	PriorityTableAdd(tEraBiasPriorities, tPriorities[data.LeaderType].Priorities);
	PriorityTableMultiply(tEraBiasPriorities, data.Data.Era * GlobalParameters.RST_STRATEGY_LEADER_ERA_BIAS / 100.0);
	--print("...era bias for era", data.Data.Era); --Players[data.PlayerID]:GetEra());
	dshowpriorities(tEraBiasPriorities, "era bias for era "..tostring(data.Data.Era));
	
	--print("EstablishStrategyBasePriority:");
	PriorityTableAdd(data.Priorities, tEraBiasPriorities);
	dshowpriorities(data.Priorities, "EstablishStrategyBasePriority");
end


------------------------------------------------------------------------------
-- Main function
function RefreshAndProcessData(ePlayerID:number)
	--print(Game.GetCurrentGameTurn(), "FUN RefreshAndProcessData", ePlayerID);
	
	-- do all pre-checks so others won't have to
	local pPlayer:table = Players[ePlayerID];
	if not (pPlayer ~= nil and pPlayer:IsAlive() and pPlayer:IsMajor()) then return; end
	
	-- check if data needs to be refreshed
	local data:table = tData[ePlayerID];
	--if not data.Dirty then return; end
	if data.TurnRefresh == Game.GetCurrentGameTurn() then return; end -- we already refreshed on this turn

	-- active turns with game speed scaling
	local iNumTurnsActive:number = (Game.GetCurrentGameTurn() - data.TurnRefresh) * 100 / GameInfo.GameSpeeds[GameConfiguration.GetGameSpeedType()].CostMultiplier;
	--print(Game.GetCurrentGameTurn(), data.LeaderType, "...current strategy", data.ActiveStrategy, "turn refresh", data.TurnRefresh, "active for", iNumTurnsActive, "turns");
	if not( data.TurnRefresh == -1 or data.ActiveStrategy == "NONE" or iNumTurnsActive >= GlobalParameters.RST_STRATEGY_NUM_TURNS_MUST_BE_ACTIVE ) then
		return
	end
	
	-- we should go here if: TurnRefresh == -1, ActiveStrategy == "NONE", or current strategy needs to be refreshed after being active for X turns
	RefreshPlayerData(data);
	
	-- Base Priority looks at Personality Flavors (0 - 10) and multiplies * the Flavors attached to a Grand Strategy (0-10),
	-- so expect a number between 0 and 100 back from this
	EstablishStrategyBasePriority(data);
	
	-- Loop through all GrandStrategies to set their Priorities
	-- specific conditions - TODO: can this be expandable? like Lua function as a parameter
	--                       TODO: if objects were used, then data would be self and functions would look like self:GetPriorityConquest()
	local tSpecificPriorities:table = PriorityTableNew();
	tSpecificPriorities.CONQUEST = GetPriorityConquest(data);
	tSpecificPriorities.SCIENCE  = GetPriorityScience(data);
	tSpecificPriorities.CULTURE  = GetPriorityCulture(data);
	tSpecificPriorities.RELIGION = GetPriorityReligion(data);
	tSpecificPriorities.DIPLO    = GetPriorityDiplo(data);
	tSpecificPriorities.DEFENSE  = GetPriorityDefense(data);
	--tSpecificPriorities.NAVAL  = GetPriorityNaval(data);
	--tSpecificPriorities.TRADE  = GetPriorityTrade(data);
	--print("...specific priorities for leader", data.LeaderName);
	dshowpriorities(tSpecificPriorities, "*** specific priorities "..data.LeaderType);
	
	-- add generic to specific priorities
	PriorityTableAdd(tSpecificPriorities, GetGenericPriorities(data));
	
	-- reduce the potency of these until the mid game.
	-- Civ5 just uses MaxTurn, but for Cv6 it won't work - TODO: use Num of techs / civics just as for District costs
	-- int MaxTurn = GC.getGame().getEstimateEndTurn();
	local iMaxTurn:number = RST.GameGetMaxGameTurns();
	local iCurrentTurn:number = Game.GetCurrentGameTurn();
	local fTurnAdjust:number = GlobalParameters.RST_STRATEGY_TURN_ADJUST_START + (GlobalParameters.RST_STRATEGY_TURN_ADJUST_STOP - GlobalParameters.RST_STRATEGY_TURN_ADJUST_START) * iCurrentTurn / iMaxTurn;
	dprint("...game turn adjustment (iMaxT,iCurT,perc)", iMaxTurn, iCurrentTurn, fTurnAdjust);
	--PriorityTableMultiply(tSpecificPriorities, iCurrentTurn * 2 / iMaxTurn); -- effectively, it gives 100% at half the game and scales linearly
	PriorityTableMultiply(tSpecificPriorities, fTurnAdjust/100.0); -- it scales lineary from _START to _STOP value during the game
	--print("...specific and generic priorities after turn adjustment for leader", data.LeaderName);
	dshowpriorities(tSpecificPriorities, "specific & generic after turn adjust");
	
	--print("...applying specific priorities", data.LeaderName);
	PriorityTableAdd(data.Priorities, tSpecificPriorities);
	dshowpriorities(data.Priorities, "applying specific priorities");
	
	-- random element
	for strat,value in pairs(data.Priorities) do
		data.Priorities[strat] = value + math.random(0,GlobalParameters.RST_STRATEGY_RANDOM_PRIORITY); -- AI_GS_RAND_ROLL
	end
	--print("...applying a bit of randomization", data.LeaderName);
	dshowpriorities(data.Priorities, "applying a bit of randomization");
	
	-- Give a boost to the current strategy so that small fluctuation doesn't cause a big change
	if data.ActiveStrategy ~= "NONE" then
		--print("...boosting current strategy", data.ActiveStrategy);
		data.Priorities[data.ActiveStrategy] = data.Priorities[data.ActiveStrategy] + math.random(GlobalParameters.RST_STRATEGY_CURRENT_PRIORITY/2, GlobalParameters.RST_STRATEGY_CURRENT_PRIORITY); -- AI_GRAND_STRATEGY_CURRENT_STRATEGY_WEIGHT
		dshowpriorities(data.Priorities, "boosting current strategy "..data.ActiveStrategy);
	end
			
	-- Tally up how many players we think are pursuing each Grand Strategy
	local tBetterNum:table = PriorityTableNew();
	for _,otherID in ipairs(data.Data.MajorIDsAliveAndMet) do
		local sOtherStrategy:string = GuessOtherPlayerStrategy(data, otherID); -- WARNING! can they pursue 2 strategies? if so, make changes here!
		if sOtherStrategy ~= "NONE" then -- and sOtherStrategy == data.ActiveStrategy then -- we need to compare all, not only active!
			if OtherPlayerDoingBetterThanUs(data, otherID, sOtherStrategy) then
				print("...player", otherID, "is doing better than us with", sOtherStrategy);
				tBetterNum[sOtherStrategy] = tBetterNum[sOtherStrategy] + 1;
			end
		end
	end
	dshowpriorities(tBetterNum, "num players better than us");
	
	-- Now modify our preferences based on how many people are going for stuff
	-- For each player following the strategy and being better than us, reduce our priority by 33%
	local tNerfFactor:table = PriorityTableNew();
	PriorityTableAdd(tNerfFactor, data.Priorities); -- copy
	PriorityTableMultiply(tNerfFactor, GlobalParameters.RST_STRATEGY_BETTER_THAN_US_NERF/100.0);
	PriorityTableMultiplyByTable(tNerfFactor, tBetterNum);
	dshowpriorities(tNerfFactor, "nerf factors");
	
	--print("...final priorities", data.LeaderName);
	PriorityTableAdd(data.Priorities, tNerfFactor);
	dshowpriorities(data.Priorities, "*** final priorities "..data.LeaderType);
	
	-- Now see which Grand Strategy should be active, based on who has the highest Priority right now
	local iBestPriority:number = GlobalParameters.RST_STRATEGY_MINIMUM_PRIORITY; -- minimum score to activate a strategy
	for strat,value in pairs(data.Priorities) do
		if value > iBestPriority then
			iBestPriority = value;
			data.ActiveStrategy = strat;
			--data.NumTurnsActive = 0;
		end
	end
	
	-- finish
	--if data.ActiveStrategy ~= "NONE" then
		--data.NumTurnsActive = data.NumTurnsActive + 1
	--end
	--data.Dirty = false; -- data is refreshed
	data.TurnRefresh = Game.GetCurrentGameTurn(); -- data is refreshed
	print(Game.GetCurrentGameTurn(), data.LeaderType, "...selected", data.ActiveStrategy, "priority", iBestPriority);
	
	-- log strategy to Log.lua
	if bOptionLogStrat then
		local tLog:table = {};
		table.insert(tLog, tostring(Game.GetCurrentGameTurn()));
		table.insert(tLog, "RSTSTRAT");
		table.insert(tLog, data.LeaderType);
		table.insert(tLog, string.format("%s @ %4.1f", data.ActiveStrategy, iBestPriority)); -- guessed strategy
		for _,strat in ipairs(tShowStrat) do -- others for reference, only ones defined in tShowStrat, also include nerfs!
			local tStr:string = string.format("%s @ %4.1f", strat, data.Priorities[strat]);
			if tNerfFactor[strat] ~= 0 then tStr = tStr..string.format(" (%4.1f)", tNerfFactor[strat]); end
			table.insert(tLog, tStr);
		end 
		print(table.concat(tLog, ", "));
	end
	
	--dshowrectable(tData[ePlayerID]); -- show all info
end


------------------------------------------------------------------------------
-- What others are doing?
-- This is a simplified version of main algorithms that uses only part of the information
-- (1) Leader affinity - ok, once we know who we are dealing with - human player learns that (a bit of metagaming, but it is fair)
-- (2) Victory-related stuff (yields, techs, capitals, converted civs
-- (3) Specific - government type, religion, science projects

------------------------------------------------------------------------------
function GetOtherPlayerPriorityConquest(data:table, eOtherID:number)
	--print("FUN GetOtherPlayerPriorityConquest", data.LeaderType, eOtherID);
	-- check if this victory type is enabled
	if not RST.GameIsVictoryEnabled("VICTORY_CONQUEST") then return -100; end
	
	local iPriority:number = 0;
	local ePlayerID:number = data.PlayerID;

	-- VP includes info about attacked and captured minors
	
	-- include captured capitals
	local iNumCapturedCapitals:number = RST.PlayerGetNumCapturedCapitals(eOtherID);
	--if iNumCapturedCapitals > 1 then
	iPriority = iPriority + GlobalParameters.RST_CONQUEST_CAPTURED_CAPITAL_PRIORITY * iNumCapturedCapitals;
	--end
	print("...other player has captured", iNumCapturedCapitals, "capitals; priority=", iPriority);
	
	-- Compare his military strength to the rest of the world
	local iWorldMilitaryStrength:number = RST.GameGetAverageMilitaryStrength(ePlayerID); -- include us and only known
	-- Reduce world average if he's rocking multiple capitals (VP specific)
	iWorldMilitaryStrength = iWorldMilitaryStrength * 100 / (100 + iNumCapturedCapitals * 10); -- ??????
	if iWorldMilitaryStrength > 0 then
		local iMilitaryRatio:number = (RST.PlayerGetMilitaryStrength(eOtherID) - iWorldMilitaryStrength) * GlobalParameters.RST_CONQUEST_POWER_RATIO_MULTIPLIER / iWorldMilitaryStrength; -- -100 = we are at 0, 0 = we are average, +100 = we are 2x as average, +200 = we are 3x as average, etc.
		-- Make the likelihood of BECOMING a warmonger lower than dropping the bad behavior
		--iMilitaryRatio = math.floor(iMilitaryRatio / 2); -- should be the same as setting param to 50
		--if iMilitaryRatio > 0 then -- let's not use negative priorities as for now
		iPriority = iPriority + iMilitaryRatio; -- This will add between -100 and 100 depending on this player's MilitaryStrength relative the world average. The number will typically be near 0 though, as it's fairly hard to get away from the world average
		--end
		print("...military ratio", iMilitaryRatio, "player/world", RST.PlayerGetMilitaryStrength(eOtherID), iWorldMilitaryStrength, "priority=", iPriority);
	end

	-- interesting, VP uses also "Warmonger threat" from Diplomacy! not sure if this can be extracted easily in Civ6
	-- InGame: Player	GetDiplomacy	GetWarmongerLevel
	
	--print("GetOtherPlayerPriorityConquest", iPriority);
	return iPriority;
end


------------------------------------------------------------------------------
function GetOtherPlayerPriorityScience(data:table, eOtherID:number)
	--print("FUN GetOtherPlayerPriorityScience", data.LeaderType, eOtherID);
	-- check if this victory type is enabled
	if not RST.GameIsVictoryEnabled("VICTORY_TECHNOLOGY") then return -100; end
	
	local iPriority:number = 0;
	local ePlayerID:number = data.PlayerID;
	local pOther:table = Players[eOtherID];

	-- if he already completed some projects, he is very likely to follow through
	local iSpaceRaceProjects:number = PlayerGetNumProjectsSpaceRace(eOtherID);
	iPriority = iPriority + iSpaceRaceProjects * GlobalParameters.RST_SCIENCE_PROJECT_WEIGHT;
	print("...space race projects", iSpaceRaceProjects, "priority=", iPriority);

	-- Add in his base science value.
	--iPriority = iPriority + pOther:GetTechs():GetScienceYield() * GlobalParameters.RST_SCIENCE_YIELD_WEIGHT / 100.0;
	--print("...added science yield, yield", pOther:GetTechs():GetScienceYield(), "priority=", iPriority);
	
	-- VP uses an algorithm based on civ relative position in a pack by num of techs AI_GS_CULTURE_AHEAD_WEIGHT=50 - max that we can get from that
	-- seems ok however it doesn't account for how much we are ahead (or behind)
	-- similar approach to relative power - get average techs and if we are ahead, then add some weight
	-- also, account for late game - being ahead should be more valued then?
	-- num_techs_better_than_avg * per_tech
	-- no era adjustment here - if we are doing good, our position will only get better plus yield will matter more
	-- How many turns must have passed before we test for us having a weak military?

	-- Compare our num techs to the rest of the world
	--[[
	local iWorldNumTechs:number = RST.GameGetAverageNumTechsResearched(ePlayerID); --, true, true); -- include us and only known
	if iWorldNumTechs > 0 then
		-- the PICKLE here: when we are behind, we get a negative value - it is not the case with Culture nor Religion
		local iTechBoost:number = (RST.PlayerGetNumTechsResearched(eOtherID) - iWorldNumTechs) * GlobalParameters.RST_SCIENCE_TECH_WEIGHT;
		if iTechBoost > 0 then -- let's not use negatives yet
			iPriority = iPriority + iTechBoost;
		end
		print("...tech boost", iTechBoost, "player/world", RST.PlayerGetNumTechsResearched(eOtherID), iWorldNumTechs, "priority=", iPriority);
	end
	--]]
	-- How many turns must have passed before we test for us against others
	
	-- Compare his science output to the rest of the world
	-- Reduce world average if he's completed some space race projects (VP specific)
	local iWorld:number = data.Data.AvgScience * 100 / (100 + iSpaceRaceProjects * 10);
	if iWorld > 0 then
		local iRatio:number = (pOther:GetTechs():GetScienceYield() - iWorld) * GlobalParameters.RST_SCIENCE_YIELD_RATIO_MULTIPLIER / iWorld; -- -100 = we are at 0, 0 = we are average, +100 = we are 2x as average, +200 = we are 3x as average, etc.
		iPriority = iPriority + iRatio; -- This will add between -100 and 100 depending on this player's yield relative the world average.
		print("...science ratio", iRatio, "player/world", pOther:GetTechs():GetScienceYield(), iWorld, "priority=", iPriority);
	end

	-- Compare our num techs to the rest of the world
	iWorld = data.Data.AvgTechs;
	if iWorld > 0 then
		local iRatio:number = (RST.PlayerGetNumTechsResearched(eOtherID) - iWorld) * (GlobalParameters.RST_SCIENCE_TECH_RATIO_MULTIPLIER + 3 * iWorld) / iWorld; -- slightly modified formula, adding 3*World prevents the diff from diminishing too quickly!
		iPriority = iPriority + iRatio;
		print("...tech ratio", iRatio, "player/world", RST.PlayerGetNumTechsResearched(eOtherID), iWorld, "priority=", iPriority);
	end

	--print("GetOtherPlayerPriorityScience:", iPriority);
	return iPriority;
end


------------------------------------------------------------------------------
function GetOtherPlayerPriorityCulture(data:table, eOtherID:number)
	--print("FUN GetOtherPlayerPriorityCulture", data.LeaderType, eOtherID);
	-- check if this victory type is enabled
	if not RST.GameIsVictoryEnabled("VICTORY_CULTURE") then return -100; end
	
	local iPriority:number = 0;
	local ePlayerID:number = data.PlayerID;
	local pOther:table = Players[eOtherID];

	-- Add in our base culture and tourism value
	-- VP uses /240 for culture = 3,3%, late game is getting into 5000+ => 20 pts || Civ6 ~500
	-- VP uses /1040 for tourism = 0,8%, late game is getting into 1000+ => 1 pts (?) || Civ6 ~500
	--iPriority = iPriority + pOther:GetCulture():GetCultureYield() * GlobalParameters.RST_CULTURE_YIELD_WEIGHT / 100.0;
	--print("...added culture yield, yield", pOther:GetCulture():GetCultureYield(), "priority=", iPriority);
	--iPriority = iPriority + RST.PlayerGetTourism(eOtherID) * GlobalParameters.RST_CULTURE_TOURISM_WEIGHT / 100.0;
	--print("...added tourism yield, yield", RST.PlayerGetTourism(eOtherID), "priority=", iPriority);

	-- Compare our culture output to the rest of the world
	local iWorld:number = data.Data.AvgCulture;
	if iWorld > 0 then
		local iRatio:number = (pOther:GetCulture():GetCultureYield() - iWorld) * GlobalParameters.RST_CULTURE_YIELD_RATIO_MULTIPLIER / iWorld; -- -100 = we are at 0, 0 = we are average, +100 = we are 2x as average, +200 = we are 3x as average, etc.
		iPriority = iPriority + iRatio; -- This will add between -100 and 100 depending on this player's MilitaryStrength relative the world average. The number will typically be near 0 though, as it's fairly hard to get away from the world average
		print("...culture ratio", iRatio, "player/world", pOther:GetCulture():GetCultureYield(), iWorld, "priority=", iPriority);
	end

	-- Compare our tourism output to the rest of the world
	iWorld = data.Data.AvgTourism;
	if iWorld > 0 then
		local iRatio:number = (RST.PlayerGetTourism(eOtherID) - iWorld) * GlobalParameters.RST_CULTURE_TOURISM_RATIO_MULTIPLIER / iWorld; -- -100 = we are at 0, 0 = we are average, +100 = we are 2x as average, +200 = we are 3x as average, etc.
		iPriority = iPriority + iRatio; -- This will add between -100 and 100 depending on this player's MilitaryStrength relative the world average. The number will typically be near 0 though, as it's fairly hard to get away from the world average
		print("...tourism ratio", iRatio, "player/world", RST.PlayerGetTourism(eOtherID), iWorld, "priority=", iPriority);
	end

	-- in Civ5 it is influential - 50 pts. per civ getAI_GS_CULTURE_INFLUENTIAL_CIV_MOD
	-- also similar algorithm to check if we are ahead or behind - it used pure yields however, not policies or similar
	-- can't use - no info on civics available! no cheating!
	-- simple idea - the more % we have, the more it adds
	iPriority = iPriority + GlobalParameters.RST_CULTURE_PROGRESS_MULTIPLIER * (math.exp(RST.PlayerGetCultureVictoryProgress(eOtherID) * GlobalParameters.RST_CULTURE_PROGRESS_EXPONENT / 100.0) - 1.0);
	print("...added cultural progress, perc%", RST.PlayerGetCultureVictoryProgress(eOtherID), "priority=", iPriority);
	
	--print("GetOtherPlayerPriorityCulture:", iPriority);
	return iPriority;
end


------------------------------------------------------------------------------
function GetOtherPlayerPriorityReligion(data:table, eOtherID:number)
	--print("FUN GetOtherPlayerPriorityReligion", data.LeaderType, eOtherID);
	-- check if this victory type is enabled
	if not RST.GameIsVictoryEnabled("VICTORY_RELIGIOUS") then return -100; end
	
	local iPriority:number = 0;
	local ePlayerID:number = data.PlayerID;
	local pOther:table = Players[eOtherID];
	
	-- check if we can have a religion at all (Kongo)
	-- simple version, complex one should check ExcludedGreatPersonClasses and ExcludedDistricts, then Trait and then Leader :(
	if PlayerConfigurations[eOtherID]:GetLeaderTypeName() == "LEADER_MVEMBA" then -- TRAIT_LEADER_RELIGIOUS_CONVERT
		print("This is Kongo - no religious victory");
		return -100;
	end
	
	-- first, check if he has religion
	local eReligionID:number = RST.PlayerGetReligionTypeCreated(eOtherID); -- pOther:GetReligion():GetReligionTypeCreated();
	if eReligionID == -1 or eReligionID == GameInfo.Religions.RELIGION_PANTHEON.Index then
		print("...he doesn't have a religion");
		-- we don't have a religion - abandon this victory if we cannot get one
		if #Game.GetReligion():GetReligions() >= iMaxNumReligions then
			print("...and he cannot get one - no religious victory");
			return -100;
		end
	else
		iPriority = iPriority + GlobalParameters.RST_RELIGION_RELIGION_WEIGHT;
		print("...religion founded", eReligionID, "priority=", iPriority);
	end

	-- check number of beliefs
	--iPriority = iPriority + RST.PlayerGetNumBeliefsEarned(eOtherID) * GlobalParameters.RST_RELIGION_BELIEF_WEIGHT;
	--print("...added num beliefs, num", RST.PlayerGetNumBeliefsEarned(eOtherID), "priority=", iPriority);
	
	-- faith yield - change to comparison to average?
	--iPriority = iPriority + pOther:GetReligion():GetFaithYield() * GlobalParameters.RST_RELIGION_FAITH_YIELD_WEIGHT / 100.0;
	--print("...added faith yield, yield", pOther:GetReligion():GetFaithYield(), "priority=", iPriority);
	
	-- WorldRankings displays how many civs were converted
	local iNumCivsConverted:number = PlayerGetNumCivsConverted(eOtherID);
	if iNumCivsConverted > 1 then
		iPriority = iPriority + (iNumCivsConverted-1) * GlobalParameters.RST_RELIGION_CONVERTED_WEIGHT;
		print("...converted >1 civs, num", iNumCivsConverted , "priority=", iPriority);
	end
	
	-- Compare our faith output to the rest of the world
	-- Reduce world average if he's rocking multiple converts (VP specific) - not counting ourselves
	local iWorld:number = data.Data.AvgFaith * 100 / (100 + math.max(0,(iNumCivsConverted-1)) * 10);
	if iWorld > 0 then
		local iRatio:number = (pOther:GetReligion():GetFaithYield() - iWorld) * GlobalParameters.RST_RELIGION_FAITH_RATIO_MULTIPLIER / iWorld; -- -100 = we are at 0, 0 = we are average, +100 = we are 2x as average, +200 = we are 3x as average, etc.
		iPriority = iPriority + iRatio; -- This will add between -100 and 100 depending on this player's MilitaryStrength relative the world average. The number will typically be near 0 though, as it's fairly hard to get away from the world average
		print("...faith ratio", iRatio, "player/world", pOther:GetReligion():GetFaithYield(), iWorld, "priority=", iPriority);
	end
	iWorld = data.Data.AvgCities;
	if iWorld > 0 then
		local iRatio:number = (RST.PlayerGetNumCitiesFollowingReligion(eOtherID) - iWorld) * GlobalParameters.RST_RELIGION_CITIES_RATIO_MULTIPLIER / iWorld; -- -100 = we are at 0, 0 = we are average, +100 = we are 2x as average, +200 = we are 3x as average, etc.
		iPriority = iPriority + iRatio; -- This will add between -100 and 100 depending on this player's MilitaryStrength relative the world average. The number will typically be near 0 though, as it's fairly hard to get away from the world average
		print("...cities ratio", iRatio, "player/world", RST.PlayerGetNumCitiesFollowingReligion(eOtherID) , iWorld, "priority=", iPriority);
	end

	--print("GetOtherPlayerPriorityReligion:", iPriority);
	return iPriority;
end


------------------------------------------------------------------------------
function GuessOtherPlayerStrategy(data:table, eOtherID:number)
	print(Game.GetCurrentGameTurn(), "FUN GuessOtherPlayerStrategy", data.PlayerID, eOtherID);
	
	local sLeaderType:string = PlayerConfigurations[eOtherID]:GetLeaderTypeName();
	-- get leader but with 66% factor
	--[[ ABANDONED - this early game weights too much, actual results are insignificant!
	local tLeaderPriorities:table = PriorityTableNew();
	if tPriorities[sLeaderType] == nil then
		print("WARNING: Priorities for leader", sLeaderType, "not defined.");
	else
		PriorityTableAdd(tLeaderPriorities, tPriorities[sLeaderType].Priorities);
	end
	-- multiply Leader flavors by base priority weight
	PriorityTableMultiply(tLeaderPriorities, (2/3) * GlobalParameters.RST_WEIGHT_LEADER);
	dshowpriorities(tLeaderPriorities, "*** leader priorities "..sLeaderType);
	
	-- the later the game the greater the chance
	local tEraBiasPriorities:table = PriorityTableNew();
	PriorityTableAdd(tEraBiasPriorities, tPriorities[sLeaderType].Priorities);
	PriorityTableMultiply(tEraBiasPriorities, data.Data.Era * (2/3) * GlobalParameters.RST_STRATEGY_LEADER_ERA_BIAS / 100.0);
	dshowpriorities(tEraBiasPriorities, "era bias for era "..tostring(data.Data.Era));
	--]]

	-- get specifics
	local tSpecificPriorities:table = PriorityTableNew();
	tSpecificPriorities.CONQUEST = GetOtherPlayerPriorityConquest(data, eOtherID);
	tSpecificPriorities.SCIENCE  = GetOtherPlayerPriorityScience(data, eOtherID);
	tSpecificPriorities.CULTURE  = GetOtherPlayerPriorityCulture(data, eOtherID);
	tSpecificPriorities.RELIGION = GetOtherPlayerPriorityReligion(data, eOtherID);
	--tSpecificPriorities.DIPLO    = GetPriorityDiplo(data);
	--tSpecificPriorities.DEFENSE  = GetPriorityDefense(data);
	--tSpecificPriorities.NAVAL  = GetPriorityNaval(data);
	--tSpecificPriorities.TRADE  = GetPriorityTrade(data);
	dshowpriorities(tSpecificPriorities, "*** specific priorities "..sLeaderType);
	
	-- GOVERNMENT
	--print("...generic: government", sLeaderType);
	local sGovType:string = GameInfo.Governments[ RST.PlayerGetCurrentGovernment(eOtherID) ].GovernmentType;
	local tGovPriorities:table = PriorityTableNew();
	if tPriorities[sGovType] then PriorityTableAdd(tGovPriorities, tPriorities[sGovType].Priorities);
	else                          print("WARNING: government", sGovType, "not defined in Priorities"); end
	PriorityTableMultiply(tGovPriorities, GlobalParameters.RST_WEIGHT_GOVERNMENT);
	dshowpriorities(tGovPriorities, "generic government "..string.gsub(sGovType, "GOVERNMENT_", ""));
	
	-- CITY STATES
	--print("...generic: city states", sLeaderType);
	local tMinorPriorities:table = PriorityTableNew();
	for _,minor in ipairs(PlayerManager.GetAliveMinors()) do
		if minor:GetInfluence():GetSuzerain() == eOtherID then
			local sCategory:string = GetCityStateCategory(minor:GetID());
			--print("...suzerain of", sCategory);
			PriorityTableAdd(tMinorPriorities, tPriorities[sCategory].Priorities);
		end
	end
	PriorityTableMultiply(tMinorPriorities, GlobalParameters.RST_WEIGHT_MINOR);
	dshowpriorities(tMinorPriorities, "generic city states");
	
	-- randomize, but less
	local tRandPriorities:table = PriorityTableNew();
	for strat,value in pairs(tRandPriorities) do
		tRandPriorities[strat] = math.random(0, GlobalParameters.RST_STRATEGY_RANDOM_PRIORITY * 0.5);
	end
	dshowpriorities(tRandPriorities, "randomization");
	
	local tSumPriorities:table = PriorityTableNew(); -- final here
	PriorityTableAdd(tSumPriorities, tSpecificPriorities);
	PriorityTableAdd(tSumPriorities, tGovPriorities);
	PriorityTableAdd(tSumPriorities, tMinorPriorities);
	--dshowpriorities(tSumPriorities, "specific & generic "..sLeaderType);
	
	-- reduce the potency of these until the mid game.
	--[[ not neceassary since leader is out
	local iMaxTurn:number = RST.GameGetMaxGameTurns();
	local iCurrentTurn:number = Game.GetCurrentGameTurn();
	dprint("...game turn adjustment (iMaxT,iCurT,perc)", iMaxTurn, iCurrentTurn, iCurrentTurn * 2 / iMaxTurn);
	PriorityTableMultiply(tSumPriorities, iCurrentTurn * 2 / iMaxTurn); -- effectively, it gives 100% at half the game and scales linearly
	dshowpriorities(tSumPriorities, "specific & generic after turn adjust");
	--]]
	
	--PriorityTableAdd(tSumPriorities, tLeaderPriorities);
	--PriorityTableAdd(tSumPriorities, tEraBiasPriorities);
	--PriorityTableAdd(tSumPriorities, tRandPriorities);
	dshowpriorities(tSumPriorities, "*** sum of all priorities "..sLeaderType);
	
	-- Now see which Grand Strategy should be active, based on who has the highest Priority right now
	local sGuessStrategy:string = "NONE";
	local iBestPriority:number = GlobalParameters.RST_STRATEGY_MINIMUM_PRIORITY * 0.5; -- minimum score to activate a strategy
	for strat,value in pairs(tSumPriorities) do
		if value > iBestPriority then
			iBestPriority = value;
			sGuessStrategy = strat;
		end
	end
	print(Game.GetCurrentGameTurn(), sLeaderType, "...guessed", sGuessStrategy, "priority", iBestPriority);
	
	-- log guesses to Log.lua
	if bOptionLogGuess then
		local tLog:table = {};
		table.insert(tLog, tostring(Game.GetCurrentGameTurn()));
		table.insert(tLog, "RSTGUESS");
		table.insert(tLog, data.LeaderType); -- who is guessing
		table.insert(tLog, sLeaderType); -- whom to guess
		table.insert(tLog, string.format("%s @ %4.1f", sGuessStrategy, iBestPriority)); -- guessed strategy
		for _,strat in ipairs(tShowStrat) do table.insert(tLog, string.format("%s @ %4.1f", strat, tSumPriorities[strat])); end -- others for reference, only ones defined in tShowStrat
		print(table.concat(tLog, ", "));
	end
	
	return sGuessStrategy;
end


------------------------------------------------------------------------------
-- Test if other player is doing better than we in a specific strategy
-- Returns TRUE only if better, equal returns false
-- there also approx. 5% slack in comparison to allow for small fluctuations
function OtherPlayerDoingBetterThanUs(data:table, eOtherID:number, sStrategy:string)
	print("FUN OtherPlayerDoingBetterThanUs", data.PlayerID, eOtherID, sStrategy);
	if sStrategy == "NONE" then return false; end
	local ePlayerID:number = data.PlayerID;
	------------------------------------------------------------------------------
	if sStrategy == "CONQUEST" then
		local iNumCapitalsUs:number   = RST.PlayerGetNumCapturedCapitals(ePlayerID);
		local iNumCapitalsThem:number = RST.PlayerGetNumCapturedCapitals(eOtherID);
		local iMilitaryPowerUs:number   = math.max(1, RST.PlayerGetMilitaryStrength(ePlayerID));
		local iMilitaryPowerThem:number = math.max(1, RST.PlayerGetMilitaryStrength(eOtherID));
		print("cities us/them", iNumCapitalsUs, iNumCapitalsThem, "power us/them", iMilitaryPowerUs, iMilitaryPowerThem);
		-- basically, each taken capital is worth an entire army
		iMilitaryPowerUs   = iMilitaryPowerUs   * math.max(1, iNumCapitalsUs);
		iMilitaryPowerThem = iMilitaryPowerThem * math.max(1, iNumCapitalsThem);
		return iMilitaryPowerThem / iMilitaryPowerUs > 1.05; -- allow for 5% slack
	------------------------------------------------------------------------------
	elseif sStrategy == "SCIENCE" then
		local iSpaceRaceProjectsUs:number   = PlayerGetNumProjectsSpaceRace(ePlayerID);
		local iSpaceRaceProjectsThem:number = PlayerGetNumProjectsSpaceRace(eOtherID);
		local iNumTechsUs:number = RST.PlayerGetNumTechsResearched(ePlayerID);
		local iNumTechsThem:number = RST.PlayerGetNumTechsResearched(eOtherID);
		print("projects us/them", iSpaceRaceProjectsUs, iSpaceRaceProjectsThem, "techs us/them", iNumTechsUs, iNumTechsThem);
		-- compare projects
		if iSpaceRaceProjectsThem > iSpaceRaceProjectsUs then return true; end
		if iSpaceRaceProjectsThem < iSpaceRaceProjectsUs then return false; end
		-- compare techs
		return (iNumTechsThem - iNumTechsUs) > 1; -- allow for 1 tech of slack
	------------------------------------------------------------------------------
	elseif sStrategy == "CULTURE" then
		local iProgressUs:number   = RST.PlayerGetCultureVictoryProgress(ePlayerID);
		local iProgressThem:number = RST.PlayerGetCultureVictoryProgress(eOtherID);
		local iTourismUs:number   = math.max(1, RST.PlayerGetTourism(ePlayerID));
		local iTourismThem:number = math.max(1, RST.PlayerGetTourism(eOtherID));
		print("progress us/them", iProgressUs, iProgressThem, "tourism us/them", iTourismUs, iTourismThem);
		-- compare actual victory progress, however we are considered equal if difference is less than 5pp
		if (iProgressThem - iProgressUs) > 5 then return true; end
		-- otherwise, compare tourism output, again with 5% slack
		return (iTourismThem / iTourismUs) > 1.05;
		-- Civ 5 compares also Culture yield, but it is not so important in Civ6
	------------------------------------------------------------------------------
	elseif sStrategy == "RELIGION" then
		local iConvertedUs:number   = PlayerGetNumCivsConverted(ePlayerID);
		local iConvertedThem:number = PlayerGetNumCivsConverted(eOtherID);
		local iFaithUs:number   = math.max(1, Players[ePlayerID]:GetReligion():GetFaithYield());
		local iFaithThem:number = math.max(1, Players[eOtherID]:GetReligion():GetFaithYield());
		print("converts us/them", iConvertedUs, iConvertedThem, "faith us/them", iFaithUs, iFaithThem);
		-- compare number of civs converted multiplies by Faith yield (see also Conquest)
		-- basically 1 converted Civ is worth entire yield output
		iFaithUs   = iFaithUs   * math.max(1, iConvertedUs);
		iFaithThem = iFaithThem * math.max(1, iConvertedThem);
		return iFaithThem / iFaithUs > 1.05; -- allow for 5% slack
	------------------------------------------------------------------------------
	elseif sStrategy == "DIPLO" then
		-- compare number of secured votes
		return false;
	------------------------------------------------------------------------------
	else
		print("WARNING: OtherPlayerDoingBetterThanUs, unknown strategy", sStrategy);
		return false;
	end
end


-- ===========================================================================
-- GAME EVENTS
-- ===========================================================================


-- ===========================================================================
-- only 4 params, checked
function OnCityAddedToMap(ePlayerID:number, iCityID:number, iX:number, iY:number)
	dprint("FUN OnCityAddedToMap() (player,city,x,y,a,b)",ePlayerID,iCityID,iX,iY);
	if not IsPlayerBoostable(ePlayerID) then return; end
	dprint("Player is boostable (id)", ePlayerID);
	-- BOOST CLASS DISPATCHER
	if Players[ePlayerID]:GetCities():GetCount() == 1 then
		ProcessBoostsCapitalLocation(ePlayerID, iCityID, iX, iY);
		ProcessBoostsSettledCities("1", ePlayerID, iCityID);
	end
	if Players[ePlayerID]:GetCities():GetCount() == 2 then
		ProcessBoostsSettledCities("2", ePlayerID, iCityID);
	end
end


-- ===========================================================================
function OnLoadScreenClose()
	dprint("FUN OnLoadScreenClose");
end




------------------------------------------------------------------------------
-- PlayerTurnActivated = { "player", "bIsFirstTime" },
-- TESTING MODE - it should be deactivated later, there is no need to call this here 
function OnPlayerTurnActivated( ePlayerID:number, bIsFirstTime:boolean)
	print("FUN OnPlayerTurnActivated", ePlayerID, bIsFirstTime);
	RefreshAndProcessData(ePlayerID);
end

------------------------------------------------------------------------------
-- PlayerTurnDeactivated = { "player" },
function OnPlayerTurnDeactivated(ePlayerID:number)
	print("FUN OnPlayerTurnDeactivated", ePlayerID);
	local pPlayer:table = Players[ePlayerID];
	if not (pPlayer ~= nil and pPlayer:IsAlive() and pPlayer:IsMajor()) then return; end
	tData[ePlayerID].Dirty = true; -- default mode - later can be changed for specific events (e.g. Policy changed, gov changed, etc.)
end


------------------------------------------------------------------------------
-- StrategyConditions calls via 'Call Lua Function'
-- Called separately for each player, including Minors, Free Cities and Barbarians
-- For player X it is called BEFORE PlayerTurnActivated(X)
-- For a Human, it is called AFTER LocalPlayerTurnBegin, but before PlayerTurnActivated(0)
------------------------------------------------------------------------------

function ActiveStrategyConquest(ePlayerID:number, iThreshold:number)
	--print(Game.GetCurrentGameTurn(), "FUN ActiveStrategyConquest", ePlayerID, iThreshold);
	local pPlayer:table = Players[ePlayerID];
	if not (pPlayer:IsAlive() and pPlayer:IsMajor()) then return false; end
	RefreshAndProcessData(ePlayerID);
	--print(Game.GetCurrentGameTurn(), "...strategy is", tData[ePlayerID].ActiveStrategy, tData[ePlayerID].ActiveStrategy == "CONQUEST");
	return tData[ePlayerID].ActiveStrategy == "CONQUEST";
end
GameEvents.ActiveStrategyConquest.Add(ActiveStrategyConquest);

function ActiveStrategyScience(ePlayerID:number, iThreshold:number)
	--print(Game.GetCurrentGameTurn(), "FUN ActiveStrategyScience", ePlayerID, iThreshold);
	local pPlayer:table = Players[ePlayerID];
	if not (pPlayer:IsAlive() and pPlayer:IsMajor()) then return false; end
	RefreshAndProcessData(ePlayerID);
	--print(Game.GetCurrentGameTurn(), "...strategy is", tData[ePlayerID].ActiveStrategy, tData[ePlayerID].ActiveStrategy == "SCIENCE");
	return tData[ePlayerID].ActiveStrategy == "SCIENCE";
end
GameEvents.ActiveStrategyScience.Add(ActiveStrategyScience);

function ActiveStrategyCulture(ePlayerID:number, iThreshold:number)
	--print(Game.GetCurrentGameTurn(), "FUN ActiveStrategyCulture", ePlayerID, iThreshold);
	local pPlayer:table = Players[ePlayerID];
	if not (pPlayer:IsAlive() and pPlayer:IsMajor()) then return false; end
	RefreshAndProcessData(ePlayerID);
	--print(Game.GetCurrentGameTurn(), "...strategy is", tData[ePlayerID].ActiveStrategy, tData[ePlayerID].ActiveStrategy == "CULTURE");
	return tData[ePlayerID].ActiveStrategy == "CULTURE";
end
GameEvents.ActiveStrategyCulture.Add(ActiveStrategyCulture);

function ActiveStrategyReligion(ePlayerID:number, iThreshold:number)
	--print(Game.GetCurrentGameTurn(), "FUN ActiveStrategyReligion", ePlayerID, iThreshold);
	local pPlayer:table = Players[ePlayerID];
	if not (pPlayer:IsAlive() and pPlayer:IsMajor()) then return false; end
	RefreshAndProcessData(ePlayerID);
	--print(Game.GetCurrentGameTurn(), "...strategy is", tData[ePlayerID].ActiveStrategy, tData[ePlayerID].ActiveStrategy == "RELIGION");
	return tData[ePlayerID].ActiveStrategy == "RELIGION";
end
GameEvents.ActiveStrategyReligion.Add(ActiveStrategyReligion);

function CheckTurnNumber(iPlayerID:number, iThreshold:number)
	print(Game.GetCurrentGameTurn(), "FUN CheckTurnNumber", iPlayerID, iThreshold);
	return Game.GetCurrentGameTurn() >= iThreshold;
end
GameEvents.CheckTurnNumber.Add(CheckTurnNumber);


------------------------------------------------------------------------------
function Initialize()
	--print("FUN Initialize");
	
	InitializeData();
	
	-- disable - StrategyConditions are called every turn, so it will auto-refresh when needed
	--Events.PlayerTurnActivated.Add( OnPlayerTurnActivated );  -- main event for any player start (AIs, including minors), goes for playerID = 0,1,2,...
	--Events.PlayerTurnDeactivated.Add( OnPlayerTurnDeactivated );  -- main event for any player end (including minors)

	--Events.LoadScreenClose.Add ( OnLoadScreenClose );   -- fires when Game is ready to begin i.e. big circle buttons appears; if loaded - fires AFTER LoadComplete
	-- these events fire AFTER custom PlayerTurnActivated()
	--Events.CityProductionCompleted.Add( OnCityProductionCompleted );
	--Events.CityProjectCompleted.Add( OnCityProjectCompleted );
	--Events.UnitGreatPersonCreated.Add( OnUnitGreatPersonCreated );
	--Events.TechBoostTriggered.Add( OnTechBoostTriggered );
	--Events.CivicBoostTriggered.Add( OnCivicBoostTriggered );
	--Events.ResearchCompleted.Add( OnResearchComplete );
	--Events.CivicCompleted.Add( OnCivicComplete );
	--Events.CityAddedToMap.Add( OnCityAddedToMap );
	--Events.DistrictAddedToMap.Add( OnDistrictAddedToMap );
	--Events.ImprovementAddedToMap.Add( OnImprovementAddedToMap );
	--Events.UnitAddedToMap.Add( OnUnitAddedToMap );
	--Events.UnitMoved.Add( OnUnitMoved );
	--Events.UnitMoveComplete.Add( OnUnitMoveComplete );
	--Events.DiplomacyMeet.Add( OnDiplomacyMeet );
	--Events.DiplomacyRelationshipChanged.Add( OnDiplomacyMeet );
	--Events.InfluenceChanged.Add( OnDiplomacyMeet );
	--Events.InfluenceGiven.Add( OnInfluenceGiven );
	--Events.CityReligionFollowersChanged.Add( OnCityReligionFollowersChanged ); -- this event fires every turn, for each city, very often!
	--Events.GreatWorkCreated.Add( OnGreatWorkCreated );
	--Events.GovernmentChanged.Add( OnGovernmentChanged );
	
	--InitializeBoosts();
	--dprint("List of BoostClasses:");
	--dshowtable(tBoostClasses, 0);
	-- more pre-events to check
	--Events.LoadComplete.Add( OnLoadComplete );  -- fires after loading a game, when it's ready to start (i.e. circle button)
	--Events.LoadScreenClose.Add ( OnLoadScreenClose );   -- fires then Game is ready to begin i.e. big circle buttons appears; if loaded - fires AFTER LoadComplete
	--Events.SaveComplete.Add( OnSaveComplete );  -- fires after save is completed, and Main Game Menu is displayed
	--Events.AppInitComplete.Add( OnAppInitComplete );
	--Events.GameViewStateDone.Add( OnGameViewStateDone );
	--Events.RequestSave.Add( OnRequestSave );  -- didn't fire
	--Events.RequestLoad.Add( OnRequestLoad );  -- didn't fire
	
	-- initialize events - starting events
	--Events.LocalPlayerChanged.Add( OnLocalPlayerChanged );  -- fires in-between TurnEnd and TurnBegin
	--Events.PreTurnBegin.Add( OnPreTurnBegin );  -- fires ONCE at start of turn, before actual Turn start
	--Events.TurnBegin.Add( OnTurnBegin );  -- fires ONCE at the start of Turn
	--Events.PhaseBegin.Add( OnPhaseBegin );  -- engine?
	--Events.LocalPlayerTurnBegin.Add( OnLocalPlayerTurnBegin );  -- event for LOCAL player only (i.e. HUMANS), fires BEFORE PlayerTurnActivated
	--Events.PlayerTurnActivated.Add( OnPlayerTurnActivated );  -- main event for any player start (AIs, including minors), goes for playerID = 0,1,2,...
	-- these events fire AFTER custom PlayerTurnActivated()
	--Events.CityProductionCompleted.Add(	OnCityProductionCompleted );
	--Events.CityProjectCompleted.Add( OnCityProjectComplete );	
	--Events.TechBoostTriggered.Add( OnTechBoostTriggered );
	--Events.CivicBoostTriggered.Add( OnCivicBoostTriggered );
	--Events.ResearchCompleted.Add( OnResearchComplete );
	--Events.CivicCompleted.Add( OnCivicComplete );
	
	-- HERE YOU PLAY GAME AS HUMAN
	-- initialize events - finishing events
	--Events.LocalPlayerTurnEnd.Add( OnLocalPlayerTurnEnd );  -- fires only for HUMANS
	--Events.PhaseEnd.Add( OnPhaseEnd );  -- engine?
	--Events.TurnEnd.Add( OnTurnEnd );  -- fires ONCE at end of turn
	--Events.EndTurnDirty.Add( OnEndTurnDirty );  -- engine event, triggers very often

end	
Initialize();

print("OK loaded RealStrategy.lua from Real Strategy");