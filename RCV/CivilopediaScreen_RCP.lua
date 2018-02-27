print("Loading CivilopediaScreen_RCP.lua from Real Civilopedia, version 0.1");
--------------------------------------------------------------
-- Real Civilopedia
-- Author: Infixo
-- 2018-02-18: Created, raw modifier analysis
-- 2018-02-22: Remember last visited page (based on CQUI code)
--------------------------------------------------------------

-- exposing functions and variables
if not ExposedMembers.RMA then ExposedMembers.RMA = {} end;
local RMA = ExposedMembers.RMA;
-- insert functions/objects into RMA in Initialize()

-- Base File
include("CivilopediaScreen");

-- Cache base functions
BASE_OnClose = OnClose;
BASE_OnOpenCivilopedia = OnOpenCivilopedia;
BASE_PageLayouts = {};
--print("Storing contents of PageLayouts:");
for k,v in pairs(PageLayouts) do
	BASE_PageLayouts[k] = v;
end


--------------------------------------------------------------
-- Time helpers
--------------------------------------------------------------
local fStartTime:number = 0.0
function TimerStart()
	fStartTime = Automation.GetTime()
end
function TimerTick(txt:string)
	print("Timer1 Tick", txt, string.format("%5.3f", Automation.GetTime()-fStartTime))
end

--------------------------------------------------------------
-- 2018-02-22: Remember last visited page (based on CQUI code)

local _LastSectionId = nil;
local _LastPageId = nil;

function OnOpenCivilopedia(sectionId_or_search, pageId)
	-- Opened without any query, restore the previously opened page and section instead
	if sectionId_or_search == nil and _LastPageId then
		print("Received a request to open the Civilopedia - last section and page");
		NavigateTo(_LastSectionId, _LastPageId);
		UIManager:QueuePopup(ContextPtr, PopupPriority.Current);	
		UI.PlaySound("Civilopedia_Open");
	else
		BASE_OnOpenCivilopedia(sectionId_or_search, pageId);
	end
	Controls.SearchEditBox:TakeFocus();
end

function OnClose()
	-- Store the currently opened section and page
	_LastSectionId = _CurrentSectionId;
	_LastPageId = _CurrentPageId;
	BASE_OnClose();
end

--------------------------------------------------------------

-- Tables with modifiers
local tModifiersTables = {
	["Belief"] = "BeliefModifiers", -- BeliefType
	["Building"] = "BuildingModifiers", -- BuildingType
	["Civic"] = "CivicModifiers", -- CivicType
	-- CommemorationModifiers -- no Pedia page for that!
	["District"] = "DistrictModifiers", -- DistrictType
	-- GameModifiers -- not shown in Pedia?
	["Government"] = "GovernmentModifiers", -- GovernmentType
	-- GovernorModifiers -- currently not used
	["GovernorPromotion"] = "GovernorPromotionModifiers", -- GovernorPromotionType
	-- ["GreatPerson"] = GreatPersonIndividualBirthModifiers -- GreatPersonIndividualType
	-- GreatPersonIndividualActionModifiers -- GreatPersonIndividualType + AttachmentTargetType
	["Improvement"] = "ImprovementModifiers", -- ImprovementType
	-- ["Leader"] = "LeaderTraits" => "TraitModifiers" -- TraitType
	["Policy"] = "PolicyModifiers", -- PolicyType
	["Project"] = "ProjectCompletionModifiers", -- ProjectType
	["Technology"] = "TechnologyModifiers", -- TechnologyType
	["Trait"] = "TraitModifiers", -- TraitType
	-- ["Unit"] = "UnitAbilityModifiers", -- UnitAbilityType  via TypeTags, i.e. Unit -> Class(Tag) -> TypeTags
	["UnitPromotion"] = "UnitPromotionModifiers", -- UnitPromotionType
}

