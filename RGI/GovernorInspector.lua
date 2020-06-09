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
include("PopupDialog");
include("RealYields");

include("Serialize");

-- Expansions check
local bIsRiseAndFall:boolean = Modding.IsModActive("1B28771A-C749-434B-9053-D1380C553DE9"); -- Rise & Fall
--print("Rise & Fall    :", (bIsRiseAndFall and "YES" or "no"));
local bIsGatheringStorm:boolean = Modding.IsModActive("4873eb62-8ccc-4574-b784-dda455e74e68"); -- Gathering Storm
--print("Gathering Storm:", (bIsGatheringStorm and "YES" or "no"));

-- configuration options
local bOptionTotalAll:boolean = ( GlobalParameters.RGI_OPTION_TOTAL_ALL == 1 );


-- ===========================================================================
--	CONSTANTS
-- ===========================================================================
local LL = Locale.Lookup;
local ENDCOLOR:string = "[ENDCOLOR]";
local NEWLINE:string  = "[NEWLINE]";
local TOOLTIP_SEP								:string = "-------------------";
local DATA_FIELD_SELECTION						:string = "Selection";
local SIZE_HEIGHT_PADDING_BOTTOM_ADJUST			:number = 85;	-- (Total Y - (scroll area + THIS PADDING)) = bottom area

function ColorGREEN(s) return "[COLOR_Green]"..tostring(s)..ENDCOLOR; end
function ColorRED(s)   return "[COLOR_Red]"  ..tostring(s)..ENDCOLOR; end


-- ===========================================================================
--	VARIABLES
-- ===========================================================================

local m_kCurrentTab:number = 1; -- last active tab which will be also used as a moment category
m_simpleIM = InstanceManager:new("SimpleInstance", "Top",    Controls.Stack); -- Non-Collapsable, simple
m_tabIM    = InstanceManager:new("TabInstance",    "Button", Controls.TabContainer);
m_tabs     = nil;

m_kGovernors = {}; -- available governors and their promotions, key is integer, so it can be used as tab number
m_kCities = {}; -- processed data for all cities, key is CityID

--m_kPromosHeader = InstanceManager:new("SimpleInstance", "Top",    Controls.Stack); -- Non-Collapsable, simple
--m_kPromosValues
m_kPoliciesIM = InstanceManager:new("PolicyInstance", "Top", Controls.PoliciesStack);


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
						Index = promoInfo.Index,
						PromotionType = promoInfo.GovernorPromotionType,
						Name = LL(promoInfo.Name),
						Description = LL(promoInfo.Description),
						IsActive = false, -- this will be updated during Open
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
				PromotionsTT = {}, -- tooltip with promotions
			};
			table.insert(m_kGovernors, tGovernor);
		end
	end
	--dshowrectable(m_kGovernors); -- debug
end


-- ===========================================================================
-- UPDATE SECTION - called every time a window is open, main processing happens here
-- ===========================================================================

-- refresh governor promotions and the tooltip
function UpdateGovernorPromotions()
	print("FUN UpdateGovernorPromotions()");
	
	local localPlayerID:number = Game.GetLocalPlayer();
	if localPlayerID == nil then return end;
	
	local playerGovernors:table = Players[localPlayerID]:GetGovernors();
	
	-- check if a governor has a specific promotion
	function CheckGovernorPromotion(eGovernor:number, ePromotion:number)
		--print("FUN CheckGovernorPromotion", eGovernor, ePromotion);
		local hasAny:boolean, governorList:table = playerGovernors:GetGovernorList();
		if not hasAny then print("NONE APPOINTED"); return false; end -- none appointed, no promotions
		for _,governor in ipairs(governorList) do
			if governor:GetType() == eGovernor and governor:HasPromotion(ePromotion) then return true; end --print("....YES"); return true; end
		end
		--print("....no matching promo");
		return false; -- no matching promo found
	end
	
	for _,governor in ipairs(m_kGovernors) do
		governor.PromotionsTT = ""; -- reset
		for _,promo in ipairs(governor.Promotions) do
			--print("..checking promo", governor.GovernorType, promo.PromotionType);
			promo.IsActive = CheckGovernorPromotion(governor.Index, promo.Index);
			if promo.IsActive then
				if governor.PromotionsTT ~= "" then governor.PromotionsTT = governor.PromotionsTT .. NEWLINE; end
				governor.PromotionsTT = governor.PromotionsTT .. "[ICON_Bullet]" .. promo.Description;
			end
		end
	end
end


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

-- Pingala GW types
local ePingalaGWTypes:table = {
"GREATWORKOBJECT_SCULPTURE",
"GREATWORKOBJECT_PORTRAIT",
"GREATWORKOBJECT_LANDSCAPE",
"GREATWORKOBJECT_WRITING",
"GREATWORKOBJECT_MUSIC",
};


