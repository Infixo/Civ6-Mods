print("Loading LeaderIcon.lua from Better Leader Icon v1.0");
--[[
-- Created by Luigi Mangione on Monday Jun 5 2017
-- Copyright (c) Firaxis Games
--]]

include("LuaClass");
include("TeamSupport");
include("DiplomacyRibbonSupport");

-- Expansions check
local bIsRiseAndFall:boolean = Modding.IsModActive("1B28771A-C749-434B-9053-D1380C553DE9"); -- Rise & Fall
local bIsGatheringStorm:boolean = Modding.IsModActive("4873eb62-8ccc-4574-b784-dda455e74e68"); -- Gathering Storm
local LL = Locale.Lookup;

--	Round() from SupportFunctions.lua, fixed for negative numbers
function Round(num:number, idp:number)
	local mult:number = 10^(idp or 0);
	if num >= 0 then return math.floor(num * mult + 0.5) / mult; end
	return math.ceil(num * mult - 0.5) / mult;
end


------------------------------------------------------------------
-- Class Table
------------------------------------------------------------------
LeaderIcon = LuaClass:Extend();

------------------------------------------------------------------
-- Class Constants
------------------------------------------------------------------
LeaderIcon.DATA_FIELD_CLASS = "LEADER_ICON_CLASS";
LeaderIcon.TEAM_RIBBON_PREFIX = "ICON_TEAM_RIBBON_";
LeaderIcon.TEAM_RIBBON_SIZE = 53;

------------------------------------------------------------------
-- Static-Style allocation functions
------------------------------------------------------------------
function LeaderIcon:GetInstance(instanceManager:table, newParent:table)
	-- Create leader icon class if it has not yet been created for this instance
	local instance:table = instanceManager:GetInstance(newParent);
	return LeaderIcon:AttachInstance(instance);
end

function LeaderIcon:AttachInstance(instance:table)
	self = instance[LeaderIcon.DATA_FIELD_CLASS];
	if not self then
		self = LeaderIcon:new(instance);
		instance[LeaderIcon.DATA_FIELD_CLASS] = self;
	end
	self:Reset();
	return self, instance;
end

------------------------------------------------------------------
-- Constructor
------------------------------------------------------------------
function LeaderIcon:new(instanceOrControls: table)
	self = LuaClass.new(LeaderIcon)
	self.Controls = instanceOrControls or Controls;
	return self;
end
------------------------------------------------------------------


function LeaderIcon:UpdateIcon(iconName: string, playerID: number, isUniqueLeader: boolean, ttDetails: string)
	--print("LeaderIcon:UpdateIcon", iconName, playerID, ttDetails);
	
	local pPlayer:table = Players[playerID];
	local pPlayerConfig:table = PlayerConfigurations[playerID];
	local localPlayerID:number = Game.GetLocalPlayer();

	-- Display the civ colors/icon for duplicate civs
	if isUniqueLeader == false and (playerID == localPlayerID or Players[localPlayerID]:GetDiplomacy():HasMet(playerID)) then
		local backColor, frontColor  = UI.GetPlayerColors( playerID );
		self.Controls.CivIndicator:SetHide(false);
		self.Controls.CivIndicator:SetColor(backColor);
		self.Controls.CivIcon:SetHide(false);
		self.Controls.CivIcon:SetColor(frontColor);
		self.Controls.CivIcon:SetIcon("ICON_"..pPlayerConfig:GetCivilizationTypeName());
	else
		self.Controls.CivIcon:SetHide(true);
		self.Controls.CivIndicator:SetHide(true);
	end
	
	-- Set leader portrait and hide overlay if not local player
	self.Controls.Portrait:SetIcon(iconName);
	self.Controls.YouIndicator:SetHide(playerID ~= localPlayerID);

	-- Set the tooltip
	local tooltip:string = self:GetToolTipString(playerID);
	if (ttDetails ~= nil and ttDetails ~= "") then
		tooltip = tooltip .. "[NEWLINE]" .. ttDetails;
	end
	self.Controls.Portrait:SetToolTipString(tooltip);

	self:UpdateTeamAndRelationship(playerID);
end

