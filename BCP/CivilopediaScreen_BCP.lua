print("Loading CivilopediaScreen_BCP.lua from Better Civilopedia version "..GlobalParameters.BCP_VERSION_MAJOR.."."..GlobalParameters.BCP_VERSION_MINOR);
--------------------------------------------------------------
-- Real Civilopedia
-- Author: Infixo
-- 2018-02-18: Created, raw modifier analysis
-- 2018-02-22: Remember last visited page (based on CQUI code)
-- 2018-03-07: Added Civs, Leaders, Units, Great People and reworked City-States
-- 2018-03-14: Added page history
-- 2018-03-23: Name changed into Better Civilopedia, table of units pages
-- 2018-03-26: Sources of GPPs
-- 2018-04-01: PlotYields modifiers
-- 2019-03-19: Discussions, Emergencies, Resolutions
-- 2020-05-21: Updated for May 2020 Patch (New Frontier)
--------------------------------------------------------------

-- exposed functions and variables
if not ExposedMembers.RMA then ExposedMembers.RMA = {} end;
local RMA = ExposedMembers.RMA;
local bIsRMA:boolean = Modding.IsModActive("6f2888d4-79dc-415f-a8ff-f9d81d7afb53"); -- Real Modifier Analysis
local bIsTCS:boolean = Modding.IsModActive("fd0d5e1a-0fbb-4d05-8f3e-f63fec8ff7c6"); -- TCS Pedialite
local bIsRST:boolean = Modding.IsModActive("99D9DDFE-85FB-2D92-1893-92A015B5899A"); -- Real Strategy

-- Rise & Fall check
local bIsRiseFall:boolean = Modding.IsModActive("1B28771A-C749-434B-9053-D1380C553DE9"); -- Rise & Fall

-- configuration options
local bOptionModifiers:boolean = ( GlobalParameters.BCP_OPTION_MODIFIERS == 1 );
local bOptionInternal:boolean = ( GlobalParameters.BCP_OPTION_INTERNAL == 1 );
local bOptionAiLists:boolean = ( GlobalParameters.BCP_OPTION_AILISTS == 1 );

-- Base File
include("CivilopediaScreen");

-- Cache base functions
BCP_BASE_PageLayouts = {};
BCP_BASE_OnOpenCivilopedia = OnOpenCivilopedia;
local LL = Locale.Lookup;

--print("Storing contents of PageLayouts:");
for k,v in pairs(PageLayouts) do
	BCP_BASE_PageLayouts[k] = v;
end

function OnOpenCivilopedia(sectionId_or_search, pageId)
	BCP_BASE_OnOpenCivilopedia(sectionId_or_search, pageId);
	Controls.SearchEditBox:TakeFocus();
    if bIsTCS then Controls.CivilopediaSectionTabStack:SetOffsetX(-5); end
end

-- Code from ReportScreen.lua
function Resize()
	local topPanelSizeY:number = 30;

	--if m_debugFullHeight then
		x,y = UIManager:GetScreenSizeVal();
		Controls.Main:SetSizeY( y - topPanelSizeY );
		Controls.Main:SetOffsetY( topPanelSizeY * 0.5 );
	--end
end



function Initialize_BCP()
	Resize();
end
Initialize_BCP();


--------------------------------------------------------------
-- GENERIC ADDITIONS

function ShowInternalPageInfo(page)
	if not bOptionInternal then return; end
	local chapter_body = {};
	for k,v in pairs(page) do
		if type(v) ~= "table" then
			table.insert(chapter_body, k..": "..tostring(v));
		else
			table.insert(chapter_body, k..": [table]");
		end
	end
	AddChapter("Internal page info", chapter_body);
end

-- these layouts will not show modifiers
local tPagesToSkip:table = {
	FrontPage = true,
	Simple = true,
	Resource = true,
	Terrain = true,
	Feature = true,
	Religion = true,
	Route = true,
	HistoricMoment = true,
	TableUnits = true,
	OverviewMoments = true,
	RandAgenda = true,
	Discussion = true,
	Adjacencies = true,
};

-- we assume Player as the default modifier owner, the below with pass a Capital City to avoid warnings in the log file
local tPagesWithCityOwner:table = {
	District = true,
	Building = true,
	GovernorPromotion = true,
}

function ShowModifiers(page)
	if not bOptionModifiers or not bIsRMA or tPagesToSkip[page.PageLayoutId] then return; end
	-- to avoid warnings in the log I should pass either a Player ID or a city ID
	local ePlayerID:number = Game.GetLocalPlayer();
	local iCityID = Players[ePlayerID]:GetCities():GetCapitalCity();
	if iCityID then iCityID = iCityID:GetID(); end -- trick to avoid double call
	if tPagesWithCityOwner[page.PageLayoutId] == nil then iCityID = nil; end
	local sImpact, tYields, sToolTip = RMA.CalculateModifierEffect(page.PageLayoutId, page.PageId, ePlayerID, iCityID);
	local chapter_body = {};
	table.insert(chapter_body, sImpact);
	table.insert(chapter_body, sToolTip);
	AddChapter("Modifiers", chapter_body);
