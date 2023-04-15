print("BLI: Loading DiplomacyRibbon_BLI.lua from Better Leader Icon v"..GlobalParameters.BLI_VERSION_MAJOR.."."..GlobalParameters.BLI_VERSION_MINOR);

-- ===========================================================================
-- Better Leader Icon
-- Author: Infixo
-- 2019-03-21: Created
-- 2020-05-22: Updated for May 2020 Patch (New Frontier)
-- ===========================================================================

include("DiplomacyRibbon");

local BASE_ShowStats = ShowStats;
local BASE_UpdateStatValues = UpdateStatValues;


-- ===========================================================================
-- Need to override the mouse-over behavior
function ShowStats( uiLeader:table )
	local m_ribbonStats = Options.GetUserOption("Interface", "RibbonStats");
	if 	m_ribbonStats == RibbonHUDStats.FOCUS then return; end -- DO NOT show on mouse-over
	BASE_ShowStats(uiLeader);
end


-- ===========================================================================
function UpdateStatValues( playerID:number, uiLeader:table )
	--print("UpdateStatValues", playerID, uiLeader);
	BASE_UpdateStatValues(playerID, uiLeader);
	
	local pPlayer:table = Players[playerID];
    uiLeader.TotScore:SetText( pPlayer:GetScore() );
    uiLeader.Strength:SetText( pPlayer:GetStats():GetMilitaryStrengthWithoutTreasury() );
	
	-- The dynamic tooltip update is disabled due to a weird bug that causes the leftmost leader to have a wrong tolltip - no idea why
	--local m_uiLeadersByID = GetUILeadersByID();
	--m_uiLeadersByID[playerID]:UpdateAllToolTips(playerID); -- version that utilizes ribbon's native table with leader icons
	--uiLeader.LeaderIcon:UpdateAllToolTips(playerID); -- version with LeaderIcon
	
	-- Show or hide all stats based on options.
	local m_ribbonStats = Options.GetUserOption("Interface", "RibbonStats");
	if m_ribbonStats == RibbonHUDStats.SHOW then
		if uiLeader.StatStack:IsHidden() or m_isIniting then
			ShowStats( uiLeader );
		end
		uiLeader.StatStackBLI:SetHide(true); -- hide BLI stats
	elseif m_ribbonStats == RibbonHUDStats.FOCUS then
		HideStats( uiLeader ); -- hide main stack always
		uiLeader.StatStackBLI:SetHide(false); -- show BLI stats
	elseif m_ribbonStats == RibbonHUDStats.HIDE then
		if uiLeader.StatStack:IsVisible() or m_isIniting then			
			HideStats( uiLeader );
		end
		uiLeader.StatStackBLI:SetHide(true); -- hide BLI stats
	end
	
end


-- ===========================================================================
function RefreshScoreAndStrength(playerID:number)
	local m_uiLeadersByID = GetUILeadersByID();
	local uiLeader:table = m_uiLeadersByID[playerID];
	if uiLeader ~= nil then
		UpdateStatValues(playerID, uiLeader);
	end
end

function RefreshScoreAndStrengthForAll()
	local m_uiLeadersByID = GetUILeadersByID();
	for playerID,uiLeader in pairs(m_uiLeadersByID) do
		UpdateStatValues(playerID, uiLeader);
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

print("BLI: Loaded DiplomacyRibbon_BLI.lua OK");
