print("Loading RealEraTracker.lua from Real Era Tracker version "..(GlobalParameters.RET_VERSION_MAJOR and GlobalParameters.RET_VERSION_MAJOR or "0").."."..(GlobalParameters.RET_VERSION_MINOR and GlobalParameters.RET_VERSION_MINOR or "0"));
-- ===========================================================================
--	Real Era Tracker
--	Author: Infixo
--  2019-03-28: Created
--  2023-04-16: Search feature (v1.4)
-- ===========================================================================
include("InstanceManager");
include("SupportFunctions"); -- TruncateString
include("TabSupport");

include("Serialize");

-- Expansions check
local bIsRiseAndFall:boolean = Modding.IsModActive("1B28771A-C749-434B-9053-D1380C553DE9"); -- Rise & Fall
--print("Rise & Fall    :", (bIsRiseAndFall and "YES" or "no"));
local bIsGatheringStorm:boolean = Modding.IsModActive("4873eb62-8ccc-4574-b784-dda455e74e68"); -- Gathering Storm
--print("Gathering Storm:", (bIsGatheringStorm and "YES" or "no"));

-- configuration options
local bOptionIncludeOthers:boolean = ( GlobalParameters.RET_OPTION_INCLUDE_OTHERS == 1 );


-- ===========================================================================
--	CONSTANTS
-- ===========================================================================
local LL = Locale.Lookup;
local ENDCOLOR:string = "[ENDCOLOR]";
local NEWLINE:string  = "[NEWLINE]";
local DATA_FIELD_SELECTION						:string = "Selection";
local SIZE_HEIGHT_PADDING_BOTTOM_ADJUST			:number = 85;	-- (Total Y - (scroll area + THIS PADDING)) = bottom area
local LOC_TREE_SEARCH_W_DOTS = LL("LOC_TREE_SEARCH_W_DOTS"); -- 230416 search feature

function ColorGREEN(s) return "[COLOR_Green]"..tostring(s)..ENDCOLOR; end
function ColorRED(s)   return "[COLOR_Red]"  ..tostring(s)..ENDCOLOR; end


-- ===========================================================================
--	VARIABLES
-- ===========================================================================
local m_kCurrentTab:number = 1; -- last active tab which will be also used as a moment category, 1=world, 2=civ, 3=repeat, 4=fav
local m_iMaxEraIndex:number = #GameInfo.Eras-1;
local m_iTajMahalIndex:number = (GameInfo.Buildings.BUILDING_TAJ_MAHAL and GameInfo.Buildings.BUILDING_TAJ_MAHAL.Index or -1);
local m_bIsTajMahal:boolean = false;
m_kMoments = {};
m_simpleIM = InstanceManager:new("SimpleInstance", "Top",    Controls.Stack); -- Non-Collapsable, simple
m_tabIM    = InstanceManager:new("TabInstance",    "Button", Controls.TabContainer);
m_tabs     = nil;
local _SearchQuery:string = nil; -- 230416 search feature


-- debug routine - prints a table, and tables inside recursively (up to 5 levels)
function dshowrectable(tTable:table, iLevel:number)
	local level:number = 0;
	if iLevel ~= nil then level = iLevel; end
	for k,v in pairs(tTable) do
		print(string.rep("---:",level), k, type(v), tostring(v));
		if type(v) == "table" and level < 5 then dshowrectable(v, level+1); end
	end
end


-- Infixo: this is an iterator to replace pairs
-- it sorts t and returns its elements one by one
-- source: https://stackoverflow.com/questions/15706270/sort-a-table-in-lua
function spairs( t, order_function )
	local keys:table = {}; -- actual table of keys that will bo sorted
	for key,_ in pairs(t) do table.insert(keys, key); end
	
	if order_function then
		table.sort(keys, function(a,b) return order_function(t, a, b) end)
	else
		table.sort(keys)
	end
	-- iterator here
	local i:number = 0;
	return function()
		i = i + 1;
		if keys[i] then
			return keys[i], t[keys[i]]
		end
	end
end


-- ===========================================================================
--	Single exit point for display
-- ===========================================================================
function Close()
	if not ContextPtr:IsHidden() then
		UI.PlaySound("UI_Screen_Close");
	end
	UIManager:DequeuePopup(ContextPtr);
	LuaEvents.ReportScreen_Closed();
	--print("Closing... current tab is:", m_kCurrentTab);
end


-- ===========================================================================
--	UI Callback
-- ===========================================================================
function OnCloseButton()
	Close();
end