end

-- add internal info and modifiers to all pages at once
function ShowPage(page)
	local template = _PageLayoutScriptTemplates[page.PageLayoutId];
	--print("...showing page layout", page.PageLayoutId, "with", template);
	BCP_BASE_PageLayouts[template](page); -- call original function
	ShowModifiers(page);
	ShowInternalPageInfo(page);
end

for k,v in pairs(PageLayouts) do
	PageLayouts[k] = ShowPage;
end


--------------------------------------------------------------
-- EXCEPTIONS

PageLayouts["Building"] = function(page)
	print("...showing page", page.PageLayoutId, page.PageId);
	BCP_BASE_PageLayouts[page.PageLayoutId](page); -- call original function

	local building = GameInfo.Buildings[page.PageId];
	if building == nil then return; end
	local buildingType = building.BuildingType;

	-- additional info not shown in original pedia
	local tMoreInfo:table = {};

	-- 2019-07-15 OuterDefenseStrength
	if building.OuterDefenseStrength > 0 then
		table.insert(tMoreInfo, string.format("%s [ICON_Strength] %+d", Locale.Lookup("LOC_COMBAT_PREVIEW_BASE_STRENGTH"), building.OuterDefenseStrength));
	end
	
	-- Regional Range
	if building.RegionalRange > 0 then
		table.insert(tMoreInfo, string.format("%s [ICON_Ranged] %d", Locale.Lookup("LOC_UI_PEDIA_RANGE"), building.RegionalRange));
	end
	
	-- Theming Bonus
	for row in GameInfo.Building_GreatWorks() do
		if row.BuildingType == buildingType and row.ThemingBonusDescription then
			table.insert(tMoreInfo, Locale.Lookup(row.ThemingBonusDescription));
		end
	end
	
	-- Per Era yield change 
	for row in GameInfo.Building_YieldsPerEra() do
		if row.BuildingType == buildingType then
			local yield:table = GameInfo.Yields[row.YieldType];
			table.insert(tMoreInfo, string.format("%s: %+d %s %s", Locale.Lookup("LOC_ERA_NAME"), row.YieldChange, yield.IconString, Locale.Lookup(yield.Name)));
		end
	end
	
	-- R&F gov tier
	if building.GovernmentTierRequirement then
		for row in GameInfo.Governments() do
			if row.Tier == building.GovernmentTierRequirement then table.insert(tMoreInfo, Locale.Lookup("LOC_TOOLTIP_UNLOCKS_GOVERNMENT", row.Name)); end
		end
	end

	-- buildings
	local buildings:table = {};
	for row in GameInfo.BuildingPrereqs() do
		if row.PrereqBuilding == buildingType then
			table.insert(buildings, { "ICON_"..row.Building, GameInfo.Buildings[row.Building].Name, row.Building });
		end
	end
	table.sort(buildings, function(a, b) return Locale.Compare(a[2], b[2]) == -1; end);

	-- buildings
	local units:table = {};
	for row in GameInfo.Unit_BuildingPrereqs() do
		if row.PrereqBuilding == buildingType then
			table.insert(units, { "ICON_"..row.Unit, GameInfo.Units[row.Unit].Name, row.Unit });
		end
	end
	table.sort(units, function(a, b) return Locale.Compare(a[2], b[2]) == -1; end);
	
	-- Right Column
	if #tMoreInfo > 0 or #buildings > 0 or #units > 0 then
		AddRightColumnStatBox("[ICON_Bullet][ICON_Bullet][ICON_Bullet]", function(s) -- LOC_UI_PEDIA_USAGE
			-- more building info
			if #tMoreInfo > 0 then
				s:AddSeparator();
				s:AddHeader("LOC_UI_PEDIA_TRAITS");
				for _,label in ipairs(tMoreInfo) do
					s:AddLabel(label);
				end
			end
			-- unlocks buildings
			if #buildings > 0 then
				s:AddSeparator();
				s:AddHeader("LOC_UI_PEDIA_USAGE_UNLOCKS_BUILDINGS");
				for _,icon in ipairs(buildings) do
					s:AddIconLabel(icon, icon[2]);
				end
			end
			-- unlocks units
			if #units > 0 then
				s:AddSeparator();
				s:AddHeader("LOC_UI_PEDIA_USAGE_UNLOCKS_UNITS");
				for _,icon in ipairs(units) do
					s:AddIconLabel(icon, icon[2]);
				end
			end
			s:AddSeparator();
		end);
	end
	
	ShowModifiers(page);
	ShowInternalPageInfo(page);
	
end


