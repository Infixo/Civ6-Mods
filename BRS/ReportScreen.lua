print("Loading ReportScreen.lua from Better Report Screen version "..GlobalParameters.BRS_VERSION_MAJOR.."."..GlobalParameters.BRS_VERSION_MINOR);
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

local bIsRiseFall:boolean = Modding.IsModActive("1B28771A-C749-434B-9053-D1380C553DE9"); -- Rise & Fall


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
local TOOLTIP_SEP								:string = "-------------------";
local TOOLTIP_SEP_NEWLINE						:string = "[NEWLINE]"..TOOLTIP_SEP.."[NEWLINE]";

--BRS !! Added function to sort out tables for units
-- Infixo: this is only used by Upgrade Callback; parent will be used a flag; must be set to nil when leaving report screen
local tUnitSort = { type = "", group = "", parent = nil };

-- Infixo: this is an iterator to replace pairs
-- it sorts t and returns its elements one by one
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
local m_kMinorData		:table = nil;
local m_kModifiers		:table = nil; -- to calculate yield per pop and other modifier-ralated effects on the city level
local m_kModifiersUnits	:table = nil; -- to show various abilities and effects
-- !!
-- Remember last tab variable: ARISTOS
m_kCurrentTab = 1;
-- !!

-- ===========================================================================
-- Time helpers and debug routines
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

-- ===========================================================================
--	Single exit point for display
-- ===========================================================================
function Close()
	if not ContextPtr:IsHidden() then
		UI.PlaySound("UI_Screen_Close");
	end

	UIManager:DequeuePopup(ContextPtr);
	LuaEvents.ReportScreen_Closed();
	--print("Closing... current tab is:", m_kCurrentTab);
	tUnitSort.parent = nil; -- unit upgrades off the report screen should not call re-sort
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
	LuaEvents.ReportScreen_Opened();

	-- BRS !! new line to add new variables 
	-- m_kCityData, m_kCityTotalData, m_kResourceData, m_kUnitData, m_kDealData = GetData();
	Timer2Start()
	m_kCityData, m_kCityTotalData, m_kResourceData, m_kUnitData, m_kDealData, m_kCurrentDeals, m_kUnitDataReport = GetData();
	UpdatePolicyData();
	UpdateMinorData();
	Timer2Tick("GetData")
	
	-- To remember the last opened tab when the report is re-opened: ARISTOS
	--m_tabs.SelectTab( 1 );
	m_tabs.SelectTab( m_kCurrentTab );
	
	-- show number of cities in the title bar
	Controls.TotalsLabel:SetText( Locale.Lookup("LOC_DIPLOMACY_DEAL_CITIES").." "..tostring(Players[Game.GetLocalPlayer()]:GetCities():GetCount()) );
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


-- REAL HOUSING FROM IMPROVEMENTS
-- Get the real housing from improvements, not rounded-down
-- The idea taken from CQUI, however CQUI's code is wrong(tested for vanilla and R&F) - the farm doesn't need to be worked, only created within borders
-- GetHousingFromImprovements() returns math.floor(), i.e. +0.5 is rounded to 0, must have 2 farms to get +1 housing

-- Some improvements provide more housing when a tech or civic is unlocked
-- this is done via modifiers, so we need to find them first (EFFECT_ADJUST_IMPROVEMENT_HOUSING)
-- STEPWELL_HOUSING_WITHTECH (REQUIREMENT_PLAYER_HAS_TECHNOLOGY) TechnologyType
-- GOLFCOURSE_HOUSING_WITHGLOBLIZATION (REQUIREMENT_PLAYER_HAS_CIVIC) CivicType
-- MEKEWAP_HOUSING_WITHCIVILSERVICE (REQUIREMENT_PLAYER_HAS_CIVIC)
-- All set via SubjectRequirementSetId
-- However, it is not clear if Amount=1 in modifier means +1 housing or +0.5 just as with base values
-- CQUI calculates as +1 in this case, seems that wiki also says that each of them gives +1

-- this table will hold Tech or Civic requirement for increased Housing
local tImprMoreHousingReqs:table = nil;

function PopulateImprMoreHousingReqs()
	--print("PopulateImprMoreHousingReqs");
	tImprMoreHousingReqs = {};
	for mod in GameInfo.ImprovementModifiers() do
		local tMod:table = RMA.FetchAndCacheData(mod.ModifierID); -- one of cases with upper case ID
		--print(mod.ImprovementType, "fetched", tMod.ModifierId, tMod.EffectType, tMod.SubjectReqSetId);
		if tMod and tMod.EffectType == "EFFECT_ADJUST_IMPROVEMENT_HOUSING" and tMod.SubjectReqSet then
			--dshowrectable(tMod);
			-- now extract requirement!
			for _,req in ipairs(tMod.SubjectReqSet.Reqs) do
				if req.ReqType == "REQUIREMENT_PLAYER_HAS_TECHNOLOGY" then
					tImprMoreHousingReqs[ mod.ImprovementType ] = { IsTech = true, Prereq = req.Arguments.TechnologyType, Amount = tonumber(tMod.Arguments.Amount) };
				elseif req.ReqType == "REQUIREMENT_PLAYER_HAS_CIVIC" then
					tImprMoreHousingReqs[ mod.ImprovementType ] = { IsTech = false, Prereq = req.Arguments.CivicType, Amount = tonumber(tMod.Arguments.Amount) };
				end
			end
		end
	end
	print("Found", table.count(tImprMoreHousingReqs), "improvements with additional Housing.");
	for k,v in pairs(tImprMoreHousingReqs) do print(k, v.IsTech, v.Prereq, v.Amount); end
end

function GetRealHousingFromImprovements(pCity:table)
	if tImprMoreHousingReqs == nil then PopulateImprMoreHousingReqs(); end -- do it once
	local iNumHousing:number = 0; -- we'll add data from Housing field in Improvements here BUT this is 0.5 actually per each, so the final number must by divided by 2
	for _,plotIndex in ipairs(Map.GetCityPlots():GetPurchasedPlots(pCity)) do
		local pPlot:table = Map.GetPlotByIndex(plotIndex);
		if pPlot and pPlot:GetImprovementType() > -1 and not pPlot:IsImprovementPillaged() then
			local imprInfo:table = GameInfo.Improvements[ pPlot:GetImprovementType() ];
			iNumHousing = iNumHousing + imprInfo.Housing; -- well, we can always add 0, right?
			-- now check if there's more with techs/civics
			-- this check is independent from base Housing: there could be an improvement that doesn't give housing as fresh but could later
			if tImprMoreHousingReqs[ imprInfo.ImprovementType ] then
				--print("ANALYZE WEIRD CASE", imprInfo.ImprovementType);
				local reqs:table = tImprMoreHousingReqs[ imprInfo.ImprovementType ];
				if reqs.IsTech then
					if Players[Game.GetLocalPlayer()]:GetTechs():HasTech( GameInfo.Technologies[reqs.Prereq].Index ) then iNumHousing = iNumHousing + 2 * reqs.Amount; end
				else
					if Players[Game.GetLocalPlayer()]:GetCulture():HasCivic( GameInfo.Civics[reqs.Prereq].Index ) then iNumHousing = iNumHousing + 2 * reqs.Amount; end
				end
			end
		end
	end
	return iNumHousing * 0.5;
end


