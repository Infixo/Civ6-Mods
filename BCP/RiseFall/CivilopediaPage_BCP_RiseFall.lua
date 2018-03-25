print("Loading CivilopediaPage_BCP_RiseFall.lua from Better Civilopedia version "..GlobalParameters.BCP_VERSION_MAJOR.."."..GlobalParameters.BCP_VERSION_MINOR);
--------------------------------------------------------------
-- Better Civilopedia
-- Author: Infixo
-- 2018-03-11: Created, Dedications
-- 2018-03-25: Added Alliances and Moments overview
--------------------------------------------------------------


-- ===========================================================================
--	Civilopedia - Dedication Page Layout
-- ===========================================================================

PageLayouts["Commemoration"] = function(page)
	local sectionId = page.SectionId;
	local pageId = page.PageId;

	SetPageHeader(page.Title);
	SetPageSubHeader(page.Subtitle);

	local dedication = GameInfo.CommemorationTypes[pageId];
	if dedication == nil then return; end
	local dedicationType = dedication.CommemorationType;

	-- Right Column!
	AddRightColumnStatBox("LOC_UI_PEDIA_APPLIES_TO", function(s)
		s:AddSeparator();
		if dedication.MinimumGameEra then s:AddLabel(Locale.Lookup("LOC_UI_PEDIA_MIN_ERA", GameInfo.Eras[dedication.MinimumGameEra].Name)); end
		if dedication.MaximumGameEra then s:AddLabel(Locale.Lookup("LOC_UI_PEDIA_MAX_ERA", GameInfo.Eras[dedication.MaximumGameEra].Name)); end
		s:AddSeparator();
	end);
	
	-- Left Column!
	local chapter_body:table = {};
	table.insert(chapter_body, Locale.Lookup(dedication.GoldenAgeBonusDescription));
	table.insert(chapter_body, Locale.Lookup(dedication.NormalAgeBonusDescription));
	table.insert(chapter_body, Locale.Lookup(dedication.DarkAgeBonusDescription));
	AddChapter("LOC_HUD_REPORTS_BONUSES", chapter_body);

end


-- ===========================================================================
--	Civilopedia - Alliance Page Layout
-- ===========================================================================

PageLayouts["Alliance"] = function(page)
	local sectionId = page.SectionId;
	local pageId = page.PageId;

	SetPageHeader(page.Title);
	SetPageSubHeader(page.Subtitle);

	local alliance = GameInfo.Alliances[pageId];
	if alliance == nil then return; end
	local allianceType = alliance.AllianceType;

	-- Right Column! empty
	
	-- Left Column!
	
	-- get modifiers; they will by sorted by level req already
	local tAllianceEffects:table = {};
	for row in GameInfo.AllianceEffects() do
		if row.AllianceType == allianceType then tAllianceEffects[ row.LevelRequirement ] = row; end
	end
	
	-- build the chapter
	local chapter_body:table = {};
	for level,modifier in ipairs(tAllianceEffects) do
		table.insert(chapter_body, Locale.Lookup("LOC_DIPLOACTION_ALLIANCE_LEVEL", level).."  "..string.rep("[ICON_Alliance]", level));
		local sLocText:string = "(unknown)";
		local modifierText = DB.Query("SELECT Text from ModifierStrings where ModifierID = ? and Context = 'Summary'", modifier.ModifierID);
		if modifierText and modifierText[1] then sLocText = modifierText[1].Text; end
		table.insert(chapter_body, Locale.Lookup(sLocText));
	end
	AddChapter("LOC_HUD_REPORTS_BONUSES", chapter_body);

end


-- ===========================================================================
--	Civilopedia - OverviewMoments Page Layout
-- ===========================================================================

PageLayouts["OverviewMoments"] = function(page)
	local sectionId = page.SectionId;
	local pageId = page.PageId;

	SetPageHeader(page.Title);
	SetPageSubHeader(page.Subtitle);
	
	-- prepare data i.e. sort out by EraScore
	local tMomentsByEraScore:table = {};
	for row in GameInfo.Moments() do
		local iEraScore:number = ( row.EraScore and row.EraScore or 0 );
		if tMomentsByEraScore[iEraScore] == nil then tMomentsByEraScore[iEraScore] = {}; end
		table.insert(tMomentsByEraScore[iEraScore], row);
	end

	-- Right Column! empty
	
	-- Left Column! each EraScore is a separate chapter
	
	-- we'll start with the juicy ones
	local qMaxEraScore = DB.Query("SELECT MAX(EraScore) as MaxEraScore FROM Moments");
	if qMaxEraScore == nil or qMaxEraScore[1] == nil then print("WARNING: OverviewMoments cannot retrieve max EraScore"); return; end
	local iMaxEraScore:number = qMaxEraScore[1].MaxEraScore;
	
	-- buld the chapter
	local chapter_body:table = {};
	for i:number = iMaxEraScore, 0, -1 do
		if tMomentsByEraScore[i] then
			chapter_body = {};
			for _,moment in ipairs(tMomentsByEraScore[i]) do
				local sEraFrom:string, sEraTo:string = "", "";
				if moment.MinimumGameEra then sEraFrom = Locale.Lookup(GameInfo.Eras[moment.MinimumGameEra].Name); end
				if moment.MaximumGameEra then sEraTo   = Locale.Lookup(GameInfo.Eras[moment.MaximumGameEra].Name); end
				if moment.ObsoleteEra    then sEraTo   = Locale.Lookup(GameInfo.Eras[moment.ObsoleteEra].Name);    end
				local sText:string = "[ICON_Bullet]"..Locale.Lookup(moment.Name)..": "..Locale.Lookup(moment.Description);
				if sEraFrom ~= "" or sEraTo ~= "" then
					sText = sText..string.format(" ([COLOR_Red]%s-%s[ENDCOLOR])", sEraFrom, sEraTo);
				end
				table.insert(chapter_body, sText);
			end
			table.sort(chapter_body);
			AddChapter(Locale.Lookup("LOC_UI_PEDIA_ERA_SCORE", i), table.concat(chapter_body, "[NEWLINE]"));
		end
	end

end


print("OK loaded CivilopediaPage_BCP_RiseFall.lua from Better Civilopedia");