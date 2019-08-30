print("Loading Real Modifier Analysis.lua from Better Report Screen version "..GlobalParameters.BRS_VERSION_MAJOR.."."..GlobalParameters.BRS_VERSION_MINOR);
-- ===========================================================================
-- Real Modifier Analysis
-- Author: Infixo
-- Created: February 25th - March 1st, 2018
-- ===========================================================================

-- exposing functions and variables
if not ExposedMembers.RMA then ExposedMembers.RMA = {} end;
local RMA = ExposedMembers.RMA;
-- insert functions/objects into RMA in Initialize()

-- Expansions check
local bIsRiseAndFallMod:boolean = Modding.IsModActive("1B28771A-C749-434B-9053-D1380C553DE9"); -- Rise & Fall
local bIsGatheringStorm:boolean = Modding.IsModActive("4873eb62-8ccc-4574-b784-dda455e74e68"); -- Gathering Storm
local bIsRiseAndFall:boolean = (bIsRiseAndFallMod or bIsGatheringStorm); -- GS includes gameplay features from RF


-- ===========================================================================
-- DEBUG ROUTINES
-- ===========================================================================

-- debug output routine
function dprint(sStr,p1,p2,p3,p4,p5,p6)
	local sOutStr = sStr;
	if p1 ~= nil then sOutStr = sOutStr.." [1] "..tostring(p1); end
	if p2 ~= nil then sOutStr = sOutStr.." [2] "..tostring(p2); end
	if p3 ~= nil then sOutStr = sOutStr.." [3] "..tostring(p3); end
	if p4 ~= nil then sOutStr = sOutStr.." [4] "..tostring(p4); end
	if p5 ~= nil then sOutStr = sOutStr.." [5] "..tostring(p5); end
	if p6 ~= nil then sOutStr = sOutStr.." [6] "..tostring(p6); end
	print(sOutStr);
end

-- debug routine - print contents of a table of plot indices
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

-- debug routine - prints a table (no recursion)
function dshowtable(tTable:table)
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

-- debug routine - prints extended yields table in a compacted form (1 line, formatted)
function dshowyields(pYields:table)
	local tOut:table = {}; table.insert(tOut, "  yields :");
	for yield,value in pairs(pYields) do table.insert(tOut, string.format("%s %5.2f :", yield, value)); end
	print(table.concat(tOut, " "));
end

-- debug routine - prints extended yields table in a compacted form (1 line, formatted)
function dshowsubject(pSubject:table)
	print("    sub: ", pSubject.SubjectType, pSubject.Name);
end

	--dprint("Subjects are:"); for k,v in pairs(tSubjects) do print(k,v.SubjectType,v.Name); end -- debug
-- debug routne - prints all subjects in 1 line
function dshowsubjects(pSubjects:table)
	local tOut:table = {};
	for _,subject in pairs(pSubjects) do table.insert(tOut, subject.Name); end
	print("Subjects:", table.count(pSubjects), table.concat(tOut, ","));
end

--------------------------------------------------------------
-- Timer
--------------------------------------------------------------
local fStartTime:number = 0.0
function TimerStart()
	fStartTime = Automation.GetTime()
end
function TimerTick(txt:string)
	print("Timer Tick", txt, string.format("%5.3f", Automation.GetTime()-fStartTime))
end

-- ===========================================================================
-- DATA AND VARIABLES
-- ===========================================================================

local bBaseDataDirty:boolean = true; -- set to true to refresh the data
tCities = nil; -- dynamically filled when needed (e.g. after refresh)
tPlayer = nil; -- dynamically filled when needed (e.g. after refresh)
tPlots = nil; -- only the local player's plots

-- supported Subject types, will be put into SubjectType field of respective tables
local SubjectTypes:table = {
	Game = "Game",
	Player = "Player",
	City = "City",
	District = "District",
	Building = "Building",
	Unit = "Unit",
	GreatWork = "GreatWork",
	TradeRoute = "TradeRoute",
	Plot = "Plot", -- also plot yields
}

-- ===========================================================================
-- EXTENDED YIELDS
-- extended yields to support other effects, like Amenities, Tourism, etc.
-- ===========================================================================

-- YieldsTypes 0..5 are for FOOD, PRODUCTION, GOLD, SCIENCE, CULTURE and FAITH
-- they correspond to respective YIELD_ type in Yields table
YieldTypes.TOURISM = 6
YieldTypes.AMENITY = 7
YieldTypes.HOUSING = 8
YieldTypes.LOYALTY = 9
--YieldTypes.GPPOINT =  9 -- Great Person Point
--YieldTypes.ENVOY   = 10
--YieldTypes.APPEAL  = 11
-- whereever possible keep yields in a table named Yields with entries { YieldType = YieldValue }

-- create maps (speed up)
local YieldTypesMap = {};
for yield in GameInfo.Yields() do
	YieldTypesMap[ yield.YieldType ] = string.gsub(yield.YieldType, "YIELD_","");
end
local YieldTypesOrder = {};
for yield,yid in pairs(YieldTypes) do
	YieldTypesOrder[yid] = yield;
end 
--dshowtable(YieldTypes);
--dshowtable(YieldTypesMap);
--dshowtable(YieldTypesOrder);
--for yid,yield in ipairs(YieldTypesOrder) do dprint("YieldTypesOrder", yid, yield) end

-- get a new table with all 0
function YieldTableNew()
	local tNew:table = {};
	for yield,_ in pairs(YieldTypes) do tNew[ yield ] = 0; end
	return tNew;
end

-- set all values to 0
function YieldTableClear(pYields:table)
	for yield,_ in pairs(YieldTypes) do pYields[ yield ] = 0; end
end

-- add two tables
function YieldTableAdd(pYields:table, pYieldsToAdd:table)
	for yield,_ in pairs(YieldTypes) do pYields[ yield ] = pYields[ yield ] + pYieldsToAdd[ yield ]; end
end

-- multiply by a given number
function YieldTableMultiply(pYields:table, fModifier:number)
	for yield,_ in pairs(YieldTypes) do pYields[ yield ] = pYields[ yield ] * fModifier; end
end

-- multiply by a percentage given as integer 0..100
function YieldTablePercent(pYields:table, iPercent:number)
	return YieldTableMultiply(pYields, iPercent/100.0);
end

-- get a specific yield, takes both YieldTypes and "YIELD_XXX" form
function YieldTableGetYield(pYields:table, sYield:string)
	if YieldTypesMap[ sYield ] then return pYields[ YieldTypesMap[ sYield ] ];
	else                            return pYields[ sYield ];                  end
end

-- set a specific yield, takes both YieldTypes and "YIELD_XXX" form
function YieldTableSetYield(pYields:table, sYield:string, fValue:number)
	if YieldTypesMap[ sYield ] then pYields[ YieldTypesMap[ sYield ] ] = fValue;
	else                            pYields[ sYield ] = fValue;                  end
end

-- returns a compacted string with yields info
function YieldTableGetInfo(pYields:table)
	local sYieldInfo:string = "";
	for	_,yield in ipairs(YieldTypesOrder) do
		if pYields[yield] ~= 0 then sYieldInfo = sYieldInfo..(sYieldInfo == "" and "" or " ")..GetYieldString("YIELD_"..yield, pYields[yield]); end
	end
	return sYieldInfo;
end

-- 2019-06-20 GS introduced multiple yields in one modifier, separated with comma
function YieldTableSetMultipleYields(pYields:table, sYields:string, sValues:string)
	sYields = sYields..",";	sValues = sValues..",";
	while string.len(sYields) > 0 and string.len(sValues) > 0 do
		local iCommaYields:number = string.find(sYields, ",");
		local iCommaValues:number = string.find(sValues, ",");
		--print("YieldTableSetMultipleYields", sYields, iCommaYields, sValues, iCommaValues);
		YieldTableSetYield(pYields, string.sub(sYields, 1, iCommaYields-1), tonumber(string.sub(sValues, 1, iCommaValues-1)));
		-- remove processed yield
		sYields = string.sub(sYields, iCommaYields+1);
		sValues = string.sub(sValues, iCommaValues+1);
	end
end


-- ===========================================================================
-- GENERIC FUNCTIONS AND HELPERS
-- ===========================================================================

function GetGameInfoIndex(sTableName:string, sTypeName:string) 
	local tTable = GameInfo[sTableName];
	if tTable then
		local row = tTable[sTypeName];
		if row then return row.Index
		else        return -1;        end
	end
	return -1;
end

-- check if 'value' exists in table 'pTable'; should work for any type of 'value' and table indices
function IsInTable(pTable:table, value)
	for _,data in pairs(pTable) do
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

-- changes "AA_BB_CC" string into "Aa Bb Cc"
function Capitalize(sText:string)
	--local str:string = sText:gsub("_", " ");
	--return tostring( str:gsub("(%a)([%w_']*)", function(first,rest) return first:upper()..rest:lower() end) );
	return sText; -- debug
end


-- ===========================================================================
-- Couple of functions from include("Civ6Common");
-- ===========================================================================

-- ===========================================================================
--	Return the inline text-icon for a given yield
--	yieldType	A database YIELD_TYPE
--	returns		The [ICON_yield] string
-- ===========================================================================
function GetYieldTextIcon( yieldType:string )
	local  iconString:string = "";
	if		yieldType == nil or yieldType == ""	then
		iconString = "Error:NIL";
	elseif  yieldType == "YIELD_TOURISM" then
		iconString = "[ICON_Tourism]"
	elseif  yieldType == "YIELD_AMENITY" then
		iconString = "[ICON_Amenities]" -- [ICON_Therefore] a green arrow pointing to the right
	elseif  yieldType == "YIELD_HOUSING" then
		iconString = "[ICON_Housing]" -- [ICON_LocationPip] a blue pin pointing down
	elseif  yieldType == "YIELD_LOYALTY" then
		iconString = "[ICON_PressureUp]" -- [ICON_PressureDown] is a red arrow pointing down
	elseif	GameInfo.Yields[yieldType] ~= nil and GameInfo.Yields[yieldType].IconString ~= nil and GameInfo.Yields[yieldType].IconString ~= "" then
		iconString = GameInfo.Yields[yieldType].IconString;
	else
		iconString = "Unknown:"..yieldType; 
	end			
	return iconString;
end

-- ===========================================================================
--	Return the inline entry for a yield's color
-- ===========================================================================
function GetYieldTextColor( yieldType:string )
	if     yieldType == nil or yieldType == "" then return "[COLOR:255,255,255,255]NIL ";
	elseif yieldType == "YIELD_FOOD"		   then return "[COLOR:ResFoodLabelCS]";
	elseif yieldType == "YIELD_PRODUCTION"	   then return "[COLOR:ResProductionLabelCS]";
	elseif yieldType == "YIELD_GOLD"		   then return "[COLOR:ResGoldLabelCS]";
	elseif yieldType == "YIELD_SCIENCE"		   then return "[COLOR:ResScienceLabelCS]";
	elseif yieldType == "YIELD_CULTURE"		   then return "[COLOR:ResCultureLabelCS]";
	elseif yieldType == "YIELD_FAITH"		   then return "[COLOR:ResFaithLabelCS]";
	elseif yieldType == "YIELD_TOURISM"		   then return "[COLOR:ResTourismLabelCS]";
	elseif yieldType == "YIELD_AMENITY"        then return "[COLOR_White]";
	elseif yieldType == "YIELD_HOUSING"        then return "[COLOR_White]";
	elseif yieldType == "YIELD_LOYALTY"        then return "[COLOR_White]";
	else											return "[COLOR:255,255,255,0]ERROR ";
	end				
end

-- ===========================================================================
-- Updated functions from Civ6Common, to include rounding to 1 decimal digit
-- ===========================================================================
function toPlusMinusString( value:number )
	if value == 0 then return "0"; end
	--return Locale.ToNumber(value, "+#,###.#;-#,###.#");
	return Locale.ToNumber(math.floor((value*10)+0.5)/10, "+#,###.#;-#,###.#");
end

function toPlusMinusNoneString( value:number )
	if value == 0 then return " "; end
	--return Locale.ToNumber(value, "+#,###.#;-#,###.#");
	return Locale.ToNumber(math.floor((value*10)+0.5)/10, "+#,###.#;-#,###.#");
end

-- ===========================================================================
--	Return a string with a yield icon and a +/- based on yield amount.
-- ===========================================================================
function GetYieldString( yieldType:string, amount:number )
	return GetYieldTextIcon(yieldType)..GetYieldTextColor(yieldType)..toPlusMinusString(amount).."[ENDCOLOR]";
end


-- ===========================================================================
--	This function is from SupportFunctions.lua
--	return a table indexed by buildingType, with a table of GameInfo.GreatWorks in that building
-- ===========================================================================

function GetGreatWorksForCity(pCity:table)
	local result:table = {};
	if pCity then
		local pCityBldgs:table = pCity:GetBuildings();
		for buildingInfo in GameInfo.Buildings() do
			local buildingIndex:number = buildingInfo.Index;
			local buildingType:string = buildingInfo.BuildingType;
			if(pCityBldgs:HasBuilding(buildingIndex)) then
				local numSlots:number = pCityBldgs:GetNumGreatWorkSlots(buildingIndex);
				if (numSlots ~= nil and numSlots > 0) then
					local greatWorksInBuilding:table = {};

					-- populate great works
					for index:number=0, numSlots - 1 do
						local greatWorkIndex:number = pCityBldgs:GetGreatWorkInSlot(buildingIndex, index);
						if greatWorkIndex ~= -1 then
							local greatWorkType:number = pCityBldgs:GetGreatWorkTypeFromIndex(greatWorkIndex);
							table.insert(greatWorksInBuilding, GameInfo.GreatWorks[greatWorkType]);
							-- YIELDS: only Tourism (field Tourism)
						end
					end

					-- create association between building type and great works
					if #greatWorksInBuilding > 0 then
						result[buildingType] = greatWorksInBuilding;
					end
					-- THEMED use pCityBldgs:IsBuildingThemedCorrectly()
					-- local regularTourism:number = pCityBldgs:GetBuildingTourismFromGreatWorks(false, buildingIndex);
					-- local religionTourism:number = pCityBldgs:GetBuildingTourismFromGreatWorks(true, buildingIndex);
					-- local yieldValue:number = pCityBldgs:GetBuildingYieldFromGreatWorks(yieldIndex, buildingIndex);
				end
			end
		end
	end
	return result;
end


-- ===========================================================================
-- A function for grabbing city data - from City Support by Firaxis
-- ===========================================================================

-- ===========================================================================
--	CONSTANTS
-- ===========================================================================
DATA_DOMINANT_RELIGION = "_DOMINANTRELIGION";

YIELD_STATE = {
	NORMAL  = 0,
	FAVORED = 1,
	IGNORED = 2
}


-- ===========================================================================
--	Obtains the texture for a city's current production.
--	pCity				The city
--	optionalIconSize	Size of the icon to return.
--
--	RETURNS	NIL if error, otherwise a table containing:
--			name of production item
--			description
--			icon texture of the produced item
--			u offset of the icon texture
--			v offset of the icon texture
--			(0-1) percent complete
--			(0-1) percent complete after next turn
--			# of turns
--			progress
--			cost
-- ===========================================================================
function GetCurrentProductionInfoOfCity( pCity:table, iconSize:number )
	local pBuildQueue	:table = pCity:GetBuildQueue();
	if pBuildQueue == nil then
		UI.DataError("No production queue in city!");
		return nil;
	end	
	local hash	:number = pBuildQueue:GetCurrentProductionTypeHash();
	local data	:table  = GetProductionInfoOfCity(pCity, hash);
	return data;
end


-- ===========================================================================
--	Update the yield data for a city.
-- ===========================================================================
--[[
function UpdateYieldData( pCity:table, data:table )
	data.CulturePerTurn				= pCity:GetYield( YieldTypes.CULTURE );
	data.CulturePerTurnToolTip		= pCity:GetYieldToolTip(YieldTypes.CULTURE);

	data.FaithPerTurn				= pCity:GetYield( YieldTypes.FAITH );
	data.FaithPerTurnToolTip		= pCity:GetYieldToolTip(YieldTypes.FAITH);

	data.FoodPerTurn				= pCity:GetYield( YieldTypes.FOOD );
	data.FoodPerTurnToolTip			= pCity:GetYieldToolTip(YieldTypes.FOOD);

	data.GoldPerTurn				= pCity:GetYield( YieldTypes.GOLD );
	data.GoldPerTurnToolTip			= pCity:GetYieldToolTip(YieldTypes.GOLD);

	data.ProductionPerTurn			= pCity:GetYield( YieldTypes.PRODUCTION );
	data.ProductionPerTurnToolTip	= pCity:GetYieldToolTip(YieldTypes.PRODUCTION);

	data.SciencePerTurn				= pCity:GetYield( YieldTypes.SCIENCE );
	data.SciencePerTurnToolTip		= pCity:GetYieldToolTip(YieldTypes.SCIENCE);

	return data;
end
--]]

-- ===========================================================================
-- ===========================================================================
function GetDistrictYieldText(district)
	local yieldText = "";
	for yield in GameInfo.Yields() do
		local yieldAmount = district:GetYield(yield.Index);
		if yieldAmount > 0 then
			yieldText = yieldText .. GetYieldString( yield.YieldType, yieldAmount );
		end
	end
	return yieldText;
end


-- ===========================================================================
--	Obtain the total resources for a given city.
-- ===========================================================================
function GetCityResourceData( pCity:table )

	-- Loop through all the plots for a given city; tallying the resource amount.
	local kResources : table = {};
	local cityPlots : table = Map.GetCityPlots():GetPurchasedPlots(pCity)
	for _, plotID in ipairs(cityPlots) do
		local plot			: table = Map.GetPlotByIndex(plotID)
		local plotX			: number = plot:GetX()
		local plotY			: number = plot:GetY()
		local eResourceType : number = plot:GetResourceType();

		-- TODO: Account for trade/diplomacy resources.
		if eResourceType ~= -1 and Players[pCity:GetOwner()]:GetResources():IsResourceExtractableAt(plot) then
			if kResources[eResourceType] == nil then
				kResources[eResourceType] = 1;
			else
				kResources[eResourceType] = kResources[eResourceType] + 1;
			end
		end
	end
	return kResources;
