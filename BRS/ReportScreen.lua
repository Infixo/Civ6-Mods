print("Loading ReportScreen.lua from Better Report Screen");
-- ===========================================================================
--	ReportScreen
--	All the data
--
-- ===========================================================================
include("CitySupport");
include("Civ6Common");
include("InstanceManager");
include("SupportFunctions");
include("TabSupport");

-- exposing functions and variables
if not ExposedMembers.RMA then ExposedMembers.RMA = {} end;
local RMA = ExposedMembers.RMA;

-- ===========================================================================
-- Rise & Fall check
-- ===========================================================================

local bIsRiseFall:boolean = (Game.GetEmergencyManager ~= nil) -- this is for UI scripts; for GamePlay use Game.ChangePlayerEraScore


-- ===========================================================================
--	DEBUG
--	Toggle these for temporary debugging help.
-- ===========================================================================
local m_debugFullHeight				:boolean = true;		-- (false) if the screen area should resize to full height of the available space.
local m_debugNumResourcesStrategic	:number = 0;			-- (0) number of extra strategics to show for screen testing.
local m_debugNumBonuses				:number = 0;			-- (0) number of extra bonuses to show for screen testing.
local m_debugNumResourcesLuxuries	:number = 0;			-- (0) number of extra luxuries to show for screen testing.


-- ===========================================================================
--	CONSTANTS
-- ===========================================================================
local DARKEN_CITY_INCOME_AREA_ADDITIONAL_Y		:number = 6;
local DATA_FIELD_SELECTION						:string = "Selection";
local SIZE_HEIGHT_BOTTOM_YIELDS					:number = 135;
local SIZE_HEIGHT_PADDING_BOTTOM_ADJUST			:number = 85;	-- (Total Y - (scroll area + THIS PADDING)) = bottom area
local INDENT_STRING								:string = "      ";

-- Mapping of unit type to cost.
--[[ Infixo not used
local UnitCostMap:table = {};
do
	for row in GameInfo.Units() do
		UnitCostMap[row.UnitType] = row.Maintenance;
	end
end
--]]
--BRS !! Added function to sort out tables for units
local bUnits = { group = {}, parent = {}, type = "" }

