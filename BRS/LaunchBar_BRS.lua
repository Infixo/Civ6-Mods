print("Loading LaunchBar_BRS.lua from Better Report Screen");
-- ===========================================================================
-- Better Report Screen
-- Author: Infixo
-- 2018-03-12: Created, based on LaunchBar_Expansion1.lua
-- ===========================================================================


-- ===========================================================================
-- CACHE BASE FUNCTIONS
-- ===========================================================================
--include("LaunchBar");
--BASE_CloseAllPopups = CloseAllPopups;
--BASE_OnInputActionTriggered = OnInputActionTriggered;


-- Check for HellBlazer's World Info Interface
local bIsModHBWII:boolean = Modding.IsModActive("ff9ea14f-62d8-4d10-9a9f-3512fdb11e57"); 


-- ===========================================================================
--	VARIABLES
-- ===========================================================================
local m_ReportsInstance = {};
local m_ReportsInstancePip = {};
local m_isReportScreenOpen:boolean = false;


-- ===========================================================================
--	FUNCTIONS
-- ===========================================================================

--	Input Hotkey Event
function OnInputActionTriggered( actionId )
	BRS_BASE_OnInputActionTriggered( actionId );
	-- Always available
	if actionId == Input.GetActionId("ToggleReports") then
		--print(".....Detected F8.....")
		ToggleReports();
	end
end

function CloseAllPopups()
	BRS_BASE_CloseAllPopups();
	LuaEvents.TopPanel_CloseReportsScreen();
end

function ToggleReports()
	if m_isReportScreenOpen then
		LuaEvents.TopPanel_CloseReportsScreen();
	else
		CloseAllPopups();
		LuaEvents.TopPanel_OpenReportsScreen();
	end
end


-- ===========================================================================
function Initialize()

	if not bIsModHBWII then
		-- Create a new button
		ContextPtr:BuildInstanceForControl("LaunchBarItem", m_ReportsInstance, Controls.ButtonStack);
		m_ReportsInstance.LaunchItemButton:RegisterCallback(Mouse.eLClick, ToggleReports);
		m_ReportsInstance.LaunchItemButton:SetTexture("LaunchBar_Hook_GreatWorksButton"); -- LaunchBar_Hook_ReligionButton
		m_ReportsInstance.LaunchItemButton:SetToolTipString( Locale.Lookup("LOC_HUD_REPORTS_VIEW_REPORTS").." "..Locale.Lookup("LOC_HUD_REPORTS_VIEW_REPORTS_TT") );
		m_ReportsInstance.LaunchItemIcon:SetTexture( IconManager:FindIconAtlas("ICON_TECH_ENGINEERING", 38) );

		-- Add a pin to the stack for each new item
		ContextPtr:BuildInstanceForControl("LaunchBarPinInstance", m_ReportsInstancePip, Controls.ButtonStack);
	end

	-- events called from ReportScreen when opened/closed
	LuaEvents.ReportScreen_Opened.Add( function() m_isReportScreenOpen = true;  OnOpen();  end );
	LuaEvents.ReportScreen_Closed.Add( function() m_isReportScreenOpen = false; OnClose(); end );

	RefreshView();
end
Initialize();

print("OK loaded LaunchBar_BRS.lua from Better Report Screen");