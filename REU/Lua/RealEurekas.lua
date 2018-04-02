print("Loading RealEurekas.lua from Real Eurekas mod");
-- ===========================================================================
-- RealEurekas
-- Author: Grzegorz
-- DateCreated: 4/11/2017 8:09:37 PM
-- ===========================================================================


-- ===========================================================================
-- DEBUG ROUTINES
-- ===========================================================================

-- debug output routine
function dprint(sStr,p1,p2,p3,p4,p5,p6)
	if true then return; end
	local sOutStr = sStr;
	if p1 ~= nil then sOutStr = sOutStr.." [1] "..tostring(p1); end
	if p2 ~= nil then sOutStr = sOutStr.." [2] "..tostring(p2); end
	if p3 ~= nil then sOutStr = sOutStr.." [3] "..tostring(p3); end
	if p4 ~= nil then sOutStr = sOutStr.." [4] "..tostring(p4); end
	if p5 ~= nil then sOutStr = sOutStr.." [5] "..tostring(p5); end
	if p6 ~= nil then sOutStr = sOutStr.." [6] "..tostring(p6); end
	print(sOutStr);
end

-- debug routine - print contents of a table of numbers
function dshowinttable(pTable:table)  -- For debugging purposes. LOT of table data being handled here.
	-- for ease of reading they will be printed in rows by 10
	dprint("Showing table (t,count)", pTable, table.count(pTable));
	local iSize = table.count(pTable);
	if iSize == 0 then dprint("...nothing to show"); return; end
	for y = 0, math.floor((iSize-1)/10), 1 do
		local sOutStr = "";
		for x = 0,9,1 do
			local idx = 10*y+x;
			if idx < iSize then sOutStr = sOutStr..string.format("%5d", pTable[idx+1]); end
		end
		dprint("  row", y, sOutStr);
	end
end

function dshowtable(pTable:table, iLevel:number)
	print(string.rep("---", iLevel), pTable);
	if iLevel > 4 then return; end
	for k,v in pairs(pTable) do
		print(string.rep("   ", iLevel).."["..tostring(k).."]="..tostring(v));
		if type(v) == "table" and string.find(k, "Reference") == nil then dshowtable(v, iLevel+1); end
	end
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
-- BOOST DATA AND HELPERS
-- ===========================================================================

local sBoostClassCustom:string = "BOOST_TRIGGER_TURN_NUMBER";  -- the only one that doesn't crash the game

local tBoostClasses:table = {};  -- indexed using code (cc, ccc or 99999); holds some specific type data and a table of active Boosts

-- traverse through Boosts, find custom ones and initialize tBoostTypes table accordingly
function InitializeBoosts()
	dprint("FUNCAL InitializeBoosts()");
	
	for boost in GameInfo.Boosts() do
		-- detect custom boost
		if boost.BoostClass == sBoostClassCustom and boost.NumItems > 9999 and boost.NumItems < 100000 then  -- range is all 5-digits numbers
			-- process custom boost
			dprint("Found custom boost id", boost.NumItems);
			-- find the class for code in boost.NumItems
			local sBoostClass:string = "";
			for class in GameInfo.REurBoostCodes() do
				if class.BoostCode == boost.NumItems then sBoostClass = class.BoostClass; break; end
			end
			if sBoostClass == "" then
				print("ERROR: cannot find class for boost code", boost.NumItems); return;
			end
			dprint("  ...its class is", sBoostClass);
			-- get the class object; register if nil
			local pBoostClass = tBoostClasses[sBoostClass];
			if pBoostClass == nil then
				-- first time encountered this class
				dprint("  ...registering", boost.NumItems, sBoostClass);
				pBoostClass = {};
				pBoostClass.BoostClass = sBoostClass;
				pBoostClass.BoostCode = boost.NumItems;
				pBoostClass.Boosts = {};
				tBoostClasses[sBoostClass] = pBoostClass;
			end
			-- register this specific boost
			dprint("  ...adding boost (id,numitems2,tech,civic)", boost.BoostID, boost.NumItems2, boost.TechnologyType, boost.CivicType);
			tBoostClasses[sBoostClass].Boosts[boost.BoostID] = boost;
		end  -- custom boost
	end  -- main loop
end


-- helper - can this player receive a boost? must be Alive and Major
function IsPlayerBoostable(ePlayerID:number)
	local pPlayer = Players[ePlayerID];
	if pPlayer == nil then return false; end
	if pPlayer:IsAlive() and pPlayer:IsMajor() then return true; end
	return false;
