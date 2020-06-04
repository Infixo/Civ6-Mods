print("Loading GovernorInspector.lua from Real Governor Inspector version "..(GlobalParameters.RGI_VERSION_MAJOR and GlobalParameters.RGI_VERSION_MAJOR or "0").."."..(GlobalParameters.RGI_VERSION_MINOR and GlobalParameters.RGI_VERSION_MINOR or "0"));
-- ===========================================================================
--	Real Governor Inspector
--	Author: Infixo
--  2020-06-03: Created
-- ===========================================================================
include("InstanceManager");
include("SupportFunctions"); -- TruncateString, Round
include("TabSupport");
--include("Civ6Common");
include("RealYields");

include("Serialize");

-- Expansions check
local bIsRiseAndFall:boolean = Modding.IsModActive("1B28771A-C749-434B-9053-D1380C553DE9"); -- Rise & Fall
--print("Rise & Fall    :", (bIsRiseAndFall and "YES" or "no"));
local bIsGatheringStorm:boolean = Modding.IsModActive("4873eb62-8ccc-4574-b784-dda455e74e68"); -- Gathering Storm
--print("Gathering Storm:", (bIsGatheringStorm and "YES" or "no"));

-- configuration options
local bOptionIncludeOthers:boolean = ( GlobalParameters.RET_OPTION_INCLUDE_OTHERS == 1 );


-- ===========================================================================
--	CONSTANTS
-- ===========================================================================
local LL = Locale.Lookup;
local ENDCOLOR:string = "[ENDCOLOR]";
local NEWLINE:string  = "[NEWLINE]";
local DATA_FIELD_SELECTION						:string = "Selection";
local SIZE_HEIGHT_PADDING_BOTTOM_ADJUST			:number = 85;	-- (Total Y - (scroll area + THIS PADDING)) = bottom area

function ColorGREEN(s) return "[COLOR_Green]"..tostring(s)..ENDCOLOR; end
function ColorRED(s)   return "[COLOR_Red]"  ..tostring(s)..ENDCOLOR; end


-- ===========================================================================
--	VARIABLES
-- ===========================================================================
local m_kCurrentTab:number = 1; -- last active tab which will be also used as a moment category
local m_iMaxEraIndex:number = #GameInfo.Eras-1;
local m_iTajMahalIndex:number = (GameInfo.Buildings.BUILDING_TAJ_MAHAL and GameInfo.Buildings.BUILDING_TAJ_MAHAL.Index or -1);
local m_bIsTajMahal:boolean = false;
m_kMoments = {};
m_simpleIM = InstanceManager:new("SimpleInstance", "Top",    Controls.Stack); -- Non-Collapsable, simple
m_tabIM    = InstanceManager:new("TabInstance",    "Button", Controls.TabContainer);
m_tabs     = nil;

m_kGovernors = {}; -- available governors and their promotions, key is integer, so it can be used as tab number
m_kCities = {}; -- processed data for all cities, key is CityID

--m_kPromosHeader = InstanceManager:new("SimpleInstance", "Top",    Controls.Stack); -- Non-Collapsable, simple
--m_kPromosValues


-- ===========================================================================
-- Helpers
-- ===========================================================================

-- Infixo: this is an iterator to replace pairs
-- it sorts t and returns its elements one by one
-- source: https://stackoverflow.com/questions/15706270/sort-a-table-in-lua
function spairs( t, order_function )
	local keys:table = {}; -- actual table of keys that will bo sorted
	for key,_ in pairs(t) do table.insert(keys, key); end
	
	if order_function then
		table.sort(keys, function(a,b) return order_function(t, a, b) end)
	else
		table.sort(keys)
	end
	-- iterator here
	local i:number = 0;
	return function()
		i = i + 1;
		if keys[i] then
			return keys[i], t[keys[i]]
		end
	end
end


-- ===========================================================================
-- INIT SECTION - called only once
-- ===========================================================================

-- one-time call to init all necessary data
function InitializeData()
	print("FUN InitializeData");
	
	-- list of governors created dynamically because of Ibrahim
	local pPlayer:table = Players[Game.GetLocalPlayer()];
	if pPlayer == nil then return; end
	local playerGovernors:table = pPlayer:GetGovernors();

	-- Add appointable governors
	for governorDef in GameInfo.Governors() do
		if playerGovernors:CanEverAppointGovernor(governorDef.Index) then
			-- get the promotions
			local tPromos:table = {};
			for promo in GameInfo.GovernorPromotionSets() do
				if promo.GovernorType == governorDef.GovernorType then
					local promoInfo:table = GameInfo.GovernorPromotions[ promo.GovernorPromotion ];
					local tPromo:table = {
						PromotionType = promo.GovernorPromotion,
						Name = LL(promoInfo.Name),
						Description = LL(promoInfo.Description),   
					};
					table.insert(tPromos, tPromo);
				end
			end
			local tGovernor:table = {
				Index = governorDef.Index,
				GovernorType = governorDef.GovernorType,
				Name = LL(governorDef.Name),
				IconFill = "[ICON_"..governorDef.GovernorType.."_FILL]",
				IconSlot = "[ICON_"..governorDef.GovernorType.."_SLOT]",
				Promotions = tPromos,
			};
			table.insert(m_kGovernors, tGovernor);
		end
	end
	--dshowrectable(m_kGovernors); -- debug
end


-- ===========================================================================
-- UPDATE SECTION - called every time a window is open, main processing happens here
-- ===========================================================================

-- GameInfo and other static data

