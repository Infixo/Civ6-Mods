print("Loading CivicsTreeIconLoader_BTT.lua from Better Tech Tree version 1.0");
-- ===========================================================================
-- Better Tech Tree
-- Author: Infixo
-- 2018-03-19: Created
-- ===========================================================================

include("InstanceManager");
include("CivicUnlockIcon");


g_ExtraIconData["MODIFIER_PLAYER_GRANT_SPY"] = {
	IM = InstanceManager:new( "CivicUnlockNumberedInstance", "Top"),
	
	Initialize = function(self:table, rootControl:table, itemData:table)
			local instance = CivicUnlockIcon.GetInstance(self.IM, rootControl);
			local numValue = tonumber(itemData.ModifierValue);
			instance:UpdateNumberedIcon(
				numValue,
				"[ICON_Citizen]",
				Locale.Lookup("LOC_NOTIFICATION_SPY_NEW_AGENT_MESSAGE"),
				itemData.Callback);
		end,

	Reset = function(self)
			self.IM:ResetInstances();
		end
};


-- ugly workaround, there's also Arena for +1T!
local tWalls:table = {
	[1] = "WALLS",
	[2] = "CASTLE",
	[3] = "STAR_FORT",
};

g_ExtraIconData["MODIFIER_PLAYER_DISTRICTS_ADJUST_TOURISM_CHANGE"] = {
	IM = InstanceManager:new( "CivicUnlockNumberedInstance", "Top"),
	
	Initialize = function(self:table, rootControl:table, itemData:table)
			local instance = CivicUnlockIcon.GetInstance(self.IM, rootControl);
			local numValue = tonumber(itemData.ModifierValue);
			instance:UpdateNumberedIcon(
				numValue,
				"[ICON_Tourism]",
				Locale.Lookup("LOC_BUILDING_"..tWalls[numValue].."_NAME")..string.format(" %+d [ICON_Tourism]", numValue),
				itemData.Callback);
		end,

	Reset = function(self)
			self.IM:ResetInstances();
		end
};

print("OK loaded CivicsTreeIconLoader_BTT.lua from Better Tech Tree");