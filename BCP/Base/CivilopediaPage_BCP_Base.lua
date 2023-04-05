print("Loading CivilopediaPage_BCP_Base.lua from Better Civilopedia version "..GlobalParameters.BCP_VERSION_MAJOR.."."..GlobalParameters.BCP_VERSION_MINOR);
--------------------------------------------------------------
-- Better Civilopedia
-- Author: Infixo
-- 2018-03-23: Created
--------------------------------------------------------------

-- Expansions
local bIsRiseFall:boolean = Modding.IsModActive("1B28771A-C749-434B-9053-D1380C553DE9"); -- Rise & Fall
local bIsGatheringStorm:boolean = Modding.IsModActive("4873eb62-8ccc-4574-b784-dda455e74e68"); -- Gathering Storm

local LL = Locale.Lookup;


-- ===========================================================================
--	Civilopedia - Table of Units Page Layout
-- ===========================================================================

-- Cache base functions
BCP_BASE_ResetPageContent = ResetPageContent;


local _LeftColumnUnitStatsManager = InstanceManager:new("CivilopediaLeftColumnUnitStats", "Root", Controls.LeftColumnStack);
local _LeftColumnAdjacencyManager = InstanceManager:new("CivilopediaLeftColumnAdjacency", "Root", Controls.LeftColumnStack);
local _LeftColumnTimeStratManager = InstanceManager:new("CivilopediaLeftColumnTimeStrat", "Root", Controls.LeftColumnStack);

function ResetPageContent()
	_LeftColumnUnitStatsManager:ResetInstances();
	_LeftColumnAdjacencyManager:ResetInstances();
	_LeftColumnTimeStratManager:ResetInstances();
	BCP_BASE_ResetPageContent();
end


--------------------------------------------------------------
-- Initialize table of units

local tUnitGroupTypes:table = { "MELEE", "RANGED", "CAVALRY", "NAVAL", "AIR", "SUPPORT" };
local tUnitGroups:table = {};

local tPromotionClassIcons:table = {
	PROMOTION_CLASS_AIR_BOMBER    = "[ICON_Bombard]",
	PROMOTION_CLASS_AIR_FIGHTER   = "[ICON_Ranged]",
	PROMOTION_CLASS_ANTI_CAVALRY  = "[ICON_Ability]",
	PROMOTION_CLASS_HEAVY_CAVALRY = "[ICON_Fortified]",
	PROMOTION_CLASS_LIGHT_CAVALRY = "[ICON_Fortifying]",
	PROMOTION_CLASS_MELEE         = "[ICON_Strength]",
	PROMOTION_CLASS_MONK          = "[ICON_Religion]",
	PROMOTION_CLASS_RANGED        = "[ICON_Ranged]",
	PROMOTION_CLASS_RECON         = "[ICON_TradeRoute]",
	PROMOTION_CLASS_SIEGE         = "[ICON_Bombard]",
	PROMOTION_CLASS_NAVAL_CARRIER = "[ICON_Movement]",
	PROMOTION_CLASS_NAVAL_MELEE   = "[ICON_Strength]",
	PROMOTION_CLASS_NAVAL_RAIDER  = "[ICON_Range]",
	PROMOTION_CLASS_NAVAL_RANGED  = "[ICON_Ranged]",
	PROMOTION_CLASS_SUPPORT       = "[ICON_Position]",
};

-- for convinience, one tooltip for all promo classes
local sPromoClassesToolTip:string;