function LeaderIcon:UpdateIconSimple(iconName: string, playerID: number, isUniqueLeader: boolean, ttDetails: string)
	--print("LeaderIcon:UpdateIconSimple", iconName, playerID, ttDetails);
	local localPlayerID:number = Game.GetLocalPlayer();

	self.Controls.Portrait:SetIcon(iconName);
	self.Controls.YouIndicator:SetHide(playerID ~= localPlayerID);

	-- Display the civ colors/icon for duplicate civs
	if isUniqueLeader == false and (playerID ~= -1 and Players[localPlayerID]:GetDiplomacy():HasMet(playerID)) then
		local backColor, frontColor = UI.GetPlayerColors( playerID );
		self.Controls.CivIndicator:SetHide(false);
		self.Controls.CivIndicator:SetColor(backColor);
		self.Controls.CivIcon:SetHide(false);
		self.Controls.CivIcon:SetColor(frontColor);
		self.Controls.CivIcon:SetIcon("ICON_"..PlayerConfigurations[playerID]:GetCivilizationTypeName());
	else
		self.Controls.CivIcon:SetHide(true);
		self.Controls.CivIndicator:SetHide(true);
	end

	if playerID < 0 then
		self.Controls.TeamRibbon:SetHide(true);
		self.Controls.Relationship:SetHide(true);
		self.Controls.Portrait:SetToolTipString("");
		return;
	end

	-- Set the tooltip
	local tooltip:string = self:GetToolTipString(playerID);
	if (ttDetails ~= nil and ttDetails ~= "") then
		tooltip = tooltip .. "[NEWLINE]" .. ttDetails;
	end
	self.Controls.Portrait:SetToolTipString(tooltip);

	self:UpdateTeamAndRelationship(playerID);
end

