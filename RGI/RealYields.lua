print("Loading Real Yields.lua v1.0");
-- ===========================================================================
-- Real Yields
-- This file is bo to used via 'include' statement.
-- Author: Infixo
-- 2020-06-04: Created, v1.0
-- ===========================================================================


-- ===========================================================================
-- DEBUG ROUTINES
-- ===========================================================================

-- debug output routine
function dprint(sStr,p1,p2,p3,p4,p5,p6)
	local sOutStr = sStr;
	if p1 ~= nil then sOutStr = sOutStr.." [1] "..tostring(p1); end
	if p2 ~= nil then sOutStr = sOutStr.." [2] "..tostring(p2); end
	if p3 ~= nil then sOutStr = sOutStr.." [3] "..tostring(p3); end
	if p4 ~= nil then sOutStr = sOutStr.." [4] "..tostring(p4); end
	if p5 ~= nil then sOutStr = sOutStr.." [5] "..tostring(p5); end
	if p6 ~= nil then sOutStr = sOutStr.." [6] "..tostring(p6); end
	print(sOutStr);
end

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

-- debug routine - prints extended yields table in a compacted form (1 line, formatted)
function dshowyields(pYields:table)
	local tOut:table = {}; table.insert(tOut, "  yields :");
	for yield,value in pairs(pYields) do table.insert(tOut, string.format("%s %5.2f :", yield, value)); end
	print(table.concat(tOut, " "));
end


-- ===========================================================================
-- EXTENDED YIELDS
-- extended yields to support other effects, like Amenities, Tourism, etc.
-- ===========================================================================

-- YieldTypes 0..5 are for FOOD, PRODUCTION, GOLD, SCIENCE, CULTURE and FAITH.
-- They correspond to respective YIELD_ type in the Yields table.
YieldTypes.TOURISM =  6;
YieldTypes.AMENITY =  7;
YieldTypes.HOUSING =  8;
YieldTypes.LOYALTY =  9;
YieldTypes.POWER   = 10;
--YieldTypes.GPPOINT =  9 -- Great Person Point
--YieldTypes.ENVOY   = 10
--YieldTypes.APPEAL  = 11
-- whereever possible keep yields in a table named Yields with entries { YieldType = YieldValue }

-- create maps (speed up)
local YieldTypesMap = {};
for yield in GameInfo.Yields() do
	YieldTypesMap[ yield.YieldType ] = string.gsub(yield.YieldType, "YIELD_","");
end
local YieldTypesOrder = {};
for yield,yid in pairs(YieldTypes) do
	YieldTypesOrder[yid] = yield;
end 
--dshowtable(YieldTypes);
--dshowtable(YieldTypesMap);
--dshowtable(YieldTypesOrder);
--for yid,yield in ipairs(YieldTypesOrder) do dprint("YieldTypesOrder", yid, yield) end

-- get a new table with all 0
function YieldTableNew()
	local tNew:table = {};
	for yield,_ in pairs(YieldTypes) do tNew[ yield ] = 0; end
	return tNew;
end

-- set all values to x
function YieldTableSet(pYields:table, fValue:number)
	for yield,_ in pairs(YieldTypes) do pYields[ yield ] = fValue; end
end

-- add two tables
function YieldTableAdd(pYields:table, pYieldsToAdd:table)
	for yield,_ in pairs(YieldTypes) do pYields[ yield ] = pYields[ yield ] + pYieldsToAdd[ yield ]; end
end

-- multiply by a given number
function YieldTableMultiply(pYields:table, fModifier:number)
	for yield,_ in pairs(YieldTypes) do pYields[ yield ] = pYields[ yield ] * fModifier; end
end

-- multiply by a percentage given as integer 0..100
function YieldTablePercent(pYields:table, iPercent:number)
	return YieldTableMultiply(pYields, iPercent/100.0);
end

-- get a specific yield, takes both YieldTypes and "YIELD_XXX" form
function YieldTableGetYield(pYields:table, sYield:string)
	if YieldTypesMap[ sYield ] then return pYields[ YieldTypesMap[ sYield ] ];
	else                            return pYields[ sYield ];                  end
end

-- set a specific yield, takes both YieldTypes and "YIELD_XXX" form
function YieldTableSetYield(pYields:table, sYield:string, fValue:number)
	if YieldTypesMap[ sYield ] then pYields[ YieldTypesMap[ sYield ] ] = fValue;
	else                            pYields[ sYield ] = fValue;                  end
end

-- returns a compacted string with yields info
function YieldTableGetInfo(pYields:table)
	local sYieldInfo:string = "";
	for	_,yield in ipairs(YieldTypesOrder) do
		if pYields[yield] ~= 0 then sYieldInfo = sYieldInfo..(sYieldInfo == "" and "" or " ")..GetYieldString("YIELD_"..yield, pYields[yield]); end
	end
	return sYieldInfo;
end

