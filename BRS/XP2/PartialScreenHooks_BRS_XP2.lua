print("Loading PartialScreenHooks_BRS_XP2.lua from Better Report Screen version "..GlobalParameters.BRS_VERSION_MAJOR.."."..GlobalParameters.BRS_VERSION_MINOR);
-- ===========================================================================
-- Better Report Screen
-- Author: Infixo
-- 2019-02-17: Created
-- ===========================================================================


-- ===========================================================================
-- CACHE BASE FUNCTIONS
-- ===========================================================================
include("PartialScreenHooks_Expansion2");
--BRS_BASE_CloseAllPopups = CloseAllPopups;
--BRS_BASE_OnInputActionTriggered = OnInputActionTriggered;

include("PartialScreenHooks_BRS");

print("OK loaded PartialScreenHooks_BRS_XP2.lua from Better Report Screen");