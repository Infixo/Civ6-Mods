print("Loading LeaderIcon.lua from Better Leader Icon version "..GlobalParameters.BLI_VERSION_MAJOR.."."..GlobalParameters.BLI_VERSION_MINOR);
-- ===========================================================================
-- Better Leader Icon
-- Author: Infixo
-- 2019-03-21: Created
-- ===========================================================================

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

-- configuration options
local bOptionRelationship:boolean = ( GlobalParameters.BLI_OPTION_RELATIONSHIP == 1 );

-- colors with better visibility in the tooltip
local ENDCOLOR:string = "[ENDCOLOR]";
local COLOR_GREEN:string = "[COLOR:0,127,0,255]";
local COLOR_RED:string   = "[COLOR:127,0,0,255]";
function ColorGREEN(s:string) return COLOR_GREEN..s..ENDCOLOR; end
function ColorRED(s:string)   return COLOR_RED  ..s..ENDCOLOR; end

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
	
	self:UpdateAllToolTips(playerID, ttDetails);
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
	
	self:UpdateAllToolTips(playerID, ttDetails);
end


function LeaderIcon:UpdateAllToolTips(playerID:number, ttDetails: string)
	-- Set the tooltip and deal flags
	local tooltip:string, bYourItems:boolean, bTheirItems:boolean = self:GetToolTipString(playerID);
	if (ttDetails ~= nil and ttDetails ~= "") then
		tooltip = tooltip .. "[NEWLINE]" .. ttDetails;
	end
	self.Controls.Portrait:SetToolTipString(tooltip);
	self.Controls.YourItems:SetHide(not bYourItems);
	self.Controls.TheirItems:SetHide(not bTheirItems);

	self:UpdateTeamAndRelationship(playerID);
end


function LeaderIcon:UpdateTeamAndRelationship(playerID: number)
	--print("LeaderIcon:UpdateTeamAndRelationship", playerID);
	local pPlayer:table = Players[playerID];
	local pPlayerConfig:table = PlayerConfigurations[playerID];
	local localPlayerID:number = Game.GetLocalPlayer();
	local isHuman:boolean = pPlayerConfig:IsHuman();
	local bHasMet:boolean = Players[localPlayerID]:GetDiplomacy():HasMet(playerID);

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

local iDenounceTimeLimit:number = Game.GetGameDiplomacy():GetDenounceTimeLimit();
local iMinPeaceDuration:number  = Game.GetGameDiplomacy():GetMinPeaceDuration(); -- this is also min. war duration

-- icons for various types of alliances
local tAllianceIcons:table = {
	ALLIANCE_RESEARCH = "[ICON_Science]",
	ALLIANCE_CULTURAL = "[ICON_Culture]",
	ALLIANCE_ECONOMIC = "[ICON_Gold]",
	ALLIANCE_MILITARY = "[ICON_Strength]",
	ALLIANCE_RELIGIOUS = "[ICON_Faith]",
};

-- detect the visibility level that grants access to random agendas
local iAccessAgendas:number = 999;
for row in GameInfo.Visibilities() do
	if row.RevealAgendas then iAccessAgendas = row.Index; break; end
end
--print("iAccessAgendas", iAccessAgendas);