function spairs( t, order )
		local keys = {}

		for k in pairs(t) do keys[#keys+1] = k end
		
		if order then
			table.sort(keys, function(a,b) return order(t, a, b) end)
		else
			table.sort(keys)
		end

		local i = 0
		return function()
			i = i + 1
			if keys[i] then
				return keys[i], t[keys[i]]
			end
		end
	end
-- !! end of function

-- ===========================================================================
--	VARIABLES
-- ===========================================================================

m_simpleIM = InstanceManager:new("SimpleInstance",			"Top",		Controls.Stack);				-- Non-Collapsable, simple
m_tabIM = InstanceManager:new("TabInstance",				"Button",	Controls.TabContainer);
local m_groupIM				:table = InstanceManager:new("GroupInstance",			"Top",		Controls.Stack);				-- Collapsable
local m_bonusResourcesIM	:table = InstanceManager:new("ResourceAmountInstance",	"Info",		Controls.BonusResources);
local m_luxuryResourcesIM	:table = InstanceManager:new("ResourceAmountInstance",	"Info",		Controls.LuxuryResources);
local m_strategicResourcesIM:table = InstanceManager:new("ResourceAmountInstance",	"Info",		Controls.StrategicResources);


m_kCityData = nil;
m_tabs = nil;
local m_kCityTotalData		:table = nil;
local m_kUnitData			:table = nil;	-- TODO: Show units by promotion class
local m_kResourceData		:table = nil;
local m_kDealData			:table = nil;
local m_uiGroups			:table = nil;	-- Track the groups on-screen for collapse all action.

local m_isCollapsing		:boolean = true;
--BRS !! new variables
local m_kCurrentDeals	:table = nil;
local m_kUnitDataReport	:table = nil;
local m_kPolicyData		:table = nil;
-- !!
-- Remember last tab variable: ARISTOS
m_kCurrentTab = 1;
-- !!

-- ===========================================================================
-- Time helpers
-- ===========================================================================
local fStartTime1:number = 0.0
local fStartTime2:number = 0.0
function Timer1Start()
	fStartTime1 = Automation.GetTime()
	--print("Timer1 Start", fStartTime1)
end
function Timer2Start()
	fStartTime2 = Automation.GetTime()
	--print("Timer2 Start() (start)", fStartTime2)
end
function Timer1Tick(txt:string)
	print("Timer1 Tick", txt, string.format("%5.3f", Automation.GetTime()-fStartTime1))
end
function Timer2Tick(txt:string)
	print("Timer2 Tick", txt, string.format("%5.3f", Automation.GetTime()-fStartTime2))
end

-- ===========================================================================
--	Single exit point for display
-- ===========================================================================
function Close()
	if not ContextPtr:IsHidden() then
		UI.PlaySound("UI_Screen_Close");
	end

	UIManager:DequeuePopup(ContextPtr);
	--print("Closing... current tab is:", m_kCurrentTab);
end


-- ===========================================================================
--	UI Callback
-- ===========================================================================
function OnCloseButton()
	Close();
end

-- ===========================================================================
--	Single entry point for display
-- ===========================================================================
function Open()
	UIManager:QueuePopup( ContextPtr, PopupPriority.Normal );
	Controls.ScreenAnimIn:SetToBeginning();
	Controls.ScreenAnimIn:Play();
	UI.PlaySound("UI_Screen_Open");

	-- BRS !! new line to add new variables 
	-- m_kCityData, m_kCityTotalData, m_kResourceData, m_kUnitData, m_kDealData = GetData();
	Timer2Start()
	m_kCityData, m_kCityTotalData, m_kResourceData, m_kUnitData, m_kDealData, m_kCurrentDeals, m_kUnitDataReport = GetData();
	UpdatePolicyData();
	Timer2Tick("GetData")
	
	-- To remember the last opened tab when the report is re-opened: ARISTOS
	--m_tabs.SelectTab( 1 );
	m_tabs.SelectTab( m_kCurrentTab );
end

-- ===========================================================================
--	LUA Events
--	Opened via the top panel
-- ===========================================================================
function OnTopOpenReportsScreen()
	Open();
end

-- ===========================================================================
--	LUA Events
--	Closed via the top panel
-- ===========================================================================
function OnTopCloseReportsScreen()
	Close();	
end

-- ===========================================================================
--	UI Callback
--	Collapse all the things!
-- ===========================================================================
function OnCollapseAllButton()
	if m_uiGroups == nil or table.count(m_uiGroups) == 0 then
		return;
	end

	for i,instance in ipairs( m_uiGroups ) do
		if instance["isCollapsed"] ~= m_isCollapsing then
			instance["isCollapsed"] = m_isCollapsing;
			instance.CollapseAnim:Reverse();
			RealizeGroup( instance );
		end
	end
	Controls.CollapseAll:LocalizeAndSetText(m_isCollapsing and "LOC_HUD_REPORTS_EXPAND_ALL" or "LOC_HUD_REPORTS_COLLAPSE_ALL");
	m_isCollapsing = not m_isCollapsing;
end

-- ===========================================================================
--	Populate with all data required for any/all report tabs.
-- ===========================================================================
function GetData()
	local kResources	:table = {};
	local kCityData		:table = {};
	local kCityTotalData:table = {
		Income	= {},
		Expenses= {},
		Net		= {},
		Treasury= {}
	};
	local kUnitData		:table = {};


	kCityTotalData.Income[YieldTypes.CULTURE]	= 0;
	kCityTotalData.Income[YieldTypes.FAITH]		= 0;
	kCityTotalData.Income[YieldTypes.FOOD]		= 0;
	kCityTotalData.Income[YieldTypes.GOLD]		= 0;
	kCityTotalData.Income[YieldTypes.PRODUCTION]= 0;
	kCityTotalData.Income[YieldTypes.SCIENCE]	= 0;
	kCityTotalData.Income["TOURISM"]			= 0;
	kCityTotalData.Expenses[YieldTypes.GOLD]	= 0;
	
	local playerID	:number = Game.GetLocalPlayer();
	if playerID == PlayerTypes.NONE then
		UI.DataError("Unable to get valid playerID for report screen.");
		return;
	end

	local player	:table  = Players[playerID];
	local pCulture	:table	= player:GetCulture();
	local pTreasury	:table	= player:GetTreasury();
	local pReligion	:table	= player:GetReligion();
	local pScience	:table	= player:GetTechs();
	local pResources:table	= player:GetResources();		

	-- ==========================
	-- BRS !! this will use the m_kUnitDataReport to fill out player's unit info
	-- ==========================
	local kUnitDataReport:table = {};
	local group_name:string;

	for _, unit in player:GetUnits():Members() do
		local unitInfo : table = GameInfo.Units[unit:GetUnitType()];
		local formationClass:string = unitInfo.FormationClass; -- FORMATION_CLASS_CIVILIAN, FORMATION_CLASS_LAND_COMBAT, FORMATION_CLASS_NAVAL, FORMATION_CLASS_SUPPORT, FORMATION_CLASS_AIR
		-- categorize
		group_name = string.gsub(formationClass, "FORMATION_CLASS_", "");
		if formationClass == "FORMATION_CLASS_CIVILIAN" then
			-- need to split into sub-classes
			if unit:GetGreatPerson():IsGreatPerson() then group_name = "GREAT_PERSON";
			elseif unitInfo.MakeTradeRoute then           group_name = "TRADER";
			elseif unitInfo.Spy then                      group_name = "SPY";
			elseif unit:GetReligiousStrength() > 0 then group_name = "RELIGIOUS";
			end
		end
		-- store for Units tab report
		if kUnitDataReport[group_name] == nil then
			if     group_name == "LAND_COMBAT" then  kUnitDataReport[group_name] = { ID= 1, func= group_military, Header= "UnitsMilitaryHeaderInstance",   Entry= "UnitsMilitaryEntryInstance" };
			elseif group_name == "NAVAL" then        kUnitDataReport[group_name] = { ID= 2, func= group_military, Header= "UnitsMilitaryHeaderInstance",   Entry= "UnitsMilitaryEntryInstance" };
			elseif group_name == "AIR" then          kUnitDataReport[group_name] = { ID= 3, func= group_military, Header= "UnitsMilitaryHeaderInstance",   Entry= "UnitsMilitaryEntryInstance" };
			elseif group_name == "SUPPORT" then      kUnitDataReport[group_name] = { ID= 4, func= group_civilian, Header= "UnitsCivilianHeaderInstance",   Entry= "UnitsCivilianEntryInstance" };
			elseif group_name == "CIVILIAN" then     kUnitDataReport[group_name] = { ID= 5, func= group_civilian, Header= "UnitsCivilianHeaderInstance",   Entry= "UnitsCivilianEntryInstance" };
			elseif group_name == "RELIGIOUS" then    kUnitDataReport[group_name] = { ID= 6, func= group_religious,Header= "UnitsReligiousHeaderInstance",  Entry= "UnitsReligiousEntryInstance" };
			elseif group_name == "GREAT_PERSON" then kUnitDataReport[group_name] = { ID= 7, func= group_great,    Header= "UnitsGreatPeopleHeaderInstance",Entry= "UnitsGreatPeopleEntryInstance" };
			elseif group_name == "SPY" then          kUnitDataReport[group_name] = { ID= 8, func= group_spy,      Header= "UnitsSpyHeaderInstance",        Entry= "UnitsSpyEntryInstance" };
			elseif group_name == "TRADER" then       kUnitDataReport[group_name] = { ID= 9, func= group_trader,   Header= "UnitsTraderHeaderInstance",     Entry= "UnitsTraderEntryInstance" };
			end
			kUnitDataReport[group_name].Name = "LOC_BRS_UNITS_GROUP_"..group_name;
			kUnitDataReport[group_name].units = {};
		end
		table.insert( kUnitDataReport[group_name].units, unit );
	end
	-- ==========================
	-- !! end of edit
	-- ==========================		

	local pCities = player:GetCities();
	for i, pCity in pCities:Members() do	
		local cityName	:string = pCity:GetName();
			
		-- Big calls, obtain city data and add report specific fields to it.
		local data		:table	= GetCityData( pCity );
		data.Resources			= GetCityResourceData( pCity );					-- Add more data (not in CitySupport)			
		data.WorkedTileYields, data.NumWorkedTiles = GetWorkedTileYieldData( pCity, pCulture );	-- Add more data (not in CitySupport)

		-- Add to totals.
		kCityTotalData.Income[YieldTypes.CULTURE]	= kCityTotalData.Income[YieldTypes.CULTURE] + data.CulturePerTurn;
		kCityTotalData.Income[YieldTypes.FAITH]		= kCityTotalData.Income[YieldTypes.FAITH] + data.FaithPerTurn;
		kCityTotalData.Income[YieldTypes.FOOD]		= kCityTotalData.Income[YieldTypes.FOOD] + data.FoodPerTurn;
		kCityTotalData.Income[YieldTypes.GOLD]		= kCityTotalData.Income[YieldTypes.GOLD] + data.GoldPerTurn;
		kCityTotalData.Income[YieldTypes.PRODUCTION]= kCityTotalData.Income[YieldTypes.PRODUCTION] + data.ProductionPerTurn;
		kCityTotalData.Income[YieldTypes.SCIENCE]	= kCityTotalData.Income[YieldTypes.SCIENCE] + data.SciencePerTurn;
		kCityTotalData.Income["TOURISM"]			= kCityTotalData.Income["TOURISM"] + data.WorkedTileYields["TOURISM"];
			
		kCityData[cityName] = data;

		-- Add outgoing route data
		data.OutgoingRoutes = pCity:GetTrade():GetOutgoingRoutes();

		-- Add resources
		if m_debugNumResourcesStrategic > 0 or m_debugNumResourcesLuxuries > 0 or m_debugNumBonuses > 0 then
			for debugRes=1,m_debugNumResourcesStrategic,1 do
				kResources[debugRes] = {
					CityList	= { CityName="Kangaroo", Amount=(10+debugRes) },
					Icon		= "[ICON_"..GameInfo.Resources[debugRes].ResourceType.."]",
					IsStrategic	= true,
					IsLuxury	= false,
					IsBonus		= false,
					Total		= 88
				};
			end
			for debugRes=1,m_debugNumResourcesLuxuries,1 do
				kResources[debugRes] = {
					CityList	= { CityName="Kangaroo", Amount=(10+debugRes) },
					Icon		= "[ICON_"..GameInfo.Resources[debugRes].ResourceType.."]",
					IsStrategic	= false,
					IsLuxury	= true,
					IsBonus		= false,
					Total		= 88
				};
			end
			for debugRes=1,m_debugNumBonuses,1 do
				kResources[debugRes] = {
					CityList	= { CityName="Kangaroo", Amount=(10+debugRes) },
					Icon		= "[ICON_"..GameInfo.Resources[debugRes].ResourceType.."]",
					IsStrategic	= false,
					IsLuxury	= false,
					IsBonus		= true,
					Total		= 88
				};
			end
		end

		for eResourceType,amount in pairs(data.Resources) do
			AddResourceData(kResources, eResourceType, cityName, "LOC_HUD_REPORTS_TRADE_OWNED", amount);
		end
		
		-- ADDITIONAL DATA
		
		-- Garrison in a city
		data.IsGarrisonUnit = false;
		local pPlotCity:table = Map.GetPlot( pCity:GetX(), pCity:GetY() );
		for _,unit in ipairs(Units.GetUnitsInPlot(pPlotCity)) do
			if GameInfo.Units[ unit:GetUnitType() ].FormationClass == "FORMATION_CLASS_LAND_COMBAT" then data.IsGarrisonUnit = true; break; end
		end
		
	end

	kCityTotalData.Expenses[YieldTypes.GOLD] = pTreasury:GetTotalMaintenance();

	-- NET = Income - Expense
	kCityTotalData.Net[YieldTypes.GOLD]			= kCityTotalData.Income[YieldTypes.GOLD] - kCityTotalData.Expenses[YieldTypes.GOLD];
	kCityTotalData.Net[YieldTypes.FAITH]		= kCityTotalData.Income[YieldTypes.FAITH];

	-- Treasury
	kCityTotalData.Treasury[YieldTypes.CULTURE]		= Round( pCulture:GetCultureYield(), 0 );
	kCityTotalData.Treasury[YieldTypes.FAITH]		= Round( pReligion:GetFaithBalance(), 0 );
	kCityTotalData.Treasury[YieldTypes.GOLD]		= Round( pTreasury:GetGoldBalance(), 0 );
	kCityTotalData.Treasury[YieldTypes.SCIENCE]		= Round( pScience:GetScienceYield(), 0 );
	kCityTotalData.Treasury["TOURISM"]				= Round( kCityTotalData.Income["TOURISM"], 0 );


	-- Units (TODO: Group units by promotion class and determine total maintenance cost)
	local MaintenanceDiscountPerUnit:number = pTreasury:GetMaintDiscountPerUnit();
	local pUnits :table = player:GetUnits();
	for i, pUnit in pUnits:Members() do
		local pUnitInfo:table = GameInfo.Units[pUnit:GetUnitType()];
		-- get localized unit name with appropriate suffix
		local unitName :string = Locale.Lookup(pUnitInfo.Name);
		local unitMilitaryFormation = pUnit:GetMilitaryFormation();
		if (unitMilitaryFormation == MilitaryFormationTypes.CORPS_FORMATION) then
			--unitName = unitName.." "..Locale.Lookup( (pUnitInfo.Domain == "DOMAIN_SEA" and "LOC_HUD_UNIT_PANEL_FLEET_SUFFIX") or "LOC_HUD_UNIT_PANEL_CORPS_SUFFIX");
			--unitName = unitName.." [ICON_Corps]";
		elseif (unitMilitaryFormation == MilitaryFormationTypes.ARMY_FORMATION) then
			--unitName = unitName.." "..Locale.Lookup( (pUnitInfo.Domain == "DOMAIN_SEA" and "LOC_HUD_UNIT_PANEL_ARMADA_SUFFIX") or "LOC_HUD_UNIT_PANEL_ARMY_SUFFIX");
			--unitName = unitName.." [ICON_Army]";
		else
			--BRS Civilian units can be NO_FORMATION (-1) or STANDARD (0)
			unitMilitaryFormation = MilitaryFormationTypes.STANDARD_FORMATION; -- 0
		end
		-- calculate unit maintenance with discount if active
		local TotalMaintenanceAfterDiscount:number = math.max(GetUnitMaintenance(pUnit) - MaintenanceDiscountPerUnit, 0); -- cannot go below 0
		local unitTypeKey = pUnitInfo.UnitType..unitMilitaryFormation;
		if kUnitData[unitTypeKey] == nil then
			kUnitData[unitTypeKey] = { Name = Locale.Lookup(pUnitInfo.Name), Formation = unitMilitaryFormation, Count = 1, Maintenance = TotalMaintenanceAfterDiscount };
		else
			kUnitData[unitTypeKey].Count = kUnitData[unitTypeKey].Count + 1;
			kUnitData[unitTypeKey].Maintenance = kUnitData[unitTypeKey].Maintenance + TotalMaintenanceAfterDiscount;
		end
	end

	-- =================================================================
	-- BRS Current Deals Info (didn't wanna mess with diplomatic deal data
	-- below, maybe later
	-- =================================================================
	local kCurrentDeals : table = {}
	local kPlayers : table = PlayerManager.GetAliveMajors()
	local iTotal = 0

	for _, pOtherPlayer in ipairs( kPlayers ) do
		local otherID:number = pOtherPlayer:GetID()
		if  otherID ~= playerID then
			
			local pPlayerConfig	:table = PlayerConfigurations[otherID]
			local pDeals		:table = DealManager.GetPlayerDeals( playerID, otherID )
			
			if pDeals ~= nil then

				for i, pDeal in ipairs( pDeals ) do
					iTotal = iTotal + 1

					local Receiving : table = { Agreements = {}, Gold = {}, Resources = {} }
					local Sending : table = { Agreements = {}, Gold = {}, Resources = {} }

					Receiving.Resources = pDeal:FindItemsByType( DealItemTypes.RESOURCES, DealItemSubTypes.NONE, otherID )
					Receiving.Gold = pDeal:FindItemsByType( DealItemTypes.GOLD, DealItemSubTypes.NONE, otherID )
					Receiving.Agreements = pDeal:FindItemsByType( DealItemTypes.AGREEMENTS, DealItemSubTypes.NONE, otherID )

					Sending.Resources = pDeal:FindItemsByType( DealItemTypes.RESOURCES, DealItemSubTypes.NONE, playerID )
					Sending.Gold = pDeal:FindItemsByType( DealItemTypes.GOLD, DealItemSubTypes.NONE, playerID )
					Sending.Agreements = pDeal:FindItemsByType( DealItemTypes.AGREEMENTS, DealItemSubTypes.NONE, playerID )

					kCurrentDeals[iTotal] =
					{
						WithCivilization = Locale.Lookup( pPlayerConfig:GetCivilizationDescription() ),
						EndTurn = 0,
						Receiving = {},
						Sending = {}
					}

					local iDeal = 0

					for pReceivingName, pReceivingGroup in pairs( Receiving ) do
						for _, pDealItem in ipairs( pReceivingGroup ) do

							iDeal = iDeal + 1

							kCurrentDeals[iTotal].EndTurn = pDealItem:GetEndTurn()
							kCurrentDeals[iTotal].Receiving[iDeal] = { Amount = pDealItem:GetAmount() }

							local deal = kCurrentDeals[iTotal].Receiving[iDeal]

							if pReceivingName == "Agreements" then
								deal.Name = pDealItem:GetSubTypeNameID()
							elseif pReceivingName == "Gold" then
								deal.Name = deal.Amount .. " Gold Per Turn"
								deal.Icon = "[ICON_GOLD]"
							else
								if deal.Amount > 1 then
									deal.Name = pDealItem:GetValueTypeNameID() .. "(" .. deal.Amount .. ")"
								else
									deal.Name = pDealItem:GetValueTypeNameID()
								end
								deal.Icon = "[ICON_" .. pDealItem:GetValueTypeID() .. "]"
							end

							deal.Name = Locale.Lookup( deal.Name )
						end
					end

					iDeal = 0

					for pSendingName, pSendingGroup in pairs( Sending ) do
						for _, pDealItem in ipairs( pSendingGroup ) do

							iDeal = iDeal + 1

							kCurrentDeals[iTotal].EndTurn = pDealItem:GetEndTurn()
							kCurrentDeals[iTotal].Sending[iDeal] = { Amount = pDealItem:GetAmount() }
							
							local deal = kCurrentDeals[iTotal].Sending[iDeal]

							if pSendingName == "Agreements" then
								deal.Name = pDealItem:GetSubTypeNameID()
							elseif pSendingName == "Gold" then
								deal.Name = deal.Amount .. " Gold Per Turn"
								deal.Icon = "[ICON_GOLD]"
							else
								if deal.Amount > 1 then
									deal.Name = pDealItem:GetValueTypeNameID() .. "(" .. deal.Amount .. ")"
								else
									deal.Name = pDealItem:GetValueTypeNameID()
								end
								deal.Icon = "[ICON_" .. pDealItem:GetValueTypeID() .. "]"
							end

							deal.Name = Locale.Lookup( deal.Name )
						end
					end
				end
			end
		end
	end

	-- =================================================================
	
	local kDealData	:table = {};
	local kPlayers	:table = PlayerManager.GetAliveMajors();
	for _, pOtherPlayer in ipairs(kPlayers) do
		local otherID:number = pOtherPlayer:GetID();
		local currentGameTurn = Game.GetCurrentGameTurn();
		if  otherID ~= playerID then			
			
			local pPlayerConfig	:table = PlayerConfigurations[otherID];
			local pDeals		:table = DealManager.GetPlayerDeals(playerID, otherID);
			
			if pDeals ~= nil then
				for i,pDeal in ipairs(pDeals) do
					if pDeal:IsValid() then -- BRS
					-- Add outgoing gold deals
					local pOutgoingDeal :table	= pDeal:FindItemsByType(DealItemTypes.GOLD, DealItemSubTypes.NONE, playerID);
					if pOutgoingDeal ~= nil then
						for i,pDealItem in ipairs(pOutgoingDeal) do
							local duration		:number = pDealItem:GetDuration();
							local remainingTurns:number = duration - (currentGameTurn - pDealItem:GetEnactedTurn());
							if duration ~= 0 then
								local gold :number = pDealItem:GetAmount();
								table.insert( kDealData, {
									Type		= DealItemTypes.GOLD,
									Amount		= gold,
									Duration	= remainingTurns, -- Infixo was duration in BRS
									IsOutgoing	= true,
									PlayerID	= otherID,
									Name		= Locale.Lookup( pPlayerConfig:GetCivilizationDescription() )
								});						
							end
						end
					end

					-- Add outgoing resource deals
					pOutgoingDeal = pDeal:FindItemsByType(DealItemTypes.RESOURCES, DealItemSubTypes.NONE, playerID);
					if pOutgoingDeal ~= nil then
						for i,pDealItem in ipairs(pOutgoingDeal) do
							local duration		:number = pDealItem:GetDuration();
							local remainingTurns:number = duration - (currentGameTurn - pDealItem:GetEnactedTurn());
							if duration ~= 0 then
								local amount		:number = pDealItem:GetAmount();
								local resourceType	:number = pDealItem:GetValueType();
								table.insert( kDealData, {
									Type			= DealItemTypes.RESOURCES,
									ResourceType	= resourceType,
									Amount			= amount,
									Duration		= remainingTurns, -- Infixo was duration in BRS
									IsOutgoing		= true,
									PlayerID		= otherID,
									Name			= Locale.Lookup( pPlayerConfig:GetCivilizationDescription() )
								});
								
								local entryString:string = Locale.Lookup("LOC_HUD_REPORTS_ROW_DIPLOMATIC_DEALS") .. " (" .. Locale.Lookup(pPlayerConfig:GetPlayerName()) .. " " .. Locale.Lookup("LOC_REPORTS_NUMBER_OF_TURNS", remainingTurns) .. ")";
								AddResourceData(kResources, resourceType, entryString, "LOC_HUD_REPORTS_TRADE_EXPORTED", -1 * amount);				
							end
						end
					end
					
					-- Add incoming gold deals
					local pIncomingDeal :table = pDeal:FindItemsByType(DealItemTypes.GOLD, DealItemSubTypes.NONE, otherID);
					if pIncomingDeal ~= nil then
						for i,pDealItem in ipairs(pIncomingDeal) do
							local duration		:number = pDealItem:GetDuration();
							local remainingTurns:number = duration - (currentGameTurn - pDealItem:GetEnactedTurn());
							if duration ~= 0 then
								local gold :number = pDealItem:GetAmount()
								table.insert( kDealData, {
									Type		= DealItemTypes.GOLD;
									Amount		= gold,
									Duration	= remainingTurns, -- Infixo was duration in BRS
									IsOutgoing	= false,
									PlayerID	= otherID,
									Name		= Locale.Lookup( pPlayerConfig:GetCivilizationDescription() )
								});						
							end
						end
					end

					-- Add incoming resource deals
					pIncomingDeal = pDeal:FindItemsByType(DealItemTypes.RESOURCES, DealItemSubTypes.NONE, otherID);
					if pIncomingDeal ~= nil then
						for i,pDealItem in ipairs(pIncomingDeal) do
							local duration		:number = pDealItem:GetDuration();
							if duration ~= 0 then
								local amount		:number = pDealItem:GetAmount();
								local resourceType	:number = pDealItem:GetValueType();
								local remainingTurns:number = duration - (currentGameTurn - pDealItem:GetEnactedTurn());
								table.insert( kDealData, {
									Type			= DealItemTypes.RESOURCES,
									ResourceType	= resourceType,
									Amount			= amount,
									Duration		= remainingTurns, -- Infixo was duration in BRS
									IsOutgoing		= false,
									PlayerID		= otherID,
									Name			= Locale.Lookup( pPlayerConfig:GetCivilizationDescription() )
								});
								
								local entryString:string = Locale.Lookup("LOC_HUD_REPORTS_ROW_DIPLOMATIC_DEALS") .. " (" .. Locale.Lookup(pPlayerConfig:GetPlayerName()) .. " " .. Locale.Lookup("LOC_REPORTS_NUMBER_OF_TURNS", remainingTurns) .. ")";
								AddResourceData(kResources, resourceType, entryString, "LOC_HUD_REPORTS_TRADE_IMPORTED", amount);				
							end
						end
					end	
					end	-- BRS end
				end							
			end

		end
	end

	-- Add resources provided by city states
	for i, pMinorPlayer in ipairs(PlayerManager.GetAliveMinors()) do
		local pMinorPlayerInfluence:table = pMinorPlayer:GetInfluence();		
		if pMinorPlayerInfluence ~= nil then
			local suzerainID:number = pMinorPlayerInfluence:GetSuzerain();
			if suzerainID == playerID then
				for row in GameInfo.Resources() do
					local resourceAmount:number =  pMinorPlayer:GetResources():GetExportedResourceAmount(row.Index);
					if resourceAmount > 0 then
						local pMinorPlayerConfig:table = PlayerConfigurations[pMinorPlayer:GetID()];
						local entryString:string = Locale.Lookup("LOC_HUD_REPORTS_CITY_STATE") .. " (" .. Locale.Lookup(pMinorPlayerConfig:GetPlayerName()) .. ")";
						AddResourceData(kResources, row.Index, entryString, "LOC_CITY_STATES_SUZERAIN", resourceAmount);
					end
				end
			end
		end
	end

	-- Resources not yet accounted for come from other gameplay bonuses
	if pResources then
		for row in GameInfo.Resources() do
			local internalResourceAmount:number = pResources:GetResourceAmount(row.Index);
			if (internalResourceAmount > 0) then
				if (kResources[row.Index] ~= nil) then
					if (internalResourceAmount > kResources[row.Index].Total) then
						AddResourceData(kResources, row.Index, "LOC_HUD_REPORTS_MISC_RESOURCE_SOURCE", "-", internalResourceAmount - kResources[row.Index].Total);
					end
				else
					AddResourceData(kResources, row.Index, "LOC_HUD_REPORTS_MISC_RESOURCE_SOURCE", "-", internalResourceAmount);
				end
			end
		end
	end

	--BRS !! changed
	--return kCityData, kCityTotalData, kResources, kUnitData, kDealData;
	return kCityData, kCityTotalData, kResources, kUnitData, kDealData, kCurrentDeals, kUnitDataReport
end

-- ===========================================================================
function AddResourceData( kResources:table, eResourceType:number, EntryString:string, ControlString:string, InAmount:number)
	local kResource :table = GameInfo.Resources[eResourceType];

	--Artifacts need to be excluded because while TECHNICALLY a resource, they do nothing to contribute in a way that is relevant to any other resource 
	--or screen. So... exclusion.
	if kResource.ResourceClassType == "RESOURCECLASS_ARTIFACT" then
		return;
	end

	if kResources[eResourceType] == nil then
		kResources[eResourceType] = {
			EntryList	= {},
			Icon		= "[ICON_"..kResource.ResourceType.."]",
			IsStrategic	= kResource.ResourceClassType == "RESOURCECLASS_STRATEGIC",
			IsLuxury	= GameInfo.Resources[eResourceType].ResourceClassType == "RESOURCECLASS_LUXURY",
			IsBonus		= GameInfo.Resources[eResourceType].ResourceClassType == "RESOURCECLASS_BONUS",
			Total		= 0
		};
	end

	table.insert( kResources[eResourceType].EntryList, 
	{
		EntryText	= EntryString,
		ControlText = ControlString,
		Amount		= InAmount,					
	});

	kResources[eResourceType].Total = kResources[eResourceType].Total + InAmount;
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
--	Obtain the yields from the worked plots
-- ===========================================================================
function GetWorkedTileYieldData( pCity:table, pCulture:table )

	-- Loop through all the plots for a given city; tallying the resource amount.
	local kYields : table = {
		YIELD_PRODUCTION= 0,
		YIELD_FOOD		= 0,
		YIELD_GOLD		= 0,
		YIELD_FAITH		= 0,
		YIELD_SCIENCE	= 0,
		YIELD_CULTURE	= 0,
		TOURISM			= 0,
	};
	local cityPlots : table = Map.GetCityPlots():GetPurchasedPlots(pCity);
	local pCitizens	: table = pCity:GetCitizens();	
	local iNumWorkedPlots:number = 0;
	for _, plotID in ipairs(cityPlots) do		
		local plot	: table = Map.GetPlotByIndex(plotID);
		local x		: number = plot:GetX();
		local y		: number = plot:GetY();
		isPlotWorked = pCitizens:IsPlotWorked(x,y);
		if isPlotWorked then
			for row in GameInfo.Yields() do			
				kYields[row.YieldType] = kYields[row.YieldType] + plot:GetYield(row.Index);				
			end
			iNumWorkedPlots = iNumWorkedPlots + 1; --BRS
		end

		-- Support tourism.
		-- Not a common yield, and only exposure from game core is based off
		-- of the plot so the sum is easily shown, but it's not possible to 
		-- show how individual buildings contribute... yet.
		kYields["TOURISM"] = kYields["TOURISM"] + pCulture:GetTourismAt( plotID );
	end
	return kYields, iNumWorkedPlots; --BRS added num of worked plots
end

-- ===========================================================================
-- Obtain unit maintenance
-- This function will use GameInfo for vanilla game and UnitManager for Rise&Fall
function GetUnitMaintenance(pUnit:table)
	if bIsRiseFall then
		-- Rise & Fall version
		local iUnitInfoHash:number = GameInfo.Units[ pUnit:GetUnitType() ].Hash;
		local unitMilitaryFormation = pUnit:GetMilitaryFormation();
		if unitMilitaryFormation == MilitaryFormationTypes.CORPS_FORMATION then return UnitManager.GetUnitCorpsMaintenance(iUnitInfoHash); end
		if unitMilitaryFormation == MilitaryFormationTypes.ARMY_FORMATION  then return UnitManager.GetUnitArmyMaintenance(iUnitInfoHash); end
																				return UnitManager.GetUnitMaintenance(iUnitInfoHash);
	end
	-- vanilla version
	local iUnitMaintenance:number = GameInfo.Units[ pUnit:GetUnitType() ].Maintenance;
	local unitMilitaryFormation = pUnit:GetMilitaryFormation();
	if unitMilitaryFormation == MilitaryFormationTypes.CORPS_FORMATION then return math.ceil(iUnitMaintenance * 1.5); end -- it is 150% rounded UP
	if unitMilitaryFormation == MilitaryFormationTypes.ARMY_FORMATION  then return iUnitMaintenance * 2; end -- it is 200%
	                                                                        return iUnitMaintenance;
end

-- ===========================================================================
--	Set a group to it's proper collapse/open state
--	Set + - in group row
-- ===========================================================================
function RealizeGroup( instance:table )
	local v :number = (instance["isCollapsed"]==false and instance.RowExpandCheck:GetSizeY() or 0);
	instance.RowExpandCheck:SetTextureOffsetVal(0, v);

	instance.ContentStack:CalculateSize();	
	instance.CollapseScroll:CalculateSize();
	
	local groupHeight	:number = instance.ContentStack:GetSizeY();
	instance.CollapseAnim:SetBeginVal(0, -(groupHeight - instance["CollapsePadding"]));
	instance.CollapseScroll:SetSizeY( groupHeight );				

	instance.Top:ReprocessAnchoring();
end

-- ===========================================================================
--	Callback
--	Expand or contract a group based on its existing state.
-- ===========================================================================
function OnToggleCollapseGroup( instance:table )
	instance["isCollapsed"] = not instance["isCollapsed"];
	instance.CollapseAnim:Reverse();
	RealizeGroup( instance );
end

-- ===========================================================================
--	Toggle a group expanding / collapsing
--	instance,	A group instance.
-- ===========================================================================
function OnAnimGroupCollapse( instance:table)
		-- Helper
	function lerp(y1:number,y2:number,x:number)
		return y1 + (y2-y1)*x;
	end
	local groupHeight	:number = instance.ContentStack:GetSizeY();
	local collapseHeight:number = instance["CollapsePadding"]~=nil and instance["CollapsePadding"] or 0;
	local startY		:number = instance["isCollapsed"]==true  and groupHeight or collapseHeight;
	local endY			:number = instance["isCollapsed"]==false and groupHeight or collapseHeight;
	local progress		:number = instance.CollapseAnim:GetProgress();
	local sizeY			:number = lerp(startY,endY,progress);
		
	instance.CollapseAnim:SetSizeY( groupHeight );		-- BRS added, INFIXO CHECK
	instance.CollapseScroll:SetSizeY( sizeY );	
	instance.ContentStack:ReprocessAnchoring();	
	instance.Top:ReprocessAnchoring()

	Controls.Stack:CalculateSize();
	Controls.Scroll:CalculateSize();			
end


-- ===========================================================================
function SetGroupCollapsePadding( instance:table, amount:number )
	instance["CollapsePadding"] = amount;
end


-- ===========================================================================
function ResetTabForNewPageContent()
	m_uiGroups = {};
	m_simpleIM:ResetInstances();
	m_groupIM:ResetInstances();
	m_isCollapsing = true;
	Controls.CollapseAll:LocalizeAndSetText("LOC_HUD_REPORTS_COLLAPSE_ALL");
	Controls.Scroll:SetScrollValue( 0 );	
end


-- ===========================================================================
--	Instantiate a new collapsable row (group) holder & wire it up.
--	ARGS:	(optional) isCollapsed
--	RETURNS: New group instance
-- ===========================================================================
function NewCollapsibleGroupInstance( isCollapsed:boolean )
	if isCollapsed == nil then
		isCollapsed = false;
	end
	local instance:table = m_groupIM:GetInstance();	
	instance.ContentStack:DestroyAllChildren();
	instance["isCollapsed"]		= isCollapsed;
	instance["CollapsePadding"] = nil;				-- reset any prior collapse padding

	--BRS !! added
	instance["Children"] = {}
	instance["Descend"] = false
	-- !!

	instance.CollapseAnim:SetToBeginning();
	if isCollapsed == false then
		instance.CollapseAnim:SetToEnd();
	end	

	instance.RowHeaderButton:RegisterCallback( Mouse.eLClick, function() OnToggleCollapseGroup(instance); end );			
  	instance.RowHeaderButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);

	instance.CollapseAnim:RegisterAnimCallback(               function() OnAnimGroupCollapse( instance ); end );

	table.insert( m_uiGroups, instance );

	return instance;
end


-- ===========================================================================
--	debug - Create a test page.
-- ===========================================================================
function ViewTestPage()

	ResetTabForNewPageContent();

	local instance:table = NewCollapsibleGroupInstance();	
	instance.RowHeaderButton:SetText( "Test City Icon 1" );
	instance.Top:SetID("foo");
	
	local pHeaderInstance:table = {}
	ContextPtr:BuildInstanceForControl( "CityIncomeHeaderInstance", pHeaderInstance, instance.ContentStack ) ;	

	local pCityInstance:table = {};
	ContextPtr:BuildInstanceForControl( "CityIncomeInstance", pCityInstance, instance.ContentStack ) ;

	for i=1,3,1 do
		local pLineItemInstance:table = {};
		ContextPtr:BuildInstanceForControl("CityIncomeLineItemInstance", pLineItemInstance, pCityInstance.LineItemStack );
	end

	local pFooterInstance:table = {};
	ContextPtr:BuildInstanceForControl("CityIncomeFooterInstance", pFooterInstance, instance.ContentStack  );
	
	SetGroupCollapsePadding(instance, pFooterInstance.Top:GetSizeY() );
	RealizeGroup( instance );
	
	Controls.BottomYieldTotals:SetHide( true );
	Controls.BottomResourceTotals:SetHide( true );
	Controls.BottomPoliciesFilters:SetHide( true );
	Controls.Scroll:SetSizeY( Controls.Main:GetSizeY() - (Controls.BottomYieldTotals:GetSizeY() + SIZE_HEIGHT_PADDING_BOTTOM_ADJUST ) );
end

--BRS !! sort features for income

local sort : table = { by = "CityName", descend = false }

local function sortBy( name )
	if name == sort.by then
		sort.descend = not sort.descend
	else
		sort.by = name
		sort.descend = true
		if name == "CityName" then sort.descend = false; end -- exception
	end
	ViewYieldsPage()
end

local function sortFunction( t, a, b )

	if sort.by == "TourismPerTurn" then
		if sort.descend then
			return t[b].WorkedTileYields["TOURISM"] < t[a].WorkedTileYields["TOURISM"]
		else
			return t[b].WorkedTileYields["TOURISM"] > t[a].WorkedTileYields["TOURISM"]
		end
	else
		if sort.descend then
			return t[b][sort.by] < t[a][sort.by]
		else
			return t[b][sort.by] > t[a][sort.by]
		end
	end

end


-- ===========================================================================
--	Tab Callback
-- ===========================================================================
function ViewYieldsPage()

	ResetTabForNewPageContent();

	local pPlayer:table = Players[Game.GetLocalPlayer()]; --BRS

	local instance:table = nil;
	instance = NewCollapsibleGroupInstance();
	instance.RowHeaderButton:SetText( Locale.Lookup("LOC_HUD_REPORTS_ROW_CITY_INCOME") );
	instance.RowHeaderLabel:SetHide( true ); --BRS
	
	local pHeaderInstance:table = {}
	ContextPtr:BuildInstanceForControl( "CityIncomeHeaderInstance", pHeaderInstance, instance.ContentStack ) ;	

	--BRS sorting
	pHeaderInstance.CityNameButton:RegisterCallback( Mouse.eLClick, function() sortBy( "CityName" ) end )
	pHeaderInstance.ProductionButton:RegisterCallback( Mouse.eLClick, function() sortBy( "ProductionPerTurn" ) end )
	pHeaderInstance.FoodButton:RegisterCallback( Mouse.eLClick, function() sortBy( "FoodPerTurn" ) end )
	pHeaderInstance.GoldButton:RegisterCallback( Mouse.eLClick, function() sortBy( "GoldPerTurn" ) end )
	pHeaderInstance.FaithButton:RegisterCallback( Mouse.eLClick, function() sortBy( "FaithPerTurn" ) end )
	pHeaderInstance.ScienceButton:RegisterCallback( Mouse.eLClick, function() sortBy( "SciencePerTurn" ) end )
	pHeaderInstance.CultureButton:RegisterCallback( Mouse.eLClick, function() sortBy( "CulturePerTurn" ) end )
	pHeaderInstance.TourismButton:RegisterCallback( Mouse.eLClick, function() sortBy( "TourismPerTurn" ) end )

	local goldCityTotal		:number = 0;
	local faithCityTotal	:number = 0;
	local scienceCityTotal	:number = 0;
	local cultureCityTotal	:number = 0;
	local tourismCityTotal	:number = 0;
	
	-- Infixo needed to properly calculate yields from amenities
	local kBaseYields : table = {
		YIELD_PRODUCTION = 0,
		YIELD_FOOD		 = 0, -- not affected, but added for consistency
		YIELD_GOLD		 = 0,
		YIELD_FAITH		 = 0,
		YIELD_SCIENCE	 = 0,
		YIELD_CULTURE	 = 0,
		TOURISM			 = 0,
	};
	local function StoreInBaseYields(sYield:string, fValue:number) kBaseYields[ sYield ] = kBaseYields[ sYield ] + fValue; end

	-- ========== City Income ==========

	function CreatLineItemInstance(cityInstance:table, name:string, production:number, gold:number, food:number, science:number, culture:number, faith:number)
		local lineInstance:table = {};
		ContextPtr:BuildInstanceForControl("CityIncomeLineItemInstance", lineInstance, cityInstance.LineItemStack );
		TruncateStringWithTooltipClean(lineInstance.LineItemName, 200, name);
		lineInstance.Production:SetText( toPlusMinusNoneString(production));
		lineInstance.Food:SetText( toPlusMinusNoneString(food));
		lineInstance.Gold:SetText( toPlusMinusNoneString(gold));
		lineInstance.Faith:SetText( toPlusMinusNoneString(faith));
		lineInstance.Science:SetText( toPlusMinusNoneString(science));
		lineInstance.Culture:SetText( toPlusMinusNoneString(culture));
		--BRS Infixo needed to properly calculate yields from amenities
		StoreInBaseYields("YIELD_PRODUCTION", production);
		StoreInBaseYields("YIELD_FOOD", food);
		StoreInBaseYields("YIELD_GOLD", gold);
		StoreInBaseYields("YIELD_FAITH", faith);
		StoreInBaseYields("YIELD_SCIENCE", science);
		StoreInBaseYields("YIELD_CULTURE", culture);
		StoreInBaseYields("TOURISM", 0); -- not passed here
		--BRS end
		return lineInstance;
	end
	
	--BRS this function will be used to set singular fields in LineItemInstance, based on YieldType
	function SetFieldInLineItemInstance(lineItemInstance:table, yieldType:string, yieldValue:number)
		if     yieldType == "YIELD_PRODUCTION" then lineItemInstance.Production:SetText( toPlusMinusNoneString(yieldValue) );
		elseif yieldType == "YIELD_FOOD"       then lineItemInstance.Food:SetText(       toPlusMinusNoneString(yieldValue) );
		elseif yieldType == "YIELD_GOLD"       then lineItemInstance.Gold:SetText(       toPlusMinusNoneString(yieldValue) );
		elseif yieldType == "YIELD_FAITH"      then lineItemInstance.Faith:SetText(      toPlusMinusNoneString(yieldValue) );
		elseif yieldType == "YIELD_SCIENCE"    then lineItemInstance.Science:SetText(    toPlusMinusNoneString(yieldValue) );
		elseif yieldType == "YIELD_CULTURE"    then lineItemInstance.Culture:SetText(    toPlusMinusNoneString(yieldValue) );
		end
		StoreInBaseYields(yieldType, yieldValue);
	end

	for cityName,kCityData in spairs( m_kCityData, function( t, a, b ) return sortFunction( t, a, b ) end ) do --BRS sorting
		local pCityInstance:table = {};
		ContextPtr:BuildInstanceForControl( "CityIncomeInstance", pCityInstance, instance.ContentStack ) ;
		pCityInstance.LineItemStack:DestroyAllChildren();
		TruncateStringWithTooltip(pCityInstance.CityName, 230, Locale.Lookup(kCityData.CityName));
		pCityInstance.CityPopulation:SetText(kCityData.Population);

		--Great works
		local greatWorks:table = GetGreatWorksForCity(kCityData.City);
		
		-- Infixo reset base for amenities
		for yield,_ in pairs(kBaseYields) do kBaseYields[ yield ] = 0; end
		-- go to the city after clicking
		pCityInstance.GoToCityButton:RegisterCallback( Mouse.eLClick, function() Close(); UI.LookAtPlot( kCityData.City:GetX(), kCityData.City:GetY() ); UI.SelectCity( kCityData.City ); end );
		pCityInstance.GoToCityButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound( "Main_Menu_Mouse_Over" ); end );

		-- Current Production
		local kCurrentProduction:table = kCityData.ProductionQueue[1];
		pCityInstance.CurrentProduction:SetHide( kCurrentProduction == nil );
		if kCurrentProduction ~= nil then
			local tooltip:string = Locale.Lookup(kCurrentProduction.Name);
			if kCurrentProduction.Description ~= nil then
				tooltip = tooltip .. "[NEWLINE]" .. Locale.Lookup(kCurrentProduction.Description);
			end
			pCityInstance.CurrentProduction:SetToolTipString( tooltip )

			if kCurrentProduction.Icon then
				pCityInstance.CityBannerBackground:SetHide( false );
				pCityInstance.CurrentProduction:SetIcon( kCurrentProduction.Icon );
				pCityInstance.CityProductionMeter:SetPercent( kCurrentProduction.PercentComplete );
				pCityInstance.CityProductionNextTurn:SetPercent( kCurrentProduction.PercentCompleteNextTurn );			
				pCityInstance.ProductionBorder:SetHide( kCurrentProduction.Type == ProductionType.DISTRICT );
			else
				pCityInstance.CityBannerBackground:SetHide( true );
			end
		end

		pCityInstance.Production:SetText( toPlusMinusString(kCityData.ProductionPerTurn) );
		pCityInstance.Food:SetText( toPlusMinusString(kCityData.FoodPerTurn) );
		pCityInstance.Gold:SetText( toPlusMinusString(kCityData.GoldPerTurn) );
		pCityInstance.Faith:SetText( toPlusMinusString(kCityData.FaithPerTurn) );
		pCityInstance.Science:SetText( toPlusMinusString(kCityData.SciencePerTurn) );
		pCityInstance.Culture:SetText( toPlusMinusString(kCityData.CulturePerTurn) );
		pCityInstance.Tourism:SetText( toPlusMinusString(kCityData.WorkedTileYields["TOURISM"]) );

		-- Add to all cities totals
		goldCityTotal	= goldCityTotal + kCityData.GoldPerTurn;
		faithCityTotal	= faithCityTotal + kCityData.FaithPerTurn;
		scienceCityTotal= scienceCityTotal + kCityData.SciencePerTurn;
		cultureCityTotal= cultureCityTotal + kCityData.CulturePerTurn;
		tourismCityTotal= tourismCityTotal + kCityData.WorkedTileYields["TOURISM"];
		
		if not Controls.HideCityBuildingsCheckbox:IsSelected() then --BRS

		for i,kDistrict in ipairs(kCityData.BuildingsAndDistricts) do			
			--District line item
			--BRS The only yields are from Adjacency, so this will duplicate them
			--BRS show this line only for an icon and a name
			local districtInstance = CreatLineItemInstance(	pCityInstance, 
															kDistrict.Name,
															0,--kDistrict.Production,
															0,--kDistrict.Gold,
															0,--kDistrict.Food,
															0,--kDistrict.Science,
															0,--kDistrict.Culture,
															0);--kDistrict.Faith);
			districtInstance.DistrictIcon:SetHide(false);
			districtInstance.DistrictIcon:SetIcon(kDistrict.Icon);

			function HasValidAdjacencyBonus(adjacencyTable:table)
				for _, yield in pairs(adjacencyTable) do
					if yield ~= 0 then
						return true;
					end
				end
				return false;
			end

			--Adjacency
			if HasValidAdjacencyBonus(kDistrict.AdjacencyBonus) then
				CreatLineItemInstance(	pCityInstance,
										INDENT_STRING .. Locale.Lookup("LOC_HUD_REPORTS_ADJACENCY_BONUS"),
										kDistrict.AdjacencyBonus.Production,
										kDistrict.AdjacencyBonus.Gold,
										kDistrict.AdjacencyBonus.Food,
										kDistrict.AdjacencyBonus.Science,
										kDistrict.AdjacencyBonus.Culture,
										kDistrict.AdjacencyBonus.Faith);
			end

			
			for i,kBuilding in ipairs(kDistrict.Buildings) do
				CreatLineItemInstance(	pCityInstance,
										INDENT_STRING ..  kBuilding.Name,
										kBuilding.ProductionPerTurn,
										kBuilding.GoldPerTurn,
										kBuilding.FoodPerTurn,
										kBuilding.SciencePerTurn,
										kBuilding.CulturePerTurn,
										kBuilding.FaithPerTurn);

				--Add great works
				if greatWorks[kBuilding.Type] ~= nil then
					--Add our line items!
					for _, kGreatWork in ipairs(greatWorks[kBuilding.Type]) do
						local pLineItemInstance:table = CreatLineItemInstance(pCityInstance, INDENT_STRING..INDENT_STRING..Locale.Lookup(kGreatWork.Name), 0, 0, 0,	0, 0, 0);
						for _, yield in ipairs(kGreatWork.YieldChanges) do
							SetFieldInLineItemInstance(pLineItemInstance, yield.YieldType, yield.YieldChange);
						end
					end
				end
			end
		end

		-- Display wonder yields
		if kCityData.Wonders then
			for _, wonder in ipairs(kCityData.Wonders) do
				if wonder.Yields[1] ~= nil or greatWorks[wonder.Type] ~= nil then
				-- Assign yields to the line item
					local pLineItemInstance:table = CreatLineItemInstance(pCityInstance, wonder.Name, 0, 0, 0, 0, 0, 0);
					-- Show yields
					for _, yield in ipairs(wonder.Yields) do
						SetFieldInLineItemInstance(pLineItemInstance, yield.YieldType, yield.YieldChange);
					end
				end

				--Add great works
				if greatWorks[wonder.Type] ~= nil then
					--Add our line items!
					for _, kGreatWork in ipairs(greatWorks[wonder.Type]) do
						local pLineItemInstance:table = CreatLineItemInstance(pCityInstance, INDENT_STRING..Locale.Lookup(kGreatWork.Name), 0, 0, 0, 0, 0, 0);
						for _, yield in ipairs(kGreatWork.YieldChanges) do
							SetFieldInLineItemInstance(pLineItemInstance, yield.YieldType, yield.YieldChange);
						end
					end
				end
			end
		end

		-- Display route yields
		if kCityData.OutgoingRoutes then
			for i,route in ipairs(kCityData.OutgoingRoutes) do
				if route ~= nil then
					if route.OriginYields then
						-- Find destination city
						local pDestPlayer:table = Players[route.DestinationCityPlayer];
						local pDestPlayerCities:table = pDestPlayer:GetCities();
						local pDestCity:table = pDestPlayerCities:FindID(route.DestinationCityID);
						--Assign yields to the line item
						local pLineItemInstance:table = CreatLineItemInstance(pCityInstance, Locale.Lookup("LOC_HUD_REPORTS_TRADE_WITH", Locale.Lookup(pDestCity:GetName())), 0, 0, 0, 0, 0, 0);
						for j,yield in ipairs(route.OriginYields) do
							local yieldInfo = GameInfo.Yields[yield.YieldIndex];
							if yieldInfo then
								SetFieldInLineItemInstance(pLineItemInstance, yieldInfo.YieldType, yield.Amount);
							end
						end
					end
				end
			end
		end

		--Worked Tiles
		CreatLineItemInstance(	pCityInstance,
								Locale.Lookup("LOC_HUD_REPORTS_WORKED_TILES")..string.format("  [COLOR_White]%d[ENDCOLOR]", kCityData.NumWorkedTiles),
								kCityData.WorkedTileYields["YIELD_PRODUCTION"],
								kCityData.WorkedTileYields["YIELD_GOLD"],
								kCityData.WorkedTileYields["YIELD_FOOD"],
								kCityData.WorkedTileYields["YIELD_SCIENCE"],
								kCityData.WorkedTileYields["YIELD_CULTURE"],
								kCityData.WorkedTileYields["YIELD_FAITH"]);

		-- Additional Yields from Population
		local populationToCultureScale:number = GameInfo.GlobalParameters["CULTURE_PERCENTAGE_YIELD_PER_POP"].Value / 100;
		local populationToScienceScale:number = GameInfo.GlobalParameters["SCIENCE_PERCENTAGE_YIELD_PER_POP"].Value / 100; -- Infixo added science per pop
		CreatLineItemInstance(	pCityInstance,
								Locale.Lookup("LOC_HUD_CITY_POPULATION")..string.format("  [COLOR_White]%d[ENDCOLOR]", kCityData.Population),
								0,
								0,
								0,
								kCityData.Population * populationToScienceScale,
								kCityData.Population * populationToCultureScale, 
								0);

		-- Yields from Amenities -- Infixo TOTALLY WRONG amenities are applied to all yields, not only Worked Tiles; also must be the LAST calculated entry
		--local iYieldPercent = (Round(1 + (kCityData.HappinessNonFoodYieldModifier/100), 2)*.1); -- Infixo Buggy formula
		local iYieldPercent:number = kCityData.HappinessNonFoodYieldModifier/100;
		--[[
		CreatLineItemInstance(	pCityInstance,
								Locale.Lookup("LOC_HUD_REPORTS_HEADER_AMENITIES"),
								kCityData.WorkedTileYields["YIELD_PRODUCTION"] * iYieldPercent,
								kCityData.WorkedTileYields["YIELD_GOLD"] * iYieldPercent,
								0,
								kCityData.WorkedTileYields["YIELD_SCIENCE"] * iYieldPercent,
								kCityData.WorkedTileYields["YIELD_CULTURE"] * iYieldPercent,
								kCityData.WorkedTileYields["YIELD_FAITH"] * iYieldPercent);
		--]]
		local sModifierColor:string;
		if     kCityData.HappinessNonFoodYieldModifier == 0 then sModifierColor = "COLOR_White";
		elseif kCityData.HappinessNonFoodYieldModifier  > 0 then sModifierColor = "COLOR_Green";
		else                                                     sModifierColor = "COLOR_Red"; -- <0
		end
		CreatLineItemInstance(	pCityInstance,
								Locale.Lookup("LOC_HUD_REPORTS_HEADER_AMENITIES")..string.format("  ["..sModifierColor.."]%+d%%[ENDCOLOR]", kCityData.HappinessNonFoodYieldModifier),
								kBaseYields.YIELD_PRODUCTION * iYieldPercent,
								kBaseYields.YIELD_GOLD * iYieldPercent,
								0,
								kBaseYields.YIELD_SCIENCE * iYieldPercent,
								kBaseYields.YIELD_CULTURE * iYieldPercent,
								kBaseYields.YIELD_FAITH * iYieldPercent);

		pCityInstance.LineItemStack:CalculateSize();
		pCityInstance.Darken:SetSizeY( pCityInstance.LineItemStack:GetSizeY() + DARKEN_CITY_INCOME_AREA_ADDITIONAL_Y );
		pCityInstance.Top:ReprocessAnchoring();
		end --BRS if HideCityBuildingsCheckbox:IsSelected
	end

	local pFooterInstance:table = {};
	ContextPtr:BuildInstanceForControl("CityIncomeFooterInstance", pFooterInstance, instance.ContentStack  );
	pFooterInstance.Gold:SetText( "[Icon_GOLD]"..toPlusMinusString(goldCityTotal) );
	pFooterInstance.Faith:SetText( "[Icon_FAITH]"..toPlusMinusString(faithCityTotal) );
	pFooterInstance.Science:SetText( "[Icon_SCIENCE]"..toPlusMinusString(scienceCityTotal) );
	pFooterInstance.Culture:SetText( "[Icon_CULTURE]"..toPlusMinusString(cultureCityTotal) );
	pFooterInstance.Tourism:SetText( "[Icon_TOURISM]"..toPlusMinusString(tourismCityTotal) );

	SetGroupCollapsePadding(instance, pFooterInstance.Top:GetSizeY() );
	RealizeGroup( instance );

	-- ========== Building Expenses ==========

	--BRS It displays a long list with multiple same entries - no fun at all
	-- Collapse it in the same way as Units, i.e. show Name / Count / Gold
	local kBuildingExpenses:table = {};
	for cityName,kCityData in pairs(m_kCityData) do
		for _,kDistrict in ipairs(kCityData.BuildingsAndDistricts) do
			local key = kDistrict.Name;
			if kBuildingExpenses[key] == nil then kBuildingExpenses[key] = { Count = 0, Maintenance = 0 }; end -- init entry
			kBuildingExpenses[key].Count       = kBuildingExpenses[key].Count + 1;
			kBuildingExpenses[key].Maintenance = kBuildingExpenses[key].Maintenance + kDistrict.Maintenance;
		end
		for _,kBuilding in ipairs(kCityData.Buildings) do
			local key = kBuilding.Name;
			if kBuildingExpenses[key] == nil then kBuildingExpenses[key] = { Count = 0, Maintenance = 0 }; end -- init entry
			kBuildingExpenses[key].Count       = kBuildingExpenses[key].Count + 1;
			kBuildingExpenses[key].Maintenance = kBuildingExpenses[key].Maintenance + kBuilding.Maintenance;
		end
	end
	--BRS sort by name here somehow?
	
	instance = NewCollapsibleGroupInstance();
	instance.RowHeaderButton:SetText( Locale.Lookup("LOC_HUD_REPORTS_ROW_BUILDING_EXPENSES") );
	instance.RowHeaderLabel:SetHide( true ); --BRS

	-- Header
	local pHeader:table = {};
	ContextPtr:BuildInstanceForControl( "BuildingExpensesHeaderInstance", pHeader, instance.ContentStack ) ;

	-- Buildings
	local iTotalBuildingMaintenance :number = 0;
	local bHideFreeBuildings:boolean = Controls.HideFreeBuildingsCheckbox:IsSelected(); --BRS
	for sName, data in spairs( kBuildingExpenses, function( t, a, b ) return Locale.Lookup(a) < Locale.Lookup(b) end ) do -- sorting by name (key)
		if data.Maintenance ~= 0 or not bHideFreeBuildings then
			local pBuildingInstance:table = {};
			ContextPtr:BuildInstanceForControl( "BuildingExpensesEntryInstance", pBuildingInstance, instance.ContentStack );
			TruncateStringWithTooltip(pBuildingInstance.BuildingName, 224, Locale.Lookup(sName)); 
			pBuildingInstance.BuildingCount:SetText( Locale.Lookup(data.Count) );
			pBuildingInstance.Gold:SetText( data.Maintenance == 0 and "0" or "-"..tostring(data.Maintenance));
			iTotalBuildingMaintenance = iTotalBuildingMaintenance - data.Maintenance;
		end
	end

	-- Footer
	local pBuildingFooterInstance:table = {};		
	ContextPtr:BuildInstanceForControl( "GoldFooterInstance", pBuildingFooterInstance, instance.ContentStack ) ;		
	pBuildingFooterInstance.Gold:SetText("[ICON_Gold]"..tostring(iTotalBuildingMaintenance) );

	SetGroupCollapsePadding(instance, pBuildingFooterInstance.Top:GetSizeY() );
	RealizeGroup( instance );

	-- ========== Unit Expenses ==========

	if GameCapabilities.HasCapability("CAPABILITY_REPORTS_UNIT_EXPENSES") then 
		instance = NewCollapsibleGroupInstance();
		instance.RowHeaderButton:SetText( Locale.Lookup("LOC_HUD_REPORTS_ROW_UNIT_EXPENSES") );
		instance.RowHeaderLabel:SetHide( true ); --BRS

		-- Header
		local pHeader:table = {};
		ContextPtr:BuildInstanceForControl( "UnitExpensesHeaderInstance", pHeader, instance.ContentStack ) ;

		-- Units
		local iTotalUnitMaintenance:number = 0;
		local bHideFreeUnits:boolean = Controls.HideFreeUnitsCheckbox:IsSelected(); --BRS
		-- sort units by name field, which already contains a localized name, and by military formation
		for _,kUnitData in spairs( m_kUnitData, function(t,a,b) if t[a].Name == t[b].Name then return t[a].Formation < t[b].Formation else return t[a].Name < t[b].Name end end ) do
			if kUnitData.Maintenance ~= 0 or not bHideFreeUnits then
				local pUnitInstance:table = {};
				ContextPtr:BuildInstanceForControl( "UnitExpensesEntryInstance", pUnitInstance, instance.ContentStack );
				if     kUnitData.Formation == MilitaryFormationTypes.CORPS_FORMATION then pUnitInstance.UnitName:SetText(kUnitData.Name.." [ICON_Corps]");
				elseif kUnitData.Formation == MilitaryFormationTypes.ARMY_FORMATION  then pUnitInstance.UnitName:SetText(kUnitData.Name.." [ICON_Army]");
				else                                                                      pUnitInstance.UnitName:SetText(kUnitData.Name); end
				pUnitInstance.UnitCount:SetText(kUnitData.Count);
				pUnitInstance.Gold:SetText( kUnitData.Maintenance == 0 and "0" or "-"..tostring(kUnitData.Maintenance) );
				iTotalUnitMaintenance = iTotalUnitMaintenance - kUnitData.Maintenance;
			end
		end

		-- Footer
		local pUnitFooterInstance:table = {};		
		ContextPtr:BuildInstanceForControl( "GoldFooterInstance", pUnitFooterInstance, instance.ContentStack ) ;		
		pUnitFooterInstance.Gold:SetText("[ICON_Gold]"..tostring(iTotalUnitMaintenance) );

		SetGroupCollapsePadding(instance, pUnitFooterInstance.Top:GetSizeY() );
		RealizeGroup( instance );
	end

	-- ========== Diplomatic Deals Expenses ==========
	
	if GameCapabilities.HasCapability("CAPABILITY_REPORTS_DIPLOMATIC_DEALS") then 
		instance = NewCollapsibleGroupInstance();	
		instance.RowHeaderButton:SetText( Locale.Lookup("LOC_HUD_REPORTS_ROW_DIPLOMATIC_DEALS") );
		instance.RowHeaderLabel:SetHide( true ); --BRS

		local pHeader:table = {};
		ContextPtr:BuildInstanceForControl( "DealHeaderInstance", pHeader, instance.ContentStack ) ;

		local iTotalDealGold :number = 0;
		for i,kDeal in ipairs(m_kDealData) do
			if kDeal.Type == DealItemTypes.GOLD then
				local pDealInstance:table = {};		
				ContextPtr:BuildInstanceForControl( "DealEntryInstance", pDealInstance, instance.ContentStack ) ;		

				pDealInstance.Civilization:SetText( kDeal.Name );
				pDealInstance.Duration:SetText( kDeal.Duration );
				if kDeal.IsOutgoing then
					pDealInstance.Gold:SetText( "-"..tostring(kDeal.Amount) );
					iTotalDealGold = iTotalDealGold - kDeal.Amount;
				else
					pDealInstance.Gold:SetText( "+"..tostring(kDeal.Amount) );
					iTotalDealGold = iTotalDealGold + kDeal.Amount;
				end
			end
		end
		local pDealFooterInstance:table = {};		
		ContextPtr:BuildInstanceForControl( "GoldFooterInstance", pDealFooterInstance, instance.ContentStack ) ;		
		pDealFooterInstance.Gold:SetText("[ICON_Gold]"..tostring(iTotalDealGold) );

		SetGroupCollapsePadding(instance, pDealFooterInstance.Top:GetSizeY() );
		RealizeGroup( instance );
	end


	-- ========== TOTALS ==========

	Controls.Stack:CalculateSize();
	Controls.Scroll:CalculateSize();

	-- Totals at the bottom [Definitive values]
	local localPlayer = Players[Game.GetLocalPlayer()];
	--Gold
	local playerTreasury:table	= localPlayer:GetTreasury();
	Controls.GoldIncome:SetText( toPlusMinusNoneString( playerTreasury:GetGoldYield() ));
	Controls.GoldExpense:SetText( toPlusMinusNoneString( -playerTreasury:GetTotalMaintenance() ));	-- Flip that value!
	Controls.GoldNet:SetText( toPlusMinusNoneString( playerTreasury:GetGoldYield() - playerTreasury:GetTotalMaintenance() ));
	Controls.GoldBalance:SetText( m_kCityTotalData.Treasury[YieldTypes.GOLD] );

	
	--Faith
	local playerReligion:table	= localPlayer:GetReligion();
	Controls.FaithIncome:SetText( toPlusMinusNoneString(playerReligion:GetFaithYield()));
	Controls.FaithNet:SetText( toPlusMinusNoneString(playerReligion:GetFaithYield()));
	Controls.FaithBalance:SetText( m_kCityTotalData.Treasury[YieldTypes.FAITH] );

	--Science
	local playerTechnology:table	= localPlayer:GetTechs();
	Controls.ScienceIncome:SetText( toPlusMinusNoneString(playerTechnology:GetScienceYield()));
	Controls.ScienceBalance:SetText( m_kCityTotalData.Treasury[YieldTypes.SCIENCE] );
	
	--Culture
	local playerCulture:table	= localPlayer:GetCulture();
	Controls.CultureIncome:SetText(toPlusMinusNoneString(playerCulture:GetCultureYield()));
	Controls.CultureBalance:SetText(m_kCityTotalData.Treasury[YieldTypes.CULTURE] );
	
	--Tourism. We don't talk about this one much.
	Controls.TourismIncome:SetText( toPlusMinusNoneString( m_kCityTotalData.Income["TOURISM"] ));	
	Controls.TourismBalance:SetText( m_kCityTotalData.Treasury["TOURISM"] );
	
	Controls.CollapseAll:SetHide( false );
	Controls.BottomYieldTotals:SetHide( false ); -- ViewYieldsPage
	Controls.BottomYieldTotals:SetSizeY( SIZE_HEIGHT_BOTTOM_YIELDS );
	Controls.BottomResourceTotals:SetHide( true );
	Controls.BottomPoliciesFilters:SetHide( true );
	Controls.Scroll:SetSizeY( Controls.Main:GetSizeY() - (Controls.BottomYieldTotals:GetSizeY() + SIZE_HEIGHT_PADDING_BOTTOM_ADJUST ) );	
	-- Remember this tab when report is next opened: ARISTOS
	m_kCurrentTab = 1;