PageLayouts["GreatPerson"] = function(page)
	print("...showing page layout", page.PageLayoutId);
	BCP_BASE_PageLayouts[page.PageLayoutId](page); -- call original function
	-- we need to show (a) GreatPersonIndividualActionModifiers (b) GreatPersonIndividualBirthModifiers
	if bOptionModifiers and bIsRMA then
		local sImpact, tYields, sToolTip = RMA.CalculateModifierEffect("GreatPersonIndividual", page.PageId, Game.GetLocalPlayer(), nil);
		local chapter_body = {};
		table.insert(chapter_body, sImpact);
		table.insert(chapter_body, sToolTip);
		AddChapter("Action Modifiers", chapter_body);
	end
	ShowInternalPageInfo(page);
end


-- show sources of GPP for GPs
function ShowSourcesOfGPPs(page)
	
	local gpclass = nil;
	for row in GameInfo.GreatPersonClasses() do
		if row.UnitType == page.PageId then gpclass = row; break; end
	end
	if gpclass == nil then return; end
	
	local gpclassType:string = gpclass.GreatPersonClassType;
	local gpclassIcon:string = gpclass.IconString;
	local chapter_body:table = {};
	
	-- districts
	table.insert(chapter_body, Locale.Lookup("LOC_PEDIA_DISTRICTS_TITLE"));
	for row in GameInfo.District_GreatPersonPoints() do
		if row.GreatPersonClassType == gpclassType then
			table.insert(chapter_body, string.format("%+d %s %s", row.PointsPerTurn, gpclassIcon, Locale.Lookup(GameInfo.Districts[row.DistrictType].Name)));
		end
	end
	-- buildings
	table.insert(chapter_body, Locale.Lookup("LOC_PEDIA_BUILDINGS_TITLE"));
	for row in GameInfo.Building_GreatPersonPoints() do
		if row.GreatPersonClassType == gpclassType and not GameInfo.Buildings[row.BuildingType].IsWonder then
			table.insert(chapter_body, string.format("%+d %s %s", row.PointsPerTurn, gpclassIcon, Locale.Lookup(GameInfo.Buildings[row.BuildingType].Name)));
		end
	end
	-- wonders
	table.insert(chapter_body, Locale.Lookup("LOC_PEDIA_WONDERS_PAGEGROUP_WONDERS_NAME"));
	for row in GameInfo.Building_GreatPersonPoints() do
		if row.GreatPersonClassType == gpclassType and GameInfo.Buildings[row.BuildingType].IsWonder then
			table.insert(chapter_body, string.format("%+d %s %s", row.PointsPerTurn, gpclassIcon, Locale.Lookup(GameInfo.Buildings[row.BuildingType].Name)));
		end
	end
	-- citizens not used
	-- District_CitizenGreatPersonPoints 
	-- projects
	table.insert(chapter_body, Locale.Lookup("LOC_PEDIA_WONDERS_PAGEGROUP_PROJECTS_NAME"));
	for row in GameInfo.Project_GreatPersonPoints() do
		if row.GreatPersonClassType == gpclassType then
			table.insert(chapter_body, string.format("%d* %s %s", row.Points, gpclassIcon, Locale.Lookup(GameInfo.Projects[row.ProjectType].ShortName)));
		end
	end
	
	-- modifiers - need some more work to detect which one exactly it is
	if bOptionModifiers and bIsRMA then

	table.insert(chapter_body, Locale.Lookup("LOC_UI_PEDIA_UNIQUE_ABILITY"));
	for row in GameInfo.ModifierArguments() do
		if row.Name == "GreatPersonClassType" and row.Value == gpclassType then
			local sModifierId:string = row.ModifierId;
			-- check if attached (for CSs)
			for arg in GameInfo.ModifierArguments() do
				if arg.Name == "ModifierId" and arg.Value == row.ModifierId then sModifierId = arg.ModifierId; end
			end
			local sText:string = sModifierId;
			-- detect if this is the right one
			local function DetectAndShowModifier(sObjectType:string, sTableModifiers:string, sTableObjects:string, sLocText:string)
				for mod in GameInfo[sTableModifiers]() do
					if mod.ModifierId == sModifierId or mod.ModifierID == sModifierId then
						local sLocName:string = GameInfo[sTableObjects][ mod[sObjectType] ].Name;
						if sObjectType == "CommemorationType" then sLocName = GameInfo[sTableObjects][ mod[sObjectType] ].CategoryDescription; end -- ofc, why all are named Name except for Commemoration? it has to be something different, just for fun
						sText = Locale.Lookup( sLocName );
						if sLocText then sText = sText..string.format(" (%s)", Locale.Lookup(sLocText)); end
						return true;
					end
				end
				return false;
			end
			if     DetectAndShowModifier("PolicyType",   "PolicyModifiers",   "Policies",  "LOC_POLICY_NAME")     then -- empty
			elseif DetectAndShowModifier("BuildingType", "BuildingModifiers", "Buildings", "LOC_BUILDING_NAME")   then -- empty
			elseif DetectAndShowModifier("BeliefType",   "BeliefModifiers",   "Beliefs",   "LOC_BELIEF_NAME")     then -- empty
			elseif DetectAndShowModifier("TraitType",    "TraitModifiers",    "Traits",    "LOC_UI_PEDIA_TRAITS") then -- empty
			elseif DetectAndShowModifier("UnitAbilityType", "UnitAbilityModifiers", "UnitAbilities", "LOC_PEDIA_UNITPROMOTIONS_PAGEGROUP_UNIT_ABILITIES_NAME") then -- empty
			elseif bIsRiseFall and DetectAndShowModifier("CommemorationType", "CommemorationModifiers", "CommemorationTypes", "LOC_PEDIA_CONCEPTS_PAGE_DEDICATIONS_CHAPTER_CONTENT_TITLE") then -- empty
			end
			-- get amount
			local tMod:table = RMA.FetchAndCacheData(row.ModifierId);
			local sPoints:string = "";
			if tMod.EffectType == "EFFECT_ADJUST_DISTRICT_GREAT_PERSON_POINTS" or
			   tMod.EffectType == "EFFECT_ADJUST_GREAT_PERSON_POINTS" or
			   tMod.EffectType == "EFFECT_ADJUST_CITY_HAPPINESS_GREAT_PERSON" then sPoints = "+"..tMod.Arguments.Amount.." ";
			elseif tMod.EffectType == "EFFECT_ADJUST_GREAT_PEOPLE_POINTS_PER_KILL" then sPoints = tMod.Arguments.Amount.." ";
			elseif tMod.EffectType == "EFFECT_ADJUST_GREAT_PERSON_POINTS_PERCENT" then sPoints = "+"..tMod.Arguments.Amount.."% "; end
			table.insert(chapter_body, sPoints..string.format("%s %s", gpclassIcon, sText));
		end
	end
	
	end -- modifiers & RMA
	
	AddChapter("LOC_CITY_STATES_OVERVIEW", chapter_body);
	
