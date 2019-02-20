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

print("OK Loaded CivicsTree_BTT.lua from Better Tech Tree");