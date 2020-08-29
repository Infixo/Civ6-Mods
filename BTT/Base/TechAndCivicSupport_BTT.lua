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
	--print("FUN AddExtraUnlockable",sType, sUnlockKind, sUnlockType, sDescription, sPediaKey);
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
	OCEAN = "ICON_BTT_OCEAN",
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
		if row.PrereqTech ~= nil then -- support for mods that add harvests with no tech req
			if tHarvests[ row.PrereqTech ] == nil then tHarvests[ row.PrereqTech ] = {}; end -- init a new tech
			local tTechHarvests:table = tHarvests[ row.PrereqTech ];
			if tTechHarvests[ row.ResourceType ] == nil then
				-- init a new resource
				tTechHarvests[ row.ResourceType ] = "[ICON_"..row.ResourceType.."] "..LL(GameInfo.Resources[row.ResourceType].Name)..":"; --  don't put resource font icon, modded ones usually don't have it
			end
			tTechHarvests[ row.ResourceType ] = tTechHarvests[ row.ResourceType ]..string.format(" %+d", row.Amount)..GameInfo.Yields[row.YieldType].IconString;
		end
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
	local bCanShow:boolean = false;
	for row in GameInfo.CivilizationTraits() do
		-- true only if that's our improvement
		if row.TraitType == imprInfo.TraitType and row.CivilizationType == sLocalPlayerCivType then bCanShow = true; end
	end
	return bCanShow;
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

function PopulateImprovementAdjacency()

	local adjacency_yields = {};
	local has_bonus = {};
	for impradj in GameInfo.Improvement_Adjacencies() do
		if CanShowImprovement(impradj.ImprovementType) then
			for row in GameInfo.Adjacency_YieldChanges() do
				if row.ID == impradj.YieldChangeId and (row.PrereqTech ~= nil or row.PrereqCivic ~= nil) then
					
					-- this part analyzes a single adjacency bonus
					-- it uses code from Civilopedia Improvement page to build a dynamic tooltip
					local object;
					if(row.OtherDistrictAdjacent) then
						object = "LOC_TYPE_TRAIT_ADJACENT_OBJECT_DISTRICT";
					elseif(row.AdjacentResource) then
						object = "LOC_TYPE_TRAIT_ADJACENT_OBJECT_RESOURCE";
					elseif(row.AdjacentSeaResource) then
						object = "LOC_TYPE_TRAIT_ADJACENT_OBJECT_SEA_RESOURCE";
					elseif(row.AdjacentResourceClass ~= "NO_RESOURCECLASS") then
						if(row.AdjacentResourceClass == "RESOURCECLASS_BONUS") then
							object = "LOC_TOOLTIP_BONUS_RESOURCE";
						elseif(row.AdjacentResourceClass == "RESOURCECLASS_LUXURY") then
							object = "LOC_TOOLTIP_LUXURY_RESOURCE";
						elseif(row.AdjacentResourceClass == "RESOURCECLASS_STRATEGIC") then
							object = "LOC_TOOLTIP_BONUS_STRATEGIC";
						else
							object = "LOC_TYPE_TRAIT_ADJACENT_OBJECT_RESOURCE_CLASS";
						end
					elseif(row.AdjacentRiver) then
						object = "LOC_TYPE_TRAIT_ADJACENT_OBJECT_RIVER";
					elseif(row.AdjacentWonder) then
						object = "LOC_TYPE_TRAIT_ADJACENT_OBJECT_WONDER";
					elseif(row.AdjacentNaturalWonder) then
						object = "LOC_TYPE_TRAIT_ADJACENT_OBJECT_NATURAL_WONDER";
					elseif(row.AdjacentTerrain) then
						local terrain = GameInfo.Terrains[row.AdjacentTerrain];
						if(terrain) then
							object = terrain.Name;
						end
					elseif(row.AdjacentFeature) then
						local feature = GameInfo.Features[row.AdjacentFeature];
						if(feature) then
							object = feature.Name;
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
						end
					end

					local yield = GameInfo.Yields[row.YieldType];

					if(object and yield) then

						local key = (row.TilesRequired > 1) and "LOC_TYPE_TRAIT_ADJACENT_BONUS_PER" or "LOC_TYPE_TRAIT_ADJACENT_BONUS";

						local value = Locale.Lookup(key, row.YieldChange, yield.IconString, yield.Name, row.TilesRequired, object);

						--[[ Infixo: this part is not needed
						if(row.PrereqCivic or row.PrereqTech) then
							local item;
							if(row.PrereqCivic) then
								item = GameInfo.Civics[row.PrereqCivic];
							else
								item = GameInfo.Technologies[row.PrereqTech];
							end

							if(item) then
								local text = Locale.Lookup("LOC_TYPE_TRAIT_ADJACENT_BONUS_REQUIRES_TECH_OR_CIVIC", item.Name);
								value = value .. "  " .. text;
							end
						end
						--]]

						if(row.ObsoleteCivic or row.ObsoleteTech) then
							local item;
							if(row.ObsoleteCivic) then
								item = GameInfo.Civics[row.ObsoleteCivic];
							else
								item = GameInfo.Technologies[row.ObsoleteTech];
							end
						
							if(item) then
								local text = Locale.Lookup("LOC_TYPE_TRAIT_ADJACENT_BONUS_OBSOLETE_WITH_TECH_OR_CIVIC", item.Name);
								value = value .. "  " .. text;
							end
						end
					
						-- register a new icon
						local sTechCivic:string = row.PrereqTech;
						if row.PrereqCivic ~= nil then sTechCivic = row.PrereqCivic; end
						AddExtraUnlockable(sTechCivic, "IMPR_BONUS", impradj.ImprovementType, LL(GameInfo.Improvements[impradj.ImprovementType].Name)..": "..value, impradj.ImprovementType);
					
					end -- object and yield
					
				end -- tech or civic not nil
			end -- adj
		end -- if can show
	end -- improvs
