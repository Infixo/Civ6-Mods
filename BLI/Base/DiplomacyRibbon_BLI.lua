print("Loading DiplomacyRibbon_BLI.lua from Better Leader Icon version "..GlobalParameters.BLI_VERSION_MAJOR.."."..GlobalParameters.BLI_VERSION_MINOR);
-- ===========================================================================
-- Better Leader Icon
-- Author: Infixo
-- 2019-03-21: Created
-- ===========================================================================

include("DiplomacyRibbon");

local BASE_AddLeader = AddLeader;

-- ===========================================================================
--	Add a leader (from right to left)
-- ===========================================================================
function AddLeader(iconName : string, playerID : number, isUniqueLeader: boolean)
	local leaderIcon, instance = BASE_AddLeader(iconName, playerID, isUniqueLeader);

	local pPlayer:table = Players[playerID];
    --instance.TotScore:SetText("[ICON_Capital][COLOR_White]"..    tostring(pPlayer:GetScore())                                     .."[ENDCOLOR]");
    --instance.NumTechs:SetText("[ICON_Science][COLOR_Science]"..  tostring(pPlayer:GetStats():GetNumTechsResearched())             .."[ENDCOLOR]");
    --instance.Strength:SetText("[ICON_Strength][COLOR_Military]"..tostring(pPlayer:GetStats():GetMilitaryStrengthWithoutTreasury()).."[ENDCOLOR]");
    instance.TotScore:SetText( pPlayer:GetScore() );
    instance.Strength:SetText( pPlayer:GetStats():GetMilitaryStrengthWithoutTreasury() );
	
	return leaderIcon, instance;
end

print("OK loaded DiplomacyRibbon_BLI.lua from Better Leader Icon");