print("Loading DiplomacyRibbon.lua from Better Leader Icon"); -- version "..GlobalParameters.BCP_VERSION_MAJOR.."."..GlobalParameters.BCP_VERSION_MINOR);
-- Copyright 2017-2018, Firaxis Games.
-- Leader container list on top of the HUD

include("InstanceManager");
include("LeaderIcon");
include("PlayerSupport");


-- ===========================================================================
--	CONSTANTS
-- ===========================================================================
local SCROLL_SPEED			:number = 3;


-- ===========================================================================
--	GLOBALS
-- ===========================================================================
g_maxNumLeaders	= 0; -- Number of leaders that can fit in the ribbon


-- ===========================================================================
--	MEMBERS
-- ===========================================================================
local m_leadersMet			:number = 0; -- Number of leaders in the ribbon
local m_scrollIndex			:number = 0; -- Index of leader that is supposed to be on the far right
local m_scrollPercent		:number = 0; -- Necessary for scroll lerp
local m_isScrolling			:boolean = false;
local m_uiLeadersByID		:table = {};
local m_uiChatIconsVisible	:table = {};
local m_kLeaderIM			:table = InstanceManager:new("LeaderInstance", "LeaderContainer", Controls.LeaderStack);


-- ===========================================================================
--	Cleanup leaders
-- ===========================================================================
function ResetLeaders()
	m_leadersMet = 0;
	m_uiLeadersByID = {};
	m_kLeaderIM:ResetInstances();
end

-- ===========================================================================
function OnLeaderClicked(playerID : number )
	-- Send an event to open the leader in the diplomacy view (only if they met)

	local localPlayerID:number = Game.GetLocalPlayer();
	if playerID == localPlayerID or Players[localPlayerID]:GetDiplomacy():HasMet(playerID) then
		LuaEvents.DiplomacyRibbon_OpenDiplomacyActionView( playerID );
	end
end

-- ===========================================================================
--	Add a leader (from right to left)
-- ===========================================================================
function AddLeader(iconName : string, playerID : number, isUniqueLeader: boolean)
	m_leadersMet = m_leadersMet + 1;

	-- Create a new leader instance
	local leaderIcon, instance = LeaderIcon:GetInstance(m_kLeaderIM);
	m_uiLeadersByID[playerID] = instance;
	leaderIcon:UpdateIcon(iconName, playerID, isUniqueLeader);
	leaderIcon:RegisterCallback(Mouse.eLClick, function() OnLeaderClicked(playerID); end);

	-- Returning these so mods can override them and modify the icons
	local pPlayer:table = Players[playerID];
    instance.TotScore:SetText("[ICON_Capital][COLOR_White]"..    tostring(pPlayer:GetScore())                                     .."[ENDCOLOR]");
    instance.NumTechs:SetText("[ICON_Science][COLOR_Science]"..  tostring(pPlayer:GetStats():GetNumTechsResearched())             .."[ENDCOLOR]");
    instance.Strength:SetText("[ICON_Strength][COLOR_Military]"..tostring(pPlayer:GetStats():GetMilitaryStrengthWithoutTreasury()).."[ENDCOLOR]");
	
	return leaderIcon, instance;
end

-- ===========================================================================
--	Clears leaders and re-adds them to the stack
-- ===========================================================================
function UpdateLeaders()

	local localPlayerID:number = Game.GetLocalPlayer();
	if localPlayerID == -1 then
		Controls.LeaderStack:CalculateSize();
		RealizeSize();
		return;
	end;

	ResetLeaders();

	-- Add entries for everyone we know (Majors only)
	local aPlayers:table = PlayerManager.GetAliveMajors();
	local localPlayer:table = Players[localPlayerID];
	local localDiplomacy:table = localPlayer:GetDiplomacy();

	table.sort(aPlayers, function(a:table,b:table) return localDiplomacy:GetMetTurn(a:GetID()) < localDiplomacy:GetMetTurn(b:GetID()) end);

	--First, add me!
	AddLeader("ICON_"..PlayerConfigurations[localPlayerID]:GetLeaderTypeName(), localPlayerID);

	local kMetPlayers, kUniqueLeaders = GetMetPlayersAndUniqueLeaders();

	--Then, add the leader icons.
	for _, pPlayer in ipairs(aPlayers) do
		local playerID:number = pPlayer:GetID();
		if(playerID ~= localPlayerID) then
			local isMet			:boolean = kMetPlayers[playerID];
			local pPlayerConfig	:table = PlayerConfigurations[playerID];
			if (isMet or (GameConfiguration.IsAnyMultiplayer() and pPlayerConfig:IsHuman())) then
				if isMet then
					local leaderName:string = pPlayerConfig:GetLeaderTypeName();
					AddLeader("ICON_"..leaderName, playerID, kUniqueLeaders[leaderName]);
				else
					AddLeader("ICON_LEADER_DEFAULT", playerID);
				end
			end
		end
	end

	Controls.LeaderStack:CalculateSize();
	RealizeSize();