-- ===========================================================================
--	Single entry point for display
-- ===========================================================================
function Open( tabToOpen:number )
	--print("FUN Open()", tabToOpen, m_kCurrentTab);
	
	UIManager:QueuePopup( ContextPtr, PopupPriority.Medium );
	Controls.ScreenAnimIn:SetToBeginning();
	Controls.ScreenAnimIn:Play();
	UI.PlaySound("UI_Screen_Open");

	UpdateMomentsData();
	
	-- To remember the last opened tab when the report is re-opened
	if tabToOpen ~= nil then m_kCurrentTab = tabToOpen; end
	m_tabs.SelectTab( m_kCurrentTab );
	
	-- show era score info
	local pGameEras:table = Game.GetEras();

	-- current era
	Controls.EraNameLabel:SetText( LL("LOC_ERA_PROGRESS_THE_ERA", GameInfo.Eras[ pGameEras:GetCurrentEra() ].Name) );
	-- turns till next
	if pGameEras:GetCurrentEra() == pGameEras:GetFinalEra() then
		Controls.TurnsLabel:SetHide( true );
	else
		Controls.TurnsLabel:SetHide( false );
		local nextEraCountdown:number = pGameEras:GetNextEraCountdown() + 1; -- 0 turns remaining is the last turn, shift by 1 to make sense to non-programmers
		if nextEraCountdown > 0 then
			-- If the era countdown has started only show that number
			Controls.TurnsLabel:SetText( string.format("[ICON_Turn] %d", nextEraCountdown) );
		else
			local inactiveCountdownLength:number = GlobalParameters.NEXT_ERA_TURN_COUNTDOWN; -- Even though the countdown has not started yet, account for it in our time estimates
			local currentTurn:number = Game.GetCurrentGameTurn();
			local iNextEraMinTurn:number = math.max(pGameEras:GetCurrentEraMinimumEndTurn() - currentTurn, inactiveCountdownLength);
			local iNextEraMaxTurn:number = math.max(pGameEras:GetCurrentEraMaximumEndTurn() - currentTurn, inactiveCountdownLength);
			Controls.TurnsLabel:SetText( string.format("[ICON_Turn] %d - %d", iNextEraMinTurn, iNextEraMaxTurn) );
		end
	end
	
	-- player data
	local localPlayerID:number = Game.GetLocalPlayer();
	if localPlayerID == -1 then return; end
	
	-- thresholds
	local iDarkAgeThreshold:number   = pGameEras:GetPlayerDarkAgeThreshold(localPlayerID);
	local iGoldenAgeThreshold:number = pGameEras:GetPlayerGoldenAgeThreshold(localPlayerID);
	--Controls.ThresholdsLabel:SetText( string.format("[ICON_GLORY_DARK_AGE] %s [ICON_GLORY_NORMAL_AGE] %s [ICON_GLORY_GOLDEN_AGE]", ColorRED(iDarkAgeThreshold), ColorGREEN(iGoldenAgeThreshold)) );
	Controls.ThresholdsLabel:SetText( string.format("[ICON_GLORY_DARK_AGE]  %d  [ICON_GLORY_NORMAL_AGE]  %d  [ICON_GLORY_GOLDEN_AGE]", iDarkAgeThreshold, iGoldenAgeThreshold) );
	
	-- total era score
	local iCurrentScore:number = pGameEras:GetPlayerCurrentScore(localPlayerID);
	local sAge:string = "[ICON_GLORY_DARK_AGE]";
	if iCurrentScore >= iDarkAgeThreshold   then sAge = "[ICON_GLORY_NORMAL_AGE]"; end
	if iCurrentScore >= iGoldenAgeThreshold then sAge = "[ICON_GLORY_GOLDEN_AGE]"; end
	Controls.TotalsLabel:SetText( tostring(iCurrentScore).." "..sAge );
	
	-- Taj Mahal
	m_bIsTajMahal = (Players[localPlayerID]:GetStats():GetNumBuildingsOfType(m_iTajMahalIndex) > 0);
	Controls.TajMahalImage:SetHide(not m_bIsTajMahal);
end


-- ===========================================================================
function ResetTabForNewPageContent()
	m_simpleIM:ResetInstances();
	Controls.Scroll:SetScrollValue( 0 );	
end



--[[
-- ===========================================================================
HISTORIC MOMENTS

Game.GetHistoryManager():GetAllMomentsData(playerID, iMinInterestLevel) -> interest level is different than score! just use 1 for all valid moments
-> returns a simple (ipairs) table with moments
Game:GetHistoryManager():GetMomentData(momentID)
-> returns a table with a single moment

Moment data
-----------
.ID	310
.Type	-77408354  => Hash for GameInfo.Moments[]
.InstanceDescription	The discovery of Apprenticeship by Korea sets the world stage for future discoveries in the Medieval Era!
.ActingPlayer	0
.EraScore	2
.GameEra	1
.Turn	101
.HasEverBeenCommemorated	false => seems to be false always
.ActionPlotX	-9999
.ActionPlotY	-9999
.ExtraData	table: 000000006221F3C0 => (ipairs) table of { .DataType and .DataValue }
        .DataType => GameInfo.Types[hash].Type, e.g. MOMENT_DATA_DISTRICT, MOMENT_DATA_PLAYER_ERA
		sometimes DataType gives nil - probably when no extra data is actually recorded but the record still exists, weird
		"MomentDataType" TEXT NOT NULL REFERENCES MomentDataTypes(MomentDataType)
		"GameDataType"   TEXT NOT NULL REFERENCES Types(Type)
--]]