-- Reyna adjacencies
local eReynaDistricts:table = {};
table.insert(eReynaDistricts, GameInfo.Districts.DISTRICT_COMMERCIAL_HUB.Index);
table.insert(eReynaDistricts, GameInfo.Districts.DISTRICT_HARBOR.Index);
table.insert(eReynaDistricts, GameInfo.Districts.DISTRICT_ROYAL_NAVY_DOCKYARD.Index);
table.insert(eReynaDistricts, GameInfo.Districts.DISTRICT_COTHON.Index);
table.insert(eReynaDistricts, GameInfo.Districts.DISTRICT_SUGUBA.Index);

-- Reyna power & gold
local eReynaImpr:table = {};
table.insert(eReynaImpr, GameInfo.Improvements.IMPROVEMENT_OFFSHORE_WIND_FARM.Index);
table.insert(eReynaImpr, GameInfo.Improvements.IMPROVEMENT_SOLAR_FARM.Index);
table.insert(eReynaImpr, GameInfo.Improvements.IMPROVEMENT_WIND_FARM.Index);
table.insert(eReynaImpr, GameInfo.Improvements.IMPROVEMENT_GEOTHERMAL_PLANT.Index);

-- Magnus extra production from regional buildings
local eMagnusDistricts:table = {};
table.insert(eMagnusDistricts, GameInfo.Districts.DISTRICT_INDUSTRIAL_ZONE.Index);
table.insert(eMagnusDistricts, GameInfo.Districts.DISTRICT_HANSA.Index);
local eMagnusRegional:table = {};
for building in GameInfo.Buildings() do
	if building.PrereqDistrict == "DISTRICT_INDUSTRIAL_ZONE" and building.RegionalRange > 0 then
		-- find yield
		local iYield:number = 0;
		for row in GameInfo.Building_YieldChanges() do
			if row.BuildingType == building.BuildingType and row.YieldType == "YIELD_PRODUCTION" then iYield = iYield + row.YieldChange; end
		end
		-- we assume all are powered, analysis of power is crazy difficult
		for row in GameInfo.Building_YieldChangesBonusWithPower() do
			if row.BuildingType == building.BuildingType and row.YieldType == "YIELD_PRODUCTION" then iYield = iYield + row.YieldChange; end
		end
		if iYield > 0 then -- no point analyzing 0 yields
			eMagnusRegional[ building.BuildingType ] = {
				Index = building.Index,
				BuildingType = building.BuildingType,
				Range = building.RegionalRange,
				Yield = iYield,
			};
		end
	end
end
--dshowrectable(eMagnusRegional);


