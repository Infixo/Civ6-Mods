print("Loading TechTree_REU.lua from Real Eurekas version "..GlobalParameters.REU_VERSION_MAJOR.."."..GlobalParameters.REU_VERSION_MINOR);
-- ===========================================================================
-- Real Eurekas
-- 2019-02-20: Created by Infixo
-- ===========================================================================

include("TechTree"); -- Base File
include("RealEurekasCanShow");

-- Cache base functions
REU_BASE_PopulateNode = PopulateNode;

function PopulateNode(uiNode, playerTechData)
	REU_BASE_PopulateNode(uiNode, playerTechData);

	local item		:table = g_kItemDefaults[uiNode.Type];						-- static item data
	local live		:table = playerTechData[DATA_FIELD_LIVEDATA][uiNode.Type];	-- live (changing) data

	if item.IsBoostable and live.Status ~= ITEM_STATUS.RESEARCHED then
		local boostText:string;
		if CanShowTrigger(item.Index, false) then boostText = TXT_TO_BOOST.." "..item.BoostText;
		else boostText = Locale.Lookup("LOC_REUR_QUOTE_"..math.random(22)); end
		TruncateStringWithTooltip(uiNode.BoostText, MAX_BEFORE_TRUNC_TO_BOOST, boostText);
	end
end

print("OK loaded TechTree_REU.lua from Real Eurekas");