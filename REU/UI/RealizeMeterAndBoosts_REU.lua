print("Loading RealizeMeterAndBoosts_REU.lua from Real Eurekas version "..GlobalParameters.REU_VERSION_MAJOR.."."..GlobalParameters.REU_VERSION_MINOR);
-- ===========================================================================
-- Real Eurekas
-- 2019-02-20: Created by Infixo
-- ===========================================================================

include("RealEurekasCanShow");

-- Cache base functions
REU_BASE_RealizeMeterAndBoosts = RealizeMeterAndBoosts; -- TechAndCivicSupport must be included earlier

local MAX_BEFORE_TRUNC_BOOST_MSG:number = 220;			-- Size in which boost messages will be truncated and tooltipified


-- ===========================================================================
--	Show the meters and boost information for a given tech or civic.
-- ===========================================================================
function RealizeMeterAndBoosts( kControl:table, kData:table )
	--print("FUN RealizeMeterAndBoosts"); for k,v in pairs(kData) do print(" ...",k,v); end
	REU_BASE_RealizeMeterAndBoosts(kControl, kData);

	if kData.Boostable then

		local boostText:string;
		if CanShowTrigger(kData.ID, kData.CivicType ~= nil) then boostText = Locale.Lookup(kData.TriggerDesc);
		else boostText = Locale.Lookup("LOC_REUR_QUOTE_"..math.random(22)); end

		local boostString :string = "[NEWLINE]" .. boostText;
		if  kData.BoostTriggered then
			boostString = Locale.Lookup("LOC_TECH_HAS_BEEN_BOOSTED") .. boostString;	-- Same whether tech/civic
			kControl.IconHasBeenBoosted:SetToolTipString(boostString);
		else
			boostString = Locale.Lookup("LOC_TECH_CAN_BE_BOOSTED") .. boostString;		-- Same whether tech/civic
			kControl.IconCanBeBoosted:SetToolTipString( boostString );
		end
		
		TruncateStringWithTooltip(kControl.BoostLabel, MAX_BEFORE_TRUNC_BOOST_MSG, boostText );
	end	

end

print("OK loaded RealizeMeterAndBoosts_REU.lua from Real Eurekas");