-- main function for calculating effects of governors in a specific city
function ProcessCity( pCity:table )
	print("FUN ProcessCity", pCity:GetName());
	
	local localPlayerID:number = Game.GetLocalPlayer();
	if localPlayerID == nil then return end;
	
	-- generic city data - I try to use the same names as in CitySupport.lua
	local data:table = {
		City         = pCity,
		Owner        = pCity:GetOwner(),
		GovernorIcon = "",
		GovernorTT   = "",
		CityName     = LL(pCity:GetName()),
		Population   = pCity:GetPopulation(),
		PromoEffects = {}, -- table of effects, key is PromotionType
		GovernorEffects = {}, -- table of effects, key is GovernorType
		-- working data
		PlotX        = pCity:GetX(),
		PlotY        = pCity:GetY(),
		PlotIndex    = Map.GetPlotIndex(pCity:GetX(),pCity:GetY()),
		-- Magnus
		MagnusTiles = YieldTableNew(), -- num of tiles that can be harvested or feature-removed for specific yield
		--FoodPerTurn  = pCity:GetYield( YieldTypes.FOOD ),
		FoodSurplus = pCity:GetGrowth():GetFoodSurplus(),
		RoutesEnding = 0, -- only your own
		MagnusPlant = "", -- will contain an icon of the power plant resource consumed
		MagnusProduction = 0, -- vertical integration, yield
		MagnusRegional = 0, -- vertical integration, num buildings
		-- Reyna
		RoutesPassing  = 0,
		ReynaAdjacency = 0, -- Comms and Harbors
		ReynaPower     = 0, -- num of eligible power sources
		ReynaTiles     = 0, -- num of unimproved tiles
	};

	
	-- governor
	local pAssignedGovernor = pCity:GetAssignedGovernor();
	if pAssignedGovernor then
		local eGovernorType = pAssignedGovernor:GetType();
		local governorDefinition = GameInfo.Governors[eGovernorType];
		local governorMode = pAssignedGovernor:IsEstablished() and "_FILL]" or "_SLOT]";
		data.GovernorIcon = "[ICON_" .. governorDefinition.GovernorType .. governorMode;
		data.GovernorTT = Locale.Lookup(governorDefinition.Name)..", "..Locale.Lookup(governorDefinition.Title);
	end
	
	
	-- iterate through city plots
	print("..city plots");
	local cityPlots:table = Map.GetCityPlots():GetPurchasedPlots(pCity);
	local pCitizens	: table = pCity:GetCitizens();	
	for _,plotID in ipairs(cityPlots) do
		local plot:table = Map.GetPlotByIndex(plotID);
		local x:number = plot:GetX();
		local y:number = plot:GetY();
		isPlotWorked = pCitizens:IsPlotWorked(x,y);
		if isPlotWorked then
			for row in GameInfo.Yields() do			
				--kYields[row.YieldType] = kYields[row.YieldType] + plot:GetYield(row.Index);				
			end
		end
		-- Support tourism.
		-- Not a common yield, and only exposure from game core is based off
		-- of the plot so the sum is easily shown, but it's not possible to 
		-- show how individual buildings contribute... yet.
		--kYields["TOURISM"] = kYields["TOURISM"] + pCulture:GetTourismAt( plotID );
		local eResource:number = plot:GetResourceType();
		local sResource:string = ( eResource ~= -1 and GameInfo.Resources[eResource].ResourceType or "");
		local eFeature:number = plot:GetFeatureType();
		local sFeature:string = ( eFeature ~= -1 and GameInfo.Features[eFeature].FeatureType or "");
		local eImprovement:number = plot:GetImprovementType();
		local eDistrict:number = plot:GetDistrictType();

		-- Magnus removals
		local function IncMagnusTiles(yield:string)
			YieldTableSetYield( data.MagnusTiles, yield, YieldTableGetYield(data.MagnusTiles, yield) + 1 );
		end
		if eResource ~= -1 then
			for harv in GameInfo.Resource_Harvests() do
				if harv.ResourceType == sResource then IncMagnusTiles(harv.YieldType); end
			end
		end
		if eFeature ~= -1 then
			for harv in GameInfo.Feature_Removes() do
				if harv.FeatureType == sFeature then IncMagnusTiles(harv.YieldType); end
			end
		end
		-- Reyna power
		if IsInTable(eReynaImpr, eImprovement) then data.ReynaPower = data.ReynaPower + 1; end
		-- Reyna unimproved feature tiles
		if eFeature ~= -1 and eImprovement == -1 and eDistrict == -1 then data.ReynaTiles = data.ReynaTiles + 1; end
	end

	-- more city data
	local function CheckBuilding(pCity:table, building:number)
		local cityBuildings:table = pCity:GetBuildings();
		if cityBuildings:HasBuilding(building) and not cityBuildings:IsPillaged(building) then return 1; end
		return 0;
	end
	
	-- Magnus and national routes
	print("..national routes");
	for _,route in ipairs(pCity:GetTrade():GetIncomingRoutes()) do
		if route.OriginCityPlayer == data.Owner then data.RoutesEnding = data.RoutesEnding + 1; end
	end
	
	-- Magnus PP
	if CheckBuilding( pCity, GameInfo.Buildings.BUILDING_COAL_POWER_PLANT.Index )        == 1 then data.MagnusPlant = "[ICON_RESOURCE_COAL]";    end
	if CheckBuilding( pCity, GameInfo.Buildings.BUILDING_FOSSIL_FUEL_POWER_PLANT.Index ) == 1 then data.MagnusPlant = "[ICON_RESOURCE_OIL]";     end
	if CheckBuilding( pCity, GameInfo.Buildings.BUILDING_POWER_PLANT.Index )             == 1 then data.MagnusPlant = "[ICON_RESOURCE_URANIUM]"; end
	--print(data.MagnusPlant);
	
	-- Magnus extra production
	print("..vertical integration");
	local tMagnusBuildings:table = {};
	for _,district in Players[data.Owner]:GetDistricts():Members() do
		if IsInTable(eMagnusDistricts, district:GetType()) then
			local iRange:number = Map.GetPlotDistance(district:GetX(), district:GetY(), data.PlotX, data.PlotY);
			--print("IZ", district:GetID(), "dist", iRange);
			-- check regional buildings
			local city:table = district:GetCity();
			--print("city is", city);
			for _,building in pairs(eMagnusRegional) do
				if tMagnusBuildings[ building.BuildingType ] == nil then tMagnusBuildings[ building.BuildingType ] = 0; end
				if CheckBuilding(city, building.Index) == 1 and iRange <= building.Range then
					tMagnusBuildings[ building.BuildingType ] = tMagnusBuildings[ building.BuildingType ] + 1;
				end
			end
		end
	end
	--dshowtable(tMagnusBuildings);
	-- process vertical integration
	if tMagnusBuildings.BUILDING_FACTORY > 0 then tMagnusBuildings.BUILDING_FACTORY = tMagnusBuildings.BUILDING_FACTORY - 1; end
	if tMagnusBuildings.BUILDING_ELECTRONICS_FACTORY > 0 then tMagnusBuildings.BUILDING_ELECTRONICS_FACTORY = tMagnusBuildings.BUILDING_ELECTRONICS_FACTORY - 1; end
	--dshowtable(tMagnusBuildings);
	if tMagnusBuildings.BUILDING_POWER_PLANT > 0 then tMagnusBuildings.BUILDING_POWER_PLANT = tMagnusBuildings.BUILDING_POWER_PLANT - 1;
	elseif tMagnusBuildings.BUILDING_FOSSIL_FUEL_POWER_PLANT > 0 then tMagnusBuildings.BUILDING_FOSSIL_FUEL_POWER_PLANT = tMagnusBuildings.BUILDING_FOSSIL_FUEL_POWER_PLANT - 1; end
	--dshowtable(tMagnusBuildings);
	for buildingType,num in pairs(tMagnusBuildings) do
		data.MagnusRegional = data.MagnusRegional + num;
		data.MagnusProduction = data.MagnusProduction + num * eMagnusRegional[buildingType].Yield;
	end
	
	-- Reyna and FOREIGN routes passing through (which also includes the destination!)
	print("..foreign routes");
	for _,origPlayer in ipairs(PlayerManager.GetAliveMajors()) do
		local origPlayerID:number = origPlayer:GetID();
		if origPlayerID ~= localPlayerID then
			for _,origCity in origPlayer:GetCities():Members() do
				local origCityID:number = origCity:GetID();
				--print("checking", origPlayer:GetID(), origCity:GetName());
				for _,route in ipairs(origCity:GetTrade():GetOutgoingRoutes()) do
					--print("..route to", route.DestinationCityPlayer, route.DestinationCityID);
					local path:table = Game.GetTradeManager():GetTradeRoutePath( origPlayerID, origCityID, route.DestinationCityPlayer, route.DestinationCityID );
					if IsInTable(path, data.PlotIndex) then data.RoutesPassing = data.RoutesPassing + 1; end
				end -- routes
			end -- cities
		end -- foreign
	end -- players
	
	-- Reyna double adjacency bonuses
	print("..double adjacency");
	for _,district in pCity:GetDistricts():Members() do
		if IsInTable(eReynaDistricts, district:GetType()) then
			data.ReynaAdjacency = data.ReynaAdjacency + district:GetYield(GameInfo.Yields.YIELD_GOLD.Index);
		end
	end
	
	-- Reyna power
	data.ReynaPower = data.ReynaPower + CheckBuilding( pCity, GameInfo.Buildings.BUILDING_HYDROELECTRIC_DAM.Index );

	
	-- get generic data
	-- loop through all promotions, filtering out which are valid will happen later
	print("MAIN LOOP");
	for _,governor in ipairs(m_kGovernors) do
	
		-- gather all yield-type effects for a governor
		local tGovEffect:table = YieldTableNew();
		
		for _,promotion in ipairs(governor.Promotions) do
			local tEffect:table = YieldTableNew();
			local effects:table = {
				Yields = "[ICON_CheckFail]", -- "not processed" mark
				Effect = "",
			};
			local function FormatSetEffect(num:number, icon:string)
				if num > 0 then effects.Effect = tostring(num).."["..icon.."]"; end
			end
			
			--=========
			-- MAIN ENGINE
			--=========
			-- VICTOR
			
			-- AMANI
			
			-- MOKSHA
			
			-- MAGNUS
			if promotion.PromotionType == "GOVERNOR_PROMOTION_RESOURCE_MANAGER_GROUNDBREAKER" then -- extra yields from harvests and removals
				effects.Yields = "";
				for yield,amount in pairs(data.MagnusTiles) do
					if amount > 0 then 
						if #effects.Effect > 0 then effects.Effect = effects.Effect.." "; end
						effects.Effect = effects.Effect..tostring(amount)..GetYieldTextIcon("YIELD_"..yield);
					end
				end
				effects.Effect = "[COLOR_White]"..effects.Effect..ENDCOLOR;
				
			elseif promotion.PromotionType == "GOVERNOR_PROMOTION_RESOURCE_MANAGER_SURPLUS_LOGISTICS" then -- food
				tEffect.FOOD = Round(data.FoodSurplus * 0.2, 1)
				effects.Yields = GetYieldString("YIELD_FOOD", tEffect.FOOD);
				FormatSetEffect(data.RoutesEnding, "ICON_TradeRoute");
				
			elseif promotion.PromotionType == "GOVERNOR_PROMOTION_RESOURCE_MANAGER_EXPEDITION" then -- settlers do not consume population
				effects.Yields = "[ICON_CheckSuccess]"; -- just to mark that it was processed

			elseif promotion.PromotionType == "GOVERNOR_PROMOTION_RESOURCE_MANAGER_INDUSTRIALIST" then -- power and prod from plants
				effects.Yields = "";
				if data.MagnusPlant ~= "" then
					tEffect.PRODUCTION = 2;
					effects.Yields = GetYieldString("YIELD_PRODUCTION", 2);
					effects.Effect = data.MagnusPlant;
				end
				
			elseif promotion.PromotionType == "GOVERNOR_PROMOTION_RESOURCE_MANAGER_BLACK_MARKETEER" then -- cheaper units
				effects.Yields = "[ICON_CheckSuccess]"; -- just to mark that it was processed
				
			elseif promotion.PromotionType == "GOVERNOR_PROMOTION_RESOURCE_MANAGER_VERTICAL_INTEGRATION" then
				if data.MagnusRegional > 0 then
					tEffect.PRODUCTION = data.MagnusProduction;
					effects.Yields = GetYieldString("YIELD_PRODUCTION", data.MagnusProduction);
					effects.Effect = tostring(data.MagnusRegional);
				else
					effects.Yields = GetYieldString("YIELD_PRODUCTION", 0);
				end
			
			
			-- LIANG
			
			-- PINGALA
			
			-- REYNA
			
			elseif promotion.PromotionType == "GOVERNOR_PROMOTION_MERCHANT_LAND_ACQUISITION" then -- +3 gold for each foreign route passing through
				tEffect.GOLD = data.RoutesPassing*3;
				effects.Yields = GetYieldString("YIELD_GOLD", data.RoutesPassing*3);
				FormatSetEffect(data.RoutesPassing, "ICON_TradeRoute");
				
			elseif promotion.PromotionType == "GOVERNOR_PROMOTION_MERCHANT_HARBORMASTER" then -- double adjacency
				tEffect.GOLD = data.ReynaAdjacency;
				effects.Yields = GetYieldString("YIELD_GOLD", data.ReynaAdjacency); -- the gain is one extra adjacency
				
			elseif promotion.PromotionType == "GOVERNOR_PROMOTION_MERCHANT_FORESTRY_MANAGEMENT" then -- +2 gold from unimproved feature tiles
				tEffect.GOLD = data.ReynaTiles*2;
				effects.Yields = GetYieldString("YIELD_GOLD", data.ReynaTiles*2);
				FormatSetEffect(data.ReynaTiles, "ICON_District");
				
			elseif promotion.PromotionType == "GOVERNOR_PROMOTION_MERCHANT_RENEWABLE_ENERGY" then
				tEffect.GOLD  = data.ReynaPower*2;
				tEffect.POWER = data.ReynaPower*2;
				effects.Yields = GetYieldString("YIELD_GOLD", data.ReynaPower*2).." "..GetYieldString("YIELD_POWER", data.ReynaPower*2);
				FormatSetEffect(data.ReynaPower, "ICON_Bolt");
				
			elseif promotion.PromotionType == "GOVERNOR_PROMOTION_MERCHANT_CONTRACTOR" then
				effects.Yields = "[ICON_CheckSuccess]"; -- just to mark that it was processed
				
			elseif promotion.PromotionType == "GOVERNOR_PROMOTION_MERCHANT_TAX_COLLECTOR" then --  - +2 gold per Pop
				tEffect.GOLD  = data.Population*2;
				effects.Yields = GetYieldString("YIELD_GOLD", data.Population*2);
				FormatSetEffect(data.Population, "ICON_Citizen");
				
			end -- main switch
			
			YieldTableAdd(tGovEffect, tEffect);
			data.PromoEffects[ promotion.PromotionType ] = effects;
		end -- promotions
		
		-- store the total effect
		data.GovernorEffects[ governor.GovernorType ] = YieldTableGetInfo(tGovEffect);
		
	end -- governors
	
	--dshowrectable(data); -- debug
	
	return data;
