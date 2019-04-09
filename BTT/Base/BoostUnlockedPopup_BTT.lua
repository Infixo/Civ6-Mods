print("Loading BoostUnlockedPopup_BTT.lua from Better Tech Tree version "..GlobalParameters.BTT_VERSION_MAJOR.."."..GlobalParameters.BTT_VERSION_MINOR);
-- ===========================================================================
-- Better Tech Tree
-- Author: Infixo
-- 2019-03-30: Created as a copy from Real Eurekas
-- ===========================================================================

-- Base File
include("BoostUnlockedPopup");

-- Cache base functions
BTT_BASE_ShowTechBoost = ShowTechBoost;
BTT_BASE_ShowCivicBoost = ShowCivicBoost;


-- ===========================================================================
function ShowTechBoost(techIndex, iTechProgress, eSource)
	BTT_BASE_ShowTechBoost(techIndex, iTechProgress, eSource);
	
	-- Make sure we're the local player
	if Game.GetLocalPlayer() == -1 then return; end

	local currentTech = GameInfo.Technologies[techIndex];

	-- Update Cause Label
	Controls.BoostCauseString:SetToolTipString("");

	if eSource == BoostSources.BOOST_SOURCE_TRIGGER and currentTech ~= nil then
		for row in GameInfo.Boosts() do
			if row.TechnologyType == currentTech.TechnologyType then
				Controls.BoostCauseString:SetToolTipString( Locale.Lookup("LOC_TECH_KEY_COMPLETED")..": "..Locale.Lookup(row.TriggerDescription) );
				return;
			end
		end
	end
end

-- ===========================================================================
function ShowCivicBoost(civicIndex, iCivicProgress, eSource)
	BTT_BASE_ShowCivicBoost(civicIndex, iCivicProgress, eSource);
	
	-- Make sure we're the local player
	if Game.GetLocalPlayer() == -1 then return; end
	
	local currentCivic = GameInfo.Civics[civicIndex];

	-- Update Cause Label
	Controls.BoostCauseString:SetToolTipString("");
	if eSource == BoostSources.BOOST_SOURCE_TRIGGER and currentCivic ~= nil then
		for row in GameInfo.Boosts() do
			if row.CivicType == currentCivic.CivicType then
				Controls.BoostCauseString:SetToolTipString( Locale.Lookup("LOC_TECH_KEY_COMPLETED")..": "..Locale.Lookup(row.TriggerDescription) );
				return;
			end
		end
	end
end

print("OK loaded BoostUnlockedPopup_BTT.lua from Better Tech Tree");