-- 2019-06-20 GS introduced multiple yields in one modifier, separated with comma
function YieldTableSetMultipleYields(pYields:table, sYields:string, sValues:string)
	sYields = sYields..",";	sValues = sValues..",";
	while string.len(sYields) > 0 and string.len(sValues) > 0 do
		local iCommaYields:number = string.find(sYields, ",");
		local iCommaValues:number = string.find(sValues, ",");
		--print("YieldTableSetMultipleYields", sYields, iCommaYields, sValues, iCommaValues);
		YieldTableSetYield(pYields, string.sub(sYields, 1, iCommaYields-1), tonumber(string.sub(sValues, 1, iCommaValues-1)));
		-- remove processed yield
		sYields = string.sub(sYields, iCommaYields+1);
		sValues = string.sub(sValues, iCommaValues+1);
	end
end


-- ===========================================================================
-- GENERIC FUNCTIONS AND HELPERS
-- ===========================================================================

function GetGameInfoIndex(sTableName:string, sTypeName:string) 
	local tTable = GameInfo[sTableName];
	if tTable then
		local row = tTable[sTypeName];
		if row then return row.Index
		else        return -1;        end
	end
	return -1;
end

-- check if 'value' exists in table 'pTable'; should work for any type of 'value' and table indices
function IsInTable(pTable:table, value)
	for _,data in pairs(pTable) do
		if data == value then return true; end
	end
	return false;
end

-- returns 'key' at which a given 'value' is stored in table 'pTable'; nil if not found; should work for any type of 'value' and table indices
function GetTableKey(pTable:table, value)
	for key,data in pairs(pTable) do
		if data == value then return key; end
	end
	return nil;
end


-- ===========================================================================
-- Couple of functions from Civ6Common that need to be updated
-- ===========================================================================

-- ===========================================================================
--	Return the inline text-icon for a given yield
--	yieldType	A database YIELD_TYPE
--	returns		The [ICON_yield] string
-- ===========================================================================
function GetYieldTextIcon( yieldType:string )
	local  iconString:string = "";
	if     yieldType == nil or yieldType == ""	then
		iconString = "Error:NIL";
	-- process native yields as first
	elseif GameInfo.Yields[yieldType] ~= nil and GameInfo.Yields[yieldType].IconString ~= nil and GameInfo.Yields[yieldType].IconString ~= "" then
		iconString = GameInfo.Yields[yieldType].IconString;
	elseif yieldType == "YIELD_TOURISM" then
		iconString = "[ICON_Tourism]";
	elseif yieldType == "YIELD_AMENITY" then
		iconString = "[ICON_Amenities]"; -- [ICON_Therefore] a green arrow pointing to the right
	elseif yieldType == "YIELD_HOUSING" then
		iconString = "[ICON_Housing]"; -- [ICON_LocationPip] a blue pin pointing down
	elseif yieldType == "YIELD_LOYALTY" then
		iconString = "[ICON_PressureUp]"; -- [ICON_PressureDown] is a red arrow pointing down
	elseif yieldType == "YIELD_POWER" then
		iconString = "[ICON_Power]";
	else
		iconString = "Unknown:"..yieldType; 
	end			
	return iconString;
end

-- ===========================================================================
--	Return the inline entry for a yield's color
-- ===========================================================================
function GetYieldTextColor( yieldType:string )
	if     yieldType == nil or yieldType == "" then return "[COLOR:255,255,255,255]NIL ";
	elseif yieldType == "YIELD_FOOD"		   then return "[COLOR:ResFoodLabelCS]";
	elseif yieldType == "YIELD_PRODUCTION"	   then return "[COLOR:ResProductionLabelCS]";
	elseif yieldType == "YIELD_GOLD"		   then return "[COLOR:ResGoldLabelCS]";
	elseif yieldType == "YIELD_SCIENCE"		   then return "[COLOR:ResScienceLabelCS]";
	elseif yieldType == "YIELD_CULTURE"		   then return "[COLOR:ResCultureLabelCS]";
	elseif yieldType == "YIELD_FAITH"		   then return "[COLOR:ResFaithLabelCS]";
	elseif yieldType == "YIELD_TOURISM"		   then return "[COLOR:ResTourismLabelCS]";
	elseif yieldType == "YIELD_AMENITY"        then return "[COLOR_White]";
	elseif yieldType == "YIELD_HOUSING"        then return "[COLOR_White]";
	elseif yieldType == "YIELD_LOYALTY"        then return "[COLOR_White]";
	elseif yieldType == "YIELD_POWER"          then return "[COLOR_White]";
	else											return "[COLOR:255,255,255,0]ERROR ";
	end				
end

-- ===========================================================================
-- Updated functions from Civ6Common, to include rounding to 1 decimal digit
-- ===========================================================================
function toPlusMinusString( value:number )
	if value == 0 then return "0"; end
	--return Locale.ToNumber(value, "+#,###.#;-#,###.#");
	return Locale.ToNumber(math.floor((value*10)+0.5)/10, "+#,###.#;-#,###.#");
end

function toPlusMinusNoneString( value:number )
	if value == 0 then return " "; end
	--return Locale.ToNumber(value, "+#,###.#;-#,###.#");
	return Locale.ToNumber(math.floor((value*10)+0.5)/10, "+#,###.#;-#,###.#");
end

-- ===========================================================================
--	Return a string with a yield icon and a +/- based on yield amount.
-- ===========================================================================
function GetYieldString( yieldType:string, amount:number )
	return GetYieldTextIcon(yieldType)..GetYieldTextColor(yieldType)..toPlusMinusString(amount).."[ENDCOLOR]";
end
