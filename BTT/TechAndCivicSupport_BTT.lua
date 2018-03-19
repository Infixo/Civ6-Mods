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
--
-- ===========================================================================
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
	
	print("Adding additional icons for", sCivicType);
	
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
	
	print("Adding additional icons for", sTechType);
	
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


function Initialize_BTT_TechTree()
	dprint("FUN Initialize_BTT_TechTree()");
	-- add all the new init stuff here
end


function Initialize_BTT_CivicsTree()
	dprint("FUN Initialize_BTT_CivicsTree()");
	-- add all the new init stuff here
end

print("OK loaded TechAndCivicSupport_BTT.lua from Better Tech Tree");