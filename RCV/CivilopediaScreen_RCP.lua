print("Loading CivilopediaScreen_RCP.lua from Real Civilopedia, version 0.3");
--------------------------------------------------------------
-- Real Civilopedia
-- Author: Infixo
-- 2018-02-18: Created, raw modifier analysis
-- 2018-02-22: Remember last visited page (based on CQUI code)
-- 2018-03-07: Added Civs, Leaders, Units, Great People and reworked City-States
--------------------------------------------------------------

-- exposed functions and variables
if not ExposedMembers.RMA then ExposedMembers.RMA = {} end;
local RMA = ExposedMembers.RMA;

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
-- GENERIC ADDITION

function ShowInternalPageInfo(page)
	if true then return end
	local chapter_body = {};
	for k,v in pairs(page) do
		if type(v) ~= "table" then
			table.insert(chapter_body, k..": "..v);
		else
			table.insert(chapter_body, k..": [table]");
		end
	end
	AddChapter("Internal page info", chapter_body);
end

local tPagesToSkip:table = {
	FrontPage = true,
	Simple = true,
	Resource = true,
	Terrain = true,
	Feature = true,
	Religion = true,
	Route = true,
	HistoricMoment = true,
}

-- add internal info to all pages at once
function ShowPage(page)
	--print("...showing page layout", page.PageLayoutId);
	BASE_PageLayouts[page.PageLayoutId](page); -- call original function
	if tPagesToSkip[ page.PageLayoutId ] then return; end

	local sImpact, tYields, sToolTip = RMA.CalculateModifierEffect(page.PageLayoutId, page.PageId, Game.GetLocalPlayer(), nil);
	local chapter_body = {};
	table.insert(chapter_body, sImpact);
	table.insert(chapter_body, sToolTip);
	AddChapter("Modifiers", chapter_body);

	ShowInternalPageInfo(page);
end

for k,v in pairs(PageLayouts) do
	PageLayouts[k] = ShowPage;
end


--------------------------------------------------------------
-- EXCEPTIONS

PageLayouts["GreatPerson"] = function(page)
	print("...showing page layout", page.PageLayoutId);
	BASE_PageLayouts[page.PageLayoutId](page); -- call original function
	-- we need to show (a) GreatPersonIndividualActionModifiers (b) GreatPersonIndividualBirthModifiers
	local sImpact, tYields, sToolTip = RMA.CalculateModifierEffect("GreatPersonIndividual", page.PageId, Game.GetLocalPlayer(), nil);
	local chapter_body = {};
	table.insert(chapter_body, sImpact);
	table.insert(chapter_body, sToolTip);
	AddChapter("Action Modifiers", chapter_body);
	ShowInternalPageInfo(page);
end


-- exceptions Units
-- Units.UnitType=UNIT_INDIAN_VARU
-- TypeTags.Type=UNIT_INDIAN_VARU /.Tag=CLASS_VARU
-- TypeTags.Type=UNIT_INDIAN_VARU /.Tag=CLASS_HEAVY_CAVALRY
-- TypeTags.Type=ABILITY_VARU / .Class=CLASS_VARU
-- UnitAbilities.UnitAbilityType=ABILITY_VARU
PageLayouts["Unit"] = function(page)
	print("...showing page", page.PageLayoutId, page.PageId);
	BASE_PageLayouts[page.PageLayoutId](page); -- call original function
	
	-- start with page.PageId, it contains UnitType
	-- built ability list
	local tAbilities:table = {};
	for row in GameInfo.TypeTags() do
		if row.Type == page.PageId then
			-- add class
			for row2 in GameInfo.TypeTags() do
				if row2.Tag == row.Tag and string.sub(row2.Type, 1, 7) == "ABILITY" then tAbilities[ row2.Type ] = true; end
			end
		end
	end
	-- show modifiers
	--for k,v in pairs(tAbilities) do print(k,v) end
	for ability,_ in pairs(tAbilities) do
		local sImpact, tYields, sToolTip = RMA.CalculateModifierEffect("UnitAbility", ability, Game.GetLocalPlayer(), nil);
		local chapter_body = {};
		table.insert(chapter_body, sImpact);
		table.insert(chapter_body, sToolTip);
		AddChapter(Locale.Lookup(GameInfo.UnitAbilities[ability].Name), chapter_body);
	end
	
	ShowInternalPageInfo(page);
end


-- build a table of all uniques in the DB
local tAllUniques:table = {};
function AddUniques(sTable:string)
	for row in GameInfo[sTable]() do
		if row.TraitType then tAllUniques[ row.TraitType ] = row.Name; end
	end
end
AddUniques("Units");
AddUniques("Buildings");
AddUniques("Districts");
AddUniques("Improvements");

PageLayouts["Civilization"] = function(page)
	print("...showing page", page.PageLayoutId, page.PageId);
	BASE_PageLayouts[page.PageLayoutId](page); -- call original function
	
	-- iterate through Traits that are not Uniques
	for row in GameInfo.CivilizationTraits() do
		if row.CivilizationType == page.PageId and not tAllUniques[row.TraitType] then
			local sImpact, tYields, sToolTip = RMA.CalculateModifierEffect("Trait", row.TraitType, Game.GetLocalPlayer(), nil);
			local chapter_body = {};
			table.insert(chapter_body, sImpact);
			table.insert(chapter_body, sToolTip);
			AddChapter(Locale.Lookup(GameInfo.Traits[row.TraitType].Name), chapter_body);
		end
	end
	ShowInternalPageInfo(page);
end

PageLayouts["Leader"] = function(page)
	print("...showing page", page.PageLayoutId, page.PageId);
	BASE_PageLayouts[page.PageLayoutId](page); -- call original function
	
	-- iterate through Traits
	for row in GameInfo.LeaderTraits() do
		if row.LeaderType == page.PageId then
			local sImpact, tYields, sToolTip = RMA.CalculateModifierEffect("Trait", row.TraitType, Game.GetLocalPlayer(), nil);
			local chapter_body = {};
			table.insert(chapter_body, sImpact);
			table.insert(chapter_body, sToolTip);
			AddChapter(Locale.Lookup(GameInfo.Traits[row.TraitType].Name), chapter_body);
		end
	end
	ShowInternalPageInfo(page);
end


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
        if has_leader[row.LeaderType] and not has_trait[row.TraitType] and row.TraitType ~= "MINOR_CIV_DEFAULT_TRAIT" then
			-- just display the trait
			local sImpact, tYields, sToolTip = RMA.CalculateModifierEffect("Trait", row.TraitType, Game.GetLocalPlayer(), nil);
			local chapter_body = {};
			table.insert(chapter_body, sImpact);
			table.insert(chapter_body, sToolTip);
			AddChapter(Locale.Lookup(GameInfo.Traits[row.TraitType].Name), chapter_body);
		end
    end

	ShowInternalPageInfo(page);
end

print("OK loaded CivilopediaScreen_RCP.lua from Real Civilopedia");