end


-- exceptions Units
-- Units.UnitType=UNIT_INDIAN_VARU
-- TypeTags.Type=UNIT_INDIAN_VARU /.Tag=CLASS_VARU
-- TypeTags.Type=UNIT_INDIAN_VARU /.Tag=CLASS_HEAVY_CAVALRY
-- TypeTags.Type=ABILITY_VARU / .Class=CLASS_VARU
-- UnitAbilities.UnitAbilityType=ABILITY_VARU
PageLayouts["Unit"] = function(page)
	print("...showing page", page.PageLayoutId, page.PageId);
	BCP_BASE_PageLayouts[page.PageLayoutId](page); -- call original function
	
	local unit = GameInfo.Units[page.PageId];
	if unit == nil then return; end
	local unitType = unit.UnitType;
	
	-- show sources of GPP for GPs
	for row in GameInfo.GreatPersonClasses() do
		if row.UnitType == unitType then ShowSourcesOfGPPs(page); end
	end
	
	-- start with page.PageId, it contains UnitType
	-- built ability list
	local tAbilities:table = {};
	for row in GameInfo.TypeTags() do
		if row.Type == unitType then
			-- add class
			for row2 in GameInfo.TypeTags() do
				if row2.Tag == row.Tag and string.sub(row2.Type, 1, 7) == "ABILITY" then tAbilities[ row2.Type ] = true; end
			end
		end
	end
	-- show modifiers
	if bOptionModifiers and bIsRMA then
		--for k,v in pairs(tAbilities) do print(k,v) end
		for ability,_ in pairs(tAbilities) do
			local sImpact, tYields, sToolTip = RMA.CalculateModifierEffect("UnitAbility", ability, Game.GetLocalPlayer(), nil);
			local chapter_body = {};
			table.insert(chapter_body, sImpact);
			table.insert(chapter_body, sToolTip);
			if bOptionModifiers then
				local sAbilityName:string = GameInfo.UnitAbilities[ability].Name;
				if sAbilityName == nil then sAbilityName = "LOC_"..ability.."_NAME"; end
				AddChapter(Locale.Lookup(sAbilityName), chapter_body);
			end
		end
	end
	
	-- Right Column
	local tAiInfos:table = {};
	for row in GameInfo.UnitAiInfos() do
		if row.UnitType == unitType then table.insert(tAiInfos, row.AiType); end
	end
	if #tAiInfos > 0 then
		table.sort(tAiInfos);
		AddRightColumnStatBox("[ICON_Bullet][ICON_Bullet][ICON_Bullet]", function(s)
			s:AddSeparator();
			s:AddHeader("UnitAiInfos");
			for _,aiinfo in ipairs(tAiInfos) do s:AddLabel(aiinfo); end
			s:AddSeparator();
		end);
	end
	
	ShowInternalPageInfo(page);
