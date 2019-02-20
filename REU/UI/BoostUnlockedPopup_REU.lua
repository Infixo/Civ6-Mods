print("Loading BoostUnlockedPopup_REU.lua from Real Eurekas version "..GlobalParameters.REU_VERSION_MAJOR.."."..GlobalParameters.REU_VERSION_MINOR);
-- ===========================================================================
-- Real Eurekas
-- 2019-02-20: Created by Infixo
-- ===========================================================================

-- Base File
include("BoostUnlockedPopup");

-- Cache base functions
REU_BASE_ShowTechBoost = ShowTechBoost;
REU_BASE_ShowCivicBoost = ShowCivicBoost;


-- ===========================================================================
function ShowTechBoost(techIndex, iTechProgress, eSource)
	print("ShowTechBoost", techIndex, iTechProgress, eSource);
	REU_BASE_ShowTechBoost(techIndex, iTechProgress, eSource);
	
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
	REU_BASE_ShowCivicBoost(civicIndex, iCivicProgress, eSource);
	
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

print("OK loaded BoostUnlockedPopup_REU.lua from Real Eurekas");