end

-- ===========================================================================
-- Retrieve Governor data, if applicable
-- Is established?, Count how many promotions a governor has
function GetGovernorData(pCity:table)
	if not bIsRiseAndFall then return false, 0 end
	local pGovernor:table = pCity:GetAssignedGovernor()
	if not pGovernor then return false, 0 end
	-- count promotions
	local iNumPromos:number = 0
	local sGovernorType:string = GameInfo.Governors[ pGovernor:GetType() ].GovernorType
	for row in GameInfo.GovernorPromotions() do
		if row.GovernorType == sGovernorType and pGovernor:HasPromotion(row.Index) then iNumPromos = iNumPromos + 1 end
	end
	return pGovernor:IsEstablished(), iNumPromos
end

-- ===========================================================================
--	For a given city, return a table o' data for it and the surrounding
--	districts.
--	RETURNS:	table of data
--				.City - city object
--				.field - city data
--				.Districts - table of Districts (has Buildings inside)
--						.Buildings - table of Buildings in the District
--				.Wonders - wonders
--				.OutgoingRoutes - trade routes
-- ===========================================================================
function GetCityData( pCity:table )

	local ownerID				:number = pCity:GetOwner();
	local pPlayer				:table	= Players[ownerID];
	local pCityDistricts		:table	= pCity:GetDistricts();
	local pMainDistrict			:table	= pPlayer:GetDistricts():FindID( pCity:GetDistrictID() );	-- Note player GetDistrict's object is different than above.
	local districtHitpoints		:number	= 0;
	local currentDistrictDamage :number = 0;
	local wallHitpoints			:number	= 0;
	local currentWallDamage		:number	= 0;
	local garrisonDefense		:number	= 0;

	if pCity ~= nil and pMainDistrict ~= nil then
		districtHitpoints		= pMainDistrict:GetMaxDamage(DefenseTypes.DISTRICT_GARRISON);
		currentDistrictDamage	= pMainDistrict:GetDamage(DefenseTypes.DISTRICT_GARRISON);
		wallHitpoints			= pMainDistrict:GetMaxDamage(DefenseTypes.DISTRICT_OUTER);
		currentWallDamage		= pMainDistrict:GetDamage(DefenseTypes.DISTRICT_OUTER);
		garrisonDefense			= math.floor(pMainDistrict:GetDefenseStrength() + 0.5);
	end

	-- Return value is here, 0/nil may be filled out below.
	local data :table = {
		City					= pCity,
		SubjectType				= SubjectTypes.City,
		Name					= Locale.Lookup(pCity:GetName()),
		Yields 					= YieldTableNew(), -- extended yields
		ContinentType			= 0,
		Districts				= {},		-- Per Entry Format: { Name, YieldType, YieldChange, Buildings={ Name,YieldType,YieldChange,isPillaged,isBuilt} }
		FoodSurplus				= 0,
		IsGovernorEstablished	= false,
		NumDistricts			= 0,
		NumSpecialtyDistricts	= 0,
		Population				= pCity:GetPopulation(),
		Wonders					= {},		-- Format per entry: { Name, YieldType, YieldChange }
		Plot 					= Map.GetPlot(pCity:GetX(), pCity:GetY()),
		--- not used yet
		AmenitiesNetAmount				= 0,
		AmenitiesNum					= 0,
		AmenitiesFromLuxuries			= 0,
		AmenitiesFromEntertainment		= 0,
		AmenitiesFromCivics				= 0,
		AmenitiesFromGreatPeople		= 0,
		AmenitiesFromCityStates			= 0,
		AmenitiesFromReligion			= 0,
		AmenitiesFromNationalParks  	= 0,
		AmenitiesFromStartingEra		= 0,
		AmenitiesFromImprovements		= 0,
		AmenitiesRequiredNum			= 0,
		AmenitiesFromGovernors			= 0,
		BeliefsOfDominantReligion		= {},
		Buildings						= {},		-- Per Entry Format: { Name, CitizenNum }
		BuildingsNum					= 0,
		CityWallTotalHP					= 0,
		CityWallHPPercent				= 0,
		CulturePerTurn					= 0,
		CurrentFoodPercent				= 0;		
		CurrentProdPercent				= 0,
		CurrentProductionName			= "",
		CurrentProductionDescription	= "",
		CurrentTurnsLeft				= 0,
		Damage							= 0,
		Defense							= garrisonDefense;
		DistrictsNum					= pCityDistricts:GetNumZonedDistrictsRequiringPopulation(),
		DistrictsPossibleNum			= pCityDistricts:GetNumAllowedDistrictsRequiringPopulation(),
		FaithPerTurn					= 0,
		FoodPercentNextTurn				= 0,
		FoodPerTurn						= 0,
		GoldPerTurn						= 0,
		GrowthPercent					= 100,
		Happiness						= 0,		
		HappinessGrowthModifier			= 0,		-- Multiplier
		HappinessNonFoodYieldModifier	= 0,		-- Multiplier
		Housing							= 0,
		HousingMultiplier				= 0,
		IsCapital						= pCity:IsCapital(),
		IsUnderSiege					= false,
		OccupationMultiplier            = 0,
		OwnerID							= ownerID,
		OtherGrowthModifiers			= 0,
		PantheonBelief					= -1,
		ProdPercentNextTurn				= 0,
		ProductionPerTurn				= 0;		
		ProductionQueue					= {},
		Religions						= {},		-- Format per entry: { Name, Followers }
		ReligionFollowers				= 0,
		SciencePerTurn					= 0,
		TradingPosts					= {},		-- Format per entry: { Player Number }
		TurnsUntilGrowth				= 0,
		TurnsUntilExpansion				= 0,
		UnitStats						= nil,
		--YieldFilters					= {},
	};

	-- extended yields
	for yield,yid in pairs(YieldTypes) do data.Yields[ yield ] = pCity:GetYield( yid ); end
	
	local pCityGrowth					:table = pCity:GetGrowth();
	local pCityCulture					:table = pCity:GetCulture();
	local cityGold						:table = pCity:GetGold();		
	local pBuildQueue					:table = pCity:GetBuildQueue();
	local currentProduction				:string = "LOC_HUD_CITY_PRODUCTION_NOTHING_PRODUCED";
	local currentProductionDescription	:string = "";
	local currentProductionStats		:string = "";
	local pct							:number = 0;
	local pctNextTurn					:number = 0;
	local prodTurnsLeft					:number = -1;
	local productionInfo				:table = nil; --GetCurrentProductionInfoOfCity( pCity, SIZE_PRODUCTION_ICON ); -- Infixo: NO PRODUCTION INFO YET

	-- extended yields
	data.Yields.HOUSING = pCityGrowth:GetHousing();
	data.Yields.AMENITY = pCityGrowth:GetAmenities();
	
	-- additional data
	data.IsGovernorEstablished, data.NumGovernorPromotions = GetGovernorData(pCity)
	data.ContinentType = Map.GetPlot( pCity:GetX(), pCity:GetY() ):GetContinentType()
	data.GreatWorks = GetGreatWorksForCity(pCity)

	-- Garrison in a city
	data.IsGarrisonUnit = false;
	local pPlotCity:table = Map.GetPlot( pCity:GetX(), pCity:GetY() );
	for _,unit in ipairs(Units.GetUnitsInPlot(pPlotCity)) do
		if GameInfo.Units[ unit:GetUnitType() ].FormationClass == "FORMATION_CLASS_LAND_COMBAT" then data.IsGarrisonUnit = true; break; end
	end

	-- If something is currently being produced, mark it in the queue.
	if productionInfo ~= nil then
		currentProduction				= productionInfo.Name;
		currentProductionDescription	= productionInfo.Description;
		if(productionInfo.StatString ~= nil) then
			currentProductionStats		= productionInfo.StatString;
		end
		pct								= productionInfo.PercentComplete;
		pctNextTurn						= productionInfo.PercentCompleteNextTurn;
		prodTurnsLeft					= productionInfo.Turns;
		productionInfo.Index			= 1;
		data.ProductionQueue[1]			= productionInfo;	--Place in front

		-- Some buildings will not have a description.
		if currentProductionDescription == nil then
			currentProductionDescription = "";
		end
	end

	-- current production type
	data.CurrentProductionType = "NONE";
	local iCurrentProductionHash:number = pCity:GetBuildQueue():GetCurrentProductionTypeHash();
	if iCurrentProductionHash ~= 0 then
		if     GameInfo.Buildings[iCurrentProductionHash] ~= nil then data.CurrentProductionType = "BUILDING";
		elseif GameInfo.Districts[iCurrentProductionHash] ~= nil then data.CurrentProductionType = "DISTRICT";
		elseif GameInfo.Units[iCurrentProductionHash]     ~= nil then data.CurrentProductionType = "UNIT";
		elseif GameInfo.Projects[iCurrentProductionHash]  ~= nil then data.CurrentProductionType = "PROJECT";
		end
	end

	local isGrowing	:boolean = pCityGrowth:GetTurnsUntilGrowth() ~= -1;
	local isStarving:boolean = pCityGrowth:GetTurnsUntilStarvation() ~= -1;

	local turnsUntilGrowth :number = 0;	-- It is possible for zero... no growth and no starving.
	if isGrowing then
		turnsUntilGrowth = pCityGrowth:GetTurnsUntilGrowth();
	elseif isStarving then
		turnsUntilGrowth = -pCityGrowth:GetTurnsUntilStarvation();	-- Make negative
	end	
		
	local food             :number = pCityGrowth:GetFood();
	local growthThreshold  :number = pCityGrowth:GetGrowthThreshold();
	local foodSurplus      :number = pCityGrowth:GetFoodSurplus();
	local foodpct          :number = math.max( math.min( food / growthThreshold, 1.0 ), 0.0);
	local foodpctNextTurn  :number = 0;
	if turnsUntilGrowth > 0 then
		local foodGainNextTurn = foodSurplus * pCityGrowth:GetOverallGrowthModifier();
		foodpctNextTurn = (food + foodGainNextTurn) / growthThreshold;
		foodpctNextTurn = math.max( math.min( foodpctNextTurn, 1.0), 0.0 );
	end

	-- Three religion objects to work with: overall game object, the player's religion, and this specific city's religious population
	local pGameReligion		:table = Game.GetReligion();
	local pPlayerReligion	:table = pPlayer:GetReligion();
	local pAllReligions		:table = pGameReligion:GetReligions();
	local pReligions		:table = pCity:GetReligion():GetReligionsInCity();	
	local eDominantReligion	:number = pCity:GetReligion():GetMajorityReligion();
	local followersAll		:number = 0;
	for _, religionData in pairs(pReligions) do				

		-- If the value for the religion type is less than 0, there is no religion (citizens working towards a Patheon).
		local religionType	:string = (religionData.Religion > 0) and GameInfo.Religions[religionData.Religion].ReligionType or "RELIGION_PANTHEON";
		local thisReligion	:table = { ID=religionData.Religion, ReligionType=religionType, Followers=religionData.Followers };
		table.insert( data.Religions, thisReligion );		

		if religionData.Religion == eDominantReligion and eDominantReligion > -1 then
			data.Religions[DATA_DOMINANT_RELIGION] = thisReligion;
			for _,kFoundReligion in ipairs(pAllReligions) do
				if kFoundReligion.Religion == eDominantReligion then
					for _,belief in pairs(kFoundReligion.Beliefs) do
						table.insert( data.BeliefsOfDominantReligion, belief );
					end
					break;
				end
			end
		end

		if religionType ~= "RELIGION_PANTHEON" then
			followersAll = followersAll + religionData.Followers;
		end
	end

	-- number of followers of the main religion (from ReportScreen.lua)
	data.MajorityReligionFollowers = 0;
	--local eDominantReligion:number = pCity:GetReligion():GetMajorityReligion();
	if eDominantReligion > 0 then -- WARNING! this rules out pantheons!
		for _, religionData in pairs(pCity:GetReligion():GetReligionsInCity()) do
			if religionData.Religion == eDominantReligion then data.MajorityReligionFollowers = religionData.Followers; end
		end
	end
	--print("Majority religion followers for", cityName, data.MajorityReligionFollowers);
	
	data.AmenitiesNetAmount				= pCityGrowth:GetAmenities() - pCityGrowth:GetAmenitiesNeeded();
	data.AmenitiesNum					= pCityGrowth:GetAmenities();
	data.AmenitiesFromLuxuries			= pCityGrowth:GetAmenitiesFromLuxuries();
	data.AmenitiesFromEntertainment		= pCityGrowth:GetAmenitiesFromEntertainment();
	data.AmenitiesFromCivics			= pCityGrowth:GetAmenitiesFromCivics();
	data.AmenitiesFromGreatPeople		= pCityGrowth:GetAmenitiesFromGreatPeople();
	data.AmenitiesFromCityStates		= pCityGrowth:GetAmenitiesFromCityStates();
	data.AmenitiesFromReligion			= pCityGrowth:GetAmenitiesFromReligion();
	data.AmenitiesFromNationalParks		= pCityGrowth:GetAmenitiesFromNationalParks();
	data.AmenitiesFromStartingEra		= pCityGrowth:GetAmenitiesFromStartingEra();
	data.AmenitiesFromImprovements		= pCityGrowth:GetAmenitiesFromImprovements();
	data.AmenitiesLostFromWarWeariness	= pCityGrowth:GetAmenitiesLostFromWarWeariness();
	data.AmenitiesLostFromBankruptcy	= pCityGrowth:GetAmenitiesLostFromBankruptcy();
	data.AmenitiesRequiredNum			= pCityGrowth:GetAmenitiesNeeded();
	--data.AmenitiesFromGovernors			= pCityGrowth:GetAmenitiesFromGovernors();
	data.AmenityAdvice					= pCity:GetAmenityAdvice();
	data.CityWallHPPercent				= (wallHitpoints-currentWallDamage) / wallHitpoints;
	data.CityWallCurrentHP				= wallHitpoints-currentWallDamage;
	data.CityWallTotalHP				= wallHitpoints;
	data.CurrentFoodPercent				= foodpct;
	data.CurrentProductionName			= Locale.Lookup( currentProduction );
	data.CurrentProdPercent				= pct;
	data.CurrentProductionDescription	= Locale.Lookup( currentProductionDescription );
	data.CurrentProductionIcon			= productionInfo and productionInfo.Icon;
	data.CurrentProductionStats			= productionInfo and productionInfo.StatString;
	data.CurrentTurnsLeft				= prodTurnsLeft;		
	data.FoodPercentNextTurn			= foodpctNextTurn;
	data.FoodSurplus					= foodSurplus; --Round( foodSurplus, 1); -- this is rounded to integer actually already
	data.Happiness						= pCityGrowth:GetHappiness();
	data.HappinessGrowthModifier		= pCityGrowth:GetHappinessGrowthModifier();
	data.HappinessNonFoodYieldModifier	= pCityGrowth:GetHappinessNonFoodYieldModifier();
	data.HitpointPercent				= ((districtHitpoints-currentDistrictDamage) / districtHitpoints);
	data.HitpointsCurrent				= districtHitpoints-currentDistrictDamage;
	data.HitpointsTotal					= districtHitpoints;
	data.Housing						= pCityGrowth:GetHousing();
	data.HousingFromWater				= pCityGrowth:GetHousingFromWater();
	data.HousingFromBuildings			= pCityGrowth:GetHousingFromBuildings();
	data.HousingFromImprovements		= pCityGrowth:GetHousingFromImprovements();
	data.HousingFromDistricts			= pCityGrowth:GetHousingFromDistricts();
	data.HousingFromCivics				= pCityGrowth:GetHousingFromCivics();
	data.HousingFromGreatPeople			= pCityGrowth:GetHousingFromGreatPeople();
	data.HousingFromStartingEra			= pCityGrowth:GetHousingFromStartingEra();
	data.HousingMultiplier				= pCityGrowth:GetHousingGrowthModifier();
	data.HousingAdvice					= pCity:GetHousingAdvice();
	data.OccupationMultiplier			= pCityGrowth:GetOccupationGrowthModifier();
	data.Occupied                       = pCity:IsOccupied();
	data.OtherGrowthModifiers			= pCityGrowth:GetOtherGrowthModifier();	-- Growth modifiers from Religion & Wonders
	data.PantheonBelief					= pPlayerReligion:GetPantheon();	
	data.ProdPercentNextTurn			= pctNextTurn;
	data.ReligionFollowers				= followersAll;
	data.TurnsUntilExpansion			= pCityCulture:GetTurnsUntilExpansion();
	data.TurnsUntilGrowth				= turnsUntilGrowth;
	data.UnitStats						= nil; --GetUnitStats( pBuildQueue:GetCurrentProductionTypeHash() );	--NIL if not a unit -- Infixo: NO UNIT STATS
	
	-- Helper to get an internally used enum based on the state of a certain yield.
	--[[
	local pCitizens :table = pCity:GetCitizens();
	function GetYieldState( yieldEnum:number )
		if pCitizens:IsFavoredYield(yieldEnum) then			return YIELD_STATE.FAVORED;
		elseif pCitizens:IsDisfavoredYield(yieldEnum) then	return YIELD_STATE.IGNORED;
		else												return YIELD_STATE.NORMAL;
		end
	end	 		
	data.YieldFilters[YieldTypes.CULTURE]	= GetYieldState(YieldTypes.CULTURE);
	data.YieldFilters[YieldTypes.FAITH]		= GetYieldState(YieldTypes.FAITH);
	data.YieldFilters[YieldTypes.FOOD]		= GetYieldState(YieldTypes.FOOD);
	data.YieldFilters[YieldTypes.GOLD]		= GetYieldState(YieldTypes.GOLD);
	data.YieldFilters[YieldTypes.PRODUCTION]= GetYieldState(YieldTypes.PRODUCTION);
	data.YieldFilters[YieldTypes.SCIENCE]	= GetYieldState(YieldTypes.SCIENCE);
	--]]
	--data = UpdateYieldData( pCity, data );

	-- Determine builds, districts, and wonders
	local pCityBuildings	:table = pCity:GetBuildings();
	local kCityPlots		:table = Map.GetCityPlots():GetPurchasedPlots( pCity );
	if (kCityPlots ~= nil) then
		for _,plotID in pairs(kCityPlots) do
			local kPlot:table =  Map.GetPlotByIndex(plotID);
			local kBuildingTypes:table = pCityBuildings:GetBuildingsAtLocation(plotID);
			for _, type in ipairs(kBuildingTypes) do
				local building	= GameInfo.Buildings[type];
				table.insert( data.Buildings, { 
					Name		= GameInfo.Buildings[building.BuildingType].Name, 
					Citizens	= kPlot:GetWorkerCount(),
					isPillaged	= pCityBuildings:IsPillaged(type),
					Maintenance	= GameInfo.Buildings[building.BuildingType].Maintenance			--Expense in gold
				});
			end
		end
	end	

	local pDistrict : table = pPlayer:GetDistricts():FindID( pCity:GetDistrictID() );
	if pDistrict ~= nil then
		data.IsUnderSiege = pDistrict:IsUnderSiege();
	else
		UI.DataError("Some data will be missing as unable to obtain the corresponding district for city: "..pCity:GetName());
	end

	-------------------------------------
	-- DISTRICTS
	for i, district in pCityDistricts:Members() do

		-- Helper to obtain yields for a district: build a lookup table and then match type.
		local kTempDistrictYields :table = {};
		for yield in GameInfo.Yields() do
			kTempDistrictYields[yield.Index] = yield;
		end
		-- ==========
		function GetDistrictYield( district:table, yieldType:string )
			for i,yield in ipairs( kTempDistrictYields ) do
				if yield.YieldType == yieldType then
					return district:GetYield(i);
				end
			end
			return 0;
		end

		--I do not know why we make local functions, but I am keeping standard
		function GetDistrictBonus( district:table, yieldType:string )
			for i,yield in ipairs( kTempDistrictYields ) do
				if yield.YieldType == yieldType then
					return district:GetAdjacencyYield(i);
				end
			end
			return 0;
		end


		local districtInfo	:table	= GameInfo.Districts[district:GetType()];
		local districtType	:string = districtInfo.DistrictType;	
		local locX			:number = district:GetX();
		local locY			:number = district:GetY();
		local kPlot			:table  = Map.GetPlot(locX,locY);
		local plotID		:number = kPlot:GetIndex();	
		local districtTable :table	= { 
			SubjectType		= SubjectTypes.District,
			Name			= data.Name..": "..Locale.Lookup(districtInfo.Name),
			Plot 			= kPlot,
			Yields   		= YieldTableNew(), -- district yields (from adjacency)
			--AdjYields   = YieldTableNew(), -- adjacency bonus yields -- Infixo: ADJACENCY = STANDARD YIELD
			DistrictType 	= districtType,
			CityCenter		= districtInfo.CityCenter,
			OnePerCity		= districtInfo.OnePerCity,
			-- not used yet
			YieldBonus	= GetDistrictYieldText( district ),
			isPillaged  = pCityDistricts:IsPillaged(district:GetType()),
			isBuilt		= district:IsComplete(),--pCityDistricts:HasDistrict(districtInfo.Index, true);
			Icon		= "ICON_"..districtType,
			Buildings	= {},
			--Culture		= GetDistrictYield(district, "YIELD_CULTURE" ),			
			--Faith		= GetDistrictYield(district, "YIELD_FAITH" ),
			--Food		= GetDistrictYield(district, "YIELD_FOOD" ),
			--Gold		= GetDistrictYield(district, "YIELD_GOLD" ),
			--Production	= GetDistrictYield(district, "YIELD_PRODUCTION" ),
			--Science		= GetDistrictYield(district, "YIELD_SCIENCE" ),
			Tourism		= 0,
			Maintenance = districtInfo.Maintenance,
			--[[
			AdjacencyBonus = {
				Culture		= GetDistrictBonus(district, "YIELD_CULTURE"),
				Faith		= GetDistrictBonus(district, "YIELD_FAITH"),
				Food		= GetDistrictBonus(district, "YIELD_FOOD"),
				Gold		= GetDistrictBonus(district, "YIELD_GOLD"),
				Production	= GetDistrictBonus(district, "YIELD_PRODUCTION"),
				Science		= GetDistrictBonus(district, "YIELD_SCIENCE"),
			},
			--]]
		};
		-- count all districts and specialty ones
		if district:IsComplete() and not districtInfo.CityCenter and                             districtType ~= "DISTRICT_WONDER" then
			data.NumDistricts = data.NumDistricts + 1;
		end
		if district:IsComplete() and not districtInfo.CityCenter and districtInfo.OnePerCity and districtType ~= "DISTRICT_WONDER" then
			data.NumSpecialtyDistricts = data.NumSpecialtyDistricts + 1;
		end
		
		-- extended yields -- Infixo: CHECK seems that Districts don't produce yields by themselves, only adjacency yields
		-- there is no table for that, also both functions produce the same results
		-- BUT! There is ADJUST_DISTRICT_YIELD_CHANGE, used by MODIFIER_PLAYER_DISTRICTS_ADJUST_YIELD_CHANGE and MODIFIER_PLAYER_DISTRICT_ADJUST_YIELD_CHANGE and ADJUST_DISTRICT_EXTRA_REGIONAL_YIELD for MODIFIER_PLAYER_DISTRICT_ADJUST_EXTRA_REGIONAL_YIELD
		-- the first is used by Minors to adjust yields (e.g. MINOR_CIV_SCIENTIFIC_YIELD_FOR_CAMPUS, attached when Medium influence), the other two are not used
		-- the third ise used by GREATPERSON_EXTRA_REGIONAL_BUILDING_PRODUCTION
		-- OK, Minors are giving yields to Buildings now, not Districts, different modifiers are used
		-- Another problem is that calling it with 6 gives negative big integers, unknown (bug?)
		--for yield,yid in pairs(YieldTypes) do districtTable.Yields[ yield ] = district:GetYield( yid ); end
		--for yield,yid in pairs(YieldTypes) do districtTable.Yields[ yield ] = district:GetAdjacencyYield( yid ); end -- Infixo: ADJACENCY = STANDARD YIELD
		--districtTable.Yields.TOURISM = 0; -- tourism is produced in another way, GetYield() produces stupid numbers here
		-- SECOND APPROACH
		-- GetYield and GetAdjacencyYield give yields AFTER applying modifiers
		-- We can get raw, unmodified yields from Plot:GetAdjacencyYield, however this requires a bit more complex call
		-- kPlot holds the plot, district:GetType(), also produces 0 for index=6, so it's ok
		for yield,yid in pairs(YieldTypes) do
			districtTable.Yields[ yield ] = kPlot:GetAdjacencyYield(ownerID, pCity:GetID(), district:GetType(), yid)
		end

		---------------------------------------------------------------------
		-- BUILDINGS
		local buildingTypes = pCityBuildings:GetBuildingsAtLocation(plotID);
		for _, buildingType in ipairs(buildingTypes) do -- buildingType is an Index here
			local building		:table = GameInfo.Buildings[buildingType];
			local sBuildingType:string = building.BuildingType;
			--local kYields		:table = {}; -- not used

			-- Obtain yield info for buildings.
			--[[ Infixo noy used
			for yieldRow in GameInfo.Yields() do
				local yieldChange = pCity:GetBuildingYield(buildingType, yieldRow.YieldType);
				if yieldChange ~= 0 then
					table.insert( kYields, {
						YieldType	= yieldRow.YieldType,
						YieldChange	= yieldChange
					});
				end
			end
			--]]
			-- Helper: to extract a particular yield type
			--[[ Infixo not used
			function YieldFind( kYields:table, yieldType:string )
				for _,yield in ipairs(kYields) do
					if yield.YieldType == yieldType then
						return yield.YieldChange;
					end
				end
				return 0;	-- none found
			end
			--]]
			-- Duplicate of data but common yields in an easy to parse format.
			--local culture	:number = YieldFind( kYields, "YIELD_CULTURE" );
			--local faith		:number = YieldFind( kYields, "YIELD_FAITH" );
			--local food		:number = YieldFind( kYields, "YIELD_FOOD" );
			--local gold		:number = YieldFind( kYields, "YIELD_GOLD" );
			--local production:number = YieldFind( kYields, "YIELD_PRODUCTION" );
			--local science	:number = YieldFind( kYields, "YIELD_SCIENCE" );
			-- extended yields
			local extyields :table = YieldTableNew();
			-- fix for certain policies based on building yields
			-- pCity:GetBuildingYield does NOT return a base yield, only processed one, so if the policy is selected, then it calculates the effect twice
			-- use the base data from DB
			function GetBuildingBaseYield(sBuildingType:string, sYieldType:string)
				--print("GetBuildingBaseYield", sBuildingType, sYieldType);
				for row in GameInfo.Building_YieldChanges() do
					if row.BuildingType == sBuildingType and row.YieldType == sYieldType then return row.YieldChange; end
				end
				return 0;
			end
			--for yield,yid in pairs(YieldTypes) do extyields[ yield ] = pCity:GetBuildingYield(buildingType, yid); end
			for yield,_ in pairs(YieldTypes) do extyields[ yield ] = GetBuildingBaseYield(sBuildingType, "YIELD_"..yield); end
			-- extyields.TOURISM = 0; -- tourism is produced in another way, GetBuildingYield() produces stupid numbers here ??? I don't know, the bug is for districts for sure
			
			if building.IsWonder then
				table.insert( data.Wonders, {
					SubjectType			= SubjectTypes.Building,
					Name				= Locale.Lookup(building.Name), 
					Yields				= extyields,
					BuildingType		= sBuildingType,
					-- not used yet
					--Yields				= kYields,
					Icon				= "ICON_"..sBuildingType,
					--Citizens
					isPillaged			= pCityBuildings:IsPillaged(building.BuildingType),
					isBuilt				= pCityBuildings:HasBuilding(building.Index),
					--CulturePerTurn		= culture,	
					--FaithPerTurn		= faith,		
					--FoodPerTurn			= food,		
					--GoldPerTurn			= gold,		
					--ProductionPerTurn	= production,
					--SciencePerTurn		= science,
				});
			else
				data.BuildingsNum = data.BuildingsNum + 1;
				table.insert( districtTable.Buildings, { 
					SubjectType			= SubjectTypes.Building,
					Name				= Locale.Lookup(building.Name),
					Yields				= extyields,
					BuildingType		= sBuildingType,
					-- not used yet
					--Yields				= kYields,
					Icon				= "ICON_"..sBuildingType,
					Citizens			= kPlot:GetWorkerCount(),
					isPillaged			= pCityBuildings:IsPillaged(buildingType);
					isBuilt				= pCityBuildings:HasBuilding(building.Index);
					--CulturePerTurn		= culture,	
					--FaithPerTurn		= faith,		
					--FoodPerTurn			= food,		
					--GoldPerTurn			= gold,		
					--ProductionPerTurn	= production,
					--SciencePerTurn		= science,
				});
			end

		end

		-- Add district unless it's the special wonder district; toss that one.
		if districtType ~= "DISTRICT_WONDER" then
			table.insert( data.Districts, districtTable );
		end
	end

	---------------------------------------------------------------
	-- TRADING POSTS
	local pTrade:table = pCity:GetTrade();
	for iPlayer:number = 0, MapConfiguration.GetMaxMajorPlayers()-1,1 do
		if (pTrade:HasActiveTradingPost(iPlayer)) then
			table.insert( data.TradingPosts, iPlayer );
		end
	end

	---------------------------------------------------------------
	-- TRADE ROUTES
	local pPlayerDiplomaticAI:table = pPlayer:GetDiplomaticAI()
	data.OutgoingRoutes = {}
	data.NumRoutesDomestic = 0
	data.NumRoutesInternational = 0
	for _,route in ipairs(pTrade:GetOutgoingRoutes()) do
		local routeData:table = {
			SubjectType = SubjectTypes.TradeRoute,
			Name        = "", -- later
			IsDomestic  = (route.OriginCityPlayer == route.DestinationCityPlayer), -- boolean
			Yields      = YieldTableNew(), -- later
			NumImprovedResourcesAtDestination = 0, -- later
			IsDestinationPlayerAlly = false, -- later
			NumSpecialtyDistricts = 0, -- later
		}
		-- copy yields
		for _,yield in ipairs(route.OriginYields) do
			YieldTableSetYield(routeData.Yields, GameInfo.Yields[yield.YieldIndex].YieldType, yield.Amount)
		end
	
		-- counters
		if routeData.IsDomestic then data.NumRoutesDomestic      = data.NumRoutesDomestic + 1
		else                         data.NumRoutesInternational = data.NumRoutesInternational + 1 end

		-- Find destination city
		local pDestPlayer:table = Players[ route.DestinationCityPlayer ] -- can be used to find out diplo details
		local pDestCity:table = pDestPlayer:GetCities():FindID(route.DestinationCityID)
		routeData.Name = data.Name.." - "..Locale.Lookup(pDestCity:GetName())

		-- market economy: number of resources improved at destination (lux, strat)
		local tResources:table = GetCityResourceData(pDestCity) -- Firaxis function
		local function CountImprovedResources(sResourceClassToCount:string)
			local iNum:number = 0
			for eResourceType,amount in pairs(tResources) do
				if GameInfo.Resources[eResourceType].ResourceClassType == sResourceClassToCount then iNum = iNum + amount end
			end
			return iNum
		end
		routeData.NumImprovedResourcesStrategic = CountImprovedResources("RESOURCECLASS_STRATEGIC")
		routeData.NumImprovedResourcesLuxury    = CountImprovedResources("RESOURCECLASS_LUXURY")
		routeData.NumImprovedResourcesBonus     = CountImprovedResources("RESOURCECLASS_BONUS")
		-- if destination is Ally (diplo)
		routeData.IsDestinationPlayerAlly = ( GameInfo.DiplomaticStates[ pPlayerDiplomaticAI:GetDiplomaticStateIndex(route.DestinationCityPlayer) ].StateType == "DIPLO_STATE_ALLIED" )
		
		-- GreatPerson number of specialty districts at destination
		for _,district in pDestCity:GetDistricts():Members() do
			local districtInfo:table = GameInfo.Districts[ district:GetType() ];
			if district:IsComplete() and not districtInfo.CityCenter and districtInfo.OnePerCity and districtInfo.DistrictType ~= "DISTRICT_WONDER" then
				routeData.NumSpecialtyDistricts = routeData.NumSpecialtyDistricts + 1;
			end
		end
		
		table.insert(data.OutgoingRoutes, routeData)
	end
	data.NumRoutes = table.count(data.OutgoingRoutes)
	
	-- incoming routes are a bit easier, only yields are needed as for now
	data.IncomingRoutes = {}
	for _,route in ipairs(pTrade:GetIncomingRoutes()) do
		local routeData:table = {
			SubjectType = SubjectTypes.TradeRoute,
			Name        = "", -- later
			IsDomestic  = (route.OriginCityPlayer == route.DestinationCityPlayer), -- boolean
			Yields      = YieldTableNew(), -- later
		}
		-- copy yields
		for _,yield in ipairs(route.DestinationYields) do
			YieldTableSetYield(routeData.Yields, GameInfo.Yields[yield.YieldIndex].YieldType, yield.Amount)
		end

		-- Find origin city
		local pOriginPlayer:table = Players[ route.OriginCityPlayer ]
		local pOriginCity:table = pOriginPlayer:GetCities():FindID(route.OriginCityID)
		routeData.Name = Locale.Lookup(pOriginCity:GetName()).." - "..data.Name -- opposite to outgoing

		table.insert(data.IncomingRoutes, routeData)
	end
	
	-- done!
	return data
