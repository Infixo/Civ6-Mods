print("Loading TechAndCivicSupport_BTT.lua from Better Tech Tree version "..GlobalParameters.BTT_VERSION_MAJOR.."."..GlobalParameters.BTT_VERSION_MINOR);
-- ===========================================================================
-- Better Tech Tree
-- Author: Infixo
-- 2018-03-19: Created
-- 2018-12-01: Version 1.1, added option to switch off the harvest icons
-- 2019-04-09: Version 1.2, added Unit Commands
-- 2019-04-19: Version 2.0, new icons, modifiers, feature removals, embarkment
-- ===========================================================================

-- Rise & Fall check
--local bIsRiseFall:boolean = Modding.IsModActive("1B28771A-C749-434B-9053-D1380C553DE9"); -- Rise & Fall
--print("Rise & Fall", (bIsRiseFall and "YES" or "no"));

-- Support for Real Eurekas mod
include("RealEurekasCanShow"); -- file taken from Real Eurekas
bIsREU = Modding.IsModActive("4a8aa030-69f0-4677-9a43-2772088ea041"); -- Real Eurekas
print("Real Eurekas:", bIsREU and "YES" or "no");

-- configuration options
local bOptionHarvests:boolean = ( GlobalParameters.BTT_OPTION_HARVESTS == 1 );

local LL = Locale.Lookup;


-- ===========================================================================
-- CACHE BASE FUNCTIONS
-- ===========================================================================
BTT_BASE_PopulateUnlockablesForCivic = PopulateUnlockablesForCivic;
BTT_BASE_PopulateUnlockablesForTech = PopulateUnlockablesForTech;


-- ===========================================================================
-- DEBUG ROUTINES
-- ===========================================================================

-- debug routine - prints a table (no recursion)
function dshowtable(tTable:table)
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
-- DATA AND HELPERS
-- ===========================================================================

local m_kExtraUnlockables:table = {}; -- simple table, each value is data for 1 extra unlock