end

-- ===========================================================================
--	Updates size and location of BG and Scroll controls
--	additionalElementsWidth, from MODS that add additional content.
-- ===========================================================================
function RealizeSize( additionalElementsWidth:number )
	
	if additionalElementsWidth == nil then
		additionalElementsWidth = 0;
	end
	
	local MIN_LEFT_HOOKS		:number	= 260;
	local RIGHT_HOOKS_INITIAL	:number	= 163;
	local WORLD_TRACKER_OFFSET	:number	= 40;
	local launchBarWidth		:number = MIN_LEFT_HOOKS;
	local partialScreenBarWidth :number = RIGHT_HOOKS_INITIAL;

	-- Obtain controls
	local uiPartialScreenHookBar :table	= ContextPtr:LookUpControl( "/InGame/PartialScreenHooks/ButtonStack" );
	local uiLaunchBar			 :table	= ContextPtr:LookUpControl( "/InGame/LaunchBar/ButtonStack" );
	
	if (uiLaunchBar ~= nil) then
		launchBarWidth = math.max(uiLaunchBar:GetSizeX() + WORLD_TRACKER_OFFSET, MIN_LEFT_HOOKS);
	end
	if (uiPartialScreenHookBar~=nil) then
		partialScreenBarWidth = uiPartialScreenHookBar:GetSizeX();
	end

	local screenWidth:number, screenHeight:number = UIManager:GetScreenSizeVal(); -- Cache screen dimensions
	
	local SIZE_LEADER		:number = 51;	-- Size of leader icon and border.
	local PADDING_LEADER	:number = 3;	-- Padding used in stack control.	
	local maxSize			:number = screenWidth - launchBarWidth - partialScreenBarWidth;	
	local size				:number = maxSize;

	g_maxNumLeaders = math.floor(maxSize / (SIZE_LEADER + PADDING_LEADER));

	Controls.LeaderBG:SetHide( m_leadersMet==0 )
	if m_leadersMet > 0 then
		-- Compute size of the background shadow
		local BG_PADDING_EDGE	:number = 50;		-- Account for the (tons of) alpha on edges of shadow graphic.
		local MINIMUM_BG_SIZE	:number = 100;
		local bgSize			:number = 0;
		if (m_leadersMet > g_maxNumLeaders) then
			bgSize = g_maxNumLeaders * (SIZE_LEADER + PADDING_LEADER) + additionalElementsWidth + BG_PADDING_EDGE;
		else
			bgSize = m_leadersMet * (SIZE_LEADER + PADDING_LEADER) + additionalElementsWidth + BG_PADDING_EDGE;
		end		
		bgSize = math.max(bgSize, MINIMUM_BG_SIZE);
		Controls.LeaderBG:SetSizeX( bgSize );
		Controls.RibbonContainer:SetSizeX( bgSize );

		-- Compute actual size of the container
		local PADDING_EDGE		:number = 8;		-- Ensure scroll bar is wide enough
		size = g_maxNumLeaders * (SIZE_LEADER + PADDING_LEADER) + PADDING_EDGE + additionalElementsWidth;
	end
	Controls.ScrollContainer:SetSizeX(size);
	Controls.LeaderScroll:SetSizeX(size);
	Controls.RibbonContainer:SetOffsetX(partialScreenBarWidth);	
	Controls.LeaderScroll:CalculateSize();
	RealizeScroll();
end

-- ===========================================================================
--	Updates visibility of previous and next buttons
-- ===========================================================================
function RealizeScroll()
	Controls.NextButtonContainer:SetHide( not CanScrollLeft() );
	Controls.PreviousButtonContainer:SetHide( not CanScrollRight() );	
end

-- ===========================================================================
function CanScrollLeft()
	return m_scrollIndex > 0;
