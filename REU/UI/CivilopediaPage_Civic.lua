print("Loading CivilopediaPage_Civic.lua from Real Eurekas version  "..GlobalParameters.REU_VERSION_MAJOR.."."..GlobalParameters.REU_VERSION_MINOR);
-- ===========================================================================
--	Civilopedia - Civic Page Layout
-- ===========================================================================
include("TechAndCivicUnlockables");
-- Infixo
include( "TechAndCivicSupport");

PageLayouts["Civic" ] = function(page)
	local sectionId = page.SectionId;
	local pageId = page.PageId;

	SetPageHeader(page.Title);
	SetPageSubHeader(page.Subtitle);

	local civic = GameInfo.Civics[pageId];
	if(civic == nil) then
		return;
	end
	local civicType = civic.CivicType;

	local required_civics = {};
	local leadsto_civics = {};

	for row in GameInfo.CivicPrereqs() do
		if(row.Civic == civicType) then
			local c = GameInfo.Civics[row.PrereqCivic];
			if(c) then
				table.insert(required_civics, {"ICON_" .. c.CivicType, c.Name, c.CivicType});
			end
		end

		if(row.PrereqCivic == civicType) then
			local c = GameInfo.Civics[row.Civic];
			if(c) then
				table.insert(leadsto_civics, {"ICON_" .. c.CivicType, c.Name, c.CivicType});
			end
		end
	end

	local boosts = {};
	for row in GameInfo.Boosts() do
		if(row.CivicType == civicType) then
			table.insert(boosts, row);
		end
	end

	local stats = {};

	local envoys = 0;
	local spies = 0;

	for row in GameInfo.CivicModifiers() do
		if(row.CivicType == civicType) then
			-- Extract information from Modifiers to append to stats.
			-- NOTE: This is a pretty naive implementation as it only looks at the effect and arguments and not the requirements.
			local modifier = GameInfo.Modifiers[row.ModifierId];
			if(modifier) then
				local dynamicModifier = GameInfo.DynamicModifiers[modifier.ModifierType];
				local effect = dynamicModifier and dynamicModifier.EffectType;

				if(effect == "EFFECT_GRANT_INFLUENCE_TOKEN") then
					-- TODO: Is there any way we can hash these arguments to speed up the lookup?
					for argument in GameInfo.ModifierArguments() do
						if(argument.ModifierId == row.ModifierId and argument.Name == "Amount") then
							envoys = envoys + tonumber(argument.Value);


						end 
					end
				elseif(effect == "EFFECT_GRANT_SPY") then
					-- TODO: Is there any way we can hash these arguments to speed up the lookup?
					for argument in GameInfo.ModifierArguments() do
						if(argument.ModifierId == row.ModifierId and argument.Name == "Amount") then
							spies = spies + tonumber(argument.Value);
						end 
					end
				end
			end
		end
	end

	if(spies > 0) then
		table.insert(stats, Locale.Lookup("LOC_TYPE_TRAIT_SPIES", spies)); 
	end

	if(envoys > 0) then
		table.insert(stats, Locale.Lookup("LOC_TYPE_TRAIT_ENVOYS", envoys)); 
	end

	for row in GameInfo.Building_YieldChanges() do
		if(row.BuildingType == buildingType) then
			local yield = GameInfo.Yields[row.YieldType];
			if(yield) then
				table.insert(stats, Locale.Lookup("LOC_TYPE_TRAIT_YIELD", row.YieldChange, yield.IconString, yield.Name)); 
			end
		end
	end

	local unlockables = GetUnlockablesForCivic(civicType);

	local unlocks = {};
	for i,v in ipairs(unlockables) do
		table.insert(unlocks, {"ICON_" .. v[1], Locale.Lookup(v[2]), v[3], v[1]});
	end

	local function SortUnlockables(a,b)
		local ta = GameInfo.Types[a[4]];
		local tb = GameInfo.Types[b[4]];

		if(ta.Kind == tb.Kind) then
			-- sort by Name
			return Locale.Compare(a[2], b[2]) == -1;
		else
			-- Ideally we should sort by Kind's NAME but this field does not exist yet.
			return ta.Kind < tb.Kind;
		end
	end

	table.sort(unlocks, SortUnlockables);
	
	-- Right Column
	AddPortrait("ICON_" .. civicType);

	-- Quotes!
	for row in GameInfo.CivicQuotes() do
		if(row.CivicType == civicType) then
			AddQuote(row.Quote, row.QuoteAudio);
		end
	end

	
	AddRightColumnStatBox("LOC_UI_PEDIA_TRAITS", function(s)
		s:AddSeparator();

		if(#stats > 0) then
			for _, v in ipairs(stats) do
				s:AddLabel(v);
			end
			s:AddSeparator();
		end
	end);

	AddRightColumnStatBox("LOC_UI_PEDIA_UNLOCKS", function(s)
		s:AddSeparator();
		local icons = {};
		for _, icon in ipairs(unlocks) do
			table.insert(icons, icon);	
				
			if(#icons == 4) then
				s:AddIconList(icons[1], icons[2], icons[3], icons[4]);
				icons = {};
			end
		end

		if(#icons > 0) then
			s:AddIconList(icons[1], icons[2], icons[3], icons[4]);
		end
		s:AddSeparator();
	end);

	AddRightColumnStatBox("LOC_UI_PEDIA_REQUIREMENTS", function(s)
		s:AddSeparator();

		if(civic.EraType) then
			local era = GameInfo.Eras[civic.EraType];
			if(era) then
				s:AddLabel(era.Name);
				s:AddSeparator();
			end
		end

		if(#required_civics > 0) then
			s:AddHeader("LOC_UI_PEDIA_REQUIRED_CIVICS");
			local icons = {};
			for _, icon in ipairs(required_civics) do
				s:AddIconLabel(icon, icon[2]);
			end
			s:AddSeparator();
		end
				
		local yield = GameInfo.Yields["YIELD_CULTURE"];
		if(yield) then
			s:AddHeader("LOC_UI_PEDIA_CULTURE_COST");
			local t = Locale.Lookup("LOC_UI_PEDIA_BASE_COST", tonumber(civic.Cost), yield.IconString, yield.Name);
			s:AddLabel(t);
			s:AddSeparator();
		end
		

		if(#boosts > 0) then
			s:AddHeader("LOC_UI_PEDIA_BOOSTS");

			for i,b in ipairs(boosts) do
				-- Infixo: start
				--s:AddLabel(b.TriggerDescription);
				if CanShowTrigger(civic.Index, true) then s:AddLabel(b.TriggerDescription);
				else s:AddLabel("LOC_REUR_QUOTE_"..math.random(22)); end
				-- Infixo: end
			end
			s:AddSeparator();
		end
	end);

	AddRightColumnStatBox("LOC_UI_PEDIA_PROGRESSION", function(s)
		s:AddSeparator();

		if(#leadsto_civics > 0) then
			s:AddHeader("LOC_UI_PEDIA_LEADS_TO_CIVICS");
			local icons = {};
			for _, icon in ipairs(leadsto_civics) do
				s:AddIconLabel(icon, icon[2]);
			end
		end

		s:AddSeparator();
	end);

	-- Left Column
	AddChapter("LOC_UI_PEDIA_DESCRIPTION", civic.Description);

	local chapters = GetPageChapters(page.PageLayoutId);
	for i, chapter in ipairs(chapters) do
		local chapterId = chapter.ChapterId;
		local chapter_header = GetChapterHeader(sectionId, pageId, chapterId);
		local chapter_body = GetChapterBody(sectionId, pageId, chapterId);

		AddChapter(chapter_header, chapter_body);
	end
end

print("OK loaded CivilopediaPage_Civic.lua from Real Eurekas");