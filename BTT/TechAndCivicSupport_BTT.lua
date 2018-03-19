print("Loading TechAndCivicSupport_BTT.lua from Better Tech Tree version 1.0");
-- ===========================================================================
-- Better Tech Tree
-- Author: Infixo
-- 2018-03-19: Created
-- ===========================================================================

-- Rise & Fall check
local bIsRiseFall:boolean = Modding.IsModActive("1B28771A-C749-434B-9053-D1380C553DE9"); -- Rise & Fall
print("Rise & Fall", (bIsRiseFall and "YES" or "no"));


-- ===========================================================================
-- CACHE BASE FUNCTIONS
-- ===========================================================================
BTT_BASE_PopulateUnlockablesForCivic = PopulateUnlockablesForCivic;
BTT_BASE_PopulateUnlockablesForTech = PopulateUnlockablesForTech;


-- ===========================================================================
-- DEBUG ROUTINES
-- ===========================================================================

-- debug output routine
function dprint(sStr,p1,p2,p3,p4,p5,p6)
	local sOutStr = sStr;
	if p1 ~= nil then sOutStr = sOutStr.." [1] "..tostring(p1); end
	if p2 ~= nil then sOutStr = sOutStr.." [2] "..tostring(p2); end
	if p3 ~= nil then sOutStr = sOutStr.." [3] "..tostring(p3); end
	if p4 ~= nil then sOutStr = sOutStr.." [4] "..tostring(p4); end
	if p5 ~= nil then sOutStr = sOutStr.." [5] "..tostring(p5); end
	if p6 ~= nil then sOutStr = sOutStr.." [6] "..tostring(p6); end
	print(Game:GetCurrentGameTurn().." "..sOutStr);