-- filter out the unlockables for a specific tech or civic
function GetExtraUnlockables(sType:string)
	local tExtras:table = {};
	for _,item in ipairs(m_kExtraUnlockables) do
		if item.Type == sType then table.insert(tExtras, item); end
	end
	--print("found", #tExtras, "for", sType)
	return tExtras;
end

function AddExtraUnlockable(sType:string, sUnlockKind:string, sUnlockType:string, sDescription:string, sPediaKey:string)
	print("FUN AddExtraUnlockable",sType, sUnlockKind, sUnlockType, sDescription, sPediaKey);
	local tItem:table = {
		Type = sType,
		UnlockKind = sUnlockKind, -- "BOOST", "IMPROVEMENT", "SPY", "HARVEST"
		UnlockType = sUnlockType, -- actual object to be shown
		Description = sDescription, -- additional info, to put on the icon OR into the tooltip
		PediaKey = sPediaKey,
	}
	table.insert(m_kExtraUnlockables, tItem);
end

function IsExtraUnlockableAdded(sType:string, sUnlockKind:string, sUnlockType:string)
	for _,item in ipairs(m_kExtraUnlockables) do
		if item.Type == sType and item.UnlockKind == sUnlockKind and item.UnlockType == sUnlockType then return true; end
	end
	return false;
end

-- ===========================================================================
--
-- ===========================================================================

local tBackgroundTextures:table = {
	BOOST_TECH = "ICON_BTT_BOOST_TECH", --"ICON_TECHUNLOCK_5", -- "LaunchBar_Hook_ScienceButton",
	BOOST_CIVIC = "ICON_BTT_BOOST_CIVIC", --"ICON_TECHUNLOCK_5", -- same as Resources "LaunchBar_Hook_CultureButton",
	HARVEST = "ICON_BTT_HARVEST",
	IMPR_BONUS = "ICON_BTT_IMPR_BONUS",
	UNIT = "ICON_BTT_SQUARE",
	TOURISM = "ICON_BTT_SQUARE",
	COMMAND = "ICON_BTT_SQUARE",
	OTHER = "ICON_BTT_SQUARE",
};

-- NOT USED!!!
--[[
function GetUnlockIcon(typeName)
	if string.find(typeName, "TECH_") then return tBackgroundTextures.BOOST_TECH; end
	if string.find(typeName, "CIVIC_") then return tBackgroundTextures.BOOST_CIVIC; end
	return BTT_BASE_GetUnlockIcon(typeName);
end
--]]

-- this will add 1 simple unlockable, i.e. only background and icon
function PopulateUnlockableSimple(tItem:table, instanceManager:table)
	--print("FUN PopulateUnlockableSimple"); dshowtable(tItem);

	local unlockInstance = instanceManager:GetInstance();

	-- background is taken from Kind
	unlockInstance.UnlockIcon:SetTexture( IconManager:FindIconAtlas(tBackgroundTextures[tItem.UnlockKind], 38) );
	
	-- the actual icon is taken from Type
	unlockInstance.Icon:SetIcon("ICON_"..tItem.UnlockType);
	unlockInstance.Icon:SetHide(false);
	
	-- tooltip
	unlockInstance.UnlockIcon:SetToolTipString(tItem.Description);

	-- civilopedia
	if not IsTutorialRunning() and tItem.PediaKey then
		unlockInstance.UnlockIcon:RegisterCallback(
			Mouse.eRClick,
			function() LuaEvents.OpenCivilopedia(tItem.PediaKey);
		end);
	end

end


function PopulateUnlockablesForCivic(playerID:number, civicID:number, kItemIM:table, kGovernmentIM:table, callback:ifunction, hideDescriptionIcon:boolean )
	--print("FUN PopulateUnlockablesForCivic (pid,cid,bhide)",playerID,civicID,hideDescriptionIcon);
	
	local civicInfo:table = GameInfo.Civics[civicID];
	if civicInfo == nil then
		print("ERROR: PopulateUnlockablesForCivic Unable to find a civic type in the database with an ID value of", civicID);
		return;
	end
	
	local sCivicType:string = civicInfo.CivicType;
	local iNumIcons:number = 0;
	
	-- I can block showing extra star by passing hideDescriptionIcon = true
	-- BUT: not all can be disabled unfortunately...
	-- must stay: other modifiers than spies, feature removal, adjacency bonuses
	-- we're gonna HIDE the star by default - it will only be shown if a record exists in m_kShowStar
	-- there's no flag like this in TechTree anyway, so no use doing it only for Civics
	
	iNumIcons = BTT_BASE_PopulateUnlockablesForCivic(playerID, civicID, kItemIM, kGovernmentIM, callback, hideDescriptionIcon );
	if iNumIcons == nil then iNumIcons = 0; end
	
	--print("Adding additional icons for", sCivicType);
	
	for _,item in ipairs( GetExtraUnlockables(sCivicType) ) do
		PopulateUnlockableSimple(item, kItemIM);
		iNumIcons = iNumIcons + 1;
	end
	
	kItemIM.m_ParentControl:CalculateSize();
	
	return iNumIcons;
end


-- ===========================================================================
--
-- ===========================================================================
function PopulateUnlockablesForTech(playerID:number, techID:number, instanceManager:table, callback:ifunction )
	--print("FUN PopulateUnlockablesForTech (pid,tid)",playerID,techID);

	local techInfo:table = GameInfo.Technologies[techID];
	if techInfo == nil then
		print("ERROR: PopulateUnlockablesForTech Unable to find a tech type in the database with an ID value of", techID);
		return;
	end
	
	local sTechType:string = techInfo.TechnologyType;
	local iNumIcons:number = 0;
	
	iNumIcons = BTT_BASE_PopulateUnlockablesForTech(playerID, techID, instanceManager, callback);
	if iNumIcons == nil then iNumIcons = 0; end
	
	--print("Adding additional icons for", sTechType);
	
	for _,item in ipairs( GetExtraUnlockables(sTechType) ) do
		PopulateUnlockableSimple(item, instanceManager);
		iNumIcons = iNumIcons + 1;
	end
	
	instanceManager.m_ParentControl:CalculateSize();
	
	return iNumIcons;
end


-- ===========================================================================
-- POPULATE EXTRA UNLOCKABLES
-- ===========================================================================

-- simple version first, only for direct Civic/Tech boosts
-- TODO: add support for Units, Districts and Buildings
function PopulateBoosts()

	-- Real Eurekas
	if bIsREU and eTVP ~= 0 then return; end -- boosts will be shown only when option "Always visible" is chosen

	local sType:string, sUnlockKind:string, sUnlockType:string, sDescription:string, sDescBoost:string, sPediaKey:string, objectInfo:table;
	
	for row in GameInfo.Boosts() do
		-- what is boosted?
		if     row.TechnologyType then
			sUnlockKind = "BOOST_TECH"; sUnlockType = row.TechnologyType; sPediaKey = row.TechnologyType;
			sDescBoost = string.format(": %d%% [ICON_TechBoosted] %s [ICON_GoingTo] %s", row.Boost, LL("LOC_HUD_POPUP_TECH_BOOST_UNLOCKED"), LL(GameInfo.Technologies[row.TechnologyType].Name));
		elseif row.CivicType then
			sUnlockKind = "BOOST_CIVIC"; sUnlockType = row.CivicType; sPediaKey = row.CivicType;
			sDescBoost = string.format(": %d%% [ICON_CivicBoosted] %s [ICON_GoingTo] %s", row.Boost, LL("LOC_HUD_POPUP_CIVIC_BOOST_UNLOCKED"), LL(GameInfo.Civics[row.CivicType].Name));
		else
			-- error in boost definition
		end
		-- what is the boost? it gives Type; in rare cases can generate more than 1 unlock!
		if row.BoostingCivicType then
			sType = row.BoostingCivicType;
			sDescription = LL( GameInfo.Civics[sType].Name )..sDescBoost;
			AddExtraUnlockable(sType, sUnlockKind, sUnlockType, sDescription, sPediaKey);
		end
		if row.BoostingTechType then
			sType = row.BoostingTechType;
			sDescription = LL( GameInfo.Technologies[sType].Name )..sDescBoost;
			AddExtraUnlockable(sType, sUnlockKind, sUnlockType, sDescription, sPediaKey);
		end
		if row.DistrictType then
			sType = nil; sDescription = sDescBoost;
			objectInfo = GameInfo.Districts[row.DistrictType];
			if objectInfo then sType = ( objectInfo.PrereqTech and objectInfo.PrereqTech or objectInfo.PrereqCivic ); end
			if sType then
				if row.BoostClass == "BOOST_TRIGGER_HAVE_X_DISTRICTS" then sDescription = string.format(" (%d)", row.NumItems)..sDescription; end
				sDescription = LL(objectInfo.Name)..sDescription;
				AddExtraUnlockable(sType, sUnlockKind, sUnlockType, sDescription, sPediaKey);
			end
		end
		if row.BuildingType then
			sType = nil; sDescription = sDescBoost;
			objectInfo = GameInfo.Buildings[row.BuildingType];
			if objectInfo then sType = ( objectInfo.PrereqTech and objectInfo.PrereqTech or objectInfo.PrereqCivic ); end
			if sType then
				if row.BoostClass == "BOOST_TRIGGER_HAVE_X_BUILDINGS" then sDescription = string.format(" (%d)", row.NumItems)..sDescription; end
				sDescription = LL(objectInfo.Name)..sDescription;
				AddExtraUnlockable(sType, sUnlockKind, sUnlockType, sDescription, sPediaKey);
			end
		end
		if row.Unit1Type then
			sType = nil; sDescription = sDescBoost;
			objectInfo = GameInfo.Units[row.Unit1Type];
			if objectInfo then sType = ( objectInfo.PrereqTech and objectInfo.PrereqTech or objectInfo.PrereqCivic ); end
			if sType then
				if row.BoostClass == "BOOST_TRIGGER_OWN_X_UNITS_OF_TYPE" or row.BoostClass == "BOOST_TRIGGER_MAINTAIN_X_TRADE_ROUTES" then sDescription = string.format(" (%d)", row.NumItems)..sDescription; end
				sDescription = LL(objectInfo.Name)..sDescription;
				AddExtraUnlockable(sType, sUnlockKind, sUnlockType, sDescription, sPediaKey);
			end
		end
		if row.ResourceType then
			sType = nil; sDescription = sDescBoost;
			objectInfo = GameInfo.Resources[row.ResourceType];
			if objectInfo then sType = ( objectInfo.PrereqTech and objectInfo.PrereqTech or objectInfo.PrereqCivic ); end
			if sType then
				sDescription = LL(objectInfo.Name).."[ICON_"..row.ResourceType.."] "..LL(GameInfo.Improvements[row.ImprovementType].Name)..sDescription;
				AddExtraUnlockable(sType, sUnlockKind, sUnlockType, sDescription, sPediaKey);
			end
		end
		if row.ImprovementType and row.ResourceType == nil then
			sType = nil; sDescription = sDescBoost;
			objectInfo = GameInfo.Improvements[row.ImprovementType];
			if objectInfo then sType = ( objectInfo.PrereqTech and objectInfo.PrereqTech or objectInfo.PrereqCivic ); end
			if sType then
				if row.BoostClass == "BOOST_TRIGGER_HAVE_X_IMPROVEMENTS" then sDescription = string.format(" (%d)", row.NumItems)..sDescription; end
				sDescription = LL(objectInfo.Name)..sDescription;
				AddExtraUnlockable(sType, sUnlockKind, sUnlockType, sDescription, sPediaKey);
			end
		end
	end
end

function PopulateHarvests()
	local sTT:string;
	local tHarvests:table = {};
	-- first, collate harvests of the same resource into 1 string
	for row in GameInfo.Resource_Harvests() do
		if tHarvests[ row.PrereqTech ] == nil then tHarvests[ row.PrereqTech ] = {}; end -- init a new tech
		local tTechHarvests:table = tHarvests[ row.PrereqTech ];
		if tTechHarvests[ row.ResourceType ] == nil then
			-- init a new resource
			tTechHarvests[ row.ResourceType ] = "[ICON_"..row.ResourceType.."] "..LL(GameInfo.Resources[row.ResourceType].Name)..":"; --  don't put resource font icon, modded ones usually don't have it
		end
		tTechHarvests[ row.ResourceType ] = tTechHarvests[ row.ResourceType ]..string.format(" %+d", row.Amount)..GameInfo.Yields[row.YieldType].IconString;
	end
		--if sDesc == nil then -- insert name as initial insert
			--sDesc = LL("LOC_UNITOPERATION_HARVEST_RESOURCE_DESCRIPTION")..": "..LL(GameInfo.Resources[row.ResourceType].Name); --  don't put resource font icon, modded ones usually don't have it
		--end
	-- second, add to the proper techs
	for tech,harvests in pairs(tHarvests) do
		-- create a collated tooltip
		local sTT:string = LL("LOC_UNITOPERATION_HARVEST_RESOURCE_DESCRIPTION");
		for _,tooltip in pairs(harvests) do sTT = sTT.."[NEWLINE]"..tooltip; end
		AddExtraUnlockable(tech, "HARVEST", "BTT_HAMMER", sTT, "WORLD_2");
	end
end


function PopulateFeatureRemovals()
	for row in GameInfo.Features() do
		if row.RemoveTech ~= nil then
			-- removable feature, build yields
			local sTT:string = LL("LOC_UNITOPERATION_REMOVE_FEATURE_DESCRIPTION")..": "..LL(row.Name);
			for yield in GameInfo.Feature_Removes() do
				if yield.FeatureType == row.FeatureType then
					sTT = sTT..string.format(" %+d", yield.Yield)..GameInfo.Yields[yield.YieldType].IconString;
				end
			end
			AddExtraUnlockable(row.RemoveTech, "HARVEST", "BTT_REMOVE", sTT, row.FeatureType);
		end
	end
end


-- many improvements are unique to a Civ
-- must not show them unless the player is that Civ
function CanShowImprovement(sImprovementType:string)
	--print("FUN CanShowImprovement(imp)",sImprovementType);
	local imprInfo:table = GameInfo.Improvements[sImprovementType];
	if imprInfo == nil then return false; end -- assert
	if imprInfo.TraitType == nil then return true; end -- not unique
	if imprInfo.TraitType == "TRAIT_CIVILIZATION_NO_PLAYER" then return true; end -- generic for all players
	if string.find(imprInfo.TraitType, "MINOR_CIV") then return true; end -- we may acquire that! ugly hack, but I don't to iterate LeaderTraits to check for 1 instance (Colossal Head)
	-- find civ
	if Game.GetLocalPlayer() == -1 then return true; end
	local sLocalPlayerCivType:string = PlayerConfigurations[ Game.GetLocalPlayer() ]:GetCivilizationTypeName();
	--print("checking trait for",sLocalPlayerCivType);
	for row in GameInfo.CivilizationTraits() do
		if row.TraitType == imprInfo.TraitType then
			return row.CivilizationType == sLocalPlayerCivType; -- true if that's our improvement, false if somebody's else
		end
	end
	-- didn't find any? error
	return false;
end

function PopulateImprovementBonus()
	local sType:string, sDesc:string;
	for row in GameInfo.Improvement_BonusYieldChanges() do
		if     row.PrereqTech  then sType = row.PrereqTech;
		elseif row.PrereqCivic then sType = row.PrereqCivic;
		else -- error in configuration
		end
		if CanShowImprovement(row.ImprovementType) then
			sDesc = LL(GameInfo.Improvements[row.ImprovementType].Name)..": +"..tostring(row.BonusYieldChange)..GameInfo.Yields[row.YieldType].IconString;
			AddExtraUnlockable(sType, "IMPR_BONUS", row.ImprovementType, sDesc, row.ImprovementType);
		end
	end
end

function PopulateFromModifiers(sTreeKind:string)
	local sType:string, sDesc:string;
	for row in GameInfo[sTreeKind.."Modifiers"]() do
		sType = row[sTreeKind.."Type"];
		for mod in GameInfo.Modifiers() do
			if mod.ModifierId == row.ModifierId then
				if mod.ModifierType == "MODIFIER_PLAYER_GRANT_SPY" then
					sDesc = "+1 "..LL(GameInfo.Units["UNIT_SPY"].Name);
					AddExtraUnlockable(sType, "UNIT", "UNIT_SPY", sDesc, "UNIT_SPY");
				elseif string.find(mod.ModifierType, "ADJUST_TOURISM") or mod.ModifierType == "MODIFIER_PLAYER_ADJUST_RELIGIOUS_TOURISM_REDUCTION" then
					-- MODIFIER_PLAYER_CITIES_ADJUST_TOURISM MODIFIER_PLAYER_ADJUST_TOURISM  MODIFIER_PLAYER_DISTRICTS_ADJUST_TOURISM_CHANGE
					-- tourism modifiers - no specific description, register only once (Conservation!)
					if not IsExtraUnlockableAdded(sType, "TOURISM", "BTT_TOURISM") then
						sDesc = LL("LOC_TOP_PANEL_TOURISM");
						AddExtraUnlockable(sType, "TOURISM", "BTT_TOURISM", sDesc, "TOURISM_1");
					end
				elseif mod.ModifierType == "MODIFIER_PLAYER_GRANT_CITIES_URBAN_DEFENSES" then AddExtraUnlockable(sType, "OTHER", "BTT_DEFENSE",  LL("LOC_BTT_URBAN_DEFENSES"), "COMBAT_9");
				elseif mod.ModifierType == "MODIFIER_PLAYER_ADD_DIPLO_VISIBILITY"        then AddExtraUnlockable(sType, "OTHER", "BTT_ACCESS",   LL("LOC_BTT_DIPLO_VISIBILITY"), "DIPLO_4");
				elseif mod.ModifierType == "MODIFIER_PLAYER_ADJUST_EMBARKED_MOVEMENT"    then AddExtraUnlockable(sType, "OTHER", "BTT_MOVEMENT", LL("LOC_BTT_EMBARKED_MOVEMENT"), "MOVEMENT_5");
				elseif mod.ModifierType == "MODIFIER_PLAYER_UNITS_ADJUST_SEA_MOVEMENT"   then AddExtraUnlockable(sType, "OTHER", "BTT_MOVEMENT", LL("LOC_TECH_MATHEMATICS_DESCRIPTION"), "MOVEMENT_4");
				elseif mod.ModifierType == "MODIFIER_PLAYER_UNITS_ADJUST_VALID_TERRAIN"  then AddExtraUnlockable(sType, "OTHER", "BTT_MOVEMENT", LL("LOC_BTT_VALID_OCEAN"), "MOVEMENT_4");
				elseif mod.ModifierType == "MODIFIER_PLAYER_GRANT_COMBAT_ADJACENCY"      then AddExtraUnlockable(sType, "OTHER", "BTT_STRENGTH", LL("LOC_CIVIC_MILITARY_TRADITION_DESCRIPTION"), "COMBAT_9");
				else
					-- check for other modifiers here
				end
				break;
			end
		end
	end
end

-- 2019-04-09 UnitCommands
function PopulateUnitCommands(sPrereq:string)
	local sType:string, sDesc:string;
	for row in GameInfo.UnitCommands() do
		sType = row[sPrereq];
		if sType ~= nil then
			sDesc = LL(row.Description);
			AddExtraUnlockable(sType, "COMMAND", row.CommandType, sDesc, row.CommandType);
		end
	end
end


-- 2019-04-19 Embarkment
function PopulateEmbarkment(sTable:string, sType:string)
	--print("FUN PopulateEmbarkment", sTable, sType);
	for row in GameInfo[sTable]() do
		-- unit
		if row.EmbarkUnitType ~= nil then
			--print("...unit", row.EmbarkUnitType); dshowtable(row);
			AddExtraUnlockable(row[sType], "OTHER", row.EmbarkUnitType, LL("LOC_UNITOPERATION_EMBARK_DESCRIPTION")..": "..LL(GameInfo.Units[row.EmbarkUnitType].Name), "MOVEMENT_5");
		end
		-- all units
		if row.EmbarkAll then
			--print("...all units"); dshowtable(row);
			AddExtraUnlockable(row[sType], "OTHER", "BTT_UNITS", LL("LOC_TECH_SHIPBUILDING_DESCRIPTION"), "MOVEMENT_5");
		end
	end
end


function Initialize_BTT_TechTree()
	--print("FUN Initialize_BTT_TechTree()");
	-- add all the new init stuff here
	PopulateBoosts();
	PopulateHarvests();
	PopulateFeatureRemovals();
	PopulateImprovementBonus();
	PopulateFromModifiers("Technology");
	PopulateUnitCommands("PrereqTech");
	PopulateEmbarkment("Technologies", "TechnologyType");
	print("Extra unlockables found:", #m_kExtraUnlockables);
end


function Initialize_BTT_CivicsTree()
	--print("FUN Initialize_BTT_CivicsTree()");
	-- add all the new init stuff here
	PopulateBoosts();
	PopulateImprovementBonus();
	PopulateFromModifiers("Civic");
	PopulateUnitCommands("PrereqCivic");
	PopulateEmbarkment("Civics", "CivicType");
	print("Extra unlockables found:", #m_kExtraUnlockables);
end

print("OK loaded TechAndCivicSupport_BTT.lua from Better Tech Tree");