end


-- ===========================================================================
-- Obtain unit maintenance
-- This function will use GameInfo for vanilla game and UnitManager for Rise&Fall
function GetUnitMaintenance(pUnit:table)
	local iUnitMaintenance:number = GameInfo.Units[ pUnit:GetUnitType() ].Maintenance;
	local unitMilitaryFormation = pUnit:GetMilitaryFormation();
	if unitMilitaryFormation == MilitaryFormationTypes.CORPS_FORMATION then return math.ceil(iUnitMaintenance * 1.5); end -- it is 150% rounded UP
	if unitMilitaryFormation == MilitaryFormationTypes.ARMY_FORMATION  then return iUnitMaintenance * 2; end -- it is 200%
	                                                                        return iUnitMaintenance;
end

-- ===========================================================================
-- Diplomatic data (city states and allies)
-- Trade routes (?)
-- Units (?)
function GetPlayerData(ePlayerID:number)
	local pPlayer:table = Players[ Game.GetLocalPlayer() ]
	if ePlayerID then pPlayer = Players[ ePlayerID ] end
	if not pPlayer then return end -- error
	
	tPlayer 			= {} -- clear old data
	tPlayer.Player 		= pPlayer
	tPlayer.SubjectType = SubjectTypes.Player
	tPlayer.Name 		= Locale.Lookup(PlayerConfigurations[pPlayer:GetID()]:GetCivilizationShortDescription())
	tPlayer.Cities		= tCities
	
	-- YIELDS
	tPlayer.Yields = YieldTableNew()
	tPlayer.Yields.GOLD    = pPlayer:GetTreasury():GetGoldYield();
	tPlayer.Yields.SCIENCE = pPlayer:GetTechs():GetScienceYield();
	tPlayer.Yields.CULTURE = pPlayer:GetCulture():GetCultureYield();
	tPlayer.Yields.FAITH   = pPlayer:GetReligion():GetFaithYield();
	tPlayer.Yields.TOURISM = pPlayer:GetStats():GetTourism();
	local iTotFood:number, iTotProd:number, iTotAmenity:number, iTotHousing:number = 0, 0, 0, 0
	for _,city in pPlayer:GetCities():Members() do
		iTotFood    = iTotFood    + city:GetGrowth():GetFoodSurplus()
		iTotAmenity = iTotAmenity + city:GetGrowth():GetAmenities()
		iTotHousing = iTotHousing + city:GetGrowth():GetHousing()
		iTotProd    = iTotProd    + city:GetBuildQueue():GetProductionYield()
	end
	tPlayer.Yields.FOOD = iTotFood
	tPlayer.Yields.PRODUCTION = iTotProd
	tPlayer.Yields.AMENITY = iTotAmenity
	tPlayer.Yields.HOUSING = iTotHousing

	-- TRADE ROUTES
	tPlayer.NumRoutes = 0
	tPlayer.NumRoutesDomestic = 0
	tPlayer.NumRoutesInternational = 0
	for cityname,city in pairs(tCities) do
		tPlayer.NumRoutes = tPlayer.NumRoutes + city.NumRoutes
		tPlayer.NumRoutesDomestic = tPlayer.NumRoutesDomestic + city.NumRoutesDomestic
		tPlayer.NumRoutesInternational = tPlayer.NumRoutesInternational + city.NumRoutesInternational
	end

	-- UNITS
	tPlayer.Units = {}
	for _,unit in pPlayer:GetUnits():Members() do
		local pUnitInfo:table = GameInfo.Units[ unit:GetUnitType() ]
		
		-- get localized unit name with appropriate suffix
		local unitName:string = Locale.Lookup(pUnitInfo.Name);
		local unitMilitaryFormation:number = unit:GetMilitaryFormation()
		if (unitMilitaryFormation == MilitaryFormationTypes.CORPS_FORMATION) then
			unitName = unitName.." [ICON_Corps]"
		elseif (unitMilitaryFormation == MilitaryFormationTypes.ARMY_FORMATION) then
			unitName = unitName.." [ICON_Army]"
		else
			--BRS Civilian units can be NO_FORMATION (-1) or STANDARD (0)
			unitMilitaryFormation = MilitaryFormationTypes.STANDARD_FORMATION; -- 0
		end
		local unitData:table = {
			SubjectType = SubjectTypes.Unit,
			Name = unitName,
			MilitaryFormation = unitMilitaryFormation,
			Maintenance = GetUnitMaintenance(unit),
			IsCivilian = (pUnitInfo.FormationClass == "FORMATION_CLASS_CIVILIAN"),
		}
		table.insert(tPlayer.Units, unitData)
	end

	-- WMDs
	tPlayer.WMDs = {
		Num = 0,
		Maintenance = 0,
	}
	for row in GameInfo.WMDs() do
		local iNum:number = pPlayer:GetWMDs():GetWeaponCount(row.Index)
		tPlayer.WMDs.Num = tPlayer.WMDs.Num + iNum
		tPlayer.WMDs.Maintenance = tPlayer.WMDs.Maintenance + iNum * row.Maintenance
	end
	
	-- CITY-STATES
	tPlayer.NumSuzerainCityStates = 0;
	tPlayer.NumInfluenceTokensGiven = 0;
	for _,minor in ipairs(PlayerManager.GetAliveMinors()) do
		-- we need to check for City State actually, because Free Cities are considered Minors as well
		if minor:IsMinor() then 
			if minor:GetInfluence():GetSuzerain() == pPlayer:GetID() then tPlayer.NumSuzerainCityStates = tPlayer.NumSuzerainCityStates + 1; end
			tPlayer.NumInfluenceTokensGiven = tPlayer.NumInfluenceTokensGiven + minor:GetInfluence():GetTokensReceived(pPlayer:GetID());
		end
	end