-- one-time call to init all necessary data
-- it will create all possible moments in a separate table
function InitializeMomentsData()
	--print("FUN InitializeMomentsData");
	
	local function RegisterOneMoment(sKey:string, moment:table, sObject:string, sValidFor:string)
		--print("FUN RegisterOneMoment",sKey,sObject,sValidFor);
		if moment.EraScore == nil then return nil; end
		local data:table = {
			MomentType = moment.MomentType,
			Category = moment.Category,
			EraScore = moment.EraScore,
			Description = LL(moment.Name),
			LongDesc = LL(moment.Description),
			Object = sObject,
			ValidFor = sValidFor, -- either LEADER_x or CIVILIZATION_x
			MinEra = moment.MinEra,
			MaxEra = moment.MaxEra,
			-- op data
			Favored = false,
			Status = 0, -- 0: not earned, 1: earned, -1: invalid (e.g. earned on world level and this is local level)
			Turn = 0,
			Count = 0,
			Player = "",
			TT = {}, -- tooltip
			ExtraData = {}, -- for future uses
		};
		if moment.ObjectType ~= nil and data.Object == "" then data.Object = LL("LOC_"..moment.ObjectType.."_NAME"); end
		m_kMoments[ sKey ] = data;
		return data;
	end
	
	for moment in GameInfo.Moments() do
		if     moment.Special == "ERA" then
			-- register separate moments for each era (exceot Ancient)
			for era in GameInfo.Eras() do
				if era.EraType ~= "ERA_ANCIENT" then 
					local pMoment:table = RegisterOneMoment(era.EraType.."_"..moment.MomentType, moment, LL(era.Name), "");
					-- adjust eras for -2..+1 range
					pMoment.MinEra = GameInfo.Eras[ math.max(era.Index-2, 0) ].EraType; 
					pMoment.MaxEra = GameInfo.Eras[ math.min(era.Index+1, m_iMaxEraIndex) ].EraType;
				end -- ancient
			end -- for
		
		elseif moment.Special == "STRATEGIC" then
			-- register separate moments for each strategic resource that is used to create a standard unit
			local sql:string = "select distinct StrategicResource from Units where StrategicResource is not null order by StrategicResource";
			for _,row in ipairs(DB.Query(sql)) do
				RegisterOneMoment(row.StrategicResource.."_"..moment.MomentType, moment, LL(GameInfo.Resources[row.StrategicResource].Name), "");
			end
		
		elseif moment.Special == "UNIQUE" then
			-- register separate moments for all uniques
			local function RegisterMomentsForUniques(sTable:string, sField:string)
				for row in GameInfo[sTable]() do
					-- helper - check if trait is valid for a leader or a civ
					-- only majors are valid
					local function GetValidFor(sTrait:string)
						-- check civilizations
						for row in GameInfo.CivilizationTraits() do
							if row.TraitType == sTrait then
								local civ = GameInfo.Civilizations[row.CivilizationType];
								if civ ~= nil then
									if civ.StartingCivilizationLevelType == "CIVILIZATION_LEVEL_FULL_CIV" then return civ.CivilizationType; else return ""; end
								end
							end -- traits
						end -- for
						-- check leaders
						for row in GameInfo.LeaderTraits() do
							if row.TraitType == sTrait then
								local leader = GameInfo.Leaders[row.LeaderType];
								if leader ~= nil then
									if leader.InheritFrom == "LEADER_DEFAULT" then return leader.LeaderType; else return ""; end
								end
							end -- traits
						end -- for
						return "";
					end
					if row.TraitType ~= nil and row.TraitType ~= "" then
						local sValidFor:string = GetValidFor(row.TraitType);
						if sValidFor ~= "" then RegisterOneMoment(row[sField].."_"..moment.MomentType, moment, LL(row.Name), sValidFor); end
					end
				end
			end
			if     moment.MomentIllustrationType == "MOMENT_ILLUSTRATION_UNIQUE_BUILDING"    then RegisterMomentsForUniques("Buildings",    "BuildingType");
			elseif moment.MomentIllustrationType == "MOMENT_ILLUSTRATION_UNIQUE_DISTRICT"    then RegisterMomentsForUniques("Districts",    "DistrictType");
			elseif moment.MomentIllustrationType == "MOMENT_ILLUSTRATION_UNIQUE_IMPROVEMENT" then RegisterMomentsForUniques("Improvements", "ImprovementType");
			elseif moment.MomentIllustrationType == "MOMENT_ILLUSTRATION_UNIQUE_UNIT"        then RegisterMomentsForUniques("Units",        "UnitType");
			end
			
		else
			-- standard moment
			RegisterOneMoment(moment.MomentType, moment, "", "");
		end
	end
	--dshowrectable(m_kMoments); -- debug
end


-- main function for registering historic moments
function ProcessHistoricMoment(sKey:string, pMoment:table, eCategory:number, localPlayerID:number)
	--print("FUN ProcessHistoricMoment", sKey, pMoment.ID, eCategory, pMoment.ActingPlayer, localPlayerID);
	
	local sPlayer:string = LL(PlayerConfigurations[pMoment.ActingPlayer]:GetCivilizationShortDescription());
	local sUnknown:string = LL("LOC_MULTIPLAYER_UNKNOWN");
	
	-- fill the data using the earned moment
	local function FillTrackedMoment(trackedMoment:table, eStatus:number, sPlayer:string)
		trackedMoment.Status = eStatus;
		trackedMoment.Turn = pMoment.Turn;
		trackedMoment.Count = trackedMoment.Count + 1;
		trackedMoment.Player = sPlayer;
		table.insert(trackedMoment.TT, string.format("[ICON_Turn]%d: %s", pMoment.Turn, pMoment.InstanceDescription));
		trackedMoment.ExtraData = pMoment.ExtraData;
	end
	
	local trackedMoment:table = m_kMoments[sKey];
	if trackedMoment == nil then print("ERROR ProcessHistoricMoment: cannot find moment for key", sKey); return; end
	FillTrackedMoment(trackedMoment, 1, sPlayer); -- set as "earned"
	
	-- if the player is not local, then nothing more to do
	if pMoment.ActingPlayer ~= localPlayerID then return; end
	
	-- this is the tweak to invalidate a local moment in case there is a world-version earned
	-- it uses a strong assumption that world type has "_IN_WORLD" added to the local version
	-- this is only applied to moments earned by a local player (because we have to invalidate a local version)
	if eCategory == 1 then
		local sKey2:string = string.gsub(sKey, "_IN_WORLD", "");
		--print("...checking world moment", sKey, sKey2);
		local trackedMoment2:table = m_kMoments[sKey2];
		if trackedMoment2 ~= nil then
			--print("...invalidating", sKey2, "because of", sKey);
			FillTrackedMoment(trackedMoment2, -1, sPlayer);
		end
		sKey2 = string.gsub(sKey, "_FIRST_IN_WORLD", "");
		local trackedMoment2:table = m_kMoments[sKey2];
		if trackedMoment2 ~= nil and trackedMoment2.Category == 2 then
			FillTrackedMoment(trackedMoment2, -1, sPlayer);
		end
		return;
	end
	
	-- the other way around
	-- local or repeat, if earned and world is NOT, then invalidate
	if eCategory == 2 then
		local sKey2:string = sKey.."_IN_WORLD";
		local trackedMoment2:table = m_kMoments[sKey2];
		if trackedMoment2 ~= nil and trackedMoment2.Category == 1 and trackedMoment2.Status == 0 then
			FillTrackedMoment(trackedMoment2, -1, sUnknown);
		end
		sKey2 = sKey.."_FIRST_IN_WORLD";
		trackedMoment2 = m_kMoments[sKey2];
		if trackedMoment2 ~= nil and trackedMoment2.Category == 1 and trackedMoment2.Status == 0 then
			FillTrackedMoment(trackedMoment2, -1, sUnknown);
		end
		return;
	end
	
	-- the only case for Repeat - National Park
	if pMoment.MomentType == "MOMENT_NATIONAL_PARK_CREATED" then
		local trackedMoment2:table = m_kMoments["MOMENT_NATIONAL_PARK_CREATED_FIRST_IN_WORLD"];
		if trackedMoment2 ~= nil and trackedMoment2.Status == 0 then
			FillTrackedMoment(trackedMoment2, -1, sUnknown);
		end
	end
