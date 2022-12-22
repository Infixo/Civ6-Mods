print("Loading ClimateScreen.lua from Better Climate Screen version 1.2");
--	Copyright 2018, Firaxis Games
 
-- ===========================================================================
include("InstanceManager");
include("SupportFunctions");	--Round
include("TabSupport");
include("PopupDialog");
include("ModalScreen_PlayerYieldsHelper");	-- Resizing and top panel vis.
include("GameRandomEvents");
include("CivilizationIcon");

-- DLC check
local bIsGCM:boolean = Modding.IsModActive("9DE86512-DE1A-400D-8C0A-AB46EBBF76B9"); -- Gran Colombia & Maya
print("Gran Colombia & Maya:", (bIsGCM and "YES" or "no"));

-- ===========================================================================
--	DEBUG
-- ===========================================================================
debug_amt = 0;

-- ===========================================================================
--	CONSTANTS
-- ===========================================================================
local RELOAD_CACHE_ID	:string = "ClimateScreen"; -- Unique name for hotreload
local MAX_PHASES		:number = 7;		-- Maximum climate phases
local PLAYER_NO_ONE		:number = -1;		-- Signify no player (autoplay)

local NUCLEAR_ACCIDENT_EVENT_TYPE	:string = "NUCLEAR_ACCIDENT";
local CLIMATE_CHANGE_EVENT_TYPE		:string = "SEA_LEVEL";

local SEA_LEVEL_WAVE_OFFSET	:number = 15;

-- ===========================================================================
--	MEMBERS
-- ===========================================================================
local m_kResCO2IM				:table = InstanceManager:new( "ResourceCO2Instance", "Top", Controls.GlobalResStack ); -- CO2 emmission from resources (WORLD)
local m_kCivCO2IM				:table = InstanceManager:new( "CivCO2Instance", "Top", Controls.GlobalCivStack ); -- CO2 emmission from Civs (WORLD)
local m_kYourCO2IM				:table = InstanceManager:new( "ResourceCO2Instance", "Top", Controls.YourCO2Stack ); -- CO2 emmission from resources (YOU)
local m_kSliceIM				:table = InstanceManager:new( "PieChartSliceInstance", "Slice" );
local m_kAffectedCitiesIM		:table = InstanceManager:new( "CityInstance", "Top", Controls.CitiesStack );
local m_kEventRowInstance		:table = InstanceManager:new( "EventRowInstance", "Top", Controls.EventStack );
local m_kClimateChangeInstance	:table = InstanceManager:new( "ClimateChangeInstance", "Top", Controls.EventStack );

local m_tabs				:table;				-- Main tabs
local m_CO2tabs				:table;				-- CO2 contribtion tabs
local m_kGlobalPieSlices	:table = {};		-- holds pie slice instances created for the global pie charts
local m_playerID			:number = -1;
local m_worldAgeName		:string;
local m_RealismName			:string;
local m_currentTabName		:string;
local m_currentCO2TabName	:string;
local m_kBarSegments		:table = {};
local m_TopPanelHeight		:number = 0;		-- Used to push vignette below top panel
local m_firstSeaLevelEvent  :number = -1;
local m_currentSeaLevelEvent :number = -1;
local m_currentSeaLevelPhase :number = 0;
local m_CO2For1Phase        :number = 0; -- Infixo 2022-12-21
local m_prevTurnNum			:number = 0;
local m_prevTurnCO2			:number = 0;


-- ===========================================================================
--	FUNCTIONS
-- ===========================================================================

-- ===========================================================================
function Open( selectedTabName:string )	
	
	m_playerID = Game.GetLocalPlayer();		-- Get ID and leave if during autoplay
	if m_playerID == -1 then return end;	
	
	m_kSliceIM:ResetInstances();	-- Instance manager that generates pie chart slices.

	--m_CO2tabs.SelectTab( Controls.CO2ButtonByCivilization );
	
	UpdateClimateChangeEventsData();

	if selectedTabName=="Overview" or selectedTabName==nil then m_tabs.SelectTab( Controls.ButtonOverview ); end
	if selectedTabName=="CO2Levels" then m_tabs.SelectTab( Controls.ButtonCO2Levels ); end
	if selectedTabName=="EventHistory" then m_tabs.SelectTab( Controls.ButtonEventHistory ); end
	
	UI.PlaySound("UI_Screen_Open");

	-- From ModalScreen_PlayerYieldsHelper
	if not RefreshYields() then
		Controls.Vignette:SetSizeY(m_TopPanelHeight);
	end

	-- From Civ6_styles: FullScreenVignetteConsumer
	Controls.ScreenAnimIn:SetToBeginning();
	Controls.ScreenAnimIn:Play();

	LuaEvents.ClimateScreen_Opened();		-- Tell other UI's (e.g., LaunchBar) this is opened

	local kParameters = {};
	kParameters.RenderAtCurrentParent = true;
	kParameters.InputAtCurrentParent = true;
	kParameters.AlwaysVisibleInQueue = true;
	UIManager:QueuePopup(ContextPtr, PopupPriority.Low, kParameters);
end

-- ===========================================================================
--	Actual close function, asserts if already closed
-- ===========================================================================
function Close()
	if not ContextPtr:IsHidden() then
		UI.PlaySound("UI_Screen_Close");
		LuaEvents.ClimateScreen_Closed();		-- Tell other UI's (e.g., LaunchBar) this is closed
	end
		
	UIManager:DequeuePopup(ContextPtr);
end

-- ===========================================================================
--	LUA Event, Callback
--	Close this screen
-- ===========================================================================
function OnClose()
	if not ContextPtr:IsHidden() then
		Close();
	end
end

-- ===========================================================================
--	LUA Event
--	Explicit close (from partial screen hooks), part of closing everything,
-- ===========================================================================
function OnCloseAllExcept( contextToStayOpen:string )
	if contextToStayOpen == ContextPtr:GetID() then return; end
	Close();
end

-- ===========================================================================
function GetWorstCO2PlayerID()
	local CO2Total		:number = GameClimate.GetTotalCO2Footprint();
	local CO2TopPlayer	:number = PLAYER_NO_ONE;
	local worstCO2		:number = 0;

	if CO2Total > 0 then
		for _,pPlayer in ipairs(PlayerManager.GetAliveMajors()) do			
			local CO2:number = GameClimate.GetPlayerCO2Footprint( pPlayer:GetID(), false );
			if CO2 > worstCO2 then
				CO2TopPlayer = pPlayer:GetID();
				worstCO2 = CO2;
			end
		end
	end
	return CO2TopPlayer;
end

-- ===========================================================================
--	Assumes all tabs are made of two buttons, one for actual button state and 
--	one for holding onto a selected state (e.g., the current tab.)
--		Each tab has: "ButtonFoo" and in it a "SelectFoo"
-- ===========================================================================
function RealizeTabs( selectedTabName:string )
	
	m_currentTabName = selectedTabName;

	local kTabNames:table = {"Overview","CO2Levels","EventHistory" }

	Controls.SelectedOverview:SetHide( selectedTabName ~= "Overview" );
	Controls.ButtonOverview:SetSelected( selectedTabName == "Overview" );
	Controls.OverviewPane:SetHide( selectedTabName ~= "Overview" );

	Controls.SelectedCO2Levels:SetHide( selectedTabName ~= "CO2Levels"  );
	Controls.ButtonCO2Levels:SetSelected( selectedTabName == "CO2Levels"   );
	Controls.CO2LevelsPane:SetHide( selectedTabName ~= "CO2Levels" );

	Controls.SelectedEventHistory:SetHide( selectedTabName ~= "EventHistory"  );
	Controls.ButtonEventHistory:SetSelected( selectedTabName == "EventHistory"   );	
	Controls.EventHistoryPane:SetHide( selectedTabName ~= "EventHistory" );
end

-- ===========================================================================
--	Same as above but for CO2 sub-tabs
-- ===========================================================================
function RealizeCO2Tabs( selectedTabName:string )
	
	m_currentCO2TabName = selectedTabName;

	local kTabNames:table = {"ByCivilization","ByResource","Deforestation" }

	Controls.CO2SelectedByCivilization:SetHide( selectedTabName ~= "ByCivilization" );
	Controls.CO2ButtonByCivilization:SetSelected( selectedTabName == "ByCivilization" );

	Controls.CO2SelectedByResource:SetHide( selectedTabName ~= "ByResource"  );
	Controls.CO2ButtonByResource:SetSelected( selectedTabName == "ByResource"   );

	-- TODO: pending gamecore implementation
	--Controls.CO2SelectedDeforestation:SetHide( selectedTabName ~= "Deforestation"  );
	--Controls.CO2ButtonDeforestation:SetSelected( selectedTabName == "Deforestation"   );	
