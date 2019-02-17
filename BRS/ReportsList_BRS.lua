print("Loading ReportsList_BRS.lua from Better Report Screen "..GlobalParameters.BRS_VERSION_MAJOR.."."..GlobalParameters.BRS_VERSION_MINOR);
-- ===========================================================================
-- Better Report Screen
-- Author: Infixo
-- 2019-02-17: Created
-- ===========================================================================

include("ReportsList");

local m_ReportButtonIM:table = InstanceManager:new("ReportButtonInstance", "Button");

function OnRaiseDealsReport()    LuaEvents.ReportsList_OpenDeals();    end
function OnRaiseUnitsReport()    LuaEvents.ReportsList_OpenUnits();    end
function OnRaisePoliciesReport() LuaEvents.ReportsList_OpenPolicies(); end
function OnRaiseMinorsReport()   LuaEvents.ReportsList_OpenMinors();   end

function LateInitialize()	
	m_ReportButtonIM:ResetInstances();
	AddReport("LOC_PARTIALSCREEN_REPORTS_YIELDS",	   OnRaiseYieldsReport,     Controls.EmpireReportsStack);
	AddReport("LOC_PARTIALSCREEN_REPORTS_RESOURCES",   OnRaiseResourcesReport,  Controls.EmpireReportsStack);
	AddReport("LOC_PARTIALSCREEN_REPORTS_CITY_STATUS", OnRaiseCityStatusReport, Controls.EmpireReportsStack);
	AddReport("LOC_HUD_REPORTS_TAB_DEALS",             OnRaiseDealsReport,      Controls.EmpireReportsStack);
	AddReport("LOC_HUD_REPORTS_TAB_UNITS",             OnRaiseUnitsReport,      Controls.EmpireReportsStack);
	AddReport("LOC_HUD_REPORTS_TAB_POLICIES",          OnRaisePoliciesReport,   Controls.EmpireReportsStack);
	AddReport("LOC_HUD_REPORTS_TAB_MINORS",            OnRaiseMinorsReport,     Controls.EmpireReportsStack);
	
	-- Only add global resources if this game mode allows trade.
	if (HasCapability("CAPABILITY_DIPLOMACY_DEALS")) then
		AddReport("LOC_PARTIALSCREEN_REPORTS_RESOURCES",	OnRaiseGlobalResourcesReport,	Controls.GlobalReportsStack );		
	end
	Controls.GlobalTitle:SetHide( not HasCapability("CAPABILITY_DIPLOMACY_DEALS"));
end

print("OK loaded ReportsList_BRS.lua from Better Report Screen");