end


function RetrieveFromExtraData(moment:table, sType:string)
	--print("FUN RetrieveFromExtraData", GameInfo.Moments[moment.Type].MomentType, sType);
	--dshowrectable(moment);
	local sValue;
	if moment.ExtraData[1] ~= nil and GameInfo.Types[ moment.ExtraData[1].DataType ].Type == sType then
		sValue = moment.ExtraData[1].DataValue;
	end
	if moment.ExtraData[2] ~= nil and GameInfo.Types[ moment.ExtraData[2].DataType ].Type == sType then
		sValue = moment.ExtraData[2].DataValue;
	end
	if sValue == nil then
		print("ERROR RetrieveFromExtraData: can't find", sType); dshowrectable(moment); return "";
	end
	--print("...retrieved", sValue);
	-- get the actual value
	if sType == "MOMENT_DATA_BUILDING"    then return GameInfo.Buildings[ sValue ].BuildingType; end
	if sType == "MOMENT_DATA_DISTRICT"    then return GameInfo.Districts[ sValue ].DistrictType; end
	if sType == "MOMENT_DATA_IMPROVEMENT" then return GameInfo.Improvements[ sValue ].ImprovementType; end
	if sType == "MOMENT_DATA_PLAYER_ERA"  then return GameInfo.Eras[ sValue ].EraType; end
	if sType == "MOMENT_DATA_RESOURCE"    then return GameInfo.Resources[ sValue ].ResourceType; end
	if sType == "MOMENT_DATA_UNIT"        then return GameInfo.Units[ sValue ].UnitType; end
	print("ERROR RetrieveFromExtraData: data type not supported", sType); return "";
end


function UpdateMomentsData()
	--print("FUN UpdateMomentsData");
	
	-- reset the operational data
	for _,moment in pairs(m_kMoments) do
		moment.Status = 0;
		moment.Turn = 0;
		moment.Count = 0;
		moment.Player = "";
		moment.TT = {};
		moment.ExtraData = {};
	end
	
	-- civ and leader for uniques
	local localPlayerID:number = Game.GetLocalPlayer();
	if localPlayerID == -1 then return; end
	local sCivilization:string = PlayerConfigurations[localPlayerID]:GetCivilizationTypeName();
	local sLeader:string       = PlayerConfigurations[localPlayerID]:GetLeaderTypeName();

	-- update for the current local player
	for _,moment in ipairs(Game.GetHistoryManager():GetAllMomentsData()) do
		local momentInfo:table = GameInfo.Moments[moment.Type];
		-- process only local player or others if cheating option is on and category is World
		if moment.EraScore ~= nil and moment.EraScore > 0 and momentInfo ~= nil and ( moment.ActingPlayer == localPlayerID or (bOptionIncludeOthers and momentInfo.Category == 1) ) then
			if momentInfo.Special == nil then
				ProcessHistoricMoment(momentInfo.MomentType, moment, momentInfo.Category, localPlayerID);
			else
				-- special moments
				if momentInfo.Special == "STRATEGIC" then
					local sExtra:string = RetrieveFromExtraData(moment, "MOMENT_DATA_RESOURCE"); -- extra data contains MOMENT_DATA_RESOURCE
					if sExtra ~= "" then
						ProcessHistoricMoment(sExtra.."_"..momentInfo.MomentType, moment, momentInfo.Category, localPlayerID);
					end
				end
				if momentInfo.Special == "ERA" then
					local sExtra:string = RetrieveFromExtraData(moment, "MOMENT_DATA_PLAYER_ERA"); -- extra data contains MOMENT_DATA_PLAYER_ERA
					if sExtra ~= "" then
						ProcessHistoricMoment(sExtra.."_"..momentInfo.MomentType, moment, momentInfo.Category, localPlayerID);
					end
				end
				if momentInfo.Special == "UNIQUE" then
					local sType:string = "(error)";
					if     momentInfo.MomentIllustrationType == "MOMENT_ILLUSTRATION_UNIQUE_BUILDING"    then sType = "MOMENT_DATA_BUILDING";
					elseif momentInfo.MomentIllustrationType == "MOMENT_ILLUSTRATION_UNIQUE_DISTRICT"    then sType = "MOMENT_DATA_DISTRICT";
					elseif momentInfo.MomentIllustrationType == "MOMENT_ILLUSTRATION_UNIQUE_IMPROVEMENT" then sType = "MOMENT_DATA_IMPROVEMENT";
					elseif momentInfo.MomentIllustrationType == "MOMENT_ILLUSTRATION_UNIQUE_UNIT"        then sType = "MOMENT_DATA_UNIT"; end
					local sExtra:string = RetrieveFromExtraData(moment, sType);
					if sExtra ~= "" then
						ProcessHistoricMoment(sExtra.."_"..momentInfo.MomentType, moment, momentInfo.Category, localPlayerID);
					end
				end
				--print("*** special moment data ***"); dshowrectable(moment);
			end
		end
	end
