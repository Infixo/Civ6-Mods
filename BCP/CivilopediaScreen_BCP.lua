print("Loading CivilopediaScreen_BCP.lua from Better Civilopedia version "..GlobalParameters.BCP_VERSION_MAJOR.."."..GlobalParameters.BCP_VERSION_MINOR);
--------------------------------------------------------------
-- Real Civilopedia
-- Author: Infixo
-- 2018-02-18: Created, raw modifier analysis
-- 2018-02-22: Remember last visited page (based on CQUI code)
-- 2018-03-07: Added Civs, Leaders, Units, Great People and reworked City-States
-- 2018-03-14: Added page history
-- 2018-03-23: Name changed into Better Civilopedia, table of units pages
--------------------------------------------------------------

-- exposed functions and variables
if not ExposedMembers.RMA then ExposedMembers.RMA = {} end;
local RMA = ExposedMembers.RMA;

-- configuration options
local bOptionModifiers:boolean = ( GlobalParameters.BCP_OPTION_MODIFIERS == 1 );
local bOptionInternal:boolean = ( GlobalParameters.BCP_OPTION_INTERNAL == 1 );


-- Base File
include("CivilopediaScreen");

-- Cache base functions
BCP_BASE_OnOpenCivilopedia = OnOpenCivilopedia;
BCP_BASE_NavigateTo = NavigateTo;
BCP_BASE_PageLayouts = {};
--print("Storing contents of PageLayouts:");
for k,v in pairs(PageLayouts) do
	BCP_BASE_PageLayouts[k] = v;
end


--------------------------------------------------------------
-- 2018-02-22: Remember last visited page (based on CQUI code)

local _LastSectionId = nil;
local _LastPageId = nil;

function OnOpenCivilopedia(sectionId_or_search, pageId)
	-- Opened without any query, restore the previously opened page and section instead
	if sectionId_or_search == nil and _LastPageId then
		print("Received a request to open the Civilopedia - last section and page", _LastSectionId, _LastPageId);
		NavigateTo(_LastSectionId, _LastPageId, true); -- should already be in history, so don't store again
		UIManager:QueuePopup(ContextPtr, PopupPriority.Current);	
		UI.PlaySound("Civilopedia_Open");
	else
		print("Received a request to open the Civilopedia");
		pageVisitHistory = {};
		pageHistoryIndex = 0;
		BCP_BASE_OnOpenCivilopedia(sectionId_or_search, pageId);
	end
	Controls.SearchEditBox:TakeFocus();
end


--------------------------------------------------------------
-- 2018-03-14: Page history and back/next buttons (based on Civilopedia Improvement mod)

-- stores the history of pages visited, with sectionID and pageID
local pageVisitHistory = {};
local pageHistoryIndex = 0;

function IsBackPageButtonDisabled()
	return #pageVisitHistory == 0 or pageHistoryIndex == 1;
end

function IsNextPageButtonDisabled()
	return #pageVisitHistory == 0 or pageHistoryIndex == #pageVisitHistory;
end

function RefreshHistoryButtons()
	Controls.BackPageButton:SetDisabled( IsBackPageButtonDisabled() );
	Controls.NextPageButton:SetDisabled( IsNextPageButtonDisabled() );
	Controls.BackPageButton:SetAlpha( IsBackPageButtonDisabled() and 0.4 or 1.0);
	Controls.NextPageButton:SetAlpha( IsNextPageButtonDisabled() and 0.4 or 1.0);
end

-------------------------------------------------------------------------------
-- This function will remember the history by default
-- Need 3rd param set to true to NOT rememeber
-- This way we don't need to modify all functions that call NavigateTo
function NavigateTo(SectionId, PageId, bNotInHistory)
	--print("Navigating to " .. SectionId .. ":" .. PageId);

	local prevSectionId = _CurrentSectionId;
	local prevPageId = _CurrentPageId;

	-- Store the currently opened section and page
	_LastSectionId = SectionId;
	_LastPageId = PageId;
	
	BCP_BASE_NavigateTo(SectionId, PageId);

	if SectionId == prevSectionId and PageId == prevPageId then return; end

	-- support for page history
	if bNotInHistory then return; end
	while pageHistoryIndex < #pageVisitHistory do
		table.remove(pageVisitHistory);
	end
	table.insert(pageVisitHistory, { sectionId = SectionId, pageId = PageId });
	pageHistoryIndex = #pageVisitHistory;
	RefreshHistoryButtons();
	--print("pageHistoryIndex:", pageHistoryIndex);
	--for i,v in pairs(pageVisitHistory) do
		--print(i .. ":" .. v.sectionId .. ":" .. v.pageId);
	--end
end

function OnBackPageButton()
	if IsBackPageButtonDisabled() then return; end -- assert
	--print("Back button clicked");
	pageHistoryIndex = pageHistoryIndex - 1;
	NavigateTo( pageVisitHistory[ pageHistoryIndex ].sectionId, pageVisitHistory[ pageHistoryIndex ].pageId, true ); -- don't store
	RefreshHistoryButtons();
