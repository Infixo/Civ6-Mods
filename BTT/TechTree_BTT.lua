print("Loading TechTree_BTT.lua from Better Tech Tree version "..GlobalParameters.BTT_VERSION_MAJOR.."."..GlobalParameters.BTT_VERSION_MINOR);
-- ===========================================================================
-- Better Tech Tree
-- Author: Infixo
-- 2018-03-19: Created
-- ===========================================================================

include("TechTree");

BTT_BASE_LateInitialize = LateInitialize;

include("TechAndCivicSupport_BTT");

function LateInitialize()
	Initialize_BTT_TechTree(); -- we must call it BEFORE main LateInitialize because of AllocateUI being called there; all data must be ready before that
	BTT_BASE_LateInitialize();
end

print("OK Loaded TechTree_BTT.lua from Better Tech Tree");