end

-- ===========================================================================
function GetDirectionText( eDirection:number )
	if eDirection == DirectionTypes.NO_DIRECTION then
		return "";
	elseif eDirection == DirectionTypes.DIRECTION_NORTHEAST then
		return "LOC_CLIMATE_SCREEN_NORTHEAST";
	elseif eDirection == DirectionTypes.DIRECTION_EAST then
		return "LOC_CLIMATE_SCREEN_EAST";
	elseif eDirection == DirectionTypes.DIRECTION_SOUTHEAST then
		return "LOC_CLIMATE_SCREEN_SOUTHEAST";
	elseif eDirection == DirectionTypes.DIRECTION_SOUTHWEST then
		return "LOC_CLIMATE_SCREEN_SOUTHWEST";
	elseif eDirection == DirectionTypes.DIRECTION_WEST then
		return "LOC_CLIMATE_SCREEN_WEST";
	elseif eDirection == DirectionTypes.DIRECTION_NORTHWEST then
		return "LOC_CLIMATE_SCREEN_NORTHWEST";
	end
end

-- ===========================================================================
function RefreshCurrentEvent()
	local kCurrentEvent:table = GameRandomEvents.GetCurrentTurnEvent();
	if kCurrentEvent ~= nil then 
		local kCurrentEventDef:table = GameInfo.RandomEvents[kCurrentEvent.RandomEvent];
		if kCurrentEventDef ~= nil then
			
			if kCurrentEventDef.EffectOperatorType == CLIMATE_CHANGE_EVENT_TYPE then
				-- If we're a Climate Change event (have SeaLevel) then bail
				Controls.CurrentEventStack:SetHide(true);
				Controls.SeaLevelAlertIndicator:SetHide(false);
				Controls.PolarIceAlertIndicator:SetHide(false);
				return;
			elseif kCurrentEventDef.EffectOperatorType == NUCLEAR_ACCIDENT_EVENT_TYPE then
				-- Don't show nuclear accidents
				Controls.CurrentEventStack:SetHide(true);
				return;
			end

			local pCurrentPlot:table = Map.GetPlotByIndex(kCurrentEvent.CurrentLocation);

			-- Determine if the current location of this event is visible so we can hide some data
			local bIsEventVisible:boolean = false;
			if pCurrentPlot ~= nil then
				local pLocalPlayerVis:table = PlayersVisibility[Game.GetLocalPlayer()];
				if pLocalPlayerVis ~= nil then
					if pLocalPlayerVis:IsRevealed(pCurrentPlot:GetX(), pCurrentPlot:GetY()) then
						bIsEventVisible = true;
					end
				end
			end

            -- Weather type name
			Controls.WeatherStatusText:SetText(Locale.ToUpper(kCurrentEventDef.Name));

            -- Event specific name
            if kCurrentEvent.Name and bIsEventVisible then
                Controls.WeatherName:SetText(Locale.Lookup(kCurrentEvent.Name));
                Controls.WeatherName:SetHide(false);
            else
                Controls.WeatherName:SetHide(true);
            end

            -- Icon
            if kCurrentEventDef.IconLarge and kCurrentEventDef.IconLarge ~= "" then
                Controls.WeatherStatusImage:SetTexture(kCurrentEventDef.IconLarge);
            else
                UI.DataError("Unable to find IconLarge for RandomEvents type: " .. kCurrentEventDef.PrimaryKey);
            end

			-- Get the territory name as a back up to continent name
			local territoryName:string = nil;
			local pTerritory:object = Territories.GetTerritoryAt(kCurrentEvent.CurrentLocation);
			if pTerritory then
				territoryName = pTerritory:GetName();
			end

			-- Current Location and Direction
			local location:string = "";
			if pCurrentPlot ~= nil then
				local eContinentType:number = pCurrentPlot:GetContinentType();
				if eContinentType and eContinentType ~= -1 then
					local kContinentDef:table = GameInfo.Continents[eContinentType];
					location = Locale.ToUpper(kContinentDef.Description);
				elseif territoryName ~= nil then
					location = territoryName;
				else
					location = Locale.Lookup("LOC_CLIMATE_SCREEN_WATER");
				end
			end

			local direction:string = Locale.Lookup(GetDirectionText(kCurrentEvent.CurrentDirection));
			
			if kCurrentEventDef.Global then
				Controls.WeatherLocation:SetText(Locale.Lookup("LOC_CLIMATE_SCREEN_LOCATION", Locale.Lookup("LOC_CLIMATE_SCREEN_GLOBAL")));
			elseif not bIsEventVisible then
				Controls.WeatherLocation:SetText(Locale.Lookup("LOC_CLIMATE_SCREEN_LOCATION", Locale.Lookup("LOC_CIVICS_TREE_NOT_REVEALED_CIVIC")));
			elseif location ~= "" and direction ~= "" then
				Controls.WeatherLocation:SetText(Locale.Lookup("LOC_CLIMATE_SCREEN_LOCATION_DIRECTION", location, direction));
			elseif location ~= "" then
				Controls.WeatherLocation:SetText(Locale.Lookup("LOC_CLIMATE_SCREEN_LOCATION", location));
			else
				Controls.WeatherLocation:SetText("");
			end

            -- Affected Cities
			m_kAffectedCitiesIM:ResetInstances();
			local doesAffectACity:boolean = false;
			local kCurrentAffectedCities:table = GameRandomEvents.GetCurrentAffectedCities();
            for _, affectedCity in ipairs(kCurrentAffectedCities) do
				local pOwner:table = Players[affectedCity.CityOwner];
				local pLocalPlayerDiplo:table = Players[Game.GetLocalPlayer()]:GetDiplomacy();
				if pOwner ~= nil and pLocalPlayerDiplo:HasMet(affectedCity.CityOwner) then
					local pCity:table = pOwner:GetCities():FindID(affectedCity.CityID);
					if pCity then
						local pOwnerConfig:table = PlayerConfigurations[affectedCity.CityOwner];
						local iconString:string = "ICON_" .. pOwnerConfig:GetCivilizationTypeName();
						local textureOffsetX, textureOffsetY, textureSheet = IconManager:FindIconAtlas(iconString, 30);
						local secondaryColor, primaryColor = UI.GetPlayerColors( affectedCity.CityOwner );
						
						local cityInstance:table = m_kAffectedCitiesIM:GetInstance();
						cityInstance.Icon:SetTexture(textureOffsetX, textureOffsetY, textureSheet);
						cityInstance.Icon:LocalizeAndSetToolTip( pOwnerConfig:GetCivilizationDescription() );
						cityInstance.Icon:SetColor( primaryColor );
						cityInstance.IconBacking:SetColor( secondaryColor );
						cityInstance.Name:SetText(Locale.Lookup(pCity:GetName()));
						doesAffectACity = true;
					end
				end
			end
			Controls.CitiesStack:SetHide(not bIsEventVisible);
			Controls.CitiesStackDivider:SetHide(not doesAffectACity or not bIsEventVisible);

			if kCurrentEventDef.EffectString ~= nil then
				Controls.WeatherEffect:SetText(Locale.Lookup(kCurrentEventDef.EffectString));
			else
				Controls.WeatherEffect:SetText("");
			end

			-- Buff/Debuff
			local bAnyBuff:boolean = false;

			if kCurrentEvent.FertilityAdded ~= nil and kCurrentEvent.FertilityAdded < 0 then
				Controls.PlotLostFertileLabel:SetText(math.abs(kCurrentEvent.FertilityAdded));
				Controls.PlotLostFertileContainer:SetHide(false);
				bAnyBuff = true;
			else
				Controls.PlotLostFertileContainer:SetHide(true);
			end

			if kCurrentEvent.FertilityAdded ~= nil and kCurrentEvent.FertilityAdded > 0 then
				Controls.PlotFertileLabel:SetText(kCurrentEvent.FertilityAdded);
				Controls.PlotFertileContainer:SetHide(false);
				bAnyBuff = true;
			else
				Controls.PlotFertileContainer:SetHide(true);
			end

			if kCurrentEvent.TilesDamaged ~= nil and kCurrentEvent.TilesDamaged > 0 then
				Controls.PlotDamagedLabel:SetText(kCurrentEvent.TilesDamaged);
				Controls.PlotDamagedContainer:SetHide(false);
				bAnyBuff = true;
			else
				Controls.PlotDamagedContainer:SetHide(true);
			end

			if kCurrentEvent.UnitsLost ~= nil and kCurrentEvent.UnitsLost > 0 then
				Controls.UnitsLostLabel:SetText(kCurrentEvent.UnitsLost);
				Controls.UnitsLostContainer:SetHide(false);
				bAnyBuff = true;
			else
				Controls.UnitsLostContainer:SetHide(true);
			end

			if kCurrentEvent.PopLost ~= nil and kCurrentEvent.PopLost > 0 then
				Controls.PopLostLabel:SetText(kCurrentEvent.PopLost);
				Controls.PopLostContainer:SetHide(false);
				bAnyBuff = true;
			else
				Controls.PopLostContainer:SetHide(true);
			end

			local showBuffStack:boolean = bIsEventVisible and bAnyBuff;
			Controls.BuffStack:SetHide(not showBuffStack);
		end

		Controls.CurrentEventStack:SetHide(false);
	else
		Controls.CurrentEventStack:SetHide(true);
	end
