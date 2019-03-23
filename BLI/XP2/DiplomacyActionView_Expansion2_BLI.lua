print("Loading DiplomacyActionView_Expansion2_BLI.lua from Better Leader Icon version "..GlobalParameters.BLI_VERSION_MAJOR.."."..GlobalParameters.BLI_VERSION_MINOR);
-- ===========================================================================
-- Better Leader Icon
-- Author: Infixo
-- 2019-03-23: Created
-- ===========================================================================

include("DiplomacyActionView_Expansion2");


-- ===========================================================================
-- Need to override this function again because XP2 will load an original version back from XP1 file.

function PopulateLeader(leaderIcon : table, player : table, isUniqueLeader : boolean)
	BASE_PopulateLeader(leaderIcon, player, isUniqueLeader);
end

print("OK loaded DiplomacyActionView_Expansion2_BLI.lua from Better Leader Icon");