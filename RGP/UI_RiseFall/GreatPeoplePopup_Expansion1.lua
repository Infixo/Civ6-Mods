--[[
-- Created by Samuel Batista, Nov 21 2017
-- Copyright (c) Firaxis Games
--]]

-- ===========================================================================
-- Base File
-- ===========================================================================
include("GreatPeoplePopup");

-- ===========================================================================
-- CACHE BASE FUNCTIONS
-- ===========================================================================
BASE_GetPatronizeWithGoldTT = GetPatronizeWithGoldTT;
BASE_GetPatronizeWithFaithTT = GetPatronizeWithFaithTT;

-- ===========================================================================
-- OVERRIDE FUNCTIONS
-- ===========================================================================
function GetPatronizeWithGoldTT(kPerson)
	local localPlayer = Players[Game.GetLocalPlayer()];
	if (localPlayer:GetGreatPeoplePoints():IsNoPatronageWith(GameInfo.Yields["YIELD_GOLD"].Index)) then
		return Locale.Lookup("LOC_GREAT_PEOPLE_PATRONAGE_GOLD_OFF");
	end
	return BASE_GetPatronizeWithGoldTT(kPerson);
end

function GetPatronizeWithFaithTT(kPerson)
	local localPlayer = Players[Game.GetLocalPlayer()];
	if (localPlayer:GetGreatPeoplePoints():IsNoPatronageWith(GameInfo.Yields["YIELD_FAITH"].Index)) then
		return Locale.Lookup("LOC_GREAT_PEOPLE_PATRONAGE_FAITH_OFF");
	end
	return BASE_GetPatronizeWithFaithTT(kPerson);
end