end


function UpdateData()
	print("FUN UpdateData");

	local localPlayerID:number = Game.GetLocalPlayer();
	if localPlayerID == nil then return end;

	local player:table = Players[localPlayerID];
	--local pCulture	:table	= player:GetCulture();
	--local pTreasury	:table	= player:GetTreasury();
	--local pReligion	:table	= player:GetReligion();
	--local pScience	:table	= player:GetTechs();
	--local pResources:table	= player:GetResources();		
	
	m_kCities = {}; -- reset data
	
	for _,pCity in player:GetCities():Members() do	
		--data.Resources			= GetCityResourceData( pCity );					-- Add more data (not in CitySupport)			
		--data.WorkedTileYields	= GetWorkedTileYieldData( pCity, pCulture );	-- Add more data (not in CitySupport)
		table.insert(m_kCities, ProcessCity( pCity ));
	end
	--dshowrectable(m_kCities); -- debug
end


-- ===========================================================================
-- INFO PAGE - refresh the data based on sorts, flags, etc.
-- ===========================================================================

-- clear all data
function ResetTabForNewPageContent()
	m_simpleIM:ResetInstances();
	Controls.Scroll:SetScrollValue( 0 );	
end

-- fills a single instance with the data of the moment
function ShowSingleCity(pCity:table, pInstance:table)
	print("FUN ShowSingleCity", pCity.CityName);
	
	pInstance.Governor:SetText( pCity.GovernorIcon );
	pInstance.Governor:SetToolTipString( pCity.GovernorTT );
	pInstance.CityName:SetText( pCity.CityName );
	pInstance.Population:SetText( pCity.Population );
	pInstance.Total:SetText( pCity.GovernorEffects[ m_kGovernors[m_kCurrentTab].GovernorType ] );
	
	-- fill out effects with dynamic data
	for _,promo in ipairs(m_kGovernors[m_kCurrentTab].Promotions) do
		local pPromoEffectInstance:table = {};
		ContextPtr:BuildInstanceForControl( "PromoEffectInstance", pPromoEffectInstance, pInstance.PromoEffects );
		--dshowrectable(pCity);
		local promoEffects:table = pCity.PromoEffects[ promo.PromotionType ];
		pPromoEffectInstance.Yields:SetText( promoEffects.Yields );
		pPromoEffectInstance.Effect:SetText( promoEffects.Effect );
	end