function Initialize_TableUnits()
	-- build a tooltip for promo classes
	local tPromoClassesTT:table = {};
	for promo,icon in pairs(tPromotionClassIcons) do
		table.insert(tPromoClassesTT, icon..Locale.Lookup("LOC_"..promo.."_NAME"));
	end
	table.insert(tPromoClassesTT, "[ICON_Capital]"..Locale.Lookup("LOC_UI_PEDIA_SPECIAL_UNITS"));
	sPromoClassesToolTip = table.concat(tPromoClassesTT, "[NEWLINE]");

	-- CacheData();
	-- init groups
	for _,groupType in ipairs(tUnitGroupTypes) do tUnitGroups[ groupType ] = {}; end
	-- sort out the units into proper groups
	for unit in GameInfo.Units() do
		local sUnitType:string = unit.UnitType;
		local bIsBaseUnit:boolean = true;
		local baseUnit:table = unit;
		if GameInfo.UnitReplaces[sUnitType] then baseUnit = GameInfo.Units[ GameInfo.UnitReplaces[sUnitType].ReplacesUnitType ]; bIsBaseUnit = false; end
		-- group must be from base unit! to avoid group change for uniques!
		local sGroup:string, sType:string = "", "";
		if     baseUnit.FormationClass == "FORMATION_CLASS_AIR"     then sGroup = "AIR";
		elseif baseUnit.FormationClass == "FORMATION_CLASS_NAVAL"   then sGroup = "NAVAL";
		elseif baseUnit.FormationClass == "FORMATION_CLASS_SUPPORT" then sGroup = "SUPPORT";
		elseif baseUnit.FormationClass == "FORMATION_CLASS_LAND_COMBAT" then
			if     baseUnit.PromotionClass == "PROMOTION_CLASS_HEAVY_CAVALRY" or baseUnit.PromotionClass == "PROMOTION_CLASS_LIGHT_CAVALRY" then sGroup = "CAVALRY";
			elseif baseUnit.PromotionClass == "PROMOTION_CLASS_RANGED"        or baseUnit.PromotionClass == "PROMOTION_CLASS_SIEGE"         then sGroup = "RANGED";
			else sGroup = "MELEE";
			end
		end
		if sGroup ~= "" then
			local sBaseUnitType:string = baseUnit.UnitType;
			-- era retrieval (from base Unit!)
			local iEra:number = 0; -- Ancient by default
			if     baseUnit.PrereqTech  then iEra = GameInfo.Eras[ GameInfo.Technologies[baseUnit.PrereqTech].EraType ].Index;
			elseif baseUnit.PrereqCivic then iEra = GameInfo.Eras[ GameInfo.Civics[baseUnit.PrereqCivic].EraType ].Index; end
			table.insert( tUnitGroups[sGroup], {
				Unit = unit,
				Era = iEra,
				IsBaseUnit = bIsBaseUnit,
				IsUnique = ( unit.TraitType ~= nil ),
				BaseUnitType = sBaseUnitType,
				UnitType = sUnitType,
				PromoClass = ( tPromotionClassIcons[ unit.PromotionClass ] and tPromotionClassIcons[ unit.PromotionClass ] or "[ICON_Capital]" ),
				BaseUnitCost = GameInfo.Units[ sBaseUnitType ].Cost,
			} );
		end
	end
	-- sort groups
	local function funSort( a, b )
		if a.Era ~= b.Era then return a.Era < b.Era; end -- easy case of different eras
		-- first level is by BaseUnit
		if a.BaseUnitCost == b.BaseUnitCost then
			if a.BaseUnitType == b.BaseUnitType then
				-- a group of replacements
				if a.IsUnique and b.IsUnique then return a.UnitType < b.UnitType; end
				if a.IsUnique then return false; end
				return true; -- b.IsUnique
			end
			return a.BaseUnitType < b.BaseUnitType;
		end
		return a.BaseUnitCost < b.BaseUnitCost;
	end
	for group,units in pairs(tUnitGroups) do
		table.sort(units, funSort);
	end
	-- debug
	--for group,units in pairs(tUnitGroups) do
		--for _,unit in ipairs(units) do print(group, unit.Era, unit.BaseUnitCost, unit.BaseUnitType, unit.UnitType); end
	--end
end
Initialize_TableUnits();


--------------------------------------------------------------
-- Page Layout

local COLOR_RED   = "[COLOR:255,40,50,160]";
local COLOR_GREEN = "[COLOR:80,255,90,160]";
local COLOR_GREY  = "[COLOR:0,0,0,112]";