end

-- ===========================================================================
function TabSelectOverview()
	RealizeTabs("Overview");
	
	-- Alert indicators are shown by RefreshCurrentEvent if required
	Controls.SeaLevelAlertIndicator:SetHide(true);
	Controls.PolarIceAlertIndicator:SetHide(true);		

	RefreshCurrentEvent();

	local ClimateLevel			:number = m_currentSeaLevelPhase;

	local ClimateName			:string;
	if (m_currentSeaLevelEvent < 0) then
		ClimateName = Locale.ToUpper("LOC_CLIMATE_CLIMATE_CHANGE_PHASE_0");
	else
		ClimateName = Locale.ToUpper(GameInfo.RandomEvents[m_currentSeaLevelEvent].Name);
	end
	
	local CO2Total				:number = GameClimate.GetTotalCO2Footprint();
	local CO2Player				:number = GameClimate.GetPlayerCO2Footprint( m_playerID, false  );
	local CO2TopPlayer			:number = GetWorstCO2PlayerID();
	local CO2Modifier			:number = GameClimate.GetCO2FootprintModifier();
	
	-- Determine worst CO2 contributor
	local TopContributorName	:string = Locale.Lookup("LOC_CLIMATE_NO_ONE"); 
	if CO2TopPlayer ~= PLAYER_NO_ONE then 
		local pPlayerConfiguration :table = PlayerConfigurations[CO2TopPlayer];
		TopContributorName = pPlayerConfiguration:GetPlayerName();
	end 	
	
	local TempIncrease			:number = GameClimate.GetTemperatureChange(); -- Change in temperature from the starting baseline, in Celsius 
	local TempIncreaseText		:string = tostring(Locale.ToNumber(TempIncrease, "#.#"));
	local deforestationType		:number = GameClimate.GetDeforestationType(); 
	local co2Modifier			:number = GameClimate.GetCO2FootprintModifier(); 
	local deforestationName		:string = "";
	local deforestationDescription	:string = "";
	local TempTooltip			:string = "";
	if (deforestationType >= 0) then
		local kDeforestationLevel:table = GameInfo.DeforestationLevels[deforestationType];
		deforestationName = kDeforestationLevel.Name;
		deforestationDescription = kDeforestationLevel.Description; 
		TempTooltip	= Locale.Lookup("LOC_CLIMATE_TEMPERATURE_TOOLTIP", deforestationName, deforestationDescription, co2Modifier );
	end
	local co2Modifier			:number = GameClimate.GetCO2FootprintModifier();

	local stormChance			:number = GameClimate.GetStormPercentChance();
	local stormIncrease			:number = GameClimate.GetStormClimateIncreasedChance();

	local riverFloodChance		:number = GameClimate.GetFloodPercentChance();
	local riverFloodIncrease	:number = GameClimate.GetFloodClimateIncreasedChance();
	local riverNum				:number = RiverManager.GetNumRivers();
	local riverFloodableNum		:number = RiverManager.GetNumFloodableRivers();
	
	local volcanoTotalNum		:number = MapFeatureManager.GetNumNormalVolcanoes();
	local volcanoActiveNum		:number = MapFeatureManager.GetNumActiveVolcanoes();
	local volcanoEruptionsNum	:number = MapFeatureManager.GetNumEruptions();
	local volcanoNaturalWonder	:number = MapFeatureManager.GetNumNaturalWonderVolcanoes();
	--local volcanoPercent		:number = MapFeatureManager.GetPercentVolcanoesActive();
	local volcanoEruptChance	:number = GameClimate.GetEruptionPercentChance();

	local droughtChance			:number = GameClimate.GetDroughtPercentChance();
	local droughtIncrease		:number = GameClimate.GetDroughtClimateIncreasedChance();
	
	local nextIceLostTurns		:number = GameClimate.GetNextIceLossTurns();

	local tilesFlooded			:number = GameClimate.GetTilesFlooded();
	local tilesSubmerged		:number = GameClimate.GetTilesSubmerged();
	local nextSeaRiseTurns		:number = GameClimate.GetNextSeaLevelRiseTurns();

	Controls.ClimateChangePhaseText:SetText(ClimateName);
	UpdatePhaseBar(ClimateLevel,-1,-1);

	-- Left
	if m_prevTurnNum > 0 then
		Controls.ContributeTotal:SetText( string.format("%s (+%d)", Locale.Lookup("LOC_CLIMATE_TOTAL_NUM", CO2Total), CO2Total-m_prevTurnCO2) );
	else
		Controls.ContributeTotal:SetText(Locale.Lookup("LOC_CLIMATE_TOTAL_NUM", CO2Total));
	end
	Controls.ContributeTop:SetText(Locale.Lookup("LOC_CLIMATE_TOP_CONTRIBUTOR_NUM", TopContributorName));
	Controls.ContributeMe:SetText(Locale.Lookup("LOC_CLIMATE_MY_CONTRIBUTION_NUM", CO2Player));
	Controls.OverviewCO2Grid:SetToolTipString(Locale.Lookup("LOC_CLIMATE_CO2_TOTAL_TOOLTIP", CO2Modifier));

	Controls.ClimateTemperature:SetText(Locale.Lookup("LOC_CLIMATE_TEMPERATURE_SUBTEXT"));
	Controls.TemperatureValue:SetText(Locale.Lookup("LOC_CLIMATE_TEMPERATURE", TempIncreaseText));	
	Controls.GlobalTempGrid:SetToolTipString(TempTooltip);
	
	Controls.WorldAgeText:SetHide(m_worldAgeName==nil);
	if m_worldAgeName then
		Controls.WorldAgeText:SetText( Locale.Lookup("LOC_CLIMATE_WORLD_AGE",m_worldAgeName) );
	end
		
	Controls.RealismText:SetHide(m_RealismName==nil);
	if m_RealismName then
		Controls.RealismText:SetText( Locale.Lookup("LOC_CLIMATE_REALISM", m_RealismName) );
	end


	-- Right
	Controls.StormChanceNum:SetText(Locale.Lookup("LOC_CLIMATE_PERCENT_CHANCE", stormChance));
	Controls.StormChanceFromClimateChange:SetText( Locale.Lookup("LOC_CLIMATE_AMOUNT_FROM_CLIMATE_CHANGE", stormIncrease)  );	

	Controls.RiverFloodChanceNum:SetText(Locale.Lookup("LOC_CLIMATE_PERCENT_CHANCE", riverFloodChance));
	Controls.RiverFloodChanceFromClimateChange:SetText( Locale.Lookup("LOC_CLIMATE_AMOUNT_FROM_CLIMATE_CHANGE", riverFloodIncrease)  );	

	Controls.DroughtActivityChanceNum:SetText(Locale.Lookup("LOC_CLIMATE_PERCENT_CHANCE", droughtChance));
	Controls.DroughtChanceFromClimateChange:SetText( Locale.Lookup("LOC_CLIMATE_AMOUNT_FROM_CLIMATE_CHANGE", droughtIncrease)  );	

	Controls.VolcanicActivityChanceNum:SetText(Locale.Lookup("LOC_CLIMATE_PERCENT_CHANCE", volcanoEruptChance));
	Controls.VolatileNum:SetText( Locale.Lookup("LOC_CLIMATE_VOLCANO_VOLATILE_NUM", volcanoNaturalWonder) );
	Controls.InactiveNum:SetText( Locale.Lookup("LOC_CLIMATE_VOLCANO_INACTIVE_NUM", volcanoTotalNum - volcanoActiveNum) );
	Controls.ActiveNum:SetText( Locale.Lookup("LOC_CLIMATE_VOLCANO_ACTIVE_NUM", volcanoActiveNum) );
	Controls.EruptedNum:SetText( Locale.Lookup("LOC_CLIMATE_VOLCANO_ERUPTED_NUM", volcanoEruptionsNum) );

	-- Gran Colombia & Maya
	if bIsGCM then
		local forestFireChance = GameClimate.GetFirePercentChance();
		local forestFireIncrease = GameClimate.GetFireClimateIncreasedChance();
		Controls.ForestFireActivityChanceNum:SetText( Locale.Lookup("LOC_CLIMATE_PERCENT_CHANCE", forestFireChance) );
		Controls.ForestFireChanceFromClimateChange:SetText( Locale.Lookup("LOC_CLIMATE_AMOUNT_FROM_CLIMATE_CHANGE", forestFireIncrease) );
	end
	
	-- Bottom
	local iIceLoss	:number = 0;
	local fSeaLevel	:number = 0.0;
	if (m_currentSeaLevelEvent > -1) then
		iIceLoss = GameInfo.RandomEvents[m_currentSeaLevelEvent].IceLoss;
		szSeaLevel = GameInfo.RandomEvents[m_currentSeaLevelEvent].Description;
	end

	if szSeaLevel == nil then
		szSeaLevel = "0";
	end

	Controls.PolarIceLostNum:SetText( Locale.Lookup("LOC_CLIMATE_LOST", iIceLoss));
	if nextIceLostTurns > 0 and ClimateLevel < MAX_PHASES then
		Controls.NextPolarIceLost:SetHide(false);
		Controls.NextPolarIceLost:SetText( Locale.Lookup("LOC_CLIMATE_POLAR_ICE_MELT_X_TURNS", nextIceLostTurns));
	else
		Controls.NextPolarIceLost:SetHide(true);
	end

	Controls.SeaLevel:SetText(Locale.Lookup("LOC_CLIMATE_SEA_LEVEL_RISE", Locale.Lookup(szSeaLevel)));
	Controls.SeaLevelArea:SetToolTipString( Locale.Lookup("LOC_CLIMATE_SEA_LEVEL_RISE_DESCRIPTION_TOOLTIP", szSeaLevel) );	
	Controls.TilesFlooded:SetText( Locale.Lookup("LOC_CLIMATE_COASTAL_TILES_FLOODED_NUM", tilesFlooded ));
	Controls.TilesSubmerged:SetText( Locale.Lookup("LOC_CLIMATE_COASTAL_TILES_SUBMERGED_NUM", tilesSubmerged ));
	if nextSeaRiseTurns > 0 and ClimateLevel < MAX_PHASES then
		Controls.NextSeaLevelRise:SetHide(false);
		Controls.NextSeaLevelRise:SetText(	Locale.Lookup("LOC_CLIMATE_SEA_LEVEL_RISE_X_TURNS", nextSeaRiseTurns));
	else
		Controls.NextSeaLevelRise:SetHide(true);
	end

	Controls.SeaLevelWave:SetOffsetY((ClimateLevel * SEA_LEVEL_WAVE_OFFSET) - SEA_LEVEL_WAVE_OFFSET);