end


-- ===========================================================================
-- PLOT YIELDS

function GetPlotsData(ePlayerID:number)
	local pPlayer:table = Players[ Game.GetLocalPlayer() ];
	if ePlayerID then pPlayer = Players[ ePlayerID ]; end
	if not pPlayer then return; end -- error
	
	tPlots = {}; -- clear old data
	for _,city in pPlayer:GetCities():Members() do
		for _,plotIndex in ipairs(Map.GetCityPlots():GetPurchasedPlots(city)) do
			local pPlot:table = Map.GetPlotByIndex(plotIndex);
			if pPlot then
				local plotData:table = {
					SubjectType = SubjectTypes.Plot,
					Name = tostring(pPlot:GetX())..":"..tostring(pPlot:GetY()),
					Plot = pPlot,
				};
				table.insert(tPlots, plotData);
			end
		end
	end

end

-- ===========================================================================
-- MODIFIERS' STATIC DATA
-- ===========================================================================
-- 0. Start with ModifierId
-- 1. Retrieve all relevant data into a table that will store them for future use
--   1a. Retrieve data from Modifiers: ModifierType, 3x bools, OwnerReqSetId, SubjectReqSetId
--   1b. ModifierType is the key, retrieve data from DynamicModifiers: CollectionType, EffectType
--   1c. Retrieve data from ModifierArguments: table of key=Name, value=Value
--         ignore Extra (usually -1) and SecondExtra for now
--         Type could be 'ScaleByGameSpeed' - probably for value only; start with Standard Speed, add scaling later
-- 2. display raw data
-- 3. Analyze CollectionType
-- 4. Analyze EffectType
-- ===========================================================================

local tModifiers = {}; -- main table to store all modifiers; will be populated online, also acting as cache
-- Modifier
--   .ModifierId
--   .ModifierType
--   .RunOnce / .NewOnly / .Permanent
--   .OwnerReqSetId / .SubjectReqSetId
--   .OwnerReqSet / .SubjectReqSet
--   .CollectionType
--   .EffectType
--   .Arguments - table of {Name=Value}

local tReqs = {}; -- main table to store all requirements; will be populated online, also acting as cache
-- Req
--   .ReqId
--   .Arguments
--   more fields here

local tReqSets = {}; -- main table to store all requirement sets; will be populated online, also acting as cache
-- ReqSet
--   .ReqSetId
--   .TestAll / .TestAny
--   .Reqs - table of {Req}

local INDENT1 = "    ";
local INDENT2 = INDENT1..INDENT1;

function FetchAndCacheDataReq(sReqId:string)
	--dprint("FUNCAL FetchAndCacheDataReq(req)", sReqId);
	-- check if we already have it
	local tReq:table = tReqs[ sReqId ];
	if tReq then return tReq; end
	-- filters in GameInfo don't work for modifiers, we need to use normal search
	tReq = {};
	-- Requirements
	for req in GameInfo.Requirements() do
		if req.RequirementId == sReqId then
			--dprint("...found ", sReqId);
			tReq.ReqId         = sReqId;
			tReq.ReqType       = req.RequirementType;
			tReq.Inverse       = req.Inverse; -- boolean
			tReq.Persistent    = req.Persistent; -- boolean, only 1% are true - TODO: WHAT DOES IT DO?
			tReq.ProgressWeight= req.ProgressWeight; -- integer, 1% is 0, the rest is 1
			tReq.Triggered     = req.Triggered; -- boolean, only 2% are true
			-- .Likeliness, .Impact -- always 0
			-- .Reverse -- always false
			break;
		end
	end
	-- RequirementArguments - this one must be searched entirely
	tReq.Arguments = {};
	for arg in GameInfo.RequirementArguments() do
		if arg.RequirementId == sReqId then
			-- now we need to convert values into a proper type
			-- there are 81 names, so maybe we'll do it when actually trying to use it?
			--dprint("..found arg", arg.Name, arg.Value);
			tReq.Arguments[ arg.Name ] = arg.Value;
			-- special handling for Type not necessary (yet?) - all are ARGTYPE_IDENTITY
			--if arg.Type == "ScaleByGameSpeed" then
				-- add here: access game speed, multiply by it
				--tModifier.ScaleByGameSpeed = true;
			--end
		end
	end
	-- done!
	tReqs[ sReqId ] = tReq;
	return tReq;
end

function DecodeReq(tOut:table, sReqId:string)
	--dprint("FUNCAL DecodeReq(req)",sReqId);
	local tReq:table = FetchAndCacheDataReq(sReqId);
	if not tReq then return "ERROR: "..sReqId.." not defined!"; end
	table.insert(tOut, INDENT2..Capitalize(sReqId));
	table.insert(tOut, INDENT2.."Type: "..Capitalize(tReq.ReqType));
	for name,value in pairs(tReq.Arguments) do table.insert(tOut, INDENT2..name.." = "..value); end
	if tReq.Inverse then table.insert(tOut, INDENT2.."Inverse"); end
	if tReq.Persistent then table.insert(tOut, INDENT2.."Persistent"); end
	if tReq.Triggered then table.insert(tOut, INDENT2.."Triggered"); end
	table.insert(tOut, INDENT2.."ProgressWeight = "..tReq.ProgressWeight);
end


function FetchAndCacheDataReqSet(sReqSetId:string)
	--dprint("FUNCAL FetchAndCacheDataReqSet(req)", sReqSetId);
	-- check if we already have it
	local tReqSet:table = tReqSets[ sReqSetId ];
	if tReqSet then return tReqSet; end
	-- filters in GameInfo don't work for modifiers, we need to use normal search
	tReqSet = {};
	-- RequirementSets
	for req in GameInfo.RequirementSets() do
		if req.RequirementSetId == sReqSetId then
			--dprint("...found ", sReqSetId);
			tReqSet.ReqSetId = sReqSetId;
			tReqSet.TestAll = ( req.RequirementSetType == "REQUIREMENTSET_TEST_ALL" );-- 90% are TEST_ALL
			tReqSet.TestAny = ( req.RequirementSetType == "REQUIREMENTSET_TEST_ANY" );
			tReqSet.Reqs = {};
			break;
		end
	end
	-- check if it exists!
	if table.count(tReqSet) == 0 then return nil; end
	-- fill actual Requirements (from RequirementSetRequirements)
	for req in GameInfo.RequirementSetRequirements() do
		if req.RequirementSetId == sReqSetId then
			table.insert(tReqSet.Reqs, FetchAndCacheDataReq(req.RequirementId));
			-- it is possible that there will a call to another requirement via Type = REQUIREMENT_REQUIREMENTSET_IS_MET
			--if tReq.ReqType == "REQUIREMENT_REQUIREMENTSET_IS_MET" and tReq.Arguments.RequirementSetId then
				--DecodeReqSet(tOut, tReq.Arguments.RequirementSetId);
			--end
		end
	end
	-- done!
	tReqSets[ sReqSetId ] = tReqSet;
	return tReqSet;
end

function DecodeReqSet(tOut:table, sReqSetId:string)
	--dprint("FUNCAL DecodeReqSet(req)",sReqSetId);
	local tReqSet:table = FetchAndCacheDataReqSet(sReqSetId);
	if not tReqSet then return "ERROR: "..sReqSetId.." not defined!"; end
	if tReqSet.TestAll then table.insert(tOut, INDENT1.."Test All of:"); end
	if tReqSet.TestAny then table.insert(tOut, INDENT1.."Test Any of:"); end
	for _,req in ipairs(tReqSet.Reqs) do DecodeReq(tOut, req.ReqId); end
end


function FetchAndCacheData(sModifierId:string)
	--dprint("FUNCAL FetchAndCacheData(mod)", sModifierId);
	-- check if we already have it
	local tModifier:table = tModifiers[ sModifierId ];
	if tModifier then return tModifier; end
	-- filters in GameInfo don't work for modifiers, we need to use normal search
	tModifier = {};
	-- Modifiers
	for mod in GameInfo.Modifiers() do
		if mod.ModifierId == sModifierId then
			--dprint("...found ", sModifierId);
			tModifier.ModifierId   = sModifierId;
			tModifier.ModifierType = mod.ModifierType;
			tModifier.RunOnce      = mod.RunOnce; -- boolean
			tModifier.NewOnly      = mod.NewOnly; -- boolean
			tModifier.Permanent    = mod.Permanent; -- boolean
			tModifier.OwnerReqSetId = mod.OwnerRequirementSetId;
			tModifier.SubjectReqSetId = mod.SubjectRequirementSetId;
			--tModifier.Text = ""; -- filled later
			break;
		end
	end
	-- check if it exists!
	if table.count(tModifier) == 0 then print("WARNING! FetchAndCacheData: No definition for Modifier", sModifierId); return nil; end
	-- DynamicModifiers
	sModifierType = tModifier.ModifierType;
	for mod in GameInfo.DynamicModifiers() do
		if mod.ModifierType == sModifierType then
			tModifier.CollectionType = mod.CollectionType;
			tModifier.EffectType     = mod.EffectType;
			break;
		end
	end
	if tModifier.CollectionType == nil or tModifier.EffectType == nil then print("WARNING! FetchAndCacheData: No dynamic modifier definition for Modifier", sModifierId); return nil; end
	-- ModifierStrings - this one must be searched entirely
	-- WARNING! There are 4 modifiers with 2 strings, but 99% of them has only 1 - we'll get only 1 here!
	for row in GameInfo.ModifierStrings() do
		if row.ModifierId == sModifierId then tModifier.Text = row.Text; break; end
	end
	-- ModifierArguments - this one must be searched entirely
	tModifier.Arguments = {};
	for arg in GameInfo.ModifierArguments() do
		if arg.ModifierId == sModifierId then
			-- now we need to convert values into a proper type
			-- there are 216 names, so maybe we'll do it when actually trying to use it?
			--dprint("..found arg", arg.Name, arg.Value);
			tModifier.Arguments[ arg.Name ] = arg.Value;
			-- special handling for Type
			if arg.Type == "ScaleByGameSpeed" then
				-- add here: access game speed, multiply by it
				tModifier.ScaleByGameSpeed = true;
			end
		end
	end
	-- requirements
	if tModifier.OwnerReqSetId   then tModifier.OwnerReqSet   = FetchAndCacheDataReqSet(tModifier.OwnerReqSetId);   end
	if tModifier.SubjectReqSetId then tModifier.SubjectReqSet = FetchAndCacheDataReqSet(tModifier.SubjectReqSetId); end
	-- done!
	tModifiers[ sModifierId ] = tModifier;
	return tModifier; 
end

------------------------------------------------------------------------------
-- Returns 5 values:
--  string - decoded into text (tooltip), contains info about structure, owner, subjects and final impact
--  table - extended yields table
--  string - id of the attached modifier, if an effect is "attach modifier"
--  boolean - true if there was an unknown effect
--  table - the modifier
--  string - type of subjects
function DecodeModifier(sModifierId:string, ePlayerID:number, iCityID:number, tMainSubjects:table, sMainSubjectType:string)
	--dprint("FUN DecodeModifier(modid,pid,cid,subtype)",sModifierId,ePlayerID,iCityID,sMainSubjectType);
	local tMod:table = FetchAndCacheData(sModifierId);
	if not tMod then return "ERROR: "..sModifierId.." not defined!"; end
	local tOut = {};
	table.insert(tOut, "Modifier: "..Capitalize(tMod.ModifierId));
	table.insert(tOut, "Type: "..Capitalize(tMod.ModifierType));
	if tMod.OwnerReqSetId then
		table.insert(tOut, "Owner: "..Capitalize(tMod.OwnerReqSetId));
		DecodeReqSet(tOut, tMod.OwnerReqSetId);
	end
	table.insert(tOut, "Collection: "..Capitalize(tMod.CollectionType));
	if tMod.SubjectReqSetId then
		table.insert(tOut, "Subject: "..Capitalize(tMod.SubjectReqSetId));
		DecodeReqSet(tOut, tMod.SubjectReqSetId);
	end
	table.insert(tOut, "Effect: "..Capitalize(tMod.EffectType));
	for name,value in pairs(tMod.Arguments) do table.insert(tOut, name.." = "..value); end
	if tMod.ScaleByGameSpeed then table.insert(tOut, "Scaled by Game Speed"); end
	if tMod.RunOnce then table.insert(tOut, "Run Once"); end
	if tMod.NewOnly then table.insert(tOut, "New Only"); end
	if tMod.Permanent then table.insert(tOut, "Permanent"); end
	-- analysis starts here
	if bBaseDataDirty then RefreshBaseData(); end -- make sure we have current data
	-- TODO: ASSUMPTION Owner will be Player, this is true for Policies and many other modifiers
	-- TODO: add support for other owners later, if necessary
	local tOwner:table, sOwnerType:string = tPlayer, SubjectTypes.Player; -- Players[ Game:GetLocalPlayer() ]
	-- 2018-03-27 added City support
	if ePlayerID and iCityID then
		local pCity:table = Players[ePlayerID]:GetCities():FindID(iCityID);
		if pCity then tOwner, sOwnerType = tCities[ pCity:GetName()], SubjectTypes.City; end
	end
	-- build a collection of subjects
	local tSubjects:table, sSubjectType:string = tMainSubjects, sMainSubjectType; -- let's start with passed args, will be nils most of the time
	if tMainSubjects == nil or sMainSubjectType == nil then 
		-- rebuild collection
		tSubjects, sSubjectType = BuildCollectionOfSubjects(tMod, tOwner, sOwnerType);
	else
		if tMod.CollectionType == "COLLECTION_CITY_DISTRICTS" then
			-- try to pass cities
			tSubjects, sSubjectType = BuildCollectionOfSubjects(tMod, tMainSubjects, sMainSubjectType);
		elseif tMod.CollectionType ~= "COLLECTION_OWNER" then
			-- rebuild collection
			tSubjects, sSubjectType = BuildCollectionOfSubjects(tMod, tOwner, sOwnerType);
		end
	end
	--dprint("Subjects are:"); for k,v in pairs(tSubjects) do print(k,v.SubjectType,v.Name); end -- debug
	--dshowsubjects(tSubjects); -- debug
	-- list subjects
	local tSubjectsOut:table = {};
	table.insert(tSubjectsOut, "Subject(s): "..sSubjectType);
	table.insert(tSubjectsOut, table.count(tSubjects));
	--if sSubjectType ~= SubjectTypes.Plot then
		for _,subject in ipairs(tSubjects) do table.insert(tSubjectsOut, subject.Name); end
	--end
	table.insert(tOut, table.concat(tSubjectsOut, ", "));
	-- calculate impact of the modifier
	local bUnknownEffect:boolean = false;
	local tImpact:table = YieldTableNew();
	for i,subject in pairs(tSubjects) do
		local tSubjectImpact:table = ApplyEffectAndCalculateImpact(tMod, subject, sSubjectType); -- it will return nil if effect unknown
		if tSubjectImpact then
			--dprint("Impact for subject ", subject.Name); dshowyields(tSubjectImpact); -- debug
			YieldTableAdd(tImpact, tSubjectImpact);
		else
			bUnknownEffect = true;
		end
	end
	--dprint("Impact for all subjects"); dshowyields(tImpact); -- debug
	-- create an output string
	local sImpactText:string = "Effect: ";
	local bImpact:boolean = false;
	for	yield,value in pairs(tImpact) do
		if value ~= 0 then
			sImpactText = sImpactText..GetYieldString("YIELD_"..yield, value);
			bImpact = true;
		end
	end
	if not bImpact then sImpactText = sImpactText.."yields not affected"; end
	table.insert(tOut, sImpactText);
	if bUnknownEffect then table.insert(tOut, "[COLOR_Red]Unknown effect[ENDCOLOR]"); end -- [ICON_Exclamation]
	-- return 7 values
	return
		table.concat(tOut, "[NEWLINE]"),
		tImpact,
		((tMod.EffectType == "EFFECT_ATTACH_MODIFIER") and tMod.Arguments.ModifierId) or nil,
		bUnknownEffect,
		tMod,
		tSubjects,
		sSubjectType;
