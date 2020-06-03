print("Loading ReportsListLoader.lua from ReportsList Loader "..GlobalParameters.RLL_VERSION_MAJOR.."."..GlobalParameters.RLL_VERSION_MINOR);
-- ===========================================================================
-- ReportsList Loader
-- Author: Infixo
-- 2019-03-30: Created
-- I hereby grant the permission to use RLL in other Civ6 mods provided no changes are made to the code.
-- ===========================================================================

include("ReportsList");

local bIsRiseAndFall:boolean    = Modding.IsModActive("1B28771A-C749-434B-9053-D1380C553DE9"); -- Rise & Fall
local bIsGatheringStorm:boolean = Modding.IsModActive("4873eb62-8ccc-4574-b784-dda455e74e68"); -- Gathering Storm

local m_ReportButtonIM:table = InstanceManager:new("ReportButtonInstance", "Button");

function LateInitialize()	
	m_ReportButtonIM:ResetInstances();
	-- filter out reports
	local tReports:table = {};
	for report in GameInfo.RLLReports() do
		local bAdd:boolean = true;
		if report.RequiresXP1 and not (bIsRiseAndFall or bIsGatheringStorm) then bAdd = false; end
		if report.RequiresXP2 and not bIsGatheringStorm                     then bAdd = false; end
		if report.GameCapability ~= nil and not HasCapability(report.GameCapability) then bAdd = false; end
		if bAdd then table.insert(tReports, report); end
	end
	-- sort and add
	table.sort(tReports, function (a,b) return a.SortOrder < b.SortOrder; end);
	for _,report in ipairs(tReports) do
		AddReport(report.ButtonLabel, function() Close(); LuaEvents[report.LuaEvent](); end, Controls[report.StackID]);
	end
end

print("OK loaded ReportsListLoader.lua from ReportsList Loader");