end


-- build a table of all uniques in the DB
local tAllUniques:table = {};
function AddUniques(sTable:string)
	for row in GameInfo[sTable]() do
		if row.TraitType then tAllUniques[ row.TraitType ] = row.Name; end
	end
end
AddUniques("Units");
AddUniques("Buildings");
AddUniques("Districts");
AddUniques("Improvements");


-- AiLists
-- display separately for Leaders and Civs
-- CivilizationTrait
--   ListType (System, Trait) [AiLists]
--      row1 Item Favored Value (StringVal if  exists) [AiFavoredItems]
--      row2 Item Favored Value (StringVal if  exists)
-- LaderTrait & AgendaTrait
--   same as above

function ShowAiLists(tTraits:table)
	if not bOptionAiLists then return; end

	local chapter_body = {};
	local tAiLists:table = {};
	-- build a list of AiLists to display
	for _,trait in ipairs(tTraits) do
		for row in GameInfo.AiLists() do
			if row.LeaderType == trait or row.AgendaType == trait then
				table.insert(tAiLists, row);
			end
		end
	end
	-- show all lists
	for _,ailist in ipairs(tAiLists) do
		local tList:table = {};
		table.insert(tList, string.format("[COLOR_Blue]%s[ENDCOLOR] (%s)", ailist.ListType, ailist.System)); -- AiLists, header
		table.insert(tList, ailist.LeaderType ~= nil and ailist.LeaderType or (ailist.AgendaType ~= nil and ailist.AgendaType or "[COLOR_Red]unknown[ENDCOLOR]"));
		-- find and display AiFavoredItems
		for row in GameInfo.AiFavoredItems() do
			if row.ListType == ailist.ListType then
				table.insert(tList, string.format("[ICON_BULLET]%s %s %d %s",
					row.Item,
					row.Favored and "YES" or "no",
					row.Value,
					row.StringVal ~= nil and row.StringVal or "")); -- AiFavoredItems, single record
			end
		end
		table.insert(chapter_body, table.concat(tList, "[NEWLINE]"));
	end
	if table.count(chapter_body) == 0 then table.insert(chapter_body, "No AI lists defined."); end
	AddChapter("AI", chapter_body);
end


-- helper
function AddTrait(sTraitType:string, sUniqueName:string)
	--print("FUN AddTrait", sTraitType, sUniqueName);
	if not (bOptionModifiers and bIsRMA) then return; end
	local sImpact, tYields, sToolTip = RMA.CalculateModifierEffect("Trait", sTraitType, Game.GetLocalPlayer(), nil);
	local chapter_body = {};
	table.insert(chapter_body, sImpact);
	table.insert(chapter_body, sToolTip);
	local sName:string = ( GameInfo.Traits[sTraitType].Name == nil and sTraitType or Locale.Lookup(GameInfo.Traits[sTraitType].Name));
	if GameInfo.Traits[sTraitType].InternalOnly then sName = "[COLOR_Red]"..sTraitType.."[ENDCOLOR]"; end
	if sUniqueName then sName = sUniqueName; end
	AddChapter(sName, chapter_body);
end

PageLayouts["Civilization"] = function(page)
	print("...showing page", page.PageLayoutId, page.PageId);
	BCP_BASE_PageLayouts[page.PageLayoutId](page); -- call original function
	
	local tTraits:table = {};
	
	-- iterate through Traits that are not Uniques
	for row in GameInfo.CivilizationTraits() do
		if row.CivilizationType == page.PageId and not tAllUniques[row.TraitType] then
			AddTrait(row.TraitType);
		end
		if row.CivilizationType == page.PageId then
			table.insert(tTraits, row.TraitType);
		end
	end
	
	-- 2023-04-02 Right Column: StartBias info
	AddRightColumnStatBox("LOC_UI_PEDIA_START_BIAS", function(s)
		-- river
		for row in GameInfo.StartBiasRivers() do
			if row.CivilizationType == page.PageId then
				s:AddLabel(string.format("%s: %d", LL("LOC_TOOLTIP_RIVER"), row.Tier));
			end
		end
		-- terrain
		s:AddSeparator();
		for row in GameInfo.StartBiasTerrains() do
			if row.CivilizationType == page.PageId then
				s:AddLabel(string.format("%s: %d", LL(GameInfo.Terrains[row.TerrainType].Name), row.Tier));
			end
		end
		-- feature
		s:AddSeparator();
		for row in GameInfo.StartBiasFeatures() do
			if row.CivilizationType == page.PageId then
				s:AddLabel(string.format("%s: %d", LL(GameInfo.Features[row.FeatureType].Name), row.Tier));
			end
		end
		-- resource
		s:AddSeparator();
		for row in GameInfo.StartBiasResources() do
			if row.CivilizationType == page.PageId then
				s:AddLabel(string.format("[ICON_%s] %s: %d", row.ResourceType, LL(GameInfo.Resources[row.ResourceType].Name), row.Tier));
			end
		end
	end);
	
	ShowAiLists(tTraits);
	ShowInternalPageInfo(page);
	
