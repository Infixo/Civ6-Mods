print("Loading CivilopediaPage_BCP_XP2.lua from Better Civilopedia version "..GlobalParameters.BCP_VERSION_MAJOR.."."..GlobalParameters.BCP_VERSION_MINOR);
--------------------------------------------------------------
-- Better Civilopedia
-- Author: Infixo
-- 2019-03-19: Created, Resolutions and Discussions
--------------------------------------------------------------

local COLOR_GREY  = "[COLOR:0,0,0,112]";
local LL = Locale.Lookup;

-- ===========================================================================
--	Civilopedia - Resolution Page Layout
-- ===========================================================================

PageLayouts["Resolution"] = function(page)
	print("...showing page", page.PageLayoutId, page.PageId);
	local pageId = page.PageId;

	SetPageHeader(page.Title);
	SetPageSubHeader(page.Subtitle);

	local resolution = GameInfo.Resolutions[pageId];
	if resolution == nil then return; end
	local resolutionType = resolution.ResolutionType;

	-- Right Column!

	-- Left Column!
	local chapter_body:table = {};
	if resolution.EarliestEra or resolution.LatestEra then
		local sText:string = Locale.Lookup("LOC_UI_PEDIA_APPLIES_TO")..": ";
		if resolution.EarliestEra then sText = sText..Locale.Lookup(GameInfo.Eras[resolution.EarliestEra].Name); end
		sText = sText.." [ICON_GoingTo] ";
		if resolution.LatestEra then sText = sText..Locale.Lookup(GameInfo.Eras[resolution.LatestEra].Name); end
		table.insert(chapter_body, sText);
	end
	-- WC uses literals "A:" and "B:", no translation here
	table.insert(chapter_body, "A:[NEWLINE]"..Locale.Lookup(resolution.Effect1Description));
	table.insert(chapter_body, "B:[NEWLINE]"..Locale.Lookup(resolution.Effect2Description));
	AddChapter("LOC_OPTIONS", chapter_body);
end

	-- try to retrieve possible targets
	--[[ those functions only work in GameScripts context
	if resolution.ValidationLua ~= nil and resolution.TargetKind ~= "PLAYER" then
		local tTargets:table = {}; tTargets.ResolutionOptions = nil;
		GameEvents[resolution.ValidationLua].Call("x", 0, tTargets);
		if tTargets.ResolutionOptions ~= nil then
			local tTmp:table = {};
			table.insert(tTmp, "[COLOR_Grey]("..resolution.ValidationLua..")[ENDCOLOR] "..Locale.Lookup("LOC_UI_PEDIA_APPLIES_TO")..":");
			for _,target in pairs(tTargets.ResolutionOptions) do
				table.insert(tTmp, GameInfo.Types[v].Type);
			end	-- for
			table.insert(chapter_body, table.concat(tTmp, "[NEWLINE]"));
		end -- if
	end -- if
	--]]

-- ===========================================================================
--	Civilopedia - Discussion Page Layout
-- ===========================================================================

PageLayouts["Discussion"] = function(page)
	print("...showing page", page.PageLayoutId, page.PageId);
	local pageId = page.PageId;

	SetPageHeader(page.Title);
	SetPageSubHeader(page.Subtitle);

	-- discussion
	local discussion = GameInfo.Discussions[pageId];
	if discussion == nil then return; end
	local discussionType = discussion.DiscussionType;

	-- Right Column! empty
	
	-- Left Column!
	local chapter_body:table = {};
	local tTmp:table = {};
	table.insert(chapter_body, Locale.Lookup(discussion.Description));

	-- EmergencyAlliances
	local emergencyType = discussion.EmergencyType;
	local emergency = GameInfo.EmergencyAlliances[emergencyType];
	if emergency == nil then return; end
	
	table.insert(chapter_body, "[ICON_GoingTo]"..LL(emergency.Name).." "..COLOR_GREY.."("..discussion.EmergencyType..")[ENDCOLOR]");
	
	-- helper
	local function AddField(tTable:table, tObject:table, sField:string, sSuffix:string)
		if tObject[sField] == nil then return; end
		if sSuffix == nil then sSuffix = ""; end
		table.insert(tTable, COLOR_GREY..sField..":[ENDCOLOR] "..sSuffix..LL(tObject[sField], "[ICON_Bolt]"));
	end
	
	-- EmergencyTexts
	local texts = GameInfo.EmergencyTexts[emergency.EmergencyText];
	if texts ~= nil then
		tTmp = {};
		AddField(tTmp, texts, "Flavor");
		AddField(tTmp, texts, "DescriptionShorter");
		AddField(tTmp, texts, "Description");
		AddField(tTmp, texts, "ExtraEffects");
		table.insert(chapter_body, table.concat(tTmp, "[NEWLINE]"));
	end
	
	-- EmergencyGoalTexts
	local goals = GameInfo.EmergencyGoalTexts[emergency.GoalText];
	if goals ~= nil then
		tTmp = {};
		table.insert(tTmp, LL("LOC_TUTORIAL_GOAL_GENERAL_1"));
		AddField(tTmp, goals, "GoalDescription");
		AddField(tTmp, goals, "ShortGoalDescription");
		AddField(tTmp, goals, "TentativeGoalDescription");
		AddField(tTmp, goals, "ListGoal");
		table.insert(tTmp, LL("LOC_BCP_TARGET_GOALS"));
		AddField(tTmp, goals, "ShortTargetGoalDescription");
		AddField(tTmp, goals, "TargetListGoal");
		table.insert(chapter_body, table.concat(tTmp, "[NEWLINE]"));
	end
	
	-- EmergencyBuffs
	tTmp = {};
	for row in GameInfo.EmergencyBuffs() do
		if row.EmergencyType == emergencyType then AddField(tTmp, row, "Description"); end
	end
	if #tTmp > 0 then table.insert(chapter_body, LL("LOC_HUD_REPORTS_BONUSES")..":[NEWLINE]"..table.concat(tTmp, "[NEWLINE]")); end
      
	-- EmergencyScoreSources
	tTmp = {};
	for row in GameInfo.EmergencyScoreSources() do
		if row.EmergencyType == emergencyType then AddField(tTmp, row, "Description"); end
	end
	if #tTmp > 0 then table.insert(chapter_body, LL("LOC_BCP_SCORE_SOURCES").."[NEWLINE]"..table.concat(tTmp, "[NEWLINE]")); end
	
	-- EmergencyRewards
	tTmp = {};
	for row in GameInfo.EmergencyRewards() do
		if row.EmergencyType == emergencyType then
			local tier:string = "";
			if     row.FirstPlace then tier = "[1] ";
			elseif row.TopTier    then tier = "[2] ";
			elseif row.BottomTier then tier = "[3] ";
			end
			AddField(tTmp, row, "Description", tier);
		end
	end
	if #tTmp > 0 then table.insert(chapter_body, LL("LOC_BCP_REWARDS").."[NEWLINE]"..table.concat(tTmp, "[NEWLINE]")); end
	
	AddChapter("LOC_UI_PEDIA_DESCRIPTION", chapter_body);
end

print("OK loaded CivilopediaPage_BCP_XP2.lua from Better Civilopedia");