-- Owners for various modifiers, i.e. tells which owner to use when collection is "COLLECTION_OWNER"
local tModifiersOwners = {
	["Belief"] = "Player",
	["Building"] = "City",
	["Civic"] = "Player",
	-- CommemorationModifiers -- no Pedia page for that!
	["District"] = "District", -- or City?
	-- GameModifiers -- not shown in Pedia?
	["Government"] = "Player",
	-- GovernorModifiers -- currently not used
	["GovernorPromotion"] = "City",
	-- ["GreatPerson"] = GreatPersonIndividualBirthModifiers -- GreatPersonIndividualType
	-- GreatPersonIndividualActionModifiers -- GreatPersonIndividualType + AttachmentTargetType
	["Improvement"] = "City",
	-- ["Leader"] = "LeaderTraits" => "TraitModifiers" -- TraitType
	["Policy"] = "Player",
	["Project"] = "City", -- depends on MaxPlayerInstances, if 1 then "Player", if NULL then "City"
	["Technology"] = "Player",
	["Trait"] = "Player",
	-- ["Unit"] = "UnitAbilityModifiers", -- UnitAbilityType  via TypeTags, i.e. Unit -> Class(Tag) -> TypeTags
	["UnitPromotion"] = "Unit",
}
	
--PageLayouts["Building"] = function(page)
	--print("INSIDE MY OWN FUNCTON, showing (page)...");
	--for k,v in pairs(page) do print(k,v); end
	--BASE_PageLayout_Building(page);
	--ShowInternalPageInfo(page);
--end

function ShowModifiers(page)
	local sModifiersTable:string = tModifiersTables[ page.PageLayoutId ];
	-- check if there are modifiers at all
	if sModifiersTable == nil then return; end
	local sObjectType:string = page.PageLayoutId.."Type"; -- simple version for starters
	local chapter_body = {};
	-- iterate and find them
	--print("...checking modifiers (obj,table,field)", page.PageId, sModifiersTable, sObjectType);
	TimerStart()
	for mod in GameInfo[sModifiersTable]() do
		if mod[sObjectType] == page.PageId then
			-- stupid Firaxis, some fields are named ModifierId and some ModifierID (sic!)
			local sModifierId:string = mod.ModifierId;
			if not sModifierId then sModifierId = mod.ModifierID; end -- fix for BeliefModifiers, GoodyHutSubTypes, ImprovementModifiers
			local sText:string, pYields:table, sAttachedId:string = RMA.DecodeModifier(sModifierId);
			table.insert(chapter_body, sText);
			if sAttachedId then
				sText, pYields, sAttachedId = RMA.DecodeModifier(sAttachedId);
				table.insert(chapter_body, sText);
			end
		--else
			--print("comp:", mod[sObjectType], page.PageId);
		end
	end
	if #chapter_body == 0 then
		table.insert(chapter_body, "No modifiers for this object.");
	end
	TimerTick("All modifiers for "..page.PageId)
	AddChapter("Modifiers", chapter_body);
end

function ShowInternalPageInfo(page)
	-- now do it in the window! -- Left Column
	--AddChapter("Test Single", "This is a single paragraph.");
	local chapter_body = {};
	for k,v in pairs(page) do
		if type(v) ~= "table" then
			table.insert(chapter_body, k..": "..v);
		else
			table.insert(chapter_body, k..": [table]");
		end
	end
	AddChapter("Internal page info", chapter_body);
	--end
end

-- add internal info to all pages at once
function ShowPage(page)
	--print("...showing page layout", page.PageLayoutId);
	BASE_PageLayouts[page.PageLayoutId](page); -- call original function
	ShowModifiers(page);
	ShowInternalPageInfo(page);
end
for k,v in pairs(PageLayouts) do
	PageLayouts[k] = ShowPage;
end