end


-- ===========================================================================
--	Tab Callback
-- ===========================================================================
function ViewResourcesPage()	

	ResetTabForNewPageContent();

	local strategicResources:string = "";
	local luxuryResources	:string = "";
	local kBonuses			:table	= {};
	local kLuxuries			:table	= {};
	local kStrategics		:table	= {};
	

	for eResourceType,kSingleResourceData in pairs(m_kResourceData) do
		
		--!!ARISTOS: Only display list of selected resource types, according to checkboxes
		if (kSingleResourceData.IsStrategic and Controls.StrategicCheckbox:IsSelected()) or
			(kSingleResourceData.IsLuxury and Controls.LuxuryCheckbox:IsSelected()) or
			(kSingleResourceData.IsBonus and Controls.BonusCheckbox:IsSelected()) then

		local instance:table = NewCollapsibleGroupInstance();	

		local kResource :table = GameInfo.Resources[eResourceType];
		instance.RowHeaderButton:SetText(  kSingleResourceData.Icon..Locale.Lookup( kResource.Name ) );
		instance.RowHeaderLabel:SetHide( true ); --BRS

		local pHeaderInstance:table = {};
		ContextPtr:BuildInstanceForControl( "ResourcesHeaderInstance", pHeaderInstance, instance.ContentStack ) ;

		local kResourceEntries:table = kSingleResourceData.EntryList;
		for i,kEntry in ipairs(kResourceEntries) do
			local pEntryInstance:table = {};
			ContextPtr:BuildInstanceForControl( "ResourcesEntryInstance", pEntryInstance, instance.ContentStack ) ;
			pEntryInstance.CityName:SetText( Locale.Lookup(kEntry.EntryText) );
			pEntryInstance.Control:SetText( Locale.Lookup(kEntry.ControlText) );
			pEntryInstance.Amount:SetText( (kEntry.Amount<=0) and tostring(kEntry.Amount) or "+"..tostring(kEntry.Amount) );
		end

		local pFooterInstance:table = {};
		ContextPtr:BuildInstanceForControl( "ResourcesFooterInstance", pFooterInstance, instance.ContentStack ) ;
		pFooterInstance.Amount:SetText( tostring(kSingleResourceData.Total) );		

		-- Show how many of this resource are being allocated to what cities
		local localPlayerID = Game.GetLocalPlayer();
		local localPlayer = Players[localPlayerID];
		local citiesProvidedTo: table = localPlayer:GetResources():GetResourceAllocationCities(GameInfo.Resources[kResource.ResourceType].Index);
		local numCitiesProvidingTo: number = table.count(citiesProvidedTo);
		if (numCitiesProvidingTo > 0) then
			pFooterInstance.AmenitiesContainer:SetHide(false);
			pFooterInstance.Amenities:SetText("[ICON_Amenities][ICON_GoingTo]"..numCitiesProvidingTo.." "..Locale.Lookup("LOC_PEDIA_CONCEPTS_PAGEGROUP_CITIES_NAME"));
			local amenitiesTooltip: string = "";
			local playerCities = localPlayer:GetCities();
			for i,city in ipairs(citiesProvidedTo) do
				local cityName = Locale.Lookup(playerCities:FindID(city.CityID):GetName());
				if i ~=1 then
					amenitiesTooltip = amenitiesTooltip.. "[NEWLINE]";
				end
				amenitiesTooltip = amenitiesTooltip.. city.AllocationAmount.." [ICON_".. kResource.ResourceType.."] [Icon_GoingTo] " ..cityName;
			end
			pFooterInstance.Amenities:SetToolTipString(amenitiesTooltip);
		else
			pFooterInstance.AmenitiesContainer:SetHide(true);
		end

		SetGroupCollapsePadding(instance, pFooterInstance.Top:GetSizeY() ); --BRS moved into if
		RealizeGroup( instance ); --BRS moved into if

		end -- ARISTOS checkboxes

		if kSingleResourceData.IsStrategic then
			--strategicResources = strategicResources .. kSingleResourceData.Icon .. tostring( kSingleResourceData.Total );
			table.insert(kStrategics, kSingleResourceData.Icon .. tostring( kSingleResourceData.Total ) );
		elseif kSingleResourceData.IsLuxury then			
			--luxuryResources = luxuryResources .. kSingleResourceData.Icon .. tostring( kSingleResourceData.Total );			
			table.insert(kLuxuries, kSingleResourceData.Icon .. tostring( kSingleResourceData.Total ) );
		else
			table.insert(kBonuses, kSingleResourceData.Icon .. tostring( kSingleResourceData.Total ) );
		end

		--SetGroupCollapsePadding(instance, pFooterInstance.Top:GetSizeY() ); --BRS moved into if
		--RealizeGroup( instance ); --BRS moved into if
	end
	
	m_strategicResourcesIM:ResetInstances();
	for i,v in ipairs(kStrategics) do
		local resourceInstance:table = m_strategicResourcesIM:GetInstance();	
		resourceInstance.Info:SetText( v );
	end
	Controls.StrategicResources:CalculateSize();
	Controls.StrategicGrid:ReprocessAnchoring();

	m_bonusResourcesIM:ResetInstances();
	for i,v in ipairs(kBonuses) do
		local resourceInstance:table = m_bonusResourcesIM:GetInstance();	
		resourceInstance.Info:SetText( v );
	end
	Controls.BonusResources:CalculateSize();
	Controls.BonusGrid:ReprocessAnchoring();

	m_luxuryResourcesIM:ResetInstances();
	for i,v in ipairs(kLuxuries) do
		local resourceInstance:table = m_luxuryResourcesIM:GetInstance();	
		resourceInstance.Info:SetText( v );
	end
	
	Controls.LuxuryResources:CalculateSize();
	Controls.LuxuryResources:ReprocessAnchoring();
	Controls.LuxuryGrid:ReprocessAnchoring();
	
	Controls.Stack:CalculateSize();
	Controls.Scroll:CalculateSize();

	Controls.CollapseAll:SetHide( false );
	Controls.BottomYieldTotals:SetHide( true );
	Controls.BottomResourceTotals:SetHide( false ); -- ViewResourcesPage
	Controls.BottomPoliciesFilters:SetHide( true );
	Controls.Scroll:SetSizeY( Controls.Main:GetSizeY() - (Controls.BottomResourceTotals:GetSizeY() + SIZE_HEIGHT_PADDING_BOTTOM_ADJUST ) );	
	-- Remember this tab when report is next opened: ARISTOS
	m_kCurrentTab = 2;