end


function GetModifierArgument(sModifierId:string, sName:string)
	for row in GameInfo.ModifierArguments() do
		if row.ModifierId == sModifierId and row.Name == sName then return row.Value; end
	end
	return nil;
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
				elseif mod.ModifierType == "MODIFIER_PLAYER_GRANT_CITIES_URBAN_DEFENSES" then
					-- DefenseValue = 400
					AddExtraUnlockable(sType, "OTHER", "BTT_DEFENSE",  LL("LOC_BTT_URBAN_DEFENSES", GetModifierArgument(mod.ModifierId, "DefenseValue")), "COMBAT_9");
				elseif mod.ModifierType == "MODIFIER_PLAYER_ADD_DIPLO_VISIBILITY"        then
					-- Amount = 1, Source = SOURCE_TECH
					AddExtraUnlockable(sType, "OTHER", "BTT_ACCESS",   LL("LOC_BTT_DIPLO_VISIBILITY"), "DIPLO_4");
				elseif mod.ModifierType == "MODIFIER_PLAYER_ADJUST_EMBARKED_MOVEMENT"    then
					-- Amount = 1/2
					AddExtraUnlockable(sType, "OCEAN", "BTT_MOVEMENT", LL("LOC_BTT_EMBARKED_MOVEMENT", GetModifierArgument(mod.ModifierId, "Amount")), "MOVEMENT_5");
				elseif mod.ModifierType == "MODIFIER_PLAYER_UNITS_ADJUST_SEA_MOVEMENT"   then
					-- Amount = 1
					AddExtraUnlockable(sType, "OCEAN", "BTT_MOVEMENT", LL("LOC_BTT_ALL_NAVAL_UNITS_MOVEMENT", GetModifierArgument(mod.ModifierId, "Amount")), "MOVEMENT_4");
				elseif mod.ModifierType == "MODIFIER_PLAYER_UNITS_ADJUST_VALID_TERRAIN"  then
					-- TerrainType = TERRAIN_OCEAN, Valid = 1
					AddExtraUnlockable(sType, "OCEAN", "BTT_WORLD", LL("LOC_BTT_VALID_OCEAN"), "MOVEMENT_4");
				elseif mod.ModifierType == "MODIFIER_PLAYER_GRANT_COMBAT_ADJACENCY"      then
					-- Enable = 1
					AddExtraUnlockable(sType, "OTHER", "BTT_STRENGTH", LL("LOC_CIVIC_MILITARY_TRADITION_DESCRIPTION"), "COMBAT_9");
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
			AddExtraUnlockable(row[sType], "OCEAN", row.EmbarkUnitType, LL("LOC_UNITOPERATION_EMBARK_DESCRIPTION")..": "..LL(GameInfo.Units[row.EmbarkUnitType].Name), "MOVEMENT_5");
		end
		-- all units
		if row.EmbarkAll then
			--print("...all units"); dshowtable(row);
			AddExtraUnlockable(row[sType], "OCEAN", "BTT_UNITS", LL("LOC_TECH_SHIPBUILDING_DESCRIPTION"), "MOVEMENT_5");
		end
	end
end