end


-- ===========================================================================
-- MOMENTS PAGE
--.ID	310
--.Type	-77408354  => Hash for GameInfo.Moments[]
--.InstanceDescription	The discovery of Apprenticeship by Korea sets the world stage for future discoveries in the Medieval Era!
--.ActingPlayer	0
--.EraScore	2
--.GameEra	1
--.Turn	101
--.HasEverBeenCommemorated	false => seems to be false always
--.ActionPlotX	-9999
--.ActionPlotY	-9999
--.ExtraData	table: 000000006221F3C0 => (ipairs) table of { .DataType and .DataValue }
-- ===========================================================================

-- fills a single instance with the data of the moment
function ShowMoment(pMoment:table, pInstance:table)
	--print("FUN ShowMoment", pMoment.MomentType);
	
	-- favored
	pInstance.Favored:SetSelected( pMoment.Favored );
	pInstance.Favored:RegisterCallback( Mouse.eLClick, function() pMoment.Favored = not pMoment.Favored; ViewMomentsPage(); end );
	-- category, era score
	if     pMoment.Category == 1 then pInstance.Group:SetText("[ICON_CapitalLarge]"); pInstance.Group:SetOffsetY(10);
	elseif pMoment.Category == 2 then pInstance.Group:SetText("[ICON_Capital]");      pInstance.Group:SetOffsetY(7);
	else                              pInstance.Group:SetText("[ICON_Army]");         pInstance.Group:SetOffsetY(8); end
	-- score
	local iScore:number = pMoment.EraScore;
	if m_bIsTajMahal and iScore >= 2 then iScore = iScore + 1; end
	pInstance.EraScore:SetText("[COLOR_White]"..tostring(iScore)..ENDCOLOR);
	-- description
	local isTruncated:boolean = TruncateString(pInstance.Description, 305, pMoment.Description);
	if isTruncated then pInstance.Description:SetToolTipString( pMoment.Description..NEWLINE..pMoment.LongDesc );
	else                pInstance.Description:SetToolTipString( pMoment.LongDesc ); end
	-- object & valid for
	isTruncated = TruncateString(pInstance.Object, 155, pMoment.Object);
	local sStatusTT:string = "";
	if isTruncated then sStatusTT = pMoment.Object; end
	if pMoment.ValidFor ~= "" then
		if sStatusTT ~= "" then sStatusTT = sStatusTT..NEWLINE; end
		if     GameInfo.Civilizations[pMoment.ValidFor] ~= nil then sStatusTT = sStatusTT..LL(GameInfo.Civilizations[pMoment.ValidFor].Name);
		elseif GameInfo.Leaders[pMoment.ValidFor]       ~= nil then sStatusTT = sStatusTT..LL(GameInfo.Leaders[pMoment.ValidFor].Name);
		else                                                        sStatusTT = sStatusTT..pMoment.ValidFor; end
	end
	pInstance.Object:SetToolTipString(sStatusTT);
	-- status and tooltips
	if     pMoment.Status == 0 then pInstance.Status:SetText("[ICON_Bullet]");        pInstance.Status:SetOffsetY(0);
	elseif pMoment.Status == 1 then pInstance.Status:SetText("[ICON_CheckmarkBlue]"); pInstance.Status:SetOffsetY(0);
	else                            pInstance.Status:SetText("[ICON_Not]");           pInstance.Status:SetOffsetY(4); end
	pInstance.Status:SetToolTipString("");
	if #pMoment.TT > 0 then pInstance.Status:SetToolTipString(table.concat(pMoment.TT, NEWLINE)); end
	-- turn, count, player
	pInstance.Turn:SetText(tostring(pMoment.Turn));
	pInstance.Count:SetText(tostring(pMoment.Count));
	pInstance.Player:SetText(pMoment.Player);
	-- era info
	pInstance.Eras:SetText("");
	if pMoment.MinEra ~= nil or pMoment.MaxEra ~= nil then
		pInstance.Eras:SetText("[ICON_Turn]");
		local sEras:string = " [ICON_GoingTo] ";
		if pMoment.MinEra ~= nil then sEras = LL(GameInfo.Eras[pMoment.MinEra].Name)..sEras; end
		if pMoment.MaxEra ~= nil then sEras = sEras..LL(GameInfo.Eras[pMoment.MaxEra].Name); end
		pInstance.Eras:SetToolTipString(sEras);
	end
	-- debug extra tooltip
	pInstance.Extra:SetText("---");
	local tTT:table = {};
	for k,v in pairs(pMoment) do
		table.insert(tTT, tostring(k)..": "..tostring(v));
	end
	-- ExtraData (ipairs) table of { .DataType and .DataValue }
	for i,extra in ipairs(pMoment.ExtraData) do
		if GameInfo.Types[extra.DataType] == nil then
			table.insert(tTT, string.format("[%d] %s", i, tostring(extra.DataType)));
		else
			table.insert(tTT, string.format("[%d] %s", i, GameInfo.Types[extra.DataType].Type));
		end
		table.insert(tTT, string.format("[%d] %s", i, tostring(extra.DataValue)));
	end
	pInstance.Extra:SetToolTipString(table.concat(tTT, NEWLINE));