end

-- sort function
function CitiesSortFunction(t, a, b)
	return t[a].CityName < t[b].CityName;
	--[[
	-- favored always first
	if t[a].Favored ~= t[b].Favored then
		return t[a].Favored;
	end
	-- favored are either both true or both false
	if t[a].EraScore == t[b].EraScore then
		-- sort by descripion
		if t[a].Description == t[b].Description then
			return t[a].Object < t[b].Object;
		end
		return t[a].Description < t[b].Description;
	end
	return t[a].EraScore > t[b].EraScore;
	--]]
end

-- main function - called many times especially when sorting happens
function ViewGovernorPage(eTabNum:number)
	print("FUN ViewGovernorPage", eTabNum);
	if eTabNum == nil then eTabNum = m_kCurrentTab; end
	-- Remember this tab when report is next opened
	m_kCurrentTab = eTabNum;
	
	ResetTabForNewPageContent();
	local instance:table = m_simpleIM:GetInstance();
	instance.Top:DestroyAllChildren();
	--instance.Children = {}
	--instance.Descend = true;
	
	local pHeaderInstance:table = {};
	ContextPtr:BuildInstanceForControl( "CityHeaderInstance", pHeaderInstance, instance.Top );

	-- fill out header with dynamic promo names
	for _,promo in ipairs(m_kGovernors[m_kCurrentTab].Promotions) do
		local pPromoNameInstance:table = {};
		ContextPtr:BuildInstanceForControl( "PromoNameInstance", pPromoNameInstance, pHeaderInstance.PromoNames );
		pPromoNameInstance.PromoName:SetText( promo.Name );
		local isTruncated:boolean = TruncateString(pPromoNameInstance.PromoName, 96, promo.Name);
		if isTruncated then pPromoNameInstance.PromoName:SetToolTipString( promo.Name..NEWLINE..promo.Description );
		else                pPromoNameInstance.PromoName:SetToolTipString( promo.Description ); end
	end
	

	-- civ and leader for uniques
	local localPlayerID:number = Game.GetLocalPlayer();
	if localPlayerID == -1 then return; end
	local sCivilization:string = PlayerConfigurations[localPlayerID]:GetCivilizationTypeName();
	local sLeader:string       = PlayerConfigurations[localPlayerID]:GetLeaderTypeName();
	
	-- checkboxes
	local bEraScore1:boolean = Controls.EraScore1Checkbox:IsSelected();
	local bEraScore2:boolean = Controls.EraScore2Checkbox:IsSelected();
	local bEraScore3:boolean = Controls.EraScore3Checkbox:IsSelected();
	local bEraScore4:boolean = Controls.EraScore4Checkbox:IsSelected();
	local bHideNotActive:boolean    = Controls.HideNotActiveCheckbox:IsSelected();
	local bShowOnlyEarned:boolean   = Controls.ShowOnlyEarnedCheckbox:IsSelected();
	local bHideNotAvailable:boolean = Controls.HideNotAvailableCheckbox:IsSelected();

	-- filter out loop
	local tShow:table = {};
	-- just for test
	for _,city in Players[localPlayerID]:GetCities():Members() do
		table.insert(tShow, city);
	end
	
	-- show loop
	--print("...filtering done, before show");
	for _,city in spairs(m_kCities, CitiesSortFunction) do
		local pCityInstance:table = {};
		ContextPtr:BuildInstanceForControl( "CityEntryInstance", pCityInstance, instance.Top );
		--table.insert( instance.Children, pMomentInstance );
		ShowSingleCity( city, pCityInstance );
	end
	--print("...show loop completed");

	Controls.Stack:CalculateSize();
	Controls.Scroll:CalculateSize();
	Controls.Scroll:SetSizeY( Controls.Main:GetSizeY() - (Controls.BottomFilters:GetSizeY() + SIZE_HEIGHT_PADDING_BOTTOM_ADJUST ) );
	
	-- save current favored moments
	SaveDataToPlayerSlot(localPlayerID, "RETFavoredMoments", tSaveData);