end

-- ===========================================================================
--	Tab Callback
-- ===========================================================================

-- helper from CityPanel.lua
function GetPercentGrowthColor( percent:number )
	if percent == 0 then return "Error"; end
	if percent <= 0.25 then return "WarningMajor"; end
	if percent <= 0.5 then return "WarningMinor"; end
	return "StatNormalCSGlow";
end

function city_fields( kCityData, pCityInstance )

	local function ColorRed(text) return("[COLOR_Red]"..tostring(text).."[ENDCOLOR]"); end -- Infixo: helper
	local function ColorGreen(text) return("[COLOR_Green]"..tostring(text).."[ENDCOLOR]"); end -- Infixo: helper

	-- Infixo: status will show various icons
	--pCityInstance.Status:SetText( kCityData.IsUnderSiege and Locale.Lookup("LOC_HUD_REPORTS_STATUS_UNDER_SEIGE") or Locale.Lookup("LOC_HUD_REPORTS_STATUS_NORMAL") );
	local sStatusText:string = "";
	local tStatusToolTip:table = {};
	if kCityData.Population > kCityData.Housing then
		sStatusText = sStatusText.."[ICON_HousingInsufficient]"; table.insert(tStatusToolTip, Locale.Lookup("LOC_CITY_BANNER_HOUSING_INSUFFICIENT"));
	end -- insufficient housing   
	if kCityData.AmenitiesNum < kCityData.AmenitiesRequiredNum then
		sStatusText = sStatusText.."[ICON_AmenitiesInsufficient]"; table.insert(tStatusToolTip, Locale.Lookup("LOC_CITY_BANNER_AMENITIES_INSUFFICIENT"));
	end -- insufficient amenities
	if kCityData.IsUnderSiege then
		sStatusText = sStatusText.."[ICON_UnderSiege]"; table.insert(tStatusToolTip, Locale.Lookup("LOC_HUD_REPORTS_STATUS_UNDER_SEIGE"));
	end -- under siege
	if kCityData.Occupied then
		sStatusText = sStatusText.."[ICON_Occupied]"; table.insert(tStatusToolTip, Locale.Lookup("LOC_HUD_CITY_GROWTH_OCCUPIED"));
	end -- occupied 
	pCityInstance.Status:SetText( sStatusText );
	pCityInstance.Status:SetToolTipString( table.concat(tStatusToolTip, "[NEWLINE]") );
	
	-- CityName
	--pCityInstance.CityName:SetText( Locale.Lookup( kCityData.CityName ) );
	TruncateStringWithTooltip(pCityInstance.CityName, 150, Locale.Lookup(kCityData.CityName));
	
	-- Population and Housing
	if bIsRiseFall then
		if kCityData.Population > kCityData.Housing then
			pCityInstance.Population:SetText( tostring(kCityData.Population) .. " / "..ColorRed(kCityData.Housing));
		else
			pCityInstance.Population:SetText( tostring(kCityData.Population) .. " / " .. tostring(kCityData.Housing));
		end
	else -- vanilla version
		pCityInstance.Population:SetText( tostring(kCityData.Population) ); -- Infixo
		pCityInstance.Housing:SetText( tostring( kCityData.Housing ) );
	end
	
	-- GrowthRateStatus
	--<ColorSet Name="WarningMinor"         Color0="206,199,91,255"   Color1="0,0,0,200" />
	--<ColorSet Name="WarningMajor"         Color0="200,146,52,255"   Color1="0,0,0,200" />
	--<ColorSet Name="Error"                Color0="200,62,52,255"    Color1="0,0,0,200" />
	local sGRStatus:string = "LOC_HUD_REPORTS_STATUS_NORMAL";
	local sGRColor:string = "";
	if     kCityData.HousingMultiplier == 0 or kCityData.Occupied then sGRStatus = "LOC_HUD_REPORTS_STATUS_HALTED"; sGRColor = "[COLOR:200,62,52,255]"; -- Error
	elseif kCityData.HousingMultiplier <= 0.25                    then sGRStatus = "LOC_HUD_REPORTS_STATUS_SLOWED"; sGRColor = "[COLOR:200,146,52,255]"; -- WarningMajor
	elseif kCityData.HousingMultiplier <= 0.5                     then sGRStatus = "LOC_HUD_REPORTS_STATUS_SLOWED"; sGRColor = "[COLOR:206,199,91,255]"; end -- WarningMinor
	pCityInstance.GrowthRateStatus:SetText( sGRColor..Locale.Lookup(sGRStatus)..(sGRColor~="" and "[ENDCOLOR]" or "") );
	--if sGRColor ~= "" then pCityInstance.GrowthRateStatus:SetColorByName( sGRColor ); end

	-- Amenities and Happiness
	if kCityData.AmenitiesNum < kCityData.AmenitiesRequiredNum then
		pCityInstance.Amenities:SetText( ColorRed(kCityData.AmenitiesNum).." / "..tostring(kCityData.AmenitiesRequiredNum) );
	else
		pCityInstance.Amenities:SetText( tostring(kCityData.AmenitiesNum).." / "..tostring(kCityData.AmenitiesRequiredNum) );
	end
	local happinessInfo:table = GameInfo.Happinesses[kCityData.Happiness];
	local happinessText:string = Locale.Lookup( happinessInfo.Name );
	if happinessInfo.GrowthModifier < 0 then happinessText = "[COLOR:StatBadCS]"..happinessText.."[ENDCOLOR]"; end
	if happinessInfo.GrowthModifier > 0 then happinessText = "[COLOR:StatGoodCS]"..happinessText.."[ENDCOLOR]"; end
	pCityInstance.CitizenHappiness:SetText( happinessText );
	--<ColorSet Name="StatGoodCS"										Color0="80,255,90,240"		Color1="0,0,0,200" />
	--<ColorSet Name="StatNormalCS"									Color0="200,200,200,240"	Color1="0,0,0,200" />
	--<ColorSet Name="StatBadCS"										Color0="255,40,50,240"		Color1="0,0,0,200" />
	
	-- Strength and icon for Garrison Unit
	if kCityData.IsGarrisonUnit then 
		pCityInstance.Strength:SetText( tostring(kCityData.Defense).."[ICON_Fortified]" ); -- [ICON_Unit] small person [ICON_Exclamation] it's in a circle
		pCityInstance.Strength:SetToolTipString("Garrison Unit");
	else
		pCityInstance.Strength:SetText( tostring(kCityData.Defense) );
		pCityInstance.Strength:SetToolTipString("");
	end

	-- WarWeariness
	local warWearyValue:number = kCityData.AmenitiesLostFromWarWeariness;
	--pCityInstance.WarWeariness:SetText( (warWearyValue==0) and "0" or ColorRed("-"..tostring(warWearyValue)) );
	-- Damage
	--pCityInstance.Damage:SetText( tostring(kCityData.Damage) );	-- Infixo (vanilla version)
	local sDamageWWText:string = "0";
	if kCityData.HitpointsTotal > kCityData.HitpointsCurrent then sDamageWWText = ColorRed(kCityData.HitpointsTotal - kCityData.HitpointsCurrent); end
	sDamageWWText = sDamageWWText.." / "..( (warWearyValue==0) and "0" or ColorRed("-"..tostring(warWearyValue)) );
	pCityInstance.Damage:SetText( sDamageWWText );
	pCityInstance.Damage:SetToolTipString( Locale.Lookup("LOC_HUD_REPORTS_HEADER_DAMAGE").." / "..Locale.Lookup("LOC_HUD_REPORTS_HEADER_WAR_WEARINESS") );

	-- Districts
	-- TODO
	
	if not bIsRiseFall then return end -- the 2 remaining fields are for Rise & Fall only
	
	-- Loyalty -- Infixo: this is not stored - try to store it for sorting later!
	local pCulturalIdentity = kCityData.City:GetCulturalIdentity();
	local currentLoyalty = pCulturalIdentity:GetLoyalty();
	local maxLoyalty = pCulturalIdentity:GetMaxLoyalty();
	local loyaltyPerTurn:number = pCulturalIdentity:GetLoyaltyPerTurn();
	local loyaltyFontIcon:string = loyaltyPerTurn >= 0 and "[ICON_PressureUp]" or "[ICON_PressureDown]";
	local iNumTurnsLoyalty:number = 0;
	if loyaltyPerTurn > 0 then
		iNumTurnsLoyalty = math.ceil((maxLoyalty-currentLoyalty)/loyaltyPerTurn);
		pCityInstance.Loyalty:SetText( loyaltyFontIcon.." "..toPlusMinusString(loyaltyPerTurn).."/"..( iNumTurnsLoyalty == 0 and tostring(iNumTurnsLoyalty) or ColorGreen(iNumTurnsLoyalty) ) );
	elseif loyaltyPerTurn < 0 then
		iNumTurnsLoyalty = math.ceil(currentLoyalty/(-loyaltyPerTurn));
		pCityInstance.Loyalty:SetText( loyaltyFontIcon.." "..ColorRed(toPlusMinusString(loyaltyPerTurn).."/"..iNumTurnsLoyalty) );
	else
		pCityInstance.Loyalty:SetText( loyaltyFontIcon.." 0" );
	end
	pCityInstance.Loyalty:SetToolTipString(loyaltyFontIcon .. " " .. Round(currentLoyalty, 1) .. "/" .. maxLoyalty);
	kCityData.Loyalty = currentLoyalty; -- Infixo: store for sorting
	kCityData.LoyaltyPerTurn = loyaltyPerTurn; -- Infixo: store for sorting

	-- Governor -- Infixo: this is not stored neither
	local pAssignedGovernor = kCityData.City:GetAssignedGovernor();
	if pAssignedGovernor then
		local eGovernorType = pAssignedGovernor:GetType();
		local governorDefinition = GameInfo.Governors[eGovernorType];
		local governorMode = pAssignedGovernor:IsEstablished() and "_FILL" or "_SLOT";
		local governorIcon = "ICON_" .. governorDefinition.GovernorType .. governorMode;
		pCityInstance.Governor:SetText("[" .. governorIcon .. "]");
		pCityInstance.Governor:SetToolTipString(Locale.Lookup(governorDefinition.Name)..", "..Locale.Lookup(governorDefinition.Title));
		kCityData.Governor = governorDefinition.GovernorType;
	else
		pCityInstance.Governor:SetText("");
		kCityData.Governor = "";
	end