end


-- ===========================================================================
--	Creates a pie chart by abusing the meter control
--	Pie slices are in percents (e.g., .1 is 10%) and summed are 1.0 or less.
--
--	uiHolder		UI control that will host the meter control "slices"
--	sliceIM			An instance manager which generates the "Slice" graphics.
--	kSliceAmounts	Ordered array of numbers 0 to 1.0 for each slice.
--	kColors			(optional) Ordered array of numbers (AABBGGRR) for pie slices.
--
--	RETURNS:	A table of the slice instances.
-- ===========================================================================
function BuildPieChart( uiHolder:table, sliceIM:table, kSliceAmounts:table, kColors:table )

	-- Protect the flock, bad arguements raise errors and return empty tables:
	if uiHolder == nil then			UI.DataError("Cannot build pie chart due to nil uiHolder passed in."); return {}; end;
	if sliceIM == nil then			UI.DataError("Cannot build pie chart due to a nil instance manager for generating slices passed in."); return {}; end;
	if kSliceAmounts == nil then	UI.DataError("Cannot build pie chart due to a nil table of slice amounts passed in."); return {}; end;
	
	-- Determine total amount from slices and check bounds (create non-1 multiplier if necessary.)
	local total			:number = 0;
	local multiplier	:number = 1;
	for i,v in ipairs(kSliceAmounts) do
		total = total + v;
	end
	if total > 1.0 then
		multiplier = 1.0 / total;
		UI.DataError("Total of pie chart slices "..tostring(total).." exceeds 1.0 (100%).  Applying multiplier "..tostring(multiplier));
	elseif total < 0 then		
		UI.DataError("Total of slices "..tostring(total).." is less than 0!  Something is fishy with your data.");
		total = 0;
	end

	-- If colors were not passed in, generate a table.
	if kColors == nil or table.count(kColors)==0 then
		kColors = { UI.GetColorValueFromHexLiteral(0xff000099), UI.GetColorValueFromHexLiteral(0xff008888), UI.GetColorValueFromHexLiteral(0xff009900), UI.GetColorValueFromHexLiteral(0xff888800), UI.GetColorValueFromHexLiteral(0xff990000), UI.GetColorValueFromHexLiteral(0xff880088) };
	end
	local maxColors:number = #kColors;


	-- Loop through generating pie slices.
	local kUISlices		:table = {};
	local remaining		:number = total;	

	for i,v in ipairs(kSliceAmounts) do
		local uiInstance:table = sliceIM:GetInstance( uiHolder );
		table.insert(kUISlices, uiInstance);

		uiInstance["Slice"]:SetColor( kColors[ ((i-1) % maxColors)+1 ] );	-- MOD
		uiInstance["Slice"]:SetPercent( remaining );
		
		remaining = remaining - v;
	end

	return kUISlices;
end

-- ===========================================================================
--	Create a table of colors to use for pie charting.
-- ===========================================================================
function GetPieChartColorTable()
	local kColors = {};
	table.insert(kColors, UI.GetColorValue("COLOR_STANDARD_RED_MD") );
	table.insert(kColors, UI.GetColorValue("COLOR_STANDARD_ORANGE_MD") );
	table.insert(kColors, UI.GetColorValue("COLOR_STANDARD_YELLOW_MD") );
	table.insert(kColors, UI.GetColorValue("COLOR_STANDARD_GREEN_MD") );
	table.insert(kColors, UI.GetColorValue("COLOR_STANDARD_AQUA_MD") );
	table.insert(kColors, UI.GetColorValue("COLOR_STANDARD_BLUE_MD") );
	table.insert(kColors, UI.GetColorValue("COLOR_STANDARD_PURPLE_MD") );
	return kColors;
end

-- ===========================================================================
function TabSelectCO2Levels()

	RealizeTabs("CO2Levels");
	
	TabCO2ByCivilization();
	TabCO2ByResource();
	RealizePlayerCO2();

	local CO2Total		:number = GameClimate.GetTotalCO2Footprint();
	local CO2Player		:number = GameClimate.GetPlayerCO2Footprint(m_playerID, false );
	local CO2Modifier	:number = GameClimate.GetCO2FootprintModifier();

	local sGlobalTotal:string = "";
	if CO2Modifier ~= 0 then
		sGlobalTotal = Locale.Lookup("LOC_CLIMATE_TOTAL_NUM_W_MOD", CO2Total, CO2Modifier);
	else
		sGlobalTotal = Locale.Lookup("LOC_CLIMATE_TOTAL_NUM", CO2Total);
	end
	-- Infixo 2022-12-21
	if m_prevTurnNum > 0 then
		Controls.GlobalContributionsTotalNum:SetText( string.format("%s  +%d", sGlobalTotal, CO2Total-m_prevTurnCO2) );
	else
		Controls.GlobalContributionsTotalNum:SetText( sGlobalTotal ) ;
	end
	Controls.YourContributionsNum:SetText( Locale.Lookup("LOC_CLIMATE_TOTAL_NUM", CO2Player) );
	Controls.GlobalContributionsTotalNum:SetToolTipString(Locale.Lookup("LOC_CLIMATE_CO2_TOTAL_TOOLTIP", CO2Modifier));