end


-- ===========================================================================
-- SAVING/LOADING PERSISTENT DATA
-- ===========================================================================

------------------------------------------------------------------------------
-- Save player and game related data into Game and Player Values
-- Serialize values using serialize()

function SaveDataToGameSlot(sSlotName:string, data)
	--print("FUN SaveDataToGameSlot() (slot,type)", sSlotName, type(data));
	--dshowrectable(data);
	local sData = serialize(data);
	--print("-->>", sData);
	GameConfiguration.SetValue(sSlotName, sData);
	--local sCheck:string = GameConfiguration.GetValue(sSlotName);
	--print("check:", sCheck == sData);
end

function SaveDataToPlayerSlot(ePlayerID:number, sSlotName:string, data)
	--print("FUN SaveDataToPlayerSlot (pid,slot,type)", ePlayerID, sSlotName, type(data));
	--dshowrectable(data);
	local sData = serialize(data);
	--print("-->>", sData);
	PlayerConfigurations[ePlayerID]:SetValue(sSlotName, sData);
	--local sCheck:string = PlayerConfigurations[ePlayerID]:GetValue(sSlotName);
	--print("check:", sCheck == sData);
end


------------------------------------------------------------------------------
-- Load persistent data (careful - it is BEFORE OnLoadScreenClose)
-- Deserialize values using loadstring()

function LoadDataFromGameSlot(sSlotName:string)
	--print("FUN LoadDataFromGameSlot() (slot)", sSlotName);
	local sData:string = GameConfiguration.GetValue(sSlotName);
	--print("<<--", sData);
	if sData == nil then print("WARNING: LoadDataFromGameSlot no data in slot", sSlotName); return nil; end
	local tTable = loadstring(sData)();
	--dshowrectable(tTable);
	return tTable;
end

function LoadDataFromPlayerSlot(ePlayerID:number, sSlotName:string)
	--print("FUN LoadDataFromPlayerSlot() (pid,slot)", ePlayerID, sSlotName);
	local sData:string = PlayerConfigurations[ePlayerID]:GetValue(sSlotName);
	--print("<<--", sData);
	if sData == nil then print("WARNING: LoadDataFromPlayerSlot no data in slot", sSlotName, "for player", ePlayerID); return nil; end
	local tTable = loadstring(sData)();
	--dshowrectable(tTable);
	return tTable;
end


-- this event is called ONLY when loading a save file
function OnLoadComplete()
	--print("FUN OnLoadComplete");
	-- get favored moments from a save file
	--print("--- LOADING FAVORED MOMENTS ---");
	--for _,playerID in ipairs(PlayerManager.GetAliveIDs()) do
		local data:table = LoadDataFromPlayerSlot(Game.GetLocalPlayer(), "RETFavoredMoments");
		if data ~= nil then -- but make sure we really loaded the data
			for _,key in ipairs(data) do
				if m_kMoments[key] then m_kMoments[key].Favored = true; end
			end
		end
	--end
	--print("--- END LOADING FAVORED ---");
end


-- ===========================================================================
-- UI Single exit point for display
-- ===========================================================================
function Close()
	if not ContextPtr:IsHidden() then
		UI.PlaySound("UI_Screen_Close");
	end
	UIManager:DequeuePopup(ContextPtr);
	LuaEvents.ReportScreen_Closed();
	--print("Closing... current tab is:", m_kCurrentTab);
end


-- ===========================================================================
--	UI Callback
-- ===========================================================================
function OnCloseButton()
	Close();
end


