print("Loading RFE_Main.lua from Real Fixes Elizabeth v1.0");
-- ===========================================================================
-- Real Fixes: Elizabeth
-- 2023-03-31: Created by Infixo
-- ===========================================================================

local m_eGreatPersonAdmiral:number = GameInfo.GreatPersonClasses.GREAT_PERSON_CLASS_ADMIRAL.Index;
local m_sAbilityModifier:string = "ELIZABETH_TRADE_ROUTES_MODIFIER";

function OnUnitGreatPersonCreated(ePlayerID:number, iUnitID:number, eGreatPersonClass:number, eGreatPersonIndividual:number)
	if eGreatPersonClass == m_eGreatPersonAdmiral and PlayerConfigurations[ePlayerID]:GetLeaderTypeName() == "LEADER_ELIZABETH" then
		Players[ePlayerID]:AttachModifierByID(m_sAbilityModifier);
		Events.UnitGreatPersonCreated.Remove( OnUnitGreatPersonCreated );
	end
end

function Initialize()
	Events.UnitGreatPersonCreated.Add( OnUnitGreatPersonCreated );
end	
Initialize();

print("OK loaded RFE_Main.lua from Real Fixes Elizabeth");