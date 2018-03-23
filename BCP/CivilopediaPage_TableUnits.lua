print("Loading CivilopediaPage_TableUnits.lua from Better Civilopedia version "..GlobalParameters.BCP_VERSION_MAJOR.."."..GlobalParameters.BCP_VERSION_MINOR);
--------------------------------------------------------------
-- Better Civilopedia
-- Author: Infixo
-- 2018-03-23: Created
--------------------------------------------------------------
-- ===========================================================================
--	Civilopedia - Table of Units Page Layout
-- ===========================================================================

-- Cache base functions
BCP_BASE_ResetPageContent = ResetPageContent;


local _LeftColumnUnitStatsManager = InstanceManager:new("CivilopediaLeftColumnUnitStats", "Root", Controls.LeftColumnStack);

function ResetPageContent()
	_LeftColumnUnitStatsManager:ResetInstances();
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
	for group,units in pairs(tUnitGroups) do
		for _,unit in ipairs(units) do print(group, unit.Era, unit.BaseUnitCost, unit.BaseUnitType, unit.UnitType); end
	end
end
Initialize_TableUnits();


--------------------------------------------------------------
-- Page Layout

local COLOR_RED   = "[COLOR:255,40,50,160]";
local COLOR_GREEN = "[COLOR:80,255,90,160]";


PageLayouts["TableUnits"] = function(page)
	local sectionId = page.SectionId;
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
			eraLine.StatName:SetText("[COLOR:0,0,0,128]"..Locale.Lookup(GameInfo.Eras[iCurrentEra].Name).."[ENDCOLOR]");
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
		unitLine.Button:RegisterCallback(Mouse.eLClick, function() NavigateTo(sectionId, unit.UnitType); end);
	end
end

print("OK loaded CivilopediaPage_TableUnits.lua from Better Civilopedia");