-- main function for calculating effects of governors in a specific city
function ProcessCity( pCity:table )
	print("FUN ProcessCity", pCity:GetName());
	
	local localPlayerID:number = Game.GetLocalPlayer();
	if localPlayerID == nil then return end;
	local playerResources:table = Players[localPlayerID]:GetResources();
	
	local cityGrowth:table = pCity:GetGrowth();
	local cityBuildings:table = pCity:GetBuildings();
	
	-- generic city data - I try to use the same names as in CitySupport.lua
	local data:table = {
		City         = pCity,
		Owner        = pCity:GetOwner(),
		Status       = "", -- icons with the city status, only NEGATIVE effects are shown
		Governor     = -1, -- assigned gov
		IsEstablished = false,
		GovernorIcon = "",
		GovernorTT   = "",
		CityName     = LL(pCity:GetName()),
		CapitalIcon  = (pCity:IsCapital() and "[ICON_Capital]" or ""),
		Population   = pCity:GetPopulation(),
		PromoEffects = {}, -- table of effects, key is PromotionType
		GovernorEffects = {}, -- table of effects, key is GovernorType
		-- working data
		PlotX        = pCity:GetX(),
		PlotY        = pCity:GetY(),
		PlotIndex    = Map.GetPlotIndex(pCity:GetX(),pCity:GetY()),
		HappinessNonFoodYieldModifier = cityGrowth:GetHappinessNonFoodYieldModifier(), -- modifier from amenities
		HappinessGrowthModifier		  = cityGrowth:GetHappinessGrowthModifier(), -- YIELD_FOOD
		-- Victor
		VictorResources = {}, -- strat resources
		VictorProject = "", -- WMD
		VictorProduction = 0, -- extra production
		-- Magnus
		MagnusTiles = YieldTableNew(), -- num of tiles that can be harvested or feature-removed for specific yield
		--FoodPerTurn  = pCity:GetYield( YieldTypes.FOOD ),
		FoodSurplus = cityGrowth:GetFoodSurplus(),
		RoutesEnding = 0, -- only your own
		MagnusPlant = "", -- will contain an icon of the power plant resource consumed
		MagnusProduction = 0, -- vertical integration, yield
		MagnusRegional = 0, -- vertical integration, num buildings
		-- Liang
		LiangFisheries = 0, -- num of fisheries
		LiangParks = 0, -- num of recreation parks
		LiangHousing = 0, -- neighborhood and aqueduct
		LiangAmenities = 0, -- canals and dams
		LiangProduction = 0, -- production bonus
		LiangDistrict = "", -- name of the district
		-- Pingala
		PingalaCulture = 0, -- extra yield
		PingalaScience = 0, -- extra yield
		PingalaTourism = 0, -- tourism from GWs
		PingalaNumGW = 0, -- num of eligible GWs
		PingalaProject = "", -- space race
		PingalaProduction = 0, -- extra production
		PingalaGPP = {}, -- extra GPPs
		-- Reyna
		RoutesPassing  = 0,
		ReynaAdjacency = 0, -- Comms and Harbors
		ReynaPower     = 0, -- num of eligible power sources
		ReynaTiles     = 0, -- num of unimproved tiles
	};

	-- more city data
	local hashItemProduced:number = pCity:GetBuildQueue():GetCurrentProductionTypeHash();
	
	local function CheckBuilding(pCity:table, building:number)
		local cityBuildings:table = pCity:GetBuildings();
		if cityBuildings:HasBuilding(building) and not cityBuildings:IsPillaged(building) then return 1; end
		return 0;
	end
	
	-- city status - power
	if not pCity:GetPower():IsFullyPowered() then -- insufficient power
		data.Status = data.Status .. "[ICON_PowerInsufficient]";
	end
	-- city status - loyalty
	if pCity:GetCulturalIdentity():GetLoyaltyPerTurn() < 0 then
		data.Status = data.Status .. "[ICON_PressureDown]";
	end
	-- city status - under siege
	local pDistrict:table = Players[localPlayerID]:GetDistricts():FindID( pCity:GetDistrictID() );
	if pDistrict ~= nil and pDistrict:IsUnderSiege() then
		data.Status = data.Status .. "[ICON_UnderSiege]";
	end
	-- city status - occupied
	if pCity:IsOccupied() then
		data.Status = data.Status .. "[ICON_Occupied]";
	end
	-- city status - housing
	if cityGrowth:GetHousing() < data.Population then -- insufficient housing
		data.Status = data.Status .. "[ICON_HousingInsufficient]";
	end
	-- city status - amenities
	if cityGrowth:GetAmenities() < cityGrowth:GetAmenitiesNeeded() then
		data.Status = data.Status .. "[ICON_AmenitiesInsufficient]";
	end
	
	-- governor
	local function GetPromotionTT(eGov:number)
		for _,gov in ipairs(m_kGovernors) do
			if gov.Index == eGov then return gov.PromotionsTT; end
		end
		return "";
	end
	local pAssignedGovernor = pCity:GetAssignedGovernor();
	if pAssignedGovernor then
		data.Governor = pAssignedGovernor:GetType();
		data.IsEstablished = pAssignedGovernor:IsEstablished();
		local governorDefinition = GameInfo.Governors[data.Governor];
		local governorMode = data.IsEstablished and "_FILL]" or "_SLOT]";
		data.GovernorIcon = "[ICON_" .. governorDefinition.GovernorType .. governorMode;
		data.GovernorTT = Locale.Lookup(governorDefinition.Name)..", "..Locale.Lookup(governorDefinition.Title)..NEWLINE..GetPromotionTT(data.Governor);
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
		local sImprovement:string = ( eImprovement ~= -1 and GameInfo.Improvements[eImprovement].ImprovementType or "");
		local bIsImprovementPillaged:boolean = plot:IsImprovementPillaged();
		local eDistrict:number = plot:GetDistrictType();
		
		-- Victor strat resources
		local function IsImprovementValid(sImprovement:string, sResource:string)
			--print("IsImprovementValid", sImprovement, sResource);
			for row in GameInfo.Improvement_ValidResources() do
				if row.ImprovementType == sImprovement and row.ResourceType == sResource then return true; end
			end
			return false;
		end
		if eResource ~= -1 and GameInfo.Resources[eResource].ResourceClassType == "RESOURCECLASS_STRATEGIC" and playerResources:IsResourceVisible(eResource) then
			if (eImprovement ~= -1 and IsImprovementValid(sImprovement, sResource) and not bIsImprovementPillaged) or eDistrict ~= -1 then
				if data.VictorResources[sResource] == nil then data.VictorResources[sResource] = 0; end
				data.VictorResources[sResource] = data.VictorResources[sResource] + 1;
			end
		end
		
		-- Magnus removals
		local function IncMagnusTiles(yield:string)
			YieldTableSetYield( data.MagnusTiles, yield, YieldTableGetYield(data.MagnusTiles, yield) + 1 );
		end
		if eResource ~= -1 then -- TODO: technically should check if visible, but only strategic ones have this issue and they cannot be harvestes in the vanilla game
			for harv in GameInfo.Resource_Harvests() do
				if harv.ResourceType == sResource then IncMagnusTiles(harv.YieldType); end
			end
		end
		if eFeature ~= -1 then
			for harv in GameInfo.Feature_Removes() do
				if harv.FeatureType == sFeature then IncMagnusTiles(harv.YieldType); end
			end
		end
		-- Liang
		if eImprovement == GameInfo.Improvements.IMPROVEMENT_FISHERY.Index and not bIsImprovementPillaged then
			data.LiangFisheries = data.LiangFisheries + 1;
		end
		if eImprovement == GameInfo.Improvements.IMPROVEMENT_CITY_PARK.Index and not bIsImprovementPillaged then
			data.LiangParks = data.LiangParks + 1;
		end
		
		-- Reyna power
		if IsInTable(eReynaImpr, eImprovement) and not bIsImprovementPillaged then data.ReynaPower = data.ReynaPower + 1; end
		-- Reyna unimproved feature tiles
		if eFeature ~= -1 and eImprovement == -1 and eDistrict == -1 then data.ReynaTiles = data.ReynaTiles + 1; end
	end
	
	-- Victor nuclear production
	-- This extra production does not appear as increase in the total prod output but only as less turns to finish the project
	local tProjectProduced:table = GameInfo.Projects[ hashItemProduced ];
	if hashItemProduced ~= 0 and tProjectProduced ~= nil and tProjectProduced.WMD then
		data.VictorProject = LL(tProjectProduced.ShortName);
		local baseCityProd:number = pCity:GetYield("YIELD_PRODUCTION") / (1 + data.HappinessNonFoodYieldModifier/100.0);
		data.VictorProduction = Round( baseCityProd * 0.3, 1 );
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
		--print("....ID", district:GetID());
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
	if tMagnusBuildings.BUILDING_FACTORY             and tMagnusBuildings.BUILDING_FACTORY             > 0 then tMagnusBuildings.BUILDING_FACTORY             = tMagnusBuildings.BUILDING_FACTORY             - 1; end
	if tMagnusBuildings.BUILDING_ELECTRONICS_FACTORY and tMagnusBuildings.BUILDING_ELECTRONICS_FACTORY > 0 then tMagnusBuildings.BUILDING_ELECTRONICS_FACTORY = tMagnusBuildings.BUILDING_ELECTRONICS_FACTORY - 1; end
	--dshowtable(tMagnusBuildings);
	if     tMagnusBuildings.BUILDING_POWER_PLANT             and tMagnusBuildings.BUILDING_POWER_PLANT             > 0 then tMagnusBuildings.BUILDING_POWER_PLANT             = tMagnusBuildings.BUILDING_POWER_PLANT             - 1;
	elseif tMagnusBuildings.BUILDING_FOSSIL_FUEL_POWER_PLANT and tMagnusBuildings.BUILDING_FOSSIL_FUEL_POWER_PLANT > 0 then tMagnusBuildings.BUILDING_FOSSIL_FUEL_POWER_PLANT = tMagnusBuildings.BUILDING_FOSSIL_FUEL_POWER_PLANT - 1; end
	--dshowtable(tMagnusBuildings);
	for buildingType,num in pairs(tMagnusBuildings) do
		data.MagnusRegional = data.MagnusRegional + num;
		data.MagnusProduction = data.MagnusProduction + num * eMagnusRegional[buildingType].Yield;
	end
	
	-- Liang water works
	print("..water works");
	for _,district in pCity:GetDistricts():Members() do
		local eDistrict:number = district:GetType();
		-- housing
		if eDistrict == GameInfo.Districts.DISTRICT_NEIGHBORHOOD.Index then data.LiangHousing = data.LiangHousing + 1; end
		if eDistrict == GameInfo.Districts.DISTRICT_MBANZA.Index then data.LiangHousing = data.LiangHousing + 1; end
		if eDistrict == GameInfo.Districts.DISTRICT_AQUEDUCT.Index then data.LiangHousing = data.LiangHousing + 1; end
		if eDistrict == GameInfo.Districts.DISTRICT_BATH.Index then data.LiangHousing = data.LiangHousing + 1; end
		-- amenities
		if eDistrict == GameInfo.Districts.DISTRICT_CANAL.Index then data.LiangAmenities = data.LiangAmenities + 1; end
		if eDistrict == GameInfo.Districts.DISTRICT_DAM.Index then data.LiangAmenities = data.LiangAmenities + 1; end
	end
	
	-- Liang district production
	-- Liang seems to be broken as she doesn't provide 20% modifier but flat +4 prod - weird
	local tDistrictProduced:table = GameInfo.Districts[ hashItemProduced ];
	if hashItemProduced ~= 0 and tDistrictProduced ~= nil then
		data.LiangDistrict = LL(tDistrictProduced.Name);
		local baseCityProd:number = pCity:GetYield("YIELD_PRODUCTION");
		local cityProdMod:number = data.HappinessNonFoodYieldModifier; -- modifier
		if data.Governor == GameInfo.Governors.GOVERNOR_THE_BUILDER.Index and data.IsEstablished then
			cityProdMod = cityProdMod + 20;
		end
		baseCityProd = baseCityProd / (1 + cityProdMod/100.0);
		data.LiangProduction = Round( baseCityProd * 0.2, 1 );
	end
	
	-- Pingala extra yields
	local baseCityCulture:number = pCity:GetYield("YIELD_CULTURE");
	local baseCityScience:number = pCity:GetYield("YIELD_SCIENCE");
	if data.Governor == GameInfo.Governors.GOVERNOR_THE_EDUCATOR.Index and data.IsEstablished then
		baseCityCulture = baseCityCulture / (1 + (data.HappinessNonFoodYieldModifier + 15)/100);
		baseCityScience = baseCityScience / (1 + (data.HappinessNonFoodYieldModifier + 15)/100);
	else
		baseCityCulture = baseCityCulture / (1 + (data.HappinessNonFoodYieldModifier +  0)/100);
		baseCityScience = baseCityScience / (1 + (data.HappinessNonFoodYieldModifier +  0)/100);
	end
	data.PingalaCulture = Round( baseCityCulture * 0.15, 1 );
	data.PingalaScience = Round( baseCityScience * 0.15, 1 );
	
	-- Pingala GW
	print("..great works");
	for building in GameInfo.Buildings() do
		local buildingIndex:number = building.Index;
		if cityBuildings:HasBuilding(buildingIndex) then
			local iNumSlots:number = cityBuildings:GetNumGreatWorkSlots(buildingIndex);
			--print("..", building.BuildingType, iNumSlots);
			if iNumSlots > 0 then
				-- count GWs
				for idx = 0, iNumSlots-1 do
					local eGWIdx:number = cityBuildings:GetGreatWorkInSlot(buildingIndex, idx);
					if eGWIdx ~= -1 then
						local eGW:number = cityBuildings:GetGreatWorkTypeFromIndex(eGWIdx);
						--print("....gw,type", eGW,GameInfo.GreatWorks[eGW].GreatWorkObjectType);
						if IsInTable(ePingalaGWTypes, GameInfo.GreatWorks[eGW].GreatWorkObjectType) then
							data.PingalaNumGW = data.PingalaNumGW + 1;
						end
					end
				end
				-- get regular tourism except Artifacts
				--print("....tourism", cityBuildings:GetBuildingTourismFromGreatWorks(false, buildingIndex));
				if cityBuildings:GetGreatWorkSlotType(buildingIndex, 0) ~= GameInfo.GreatWorkSlotTypes.GREATWORKSLOT_ARTIFACT.Index then
					data.PingalaTourism = data.PingalaTourism + cityBuildings:GetBuildingTourismFromGreatWorks(false, buildingIndex);
				end
			end
		end -- in city
	end -- all buildings
	
	-- Pingala space project production
	-- This extra production does not appear as increase in the total prod output but only as less turns to finish the project
	--local tProjectProduced:table = GameInfo.Projects[ hashItemProduced ];
	if hashItemProduced ~= 0 and tProjectProduced ~= nil and tProjectProduced.SpaceRace then
		data.PingalaProject = LL(tProjectProduced.ShortName);
		--if data.Governor == GameInfo.Governors.GOVERNOR_THE_EDUCATOR.Index and data.IsEstablished then
			--data.PingalaProduction = Round( pCity:GetYield("YIELD_PRODUCTION") -  pCity:GetYield("YIELD_PRODUCTION") / 1.3, 1 );
		--else
		local baseCityProd:number = pCity:GetYield("YIELD_PRODUCTION") / (1 + data.HappinessNonFoodYieldModifier/100.0);
		data.PingalaProduction = Round( baseCityProd * 0.3, 1 );
		--end
	end

	-- Pingala GPPs
	print("..great people points");
	for building in GameInfo.Buildings() do
		local buildingType:string  = building.BuildingType;
		local buildingIndex:number = building.Index;
		if cityBuildings:HasBuilding(buildingIndex) and not cityBuildings:IsPillaged(buildingIndex) then
			for row in GameInfo.Building_GreatPersonPoints() do
				if row.BuildingType == buildingType then
					if data.PingalaGPP[row.GreatPersonClassType] == nil then data.PingalaGPP[row.GreatPersonClassType] = 0; end
					data.PingalaGPP[row.GreatPersonClassType] = data.PingalaGPP[row.GreatPersonClassType] + row.PointsPerTurn;
				end
			end
			--print("..building", buildingType);
		end -- in city
	end -- buildings
	--dshowtable(data.PingalaGPP);
	
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
				Yields = "",
				Effect = "",
			};
			local bCheckSuccess:boolean = false; -- just to mark that it was processed
			local function FormatSetEffect(num:number, icon:string)
				if num > 0 then effects.Effect = tostring(num).."["..icon.."]"; end
			end
			
			--=========
			-- MAIN ENGINE
			--=========
			
			-- VICTOR
			--GOVERNOR_PROMOTION_REDOUBT
			--GOVERNOR_PROMOTION_GARRISON_COMMANDER
			--GOVERNOR_PROMOTION_EMBRASURE
			--GOVERNOR_PROMOTION_AIR_DEFENSE_INITIATIVE
			if promotion.PromotionType == "GOVERNOR_PROMOTION_DEFENSE_LOGISTICS" then
				effects.Yields = "";
				for class,amount in pairs(data.VictorResources) do
					--if amount > 0 then 
						if #effects.Effect > 0 then effects.Effect = effects.Effect.." "; end
						effects.Effect = effects.Effect..tostring(amount).."[ICON_"..class.."]";
					--end
				end
				effects.Effect = "[COLOR_White]"..effects.Effect..ENDCOLOR;
			
			elseif promotion.PromotionType == "GOVERNOR_PROMOTION_EDUCATOR_ARMS_RACE_PROPONENT" then
				tEffect.PRODUCTION = data.VictorProduction;
				--effects.Effect = data.VictorProject;
				if data.VictorProduction > 0 then effects.Effect = "[ICON_RESOURCE_URANIUM]"; end
		
			
			-- AMANI
			
			-- MOKSHA
			
			-- MAGNUS
			elseif promotion.PromotionType == "GOVERNOR_PROMOTION_RESOURCE_MANAGER_GROUNDBREAKER" then -- extra yields from harvests and removals
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
				--effects.Yields = GetYieldString("YIELD_FOOD", tEffect.FOOD);
				FormatSetEffect(data.RoutesEnding, "ICON_TradeRoute");
				
			elseif promotion.PromotionType == "GOVERNOR_PROMOTION_RESOURCE_MANAGER_EXPEDITION" then -- settlers do not consume population
				bCheckSuccess = true;
				--effects.Yields = "[ICON_CheckSuccess]"; -- just to mark that it was processed

			elseif promotion.PromotionType == "GOVERNOR_PROMOTION_RESOURCE_MANAGER_INDUSTRIALIST" then -- power and prod from plants
				effects.Yields = "";
				if data.MagnusPlant ~= "" then
					tEffect.PRODUCTION = 2;
					--effects.Yields = GetYieldString("YIELD_PRODUCTION", 2);
					effects.Effect = data.MagnusPlant;
				end
				
			elseif promotion.PromotionType == "GOVERNOR_PROMOTION_RESOURCE_MANAGER_BLACK_MARKETEER" then -- cheaper units
				bCheckSuccess = true;
				--effects.Yields = "[ICON_CheckSuccess]"; -- just to mark that it was processed
				
			elseif promotion.PromotionType == "GOVERNOR_PROMOTION_RESOURCE_MANAGER_VERTICAL_INTEGRATION" then
				if data.MagnusRegional > 0 then
					tEffect.PRODUCTION = data.MagnusProduction;
					--effects.Yields = GetYieldString("YIELD_PRODUCTION", data.MagnusProduction);
					effects.Effect = tostring(data.MagnusRegional);
				else
					--effects.Yields = "";
				end
			
			
			-- LIANG
			
			elseif promotion.PromotionType == "GOVERNOR_PROMOTION_BUILDER_GUILDMASTER" then -- builders +1 charge
				bCheckSuccess = true;
				--effects.Yields = "[ICON_CheckSuccess]"; -- just to mark that it was processed
				
			elseif promotion.PromotionType == "GOVERNOR_PROMOTION_ZONING_COMMISSIONER" then -- +20% towards constructing districts
				tEffect.PRODUCTION = data.LiangProduction;
				effects.Effect = data.LiangDistrict;
			
			elseif promotion.PromotionType == "GOVERNOR_PROMOTION_AQUACULTURE" then -- fisheries +1 prod
				tEffect.PRODUCTION = data.LiangFisheries;
				--effects.Yields = YieldTableGetInfo(tEffect);
				FormatSetEffect(data.LiangFisheries, "ICON_District");
			
			elseif promotion.PromotionType == "GOVERNOR_PROMOTION_REINFORCED_INFRASTRUCTURE" then -- no damage
				bCheckSuccess = true;
				--effects.Yields = "[ICON_CheckSuccess]"; -- just to mark that it was processed
				
			elseif promotion.PromotionType == "GOVERNOR_PROMOTION_WATER_WORKS" then -- housing and amenities
				tEffect.HOUSING = data.LiangHousing*2;
				tEffect.AMENITY = data.LiangAmenities;
				--effects.Yields = YieldTableGetInfo(tEffect);
				--effects.Effect = string.format("%d[ICON_DISTRICT_NEIGHBORHOOD][ICON_DISTRICT_AQUEDUCT] %d[ICON_DISTRICT_CANAL][ICON_DISTRICT_DAM]", data.LiangHousing, data.LiangAmenities);
				if data.LiangAmenities > 0 or data.LiangHousing > 0 then
					effects.Effect = string.format("%d  /  %d", data.LiangAmenities, data.LiangHousing);
				end
			
			elseif promotion.PromotionType == "GOVERNOR_PROMOTION_PARKS_RECREATION" then -- city parks +3 culture
				tEffect.CULTURE = data.LiangParks*3;
				--effects.Yields = YieldTableGetInfo(tEffect);
				FormatSetEffect(data.LiangParks, "ICON_District");

			
			-- PINGALA
			
			elseif promotion.PromotionType == "GOVERNOR_PROMOTION_EDUCATOR_LIBRARIAN" then
				tEffect.CULTURE = data.PingalaCulture;
				tEffect.SCIENCE = data.PingalaScience;
				
			elseif promotion.PromotionType == "GOVERNOR_PROMOTION_EDUCATOR_CONNOISSEUR" then
				tEffect.CULTURE = data.Population;
				FormatSetEffect(data.Population, "ICON_Citizen");
				
			elseif promotion.PromotionType == "GOVERNOR_PROMOTION_EDUCATOR_RESEARCHER" then
				tEffect.SCIENCE = data.Population;
				FormatSetEffect(data.Population, "ICON_Citizen");
				
			elseif promotion.PromotionType == "GOVERNOR_PROMOTION_EDUCATOR_GRANTS" then
				--local tGPPs:table = {};
				local iTotGPP:number = 0;
				for class,num in pairs(data.PingalaGPP) do
					--table.insert(tGPPs, string.format("%d%s", num, GameInfo.GreatPersonClasses[class].IconString));
					iTotGPP = iTotGPP + num;
				end
				--effects.Effect = table.concat(tGPPs, " ");
				effects.Effect = "[COLOR_White]+"..tostring(iTotGPP)..ENDCOLOR;
				
			elseif promotion.PromotionType == "GOVERNOR_PROMOTION_MERCHANT_CURATOR" then
				tEffect.TOURISM = data.PingalaTourism;
				effects.Effect = tostring(data.PingalaNumGW);
				
			elseif promotion.PromotionType == "GOVERNOR_PROMOTION_EDUCATOR_SPACE_INITIATIVE" then
				tEffect.PRODUCTION = data.PingalaProduction;
				--effects.Effect = data.PingalaProject;
				if data.PingalaProduction > 0 then effects.Effect = "[ICON_DISTRICT_SPACEPORT]"; end

			
			-- REYNA
			
			elseif promotion.PromotionType == "GOVERNOR_PROMOTION_MERCHANT_LAND_ACQUISITION" then -- +3 gold for each foreign route passing through
				tEffect.GOLD = data.RoutesPassing*3;
				--effects.Yields = YieldTableGetInfo(tEffect);
				FormatSetEffect(data.RoutesPassing, "ICON_TradeRoute");
				
			elseif promotion.PromotionType == "GOVERNOR_PROMOTION_MERCHANT_HARBORMASTER" then -- double adjacency
				tEffect.GOLD = data.ReynaAdjacency; -- the gain is one extra adjacency
				--effects.Yields = YieldTableGetInfo(tEffect);
				
			elseif promotion.PromotionType == "GOVERNOR_PROMOTION_MERCHANT_FORESTRY_MANAGEMENT" then -- +2 gold from unimproved feature tiles
				tEffect.GOLD = data.ReynaTiles*2;
				--effects.Yields = YieldTableGetInfo(tEffect);
				FormatSetEffect(data.ReynaTiles, "ICON_District");
				
			elseif promotion.PromotionType == "GOVERNOR_PROMOTION_MERCHANT_RENEWABLE_ENERGY" then
				tEffect.GOLD  = data.ReynaPower*2;
				tEffect.POWER = data.ReynaPower*2;
				--effects.Yields = YieldTableGetInfo(tEffect);
				FormatSetEffect(data.ReynaPower, "ICON_Bolt");
				
			elseif promotion.PromotionType == "GOVERNOR_PROMOTION_MERCHANT_CONTRACTOR" then
				bCheckSuccess = true;
				--effects.Yields = "[ICON_CheckSuccess]"; -- just to mark that it was processed
				
			elseif promotion.PromotionType == "GOVERNOR_PROMOTION_MERCHANT_TAX_COLLECTOR" then --  - +2 gold per Pop
				tEffect.GOLD  = data.Population*2;
				--effects.Yields = YieldTableGetInfo(tEffect);
				FormatSetEffect(data.Population, "ICON_Citizen");
				
			end -- main switch
			
			effects.Yields = ( bCheckSuccess and "[ICON_CheckSuccess]" or YieldTableGetInfo(tEffect) );
			data.PromoEffects[ promotion.PromotionType ] = effects;
			-- sum up only effects from active promotions
			if bOptionTotalAll or promotion.IsActive then
				YieldTableAdd(tGovEffect, tEffect);
			end
			
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
	
	UpdateGovernorPromotions();
	
	m_kCities = {}; -- reset data
	
	for _,pCity in player:GetCities():Members() do	
		--data.Resources			= GetCityResourceData( pCity );					-- Add more data (not in CitySupport)			
		--data.WorkedTileYields	= GetWorkedTileYieldData( pCity, pCulture );	-- Add more data (not in CitySupport)
		table.insert(m_kCities, ProcessCity( pCity ));
	end
	--dshowrectable(m_kCities); -- debug
