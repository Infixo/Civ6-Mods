print("Loading DiplomacyActionView_Expansion2_BLI.lua from Better Leader Icon version "..GlobalParameters.BLI_VERSION_MAJOR.."."..GlobalParameters.BLI_VERSION_MINOR);
-- ===========================================================================
-- Better Leader Icon
-- Author: Infixo
-- 2019-03-23: Created
-- ===========================================================================

-- CQUI compatibility: Use CQUI as base if active
local bIsCQUI:boolean = Modding.IsModActive("1d44b5e7-753e-405b-af24-5ee634ec8a01");

if (bIsCQUI) then
    include("diplomacyactionview_CQUI_expansion2");
else
    include("DiplomacyActionView_Expansion2");
end


-- ===========================================================================
-- Need to override this function again because XP2 will load an original version back from XP1 file.

function PopulateLeader(leaderIcon : table, player : table, isUniqueLeader : boolean)
	BASE_PopulateLeader(leaderIcon, player, isUniqueLeader);
end

print("OK loaded DiplomacyActionView_Expansion2_BLI.lua from Better Leader Icon");