print("Loading TechTree_BTT_vanilla.lua from Better Tech Tree version 1.0");
-- ===========================================================================
-- Better Tech Tree
-- Author: Infixo
-- 2018-03-19: Created
-- ===========================================================================

include("TechTree");

include("TechAndCivicSupport_BTT");

if HasCapability("CAPABILITY_TECH_TREE") then
	Initialize_BTT_TechTree(); -- we must call it BEFORE main Initialize because of AllocateUI being called there; all data must be ready before that
	Initialize(); -- run it 2nd time but no problems with that, all data and UI is recreated from scratch
end

print("OK Loaded TechTree_BTT_vanilla.lua from Better Tech Tree");