end

-- ===========================================================================
-- MODIFIERS' DYNAMIC ANALYSIS
-- ===========================================================================


------------------------------------------------------------------------------
-- Requires 3 arguments
--  table - requirement
--  table - subject to analyze (from tCities or any other)
--  string - type of subject (e.g. "City", "District")
function CheckOneRequirement(tReq:table, tSubject:table, sSubjectType:string)
	--dprint("FUNCAL CheckOneRequirement(req,type,sub)(subject)",tReq.ReqId,tReq.ReqType,sSubjectType,tSubject.SubjectType,tSubject.Name);
	
	local function CheckForMismatchError(sExpectedType:string)
		if sExpectedType == tSubject.SubjectType then return false; end
		print("ERROR: CheckOneRequirement mismatch for exp subject", sExpectedType, "got", tSubject.SubjectType, "req is", tReq.ReqId, tReq.ReqType); return true;
	end
	
	-- MAIN DISPATCHER FOR REQUIREMENTS
	local bIsValidSubject:boolean = false;
	
	if     tReq.ReqType == "REQUIREMENT_REQUIREMENTSET_IS_MET" then -- 19
		-- recursion? could be diffcult
		
	-- bunch of reqs simulated to be always true (usually regarding player's situation)
	elseif tReq.ReqType == "REQUIREMENT_PLAYER_IS_AT_PEACE"                 then return true;
	elseif tReq.ReqType == "REQUIREMENT_PLAYER_IS_AT_PEACE_WITH_ALL_MAJORS" then return true;
	elseif tReq.ReqType == "REQUIREMENT_CITY_FOLLOWS_PANTHEON" then return true;
	elseif tReq.ReqType == "REQUIREMENT_CITY_FOLLOWS_RELIGION" then return true;
	elseif tReq.ReqType == "REQUIREMENT_PLAYER_HAS_PANTHEON" then return true; -- 2019-04-14 Support for Real Balanced Pantheons
	
	-- 2019-04-14 Support for Real Balanced Pantheons
	elseif tReq.ReqType == "REQUIREMENT_GAME_ERA_IS" then
		-- valid for any subject, no check needed
		if bIsRiseAndFall then
			local eraType:string = GameInfo.Eras[ Game.GetEras():GetCurrentEra() ].EraType;
			bIsValidSubject = ( tReq.Arguments.EraType == eraType );
		end
	
	elseif tReq.ReqType == "REQUIREMENT_CITY_HAS_BUILDING" then -- 35, Wonders too!
		--if CheckForMismatchError(SubjectTypes.City) then return false; end
		if not( tSubject.SubjectType == SubjectTypes.City or tSubject.SubjectType == SubjectTypes.District ) then
			print("ERROR: CheckOneRequirement mismatch for subject", tSubject.SubjectType); dshowtable(tReq); return nil;
		end
		if tSubject.SubjectType == SubjectTypes.City then
			for _,district in ipairs(tSubject.Districts) do
				if district.isBuilt then
					for _,building in ipairs(district.Buildings) do
						local buildingType:string = building.BuildingType;	
						if GameInfo.BuildingReplaces[ buildingType ] then buildingType = GameInfo.BuildingReplaces[ buildingType ].ReplacesBuildingType; end
						bIsValidSubject = ( buildingType == tReq.Arguments.BuildingType ); -- BUILDING_LIGHTHOUSE, etc.
						if bIsValidSubject then break; end
					end
					if bIsValidSubject then break; end
				end -- isBuilt
			end
			if not bIsValidSubject then -- still not found
				for _,wonder in ipairs(tSubject.Wonders) do
					-- wonders don't have replacements
					bIsValidSubject = ( wonder.BuildingType == tReq.Arguments.BuildingType ); -- BUILDING_ST_BASILS_CATHEDRAL, etc.
					if bIsValidSubject then break; end
				end
			end
		else --  subject is District
			if tSubject.isBuilt then
				for _,building in ipairs(tSubject.Buildings) do
					local buildingType:string = building.BuildingType;	
					if GameInfo.BuildingReplaces[ buildingType ] then buildingType = GameInfo.BuildingReplaces[ buildingType ].ReplacesBuildingType; end
					bIsValidSubject = ( buildingType == tReq.Arguments.BuildingType ); -- BUILDING_LIGHTHOUSE, etc.
					if bIsValidSubject then break; end
				end
			end -- isBuilt
		end

	elseif tReq.ReqType == "REQUIREMENT_CITY_HAS_DISTRICT" then -- 10
		if CheckForMismatchError(SubjectTypes.City) then return false; end
		for _,district in ipairs(tSubject.Districts) do
			if district.isBuilt then
				local districtType:string = district.DistrictType;	
				if GameInfo.DistrictReplaces[ districtType ] then districtType = GameInfo.DistrictReplaces[ districtType ].ReplacesDistrictType; end
				bIsValidSubject = ( districtType == tReq.Arguments.DistrictType ); -- DISTRICT_THEATER, etc.
				if bIsValidSubject then break; end
			end -- isBuilt
		end
		
	elseif tReq.ReqType == "REQUIREMENT_CITY_HAS_HIGH_ADJACENCY_DISTRICT" then
		if CheckForMismatchError(SubjectTypes.City) then return false; end
		-- must use 3 arguments actually, plus replacements
		for _,district in ipairs(tSubject.Districts) do
			if district.isBuilt then
				local districtType:string = district.DistrictType;	
				if GameInfo.DistrictReplaces[ districtType ] then districtType = GameInfo.DistrictReplaces[ districtType ].ReplacesDistrictType; end
				bIsValidSubject = ( ( districtType == tReq.Arguments.DistrictType ) and -- DISTRICT_THEATER, etc.
									( YieldTableGetYield(district.Yields, tReq.Arguments.YieldType) >= tonumber(tReq.Arguments.Amount)) );
				if bIsValidSubject then break; end
			end -- isBuilt
		end

	elseif tReq.ReqType == "REQUIREMENT_CITY_HAS_X_POPULATION" then
		if CheckForMismatchError(SubjectTypes.City) then return false; end
		bIsValidSubject = ( tSubject.Population >= tonumber(tReq.Arguments.Amount) );
		
	elseif tReq.ReqType == "REQUIREMENT_CITY_HAS_X_SPECIALTY_DISTRICTS" then
		if CheckForMismatchError(SubjectTypes.City) then return false; end
		--local iNumDistricts:number = 0;
		--for _,district in ipairs(tSubject.Districts) do
			--if not district.CityCenter then iNumDistricts = iNumDistricts + 1; end
		--end
		bIsValidSubject = ( tSubject.NumSpecialtyDistricts >= tonumber(tReq.Arguments.Amount) );

	elseif tReq.ReqType == "REQUIREMENT_CITY_HAS_GOVERNOR" then
		if CheckForMismatchError(SubjectTypes.City) then return false; end
		bIsValidSubject = tSubject.IsGovernorEstablished;

	elseif tReq.ReqType == "REQUIREMENT_CITY_HAS_GOVERNOR_WITH_X_TITLES" then
		if CheckForMismatchError(SubjectTypes.City) then return false; end
		bIsValidSubject = (tSubject.IsGovernorEstablished and tSubject.NumGovernorPromotions >= tonumber(tReq.Arguments.Amount))
		
	elseif tReq.ReqType == "REQUIREMENT_CITY_HAS_GARRISON_UNIT" then
		if CheckForMismatchError(SubjectTypes.City) then return false; end
		bIsValidSubject = tSubject.IsGarrisonUnit;

	elseif tReq.ReqType == "REQUIREMENT_CITY_IS_OWNER_CAPITAL_CONTINENT" then
		if CheckForMismatchError(SubjectTypes.City) then return false; end
		-- compare capital's continent to this one
		local pCapital:table = Players[ tSubject.City:GetOwner() ]:GetCities():GetCapitalCity(); -- TODO: probably should be stored in thePlayer object
		local eOwnerCapitalContinent:number = Map.GetPlot( pCapital:GetX(), pCapital:GetY() ):GetContinentType();
		bIsValidSubject = ( tSubject.ContinentType == eOwnerCapitalContinent );
	
	elseif tReq.ReqType == "REQUIREMENT_DISTRICT_TYPE_MATCHES" then -- 12
		if CheckForMismatchError(SubjectTypes.District) then return false; end
		local districtType:string = tSubject.DistrictType;
		if GameInfo.DistrictReplaces[ districtType ] then districtType = GameInfo.DistrictReplaces[ districtType ].ReplacesDistrictType; end
		bIsValidSubject = ( districtType == tReq.Arguments.DistrictType ); -- DISTRICT_THEATER, etc.
			
	elseif tReq.ReqType == "REQUIREMENT_PLAYER_HAS_BUILDING" then -- 9
		if CheckForMismatchError("Player") then return false; end
		
	elseif tReq.ReqType == "REQUIREMENT_PLAYER_HAS_TECHNOLOGY" then -- 9
		if CheckForMismatchError("Player") then return false; end
		
	elseif tReq.ReqType == "REQUIREMENT_PLAYER_HAS_DISTRICT" then -- 1
		if CheckForMismatchError("Player") then return false; end
		
	elseif tReq.ReqType == "REQUIREMENT_PLOT_TERRAIN_CLASS_MATCHES" then
		if CheckForMismatchError(SubjectTypes.Plot) then return false; end
		bIsValidSubject = false;
		local eTerrainType:number = tSubject.Plot:GetTerrainType();
		if eTerrainType ~= -1 then
			local sTerrainType:string = GameInfo.Terrains[eTerrainType].TerrainType;
			for row in GameInfo.TerrainClass_Terrains() do
				if row.TerrainType == sTerrainType and row.TerrainClassType == tReq.Arguments.TerrainClass then
					bIsValidSubject = true; break;
				end
			end
		end -- if
		
	elseif tReq.ReqType == "REQUIREMENT_PLOT_TERRAIN_TYPE_MATCHES" then -- 14
		if CheckForMismatchError(SubjectTypes.Plot) then return false; end
		local info:table = GameInfo.Terrains[ tReq.Arguments.TerrainType ];
		if info == nil then return false; end -- error
		bIsValidSubject = ( tSubject.Plot:GetTerrainType() == info.Index );

	elseif tReq.ReqType == "REQUIREMENT_PLOT_HAS_ANY_FEATURE" then
		if CheckForMismatchError(SubjectTypes.Plot) then return false; end
		bIsValidSubject = ( tSubject.Plot:GetFeatureType() ~= -1 );
		
	elseif tReq.ReqType == "REQUIREMENT_PLOT_FEATURE_TYPE_MATCHES" then -- 10
		if CheckForMismatchError(SubjectTypes.Plot) then return false; end
		local info:table = GameInfo.Features[ tReq.Arguments.FeatureType ];
		if info == nil then return false; end -- error
		bIsValidSubject = ( tSubject.Plot:GetFeatureType() == info.Index );

	elseif tReq.ReqType == "REQUIREMENT_PLOT_HAS_ANY_RESOURCE" then
		if CheckForMismatchError(SubjectTypes.Plot) then return false; end
		bIsValidSubject = ( tSubject.Plot:GetResourceType() ~= -1 );
		
	elseif tReq.ReqType == "REQUIREMENT_PLOT_RESOURCE_TYPE_MATCHES" then
		if CheckForMismatchError(SubjectTypes.Plot) then return false; end
		local info:table = GameInfo.Resources[ tReq.Arguments.ResourceType ];
		if info == nil then return false; end -- error
		bIsValidSubject = ( tSubject.Plot:GetResourceType() == info.Index );

	elseif tReq.ReqType == "REQUIREMENT_PLOT_RESOURCE_CLASS_TYPE_MATCHES" then
		if CheckForMismatchError(SubjectTypes.Plot) then return false; end
		local resource:number = tSubject.Plot:GetResourceType();
		if resource < 0 then return false; end -- no resource in the plot
		local info:table = GameInfo.Resources[ resource ];
		if info == nil then return false; end -- error
		bIsValidSubject = ( info.ResourceClassType == tReq.Arguments.ResourceClassType );
		
	elseif tReq.ReqType == "REQUIREMENT_PLOT_RESOURCE_TAG_MATCHES" then
		if CheckForMismatchError(SubjectTypes.Plot) then return false; end
		local resource:number = tSubject.Plot:GetResourceType();
		if resource < 0 then return false; end -- no resource in the plot
		local info:table = GameInfo.Resources[ resource ];
		if info == nil then return false; end -- error
		local sResourceType:string = info.ResourceType;
		bIsValidSubject = false;
		for row in GameInfo.TypeTags() do
			if row.Type == sResourceType and row.Tag == tReq.Arguments.Tag then
				bIsValidSubject = true; break;
			end
		end

	elseif tReq.ReqType == "REQUIREMENT_PLOT_RESOURCE_VISIBLE" then
		if CheckForMismatchError(SubjectTypes.Plot) then return false; end
		bIsValidSubject = false;
		local resource:number = tSubject.Plot:GetResourceType();
		if resource ~= -1 then -- 2019-04-08 fixed lack of Inverse
			bIsValidSubject = ( tPlayer.Player:GetResources():IsResourceVisible( resource ) );
		end
	
	-- 2019-04-15 Support for Real Balance Pantheons
	elseif tReq.ReqType == "REQUIREMENT_PLOT_IS_MOUNTAIN" then
		if CheckForMismatchError(SubjectTypes.Plot) then return false; end
		bIsValidSubject = tSubject.Plot:IsMountain();
		
	-- 2019-04-15 Support for Real Balance Pantheons
	elseif tReq.ReqType == "REQUIREMENT_PLOT_IS_HILLS" then
		if CheckForMismatchError(SubjectTypes.Plot) then return false; end
		bIsValidSubject = tSubject.Plot:IsHills();
		
	-- 2019-04-15 Support for Real Balance Pantheons
	elseif tReq.ReqType == "REQUIREMENT_PLOT_HAS_ANY_DISTRICT" then
		if CheckForMismatchError(SubjectTypes.Plot) then return false; end
		bIsValidSubject = ( tSubject.Plot:GetDistrictType() ~= -1 );
		
	-- 2019-04-15 Support for Real Balance Pantheons
	elseif tReq.ReqType == "REQUIREMENT_PLOT_HAS_ANY_IMPROVEMENT" then
		if CheckForMismatchError(SubjectTypes.Plot) then return false; end
		bIsValidSubject = ( tSubject.Plot:GetImprovementType() ~= -1 );

	elseif tReq.ReqType == "REQUIREMENT_PLOT_IMPROVEMENT_TYPE_MATCHES" then
		if CheckForMismatchError(SubjectTypes.Plot) then return false; end
		local info:table = GameInfo.Improvements[ tReq.Arguments.ImprovementType ];
		if info == nil then print("ERROR: CheckOneRequirement unknown improvement", tReq.Arguments.ImprovementType); return false; end -- error
		bIsValidSubject = ( tSubject.Plot:GetImprovementType() == info.Index );
		
	elseif tReq.ReqType == "REQUIREMENT_PLOT_IS_APPEAL_BETWEEN" then
		if CheckForMismatchError(SubjectTypes.Plot) then return false; end
		bIsValidSubject = ( tSubject.Plot:GetAppeal() >= tonumber(tReq.Arguments.MinimumAppeal) );
		-- there is probably maximum appeal but it is not used at all
		
	elseif tReq.ReqType == "REQUIREMENT_PLOT_ADJACENT_TO_RIVER" then
		--if CheckForMismatchError(SubjectTypes.Plot) then return false; end -- this could be District or Plot, maybe City?
		if not( tSubject.SubjectType == SubjectTypes.Plot or tSubject.SubjectType == SubjectTypes.District or tSubject.SubjectType == SubjectTypes.City ) then
			print("ERROR: CheckOneRequirement mismatch for subject", tSubject.SubjectType); dshowtable(tReq); return nil;
		end
		-- 2019-04-06 only IsRiver counts, tested on Hydro Dam upgrade
		--bIsValidSubject = ( tSubject.Plot:IsRiver() or tSubject.Plot:IsRiverAdjacent() );
		bIsValidSubject = tSubject.Plot:IsRiver();
	
	elseif tReq.ReqType == "REQUIREMENT_PLOT_DISTRICT_TYPE_MATCHES" then
		if CheckForMismatchError(SubjectTypes.District) then return false; end
		local districtType:string = tSubject.DistrictType;
		if GameInfo.DistrictReplaces[ districtType ] then districtType = GameInfo.DistrictReplaces[ districtType ].ReplacesDistrictType; end
		bIsValidSubject = ( districtType == tReq.Arguments.DistrictType ); -- DISTRICT_THEATER, etc.

	-- 2019-04-15 Support for Real Balance Pantheons
	elseif tReq.ReqType == "REQUIREMENT_PLOT_ADJACENT_DISTRICT_TYPE_MATCHES" then
		if CheckForMismatchError(SubjectTypes.Plot) then return false; end
		--local districtType:string = tSubject.DistrictType;
		--if GameInfo.DistrictReplaces[ districtType ] then districtType = GameInfo.DistrictReplaces[ districtType ].ReplacesDistrictType; end
		local info:table = GameInfo.Districts[ tReq.Arguments.DistrictType ];
		if info == nil then print("ERROR: CheckOneRequirement unknown district", tReq.Arguments.DistrictType); return false; end -- error
		local eDistrictType:number = info.Index;
		local iX:number, iY:number = tSubject.Plot:GetX(), tSubject.Plot:GetY();
		for direction = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1, 1 do
			local adjacentPlot = Map.GetAdjacentPlot(iX, iY, direction);
			if adjacentPlot ~= nil and adjacentPlot:GetDistrictType() == eDistrictType then bIsValidSubject = true; break; end
		end
		
	else
		-- do nothing here... probably will never implement all possible types
		return false;
	end
	-- done!
	if tReq.Inverse then return not bIsValidSubject; end
	return bIsValidSubject;
end


------------------------------------------------------------------------------
-- Requires 3 arguments
--  table - requirement set
--  table - subject to analyze (from tCities or any other)
--  string - type of subject (e.g. "City", "District")
function CheckAllRequirements(tReqSet:table, tSubject:table, sSubjectType:string)
	--dprint("FUNCAL CheckAllRequirements(req,sub)(subject)",tReqSet.ReqSetId,sSubjectType,tSubject.SubjectType,tSubject.Name);
	for _,req in ipairs(tReqSet.Reqs) do
		local bIsValid:boolean = CheckOneRequirement(req, tSubject, sSubjectType);
		if tReqSet.TestAny and     bIsValid then return true;  end -- we found 1 positive, that is all needed for TestAny
		if tReqSet.TestAll and not bIsValid then return false; end -- we found 1 negative, that is all needed for TestAll
	end
	-- we went through all reqs and didn't break, it means that opposite condition to TestAll/Any is met
	if tReqSet.TestAny then return false; end -- all were negative
	if tReqSet.TestAll then return true;  end -- all were positive
	-- still nothing? error...
	print("ERROR: checked all requirements and nothing seems to work out for subject", sSubjectType);
	dshowtable(tReqSet);
	return false;
end


------------------------------------------------------------------------------
-- BuildCollectionOfSubjects return 2 values
--  table - of subjects - these are objects from tCities (cities, districts or buildings), TODO: filtered using SubReqs
--  string - type of the subject
function BuildCollectionOfSubjects(tMod:table, tOwner:table, sOwnerType:string)
	--dprint("FUN BuildCollectionOfSubjects(subreq,ownname,owntype,passed)",tMod.SubjectReqSetId,tOwner.Name,tOwner.SubjectType,sOwnerType);
	local tSubjects:table, sSubjectType:string = {}, "([COLOR_Red]unknown[ENDCOLOR])";
	local tReqSet:table = tMod.SubjectReqSet; -- speed up some checking
	--dprint("  Subject requirement set is (id)", tMod.SubjectReqSetId);
	-- MAIN DISPATCHER FOR COLLECTIONS
	if tMod.CollectionType == "COLLECTION_OWNER" then
		-- most difficult one... not yet...
		-- for a start - we assume Player is the owner
		-- we'll need some exception handling here if this is not true
		if sOwnerType == SubjectTypes.City and tOwner.SubjectType == SubjectTypes.City then
			sSubjectType = SubjectTypes.City;
			table.insert(tSubjects, tOwner);
		else
			-- all other will get the player
			sSubjectType = SubjectTypes.Player;
			table.insert(tSubjects, tPlayer); -- there's only one
		end
		
	-- 2019-04-17 Fix for City-States attached modifiers that cannot recognize a subject properly
	elseif tMod.CollectionType == "COLLECTION_ALL_PLAYERS" then
		sSubjectType = SubjectTypes.Player;
		table.insert(tSubjects, tPlayer); -- there's only one

	elseif tMod.CollectionType == "COLLECTION_CITY_DISTRICTS" then
		local function AddDistrictsFromCity(tSubject:table)
			if tSubject.SubjectType ~= SubjectTypes.City then
				print("ERROR: BuildCollectionOfSubjects: Mismatch type for COLLECTION_CITY_DISTRICTS", sOwnerType); dshowtable(tMod); dshowrectable(tSubject); return
			end
			for _,district in ipairs(tSubject.Districts) do
				if district.isBuilt then
					--print("working on district",district.Name)
					if tReqSet then  
						if CheckAllRequirements(tReqSet, district, sSubjectType) then table.insert(tSubjects, district); end
					else
						table.insert(tSubjects, district);
					end
				end
			end
		end
		-- need City here as owner
		sSubjectType = SubjectTypes.District;
		if tOwner.SubjectType == SubjectTypes.City then -- single city
			AddDistrictsFromCity(tOwner);
		elseif sOwnerType == SubjectTypes.City then -- player's cities
			for cityname,citydata in pairs(tOwner) do
				AddDistrictsFromCity(citydata);
			end
		else
			print("ERROR: BuildCollectionOfSubjects: Mismatch type for COLLECTION_CITY_DISTRICTS", sOwnerType); dshowtable(tMod);
		end

	elseif tMod.CollectionType == "COLLECTION_PLAYER_CAPITAL_CITY" then
		sSubjectType = SubjectTypes.City;
		for cityname,citydata in pairs(tCities) do
			if citydata.IsCapital then
				table.insert(tSubjects, citydata);
				break;
			end
		end

	elseif tMod.CollectionType == "COLLECTION_PLAYER_CITIES" or
		-- WARNING! this is a shortcut for Beliefs; will produce incorrect results for e.g. Wonders or any other modifier that affects only single city
		tMod.CollectionType == "COLLECTION_ALL_CITIES" then
		sSubjectType = SubjectTypes.City;
		for cityname,citydata in pairs(tCities) do
			if tReqSet then 
				if CheckAllRequirements(tReqSet, citydata, sSubjectType) then table.insert(tSubjects, citydata); end
			else
				table.insert(tSubjects, citydata);
			end
		end

	elseif tMod.CollectionType == "COLLECTION_PLAYER_GOVERNORS" then -- we'll use cities that have an assigned Governor (doesn't need to be established?)
		sSubjectType = SubjectTypes.City;
		for cityname,citydata in pairs(tCities) do
			if bIsRiseAndFall and citydata.City:GetAssignedGovernor() then
				if tReqSet then 
					if CheckAllRequirements(tReqSet, citydata, sSubjectType) then table.insert(tSubjects, citydata); end
				else
					table.insert(tSubjects, citydata);
				end
			end
		end

	elseif tMod.CollectionType == "COLLECTION_PLAYER_DISTRICTS" then
		sSubjectType = SubjectTypes.District;
		for cityname,citydata in pairs(tCities) do
			for _,district in ipairs(citydata.Districts) do
				if district.isBuilt then
					if tReqSet then  
						if CheckAllRequirements(tReqSet, district, sSubjectType) then table.insert(tSubjects, district); end
					else
						table.insert(tSubjects, district);
					end
				end
			end
		end
		
	elseif tMod.CollectionType == "COLLECTION_PLAYER_PLOT_YIELDS" or 
		-- WARNING! this is a shortcut for Pantheons; will produce incorrect results for e.g. Wonders or any other modifier that affects only single city
		tMod.CollectionType == "COLLECTION_CITY_PLOT_YIELDS" then
		sSubjectType = SubjectTypes.Plot;
		for _,plot in ipairs(tPlots) do
			if tReqSet then
				if CheckAllRequirements(tReqSet, plot, sSubjectType) then table.insert(tSubjects, plot); end
			else
				table.insert(tSubjects, plot);
			end
		end

		
	else
		-- do nothing here... probably will never implement all possible types
		--COLLECTION_ALL_PLOT_YIELDS
		--COLLECTION_SINGLE_PLOT_YIELDS
		-- units
		--COLLECTION_ALLIANCE_TRAINED_UNITS
		--COLLECTION_ALLIANCE_UNITS
		--COLLECTION_ALL_UNITS
		--COLLECTION_CITY_TRAINED_UNITS
		--COLLECTION_EMERGENCY_UNITS
		--COLLECTION_PLAYER_TRAINED_UNITS
		--COLLECTION_PLAYER_UNITS
	end
	return tSubjects, sSubjectType;
