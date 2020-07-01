print("Loading TechTree_BTT.lua from Better Tech Tree version "..GlobalParameters.BTT_VERSION_MAJOR.."."..GlobalParameters.BTT_VERSION_MINOR);
-- ===========================================================================
-- Better Tech Tree
-- Author: Infixo
-- 2018-03-19: Created
-- ===========================================================================


include("TechTree");
BTT_BASE_LateInitialize = LateInitialize;

include("TechAndCivicSupport_BTT");

local DATA_PREFIX:string = "BTT_MARKED_"; -- prefix used to save/load values from the savefile

local tTechsWithUniques:table = {};

function LateInitialize()
    Initialize_TechsWithUniques();
	Initialize_BTT_TechTree(); -- we must call it BEFORE main LateInitialize because of AllocateUI being called there; all data must be ready before that
	BTT_BASE_LateInitialize(); -- this calls PopulateNode() via View()
    Initialize_BTT_Extra();
end


-- ===========================================================================
-- Support for Real Eurekas mod

--local bIsREU:boolean = Modding.IsModActive("4a8aa030-69f0-4677-9a43-2772088ea041"); -- Real Eurekas

--include("RealEurekasCanShow"); -- file taken from Real Eurekas

-- Cache base functions
REU_BASE_PopulateNode = PopulateNode;

function PopulateNode(uiNode, playerTechData)
	REU_BASE_PopulateNode(uiNode, playerTechData);
    
    -- marking as important
    if uiNode.Name == nil then
        --print(uiNode.Type, tTechsWithUniques[uiNode.Type]);
        uiNode.Name = uiNode.NodeName:GetText();
        -- try to retrieve the flag from the save file
        local localPlayerID:number = Game.GetLocalPlayer();
        if localPlayerID ~= PlayerTypes.NONE and localPlayerID ~= PlayerTypes.OBSERVER then
            uiNode.IsMarked = PlayerConfigurations[localPlayerID]:GetValue(DATA_PREFIX..uiNode.Type);
        end
        -- init with uniques if still nil
        if uiNode.IsMarked == nil then uiNode.IsMarked = ( tTechsWithUniques[uiNode.Type] == true ); end
        --if uiNode.IsMarked then print(uiNode.Type, tTechsWithUniques[uiNode.Type], uiNode.IsMarked, uiNode.Name); end
    end
    -- show/hide
    uiNode.MarkLabel:SetHide(not uiNode.IsMarked);
    
	if not bIsREU then return; end

	local item		:table = g_kItemDefaults[uiNode.Type];						-- static item data
	local live		:table = playerTechData[DATA_FIELD_LIVEDATA][uiNode.Type];	-- live (changing) data

	if item.IsBoostable and live.Status ~= ITEM_STATUS.RESEARCHED then
		local boostText:string;
		if CanShowTrigger(item.Index, false) then boostText = TXT_TO_BOOST.." "..item.BoostText;
		else boostText = GetRandomQuote(item.Index); end
		TruncateStringWithTooltip(uiNode.BoostText, MAX_BEFORE_TRUNC_TO_BOOST, boostText);
	end
end



-- ===========================================================================
-- Marking techs as important for easier planning

function Initialize_TechsWithUniques()
    --print("FUN Initialize_TechsWithUniques");
    local localPlayerID:number = Game.GetLocalPlayer();
	if localPlayerID == PlayerTypes.NONE or localPlayer == PlayerTypes.OBSERVER then return; end
    
    -- Obtain "uniques" from Civilization and for the chosen leader
    local uniqueAbilities,    uniqueUnits,    uniqueBuildings    = GetLeaderUniqueTraits(       PlayerConfigurations[localPlayerID]:GetLeaderTypeName(),       true );
    local civUniqueAbilities, civUniqueUnits, civUniqueBuildings = GetCivilizationUniqueTraits( PlayerConfigurations[localPlayerID]:GetCivilizationTypeName(), true );

    -- Merge tables
    for i,v in ipairs(civUniqueAbilities) do table.insert(uniqueAbilities, v); end
    for i,v in ipairs(civUniqueUnits)     do table.insert(uniqueUnits, v);     end
    for i,v in ipairs(civUniqueBuildings) do table.insert(uniqueBuildings, v); end
    
    -- find and mark techs
    for _,item in ipairs(uniqueUnits) do
        local itemInfo:table = GameInfo.Units[item.Type];
        --if itemInfo.PrereqCivic ~= nil then sDescription = GetUnlockCivicDesc(itemInfo.PrereqCivic); end
        if itemInfo and itemInfo.PrereqTech ~= nil then tTechsWithUniques[ itemInfo.PrereqTech ] = true; end
    end
    for _,item in ipairs(uniqueBuildings) do
        local itemInfo:table = GameInfo.Buildings[item.Type];
        if itemInfo == nil then itemInfo = GameInfo.Districts[item.Type]; end
        if itemInfo == nil then itemInfo = GameInfo.Improvements[item.Type]; end
        --if itemInfo.PrereqCivic ~= nil then sDescription = GetUnlockCivicDesc(itemInfo.PrereqCivic); end
        if itemInfo and itemInfo.PrereqTech ~= nil then tTechsWithUniques[ itemInfo.PrereqTech ] = true; end
    end
    dshowtable(tTechsWithUniques);
end

function OnLeftClickNodeNameButton(node:table)
    --print("FUN OnLeftClickNodeNameButton", node.Type, node.Name, node.IsMarked);
    node.IsMarked = not node.IsMarked;
    node.MarkLabel:SetHide(not node.IsMarked);
    -- save the value
    local localPlayerID:number = Game.GetLocalPlayer();
    if localPlayerID ~= PlayerTypes.NONE and localPlayerID ~= PlayerTypes.OBSERVER then
        --print("saving to", DATA_PREFIX..node.Type);
        PlayerConfigurations[localPlayerID]:SetValue(DATA_PREFIX..node.Type, node.IsMarked);
    end
end

-- this is called AFTER AllocateUI(), so all nodes SHOULD be available via g_uiNodes
-- please note that PopulateNode is also called before, so some inits are moved there
function Initialize_BTT_Extra()
    --print("FUN Initialize_BTT_Extra");
    --dshowtable(g_uiNodes);
    -- hook left-clicks
    for _,node in pairs(g_uiNodes) do
		node.NodeNameButton:RegisterCallback( Mouse.eLClick, function() OnLeftClickNodeNameButton(node); end );
		node.NodeNameButton:SetSizeX( node.NodeName:GetSizeX() + 20 );
    end
end


print("OK Loaded TechTree_BTT.lua from Better Tech Tree");