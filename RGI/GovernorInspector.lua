print("Loading GovernorInspector.lua from Real Governor Inspector version "..(GlobalParameters.RGI_VERSION_MAJOR and GlobalParameters.RGI_VERSION_MAJOR or "0").."."..(GlobalParameters.RGI_VERSION_MINOR and GlobalParameters.RGI_VERSION_MINOR or "0"));
-- ===========================================================================
--	Real Governor Inspector
--	Author: Infixo
--  2020-06-03: Created
-- ===========================================================================
include("InstanceManager");
include("SupportFunctions"); -- TruncateString
include("TabSupport");
include("Civ6Common");

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

-- debug routine - prints a table, and tables inside recursively (up to 5 levels)
function dshowrectable(tTable:table, iLevel:number)
	local level:number = 0;
	if iLevel ~= nil then level = iLevel; end
	for k,v in pairs(tTable) do
		print(string.rep("---:",level), k, type(v), tostring(v));
		if type(v) == "table" and level < 5 then dshowrectable(v, level+1); end
	end
end


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

-- check if 'value' exists in table 'pTable'; should work for any type of 'value' and table indices
function IsInTable(pTable:table, value)
	for _,data in pairs(pTable) do
		if data == value then return true; end
	end
	return false;
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

-- Rayna adjacencies
local eRaynaDistricts:table = {};
table.insert(eRaynaDistricts, GameInfo.Districts.DISTRICT_COMMERCIAL_HUB.Index);
table.insert(eRaynaDistricts, GameInfo.Districts.DISTRICT_HARBOR.Index);
table.insert(eRaynaDistricts, GameInfo.Districts.DISTRICT_ROYAL_NAVY_DOCKYARD.Index);
table.insert(eRaynaDistricts, GameInfo.Districts.DISTRICT_COTHON.Index);
table.insert(eRaynaDistricts, GameInfo.Districts.DISTRICT_SUGUBA.Index);

-- Rayna power & gold
local eRaynaImpr:table = {};
table.insert(eRaynaImpr, GameInfo.Improvements.IMPROVEMENT_OFFSHORE_WIND_FARM.Index);
table.insert(eRaynaImpr, GameInfo.Improvements.IMPROVEMENT_SOLAR_FARM.Index);
table.insert(eRaynaImpr, GameInfo.Improvements.IMPROVEMENT_WIND_FARM.Index);
table.insert(eRaynaImpr, GameInfo.Improvements.IMPROVEMENT_GEOTHERMAL_PLANT.Index);
local eRaynaDam:number = GameInfo.Buildings.BUILDING_HYDROELECTRIC_DAM.Index;


