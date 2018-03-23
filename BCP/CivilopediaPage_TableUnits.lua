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
		-- group
		local sGroup:string = "";
		if     unit.FormationClass == "FORMATION_CLASS_AIR"     then sGroup = "AIR";
		elseif unit.FormationClass == "FORMATION_CLASS_NAVAL"   then sGroup = "NAVAL";
		elseif unit.FormationClass == "FORMATION_CLASS_SUPPORT" then sGroup = "SUPPORT";
		elseif unit.FormationClass == "FORMATION_CLASS_LAND_COMBAT" then
			if     unit.PromotionClass == "PROMOTION_CLASS_HEAVY_CAVALRY" or unit.PromotionClass == "PROMOTION_CLASS_LIGHT_CAVALRY" then sGroup = "CAVALRY";
			elseif unit.PromotionClass == "PROMOTION_CLASS_RANGED"        or unit.PromotionClass == "PROMOTION_CLASS_SIEGE"         then sGroup = "RANGED";
			else sGroup = "MELEE";
			end
		end
		if sGroup ~= "" then
			local bIsBaseUnit:boolean = true;
			local sUnitType:string = unit.UnitType;
			local sBaseUnitType:string = sUnitType;
			if GameInfo.UnitReplaces[sUnitType] then sBaseUnitType = GameInfo.UnitReplaces[sUnitType].ReplacesUnitType; bIsBaseUnit = false; end
			-- TODO: add here Era retrieval
			table.insert( tUnitGroups[sGroup], {
				Unit = unit,
				-- ERA
				IsBaseUnit = bIsBaseUnit,
				BaseUnitType = sBaseUnitType,
				UnitType = sUnitType,
				BaseUnitCost = GameInfo.Units[ sBaseUnitType ].Cost,
			} );
		end
	end
	-- sort groups
	local function funSort( a, b )
		if a.BaseUnitType == b.BaseUnitType then
			if a.IsBaseUnit then return true; end
			if b.IsBaseUnit then return false; end
			return a.UnitType < b.UnitType;
		else
			return a.BaseUnitCost < b.BaseUnitCost;
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
	for _,unit in ipairs(tUnitGroups[pageId]) do
		local unitInfo:table = unit.Unit;
		local unitLine = _LeftColumnUnitStatsManager:GetInstance();
		-- icon and name plus indents
		unitLine.SpaceLeft:SetHide(unit.IsBaseUnit);
		unitLine.Icon:SetIcon("ICON_"..unit.UnitType);
		unitLine.StatName:LocalizeAndSetText(unitInfo.Name);
		unitLine.StatName:SetToolTipString(Locale.Lookup(unitInfo.Description));
		unitLine.SpaceRight:SetHide(not unit.IsBaseUnit);
		-- stats
		local function ShowStat(name:string)
			unitLine["Stat"..name]:SetText( tostring(unitInfo[name]) );
		end
		ShowStat("BaseMoves");
		ShowStat("Combat");
		ShowStat("RangedCombat");
		ShowStat("Range");
		ShowStat("Bombard");
		ShowStat("Cost");
		-- click action
		unitLine.Button:RegisterCallback(Mouse.eLClick, function() NavigateTo(sectionId, unit.UnitType); end);
	end
end

print("OK loaded CivilopediaPage_TableUnits.lua from Better Civilopedia");