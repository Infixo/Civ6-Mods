print("Loading CivilopediaSupport_RCP.lua from Real Civilopedia, version 0.2");
--------------------------------------------------------------
-- Real Civilopedia
-- 2018-02-22: Created by Infixo based on CQUI code
--------------------------------------------------------------

-- Base File
include("CivilopediaSupport");

-- Cache base functions
BASE_OnClose = OnClose;
BASE_OnOpenCivilopedia = OnOpenCivilopedia;

local _LastSectionId = nil;
local _LastPageId = nil;

--------------------------------------------------------------
function OnOpenCivilopedia(sectionId_or_search, pageId)
	-- Opened without any query, restore the previously opened page and section instead
	if sectionId_or_search == nil and _LastPage then
		print("Received a request to open the Civilopedia - last section and page");
		NavigateTo(_LastSectionId, _LastPageId);
		UIManager:QueuePopup(ContextPtr, PopupPriority.Current);	
		UI.PlaySound("Civilopedia_Open");
	else
		BASE_OnOpenCivilopedia(sectionId_or_search, pageId);
	end
	Controls.SearchEditBox:TakeFocus();
end

--------------------------------------------------------------
function OnClose()
	-- Store the currently opened section and page
	_LastSectionId = _CurrentSectionId;
	_LastPageId = _CurrentPageId;
	BASE_OnClose();
end

print("OK loaded CivilopediaSupport_RCP.lua from Real Civilopedia, version 0.2");