end

-- ===========================================================================
function CanScrollRight()
	return m_leadersMet - m_scrollIndex > g_maxNumLeaders;
end

-- ===========================================================================
--	Initialize scroll animation in a particular direction
-- ===========================================================================
function Scroll(direction : number)
 
	m_scrollPercent = 0;
	m_scrollIndex = m_scrollIndex + direction;

	if(m_scrollIndex < 0) then 
		m_scrollIndex = 0; 
	end

	if(not m_isScrolling) then
		ContextPtr:SetUpdate( UpdateScroll );
		m_isScrolling = true;
	end

	RealizeScroll();
end

-- ===========================================================================
--	Update scroll animation (only called while animating)
-- ===========================================================================
function UpdateScroll(deltaTime : number)
	
	local start:number = Controls.LeaderScroll:GetScrollValue();
	local destination:number = 1.0 - (m_scrollIndex / (m_leadersMet - g_maxNumLeaders));

	m_scrollPercent = m_scrollPercent + (SCROLL_SPEED * deltaTime);
	if(m_scrollPercent >= 1) then
		m_scrollPercent = 1
		EndScroll();
	end

	Controls.LeaderScroll:SetScrollValue(start + (destination - start) * m_scrollPercent);
end

-- ===========================================================================
--	Cleans up scroll update callback when done scrollin
-- ===========================================================================
function EndScroll()
	ContextPtr:ClearUpdate();
	m_isScrolling = false;
	RealizeScroll();
end

-- ===========================================================================
--	SystemUpdateUI Callback
-- ===========================================================================
function OnUpdateUI(type:number, tag:string, iData1:number, iData2:number, strData1:string)
	if(type == SystemUpdateUI.ScreenResize) then
		RealizeSize();
	end
end

-- ===========================================================================
--	Diplomacy Callback
-- ===========================================================================
function OnDiplomacyMeet(player1ID:number, player2ID:number)
	
	local localPlayerID:number = Game.GetLocalPlayer();
	-- Have a local player?
	if(localPlayerID ~= -1) then
		-- Was the local player involved?
		if (player1ID == localPlayerID or player2ID == localPlayerID) then
			UpdateLeaders();
		end
	end
end

-- ===========================================================================
--	Diplomacy Callback
-- ===========================================================================
function OnDiplomacyWarStateChange(player1ID:number, player2ID:number)
	
	local localPlayerID:number = Game.GetLocalPlayer();
	-- Have a local player?
	if(localPlayerID ~= -1) then
		-- Was the local player involved?
		if (player1ID == localPlayerID or player2ID == localPlayerID) then
			UpdateLeaders();
		end
	end
end

-- ===========================================================================
--	Diplomacy Callback
-- ===========================================================================
function OnDiplomacySessionClosed(sessionID:number)

	local localPlayerID:number = Game.GetLocalPlayer();
	-- Have a local player?
	if(localPlayerID ~= -1) then
		-- Was the local player involved?
		local diplomacyInfo:table = DiplomacyManager.GetSessionInfo(sessionID);
		if(diplomacyInfo ~= nil and (diplomacyInfo.FromPlayer == localPlayerID or diplomacyInfo.ToPlayer == localPlayerID)) then
			UpdateLeaders();
		end
	end

end

-- ===========================================================================
--	EVENT
-- ===========================================================================
function OnInterfaceModeChanged(eOldMode:number, eNewMode:number)
	if eNewMode == InterfaceModeTypes.VIEW_MODAL_LENS then
		ContextPtr:SetHide(true);
	end
	if eOldMode == InterfaceModeTypes.VIEW_MODAL_LENS then
		ContextPtr:SetHide(false);
	end
end

-- ===========================================================================
--	EVENT
-- ===========================================================================
function OnTurnBegin(playerID:number)
	local leader:table = m_uiLeadersByID[playerID];
	if(leader ~= nil) then
		leader.LeaderContainer:SetToBeginning();
		leader.LeaderContainer:Play();
	end
end

-- ===========================================================================
--	EVENT
-- ===========================================================================
function OnTurnEnd(playerID:number)
	if(playerID ~= -1) then
		local leader = m_uiLeadersByID[playerID];
		if(leader ~= nil) then
			leader.LeaderContainer:Reverse();
		end
	end
end

-- ===========================================================================
--	LUAEvent
-- ===========================================================================
function OnLaunchBarResized( width:number )
	RealizeSize();