end

function sort_cities( type, instance )

	local i = 0
	
	for _, kCityData in spairs( m_kCityData, function( t, a, b ) return city_sortFunction( instance.Descend, type, t, a, b ); end ) do
		i = i + 1
		local cityInstance = instance.Children[i]

		city_fields( kCityData, cityInstance )

		-- go to the city after clicking
		cityInstance.GoToCityButton:RegisterCallback( Mouse.eLClick, function() Close(); UI.LookAtPlot( kCityData.City:GetX(), kCityData.City:GetY() ); UI.SelectCity( kCityData.City ); end );
		cityInstance.GoToCityButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound( "Main_Menu_Mouse_Over" ); end );
	end
	
end

function city_sortFunction( descend, type, t, a, b )

	local aCity = 0
	local bCity = 0
	
	if type == "name" then
		aCity = Locale.Lookup( t[a].CityName )
		bCity = Locale.Lookup( t[b].CityName )
	elseif type == "gover" then
		aCity = t[a].Governor
		bCity = t[b].Governor
	elseif type == "loyal" then
		aCity = t[a].Loyalty
		bCity = t[b].Loyalty
	elseif type == "pop" then
		aCity = t[a].Population
		bCity = t[b].Population
		if aCity == bCity then -- same pop, sort by Housing
			aCity = t[a].Housing
			bCity = t[b].Housing
		end
	elseif type == "house" then -- Infixo: can leave it, will not be used
		aCity = t[a].Housing
		bCity = t[b].Housing
	elseif type == "amen" then
		aCity = t[a].AmenitiesNum
		bCity = t[b].AmenitiesNum
		if aCity == bCity then -- same amenities, sort by required
			aCity = t[a].AmenitiesRequiredNum
			bCity = t[b].AmenitiesRequiredNum
		end
	elseif type == "happy" then
		aCity = t[a].Happiness
		bCity = t[b].Happiness
		if aCity == bCity then -- same happiness, sort by difference in amenities
			aCity = t[a].AmenitiesNum - t[a].AmenitiesRequiredNum
			bCity = t[b].AmenitiesNum - t[b].AmenitiesRequiredNum
		end
	elseif type == "growth" then
		aCity = t[a].HousingMultiplier
		bCity = t[b].HousingMultiplier
	elseif type == "war" then
		aCity = t[a].AmenitiesLostFromWarWeariness
		bCity = t[b].AmenitiesLostFromWarWeariness
	elseif type == "status" then
		if t[a].IsUnderSiege == false then aCity = 10 else aCity = 20 end
		if t[b].IsUnderSiege == false then bCity = 10 else bCity = 20 end
	elseif type == "str" then
		aCity = t[a].Defense
		bCity = t[b].Defense
	elseif type == "dam" then
		aCity = t[a].Damage
		bCity = t[b].Damage
	elseif type == "districts" then
		aCity = t[a].NumDistricts
		bCity = t[b].NumDistricts
	end
	
	if descend then return bCity > aCity else return bCity < aCity end