end


------------------------------------------------------------------------------
-- Returns a table of extended yields
-- It will return nil if an effect is unknown
function ApplyEffectAndCalculateImpact(tMod:table, tSubject:table, sSubjectType:string)
	--dprint("FUN ApplyEffectAndCalculateImpact(mod,eff,sub)(subject)",tMod.ModifierId,tMod.EffectType,sSubjectType,tSubject.SubjectType,tSubject.Name);

	local function CheckForMismatchError(sExpectedType:string)
		if sExpectedType == tSubject.SubjectType then return false; end
		print("ERROR: ApplyEffectAndCalculateImpact mismatch for subject", sSubjectType); dshowtable(tMod); return true;
	end
	
	-- MAIN DISPATCHER FOR EFFECTS
	local tImpact:table = YieldTableNew();
	
	if tMod.EffectType == "EFFECT_ATTACH_MODIFIER" then
		-- well, do nothing here but return tImpact, this will clear unknown flag
	
	-- single effect for changing plot yields
	elseif tMod.EffectType == "EFFECT_ADJUST_PLOT_YIELD" then
		if CheckForMismatchError(SubjectTypes.Plot) then return nil; end
		YieldTableSetMultipleYields(tImpact, tMod.Arguments.YieldType, tMod.Arguments.Amount);

	------------------------------ CITY ------------------------------------------------
	
	elseif tMod.EffectType == "EFFECT_ADJUST_CITY_YIELD_CHANGE" then
		if CheckForMismatchError(SubjectTypes.City) then return nil; end
		YieldTableSetYield(tImpact, tMod.Arguments.YieldType, tonumber(tMod.Arguments.Amount));

	elseif tMod.EffectType == "EFFECT_ADJUST_CITY_ALL_YIELDS_CHANGE" then
		if CheckForMismatchError(SubjectTypes.City) then return nil; end
		local fYieldChange:number = tonumber(tMod.Arguments.Amount);
		for yield in GameInfo.Yields() do YieldTableSetYield(tImpact, yield.YieldType, fYieldChange); end
		
	elseif tMod.EffectType == "EFFECT_ADJUST_CITY_YIELD_MODIFIER" then
		if CheckForMismatchError(SubjectTypes.City) then return nil; end
		YieldTableSetYield(tImpact, tMod.Arguments.YieldType, YieldTableGetYield(tSubject.Yields, tMod.Arguments.YieldType) * tonumber(tMod.Arguments.Amount) / 100.0);

	elseif tMod.EffectType == "EFFECT_ADJUST_CITY_YIELD_PER_DISTRICT" then
		if CheckForMismatchError(SubjectTypes.City) then return nil; end
		YieldTableSetYield(tImpact, tMod.Arguments.YieldType, tonumber(tMod.Arguments.Amount) * tSubject.NumDistricts);
		
	elseif tMod.EffectType == "EFFECT_ADJUST_CITY_YIELD_PER_POPULATION" then
		if CheckForMismatchError(SubjectTypes.City) then return nil; end
		YieldTableSetYield(tImpact, tMod.Arguments.YieldType, tonumber(tMod.Arguments.Amount) * tSubject.Population);
		
	elseif tMod.EffectType == "EFFECT_ADJUST_CITY_GROWTH" then
		if CheckForMismatchError(SubjectTypes.City) then return nil; end
		tImpact.FOOD = tSubject.FoodSurplus * tonumber(tMod.Arguments.Amount) / 100.0;

	elseif tMod.EffectType == "EFFECT_ADJUST_CITY_IDENTITY_PER_TURN" then
		if CheckForMismatchError(SubjectTypes.City) then return nil; end
		tImpact.LOYALTY = tonumber(tMod.Arguments.Amount);
		
	elseif tMod.EffectType == "EFFECT_ADJUST_CITY_AMENITIES_FROM_RELIGION" then
		if not( tSubject.SubjectType == SubjectTypes.City or tSubject.SubjectType == SubjectTypes.District ) then
			print("ERROR: ApplyEffectAndCalculateImpact mismatch for subject", sSubjectType); dshowtable(tMod); return nil;
		end
		tImpact.AMENITY = tonumber(tMod.Arguments.Amount);
		
	------------------------------ DISTRICT ------------------------------------------------
	
	elseif tMod.EffectType == "EFFECT_ADJUST_DISTRICT_YIELD_MODIFIER" then
		if CheckForMismatchError(SubjectTypes.District) then return nil; end
		YieldTableSetYield(tImpact, tMod.Arguments.YieldType, YieldTableGetYield(tSubject.Yields, tMod.Arguments.YieldType) * tonumber(tMod.Arguments.Amount) / 100.0);
	
	elseif tMod.EffectType == "EFFECT_ADJUST_DISTRICT_YIELD_CHANGE" then
		if CheckForMismatchError("District") then return nil; end
		return nil;

	-- 2019-04-17 Added
	elseif tMod.EffectType == "EFFECT_ADJUST_DISTRICT_YIELD_BASED_ON_ADJACENCY_BONUS" then
		if CheckForMismatchError(SubjectTypes.District) then return nil; end
		YieldTableSetYield(tImpact, tMod.Arguments.YieldTypeToGrant, YieldTableGetYield(tSubject.Yields, tMod.Arguments.YieldTypeToMirror));

	elseif tMod.EffectType == "EFFECT_FEATURE_ADJACENCY" then
		if CheckForMismatchError(SubjectTypes.City) then return nil; end
		-- complex effect, with 4 parameters
		-- DistrictType, FeatureType (must be adjacent), YieldType, Amount
		-- need to iterate through all built districts and check if there's an adjacent feature
		
		local function GetNumAdjacentFeatureType(iX:number, iY:number, sFeatureType:string)
			local adjacentPlot:table, eFeature:number, iNum:number = nil, 0, 0;
			for direction = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1, 1 do
				adjacentPlot = Map.GetAdjacentPlot(iX, iY, direction);
				if adjacentPlot then
					eFeature = adjacentPlot:GetFeatureType();
					if eFeature > -1 and GameInfo.Features[eFeature].FeatureType == sFeatureType then iNum = iNum + 1; end
				end
			end
			return iNum;
		end
		
		local iNum:number = 0;
		for _,district in ipairs(tSubject.Districts) do
			if district.isBuilt and district.DistrictType == tMod.Arguments.DistrictType then
				iNum = iNum + GetNumAdjacentFeatureType(district.Plot:GetX(), district.Plot:GetY(), tMod.Arguments.FeatureType);
			end
		end
		-- compatibility tweak for CIVITAS CS mod - remove if not needed any more
		-- they use YieldChange instead of Amount in this modifier
		if     tMod.Arguments.Amount      then YieldTableSetYield(tImpact, tMod.Arguments.YieldType, iNum * tonumber(tMod.Arguments.Amount));
		elseif tMod.Arguments.YieldChange then YieldTableSetYield(tImpact, tMod.Arguments.YieldType, iNum * tonumber(tMod.Arguments.YieldChange));
		end
		
	elseif tMod.EffectType == "EFFECT_TERRAIN_ADJACENCY" then
		if CheckForMismatchError(SubjectTypes.City) then return nil; end
		-- complex effect, with 4 parameters
		-- DistrictType, TerrainType (must be adjacent), YieldType, Amount
		-- need to iterate through all built districts and check if there's an adjacent terrain
		
		local function GetNumAdjacentTerrainType(iX:number, iY:number, sTerrainType:string)
			local adjacentPlot:table, eTerrain:number, iNum:number = nil, 0, 0;
			for direction = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1, 1 do
				adjacentPlot = Map.GetAdjacentPlot(iX, iY, direction);
				if adjacentPlot then
					eTerrain = adjacentPlot:GetTerrainType();
					if eTerrain > -1 and GameInfo.Terrains[eTerrain].TerrainType == sTerrainType then iNum = iNum + 1; end
				end
			end
			return iNum;
		end
		
		local iNum:number = 0;
		for _,district in ipairs(tSubject.Districts) do
			if district.isBuilt and district.DistrictType == tMod.Arguments.DistrictType then
				iNum = iNum + GetNumAdjacentTerrainType(district.Plot:GetX(), district.Plot:GetY(), tMod.Arguments.TerrainType);
			end
		end
		YieldTableSetYield(tImpact, tMod.Arguments.YieldType, iNum * tonumber(tMod.Arguments.Amount));
		
	------------------------------ BUILDING ------------------------------------------------
	
	elseif tMod.EffectType == "EFFECT_ADJUST_BUILDING_YIELD_CHANGE" then
		if CheckForMismatchError(SubjectTypes.City) then return nil; end
		local sBuildingType:string = tMod.Arguments.BuildingType;
		local bApplied:boolean = false;
		for _,district in ipairs(tSubject.Districts) do
			if district.isBuilt then
				for _,building in ipairs(district.Buildings) do
					local buildingType:string = building.BuildingType;	
					if GameInfo.BuildingReplaces[ buildingType ] then buildingType = GameInfo.BuildingReplaces[ buildingType ].ReplacesBuildingType; end
					if buildingType == sBuildingType then
						YieldTableSetYield(tImpact, tMod.Arguments.YieldType, tonumber(tMod.Arguments.Amount)); bApplied = true; break;
					end
				end
				if bApplied then break; end
			end -- isBuilt
		end
		
	elseif tMod.EffectType == "EFFECT_ADJUST_BUILDING_YIELD_MODIFIER" then
		if CheckForMismatchError(SubjectTypes.City) then return nil; end
		local sBuildingType:string = tMod.Arguments.BuildingType;
		local bApplied:boolean = false;
		for _,district in ipairs(tSubject.Districts) do
			if district.isBuilt then
				for _,building in ipairs(district.Buildings) do
					local buildingType:string = building.BuildingType;	
					if GameInfo.BuildingReplaces[ buildingType ] then buildingType = GameInfo.BuildingReplaces[ buildingType ].ReplacesBuildingType; end
					if buildingType == sBuildingType then
						YieldTableSetYield(tImpact, tMod.Arguments.YieldType, YieldTableGetYield(building.Yields, tMod.Arguments.YieldType)*tonumber(tMod.Arguments.Amount)/100.0); bApplied = true; break;
					end
				end
				if bApplied then break; end
			end -- isBuilt
		end
		
	elseif tMod.EffectType == "EFFECT_ADJUST_BUILDING_YIELD_MODIFIERS_FOR_DISTRICT" then
		if CheckForMismatchError(SubjectTypes.City) then return nil; end
		-- must use 3 arguments actually, plus replacements
		for _,district in ipairs(tSubject.Districts) do
			local districtType:string = district.DistrictType;
			if GameInfo.DistrictReplaces[ districtType ] then districtType = GameInfo.DistrictReplaces[ districtType ].ReplacesDistrictType; end
			if districtType == tMod.Arguments.DistrictType then -- DISTRICT_THEATER, etc.
				if district.isBuilt then
					local fYieldChange:number = 0.0;
					for _,building in ipairs(district.Buildings) do
						fYieldChange = fYieldChange + YieldTableGetYield(building.Yields, tMod.Arguments.YieldType) * tonumber(tMod.Arguments.Amount) / 100.0;
					end
					YieldTableSetYield(tImpact, tMod.Arguments.YieldType, fYieldChange);
					break;
				end -- isBuilt
			end
		end
		
	------------------------------ PRODUCTION ------------------------------------------------
	
	-- special effects to boost production
	elseif tMod.EffectType == "EFFECT_ADJUST_CITY_PRODUCTION_BUILDING" then
		if CheckForMismatchError(SubjectTypes.City) then return nil; end
		if tSubject.CurrentProductionType == "BUILDING" then tImpact.PRODUCTION = tonumber(tMod.Arguments.Amount); end
		
	-- special effects to boost production
	elseif tMod.EffectType == "EFFECT_ADJUST_CITY_PRODUCTION_DISTRICT" then
		if CheckForMismatchError(SubjectTypes.City) then return nil; end
		if tSubject.CurrentProductionType == "DISTRICT" then tImpact.PRODUCTION = tonumber(tMod.Arguments.Amount); end
		
	-- special effects to boost production
	elseif tMod.EffectType == "EFFECT_ADJUST_CITY_PRODUCTION_UNIT" then
		if CheckForMismatchError(SubjectTypes.City) then return nil; end
		if tSubject.CurrentProductionType == "UNIT" then tImpact.PRODUCTION = tonumber(tMod.Arguments.Amount); end
	
	------------------------------  HOUSING AMENITY LOYALTY ------------------------------------------------
	
	elseif tMod.EffectType == "EFFECT_ADJUST_BUILDING_HOUSING" then
		if CheckForMismatchError("City") then return nil; end
		-- two versions, one with BuildingType provided and the other unconditional
		if tMod.Arguments.BuildingType then
			local buildingInfo:table = GameInfo.Buildings[ tMod.Arguments.BuildingType ];
			if buildingInfo == nil then return nil; end
			if tSubject.City:GetBuildings():HasBuilding( buildingInfo.Index ) then
				tImpact.HOUSING = tonumber(tMod.Arguments.Amount);
			end
		else
			tImpact.HOUSING = tonumber(tMod.Arguments.Amount);
		end

	elseif tMod.EffectType == "EFFECT_ADJUST_CITY_HOUSING_PER_DISTRICT" then
		if CheckForMismatchError(SubjectTypes.City) then return nil; end
		tImpact.HOUSING = tSubject.NumDistricts;
		
	elseif tMod.EffectType == "EFFECT_ADJUST_POLICY_HOUSING" then
		if CheckForMismatchError(SubjectTypes.City) then return nil; end
		tImpact.HOUSING = tonumber(tMod.Arguments.Amount);
		
	elseif tMod.EffectType == "EFFECT_ADJUST_POLICY_AMENITY" then
		if CheckForMismatchError(SubjectTypes.City) then return nil; end
		tImpact.AMENITY = tonumber(tMod.Arguments.Amount);

	elseif tMod.EffectType == "EFFECT_GOVERNOR_ADJUST_IDENITITY_PER_TITLE" then -- WARNING! Firaxis made typo here in IDENITITY
		if CheckForMismatchError(SubjectTypes.City) then return nil; end
		tImpact.LOYALTY = tSubject.NumGovernorPromotions * tonumber(tMod.Arguments.Amount);
		
	------------------------------ UNIT ------------------------------------------------
	
	elseif tMod.EffectType == "EFFECT_ADJUST_UNIT_MAINTENANCE_DISCOUNT" then
		if CheckForMismatchError(SubjectTypes.Player) then return nil; end
		local iAmount:number = tonumber(tMod.Arguments.Amount);
		local iDiscount:number = 0;
		for _,unit in ipairs(tSubject.Units) do
			if not unit.IsCivilian then iDiscount = iDiscount + math.min(iAmount, unit.Maintenance); end
		end
		tImpact.GOLD = iDiscount;

	elseif tMod.EffectType == "EFFECT_ADJUST_PLAYER_WMD_MAINTENANCE_MODIFIER" then
		if CheckForMismatchError(SubjectTypes.Player) then return nil; end
		tImpact.GOLD = tSubject.WMDs.Maintenance * tonumber(tMod.Arguments.Amount) / 100.0;

	------------------------------ ENVOY ------------------------------------------------
	
	elseif tMod.EffectType == "EFFECT_ADJUST_PLAYER_YIELD_CHANGE_PER_USED_INFLUENCE_TOKEN" then
		if CheckForMismatchError(SubjectTypes.Player) then return nil; end
		YieldTableSetYield(tImpact, tMod.Arguments.YieldType, tSubject.NumInfluenceTokensGiven * tonumber(tMod.Arguments.Amount));

	elseif tMod.EffectType == "EFFECT_ADJUST_PLAYER_YIELD_CHANGE_PER_TRIBUTARY" then
		if CheckForMismatchError(SubjectTypes.Player) then return nil; end
		YieldTableSetYield(tImpact, tMod.Arguments.YieldType, tSubject.NumSuzerainCityStates * tonumber(tMod.Arguments.Amount));
		
	elseif tMod.EffectType == "EFFECT_ADJUST_PLAYER_YIELD_MODIFIER_PER_TRIBUTARY" then
		if CheckForMismatchError(SubjectTypes.Player) then return nil; end
		YieldTableSetYield(tImpact, tMod.Arguments.YieldType, YieldTableGetYield(tSubject.Yields, tMod.Arguments.YieldType) * tSubject.NumSuzerainCityStates * tonumber(tMod.Arguments.Amount) / 100.0);

	------------------------------ TRADE ROUTE ------------------------------------------------
	
	elseif tMod.EffectType == "EFFECT_ADJUST_PLAYER_TRADE_ROUTE_YIELD_MODIFIER" then
		if CheckForMismatchError(SubjectTypes.Player) then return nil; end
		local bOrigin:boolean = true; -- apply to Outgoing routes (i.e. we are Origin)
		if tonumber(tMod.Arguments.Destination) == 1 then bOrigin = false;
		elseif tonumber(tMod.Arguments.Origin) == 1 then bOrigin = true; -- just making sure
		else return nil; end -- bad args
		for cityname,city in pairs(tSubject.Cities) do
			local tRoutes:table = city.OutgoingRoutes; -- default
			if not bOrigin then tRoutes = city.IncomingRoutes; end
			for _,route in ipairs(tRoutes) do
				local tSingleRouteImpact:table = YieldTableNew();
				--dprint("route yields for", route.Name); dshowyields(route.Yields);
				YieldTableSetYield(tSingleRouteImpact, tMod.Arguments.YieldType, YieldTableGetYield(route.Yields, tMod.Arguments.YieldType));
				YieldTablePercent(tSingleRouteImpact, tonumber(tMod.Arguments.Amount));
				--dprint("single impact is"); dshowyields(tSingleRouteImpact);
				YieldTableAdd(tImpact, tSingleRouteImpact);
			end
		end

	elseif tMod.EffectType == "EFFECT_ADJUST_TRADE_ROUTE_YIELD" then
		if CheckForMismatchError(SubjectTypes.Player) then return nil end
		local iNum:number = 0
		for cityname,city in pairs(tSubject.Cities) do iNum = iNum + city.NumRoutes end
		YieldTableSetYield(tImpact, tMod.Arguments.YieldType, iNum * tonumber(tMod.Arguments.Amount));

	elseif tMod.EffectType == "EFFECT_ADJUST_PLAYER_TRADE_ROUTE_ORIGIN_YIELD_FOR_ALLY_ROUTE" then
		if CheckForMismatchError(SubjectTypes.Player) then return nil end
		local iNum:number = 0
		for cityname,city in pairs(tSubject.Cities) do
			for _,route in ipairs(city.OutgoingRoutes) do
				if route.IsDestinationPlayerAlly then iNum = iNum + 1 end
			end
		end
		YieldTableSetYield(tImpact, tMod.Arguments.YieldType, iNum * tonumber(tMod.Arguments.Amount))

	elseif tMod.EffectType == "EFFECT_ADJUST_TRADE_ROUTE_YIELD_FOR_DOMESTIC" then
		if CheckForMismatchError(SubjectTypes.Player) then return nil; end
		local iNum:number = 0;
		for cityname,city in pairs(tSubject.Cities) do iNum = iNum + city.NumRoutesDomestic end
		YieldTableSetYield(tImpact, tMod.Arguments.YieldType, iNum * tonumber(tMod.Arguments.Amount));

	elseif tMod.EffectType == "EFFECT_ADJUST_TRADE_ROUTE_YIELD_FOR_INTERNATIONAL" then
		if CheckForMismatchError(SubjectTypes.Player) then return nil; end
		local iNum:number = 0;
		for cityname,city in pairs(tSubject.Cities) do iNum = iNum + city.NumRoutesInternational end
		YieldTableSetYield(tImpact, tMod.Arguments.YieldType, iNum * tonumber(tMod.Arguments.Amount));
		
	elseif tMod.EffectType == "EFFECT_ADJUST_TRADE_ROUTE_YIELD_PER_SPECIALTY_DISTRICT_FOR_DOMESTIC" then
		if CheckForMismatchError(SubjectTypes.Player) then return nil; end
		local iNum:number = 0;
		for cityname,city in pairs(tSubject.Cities) do
			for _,route in ipairs(city.OutgoingRoutes) do
				if route.IsDomestic then iNum = iNum + route.NumSpecialtyDistricts; end
			end
		end
		YieldTableSetYield(tImpact, tMod.Arguments.YieldType, iNum * tonumber(tMod.Arguments.Amount))

	elseif tMod.EffectType == "EFFECT_ADJUST_TRADE_ROUTE_YIELD_PER_SPECIALTY_DISTRICT_FOR_INTERNATIONAL" then
		if CheckForMismatchError(SubjectTypes.Player) then return nil; end
		local iNum:number = 0;
		for cityname,city in pairs(tSubject.Cities) do
			for _,route in ipairs(city.OutgoingRoutes) do
				if not route.IsDomestic then iNum = iNum + route.NumSpecialtyDistricts; end
			end
		end
		YieldTableSetYield(tImpact, tMod.Arguments.YieldType, iNum * tonumber(tMod.Arguments.Amount))

	elseif tMod.EffectType == "EFFECT_ADJUST_CITY_TRADE_ROUTE_YIELD_PER_DESTINATION_STRATEGIC_RESOURCE_FOR_INTERNATIONAL" then
		if CheckForMismatchError(SubjectTypes.City) then return nil; end
		local iNum:number = 0;
		for _,route in ipairs(tSubject.OutgoingRoutes) do
			if not route.IsDomestic then iNum = iNum + route.NumImprovedResourcesStrategic; end
		end
		YieldTableSetYield(tImpact, tMod.Arguments.YieldType, iNum * tonumber(tMod.Arguments.Amount));
		
	elseif tMod.EffectType == "EFFECT_ADJUST_CITY_TRADE_ROUTE_YIELD_PER_DESTINATION_LUXURY_RESOURCE_FOR_INTERNATIONAL" then
		if CheckForMismatchError(SubjectTypes.City) then return nil; end
		local iNum:number = 0
		for _,route in ipairs(tSubject.OutgoingRoutes) do
			if not route.IsDomestic then iNum = iNum + route.NumImprovedResourcesLuxury; end
		end
		YieldTableSetYield(tImpact, tMod.Arguments.YieldType, iNum * tonumber(tMod.Arguments.Amount));

	elseif tMod.EffectType == "EFFECT_ADJUST_CITY_TRADE_ROUTE_YIELD_PER_DESTINATION_STRATEGIC_RESOURCE_FOR_DOMESTIC" then
		if CheckForMismatchError(SubjectTypes.City) then return nil; end
		local iNum:number = 0;
		for _,route in ipairs(tSubject.OutgoingRoutes) do
			if route.IsDomestic then iNum = iNum + route.NumImprovedResourcesStrategic; end
		end
		YieldTableSetYield(tImpact, tMod.Arguments.YieldType, iNum * tonumber(tMod.Arguments.Amount));

	------------------------------ GREAT WORK and TOURISM ------------------------------------------------
	
	-- 2019-04-17 Added
	elseif tMod.EffectType == "EFFECT_ADJUST_PLAYER_TOURISM" then
		if CheckForMismatchError(SubjectTypes.Player) then return nil; end
		tImpact.TOURISM = tSubject.Yields.TOURISM * tonumber(tMod.Arguments.Amount) / 100;

	elseif tMod.EffectType == "EFFECT_ADJUST_DISTRICT_TOURISM_CHANGE" then
		if not( tSubject.SubjectType == SubjectTypes.City or tSubject.SubjectType == SubjectTypes.District ) then
			print("ERROR: ApplyEffectAndCalculateImpact mismatch for subject", tSubject.SubjectType); dshowtable(tMod); return nil;
		end
		tImpact.TOURISM = tonumber(tMod.Arguments.Amount);
	
	elseif tMod.EffectType == "EFFECT_ADJUST_CITY_TOURISM" then
		if CheckForMismatchError(SubjectTypes.City) then return nil; end
		-- this effect is quite complex, it supports 4 argument types: BoostsWonders (=1), GreatWorkObjectType (=GREATWORKOBJECT_PORTRAIT), ImprovementType (=IMPROVEMENT_BEACH_RESORT), Religious (=1), ScalingFactor (=200)
		-- the key ones are GreatWorkObjectType and ScalingFactor used for "scale tourism from specific GW by X%"
		if tMod.Arguments.GreatWorkObjectType and tMod.Arguments.ScalingFactor then
			-- we must actualy count Tourism not GWs because each GW can have a different value (even if now they all are the same for a given object type)
			local function GetTourismFromGreatWorks(sGreatWorkObjectType:string)
				local iTourism:number = 0;
				--	return a table indexed by buildingType, with a table of GameInfo.GreatWorks in that building
				for buildingType,greatWorks in pairs(tSubject.GreatWorks) do
					for _,greatWork in ipairs(greatWorks) do -- this should give GameInfo.GreatWorks object
						if greatWork.GreatWorkObjectType == sGreatWorkObjectType then iTourism = iTourism + greatWork.Tourism; end
					end
				end
				--dprint("Tourism from GWs (type) in (city) is (num)", sGreatWorkObjectType, tSubject.Name, iTourism);
				return iTourism;
			end
			-- impact is only difference, hence -100, and for ScalingFactor<100 it is actualy a negative impact!
			tImpact.TOURISM = GetTourismFromGreatWorks(tMod.Arguments.GreatWorkObjectType) * (tonumber(tMod.Arguments.ScalingFactor)-100) / 100.0;
			-- TODO: don't know how stacking works - this assumes it additive (so, each modifier is applied to base yield)
			-- TODO: nothing about theming
		else
			-- other arguments
			-- ImprovementType is used by CRISTOREDENTOR_BEACHTOURISM (TODO: applied to all Beach Resorts)and TRAIT_WONDER_DOUBLETOURISM
			-- BoostsWonders is used by COMMEMORATION_TOURISM_GA_WONDERS
			-- Religious is used by STBASILS_ADDRELIGIOUSTOURISM (City level)
		end

	elseif tMod.EffectType == "EFFECT_ADJUST_CITY_GREATWORK_YIELD" then
		if CheckForMismatchError(SubjectTypes.City) then return nil; end
		local iNum:number = 0;
		if tMod.Arguments.YieldChange then
			-- version that adds flat yields
			for buildingType,greatWorks in pairs(tSubject.GreatWorks) do
				for _,greatWork in ipairs(greatWorks) do -- this should give GameInfo.GreatWorks object
					if greatWork.GreatWorkObjectType == tMod.Arguments.GreatWorkObjectType then iNum = iNum + 1; end
				end
			end
			YieldTableSetYield(tImpact, tMod.Arguments.YieldType, iNum * tonumber(tMod.Arguments.YieldChange));
		elseif tMod.Arguments.ScalingFactor then
			-- version that adds percentage on base yield
			for buildingType,greatWorks in pairs(tSubject.GreatWorks) do
				for _,greatWork in ipairs(greatWorks) do -- this should give GameInfo.GreatWorks object
					if greatWork.GreatWorkObjectType == tMod.Arguments.GreatWorkObjectType then
						-- get yield for this specific GW from external table
						for row in GameInfo.GreatWork_YieldChanges() do
							if row.GreatWorkType == greatWork.GreatWorkType and row.YieldType == tMod.Arguments.YieldType then iNum = iNum + row.YieldChange; end
						end
					end
				end
			end
			YieldTableSetYield(tImpact, tMod.Arguments.YieldType, iNum * (tonumber(tMod.Arguments.ScalingFactor)-100) / 100.0);
		end
	
	------------------------------  WONDER ------------------------------------------------
	
	elseif tMod.EffectType == "EFFECT_ADJUST_WONDER_YIELD_CHANGE" then
		if CheckForMismatchError(SubjectTypes.City) then return nil; end
		YieldTableSetYield(tImpact, tMod.Arguments.YieldType, table.count(tSubject.Wonders) * tonumber(tMod.Arguments.Amount));
	
	------------------------------  RELIGION ------------------------------------------------
	
	elseif tMod.EffectType == "EFFECT_ADJUST_FOLLOWER_YIELD_MODIFIER" then
		if CheckForMismatchError(SubjectTypes.City) then return nil; end
		YieldTableSetYield(tImpact, tMod.Arguments.YieldType, YieldTableGetYield(tSubject.Yields, tMod.Arguments.YieldType) * tSubject.MajorityReligionFollowers * tonumber(tMod.Arguments.Amount) / 100.0);
	
	else
		-- do nothing here... probably will never implement all possible types
		return nil;
	end
	-- done!
	--dprint("  Impact for subject (type,name)",tSubject.SubjectType,tSubject.Name); dshowyields(tSubject.Yields); dshowyields(tImpact); -- debug
	return tImpact;