end

-- ===========================================================================
function TabSelectEventHistory()

	RealizeTabs("EventHistory");

	m_kEventRowInstance:ResetInstances();
	m_kClimateChangeInstance:ResetInstances();

	local iCurrentTurn = Game.GetCurrentGameTurn();
	for i=iCurrentTurn, 0, -1 do
		local kEvent:table = GameRandomEvents.GetEventsForTurn(i);
		if kEvent ~= nil then
			local kEventDef:table = GameInfo.RandomEvents[kEvent.RandomEvent];
			if kEventDef ~= nil then
				if kEventDef.ClimateChangePoints > 0 then
					CreateClimateChangeInstance(kEvent, kEventDef, i);
				elseif kEventDef.EffectOperatorType ~= NUCLEAR_ACCIDENT_EVENT_TYPE then
					local pEventPlot:table = Map.GetPlotByIndex(kEvent.CurrentLocation);
					if kEventDef.Global then
						CreateEventInstance(kEvent, kEventDef, i);
					elseif pEventPlot ~= nil then
						local pLocalPlayerVis:table = PlayersVisibility[Game.GetLocalPlayer()];
						if pLocalPlayerVis ~= nil and pLocalPlayerVis:IsRevealed(pEventPlot:GetX(), pEventPlot:GetY()) then
							CreateEventInstance(kEvent, kEventDef, i);
						end
					end
				end
			end
		end
	end
end

-- ===========================================================================
function CreateClimateChangeInstance( kEvent:table, kEventDef:table, iTurn:number )
	local kInstance:table = m_kClimateChangeInstance:GetInstance();

	kInstance.EventTypeName:SetText(Locale.ToUpper(kEventDef.Name));

	local strDate = Calendar.MakeYearStr(iTurn);
	kInstance.DateString:SetText("[Icon_Turn]" .. Locale.Lookup("LOC_CLIMATE_ENTRY_DATE", iTurn, strDate));
end

-- ===========================================================================
function CreateEventInstance( kEvent:table, kEventDef:table, iTurn:number )
	local kInstance:table = m_kEventRowInstance:GetInstance();
				
	-- Icon
	if kEventDef.IconSmall and kEventDef.IconSmall ~= "" then
		kInstance.Icon:SetTexture(kEventDef.IconSmall);
	end

	-- Name
	kInstance.EventTypeName:SetText(Locale.ToUpper(kEventDef.Name));
	kInstance.EventName:SetText(Locale.ToUpper(kEvent.Name));

	-- Create descriptive tooltip
	local tooltip:string = "";
	if kEventDef.EffectString then
		tooltip = tooltip .. Locale.Lookup(kEventDef.EffectString);
		kInstance.NameContainer:SetToolTipString(tooltip);
	end

	-- Get the territory name as a back up to continent name
	local territoryName:string = nil;
	local pTerritory:object = Territories.GetTerritoryAt(kEvent.StartLocation);
	if pTerritory then
		territoryName = pTerritory:GetName();
	end

	-- Location
	local pPlot:table = Map.GetPlotByIndex(kEvent.StartLocation);
	if pPlot ~= nil then
		local eContinentType:number = pPlot:GetContinentType();
		if eContinentType and eContinentType ~= -1 then
			local kContinentDef:table = GameInfo.Continents[eContinentType];
			kInstance.LocationString:SetText(Locale.Lookup(kContinentDef.Description));
		elseif territoryName ~= nil then
			kInstance.LocationString:SetText(territoryName);
		else
			kInstance.LocationString:SetText(Locale.Lookup("LOC_CLIMATE_SCREEN_WATER"));
		end
	end

	-- Effects
	if kEvent.FertilityAdded > 0 then
		kInstance.FertilizedTilesIcon:SetHide(false);
		kInstance.LosingFertilizedTilesIcon:SetHide(true);
		kInstance.FertilizedTiles:SetText(kEvent.FertilityAdded);
		kInstance.FertilizedContainer:SetToolTipString(Locale.Lookup("LOC_CLIMATE_FERTILIZED_TILES"));
	elseif kEvent.FertilityAdded < 0 then
		kInstance.FertilizedTilesIcon:SetHide(true);
		kInstance.LosingFertilizedTilesIcon:SetHide(false);
		kInstance.FertilizedTiles:SetText(math.abs(kEvent.FertilityAdded));
		kInstance.FertilizedContainer:SetToolTipString(Locale.Lookup("LOC_CLIMATE_LOST_FERTILIZED_TILES"));
	else
		kInstance.FertilizedTilesIcon:SetHide(true);
		kInstance.LosingFertilizedTilesIcon:SetHide(true);
		kInstance.FertilizedTiles:SetText("");
	end

	if kEvent.TilesDamaged > 0 then
		kInstance.DamagedTilesIcon:SetHide(false);
		kInstance.DamagedTiles:SetText(kEvent.TilesDamaged);
	else
		kInstance.DamagedTilesIcon:SetHide(true);
		kInstance.DamagedTiles:SetText("");
	end

	if kEvent.UnitsLost > 0 then
		kInstance.UnitsLostIcon:SetHide(false);
		kInstance.UnitsLost:SetText(kEvent.UnitsLost);
	else
		kInstance.UnitsLostIcon:SetHide(true);
		kInstance.UnitsLost:SetText("");
	end

	if kEvent.PopLost > 0 then
		kInstance.PopLostIcon:SetHide(false);
		kInstance.PopLost:SetText(kEvent.PopLost);
	else
		kInstance.PopLostIcon:SetHide(true);
		kInstance.PopLost:SetText("");
	end

	-- Date
	local strDate = Calendar.MakeYearStr(iTurn);
	kInstance.DateString:SetText("[Icon_Turn]" .. Locale.Lookup("LOC_CLIMATE_ENTRY_DATE", iTurn, strDate));
end

-- ===========================================================================
--	Create the pie-chart on the right side of the screen that is composed of
--	overlayed meters.
-- ===========================================================================

-- helpers
function FormatLastTurn(lastTurn:number)
	return lastTurn == 0 and "0" or string.format("%+d", lastTurn);
end
function ResourceIcon(icon:string)
	return "[ICON_"..icon.."]";
end
function FormatPercent(amount:number, total:number)
	return total == 0 and "-" or string.format("%.0f%%", amount*100/total);
end

function RealizePlayerCO2()

	local pLocalPlayer			:table = Players[m_playerID];
	local pResources			:table	= pLocalPlayer:GetResources();	
	local kResourceUseAmounts	:table = {};		-- hold raw CO2 usage amounts by each resource
	--local kSliceAmounts			:table = {};		-- hold the % each resource is contributing to CO2
	local total					:number = 0;
	--local kColors				:table = GetPieChartColorTable();
	--local maxColors				:number = #kColors;
	--local colorIndex			:number = 1;	-- Used to tint correponding colors

	m_kYourCO2IM:ResetInstances();

	-- calculate the total first
	for kResourceInfo in GameInfo.Resources() do
		total = total + GameClimate.GetPlayerResourceCO2Footprint( m_playerID, kResourceInfo.Index, false );
	end
	
	for kResourceInfo in GameInfo.Resources() do

		-- Does the resource contribute to CO2?
		local kConsumption:table = GameInfo.Resource_Consumption[kResourceInfo.ResourceType];
		if kConsumption ~= nil and kConsumption.CO2perkWh ~= nil and kConsumption.CO2perkWh > 0 then

			-- Is the player using the resource?			
			local amount :number = GameClimate.GetPlayerResourceCO2Footprint( m_playerID, kResourceInfo.Index, false );
			if amount > 0 then

				local uiResource		:table = m_kYourCO2IM:GetInstance();
				local co2Amount			:number = amount;
				--local color				:number = kColors[colorIndex];
				local amountLastTurn	:number = GameClimate.GetPlayerResourceCO2Footprint( m_playerID, kResourceInfo.Index, true );
				local resourceTotal		:number = GameClimate.GetPlayerRawResourceConsumption( m_playerID, kResourceInfo.Index, false );
				local resourceLastTurn	:number = GameClimate.GetPlayerRawResourceConsumption( m_playerID, kResourceInfo.Index, true );

				uiResource.Icon:SetIcon( "ICON_" .. kResourceInfo.ResourceType);
				uiResource.Name:SetText( Locale.Lookup(kResourceInfo.Name) );
				uiResource.Percent:SetText( FormatPercent(co2Amount, total) );
				uiResource.Amount:SetText( co2Amount );
				uiResource.LastTurn:SetText( FormatLastTurn(amountLastTurn) );
				--uiResource.Palette:SetColor( color );

				uiResource.ResAmount:SetText( tostring(resourceTotal)..ResourceIcon(kResourceInfo.ResourceType) );
				uiResource.ResLastTurn:SetText( FormatLastTurn(resourceLastTurn)..ResourceIcon(kResourceInfo.ResourceType) );
				uiResource.Top:SetToolTipString( Locale.Lookup("LOC_CLIMATE_RESOURCE_CONSUMED_LAST_TURN", resourceLastTurn, kResourceInfo.Name, amountLastTurn) );
				
				--table.insert( kResourceUseAmounts, amount);
				--total = total + co2Amount;

				--colorIndex = (colorIndex + 1) % maxColors;
			end
		end
	end

	-- Now total is known, create an array based on percentages (0.0 - 1.0) each resources makes and chart it.
	--for i,amount in ipairs( kResourceUseAmounts ) do
		--table.insert(kSliceAmounts, amount/total );
	--end
	
	--BuildPieChart( Controls.TotalContributionsPie, m_kSliceIM, kSliceAmounts, kColors );