end

-- helper - check if we need to proces a specific boost (an object from Boosts table)
function HasBoostBeenTriggered(ePlayerID:number, pBoost:table)
	dprint("FUNCAL HasBoostBeenTriggered() (player,id,tech,civic)",ePlayerID,pBoost.BoostID,pBoost.TechnologyType,pBoost.CivicType);
	if pBoost.TechnologyType ~= nil then 
		dprint("  ...checking (tech)", pBoost.TechnologyReference.Index);
		return Players[ePlayerID]:GetTechs():HasBoostBeenTriggered( pBoost.TechnologyReference.Index );
	end
	if pBoost.CivicType ~= nil then
		dprint("  ...checking (civic)", pBoost.CivicReference.Index);
		return Players[ePlayerID]:GetCulture():HasBoostBeenTriggered( pBoost.CivicReference.Index );
	end
	print("ERROR: no tech nor civic attached to boost, no further processing required", pBoost.BoostID);
	return true;  -- so we we won't run any further processing
end

-- main function to actually trigger a boost
function TriggerBoost(ePlayerID:number, pBoost:table)
	dprint("FUNCAL () TriggerBoost(player,id,tech,civic)",ePlayerID,pBoost.BoostID,pBoost.TechnologyType,pBoost.CivicType);
	if pBoost.TechnologyType ~= nil then 
		dprint("  ...triggering (tech)", pBoost.TechnologyReference.Index);
		Players[ePlayerID]:GetTechs():TriggerBoost( pBoost.TechnologyReference.Index );
	end
	if pBoost.CivicType ~= nil then
		dprint("  ...triggering (civic)", pBoost.CivicReference.Index);
		Players[ePlayerID]:GetCulture():TriggerBoost( pBoost.CivicReference.Index );
	end
	dprint("  ...checking results:", HasBoostBeenTriggered(ePlayerID, pBoost));
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
	dprint("FUNSTA CountCityTilesTerrain()",sTerrainType);
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
	dprint("FUNSTA CountCityTilesFeature()",sFeatureType);
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
	dprint("Resources NOT visible");
	for res in GameInfo.Resources() do
		if not tResourceVisible[res.Index] then dprint("  ... (type)", res.ResourceType); end
	end
end


function CountCityTilesImprovableRes(tPlots:table, sImprovementType:string)
	dprint("FUNSTA CountCityTilesImprovableRes()",sImprovementType);
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


function ProcessBoostsSettledCities(sClassFix:string, ePlayerID:number, iCityID:number)
	dprint("FUNCAL ProcessBoostsSettledCities() (fix,player,city)",sClassFix,ePlayerID,iCityID);

	-- we always have to count all plots from all cities (no matter if 1 or 2 or more)
	local tPlots = {};
	for _,city in Players[ePlayerID]:GetCities():Members() do
		dprint("Getting plots for city (id,name)", city:GetID(), city:GetName());
		GetCityPlots(tPlots, ePlayerID, city:GetID());
	end

	local tBoostClass:table = nil;
	
	-- BOOST: SETTLE_CITY1_DESERT_X, SETTLE_CITY1_SNOW_X, SETTLE_CITY1_TUNDRA_X
	local function ProcessBoostSettledCitiesTerrain(sBoostClass:string, sTerrainType:string)
		tBoostClass = tBoostClasses[sBoostClass];
		if tBoostClass == nil then return end;
		dprint("  ...processing (class,terrain)", sBoostClass, sTerrainType);
		local iNumItems:number = CountCityTilesTerrain(tPlots, sTerrainType);
		for id,boost in pairs(tBoostClass.Boosts) do
			dprint("     ...for boost (id,items2,num)", id, boost.NumItems2, iNumItems);
			if not HasBoostBeenTriggered(ePlayerID, boost) and iNumItems >= boost.NumItems2 then TriggerBoost(ePlayerID, boost); end
		end
	end
	ProcessBoostSettledCitiesTerrain("SETTLE_CITY"..sClassFix.."_DESERT_X", "TERRAIN_DESERT");
	ProcessBoostSettledCitiesTerrain("SETTLE_CITY"..sClassFix.."_SNOW_X", "TERRAIN_SNOW");
	ProcessBoostSettledCitiesTerrain("SETTLE_CITY"..sClassFix.."_TUNDRA_X", "TERRAIN_TUNDRA");
	
	-- BOOST: SETTLE_CITY1_FEATURE_X
	tBoostClass = tBoostClasses["SETTLE_CITY"..sClassFix.."_FEATURE_X"];
	if tBoostClass ~= nil then
		for id,boost in pairs(tBoostClass.Boosts) do
			dprint("  ...processing (class,feature)", "SETTLE_CITY"..sClassFix.."_FEATURE_X", boost.FeatureType);
			local iNumItems:number = CountCityTilesFeature(tPlots, boost.FeatureType);
			dprint("     ...for boost (id,items2,num)", id, boost.NumItems2, iNumItems);
			if not HasBoostBeenTriggered(ePlayerID, boost) and iNumItems >= boost.NumItems2 then TriggerBoost(ePlayerID, boost); end
		end
	end
	
	-- BOOST: SETTLE_CITY1_IMPR_X
	tBoostClass = tBoostClasses["SETTLE_CITY"..sClassFix.."_IMPR_X"];
	if tBoostClass ~= nil then 
		-- special addition - additional resource visibility check is required
		UpdateResourceVisibility(ePlayerID);
		for id,boost in pairs(tBoostClass.Boosts) do
			dprint("  ...processing (class,improv)", "SETTLE_CITY"..sClassFix.."_IMPR_X", boost.ImprovementType);
			local iNumItems:number = CountCityTilesImprovableRes(tPlots, boost.ImprovementType);
			dprint("     ...for boost (id,items2,num)", id, boost.NumItems2, iNumItems);
			if not HasBoostBeenTriggered(ePlayerID, boost) and iNumItems >= boost.NumItems2 then TriggerBoost(ePlayerID, boost); end
		end
	end
	
