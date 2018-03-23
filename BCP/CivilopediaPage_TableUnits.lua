print("Loading CivilopediaPage_TableUnits.lua from Better Civilopedia version "..GlobalParameters.BCP_VERSION_MAJOR.."."..GlobalParameters.BCP_VERSION_MINOR);
--------------------------------------------------------------
-- Better Civilopedia
-- Author: Infixo
-- 2018-03-23: Created
--------------------------------------------------------------
-- ===========================================================================
--	Civilopedia - Table of Units Page Layout
-- ===========================================================================

include("SupportFunctions"); -- TruncateStringWithTooltip

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

function Initialize_TableUnits()
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
		local sGroup:string = "";
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
			-- era retrieval
			local iEra:number = 0; -- Ancient by default
			if     unit.PrereqTech  then iEra = GameInfo.Eras[ GameInfo.Technologies[unit.PrereqTech].EraType ].Index;
			elseif unit.PrereqCivic then iEra = GameInfo.Eras[ GameInfo.Civics[unit.PrereqCivic].EraType ].Index; end
			table.insert( tUnitGroups[sGroup], {
				Unit = unit,
				Era = iEra,
				IsBaseUnit = bIsBaseUnit,
				IsUnique = ( unit.TraitType ~= nil ),
				BaseUnitType = sBaseUnitType,
				UnitType = sUnitType,
				BaseUnitCost = GameInfo.Units[ sBaseUnitType ].Cost,
			} );
		end
	end
	-- sort groups
	local function funSort( a, b )
		if a.Era ==  b.Era then
			if a.BaseUnitType == b.BaseUnitType then
				if a.IsBaseUnit then return true; end
				if b.IsBaseUnit then return false; end
				return a.UnitType < b.UnitType;
			else
				if a.BaseUnitCost == b.BaseUnitCost then
					-- a bit weird case is when they they are different BaseUnits but have the same cost
					if a.IsUnique then return true; end
					if b.IsUnique then return false; end
					return a.UnitType < b.UnitType;
				else
					return a.BaseUnitCost < b.BaseUnitCost;
				end
			end
		else
			return a.Era < b.Era;
		end
	end
	for group,units in pairs(tUnitGroups) do
		table.sort(units, funSort);
	end
	-- debug
	--for group,units in pairs(tUnitGroups) do
		--for _,unit in ipairs(units) do print(group, unit.BaseUnitCost, unit.BaseUnitType, unit.UnitType); end
	--end
end
Initialize_TableUnits();


--------------------------------------------------------------
-- Page Layout

local COLOR_RED = "[COLOR:255,40,50,160]";
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
	headerLine.StatBaseMoves:SetText("[ICON_Movement]");
	headerLine.StatCombat:SetText("[ICON_Strength]");
	headerLine.StatRangedCombat:SetText("[ICON_Ranged]");
	headerLine.StatRange:SetText("[ICON_Range]");
	headerLine.StatBombard:SetText("[ICON_Bombard]");
	headerLine.StatCost:SetText("[ICON_Production]");
	headerLine.SpaceRight:SetHide(false);
	
	-- ok, show the units!
	local iCurrentEra:number = -1; 
	for _,unit in ipairs(tUnitGroups[pageId]) do
		if unit.Era > iCurrentEra and unit.IsBaseUnit then
			iCurrentEra = unit.Era;
			-- add era intermediate header
			local eraLine = _LeftColumnUnitStatsManager:GetInstance();
			eraLine.SpaceLeft:SetHide(true);
			eraLine.Icon:SetHide(true);
			eraLine.StatName:SetText("[COLOR:0,0,0,128]"..Locale.Lookup(GameInfo.Eras[iCurrentEra].Name).."[ENDCOLOR]");
			eraLine.StatBaseMoves:SetText("");
			eraLine.StatCombat:SetText("");
			eraLine.StatRangedCombat:SetText("");
			eraLine.StatRange:SetText("");
			eraLine.StatBombard:SetText("");
			eraLine.StatCost:SetText("");
			eraLine.SpaceRight:SetHide(false);
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