PageLayouts["TableUnits"] = function(page)
	print("...showing page", page.PageLayoutId, page.PageId);
	local pageId = page.PageId;
	
	if tUnitGroups[pageId] == nil then return; end -- assert

	SetPageHeader(page.Title);
	SetPageSubHeader(page.Subtitle);

	-- generate table header
	local headerLine = _LeftColumnUnitStatsManager:GetInstance();
	headerLine.SpaceLeft:SetHide(true);
	headerLine.Icon:SetHide(true);
	headerLine.StatName:LocalizeAndSetText("LOC_UNIT_NAME");
	headerLine.StatName:SetToolTipString(sPromoClassesToolTip);
	headerLine.SpaceRight:SetHide(false);
	headerLine.StatPromo:SetText("");
	headerLine.StatBaseMoves:SetText("[ICON_Movement]");
	headerLine.StatCombat:SetText("[ICON_Strength]");
	headerLine.StatRangedCombat:SetText("[ICON_Ranged]");
	headerLine.StatRange:SetText("[ICON_Range]");
	headerLine.StatBombard:SetText("[ICON_Bombard]");
	headerLine.StatCost:SetText("[ICON_Production]");
	
	-- ok, show the units!
	local iCurrentEra:number = -1; 
	for _,unit in ipairs(tUnitGroups[pageId]) do
		if unit.Era > iCurrentEra then
			iCurrentEra = unit.Era;
			-- add era intermediate header
			local eraLine = _LeftColumnUnitStatsManager:GetInstance();
			eraLine.SpaceLeft:SetHide(true);
			eraLine.Icon:SetHide(true);
			eraLine.StatName:SetText(COLOR_GREY..Locale.Lookup(GameInfo.Eras[iCurrentEra].Name).."[ENDCOLOR]");
			eraLine.SpaceRight:SetHide(false);
			eraLine.StatPromo:SetText("");
			eraLine.StatBaseMoves:SetText("");
			eraLine.StatCombat:SetText("");
			eraLine.StatRangedCombat:SetText("");
			eraLine.StatRange:SetText("");
			eraLine.StatBombard:SetText("");
			eraLine.StatCost:SetText("");
		end
		local unitInfo:table = unit.Unit;
		local unitBaseInfo:table = GameInfo.Units[ unit.BaseUnitType ];
		local unitLine = _LeftColumnUnitStatsManager:GetInstance();
		-- icon and name plus indents
		unitLine.SpaceLeft:SetHide(unit.IsBaseUnit);
		unitLine.Icon:SetIcon("ICON_"..unit.UnitType);
		unitLine.Icon:SetHide(false);
		unitLine.StatName:SetText( (unit.IsUnique and "[ICON_You]" or "")..Locale.Lookup(unitInfo.Name) );
		unitLine.StatName:SetToolTipString(Locale.Lookup(unitInfo.Description));
		unitLine.SpaceRight:SetHide(not unit.IsBaseUnit);
		unitLine.StatPromo:SetText(unit.PromoClass);
		-- stats
		local function ShowStat(name:string, bInverse:boolean)
			local iStat:number = unitInfo[name];
			if iStat == 0 then unitLine["Stat"..name]:SetText(""); return; end
			if unit.IsBaseUnit then
				unitLine["Stat"..name]:SetText( tostring(iStat) );
			else
				local iStatDiff:number = iStat - unitBaseInfo[name];
				if iStatDiff == iStat then iStatDiff = 0; end -- e.g. Immortal case
				if     iStatDiff > 0 then unitLine["Stat"..name]:SetText( string.format("%d ("..(bInverse and COLOR_RED or COLOR_GREEN).."%+d[ENDCOLOR])", iStat, iStatDiff) );
				elseif iStatDiff < 0 then unitLine["Stat"..name]:SetText( string.format("%d ("..(bInverse and COLOR_GREEN or COLOR_RED).."%+d[ENDCOLOR])", iStat, iStatDiff) );
				else                      unitLine["Stat"..name]:SetText( tostring(iStat) ); end
			end
		end
		ShowStat("BaseMoves");
		ShowStat("Combat");
		ShowStat("RangedCombat");
		ShowStat("Range");
		ShowStat("Bombard");
		ShowStat("Cost", true); -- inverse colors!
		-- click action
		unitLine.Button:RegisterCallback(Mouse.eLClick, function() NavigateTo(page.SectionId, unit.UnitType); end);
	end
end


-- ===========================================================================
--	Civilopedia - Random Agenda Page Layout
-- ===========================================================================