end


PageLayouts["Leader"] = function(page)
	print("...showing page", page.PageLayoutId, page.PageId);
	BCP_BASE_PageLayouts[page.PageLayoutId](page); -- call original function

	local tTraits:table = {};
	
	-- iterate through Traits
	for row in GameInfo.LeaderTraits() do
		if row.LeaderType == page.PageId then
			AddTrait(row.TraitType);
			table.insert(tTraits, row.TraitType);
		end
	end
	
	-- iterate through Traits from Agendas
	for agenda in GameInfo.HistoricalAgendas() do
		if agenda.LeaderType == page.PageId then
			for row in GameInfo.AgendaTraits() do
				if row.AgendaType == agenda.AgendaType then
					AddTrait(row.TraitType, Locale.Lookup(GameInfo.Agendas[agenda.AgendaType].Name));
					table.insert(tTraits, row.TraitType);
				end
			end
		end
	end

	-- 2023-04-02 Right Column: Real Strategy priorities
	if bIsRST then
		AddRightColumnStatBox("LOC_HUD_REPORTS_PRIORITY", function(s)
			s:AddSeparator();
			for row in GameInfo.RSTFlavors() do
				if row.ObjectType == page.PageId then
					s:AddLabel(string.format("%s: %d", row.Strategy, row.Value));
				end
			end
			s:AddSeparator();
		end);
	end
	
	ShowAiLists(tTraits);
	ShowInternalPageInfo(page);
	
end


PageLayouts["CityState"] = function(page)
	print("...showing page layout", page.PageLayoutId);
	BCP_BASE_PageLayouts[page.PageLayoutId](page); -- call original function
	--ShowModifiers(page);
	-- special CityState logic
	-- we need to show (a) leader traits (b) city-state type modifiers
	
    local civ = GameInfo.Civilizations[page.PageId];
    if not civ then return; end
    local civType = civ.CivilizationType;
	
    -- Leaders has an Inherit from column which makes life..tricky.
    -- We need to recursively discover all leader types and use all of them.
    local base_leaders = {};
    for row in GameInfo.CivilizationLeaders() do
        if(row.CivilizationType == civType) then
            local leader = GameInfo.Leaders[row.LeaderType];
            if(leader) then
                table.insert(base_leaders, leader);
            end
	    end
    end

    function AddInheritedLeaders(leaders, leader)
        local inherit = leader.InheritFrom;
        if(inherit ~= nil) then
            local parent = GameInfo.Leaders[inherit];
            if(parent) then
                table.insert(leaders, parent);
                AddInheritedLeaders(leaders, parent);
            end
        end
    end

	-- Recurse base leaders and populate list with inherited leaders.
	local leaders = {};
    for i,v in ipairs(base_leaders) do
		table.insert(leaders, v);
		AddInheritedLeaders(leaders, v);
    end

	-- Enumerate final list and index.
	local has_leader = {};
	for i,v in ipairs(leaders) do
		has_leader[v.LeaderType] = true;
	end
	
	-- TRAITS
    local traits = {};
    local has_trait = {};
	
	local function AddTrait(sTraitType:string)
		local trait = GameInfo.Traits[sTraitType];
		if not trait then print("ERROR: trait not defined", sTraitType); return; end
		table.insert(traits, trait);
		has_trait[sTraitType] = true;
	end

    -- Populate traits from civilizations.
    for row in GameInfo.CivilizationTraits() do
        if(row.CivilizationType == civType) then AddTrait(row.TraitType); end
    end

    -- Populate traits from leaders (including inherited) [modifiers]
	if bOptionModifiers and bIsRMA then
    for row in GameInfo.LeaderTraits() do
        if has_leader[row.LeaderType] and not has_trait[row.TraitType] and row.TraitType ~= "MINOR_CIV_DEFAULT_TRAIT" then
			-- just display the trait
			local sImpact, tYields, sToolTip = RMA.CalculateModifierEffect("Trait", row.TraitType, Game.GetLocalPlayer(), nil);
			local chapter_body = {};
			table.insert(chapter_body, sImpact);
			table.insert(chapter_body, sToolTip);
			AddChapter(Locale.Lookup(GameInfo.Traits[row.TraitType].Name), chapter_body);
		end
    end
	end
	ShowInternalPageInfo(page);
end


--------------------------------------------------------------
-- Changes to Plot Yields
--------------------------------------------------------------

local COLOR_GREY  = "[COLOR:0,0,0,112]";

local tPlotModifiers:table = nil;