end

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
	print("found", #tExtras, "for", sType)
	return tExtras;
end

function AddExtraUnlockable(sType:string, sUnlockKind:string, sUnlockType:string, sDescription:string, sPediaKey:string)
	dprint("FUN AddExtraUnlockable",sType, sUnlockKind, sUnlockType, sDescription, sPediaKey);
	local tItem:table = {
		Type = sType,
		UnlockKind = sUnlockKind, -- "BOOST", "IMPROVEMENT", "SPY", "HARVEST"
		UnlockType = sUnlockType, -- actual object to be shown
		Description = sDescription, -- additional info, to put on the icon OR into the tooltip
		PediaKey = sPediaKey,
	}
	table.insert(m_kExtraUnlockables, tItem);
end


-- ===========================================================================
--
-- ===========================================================================

local tBackgroundTextures:table = {
	BOOST_CIVIC = "ICON_TECHUNLOCK_5", -- same as Resources "LaunchBar_Hook_CultureButton",
	BOOST_TECH = "ICON_TECHUNLOCK_5", -- "LaunchBar_Hook_ScienceButton",
};

-- this will add 1 simple unlockable, i.e. only background and icon
function PopulateUnlockableSimple(tItem:table, instanceManager:table)
	dprint("FUN PopulateUnlockableSimple"); dshowtable(tItem);

	local unlockInstance = instanceManager:GetInstance();

	-- background is taken from Kind
	unlockInstance.UnlockIcon:SetTexture( IconManager:FindIconAtlas(tBackgroundTextures[tItem.UnlockKind], 38) );
	--unlockInstance.UnlockIcon:SetTexture( tBackgroundTextures[tItem.UnlockKind] );
	
	-- the actual icon is taken from Type
	unlockInstance.Icon:SetIcon("ICON_"..tItem.UnlockType); -- control:SetTexture( IconManager:FindIconAtlas("ICON_TECH_ENGINEERING", 38) );
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
	--dprint("FUN PopulateUnlockablesForCivic (pid,cid,bhide)",playerID,civicID,hideDescriptionIcon);
	
	local civicInfo:table = GameInfo.Civics[civicID];
	if civicInfo == nil then
		print("ERROR: PopulateUnlockablesForCivic Unable to find a civic type in the database with an ID value of", civicID);
		return;
	end
	
	local sCivicType:string = civicInfo.CivicType;
	local iNumIcons:number = 0;
	
	iNumIcons = BTT_BASE_PopulateUnlockablesForCivic(playerID, civicID, kItemIM, kGovernmentIM, callback, hideDescriptionIcon );
	if iNumIcons == nil then iNumIcons = 0; end
	
	--print("Adding additional icons for", sCivicType);
	
	for _,item in ipairs( GetExtraUnlockables(sCivicType) ) do
		PopulateUnlockableSimple(item, kItemIM);
		iNumIcons = iNumIcons + 1;
	end
	
	return iNumIcons;
end

function PopulateUnlockablesForCivic_REMOVE(playerID:number, civicID:number, kItemIM:table, kGovernmentIM:table, callback:ifunction, hideDescriptionIcon:boolean )

	local governmentData = GetGovernmentData();
	local civicType:string = civicData.CivicType;

	-- Unlockables is an array of {type, name}
	local numIcons:number = 0;
	local unlockables = GetUnlockablesForCivic_Cached(civicType, playerID);
	
	if(unlockables and #unlockables > 0) then
		for i,v in ipairs(unlockables) do

			local typeName = v[1];
			local civilopediaKey = v[3];
			local typeInfo = GameInfo.Types[typeName];
		
			if(kGovernmentIM and typeInfo and typeInfo.Kind == "KIND_GOVERNMENT") then

				local unlock = kGovernmentIM:GetInstance();

				local government = governmentData[typeName];
				if(government) then
					unlock.MilitaryPolicyLabel:SetText(tostring(government.NumSlotMilitary));
					unlock.EconomicPolicyLabel:SetText(tostring(government.NumSlotEconomic));
					unlock.DiplomaticPolicyLabel:SetText(tostring(government.NumSlotDiplomatic));
					unlock.WildcardPolicyLabel:SetText(tostring(government.NumSlotWildcard));
					unlock.GovernmentName:SetText(Locale.Lookup(government.Name));
				end	
				local toolTip = ToolTipHelper.GetToolTip(typeName, playerID);
				unlock.GovernmentInstanceGrid:LocalizeAndSetToolTip(toolTip);

				unlock.GovernmentInstanceGrid:RegisterCallback(Mouse.eLClick, callback);

				if(not IsTutorialRunning()) then
					unlock.GovernmentInstanceGrid:RegisterCallback(Mouse.eRClick, function() 
						LuaEvents.OpenCivilopedia(civilopediaKey);
					end);
				end
			else
				local unlockIcon = kItemIM:GetInstance();
				local icon = GetUnlockIcon(typeName);	
				unlockIcon.Icon:SetIcon("ICON_"..typeName);
				unlockIcon.Icon:SetHide(false);

				local textureOffsetX, textureOffsetY, textureSheet = IconManager:FindIconAtlas(icon,38);
				if textureSheet ~= nil then
					unlockIcon.UnlockIcon:SetTexture(textureOffsetX, textureOffsetY, textureSheet);
				end

				local toolTip = ToolTipHelper.GetToolTip(typeName, playerID);

				unlockIcon.UnlockIcon:LocalizeAndSetToolTip(toolTip);
			
				if callback ~= nil then		
					unlockIcon.UnlockIcon:RegisterCallback(Mouse.eLClick, callback);
				else
					unlockIcon.UnlockIcon:ClearCallback(Mouse.eLClick);
				end

				if(not IsTutorialRunning()) then
					unlockIcon.UnlockIcon:RegisterCallback(Mouse.eRClick, function() 
						LuaEvents.OpenCivilopedia(civilopediaKey);
					end);
				end
			end

			numIcons = numIcons + 1;
		end
		
	end

	if (civicData.Description and hideDescriptionIcon ~= true) then
		local unlockIcon:table	= kItemIM:GetInstance();
		unlockIcon.Icon:SetHide(true); -- foreground icon unnecessary in this case
		local textureOffsetX, textureOffsetY, textureSheet = IconManager:FindIconAtlas("ICON_TECHUNLOCK_13",38);
		if textureSheet ~= nil then
			unlockIcon.UnlockIcon:SetTexture(textureOffsetX, textureOffsetY, textureSheet);
		end
		unlockIcon.UnlockIcon:LocalizeAndSetToolTip(GameInfo.Civics[civicID].Description);
		if callback ~= nil then		
			unlockIcon.UnlockIcon:RegisterCallback(Mouse.eLClick, callback);
		else
			unlockIcon.UnlockIcon:ClearCallback(Mouse.eLClick);
		end

		if(not IsTutorialRunning()) then
			unlockIcon.UnlockIcon:RegisterCallback(Mouse.eRClick, function() 
				LuaEvents.OpenCivilopedia(civicType);
			end);
		end

		numIcons = numIcons + 1;
	end

	kItemIM.m_ParentControl:CalculateSize();

	return numIcons;
end


-- ===========================================================================
--
-- ===========================================================================
function PopulateUnlockablesForTech(playerID:number, techID:number, instanceManager:table, callback:ifunction )
	--dprint("FUN PopulateUnlockablesForTech (pid,tid)",playerID,techID);

	local techInfo:table = GameInfo.Technologies[techID];
	if techInfo == nil then
		print("ERROR: PopulateUnlockablesForTech Unable to find a tech type in the database with an ID value of", techID);
		return;
	end
	
	local sTechType:string = techInfo.TechnologyType;
	local iNumIcons:number = 0;
	
	iNumIcons = BTT_BASE_PopulateUnlockablesForTech(playerID, techID, instanceManager, callback);
	if iNumIcons == nil then iNumIcons = 0; end

	-- debug
	--local unlockables:table = GetUnlockablesForTech_Cached(sTechType, playerID);
	--for i,v in ipairs(unlockables) do print("pedia key",v[3]) end
	
	--print("Adding additional icons for", sTechType);
	
	for _,item in ipairs( GetExtraUnlockables(sTechType) ) do
		PopulateUnlockableSimple(item, instanceManager);
		iNumIcons = iNumIcons + 1;
	end
	
	return iNumIcons;
end
	
function PopulateUnlockablesForTech_REMOVE(playerID:number, techID:number, instanceManager:table, callback:ifunction )

	-- Unlockables is an array of {type, name}
	local numIcons:number = 0;
	local unlockables:table = GetUnlockablesForTech_Cached(techType, playerID);

	-- Hard-coded goodness.
	if unlockables and table.count(unlockables) > 0 then
		for i,v in ipairs(unlockables) do

			local typeName	:string = v[1];
			local civilopediaKey = v[3];
			local unlockIcon:table	= instanceManager:GetInstance();
			
			local icon = GetUnlockIcon(typeName);		
			unlockIcon.Icon:SetIcon("ICON_"..typeName);
			unlockIcon.Icon:SetHide(false);
			 
			local textureOffsetX, textureOffsetY, textureSheet = IconManager:FindIconAtlas(icon,38);
			if textureSheet ~= nil then
				unlockIcon.UnlockIcon:SetTexture(textureOffsetX, textureOffsetY, textureSheet);
			end

			local toolTip :string = ToolTipHelper.GetToolTip(typeName, playerID);
			unlockIcon.UnlockIcon:LocalizeAndSetToolTip(toolTip);
			if callback ~= nil then		
				unlockIcon.UnlockIcon:RegisterCallback(Mouse.eLClick, callback);
			else
				unlockIcon.UnlockIcon:ClearCallback(Mouse.eLClick);
			end

			if(not IsTutorialRunning()) then
				unlockIcon.UnlockIcon:RegisterCallback(Mouse.eRClick, function() 
					LuaEvents.OpenCivilopedia(civilopediaKey);
				end);
			end
		end

		numIcons = numIcons + 1;
	end

	if (GameInfo.Technologies[techID].Description) then
		local unlockIcon:table	= instanceManager:GetInstance();
		unlockIcon.Icon:SetHide(true); -- foreground icon unnecessary in this case
		local textureOffsetX, textureOffsetY, textureSheet = IconManager:FindIconAtlas("ICON_TECHUNLOCK_13",38);
		if textureSheet ~= nil then
			unlockIcon.UnlockIcon:SetTexture(textureOffsetX, textureOffsetY, textureSheet);
		end
		unlockIcon.UnlockIcon:LocalizeAndSetToolTip(GameInfo.Technologies[techID].Description);
		if callback ~= nil then		
			unlockIcon.UnlockIcon:RegisterCallback(Mouse.eLClick, callback);
		else
			unlockIcon.UnlockIcon:ClearCallback(Mouse.eLClick);
		end

		if(not IsTutorialRunning()) then
			unlockIcon.UnlockIcon:RegisterCallback(Mouse.eRClick, function() 
				LuaEvents.OpenCivilopedia(GameInfo.Technologies[techID].TechnologyType);
			end);
		end

		numIcons = numIcons + 1;
	end

	return numIcons;
end

-- ===========================================================================
-- POPULATE EXTRA UNLOCKABLES
-- ===========================================================================

-- simple version first, only for direct Civic/Tech boosts
-- TODO: add support for Units, Districts and Buildings
function PopulateBoosts()
	local sType:string, sUnlockKind:string, sUnlockType:string, sDescription:string, sPediaKey:string, objectInfo:table;
	
	for row in GameInfo.Boosts() do
		-- what is boosted?
		if     row.TechnologyType then
			sUnlockKind = "BOOST_TECH"; sUnlockType = row.TechnologyType; sPediaKey = row.TechnologyType;
			sDescription = Locale.Lookup("LOC_BTT_BOOST_TECH_DESC", Locale.Lookup(GameInfo.Technologies[row.TechnologyType].Name), row.Boost);
		elseif row.CivicType then
			sUnlockKind = "BOOST_CIVIC"; sUnlockType = row.CivicType; sPediaKey = row.CivicType;
			sDescription = Locale.Lookup("LOC_BTT_BOOST_CIVIC_DESC", Locale.Lookup(GameInfo.Civics[row.CivicType].Name), row.Boost);
		else
			-- error in boost definition
		end
		-- what is the boost? it gives Type; in rare cases can generate more than 1 unlock!
		if row.BoostingCivicType then
			sType = row.BoostingCivicType;
			sDescription = Locale.Lookup( GameInfo.Civics[sType].Name )..": "..sDescription;
			AddExtraUnlockable(sType, sUnlockKind, sUnlockType, sDescription, sPediaKey);
		end
		if row.BoostingTechType then
			sType = row.BoostingTechType;
			sDescription = Locale.Lookup( GameInfo.Technologies[sType].Name )..": "..sDescription;
			AddExtraUnlockable(sType, sUnlockKind, sUnlockType, sDescription, sPediaKey);
		end
		if row.DistrictType then
			sType = nil;
			objectInfo = GameInfo.Districts[row.DistrictType];
			if objectInfo then sType = ( objectInfo.PrereqTech and objectInfo.PrereqTech or objectInfo.PrereqCivic ); end
			if sType then
				sDescription = Locale.Lookup(objectInfo.Name)..": "..sDescription;
				if row.BoostClass == "BOOST_TRIGGER_HAVE_X_DISTRICTS" then sDescription = tostring(row.NumItems).." "..sDescription; end
				AddExtraUnlockable(sType, sUnlockKind, sUnlockType, sDescription, sPediaKey);
			end
		end
		if row.BuildingType then
			sType = nil;
			objectInfo = GameInfo.Buildings[row.BuildingType];
			if objectInfo then sType = ( objectInfo.PrereqTech and objectInfo.PrereqTech or objectInfo.PrereqCivic ); end
			if sType then
				sDescription = Locale.Lookup(objectInfo.Name)..": "..sDescription;
				if row.BoostClass == "BOOST_TRIGGER_HAVE_X_BUILDINGS" then sDescription = tostring(row.NumItems).." "..sDescription; end
				AddExtraUnlockable(sType, sUnlockKind, sUnlockType, sDescription, sPediaKey);
			end
		end
		if row.Unit1Type then
			sType = nil;
			objectInfo = GameInfo.Units[row.Unit1Type];
			if objectInfo then sType = ( objectInfo.PrereqTech and objectInfo.PrereqTech or objectInfo.PrereqCivic ); end
			if sType then
				sDescription = Locale.Lookup(objectInfo.Name)..": "..sDescription;
				if row.BoostClass == "BOOST_TRIGGER_OWN_X_UNITS_OF_TYPE" or row.BoostClass == "BOOST_TRIGGER_MAINTAIN_X_TRADE_ROUTES" then sDescription = tostring(row.NumItems).." "..sDescription; end
				AddExtraUnlockable(sType, sUnlockKind, sUnlockType, sDescription, sPediaKey);
			end
		end
		if row.ResourceType then
			sType = nil;
			objectInfo = GameInfo.Resources[row.ResourceType];
			if objectInfo then sType = ( objectInfo.PrereqTech and objectInfo.PrereqTech or objectInfo.PrereqCivic ); end
			if sType then
				sDescription = Locale.Lookup(objectInfo.Name)..": "..sDescription;
				AddExtraUnlockable(sType, sUnlockKind, sUnlockType, sDescription, sPediaKey);
			end
		end
		if row.ImprovementType and row.ResourceType == nil then
			sType = nil;
			objectInfo = GameInfo.Improvements[row.ImprovementType];
			if objectInfo then sType = ( objectInfo.PrereqTech and objectInfo.PrereqTech or objectInfo.PrereqCivic ); end
			if sType then
				sDescription = Locale.Lookup(objectInfo.Name)..": "..sDescription;
				if row.BoostClass == "BOOST_TRIGGER_HAVE_X_IMPROVEMENTS" then sDescription = tostring(row.NumItems).." "..sDescription; end
				AddExtraUnlockable(sType, sUnlockKind, sUnlockType, sDescription, sPediaKey);
			end
		end
		--[[
		if row.BoostingCivicType and row.TechnologyType then
			AddExtraUnlockable(row.BoostingCivicType, "BOOST_TECH", row.TechnologyType, Locale.Lookup("LOC_BTT_BOOST_TECH_DESC", Locale.Lookup(GameInfo.Technologies[row.TechnologyType].Name), row.Boost), row.TechnologyType);
		end
		if row.BoostingTechType and row.CivicType then
			AddExtraUnlockable(row.BoostingTechType, "BOOST_CIVIC", row.CivicType, Locale.Lookup("LOC_BTT_BOOST_CIVIC_DESC", Locale.Lookup(GameInfo.Civics[row.CivicType].Name), row.Boost), row.CivicType);
		end
		--]]
		--AddExtraUnlockable(sType, sUnlockKind, sUnlockType, sDescription, sPediaKey);
	end
end



function Initialize_BTT_TechTree()
	dprint("FUN Initialize_BTT_TechTree()");
	-- add all the new init stuff here
	PopulateBoosts();
end


function Initialize_BTT_CivicsTree()
	dprint("FUN Initialize_BTT_CivicsTree()");
	-- add all the new init stuff here
	PopulateBoosts();
end

print("OK loaded TechAndCivicSupport_BTT.lua from Better Tech Tree");