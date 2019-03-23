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

local tInstances:table = {};

function AddLeader(iconName : string, playerID : number, isUniqueLeader: boolean)
	local leaderIcon, instance = BASE_AddLeader(iconName, playerID, isUniqueLeader);
	tInstances[playerID] = instance;
	RefreshScoreAndStrength(playerID);
	return leaderIcon, instance;
end

function RefreshScoreAndStrength(playerID:number)
	local instance = tInstances[playerID];
	if instance == nil then return; end
	local pPlayer:table = Players[playerID];
    instance.TotScore:SetText( pPlayer:GetScore() );
    instance.Strength:SetText( pPlayer:GetStats():GetMilitaryStrengthWithoutTreasury() );
	instance[LeaderIcon.DATA_FIELD_CLASS]:UpdateAllToolTips(playerID);
end

function RefreshScoreAndStrengthForAll()
	for playerID,instance in pairs(tInstances) do
		local pPlayer:table = Players[playerID];
		instance.TotScore:SetText( pPlayer:GetScore() );
		instance.Strength:SetText( pPlayer:GetStats():GetMilitaryStrengthWithoutTreasury() );
		instance[LeaderIcon.DATA_FIELD_CLASS]:UpdateAllToolTips(playerID);
	end
end

Events.PlayerTurnActivated.Add( RefreshScoreAndStrengthForAll );
Events.PlayerTurnDeactivated.Add( RefreshScoreAndStrengthForAll );
Events.CivicCompleted.Add( RefreshScoreAndStrength );
Events.ResearchCompleted.Add( RefreshScoreAndStrength );
Events.CityAddedToMap.Add( RefreshScoreAndStrength );
Events.CityRemovedFromMap.Add( RefreshScoreAndStrength );
Events.CityPopulationChanged.Add( RefreshScoreAndStrength );
Events.CityLiberated.Add( RefreshScoreAndStrengthForAll );
Events.UnitAddedToMap.Add( RefreshScoreAndStrength );
Events.UnitRemovedFromMap.Add( RefreshScoreAndStrength );

print("OK loaded DiplomacyRibbon_BLI.lua from Better Leader Icon");