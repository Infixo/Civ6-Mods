--print("Loading RealEurekasCanShow.lua from Better Tech Tree version "..GlobalParameters.BTT_VERSION_MAJOR.."."..GlobalParameters.BTT_VERSION_MINOR);
-- ===========================================================================
-- Real Eurekas - function to check if a trigger description can be shown
-- 2019-02-20: Created by Infixo
-- 2019-03-16: Support for MP and new randomization method
-- ===========================================================================

local eTVP:number = GameConfiguration.GetValue("TriggerVisibilityParam");
if eTVP == nil then eTVP = 0; end

function CanShowTrigger(iTechID:number, bCivic:boolean)
	local pPlayerTechs = Players[Game.GetLocalPlayer()]:GetTechs();
	if bCivic then pPlayerTechs = Players[Game.GetLocalPlayer()]:GetCulture(); end
	-- alway visible, check if it is revealed
	if eTVP == 0 then
        if bCivic then return pPlayerTechs:IsCivicRevealed(iTechID);
        else           return pPlayerTechs:IsTechRevealed(iTechID); end
    end
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


local iRandomSeed:number = GlobalParameters.REU_RANDOM_SEED;

function GetRandomQuote(iIndex:number)
	return Locale.Lookup("LOC_REUR_QUOTE_"..tostring(1+(iRandomSeed+iIndex)%22));
end

--print("OK loaded RealEurekasCanShow.lua from Better Tech Tree version ");