-- ===========================================================================
-- UI Single entry point for display
-- ===========================================================================
function Open( tabToOpen:number )
	print("FUN Open()", tabToOpen, m_kCurrentTab);
	
	UIManager:QueuePopup( ContextPtr, PopupPriority.Medium );
	Controls.ScreenAnimIn:SetToBeginning();
	Controls.ScreenAnimIn:Play();
	UI.PlaySound("UI_Screen_Open");

	UpdateData();
	
	-- To remember the last opened tab when the report is re-opened
	if tabToOpen ~= nil then m_kCurrentTab = tabToOpen; end
	m_tabs.SelectTab( m_kCurrentTab );
	
	-- show era score info
	local pGameEras:table = Game.GetEras();

	-- current era
	Controls.EraNameLabel:SetText( LL("LOC_ERA_PROGRESS_THE_ERA", GameInfo.Eras[ pGameEras:GetCurrentEra() ].Name) );
	-- turns till next
	if pGameEras:GetCurrentEra() == pGameEras:GetFinalEra() then
		Controls.TurnsLabel:SetHide( true );
	else
		Controls.TurnsLabel:SetHide( false );
		local nextEraCountdown:number = pGameEras:GetNextEraCountdown() + 1; -- 0 turns remaining is the last turn, shift by 1 to make sense to non-programmers
		if nextEraCountdown > 0 then
			-- If the era countdown has started only show that number
			Controls.TurnsLabel:SetText( string.format("[ICON_Turn] %d", nextEraCountdown) );
		else
			local inactiveCountdownLength:number = GlobalParameters.NEXT_ERA_TURN_COUNTDOWN; -- Even though the countdown has not started yet, account for it in our time estimates
			local currentTurn:number = Game.GetCurrentGameTurn();
			local iNextEraMinTurn:number = math.max(pGameEras:GetCurrentEraMinimumEndTurn() - currentTurn, inactiveCountdownLength);
			local iNextEraMaxTurn:number = math.max(pGameEras:GetCurrentEraMaximumEndTurn() - currentTurn, inactiveCountdownLength);
			Controls.TurnsLabel:SetText( string.format("[ICON_Turn] %d - %d", iNextEraMinTurn, iNextEraMaxTurn) );
		end
	end
	
	-- player data
	local localPlayerID:number = Game.GetLocalPlayer();
	if localPlayerID == -1 then return; end
	--[[
	-- thresholds
	local iDarkAgeThreshold:number   = pGameEras:GetPlayerDarkAgeThreshold(localPlayerID);
	local iGoldenAgeThreshold:number = pGameEras:GetPlayerGoldenAgeThreshold(localPlayerID);
	--Controls.ThresholdsLabel:SetText( string.format("[ICON_GLORY_DARK_AGE] %s [ICON_GLORY_NORMAL_AGE] %s [ICON_GLORY_GOLDEN_AGE]", ColorRED(iDarkAgeThreshold), ColorGREEN(iGoldenAgeThreshold)) );
	Controls.ThresholdsLabel:SetText( string.format("[ICON_GLORY_DARK_AGE]  %d  [ICON_GLORY_NORMAL_AGE]  %d  [ICON_GLORY_GOLDEN_AGE]", iDarkAgeThreshold, iGoldenAgeThreshold) );
	
	-- total era score
	local iCurrentScore:number = pGameEras:GetPlayerCurrentScore(localPlayerID);
	local sAge:string = "[ICON_GLORY_DARK_AGE]";
	if iCurrentScore >= iDarkAgeThreshold   then sAge = "[ICON_GLORY_NORMAL_AGE]"; end
	if iCurrentScore >= iGoldenAgeThreshold then sAge = "[ICON_GLORY_GOLDEN_AGE]"; end
	Controls.TotalsLabel:SetText( tostring(iCurrentScore).." "..sAge );
	
	-- Taj Mahal
	m_bIsTajMahal = (Players[localPlayerID]:GetStats():GetNumBuildingsOfType(m_iTajMahalIndex) > 0);
	Controls.TajMahalImage:SetHide(not m_bIsTajMahal);
	--]]
end


-- ===========================================================================
-- UI
-- ===========================================================================
function AddTabSection( name:string, populateCallback:ifunction )
	local kTab:table = m_tabIM:GetInstance();
	kTab.Button[DATA_FIELD_SELECTION] = kTab.Selection;

	local callback:ifunction = function()
		if m_tabs.prevSelectedControl ~= nil then
			m_tabs.prevSelectedControl[DATA_FIELD_SELECTION]:SetHide(true);
		end
		kTab.Selection:SetHide(false);
		populateCallback();
	end

	kTab.Button:GetTextControl():SetText( Locale.Lookup(name) );
	kTab.Button:SetSizeToText( 40, 20 ); -- default 40,20
    kTab.Button:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);

	m_tabs.AddTab( kTab.Button, callback );
end


-- ===========================================================================
--	UI Callback
-- ===========================================================================
function OnInputHandler( pInputStruct:table )
	local uiMsg :number = pInputStruct:GetMessageType();
	if uiMsg == KeyEvents.KeyUp then 
		local uiKey = pInputStruct:GetKey();
		if uiKey == Keys.VK_ESCAPE then
			if ContextPtr:IsHidden()==false then
				Close();
				return true;
			end
		end		
	end
	return false;
end


-- ===========================================================================
function Resize()
	local topPanelSizeY:number = 30;
	x,y = UIManager:GetScreenSizeVal();
	Controls.Main:SetSizeY( y - topPanelSizeY );
	Controls.Main:SetOffsetY( topPanelSizeY * 0.5 );
end


-- ===========================================================================
--	Game Event Callback
-- ===========================================================================
function OnLocalPlayerTurnEnd()
	if(GameConfiguration.IsHotseat()) then
		OnCloseButton();
	end
end