end


-- ===========================================================================
function TabCO2ByCivilization()
	--print("FUN TabCO2ByCiviliation()");
	--RealizeCO2Tabs("ByCivilization");

	--m_kCO2CivsIM:ResetInstances(); -- clear old data
	m_kCivCO2IM:ResetInstances(); -- clear old data

	-- Realease instances of pie slices previously used in the global section.
	for _,uiSliceInstance in ipairs(m_kGlobalPieSlices) do
		m_kSliceIM:ReleaseInstance( uiSliceInstance );
	end

	local pLocalPlayer			:table = Players[m_playerID];
	local pPlayerDiplomacy		:table = pLocalPlayer:GetDiplomacy();
	local pPlayers				:table = PlayerManager.GetAliveMajors();	
	local total					:number = 0;
	local kFootprints			:table = {};		-- hold raw CO2 usage amounts by each resource	
	local kColors				:table = {};
	local kLastTurn:table = {}; -- cache for last turn emmission
	
	-- last turn emmission is only available via GetPlayerResourceCO2Footprint(ePlayer,eResource,bLastTurn)
	-- resources not related to CO2 just return 0, so we can just loop through
	local function GetLastTurnEmission(playerID:number)
		if kLastTurn[playerID] == nil then
			local iCO2FootprintLastTurn:number = 0;
			for kResourceInfo in GameInfo.Resources() do
				iCO2FootprintLastTurn = iCO2FootprintLastTurn + GameClimate.GetPlayerResourceCO2Footprint( playerID, kResourceInfo.Index, true );
			end
			kLastTurn[playerID] = iCO2FootprintLastTurn;
		end
		--print("..last turn", playerID, kLastTurn[playerID]);
		return kLastTurn[playerID];
	end
	
	-- calculate the total first, so we can get percentages later
	local iNumPlayersWithCO2:number = 0;
	for _,pPlayer in ipairs(pPlayers) do
		local playerID:number = pPlayer:GetID();
		local iCO2FootprintNum:number = GameClimate.GetPlayerCO2Footprint(playerID, false);
		local iCO2FootprintLastTurn:number = GetLastTurnEmission(playerID);
		
		if not ( iCO2FootprintLastTurn == 0 and iCO2FootprintNum == 0 ) then
			total = total + iCO2FootprintNum;
			iNumPlayersWithCO2 = iNumPlayersWithCO2 + 1;
		end
	end
	
	-- calculate tresholds - 50% and 150% of the average
	local fCO2Avg:number, fCO2Min:number, fCO2Max:number = 0.0, 0.0, 0.0;
	if iNumPlayersWithCO2 > 1 then -- apply coloring only if at least 2 players contribute
		fCO2Avg = total / iNumPlayersWithCO2;
		fCO2Min = fCO2Avg * 0.5;
		fCO2Max = fCO2Avg * 1.5;
	end
	
	local function FormatColor(text:string, amount:number)
		if amount == 0 then return "[COLOR:128,128,128,128]"..text.."[ENDCOLOR]"; end
		if iNumPlayersWithCO2 < 2 then return text; end
		if amount < fCO2Min then return "[COLOR_GREEN]"..text.."[ENDCOLOR]"; end
		if amount > fCO2Max then return "[COLOR_RED]"..text.."[ENDCOLOR]"; end
		return text;
	end
	
	-- gather data
	local tRows:table = {};
	local function AddCivCO2Row(bIcon:boolean, playerID:number, civName:string, amount:number, lastTurn:number)
		--print("..adding", playerID, civName);
		local row:table = { Icon = bIcon, PlayerID = playerID, CivName = civName, Amount = amount, LastTurn = lastTurn };
		table.insert(tRows, row);
	end
	
	-- unmet players are put into one bag (dark blue back color in the original screen)
	local bShowUnmet:boolean = false;
	local iUnmetCO2FootprintNum:number, iUnmetCO2FootprintLastTurn:number = 0, 0;
	
	for _, pPlayer in ipairs(pPlayers) do
		local playerID			:number = pPlayer:GetID();
		local iCO2FootprintNum	:number = GameClimate.GetPlayerCO2Footprint( playerID, false  );

		-- last turn emmission is only available via GetPlayerResourceCO2Footprint(ePlayer,eResource,bLastTurn)
		-- resources not related to CO2 just return 0, so we can just loop through
		local iCO2FootprintLastTurn:number = GetLastTurnEmission(playerID);
		--for kResourceInfo in GameInfo.Resources() do
			--iCO2FootprintLastTurn = iCO2FootprintLastTurn + GameClimate.GetPlayerResourceCO2Footprint( playerID, kResourceInfo.Index, true );
		--end
		
		local pPlayerConfig		:table = PlayerConfigurations[playerID];
		local civType			:string = pPlayerConfig:GetCivilizationTypeName();
		local civName			:string = Locale.Lookup( pPlayerConfig:GetCivilizationShortDescription() );
		--local backColor, frontColor = UI.GetPlayerColors(playerID);

		-- unmet players get a dark blue pie wedge and no clues about who the civ is
		if pPlayerDiplomacy:HasMet(playerID) or m_playerID == playerID then
			if m_playerID == playerID then
				civName = "[ICON_Capital]"..Locale.Lookup( "LOC_CLIMATE_YOU", civName );	-- Add "(You)" for your civ.
			end
			AddCivCO2Row(true, playerID, civName, iCO2FootprintNum, iCO2FootprintLastTurn);
		else
			iUnmetCO2FootprintNum = iUnmetCO2FootprintNum + iCO2FootprintNum;
			iUnmetCO2FootprintLastTurn = iUnmetCO2FootprintLastTurn + iCO2FootprintLastTurn;
			bShowUnmet = true;
		end
	end

	-- unmer players at the end
	if bShowUnmet then
		AddCivCO2Row(false, 0, Locale.Lookup("LOC_WORLD_RANKING_UNMET_PLAYER"), iUnmetCO2FootprintNum, iUnmetCO2FootprintLastTurn);
	end
	
	-- show single row
	local function ShowCivCO2Row(bIcon:boolean, playerID:number, civName:string, amount:number, lastTurn:number)
		uiCiv = m_kCivCO2IM:GetInstance();
		-- icon
		if bIcon then
			local civIconController = CivilizationIcon:AttachInstance( uiCiv.CivIcon );
			civIconController:UpdateIconFromPlayerID( playerID );
			civIconController:SetLeaderTooltip( playerID );
		end
		-- values
		uiCiv.Name:SetText( civName );
		uiCiv.Percent:SetText( FormatColor( FormatPercent(amount, total), amount ) );
		uiCiv.Amount:SetText( FormatColor( tostring(amount), amount) );
		uiCiv.LastTurn:SetText( FormatColor( FormatLastTurn(lastTurn), amount ) );
	end
	
	-- sort and display
	local function sortFunction(a,b)
		if a.Amount == b.Amount then
			return a.LastTurn > b.LastTurn;
		end
		return a.Amount > b.Amount;
	end
	table.sort(tRows, sortFunction);
	for _,row in ipairs(tRows) do
		ShowCivCO2Row(row.Icon, row.PlayerID, row.CivName, row.Amount, row.LastTurn);
	end