function Initialize_PlotYields()

	tPlotModifiers = {};
	
	-- select modifier types to detect
	local tTrackedModifierTypes:table = {};
	for row in GameInfo.DynamicModifiers() do
		if row.EffectType == "EFFECT_ADJUST_PLOT_YIELD" then tTrackedModifierTypes[row.ModifierType] = true; end
	end
	--print("Tracked modifier types:"); for mod,_ in pairs(tTrackedModifierTypes) do print("  "..mod); end

	-- select actual modifiers
	for row in GameInfo.Modifiers() do
		if tTrackedModifierTypes[row.ModifierType] and row.SubjectRequirementSetId then
			local tMod:table = RMA.FetchAndCacheData(row.ModifierId);
			--print("..fetched", tMod.ModifierId, tMod.ModifierType, tMod.EffectType);
			-- iterate through reqs and see if they match one of tracked ones
			local function AddPlotModifier(req:table, sType:string, bIsTag:boolean)
				if bIsTag then table.insert(tPlotModifiers, { Type = sType, Object = req.Arguments.Tag,    Mod = tMod });
				else           table.insert(tPlotModifiers, { Type = sType, Object = req.Arguments[sType], Mod = tMod }); end
			end
			for _,req in ipairs(tMod.SubjectReqSet.Reqs) do
				if     req.ReqType == "REQUIREMENT_PLOT_TERRAIN_TYPE_MATCHES"        then AddPlotModifier(req, "TerrainType");
				elseif req.ReqType == "REQUIREMENT_PLOT_FEATURE_TYPE_MATCHES"        then AddPlotModifier(req, "FeatureType");
				elseif req.ReqType == "REQUIREMENT_PLOT_FEATURE_TAG_MATCHES"         then AddPlotModifier(req, "FeatureTag", true); -- (not used)
				elseif req.ReqType == "REQUIREMENT_PLOT_RESOURCE_TYPE_MATCHES"       then AddPlotModifier(req, "ResourceType");
				elseif req.ReqType == "REQUIREMENT_PLOT_RESOURCE_CLASS_TYPE_MATCHES" then AddPlotModifier(req, "ResourceClassType");
				elseif req.ReqType == "REQUIREMENT_PLOT_RESOURCE_TAG_MATCHES"        then AddPlotModifier(req, "ResourceTag", true); -- (Vocabulary=RESOURCE_CLASS)
				elseif req.ReqType == "REQUIREMENT_PLOT_IMPROVEMENT_TYPE_MATCHES"    then AddPlotModifier(req, "ImprovementType");
				elseif req.ReqType == "REQUIREMENT_PLOT_IMPROVEMENT_TAG_MATCHES"     then AddPlotModifier(req, "ImprovementTag", true); -- (not used)
				end
			end
		end
	end
	--print("Tracked modifiers:"); for _,mod in ipairs(tPlotModifiers) do print("  ", mod.Type, mod.Object, mod.Mod.ModifierId); end
end

function ShowPlotYields(page, sTable:string)

	if not (bOptionModifiers and bIsRMA) then return; end
	
	if tPlotModifiers == nil then Initialize_PlotYields(); end -- delayed init

	local objectInfo:table = GameInfo[sTable][page.PageId];
	if objectInfo == nil then return; end

	local sObjectClassType:string = page.PageLayoutId.."ClassType"; -- used only by resources
	local sObjectType:string      = page.PageLayoutId.."Type";
	local sObjectTag:string       = page.PageLayoutId.."Tag";
	local chapter_body:table = {};
	
	for _,mod in ipairs(tPlotModifiers) do
		--print("modifier is", mod.Mod.ModifierID);
		
		local function AddYieldChange(sPrefix:string)
			-- 2019-06-20 GS introduced multiple yields in one modifier, separated with comma
			local sYieldType:string, sAmount:string = mod.Mod.Arguments.YieldType..",", mod.Mod.Arguments.Amount..",";
			while string.len(sYieldType) > 0 and string.len(sAmount) > 0 do
				local iCommaYieldType:number = string.find(sYieldType, ",");
				local iCommaAmount:number = string.find(sAmount, ",");
				--print("repeat", sYieldType, iCommaYieldType, sAmount, iCommaAmount);
				table.insert(chapter_body, string.format(COLOR_GREY.."%s[ENDCOLOR]%+d %s "..COLOR_GREY.."(%s)",
					sPrefix,
					tonumber(string.sub(sAmount, 1, iCommaAmount-1)),
					GameInfo.Yields[ string.sub(sYieldType, 1, iCommaYieldType-1) ].IconString,
					mod.Mod.ModifierId));
				-- remove processed yield
				sYieldType = string.sub(sYieldType, iCommaYieldType+1);
				sAmount = string.sub(sAmount, iCommaAmount+1);
			end
		end
		
		if mod.Type == sObjectType and mod.Object == page.PageId then
			AddYieldChange("");
		elseif mod.Type == sObjectClassType and mod.Object == objectInfo[sObjectClassType] then
			AddYieldChange(Locale.Lookup("LOC_"..mod.Object.."_NAME")..": ");
		elseif mod.Type == sObjectTag then
			-- check Tag
			for row in GameInfo.TypeTags() do
				if row.Tag == mod.Object and row.Type == page.PageId then
					AddYieldChange(Locale.Lookup("LOC_MODS_DETAILS_TAGS").." "); break;
				end
			end
		end
	end
	
	if #chapter_body > 0 then AddChapter("LOC_CITY_STATES_OVERVIEW", chapter_body); end