function LeaderIcon:GetRelationToolTipString(playerID:number)
	--print("FUN LeaderIcon:GetRelationToolTipString", playerID);
	
	local localPlayerID:number = Game.GetLocalPlayer();
	if localPlayerID == -1 then return ""; end
	local localPlayerDiplomacy = Players[localPlayerID]:GetDiplomacy();
	
	local pPlayer:table = Players[playerID];
	local pPlayerDiplomaticAI:table = pPlayer:GetDiplomaticAI();
	
	local tTT:table = {};
	
	-- DiplomaticState (what do they think of us?)
	local iState:number = pPlayerDiplomaticAI:GetDiplomaticStateIndex(localPlayerID);
	local infoState:table = GameInfo.DiplomaticStates[iState];
	
	-- Remaining turns for Denounced and Declared Friend
	local iRemainingTurns:number = -1;
	if infoState.StateType == "DIPLO_STATE_DECLARED_FRIEND" then
		iRemainingTurns = localPlayerDiplomacy:GetDeclaredFriendshipTurn(playerID) + iDenounceTimeLimit - Game.GetCurrentGameTurn();
	end
	if infoState.StateType == "DIPLO_STATE_DENOUNCED" then
		local iOurDenounceTurn = localPlayerDiplomacy:GetDenounceTurn(playerID);
		local iTheirDenounceTurn = pPlayer:GetDiplomacy():GetDenounceTurn(localPlayerID);
		local iPlayerOrderAdjustment = 0;
		if iTheirDenounceTurn >= iOurDenounceTurn then
			if playerID > localPlayerID then iPlayerOrderAdjustment = 1; end
		else
			if localPlayerID > playerID then iPlayerOrderAdjustment = 1; end
		end
		iRemainingTurns = 1 + math.max(iOurDenounceTurn, iTheirDenounceTurn) + iDenounceTimeLimit - Game.GetCurrentGameTurn() + iPlayerOrderAdjustment;
	end
	-- Remaining turns for peace deal if at war
	local bIsAtWar:boolean = false;
	local bIsPeaceDeal:boolean = false;
	if infoState.StateType == "DIPLO_STATE_WAR" then
		bIsAtWar = true;
		local bValidAction, tResults = localPlayerDiplomacy:IsDiplomaticActionValid("DIPLOACTION_PROPOSE_PEACE_DEAL", playerID, true);
		bIsPeaceDeal = bValidAction;
		iRemainingTurns = iMinPeaceDuration + localPlayerDiplomacy:GetAtWarChangeTurn(playerID) - Game.GetCurrentGameTurn();
	end
	
	local sDiploTT:string = LL(infoState.Name);
	if bIsAtWar then
		if bIsPeaceDeal then sDiploTT = sDiploTT.."  "..ColorGREEN(LL("LOC_DIPLOACTION_MAKE_PEACE_NAME"));
		else                 sDiploTT = sDiploTT.."  "..ColorRED(tostring(iRemainingTurns)).."[ICON_TURN] "..LL("LOC_DIPLOACTION_MAKE_PEACE_NAME"); end
	elseif iRemainingTurns ~= -1 then
		sDiploTT = sDiploTT.."  [ICON_TURN]"..LL("LOC_ESPIONAGEPOPUP_TURNS_REMAINING", iRemainingTurns);
	end
	table.insert(tTT, sDiploTT);
	
	-- relationship change LOC_DIPLOMACY_INTEL_RELATIONSHIP
	local iDiploChange:number = 0;
	local toolTips = pPlayerDiplomaticAI:GetDiplomaticModifiers(localPlayerID);
	if toolTips then
		for _,tip in pairs(toolTips) do iDiploChange = iDiploChange + tip.Score; end
	end
	if iDiploChange ~= 0 then
		local sDiploChange:string = "0";
		if iDiploChange > 0 then sDiploChange = "[ICON_PressureUp]"  ..ColorGREEN("+"..tostring(iDiploChange)); end
		if iDiploChange < 0 then sDiploChange = "[ICON_PressureDown]"..ColorRED(       tostring(iDiploChange)); end
		table.insert(tTT, sDiploChange);
	end

	-- impact of the diplo relation on yields
	local sYields:string = tostring(infoState.DiplomaticYieldBonus).."%";
	if infoState.DiplomaticYieldBonus > 0 then sYields = ColorGREEN("+"..sYields); end
	if infoState.DiplomaticYieldBonus < 0 then sYields = ColorRED(       sYields); end
	table.insert(tTT, LL("LOC_HUD_REPORTS_TAB_YIELDS")..": "..sYields);
	
	-- Alliance
	if bIsRiseAndFall or bIsGatheringStorm then
		local allianceType = localPlayerDiplomacy:GetAllianceType(playerID);
		if allianceType ~= -1 then
			local info:table = GameInfo.Alliances[allianceType];
			table.insert(tTT, tAllianceIcons[info.AllianceType]..LL(info.Name).." "..LL("LOC_DIPLOACTION_ALLIANCE_LEVEL", localPlayerDiplomacy:GetAllianceLevel(playerID)));
			--table.insert(tTT, tAllianceIcons[info.AllianceType]..LL(info.Name).." "..string.rep("[ICON_Alliance]", localPlayerDiplomacy:GetAllianceLevel(playerID)));
			local iTurns:number = localPlayerDiplomacy:GetAllianceTurnsUntilExpiration(playerID);
			local sExpires:string = tAllianceIcons[info.AllianceType]..LL("LOC_DIPLOACTION_EXPIRES_IN_X_TURNS", iTurns);
			sExpires = string.gsub(sExpires, "%(", "");
			sExpires = string.gsub(sExpires, "%)", "");
			if iTurns < 4 then sExpires = ColorRED(sExpires); end
			table.insert(tTT, sExpires);
		end
	end
	
	-- Grievances  ICON_GRIEVANCE, ICON_STAT_GRIEVANCE, ICON_GRIEVANCE_TT
	if bIsGatheringStorm and playerID ~= localPlayerID then
		local iGrievances:number = localPlayerDiplomacy:GetGrievancesAgainst(playerID);
		local iGrievancePerTurn:number = Game.GetGameDiplomacy():GetGrievanceChangePerTurn(playerID, localPlayerID);
		local sGrievances:string = "[ICON_STAT_GRIEVANCE] "..LL("LOC_DIPLOMACY_GRIEVANCES_NONE_SIMPLE");
		if iGrievances > 0 then
			sGrievances = ColorGREEN(LL("LOC_DIPLOMACY_GRIEVANCES_WITH_THEM_SIMPLE", iGrievances));
			if iGrievancePerTurn > 0 then sGrievances = sGrievances..ColorGREEN("  ( +"..tostring(iGrievancePerTurn).." )"); end
			if iGrievancePerTurn < 0 then sGrievances = sGrievances..ColorRED(  "  ( " ..tostring(iGrievancePerTurn).." )"); end
		end
		if iGrievances < 0 then
			sGrievances = ColorRED(LL("LOC_DIPLOMACY_GRIEVANCES_WITH_US_SIMPLE", -iGrievances));
			if iGrievancePerTurn > 0 then sGrievances = sGrievances..ColorRED(  "  ( +"..tostring(iGrievancePerTurn).." )"); end
			if iGrievancePerTurn < 0 then sGrievances = sGrievances..ColorGREEN("  ( " ..tostring(iGrievancePerTurn).." )"); end
		end
		table.insert(tTT, sGrievances);
	end
	
	-- Access level  ICON_VisLimited, VisOpen, VisSecret, VisTopSecret
	local iAccessLevel = localPlayerDiplomacy:GetVisibilityOn(playerID);
	table.insert(tTT, string.format("%s %s [COLOR_Grey](%d)[ENDCOLOR]", LL("LOC_DIPLOMACY_INTEL_ACCESS_LEVEL"), LL(GameInfo.Visibilities[iAccessLevel].Name), iAccessLevel));
	
	-- Agendas
	table.insert(tTT, "----------------------------------------"); -- 40 chars
	table.insert(tTT, LL("LOC_DIPLOMACY_INTEL_ADGENDAS"));
	local tAgendaTypes:table = pPlayer:GetAgendaTypes();
	for i, agendaType in ipairs(tAgendaTypes) do
		local bHidden:boolean = true;
		if iAccessLevel >= iAccessAgendas then bHidden = false; end
		if i == 1 then bHidden = false; end
		if bHidden then table.insert(tTT, "- "..LL("LOC_DIPLOMACY_HIDDEN_AGENDAS", 1, false)..ENDCOLOR);
		else            table.insert(tTT, "- "..LL( GameInfo.Agendas[agendaType].Name )); end
	end
	
	-- Diplo modifiers, from DiplomacyActionView.lua
	if bOptionRelationship and toolTips then
		table.insert(tTT, "----------------------------------------"); -- 40 chars
		table.insert(tTT, LL("LOC_DIPLOMACY_INTEL_OUR_RELATIONSHIP"));
		table.sort(toolTips, function(a,b) return a.Score > b.Score; end);
		for _,tip in ipairs(toolTips) do
			if score ~= 0 then
				--local scoreText = Locale.Lookup("{1_Score : number +#,###.##;-#,###.##}", score);
				local scoreText:string = string.format("%+d", tip.Score);
				--local scoreText:string = tostring(tip.Score);
				if tip.Score > 0 then scoreText = ColorGREEN(scoreText); else scoreText = ColorRED(scoreText); end
				if tip.Text == LL("LOC_TOOLTIP_DIPLOMACY_UNKNOWN_REASON") then scoreText = scoreText.."  [COLOR_Grey]"..tip.Text.."[ENDCOLOR]";
				else                                                           scoreText = scoreText.."  "..tip.Text; end
				table.insert(tTT, scoreText);
			end -- if
		end -- for
	end -- if

	return table.concat(tTT, "[NEWLINE]");
