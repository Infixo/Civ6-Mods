print("Loading PartialScreenHooks_BRS.lua from Better Report Screen version "..GlobalParameters.BRS_VERSION_MAJOR.."."..GlobalParameters.BRS_VERSION_MINOR);
-- ===========================================================================
-- Better Report Screen
-- Author: Infixo
-- 2019-02-17: Created
-- ===========================================================================


-- ===========================================================================
-- CACHE BASE FUNCTIONS
-- ===========================================================================
--include("LaunchBar");
--BASE_CloseAllPopups = CloseAllPopups;
BRS_BASE_OnInputActionTriggered = OnInputActionTriggered;
BRS_BASE_LateInitialize = LateInitialize;


-- ===========================================================================
--	Action Hotkeys
-- ===========================================================================
local m_ToggleReportsId:number = Input.GetActionId("ToggleReports");


-- ===========================================================================
--	VARIABLES
-- ===========================================================================
--local m_ReportsInstance = {};
--local m_ReportsInstancePip = {};
local m_isReportScreenOpen:boolean = false;


-- ===========================================================================
--	FUNCTIONS
-- ===========================================================================

--	Input Hotkey Event
function OnInputActionTriggered( actionId )
	print("FUN OnInputActionTriggered_BRS", actionId);
	BRS_BASE_OnInputActionTriggered( actionId );
	-- Always available
	if actionId == m_ToggleReportsId then
		print(".....Detected F8.....")
		ToggleReports();
	end
end

--function CloseAllPopups()
	--BRS_BASE_CloseAllPopups();
	--LuaEvents.TopPanel_CloseReportsScreen();
--end

function ToggleReports()
	print("FUN ToggleReports", m_isReportScreenOpen);
	if m_isReportScreenOpen then
		LuaEvents.TopPanel_CloseReportsScreen();
	else
		--CloseAllPopups();
		LuaEvents.TopPanel_OpenReportsScreen();
	end
end

-- ===========================================================================
-- Add a button to the partial screen hooks.
-- Must override this function because it doesn't return the instance created within it
-- Nope, can't do. m_kPartialScreens is a local variable and I cannot access it from here.
-- Conversly, I cannot redefine it here as it used to add a static World Rankings screen in the main file.
-- ===========================================================================
--[[
function AddScreenHook( contextName:string, texture:string, tooltip:string, callback:ifunction, callback2:ifunction)
	print("FUN AddScreenHook", contextName, texture, tooltip, callback, callback2);

	if m_kPartialScreens[contextName] == nil then
		table.insert(m_kPartialScreens, contextName);
	else
		UI.DataError("Attempt to add a screen hook '"..contextName.."' which already exists!");
		return;
	end
	
	local screenHookInst:table = m_ScreenHookIM:GetInstance();
	screenHookInst.ScreenHookImage:SetTexture(texture);
	screenHookInst.ScreenHookButton:SetToolTipString(Locale.Lookup(tooltip));
	screenHookInst.ScreenHookButton:RegisterCallback( Mouse.eLClick, callback );
	screenHookInst.ScreenHookButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	if callback2 ~= nil then screenHookInst.ScreenHookButton:RegisterCallback( Mouse.eRClick, callback2 ); end;
end
--]]

-- ===========================================================================
--[[
function AddReportsHook()
	print("FUN AddReportsHook");
	if ( HasCapability("CAPABILITY_REPORTS_LIST") ) then
		AddScreenHook("ReportsList", "LaunchBar_Hook_Reports", "LOC_PARTIALSCREEN_REPORTS_TOOLTIP", OnToggleReportsList, ToggleReports );
	end
end
--]]

-- ===========================================================================
function LateInitialize()
	print("FUN LateInitialize");
	BRS_BASE_LateInitialize();
	-- events called from ReportScreen when opened/closed
	LuaEvents.ReportScreen_Opened.Add( function() m_isReportScreenOpen = true;  end );
	LuaEvents.ReportScreen_Closed.Add( function() m_isReportScreenOpen = false; end );
end

print("OK loaded PartialScreenHooks_BRS.lua from Better Report Screen");