print("Loading DiplomacyActionView_Expansion1_BLI.lua from Better Leader Icon version "..GlobalParameters.BLI_VERSION_MAJOR.."."..GlobalParameters.BLI_VERSION_MINOR);
-- ===========================================================================
-- Better Leader Icon
-- Author: Infixo
-- 2019-03-23: Created
-- ===========================================================================

include("DiplomacyActionView_Expansion1");


-- ===========================================================================
-- This is an override for XP1 function, not an extension. It calls BASE directly.

function PopulateLeader(leaderIcon : table, player : table, isUniqueLeader : boolean)
	BASE_PopulateLeader(leaderIcon, player, isUniqueLeader);
end

print("OK loaded DiplomacyActionView_Expansion1_BLI.lua from Better Leader Icon");