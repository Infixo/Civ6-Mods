print("Loading CivilopediaPage_Commemoration.lua from Real Civilopedia, version 0.4");
--------------------------------------------------------------
-- Real Civilopedia
-- Author: Infixo
-- 2018-03-11: Created
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

print("OK loaded CivilopediaPage_Commemoration.lua from Real Civilopedia, version 0.4");