end

function ViewCityStatusPage()	

	ResetTabForNewPageContent();

	local instance:table = m_simpleIM:GetInstance();
	instance.Top:DestroyAllChildren();
	
	instance.Children = {}
	instance.Descend = true
	
	local pHeaderInstance:table = {};
	ContextPtr:BuildInstanceForControl( "CityStatusHeaderInstance", pHeaderInstance, instance.Top );
	
	pHeaderInstance.CityNameButton:RegisterCallback( Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_cities( "name", instance ) end )
	if bIsRiseFall then pHeaderInstance.CityGovernorButton:RegisterCallback( Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_cities( "gover", instance ) end ) end -- Infixo
	if bIsRiseFall then pHeaderInstance.CityLoyaltyButton:RegisterCallback( Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_cities( "loyal", instance ) end ) end -- Infixo
	pHeaderInstance.CityPopulationButton:RegisterCallback( Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_cities( "pop", instance ) end )
	if not bIsRiseFall then pHeaderInstance.CityHousingButton:RegisterCallback( Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_cities( "house", instance ) end ) end -- Infixo
	pHeaderInstance.CityGrowthButton:RegisterCallback( Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_cities( "growth", instance ) end )
	pHeaderInstance.CityAmenitiesButton:RegisterCallback( Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_cities( "amen", instance ) end )
	pHeaderInstance.CityHappinessButton:RegisterCallback( Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_cities( "happy", instance ) end )
	--pHeaderInstance.CityWarButton:RegisterCallback( Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_cities( "war", instance ) end )
	pHeaderInstance.CityDistrictsButton:RegisterCallback( Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_cities( "districts", instance ) end )
	pHeaderInstance.CityStatusButton:RegisterCallback( Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_cities( "status", instance ) end )
	pHeaderInstance.CityStrengthButton:RegisterCallback( Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_cities( "str", instance ) end )
	pHeaderInstance.CityDamageButton:RegisterCallback( Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_cities( "dam", instance ) end )

	-- 
	for _, kCityData in spairs( m_kCityData, function( t, a, b ) return city_sortFunction( true, "name", t, a, b ); end ) do -- initial sort by name ascending

		local pCityInstance:table = {}

		ContextPtr:BuildInstanceForControl( "CityStatusEntryInstance", pCityInstance, instance.Top );
		table.insert( instance.Children, pCityInstance );
		
		city_fields( kCityData, pCityInstance );

		-- go to the city after clicking
		pCityInstance.GoToCityButton:RegisterCallback( Mouse.eLClick, function() Close(); UI.LookAtPlot( kCityData.City:GetX(), kCityData.City:GetY() ); UI.SelectCity( kCityData.City ); end );
		pCityInstance.GoToCityButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound( "Main_Menu_Mouse_Over" ); end );

	end

	Controls.Stack:CalculateSize();
	Controls.Scroll:CalculateSize();

	Controls.CollapseAll:SetHide( true );
	Controls.BottomYieldTotals:SetHide( true );
	Controls.BottomResourceTotals:SetHide( true );
	Controls.BottomPoliciesFilters:SetHide( true );
	Controls.Scroll:SetSizeY( Controls.Main:GetSizeY() - 88);
	-- Remember this tab when report is next opened: ARISTOS
	m_kCurrentTab = 3;
end


-- ===========================================================================
-- BRS NEW SECTION (UNITS)
-- ===========================================================================

function unit_sortFunction( descend, type, t, a, b )

	local aUnit = 0
	local bUnit = 0

	if type == "type" then
		aUnit = UnitManager.GetTypeName( t[a] )
		bUnit = UnitManager.GetTypeName( t[b] )
	elseif type == "name" then
		aUnit = Locale.Lookup( t[a]:GetName() )
		bUnit = Locale.Lookup( t[b]:GetName() )
	elseif type == "status" then
		aUnit = UnitManager.GetActivityType( t[a] )
		bUnit = UnitManager.GetActivityType( t[b] )
	elseif type == "level" then
		aUnit = t[a]:GetExperience():GetLevel()
		bUnit = t[b]:GetExperience():GetLevel()
	elseif type == "exp" then
		aUnit = t[a]:GetExperience():GetExperiencePoints()
		bUnit = t[b]:GetExperience():GetExperiencePoints()
	elseif type == "health" then
		aUnit = t[a]:GetMaxDamage() - t[a]:GetDamage()
		bUnit = t[b]:GetMaxDamage() - t[b]:GetDamage()
	elseif type == "move" then
		if ( t[a]:GetFormationUnitCount() > 1 ) then
			aUnit = t[a]:GetFormationMovesRemaining()
		else
			aUnit = t[a]:GetMovesRemaining()
		end
		
		if ( t[b]:GetFormationUnitCount() > 1 ) then
			bUnit = t[b]:GetFormationMovesRemaining()
		else
			bUnit = t[b]:GetMovesRemaining()
		end
	elseif type == "charge" then
		aUnit = t[a]:GetBuildCharges()
		bUnit = t[b]:GetBuildCharges()
	elseif type == "yield" then
		aUnit = t[a].yields
		bUnit = t[b].yields
	elseif type == "route" then
		aUnit = t[a].route
		bUnit = t[b].route
	elseif type == "class" then
		aUnit = t[a]:GetGreatPerson():GetClass()
		bUnit = t[b]:GetGreatPerson():GetClass()
	elseif type == "strength" then
		aUnit = t[a]:GetReligiousStrength()
		bUnit = t[b]:GetReligiousStrength()
	elseif type == "spread" then
		aUnit = t[a]:GetSpreadCharges()
		bUnit = t[b]:GetSpreadCharges()
	elseif type == "mission" then
		aUnit = t[a].mission
		bUnit = t[b].mission
	elseif type == "turns" then
		aUnit = t[a].turns
		bUnit = t[b].turns
	end
	
	if descend then return bUnit > aUnit else return bUnit < aUnit end
	
end

function sort_units( type, group, parent )

	local i = 0
	--local unit_group = m_kUnitData["Unit_Report"][group]
	local unit_group = m_kUnitDataReport[group]
	
	for _, unit in spairs( unit_group.units, function( t, a, b ) return unit_sortFunction( parent.Descend, type, t, a, b ) end ) do
		i = i + 1
		local unitInstance = parent.Children[i]
		
		common_unit_fields( unit, unitInstance )
		if unit_group.func then unit_group.func( unit, unitInstance, group, parent, type ) end
		
		unitInstance.LookAtButton:RegisterCallback( Mouse.eLClick, function() Close(); UI.LookAtPlot( unit:GetX( ), unit:GetY( ) ); UI.SelectUnit( unit ); end )
		unitInstance.LookAtButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound( "Main_Menu_Mouse_Over" ); end )
	end
	
end

