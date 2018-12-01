print("Loading CivicsTree_BTT.lua from Better Tech Tree version "..GlobalParameters.BTT_VERSION_MAJOR.."."..GlobalParameters.BTT_VERSION_MINOR);
-- ===========================================================================
-- Better Tech Tree
-- Author: Infixo
-- 2018-03-19: Created
-- ===========================================================================

include("CivicsTree");

include("TechAndCivicSupport_BTT");

if HasCapability("CAPABILITY_CIVICS_CHOOSER") then
	Initialize_BTT_CivicsTree(); -- we must call it BEFORE main Initialize because of AllocateUI being called there; all data must be ready before that
	Initialize(); -- run it 2nd time but no problems with that, all data and UI is recreated from scratch
end

print("OK Loaded CivicsTree_BTT.lua from Better Tech Tree");