end


-- ===========================================================================
-- Assign governor - code from GovernorAssignmentChooser.lua
-- ===========================================================================

function ConfirmedAssignment(data:table)
	-- Request assignment
	local pLocalPlayer = Players[Game.GetLocalPlayer()];
	if (pLocalPlayer ~= nil) then
		local kParameters:table = {};
		kParameters[PlayerOperations.PARAM_GOVERNOR_TYPE] = m_kGovernors[m_kCurrentTab].Index; --m_SelectedGovernorID;
		kParameters[PlayerOperations.PARAM_PLAYER_ONE] = data.City:GetOwner(); --m_SelectedCityOwner;
		kParameters[PlayerOperations.PARAM_CITY_DEST] = data.City:GetID(); --m_SelectedCityID;
		UI.RequestPlayerOperation(Game.GetLocalPlayer(), PlayerOperations.ASSIGN_GOVERNOR, kParameters);
		-- refresh
		UpdateData();
		ViewGovernorPage();
	end
end

function AssignGovernor(data:table)
	local localPlayerID = Game.GetLocalPlayer();
	if (localPlayerID ~= nil) then
		local pCity = data.City; --CityManager.GetCity(m_SelectedCityOwner, m_SelectedCityID);
		if pCity ~= nil and pCity:GetAssignedGovernor() ~= nil then
			local pAssignedGovernor = pCity:GetAssignedGovernor();
			local governorOwner = pAssignedGovernor:GetOwner();
			if (pAssignedGovernor:GetOwner() == localPlayerID) then
				-- If this city already has an assigned governor popup a popup dialog to confirm the replacement
				local popup:table = PopupDialogInGame:new( "GovernorAssignmentReplaceConfirm" );
				--popup:ShowYesNoDialog( Locale.Lookup("LOC_GOVERNOR_ASSIGNMENT_CONFIRM_REPLACEMENT"), function() ConfirmedAssignment(); LuaEvents.GovernorPanel_Open(); end );
				popup:ShowYesNoDialog( Locale.Lookup("LOC_GOVERNOR_ASSIGNMENT_CONFIRM_REPLACEMENT"), function() ConfirmedAssignment(data); end );
			else
				ConfirmedAssignment(data);
				--LuaEvents.GovernorPanel_Close();
			end
		else
			ConfirmedAssignment(data);
			--LuaEvents.GovernorPanel_Close();
		end
	end