end

PageLayouts["Terrain"] = function(page)
	print("...showing page", page.PageLayoutId, page.PageId);
	BCP_BASE_PageLayouts[page.PageLayoutId](page); -- call original function
	
	ShowPlotYields(page, "Terrains");
	ShowInternalPageInfo(page);

end


PageLayouts["Feature"] = function(page)
	print("...showing page", page.PageLayoutId, page.PageId);
	BCP_BASE_PageLayouts[page.PageLayoutId](page); -- call original function
	
	ShowPlotYields(page, "Features");
	ShowInternalPageInfo(page);

end


PageLayouts["Resource"] = function(page)
	print("...showing page", page.PageLayoutId, page.PageId);
	BCP_BASE_PageLayouts[page.PageLayoutId](page); -- call original function
	
	ShowPlotYields(page, "Resources");
	ShowInternalPageInfo(page);

end


PageLayouts["Improvement"] = function(page)
	print("...showing page", page.PageLayoutId, page.PageId);
	BCP_BASE_PageLayouts[page.PageLayoutId](page); -- call original function

	ShowPlotYields(page, "Improvements");
	ShowModifiers(page);
	ShowInternalPageInfo(page);

end


-- 2019-04-17 More info for Govs
PageLayouts["Government"] = function(page)
	print("...showing page", page.PageLayoutId, page.PageId);
	BCP_BASE_PageLayouts[page.PageLayoutId](page); -- call original function
	
	local government = GameInfo.Governments[page.PageId];
	if government == nil then return; end
	local governmentType = government.GovernmentType;
	
	-- insert descriptions before Historical Context
	-- Left Column!
	local chapter_body:table = {};
	
	-- bonuses
	local inherentBonusDescription = government.InherentBonusDesc;
	local accumulatedBonusDescription = government.AccumulatedBonusDesc;
	table.insert(chapter_body, Locale.Lookup("{LOC_GOVERNMENT_INHERENT_BONUS}: {1}", inherentBonusDescription)); -- Inherent bonus
	table.insert(chapter_body, Locale.Lookup("{LOC_GOVERNMENT_ACCUMULATED_BONUS}: {1}", accumulatedBonusDescription)); -- Legacy bonus
	
	-- influence
	local influencePointBonusDescription = Locale.Lookup("LOC_GOVT_INFLUENCE_POINTS_TOWARDS_ENVOYS", government.InfluencePointsPerTurn, government.InfluencePointsThreshold, government.InfluenceTokensPerThreshold);
	table.insert(chapter_body, Locale.Lookup("{LOC_GOVERNMENT_INFLUENCE_BONUS}: {1}", influencePointBonusDescription)); -- Influence generation
	
	-- favor generation
	local favor:number = 0;
	for row in GameInfo.Governments_XP2() do
		if row.GovernmentType == governmentType then favor = row.Favor; break; end
	end
	local favorBonusDescription = Locale.Lookup("LOC_GOVT_FAVOR_PER_TURN", favor); -- "Gain {1_FavorPerTurn} [ICON_FAVOR] Diplomatic Favor per [ICON_Turn] Turn."
	--if(not Locale.IsNilOrWhitespace(favorBonusDescription)) then
	table.insert(chapter_body, Locale.Lookup("{LOC_GOVERNMENT_FAVOR_BONUS}: {1}", favorBonusDescription)); -- "Favor generation"
	--end
	
	AddChapter("LOC_HUD_REPORTS_BONUSES", chapter_body);
	
	-- Right Column
	if government.Tier ~= nil then
		AddRightColumnStatBox("[ICON_Bullet][ICON_Bullet][ICON_Bullet]", function(s)
			s:AddSeparator();
			s:AddLabel(government.Tier);
			s:AddLabel(Locale.Lookup("LOC_TOOLTIP_SAMPLE_DIPLOMACY_GOVERNMENT_DIFFERENT")..": "..tostring(government.OtherGovernmentIntolerance));
			s:AddSeparator();
		end);
	end
	
	ShowModifiers(page);
	ShowInternalPageInfo(page);
end

print("OK loaded CivilopediaScreen_BCP.lua from Better Civilopedia");