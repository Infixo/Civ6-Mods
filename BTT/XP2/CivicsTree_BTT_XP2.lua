print("Loading CivicsTree_BTT_XP2.lua from Better Tech Tree version "..GlobalParameters.BTT_VERSION_MAJOR.."."..GlobalParameters.BTT_VERSION_MINOR);
-- ===========================================================================
-- Better Tech Tree
-- Author: Infixo
-- 2019-02-16: Created
-- ===========================================================================

include("CivicsTree_Expansion2");

BTT_XP2_LateInitialize = LateInitialize;

include("TechAndCivicSupport_BTT");

function LateInitialize()
	Initialize_BTT_CivicsTree(); -- we must call it BEFORE main LateInitialize because of AllocateUI being called there; all data must be ready before that
	BTT_XP2_LateInitialize();
end

print("OK Loaded CivicsTree_BTT_XP2.lua from Better Tech Tree");