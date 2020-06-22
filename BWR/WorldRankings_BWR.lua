print("Loading WorldRankings_BWR.lua from Better World Rankings version "..GlobalParameters.BWR_VERSION_MAJOR.."."..GlobalParameters.BWR_VERSION_MINOR);
-- ===========================================================================
-- Better World Rankings
-- Author: Infixo
-- 2020-06-22: Created
-- This file contains the actual mod changes. It is executed AFTER base / exp2 files have been executed
-- ===========================================================================

-- Cache base functions
BASE_GatherCultureData = GatherCultureData;
BASE_PopulateCultureInstance = PopulateCultureInstance;
BASE_ViewCulture = ViewCulture;


-- calculate tourism needed to attract one visiting tourist
local m_iTourismForOne:number = GlobalParameters.TOURISM_TOURISM_TO_MOVE_CITIZEN * PlayerManager.GetWasEverAliveMajorsCount();


-- ===========================================================================
-- Helpers

-- debug routine - prints a table (no recursion)
function dshowtable(tTable:table)
	for k,v in pairs(tTable) do
		print(k, type(v), tostring(v));
	end
end

-- debug routine - prints a table, and tables inside recursively (up to 5 levels)
function dshowrectable(tTable:table, iLevel:number)
	local level:number = 0;
	if iLevel ~= nil then level = iLevel; end
	for k,v in pairs(tTable) do
		print(string.rep("---:",level), k, type(v), tostring(v));
		if type(v) == "table" and level < 5 then dshowrectable(v, level+1); end
	end
end


-- ===========================================================================
-- CULTURE

function GatherCultureData()
	--print("FUN GatherCultureData()");
	-- gather the data
	local data:table = BASE_GatherCultureData();
	--dshowrectable(data); -- debug
	-- data is ipairs table of team records
	--   team record: TeamID, BestNumRequiredTourists, BestNumVisitingUs, PlayerData:table
	--   PlayerData is ipairs table of single plater data: PlayerID, TurnsTillCulturalVictory, NumVisitingUs, NumStaycationers, NumRequiredTourists

	-- add more data - iterate through all players and add more data
	local localPlayer:number = Game.GetLocalPlayer();
	local playerCulture:table = Players[localPlayer]:GetCulture();
	
	for _,teamData in ipairs(data) do
		--print("..team", teamData.TeamID);
		for _,playerData in ipairs(teamData.PlayerData) do
			local playerID:number = playerData.PlayerID;
			--print("....player", playerData.PlayerID);
			
			-- needed: is there TR, is open borders, tourism boost, etc.
			playerData.CulturePerTurn = Round(Players[playerID]:GetCulture():GetCultureYield(), 0);
			playerData.ToolTip = playerCulture:GetTouristsFromTooltip(playerID);
			playerData.TourismBoost = 0; -- percentage
			playerData.TradeRoute = false; -- is there a TR between us
			playerData.OpenBorders = Players[localPlayer]:GetDiplomacy():HasOpenBordersFrom(playerID); -- "you received open borders"
			playerData.TurnsTillNext = 999; -- turns till we attract the next visting tourist from this player

			--if playerData.CulturePerTurn >= 100 then playerData.CulturePerTurn = Round(playerData.CulturePerTurn, 0);
			--else                                     playerData.CulturePerTurn = Round(playerData.CulturePerTurn, 1); end
			
			-- Determine if toPlayer has a trade route with fromPlayer (modified code from TradeOverview.lua)
			local function CheckTradeRoute(fromPlayer:number, toPlayer:number)
				if Players[toPlayer] == nil then return false; end -- assert
				for _,city in Players[toPlayer]:GetCities():Members() do
					if city:GetTrade():HasTradeRouteFrom(fromPlayer) then return true; end
				end
				return false;
			end
			-- Note: this is a two-way bonus, it doesn't matter who sends the TR
			--print("......checking TR", localPlayer, playerID);
			playerData.TradeRoute = ( CheckTradeRoute(localPlayer, playerID) or CheckTradeRoute(playerID, localPlayer) );
			
			-- calculate tourism boost modifier
			-- unfortunately it is not available via a simple call, needs to be retrieved from the tooltip
			local sCurrentT:string, sLifetimeT:string = string.match(playerData.ToolTip, "([%d%.,]+)%D+([%d%.,]+)"); -- detects first 2 numbers, number may contain . or ,
			--print("....tourism string to player", playerID, sCurrentT, sLifetimeT);
			sCurrentT  = string.gsub(sCurrentT, "%D",""); -- remove all non-digits, it returns 2 values, so cannot use directly with tonumber()
			sLifetimeT = string.gsub(sLifetimeT,"%D","");
			local iCurrentT:number, iLifetimeT:number = tonumber(sCurrentT), tonumber(sLifetimeT);
			--print("....tourism number to player", playerID, iCurrentT, iLifetimeT);
			local iTotalT:number = Players[localPlayer]:GetStats():GetTourism();
			if iTotalT > 0 then
				playerData.TourismBoost = Round((iCurrentT - iTotalT) * 100 / iTotalT, 0);
			end
			
			-- turns till the next one
			if iCurrentT > 0 then
				local iTouristsFrom:number = playerCulture:GetTouristsFrom(playerID);
				playerData.TurnsTillNext = ( (iTouristsFrom+1) * m_iTourismForOne - iLifetimeT ) / iCurrentT;
				--print("....turns till next", iTouristsFrom, iLifetimeT, playerData.TurnsTillNext);
				playerData.TurnsTillNext = math.floor(playerData.TurnsTillNext) + 1;
			end
		end
	end
	
	return data;
