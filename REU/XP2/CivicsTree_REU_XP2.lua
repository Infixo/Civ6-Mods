print("Loading CivicsTree_REU_XP2.lua from Real Eurekas version "..GlobalParameters.REU_VERSION_MAJOR.."."..GlobalParameters.REU_VERSION_MINOR);
-- ===========================================================================
-- Real Eurekas
-- 2019-02-20: Created by Infixo
-- ===========================================================================

include("CivicsTree_Expansion2"); -- Base File
include("RealEurekasCanShow");

-- Cache base functions
REU_XP2_PopulateNode = PopulateNode;

function PopulateNode(uiNode, playerTechData)
	REU_XP2_PopulateNode(uiNode, playerTechData);

	local item		:table = g_kItemDefaults[uiNode.Type];						-- static item data
	local live		:table = playerTechData[DATA_FIELD_LIVEDATA][uiNode.Type];	-- live (changing) data
	local status	:number = live.IsRevealed and live.Status or ITEM_STATUS.UNREVEALED;

	if item.IsBoostable and status ~= ITEM_STATUS.RESEARCHED and status ~= ITEM_STATUS.UNREVEALED then
		local boostText:string;
		if CanShowTrigger(item.Index, true) then boostText = TXT_TO_BOOST.." "..item.BoostText;
		else boostText = GetRandomQuote(item.Index); end
		TruncateStringWithTooltip(uiNode.BoostText, MAX_BEFORE_TRUNC_TO_BOOST, boostText);
	end
end

print("OK loaded CivicsTree_REU_XP2.lua from Real Eurekas");