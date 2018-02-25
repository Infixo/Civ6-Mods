print("Loading Real Modifier Analysis.lua");
-- ===========================================================================
-- Real Modifier Analysis
-- Author: Infixo
-- Created: February 25th - March 1st, 2018
-- ===========================================================================

-- exposing functions and variables
if not ExposedMembers.RMA then ExposedMembers.RMA = {} end;
local RMA = ExposedMembers.RMA;
-- insert functions/objects into RMA in Initialize()


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


-- ===========================================================================
-- DATA AND VARIABLES
-- ===========================================================================

local bBaseDataDirty:boolean = true; -- set to true to refresh the data
local tCities:table = nil; -- dynamically filled when needed (e.g. after refresh)

-- supported Subject types, will be put into SubjectType field of respective tables
local SubjectTypes:table = {
	Game = "Game",
	Player = "Player",
	City = "City",
	District = "District",
	Building = "Building",
	GreatWork = "GreatWork",
}

-- ===========================================================================
-- EXTENDED YIELDS
-- extended yields to support other effects, like Amenities, Tourism, etc.
-- ===========================================================================

-- YieldsTypes 0..5 are for FOOD, PRODUCTION, GOLD, SCIENCE, CULTURE and FAITH
-- they correspond to respective YIELD_ type in Yields table
--YieldTypes.TOURISM =  6;
--YieldTypes.AMENITY =  7;
--YieldTypes.HOUSING =  8;
--YieldTypes.GPPOINT =  9; -- Great Person Point
--YieldTypes.ENVOY   = 10;
--YieldTypes.APPEAL  = 11;
--YieldTypes.LOYALTY = 12;
-- whereever possible keep yields in a table named Yields with entries { YieldType = YieldValue }

-- create a map (speed up)
local YieldTypesMap = {};
for yield in GameInfo.Yields() do
	YieldTypesMap[ yield.YieldType ] = string.gsub(yield.YieldType, "YIELD_","");
end
--dshowtable(YieldTypes);
--dshowtable(YieldTypesMap);

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
function YieldTableAdd(pYieldsA:table, pYieldsB:table)
	local tRes:table = YieldTableNew();
	for yield,_ in pairs(YieldTypes) do tRes[ yield ] = pYieldsA[ yield ] + pYieldsB[ yield ]; end
	return tRes;
end

-- multiply by a given number
function YieldTableMultiply(pYields:table, fModifier:number)
	local tRes:table = YieldTableNew();
	for yield,_ in pairs(YieldTypes) do tRes[ yield ] = pYields[ yield ] * fModifier; end
	return tRes;
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
		iconString="Error:NIL";
	elseif	GameInfo.Yields[yieldType] ~= nil and GameInfo.Yields[yieldType].IconString ~= nil and GameInfo.Yields[yieldType].IconString ~= "" then
		iconString=GameInfo.Yields[yieldType].IconString;
	else
		iconString = "Unknown:"..yieldType; 
	end			
	return iconString;
end

-- ===========================================================================
--	Return the inline entry for a yield's color
-- ===========================================================================
function GetYieldTextColor( yieldType:string )
	if		yieldType == nil or yieldType == "" then return "[COLOR:255,255,255,255]NIL ";
	elseif	yieldType == "YIELD_FOOD"			then return "[COLOR:ResFoodLabelCS]";
	elseif	yieldType == "YIELD_PRODUCTION"		then return "[COLOR:ResProductionLabelCS]";
	elseif	yieldType == "YIELD_GOLD"			then return "[COLOR:ResGoldLabelCS]";
	elseif	yieldType == "YIELD_SCIENCE"		then return "[COLOR:ResScienceLabelCS]";
	elseif	yieldType == "YIELD_CULTURE"		then return "[COLOR:ResCultureLabelCS]";
	elseif	yieldType == "YIELD_FAITH"			then return "[COLOR:ResFaithLabelCS]";
	else											 return "[COLOR:255,255,255,0]ERROR ";
	end				
end

-- ===========================================================================
--	Return a string with +/- or 0 based on any value.
-- ===========================================================================
function toPlusMinusString( value:number )
	if(value == 0) then
		return "0";
	else
		return Locale.ToNumber(value, "+#,###.#;-#,###.#");
	end
end

-- ===========================================================================
--	Return a string with +/- or 0 based on any value.
-- ===========================================================================
function toPlusMinusNoneString( value:number )
	if(value == 0) then
		return " ";
	else
		return Locale.ToNumber(value, "+#,###.#;-#,###.#");
	end