end

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

	local localPlayerID:number = Game.GetLocalPlayer();
	if localPlayerID == -1 then return ""; end

	local tTT:table = {};
	local result:string = "";
	local pPlayer:table = Players[playerID];
	local pPlayerConfig:table = PlayerConfigurations[playerID];

	if pPlayerConfig and pPlayerConfig:GetLeaderTypeName() then
		local isHuman:boolean = pPlayerConfig:IsHuman();
		--local localPlayerID:number = Game.GetLocalPlayer();
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
	local iGoldPerTurn:number = playerTreasury:GetGoldYield() - playerTreasury:GetTotalMaintenance();

	-- Separator
	table.insert(tTT, "--------------------------------------------------"); -- 50 chars

	-- Statistics
	table.insert(tTT, "[ICON_Capital] " ..LL("LOC_WORLD_RANKINGS_OVERVIEW_DOMINATION_SCORE", tostring(pPlayer:GetScore())));
	table.insert(tTT, "[ICON_Strength] "..LL("LOC_WORLD_RANKINGS_OVERVIEW_DOMINATION_MILITARY_STRENGTH", "[COLOR_Military]"..tostring(pPlayer:GetStats():GetMilitaryStrengthWithoutTreasury()).."[ENDCOLOR]"));
	table.insert(tTT, string.format("[ICON_Gold] %s: [COLOR_GoldDark]%d (%+.1f)[ENDCOLOR]", LL("LOC_YIELD_GOLD_NAME"), iGoldBalance, iGoldPerTurn));
	table.insert(tTT, "[ICON_Science] "..LL("LOC_WORLD_RANKINGS_OVERVIEW_SCIENCE_NUM_TECHS", "[COLOR_Science]" ..tostring(pPlayer:GetStats():GetNumTechsResearched()).. "[ENDCOLOR]"));
	table.insert(tTT, LL("LOC_WORLD_RANKINGS_OVERVIEW_SCIENCE_SCIENCE_RATE", "[COLOR_Science]"..tostring(Round(pPlayer:GetTechs():GetScienceYield(),1)).."[ENDCOLOR]"));
	table.insert(tTT, LL("LOC_WORLD_RANKINGS_OVERVIEW_CULTURE_TOURISM_RATE", "[COLOR_Tourism]"..tostring(Round(pPlayer:GetStats():GetTourism(),1)).."[ENDCOLOR]"));
	table.insert(tTT, LL("LOC_WORLD_RANKINGS_OVERVIEW_CULTURE_CULTURE_RATE", "[COLOR_Culture]"..tostring(Round(pPlayer:GetCulture():GetCultureYield(),1)).."[ENDCOLOR]"));
	table.insert(tTT, LL("LOC_WORLD_RANKINGS_OVERVIEW_RELIGION_FAITH_RATE", "[COLOR_FaithDark]"..tostring(Round(pPlayer:GetReligion():GetFaithYield(),1)).."[ENDCOLOR]"));
	table.insert(tTT, "[ICON_Faith] "..LL("LOC_WORLD_RANKINGS_OVERVIEW_RELIGION_CITIES_FOLLOWING_RELIGION", "[COLOR_FaithDark]"..tostring(pPlayer:GetStats():GetNumCitiesFollowingReligion()).."[ENDCOLOR]"));
	if bIsGatheringStorm then
		table.insert(tTT, " [ICON_Favor]  "..LL("LOC_DIPLOMATIC_FAVOR_NAME")..": [COLOR_GoldDark]"..tostring(pPlayer:GetFavor()).."[ENDCOLOR]"); -- ICON_Favor_Large is too big
	end
	
	if localPlayerID == playerID then return table.concat(tTT, "[NEWLINE]"), false, false; end -- don't show deals for a local player

	-- Possible resource deals
	local function CheckResourceDeals(fromPlayer:number, toPlayer:number, sLine:string)
		-- For other players, use deal manager to see what the local player can trade for.
		local pForDeal			:table = DealManager.GetWorkingDeal(DealDirection.OUTGOING, fromPlayer, toPlayer); -- order of players is not important here
		local possibleResources	:table = DealManager.GetPossibleDealItems(fromPlayer, toPlayer, DealItemTypes.RESOURCES, pForDeal); -- from, to, type, forDeal
		local function SortDealItems(a,b)
			local classA:string = GameInfo.Resources[a.ForType].ResourceClassType;
			local classB:string = GameInfo.Resources[b.ForType].ResourceClassType;
			if classA == "RESOURCECLASS_LUXURY"    and classB == "RESOURCECLASS_STRATEGIC" then return false; end
			if classA == "RESOURCECLASS_STRATEGIC" and classB == "RESOURCECLASS_LUXURY"    then return true;  end
			return GameInfo.Resources[a.ForType].ResourceType < GameInfo.Resources[b.ForType].ResourceType;
		end
		table.sort(possibleResources, SortDealItems);
		--[[ values returned by GetPossibleDealItems
		 InGame: 1	ForTypeName	LOC_RESOURCE_FURS_NAME
		 InGame: 1	Type	-1069574269
		 InGame: 1	ForType	16
		 InGame: 1	SubType	0
		 InGame: 1	ValidationResult	1
		 InGame: 1	IsValid	true
		 InGame: 1	MaxAmount	2
		 InGame: 1	Duration	30
		--]]
		local toResources = Players[toPlayer]:GetResources();
		local tDealItems:table = {};
		local bDealFlag:boolean = false;
		for i, entry in ipairs(possibleResources) do
			local infoRes:table = GameInfo.Resources[entry.ForType];
			if infoRes ~= nil and entry.MaxAmount > 0 then
				local sColor:string = COLOR_GREEN; -- default
				if infoRes.ResourceClassType == "RESOURCECLASS_STRATEGIC" then sColor = COLOR_RED; end
				--local sResDeal:string = string.format("%d [ICON_%s] %s", entry.MaxAmount, infoRes.ResourceType, LL(infoRes.Name));
				if bIsGatheringStorm and infoRes.ResourceClassType == "RESOURCECLASS_STRATEGIC" then
					-- new logic for strategic resources in GS - calculate how many we can sell
					local iNumCanBuy:number = toResources:GetResourceStockpileCap(entry.ForType) - toResources:GetResourceAmount(entry.ForType);
					if iNumCanBuy > 0 then
						table.insert(tDealItems, string.format(sColor.."%d[ICON_%s][ENDCOLOR]", math.min(entry.MaxAmount, iNumCanBuy), infoRes.ResourceType)); -- no limit here, can sell all as they are accumulated per turn
					end
				else
					-- show only items that toPlayer doesn't have and fromPlayer has surplus (>1)
					if not toResources:HasResource(infoRes.Index) and entry.MaxAmount > 1 then
						table.insert(tDealItems, string.format(sColor.."%d[ICON_%s][ENDCOLOR]", entry.MaxAmount-1, infoRes.ResourceType)); --LL(infoRes.Name)
						bDealFlag = true;
					end
				end
			end
		end
		if #tDealItems > 0 then table.insert(tTT, LL(sLine)..": "..table.concat(tDealItems, " ")); return bDealFlag;
		else                    table.insert(tTT, LL(sLine)..": -");                               return bDealFlag; end
	end -- function
	
	-- Separator
	table.insert(tTT, "--------------------------------------------------"); -- 50 chars
	local bYourItems:boolean, bTheirItems:boolean = false, false;
	if pPlayer:GetDiplomacy():IsAtWarWith(localPlayerID) then
		-- no deals when at war
		table.insert(tTT, LL("LOC_DIPLOMACY_DEAL_YOUR_ITEMS") ..": "..ColorRED(LL("LOC_DIPLO_STATE_WAR_NAME")));
		table.insert(tTT, LL("LOC_DIPLOMACY_DEAL_THEIR_ITEMS")..": "..ColorRED(LL("LOC_DIPLO_STATE_WAR_NAME")));
	else
		bYourItems  = CheckResourceDeals(localPlayerID, playerID, "LOC_DIPLOMACY_DEAL_YOUR_ITEMS");
		bTheirItems = CheckResourceDeals(playerID, localPlayerID, "LOC_DIPLOMACY_DEAL_THEIR_ITEMS");
	end
	
	return table.concat(tTT, "[NEWLINE]"), bYourItems, bTheirItems;
end

print("OK loaded LeaderIcon.lua from Better Leader Icon");