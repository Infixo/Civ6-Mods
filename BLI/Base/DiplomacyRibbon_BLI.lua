print("Loading DiplomacyRibbon_BLI.lua from Better Leader Icon version "..GlobalParameters.BLI_VERSION_MAJOR.."."..GlobalParameters.BLI_VERSION_MINOR);
-- ===========================================================================
-- Better Leader Icon
-- Author: Infixo
-- 2019-03-21: Created
-- ===========================================================================

include("DiplomacyRibbon");

local BASE_ResetLeaders = ResetLeaders;
local BASE_AddLeader = AddLeader;
local BASE_ShowStats = ShowStats;
local BASE_UpdateStatValues = UpdateStatValues;

local tInstances:table = {};


-- ===========================================================================
--	Cleanup leaders
-- ===========================================================================
function ResetLeaders()
	BASE_ResetLeaders();
	tInstances = {};
end

-- ===========================================================================
--	Add a leader (from right to left)
-- ===========================================================================
function AddLeader(iconName:string, playerID:number, kProps:table)
	local leaderIcon, uiLeader = BASE_AddLeader(iconName, playerID, kProps);
	tInstances[playerID] = uiLeader;
	--RefreshScoreAndStrength(playerID);
	return leaderIcon, uiLeader;
end


-- ===========================================================================
-- Need to override the mouse-over behavior
function ShowStats( uiLeader:table )
	local m_ribbonStats = Options.GetUserOption("Interface", "RibbonStats");
	if 	m_ribbonStats == RibbonHUDStats.FOCUS then return; end -- DO NOT show on mouse-over
	BASE_ShowStats(uiLeader);
end


-- ===========================================================================
function UpdateStatValues( playerID:number, uiLeader:table )
	local m_ribbonStats = Options.GetUserOption("Interface", "RibbonStats");
	--print("UpdateStatValues", playerID, uiLeader, m_ribbonStats);
	BASE_UpdateStatValues(playerID, uiLeader);
	
	local pPlayer:table = Players[playerID];
    uiLeader.TotScore:SetText( pPlayer:GetScore() );
    uiLeader.Strength:SetText( pPlayer:GetStats():GetMilitaryStrengthWithoutTreasury() );
	uiLeader[LeaderIcon.DATA_FIELD_CLASS]:UpdateAllToolTips(playerID);
	
	-- Show or hide all stats based on options.
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
	local uiLeader = tInstances[playerID];
	if uiLeader == nil then return; end
	UpdateStatValues(playerID, uiLeader);
end

function RefreshScoreAndStrengthForAll()
	for playerID,uiLeader in pairs(tInstances) do
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

print("OK loaded DiplomacyRibbon_BLI.lua from Better Leader Icon");