function common_unit_fields( unit, unitInstance )

	if unitInstance.Formation then unitInstance.Formation:SetHide( true ) end

	local textureOffsetX:number, textureOffsetY:number, textureSheet:string = IconManager:FindIconAtlas( "ICON_" .. UnitManager.GetTypeName( unit ), 32 )
	unitInstance.UnitType:SetTexture( textureOffsetX, textureOffsetY, textureSheet )
	unitInstance.UnitType:SetToolTipString( Locale.Lookup( GameInfo.Units[UnitManager.GetTypeName( unit )].Name ) )

	unitInstance.UnitName:SetText( Locale.Lookup( unit:GetName() ) )
			
	-- adds the status icon
	local activityType:number = UnitManager.GetActivityType( unit )
	print("Unit", unit:GetID(),activityType,unit:GetSpyOperation(),unit:GetSpyOperationEndTurn());
	unitInstance.UnitStatus:SetHide( false )
	local bIsMoving:boolean = true; -- Infixo
	
	if activityType == ActivityTypes.ACTIVITY_SLEEP then
		local textureOffsetX:number, textureOffsetY:number, textureSheet:string = IconManager:FindIconAtlas( "ICON_STATS_SLEEP", 22 )
		unitInstance.UnitStatus:SetTexture( textureOffsetX, textureOffsetY, textureSheet )
		bIsMoving = false;
	elseif activityType == ActivityTypes.ACTIVITY_HOLD then
		local textureOffsetX:number, textureOffsetY:number, textureSheet:string = IconManager:FindIconAtlas( "ICON_STATS_SKIP", 22 )
		unitInstance.UnitStatus:SetTexture( textureOffsetX, textureOffsetY, textureSheet )
	elseif activityType ~= ActivityTypes.ACTIVITY_AWAKE and unit:GetFortifyTurns() > 0 then
		local textureOffsetX:number, textureOffsetY:number, textureSheet:string = IconManager:FindIconAtlas( "ICON_DEFENSE", 22 )
		unitInstance.UnitStatus:SetTexture( textureOffsetX, textureOffsetY, textureSheet )
		bIsMoving = false;
	else
		-- just use a random icon for sorting purposes
		local textureOffsetX:number, textureOffsetY:number, textureSheet:string = IconManager:FindIconAtlas( "ICON_STATS_SPREADCHARGES", 22 )
		unitInstance.UnitStatus:SetTexture( textureOffsetX, textureOffsetY, textureSheet )
		unitInstance.UnitStatus:SetHide( true )
	end
	if activityType == ActivityTypes.ACTIVITY_SENTRY then bIsMoving = false; end
	if unit:GetSpyOperation() ~= -1 then bIsMoving = false; end
	
	-- moves here to mark units that should move this turn
	if ( unit:GetFormationUnitCount() > 1 ) then
		unitInstance.UnitMove:SetText( tostring( unit:GetFormationMovesRemaining() ) .. "/" .. tostring( unit:GetFormationMaxMoves() ) )
		unitInstance.Formation:SetHide( false )
	elseif unitInstance.UnitMove then
		if unit:GetMovesRemaining() == 0 then bIsMoving = false; end
		unitInstance.UnitMove:SetText( (bIsMoving and "[COLOR_Red]" or "")..tostring( unit:GetMovesRemaining() ).."/"..tostring( unit:GetMaxMoves() )..(bIsMoving and "[ENDCOLOR]" or "") )
	end
			
end

function group_military( unit, unitInstance, group, parent, type )

	local unitExp : table = unit:GetExperience()
	
	unitInstance.Promotion:SetHide( true )
	unitInstance.Upgrade:SetHide( true )
				
	if ( unit:GetMilitaryFormation() == MilitaryFormationTypes.CORPS_FORMATION ) then
		unitInstance.UnitName:SetText( Locale.Lookup( unit:GetName() ) .. " " .. "[ICON_Corps]" )
	elseif ( unit:GetMilitaryFormation() == MilitaryFormationTypes.ARMY_FORMATION ) then
		unitInstance.UnitName:SetText( Locale.Lookup( unit:GetName() ) .. " " .. "[ICON_Army]" )
	end
			
	unitInstance.UnitLevel:SetText( tostring( unitExp:GetLevel() ) )
				
	unitInstance.UnitExp:SetText( tostring( unitExp:GetExperiencePoints() ) .. "/" .. tostring( unitExp:GetExperienceForNextLevel() ) )
	
	local bCanStart, tResults = UnitManager.CanStartCommand( unit, UnitCommandTypes.PROMOTE, true, true );
	
	if ( bCanStart and tResults ) then
		unitInstance.Promotion:SetHide( false )
		local tPromotions = tResults[UnitCommandResults.PROMOTIONS];
		unitInstance.Promotion:RegisterCallback( Mouse.eLClick, function() bUnits.group = group; bUnits.parent = parent; bUnits.type = type; LuaEvents.Report_PromoteUnit( unit ); end )
	end

	unitInstance.UnitHealth:SetText( tostring( unit:GetMaxDamage() - unit:GetDamage() ) .. "/" .. tostring( unit:GetMaxDamage() ) )
			
	local bCanStart, tResults = UnitManager.CanStartCommand( unit, UnitCommandTypes.UPGRADE, false, true);

	if ( bCanStart ) then
		unitInstance.Upgrade:SetHide( false )
		unitInstance.Upgrade:RegisterCallback( Mouse.eLClick, function() bUnits.group = group; bUnits.parent = parent; bUnits.type = type; UnitManager.RequestCommand( unit, UnitCommandTypes.UPGRADE ); end )
		local upgradeUnitName = GameInfo.Units[tResults[UnitOperationResults.UNIT_TYPE]].Name;
		local toolTipString	= Locale.Lookup( "LOC_UNITOPERATION_UPGRADE_DESCRIPTION" );
		toolTipString = toolTipString .. " " .. Locale.Lookup(upgradeUnitName);
		local upgradeCost = unit:GetUpgradeCost();
					
		if (upgradeCost ~= nil) then
			toolTipString = toolTipString .. ": " .. upgradeCost .. " " .. Locale.Lookup("LOC_TOP_PANEL_GOLD");
		end

		toolTipString = Locale.Lookup( "LOC_UNITOPERATION_UPGRADE_INFO", upgradeUnitName, upgradeCost );
					
		if (tResults[UnitOperationResults.FAILURE_REASONS] ~= nil) then
			-- Add the reason(s) to the tool tip
			for i,v in ipairs(tResults[UnitOperationResults.FAILURE_REASONS]) do
				toolTipString = toolTipString .. "[NEWLINE]" .. "[COLOR:Red]" .. Locale.Lookup(v) .. "[ENDCOLOR]";
			end
		end
						
		unitInstance.Upgrade:SetToolTipString( toolTipString )
	end
	
end

function group_civilian( unit, unitInstance, group, parent, type )

	unitInstance.UnitCharges:SetText( tostring( unit:GetBuildCharges() ) )
	
end

function group_great( unit, unitInstance, group, parent, type )

	unitInstance.UnitClass:SetText( Locale.Lookup( GameInfo.GreatPersonClasses[unit:GetGreatPerson():GetClass()].Name ) )

end

function group_religious( unit, unitInstance, group, parent, type )

	unitInstance.UnitSpreads:SetText( unit:GetSpreadCharges() )
	unitInstance.UnitStrength:SetText( unit:GetReligiousStrength() )

end

function group_spy( unit, unitInstance, group, parent, type )

	local operationType : number = unit:GetSpyOperation();
	
	unitInstance.UnitOperation:SetText( "None" )
	unitInstance.UnitTurns:SetText( "0" )
	unit.mission = "None"
	unit.turns = 0

	if ( operationType ~= -1 ) then
		-- Mission Name
		local operationInfo:table = GameInfo.UnitOperations[operationType];
		unitInstance.UnitOperation:SetText( Locale.Lookup( operationInfo.Description ) )

		-- Turns Remaining
		unitInstance.UnitTurns:SetText( Locale.Lookup( "LOC_UNITPANEL_ESPIONAGE_MORE_TURNS", unit:GetSpyOperationEndTurn() - Game.GetCurrentGameTurn() ) )
		
		unit.mission = Locale.Lookup( operationInfo.Description )
		unit.turns = unit:GetSpyOperationEndTurn() - Game.GetCurrentGameTurn()
	end

end

function group_trader( unit, unitInstance, group, parent, type )

	local owningPlayer:table = Players[unit:GetOwner()];
	local cities:table = owningPlayer:GetCities();
	local yieldtype : table = { ["YIELD_FOOD"] = "[ICON_Food]",
								["YIELD_PRODUCTION"] = "[ICON_Production]",
								["YIELD_GOLD"] = "[ICON_Gold]",
								["YIELD_SCIENCE"] = "[ICON_Science]",
								["YIELD_CULTURE"] = "[ICON_Culture]",
								["YIELD_FAITH"] = "[ICON_Faith]"
										  }
	local yields : string = ""
	
	unitInstance.UnitYields:SetText( "No Yields" )
	unitInstance.UnitRoute:SetText( "No Route" )
	unit.yields = "No Yields"
	unit.route = "No Route"

	for _, city in cities:Members() do
		local outgoingRoutes:table = city:GetTrade():GetOutgoingRoutes();
	
		for i,route in ipairs(outgoingRoutes) do
			if unit:GetID() == route.TraderUnitID then
				-- Find origin city
				local originCity:table = cities:FindID(route.OriginCityID);

				-- Find destination city
				local destinationPlayer:table = Players[route.DestinationCityPlayer];
				local destinationCities:table = destinationPlayer:GetCities();
				local destinationCity:table = destinationCities:FindID(route.DestinationCityID);

				-- Set origin to destination name
				if originCity and destinationCity then
					unitInstance.UnitRoute:SetText( Locale.Lookup("LOC_HUD_UNIT_PANEL_TRADE_ROUTE_NAME", originCity:GetName(), destinationCity:GetName()) )
					unit.route = Locale.Lookup("LOC_HUD_UNIT_PANEL_TRADE_ROUTE_NAME", originCity:GetName(), destinationCity:GetName())
				end

				for j, yieldInfo in pairs( route.OriginYields ) do
					if yieldInfo.Amount > 0 then
						local yieldDetails:table = GameInfo.Yields[yieldInfo.YieldIndex];
						yields = yields .. yieldtype[yieldDetails.YieldType] .. "+" .. yieldInfo.Amount
						unitInstance.UnitYields:SetText( yields )
						unit.yields = yields
					end
				end
			end
		end
	end
	
end


