print("Loading TechTree_BTT_XP1.lua from Better Tech Tree version "..GlobalParameters.BTT_VERSION_MAJOR.."."..GlobalParameters.BTT_VERSION_MINOR);
-- ===========================================================================
-- Better Tech Tree
-- Author: Infixo
-- 2018-03-19: Created
-- ===========================================================================

include("TechTree_Expansion1");

BTT_XP1_LateInitialize = LateInitialize;

include("TechAndCivicSupport_BTT");

function LateInitialize()
	Initialize_BTT_TechTree(); -- we must call it BEFORE main LateInitialize because of AllocateUI being called there; all data must be ready before that
	BTT_XP1_LateInitialize();
end

print("OK Loaded TechTree_BTT_XP1.lua from Better Tech Tree");