end

-- BOOST: SETTLE_CAPITAL_COAST, SETTLE_CAPITAL_LAKE, SETTLE_CAPITAL_RIVER, SETTLE_CAPITAL_MOUNTAIN
function ProcessBoostsCapitalLocation(ePlayerID:number, iCityID:number, iX:number, iY:number)
	dprint("FUNSTA ProcessBoostsCapitalLocation() (player,city,x,y)",ePlayerID,iCityID,iX,iY);
	
	local pPlot = Map.GetPlot(iX, iY);
	
	-- BOOST: SETTLE_CAPITAL_COAST
	tBoostClass = tBoostClasses["SETTLE_CAPITAL_COAST"];
	if tBoostClass ~= nil then 
		for id,boost in pairs(tBoostClass.Boosts) do
			dprint("  ...processing boost (class,id,coast)", "SETTLE_CAPITAL_COAST", id, pPlot:IsCoastalLand());
			if not HasBoostBeenTriggered(ePlayerID, boost) and pPlot:IsCoastalLand() then TriggerBoost(ePlayerID, boost); end
		end
	end
	-- BOOST: SETTLE_CAPITAL_RIVER
	tBoostClass = tBoostClasses["SETTLE_CAPITAL_RIVER"];
	if tBoostClass ~= nil then 
		for id,boost in pairs(tBoostClass.Boosts) do
			dprint("  ...processing boost (class,id,coast)", "SETTLE_CAPITAL_RIVER", id, pPlot:IsRiver());
			if not HasBoostBeenTriggered(ePlayerID, boost) and pPlot:IsRiver() then TriggerBoost(ePlayerID, boost); end
		end
	end
	-- BOOST: SETTLE_CAPITAL_LAKE
	tBoostClass = tBoostClasses["SETTLE_CAPITAL_LAKE"];
	if tBoostClass ~= nil then 
		local bIsLake:boolean = false;
		for direction = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1, 1 do
			local testPlot = Map.GetAdjacentPlot(iX, iY, direction);
			if testPlot:IsLake() then bIsLake = true; break; end
		end
		for id,boost in pairs(tBoostClass.Boosts) do
			dprint("  ...processing boost (class,id,lake)", "SETTLE_CAPITAL_LAKE", id, bIsLake);
			if not HasBoostBeenTriggered(ePlayerID, boost) and bIsLake then TriggerBoost(ePlayerID, boost); end
		end
	end
	-- BOOST: SETTLE_CAPITAL_MOUNTAIN
	tBoostClass = tBoostClasses["SETTLE_CAPITAL_MOUNTAIN"];
	if tBoostClass ~= nil then 
		local bIsMountain:boolean = false;
		for direction = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1, 1 do
			local testPlot = Map.GetAdjacentPlot(iX, iY, direction);
			if testPlot:IsMountain() then bIsMountain = true; break; end
		end
		for id,boost in pairs(tBoostClass.Boosts) do
			dprint("  ...processing boost (class,id,mountain)", "SETTLE_CAPITAL_MOUNTAIN", id, bIsMountain);
			if not HasBoostBeenTriggered(ePlayerID, boost) and bIsMountain then TriggerBoost(ePlayerID, boost); end
		end
	end