-- ===========================================================================
--	!! Start of Unit Report Page
-- ===========================================================================
function ViewUnitsPage()

	ResetTabForNewPageContent();
	
	--for iUnitGroup, kUnitGroup in spairs( m_kUnitData["Unit_Report"], function( t, a, b ) return t[b].ID > t[a].ID end ) do
	for iUnitGroup, kUnitGroup in spairs( m_kUnitDataReport, function( t, a, b ) return t[b].ID > t[a].ID end ) do
		local instance : table = NewCollapsibleGroupInstance()
		
		instance.RowHeaderButton:SetText( Locale.Lookup(kUnitGroup.Name) );
		instance.RowHeaderLabel:SetHide( false ); --BRS
		instance.RowHeaderLabel:SetText( Locale.Lookup("LOC_BRS_UNITS_GROUP_NUM_UNITS", #kUnitGroup.units) );
		
		local pHeaderInstance:table = {}
		ContextPtr:BuildInstanceForControl( kUnitGroup.Header, pHeaderInstance, instance.ContentStack )

		if pHeaderInstance.UnitTypeButton then     pHeaderInstance.UnitTypeButton:RegisterCallback(    Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_units( "type", iUnitGroup, instance ) end ) end
		if pHeaderInstance.UnitNameButton then     pHeaderInstance.UnitNameButton:RegisterCallback(    Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_units( "name", iUnitGroup, instance ) end ) end
		if pHeaderInstance.UnitStatusButton then   pHeaderInstance.UnitStatusButton:RegisterCallback(  Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_units( "status", iUnitGroup, instance ) end ) end
		if pHeaderInstance.UnitLevelButton then    pHeaderInstance.UnitLevelButton:RegisterCallback(   Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_units( "level", iUnitGroup, instance ) end ) end
		if pHeaderInstance.UnitExpButton then      pHeaderInstance.UnitExpButton:RegisterCallback(     Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_units( "exp", iUnitGroup, instance ) end ) end
		if pHeaderInstance.UnitHealthButton then   pHeaderInstance.UnitHealthButton:RegisterCallback(  Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_units( "health", iUnitGroup, instance ) end ) end
		if pHeaderInstance.UnitMoveButton then     pHeaderInstance.UnitMoveButton:RegisterCallback(    Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_units( "move", iUnitGroup, instance ) end ) end
		if pHeaderInstance.UnitChargeButton then   pHeaderInstance.UnitChargeButton:RegisterCallback(  Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_units( "charge", iUnitGroup, instance ) end ) end
		if pHeaderInstance.UnitYieldButton then    pHeaderInstance.UnitYieldButton:RegisterCallback(   Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_units( "yield", iUnitGroup, instance ) end ) end
		if pHeaderInstance.UnitRouteButton then    pHeaderInstance.UnitRouteButton:RegisterCallback(   Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_units( "route", iUnitGroup, instance ) end ) end
		if pHeaderInstance.UnitClassButton then    pHeaderInstance.UnitClassButton:RegisterCallback(   Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_units( "class", iUnitGroup, instance ) end ) end
		if pHeaderInstance.UnitStrengthButton then pHeaderInstance.UnitStrengthButton:RegisterCallback(Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_units( "strength", iUnitGroup, instance ) end ) end
		if pHeaderInstance.UnitSpreadButton then   pHeaderInstance.UnitSpreadButton:RegisterCallback(  Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_units( "spread", iUnitGroup, instance ) end ) end
		if pHeaderInstance.UnitMissionButton then  pHeaderInstance.UnitMissionButton:RegisterCallback( Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_units( "mission", iUnitGroup, instance ) end ) end
		if pHeaderInstance.UnitTurnsButton then    pHeaderInstance.UnitTurnsButton:RegisterCallback(   Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_units( "turns", iUnitGroup, instance ) end ) end

		for _,unit in ipairs( kUnitGroup.units ) do			
			local unitInstance:table = {}
			table.insert( instance.Children, unitInstance )
			
			ContextPtr:BuildInstanceForControl( kUnitGroup.Entry, unitInstance, instance.ContentStack )
			
			common_unit_fields( unit, unitInstance )
			
			if kUnitGroup.func then kUnitGroup.func( unit, unitInstance, iUnitGroup, instance ) end
			
			-- allows you to select a unit and zoom to them
			unitInstance.LookAtButton:RegisterCallback( Mouse.eLClick, function() Close(); UI.LookAtPlot( unit:GetX( ), unit:GetY( ) ); UI.SelectUnit( unit ); end )
			unitInstance.LookAtButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound( "Main_Menu_Mouse_Over" ); end )
		end
	
		local pFooterInstance:table = {}
		ContextPtr:BuildInstanceForControl( "UnitsFooterInstance", pFooterInstance, instance.ContentStack )
		pFooterInstance.Amount:SetText( tostring( #kUnitGroup.units ) )
	
		SetGroupCollapsePadding( instance, pFooterInstance.Top:GetSizeY() )
		RealizeGroup( instance )
	end

	Controls.Stack:CalculateSize();
	Controls.Scroll:CalculateSize();
	
	Controls.CollapseAll:SetHide( false );
	Controls.BottomYieldTotals:SetHide( true )
	Controls.BottomResourceTotals:SetHide( true )
	Controls.BottomPoliciesFilters:SetHide( true );
	Controls.Scroll:SetSizeY( Controls.Main:GetSizeY() - 88 )
	-- Remember this tab when report is next opened: ARISTOS
	m_kCurrentTab = 5;
end

-- ===========================================================================
--	!! End of Unit Report Page
-- ===========================================================================

-- ===========================================================================
--	!! Start of Deals Report Page
-- ===========================================================================
function ViewDealsPage()

	ResetTabForNewPageContent();
	
	for j, pDeal in spairs( m_kCurrentDeals, function( t, a, b ) return t[b].EndTurn > t[a].EndTurn end ) do
		local ending = pDeal.EndTurn - Game.GetCurrentGameTurn()
		local turns = "turns"
		if ending == 1 then turns = "turn" end

		local instance : table = NewCollapsibleGroupInstance()

		instance.RowHeaderButton:SetText( "Deal With " .. pDeal.WithCivilization )
		instance.RowHeaderLabel:SetText( "Ends in " .. ending .. " " .. turns .. " (" .. pDeal.EndTurn .. ")" )
		instance.RowHeaderLabel:SetHide( false )

		local dealHeaderInstance : table = {}
		ContextPtr:BuildInstanceForControl( "DealsHeader", dealHeaderInstance, instance.ContentStack )

		local iSlots = #pDeal.Sending

		if iSlots < #pDeal.Receiving then iSlots = #pDeal.Receiving end

		for i = 1, iSlots do
			local dealInstance : table = {}
			ContextPtr:BuildInstanceForControl( "DealsInstance", dealInstance, instance.ContentStack )
			table.insert( instance.Children, dealInstance )
		end

		for i, pDealItem in pairs( pDeal.Sending ) do
			if pDealItem.Icon then
				instance.Children[i].Outgoing:SetText( pDealItem.Icon .. " " .. pDealItem.Name )
			else
				instance.Children[i].Outgoing:SetText( pDealItem.Name )
			end
		end

		for i, pDealItem in pairs( pDeal.Receiving ) do
			if pDealItem.Icon then
				instance.Children[i].Incoming:SetText( pDealItem.Icon .. " " .. pDealItem.Name )
			else
				instance.Children[i].Incoming:SetText( pDealItem.Name )
			end
		end
	
		local pFooterInstance:table = {}
		ContextPtr:BuildInstanceForControl( "DealsFooterInstance", pFooterInstance, instance.ContentStack )
		pFooterInstance.Outgoing:SetText( "Total: " .. #pDeal.Sending )
		pFooterInstance.Incoming:SetText( "Total: " .. #pDeal.Receiving )
	
		SetGroupCollapsePadding( instance, pFooterInstance.Top:GetSizeY() )
		RealizeGroup( instance );
	end

	Controls.Stack:CalculateSize();
	Controls.Scroll:CalculateSize();

	Controls.CollapseAll:SetHide( false );
	Controls.BottomYieldTotals:SetHide( true );
	Controls.BottomResourceTotals:SetHide( true );
	Controls.BottomPoliciesFilters:SetHide( true );
	Controls.Scroll:SetSizeY( Controls.Main:GetSizeY() - 88);
	-- Remember this tab when report is next opened: ARISTOS
	m_kCurrentTab = 4;
end


-- ===========================================================================
-- POLICY PAGE
-- ===========================================================================

function UpdatePolicyData()
	-- prepare data
	-- this will be moved outside to be only calculated once
	m_kPolicyData = {
		SLOT_MILITARY = {},
		SLOT_ECONOMIC = {},
		SLOT_DIPLOMATIC = {},
		SLOT_GREAT_PERSON = {},
		SLOT_LEGACY = {},
		SLOT_DARKAGE = {},
	};
	Timer1Start();
	local ePlayerID:number = Game.GetLocalPlayer();
	local pPlayer:table = Players[ePlayerID];
	if not pPlayer then return; end -- assert
	local pPlayerCulture:table = pPlayer:GetCulture();
	-- find out which polices are slotted now
	local tSlottedPolicies:table = {};
	for i = 0, pPlayerCulture:GetNumPolicySlots()-1 do tSlottedPolicies[ pPlayerCulture:GetSlotPolicy(i) ] = true; end
	-- iterate through all policies
	for policy in GameInfo.Policies() do
		local policyData:table = {
			Index = policy.Index,
			Name = Locale.Lookup(policy.Name),
			Description = Locale.Lookup(policy.Description),
			--Yields from modifiers
			-- Status TODO from Player:GetCulture?
			IsActive = (pPlayerCulture:IsPolicyUnlocked(policy.Index) and not pPlayerCulture:IsPolicyObsolete(policy.Index)),
			IsSlotted = ((tSlottedPolicies[ policy.Index ] and true) or false),
		};
		local sSlotType:string = policy.GovernmentSlotType;
		if sSlotType == "SLOT_WILDCARD" then sSlotType = ((policy.RequiresGovernmentUnlock and "SLOT_LEGACY") or "SLOT_DARKAGE"); end
		table.insert(m_kPolicyData[sSlotType], policyData);
		-- policy impact from modifiers
		policyData.Impact, policyData.Yields, policyData.ImpactToolTip, policyData.UnknownEffect = RMA.CalculateModifierEffect("Policy", policy.PolicyType, ePlayerID, nil);
		policyData.IsImpact = false; -- for toggling options
		for _,value in pairs(policyData.Yields) do if value ~= 0 then policyData.IsImpact = true; break; end end
	end
	Timer1Tick("--- ALL POLICY DATA ---");
end

function ViewPolicyPage()

	ResetTabForNewPageContent();

	-- fill
	--for iUnitGroup, kUnitGroup in spairs( m_kUnitDataReport, function( t, a, b ) return t[b].ID > t[a].ID end ) do
	for policyGroup,policies in pairs(m_kPolicyData) do
		local instance : table = NewCollapsibleGroupInstance()
		
		instance.RowHeaderButton:SetText( Locale.Lookup("LOC_BRS_POLICY_GROUP_"..policyGroup) );
		instance.RowHeaderLabel:SetHide( false );
		
		local pHeaderInstance:table = {}
		ContextPtr:BuildInstanceForControl( "PolicyHeaderInstance", pHeaderInstance, instance.ContentStack ) -- instance ID, pTable, stack

		-- set sorting callbacks
		--if pHeaderInstance.UnitTypeButton then     pHeaderInstance.UnitTypeButton:RegisterCallback(    Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_units( "type", iUnitGroup, instance ) end ) end
		--if pHeaderInstance.UnitNameButton then     pHeaderInstance.UnitNameButton:RegisterCallback(    Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_units( "name", iUnitGroup, instance ) end ) end
		--if pHeaderInstance.UnitStatusButton then   pHeaderInstance.UnitStatusButton:RegisterCallback(  Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_units( "status", iUnitGroup, instance ) end ) end

		-- fill a single group
		local iNumPolices:number = 0;
		for _,policy in ipairs(policies) do
		
			--FILTERS
			if (not Controls.HideInactivePoliciesCheckbox:IsSelected() or policy.IsActive) and
				(not Controls.HideNoImpactPoliciesCheckbox:IsSelected() or policy.IsImpact) then
		
			local pPolicyInstance:table = {}
			--table.insert( instance.Children, unitInstance )
			
			ContextPtr:BuildInstanceForControl( "PolicyEntryInstance", pPolicyInstance, instance.ContentStack ) -- instance ID, pTable, stack
			iNumPolices = iNumPolices + 1;
			
			--common_unit_fields( unit, unitInstance ) -- fill a single entry
			-- status with tooltip
			local sStatusText:string;
			local sStatusToolTip:string = "Id "..tostring(policy.Index);
			if policy.IsActive then sStatusText = "[ICON_CheckSuccess]"; sStatusToolTip = sStatusToolTip.." Active policy";
			else                    sStatusText = "[ICON_CheckFail]";    sStatusToolTip = sStatusToolTip.." Inactive policy (obsolete or not yet unlocked)"; end
			if policy.UnknownEffect then
				sStatusText = sStatusText.." [ICON_Exclamation]";
				sStatusToolTip = sStatusToolTip.."[NEWLINE][COLOR_Red]Unknown effect[ENDCOLOR] was not processed.";
			end
			pPolicyInstance.PolicyEntryStatus:SetText(sStatusText);
			pPolicyInstance.PolicyEntryStatus:SetToolTipString(sStatusToolTip);
			-- name with description
			local sPolicyName:string = policy.Name;
			if policy.IsSlotted then sPolicyName = "[ICON_Checkmark]"..sPolicyName; end
			TruncateString(pPolicyInstance.PolicyEntryName, 178, sPolicyName); -- [ICON_Checkmark] [ICON_CheckSuccess] [ICON_CheckFail] [ICON_CheckmarkBlue]
			pPolicyInstance.PolicyEntryName:SetToolTipString(policy.Description);
			-- impact with modifiers
			TruncateString(pPolicyInstance.PolicyEntryImpact, 218, policy.Impact=="" and "[ICON_CheckmarkBlue]" or policy.Impact);
			pPolicyInstance.PolicyEntryImpact:SetToolTipString(policy.ImpactToolTip);
			-- fill out yields
			for yield,value in pairs(policy.Yields) do
				if value ~= 0 then pPolicyInstance["PolicyEntryYield"..yield]:SetText(toPlusMinusNoneString(value)); end
			end
			
			end -- FILTERS
			
		end
		
		instance.RowHeaderLabel:SetText( Locale.Lookup("LOC_BRS_POLICY_GROUP_NUM_POLICIES", iNumPolices) );
		
		-- no footer
		SetGroupCollapsePadding(instance, 0 );
		RealizeGroup( instance );
	end
	
	-- finishing
	Controls.Stack:CalculateSize();
	Controls.Scroll:CalculateSize();

	Controls.CollapseAll:SetHide( false );
	Controls.BottomYieldTotals:SetHide( true );
	Controls.BottomResourceTotals:SetHide( true );
	Controls.BottomPoliciesFilters:SetHide( false ); -- ViewPolicyPage
	Controls.Scroll:SetSizeY( Controls.Main:GetSizeY() - (Controls.BottomPoliciesFilters:GetSizeY() + SIZE_HEIGHT_PADDING_BOTTOM_ADJUST ) );	
	--Controls.Scroll:SetSizeY( Controls.Main:GetSizeY() - 88);
	-- Remember this tab when report is next opened: ARISTOS
	m_kCurrentTab = 6;
end


-- ===========================================================================
--
-- ===========================================================================
function AddTabSection( name:string, populateCallback:ifunction )
	local kTab		:table				= m_tabIM:GetInstance();	
	kTab.Button[DATA_FIELD_SELECTION]	= kTab.Selection;

	local callback	:ifunction	= function()
		if m_tabs.prevSelectedControl ~= nil then
			m_tabs.prevSelectedControl[DATA_FIELD_SELECTION]:SetHide(true);
		end
		kTab.Selection:SetHide(false);
		Timer1Start();
		populateCallback();
		Timer1Tick("Section "..Locale.Lookup(name).." populated");
	end

	kTab.Button:GetTextControl():SetText( Locale.Lookup(name) );
	kTab.Button:SetSizeToText( 0, 20 ); -- default 40,20
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
--	UI Event
-- ===========================================================================
function OnInit( isReload:boolean )
	if isReload then		
		if ContextPtr:IsHidden()==false then
			Open();
		end
	end
	m_tabs.AddAnimDeco(Controls.TabAnim, Controls.TabArrow);	
end


-- ===========================================================================
function Resize()
	local topPanelSizeY:number = 30;

	if m_debugFullHeight then
		x,y = UIManager:GetScreenSizeVal();
		Controls.Main:SetSizeY( y - topPanelSizeY );
		Controls.Main:SetOffsetY( topPanelSizeY * 0.5 );
	end
end

-- ===========================================================================
-- Checkboxes for hiding city details and free units/buildings

function OnToggleHideCityBuildings()
	local isChecked = Controls.HideCityBuildingsCheckbox:IsSelected();
	Controls.HideCityBuildingsCheckbox:SetSelected( not isChecked );
	ViewYieldsPage()
end

function OnToggleHideFreeBuildings()
	local isChecked = Controls.HideFreeBuildingsCheckbox:IsSelected();
	Controls.HideFreeBuildingsCheckbox:SetSelected( not isChecked );
	ViewYieldsPage()
end

function OnToggleHideFreeUnits()
	local isChecked = Controls.HideFreeUnitsCheckbox:IsSelected();
	Controls.HideFreeUnitsCheckbox:SetSelected( not isChecked );
	ViewYieldsPage()
end

-- ===========================================================================
-- Checkboxes for different resources in Resources tab

function OnToggleStrategic()
	local isChecked = Controls.StrategicCheckbox:IsSelected();
	Controls.StrategicCheckbox:SetSelected( not isChecked );
	ViewResourcesPage();
end

function OnToggleLuxury()
	local isChecked = Controls.LuxuryCheckbox:IsSelected();
	Controls.LuxuryCheckbox:SetSelected( not isChecked );
	ViewResourcesPage();
end

function OnToggleBonus()
	local isChecked = Controls.BonusCheckbox:IsSelected();
	Controls.BonusCheckbox:SetSelected( not isChecked );
	ViewResourcesPage();
end

-- ===========================================================================
-- Checkboxes for policy filters

function OnToggleInactivePolicies()
	local isChecked = Controls.HideInactivePoliciesCheckbox:IsSelected();
	Controls.HideInactivePoliciesCheckbox:SetSelected( not isChecked );
	ViewPolicyPage();
end

function OnToggleNoImpactPolicies()
	local isChecked = Controls.HideNoImpactPoliciesCheckbox:IsSelected();
	Controls.HideNoImpactPoliciesCheckbox:SetSelected( not isChecked );
	ViewPolicyPage();
end

-- ===========================================================================
function Initialize()

	Resize();	

	m_tabs = CreateTabs( Controls.TabContainer, 42, 34, 0xFF331D05 );
	--AddTabSection( "Test",								ViewTestPage );			--TRONSTER debug
	--AddTabSection( "Test2",								ViewTestPage );			--TRONSTER debug
	AddTabSection( "LOC_HUD_REPORTS_TAB_YIELDS",		ViewYieldsPage );
	AddTabSection( "LOC_HUD_REPORTS_TAB_RESOURCES",		ViewResourcesPage );
	AddTabSection( "LOC_HUD_REPORTS_TAB_CITY_STATUS",	ViewCityStatusPage );	
	AddTabSection( "LOC_HUD_REPORTS_TAB_DEALS",			ViewDealsPage );
	AddTabSection( "LOC_HUD_REPORTS_TAB_UNITS",			ViewUnitsPage );
	AddTabSection( "Policies",			ViewPolicyPage );

	m_tabs.SameSizedTabs(50);
	m_tabs.CenterAlignTabs(-10);		

	-- UI Callbacks
	ContextPtr:SetInitHandler( OnInit );
	ContextPtr:SetInputHandler( OnInputHandler, true );
	ContextPtr:SetRefreshHandler( function() if bUnits.group then m_kCityData, m_kCityTotalData, m_kResourceData, m_kUnitData, m_kDealData, m_kCurrentDeals, m_kUnitDataReport = GetData(); UpdatePolicyData(); sort_units( bUnits.type, bUnits.group, bUnits.parent ); end; end )
	
	Events.UnitPromoted.Add( function() LuaEvents.UnitPanel_HideUnitPromotion(); ContextPtr:RequestRefresh() end )
	Events.UnitUpgraded.Add( function() ContextPtr:RequestRefresh() end )

	Controls.CloseButton:RegisterCallback( Mouse.eLClick, OnCloseButton );
	Controls.CloseButton:RegisterCallback(	Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	Controls.CollapseAll:RegisterCallback( Mouse.eLClick, OnCollapseAllButton );
	Controls.CollapseAll:RegisterCallback(	Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);

	--BRS Yields tab toggle
	Controls.HideCityBuildingsCheckbox:RegisterCallback( Mouse.eLClick, OnToggleHideCityBuildings )
	Controls.HideCityBuildingsCheckbox:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end )
	Controls.HideCityBuildingsCheckbox:SetSelected( true );
	Controls.HideFreeBuildingsCheckbox:RegisterCallback( Mouse.eLClick, OnToggleHideFreeBuildings )
	Controls.HideFreeBuildingsCheckbox:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end )
	Controls.HideFreeBuildingsCheckbox:SetSelected( true );
	Controls.HideFreeUnitsCheckbox:RegisterCallback( Mouse.eLClick, OnToggleHideFreeUnits )
	Controls.HideFreeUnitsCheckbox:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end )
	Controls.HideFreeUnitsCheckbox:SetSelected( true );
	
	--ARISTOS: Resources toggle
	Controls.LuxuryCheckbox:RegisterCallback( Mouse.eLClick, OnToggleLuxury );
	Controls.LuxuryCheckbox:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end );
	Controls.LuxuryCheckbox:SetSelected( true );
	Controls.StrategicCheckbox:RegisterCallback( Mouse.eLClick, OnToggleStrategic );
	Controls.StrategicCheckbox:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end );
	Controls.StrategicCheckbox:SetSelected( true );
	Controls.BonusCheckbox:RegisterCallback( Mouse.eLClick, OnToggleBonus );
	Controls.BonusCheckbox:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end );
	Controls.BonusCheckbox:SetSelected( true );

	-- Polices Filters
	Controls.HideInactivePoliciesCheckbox:RegisterCallback( Mouse.eLClick, OnToggleInactivePolicies );
	Controls.HideInactivePoliciesCheckbox:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end );
	Controls.HideInactivePoliciesCheckbox:SetSelected( true );
	Controls.HideNoImpactPoliciesCheckbox:RegisterCallback( Mouse.eLClick, OnToggleNoImpactPolicies );
	Controls.HideNoImpactPoliciesCheckbox:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end );
	Controls.HideNoImpactPoliciesCheckbox:SetSelected( false );

	-- Events
	LuaEvents.TopPanel_OpenReportsScreen.Add( OnTopOpenReportsScreen );
	LuaEvents.TopPanel_CloseReportsScreen.Add( OnTopCloseReportsScreen );
end
Initialize();

print("OK loaded ReportScreen.lua from Better Report Screen");