end


-- ===========================================================================
-- INFO PAGE - refresh the data based on sorts, flags, etc.
-- ===========================================================================

local tColumnSize:table = {
	-- Victor
	GOVERNOR_PROMOTION_GARRISON_COMMANDER = 95,
	GOVERNOR_PROMOTION_DEFENSE_LOGISTICS = 140,
	GOVERNOR_PROMOTION_EMBRASURE = 95,
	-- Magnus
	GOVERNOR_PROMOTION_RESOURCE_MANAGER_GROUNDBREAKER = 130,
	GOVERNOR_PROMOTION_RESOURCE_MANAGER_EXPEDITION = 100,
	GOVERNOR_PROMOTION_RESOURCE_MANAGER_BLACK_MARKETEER = 100,
	-- Pingala
	GOVERNOR_PROMOTION_EDUCATOR_LIBRARIAN = 150,
	GOVERNOR_PROMOTION_EDUCATOR_CONNOISSEUR = 100,
	GOVERNOR_PROMOTION_EDUCATOR_RESEARCHER = 100,
	GOVERNOR_PROMOTION_EDUCATOR_GRANTS = 100,
	GOVERNOR_PROMOTION_MERCHANT_CURATOR = 100,
	-- Liang
	GOVERNOR_PROMOTION_BUILDER_GUILDMASTER = 100,
	GOVERNOR_PROMOTION_ZONING_COMMISSIONER = 130,
	GOVERNOR_PROMOTION_REINFORCED_INFRASTRUCTURE = 100,
};