end

-- ===========================================================================
--	Return a string with a yield icon and a +/- based on yield amount.
-- ===========================================================================
function GetYieldString( yieldType:string, amount:number )
	return GetYieldTextIcon(yieldType)..GetYieldTextColor(yieldType)..toPlusMinusString(amount).."[ENDCOLOR]";
end


-- ===========================================================================
--	This function is from SupportFunctions.lua
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
						end
					end

					-- create association between building type and great works
					if #greatWorksInBuilding > 0 then
						result[buildingType] = greatWorksInBuilding;
					end
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
--	For a given city, return a table o' data for it and the surrounding
--	districts.
--	RETURNS:	table of data
--				.City - city object
--				.field - city data
--				.Districts - table of Districts (has Buildings inside)
--						.Buildings - table of Buildings in the District
--				.Wonders - wonders
-- ===========================================================================
function GetCityData( pCity:table )

	local owner					:number = pCity:GetOwner();
	local pPlayer				:table	= Players[owner];
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
		Name					= pCity:GetName(),
		Yields 					= YieldTableNew(), -- extended yields
		Districts				= {},		-- Per Entry Format: { Name, YieldType, YieldChange, Buildings={ Name,YieldType,YieldChange,isPillaged,isBuilt} }
		Wonders					= {},		-- Format per entry: { Name, YieldType, YieldChange }
		ContinentType			= 0,
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
		FoodSurplus						= 0,
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
		Owner							= owner,
		OtherGrowthModifiers			= 0,
		PantheonBelief					= -1,
		Population						= pCity:GetPopulation(),
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

	data.ContinentType					= Map.GetPlot( pCity:GetX(), pCity:GetY() ):GetContinentType();
	data.AmenitiesNetAmount				= pCityGrowth:GetAmenities() - pCityGrowth:GetAmenitiesNeeded();
	data.AmenitiesNum					= pCityGrowth:GetAmenities();
	--data.Yields.AMENITY 				= data.AmenitiesNum;
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
	data.AmenitiesFromGovernors			= pCityGrowth:GetAmenitiesFromGovernors();
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
	data.FoodSurplus					= foodSurplus; --Round( foodSurplus, 1);
	data.Happiness						= pCityGrowth:GetHappiness();
	data.HappinessGrowthModifier		= pCityGrowth:GetHappinessGrowthModifier();
	data.HappinessNonFoodYieldModifier	= pCityGrowth:GetHappinessNonFoodYieldModifier();
	data.HitpointPercent				= ((districtHitpoints-currentDistrictDamage) / districtHitpoints);
	data.HitpointsCurrent				= districtHitpoints-currentDistrictDamage;
	data.HitpointsTotal					= districtHitpoints;
	data.Housing						= pCityGrowth:GetHousing();
	--data.Yields.HOUSING 				= data.Housing;
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


	-- Districts
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
			Name			= Locale.Lookup(districtInfo.Name), 
			Yields   = YieldTableNew(), -- district yields
			--AdjYields   = YieldTableNew(), -- adjacency bonus yields -- Infixo: ADJACENCY = STANDARD YIELD
			DistrictType 	= districtType,
			-- not used yet
			YieldBonus	= GetDistrictYieldText( district ),
			isPillaged  = pCityDistricts:IsPillaged(district:GetType());
			isBuilt		= pCityDistricts:HasDistrict(districtInfo.Index, true);
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
		
		-- extended yields -- Infixo: CHECK seems that Districts don't produce yields by themselves, only adjacency yields
		-- there is no table for that, also both functions produce the same results
		-- BUT! There is ADJUST_DISTRICT_YIELD_CHANGE, used by MODIFIER_PLAYER_DISTRICTS_ADJUST_YIELD_CHANGE and MODIFIER_PLAYER_DISTRICT_ADJUST_YIELD_CHANGE and ADJUST_DISTRICT_EXTRA_REGIONAL_YIELD for MODIFIER_PLAYER_DISTRICT_ADJUST_EXTRA_REGIONAL_YIELD
		-- the first is used by Minors to adjust yields (e.g. MINOR_CIV_SCIENTIFIC_YIELD_FOR_CAMPUS, attached when Medium influence), the other two are not used
		-- the third ise used by GREATPERSON_EXTRA_REGIONAL_BUILDING_PRODUCTION
		-- OK, Minors are giving yields to Buildings now, not Districts, different modifiers are used
		-- Another problem is that calling it with 6 gives negative big integers, unknown (bug?)
		--for yield,yid in pairs(YieldTypes) do districtTable.Yields[ yield ] = district:GetYield( yid ); end
		for yield,yid in pairs(YieldTypes) do districtTable.Yields[ yield ] = district:GetAdjacencyYield( yid ); end -- Infixo: ADJACENCY = STANDARD YIELD
		--districtTable.Yields.TOURISM = 0; -- tourism is produced in another way, GetYield() produces stupid numbers here

		local buildingTypes = pCityBuildings:GetBuildingsAtLocation(plotID);
		for _, buildingType in ipairs(buildingTypes) do
			local building		:table = GameInfo.Buildings[buildingType];
			local kYields		:table = {};

			-- Obtain yield info for buildings.
			for yieldRow in GameInfo.Yields() do
				local yieldChange = pCity:GetBuildingYield(buildingType, yieldRow.YieldType);
				if yieldChange ~= 0 then
					table.insert( kYields, {
						YieldType	= yieldRow.YieldType,
						YieldChange	= yieldChange
					});
				end
			end

			-- Helper: to extract a particular yield type
			function YieldFind( kYields:table, yieldType:string )
				for _,yield in ipairs(kYields) do
					if yield.YieldType == yieldType then
						return yield.YieldChange;
					end
				end
				return 0;	-- none found
			end

			-- Duplicate of data but common yields in an easy to parse format.
			--local culture	:number = YieldFind( kYields, "YIELD_CULTURE" );
			--local faith		:number = YieldFind( kYields, "YIELD_FAITH" );
			--local food		:number = YieldFind( kYields, "YIELD_FOOD" );
			--local gold		:number = YieldFind( kYields, "YIELD_GOLD" );
			--local production:number = YieldFind( kYields, "YIELD_PRODUCTION" );
			--local science	:number = YieldFind( kYields, "YIELD_SCIENCE" );
			-- extended yields
			local extyields :table = YieldTableNew();
			for yield,yid in pairs(YieldTypes) do extyields[ yield ] = pCity:GetBuildingYield(buildingType, yid); end
			-- extyields.TOURISM = 0; -- tourism is produced in another way, GetBuildingYield() produces stupid numbers here ??? I don't know, the bug is for districts for sure
			
			if building.IsWonder then
				table.insert( data.Wonders, {
					SubjectType			= SubjectTypes.Building,
					Name				= Locale.Lookup(building.Name), 
					Yields				= extyields,
					BuildingType		= building.BuildingType,
					-- not used yet
					--Yields				= kYields,
					Icon				= "ICON_"..building.BuildingType,
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
					BuildingType		= building.BuildingType,
					-- not used yet
					--Yields				= kYields,
					Icon				= "ICON_"..building.BuildingType,
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

	local pTrade:table = pCity:GetTrade();
	for iPlayer:number = 0, MapConfiguration.GetMaxMajorPlayers()-1,1 do
		if (pTrade:HasActiveTradingPost(iPlayer)) then
			table.insert( data.TradingPosts, iPlayer );
		end
	end


	return data;
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
	table.insert(tOut, INDENT2..Capitalize(tReq.ReqType));
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
			break;
		end
	end
	-- check if it exists!
	if table.count(tModifier) == 0 then return nil; end
	-- DynamicModifiers
	sModifierType = tModifier.ModifierType;
	for mod in GameInfo.DynamicModifiers() do
		if mod.ModifierType == sModifierType then
			tModifier.CollectionType = mod.CollectionType;
			tModifier.EffectType     = mod.EffectType;
			break;
		end
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
-- Returns 3 values:
--  string - decoded into text (tooltip), contains info about structure, owner, subjects and final impact
--  table - extended yields table
--  string - id of the attached modifier, if an effect is "attach modifier"
function DecodeModifier(sModifierId:string)
	local tMod:table = FetchAndCacheData(sModifierId);
	if not tMod then return "ERROR: "..sModifierId.." not defined!"; end
	local tOut = {};
	table.insert(tOut, "Id: "..Capitalize(tMod.ModifierId));
	if tMod.OwnerReqSetId then
		table.insert(tOut, "Owner: "..Capitalize(tMod.OwnerReqSetId));
		DecodeReqSet(tOut, tMod.OwnerReqSetId);
	end
	table.insert(tOut, Capitalize(tMod.CollectionType));
	if tMod.SubjectReqSetId then
		table.insert(tOut, "Subject: "..Capitalize(tMod.SubjectReqSetId));
		DecodeReqSet(tOut, tMod.SubjectReqSetId);
	end
	table.insert(tOut, Capitalize(tMod.EffectType));
	for name,value in pairs(tMod.Arguments) do table.insert(tOut, name.." = "..value); end
	if tMod.ScaleByGameSpeed then table.insert(tOut, "Scaled by Game Speed"); end
	if tMod.RunOnce then table.insert(tOut, "Run Once"); end
	if tMod.NewOnly then table.insert(tOut, "New Only"); end
	if tMod.Permanent then table.insert(tOut, "Permanent"); end
	-- analysis starts here
	if bBaseDataDirty then RefreshBaseData(); end -- make sure we have current data
	-- TODO: ASSUMPTION Owner will be Player, this is true for Policies and many other modifiers
	-- TODO: add support for other owners later, if necessary
	local tOwner:table, sOwnerType:string = Players[ Game:GetLocalPlayer() ], SubjectTypes.Player;
	-- build a collection of subjects
	local tSubjects:table, sSubjectType:string = BuildCollectionOfSubjects(tMod, tOwner, sOwnerType);
	dprint("Subjects are:"); dshowtable(tSubjects); -- debug
	table.insert(tOut, "Subject(s): "..sSubjectType..", num: "..table.count(tSubjects));
	-- calculate impact of the modifier
	local tImpact:table = YieldTableNew();
	for i,subject in pairs(tSubjects) do
		local tSubjectImpact:table = ApplyEffectAndCalculateImpact(tMod, subject, sSubjectType); -- it will return nil if effect unknown
		if tSubjectImpact then
			--dprint("Impact for subject (i)", i); dshowtable(tSubjectImpact); -- debug
			tImpact = YieldTableAdd(tImpact, tSubjectImpact);
		end
	end
	dprint("Impact for all subjects"); dshowyields(tImpact); -- debug
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
	-- return 3 values
	return table.concat(tOut, "[NEWLINE]"), tImpact, ((tMod.EffectType == "EFFECT_ATTACH_MODIFIER") and tMod.Arguments.ModifierId) or nil
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
	dprint("FUNCAL CheckOneRequirement(req,type,sub)(subject)",tReq.ReqId,tReq.ReqType,sSubjectType,tSubject.SubjectType,tSubject.Name);
	
	local function CheckForMismatchError(sExpectedType:string)
		if sExpectedType == sSubjectType then return false; end
		print("ERROR: CheckOneRequirement mismatch for subject", sSubjectType); dshowtable(tReq); return true;
	end
	
	-- MAIN DISPATCHER FOR REQUIREMENTS
	local bIsValidSubject:boolean = false;
	
	if     tReq.ReqType == "REQUIREMENT_REQUIREMENTSET_IS_MET" then -- 19
		-- recursion? could be diffcult
		
	elseif tReq.ReqType == "REQUIREMENT_CITY_HAS_BUILDING" then -- 35, Wonders too!
		if CheckForMismatchError(SubjectTypes.City) then return false; end
		for _,district in ipairs(tSubject.Districts) do
			for _,building in ipairs(district.Buildings) do
				local buildingType:string = building.BuildingType;	
				if GameInfo.BuildingReplaces[ buildingType ] then buildingType = GameInfo.BuildingReplaces[ buildingType ].ReplacesBuildingType; end
				bIsValidSubject = ( buildingType == tReq.Arguments.BuildingType ); -- BUILDING_LIGHTHOUSE, etc.
				if bIsValidSubject then break; end
			end
			if bIsValidSubject then break; end
		end
		if not bIsValidSubject then -- still not found
			for _,wonder in ipairs(tSubject.Wonders) do
				-- wonders don't have replacements
				bIsValidSubject = ( wonder.BuildingType == tReq.Arguments.BuildingType ); -- BUILDING_ST_BASILS_CATHEDRAL, etc.
				if bIsValidSubject then break; end
			end
		end

	elseif tReq.ReqType == "REQUIREMENT_CITY_HAS_DISTRICT" then -- 10
		if CheckForMismatchError(SubjectTypes.City) then return false; end
		for _,district in ipairs(tSubject.Districts) do
			local districtType:string = district.DistrictType;	
			if GameInfo.DistrictReplaces[ districtType ] then districtType = GameInfo.DistrictReplaces[ districtType ].ReplacesDistrictType; end
			bIsValidSubject = ( districtType == tReq.Arguments.DistrictType ); -- DISTRICT_THEATER, etc.
			if bIsValidSubject then break; end
		end

	elseif tReq.ReqType == "REQUIREMENT_CITY_HAS_X_SPECIALTY_DISTRICTS" then -- 4
		if CheckForMismatchError("City") then return false; end

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
		
	elseif tReq.ReqType == "REQUIREMENT_PLOT_TERRAIN_TYPE_MATCHES" then -- 14
		if CheckForMismatchError("Plot") then return false; end
		
	elseif tReq.ReqType == "REQUIREMENT_PLOT_FEATURE_TYPE_MATCHES" then -- 10
		if CheckForMismatchError("Plot") then return false; end
		
	else
		-- do nothing here... probably will never implement all possible types
		return false;
	end
	if tReq.Inverse then return not bIsValidSubject; end
	return bIsValidSubject;
end


------------------------------------------------------------------------------
-- Requires 3 arguments
--  table - requirement set
--  table - subject to analyze (from tCities or any other)
--  string - type of subject (e.g. "City", "District")
function CheckAllRequirements(tReqSet:table, tSubject:table, sSubjectType:string)
	dprint("FUNCAL CheckAllRequirements(req,sub)(subject)",tReqSet.ReqSetId,sSubjectType,tSubject.SubjectType,tSubject.Name);
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
--  strng - type of the subject
function BuildCollectionOfSubjects(tMod:table, tOwner:table, sOwnerType:string)
	print("FUNCAL BuildCollectionOfSubjects(sub,owner)",tMod.SubjectReqSetId,sOwnerType);
	local tSubjects:table, sSubjectType:string = {}, "(unknown)";
	local tReqSet:table = tMod.SubjectReqSet; -- speed up some checking
	dprint("  Subject requirement set is (id)", tMod.SubjectReqSetId);
	-- MAIN DISPATCHER FOR COLLECTIONS
	if tMod.CollectionType == "COLLECTION_OWNER" then
		-- most difficult one... not yet...
	elseif tMod.CollectionType == "COLLECTION_CITY_DISTRICTS" then
		-- need City here as owner
		sSubjectType = "District";
	elseif tMod.CollectionType == "COLLECTION_PLAYER_CAPITAL_CITY" then
		sSubjectType = "City";
		for cityname,citydata in pairs(tCities) do
			if citydata.IsCapital then
			end
		end
	elseif tMod.CollectionType == "COLLECTION_PLAYER_CITIES" then
		sSubjectType = SubjectTypes.City;
		for cityname,citydata in pairs(tCities) do
			if tReqSet then 
				if CheckAllRequirements(tReqSet, citydata, sSubjectType) then table.insert(tSubjects, citydata); end
			else
				table.insert(tSubjects, citydata);
			end
		end
	elseif tMod.CollectionType == "COLLECTION_PLAYER_DISTRICTS" then
		sSubjectType = SubjectTypes.District;
		for cityname,citydata in pairs(tCities) do
			for _,district in ipairs(citydata.Districts) do
				if tReqSet then  
					if CheckAllRequirements(tReqSet, district, sSubjectType) then table.insert(tSubjects, district); end
				else
					table.insert(tSubjects, district);
				end
			end
		end
	else
		-- do nothing here... probably will never implement all possible types
	end
	return tSubjects, sSubjectType;
end


------------------------------------------------------------------------------
-- Returns a table of extended yields
-- It will return nil if an effect is unknown
function ApplyEffectAndCalculateImpact(tMod:table, tSubject:table, sSubjectType:string)
	dprint("FUNCAL ApplyEffectAndCalculateImpact(mod,eff,sub)(subject)",tMod.ModifierId,tMod.EffectType,sSubjectType,tSubject.SubjectType,tSubject.Name);

	local function CheckForMismatchError(sExpectedType:string)
		if sExpectedType == tSubject.SubjectType then return false; end
		print("ERROR: ApplyEffectAndCalculateImpact mismatch for subject", sSubjectType); dshowtable(tMod); return true;
	end
	
	-- MAIN DISPATCHER FOR EFFECTS
	local tImpact:table = YieldTableNew();
	
	if tMod.EffectType == "" then
	
	elseif tMod.EffectType == "EFFECT_ADJUST_CITY_YIELD_MODIFIER" then
		if CheckForMismatchError(SubjectTypes.City) then return nil; end
		YieldTableSetYield(tImpact, tMod.Arguments.YieldType, YieldTableGetYield(tSubject.Yields, tMod.Arguments.YieldType) * tonumber(tMod.Arguments.Amount) / 100.0);
		dprint("  Impact for subject (type,name)",tSubject.SubjectType,tSubject.Name); dshowyields(tSubject.Yields); dshowyields(tImpact); -- debug
		return tImpact;
	
	elseif tMod.EffectType == "EFFECT_ADJUST_DISTRICT_YIELD_MODIFIER" then
		if CheckForMismatchError(SubjectTypes.District) then return nil; end
		YieldTableSetYield(tImpact, tMod.Arguments.YieldType, YieldTableGetYield(tSubject.Yields, tMod.Arguments.YieldType) * tonumber(tMod.Arguments.Amount) / 100.0);
		dprint("  Impact for subject (type)", tSubject.DistrictType); dshowyields(tSubject.Yields); dshowyields(tImpact); -- debug
		return tImpact;
	
	elseif tMod.EffectType == "EFFECT_ADJUST_DISTRICT_YIELD_CHANGE" then
		if CheckForMismatchError("District") then return nil; end
		
	elseif tMod.EffectType == "EFFECT_ADJUST_BUILDING_YIELD_CHANGE" then
		if CheckForMismatchError("District") then return nil; end
		
	elseif tMod.EffectType == "EFFECT_ADJUST_BUILDING_YIELD_MODIFIER" then
		if CheckForMismatchError("District") then return nil; end
		
	elseif tMod.EffectType == "EFFECT_ADJUST_BUILDING_HOUSING" then
		if CheckForMismatchError("City") then return nil; end
		
	else
		-- do nothing here... probably will never implement all possible types
	end
	return nil;
end


------------------------------------------------------------------------------
-- RefreshBaseData should be called when the window is open or after the data has changed
-- Probably could use a Lua event for that (TODO)
-- TODO: what about other players? probably will need multiple tables of cities, but let's start with LocalPlayer
function RefreshBaseData(ePlayerID:number)
	dprint("FUNCAL RefreshBaseData(player)",ePlayerID)
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
		--data.OutgoingRoutes = pCity:GetTrade():GetOutgoingRoutes(); -- Add outgoing route data
		tCities[ cityName ] = data;
		--dprint("**** CITY DATA ****", cityName); -- debug
		--dshowrectable(data); -- debug
	end
	bBaseDataDirty = false; -- clean :)
end

function Initialize()
	-- exposed members
	RMA.DecodeModifier  = DecodeModifier;
	RMA.RefreshBaseData = RefreshBaseData;
	
	-- add events that require the base data to be refreshed
	-- only set the dirty flag, the actual data will be refreshed when necessary
	Events.GovernmentChanged.Add(        function() bBaseDataDirty = true end );
	Events.GovernmentPolicyChanged.Add(  function() bBaseDataDirty = true end );
	Events.GovernmentPolicyObsoleted.Add(function() bBaseDataDirty = true end );
	Events.CityAddedToMap.Add(           function() bBaseDataDirty = true end );
	Events.CityFocusChanged.Add(         function() bBaseDataDirty = true end );
	Events.CityProductionChanged.Add(    function() bBaseDataDirty = true end );
	Events.CityProductionCompleted.Add(  function() bBaseDataDirty = true end );
	Events.CityWorkerChanged.Add(        function() bBaseDataDirty = true end );
	Events.DistrictDamageChanged.Add(    function() bBaseDataDirty = true end );
	Events.ImprovementChanged.Add(       function() bBaseDataDirty = true end );
	Events.PlayerResourceChanged.Add(    function() bBaseDataDirty = true end );
	Events.ResearchCompleted.Add(        function() bBaseDataDirty = true end );
	Events.CivicCompleted.Add(           function() bBaseDataDirty = true end );
	Events.FaithChanged.Add(             function() bBaseDataDirty = true end );
	Events.TreasuryChanged.Add(          function() bBaseDataDirty = true end );
	Events.TradeRouteAddedToMap.Add(     function() bBaseDataDirty = true end );
	Events.TradeRouteRemovedFromMap.Add( function() bBaseDataDirty = true end );
	Events.PlotYieldChanged.Add(         function() bBaseDataDirty = true end );
    Events.GovernorAssigned.Add(         function() bBaseDataDirty = true end );
    Events.GovernorPromoted.Add(         function() bBaseDataDirty = true end );
	Events.PantheonFounded.Add(          function() bBaseDataDirty = true end );
	Events.ReligionFounded.Add(          function() bBaseDataDirty = true end );
	
end
Initialize();

print("OK loaded Real Modifier Analysis.lua");