print("Loading DiplomacyRibbon_Expansion1.lua from Better Leader Icon version "..GlobalParameters.BLI_VERSION_MAJOR.."."..GlobalParameters.BLI_VERSION_MINOR);
-- ===========================================================================
-- Better Leader Icon
-- Author: Infixo
-- 2019-03-21: Created
-- ===========================================================================

include("DiplomacyRibbon_BLI");

XP1_AddLeader = AddLeader;

-- ===========================================================================
function AddLeader(iconName : string, playerID : number, isUniqueLeader: boolean)
	local leaderIcon, instance = XP1_AddLeader(iconName, playerID, isUniqueLeader);

	-- Update relationship pip tool with details about our alliance if we're in one
	--[[ Infixo: Don't do anything - the enhaced tooltip handles that
	local localPlayerDiplomacy:table = Players[Game.GetLocalPlayer()]:GetDiplomacy();
	if localPlayerDiplomacy then
		local allianceType = localPlayerDiplomacy:GetAllianceType(playerID);
		if allianceType ~= -1 then
			local allianceName = Locale.Lookup(GameInfo.Alliances[allianceType].Name);
			local allianceLevel = localPlayerDiplomacy:GetAllianceLevel(playerID);
			leaderIcon.Controls.Relationship:SetToolTipString(Locale.Lookup("LOC_DIPLOMACY_ALLIANCE_FLAG_TT", allianceName, allianceLevel));
		end
	end
	--]]
	return leaderIcon, instance;
end

print("Loading DiplomacyRibbon_Expansion1.lua from Better Leader Icon");