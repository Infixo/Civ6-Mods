--print("Loading RealEurekasCanShow.lua from Real Eurekas version "..GlobalParameters.REU_VERSION_MAJOR.."."..GlobalParameters.REU_VERSION_MINOR);
-- ===========================================================================
-- Real Eurekas - function to check if a trigger description can be shown
-- 2019-02-20: Created by Infixo
-- ===========================================================================

local eTVP:number = GameConfiguration.GetValue("TriggerVisibilityParam");

function CanShowTrigger(iTechID:number, bCivic:boolean)
	if eTVP == nil then eTVP = 0; end
	-- alway visible, nothing more to check
	if eTVP == 0 then return true; end
	local pPlayerTechs = Players[Game.GetLocalPlayer()]:GetTechs();
	if bCivic then pPlayerTechs = Players[Game.GetLocalPlayer()]:GetCulture(); end
	-- already triggered, no point hiding it
	if pPlayerTechs:HasBoostBeenTriggered(iTechID) then return true; end
	-- only for techs and civics that can be researched (default)
	if eTVP == 1 then
		if bCivic then return pPlayerTechs:CanProgress(iTechID);
		else           return pPlayerTechs:CanResearch(iTechID); end
	end
	-- only after triggering
	if eTVP == 3 then  
		return pPlayerTechs:HasBoostBeenTriggered(iTechID);  -- same name for both Techs and Civics
	end
	-- eTVP == 2, only after some progress has been made (last option remaining)
	if bCivic then return pPlayerTechs:GetCulturalProgress(iTechID) > 0;
	else           return pPlayerTechs:GetResearchProgress(iTechID) > 0; end
end

--print("OK loaded RealEurekasCanShow.lua from Real Eurekas version ");