end


-- playerData: PlayerID, TurnsTillCulturalVictory, NumVisitingUs, NumStaycationers, NumRequiredTourists
function PopulateCultureInstance(instance:table, playerData:table)
	--print("FUN PopulateCultureInstance()");
	--dshowrectable(playerData); -- debug
	BASE_PopulateCultureInstance(instance, playerData);
	
	-- better tooltip
	instance.VisitingUsTourists:SetToolTipString("");
	instance.VisitingUsIcon:SetToolTipString("");
	instance.VisitingUsContainer:SetToolTipString(playerData.ToolTip);
	
	-- new fields
	instance.CulturePerTurn:SetText( "[COLOR_Culture]"..tostring(playerData.CulturePerTurn).."[ENDCOLOR]" );
	instance.TradeRoute:SetText( playerData.TradeRoute and "[ICON_PROPOSE_TRADE]" or "[ICON_CheckFail]" );
	instance.OpenBorders:SetText( playerData.OpenBorders and "[ICON_OPEN_BORDERS]" or "[ICON_CheckFail]" );
	-- tourism boost
	if     playerData.TourismBoost == 0 then instance.TourismBoost:SetText("0%");
	elseif playerData.TourismBoost > 0  then instance.TourismBoost:SetText(string.format("[COLOR_GREEN]+%d%%[ENDCOLOR]", playerData.TourismBoost));
	else                                     instance.TourismBoost:SetText(string.format("[COLOR_RED]%d%%[ENDCOLOR]", playerData.TourismBoost));
	end
	-- turns till the next visiting tourist
	if playerData.TurnsTillNext ~= 999 then
		instance.TurnsTillNext:SetHide(false);
		instance.TurnsTillNext:SetText("[ICON_Turn]"..tostring(playerData.TurnsTillNext));
	else
		instance.TurnsTillNext:SetHide(true);
	end
end


function ViewCulture()
	--print("FUN ViewCulture");
	BASE_ViewCulture();
	
	-- new fields
	Controls.TourismForOne:SetText(Locale.Lookup("LOC_BWR_TOURISM_FOR_ONE", m_iTourismForOne));
end


-- ===========================================================================
-- SCORE

-- these categories will be shown by default, all that are not here will be shown as a tooltip
local tScoresMap:table = {
	CATEGORY_EMPIRE       = {"Score1", "[ICON_Citizen]"},
	CATEGORY_TECH         = {"Score2", "[ICON_Science]"},
	CATEGORY_CIVICS       = {"Score3", "[ICON_Culture]"},
	CATEGORY_GREAT_PEOPLE = {"Score4", "[ICON_GreatPerson]"},
	CATEGORY_RELIGION     = {"Score5", "[ICON_Religion]"},
	CATEGORY_WONDER       = {"Score6", "[ICON_Housing]"},
	CATEGORY_ERA_SCORE    = {"Score7", "[ICON_Turn]"},
};

-- overwrite fully so it functions as "always details"
function PopulateScoreInstance(instance:table, playerData:table)
	PopulatePlayerInstanceShared(instance, playerData.PlayerID);

	instance.Score:SetText(playerData.PlayerScore);

	ResizeLocalPlayerBorder(instance, 75 + 9); -- +SIZE_LOCAL_PLAYER_BORDER_PADDING but it is local

	local detailsText:string = "";
	for i, category in ipairs(playerData.Categories) do
		local categoryInfo:table = GameInfo.ScoringCategories[category.CategoryID];
		local sTT:string = Locale.Lookup(categoryInfo.Name) .. ": " .. category.CategoryScore;
		local tScoreRec:table = tScoresMap[ categoryInfo.CategoryType ];
		if tScoreRec ~= nil then
			-- display specific category
			instance[ tScoreRec[1] ]:SetText( tScoreRec[2]..tostring(category.CategoryScore) );
			instance[ tScoreRec[1] ]:SetToolTipString(sTT);
			instance[ tScoreRec[1] ]:SetHide(false);
		else
			-- all others go here
			if #detailsText > 0 then detailsText = detailsText.."[NEWLINE]"; end
			detailsText = detailsText..sTT;
		end
	end

	if #detailsText > 0 then
		instance.ScoreX:SetToolTipString(detailsText);
		instance.ScoreX:SetHide(false);
	else
		instance.ScoreX:SetHide(true);
	end
end


print("OK loaded WorldRankings_BWR.lua from Better World Rankings");