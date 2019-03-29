print("Loading ReportsList_RET.lua from Real Era Tracker "..GlobalParameters.RET_VERSION_MAJOR.."."..GlobalParameters.RET_VERSION_MINOR);
-- ===========================================================================
-- Real Era Tracker
-- Author: Infixo
-- 2019-03-28: Created
-- ===========================================================================

include("ReportsList_BRS");

BRS_LateInitialize = LateInitialize;

function OnRaiseEraTracker() Close(); LuaEvents.ReportsList_OpenEraTracker(); end

function LateInitialize()
	BRS_LateInitialize();
	AddReport("LOC_RET_BUTTON_LABEL", OnRaiseEraTracker, Controls.GlobalReportsStack);
end

print("OK loaded ReportsList_RET.lua from Real Era Tracker");