end

-- ===========================================================================
--	UI Callback
-- ===========================================================================
function OnScrollLeft()
	if CanScrollLeft() then 
		Scroll(-1); 
	end
end

-- ===========================================================================
--	UI Callback
-- ===========================================================================
function OnScrollRight()
	if CanScrollRight() then 
		Scroll(1); 
	end
end

-- ===========================================================================
function OnChatReceived(fromPlayer:number, stayOnScreen:boolean)
	local instance:table= m_uiLeadersByID[fromPlayer];
	if instance == nil then return; end
	if stayOnScreen then
		Controls.ChatIndicatorWaitTimer:Stop();
		instance.ChatIndicatorFade:RegisterEndCallback(function() end);
		table.insert(m_uiChatIconsVisible, instance.ChatIndicatorFade);
	else
		Controls.ChatIndicatorWaitTimer:Stop();

		instance.ChatIndicatorFade:RegisterEndCallback(function() 
			Controls.ChatIndicatorWaitTimer:RegisterEndCallback(function()
				instance.ChatIndicatorFade:RegisterEndCallback(function() instance.ChatIndicatorFade:SetToBeginning(); end);
				instance.ChatIndicatorFade:Reverse();
			end);
			Controls.ChatIndicatorWaitTimer:SetToBeginning();
			Controls.ChatIndicatorWaitTimer:Play();
		end);
	end
	instance.ChatIndicatorFade:Play();
end

-- ===========================================================================
function OnChatPanelShown(fromPlayer:number, stayOnScreen:boolean)
	for _, chatIndicatorFade in ipairs(m_uiChatIconsVisible) do
		chatIndicatorFade:RegisterEndCallback(function() chatIndicatorFade:SetToBeginning(); end);
		chatIndicatorFade:Reverse();
	end
	chatIndicatorFade = {};
end

-- ===========================================================================
function LateInitialize()
	Controls.NextButton:RegisterCallback( Mouse.eLClick, OnScrollLeft );
	Controls.PreviousButton:RegisterCallback( Mouse.eLClick, OnScrollRight );
	Controls.LeaderScroll:SetScrollValue(1);

	Events.SystemUpdateUI.Add( OnUpdateUI );
	Events.DiplomacyMeet.Add( OnDiplomacyMeet );
	Events.DiplomacySessionClosed.Add( OnDiplomacySessionClosed );
	Events.DiplomacyDeclareWar.Add( OnDiplomacyWarStateChange ); 
	Events.DiplomacyMakePeace.Add( OnDiplomacyWarStateChange ); 
	Events.DiplomacyRelationshipChanged.Add( UpdateLeaders ); 
	Events.InterfaceModeChanged.Add( OnInterfaceModeChanged );
	Events.RemotePlayerTurnBegin.Add( OnTurnBegin );
	Events.RemotePlayerTurnEnd.Add( OnTurnEnd );
	Events.LocalPlayerTurnBegin.Add( function() OnTurnBegin(Game.GetLocalPlayer()); end );
	Events.LocalPlayerTurnEnd.Add( function() OnTurnEnd(Game.GetLocalPlayer()); end );
	Events.MultiplayerPlayerConnected.Add(UpdateLeaders);
	Events.MultiplayerPostPlayerDisconnected.Add(UpdateLeaders);
	Events.LocalPlayerChanged.Add(UpdateLeaders);
	Events.PlayerInfoChanged.Add(UpdateLeaders);
	Events.PlayerDefeat.Add(UpdateLeaders);
	Events.PlayerRestored.Add(UpdateLeaders);

	LuaEvents.ChatPanel_OnChatReceived.Add(OnChatReceived);
	LuaEvents.WorldTracker_OnChatShown.Add(OnChatPanelShown);
	LuaEvents.LaunchBar_Resize.Add( OnLaunchBarResized );
	LuaEvents.PartialScreenHooks_Realize.Add(RealizeSize);
		
	if not BASE_LateInitialize then	-- Only update leaders if this is the last in the call chain.
		UpdateLeaders();
	end
end

-- ===========================================================================
function OnInit( isReload:boolean )
	LateInitialize();
end

-- ===========================================================================
--	Main Initialize
-- ===========================================================================
function Initialize()	
	-- UI Events
	ContextPtr:SetInitHandler( OnInit );
end
Initialize();