-- main function for calculating effects of governors in a specific city
function ProcessCity( pCity:table )
	print("FUN ProcessCity", pCity:GetName());
	
	local localPlayerID:number = Game.GetLocalPlayer();
	if localPlayerID == nil then return end;
	
	-- generic city data - I try to use the same names as in CitySupport.lua
	local data:table = {
		City         = pCity,
		GovernorIcon = "",
		GovernorTT   = "",
		CityName     = LL(pCity:GetName()),
		Population   = pCity:GetPopulation(),
		PromoEffects = {}, -- table of effects, key is PromotionType
		-- working data
		PlotIndex    = Map.GetPlotIndex(pCity:GetX(),pCity:GetY()),
		RoutesPassing = 0,
		RaynaAdjacency = 0, -- Comms and Harbors
		RaynaPower = 0, -- num of eligible power sources
		RaynaTiles = 0, -- num of unimproved tiles
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
		local eImprovement:number = plot:GetImprovementType();
		local eFeature:number = plot:GetFeatureType();
		local eDistrict:number = plot:GetDistrictType();

		-- Rayna power
		if IsInTable(eRaynaImpr, eImprovement) then data.RaynaPower = data.RaynaPower + 1; end
		-- Rayna unimproved feature tiles
		if eFeature ~= -1 and eImprovement == -1 and eDistrict == -1 then data.RaynaTiles = data.RaynaTiles + 1; end
	end

	-- more city data
	
	-- Rayna and FOREIGN routes passing through (which also includes the destination!)
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
	
	-- Rayna double adjacency bonuses
	print("..double adjacency");
	for _,district in pCity:GetDistricts():Members() do
		if IsInTable(eRaynaDistricts, district:GetType()) then
			data.RaynaAdjacency = data.RaynaAdjacency + district:GetYield(GameInfo.Yields.YIELD_GOLD.Index);
		end
	end
	
	-- Rayna power
	if pCity:GetBuildings():HasBuilding( eRaynaDam ) and not pCity:GetBuildings():IsPillaged( eRaynaDam ) then
		 data.RaynaPower = data.RaynaPower + 1;
	end
	
	
	-- get generic data
	-- loop through all promotions, filtering out which are valid will happen later
	
	for _,governor in ipairs(m_kGovernors) do
		for _,promotion in ipairs(governor.Promotions) do
			local effects:table = {
				Yields = ".",
				Effect = "",
			};
			--=========
			-- MAIN ENGINE
			--=========
			
			
			-- RAYNA
			if     promotion.PromotionType == "GOVERNOR_PROMOTION_MERCHANT_LAND_ACQUISITION" then -- +3 gold for each foreig route passing through
				effects.Yields = GetYieldString("YIELD_GOLD", data.RoutesPassing*2);
				effects.Effect = tostring(data.RoutesPassing);
			elseif promotion.PromotionType == "GOVERNOR_PROMOTION_MERCHANT_HARBORMASTER" then -- double adjacency
				effects.Yields = GetYieldString("YIELD_GOLD", data.RaynaAdjacency); -- the gain is one extra adjacency
			elseif promotion.PromotionType == "GOVERNOR_PROMOTION_MERCHANT_FORESTRY_MANAGEMENT" then -- gold from unimproved feature tiles
				effects.Yields = GetYieldString("YIELD_GOLD", data.RaynaTiles*2);
				effects.Effect = tostring(data.RaynaTiles);
			elseif promotion.PromotionType == "GOVERNOR_PROMOTION_MERCHANT_RENEWABLE_ENERGY" then
				effects.Yields = GetYieldString("YIELD_GOLD", data.RaynaPower*2).." [ICON_Power]"..toPlusMinusString(data.RaynaPower*2);
				effects.Effect = tostring(data.RaynaPower);
			--GOVERNOR_PROMOTION_MERCHANT_CONTRACTOR
			elseif promotion.PromotionType == "GOVERNOR_PROMOTION_MERCHANT_TAX_COLLECTOR" then --  - +2 gold per Pop
				effects.Yields = GetYieldString("YIELD_GOLD", data.Population*2);
			end
			
			
			data.PromoEffects[ promotion.PromotionType ] = effects;
		end -- promotions
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
--.ID	310
--.Type	-77408354  => Hash for GameInfo.Moments[]
--.InstanceDescription	The discovery of Apprenticeship by Korea sets the world stage for future discoveries in the Medieval Era!
--.ActingPlayer	0
--.EraScore	2
--.GameEra	1
--.Turn	101
--.HasEverBeenCommemorated	false => seems to be false always
--.ActionPlotX	-9999
--.ActionPlotY	-9999
--.ExtraData	table: 000000006221F3C0 => (ipairs) table of { .DataType and .DataValue }
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
	
	-- fill out effects with dynamic data
	for _,promo in ipairs(m_kGovernors[m_kCurrentTab].Promotions) do
		local pPromoEffectInstance:table = {};
		ContextPtr:BuildInstanceForControl( "PromoEffectInstance", pPromoEffectInstance, pInstance.PromoEffects );
		--dshowrectable(pCity);
		local promoEffects:table = pCity.PromoEffects[ promo.PromotionType ];
		pPromoEffectInstance.Yields:SetText( promoEffects.Yields );
		pPromoEffectInstance.Effect:SetText( promoEffects.Effect );
		--local isTruncated:boolean = TruncateString(pPromoEffectInstance.PromoName, 110, promo.Name);
		--if isTruncated then pPromoEffectInstance.PromoName:SetToolTipString( promo.Name..NEWLINE..promo.Description );
		--else                pPromoEffectInstance.PromoName:SetToolTipString( promo.Description ); end
	end

	--[[
	-- favored
	pInstance.Favored:SetSelected( pMoment.Favored );
	pInstance.Favored:RegisterCallback( Mouse.eLClick, function() pMoment.Favored = not pMoment.Favored; ViewGovernorPage(); end );
	-- category, era score
	if     pMoment.Category == 1 then pInstance.Group:SetText("[ICON_CapitalLarge]"); pInstance.Group:SetOffsetY(10);
	elseif pMoment.Category == 2 then pInstance.Group:SetText("[ICON_Capital]");      pInstance.Group:SetOffsetY(7);
	else                              pInstance.Group:SetText("[ICON_Army]");         pInstance.Group:SetOffsetY(8); end
	-- score
	local iScore:number = pMoment.EraScore;
	if m_bIsTajMahal and iScore >= 2 then iScore = iScore + 1; end
	pInstance.EraScore:SetText("[COLOR_White]"..tostring(iScore)..ENDCOLOR);
	-- description
	local isTruncated:boolean = TruncateString(pInstance.Description, 305, pMoment.Description);
	if isTruncated then pInstance.Description:SetToolTipString( pMoment.Description..NEWLINE..pMoment.LongDesc );
	else                pInstance.Description:SetToolTipString( pMoment.LongDesc ); end
	-- object & valid for
	isTruncated = TruncateString(pInstance.Object, 155, pMoment.Object);
	local sStatusTT:string = "";
	if isTruncated then sStatusTT = pMoment.Object; end
	if pMoment.ValidFor ~= "" then
		if sStatusTT ~= "" then sStatusTT = sStatusTT..NEWLINE; end
		if     GameInfo.Civilizations[pMoment.ValidFor] ~= nil then sStatusTT = sStatusTT..LL(GameInfo.Civilizations[pMoment.ValidFor].Name);
		elseif GameInfo.Leaders[pMoment.ValidFor]       ~= nil then sStatusTT = sStatusTT..LL(GameInfo.Leaders[pMoment.ValidFor].Name);
		else                                                        sStatusTT = sStatusTT..pMoment.ValidFor; end
	end
	pInstance.Object:SetToolTipString(sStatusTT);
	-- status and tooltips
	if     pMoment.Status == 0 then pInstance.Status:SetText("[ICON_Bullet]");        pInstance.Status:SetOffsetY(0);
	elseif pMoment.Status == 1 then pInstance.Status:SetText("[ICON_CheckmarkBlue]"); pInstance.Status:SetOffsetY(0);
	else                            pInstance.Status:SetText("[ICON_Not]");           pInstance.Status:SetOffsetY(4); end
	pInstance.Status:SetToolTipString("");
	if #pMoment.TT > 0 then pInstance.Status:SetToolTipString(table.concat(pMoment.TT, NEWLINE)); end
	-- turn, count, player
	pInstance.Turn:SetText(tostring(pMoment.Turn));
	pInstance.Count:SetText(tostring(pMoment.Count));
	pInstance.Player:SetText(pMoment.Player);
	-- era info
	pInstance.Eras:SetText("");
	if pMoment.MinEra ~= nil or pMoment.MaxEra ~= nil then
		pInstance.Eras:SetText("[ICON_Turn]");
		local sEras:string = " [ICON_GoingTo] ";
		if pMoment.MinEra ~= nil then sEras = LL(GameInfo.Eras[pMoment.MinEra].Name)..sEras; end
		if pMoment.MaxEra ~= nil then sEras = sEras..LL(GameInfo.Eras[pMoment.MaxEra].Name); end
		pInstance.Eras:SetToolTipString(sEras);
	end
	-- debug extra tooltip
	pInstance.Extra:SetText("---");
	local tTT:table = {};
	for k,v in pairs(pMoment) do
		table.insert(tTT, tostring(k)..": "..tostring(v));
	end
	-- ExtraData (ipairs) table of { .DataType and .DataValue }
	for i,extra in ipairs(pMoment.ExtraData) do
		if GameInfo.Types[extra.DataType] == nil then
			table.insert(tTT, string.format("[%d] %s", i, tostring(extra.DataType)));
		else
			table.insert(tTT, string.format("[%d] %s", i, GameInfo.Types[extra.DataType].Type));
		end
		table.insert(tTT, string.format("[%d] %s", i, tostring(extra.DataValue)));
	end
	pInstance.Extra:SetToolTipString(table.concat(tTT, NEWLINE));
	--]]
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
		local isTruncated:boolean = TruncateString(pPromoNameInstance.PromoName, 110, promo.Name);
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
	
	--[[
	local iCurrentEra:number = Game.GetEras():GetCurrentEra();
	local tSaveData:table = {}; -- save current favored moments
	for key,moment in pairs(m_kMoments) do
		--print("...filtering key", key);
		-- filters
		local bShow:boolean = true;
		-- harcoded
		if moment.EraScore == nil or moment.EraScore == 0 then bShow = false; end
		if moment.ValidFor ~= nil and moment.ValidFor ~= "" then
			if not( moment.ValidFor == sCivilization or moment.ValidFor == sLeader ) then bShow = false; end
		end
		--if eGroup == 0 then
			--if not moment.Favored then bShow = false; end
		--else
			--if moment.Category ~= eGroup then bShow = false; end
		--end
		
		if not moment.Favored then -- favored are ALWAYS shown
		
			-- checkboxes
			if moment.EraScore == 1 and not bEraScore1 then bShow = false; end
			if moment.EraScore == 2 and not bEraScore2 then bShow = false; end
			if moment.EraScore == 3 and not bEraScore3 then bShow = false; end
			if moment.EraScore >= 4 and not bEraScore4 then bShow = false; end
			if bHideNotActive  and moment.Status ~= 0 then bShow = false; end
			if bShowOnlyEarned and moment.Status ~= 1 then bShow = false; end
			-- available & eras
			local iMinEra:number, iMaxEra:number = 0, m_iMaxEraIndex;
			if moment.MinEra ~= nil then iMinEra = GameInfo.Eras[moment.MinEra].Index; end
			if moment.MaxEra ~= nil then iMaxEra = GameInfo.Eras[moment.MaxEra].Index; end
			if bHideNotAvailable and (iCurrentEra < iMinEra or iCurrentEra > iMaxEra) then bShow = false; end
		
		end -- not favored
		
		if bShow then table.insert(tShow, city); end
		if moment.Favored then table.insert(tSaveData, key); end
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


-- ===========================================================================
function Initialize()
	-- UI Callbacks
	ContextPtr:SetInitHandler( OnInit );
	ContextPtr:SetInputHandler( OnInputHandler, true );
	Controls.CloseButton:RegisterCallback( Mouse.eLClick, OnCloseButton );
	Controls.CloseButton:RegisterCallback(	Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	-- Filters
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
	-- Events
	LuaEvents.ReportsList_OpenGovernorInspector.Add( function() Open(); end );
	Events.LocalPlayerTurnEnd.Add( OnLocalPlayerTurnEnd );
	-- loading persistent data
	Events.LoadComplete.Add( OnLoadComplete ); -- fires ONLY when loading a game from a save file, when it's ready to start (i.e. circle button appears)
end
Initialize();

print("OK loaded GovernorInspector.lua from Real Governor Inspector");