end


-- ===========================================================================
-- GAME EVENTS
-- ===========================================================================


-- ===========================================================================
-- only 4 params, checked
function OnCityAddedToMap(ePlayerID:number, iCityID:number, iX:number, iY:number)
	dprint("FUNCAL OnCityAddedToMap() (player,city,x,y,a,b)",ePlayerID,iCityID,iX,iY);
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
function OnCityProductionCompleted(ePlayer:number, iCity:number, eOrderType, eObjectType, bCanceled, typeModifier)
	dprint("FUNSTA OnCityProductionCompleted(ePlayer,iCity,eOrderType,eObjectType,bCanceled,typeModifier)",ePlayer,iCity,eOrderType,eObjectType,bCanceled,typeModifier);
end

-- ===========================================================================
function OnDistrictAddedToMap( playerID: number, districtID : number, cityID :number, districtX : number, districtY : number, districtType:number, percentComplete:number )
-- percentComplete was ERA_ANCIENT=-1851407529
-- 1400916610=ERA_CLASSICAL (I was in Medieval)
-- 848543945=ERA_RENAISSANCE (I was in Industrial)
-- 1948543980=ERA_ATOMIC (I was in Information)
	dprint("FUNCAL OnDistrictAddedToMap() (did,cid,x,y,type,perc)",districtID,cityID,districtX,districtY,districtType,percentComplete);
end

-- ===========================================================================
function OnImprovementAddedToMap(locX, locY, eImprType, eOwner, resource, isPillaged, isWorked)
	dprint("FUNCAL OnImprovementAddedToMap() (x,y,type,owner,resource)",locX,locY,eImprType,eOwner,resource);
end

-- ===========================================================================
function OnUnitAddedToMap( playerID: number, unitID : number, unitX : number, unitY : number )
	dprint("FUNCAL OnUnitAddedToMap() (player,unit,x,y)",playerID,unitID,unitX,unitY);
end

-- ===========================================================================
-- it's call for each plot that unit is traversing
function OnUnitMoved(ePlayerID:number, iUnitID:number, x, y, locallyVisible, stateChange)
	dprint("FUNCAL OnUnitMoved (player,unit,x,y,visible,state)",ePlayerID, iUnitID,x,y,locallyVisible,stateChange);
end

-- ===========================================================================
-- only 4 params, checked
function OnUnitMoveComplete(playerID, unitID, x, y)
	dprint("FUNCAL OnUnitMoveComplete() (player,unit,x,y,visible,state)",playerID,unitID,x,y);
end

-- ===========================================================================
function OnLoadScreenClose()
	dprint("FUNCAL OnLoadScreenClose");
end

-- ===========================================================================
function Initialize()
	dprint("FUNSTA Initialize()");

	Events.LoadScreenClose.Add ( OnLoadScreenClose );   -- fires then Game is ready to begin i.e. big circle buttons appears; if loaded - fires AFTER LoadComplete
	--Events.PlayerTurnActivated.Add( OnPlayerTurnActivated );  -- main event for any player start (AIs, including minors), goes for playerID = 0,1,2,...
	-- these events fire AFTER custom PlayerTurnActivated()
	--Events.CityProductionCompleted.Add(	OnCityProductionCompleted );
	--Events.CityProjectCompleted.Add( OnCityProjectComplete );	
	--Events.TechBoostTriggered.Add( OnTechBoostTriggered );
	--Events.CivicBoostTriggered.Add( OnCivicBoostTriggered );
	--Events.ResearchCompleted.Add( OnResearchComplete );
	--Events.CivicCompleted.Add( OnCivicComplete );
	Events.CityAddedToMap.Add( OnCityAddedToMap );
	--Events.DistrictAddedToMap.Add( OnDistrictAddedToMap );
	--Events.ImprovementAddedToMap.Add( OnImprovementAddedToMap );
	--Events.UnitAddedToMap.Add( OnUnitAddedToMap );
	--Events.UnitMoved.Add( OnUnitMoved );
	--Events.UnitMoveComplete.Add( OnUnitMoveComplete );
	
	InitializeBoosts();
	--dprint("List of BoostClasses");
	--dshowtable(tBoostClasses, 0);
	
	dprint("FUNEND Initialize()");
end	
Initialize();

print("Finished loading RealEurekas.lua from Real Eurekas mod");