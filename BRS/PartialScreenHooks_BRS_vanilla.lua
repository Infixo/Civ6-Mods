print("Loading LaunchBar_BRS_vanilla.lua from Better Report Screen "..GlobalParameters.BRS_VERSION_MAJOR.."."..GlobalParameters.BRS_VERSION_MINOR);
-- ===========================================================================
-- Better Report Screen
-- Author: Infixo
-- 2018-03-12: Created
-- ===========================================================================


-- ===========================================================================
-- CACHE BASE FUNCTIONS
-- ===========================================================================
include("LaunchBar");
BRS_BASE_CloseAllPopups = CloseAllPopups;
BRS_BASE_OnInputActionTriggered = OnInputActionTriggered;

include("LaunchBar_BRS");

print("OK loaded LaunchBar_BRS_vanilla.lua from Better Report Screen");