-- clear all data
function ResetTabForNewPageContent()
	m_simpleIM:ResetInstances();
	Controls.Scroll:SetScrollValue( 0 );	
end

-- fills a single instance with the data of the moment
function ShowSingleCity(pCity:table, pInstance:table)
	print("FUN ShowSingleCity", pCity.CityName);
	local function TruncateWithToolTip(control:table, length:number, text:string)
		local isTruncated:boolean = TruncateString(control, length, text);
		if isTruncated then control:SetToolTipString(text); end
	end
	
	pInstance.Governor:SetText( pCity.GovernorIcon );
	pInstance.Governor:SetToolTipString( pCity.GovernorTT );
	pInstance.CityName:SetText( pCity.CapitalIcon..pCity.CityName.."  "..pCity.Status );
	pInstance.Population:SetText( pCity.Population );
	TruncateWithToolTip(pInstance.Total, 198, pCity.GovernorEffects[ m_kGovernors[m_kCurrentTab].GovernorType ]);
	
	-- go to the city after clicking
	pInstance.GoToCityButton:SetToolTipString( "[ICON_GoingTo] "..pCity.CityName );
	pInstance.GoToCityButton:RegisterCallback( Mouse.eLClick, function() Close(); UI.LookAtPlot( pCity.City:GetX(), pCity.City:GetY() ); UI.SelectCity( pCity.City ); end );
	--pInstance.GoToCityButton:RegisterCallback( Mouse.eRClick, function() AssignGovernor(pCity); end );
	pInstance.GoToCityButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound( "Main_Menu_Mouse_Over" ); end );
	
	
	-- fill out effects with dynamic data
	for _,promo in ipairs(m_kGovernors[m_kCurrentTab].Promotions) do
		local pPromoEffectInstance:table = {};
		ContextPtr:BuildInstanceForControl( "PromoEffectInstance", pPromoEffectInstance, pInstance.PromoEffects );
		--dshowrectable(pCity);
		local promoEffects:table = pCity.PromoEffects[ promo.PromotionType ];
		--TruncateWithToolTip(pPromoEffectInstance.Yields, 120, promoEffects.Yields);
		--TruncateWithToolTip(pPromoEffectInstance.Effect, 120, promoEffects.Effect);
		pPromoEffectInstance.Yields:SetText(promoEffects.Yields);
		pPromoEffectInstance.Effect:SetText(promoEffects.Effect);
		-- dynamic column width
		if tColumnSize[promo.PromotionType] ~= nil then
			pPromoEffectInstance.Top:SetSizeX( tColumnSize[promo.PromotionType] );
		end
		--[[
		if promo.PromotionType == "GOVERNOR_PROMOTION_EDUCATOR_CONNOISSEUR" or promo.PromotionType == "GOVERNOR_PROMOTION_EDUCATOR_RESEARCHER" then
			pPromoEffectInstance.Top:SetSizeX(100);
		elseif promo.PromotionType == "GOVERNOR_PROMOTION_EDUCATOR_LIBRARIAN" then
			pPromoEffectInstance.Top:SetSizeX(160);
		end
		-]]
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
		-- dynamic column width
		local iColumnSize:number = 110; -- default
		if tColumnSize[promo.PromotionType] ~= nil then
			iColumnSize = tColumnSize[promo.PromotionType];
			pPromoNameInstance.Top:SetSizeX( iColumnSize );
		end
		--pPromoNameInstance.PromoName:SetText( promo.Name );
		--local sName:string = 
		local isTruncated:boolean = TruncateString(pPromoNameInstance.PromoName, iColumnSize-4, promo.Name);
		local tTT:table = {};
		if isTruncated then table.insert(tTT, promo.Name); end
		table.insert(tTT, promo.Description);
		local sLocExtra = "LOC_RGI_"..promo.PromotionType;
		local sExtra:string = LL(sLocExtra);
		if sExtra ~= sLocExtra then table.insert(tTT, TOOLTIP_SEP); table.insert(tTT, sExtra); end
		pPromoNameInstance.PromoName:SetToolTipString( table.concat(tTT, NEWLINE) );
		-- is earned?
		if promo.IsActive then
			pPromoNameInstance.PromoName:SetColor(UI.GetColorValue("COLOR_WHITE"));
		end
	end
	
	-- civ and leader for uniques
	--local localPlayerID:number = Game.GetLocalPlayer();
	--if localPlayerID == -1 then return; end
	--local sCivilization:string = PlayerConfigurations[localPlayerID]:GetCivilizationTypeName();
	--local sLeader:string       = PlayerConfigurations[localPlayerID]:GetLeaderTypeName();
	--[[
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
	--]]
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
	Controls.Scroll:SetSizeY( Controls.Main:GetSizeY() - Controls.PoliciesSection:GetSizeY() - SIZE_HEIGHT_PADDING_BOTTOM_ADJUST );
	
	-- save current favored moments
	--SaveDataToPlayerSlot(localPlayerID, "RETFavoredMoments", tSaveData);
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
	--[[
		local data:table = LoadDataFromPlayerSlot(Game.GetLocalPlayer(), "RETFavoredMoments");
		if data ~= nil then -- but make sure we really loaded the data
			for _,key in ipairs(data) do
				if m_kMoments[key] then m_kMoments[key].Favored = true; end
			end
		end
	--]]
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