-- exceptions
PageLayouts["CityState"] = function(page)
	print("...showing page layout", page.PageLayoutId);
	BASE_PageLayouts[page.PageLayoutId](page); -- call original function
	--ShowModifiers(page);
	-- special CityState logic
	-- we need to show (a) leader traits (b) city-state type modifiers
	
    local civ = GameInfo.Civilizations[page.PageId];
    if not civ then return; end
    local civType = civ.CivilizationType;
	
    -- Leaders has an Inherit from column which makes life..tricky.
    -- We need to recursively discover all leader types and use all of them.
    local base_leaders = {};
    for row in GameInfo.CivilizationLeaders() do
        if(row.CivilizationType == civType) then
            local leader = GameInfo.Leaders[row.LeaderType];
            if(leader) then
                table.insert(base_leaders, leader);
            end
	    end
    end

    function AddInheritedLeaders(leaders, leader)
        local inherit = leader.InheritFrom;
        if(inherit ~= nil) then
            local parent = GameInfo.Leaders[inherit];
            if(parent) then
                table.insert(leaders, parent);
                AddInheritedLeaders(leaders, parent);
            end
        end
    end

	-- Recurse base leaders and populate list with inherited leaders.
	local leaders = {};
    for i,v in ipairs(base_leaders) do
		table.insert(leaders, v);
		AddInheritedLeaders(leaders, v);
    end

	-- Enumerate final list and index.
	local has_leader = {};
	for i,v in ipairs(leaders) do
		has_leader[v.LeaderType] = true;
	end
	
	-- Show leaders
	--for k,v in pairs(has_leader) do if v then print(civType, "has leader", k) end end
	local tOut = {};
	--table.insert(tOut, "Leaders:");
	for k,v in pairs(has_leader) do
		if v then table.insert(tOut, k); end
	end
	AddChapter("Leaders", tOut);
	
	-- TRAITS
    local traits = {};
    local has_trait = {};
	
	local function AddTrait(sTraitType:string)
		local trait = GameInfo.Traits[sTraitType];
		if not trait then print("ERROR: trait not defined", sTraitType); return; end
		table.insert(traits, trait);
		has_trait[sTraitType] = true;
	end

    -- Populate traits from civilizations.
    for row in GameInfo.CivilizationTraits() do
        if(row.CivilizationType == civType) then AddTrait(row.TraitType); end
    end

    -- Populate traits from leaders (including inherited)
    for row in GameInfo.LeaderTraits() do
        if(has_leader[row.LeaderType] == true and has_trait[row.TraitType] ~= true) then AddTrait(row.TraitType); end
    end
	
	-- Show Traits
	--for k,v in pairs(has_leader) do if v then print(civType, "has leader", k) end end
	tOut = {};
	--table.insert(tOut, "Leaders:");
	for i,trait in ipairs(traits) do
		local sTrait:string = trait.TraitType;
		if trait.InternalOnly then sTrait = sTrait.." (internal)"; end
		table.insert(tOut, sTrait);
	end
	AddChapter("Traits", tOut);

	-- Show Modifiers
	local chapter_body = {};
	-- iterate and find them
	--print("...checking modifiers (obj,table,field)", page.PageId, sModifiersTable, sObjectType);
	for mod in GameInfo.TraitModifiers() do
		if has_trait[mod.TraitType] then
			local sModifierId:string = mod.ModifierId;
			local sText:string, pYields:table, sAttachedId:string = RMA.DecodeModifier(sModifierId);
			table.insert(chapter_body, sText);
			if sAttachedId then
				sText, pYields, sAttachedId = RMA.DecodeModifier(sAttachedId);
				table.insert(chapter_body, sText);
			end
		--else
			--print("comp:", mod[sObjectType], page.PageId);
		end
	end
	if #chapter_body == 0 then
		table.insert(chapter_body, "No modifiers for this object.");
	end
	AddChapter("Modifiers", chapter_body);
	
	-- end
	ShowInternalPageInfo(page);
end


print("OK loaded CivilopediaScreen_RCP.lua from Real Civilopedia");