end

-- sort function
function MomentsSortFunction(t, a, b)
	-- favored always first
	if t[a].Favored ~= t[b].Favored then
		return t[a].Favored;
	end
	-- favored are either both true or both false
	if t[a].EraScore == t[b].EraScore then
		-- sort by descripion
		if t[a].Description == t[b].Description then
			return t[a].Object < t[b].Object;
		end
		return t[a].Description < t[b].Description;
	end
	return t[a].EraScore > t[b].EraScore;
end

-- main function
function ViewMomentsPage(eGroup:number)
	--print("FUN ViewMomentsPage", eGroup);
	if eGroup == nil then eGroup = m_kCurrentTab; end
	-- Remember this tab when report is next opened
	m_kCurrentTab = eGroup;
	
	ResetTabForNewPageContent();
	local instance:table = m_simpleIM:GetInstance();
	instance.Top:DestroyAllChildren();
	--instance.Children = {}
	--instance.Descend = true;
	local pHeaderInstance:table = {};
	ContextPtr:BuildInstanceForControl( "CityStatus2HeaderInstance", pHeaderInstance, instance.Top );

	-- civ and leader for uniques
	local localPlayerID:number = Game.GetLocalPlayer();
	if localPlayerID == -1 then return; end
	local sCivilization:string = PlayerConfigurations[localPlayerID]:GetCivilizationTypeName();
	local sLeader:string       = PlayerConfigurations[localPlayerID]:GetLeaderTypeName();
	
	-- checkboxes
	local bEraScore1:boolean = Controls.EraScore1Checkbox:IsSelected();
	local bEraScore2:boolean = Controls.EraScore2Checkbox:IsSelected();
	local bEraScore3:boolean = Controls.EraScore3Checkbox:IsSelected();
	local bEraScore4:boolean = Controls.EraScore4Checkbox:IsSelected();
	local bHideNotActive:boolean    = Controls.HideNotActiveCheckbox:IsSelected();
	local bShowOnlyEarned:boolean   = Controls.ShowOnlyEarnedCheckbox:IsSelected();
	local bHideNotAvailable:boolean = Controls.HideNotAvailableCheckbox:IsSelected();

	-- filter out loop
	local tShow:table = {};
	local iCurrentEra:number = Game.GetEras():GetCurrentEra();
	local tSaveData:table = {}; -- save current favored moments
	for key,moment in pairs(m_kMoments) do
		--print("...filtering key", key);
		-- filters
		local bShow:boolean = true;
		-- harcoded
		if moment.EraScore == nil or moment.EraScore == 0 then bShow = false; end
		if moment.ValidFor ~= nil and moment.ValidFor ~= "" then
			if not( moment.ValidFor == sCivilization or moment.ValidFor == sLeader ) then bShow = false; end
		end
		if eGroup == 4 then
			if not moment.Favored then bShow = false; end
		else
			if moment.Category ~= eGroup then bShow = false; end
		end
		
		if not moment.Favored then -- favored are ALWAYS shown
		
			-- checkboxes
			if moment.EraScore == 1 and not bEraScore1 then bShow = false; end
			if moment.EraScore == 2 and not bEraScore2 then bShow = false; end
			if moment.EraScore == 3 and not bEraScore3 then bShow = false; end
			if moment.EraScore >= 4 and not bEraScore4 then bShow = false; end
			if bHideNotActive  and moment.Status ~= 0 then bShow = false; end
			if bShowOnlyEarned and moment.Status ~= 1 then bShow = false; end
			-- available & eras
			local iMinEra:number, iMaxEra:number = 0, m_iMaxEraIndex;
			if moment.MinEra ~= nil then iMinEra = GameInfo.Eras[moment.MinEra].Index; end
			if moment.MaxEra ~= nil then iMaxEra = GameInfo.Eras[moment.MaxEra].Index; end
			if bHideNotAvailable and (iCurrentEra < iMinEra or iCurrentEra > iMaxEra) then bShow = false; end
		
		end -- not favored
		
		-- 230416 search feature
		if _SearchQuery ~= nil and string.find(moment.Description, _SearchQuery) == nil then
			bShow = false;
		end
		
		if bShow then table.insert(tShow, moment); end
		if moment.Favored then table.insert(tSaveData, key); end
	end
	
	-- show loop
	--print("...filtering done, before show");
	for _,moment in spairs(tShow, MomentsSortFunction) do
		local pMomentInstance:table = {};
		ContextPtr:BuildInstanceForControl( "MomentEntryInstance", pMomentInstance, instance.Top );
		--table.insert( instance.Children, pMomentInstance );
		ShowMoment( moment, pMomentInstance );
	end
	--print("...show loop completed");

	Controls.Stack:CalculateSize();
	Controls.Scroll:CalculateSize();
	Controls.Scroll:SetSizeY( Controls.Main:GetSizeY() - (Controls.BottomFilters:GetSizeY() + SIZE_HEIGHT_PADDING_BOTTOM_ADJUST ) );
	
	-- save current favored moments
	SaveDataToPlayerSlot(localPlayerID, "RETFavoredMoments", tSaveData);
end


-- ===========================================================================
--
-- ===========================================================================
function AddTabSection( name:string, populateCallback:ifunction )
	local kTab:table = m_tabIM:GetInstance();
	kTab.Button[DATA_FIELD_SELECTION] = kTab.Selection;

	local callback:ifunction = function()
		if m_tabs.prevSelectedControl ~= nil then
			m_tabs.prevSelectedControl[DATA_FIELD_SELECTION]:SetHide(true);
		end
		kTab.Selection:SetHide(false);
		populateCallback();
	end

	kTab.Button:GetTextControl():SetText( Locale.Lookup(name) );
	kTab.Button:SetSizeToText( 40, 20 ); -- default 40,20
    kTab.Button:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);

	m_tabs.AddTab( kTab.Button, callback );