function Initialize_BTT_TechTree()
	--print("FUN Initialize_BTT_TechTree()");
	-- add all the new init stuff here
	if bOptionHarvests then
		PopulateHarvests();
		PopulateFeatureRemovals();
	end
	PopulateImprovementBonus();
	PopulateImprovementAdjacency();
	PopulateFromModifiers("Technology");
	PopulateUnitCommands("PrereqTech");
	PopulateEmbarkment("Technologies", "TechnologyType");
	PopulateBoosts();
	print("Extra unlockables found:", #m_kExtraUnlockables);
end


function Initialize_BTT_CivicsTree()
	--print("FUN Initialize_BTT_CivicsTree()");
	-- add all the new init stuff here
	PopulateImprovementBonus();
	PopulateImprovementAdjacency();
	PopulateFromModifiers("Civic");
	PopulateUnitCommands("PrereqCivic");
	PopulateEmbarkment("Civics", "CivicType");
	PopulateBoosts();
	print("Extra unlockables found:", #m_kExtraUnlockables);
end


-- ===========================================================================
-- 2020-07-01 Marking techs as important for easier planning
-- ===========================================================================

local DATA_PREFIX:string = "BTT_MARKED_"; -- prefix used to save/load values from the savefile
local tTechsWithUniques:table = {}; -- includes both techs and civics

function Initialize_TechsWithUniques()
    --print("FUN Initialize_TechsWithUniques");

    -- 2020-08-29 no initial marking when shuffle mode is ON
    if GameCapabilities.HasCapability("CAPABILITY_TREE_RANDOMIZER") then
        print("Marked techs and civics: none, shuffle mode is ON");
        return;
    end

    local localPlayerID:number = Game.GetLocalPlayer();
	if localPlayerID == PlayerTypes.NONE or localPlayer == PlayerTypes.OBSERVER then return; end
    
    -- Obtain "uniques" from Civilization and for the chosen leader
    local uniqueAbilities,    uniqueUnits,    uniqueBuildings    = GetLeaderUniqueTraits(       PlayerConfigurations[localPlayerID]:GetLeaderTypeName(),       true );
    local civUniqueAbilities, civUniqueUnits, civUniqueBuildings = GetCivilizationUniqueTraits( PlayerConfigurations[localPlayerID]:GetCivilizationTypeName(), true );

    -- Merge tables
    for i,v in ipairs(civUniqueAbilities) do table.insert(uniqueAbilities, v); end
    for i,v in ipairs(civUniqueUnits)     do table.insert(uniqueUnits, v);     end
    for i,v in ipairs(civUniqueBuildings) do table.insert(uniqueBuildings, v); end
    
    -- find and mark techs
    for _,item in ipairs(uniqueUnits) do
        local itemInfo:table = GameInfo.Units[item.Type];
        if itemInfo and itemInfo.PrereqTech  ~= nil then tTechsWithUniques[ itemInfo.PrereqTech ]  = true; end
        if itemInfo and itemInfo.PrereqCivic ~= nil then tTechsWithUniques[ itemInfo.PrereqCivic ] = true; end
    end
    for _,item in ipairs(uniqueBuildings) do
        local itemInfo:table = GameInfo.Buildings[item.Type];
        if itemInfo == nil then itemInfo = GameInfo.Districts[item.Type]; end
        if itemInfo == nil then itemInfo = GameInfo.Improvements[item.Type]; end
        if itemInfo and itemInfo.PrereqTech  ~= nil then tTechsWithUniques[ itemInfo.PrereqTech ]  = true; end
        if itemInfo and itemInfo.PrereqCivic ~= nil then tTechsWithUniques[ itemInfo.PrereqCivic ] = true; end
    end
    print("Marked techs and civics:");
    dshowtable(tTechsWithUniques);
end

function OnLeftClickNodeNameButton(node:table)
    --print("FUN OnLeftClickNodeNameButton", node.Type, node.Name, node.IsMarked);
    node.IsMarked = not node.IsMarked;
    node.MarkLabel:SetHide(not node.IsMarked);
    -- save the value
    local localPlayerID:number = Game.GetLocalPlayer();
    if localPlayerID ~= PlayerTypes.NONE and localPlayerID ~= PlayerTypes.OBSERVER then
        --print("saving to", DATA_PREFIX..node.Type);
        PlayerConfigurations[localPlayerID]:SetValue(DATA_PREFIX..node.Type, node.IsMarked);
    end
end

-- this is called AFTER AllocateUI(), so all nodes SHOULD be available via g_uiNodes
-- please note that PopulateNode is also called before, so some inits are moved there
function Initialize_BTT_Marking()
    --print("FUN Initialize_BTT_Marking");
    --dshowtable(g_uiNodes);
    -- hook left-clicks
    for _,node in pairs(g_uiNodes) do
		node.NodeNameButton:RegisterCallback( Mouse.eLClick, function() OnLeftClickNodeNameButton(node); end );
		node.NodeNameButton:SetSizeX( node.NodeName:GetSizeX() + 20 );
    end
end

-- read the flag from the savefile or initialize based on uniques
function PopulateNode_InitMark(uiNode:table)
    --print("FUN PopulateNode_InitMark", uiNode.Type, uiNode.IsMarked);
    if uiNode.IsMarked ~= nil then return; end -- already initialized
    -- try to retrieve the flag from the save file
    local localPlayerID:number = Game.GetLocalPlayer();
    if localPlayerID ~= PlayerTypes.NONE and localPlayerID ~= PlayerTypes.OBSERVER then
        uiNode.IsMarked = PlayerConfigurations[localPlayerID]:GetValue(DATA_PREFIX..uiNode.Type);
    end
    -- init with uniques if still nil
    --print(uiNode.Type, tTechsWithUniques[uiNode.Type]);
    if uiNode.IsMarked == nil then uiNode.IsMarked = ( tTechsWithUniques[uiNode.Type] == true ); end
    --if uiNode.IsMarked then print(uiNode.Type, tTechsWithUniques[uiNode.Type], uiNode.IsMarked, uiNode.Name); end
end


print("OK loaded TechAndCivicSupport_BTT.lua from Better Tech Tree");