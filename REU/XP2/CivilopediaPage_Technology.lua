print("Loading CivilopediaPage_Technology.lua (XP2) from Real Eurekas version  "..GlobalParameters.REU_VERSION_MAJOR.."."..GlobalParameters.REU_VERSION_MINOR);
-- ===========================================================================
--	Civilopedia - Technology Page Layout (XP2 override)
-- ===========================================================================
include( "RealEurekasCanShow"); -- Infixo

PageLayouts["Technology" ] = function(page)
	local sectionId = page.SectionId;
	local pageId = page.PageId;

	SetPageHeader(page.Title);
	SetPageSubHeader(page.Subtitle);

	-- Find live node that matches page id
	local tech		:table = nil;			-- From DB (static data, doesn't change)
	local pLiveTech	:table = nil;	-- From engine (live data changes per player)
	local techNodes	:table = Game.GetTechs():GetActiveTechNodes();
	for _,v in ipairs(techNodes) do
		local kFullNode:table = GameInfo.Technologies[v.TechType];
		if kFullNode.TechnologyType == pageId then
			tech = kFullNode;
			pLiveTech = v;
		end
	end
	
	if(tech == nil) then
		return;
	end
	local techType = tech.TechnologyType;	-- named id, same as pageId

	local required_techs = {};
	local leadsto = {};

	local ePlayer			:number = Game.GetLocalPlayer();
	local pPlayerTechManager:table = Players[ePlayer]:GetTechs();

	-- What was required for this tech.
	local show_prereqs = true;
	if(GameInfo.Technologies_XP2) then
		local tech_xp2 = GameInfo.Technologies_XP2[techType];
		if(tech_xp2 and tech_xp2.RandomPrereqs == true) then
			show_prereqs = false;
		end
	end

	if(show_prereqs) then
		for __,prereqTechIndex in ipairs(pLiveTech.PrereqTechTypes) do
			local pPreReqLive :table = techNodes[prereqTechIndex];
			local kPreReqData :table = GameInfo.Technologies[prereqTechIndex];
			if pPlayerTechManager:IsTechRevealed(pPreReqLive) then
				table.insert(required_techs, {"ICON_" .. kPreReqData.TechnologyType, kPreReqData.Name, kPreReqData.TechnologyType});
			end
		end
	end

	-- Build list of what more advanced technologies require this to be unlocked.
	for _,v in ipairs(techNodes) do
		for _,prereqTechIndex in ipairs(v.PrereqTechTypes) do
			if prereqTechIndex == pLiveTech.TechType then		
				if pPlayerTechManager:IsTechRevealed(v.TechType) then		
					local kFutureTech :table = GameInfo.Technologies[v.TechType];
					table.insert(leadsto, {"ICON_" .. kFutureTech.TechnologyType, kFutureTech.Name, kFutureTech.TechnologyType});
				end
				break
			end
		end
	end

	local boosts = {};
	for row in GameInfo.Boosts() do
		if(row.TechnologyType == techType) then
			table.insert(boosts, row);
		end
	end

		local stats = {};

	local envoys = 0;
	local spies = 0;

	for row in GameInfo.TechnologyModifiers() do
		if(row.TechnologyType == techType) then
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

	local unlockables = GetUnlockablesForTech(techType);

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
	AddPortrait("ICON_" .. techType);

	-- Quotes!
	for row in GameInfo.TechnologyQuotes() do
		if(row.TechnologyType == techType) then
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

		if(tech.EraType) then
			local era = GameInfo.Eras[tech.EraType];
			if(era) then
				s:AddLabel(era.Name);
				s:AddSeparator();
			end
		end

		if(#required_techs > 0) then
			s:AddHeader("LOC_UI_PEDIA_REQUIRED_TECHNOLOGIES");
			local icons = {};
			for _, icon in ipairs(required_techs) do
				s:AddIconLabel(icon, icon[2]);
			end
			s:AddSeparator();
		end
				
		local yield = GameInfo.Yields["YIELD_SCIENCE"];
		if(yield) then
			s:AddHeader("LOC_UI_PEDIA_RESEARCH_COST");
			local t = Locale.Lookup("LOC_UI_PEDIA_BASE_COST", tonumber(tech.Cost), yield.IconString, yield.Name);
			s:AddLabel(t);
			s:AddSeparator();
		end


		if(#boosts > 0) then
			s:AddHeader("LOC_UI_PEDIA_BOOSTS");

			for i,b in ipairs(boosts) do
				-- Infixo: start
				--s:AddLabel(b.TriggerDescription);
				if CanShowTrigger(tech.Index, false) then s:AddLabel(b.TriggerDescription);
				else s:AddLabel(GetRandomQuote(tech.Index)); end
				-- Infixo: end
			end
			s:AddSeparator();
		end
end);

	AddRightColumnStatBox("LOC_UI_PEDIA_PROGRESSION", function(s)
		s:AddSeparator();

		if(#leadsto > 0) then
			s:AddHeader("LOC_UI_PEDIA_LEADS_TO_TECHS");
			for _, tech in ipairs(leadsto) do
				s:AddIconLabel(tech, tech[2]);
			end
		end
		s:AddSeparator();
	end);

	-- Left Column
	AddChapter("LOC_UI_PEDIA_DESCRIPTION", tech.Description);

	local chapters = GetPageChapters(page.PageLayoutId);
	for i, chapter in ipairs(chapters) do
		local chapterId = chapter.ChapterId;
		local chapter_header = GetChapterHeader(sectionId, pageId, chapterId);
		local chapter_body = GetChapterBody(sectionId, pageId, chapterId);

		AddChapter(chapter_header, chapter_body);
	end
end

print("OK loaded CivilopediaPage_Technology.lua (XP2) from Real Eurekas");