function LeaderIcon:UpdateTeamAndRelationship(playerID: number)
	--print("LeaderIcon:UpdateTeamAndRelationship", playerID);
	local pPlayer:table = Players[playerID];
	local pPlayerConfig:table = PlayerConfigurations[playerID];
	local localPlayerID:number = Game.GetLocalPlayer();
	local isHuman:boolean = pPlayerConfig:IsHuman();
	local bHasMet:boolean = Players[localPlayerID]:GetDiplomacy():HasMet(playerID)

	-- Team Ribbon
	if(playerID == localPlayerID or bHasMet) then
		-- Show team ribbon for ourselves and civs we've met
		local teamID:number = pPlayerConfig:GetTeam();
		if #Teams[teamID] > 1 then
			local teamRibbonName:string = self.TEAM_RIBBON_PREFIX .. tostring(teamID);
			self.Controls.TeamRibbon:SetIcon(teamRibbonName);
			self.Controls.TeamRibbon:SetColor(GetTeamColor(teamID));
			self.Controls.TeamRibbon:SetHide(false);
		else
			-- Hide team ribbon if team only contains one player
			self.Controls.TeamRibbon:SetHide(true);
		end
	else
		-- Hide team ribbon for civs we haven't met
		self.Controls.TeamRibbon:SetHide(true);
	end

	-- Relationship status (Humans don't show anything, unless we are at war)
	local ourRelationship = pPlayer:GetDiplomaticAI():GetDiplomaticStateIndex(localPlayerID);
	if (not isHuman or IsValidRelationship(GameInfo.DiplomaticStates[ourRelationship].StateType)) then
		self.Controls.Relationship:SetHide(false);
		self.Controls.Relationship:SetVisState(ourRelationship);
		--if (GameInfo.DiplomaticStates[ourRelationship].Hash ~= DiplomaticStates.NEUTRAL) then
			--local sRelationTT:string = Locale.Lookup(GameInfo.DiplomaticStates[ourRelationship].Name);
			--sRelationTT = sRelationTT .. "[NEWLINE][NEWLINE]MORE DIPLO INFO HERE";
			self.Controls.Relationship:SetToolTipString( self:GetRelationToolTipString(playerID) );
		--end
	else
		self.Controls.Relationship:SetHide(true);
	end
	
	-- Player's Era (dark, normal, etc.)
	if (bIsRiseAndFall or bIsGatheringStorm) and (playerID == localPlayerID or bHasMet) then
		self.Controls.CivEra:SetHide(false);
		local pGameEras:table = Game.GetEras();
		if     pGameEras:HasHeroicGoldenAge(playerID) then self.Controls.CivEra:SetText("[ICON_GLORY_SUPER_GOLDEN_AGE]"); self.Controls.CivEra:SetToolTipString(LL("LOC_ERA_PROGRESS_HEROIC_AGE"));
		elseif pGameEras:HasGoldenAge(playerID)       then self.Controls.CivEra:SetText("[ICON_GLORY_GOLDEN_AGE]");       self.Controls.CivEra:SetToolTipString(LL("LOC_ERA_PROGRESS_GOLDEN_AGE"));
		elseif pGameEras:HasDarkAge(playerID)         then self.Controls.CivEra:SetText("[ICON_GLORY_DARK_AGE]");         self.Controls.CivEra:SetToolTipString(LL("LOC_ERA_PROGRESS_DARK_AGE"));
		else                                               self.Controls.CivEra:SetText("[ICON_GLORY_NORMAL_AGE]");       self.Controls.CivEra:SetToolTipString(LL("LOC_ERA_PROGRESS_NORMAL_AGE"));
		end
	else
		self.Controls.CivEra:SetHide(true);
	end

end


--[[ RELATIONSHIP TOOLTIP
Line 1. DiplomaticState (+-diplo modifier points)
Line 2 (optional). Alliance type, Alliance Level (alliance points/next level)
Line 3. Grievances
Line 4. Access level
Line 5..7. Agendas
-------
(reasons for current diplo state) - sorted by modifier, from high to low
--]]

function LeaderIcon:GetRelationToolTipString(playerID:number)
	--print("FUN LeaderIcon:GetRelationToolTipString", playerID);
	
	local localPlayerID:number = Game.GetLocalPlayer();
	if localPlayerID == -1 then return ""; end
	local localPlayerDiplomacy = Players[localPlayerID]:GetDiplomacy();
	
	local pPlayer:table = Players[playerID];
	local pPlayerDiplomaticAI:table = pPlayer:GetDiplomaticAI();
	
	local tTT:table = {};
	
	-- DiplomaticState
	local ourRelationship = pPlayerDiplomaticAI:GetDiplomaticStateIndex(localPlayerID);
	local toolTips = pPlayerDiplomaticAI:GetDiplomaticModifiers(localPlayerID);
	local iDiploChange:number = 0;
	if toolTips then
		for _,tip in pairs(toolTips) do iDiploChange = iDiploChange + tip.Score; end
	end
	local sFormat:string = "%s ([COLOR_Grey]0[ENDCOLOR])";
	if iDiploChange > 0 then sFormat = "%s ([COLOR_Green]%+d[ENDCOLOR])"; end
	if iDiploChange < 0 then sFormat = "%s ([COLOR_Red]%+d[ENDCOLOR])"; end
	table.insert(tTT, string.format(sFormat, Locale.Lookup(GameInfo.DiplomaticStates[ourRelationship].Name), iDiploChange));
	
	-- Alliance
	if bIsRiseAndFall or bIsGatheringStorm then
		local allianceType = localPlayerDiplomacy:GetAllianceType(playerID);
		if allianceType ~= -1 then
			table.insert(tTT, LL(GameInfo.Alliances[allianceType].Name).." "..LL("LOC_DIPLOACTION_ALLIANCE_LEVEL", localPlayerDiplomacy:GetAllianceLevel(playerID)));
		end
	end
	
	-- Grievances
	if bIsGatheringStorm and playerID ~= localPlayerID then
		local iGrievances:number = Players[Game.GetLocalPlayer()]:GetDiplomacy():GetGrievancesAgainst(playerID);
		if     iGrievances > 0 then table.insert(tTT, "[COLOR_Green]"..LL("LOC_DIPLOMACY_GRIEVANCES_WITH_THEM_SIMPLE", iGrievances).."[ENDCOLOR]");
		elseif iGrievances < 0 then table.insert(tTT, "[COLOR_Red]"..LL("LOC_DIPLOMACY_GRIEVANCES_WITH_US_SIMPLE", -iGrievances).."[ENDCOLOR]");
		else                        table.insert(tTT, LL("LOC_DIPLOMACY_GRIEVANCES_NONE_SIMPLE"));
		end
	end
	-- GRIEVANCE, STAT_GRIEVANCE, GRIEVANCE_TT
	
	-- Access level
	local iAccessLevel = localPlayerDiplomacy:GetVisibilityOn(playerID);
	table.insert(tTT, string.format("%s %s [COLOR_Grey](%d)[ENDCOLOR]", LL("LOC_DIPLOMACY_INTEL_ACCESS_LEVEL"), LL(GameInfo.Visibilities[iAccessLevel].Name), iAccessLevel));
	-- ICON_VisLimited, VisOpen, VisSecret, VisTopSecret
	
	-- Diplo modifiers, from DiplomacyActionView.lua
	--[[
	if toolTips then
		table.insert(tTT, "----------------------------------------"); -- 40 chars
		table.sort(toolTips, function(a,b) return a.Score > b.Score; end);
		for _,tip in ipairs(toolTips) do
			local score = tip.Score;
			local text = tip.Text;
			if score ~= 0 then
				local scoreText = Locale.Lookup("{1_Score : number +#,###.##;-#,###.##}", score);
				--local scoreText:string = string.format("%+ 3d", score);
				if score > 0 then scoreText = "[COLOR_Green]"..scoreText.."[ENDCOLOR]";
				else              scoreText = "[COLOR_Red]"..scoreText.."[ENDCOLOR]"; end
				--print("score, text", score, text);
				if text == LL("LOC_TOOLTIP_DIPLOMACY_UNKNOWN_REASON") then scoreText = scoreText.." - [COLOR_Grey]"..text.."[ENDCOLOR]";
				else                                                       scoreText = scoreText.." - "..text; end
				table.insert(tTT, scoreText);
			end -- if
		end -- for
	end -- if
	--]]
	return table.concat(tTT, "[NEWLINE]");
end


-- bottom-right - age (normal, dark, etc.)

--Resets instances we retrieve
function LeaderIcon:Reset()
	self.Controls.TeamRibbon:SetHide(true);
 	self.Controls.Relationship:SetHide(true);
 	self.Controls.YouIndicator:SetHide(true);
end

------------------------------------------------------------------
function LeaderIcon:RegisterCallback(event: number, func: ifunction)
	self.Controls.SelectButton:RegisterCallback(event, func);
end

--[[ EXTENDED TOOLTIP - more or less from EDR, however Victories section
- add religion! civs & cities converted
- add Diplo Points
- add Exoplanet Expedition %
- add Culture% (and turns)

- num of civics? it is visible in Score (2p/civic)
--]]
------------------------------------------------------------------
function LeaderIcon:GetToolTipString(playerID:number)
	--print("LeaderIcon:GetToolTipString", playerID);

	local tTT:table = {};
	local result:string = "";
	local pPlayer:table = Players[playerID];
	local pPlayerConfig:table = PlayerConfigurations[playerID];

	if pPlayerConfig and pPlayerConfig:GetLeaderTypeName() then
		local isHuman:boolean = pPlayerConfig:IsHuman();
		local localPlayerID:number = Game.GetLocalPlayer();
		local leaderDesc:string = pPlayerConfig:GetLeaderName();
		local civDesc:string = pPlayerConfig:GetCivilizationDescription();
		
		if GameConfiguration.IsAnyMultiplayer() and isHuman then
			if(playerID ~= localPlayerID and not Players[localPlayerID]:GetDiplomacy():HasMet(playerID)) then
				result = Locale.Lookup("LOC_DIPLOPANEL_UNMET_PLAYER") .. " (" .. pPlayerConfig:GetPlayerName() .. ")";
				return result;
			else
				result = Locale.Lookup("LOC_DIPLOMACY_DEAL_PLAYER_PANEL_TITLE", leaderDesc, civDesc) .. " (" .. pPlayerConfig:GetPlayerName() .. ")";
			end
		else
			if(playerID ~= localPlayerID and not Players[localPlayerID]:GetDiplomacy():HasMet(playerID)) then
				result = Locale.Lookup("LOC_DIPLOPANEL_UNMET_PLAYER");
				return result;
			else
				result = Locale.Lookup("LOC_DIPLOMACY_DEAL_PLAYER_PANEL_TITLE", leaderDesc, civDesc);
			end
		end
	end
	--return result;
	table.insert(tTT, result);
	
	-- Government
	local eGovernment:number = Players[playerID]:GetCulture():GetCurrentGovernment();
	table.insert(tTT, string.format("%s %s", LL("LOC_DIPLOMACY_INTEL_GOVERNMENT"), LL(eGovernment == -1 and "LOC_GOVERNMENT_ANARCHY_NAME" or GameInfo.Governments[eGovernment].Name)));
	
	-- Cities & Population
	local iPopulation:number = 0;
	for _,city in Players[playerID]:GetCities():Members() do
		iPopulation = iPopulation + city:GetPopulation();
	end
	table.insert(tTT, string.format("%s: %d[ICON_Housing]  %s: %d[ICON_Citizen]",
		LL("LOC_REPORTS_CITIES"), pPlayer:GetCities():GetCount(),
		Locale.Lookup("LOC_HUD_CITY_POPULATION"), iPopulation));

	-- Gold
	local playerTreasury:table = pPlayer:GetTreasury();
	local iGoldBalance:number = playerTreasury:GetGoldBalance();
	--local iGoldPerTurn:number = playerTreasury:GetGoldYield() - playerTreasury:GetTotalMaintenance();

	-- Separator
	table.insert(tTT, "--------------------------------------------------"); -- 50 chars

	-- Statistics
	table.insert(tTT, "[ICON_Capital] " ..LL("LOC_WORLD_RANKINGS_OVERVIEW_DOMINATION_SCORE", tostring(pPlayer:GetScore())));
	table.insert(tTT, "[ICON_Strength] "..LL("LOC_WORLD_RANKINGS_OVERVIEW_DOMINATION_MILITARY_STRENGTH", "[COLOR_Military]"..tostring(pPlayer:GetStats():GetMilitaryStrengthWithoutTreasury()).."[ENDCOLOR]"));
	--table.insert(tTT, string.format("[ICON_Gold] %s: [COLOR_Gold]%d[ENDCOLOR] (%+.1f)", LL("LOC_YIELD_GOLD_NAME"), iGoldBalance, iGoldPerTurn));
	table.insert(tTT, "[ICON_Gold] "..LL("LOC_YIELD_GOLD_NAME")..": [COLOR_GoldDark]"..tostring(Round(iGoldBalance,0)).."[ENDCOLOR]");
	--.."[NEWLINE][ICON_Gold] "..goldBalance.."   ( " .. "[COLOR_GoldMetalDark]" .. (iGoldPerTurn>0 and "+" or "") .. (iGoldPerTurn>0 and iGoldPerTurn or "-?") .. "[ENDCOLOR]  )"
	table.insert(tTT, "[ICON_Science] "..LL("LOC_WORLD_RANKINGS_OVERVIEW_SCIENCE_NUM_TECHS", "[COLOR_Science]" ..tostring(pPlayer:GetStats():GetNumTechsResearched()).. "[ENDCOLOR]"));
	table.insert(tTT, LL("LOC_WORLD_RANKINGS_OVERVIEW_SCIENCE_SCIENCE_RATE", "[COLOR_Science]"..tostring(Round(pPlayer:GetTechs():GetScienceYield(),1)).."[ENDCOLOR]"));
	table.insert(tTT, LL("LOC_WORLD_RANKINGS_OVERVIEW_CULTURE_TOURISM_RATE", "[COLOR_Tourism]"..tostring(Round(pPlayer:GetStats():GetTourism(),1)).."[ENDCOLOR]"));
	table.insert(tTT, LL("LOC_WORLD_RANKINGS_OVERVIEW_CULTURE_CULTURE_RATE", "[COLOR_Culture]"..tostring(Round(pPlayer:GetCulture():GetCultureYield(),1)).."[ENDCOLOR]"));
	table.insert(tTT, LL("LOC_WORLD_RANKINGS_OVERVIEW_RELIGION_FAITH_RATE", "[COLOR_FaithDark]"..tostring(Round(pPlayer:GetReligion():GetFaithYield(),1)).."[ENDCOLOR]"));
	table.insert(tTT, "[ICON_Faith] "..LL("LOC_WORLD_RANKINGS_OVERVIEW_RELIGION_CITIES_FOLLOWING_RELIGION", "[COLOR_FaithDark]"..tostring(pPlayer:GetStats():GetNumCitiesFollowingReligion()).."[ENDCOLOR]"));
	if bIsGatheringStorm then
		table.insert(tTT, " [ICON_Favor]  "..LL("LOC_DIPLOMATIC_FAVOR_NAME")..": [COLOR_GoldDark]"..tostring(pPlayer:GetFavor()).."[ENDCOLOR]"); -- ICON_Favor_Large is too big
	end

	-- Victories
	--[[
	GetText = function(p) 
		local total = GlobalParameters.DIPLOMATIC_VICTORY_POINTS_REQUIRED;
		local current = 0;
		if (p:IsAlive()) then
			current = p:GetStats():GetDiplomaticVictoryPoints();
		end

		return Locale.Lookup("LOC_WORLD_RANKINGS_DIPLOMATIC_POINTS_TT", current, total);
	end,
	--]]
	
	--local canTrade, tooltip = CheckTrades(playerID, 0, EDR_showAllResources);
	
	return table.concat(tTT, "[NEWLINE]");
end

print("OK loaded LeaderIcon.lua from Better Leader Icon v1.0");