local tPolicies:table = {
	"POLICY_PRAETORIUM", -- classical
	"POLICY_CIVIL_PRESTIGE", -- medieval
	"POLICY_COMMUNICATIONS_OFFICE", -- information
	"POLICY_GOV_MERCHANT_REPUBLIC",
	"POLICY_GOV_THEOCRACY",
	"POLICY_GOV_COMMUNISM",
};

-- refresh additional information displayed in the window
function RefreshAdditionalInfo()

	-- player data
	local localPlayerID:number = Game.GetLocalPlayer();
	if localPlayerID == -1 then return; end
	
	local playerGovernors:table = Players[localPlayerID]:GetGovernors();
	local governorPointsObtained = playerGovernors:GetGovernorPoints();
	local governorPointsSpent = playerGovernors:GetGovernorPointsSpent();
	Controls.GovernorTitlesAvailable:SetText(Locale.Lookup("LOC_GOVERNOR_GOVERNOR_TITLES_AVAILABLE", governorPointsObtained - governorPointsSpent));
	Controls.GovernorTitlesSpent:SetText(Locale.Lookup("LOC_GOVERNOR_GOVERNOR_TITLES_SPENT", governorPointsSpent));
	
	-- Audience Chamber
	if GameInfo.Buildings.BUILDING_GOV_TALL ~= nil then
		Controls.AudienceChamberImage:SetHide( Players[localPlayerID]:GetStats():GetNumBuildingsOfType(GameInfo.Buildings.BUILDING_GOV_TALL.Index) == 0 );
	else
		Controls.AudienceChamberImage:SetHide( true );
	end
	
	-- Policies
	m_kPoliciesIM:ResetInstances();
	local playerCulture:table = Players[localPlayerID]:GetCulture();
	-- government enabled policy
	local sGovPolicy:string = "";
	if playerCulture:GetCurrentGovernment() ~= -1 then
		sGovPolicy = GameInfo.Governments[ playerCulture:GetCurrentGovernment() ].PolicyToUnlock;
		if sGovPolicy == nil then sGovPolicy = ""; end
	end
	-- find out which polices are slotted now
	local tSlottedPolicies:table = {};
	for i = 0, playerCulture:GetNumPolicySlots()-1 do
		if playerCulture:GetSlotPolicy(i) ~= -1 then tSlottedPolicies[ playerCulture:GetSlotPolicy(i) ] = true; end
	end
	-- iterate through policies that need checking
	for _,sPolicy in ipairs(tPolicies) do
		local policy:table = GameInfo.Policies[sPolicy];
		local bIsActive:boolean = ( playerCulture:IsPolicyUnlocked(policy.Index) and not playerCulture:IsPolicyObsolete(policy.Index) );
		local bIsSlotted:boolean = ( (tSlottedPolicies[ policy.Index ] and true) or false);
		if sPolicy == sGovPolicy then bIsSlotted = true; end
		local sName:string = Locale.Lookup(policy.Name);
		if not bIsActive then sName = "[COLOR:64,64,64,255]"..sName..ENDCOLOR;
		elseif bIsSlotted then sName = "[ICON_Checkmark]"..sName;
		--else sName = "[ICON_CheckFail]"..sName;
		end
		local pPolicyInstance:table = m_kPoliciesIM:GetInstance();
		pPolicyInstance.PolicyName:SetText(sName);
		pPolicyInstance.PolicyName:SetToolTipString( Locale.Lookup(policy.Description) );
	end
end

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
	
	RefreshAdditionalInfo();
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
	-- tabs are created dynamically because of Ibrahim
	m_tabs = CreateTabs( Controls.TabContainer, 42, 34, 0xFF331D05 );
	for index,governor in ipairs(m_kGovernors) do
		-- create a tab
		AddTabSection( governor.IconFill.."  ".. governor.Name, function() ViewGovernorPage( index ); end );
	end
	m_tabs.SameSizedTabs(10);
	m_tabs.CenterAlignTabs(-10);
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
	-- Open Governors window
	Controls.OpenGovernorsButton:RegisterCallback(Mouse.eLClick, function() Close(); LuaEvents.GovernorPanel_Toggle(); end);
	
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