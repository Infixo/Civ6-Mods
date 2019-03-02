print("Loading ReportsList_BRS.lua from Better Report Screen "..GlobalParameters.BRS_VERSION_MAJOR.."."..GlobalParameters.BRS_VERSION_MINOR);
-- ===========================================================================
-- Better Report Screen
-- Author: Infixo
-- 2019-02-17: Created
-- ===========================================================================

include("ReportsList");

local bIsGatheringStorm:boolean = Modding.IsModActive("4873eb62-8ccc-4574-b784-dda455e74e68"); -- Gathering Storm

local m_ReportButtonIM:table = InstanceManager:new("ReportButtonInstance", "Button");

function OnRaiseYieldsReport()     Close(); LuaEvents.ReportsList_OpenYields();     end
function OnRaiseResourcesReport()  Close(); LuaEvents.ReportsList_OpenResources();  end
function OnRaiseCityStatusReport() Close(); LuaEvents.ReportsList_OpenCityStatus(); end
function OnRaiseDealsReport()      Close(); LuaEvents.ReportsList_OpenDeals();      end
function OnRaiseUnitsReport()      Close(); LuaEvents.ReportsList_OpenUnits();      end
function OnRaisePoliciesReport()   Close(); LuaEvents.ReportsList_OpenPolicies();   end
function OnRaiseMinorsReport()     Close(); LuaEvents.ReportsList_OpenMinors();     end
function OnRaiseCities2Report()    Close(); LuaEvents.ReportsList_OpenCities2();     end

function LateInitialize()	
	m_ReportButtonIM:ResetInstances();
	AddReport("LOC_PARTIALSCREEN_REPORTS_YIELDS",	 OnRaiseYieldsReport,     Controls.EmpireReportsStack);
	AddReport("LOC_PARTIALSCREEN_REPORTS_RESOURCES", OnRaiseResourcesReport,  Controls.EmpireReportsStack);
	AddReport("LOC_HUD_REPORTS_TAB_CITIES", 		 OnRaiseCityStatusReport, Controls.EmpireReportsStack);
	AddReport("LOC_HUD_REPORTS_TAB_DEALS",           OnRaiseDealsReport,      Controls.EmpireReportsStack);
	AddReport("LOC_HUD_REPORTS_TAB_UNITS",           OnRaiseUnitsReport,      Controls.EmpireReportsStack);
	AddReport("LOC_HUD_REPORTS_TAB_POLICIES",        OnRaisePoliciesReport,   Controls.EmpireReportsStack);
	AddReport("LOC_HUD_REPORTS_TAB_MINORS",          OnRaiseMinorsReport,     Controls.EmpireReportsStack);
	if bIsGatheringStorm then AddReport("LOC_HUD_REPORTS_TAB_CITIES2", OnRaiseCities2Report, Controls.EmpireReportsStack); end
	
	-- Only add global resources if this game mode allows trade.
	if (HasCapability("CAPABILITY_DIPLOMACY_DEALS")) then
		AddReport("LOC_PARTIALSCREEN_REPORTS_RESOURCES",	OnRaiseGlobalResourcesReport,	Controls.GlobalReportsStack );		
	end
	Controls.GlobalTitle:SetHide( not HasCapability("CAPABILITY_DIPLOMACY_DEALS"));
end

print("OK loaded ReportsList_BRS.lua from Better Report Screen");