function GetData()
	--print("FUN GetData() - start");
	
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
	local MaintenanceDiscountPerUnit:number = pTreasury:GetMaintDiscountPerUnit(); -- this will be used in 2 reports


	-- ==========================
	-- BRS !! this will use the m_kUnitDataReport to fill out player's unit info
	-- ==========================
	--print("FUN GetData() - unit data report");
	local tSupportedFormationClasses:table = { FORMATION_CLASS_CIVILIAN = true, FORMATION_CLASS_LAND_COMBAT = true, FORMATION_CLASS_NAVAL = true, FORMATION_CLASS_SUPPORT = true, FORMATION_CLASS_AIR = true };
	local kUnitDataReport:table = {};
	local group_name:string;
	local tUnitsDist:table = {}; -- temp table for calculating units' distance from cities

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
		-- tweak to handle new, unknown formation classes
		if not tSupportedFormationClasses[formationClass] then
			print("WARNING: GetData Unknown formation class", formationClass, "for unit", unitInfo.UnitType);
			group_name = "SUPPORT";
		end
		-- store for Units tab report
		if kUnitDataReport[group_name] == nil then
			if     group_name == "LAND_COMBAT" then  kUnitDataReport[group_name] = { ID= 1, func= group_military, Header= "UnitsMilitaryHeaderInstance",   Entry= "UnitsMilitaryEntryInstance" };
			elseif group_name == "NAVAL" then        kUnitDataReport[group_name] = { ID= 2, func= group_military, Header= "UnitsMilitaryHeaderInstance",   Entry= "UnitsMilitaryEntryInstance" };
			elseif group_name == "AIR" then          kUnitDataReport[group_name] = { ID= 3, func= group_military, Header= "UnitsMilitaryHeaderInstance",   Entry= "UnitsMilitaryEntryInstance" };
			elseif group_name == "SUPPORT" then      kUnitDataReport[group_name] = { ID= 4, func= group_military, Header= "UnitsMilitaryHeaderInstance",   Entry= "UnitsMilitaryEntryInstance" };
			elseif group_name == "CIVILIAN" then     kUnitDataReport[group_name] = { ID= 5, func= group_civilian, Header= "UnitsCivilianHeaderInstance",   Entry= "UnitsCivilianEntryInstance" };
			elseif group_name == "RELIGIOUS" then    kUnitDataReport[group_name] = { ID= 6, func= group_religious,Header= "UnitsReligiousHeaderInstance",  Entry= "UnitsReligiousEntryInstance" };
			elseif group_name == "GREAT_PERSON" then kUnitDataReport[group_name] = { ID= 7, func= group_great,    Header= "UnitsGreatPeopleHeaderInstance",Entry= "UnitsGreatPeopleEntryInstance" };
			elseif group_name == "SPY" then          kUnitDataReport[group_name] = { ID= 8, func= group_spy,      Header= "UnitsSpyHeaderInstance",        Entry= "UnitsSpyEntryInstance" };
			elseif group_name == "TRADER" then       kUnitDataReport[group_name] = { ID= 9, func= group_trader,   Header= "UnitsTraderHeaderInstance",     Entry= "UnitsTraderEntryInstance" };
			end
			--print("...creating a new unit group", formationClass, group_name);
			kUnitDataReport[group_name].Name = "LOC_BRS_UNITS_GROUP_"..group_name;
			kUnitDataReport[group_name].units = {};
		end
		table.insert( kUnitDataReport[group_name].units, unit );
		-- add some unit specific data
		unit.MaintenanceAfterDiscount = math.max(GetUnitMaintenance(unit) - MaintenanceDiscountPerUnit, 0); -- cannot go below 0
		-- store data for distance calculations
		unit.NearCityDistance = 9999;
		unit.NearCityName = "";
		unit.NearCityIsCapital = false;
		unit.NearCityIsOurs = true;
		table.insert( tUnitsDist, unit );
	end
	
	-- calculate distance to the closest city for all units
	-- must iterate through all living players and their cities
	for _,player in ipairs(PlayerManager.GetAlive()) do
		local bIsOurs:boolean = ( player:GetID() == playerID );
		for _,city in player:GetCities():Members() do
			local iCityX:number, iCityY:number = city:GetX(), city:GetY();
			local sCityName:string = Locale.Lookup( city:GetName() );
			local bIsCapital:boolean = city:IsCapital();
			for _,unit in ipairs(tUnitsDist) do
				local iDistance:number = Map.GetPlotDistance( unit:GetX(), unit:GetY(), iCityX, iCityY );
				if iDistance < unit.NearCityDistance then
					unit.NearCityDistance = iDistance;
					unit.NearCityName = sCityName;
					unit.NearCityIsCapital = bIsCapital;
					unit.NearCityIsOurs = bIsOurs;
				end
			end
		end
	end
	
	-- ==========================
	-- !! end of edit
	-- ==========================		
	
	-----------------------------------
	-- MODIFIERS
	-- scan only once, select those for a) player's cities b) with desired effects
	-- store in a similar fashion as city data i.e. indexed by CityName
	-- on a city level a simple table, each entry contains:
	-- .ID - instance ID from GameEffects.GetModifiers
	-- .Active - boolean, as returned by GameEffects.GetModifierActive
	-- .Definition - table, as returned by GameEffects.GetModifierDefinition
	-- .Arguments - table, reference to .Arguments from .Definition (easy access)
	-- .OwnerType, .OwnerName - strings, as returned by GameEffects.GetObjectType and GetObjectName - for debug
	-- .Modifier - static as returned by RMA.FetchAndCacheData
	-----------------------------------
	--print("FUN GetData() - modifiers");
	m_kModifiers = {}; -- clear main table
	m_kModifiersUnits ={}; -- clear main table
	local sTrackedPlayer:string = PlayerConfigurations[playerID]:GetLeaderName(); -- LOC_LEADER_xxx_NAME
	--print("Tracking player", sTrackedPlayer); -- debug
	--[[ not used
	local tTrackedEffects:table = {
		EFFECT_ADJUST_CITY_YIELD_CHANGE = true, -- all listed as Modifiers in CityPanel
		EFFECT_ADJUST_CITY_YIELD_MODIFIER = true, -- e.g. governor's +20%, Wonders use it, some beliefs
		EFFECT_ADJUST_CITY_YIELD_PER_POPULATION = true, -- e.g. Theocracy and Communism
		EFFECT_ADJUST_CITY_YIELD_PER_DISTRICT = true, -- e.g. Democtratic Legacy +2 Production per district
		EFFECT_ADJUST_FOLLOWER_YIELD_MODIFIER = true, -- Work Ethic belief +1% Production; use the number of followers of the majority religion in the city
		--EFFECT_ADJUST_CITY_YIELD_FROM_FOREIGN_TRADE_ROUTES_PASSING_THROUGH = true, -- unknown
	};
	--]]
	--for k,v in pairs(tTrackedEffects) do print(k,v); end -- debug
	local tTrackedOwners:table = {};
	for _,city in player:GetCities():Members() do
		tTrackedOwners[ city:GetName() ] = true;
		m_kModifiers[ city:GetName() ] = {}; -- we need al least empty table for each city
	end
	local tTrackedUnits:table = {};
	for _,unit in player:GetUnits():Members() do
		tTrackedUnits[ unit:GetID() ] = true;
		m_kModifiersUnits[ unit:GetID() ] = {};
	end
	--for k,v in pairs(tTrackedOwners) do print(k,v); end -- debug
	-- main loop
	for _,instID in ipairs(GameEffects.GetModifiers()) do
		local iOwnerID:number = GameEffects.GetModifierOwner( instID );
		local iPlayerID:number = GameEffects.GetObjectsPlayerId( iOwnerID );
		local sOwnerType:string = GameEffects.GetObjectType( iOwnerID ); -- LOC_MODIFIER_OBJECT_CITY, LOC_MODIFIER_OBJECT_PLAYER, LOC_MODIFIER_OBJECT_GOVERNOR
		local sOwnerName:string = GameEffects.GetObjectName( iOwnerID ); -- LOC_CITY_xxx_NAME, LOC_LEADER_xxx_NAME, etc.
		local tSubjects:table = GameEffects.GetModifierSubjects( instID ); -- table of objectIDs or nil
		--print("checking", instID, sOwnerName, sOwnerType, iOwnerID, iPlayerID); -- debug
		
		local instdef:table = GameEffects.GetModifierDefinition(instID);
		local data:table = {
			ID = instID,
			Active = GameEffects.GetModifierActive(instID), -- should always be true? but check to be safe
			Definition = instdef, -- .Id has the static name
			Arguments = instdef.Arguments, -- same structure as static, Name = Value
			OwnerType = sOwnerType,
			OwnerName = sOwnerName,
			SubjectType = nil, -- will be filled for modifiers taken from Subjects
			SubjectName = nil, -- will be filled for modifiers taken from Subjects
			UnitID = nil, -- will be used only for units' modifiers
			Modifier = RMA.FetchAndCacheData(instdef.Id),
		};
		
		local function RegisterModifierForCity(sSubjectType:string, sSubjectName:string)
			--print("registering for city", data.ID, sSubjectType, sSubjectName);
			-- fix for sudden changes in modifier system, like Veterancy changed in March 2018 patch
			-- some modifiers might be removed, but still are attached to objects from old games
			-- the game itself seems to be resistant to such situation
			if data.Modifier == nil then print("WARNING! GetData/Modifiers: Ignoring non-existing modifier", data.ID, data.Definition.Id, sOwnerName, sSubjectName); return end
			if sSubjectType == nil or sSubjectName == nil then
				data.SubjectType = nil;
				data.SubjectName = nil;
				table.insert(m_kModifiers[sOwnerName], data);
			else -- register as subject
				data.SubjectType = sSubjectType;
				data.SubjectName = sSubjectName;
				table.insert(m_kModifiers[sSubjectName], data);
			end
			-- debug output
			--print("--------- Tracking", data.ID, sOwnerType, sOwnerName, sSubjectName);
			--for k,v in pairs(data) do print(k,v); end
			--print("- Modifier:", data.Definition.Id);
			--print("- Collection:", data.Modifier.CollectionType);
			--print("- Effect:", data.Modifier.EffectType);
			--print("- Arguments:");
			--for k,v in pairs(data.Arguments) do print(k,v); end -- debug
		end

		local function RegisterModifierForUnit(iUnitID:number, sSubjectType:string, sSubjectName:string)
			--print("registering for unit", iUnitID, data.ID, sSubjectType, sSubjectName);
			-- fix for sudden changes in modifier system, like Veterancy changed in March 2018 patch
			-- some modifiers might be removed, but still are attached to objects from old games
			-- the game itself seems to be resistant to such situation
			if data.Modifier == nil then print("WARNING! GetData/Modifiers: Ignoring non-existing modifier", data.ID, data.Definition.Id, sOwnerName, sSubjectName); return end
			data.UnitID = iUnitID;
			if sSubjectType == nil or sSubjectName == nil then
				data.SubjectType = nil;
				data.SubjectName = nil;
			else -- register as subject
				data.SubjectType = sSubjectType;
				data.SubjectName = sSubjectName;
			end
			table.insert(m_kModifiersUnits[iUnitID], data);
			-- debug output
			--print("--------- Tracking", iUnitID, data.ID, sOwnerType, sOwnerName, sSubjectName);
			--for k,v in pairs(data) do print(k,v); end
			--print("- Modifier:", data.Definition.Id);
			--print("- Collection:", data.Modifier.CollectionType);
			--print("- Effect:", data.Modifier.EffectType);
			--print("- Arguments:");
			--for k,v in pairs(data.Arguments) do print(k,v); end -- debug
		end
		
		-- this part is for modifiers attached directly to the city (COLLECTION_OWNER)
		if tTrackedOwners[ sOwnerName ] then
			RegisterModifierForCity(); -- City is owner
		end
		
		-- this part is for modifiers attached to the player
		-- we need to analyze Subjects (COLLECTION_PLAYER_CITIES, COLLECTION_PLAYER_CAPITAL_CITY)
		-- GetModifierTrackedObjects gives all Subjects, but GetModifierSubjects gives only those with met requirements!
		if sOwnerType == "LOC_MODIFIER_OBJECT_PLAYER" and sOwnerName == sTrackedPlayer and tSubjects then
			for _,subjectID in ipairs(tSubjects) do
				local sSubjectType:string = GameEffects.GetObjectType( subjectID ); -- LOC_MODIFIER_OBJECT_CITY, LOC_MODIFIER_OBJECT_PLAYER, LOC_MODIFIER_OBJECT_GOVERNOR
				local sSubjectName:string = GameEffects.GetObjectName( subjectID ); -- LOC_CITY_xxx_NAME, LOC_LEADER_xxx_NAME, etc.
				if sSubjectType == "LOC_MODIFIER_OBJECT_CITY" and tTrackedOwners[sSubjectName] then RegisterModifierForCity(sSubjectType, sSubjectName); end
			end
		end
		
		-- this part is for modifiers attached to Districts
		-- we process all districts, but sOwnerName contains DistrictName if necessary LOC_DISTRICT_xxx_NAME
		-- for each there is always a set of Subjects, even if only 1 for a singular effect
		-- those subjects can be LOC_MODIFIER_OBJECT_DISTRICT or LOC_MODIFIER_OBJECT_PLOT_YIELDS
		-- then we need to find its City, which is stupidly hidden in a description string "District: districtID, Owner: playerID, City: cityID"
		if iPlayerID == playerID and sOwnerType == "LOC_MODIFIER_OBJECT_DISTRICT" and tSubjects then
			for _,subjectID in ipairs(tSubjects) do
				local sSubjectType:string = GameEffects.GetObjectType( subjectID );
				local sSubjectName:string = GameEffects.GetObjectName( subjectID );
				if sSubjectType == "LOC_MODIFIER_OBJECT_DISTRICT" then
					-- find a city
					local sSubjectString:string = GameEffects.GetObjectString( subjectID );
					local iCityID:number = tonumber( string.sub(sSubjectString, string.find(sSubjectString, "City:")+6) );
					--print("city:", sSubjectString, "decode:", iCityID)
					if iCityID ~= nil then
						local pCity:table = player:GetCities():FindID(iCityID);
						if pCity and tTrackedOwners[pCity:GetName()] then RegisterModifierForCity(sSubjectType, pCity:GetName()); end
					end
				end
			end
		end
		
		-- this part is for units as owners, we need to decode the unit and see if it's ours
		if sOwnerType == "LOC_MODIFIER_OBJECT_UNIT" then
			-- find a unit
			local sOwnerString:string = GameEffects.GetObjectString( iOwnerID );
			local iUnitID:number      = tonumber( string.sub(sOwnerString, string.find(sOwnerString,"Unit:")+6,  string.find(sOwnerString,", Owner:")-1) );
			local iUnitOwnerID:number = tonumber( string.sub(sOwnerString, string.find(sOwnerString,"Owner:")+7, string.find(sOwnerString,", Type")-1) );
			--print("unit:", sOwnerString, "decode:", iUnitOwnerID, iUnitID)
			if iUnitID and iUnitOwnerID and iUnitOwnerID == playerID and tTrackedUnits[iUnitID] then
				RegisterModifierForUnit(iUnitID);
			end
		end
		
		-- this part is for units as subjects; to make it more unified it will simply analyze all subjects' sets
		if tSubjects then
			for _,subjectID in ipairs(tSubjects) do
				local sSubjectType:string = GameEffects.GetObjectType( subjectID );
				local sSubjectName:string = GameEffects.GetObjectName( subjectID );
				if sSubjectType == "LOC_MODIFIER_OBJECT_UNIT" then
					-- find a unit
					local sSubjectString:string = GameEffects.GetObjectString( subjectID );
					local iUnitID:number      = tonumber( string.sub(sSubjectString, string.find(sSubjectString,"Unit:")+6,  string.find(sSubjectString,", Owner:")-1) );
					local iUnitOwnerID:number = tonumber( string.sub(sSubjectString, string.find(sSubjectString,"Owner:")+7, string.find(sSubjectString,", Type")-1) );
					if iUnitID and iUnitOwnerID and iUnitOwnerID == playerID and tTrackedUnits[iUnitID] then
						RegisterModifierForUnit(iUnitID, sSubjectType, sSubjectName);
					end
				end -- unit
			end -- subjects
		end
		
	end
	--print("--------------"); print("FOUND MODIFIERS FOR CITIES"); for k,v in pairs(m_kModifiers) do print(k, #v); end
	--print("--------------"); print("FOUND MODIFIERS FOR UNITS"); for k,v in pairs(m_kModifiersUnits) do print(k, #v); end

	--print("FUN GetData() - cities");
	local pCities = player:GetCities();
	for i, pCity in pCities:Members() do	
		local cityName	:string = pCity:GetName();
			
		-- Big calls, obtain city data and add report specific fields to it.
		local data		:table	= GetCityData( pCity );
		data.Resources			= GetCityResourceData( pCity ); -- Add more data (not in CitySupport)			
		data.WorkedTileYields, data.NumWorkedTiles, data.SpecialistYields, data.NumSpecialists = GetWorkedTileYieldData( pCity, pCulture );	-- Add more data (not in CitySupport)

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
		data.IncomingRoutes = pCity:GetTrade():GetIncomingRoutes();

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
		
		-- Modifiers
		data.Modifiers = m_kModifiers[ cityName ]; -- just a reference to the main table
		
		-- real housing from improvements
		data.RealHousingFromImprovements = GetRealHousingFromImprovements(pCity);
		
		-- number of followers of the main religion
		data.MajorityReligionFollowers = 0;
		local eDominantReligion:number = pCity:GetReligion():GetMajorityReligion();
		if eDominantReligion > 0 then -- WARNING! this rules out pantheons!
			for _, religionData in pairs(pCity:GetReligion():GetReligionsInCity()) do
				if religionData.Religion == eDominantReligion then data.MajorityReligionFollowers = religionData.Followers; end
			end
		end
		--print("Majority religion followers for", cityName, data.MajorityReligionFollowers);
		
		-- Garrison in a city
		data.IsGarrisonUnit = false;
		local pPlotCity:table = Map.GetPlot( pCity:GetX(), pCity:GetY() );
		for _,unit in ipairs(Units.GetUnitsInPlot(pPlotCity)) do
			if GameInfo.Units[ unit:GetUnitType() ].FormationClass == "FORMATION_CLASS_LAND_COMBAT" then
				data.IsGarrisonUnit = true;
				data.GarrisonUnitName = Locale.Lookup( unit:GetName() );
				break;
			end
		end
		
		-- count all districts and specialty ones
		data.NumDistricts = 0;
		data.NumSpecialtyDistricts = 0
		for _,district in pCity:GetDistricts():Members() do
			local districtInfo:table = GameInfo.Districts[ district:GetType() ];
			if district:IsComplete() and not districtInfo.CityCenter and                             districtInfo.DistrictType ~= "DISTRICT_WONDER" then
				data.NumDistricts = data.NumDistricts + 1;
			end
			if district:IsComplete() and not districtInfo.CityCenter and districtInfo.OnePerCity and districtInfo.DistrictType ~= "DISTRICT_WONDER" then
				data.NumSpecialtyDistricts = data.NumSpecialtyDistricts + 1;
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
		
		-- Growth and related data
		-- This part of code is from CityPanelOverview.lua, retrofitted to use here (it uses data as prepared by CitySupport.lua)
		-- line 1, data.FoodPerTurn
		data.FoodConsumption = -(data.FoodPerTurn - data.FoodSurplus); -- line 2, it will be always negative!
		-- line 3, data.FoodSurplus
		-- line 4, data.HappinessGrowthModifier
		-- line 5, data.OccupationMultiplier
		data.FoodPerTurnModified = 0; -- line 6, modified food per turn [=line3 * (1+line4+line5)
		-- line 7, data.HousingMultiplier
		-- line 8a vanilla, data.OccupationMultiplier
		-- line 8b ris&fal, loyalty calculated
		data.TotalFoodSurplus = 0; -- line 9, as displayed in City Details
		-- line 10, data.TurnsUntilGrowth
		-- growth changes related to Loyalty
		if bIsRiseFall then
			data.LoyaltyGrowthModifier = Round( 100 * pCity:GetGrowth():GetLoyaltyGrowthModifier() - 100, 0 );
			data.LoyaltyLevelName = GameInfo.LoyaltyLevels[ pCity:GetCulturalIdentity():GetLoyaltyLevel() ].Name;
		end
		
		local tGrowthTT:table = {}; -- growth tooltip
		local function AddGrowthToolTip(sText:string, fValue:number, sSuffix:string)
			if fValue then table.insert(tGrowthTT, Locale.Lookup(sText)..": "..toPlusMinusString(fValue)..(sSuffix and sSuffix or ""));
			else           table.insert(tGrowthTT, Locale.Lookup(sText)..": "..Locale.Lookup("LOC_HUD_CITY_NOT_APPLICABLE")); end
		end
		local function AddGrowthToolTipSeparator()
			table.insert(tGrowthTT, "----------");
		end

		AddGrowthToolTip("LOC_HUD_CITY_FOOD_PER_TURN", data.FoodPerTurn); -- line 1: food per turn
		AddGrowthToolTip("LOC_HUD_CITY_FOOD_CONSUMPTION", data.FoodConsumption); -- line 2: food consumption
		AddGrowthToolTipSeparator();
		AddGrowthToolTip("LOC_HUD_CITY_GROWTH_FOOD_PER_TURN", data.FoodSurplus); -- line 3: food growth per turn

		if data.TurnsUntilGrowth > -1 then
			-- GROWTH IN: Set bonuses and multipliers
			AddGrowthToolTip("LOC_HUD_CITY_HAPPINESS_GROWTH_BONUS", Round(data.HappinessGrowthModifier, 0), "%"); -- line 4: amenities (happiness) growth bonus
			AddGrowthToolTip("LOC_HUD_CITY_OTHER_GROWTH_BONUSES", Round(data.OtherGrowthModifiers * 100, 0), "%"); -- line 5: other growth bonuses
			AddGrowthToolTipSeparator();
			local growthModifier =  math.max(1 + (data.HappinessGrowthModifier/100) + data.OtherGrowthModifiers, 0); -- This is unintuitive but it's in parity with the logic in City_Growth.cpp
			data.FoodPerTurnModified = Round(data.FoodSurplus * growthModifier, 2); -- line 6
			AddGrowthToolTip("LOC_HUD_CITY_MODIFIED_GROWTH_FOOD_PER_TURN", data.FoodPerTurnModified); -- line 6: modified food per turn
			table.insert(tGrowthTT, Locale.Lookup("LOC_HUD_CITY_HOUSING_MULTIPLIER")..": "..data.HousingMultiplier); -- line 7: housing multiplier
			data.TotalFoodSurplus = data.FoodPerTurnModified * data.HousingMultiplier;
			-- occupied
			if data.Occupied then data.TotalFoodSurplus = data.FoodPerTurnModified * data.OccupationMultiplier; end
			AddGrowthToolTip("LOC_HUD_CITY_OCCUPATION_MULTIPLIER", (data.Occupied and data.OccupationMultiplier * 100) or nil, "%"); -- line 8a
			if bIsRiseFall then
				if data.LoyaltyGrowthModifier ~= 0 then AddGrowthToolTip(data.LoyaltyLevelName, data.LoyaltyGrowthModifier, "%"); -- line 8b
				else table.insert(tGrowthTT, Locale.Lookup(data.LoyaltyLevelName)..": "..Locale.Lookup("LOC_CULTURAL_IDENTITY_LOYALTY_NO_GROWTH_PENALTY")); end -- line 8b
			end
			AddGrowthToolTipSeparator();
			-- final
			AddGrowthToolTip("LOC_HUD_CITY_TOTAL_FOOD_SURPLUS", data.TotalFoodSurplus, (data.TotalFoodSurplus > 0 and "[ICON_FoodSurplus]") or "[ICON_FoodDeficit]"); -- line 9
			if data.Occupied then AddGrowthToolTip("LOC_HUD_CITY_GROWTH_OCCUPIED"); -- line 10, occupied: no growth
			else table.insert(tGrowthTT, Locale.Lookup("LOC_HUD_CITY_TURNS_UNTIL_CITIZEN_BORN", math.abs(data.TurnsUntilGrowth))); end -- line 10
		else
			-- CITIZEN LOST IN: In a deficit, no bonuses or multipliers apply
			AddGrowthToolTip("LOC_HUD_CITY_HAPPINESS_GROWTH_BONUS"); -- line 4: amenities (happiness) growth bonus
			AddGrowthToolTip("LOC_HUD_CITY_OTHER_GROWTH_BONUSES"); -- line 5: other growth bonuses
			AddGrowthToolTipSeparator();
			data.FoodPerTurnModified = data.FoodSurplus; -- line 6
			AddGrowthToolTip("LOC_HUD_CITY_MODIFIED_GROWTH_FOOD_PER_TURN", data.FoodPerTurnModified); -- line 6: modified food per turn
			AddGrowthToolTip("LOC_HUD_CITY_HOUSING_MULTIPLIER"); -- line 7: housing multiplier
			AddGrowthToolTip("LOC_HUD_CITY_OCCUPATION_MULTIPLIER", (data.Occupied and data.OccupationMultiplier * 100) or nil, "%"); -- line 8a
			if bIsRiseFall then AddGrowthToolTip(data.LoyaltyLevelName); end -- line 8b
			AddGrowthToolTipSeparator();
			data.TotalFoodSurplus = data.FoodPerTurnModified; -- line 9
			AddGrowthToolTip("LOC_HUD_CITY_TOTAL_FOOD_DEFICIT", data.TotalFoodSurplus, "[ICON_FoodDeficit]"); -- line 9
			table.insert(tGrowthTT, "[Color:StatBadCS]"..string.upper(Locale.Lookup("LOC_HUD_CITY_STARVING")).."[ENDCOLOR]"); -- starving marker
			table.insert(tGrowthTT, Locale.Lookup("LOC_HUD_CITY_TURNS_UNTIL_CITIZEN_LOST", math.abs(data.TurnsUntilGrowth))); -- line 10
		end	
		
		data.TotalFoodSurplusToolTip = table.concat(tGrowthTT, "[NEWLINE]");

	end -- for Cities:Members

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
	--print("FUN GetData() - units");
	--local MaintenanceDiscountPerUnit:number = pTreasury:GetMaintDiscountPerUnit(); -- used also for Units tab, so defined earlier
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
	--print("FUN GetData() - deals");
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
								deal.Name = deal.Amount.." "..Locale.Lookup("LOC_DIPLOMACY_DEAL_GOLD_PER_TURN");
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
								deal.Name = deal.Amount.." "..Locale.Lookup("LOC_DIPLOMACY_DEAL_GOLD_PER_TURN");
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
-- Infixo: again, original function is incomplete, the game uses a different algorithm
-- 1. Get info about all tiles and citizens from CityManager.GetCommandTargets
-- 2. If the plot is worked then
--    2a. if it is a District then Yield = NumSpecs * District_CitizenYieldChanges.YieldChange
--    2b. if it is NOT a District then Yield = plot:GetYield()
-- I will break it into 2 rows, "Worked Tiles" and "Specialists" to avoid confusion
-- ===========================================================================
function GetWorkedTileYieldData( pCity:table, pCulture:table )
	-- return data
	local kYields:table     = { YIELD_PRODUCTION = 0, YIELD_FOOD = 0, YIELD_GOLD = 0, YIELD_FAITH = 0, YIELD_SCIENCE = 0, YIELD_CULTURE	= 0, TOURISM = 0 };
	local kSpecYields:table = { YIELD_PRODUCTION = 0, YIELD_FOOD = 0, YIELD_GOLD = 0, YIELD_FAITH = 0, YIELD_SCIENCE = 0, YIELD_CULTURE	= 0 };
	local iNumWorkedPlots:number = 0;
	local iNumSpecialists:number = 0;
	
	-- code partially taken from PlotInfo.lua
	local tParameters:table = {};
	tParameters[CityCommandTypes.PARAM_MANAGE_CITIZEN] = UI.GetInterfaceModeParameter(CityCommandTypes.PARAM_MANAGE_CITIZEN);
	local tResults:table = CityManager.GetCommandTargets( pCity, CityCommandTypes.MANAGE, tParameters );
	if tResults == nil then
		print("ERROR: GetWorkedTileYieldData, GetCommandTargets returned nil")
		return kYields, 0, kSpecYields, 0;
	end

	local tPlots:table = tResults[CityCommandResults.PLOTS];
	local tUnits:table = tResults[CityCommandResults.CITIZENS];
	--local tMaxUnits		:table = tResults[CityCommandResults.MAX_CITIZENS]; -- not used
	--local tLockedUnits	:table = tResults[CityCommandResults.LOCKED_CITIZENS]; -- not used
	if tPlots == nil or table.count(tPlots) == 0 then
		print("ERROR: GetWorkedTileYieldData, GetCommandTargets returned 0 plots")
		return kYields, 0, kSpecYields, 0;
	end
	
	--print("--- CITIZENS OF", pCity:GetName(), table.count(tPlots)); -- debug
	for i,plotId in pairs(tPlots) do

		local kPlot	:table = Map.GetPlotByIndex(plotId);
		local index:number = kPlot:GetIndex();
		local eDistrictType:number = kPlot:GetDistrictType();
		local numUnits:number = tUnits[i];
		--local maxUnits:number = tMaxUnits[i];
		--print("..plot", index, kPlot:GetX(), kPlot:GetY(), eDistrictType, numUnits, "yields", kPlot:GetYield(0), kPlot:GetYield(1));
		
		if numUnits > 0 then -- if worked at all
			if eDistrictType > 0 then -- CITY_CENTER is treated as normal tile with yields, it is not a specialist
				-- district
				iNumSpecialists = iNumSpecialists + numUnits;
				local sDistrictType:string = GameInfo.Districts[ eDistrictType ].DistrictType;
				for row in GameInfo.District_CitizenYieldChanges() do
					if row.DistrictType == sDistrictType then
						kSpecYields[row.YieldType] = kSpecYields[row.YieldType] + numUnits * row.YieldChange;
					end
				end
			else
				-- normal tile or City Center
				iNumWorkedPlots = iNumWorkedPlots + 1;
				for row in GameInfo.Yields() do			
					kYields[row.YieldType] = kYields[row.YieldType] + kPlot:GetYield(row.Index);				
				end
			end
		end
		-- Support tourism.
		-- Not a common yield, and only exposure from game core is based off
		-- of the plot so the sum is easily shown, but it's not possible to 
		-- show how individual buildings contribute... yet.
		kYields.TOURISM = kYields.TOURISM + pCulture:GetTourismAt( index );
	end
	--print("--- SUMMARY OF", pCity:GetName(), iNumWorkedPlots, iNumSpecialists); -- debug
	return kYields, iNumWorkedPlots, kSpecYields, iNumSpecialists;
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

local sortCities : table = { by = "CityName", descend = false }

local function sortByCities( name )
	if name == sortCities.by then
		sortCities.descend = not sortCities.descend
	else
		sortCities.by = name
		sortCities.descend = true
		if name == "CityName" then sortCities.descend = false; end -- exception
	end
	ViewYieldsPage()
end

local function sortFunction( t, a, b )

	if sortCities.by == "TourismPerTurn" then
		if sortCities.descend then
			return t[b].WorkedTileYields["TOURISM"] < t[a].WorkedTileYields["TOURISM"]
		else
			return t[b].WorkedTileYields["TOURISM"] > t[a].WorkedTileYields["TOURISM"]
		end
	else
		if sortCities.descend then
			return t[b][sortCities.by] < t[a][sortCities.by]
		else
			return t[b][sortCities.by] > t[a][sortCities.by]
		end
	end

end


-- ===========================================================================
--	Tab Callback
-- ===========================================================================

local populationToCultureScale:number = GameInfo.GlobalParameters["CULTURE_PERCENTAGE_YIELD_PER_POP"].Value / 100;
local populationToScienceScale:number = GameInfo.GlobalParameters["SCIENCE_PERCENTAGE_YIELD_PER_POP"].Value / 100; -- Infixo added science per pop

function ViewYieldsPage()

	ResetTabForNewPageContent();

	local pPlayer:table = Players[Game.GetLocalPlayer()]; --BRS

	local instance:table = nil;
	instance = NewCollapsibleGroupInstance();
	instance.RowHeaderButton:SetText( Locale.Lookup("LOC_HUD_REPORTS_ROW_CITY_INCOME") );
	instance.RowHeaderLabel:SetHide( true ); --BRS
	instance.AmenitiesContainer:SetHide(true);
	
	local pHeaderInstance:table = {}
	ContextPtr:BuildInstanceForControl( "CityIncomeHeaderInstance", pHeaderInstance, instance.ContentStack ) ;	

	--BRS sorting
	-- sorting is a bit weird because ViewYieldsPage is called again and entire tab is recreated, so new callbacks are registered
	pHeaderInstance.CityNameButton:RegisterCallback( Mouse.eLClick, function() sortByCities( "CityName" ) end )
	pHeaderInstance.ProductionButton:RegisterCallback( Mouse.eLClick, function() sortByCities( "ProductionPerTurn" ) end )
	--pHeaderInstance.FoodButton:RegisterCallback( Mouse.eLClick, function() sortByCities( "FoodPerTurn" ) end )
	pHeaderInstance.FoodButton:RegisterCallback( Mouse.eLClick, function() sortByCities( "TotalFoodSurplus" ) end )
	pHeaderInstance.GoldButton:RegisterCallback( Mouse.eLClick, function() sortByCities( "GoldPerTurn" ) end )
	pHeaderInstance.FaithButton:RegisterCallback( Mouse.eLClick, function() sortByCities( "FaithPerTurn" ) end )
	pHeaderInstance.ScienceButton:RegisterCallback( Mouse.eLClick, function() sortByCities( "SciencePerTurn" ) end )
	pHeaderInstance.CultureButton:RegisterCallback( Mouse.eLClick, function() sortByCities( "CulturePerTurn" ) end )
	pHeaderInstance.TourismButton:RegisterCallback( Mouse.eLClick, function() sortByCities( "TourismPerTurn" ) end )

	local goldCityTotal		:number = 0;
	local faithCityTotal	:number = 0;
	local scienceCityTotal	:number = 0;
	local cultureCityTotal	:number = 0;
	local tourismCityTotal	:number = 0;
	
	-- helper for calculating lines from modifiers
	local function GetEmptyYieldsTable()
		return { YIELD_PRODUCTION = 0, YIELD_FOOD = 0, YIELD_GOLD = 0, YIELD_FAITH = 0, YIELD_SCIENCE = 0, YIELD_CULTURE = 0 };
	end
	-- Infixo needed to properly calculate yields from % modifiers (like amenities)
	local kBaseYields:table = GetEmptyYieldsTable();
	kBaseYields.TOURISM = 0;
	local function StoreInBaseYields(sYield:string, fValue:number) kBaseYields[ sYield ] = kBaseYields[ sYield ] + fValue; end

	-- ========== City Income ==========

	function CreatLineItemInstance(cityInstance:table, name:string, production:number, gold:number, food:number, science:number, culture:number, faith:number, bDontStore:boolean)
		local lineInstance:table = {};
		ContextPtr:BuildInstanceForControl("CityIncomeLineItemInstance", lineInstance, cityInstance.LineItemStack );
		TruncateStringWithTooltipClean(lineInstance.LineItemName, 345, name);
		lineInstance.Production:SetText( toPlusMinusNoneString(production));
		lineInstance.Food:SetText( toPlusMinusNoneString(food));
		lineInstance.Gold:SetText( toPlusMinusNoneString(gold));
		lineInstance.Faith:SetText( toPlusMinusNoneString(faith));
		lineInstance.Science:SetText( toPlusMinusNoneString(science));
		lineInstance.Culture:SetText( toPlusMinusNoneString(culture));
		--BRS Infixo needed to properly calculate yields from % modifiers (like amenities)
		if bDontStore then return lineInstance; end -- default: omit param and store
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
		TruncateStringWithTooltip(pCityInstance.CityName, 230, (kCityData.IsCapital and "[ICON_Capital]" or "")..Locale.Lookup(kCityData.CityName));
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

		-- Infixo: this is the place to add Yield Focus
		local function SetYieldTextAndFocusFlag(pLabel:table, fValue:number, eYieldType:number)
			local sText:string = toPlusMinusString(fValue);
			local sToolTip:string = "";
			if     kCityData.YieldFilters[eYieldType] == YIELD_STATE.FAVORED then
				sText = sText.."  [COLOR:0,255,0,255]!"; -- [ICON_FoodSurplus][ICON_CheckSuccess]
				sToolTip = Locale.Lookup("LOC_HUD_CITY_YIELD_FOCUSING", GameInfo.Yields[eYieldType].Name);
			elseif kCityData.YieldFilters[eYieldType] == YIELD_STATE.IGNORED then
				sText = sText.."  [COLOR:255,0,0,255]!"; -- [ICON_FoodDeficit][ICON_CheckFail]
				sToolTip = Locale.Lookup("LOC_HUD_CITY_YIELD_IGNORING", GameInfo.Yields[eYieldType].Name);
			end
			pLabel:SetText( sText );
			pLabel:SetToolTipString( sToolTip );
		end
		SetYieldTextAndFocusFlag( pCityInstance.Production,kCityData.ProductionPerTurn,YieldTypes.PRODUCTION );
		--SetYieldTextAndFocusFlag( pCityInstance.Food,      kCityData.FoodPerTurn,      YieldTypes.FOOD );
		SetYieldTextAndFocusFlag( pCityInstance.Food,      kCityData.TotalFoodSurplus, YieldTypes.FOOD );
		SetYieldTextAndFocusFlag( pCityInstance.Gold,      kCityData.GoldPerTurn,      YieldTypes.GOLD );
		SetYieldTextAndFocusFlag( pCityInstance.Faith,     kCityData.FaithPerTurn,     YieldTypes.FAITH );
		SetYieldTextAndFocusFlag( pCityInstance.Science,   kCityData.SciencePerTurn,   YieldTypes.SCIENCE );
		SetYieldTextAndFocusFlag( pCityInstance.Culture,   kCityData.CulturePerTurn,   YieldTypes.CULTURE );
		pCityInstance.Tourism:SetText( toPlusMinusString(kCityData.WorkedTileYields["TOURISM"]) ); -- unchanged (no focus feature here)
		-- BIG food tooltip
		pCityInstance.FoodContainer:SetToolTipString(kCityData.TotalFoodSurplusToolTip);

		-- Add to all cities totals
		goldCityTotal	= goldCityTotal + kCityData.GoldPerTurn;
		faithCityTotal	= faithCityTotal + kCityData.FaithPerTurn;
		scienceCityTotal= scienceCityTotal + kCityData.SciencePerTurn;
		cultureCityTotal= cultureCityTotal + kCityData.CulturePerTurn;
		tourismCityTotal= tourismCityTotal + kCityData.WorkedTileYields["TOURISM"];
		
		if not Controls.HideCityBuildingsCheckbox:IsSelected() then --BRS
		
		-- Worked Tiles
		if kCityData.NumWorkedTiles > 0 then 
			CreatLineItemInstance(	pCityInstance,
									Locale.Lookup("LOC_HUD_REPORTS_WORKED_TILES")..string.format("  [COLOR_White]%d[ENDCOLOR]", kCityData.NumWorkedTiles),
									kCityData.WorkedTileYields["YIELD_PRODUCTION"],
									kCityData.WorkedTileYields["YIELD_GOLD"],
									kCityData.WorkedTileYields["YIELD_FOOD"],
									kCityData.WorkedTileYields["YIELD_SCIENCE"],
									kCityData.WorkedTileYields["YIELD_CULTURE"],
									kCityData.WorkedTileYields["YIELD_FAITH"]);
		end

		-- Specialists
		if kCityData.NumSpecialists > 0 then
			CreatLineItemInstance(	pCityInstance,
									Locale.Lookup("LOC_BRS_SPECIALISTS")..string.format("  [COLOR_White]%d[ENDCOLOR]", kCityData.NumSpecialists),
									kCityData.SpecialistYields["YIELD_PRODUCTION"],
									kCityData.SpecialistYields["YIELD_GOLD"],
									kCityData.SpecialistYields["YIELD_FOOD"],
									kCityData.SpecialistYields["YIELD_SCIENCE"],
									kCityData.SpecialistYields["YIELD_CULTURE"],
									kCityData.SpecialistYields["YIELD_FAITH"]);
		end

		-- Additional Yields from Population
		-- added modifiers with EFFECT_ADJUST_CITY_YIELD_PER_POPULATION
		local tPopYields:table = GetEmptyYieldsTable(); -- will always show
		for _,mod in ipairs(kCityData.Modifiers) do
			if mod.Modifier.EffectType == "EFFECT_ADJUST_CITY_YIELD_PER_POPULATION" then
				tPopYields[ mod.Arguments.YieldType ] = tPopYields[ mod.Arguments.YieldType ] + kCityData.Population * tonumber(mod.Arguments.Amount);
			end
		end
		CreatLineItemInstance(	pCityInstance,
								Locale.Lookup("LOC_HUD_CITY_POPULATION")..string.format("  [COLOR_White]%d[ENDCOLOR]", kCityData.Population),
								tPopYields.YIELD_PRODUCTION,
								tPopYields.YIELD_GOLD,
								tPopYields.YIELD_FOOD    + kCityData.FoodConsumption, -- food
								tPopYields.YIELD_SCIENCE + kCityData.Population * populationToScienceScale,
								tPopYields.YIELD_CULTURE + kCityData.Population * populationToCultureScale,
								tPopYields.YIELD_FAITH);

		-- Main loop for all districts and buildings
		for i,kDistrict in ipairs(kCityData.BuildingsAndDistricts) do			
			--District line item
			--BRS GetYield() includes also GetAdjacencyYield(), so must subtract to not duplicate them
			local districtInstance = CreatLineItemInstance(	pCityInstance, 
															(kDistrict.isBuilt and kDistrict.Name) or Locale.Lookup("LOC_CITY_BANNER_PRODUCING", kDistrict.Name),
															kDistrict.Production - kDistrict.AdjacencyBonus.Production,
															kDistrict.Gold       - kDistrict.AdjacencyBonus.Gold,
															kDistrict.Food       - kDistrict.AdjacencyBonus.Food,
															kDistrict.Science    - kDistrict.AdjacencyBonus.Science,
															kDistrict.Culture    - kDistrict.AdjacencyBonus.Culture,
															kDistrict.Faith      - kDistrict.AdjacencyBonus.Faith);
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
			if kDistrict.isBuilt and HasValidAdjacencyBonus(kDistrict.AdjacencyBonus) then -- Infixo fix for checking if it is actually built!
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
						local sIconString:string = GameInfo.GreatWorkObjectTypes[ kGreatWork.GreatWorkObjectType ].IconString;
						local pLineItemInstance:table = CreatLineItemInstance(pCityInstance, INDENT_STRING..INDENT_STRING..sIconString..Locale.Lookup(kGreatWork.Name), 0, 0, 0, 0, 0, 0);
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
					pLineItemInstance.DistrictIcon:SetHide(false);
					pLineItemInstance.DistrictIcon:SetIcon("ICON_DISTRICT_WONDER");
					-- Show yields
					for _, yield in ipairs(wonder.Yields) do
						SetFieldInLineItemInstance(pLineItemInstance, yield.YieldType, yield.YieldChange);
					end
				end

				--Add great works
				if greatWorks[wonder.Type] ~= nil then
					--Add our line items!
					for _, kGreatWork in ipairs(greatWorks[wonder.Type]) do
						local sIconString:string = GameInfo.GreatWorkObjectTypes[ kGreatWork.GreatWorkObjectType ].IconString;
						local pLineItemInstance:table = CreatLineItemInstance(pCityInstance, INDENT_STRING..sIconString..Locale.Lookup(kGreatWork.Name), 0, 0, 0, 0, 0, 0);
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

		-- Flat yields from Modifiers EFFECT_ADJUST_CITY_YIELD_CHANGE
		local tFlatYields:table = GetEmptyYieldsTable();
		local bFlatYields:boolean = false;
		for _,mod in ipairs(kCityData.Modifiers) do
			if mod.Modifier.EffectType == "EFFECT_ADJUST_CITY_YIELD_CHANGE" then
				tFlatYields[ mod.Arguments.YieldType ] = tFlatYields[ mod.Arguments.YieldType ] + tonumber(mod.Arguments.Amount);
				bFlatYields = true;
			end
		end
		--print("MOD from FLAT YIELDS"); for k,v in pairs(tFlatYields) do print(k,v); end
		if bFlatYields then
			CreatLineItemInstance(
				pCityInstance, Locale.Lookup("LOC_BRS_FROM_MODIFIERS"),
				tFlatYields.YIELD_PRODUCTION, tFlatYields.YIELD_GOLD, tFlatYields.YIELD_FOOD, tFlatYields.YIELD_SCIENCE, tFlatYields.YIELD_CULTURE, tFlatYields.YIELD_FAITH
			); -- this one needs to be stored
		end

		-- Flat yields from Modifiers EFFECT_ADJUST_CITY_YIELD_PER_DISTRICT
		if kCityData.NumSpecialtyDistricts > 0 then
			tFlatYields = GetEmptyYieldsTable();
			bFlatYields = false;
			for _,mod in ipairs(kCityData.Modifiers) do
				if mod.Modifier.EffectType == "EFFECT_ADJUST_CITY_YIELD_PER_DISTRICT" then
					tFlatYields[ mod.Arguments.YieldType ] = tFlatYields[ mod.Arguments.YieldType ] + tonumber(mod.Arguments.Amount) * kCityData.NumSpecialtyDistricts;
					bFlatYields = true;
				end
			end
			if bFlatYields then
				CreatLineItemInstance(
					pCityInstance, Locale.Lookup("LOC_BRS_HAVING_DISTRICTS", kCityData.NumSpecialtyDistricts),
					tFlatYields.YIELD_PRODUCTION, tFlatYields.YIELD_GOLD, tFlatYields.YIELD_FOOD, tFlatYields.YIELD_SCIENCE, tFlatYields.YIELD_CULTURE, tFlatYields.YIELD_FAITH
				); -- this one needs to be stored
			end
		end
		
		-- Flat yields from Modifiers EFFECT_ADJUST_CITY_PRODUCTION_BUILDING
		if kCityData.CurrentProductionType == "BUILDING" then
			tFlatYields = GetEmptyYieldsTable();
			bFlatYields = false;
			for _,mod in ipairs(kCityData.Modifiers) do
				if mod.Modifier.EffectType == "EFFECT_ADJUST_CITY_PRODUCTION_BUILDING" then
					tFlatYields.YIELD_PRODUCTION = tFlatYields.YIELD_PRODUCTION + tonumber(mod.Arguments.Amount);
					bFlatYields = true;
				end
			end
			if bFlatYields then
				CreatLineItemInstance(
					pCityInstance, Locale.Lookup("LOC_BRS_PROD_BUILDINGS"),
					tFlatYields.YIELD_PRODUCTION, tFlatYields.YIELD_GOLD, tFlatYields.YIELD_FOOD, tFlatYields.YIELD_SCIENCE, tFlatYields.YIELD_CULTURE, tFlatYields.YIELD_FAITH
				); -- this one needs to be stored
			end
		end
		
		-- Flat yields from Modifiers EFFECT_ADJUST_CITY_PRODUCTION_DISTRICT
		if kCityData.CurrentProductionType == "DISTRICT" then
			tFlatYields = GetEmptyYieldsTable();
			bFlatYields = false;
			for _,mod in ipairs(kCityData.Modifiers) do
				if mod.Modifier.EffectType == "EFFECT_ADJUST_CITY_PRODUCTION_DISTRICT" then
					tFlatYields.YIELD_PRODUCTION = tFlatYields.YIELD_PRODUCTION + tonumber(mod.Arguments.Amount);
					bFlatYields = true;
				end
			end
			if bFlatYields then
				CreatLineItemInstance(
					pCityInstance, Locale.Lookup("LOC_BRS_PROD_DISTRICTS"),
					tFlatYields.YIELD_PRODUCTION, tFlatYields.YIELD_GOLD, tFlatYields.YIELD_FOOD, tFlatYields.YIELD_SCIENCE, tFlatYields.YIELD_CULTURE, tFlatYields.YIELD_FAITH
				); -- this one needs to be stored
			end
		end
		
		-- Flat yields from Modifiers EFFECT_ADJUST_CITY_PRODUCTION_UNIT
		if kCityData.CurrentProductionType == "UNIT" then
			tFlatYields = GetEmptyYieldsTable();
			bFlatYields = false;
			for _,mod in ipairs(kCityData.Modifiers) do
				if mod.Modifier.EffectType == "EFFECT_ADJUST_CITY_PRODUCTION_UNIT" then
					tFlatYields.YIELD_PRODUCTION = tFlatYields.YIELD_PRODUCTION + tonumber(mod.Arguments.Amount);
					bFlatYields = true;
				end
			end
			if bFlatYields then
				CreatLineItemInstance(
					pCityInstance, Locale.Lookup("LOC_BRS_PROD_UNITS"),
					tFlatYields.YIELD_PRODUCTION, tFlatYields.YIELD_GOLD, tFlatYields.YIELD_FOOD, tFlatYields.YIELD_SCIENCE, tFlatYields.YIELD_CULTURE, tFlatYields.YIELD_FAITH
				); -- this one needs to be stored
			end
		end
		
		-- Religious followers EFFECT_ADJUST_FOLLOWER_YIELD_MODIFIER
		local tFollowersModifiers:table = GetEmptyYieldsTable(); -- not yields, but stores numbers anyway
		local bShowFollowers:boolean = false;
		for _,mod in ipairs(kCityData.Modifiers) do
			if mod.Modifier.EffectType == "EFFECT_ADJUST_FOLLOWER_YIELD_MODIFIER" then
				tFollowersModifiers[ mod.Arguments.YieldType ] = tFollowersModifiers[ mod.Arguments.YieldType ] + tonumber(mod.Arguments.Amount);
				bShowFollowers = true;
			end
		end
		--print("MOD from FOLLOWERS"); for k,v in pairs(tFollowersModifiers) do print(k,v); end
		if bShowFollowers then
			CreatLineItemInstance(	pCityInstance,
									Locale.Lookup("LOC_UI_RELIGION_FOLLOWERS")..string.format("  [COLOR_White]%d[ENDCOLOR]", kCityData.MajorityReligionFollowers),
									kBaseYields.YIELD_PRODUCTION * tFollowersModifiers.YIELD_PRODUCTION * kCityData.MajorityReligionFollowers / 100.0,
									kBaseYields.YIELD_GOLD       * tFollowersModifiers.YIELD_GOLD       * kCityData.MajorityReligionFollowers / 100.0,
									kBaseYields.YIELD_FOOD       * tFollowersModifiers.YIELD_FOOD       * kCityData.MajorityReligionFollowers / 100.0,
									kBaseYields.YIELD_SCIENCE    * tFollowersModifiers.YIELD_SCIENCE    * kCityData.MajorityReligionFollowers / 100.0,
									kBaseYields.YIELD_CULTURE    * tFollowersModifiers.YIELD_CULTURE    * kCityData.MajorityReligionFollowers / 100.0,
									kBaseYields.YIELD_FAITH      * tFollowersModifiers.YIELD_FAITH      * kCityData.MajorityReligionFollowers / 100.0,
									true); -- don't store in base yields, we'll need it for other rows
		end
		
		-- Percentage scaled yields from Modifiers EFFECT_ADJUST_CITY_YIELD_MODIFIER
		local tPercYields:table = GetEmptyYieldsTable();
		local bPercYields:boolean = false;
		for _,mod in ipairs(kCityData.Modifiers) do
			if mod.Modifier.EffectType == "EFFECT_ADJUST_CITY_YIELD_MODIFIER" then
				tPercYields[ mod.Arguments.YieldType ] = tPercYields[ mod.Arguments.YieldType ] + tonumber(mod.Arguments.Amount);
				bPercYields = true;
			end
		end
		--print("MOD from PERC YIELDS", cityName); for k,v in pairs(tPercYields) do print(k,v); end
		if bPercYields then
			CreatLineItemInstance(	pCityInstance,
									Locale.Lookup("LOC_BRS_FROM_MODIFIERS_PERCENT"),
									kBaseYields.YIELD_PRODUCTION * tPercYields.YIELD_PRODUCTION / 100.0,
									kBaseYields.YIELD_GOLD       * tPercYields.YIELD_GOLD       / 100.0,
									kBaseYields.YIELD_FOOD       * tPercYields.YIELD_FOOD       / 100.0,
									kBaseYields.YIELD_SCIENCE    * tPercYields.YIELD_SCIENCE    / 100.0,
									kBaseYields.YIELD_CULTURE    * tPercYields.YIELD_CULTURE    / 100.0,
									kBaseYields.YIELD_FAITH      * tPercYields.YIELD_FAITH      / 100.0,
									true); -- don't store in base yields, we'll need it for other rows
		end

		-- Yields from Amenities -- Infixo TOTALLY WRONG amenities are applied to all yields, not only Worked Tiles; also must be the LAST calculated entry
		--local iYieldPercent = (Round(1 + (kCityData.HappinessNonFoodYieldModifier/100), 2)*.1); -- Infixo Buggy formula
		local iYieldPercent:number = kCityData.HappinessNonFoodYieldModifier/100;
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
	instance.AmenitiesContainer:SetHide(true);

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
		instance.AmenitiesContainer:SetHide(true);

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
		instance.AmenitiesContainer:SetHide(true);

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
	Controls.BottomMinorsFilters:SetHide( true );
	Controls.Scroll:SetSizeY( Controls.Main:GetSizeY() - (Controls.BottomYieldTotals:GetSizeY() + SIZE_HEIGHT_PADDING_BOTTOM_ADJUST ) );	
	-- Remember this tab when report is next opened: ARISTOS
	m_kCurrentTab = 1;
end


-- ===========================================================================
-- RESOURCES PAGE
-- ===========================================================================

function ViewResourcesPage()	

	ResetTabForNewPageContent();

	local strategicResources:string = "";
	local luxuryResources	:string = "";
	local kBonuses			:table	= {};
	local kLuxuries			:table	= {};
	local kStrategics		:table	= {};
	

	--for eResourceType,kSingleResourceData in pairs(m_kResourceData) do
	for eResourceType,kSingleResourceData in spairs(m_kResourceData, function(t,a,b) return Locale.Lookup(GameInfo.Resources[a].Name) < Locale.Lookup(GameInfo.Resources[b].Name) end) do
		
		local kResource :table = GameInfo.Resources[eResourceType];
		
		--!!ARISTOS: Only display list of selected resource types, according to checkboxes
		if (kSingleResourceData.IsStrategic and Controls.StrategicCheckbox:IsSelected()) or
			(kSingleResourceData.IsLuxury and Controls.LuxuryCheckbox:IsSelected()) or
			(kSingleResourceData.IsBonus and Controls.BonusCheckbox:IsSelected()) then

		local instance:table = NewCollapsibleGroupInstance();	

		instance.RowHeaderButton:SetText(  kSingleResourceData.Icon..Locale.Lookup( kResource.Name ) );
		instance.RowHeaderLabel:SetHide( false ); --BRS
		if kSingleResourceData.Total < 0 then
			instance.RowHeaderLabel:SetText( Locale.Lookup("LOC_HUD_REPORTS_TOTALS").." [COLOR_Red]"..tostring(kSingleResourceData.Total).."[ENDCOLOR]" );
		else
			instance.RowHeaderLabel:SetText( Locale.Lookup("LOC_HUD_REPORTS_TOTALS").." "..tostring(kSingleResourceData.Total) );
		end

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

		--local pFooterInstance:table = {};
		--ContextPtr:BuildInstanceForControl( "ResourcesFooterInstance", pFooterInstance, instance.ContentStack ) ;
		--pFooterInstance.Amount:SetText( tostring(kSingleResourceData.Total) );

		-- Show how many of this resource are being allocated to what cities
		local localPlayerID = Game.GetLocalPlayer();
		local localPlayer = Players[localPlayerID];
		local citiesProvidedTo: table = localPlayer:GetResources():GetResourceAllocationCities(GameInfo.Resources[kResource.ResourceType].Index);
		local numCitiesProvidingTo: number = table.count(citiesProvidedTo);
		if (numCitiesProvidingTo > 0) then
			--pFooterInstance.AmenitiesContainer:SetHide(false);
			instance.AmenitiesContainer:SetHide(false); ---BRS
			--pFooterInstance.Amenities:SetText("[ICON_Amenities][ICON_GoingTo]"..numCitiesProvidingTo.." "..Locale.Lookup("LOC_PEDIA_CONCEPTS_PAGEGROUP_CITIES_NAME"));
			instance.Amenities:SetText("[ICON_Amenities][ICON_GoingTo]"..numCitiesProvidingTo.." "..Locale.Lookup("LOC_PEDIA_CONCEPTS_PAGEGROUP_CITIES_NAME"));
			local amenitiesTooltip: string = "";
			local playerCities = localPlayer:GetCities();
			for i,city in ipairs(citiesProvidedTo) do
				local cityName = Locale.Lookup(playerCities:FindID(city.CityID):GetName());
				if i ~=1 then
					amenitiesTooltip = amenitiesTooltip.. "[NEWLINE]";
				end
				amenitiesTooltip = amenitiesTooltip.. city.AllocationAmount.." [ICON_".. kResource.ResourceType.."] [Icon_GoingTo] " ..cityName;
			end
			--pFooterInstance.Amenities:SetToolTipString(amenitiesTooltip);
			instance.Amenities:SetToolTipString(amenitiesTooltip);
		else
			--pFooterInstance.AmenitiesContainer:SetHide(true);
			instance.AmenitiesContainer:SetHide(true);
		end

		--SetGroupCollapsePadding(instance, pFooterInstance.Top:GetSizeY() ); --BRS moved into if
		SetGroupCollapsePadding(instance, 0); --BRS no footer
		RealizeGroup( instance ); --BRS moved into if

		end -- ARISTOS checkboxes

		local tResBottomData:table = {
			Text = kSingleResourceData.Icon..tostring(kSingleResourceData.Total),
			ToolTip = kSingleResourceData.Icon..Locale.Lookup( kResource.Name ).." "..tostring(kSingleResourceData.Total),
		};
		if     kSingleResourceData.IsStrategic then table.insert(kStrategics, tResBottomData);
		elseif kSingleResourceData.IsLuxury    then table.insert(kLuxuries,   tResBottomData);
		else                                        table.insert(kBonuses,    tResBottomData); end

		--SetGroupCollapsePadding(instance, pFooterInstance.Top:GetSizeY() ); --BRS moved into if
		--RealizeGroup( instance ); --BRS moved into if
	end
	
	local function ShowResources(kResIM:table, kResources:table)
		kResIM:ResetInstances();
		for i,v in ipairs(kResources) do
			local resourceInstance:table = kResIM:GetInstance();
			resourceInstance.Info:SetText( v.Text );
			resourceInstance.Info:SetToolTipString( v.ToolTip );
		end
	end
	ShowResources(m_strategicResourcesIM, kStrategics);
	Controls.StrategicResources:CalculateSize();
	Controls.StrategicGrid:ReprocessAnchoring();
	ShowResources(m_bonusResourcesIM, kBonuses);
	Controls.BonusResources:CalculateSize();
	Controls.BonusGrid:ReprocessAnchoring();
	ShowResources(m_luxuryResourcesIM, kLuxuries);
	Controls.LuxuryResources:CalculateSize();
	Controls.LuxuryResources:ReprocessAnchoring();
	--Controls.LuxuryGrid:ReprocessAnchoring();
	
	Controls.Stack:CalculateSize();
	Controls.Scroll:CalculateSize();

	Controls.CollapseAll:SetHide( false );
	Controls.BottomYieldTotals:SetHide( true );
	Controls.BottomResourceTotals:SetHide( false ); -- ViewResourcesPage
	Controls.BottomPoliciesFilters:SetHide( true );
	Controls.BottomMinorsFilters:SetHide( true );
	Controls.Scroll:SetSizeY( Controls.Main:GetSizeY() - (Controls.BottomResourceTotals:GetSizeY() + SIZE_HEIGHT_PADDING_BOTTOM_ADJUST ) );	
	-- Remember this tab when report is next opened: ARISTOS
	m_kCurrentTab = 2;
end


-- ===========================================================================
-- CITY STATUS PAGE
-- ===========================================================================

function GetFontIconForDistrict(sDistrictType:string)
	-- exceptions first
	if sDistrictType == "DISTRICT_CITY_CENTER"                 then return "[ICON_DISTRICT_CITYCENTER]";    end
	if sDistrictType == "DISTRICT_HOLY_SITE"                   then return "[ICON_DISTRICT_HOLYSITE]";      end
	if sDistrictType == "DISTRICT_ENTERTAINMENT_COMPLEX"       then return "[ICON_DISTRICT_ENTERTAINMENT]"; end
	if sDistrictType == "DISTRICT_WATER_ENTERTAINMENT_COMPLEX" then return "[ICON_DISTRICT_ENTERTAINMENT]"; end -- no need to check for mutuals with that
	if sDistrictType == "DISTRICT_AERODROME"                   then return "[ICON_DISTRICT_WONDER]";        end -- no unique font icon for an aerodrome
	-- default icon last
	return "[ICON_"..sDistrictType.."]";
end

local tDistrictsOrder:table = {
	-- Ancient Era
	--"DISTRICT_GOVERNMENT", -- to save space, will be treated separately
	"DISTRICT_HOLY_SITE", -- icon is DISTRICT_HOLYSITE
	"DISTRICT_CAMPUS",
	"DISTRICT_ENCAMPMENT",
	-- Classical Era
	"DISTRICT_THEATER",
	"DISTRICT_COMMERCIAL_HUB",
	"DISTRICT_HARBOR",
	"DISTRICT_ENTERTAINMENT_COMPLEX", -- with DISTRICT_WATER_ENTERTAINMENT_COMPLEX, icon is DISTRICT_ENTERTAINMENT
	-- Medieval Era
	"DISTRICT_INDUSTRIAL_ZONE",
	-- others
	"DISTRICT_AQUEDUCT",
	"DISTRICT_NEIGHBORHOOD",
	"DISTRICT_SPACEPORT",
	"DISTRICT_AERODROME", -- no icon, we'll use an icon for DISTRICT_WONDER
}
--for k,v in pairs(tDistrictsOrder) do print("tDistrictsOrder",k,v) end;

function HasCityDistrict(kCityData:table, sDistrictType:string)
	for _,district in ipairs(kCityData.BuildingsAndDistricts) do
		if district.isBuilt then
			local sDistrictInCity:string = district.Type;
			--if district.DistrictType == sDistrictType then return true; end
			if GameInfo.DistrictReplaces[ sDistrictInCity ] then sDistrictInCity = GameInfo.DistrictReplaces[ sDistrictInCity ].ReplacesDistrictType; end
			if sDistrictInCity == sDistrictType then return true; end
			-- check mutually exclusive
			for row in GameInfo.MutuallyExclusiveDistricts() do
				if sDistrictInCity == row.District and row.MutuallyExclusiveDistrict == sDistrictType then return true; end
			end
		end
	end
	return false;
end

-- districts
function GetDistrictsForCity(kCityData:table)
	local sDistricts:string = "";
	for _,districtType in ipairs(tDistrictsOrder) do
		local sDistrictIcon:string = "[ICON_Bullet]"; -- default empty
		if HasCityDistrict(kCityData, districtType) then
			sDistrictIcon = GetFontIconForDistrict(districtType);
		end
		sDistricts = sDistricts..sDistrictIcon;
	end
	return sDistricts;
end

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
	if HasCityDistrict(kCityData, "DISTRICT_GOVERNMENT") then
		sStatusText = sStatusText.."[ICON_DISTRICT_GOVERNMENT]"; table.insert(tStatusToolTip, Locale.Lookup("LOC_DISTRICT_GOVERNMENT_NAME"));
	end
	local bHasWonder:boolean = false;
	for _,wonder in ipairs(kCityData.Wonders) do
		bHasWonder = true;
		table.insert(tStatusToolTip, wonder.Name);
	end
	if bHasWonder then sStatusText = sStatusText.."[ICON_DISTRICT_WONDER]"; end

	pCityInstance.Status:SetText( sStatusText );
	pCityInstance.Status:SetToolTipString( table.concat(tStatusToolTip, "[NEWLINE]") );
	
	-- Religions
	local eCityReligion:number = kCityData.City:GetReligion():GetMajorityReligion();
	local eCityPantheon:number = kCityData.City:GetReligion():GetActivePantheon();
	
	local function ShowReligionTooltip(sHeader:string)
		local tTT:table = {};
		table.insert(tTT, "[ICON_Religion]"..sHeader);
		table.sort(kCityData.Religions, function(a,b) return a.Followers > b.Followers; end);
		for _,rel in ipairs(kCityData.Religions) do
			--print(rel.ID, rel.ReligionType, rel.Followers);
			--table.insert(tTT, string.format("%s: %d", Game.GetReligion():GetName( math.max(0, rel.ID) ), rel.Followers)); -- LOC_UI_RELIGION_NUM_FOLLOWERS_TT
			table.insert(tTT, Locale.Lookup("LOC_UI_RELIGION_NUM_FOLLOWERS_TT", Game.GetReligion():GetName( math.max(0, rel.ID) ), rel.Followers));
		end
		pCityInstance.ReligionIcon:SetToolTipString(table.concat(tTT, "[NEWLINE]"));
	end
	
	if eCityReligion > 0 then
		local iconName : string = "ICON_" .. GameInfo.Religions[eCityReligion].ReligionType;
		local majorityReligionColor : number = UI.GetColorValue(GameInfo.Religions[eCityReligion].Color);
		if (majorityReligionColor ~= nil) then
			pCityInstance.ReligionIcon:SetColor(majorityReligionColor);
		end
		local textureOffsetX, textureOffsetY, textureSheet = IconManager:FindIconAtlas(iconName,22);
		if (textureOffsetX ~= nil) then
			pCityInstance.ReligionIcon:SetTexture( textureOffsetX, textureOffsetY, textureSheet );
		end
		pCityInstance.ReligionIcon:SetHide(false);
		--pCityInstance.ReligionIcon:SetToolTipString(Game.GetReligion():GetName(eCityReligion));
		ShowReligionTooltip( Game.GetReligion():GetName(eCityReligion) );
		
	elseif eCityPantheon >= 0 then
		local iconName : string = "ICON_" .. GameInfo.Religions[0].ReligionType;
		local majorityReligionColor : number = UI.GetColorValue(GameInfo.Religions.RELIGION_PANTHEON.Color);
		if (majorityReligionColor ~= nil) then
			pCityInstance.ReligionIcon:SetColor(majorityReligionColor);
		end
		local textureOffsetX, textureOffsetY, textureSheet = IconManager:FindIconAtlas(iconName,22);
		if (textureOffsetX ~= nil) then
			pCityInstance.ReligionIcon:SetTexture( textureOffsetX, textureOffsetY, textureSheet );
		end
		pCityInstance.ReligionIcon:SetHide(false);
		--pCityInstance.ReligionIcon:SetToolTipString(Locale.Lookup("LOC_HUD_CITY_PANTHEON_TT", GameInfo.Beliefs[eCityPantheon].Name));
		ShowReligionTooltip( Locale.Lookup("LOC_HUD_CITY_PANTHEON_TT", GameInfo.Beliefs[eCityPantheon].Name) );

	else
		pCityInstance.ReligionIcon:SetHide(true);
		pCityInstance.ReligionIcon:SetToolTipString("");
	end
	
	-- CityName
	--pCityInstance.CityName:SetText( Locale.Lookup( kCityData.CityName ) );
	TruncateStringWithTooltip(pCityInstance.CityName, 178, (kCityData.IsCapital and "[ICON_Capital]" or "")..Locale.Lookup(kCityData.CityName));
	
	-- Population and Housing
	-- a bit more complicated due to real housing from improvements
	local fRealHousing:number = kCityData.Housing - kCityData.HousingFromImprovements + kCityData.RealHousingFromImprovements;
	if kCityData.Population >= fRealHousing then
		pCityInstance.Population:SetText( "[COLOR_White]"..tostring(kCityData.Population).."[ENDCOLOR] / "..ColorRed(fRealHousing) );
	else
		pCityInstance.Population:SetText( "[COLOR_White]"..tostring(kCityData.Population).."[ENDCOLOR] / "..tostring(fRealHousing) );
	end
	--[[ debug
	local tTT:table = {};
	table.insert(tTT, "Housing : "..kCityData.Housing);
	table.insert(tTT, "FromImpr: "..kCityData.HousingFromImprovements);
	table.insert(tTT, "RealImpr: "..kCityData.RealHousingFromImprovements);
	table.insert(tTT, "RealHous: "..fRealHousing);
	pCityInstance.Population:SetToolTipString(table.concat(tTT, "[NEWLINE]"));
	--]]
	
	-- GrowthRateStatus
	local sGRStatus:string = "LOC_HUD_REPORTS_STATUS_NORMAL";
	local sGRColor:string = "";
	if     kCityData.HousingMultiplier == 0 or kCityData.Occupied then sGRStatus = "LOC_HUD_REPORTS_STATUS_HALTED"; sGRColor = "[COLOR:200,62,52,255]"; -- Error
	elseif kCityData.HousingMultiplier <= 0.25                    then sGRStatus = tostring(100 * kCityData.HousingMultiplier - 100).."%"; sGRColor = "[COLOR:200,146,52,255]"; -- WarningMajor "LOC_HUD_REPORTS_STATUS_SLOWED"; 
	elseif kCityData.HousingMultiplier <= 0.5                     then sGRStatus = tostring(100 * kCityData.HousingMultiplier - 100).."%"; sGRColor = "[COLOR:206,199,91,255]"; end -- WarningMinor "LOC_HUD_REPORTS_STATUS_SLOWED";
	pCityInstance.GrowthRateStatus:SetText( sGRColor..Locale.Lookup(sGRStatus)..(sGRColor~="" and "[ENDCOLOR]" or "") );
	--if sGRColor ~= "" then pCityInstance.GrowthRateStatus:SetColorByName( sGRColor ); end

	-- Amenities
	if kCityData.AmenitiesNum < kCityData.AmenitiesRequiredNum then
		pCityInstance.Amenities:SetText( ColorRed(kCityData.AmenitiesNum).." / "..tostring(kCityData.AmenitiesRequiredNum) );
	else
		pCityInstance.Amenities:SetText( tostring(kCityData.AmenitiesNum).." / "..tostring(kCityData.AmenitiesRequiredNum) );
	end
	
	-- Happiness
	local happinessFormat:string = "%s";
	local happinessText:string = Locale.Lookup( GameInfo.Happinesses[kCityData.Happiness].Name );
	local happinessToolTip:string = happinessText;
	if kCityData.HappinessGrowthModifier < 0 then happinessFormat = "[COLOR:255,40,50,160]%s[ENDCOLOR]"; end -- StatBadCS    Color0="255,40,50,240" StatNormalCS Color0="200,200,200,240"
	if kCityData.HappinessGrowthModifier > 0 then happinessFormat = "[COLOR:80,255,90,160]%s[ENDCOLOR]"; end -- StatGoodCS   Color0="80,255,90,240"
	if kCityData.HappinessGrowthModifier ~= 0 then happinessText = string.format("%+d%% %+d%%", kCityData.HappinessGrowthModifier, kCityData.HappinessNonFoodYieldModifier); end
	pCityInstance.CitizenHappiness:SetText( string.format(happinessFormat, happinessText) );
	pCityInstance.CitizenHappiness:SetToolTipString( string.format(happinessFormat, happinessToolTip) );
	
	-- Strength and icon for Garrison Unit, and Walls
	local sStrength:string = tostring(kCityData.Defense);
	local sStrengthToolTip:string = "";
	local function CheckForWalls(sWallsType:string)
		local pCityBuildings:table = kCityData.City:GetBuildings();
		if pCityBuildings:HasBuilding( GameInfo.Buildings[ sWallsType ].Index ) then
			sStrengthToolTip = sStrengthToolTip..(string.len(sStrengthToolTip) == 0 and "" or "[NEWLINE]")..Locale.Lookup(GameInfo.Buildings[ sWallsType ].Name);
			if pCityBuildings:IsPillaged( GameInfo.Buildings[ sWallsType ].Index ) then
				sStrength = sStrength.."[COLOR_Red]!";
				sStrengthToolTip = sStrengthToolTip.." "..Locale.Lookup("LOC_TOOLTIP_PLOT_PILLAGED_TEXT");
			else
				sStrength = sStrength.."[COLOR_Green]!";
			end
		end
	end
	CheckForWalls("BUILDING_WALLS");
	CheckForWalls("BUILDING_CASTLE");
	CheckForWalls("BUILDING_STAR_FORT");
	-- Garrison
	if kCityData.IsGarrisonUnit then 
		sStrength = sStrength.."[ICON_Fortified]";
		sStrengthToolTip = sStrengthToolTip..(string.len(sStrengthToolTip) == 0 and "" or "[NEWLINE]")..Locale.Lookup("LOC_BRS_TOOLTIP_GARRISON").." ("..kCityData.GarrisonUnitName..")";
	end
	pCityInstance.Strength:SetText( sStrength );
	pCityInstance.Strength:SetToolTipString( sStrengthToolTip );

	-- WarWeariness
	local warWearyValue:number = kCityData.AmenitiesLostFromWarWeariness;
	--pCityInstance.WarWeariness:SetText( (warWearyValue==0) and "0" or ColorRed("-"..tostring(warWearyValue)) );
	-- Damage
	--pCityInstance.Damage:SetText( tostring(kCityData.Damage) );	-- Infixo (vanilla version)
	local sDamageWWText:string = "0";
	if kCityData.HitpointsTotal > kCityData.HitpointsCurrent then sDamageWWText = ColorRed(kCityData.HitpointsTotal - kCityData.HitpointsCurrent); end
	sDamageWWText = sDamageWWText.." / "..( (warWearyValue==0) and "0" or ColorRed("-"..tostring(warWearyValue)) );
	pCityInstance.Damage:SetText( sDamageWWText );
	--pCityInstance.Damage:SetToolTipString( Locale.Lookup("LOC_HUD_REPORTS_HEADER_DAMAGE").." / "..Locale.Lookup("LOC_HUD_REPORTS_HEADER_WAR_WEARINESS") );
	
	-- Trading Posts
	kCityData.IsTradingPost = false;
	for _,tpPlayer in ipairs(kCityData.TradingPosts) do
		if tpPlayer == Game.GetLocalPlayer() then kCityData.IsTradingPost = true; break; end
	end
	pCityInstance.TradingPost:SetHide(not kCityData.IsTradingPost);
	
	-- Trading Routes
	local tTRTT:table = {};
	pCityInstance.TradeRoutes:SetText("[COLOR_White]"..( #kCityData.OutgoingRoutes > 0 and tostring(#kCityData.OutgoingRoutes) or "" ).."[ENDCOLOR]");
	for i,route in ipairs(kCityData.OutgoingRoutes) do
		-- Find destination city
		local pDestPlayer:table = Players[route.DestinationCityPlayer];
		local pDestPlayerCities:table = pDestPlayer:GetCities();
		local pDestCity:table = pDestPlayerCities:FindID(route.DestinationCityID);
		table.insert(tTRTT, Locale.Lookup(pDestCity:GetName()));
	end
	pCityInstance.TradeRoutes:SetToolTipString( table.concat(tTRTT, ", ") );
	
	-- Districts
	pCityInstance.Districts:SetText( GetDistrictsForCity(kCityData) );
	
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
		kCityData.Governor = governorDefinition.GovernorType;
		-- name and promotions
		local tGovernorTT:table = {};
		table.insert(tGovernorTT, Locale.Lookup(governorDefinition.Name)..", "..Locale.Lookup(governorDefinition.Title));
		for row in GameInfo.GovernorPromotions() do
			if pAssignedGovernor:HasPromotion( row.Index ) then table.insert(tGovernorTT, Locale.Lookup(row.Name)..": "..Locale.Lookup(row.Description)); end
		end
		pCityInstance.Governor:SetToolTipString(table.concat(tGovernorTT, "[NEWLINE]"));
	else
		pCityInstance.Governor:SetText("");
		pCityInstance.Governor:SetToolTipString("");
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
		if aCity == bCity then 
			aCity = t[a].City:GetCulturalIdentity():GetLoyaltyPerTurn();
			bCity = t[b].City:GetCulturalIdentity():GetLoyaltyPerTurn();
		end
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
	elseif type == "trpost" then
		aCity = ( t[a].IsTradingPost and 1 or 0 );
		bCity = ( t[b].IsTradingPost and 1 or 0 );
	elseif type == "numtr" then
		aCity = #t[a].OutgoingRoutes;
		bCity = #t[b].OutgoingRoutes;
	elseif type == "districts" then
		aCity = t[a].NumDistricts
		bCity = t[b].NumDistricts
	elseif type == "religion" then
		aCity = t[a].City:GetReligion():GetMajorityReligion();
		bCity = t[b].City:GetReligion():GetMajorityReligion();
		if aCity > 0 and bCity > 0 then 
			-- both cities have religion
			if descend then return bCity > aCity else return bCity < aCity end
		elseif aCity > 0 then
			-- only A has religion, must ALWAYS be before B
			return true
		elseif bCity > 0 then
			-- only B has religion, must ALWAYS be before A
		end
		-- none has, check pantheons
		aCity = t[a].City:GetReligion():GetActivePantheon();
		bCity = t[b].City:GetReligion():GetActivePantheon();
		if aCity > 0 and bCity > 0 then 
			-- both cities have a pantheon
			if descend then return bCity > aCity else return bCity < aCity end
		elseif aCity > 0 then
			-- only A has pantheon, must ALWAYS be before B
			return true
		elseif bCity > 0 then
			-- only B has pantheon, must ALWAYS be before A
		end
		-- none has, no more checks
		return false
	else
		-- nothing to do here
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
	
	pHeaderInstance.CityReligionButton:RegisterCallback( Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_cities( "religion", instance ) end )
	pHeaderInstance.CityNameButton:RegisterCallback( Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_cities( "name", instance ) end )
	if bIsRiseFall then pHeaderInstance.CityGovernorButton:RegisterCallback( Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_cities( "gover", instance ) end ) end -- Infixo
	if bIsRiseFall then pHeaderInstance.CityLoyaltyButton:RegisterCallback( Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_cities( "loyal", instance ) end ) end -- Infixo
	pHeaderInstance.CityPopulationButton:RegisterCallback( Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_cities( "pop", instance ) end )
	--pHeaderInstance.CityHousingButton:RegisterCallback( Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_cities( "house", instance ) end ) end -- Infixo
	pHeaderInstance.CityGrowthButton:RegisterCallback( Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_cities( "growth", instance ) end )
	pHeaderInstance.CityAmenitiesButton:RegisterCallback( Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_cities( "amen", instance ) end )
	pHeaderInstance.CityHappinessButton:RegisterCallback( Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_cities( "happy", instance ) end )
	--pHeaderInstance.CityWarButton:RegisterCallback( Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_cities( "war", instance ) end )
	pHeaderInstance.CityDistrictsButton:RegisterCallback( Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_cities( "districts", instance ) end )
	pHeaderInstance.CityStatusButton:RegisterCallback( Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_cities( "status", instance ) end )
	pHeaderInstance.CityStrengthButton:RegisterCallback( Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_cities( "str", instance ) end )
	pHeaderInstance.CityDamageButton:RegisterCallback( Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_cities( "dam", instance ) end )
	pHeaderInstance.CityTradingPostButton:RegisterCallback( Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_cities( "trpost", instance ) end );
	pHeaderInstance.CityTradeRoutesButton:RegisterCallback( Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_cities( "numtr", instance ) end );

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
	Controls.BottomMinorsFilters:SetHide( true );
	Controls.Scroll:SetSizeY( Controls.Main:GetSizeY() - 88);
	-- Remember this tab when report is next opened: ARISTOS
	m_kCurrentTab = 3;
end


-- ===========================================================================
-- UNITS PAGE
-- ===========================================================================

-- returns the name of the City that the unit is currently in, or ""
function GetCityForUnit(pUnit:table)
	local pCity:table = Cities.GetCityInPlot( pUnit:GetX(), pUnit:GetY() );
	return ( pCity and Locale.Lookup(pCity:GetName()) ) or "";
end

-- returns the icon for the District that the unit is currently in, or ""
function GetDistrictIconForUnit(pUnit:table)
	local pPlot:table = Map.GetPlot( pUnit:GetX(), pUnit:GetY() );
	if not pPlot then return ""; end -- assert
	local eDistrictType:number = pPlot:GetDistrictType();
	--print("Unit", pUnit:GetName(), eDistrictType);
	if eDistrictType < 0 then return ""; end
	local sDistrictType:string = GameInfo.Districts[ eDistrictType ].DistrictType;
	if GameInfo.DistrictReplaces[ sDistrictType ] then sDistrictType = GameInfo.DistrictReplaces[ sDistrictType ].ReplacesDistrictType; end
	return GetFontIconForDistrict(sDistrictType);
end

function unit_sortFunction( descend, type, t, a, b )
	local aUnit, bUnit

	if type == "type" then
		aUnit = UnitManager.GetTypeName( t[a] )
		bUnit = UnitManager.GetTypeName( t[b] )
	elseif type == "name" then
		aUnit = Locale.Lookup( t[a]:GetName() )
		bUnit = Locale.Lookup( t[b]:GetName() )
		if aUnit == bUnit then
			aUnit = t[a]:GetMilitaryFormation()
			bUnit = t[b]:GetMilitaryFormation()
		end
	elseif type == "maintenance" then
		aUnit = t[a].MaintenanceAfterDiscount;
		bUnit = t[b].MaintenanceAfterDiscount;
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
	elseif type == "city" then
		aUnit = t[a].NearCityName
		bUnit = t[b].NearCityName
		if aUnit == bUnit then
			aUnit = t[a].NearCityDistance
			bUnit = t[b].NearCityDistance
		end
		--[[
		if aUnit ~= "" and bUnit ~= "" then 
			if descend then return aUnit > bUnit else return aUnit < bUnit end
		else
			if     aUnit == "" then return false;
			elseif bUnit == "" then return true;
			else                    return false; end
		end
		--]]
	else
		return false; -- assert
	end
	
	if descend then return aUnit > bUnit else return aUnit < bUnit end
	
end

function sort_units( type, group, parent )

	local i = 0
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

	--if unitInstance.Formation then unitInstance.Formation:SetHide( true ) end

	local textureOffsetX:number, textureOffsetY:number, textureSheet:string = IconManager:FindIconAtlas( "ICON_" .. UnitManager.GetTypeName( unit ), 32 )
	unitInstance.UnitType:SetTexture( textureOffsetX, textureOffsetY, textureSheet )
	--unitInstance.UnitType:SetToolTipString( Locale.Lookup( GameInfo.Units[UnitManager.GetTypeName( unit )].Name ) )
	unitInstance.UnitType:SetToolTipString( Locale.Lookup(GameInfo.Units[unit:GetUnitType()].Name).."[NEWLINE]"..Locale.Lookup(GameInfo.Units[unit:GetUnitType()].Description) );

	-- debug section to see Modifiers for all units
	--[[
	local tPromoTT:table = {};
	table.insert(tPromoTT, Locale.Lookup( GameInfo.Units[UnitManager.GetTypeName( unit )].Name ));
	local tUnitModifiers:table = m_kModifiersUnits[ unit:GetID() ];
	if table.count(tUnitModifiers) > 0 then table.insert(tPromoTT, TOOLTIP_SEP); end
	local i = 0;
	for _,mod in ipairs(tUnitModifiers) do
		i = i + 1;
		table.insert(tPromoTT, i..". "..Locale.Lookup(mod.OwnerName)..": "..mod.Modifier.ModifierId.." ("..RMA.GetObjectNameForModifier(mod.Modifier.ModifierId)..") "..mod.Modifier.EffectType.." "..( mod.Modifier.Text and "|"..Locale.Lookup(mod.Modifier.Text).."|" or "-"));
	end
	unitInstance.UnitType:SetToolTipString( table.concat(tPromoTT, "[NEWLINE]") );
	--]]

	unitInstance.UnitName:SetText( Locale.Lookup(unit:GetName()) );
	
	-- adds the status icon
	local activityType:number = UnitManager.GetActivityType( unit )
	--print("Unit", unit:GetID(),activityType,unit:GetSpyOperation(),unit:GetSpyOperationEndTurn());
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
		unitInstance.UnitMove:SetText( tostring(unit:GetFormationMovesRemaining()).."/"..tostring(unit:GetFormationMaxMoves()).." [ICON_Formation]" );
		--unitInstance.Formation:SetHide( false )
		unitInstance.UnitMove:SetToolTipString( Locale.Lookup("LOC_HUD_UNIT_ACTION_AUTOEXPLORE_IN_FORMATION") );
	elseif unitInstance.UnitMove then
		if unit:GetMovesRemaining() == 0 then bIsMoving = false; end
		unitInstance.UnitMove:SetText( (bIsMoving and "[COLOR_Red]" or "")..tostring( unit:GetMovesRemaining() ).."/"..tostring( unit:GetMaxMoves() )..(bIsMoving and "[ENDCOLOR]" or "") )
		unitInstance.UnitMove:SetToolTipString( "" );
	end
	
	unit.District = GetDistrictIconForUnit(unit);
	unitInstance.UnitDistrict:SetText(unit.District);
	--unit.City = GetCityForUnit(unit);
	--unitInstance.UnitCity:SetText(unit.City);
	local sCityName:string = ( unit.NearCityIsCapital and "[ICON_Capital]" or "" )..unit.NearCityName;
	if     unit.NearCityDistance == 0 then sCityName = "[COLOR:16,232,75,160]"..sCityName.."[ENDCOLOR]";
	elseif unit.NearCityIsOurs        then sCityName = sCityName.." "..unit.NearCityDistance;
	else                                   sCityName = "[COLOR_Red]"..sCityName.." "..unit.NearCityDistance.."[ENDCOLOR]"; end
	unitInstance.UnitCity:SetText( (unit.NearCityDistance > 3) and "" or sCityName );
	
	unitInstance.UnitMaintenance:SetText( toPlusMinusString(-unit.MaintenanceAfterDiscount) );
end

-- simple texts for modifiers' effects
local tTextsForEffects:table = {
	EFFECT_ATTACH_MODIFIER = "LOC_GREATPERSON_PASSIVE_NAME_DEFAULT",
	EFFECT_ADJUST_UNIT_EXTRACT_SEA_ARTIFACTS = "[ICON_RESOURCE_SHIPWRECK]",
	EFFECT_ADJUST_UNIT_NUM_ATTACKS = "LOC_PROMOTION_WOLFPACK_DESCRIPTION",
	EFFECT_ADJUST_UNIT_ATTACK_AND_MOVE = "LOC_PROMOTION_GUERRILLA_DESCRIPTION",
	EFFECT_ADJUST_UNIT_MOVE_AND_ATTACK = "LOC_PROMOTION_GUERRILLA_DESCRIPTION",
	EFFECT_ADJUST_UNIT_BYPASS_COMBAT_UNIT = "LOC_ABILITY_BYPASS_COMBAT_UNIT_NAME",
	EFFECT_ADJUST_UNIT_IGNORE_TERRAIN_COST = "LOC_ABILITY_IGNORE_TERRAIN_COST_NAME", -- Arguments.Type = ALL HILLS FOREST
	EFFECT_ADJUST_UNIT_PARADROP_ABILITY = "LOC_UNITCOMMAND_PARADROP_DESCRIPTION",
	EFFECT_ADJUST_UNIT_SEE_HIDDEN = "LOC_ABILITY_SEE_HIDDEN_NAME",
	EFFECT_ADJUST_UNIT_HIDDEN_VISIBILITY = "LOC_ABILITY_STEALTH_NAME",
	EFFECT_ADJUST_UNIT_RAIDING = "LOC_ABILITY_COASTAL_RAID_NAME",
	EFFECT_ADJUST_UNIT_IGNORE_RIVERS = "LOC_PROMOTION_AMPHIBIOUS_NAME",
	EFFECT_ADJUST_UNIT_IGNORE_SHORES = "[ICON_CheckmarkBlue]{LOC_UNITOPERATION_DISEMBARK_DESCRIPTION}",
	EFFECT_ADJUST_PLAYER_RANDOM_CIVIC_BOOST_GOODY_HUT = "{LOC_HUD_POPUP_CIVIC_BOOST_UNLOCKED}[ICON_CivicBoosted]",
	EFFECT_ADJUST_PLAYER_RANDOM_TECHNOLOGY_BOOST_GOODY_HUT = "{LOC_HUD_POPUP_TECH_BOOST_UNLOCKED}[ICON_TechBoosted]",
};

function group_military( unit, unitInstance, group, parent, type )

	-- for military we'll show its base strength also
	local eFormation:number = unit:GetMilitaryFormation();
	local iCombat:number, iRanged:number, iBombard:number = unit:GetCombat(), unit:GetRangedCombat(), unit:GetBombardCombat();
	
	-- name will be: name .. formation .. strength
	local sText:string = Locale.Lookup( unit:GetName() );
	if     eFormation == MilitaryFormationTypes.CORPS_FORMATION then sText = sText .. " [ICON_Corps]";
	elseif eFormation == MilitaryFormationTypes.ARMY_FORMATION  then sText = sText .. " [ICON_Army]" ;
	end
	if     iBombard > 0 then sText = sText.." [ICON_Bombard]"..tostring(iBombard);
	elseif iRanged > 0  then sText = sText.." [ICON_Ranged]"..tostring(iRanged);
	elseif iCombat > 0  then sText = sText.." [ICON_Strength]"..tostring(iCombat);
	end
	unitInstance.UnitName:SetText( sText );

	-- Level and Promotions
	local unitExp : table = unit:GetExperience()
	local iUnitLevel:number = unitExp:GetLevel();
	if     iUnitLevel < 2  then unitInstance.UnitLevel:SetText( tostring(iUnitLevel) );
	elseif iUnitLevel == 2 then unitInstance.UnitLevel:SetText( tostring(iUnitLevel).." [ICON_Promotion]" );
	else                        unitInstance.UnitLevel:SetText( tostring(iUnitLevel).." [ICON_Promotion]"..string.rep("*", iUnitLevel-2) ); end
	local tPromoTT:table = {};
	for _,promo in ipairs(unitExp:GetPromotions()) do
		table.insert(tPromoTT, Locale.Lookup(GameInfo.UnitPromotions[promo].Name)..": "..Locale.Lookup(GameInfo.UnitPromotions[promo].Description));
	end
	-- this section might grow!
	local tUnitModifiers:table = m_kModifiersUnits[ unit:GetID() ];
	local tMod:table = nil;
	local sText:string = "";
	if table.count(tUnitModifiers) > 0 then table.insert(tPromoTT, TOOLTIP_SEP); end
	local iPromoNum:number = 0;
	for _,mod in ipairs(tUnitModifiers) do
		local function AddExtraPromoText(sText:string)
			iPromoNum = iPromoNum + 1;
			table.insert(tPromoTT, tostring(iPromoNum)..". "..Locale.Lookup(mod.OwnerName).." ("..RMA.GetObjectNameForModifier(mod.Modifier.ModifierId)..") "..sText);
		end
		tMod = mod.Modifier;
		sText = ""; if tMod.Text then sText = Locale.Lookup(tMod.Text); end
		if sText ~= "" then
			AddExtraPromoText( sText );
		elseif tMod.EffectType == "EFFECT_ADJUST_PLAYER_STRENGTH_MODIFIER" or tMod.EffectType == "EFFECT_ADJUST_UNIT_DIPLO_VISIBILITY_COMBAT_MODIFIER" then
			AddExtraPromoText( string.format("%+d [ICON_Strength]", tonumber(tMod.Arguments.Amount))); -- Strength
		elseif tMod.EffectType == "EFFECT_GRANT_ABILITY" then
			local unitAbility:table = GameInfo.UnitAbilities[ tMod.Arguments.AbilityType ];
			if unitAbility then
				AddExtraPromoText( Locale.Lookup(unitAbility.Name)..": "..Locale.Lookup(unitAbility.Description)); -- LOC_CIVICS_KEY_ABILITY
			else
				AddExtraPromoText( tMod.EffectType.." [COLOR_Red]"..tMod.Arguments.AbilityType.."[ENDCOLOR]")
			end
		elseif tMod.EffectType == "EFFECT_GRANT_PROMOTION" then
			local unitPromotion:table = GameInfo.UnitPromotions[ tMod.Arguments.PromotionType ];
			if unitPromotion then
				AddExtraPromoText( Locale.Lookup(unitPromotion.Name)..": "..Locale.Lookup(unitPromotion.Description));
			else
				AddExtraPromoText( tMod.EffectType.." [COLOR_Red]"..tMod.Arguments.PromotionType.."[ENDCOLOR]")
			end
		elseif tMod.EffectType == "EFFECT_ADJUST_UNIT_EXPERIENCE_MODIFIER" then
			AddExtraPromoText( string.format("%+d%% ", tonumber(tMod.Arguments.Amount))..Locale.Lookup("LOC_HUD_UNIT_PANEL_XP")); -- +x%
		elseif tMod.EffectType == "EFFECT_ADJUST_UNIT_FLANKING_BONUS_MODIFIER" then
			AddExtraPromoText( Locale.Lookup("LOC_COMBAT_PREVIEW_FLANKING_BONUS_DESC", tMod.Arguments.Percent.."%") ); -- +x%
		elseif tMod.EffectType == "EFFECT_ADJUST_UNIT_SEA_MOVEMENT" or tMod.EffectType == "EFFECT_ADJUST_UNIT_MOVEMENT" then
			AddExtraPromoText( string.format("%+d [ICON_Movement]", tonumber(tMod.Arguments.Amount))); -- Movement
		elseif tMod.EffectType == "EFFECT_ADJUST_UNIT_VALID_TERRAIN" then
			AddExtraPromoText( Locale.Lookup( GameInfo.Terrains[tMod.Arguments.TerrainType].Name ) );
		elseif tMod.EffectType == "EFFECT_ADJUST_UNIT_ATTACK_RANGE" then
			AddExtraPromoText( string.format("%+d [ICON_Range]", tonumber(tMod.Arguments.Amount)));
		elseif tTextsForEffects[tMod.EffectType] then
			AddExtraPromoText( Locale.Lookup(tTextsForEffects[tMod.EffectType]) );
		elseif tMod.EffectType == "EFFECT_ADJUST_UNIT_STRENGTH_REDUCTION_FOR_DAMAGE_MODIFIER" then
			AddExtraPromoText( string.format("[ICON_Damaged] -%d%%", tonumber(tMod.Arguments.Amount)) ); -- +x%
		elseif tMod.EffectType == "EFFECT_ADJUST_UNIT_POST_COMBAT_HEAL" then
			AddExtraPromoText( Locale.Lookup("LOC_BRS_HEADER_HEALTH")..string.format(" %+d", tonumber(tMod.Arguments.Amount)) ); -- +x HP
		elseif tMod.EffectType == "EFFECT_ADJUST_UNIT_BARBARIAN_COMBAT" then
			local iAdvStr:number = tonumber(tMod.Arguments.Amount);
			AddExtraPromoText( string.gsub(Locale.Lookup("LOC_COMBAT_PREVIEW_BONUS_VS_BARBARIANS", iAdvStr), "+"..tostring(iAdvStr), "+"..tostring(iAdvStr).." [ICON_Strength]") );  -- +{1_Value} Advantage vs. Barbarians
		else
			AddExtraPromoText( "[COLOR_Grey]"..tMod.EffectType.."[ENDCOLOR]" );
		end
	end
	unitInstance.UnitLevel:SetToolTipString( table.concat(tPromoTT, "[NEWLINE]") );
	
	-- XP and Promotion Available
	local bCanStart, tResults = UnitManager.CanStartCommand( unit, UnitCommandTypes.PROMOTE, true, true );
	unitInstance.UnitExp:SetText( tostring(unitExp:GetExperiencePoints()).."/"..tostring(unitExp:GetExperienceForNextLevel())..((bCanStart and tResults) and " [ICON_Promotion]" or "") );
	unitInstance.UnitExp:SetToolTipString( (bCanStart and tResults) and Locale.Lookup("LOC_HUD_UNIT_ACTION_AUTOEXPLORE_PROMOTION_AVAILABLE") or "" );

	-- Unit Health
	local iHealthPoints:number = unit:GetMaxDamage() - unit:GetDamage();
	local fHealthPercent:number = iHealthPoints / unit:GetMaxDamage();
	local sHealthColor:string = "";
	-- Common format is 0xBBGGRRAA (BB blue, GG green, RR red, AA alpha); stupid Firaxis - it's 0xAABBGGRR
	if     fHealthPercent > 0.7 then sHealthColor = "[COLOR:16,232,75,160]";   -- COLORS.METER_HP_GOOD 0xFF4BE810
	elseif fHealthPercent > 0.4 then sHealthColor = "[COLOR:248,255,45,160]";  -- COLORS.METER_HP_OK   0xFF2DFFF8
	else                             sHealthColor = "[COLOR:245,1,1,160]"; end -- COLORS.METER_HP_BAD  0xFF0101F5
	unitInstance.UnitHealth:SetText( sHealthColor..tostring(iHealthPoints).."/"..tostring(unit:GetMaxDamage()).."[ENDCOLOR]" );
	
	-- upgrade flag
	unitInstance.Upgrade:SetHide( true )
	--ARISTOS: a "looser" test for the Upgrade action, to be able to show the disabled arrow if Upgrade is not possible
	local bCanStart = UnitManager.CanStartCommand( unit, UnitCommandTypes.UPGRADE, true);
	if ( bCanStart ) then
		unitInstance.Upgrade:SetHide( false )
		--ARISTOS: Now we "really" test if we can Upgrade the unit!
		local bCanStartNow, tResults = UnitManager.CanStartCommand( unit, UnitCommandTypes.UPGRADE, false, true);
		unitInstance.Upgrade:SetDisabled(not bCanStartNow);
		unitInstance.Upgrade:SetAlpha((not bCanStartNow and 0.5) or 1 ); --ARISTOS: dim if not upgradeable
		-- upgrade callback
		unitInstance.Upgrade:RegisterCallback( Mouse.eLClick, function()
			-- the only case where we need to re-sort units preserving current order
			-- actual re-sort must be done in Event, otherwise unit info is not refreshed (ui cache?)
			tUnitSort.type = type; tUnitSort.group = group; tUnitSort.parent = parent;
			UnitManager.RequestCommand( unit, UnitCommandTypes.UPGRADE );
		end )
		-- tooltip
		local upgradeUnitName = GameInfo.Units[tResults[UnitOperationResults.UNIT_TYPE]].Name;
		local toolTipString:string = Locale.Lookup( "LOC_UNITOPERATION_UPGRADE_INFO", Locale.Lookup(upgradeUnitName), unit:GetUpgradeCost() ); -- Upgrade to {1_Unit}: {2_Amount} [ICON_Gold]Gold
		if tResults[UnitOperationResults.FAILURE_REASONS] then
			-- Add the reason(s) to the tool tip
			for i,v in ipairs(tResults[UnitOperationResults.FAILURE_REASONS]) do
				toolTipString = toolTipString .. "[NEWLINE]" .. "[COLOR:Red]" .. Locale.Lookup(v) .. "[ENDCOLOR]";
			end
		end
		unitInstance.Upgrade:SetToolTipString( toolTipString );
	end
	
end

function group_civilian( unit, unitInstance, group, parent, type )

	unitInstance.UnitCharges:SetText( tostring( unit:GetBuildCharges() ) )
	
end

function group_great( unit, unitInstance, group, parent, type )

	unitInstance.UnitClass:SetText( Locale.Lookup( GameInfo.GreatPersonClasses[unit:GetGreatPerson():GetClass()].Name ) )

end

function ShowUnitPromotions(unit:table, unitInstance:table)
	-- Level and Promotions
	local tPromoTT:table = {};
	for _,promo in ipairs(unit:GetExperience():GetPromotions()) do
		table.insert(tPromoTT, Locale.Lookup(GameInfo.UnitPromotions[promo].Name)..": "..Locale.Lookup(GameInfo.UnitPromotions[promo].Description));
	end
	if     #tPromoTT == 0 then unitInstance.UnitLevel:SetText("");
	elseif #tPromoTT == 1 then unitInstance.UnitLevel:SetText("[ICON_Promotion]");
	else                       unitInstance.UnitLevel:SetText("[ICON_Promotion]"..string.rep("*", #tPromoTT-1) ); end
	unitInstance.UnitLevel:SetToolTipString( table.concat(tPromoTT, "[NEWLINE]") );
end

function group_religious( unit, unitInstance, group, parent, type )

	ShowUnitPromotions(unit, unitInstance);
	unitInstance.UnitSpreads:SetText( unit:GetSpreadCharges() )
	unitInstance.UnitStrength:SetText( unit:GetReligiousStrength() )

end

function group_spy( unit, unitInstance, group, parent, type )

	ShowUnitPromotions(unit, unitInstance);

	-- operation
	local operationType : number = unit:GetSpyOperation();
	
	unitInstance.UnitOperation:SetText( "-" );
	unitInstance.UnitTurns:SetText( "[COLOR_Red]0[ENDCOLOR]" );
	unit.mission = "-";
	unit.turns = 0;

	if ( operationType ~= -1 ) then
		-- Mission Name
		local operationInfo:table = GameInfo.UnitOperations[operationType];
		unit.mission = Locale.Lookup( operationInfo.Description );
		unitInstance.UnitOperation:SetText( unit.mission );
		-- Turns Remaining
		unit.turns = unit:GetSpyOperationEndTurn() - Game.GetCurrentGameTurn()
		--unitInstance.UnitTurns:SetText( Locale.Lookup( "LOC_UNITPANEL_ESPIONAGE_MORE_TURNS", unit:GetSpyOperationEndTurn() - Game.GetCurrentGameTurn() ) )
		unitInstance.UnitTurns:SetText( tostring(unit.turns) );
	end

end

function group_trader( unit, unitInstance, group, parent, type )

	local owningPlayer:table = Players[unit:GetOwner()];
	local cities:table = owningPlayer:GetCities();
	--[[
	local yieldtype: table = {
		YIELD_FOOD = "[ICON_Food]",
		YIELD_PRODUCTION = "[ICON_Production]",
		YIELD_GOLD = "[ICON_Gold]",
		YIELD_SCIENCE = "[ICON_Science]",
		YIELD_CULTURE = "[ICON_Culture]",
		YIELD_FAITH = "[ICON_Faith]",
	};
	--]]
	local yields : string = ""
	
	unitInstance.UnitYields:SetText( "" );
	unitInstance.UnitRoute:SetText( "[COLOR_Red]"..Locale.Lookup("LOC_UNITOPERATION_MAKE_TRADE_ROUTE_DESCRIPTION") );
	unit.yields = ""
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
						yields = yields .. GameInfo.Yields[yieldInfo.YieldIndex].IconString .. "+" .. yieldInfo.Amount
						unitInstance.UnitYields:SetText( yields )
						unit.yields = yields
					end
				end
			end
		end
	end
	
end

function ViewUnitsPage()

	ResetTabForNewPageContent();
	tUnitSort.parent = nil;
	
	for iUnitGroup, kUnitGroup in spairs( m_kUnitDataReport, function( t, a, b ) return t[b].ID > t[a].ID end ) do
		local instance : table = NewCollapsibleGroupInstance()
		
		instance.RowHeaderButton:SetText( Locale.Lookup(kUnitGroup.Name) );
		instance.RowHeaderLabel:SetHide( false ); --BRS
		instance.RowHeaderLabel:SetText( Locale.Lookup("LOC_HUD_REPORTS_TOTALS").." "..tostring(#kUnitGroup.units) );
		instance.AmenitiesContainer:SetHide(true);
		
		local pHeaderInstance:table = {}
		ContextPtr:BuildInstanceForControl( kUnitGroup.Header, pHeaderInstance, instance.ContentStack )

		-- Infixo: important info - iUnitGroup is NOT integer nor table, it is a STRING taken from FORMATION_CLASS_xxx
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
		if pHeaderInstance.UnitCityButton then     pHeaderInstance.UnitCityButton:RegisterCallback(    Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_units( "city", iUnitGroup, instance ) end ) end
		if pHeaderInstance.UnitMaintenanceButton then pHeaderInstance.UnitMaintenanceButton:RegisterCallback( Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_units( "maintenance", iUnitGroup, instance ) end ) end

		instance.Descend = false;
		for _,unit in spairs( kUnitGroup.units, function( t, a, b ) return unit_sortFunction( false, "name", t, a, b ) end ) do -- initial sort by name ascending
			local unitInstance:table = {}
			table.insert( instance.Children, unitInstance )
			
			ContextPtr:BuildInstanceForControl( kUnitGroup.Entry, unitInstance, instance.ContentStack );
			
			common_unit_fields( unit, unitInstance )
			
			if kUnitGroup.func then kUnitGroup.func( unit, unitInstance, iUnitGroup, instance, "name" ) end
			
			-- allows you to select a unit and zoom to them
			unitInstance.LookAtButton:RegisterCallback( Mouse.eLClick, function() Close(); UI.LookAtPlot( unit:GetX( ), unit:GetY( ) ); UI.SelectUnit( unit ); end )
			unitInstance.LookAtButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound( "Main_Menu_Mouse_Over" ); end )
		end

		SetGroupCollapsePadding(instance, 0); --pFooterInstance.Top:GetSizeY() )
		RealizeGroup( instance );
	end

	Controls.Stack:CalculateSize();
	Controls.Scroll:CalculateSize();
	
	Controls.CollapseAll:SetHide( false );
	Controls.BottomYieldTotals:SetHide( true )
	Controls.BottomResourceTotals:SetHide( true )
	Controls.BottomPoliciesFilters:SetHide( true );
	Controls.BottomMinorsFilters:SetHide( true );
	Controls.Scroll:SetSizeY( Controls.Main:GetSizeY() - 88 )
	-- Remember this tab when report is next opened: ARISTOS
	m_kCurrentTab = 5;
end


-- ===========================================================================
-- CURRENT DEALS PAGE
-- ===========================================================================

function ViewDealsPage()

	ResetTabForNewPageContent();
	
	for j, pDeal in spairs( m_kCurrentDeals, function( t, a, b ) return t[b].EndTurn > t[a].EndTurn end ) do
		--print("deal", pDeal.EndTurn, Game.GetCurrentGameTurn(), pDeal.EndTurn-Game.GetCurrentGameTurn());
		local iNumTurns:number = pDeal.EndTurn - Game.GetCurrentGameTurn();
		--local turns = "turns"
		--if ending == 1 then turns = "turn" end

		local instance : table = NewCollapsibleGroupInstance()

		instance.RowHeaderButton:SetText( Locale.Lookup("LOC_HUD_REPORTS_TRADE_DEAL_WITH")..pDeal.WithCivilization );
		instance.RowHeaderLabel:SetText( tostring(iNumTurns).." "..Locale.Lookup("LOC_HUD_REPORTS_TURNS_UNTIL_COMPLETED", iNumTurns).." ("..tostring(pDeal.EndTurn)..")" );
		instance.RowHeaderLabel:SetHide( false );
		instance.AmenitiesContainer:SetHide(true);

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
		pFooterInstance.Outgoing:SetText( Locale.Lookup("LOC_HUD_REPORTS_TOTALS")..#pDeal.Sending )
		pFooterInstance.Incoming:SetText( Locale.Lookup("LOC_HUD_REPORTS_TOTALS")..#pDeal.Receiving )
	
		SetGroupCollapsePadding( instance, pFooterInstance.Top:GetSizeY() )
		RealizeGroup( instance );
	end

	Controls.Stack:CalculateSize();
	Controls.Scroll:CalculateSize();

	Controls.CollapseAll:SetHide( false );
	Controls.BottomYieldTotals:SetHide( true );
	Controls.BottomResourceTotals:SetHide( true );
	Controls.BottomPoliciesFilters:SetHide( true );
	Controls.BottomMinorsFilters:SetHide( true );
	Controls.Scroll:SetSizeY( Controls.Main:GetSizeY() - 88);
	-- Remember this tab when report is next opened: ARISTOS
	m_kCurrentTab = 4;
end


-- ===========================================================================
-- POLICY PAGE
-- ===========================================================================

local tPolicyOrder:table = {
	SLOT_MILITARY = 1,
	SLOT_ECONOMIC = 2,
	SLOT_DIPLOMATIC = 3,
	SLOT_GREAT_PERSON = 4,
	SLOT_WILDCARD = 5,
	SLOT_DARKAGE = 6,
	SLOT_PANTHEON = 7,
	SLOT_FOLLOWER = 8,
};

local tPolicyGroupNames:table = {};

function InitializePolicyData()
	-- Compatbility tweak for mods adding new slot types (e.g. Rule with Faith)
	for row in GameInfo.GovernmentSlots() do
		if tPolicyOrder[row.GovernmentSlotType] == nil and row.GovernmentSlotType ~= "SLOT_WILDCARD" then
			tPolicyOrder[row.GovernmentSlotType] = table.count(tPolicyOrder) + 1;
		end
	end
	-- init group names
	for slot,_ in pairs(tPolicyOrder) do
		tPolicyGroupNames[ slot ] = Locale.Lookup( string.gsub(slot, "SLOT_", "LOC_GOVT_POLICY_TYPE_") );
	end
	-- exceptions
	tPolicyGroupNames.SLOT_GREAT_PERSON = Locale.Lookup("LOC_PEDIA_GOVERNMENTS_PAGEGROUP_GREATPEOPLE_POLICIES_NAME");
	tPolicyGroupNames.SLOT_PANTHEON     = Locale.Lookup("LOC_PEDIA_RELIGIONS_PAGEGROUP_PANTHEON_BELIEFS_NAME");
	tPolicyGroupNames.SLOT_FOLLOWER     = Locale.Lookup("LOC_PEDIA_RELIGIONS_PAGEGROUP_FOLLOWER_BELIEFS_NAME");
	-- Rise & Fall
	if not bIsRiseFall then
		tPolicyOrder.SLOT_WILDCARD = nil;
		tPolicyOrder.SLOT_DARKAGE = nil;
	end
	--print("*** POLICY ORDER ***"); dshowtable(tPolicyOrder);
	--print("*** POLICY GROUP NAMES ***"); dshowtable(tPolicyGroupNames);
end


function UpdatePolicyData()
	--print("*** UPDATE POLICY DATA ***");
	Timer1Start();
	m_kPolicyData = {}; for slot,_ in pairs(tPolicyOrder) do m_kPolicyData[slot] = {}; end -- reset all data
	local ePlayerID:number = Game.GetLocalPlayer();
	local pPlayer:table = Players[ePlayerID];
	if not pPlayer then return; end -- assert
	local pPlayerCulture:table = pPlayer:GetCulture();
	-- find out which polices are slotted now
	local tSlottedPolicies:table = {};
	for i = 0, pPlayerCulture:GetNumPolicySlots()-1 do
		if pPlayerCulture:GetSlotPolicy(i) ~= -1 then tSlottedPolicies[ pPlayerCulture:GetSlotPolicy(i) ] = true; end
	end
	--print("...Slotted policies"); dshowtable(tSlottedPolicies);
	-- iterate through all policies
	for policy in GameInfo.Policies() do
		--print("Policy:", policy.Index, policy.PolicyType, policy.GovernmentSlotType);
		local policyData:table = {
			Index = policy.Index,
			Name = Locale.Lookup(policy.Name),
			Description = Locale.Lookup(policy.Description),
			--Yields from modifiers
			-- Status TODO from Player:GetCulture?
			IsActive = (pPlayerCulture:IsPolicyUnlocked(policy.Index) and not pPlayerCulture:IsPolicyObsolete(policy.Index)),
			IsSlotted = ((tSlottedPolicies[ policy.Index ] and true) or false),
		};
		--dshowtable(policyData); -- !!!BUG HERE with Aesthetics CTD!!!
		local sSlotType:string = policy.GovernmentSlotType;
		if sSlotType == "SLOT_WILDCARD" then sSlotType = ((policy.RequiresGovernmentUnlock and "SLOT_WILDCARD") or "SLOT_DARKAGE"); end
		--print("...inserting policy", policyData.Name, "into", sSlotType);
		table.insert(m_kPolicyData[sSlotType], policyData);
		-- policy impact from modifiers
		policyData.Impact, policyData.Yields, policyData.ImpactToolTip, policyData.UnknownEffect = RMA.CalculateModifierEffect("Policy", policy.PolicyType, ePlayerID, nil);
		policyData.IsImpact = false; -- for toggling options
		for _,value in pairs(policyData.Yields) do if value ~= 0 then policyData.IsImpact = true; break; end end
	end
	-- iterate through all beliefs
	for belief in GameInfo.Beliefs() do
		if belief.BeliefClassType == "BELIEF_CLASS_PANTHEON" or belief.BeliefClassType == "BELIEF_CLASS_FOLLOWER" then
			local policyData:table = {
				Index = belief.Index,
				Name = Locale.Lookup(belief.Name),
				Description = Locale.Lookup(belief.Description),
				--Yields from modifiers
				-- Status TODO from Player:GetCulture?
				IsActive = true, -- not used by pantheons
				IsSlotted = ( pPlayer:GetReligion():GetPantheon() == belief.Index ),
			};
			local sSlotType:string = string.gsub(belief.BeliefClassType, "BELIEF_CLASS_", "SLOT_");
			table.insert(m_kPolicyData[sSlotType], policyData);
			-- belief impact from modifiers
			policyData.Impact, policyData.Yields, policyData.ImpactToolTip, policyData.UnknownEffect = RMA.CalculateModifierEffect("Belief", belief.BeliefType, ePlayerID, nil);
			policyData.IsImpact = false; -- for toggling options
			for _,value in pairs(policyData.Yields) do if value ~= 0 then policyData.IsImpact = true; break; end end
		end -- pantheons
	end -- all beliefs
	Timer1Tick("--- ALL POLICY DATA ---");
	--for policyGroup,policies in pairs(m_kPolicyData) do print(policyGroup, table.count(policies)); end
end


function ViewPolicyPage()

	ResetTabForNewPageContent();

	-- fill
	--for iUnitGroup, kUnitGroup in spairs( m_kUnitDataReport, function( t, a, b ) return t[b].ID > t[a].ID end ) do
	--for policyGroup,policies in pairs(m_kPolicyData) do
	for policyGroup,policies in spairs( m_kPolicyData, function(t,a,b) return tPolicyOrder[a] < tPolicyOrder[b]; end ) do -- simple sort by group code name
		local instance : table = NewCollapsibleGroupInstance()
		
		instance.RowHeaderButton:SetText( tPolicyGroupNames[policyGroup] );
		instance.RowHeaderLabel:SetHide( false );
		instance.AmenitiesContainer:SetHide(true);
		
		local pHeaderInstance:table = {}
		ContextPtr:BuildInstanceForControl( "PolicyHeaderInstance", pHeaderInstance, instance.ContentStack ) -- instance ID, pTable, stack
		if policyGroup == "SLOT_PANTHEON" or policyGroup == "SLOT_FOLLOWER" then pHeaderInstance.PolicyHeaderLabelName:SetText( Locale.Lookup("LOC_BELIEF_NAME") ); end
		local iNumRows:number = 0;
		pHeaderInstance.PolicyHeaderButtonLOYALTY:SetHide( not bIsRiseFall );
		
		-- set sorting callbacks
		--if pHeaderInstance.UnitTypeButton then     pHeaderInstance.UnitTypeButton:RegisterCallback(    Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_units( "type", iUnitGroup, instance ) end ) end
		--if pHeaderInstance.UnitNameButton then     pHeaderInstance.UnitNameButton:RegisterCallback(    Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_units( "name", iUnitGroup, instance ) end ) end
		--if pHeaderInstance.UnitStatusButton then   pHeaderInstance.UnitStatusButton:RegisterCallback(  Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_units( "status", iUnitGroup, instance ) end ) end

		-- fill a single group
		--for _,policy in ipairs(policies) do
		for _,policy in spairs( policies, function(t,a,b) return t[a].Name < t[b].Name; end ) do -- sort by name
		
			--FILTERS
			if (not Controls.HideInactivePoliciesCheckbox:IsSelected() or policy.IsActive) and
				(not Controls.HideNoImpactPoliciesCheckbox:IsSelected() or policy.IsImpact) then
		
			local pPolicyInstance:table = {}
			--table.insert( instance.Children, unitInstance )
			
			ContextPtr:BuildInstanceForControl( "PolicyEntryInstance", pPolicyInstance, instance.ContentStack ) -- instance ID, pTable, stack
			pPolicyInstance.PolicyEntryYieldLOYALTY:SetHide( not bIsRiseFall );
			iNumRows = iNumRows + 1;
			
			--common_unit_fields( unit, unitInstance ) -- fill a single entry
			-- status with tooltip
			local sStatusText:string;
			local sStatusToolTip:string = "Id "..tostring(policy.Index);
			if policy.IsActive then sStatusText = "[ICON_CheckSuccess]"; sStatusToolTip = sStatusToolTip.." Active policy";
			else                    sStatusText = "[ICON_CheckFail]";    sStatusToolTip = sStatusToolTip.." Inactive policy (obsolete or not yet unlocked)"; end
			pPolicyInstance.PolicyEntryStatus:SetText(sStatusText);
			--pPolicyInstance.PolicyEntryStatus:SetToolTipString(sStatusToolTip);
			
			-- name with description
			local sPolicyName:string = policy.Name;
			if policy.IsSlotted then sPolicyName = "[ICON_Checkmark]"..sPolicyName; end
			TruncateString(pPolicyInstance.PolicyEntryName, 178, sPolicyName); -- [ICON_Checkmark] [ICON_CheckSuccess] [ICON_CheckFail] [ICON_CheckmarkBlue]
			pPolicyInstance.PolicyEntryName:SetToolTipString(policy.Description);
			
			-- impact with modifiers
			local sPolicyImpact:string = ( policy.Impact == "" and "[ICON_CheckmarkBlue]" ) or policy.Impact;
			if policy.UnknownEffect then sPolicyImpact = sPolicyImpact.." [COLOR_Red]!"; end
			TruncateString(pPolicyInstance.PolicyEntryImpact, 218, sPolicyImpact);
			pPolicyInstance.PolicyEntryImpact:SetToolTipString(sStatusToolTip..TOOLTIP_SEP_NEWLINE..policy.ImpactToolTip);
			
			-- fill out yields
			for yield,value in pairs(policy.Yields) do
				if value ~= 0 then pPolicyInstance["PolicyEntryYield"..yield]:SetText(toPlusMinusNoneString(value)); end
			end
			
			end -- FILTERS
			
		end
		
		instance.RowHeaderLabel:SetText( Locale.Lookup("LOC_HUD_REPORTS_TOTALS").." "..tostring(iNumRows) );
		
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
	Controls.BottomMinorsFilters:SetHide( true );
	Controls.Scroll:SetSizeY( Controls.Main:GetSizeY() - (Controls.BottomPoliciesFilters:GetSizeY() + SIZE_HEIGHT_PADDING_BOTTOM_ADJUST ) );	
	-- Remember this tab when report is next opened: ARISTOS
	m_kCurrentTab = 6;
end



-- ===========================================================================
-- MINORS PAGE
-- ===========================================================================

-- helper to get Category out of Civ Type; categories are: CULTURAL, INDUSTRIAL, MILITARISTIC, etc.
function GetCityStateCategory(sCivType:string)
	for row in GameInfo.TypeProperties() do
		if row.Type == sCivType and row.Name == "CityStateCategory" then return row.Value; end
	end
	print("ERROR: GetCityStateCategory() no City State category for", sCivType);
	return "UNKNOWN";
end

-- helper to get a Leader for a Minor; assumes only 1 leader per Minor
function GetCityStateLeader(sCivType:string)
	for row in GameInfo.CivilizationLeaders() do
		if row.CivilizationType == sCivType then return row.LeaderType; end
	end
	print("ERROR: GetCityStateLeader() no City State leader for", sCivType);
	return "UNKNOWN";
end

-- helper to get a Trait for a Minor Leader; assumes only 1 trait per Minor Leader
function GetCityStateTrait(sLeaderType:string)
	for row in GameInfo.LeaderTraits() do
		if row.LeaderType == sLeaderType then return row.TraitType; end
	end
	print("ERROR: GetCityStateTrait() no Trait for", sLeaderType);
	return "UNKNOWN";
end

function UpdateMinorData()
	--print("*** UPDATE MINOR DATA ***");
	Timer1Start();

	local tMinorBonuses:table = {}; -- helper table to quickly access bonuses
	-- prepare empty categories
	m_kMinorData = {};
	for row in GameInfo.TypeProperties() do
		if row.Name == "CityStateCategory" and m_kMinorData[ row.Value ] == nil then
			m_kMinorData[ row.Value ] = {};
			tMinorBonuses[ row.Value ] = {};
		end
	end
	--dshowrectable(m_kMinorData); -- debug
	
	-- find out our level of involvement with alive Minors
	local tMinorRelations:table = {};
	local ePlayerID:number = Game.GetLocalPlayer();
	for _,minor in ipairs(PlayerManager.GetAliveMinors()) do
		-- we need to check for City State actually, because Free Cities are considered Minors as well
		if minor:IsMinor() then -- CIVILIZATION_LEVEL_CITY_STATE
			local minorRelation:table = {
				CivType    = PlayerConfigurations[minor:GetID()]:GetCivilizationTypeName(), -- CIVILIZATION_VILNIUS
				LeaderType = PlayerConfigurations[minor:GetID()]:GetLeaderTypeName(), -- LEADER_MINOR_CIV_VILNIUS
				IsSuzerained = ( minor:GetInfluence():GetSuzerain() == ePlayerID ), -- boolean
				NumTokens  = minor:GetInfluence():GetTokensReceived(ePlayerID),
				HasMet     = minor:GetDiplomacy():HasMet(ePlayerID),
				--HasMet     = Players[ePlayerID]:GetDiplomacy():HasMet(minor:GetID()),
			};
			tMinorRelations[ minorRelation.CivType ] = minorRelation;
		end
	end
	--dshowrectable(tMinorRelations);
	
	-- iterate through all Minors
	-- assumptions: no Civilization Traits are used, only Leader Traits; each has 1 leader; main leader is for Suzerain bonus; Inherited leaders are for small/medium/large bonuses
	
	-- first, fill out Inherited leaders
	for leader in GameInfo.Leaders() do
		if leader.InheritFrom == "LEADER_MINOR_CIV_DEFAULT" then
			local sCategory:string = string.gsub(leader.LeaderType, "LEADER_MINOR_CIV_", "");

			local function RegisterLeaderForInfluence(iNumTokens:number, sInfluence:string)
				local minorData:table = {
					--Index = civ.Index,
					CivType = leader.LeaderType,
					Category = sCategory,
					Name = Locale.Lookup("LOC_MINOR_CIV_"..sInfluence.."_INFLUENCE_ENVOYS"), -- unfortunately this is all hardcoded in LOCs, [ICON_Envoy]
					LeaderType = leader.LeaderType,
					Description = Locale.Lookup("LOC_MINOR_CIV_"..sCategory.."_TRAIT_"..sInfluence.."_INFLUENCE_BONUS"), -- unfortunately this is all hardcoded in LOCs
					NumTokens = iNumTokens, -- required number of envoys to achieve this influence level
					Trait = GetCityStateTrait(leader.LeaderType),
					Influence = 0, -- this will hold number of City States that with this influence level
					IsSuzerained = false, -- not used
					HasMet = false, -- will be true if any of that category has been met
					--Yields from modifiers
				};
				--print("registering leader", iNumTokens, sInfluence); dshowtable(minorData);
				-- impact from modifiers; the 5th parameter is used to select proper modifiers, it is the ONLY place where it is used
				minorData.Impact, minorData.Yields, minorData.ImpactToolTip, minorData.UnknownEffect = RMA.CalculateModifierEffect("Trait", minorData.Trait, ePlayerID, nil, sInfluence);
				minorData.IsImpact = false; -- for toggling options
				for _,value in pairs(minorData.Yields) do if value ~= 0 then minorData.IsImpact = true; break; end end
				-- done!
				table.insert(m_kMinorData[ minorData.Category ], minorData);
				tMinorBonuses[ minorData.Category ][ iNumTokens ] = minorData;
			end
			-- we will have to actually triple this
			RegisterLeaderForInfluence(1, "SMALL"); -- unfortunately this is all hardcoded in LOCs
			RegisterLeaderForInfluence(3, "MEDIUM");
			RegisterLeaderForInfluence(6, "LARGE");
		end
	end
	--dshowrectable(tMinorBonuses); -- debug
	-- OK UP TO THIS POINT
	-- second, fill out Main leaders
	for civ in GameInfo.Civilizations() do
		if civ.StartingCivilizationLevelType == "CIVILIZATION_LEVEL_CITY_STATE" then
			local minorData:table = {
				--Index = civ.Index,
				CivType = civ.CivilizationType,
				Category = GetCityStateCategory(civ.CivilizationType),
				Name = Locale.Lookup(civ.Name),
				LeaderType = GetCityStateLeader(civ.CivilizationType),
				Description = "", -- later
				NumTokens = 0, -- always 0
				Trait = "", -- later
				Influence = 0, -- this will hold number of envoys sent to this CS
				IsSuzerained = false, -- later
				HasMet = false, -- later
				--Yields from modifiers
			};
			--print("*** Found CS ***"); dshowtable(minorData);
			minorData.Trait = GetCityStateTrait(minorData.LeaderType);
			local tMinorRelation:table = tMinorRelations[ civ.CivilizationType ];
			if tMinorRelation ~= nil then
				minorData.Influence = tMinorRelation.NumTokens;
				minorData.IsSuzerained = tMinorRelation.IsSuzerained;
				minorData.HasMet = tMinorRelation.HasMet;
				-- register in bonuses
				for _,bonus in pairs(tMinorBonuses[minorData.Category]) do
					if minorData.Influence >= bonus.NumTokens then bonus.Influence = bonus.Influence + 1; end
					if minorData.HasMet then bonus.HasMet = true; end
				end
			end
			-- description is actually a suzerain bonus descripion
			-- it can contain many lines, from many Traits
			local tStr:table = {};
			for row in GameInfo.LeaderTraits() do
				if row.LeaderType == minorData.LeaderType then
					local sLeaderTrait:string = row.TraitType;
					for trait in GameInfo.Traits() do
						if trait.TraitType == sLeaderTrait and not trait.InternalOnly then table.insert(tStr, Locale.Lookup(trait.Description)); end
					end
				end
			end
			if #tStr == 0 then print("WARNING: UpdateMinorData() no traits for", minorData.Name); end
			minorData.Description = table.concat(tStr, "[NEWLINE]");
			--print("=== before RMA ===");
			-- impact from modifiers
			minorData.Impact, minorData.Yields, minorData.ImpactToolTip, minorData.UnknownEffect = RMA.CalculateModifierEffect("Trait", minorData.Trait, ePlayerID, nil);
			--print("=== after RMA ===");
			minorData.IsImpact = false; -- for toggling options
			for _,value in pairs(minorData.Yields) do if value ~= 0 then minorData.IsImpact = true; break; end end
			-- done!
			--print("*** Inserting CS ***"); dshowtable(minorData);
			table.insert(m_kMinorData[ minorData.Category ], minorData);
		end -- level City State
	end -- all civs

	Timer1Tick("--- ALL MINOR DATA ---");
	--dshowrectable(m_kMinorData);
end

function ViewMinorPage()

	ResetTabForNewPageContent();

	for minorGroup,minors in spairs( m_kMinorData, function(t,a,b) return a < b; end ) do -- simple sort by group code name
		local instance : table = NewCollapsibleGroupInstance()
		
		instance.RowHeaderButton:SetText( Locale.Lookup("LOC_CITY_STATES_TYPE_"..minorGroup) );
		instance.RowHeaderLabel:SetHide( false );
		instance.AmenitiesContainer:SetHide(true);
		
		local pHeaderInstance:table = {}
		ContextPtr:BuildInstanceForControl( "PolicyHeaderInstance", pHeaderInstance, instance.ContentStack ) -- instance ID, pTable, stack
		pHeaderInstance.PolicyHeaderLabelName:SetText( Locale.Lookup("LOC_HUD_REPORTS_CITY_STATE") );
		local iNumRows:number = 0;
		pHeaderInstance.PolicyHeaderButtonLOYALTY:SetHide( not bIsRiseFall );
		
		-- set sorting callbacks
		--if pHeaderInstance.UnitTypeButton then     pHeaderInstance.UnitTypeButton:RegisterCallback(    Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_units( "type", iUnitGroup, instance ) end ) end
		--if pHeaderInstance.UnitNameButton then     pHeaderInstance.UnitNameButton:RegisterCallback(    Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_units( "name", iUnitGroup, instance ) end ) end
		--if pHeaderInstance.UnitStatusButton then   pHeaderInstance.UnitStatusButton:RegisterCallback(  Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_units( "status", iUnitGroup, instance ) end ) end

		-- fill a single group
		--for _,policy in ipairs(policies) do
		for _,minor in spairs( minors, function(t,a,b) return t[a].Name < t[b].Name; end ) do -- sort by name
		
			--FILTERS
			if (not Controls.HideNotMetMinorsCheckbox:IsSelected() or minor.HasMet) and
				(not Controls.HideNoImpactMinorsCheckbox:IsSelected() or minor.IsImpact) then
		
			local pMinorInstance:table = {}
			ContextPtr:BuildInstanceForControl( "PolicyEntryInstance", pMinorInstance, instance.ContentStack ) -- instance ID, pTable, stack
			pMinorInstance.PolicyEntryYieldLOYALTY:SetHide( not bIsRiseFall );
			if minor.NumTokens == 0 then iNumRows = iNumRows + 1; end
			
			-- status with tooltip
			local sStatusText:string = "";
			local sStatusToolTip:string = "";
			if minor.Influence > 0 then sStatusText = "[ICON_CheckSuccess]"; sStatusToolTip = Locale.Lookup("LOC_ENVOY_NAME");           end
			if minor.IsSuzerained  then sStatusText = "[ICON_Checkmark]";    sStatusToolTip = Locale.Lookup("LOC_CITY_STATES_SUZERAIN"); end
			pMinorInstance.PolicyEntryStatus:SetText(sStatusText);
			pMinorInstance.PolicyEntryStatus:SetToolTipString(sStatusToolTip);     
			
			-- name with description
			local sMinorName:string = minor.Name;
			if minor.HasMet and minor.NumTokens == 0 then sMinorName = "[ICON_Capital]"..sMinorName; end
			if     minor.NumTokens > 0 then sMinorName = sMinorName.." "..tostring(minor.Influence);
			elseif minor.Influence > 0 then sMinorName = sMinorName.." [COLOR_White]"..tostring(minor.Influence).."[ENDCOLOR] [ICON_Envoy]"; end
			TruncateString(pMinorInstance.PolicyEntryName, 178, sMinorName); -- [ICON_Checkmark] [ICON_CheckSuccess] [ICON_CheckFail] [ICON_CheckmarkBlue]
			pMinorInstance.PolicyEntryName:SetToolTipString(minor.Description);
			
			-- impact with modifiers
			local sMinorImpact:string = ( minor.Impact == "" and "[ICON_CheckmarkBlue]" ) or minor.Impact;
			if minor.UnknownEffect then sMinorImpact = sMinorImpact.." [COLOR_Red]!"; end
			-- this plugin shows actual impact as an additional info; only for influence bonuses
			if minor.NumTokens > 0 then
				local tActualYields:table = {};
				for yield,value in pairs(minor.Yields) do tActualYields[yield] = value * minor.Influence; end
				local sActualInfo:string = RMA.YieldTableGetInfo(tActualYields);
				if sActualInfo ~= "" then sMinorImpact = sMinorImpact.."  ("..sActualInfo..")"; end
			end
			TruncateString(pMinorInstance.PolicyEntryImpact, 218, sMinorImpact);
			pMinorInstance.PolicyEntryImpact:SetToolTipString(minor.CivType.." / "..minor.LeaderType.."[NEWLINE]"..minor.Trait..TOOLTIP_SEP_NEWLINE..minor.ImpactToolTip);
			
			-- fill out yields
			for yield,value in pairs(minor.Yields) do
				if value ~= 0 then pMinorInstance["PolicyEntryYield"..yield]:SetText(toPlusMinusNoneString(value)); end
			end
			
			end -- FILTERS
			
		end
		
		instance.RowHeaderLabel:SetText( Locale.Lookup("LOC_HUD_REPORTS_TOTALS").." "..tostring(iNumRows) );
		
		-- no footer
		SetGroupCollapsePadding(instance, 0);
		RealizeGroup( instance );
	end
	
	-- finishing
	Controls.Stack:CalculateSize();
	Controls.Scroll:CalculateSize();

	Controls.CollapseAll:SetHide( false );
	Controls.BottomYieldTotals:SetHide( true );
	Controls.BottomResourceTotals:SetHide( true );
	Controls.BottomPoliciesFilters:SetHide( true );
	Controls.BottomMinorsFilters:SetHide( false ); -- ViewMinorPage
	Controls.Scroll:SetSizeY( Controls.Main:GetSizeY() - (Controls.BottomMinorsFilters:GetSizeY() + SIZE_HEIGHT_PADDING_BOTTOM_ADJUST ) );	
	
	-- Remember this tab when report is next opened: ARISTOS
	m_kCurrentTab = 7;
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
-- CHECKBOXES
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

-- Checkboxes for minors filters

function OnToggleNotMetMinors()
	local isChecked = Controls.HideNotMetMinorsCheckbox:IsSelected();
	Controls.HideNotMetMinorsCheckbox:SetSelected( not isChecked );
	ViewMinorPage();
end

function OnToggleNoImpactMinors()
	local isChecked = Controls.HideNoImpactMinorsCheckbox:IsSelected();
	Controls.HideNoImpactMinorsCheckbox:SetSelected( not isChecked );
	ViewMinorPage();
end


-- ===========================================================================
function Initialize()

	InitializePolicyData();
	
	Resize();	

	m_tabs = CreateTabs( Controls.TabContainer, 42, 34, 0xFF331D05 );
	--AddTabSection( "Test",								ViewTestPage );			--TRONSTER debug
	--AddTabSection( "Test2",								ViewTestPage );			--TRONSTER debug
	AddTabSection( "LOC_HUD_REPORTS_TAB_YIELDS",		ViewYieldsPage );
	AddTabSection( "LOC_HUD_REPORTS_TAB_RESOURCES",		ViewResourcesPage );
	AddTabSection( "LOC_HUD_REPORTS_TAB_CITY_STATUS",	ViewCityStatusPage );	
	AddTabSection( "LOC_HUD_REPORTS_TAB_DEALS",			ViewDealsPage );
	AddTabSection( "LOC_HUD_REPORTS_TAB_UNITS",			ViewUnitsPage );
	AddTabSection( "LOC_HUD_REPORTS_TAB_POLICIES",		ViewPolicyPage );
	AddTabSection( "LOC_HUD_REPORTS_TAB_MINORS",		ViewMinorPage );

	m_tabs.SameSizedTabs(20);
	m_tabs.CenterAlignTabs(-10);

	-- UI Callbacks
	ContextPtr:SetInitHandler( OnInit );
	ContextPtr:SetInputHandler( OnInputHandler, true );

	Events.UnitUpgraded.Add(
		function()
			if not tUnitSort.parent then return; end
			-- refresh data and re-sort group which upgraded unit was from
			m_kCityData, m_kCityTotalData, m_kResourceData, m_kUnitData, m_kDealData, m_kCurrentDeals, m_kUnitDataReport = GetData();
			UpdatePolicyData();
			UpdateMinorData();
			sort_units( tUnitSort.type, tUnitSort.group, tUnitSort.parent );
		end );

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
	Controls.BonusCheckbox:SetSelected( false ); -- not so important

	-- Polices Filters
	Controls.HideInactivePoliciesCheckbox:RegisterCallback( Mouse.eLClick, OnToggleInactivePolicies );
	Controls.HideInactivePoliciesCheckbox:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end );
	Controls.HideInactivePoliciesCheckbox:SetSelected( true );
	Controls.HideNoImpactPoliciesCheckbox:RegisterCallback( Mouse.eLClick, OnToggleNoImpactPolicies );
	Controls.HideNoImpactPoliciesCheckbox:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end );
	Controls.HideNoImpactPoliciesCheckbox:SetSelected( false );

	-- Minors Filters
	Controls.HideNotMetMinorsCheckbox:RegisterCallback( Mouse.eLClick, OnToggleNotMetMinors );
	Controls.HideNotMetMinorsCheckbox:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end );
	Controls.HideNotMetMinorsCheckbox:SetSelected( true );
	Controls.HideNoImpactMinorsCheckbox:RegisterCallback( Mouse.eLClick, OnToggleNoImpactMinors );
	Controls.HideNoImpactMinorsCheckbox:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end );
	Controls.HideNoImpactMinorsCheckbox:SetSelected( false );
	
	-- Events
	LuaEvents.TopPanel_OpenReportsScreen.Add( OnTopOpenReportsScreen );
	LuaEvents.TopPanel_CloseReportsScreen.Add( OnTopCloseReportsScreen );

end
Initialize();

print("OK loaded ReportScreen.lua from Better Report Screen");