end


-- ===========================================================================
--	UI Callback
-- ===========================================================================
function OnInputHandler( pInputStruct:table )
	local uiMsg :number = pInputStruct:GetMessageType();
	if uiMsg == KeyEvents.KeyUp then 
		local uiKey = pInputStruct:GetKey();
		if uiKey == Keys.VK_ESCAPE then
			if ContextPtr:IsHidden()==false then
				Close();
				return true;
			end
		end		
	end
	return false;
end


-- ===========================================================================
function Resize()
	local topPanelSizeY:number = 30;
	x,y = UIManager:GetScreenSizeVal();
	Controls.Main:SetSizeY( y - topPanelSizeY );
	Controls.Main:SetOffsetY( topPanelSizeY * 0.5 );
end


-- ===========================================================================
--	Game Event Callback
-- ===========================================================================
function OnLocalPlayerTurnEnd()
	if(GameConfiguration.IsHotseat()) then
		OnCloseButton();
	end
end


-- ===========================================================================
-- SAVING/LOADING PERSISTENT DATA
-- ===========================================================================

------------------------------------------------------------------------------
-- Save player and game related data into Game and Player Values
-- Serialize values using serialize()

function SaveDataToGameSlot(sSlotName:string, data)
	--print("FUN SaveDataToGameSlot() (slot,type)", sSlotName, type(data));
	--dshowrectable(data);
	local sData = serialize(data);
	--print("-->>", sData);
	GameConfiguration.SetValue(sSlotName, sData);
	--local sCheck:string = GameConfiguration.GetValue(sSlotName);
	--print("check:", sCheck == sData);
end

function SaveDataToPlayerSlot(ePlayerID:number, sSlotName:string, data)
	--print("FUN SaveDataToPlayerSlot (pid,slot,type)", ePlayerID, sSlotName, type(data));
	--dshowrectable(data);
	local sData = serialize(data);
	--print("-->>", sData);
	PlayerConfigurations[ePlayerID]:SetValue(sSlotName, sData);
	--local sCheck:string = PlayerConfigurations[ePlayerID]:GetValue(sSlotName);
	--print("check:", sCheck == sData);
end


------------------------------------------------------------------------------
-- Load persistent data (careful - it is BEFORE OnLoadScreenClose)
-- Deserialize values using loadstring()

function LoadDataFromGameSlot(sSlotName:string)
	--print("FUN LoadDataFromGameSlot() (slot)", sSlotName);
	local sData:string = GameConfiguration.GetValue(sSlotName);
	--print("<<--", sData);
	if sData == nil then print("WARNING: LoadDataFromGameSlot no data in slot", sSlotName); return nil; end
	local tTable = loadstring(sData)();
	--dshowrectable(tTable);
	return tTable;
end

function LoadDataFromPlayerSlot(ePlayerID:number, sSlotName:string)
	--print("FUN LoadDataFromPlayerSlot() (pid,slot)", ePlayerID, sSlotName);
	local sData:string = PlayerConfigurations[ePlayerID]:GetValue(sSlotName);
	--print("<<--", sData);
	if sData == nil then print("WARNING: LoadDataFromPlayerSlot no data in slot", sSlotName, "for player", ePlayerID); return nil; end
	local tTable = loadstring(sData)();
	--dshowrectable(tTable);
	return tTable;
end


-- this event is called ONLY when loading a save file
function OnLoadComplete()
	--print("FUN OnLoadComplete");
	-- get favored moments from a save file
	--print("--- LOADING FAVORED MOMENTS ---");
	--for _,playerID in ipairs(PlayerManager.GetAliveIDs()) do
		local data:table = LoadDataFromPlayerSlot(Game.GetLocalPlayer(), "RETFavoredMoments");
		if data ~= nil then -- but make sure we really loaded the data
			for _,key in ipairs(data) do
				if m_kMoments[key] then m_kMoments[key].Favored = true; end
			end
		end
	--end
	--print("--- END LOADING FAVORED ---");
end


-- ===========================================================================
function LateInitialize()
	InitializeMomentsData();
	--Resize();
	m_tabs = CreateTabs( Controls.TabContainer, 42, 34, 0xFF331D05 );
	AddTabSection( "LOC_RET_WORLD",	                      function() ViewMomentsPage(1); end );
	AddTabSection( "LOC_HUD_REPORTS_HEADER_CIVILIZATION", function() ViewMomentsPage(2); end );
	AddTabSection( "LOC_RET_REPEATABLE",                  function() ViewMomentsPage(3); end );
	AddTabSection( "LOC_RET_FAVORED",	                  function() ViewMomentsPage(4); end );
	m_tabs.SameSizedTabs(20);
	m_tabs.CenterAlignTabs(-10);
end


-- ===========================================================================
--	UI Event
-- ===========================================================================
function OnInit( isReload:boolean )
	LateInitialize();
	if isReload then		
		if ContextPtr:IsHidden() == false then
			Open();
		end
	end
	m_tabs.AddAnimDeco(Controls.TabAnim, Controls.TabArrow);	
end


-- ===========================================================================
-- CHECKBOXES
-- ===========================================================================

function OnToggleEraScore1Checkbox()
	local isChecked = Controls.EraScore1Checkbox:IsSelected();
	Controls.EraScore1Checkbox:SetSelected( not isChecked );
	ViewMomentsPage();
end