end


-- ===========================================================================
function TabCO2ByResource()

	--RealizeCO2Tabs("ByResource");

	--m_kCO2CivsIM:ResetInstances();
	m_kResCO2IM:ResetInstances();	

	-- Realease instances of pie slices previously used in the global section.
	--for _,uiSliceInstance in ipairs(m_kGlobalPieSlices) do
		--m_kSliceIM:ReleaseInstance( uiSliceInstance );
	--end

	local kResourceUseAmounts	:table = {};		-- hold raw CO2 usage amounts by each resource
	local kSliceAmounts			:table = {};		-- hold the % each resource is contributing to CO2
	local kColors				:table = GetPieChartColorTable();
	local maxColors				:number = #kColors;
	local colorIndex			:number = 1;	-- Used to tint correponding colors
	local total					:number = 0;	-- Total CO2 from all resources

	-- calculate the total first
	for kResourceInfo in GameInfo.Resources() do
		-- Does the resource contribute to CO2?
		local kConsumption:table = GameInfo.Resource_Consumption[kResourceInfo.ResourceType];
		if kConsumption ~= nil and kConsumption.CO2perkWh ~= nil and kConsumption.CO2perkWh > 0 then
			-- Loop through all players and sum up the CO2
			local amount	:number = 0;			
			for _,pPlayer in ipairs(PlayerManager.GetAliveMajors()) do			
				amount = amount + GameClimate.GetPlayerResourceCO2Footprint( pPlayer:GetID(), kResourceInfo.Index, false );
			end
		total = total + amount;
		end
	end
	
	-- For all the resources in the game
	for kResourceInfo in GameInfo.Resources() do

		-- Does the resource contribute to CO2?
		local kConsumption:table = GameInfo.Resource_Consumption[kResourceInfo.ResourceType];
		if kConsumption ~= nil and kConsumption.CO2perkWh ~= nil and kConsumption.CO2perkWh > 0 then

			-- Loop through all players and sum up the CO2 and resources
			local amount:number, lastTurn:number = 0, 0;
			local resourceTotal:number, resourceLastTurn:number = 0, 0;
			for _,pPlayer in ipairs(PlayerManager.GetAliveMajors()) do
				local playerID:number = pPlayer:GetID();
				amount   = amount   + GameClimate.GetPlayerResourceCO2Footprint( playerID, kResourceInfo.Index, false );
				lastTurn = lastTurn + GameClimate.GetPlayerResourceCO2Footprint( playerID, kResourceInfo.Index, true );
				resourceTotal    = resourceTotal    + GameClimate.GetPlayerRawResourceConsumption( playerID, kResourceInfo.Index, false );
				resourceLastTurn = resourceLastTurn + GameClimate.GetPlayerRawResourceConsumption( playerID, kResourceInfo.Index, true );
			end

			-- If more than 0, add a UI element.
			if amount > 0 then
				local uiResource	:table = m_kResCO2IM:GetInstance();
				local resourceName	:string = Locale.Lookup( kResourceInfo.Name );
				local co2Amount		:number = amount;
				local color			:number = kColors[colorIndex];

				uiResource.Icon:SetIcon("ICON_" .. kResourceInfo.ResourceType);
				--uiResource.Palette:SetColor( color );
				uiResource.Name:SetText( Locale.Lookup(kResourceInfo.Name) );
				uiResource.Percent:SetText( FormatPercent(co2Amount, total) );
				uiResource.Amount:SetText( co2Amount );
				uiResource.LastTurn:SetText( FormatLastTurn(lastTurn) );
				uiResource.ResAmount:SetText( tostring(resourceTotal)..ResourceIcon(kResourceInfo.ResourceType) );
				uiResource.ResLastTurn:SetText( FormatLastTurn(resourceLastTurn)..ResourceIcon(kResourceInfo.ResourceType) );
				--uiResource.Top:SetToolTipString( Locale.Lookup("LOC_CLIMATE_RESOURCE_CONSUMED_LAST_TURN", resourceLastTurn, kResourceInfo.Name, amountLastTurn) );
				
				
				--table.insert( kResourceUseAmounts, amount );
				--total = total + co2Amount;

				--colorIndex = (colorIndex + 1) % maxColors;
			end
		end
	end

	-- Now total is known, create an array based on percentages (0.0 - 1.0) each resources makes and chart it.
	--for i,amount in ipairs( kResourceUseAmounts ) do
		--table.insert(kSliceAmounts, amount/total );
	--end

	--m_kGlobalPieSlices = BuildPieChart( Controls.GlobalContributionsPie, m_kSliceIM, kSliceAmounts, kColors );
end


-- ===========================================================================
function TabCO2Deforestation()

	RealizeCO2Tabs("Deforestation");

	m_kCO2CivsIM:ResetInstances();

	-- Realease instances of pie slices previously used in the global section.
	for _,uiSliceInstance in ipairs(m_kGlobalPieSlices) do
		m_kSliceIM:ReleaseInstance( uiSliceInstance );
	end

end


-- ===========================================================================
--	Get indices of important climate change random events
-- ===========================================================================
function UpdateClimateChangeEventsData()	
	local iCurrentClimateChangePoints = GameClimate.GetClimateChangeForLastSeaLevelEvent();
	for row in GameInfo.RandomEvents() do
		if (row.EffectOperatorType == "SEA_LEVEL") then
			if (m_firstSeaLevelEvent == -1) then
				m_firstSeaLevelEvent = row.Index;
			end
			if (row.ClimateChangePoints == iCurrentClimateChangePoints) then
				m_currentSeaLevelEvent = row.Index; 
				m_currentSeaLevelPhase = m_currentSeaLevelEvent - m_firstSeaLevelEvent + 1;
			end
		end
	end
end

-- ===========================================================================
--	Set the phase bar to current values.
--	phase				Current phase number
--	realismAmount		Amount bar is affect by realism (TODO: value range? ??TRON)
--	globalTemperature	Amount bar is affect by temperature (TODO: value range? ??TRON)
-- ===========================================================================
function UpdatePhaseBar( phase:number, realismAmount:number, globalTemp:number )
	
	if phase < 0 then
		UI.DataError("SetPhaseBar() needs to cap phase of "..tostring(phase).." to 1");
		phase = 1;
	end
	if phase > MAX_PHASES then
		UI.DataError("SetPhaseBar() needs to cap phase of "..tostring(phase).." to max phase of "..tostring(MAX_PHASE)..".");
		phase = MAX_PHASES;
	end

	-- Fill in all existing bars.
	if (phase > 0) then
		for i=1,phase,1 do
			local uiSegment:table = m_kBarSegments[i];
			uiSegment.Progress:SetColor(UI.GetColorValue("COLOR_WHITE"));
			uiSegment.Pip:SetTexture("Climate_PhaseMeterPip_On");
		end
	end

	-- Update tooltips for all phases
	for i=1,MAX_PHASES,1 do
		UpdatePhaseTooltips(i);
	end
end

-- ===========================================================================
--	Set default values to phase segment and store in local variable for
--	later access.
--	segmentNum	Number of the phase segement to initialize.
-- ===========================================================================
function InitPhaseSegment( segmentNum:number )
	
	local uiSegment:table= Controls["Phase"..tostring(segmentNum)];
	uiSegment.Name:SetText(Locale.ToRomanNumeral(segmentNum));	
	m_kBarSegments[segmentNum] = uiSegment;	
	uiSegment.Progress:SetTexture("Climate_PhaseMeter_" .. segmentNum);
	uiSegment.Progress:SetColor(UI.GetColorValue("COLOR_CLEAR"));
	uiSegment.Pip:SetTexture("Climate_PhaseMeterPip_Off");

	UpdatePhaseTooltips(segmentNum);
end

