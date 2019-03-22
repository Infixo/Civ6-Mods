print("Loading CivicsTree_BTT.lua from Better Tech Tree version "..GlobalParameters.BTT_VERSION_MAJOR.."."..GlobalParameters.BTT_VERSION_MINOR);
-- ===========================================================================
-- Better Tech Tree
-- Author: Infixo
-- 2018-03-19: Created
-- ===========================================================================

include("CivicsTree");

BTT_BASE_LateInitialize = LateInitialize;

include("TechAndCivicSupport_BTT");

function LateInitialize()
	Initialize_BTT_CivicsTree(); -- we must call it BEFORE main LateInitialize because of AllocateUI being called there; all data must be ready before that
	BTT_BASE_LateInitialize();
end


-- ===========================================================================
-- Support for Real Eurekas mod

--local bIsREU:boolean = Modding.IsModActive("4a8aa030-69f0-4677-9a43-2772088ea041"); -- Real Eurekas

--include("RealEurekasCanShow"); -- file taken from Real Eurekas

-- Cache base functions
REU_BASE_PopulateNode = PopulateNode;

function PopulateNode(uiNode, playerTechData)
	REU_BASE_PopulateNode(uiNode, playerTechData);

	if not bIsREU then return; end

	local item		:table = g_kItemDefaults[uiNode.Type];						-- static item data
	local live		:table = playerTechData[DATA_FIELD_LIVEDATA][uiNode.Type];	-- live (changing) data

	if item.IsBoostable and live.Status ~= ITEM_STATUS.RESEARCHED then
		local boostText:string;
		if CanShowTrigger(item.Index, true) then boostText = TXT_TO_BOOST.." "..item.BoostText;
		else boostText = GetRandomQuote(item.Index); end
		TruncateStringWithTooltip(uiNode.BoostText, MAX_BEFORE_TRUNC_TO_BOOST, boostText);
	end
end

print("OK Loaded CivicsTree_BTT.lua from Better Tech Tree");