function OnToggleEraScore2Checkbox()
	local isChecked = Controls.EraScore2Checkbox:IsSelected();
	Controls.EraScore2Checkbox:SetSelected( not isChecked );
	ViewMomentsPage();
end

function OnToggleEraScore3Checkbox()
	local isChecked = Controls.EraScore3Checkbox:IsSelected();
	Controls.EraScore3Checkbox:SetSelected( not isChecked );
	ViewMomentsPage();
end

function OnToggleEraScore4Checkbox()
	local isChecked = Controls.EraScore4Checkbox:IsSelected();
	Controls.EraScore4Checkbox:SetSelected( not isChecked );
	ViewMomentsPage();
end

function OnToggleHideNotActiveCheckbox()
	local isChecked = Controls.HideNotActiveCheckbox:IsSelected();
	Controls.HideNotActiveCheckbox:SetSelected( not isChecked );
	if not isChecked then Controls.ShowOnlyEarnedCheckbox:SetSelected( isChecked ); end
	ViewMomentsPage();
end

function OnToggleShowOnlyEarnedCheckbox()
	local isChecked = Controls.ShowOnlyEarnedCheckbox:IsSelected();
	Controls.ShowOnlyEarnedCheckbox:SetSelected( not isChecked );
	if not isChecked then Controls.HideNotActiveCheckbox:SetSelected( isChecked ); end
	ViewMomentsPage();
end

function OnToggleHideNotAvailableCheckbox()
	local isChecked = Controls.HideNotAvailableCheckbox:IsSelected();
	Controls.HideNotAvailableCheckbox:SetSelected( not isChecked );
	ViewMomentsPage();
end

-- ===========================================================================
-- 230416 Search feature
-- ===========================================================================

-- https://www.lua.org/pil/20.4.html
function nocase(s)
	return string.gsub(s, "%a",
		function (c)
			return string.format("[%s%s]", string.lower(c), string.upper(c))
		end)
end

function OnSearchBarGainFocus()
	Controls.SearchEditBox:ClearString();
	if _SearchQuery then
		_SearchQuery = nil;
		ViewMomentsPage();
	end
end

function OnSearchBarLostFocus()
	if Controls.SearchEditBox:GetText() == nil then
		Controls.SearchEditBox:SetText(LOC_TREE_SEARCH_W_DOTS);
		if _SearchQuery then
			_SearchQuery = nil;
			ViewMomentsPage();
		end
	end
end

function OnSearchCharCallback()
	local str:string = Controls.SearchEditBox:GetText();
	if str ~= nil and #str > 0 and str ~= LOC_TREE_SEARCH_W_DOTS then
		local newSearch:string = nocase(str);
		if newSearch ~= _SearchQuery then
			_SearchQuery = newSearch;
			ViewMomentsPage();
		end
	end
end

-- ===========================================================================
function Initialize()
	-- UI Callbacks
	ContextPtr:SetInitHandler( OnInit );
	ContextPtr:SetInputHandler( OnInputHandler, true );
	Controls.CloseButton:RegisterCallback( Mouse.eLClick, OnCloseButton );
	Controls.CloseButton:RegisterCallback(	Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	-- Filters
	Controls.EraScore1Checkbox:RegisterCallback( Mouse.eLClick, OnToggleEraScore1Checkbox );
	Controls.EraScore1Checkbox:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end );
	Controls.EraScore1Checkbox:SetSelected( true );
	Controls.EraScore2Checkbox:RegisterCallback( Mouse.eLClick, OnToggleEraScore2Checkbox );
	Controls.EraScore2Checkbox:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end );
	Controls.EraScore2Checkbox:SetSelected( true );
	Controls.EraScore3Checkbox:RegisterCallback( Mouse.eLClick, OnToggleEraScore3Checkbox );
	Controls.EraScore3Checkbox:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end );
	Controls.EraScore3Checkbox:SetSelected( true );
	Controls.EraScore4Checkbox:RegisterCallback( Mouse.eLClick, OnToggleEraScore4Checkbox );
	Controls.EraScore4Checkbox:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end );
	Controls.EraScore4Checkbox:SetSelected( true );
	Controls.HideNotActiveCheckbox:RegisterCallback( Mouse.eLClick, OnToggleHideNotActiveCheckbox );
	Controls.HideNotActiveCheckbox:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end );
	Controls.HideNotActiveCheckbox:SetSelected( true );
	Controls.ShowOnlyEarnedCheckbox:RegisterCallback( Mouse.eLClick, OnToggleShowOnlyEarnedCheckbox );
	Controls.ShowOnlyEarnedCheckbox:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end );
	Controls.ShowOnlyEarnedCheckbox:SetSelected( false );
	Controls.HideNotAvailableCheckbox:RegisterCallback( Mouse.eLClick, OnToggleHideNotAvailableCheckbox );
	Controls.HideNotAvailableCheckbox:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end );
	Controls.HideNotAvailableCheckbox:SetSelected( true );
	-- 230416 Search feature
	Controls.SearchEditBox:RegisterStringChangedCallback(OnSearchCharCallback);
	Controls.SearchEditBox:RegisterHasFocusCallback(OnSearchBarGainFocus);
	Controls.SearchEditBox:RegisterLostFocusCallback(OnSearchBarLostFocus);
	-- Events
	LuaEvents.ReportsList_OpenEraTracker.Add( function() Open(); end );
	Events.LocalPlayerTurnEnd.Add( OnLocalPlayerTurnEnd );
	-- loading persistent data
	Events.LoadComplete.Add( OnLoadComplete ); -- fires ONLY when loading a game from a save file, when it's ready to start (i.e. circle button appears)
end
if bIsRiseAndFall or bIsGatheringStorm then
	Initialize();
end

print("OK loaded RealEraTracker.lua from Real Era Tracker");