-- ===========================================================================
function UpdatePhaseTooltips( segmentNum:number )
	local kEventDef = GameInfo.RandomEvents[m_firstSeaLevelEvent + segmentNum - 1];
	if kEventDef == nil then
		return;
	end

	local szPhaseName = kEventDef.Name;
	local szSeaLevelRise = kEventDef.Description;
	local szPhaseType = kEventDef.RandomEventType;
	local iPoints = kEventDef.ClimateChangePoints;
	local szAtOrAboveString = "";
	local szLongDescription = "";

	for row in GameInfo.CoastalLowlands() do
		if (row.FloodedEvent == szPhaseType) then
			szAtOrAboveString = Locale.Lookup("LOC_CLIMATE_TILES_AT_OR_BELOW_FLOOD_TOOLTIP", row.Name);
			szLongDescription = GameInfo.RandomEvents[row.FloodedEvent].LongDescription;
			break;
		elseif (row.SubmergedEvent == szPhaseType) then
			szAtOrAboveString = Locale.Lookup("LOC_CLIMATE_TILES_AT_OR_BELOW_SUBMERGE_TOOLTIP", row.Name);
			szLongDescription = GameInfo.RandomEvents[row.SubmergedEvent].LongDescription;
			break;
		end
	end

	local tooltip:string = 
		Locale.ToUpper(szPhaseName)
		.."[NEWLINE]"..Locale.Lookup("LOC_CLIMATE_CO2_LEVELS").." "..tostring(m_CO2For1Phase*0.5*(segmentNum+1)) -- Infixo 2022-12-21 1 phase = 0.5 temp degrees
		.."[NEWLINE]"
		.."[NEWLINE]"..Locale.Lookup("LOC_CLIMATE_CLIMATE_CHANGE_POINTS_TOOLTIP", GameClimate.GetClimateChangeLevel(), iPoints)
		.."[NEWLINE]"..Locale.Lookup("LOC_CLIMATE_FROM_WORLD_REALISM_NUM_TOOLTIP",  GameClimate.GetClimateChangeFromRealism())
		.."[NEWLINE]"..Locale.Lookup("LOC_CLIMATE_FROM_GLOBAL_TEMPERATURE_NUM_TOOLTIP", GameClimate.GetClimateChangeFromTemperature())
		.."[NEWLINE]"
		.."[NEWLINE]"..Locale.ToUpper("LOC_CLIMATE_EFFECTS_ADDED_THIS_PHASE_TOOLTIP")
		.."[NEWLINE]"
		.."[NEWLINE]"..Locale.Lookup("LOC_CLIMATE_SEA_LEVEL_RISES_NUM_TOOLTIP", szSeaLevelRise)
		..szAtOrAboveString
		.."[NEWLINE]"
		.."[NEWLINE]"..Locale.Lookup("LOC_CLIMATE_POLAR_ICE_MELT_TOOLTIP", kEventDef.IceLoss);

	if (szLongDescription ~= nil and szLongDescription ~= "") then
		tooltip = tooltip .. "[NEWLINE][NEWLINE]" .. Locale.Lookup(szLongDescription);
	end

	m_kBarSegments[segmentNum].Progress:SetToolTipString( tooltip );
end

-- ===========================================================================
--	LUA Event
-- ===========================================================================
function OnToggleClimateScreen()
	if ContextPtr:IsHidden() then
		Open("Overview");
	else
		Close();
	end
end


-- ===========================================================================
function OnInputHandler( pInputStruct:table )
	local uiMsg :number = pInputStruct:GetMessageType();
	if uiMsg == KeyEvents.KeyUp and pInputStruct:GetKey() == Keys.VK_ESCAPE then
		Close();
		return true;
	end
	return false;
end

-- ===========================================================================
function LateInitialize()
	--print("LateInitialize");
	
	-- Tab setup and setting of default tab.
	m_tabs = CreateTabs( Controls.TabContainer, 42, 34, UI.GetColorValueFromHexLiteral(0xFF331D05) );
	m_tabs.AddTab( Controls.ButtonOverview,		TabSelectOverview );
	m_tabs.AddTab( Controls.ButtonCO2Levels,	TabSelectCO2Levels );
	m_tabs.AddTab( Controls.ButtonEventHistory,	TabSelectEventHistory );
	m_tabs.CenterAlignTabs(-10);	

	--m_CO2tabs = CreateTabs( Controls.CO2TabContainer );
	--m_CO2tabs.AddTab( Controls.CO2ButtonByCivilization,		TabCO2ByCiviliation );
	--m_CO2tabs.AddTab( Controls.CO2ButtonByResource,			TabCO2ByResource );
	--m_CO2tabs.AddTab( Controls.CO2ButtonDeforestation,		TabCO2Deforestation );	-- TODO: Gamecore
	--m_CO2tabs.CenterAlignTabs(-2);	

	-- Lua Events
	LuaEvents.GameDebug_Return.Add(OnGameDebugReturn);
	LuaEvents.Launchbar_ToggleClimateScreen.Add( OnToggleClimateScreen )
	LuaEvents.Launchbar_Expansion2_ClimateScreen_Close.Add( OnClose );
end

-- ===========================================================================
--	Hot Reload Related Events
-- ===========================================================================
function OnInit(isReload:boolean)
	LateInitialize();
	if isReload then
		LuaEvents.GameDebug_GetValues(RELOAD_CACHE_ID);
	end
end

-- ===========================================================================
function OnShutdown()
	LuaEvents.GameDebug_AddValue(RELOAD_CACHE_ID, "isHidden", ContextPtr:IsHidden());
	LuaEvents.GameDebug_AddValue(RELOAD_CACHE_ID, "m_currentTabName", m_currentTabName);
end

-- ===========================================================================
function OnGameDebugReturn(context:string, contextTable:table)
	if context ~= RELOAD_CACHE_ID then return; end
	m_currentTabName = contextTable["m_currentTabName"];
	if contextTable["isHidden"] ~= nil and not contextTable["isHidden"] then
		Open(m_currentTabName);
	end
end

-- ===========================================================================
function OnPlayerTurnActivated( ePlayer:number, isFirstTime:boolean )
	if ContextPtr:IsHidden() == false and ePlayer == Game.GetLocalPlayer() then		
		Open(m_currentTabName);
	end
end

-- ===========================================================================
function OnLocalPlayerTurnEnd()
	if GameConfiguration.IsHotseat() and ContextPtr:IsVisible() then
		Close();
	end
end

-- ===========================================================================
-- Remember the current CO2 footprint for use in the next turn
function OnTurnEnd()
	m_prevTurnNum = Game.GetCurrentGameTurn();
	m_prevTurnCO2 = GameClimate.GetTotalCO2Footprint();
end

-- ===========================================================================
function Initialize()

	-- Re-used local variables:
	local worldAgeNum	:number;
	local query			:string;
	local pResults		:table;
	local kResult		:table;
	
	worldAgeNum	= MapConfiguration.GetValue("world_age");
	if worldAgeNum then
		query = "SELECT * FROM DomainValues where Domain = 'WorldAge' and Value = ? LIMIT 1";
		pResults = DB.ConfigurationQuery(query, worldAgeNum);
		kResult	= pResults[1];
		if kResult ~= nil then
			m_worldAgeName = Locale.Lookup( kResult.Name );
		end
	end

	local realismLevel:number = GameConfiguration.GetValue("GAME_REALISM");
	if realismLevel then
		query = "SELECT * FROM RealismSettings ORDER BY rowid";
		pResults = DB.Query(query);
		kResult	 = pResults[realismLevel + 1];
		if kResult ~= nil then
			m_RealismName = Locale.Lookup( kResult.Name );
		end
	end
	
	m_CO2For1Phase = math.floor(GameInfo.Maps_XP2[Map.GetMapSize()].CO2For1DegreeTempRise/1000); -- Infixo 2022-12-21

	UpdateClimateChangeEventsData();	-- Required for phase segment initialization.
	
	for phase=1,MAX_PHASES,1 do
		InitPhaseSegment(phase);		
	end

	-- UI Events
	ContextPtr:SetInitHandler( OnInit );
	ContextPtr:SetShutdown( OnShutdown );
	ContextPtr:SetInputHandler( OnInputHandler, true );

	-- UI Controls
	Controls.ModalScreenTitle:SetText(Locale.ToUpper("LOC_CLIMATE_TITLE"));
	Controls.ModalScreenClose:RegisterCallback(Mouse.eLClick, OnClose);

	-- Game Events
	Events.PlayerTurnActivated.Add( OnPlayerTurnActivated );
	Events.LocalPlayerTurnEnd.Add( OnLocalPlayerTurnEnd );
	Events.TurnEnd.Add( OnTurnEnd ); -- Infixo 2022-12-21

	m_TopPanelHeight = Controls.Vignette:GetSizeY() - TOP_PANEL_OFFSET;

end

--No capability means never initialize this so it can never be used.
if GameCapabilities.HasCapability("CAPABILITY_WORLD_CLIMATE_VIEW") then
	Initialize();
end

print("OK loaded ClimateScreen.lua from Better Climate Screen");