end


------------------------------------------------------------------------------
-- Main entry point for calculating effects for entire objects
-- returns effect:string, yields:table, tooltip:string
------------------------------------------------------------------------------
local TOOLTIP_SEP:string = "-------------------";

-- Tables with modifiers
local tModifiersTables:table = {
	["Belief"] = "BeliefModifiers", -- BeliefType
	["Building"] = "BuildingModifiers", -- BuildingType
	["Civic"] = "CivicModifiers", -- CivicType
	["District"] = "DistrictModifiers", -- DistrictType
	["Game"] = "GameModifiers", -- not shown in Pedia?
	--["GoodyHut"] = "GoodyHutSubTypes",
	["Government"] = "GovernmentModifiers", -- GovernmentType
	-- ["GreatPerson"] = GreatPersonIndividualBirthModifiers -- GreatPersonIndividualType
	["GreatPersonIndividual"] = "GreatPersonIndividualActionModifiers", -- GreatPersonIndividualType + AttachmentTargetType
	["Improvement"] = "ImprovementModifiers", -- ImprovementType
	-- ["Leader"] = "LeaderTraits" => "TraitModifiers" -- TraitType
	["Policy"] = "PolicyModifiers", -- PolicyType
	["Project"] = "ProjectCompletionModifiers", -- ProjectType
	["Technology"] = "TechnologyModifiers", -- TechnologyType
	["Trait"] = "TraitModifiers", -- TraitType
	["UnitAbility"] = "UnitAbilityModifiers", -- UnitAbilityType  via TypeTags, i.e. Unit -> Class(Tag) -> TypeTags
	["UnitPromotion"] = "UnitPromotionModifiers", -- UnitPromotionType
};

