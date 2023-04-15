print("BLI: Loading DiplomacyActionView_Expansion1_BLI.lua from Better Leader Icon v"..GlobalParameters.BLI_VERSION_MAJOR.."."..GlobalParameters.BLI_VERSION_MINOR);

-- ===========================================================================
-- Better Leader Icon
-- Author: Infixo
-- 2019-03-23: Created
-- ===========================================================================

-- CQUI and CQUI-Lite compatibility: Use CQUI as base if active
local bIsCQUI:boolean = Modding.IsModActive("1d44b5e7-753e-405b-af24-5ee634ec8a01") or Modding.IsModActive("20c0bddb-67bf-6e15-8328-60c977b3031e");

if (bIsCQUI) then
    include("diplomacyactionview_CQUI_expansion1");
else
    include("DiplomacyActionView_Expansion1");
end


-- ===========================================================================
-- This is an override for XP1 function, not an extension. It calls BASE directly.

function PopulateLeader(leaderIcon : table, player : table, isUniqueLeader : boolean)
	BASE_PopulateLeader(leaderIcon, player, isUniqueLeader);
end

print("BLI: Loaded DiplomacyActionView_Expansion1_BLI.lua OK");