-- ===========================================================================
function LateInitialize()
	print("FUN LateInitialize");
	
	InitializeData();
	
	--Resize();
	
	m_tabs = CreateTabs( Controls.TabContainer, 42, 34, 0xFF331D05 );
	
	-- are tabs created dynamically because of Ibrahim

	for index,governor in ipairs(m_kGovernors) do
		-- create a tab
		AddTabSection( governor.IconFill.."  ".. governor.Name, function() ViewGovernorPage( index ); end );
	end

	m_tabs.SameSizedTabs(10);
	m_tabs.CenterAlignTabs(-10);

	--Controls.GovernorTitlesAvailable:SetText(Locale.Lookup("LOC_GOVERNOR_GOVERNOR_TITLES_AVAILABLE", governorPointsObtained - governorPointsSpent));
	--Controls.GovernorTitlesSpent:SetText(Locale.Lookup("LOC_GOVERNOR_GOVERNOR_TITLES_SPENT", governorPointsSpent));
end


-- ===========================================================================
--	UI Event
-- ===========================================================================
function OnInit( isReload:boolean )
	LateInitialize();
	if isReload then		
		if ContextPtr:IsHidden() == false then
			Open();
		end
	end
	m_tabs.AddAnimDeco(Controls.TabAnim, Controls.TabArrow);	
end


-- ===========================================================================
-- CHECKBOXES
-- ===========================================================================
--[[
function OnToggleEraScore1Checkbox()
	local isChecked = Controls.EraScore1Checkbox:IsSelected();
	Controls.EraScore1Checkbox:SetSelected( not isChecked );
	ViewGovernorPage();
end

function OnToggleEraScore2Checkbox()
	local isChecked = Controls.EraScore2Checkbox:IsSelected();
	Controls.EraScore2Checkbox:SetSelected( not isChecked );
	ViewGovernorPage();
end

function OnToggleEraScore3Checkbox()
	local isChecked = Controls.EraScore3Checkbox:IsSelected();
	Controls.EraScore3Checkbox:SetSelected( not isChecked );
	ViewGovernorPage();
end

function OnToggleEraScore4Checkbox()
	local isChecked = Controls.EraScore4Checkbox:IsSelected();
	Controls.EraScore4Checkbox:SetSelected( not isChecked );
	ViewGovernorPage();
end

function OnToggleHideNotActiveCheckbox()
	local isChecked = Controls.HideNotActiveCheckbox:IsSelected();
	Controls.HideNotActiveCheckbox:SetSelected( not isChecked );
	if not isChecked then Controls.ShowOnlyEarnedCheckbox:SetSelected( isChecked ); end
	ViewGovernorPage();
end

function OnToggleShowOnlyEarnedCheckbox()
	local isChecked = Controls.ShowOnlyEarnedCheckbox:IsSelected();
	Controls.ShowOnlyEarnedCheckbox:SetSelected( not isChecked );
	if not isChecked then Controls.HideNotActiveCheckbox:SetSelected( isChecked ); end
	ViewGovernorPage();
end

function OnToggleHideNotAvailableCheckbox()
	local isChecked = Controls.HideNotAvailableCheckbox:IsSelected();
	Controls.HideNotAvailableCheckbox:SetSelected( not isChecked );
	ViewGovernorPage();
end
--]]

-- ===========================================================================
function Initialize()
	-- UI Callbacks
	ContextPtr:SetInitHandler( OnInit );
	ContextPtr:SetInputHandler( OnInputHandler, true );
	Controls.CloseButton:RegisterCallback( Mouse.eLClick, OnCloseButton );
	Controls.CloseButton:RegisterCallback(	Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	-- Filters
	--[[
	Controls.EraScore1Checkbox:RegisterCallback( Mouse.eLClick, OnToggleEraScore1Checkbox );
	Controls.EraScore1Checkbox:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end );
	Controls.EraScore1Checkbox:SetSelected( true );
	Controls.EraScore2Checkbox:RegisterCallback( Mouse.eLClick, OnToggleEraScore2Checkbox );
	Controls.EraScore2Checkbox:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end );
	Controls.EraScore2Checkbox:SetSelected( true );
	Controls.EraScore3Checkbox:RegisterCallback( Mouse.eLClick, OnToggleEraScore3Checkbox );
	Controls.EraScore3Checkbox:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end );
	Controls.EraScore3Checkbox:SetSelected( true );
	Controls.EraScore4Checkbox:RegisterCallback( Mouse.eLClick, OnToggleEraScore4Checkbox );
	Controls.EraScore4Checkbox:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end );
	Controls.EraScore4Checkbox:SetSelected( true );
	Controls.HideNotActiveCheckbox:RegisterCallback( Mouse.eLClick, OnToggleHideNotActiveCheckbox );
	Controls.HideNotActiveCheckbox:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end );
	Controls.HideNotActiveCheckbox:SetSelected( true );
	Controls.ShowOnlyEarnedCheckbox:RegisterCallback( Mouse.eLClick, OnToggleShowOnlyEarnedCheckbox );
	Controls.ShowOnlyEarnedCheckbox:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end );
	Controls.ShowOnlyEarnedCheckbox:SetSelected( false );
	Controls.HideNotAvailableCheckbox:RegisterCallback( Mouse.eLClick, OnToggleHideNotAvailableCheckbox );
	Controls.HideNotAvailableCheckbox:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end );
	Controls.HideNotAvailableCheckbox:SetSelected( true );
	--]]
	-- Events
	LuaEvents.ReportsList_OpenGovernorInspector.Add( function() Open(); end );
	Events.LocalPlayerTurnEnd.Add( OnLocalPlayerTurnEnd );
	-- loading persistent data
	Events.LoadComplete.Add( OnLoadComplete ); -- fires ONLY when loading a game from a save file, when it's ready to start (i.e. circle button appears)
end
Initialize();

print("OK loaded GovernorInspector.lua from Real Governor Inspector");