PageLayouts["RandAgenda"] = function(page)
	print("...showing page", page.PageLayoutId, page.PageId);
	local pageId = page.PageId;

	SetPageHeader(page.Title);
	SetPageSubHeader(page.Subtitle);

	local agenda = GameInfo.Agendas[pageId];
	if agenda == nil then return; end
	local agendaType = agenda.AgendaType;

	-- Right Column!
	
	-- Left Column!
	local chapter_body:table = {};
	table.insert(chapter_body, Locale.Lookup(agenda.Description));
	if GameInfo.RandomAgendas[agendaType].GameLimit > 0 then 
		table.insert(chapter_body, Locale.Lookup("LOC_VISIBILITY_LIMITED_NAME").." "..tostring(GameInfo.RandomAgendas[agendaType].GameLimit));
	end
	for row in GameInfo.AgendaPreferredLeaders() do
		if row.AgendaType == agendaType then
			table.insert(chapter_body, string.format("%s %d%%", Locale.Lookup(GameInfo.Leaders[row.LeaderType].Name), row.PercentageChance));
		end
	end
	-- Gathering Storm
	if bIsGatheringStorm then
		local tRandAgendaInfoXP2:table = GameInfo.RandomAgendas_XP2[agendaType];
		if tRandAgendaInfoXP2 ~= nil then
			if tRandAgendaInfoXP2.RequiresReligion then table.insert(chapter_body, Locale.Lookup("LOC_UI_RELIGION_TITLE")); end
			table.insert(chapter_body, string.format("%s", tRandAgendaInfoXP2.AgendaTag));
		end
	end
	AddChapter(Locale.Lookup(agenda.Name), chapter_body);

	-- iterate through Traits
	for row in GameInfo.AgendaTraits() do
		if row.AgendaType == agendaType then
			AddTrait(row.TraitType, Locale.Lookup(GameInfo.Agendas[agendaType].Name));
		end
	end
	
end


-- ===========================================================================
--	Civilopedia - Unit Ability Page Layout
-- ===========================================================================

PageLayouts["UnitAbility"] = function(page)
	print("...showing page", page.PageLayoutId, page.PageId);
	local pageId = page.PageId;

	SetPageHeader(page.Title);
	SetPageSubHeader(page.Subtitle);

	local unitAbility = GameInfo.UnitAbilities[page.PageId];
	if unitAbility == nil then return; end
	local unitAbilityType = unitAbility.UnitAbilityType;

	-- Right Column!
	
	-- Left Column!
	
	-- Inactive flag, Description
	local chapter_body:table = {};
	table.insert(chapter_body, COLOR_GREY..unitAbilityType.."[ENDCOLOR]");
	table.insert(chapter_body, Locale.Lookup("LOC_UI_PEDIA_ABILITY_INACTIVE")..": "..Locale.Lookup(unitAbility.Inactive and "LOC_YES" or "LOC_NO"));
	table.insert(chapter_body, unitAbility.Description ~= nil and Locale.Lookup(unitAbility.Description) or unitAbilityType);
	AddChapter(Locale.Lookup("LOC_UI_PEDIA_DESCRIPTION"), chapter_body);

	-- Granted by?
	-- every modifier with AbilityType arg has EffectType EFFECT_GRANT_ABILITY
	-- need to decode where from
	chapter_body = {};
	for arg in GameInfo.ModifierArguments() do
		if arg.Name == "AbilityType" and arg.Value == unitAbilityType then
			local sModifierId:string = arg.ModifierId;
			local sText:string = "";
			-- decode where used
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
			elseif DetectAndShowModifier("GovernmentType", "GovernmentModifiers", "Governments", "LOC_GOVERNMENT_NAME") then -- empty
			elseif bIsRiseFall and DetectAndShowModifier("CommemorationType", "CommemorationModifiers", "CommemorationTypes", "LOC_PEDIA_CONCEPTS_PAGE_DEDICATIONS_CHAPTER_CONTENT_TITLE") then -- empty
			end
			table.insert(chapter_body, sText.."  "..COLOR_GREY..sModifierId.."[ENDCOLOR]");
		end
	end
	if #chapter_body > 0 then AddChapter(Locale.Lookup("LOC_UI_PEDIA_USAGE"), chapter_body); end
	
	-- Units
	chapter_body = {};
	for row in GameInfo.TypeTags() do
		if row.Type == unitAbilityType then
			table.insert(chapter_body, COLOR_GREY..row.Tag.."[ENDCOLOR]");
			-- now list units if applicable
			local tUnitNames:table = {};
			for unit in GameInfo.TypeTags() do
				if unit.Tag == row.Tag and GameInfo.Units[unit.Type] then
					table.insert(tUnitNames, Locale.Lookup(GameInfo.Units[unit.Type].Name));
				end
			end
			if #tUnitNames == 0 then table.insert(tUnitNames, unit.Type); end
			table.insert(chapter_body, table.concat(tUnitNames, ", "));
		end
	end
	AddChapter(Locale.Lookup("LOC_PEDIA_UNITS_TITLE"), chapter_body);
	
