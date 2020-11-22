print("Loading CivilopediaPage_GreatPerson.lua from RGP Mod, version 4.0");
-- ===========================================================================
--	Civilopedia - Great Person Page Layout
-- ===========================================================================
include("GameEffectsText")

PageLayouts["GreatPerson" ] = function(page)
	local sectionId = page.SectionId;
	local pageId = page.PageId;

	SetPageHeader(page.Title);
	SetPageSubHeader(page.Subtitle);

	local greatPerson = GameInfo.GreatPersonIndividuals[pageId];
	if(greatPerson == nil) then
		return;
	end
	local greatPersonType = greatPerson.GreatPersonIndividualType;

	-- Get some info!
	local gpClass = GameInfo.GreatPersonClasses[greatPerson.GreatPersonClassType];
	local gpUnit;

	if(gpClass and gpClass.UnitType) then
		gpUnit = GameInfo.Units[gpClass.UnitType];
	end

	local active_ability = {};
	for row in GameInfo.GreatPersonIndividualActionModifiers() do
		if(row.GreatPersonIndividualType == greatPersonType) then
			local text = GetModifierText(row.ModifierId, "Summary");
			if(text) then
				table.insert(active_ability, text);
			end
		end
	end

	local passive_ability = {};
	for row in GameInfo.GreatPersonIndividualBirthModifiers() do
		if(row.GreatPersonIndividualType == greatPersonType) then
			local text = GetModifierText(row.ModifierId, "Summary");
			if(text) then
				table.insert(passive_ability, text);
			end
		end
	end

	local great_works = {};
	for row in GameInfo.GreatWorks() do
		if(row.GreatPersonIndividualType == greatPersonType) then
			table.insert(great_works, row);
		end
	end

	local resources = {};
	local has_modifier = {};
	for row in GameInfo.GreatPersonIndividualActionModifiers() do
		if(row.GreatPersonIndividualType == greatPersonType) then
			has_modifier[row.ModifierId] = true;
		end
	end

	for row in GameInfo.Modifiers() do
		if(has_modifier[row.ModifierId]) then
			local info = GameInfo.DynamicModifiers[row.ModifierType];
			if(info) then
				if(info.EffectType == "EFFECT_GRANT_FREE_RESOURCE_IN_CITY") then
					for args in GameInfo.ModifierArguments() do
						if(args.ModifierId == row.ModifierId) then
							if(args.Name == "ResourceType") then
								local resource = GameInfo.Resources[args.Value];
								if(resource) then
									table.insert(resources, {{"ICON_" .. resource.ResourceType, resource.Name, resource.ResourceType}, resource.Name});
								end
							end
						end
					end
				end
			end
		end
	end
	
		
	-- Right column data
	if(gpUnit) then
		-- Infixo start we'll use the code from GreatPeople window
		--AddPortrait("ICON_" .. gpUnit.UnitType);
		-- Grab icon of the great person themselves; first try a specific image, if it doesn't exist then use default
		local portrait:string = "ICON_" .. greatPersonType;
		local textureOffsetX, textureOffsetY, textureSheet = IconManager:FindIconAtlas(portrait, 160);
		--print("icon: portrait, OffX, OffY, Sheet", portrait, textureOffsetX, textureOffsetY, textureSheet);
		if textureSheet == nil then   -- Use a default if none found
			print("WARNING: Could not find icon atlas entry for the individual Great Person '"..portrait.."', using default instead.");
			portrait = "ICON_" .. gpUnit.UnitType;
		end
		--print("Showing portrait of ", portrait);
		AddPortrait(portrait);
		-- Infixo end
	end

	-- Now to the right!
	AddRightColumnStatBox("LOC_UI_PEDIA_TRAITS", function(s)
		s:AddSeparator();
		
		if(greatPerson.EraType) then
			local era = GameInfo.Eras[greatPerson.EraType];
			if(era) then
				if(gpClass and gpClass.AvailableInTimeline) then
					s:AddLabel(era.Name);
				end
			end
		end

		if(gpClass) then
			s:AddLabel(gpClass.Name);
		end
		

		s:AddSeparator();
	end);

	AddRightColumnStatBox("LOC_UI_PEDIA_USAGE", function(s)
		s:AddSeparator();
		
		if(#resources > 0) then
			s:AddHeader("LOC_UI_PEDIA_CREATES");
			for i,v in ipairs(resources) do
				s:AddIconLabel(v[1], v[2]);
			end
		end	

		s:AddSeparator();
	end);

	-- Left column data
	if(#great_works > 0) then
		AddHeader("LOC_UI_PEDIA_GREAT_WORKS");

		local text = {};
		for i,v in ipairs(great_works) do
			table.insert(text, "[ICON_Bullet] " .. Locale.Lookup(v.Name));
		end

		AddParagraph(table.concat(text, "[NEWLINE]"));

		if(#great_works > 0) then
			AddParagraph("LOC_GREATPERSON_ACTION_USAGE_CREATE_GREAT_WORK");		
		end
	end

	local has_special = (greatPerson.GreatPersonClassType == "GREAT_PERSON_CLASS_PROPHET");
	local has_active = (greatPerson.ActionCharges > 0) and (#active_ability > 0 or greatPerson.ActionEffectTextOverride);
	local has_passive = #passive_ability > 0 or greatPerson.BirthEffectTextOverride;

	if(has_active or has_passive or has_special) then
		AddHeader("LOC_UI_PEDIA_UNIQUE_ABILITY");
	end

	if(greatPerson.GreatPersonClassType == "GREAT_PERSON_CLASS_PROPHET") then
		AddParagraph("LOC_GREATPERSON_ACTION_USAGE_FOUND_RELIGION");
	end

	if(has_active) then
		local active_name = greatPerson.ActionNameTextOverride or "LOC_GREATPERSON_ACTION_NAME_DEFAULT";
		local name = Locale.Lookup("LOC_UI_PEDIA_GREATPERSON_ACTION", active_name, greatPerson.ActionCharges);
		local active_body = greatPerson.ActionEffectTextOverride or table.concat(active_ability, "[NEWLINE]");
		AddHeaderBody(name, active_body);
	end

	if(has_passive) then
		local passive_name = greatPerson.BirthNameTextOverride or "LOC_GREATPERSON_PASSIVE_NAME_DEFAULT";
		local passive_body = greatPerson.BirthEffectTextOverride or table.concat(passive_ability, "[NEWLINE]");
		AddHeaderBody(passive_name, passive_body);
	end

	local chapters = GetPageChapters(page.PageLayoutId);
	if(chapters) then
		for i, chapter in ipairs(chapters) do
			local chapterId = chapter.ChapterId;
			local chapter_header = GetChapterHeader(sectionId, pageId, chapterId);
			local chapter_body = GetChapterBody(sectionId, pageId, chapterId);

			AddChapter(chapter_header, chapter_body);
		end
	end
end
print("OK loaded CivilopediaPage_GreatPerson.lua from RGP Mod");