end

function OnNextPageButton()
	if IsNextPageButtonDisabled() then return; end -- assert
	--print("Next button clicked");
	pageHistoryIndex = pageHistoryIndex + 1;
	NavigateTo( pageVisitHistory[ pageHistoryIndex ].sectionId, pageVisitHistory[ pageHistoryIndex ].pageId, true ); -- don't store
	RefreshHistoryButtons();
end

function Initialize_BCP()
	Controls.BackPageButton:RegisterCallback( Mouse.eLClick, OnBackPageButton );
	Controls.BackPageButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end );
	Controls.NextPageButton:RegisterCallback( Mouse.eLClick, OnNextPageButton );
	Controls.NextPageButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end );
	RefreshHistoryButtons();
end
Initialize_BCP();


--------------------------------------------------------------
-- GENERIC ADDITIONS

function ShowInternalPageInfo(page)
	if not bOptionInternal then return; end
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
	TableUnits = true,
	OverviewMoments = true,
}

-- add internal info to all pages at once
function ShowPage(page)
	--print("...showing page layout", page.PageLayoutId);
	BCP_BASE_PageLayouts[page.PageLayoutId](page); -- call original function
	
	if not tPagesToSkip[ page.PageLayoutId ] then
		local sImpact, tYields, sToolTip = RMA.CalculateModifierEffect(page.PageLayoutId, page.PageId, Game.GetLocalPlayer(), nil);
		local chapter_body = {};
		table.insert(chapter_body, sImpact);
		table.insert(chapter_body, sToolTip);
		if bOptionModifiers then AddChapter("Modifiers", chapter_body); end
	end
	
	ShowInternalPageInfo(page);
end

for k,v in pairs(PageLayouts) do
	PageLayouts[k] = ShowPage;
end


--------------------------------------------------------------
-- EXCEPTIONS

PageLayouts["GreatPerson"] = function(page)
	print("...showing page layout", page.PageLayoutId);
	BCP_BASE_PageLayouts[page.PageLayoutId](page); -- call original function
	-- we need to show (a) GreatPersonIndividualActionModifiers (b) GreatPersonIndividualBirthModifiers
	local sImpact, tYields, sToolTip = RMA.CalculateModifierEffect("GreatPersonIndividual", page.PageId, Game.GetLocalPlayer(), nil);
	local chapter_body = {};
	table.insert(chapter_body, sImpact);
	table.insert(chapter_body, sToolTip);
	if bOptionModifiers then AddChapter("Action Modifiers", chapter_body); end
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
	BCP_BASE_PageLayouts[page.PageLayoutId](page); -- call original function
	
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
		if bOptionModifiers then AddChapter(Locale.Lookup(GameInfo.UnitAbilities[ability].Name), chapter_body); end
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
	BCP_BASE_PageLayouts[page.PageLayoutId](page); -- call original function
	
	-- iterate through Traits that are not Uniques
	for row in GameInfo.CivilizationTraits() do
		if row.CivilizationType == page.PageId and not tAllUniques[row.TraitType] then
			local sImpact, tYields, sToolTip = RMA.CalculateModifierEffect("Trait", row.TraitType, Game.GetLocalPlayer(), nil);
			local chapter_body = {};
			table.insert(chapter_body, sImpact);
			table.insert(chapter_body, sToolTip);
			if bOptionModifiers then AddChapter(Locale.Lookup(GameInfo.Traits[row.TraitType].Name), chapter_body); end
		end
	end
	ShowInternalPageInfo(page);
end

PageLayouts["Leader"] = function(page)
	print("...showing page", page.PageLayoutId, page.PageId);
	BCP_BASE_PageLayouts[page.PageLayoutId](page); -- call original function
	
	-- iterate through Traits
	for row in GameInfo.LeaderTraits() do
		if row.LeaderType == page.PageId then
			local sImpact, tYields, sToolTip = RMA.CalculateModifierEffect("Trait", row.TraitType, Game.GetLocalPlayer(), nil);
			local chapter_body = {};
			table.insert(chapter_body, sImpact);
			table.insert(chapter_body, sToolTip);
			local sName:string = Locale.Lookup(GameInfo.Traits[row.TraitType].Name);
			if GameInfo.Traits[row.TraitType].InternalOnly then sName = "[ICON_Capital]"..row.TraitType; end
			if bOptionModifiers then AddChapter(sName, chapter_body); end
		end
	end
	ShowInternalPageInfo(page);
end


PageLayouts["CityState"] = function(page)
	print("...showing page layout", page.PageLayoutId);
	BCP_BASE_PageLayouts[page.PageLayoutId](page); -- call original function
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
			if bOptionModifiers then AddChapter(Locale.Lookup(GameInfo.Traits[row.TraitType].Name), chapter_body); end
		end
    end

	ShowInternalPageInfo(page);
end

print("OK loaded CivilopediaScreen_BCP.lua from Better Civilopedia");