end


-- ===========================================================================
--	Civilopedia - Adjacencies Page Layout
-- ===========================================================================

-- adjacency decoding based on Civilopedia code by Firaxis
function DecodeAdjacency(row:table)
	local object;
	local color = "[COLOR:27,27,27,255]"; -- default color in Civilopedia
	
	if(row.OtherDistrictAdjacent) then
		object = "LOC_DISTRICT_NAME"; --"LOC_TYPE_TRAIT_ADJACENT_OBJECT_DISTRICT";
	elseif(row.AdjacentResource) then
		object = "LOC_RESOURCE_NAME"; --"LOC_TYPE_TRAIT_ADJACENT_OBJECT_RESOURCE";
		--color = "[COLOR:StatGoodCS]";
	elseif(row.AdjacentSeaResource) then
		object = "LOC_TYPE_TRAIT_ADJACENT_OBJECT_SEA_RESOURCE";
		--color = "[COLOR:StatGoodCS]";
	elseif(row.AdjacentResourceClass ~= "NO_RESOURCECLASS") then
		if(row.AdjacentResourceClass == "RESOURCECLASS_BONUS") then
			object = "LOC_TOOLTIP_BONUS_RESOURCE";
		elseif(row.AdjacentResourceClass == "RESOURCECLASS_LUXURY") then
			object = "LOC_TOOLTIP_LUXURY_RESOURCE";
		elseif(row.AdjacentResourceClass == "RESOURCECLASS_STRATEGIC") then
			object = "LOC_TOOLTIP_BONUS_STRATEGIC";
		elseif(row.AdjacentResourceClass == "RESOURCECLASS_LEY_LINE") then
			object = "LOC_TOOLTIP_LEY_LINE_RESOURCE";
		else
			object = "LOC_TYPE_TRAIT_ADJACENT_OBJECT_RESOURCE_CLASS";
		end
	elseif(row.AdjacentRiver) then
		object = "LOC_TOOLTIP_RIVER"; --LOC_TYPE_TRAIT_ADJACENT_OBJECT_RIVER";
		color = "[COLOR_LIGHTBLUE]";
	elseif(row.AdjacentWonder) then
		object = "LOC_WONDER_NAME"; --"LOC_TYPE_TRAIT_ADJACENT_OBJECT_WONDER";
		color = "[COLOR_LIGHTBLUE]";
	elseif(row.AdjacentNaturalWonder) then
		object = "LOC_NATURAL_WONDER_NAME"; --"LOC_TYPE_TRAIT_ADJACENT_OBJECT_NATURAL_WONDER";
		color = "[COLOR_LIGHTBLUE]";
	elseif(row.AdjacentTerrain) then
		local terrain = GameInfo.Terrains[row.AdjacentTerrain];
		if(terrain) then
			object = terrain.Name;
			color = "[COLOR:100,40,0,255]"; --"[COLOR:0,0,0,255]";
		end
	elseif(row.AdjacentFeature) then
		local feature = GameInfo.Features[row.AdjacentFeature];
		if(feature) then
			object = feature.Name;
			color = "[COLOR_GREEN]";  -- COLOR_DARK_GREY, COLOR_LIGHTBLUE, , COLOR_BLACK, COLOR_GREEN, [COLOR:StatGoodCS], [COLOR:StatBadCS]
		end
	elseif(row.AdjacentImprovement) then
		local improvement = GameInfo.Improvements[row.AdjacentImprovement];
		if(improvement) then
			object = improvement.Name;
		end
	elseif(row.AdjacentDistrict) then
		local district = GameInfo.Districts[row.AdjacentDistrict];
		if(district) then
			object = district.Name;
			color = "[COLOR_Blue]";
		end
	elseif(row.Self) then
		object = "LOC_DIPLO_TO_SELF";
		color = "[COLOR_LIGHTBLUE]";
	end

	local yield = GameInfo.Yields[row.YieldType];

	if object == nil or yield == nil then return "error", "[COLOR_Red]"; end

	--local key = (row.TilesRequired > 1) and "LOC_TYPE_TRAIT_ADJACENT_BONUS_PER" or "LOC_TYPE_TRAIT_ADJACENT_BONUS";
			--<Text>{1_Amount: number +#,###.#;-#,###.#} {2_YieldIcon} {3_YieldName} from every {4_Count} adjacent {5_AdjacentObject} tiles.</Text>
			--<Text>{1_Amount: number +#,###.#;-#,###.#} {2_YieldIcon} {3_YieldName} from each adjacent {5_AdjacentObject} tile.</Text>
	--local key = (row.TilesRequired > 1) 
		--and "{4_Count} {5_AdjacentObject} [ICON_GoingTo] {1_Amount: number +#,###.#;-#,###.#} {2_YieldIcon}" 
		--or  "{5_AdjacentObject} [ICON_GoingTo] {1_Amount: number +#,###.#;-#,###.#} {2_YieldIcon}";
	local key = (row.TilesRequired > 1) 
		and "{2_YieldIcon} {4_Count} {5_AdjacentObject}" 
		or  "{2_YieldIcon} {5_AdjacentObject}";
	if row.YieldChange > 2 then
		key = "[COLOR:StatGoodCS]+{1_Amount}[ENDCOLOR]" .. key;
	end
	if row.YieldChange < 0 then
		key = "[COLOR:StatBadCS]{1_Amount}[ENDCOLOR]" .. key;
	end
	
	-- Exception - Adjacent river gold bonuses can only be gained once
	--if row.AdjacentRiver then
		--key = "LOC_TYPE_TRAIT_ADJACENT_BONUS_ONCE";
	--end

	local value = Locale.Lookup(key, row.YieldChange, yield.IconString, yield.Name, row.TilesRequired, object);

	if row.PrereqCivic or row.PrereqTech then
		local item;
		if row.PrereqCivic then item = GameInfo.Civics[row.PrereqCivic];
		else                    item = GameInfo.Technologies[row.PrereqTech]; end
		if item then
			local text = Locale.Lookup("LOC_TYPE_TRAIT_ADJACENT_BONUS_REQUIRES_TECH_OR_CIVIC", item.Name);
			value = value .. text;
		end
	end

	if row.ObsoleteCivic or row.ObsoleteTech then
		local item;
		if row.ObsoleteCivic then item = GameInfo.Civics[row.ObsoleteCivic];
		else                      item = GameInfo.Technologies[row.ObsoleteTech]; end
		if item then
			local text = Locale.Lookup("LOC_TYPE_TRAIT_ADJACENT_BONUS_OBSOLETE_WITH_TECH_OR_CIVIC", item.Name);
			value = value .. text;
		end
	end
	
	return value, color;
end

PageLayouts["Adjacencies"] = function(page)
	print("...showing page", page.PageLayoutId, page.PageId);
	local pageId = page.PageId;

	SetPageHeader(page.Title);
	SetPageSubHeader(page.Subtitle);
	
	-- header
	local head = _LeftColumnAdjacencyManager:GetInstance();
	head.Root:SetSizeY(20);
	head.Icon:SetHide(true);
	head.Name:SetText(LL("LOC_DISTRICT_NAME"));
	head.Icon:SetToolTipString("");
	head.Major:SetText("+2 "..LL("LOC_UI_PEDIA_ADJACENCY"));
	head.Standard:SetText("+1 "..LL("LOC_UI_PEDIA_ADJACENCY"));
	head.Minor:SetText("+0.5 "..LL("LOC_UI_PEDIA_ADJACENCY"));
	
	-- get districts to show and sort them alphabetically
	local sorted:table = {};
	for district in GameInfo.Districts() do
		if district.DistrictType ~= "DISTRICT_CITY_CENTER" and district.DistrictType ~= "DISTRICT_WONDER" then
			table.insert(sorted, district.DistrictType);
		end
	end
	table.sort(sorted,
		function (a,b)
			return LL(GameInfo.Districts[a].Name) < LL(GameInfo.Districts[b].Name);
		end);
	
	-- show the districts
	for _,district in ipairs(sorted) do -- now district is actually DistrictType
		--if district.DistrictType ~= "DISTRICT_CITY_CENTER" and district.DistrictType ~= "DISTRICT_WONDER" then
		local line = _LeftColumnAdjacencyManager:GetInstance();
		line.Root:SetSizeY(30);
		line.Major:SetText("");
		line.Standard:SetText("");
		line.Minor:SetText("");
		line.Icon:SetIcon("ICON_"..district);
		line.Icon:SetHide(false);
		line.Name:SetText(LL(GameInfo.Districts[district].Name));
		line.Icon:SetToolTipString(LL(GameInfo.Districts[district].Description));
		-- adjacencies
		for row in GameInfo.District_Adjacencies() do
			if row.DistrictType == district then
				local adj:table = GameInfo.Adjacency_YieldChanges[row.YieldChangeId];
				local desc:string, color:string = DecodeAdjacency(adj);
				desc = color..LL(desc).."[ENDCOLOR]";
				local info = line.Minor;
				if adj.TilesRequired == 1 then
					info = line.Standard;
					if adj.YieldChange > 1 then
						info = line.Major;
					end
				end
				local old:string = info:GetText();
				if old then desc = old.."[NEWLINE]"..desc; end
				info:SetText(desc);
				local sizeY:number = info:GetSizeY();
				if sizeY > line.Root:GetSizeY() then line.Root:SetSizeY(sizeY); end
			end
		end
		-- click action
		line.Button:RegisterCallback(Mouse.eLClick, function() NavigateTo(page.SectionId, district); end);
		--end -- if
	end -- for
end


-- ===========================================================================
--	Civilopedia - Time Strategy Page Layout
-- ===========================================================================

local tTimeStrats:table = {
STRATEGY_ANCIENT_CHANGES     = 1,
STRATEGY_CLASSICAL_CHANGES   = 2,
STRATEGY_MEDIEVAL_CHANGES    = 3,
STRATEGY_RENAISSANCE_CHANGES = 4,
STRATEGY_INDUSTRIAL_CHANGES  = 5,
STRATEGY_MODERN_CHANGES      = 6,
STRATEGY_ATOMIC_CHANGES      = 7,
STRATEGY_INFORMATION_CHANGES = 8,
STRATEGY_FUTURE_CHANGES      = 9,
};

local tItems:table = {};
function GetT() return tItems; end -- debug

function Initialize_ListType(aiList:string, eraNum:number)
	--print("Initialize_ListType()",aiList,eraNum);
	for row in GameInfo.AiFavoredItems() do
		if row.ListType == aiList then
			-- found an entry, add it to the table
			if tItems[row.Item] == nil then
				tItems[row.Item] = {};
			end
			local item:table = tItems[row.Item];
			item[eraNum] = row.Value;
			--item[0] = row.Item; -- item name for easier sorting later
		end
	end
end

function Initialize_TimeStrategies()
	-- iterate strategies
	for row in GameInfo.Strategy_Priorities() do
		--print(row.StrategyType, row.ListType);
		if tTimeStrats[row.StrategyType] ~= nil then
			Initialize_ListType(row.ListType, tTimeStrats[row.StrategyType]);
		end
	end
	-- sort them by item name
	--table.sort(tItems, function (a,b) return a[0] < b[0]; end);
end
Initialize_TimeStrategies();

--[[
Name     TOT || ANC | CLA | MED | REN | IND | MOD | ATO | INF | FUT |  => total 10 columns with numbers
Item     +20 || -10 | -10 |  0  | +40 | 
--]]

PageLayouts["TimeStrategy"] = function(page)
	print("...showing page", page.PageLayoutId, page.PageId);
	local pageId = page.PageId;

	SetPageHeader(page.Title);
	SetPageSubHeader(page.Subtitle);
	
	-- sort items by name
	local sorted:table = {};
	for item,_ in pairs(tItems) do table.insert(sorted, item); end
	table.sort(sorted);
	
	-- display header
	local head = _LeftColumnTimeStratManager:GetInstance();
	head.Name:SetText(LL("LOC_REPORTS_SORT_NAME"));
	head.Total:SetText(LL("LOC_HUD_CITY_TOTAL"));
	for i = 1, 9 do head["Era"..tonumber(i)]:SetText(i); end
	
	-- display items
	local maxEra:number = tTimeStrats[pageId];
	for _,item in ipairs(sorted) do
		local line = _LeftColumnTimeStratManager:GetInstance();
		line.Name:SetText(item);
		local vals:table = tItems[item];
		local tot:number = 0;
		for i = 1, 9 do
			local color:string = "[COLOR:27,27,27,255]";
			if i == maxEra then color = "[COLOR_Blue]"; end
			local val:string = "-";
			if vals[i] then
				val = tostring(vals[i]);
				if i <= maxEra then tot = tot + vals[i]; end
			end
			line["Era"..tonumber(i)]:SetText(color..val.."[ENDCOLOR]");
		end
		line.Total:SetText(tot);
	end
end

print("OK loaded CivilopediaPage_BCP_Base.lua from Better Civilopedia");