if bIsRiseAndFall then
	tModifiersTables["Alliance"] = "AllianceEffects"; -- no Pedia page for that!
	tModifiersTables["Commemoration"] = "CommemorationModifiers"; -- no Pedia page for that!
	tModifiersTables["Governor"] = "GovernorModifiers"; -- currently empty
	tModifiersTables["GovernorPromotion"] = "GovernorPromotionModifiers"; -- GovernorPromotionType
end

if bIsGatheringStorm then
	tModifiersTables["Resolution"] = "ResolutionEffects"; -- no Pedia page for that!
end

-- Tables with objects
local tObjectsTables:table = {
	["Belief"] = "Beliefs", -- BeliefType
	["Building"] = "Buildings", -- BuildingType
	["Civic"] = "Civics", -- CivicType
	["District"] = "Districts", -- DistrictType
	-- GameModifiers -- not shown in Pedia?
	["Government"] = "Governments", -- GovernmentType
	-- ["GreatPerson"] = GreatPersonIndividualBirthModifiers -- GreatPersonIndividualType
	["GreatPersonIndividual"] = "GreatPersonIndividuals", -- GreatPersonIndividualType + AttachmentTargetType
	["Improvement"] = "Improvements", -- ImprovementType
	-- ["Leader"] = "LeaderTraits" => "TraitModifiers" -- TraitType
	["Policy"] = "Policies", -- PolicyType
	["Project"] = "Projects", -- ProjectType
	["Technology"] = "Technologies", -- TechnologyType
	["Trait"] = "Traits", -- TraitType
	["UnitAbility"] = "UnitAbilities", -- UnitAbilityType  via TypeTags, i.e. Unit -> Class(Tag) -> TypeTags
	["UnitPromotion"] = "UnitPromotions", -- UnitPromotionType
}

if bIsRiseAndFall then
	tObjectsTables["Alliance"] = "Alliances"; -- no Pedia page for that!
	tObjectsTables["Commemoration"] = "CommemorationTypes"; -- no Pedia page for that!
	tObjectsTables["Governor"] = "Governors"; -- currently empty
	tObjectsTables["GovernorPromotion"] = "GovernorPromotions"; -- GovernorPromotionType
end

if bIsGatheringStorm then
	tObjectsTables["Resolution"] = "Resolutions"; -- no Pedia page for that!
	--tObjectsTables["Discussion"] = "Discussions"; -- no Pedia page for that!
end


-- for policies:  ("Policy",   policyType,   Game.GetLocalPlayer(), nil)
-- for governors: ("Governor", governorType, Game.GetLocalPlayer(), iCityID)
-- for city states: the 5th parameter is used to select proper modifiers, it is the ONLY place where it is used
function CalculateModifierEffect(sObject:string, sObjectType:string, ePlayerID:number, iCityID:number, sInfluence:string)
	--dprint("FUN CalculateModifierEffect(obj,obtype,pid,cid,infl)",sObject,sObjectType,ePlayerID,iCityID,sInfluence);
	local sModifiersTable:string = tModifiersTables[ sObject ];
	-- check if there are modifiers at all
	if sModifiersTable == nil then return "(error)", nil, "No modifiers' table for object "..sObject; end
	local sObjectTypeField:string = sObject.."Type"; -- simple version for starters
	
	-- iterate and find them
	--dprint("...calculating modifiers (obj,table,field)", sObject, sObjectType, ePlayerID, iCityID);
	--TimerStart(); -- debug
	local tTotalImpact:table = YieldTableNew();
	local tToolTip:table = {}; -- tooltip
	local bUnknownEffect:boolean = false;
	local sSubjectFilter:string = ( sInfluence and "PLAYER_HAS_"..sInfluence.."_INFLUENCE" or nil );
	for mod in GameInfo[sModifiersTable]() do
		if mod[sObjectTypeField] == sObjectType then
			-- stupid Firaxis, some fields are named ModifierId and some ModifierID (sic!)
			local sModifierId:string = mod.ModifierId;
			if not sModifierId then sModifierId = mod.ModifierID; end -- fix for BeliefModifiers, GoodyHutSubTypes, ImprovementModifiers
			local sText:string, pYields:table, sAttachedId:string, bUnknown:boolean, tMod:table, tSubjects:table, sSubjectType:string = DecodeModifier(sModifierId, ePlayerID, iCityID);
			-- this the place to check for extra conditions
			if sSubjectFilter == nil or tMod.SubjectReqSetId == sSubjectFilter then
				table.insert(tToolTip, sText);
				if sAttachedId then
					table.insert(tToolTip, "Attached modifier");
					-- in some cases the subjects will be passed down to be processed again
					-- when (a) collection was processed correctly (b) there's more than 1 subject
					if tSubjects ~= nil then
						sText, pYields, sAttachedId, bUnknown, tMod = DecodeModifier(sAttachedId, ePlayerID, iCityID, tSubjects, sSubjectType);
					else
						sText, pYields, sAttachedId, bUnknown, tMod = DecodeModifier(sAttachedId, ePlayerID, iCityID);
					end
					table.insert(tToolTip, sText);
					-- 2019-04-14 Reset yields to 0 if there are no valid subjects that qualify for attaching
					if tSubjects ~= nil and #tSubjects == 0 then
						pYields = nil;
						table.insert(tToolTip, "Attached modifier has NO valid subjects");
					end
				end
				if pYields then YieldTableAdd(tTotalImpact, pYields); end
				bUnknownEffect = bUnknownEffect or bUnknown;
				table.insert(tToolTip, TOOLTIP_SEP);
			end -- extra conditions
		end
	end
	if #tToolTip == 0 then
		table.insert(tToolTip, "No modifiers for this object.");
	end
	
	-- generate total impact string
	--local sTotalImpact:string = "";
	local bImpact:boolean = false;
	--for yield,value in pairs(tTotalImpact) do
		--if value ~= 0 then sTotalImpact = sTotalImpact..(sTotalImpact=="" and "" or " ")..GetYieldString("YIELD_"..yield, value); end
	--end
	--for	_,yield in ipairs(YieldTypesOrder) do
		--if tTotalImpact[yield] ~= 0 then sTotalImpact = sTotalImpact..(sTotalImpact=="" and "" or " ")..GetYieldString("YIELD_"..yield, tTotalImpact[yield]); end
	--end
	local sTotalImpact:string = YieldTableGetInfo(tTotalImpact);
	if sTotalImpact == "" then
		--sTotalImpact = "-"; -- just to show that there's nothing; empty string could be misleading
		table.insert(tToolTip, "Yields not affected.");
	end
	if bUnknownEffect then
		--sTotalImpact = sTotalImpact.." [ICON_Exclamation]";
		table.insert(tToolTip, "[COLOR_Red]Unknown effect[ENDCOLOR] was not processed.");
	end
	
	--TimerTick("All modifiers for object "..sObject..":"..sObjectType); -- debug
	-- done!
	--for _,st in ipairs(tToolTip) do print(sObjectType, string.len(st), st); end -- debug
	return sTotalImpact, tTotalImpact, table.concat(tToolTip, "[NEWLINE]"), bUnknownEffect;
end

------------------------------------------------------------------------------
-- RefreshBaseData should be called when the window is open or after the data has changed
-- Probably could use a Lua event for that (TODO)
-- TODO: what about other players? probably will need multiple tables of cities, but let's start with LocalPlayer
function RefreshBaseData(ePlayerID:number)
	--dprint("FUN RefreshBaseData(player)",ePlayerID)
	local playerID:number = ePlayerID;
	if playerID == nil then playerID = Game.GetLocalPlayer(); end
	local pPlayer	:table = Players[playerID];
	local pCulture	:table = pPlayer:GetCulture();
	local pTreasury	:table = pPlayer:GetTreasury();
	local pReligion	:table = pPlayer:GetReligion();
	local pScience	:table = pPlayer:GetTechs();
	local pResources:table = pPlayer:GetResources();
	local pCities	:table = pPlayer:GetCities();

	tCities = {}; -- clear old values
	
	for _,pCity in pCities:Members() do	
		local cityName:string = pCity:GetName();

		-- Big calls, obtain city data and add report specific fields to it.
		local data:table = GetCityData( pCity );
		-- Add more data (not in CitySupport)
		--data.Resources			= GetCityResourceData( pCity );
		--data.WorkedTileYields, data.NumWorkedTiles = GetWorkedTileYieldData( pCity, pCulture );
		tCities[ cityName ] = data;
		--dprint("**** CITY DATA ****", cityName); -- debug
		--dshowrectable(data); -- debug
	end
	
	GetPlayerData(); -- for COLLECTION_OWNER as Player
	
	GetPlotsData(); -- for COLLECTION_PLAYER_PLOT_YIELDS
	
	bBaseDataDirty = false; -- clean :)
end

-- modifiers helper - could be time-consuming
-- looking for an object that has a specified modifier attached
function GetObjectNameForModifier(sModifierId:string)
	--print("looking for", sModifierId);
	for object,modtable in pairs(tModifiersTables) do
		--print("checking", object, modtable)
		for row in GameInfo[ modtable ]() do
			if row.ModifierId == sModifierId or row.ModifierID == sModifierId then
				--print("found", sModifierId, " for ", row[object.."Type"])
				if object == "Game" then return "[COLOR_Grey]Game[ENDCOLOR]"; end
				local objectInfo:table = GameInfo[ tObjectsTables[object] ][ row[object.."Type"] ];
				--print("   ...", object, objectInfo[object.."Type"], objectInfo.Name)
				if object == "Commemoration" then return Locale.Lookup(objectInfo.CategoryDescription); end
				if objectInfo.Name == nil then return "[COLOR_Grey]"..object.."[ENDCOLOR]"; end -- 2019-08-30 Some traits have no Name
				local sLocName:string = Locale.Lookup(objectInfo.Name);
				if sLocName == objectInfo.Name then return "[COLOR_Grey]"..object.."[ENDCOLOR]"; end-- LOC_ not defined
				return sLocName;
			end
		end
	end
	-- exception for 2nd table for GP modifiers, it contains multiple copies of modifiers, so there's no way to know from which GP the modifier comes anyway
	if string.find(sModifierId, "GREATPERSON") then return "[COLOR_Grey]"..Locale.Lookup("LOC_SLOT_GREAT_PERSON_NAME").."[ENDCOLOR]"; end
	-- check for GoodyHuts, modifiers for them are stored in a different manner
	for row in GameInfo.GoodyHutSubTypes() do 
		if row.ModifierID == sModifierId then return Locale.Lookup( GameInfo.Improvements["IMPROVEMENT_GOODY_HUT"].Name ); end
	end
	-- last try - this could an attached modifer via EFFECT_ATTACH_MODIFIER
	for row in GameInfo.ModifierArguments() do
		if row.Name == "ModifierId" and row.Value == sModifierId then return GetObjectNameForModifier(row.ModifierId); end -- recursive for main modifier
	end
	print("ERROR: GetObjectNameForModifier cannot find object for modifier", sModifierId);
	return "[COLOR_Red]unknown[ENDCOLOR]";
end


------------------------------------------------------------------------------
function Initialize()
	-- exposed members
	RMA.FetchAndCacheData = FetchAndCacheData;
	RMA.DecodeModifier  = DecodeModifier;
	RMA.RefreshBaseData = RefreshBaseData;
	RMA.CalculateModifierEffect = CalculateModifierEffect;
	RMA.GetObjectNameForModifier = GetObjectNameForModifier;
	RMA.YieldTableGetInfo = YieldTableGetInfo;
	
	-- add events that require the base data to be refreshed
	-- only set the dirty flag, the actual data will be refreshed when necessary
	Events.GovernmentChanged.Add(        function() bBaseDataDirty = true end );
	Events.GovernmentPolicyChanged.Add(  function() bBaseDataDirty = true end );
	Events.GovernmentPolicyObsoleted.Add(function() bBaseDataDirty = true end );
	Events.CityAddedToMap.Add(           function() bBaseDataDirty = true end );
	Events.CityFocusChanged.Add(         function() bBaseDataDirty = true end );
	Events.CityPopulationChanged.Add( 	 function() bBaseDataDirty = true end );
	Events.CityProductionChanged.Add(    function() bBaseDataDirty = true end );
	Events.CityProductionCompleted.Add(  function() bBaseDataDirty = true end );
	Events.CityWorkerChanged.Add(        function() bBaseDataDirty = true end );
	Events.DistrictDamageChanged.Add(    function() bBaseDataDirty = true end );
	Events.ImprovementChanged.Add(       function() bBaseDataDirty = true end );
	Events.PlayerResourceChanged.Add(    function() bBaseDataDirty = true end );
	Events.ResearchCompleted.Add(        function() bBaseDataDirty = true end );
	Events.CivicCompleted.Add(           function() bBaseDataDirty = true end );
	Events.TechBoostTriggered.Add( 		 function() bBaseDataDirty = true end );
	Events.CivicBoostTriggered.Add( 	 function() bBaseDataDirty = true end );
	Events.FaithChanged.Add(             function() bBaseDataDirty = true end );
	Events.TreasuryChanged.Add(          function() bBaseDataDirty = true end );
	Events.TradeRouteAddedToMap.Add(     function() bBaseDataDirty = true end );
	Events.TradeRouteRemovedFromMap.Add( function() bBaseDataDirty = true end );
	Events.PlotYieldChanged.Add(         function() bBaseDataDirty = true end );
    Events.GovernorAssigned.Add(         function() bBaseDataDirty = true end );
    Events.GovernorPromoted.Add(         function() bBaseDataDirty = true end );
	Events.PantheonFounded.Add(          function() bBaseDataDirty = true end );
	Events.ReligionFounded.Add(          function() bBaseDataDirty = true end );
	Events.CityReligionChanged.Add( 	 function() bBaseDataDirty = true end );
	Events.UnitAddedToMap.Add(           function() bBaseDataDirty = true end );
	Events.UnitRemovedFromMap.Add(       function() bBaseDataDirty = true end );
	Events.UnitMoveComplete.Add(         function() bBaseDataDirty = true end );
	Events.UnitGreatPersonActivated.Add( function() bBaseDataDirty = true end );
	Events.DiplomacyMeet.Add(            function() bBaseDataDirty = true end );
	Events.DiplomacyRelationshipChanged.Add( function() bBaseDataDirty = true end );
	Events.InfluenceGiven.Add(           function() bBaseDataDirty = true end );
	Events.ImprovementAddedToMap.Add( 	 function() bBaseDataDirty = true end );
	-- Rise & Fall
	if bIsRiseAndFall then
		Events.GovernorAssigned.Add(	 function() bBaseDataDirty = true end );
		Events.GovernorPromoted.Add(	 function() bBaseDataDirty = true end );
		Events.EmergencyStarted.Add( 	 function() bBaseDataDirty = true end );
		Events.EmergencyCompleted.Add( 	 function() bBaseDataDirty = true end );
	end
	
end
Initialize();

print("OK loaded Real Modifier Analysis.lua from Better Report Screen");