print("Loading ReportScreen_RiseFall.lua from Better Report Screen");
--[[
-- Copyright (c) 2017 Firaxis Games
--]]
-- ===========================================================================
-- INCLUDE BASE FILE
-- ===========================================================================
include("ReportScreen");


function city_fields( kCityData, pCityInstance )

	local function ColorRed(text) return("[COLOR_Red]"..tostring(text).."[ENDCOLOR]"); end -- Infixo: helper

	-- Infixo: status will show various icons
	--pCityInstance.Status:SetText( kCityData.IsUnderSiege and Locale.Lookup("LOC_HUD_REPORTS_STATUS_UNDER_SEIGE") or Locale.Lookup("LOC_HUD_REPORTS_STATUS_NORMAL") );
	local sStatusText:string = "";
	if kCityData.Population > kCityData.Housing then sStatusText = sStatusText.."[ICON_HousingInsufficient]"; end -- insufficient housing
	if kCityData.AmenitiesNum < kCityData.AmenitiesRequiredNum then sStatusText = sStatusText.."[ICON_AmenitiesInsufficient]"; end -- insufficient amenities
	if kCityData.IsUnderSiege then sStatusText = sStatusText.."[ICON_UnderSiege]"; end -- under siege
	if kCityData.Occupied then sStatusText = sStatusText.."[ICON_Occupied]"; end -- occupied
	pCityInstance.Status:SetText( sStatusText );
	
	-- CityName
	pCityInstance.CityName:SetText( Locale.Lookup( kCityData.CityName ) );
	
	-- Population and Housing
	--pCityInstance.Population:SetText( tostring(kCityData.Population) ); -- Infixo
	if kCityData.Population > kCityData.Housing then
		pCityInstance.Population:SetText( tostring(kCityData.Population) .. " / "..ColorRed(kCityData.Housing));
	else
		pCityInstance.Population:SetText( tostring(kCityData.Population) .. " / " .. tostring(kCityData.Housing));
	end
	--pCityInstance.Housing:SetText( tostring( kCityData.Housing ) );
	
	-- GrowthRateStatus
	if kCityData.HousingMultiplier == 0 or kCityData.Occupied then
		status = "LOC_HUD_REPORTS_STATUS_HALTED";
	elseif kCityData.HousingMultiplier <= 0.5 then
		status = "LOC_HUD_REPORTS_STATUS_SLOWED";
	else
		status = "LOC_HUD_REPORTS_STATUS_NORMAL";
	end
	pCityInstance.GrowthRateStatus:SetText( Locale.Lookup(status) );

	-- Amenities and Happiness
	if kCityData.AmenitiesNum < kCityData.AmenitiesRequiredNum then
		pCityInstance.Amenities:SetText( ColorRed(kCityData.AmenitiesNum).." / "..tostring(kCityData.AmenitiesRequiredNum) );
	else
		pCityInstance.Amenities:SetText( tostring(kCityData.AmenitiesNum).." / "..tostring(kCityData.AmenitiesRequiredNum) );
	end
	local happinessText:string = Locale.Lookup( GameInfo.Happinesses[kCityData.Happiness].Name );
	pCityInstance.CitizenHappiness:SetText( happinessText );

	-- WarWeariness, Strength and Damage
	local warWearyValue:number = kCityData.AmenitiesLostFromWarWeariness;
	pCityInstance.WarWeariness:SetText( (warWearyValue==0) and "0" or ColorRed("-"..tostring(warWearyValue)) );
	pCityInstance.Strength:SetText( tostring(kCityData.Defense) );
	--pCityInstance.Damage:SetText( tostring(kCityData.Damage) );	-- Infixo
	if kCityData.HitpointsTotal > kCityData.HitpointsCurrent then
		pCityInstance.Damage:SetText( ColorRed(kCityData.HitpointsTotal - kCityData.HitpointsCurrent) );
	else
		pCityInstance.Damage:SetText( "0" );
	end

	-- Loyalty -- Infixo: this is not stored - try to store it for sorting later!
	local pCulturalIdentity = kCityData.City:GetCulturalIdentity();
	local currentLoyalty = pCulturalIdentity:GetLoyalty();
	local maxLoyalty = pCulturalIdentity:GetMaxLoyalty();
	local loyaltyPerTurn:number = pCulturalIdentity:GetLoyaltyPerTurn();
	local loyaltyFontIcon:string = loyaltyPerTurn >= 0 and "[ICON_PressureUp]" or "[ICON_PressureDown]";
	pCityInstance.Loyalty:SetText(loyaltyFontIcon .. " " .. Round(currentLoyalty, 1) .. "/" .. maxLoyalty);
	kCityData.Loyalty = currentLoyalty; -- Infixo: store for sorting

	-- Governor -- Infixo: this is not stored neither
	local pAssignedGovernor = kCityData.City:GetAssignedGovernor();
	if pAssignedGovernor then
		local eGovernorType = pAssignedGovernor:GetType();
		local governorDefinition = GameInfo.Governors[eGovernorType];
		local governorMode = pAssignedGovernor:IsEstablished() and "_FILL" or "_SLOT";
		local governorIcon = "ICON_" .. governorDefinition.GovernorType .. governorMode;
		pCityInstance.Governor:SetText("[" .. governorIcon .. "]");
		kCityData.Governor = governorDefinition.GovernorType;
	else
		pCityInstance.Governor:SetText("");
		kCityData.Governor = "";
	end

end

function ViewCityStatusPage()	

	ResetTabForNewPageContent()

	local instance:table = m_simpleIM:GetInstance()
	instance.Top:DestroyAllChildren()
	
	instance.Children = {}
	instance.Descend = false
	
	local pHeaderInstance:table = {}
	ContextPtr:BuildInstanceForControl( "CityStatusHeaderInstance", pHeaderInstance, instance.Top )
	
	pHeaderInstance.CityNameButton:RegisterCallback( Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_cities( "name", instance ) end )
	pHeaderInstance.CityGovernorButton:RegisterCallback( Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_cities( "gover", instance ) end ) -- Infixo
	pHeaderInstance.CityLoyaltyButton:RegisterCallback( Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_cities( "loyal", instance ) end ) -- Infixo
	pHeaderInstance.CityPopulationButton:RegisterCallback( Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_cities( "pop", instance ) end )
	--pHeaderInstance.CityHousingButton:RegisterCallback( Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_cities( "house", instance ) end )
	pHeaderInstance.CityGrowthButton:RegisterCallback( Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_cities( "growth", instance ) end )
	pHeaderInstance.CityAmenitiesButton:RegisterCallback( Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_cities( "amen", instance ) end )
	pHeaderInstance.CityHappinessButton:RegisterCallback( Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_cities( "happy", instance ) end )
	pHeaderInstance.CityWarButton:RegisterCallback( Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_cities( "war", instance ) end )
	pHeaderInstance.CityStatusButton:RegisterCallback( Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_cities( "status", instance ) end )
	pHeaderInstance.CityStrengthButton:RegisterCallback( Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_cities( "str", instance ) end )
	pHeaderInstance.CityDamageButton:RegisterCallback( Mouse.eLClick, function() instance.Descend = not instance.Descend; sort_cities( "dam", instance ) end )

	-- 
	for cityName,kCityData in pairs( m_kCityData ) do

		local pCityInstance:table = {}

		ContextPtr:BuildInstanceForControl( "CityStatusEntryInstance", pCityInstance, instance.Top )
		table.insert( instance.Children, pCityInstance )
		
		city_fields( kCityData, pCityInstance )
			
	end

	Controls.Stack:CalculateSize();
	Controls.Scroll:CalculateSize();

	Controls.CityBuildingsCheckbox:SetHide( true ) --BRS
	Controls.CollapseAll:SetHide( true );
	Controls.BottomYieldTotals:SetHide( true );
	Controls.BottomResourceTotals:SetHide( true );
	Controls.Scroll:SetSizeY( Controls.Main:GetSizeY() - 88);
end

function sort_cities( type, instance )

	local i = 0
	
	for _, kCityData in spairs( m_kCityData, function( t, a, b ) return city_sortFunction( instance.Descend, type, t, a, b ); end ) do
		i = i + 1
		local cityInstance = instance.Children[i]
		
		city_fields( kCityData, cityInstance )
	end
	
end

function city_sortFunction( descend, type, t, a, b )

	local aCity = 0
	local bCity = 0
	
	if type == "name" then
		aCity = Locale.Lookup( t[a].CityName )
		bCity = Locale.Lookup( t[b].CityName )
	elseif type == "gover" then
		aCity = t[a].Governor
		bCity = t[b].Governor
	elseif type == "loyal" then
		aCity = t[a].Loyalty
		bCity = t[b].Loyalty
	elseif type == "pop" then
		aCity = t[a].Population
		bCity = t[b].Population
		if aCity == bCity then -- same pop, sort by Housing
			aCity = t[a].Housing
			bCity = t[b].Housing
		end
	elseif type == "house" then -- Infixo: can leave it, will not be used
		aCity = t[a].Housing
		bCity = t[b].Housing
	elseif type == "amen" then
		aCity = t[a].AmenitiesNum
		bCity = t[b].AmenitiesNum
	elseif type == "happy" then
		aCity = t[a].Happiness
		bCity = t[b].Happiness
	elseif type == "growth" then
		aCity = t[a].HousingMultiplier
		bCity = t[b].HousingMultiplier
	elseif type == "war" then
		aCity = t[a].AmenitiesLostFromWarWeariness
		bCity = t[b].AmenitiesLostFromWarWeariness
	elseif type == "status" then
		if t[a].IsUnderSiege == false then aCity = 10 else aCity = 20 end
		if t[b].IsUnderSiege == false then bCity = 10 else bCity = 20 end
	elseif type == "str" then
		aCity = t[a].Defense
		bCity = t[b].Defense
	elseif type == "dam" then
		aCity = t[a].Damage
		bCity = t[b].Damage
	end
	
	if descend then return bCity > aCity else return bCity < aCity end

end

--[[ Infixo
function ViewCityStatusPage()

	ResetTabForNewPageContent();

	local instance:table = m_simpleIM:GetInstance();	
	instance.Top:DestroyAllChildren();
	
	local pHeaderInstance:table = {}
	ContextPtr:BuildInstanceForControl( "CityStatusHeaderInstance", pHeaderInstance, instance.Top ) ;	

	-- 
	for cityName,kCityData in pairs(m_kCityData) do

		local pCityInstance:table = {}
		ContextPtr:BuildInstanceForControl( "CityStatusEntryInstance", pCityInstance, instance.Top ) ;	
		TruncateStringWithTooltip(pCityInstance.CityName, 130, Locale.Lookup(kCityData.CityName)); 
		pCityInstance.Population:SetText( tostring(kCityData.Population) .. "/" .. tostring(kCityData.Housing));

		if kCityData.HousingMultiplier == 0 or kCityData.Occupied then
			status = "LOC_HUD_REPORTS_STATUS_HALTED";
		elseif kCityData.HousingMultiplier <= 0.5 then
			status = "LOC_HUD_REPORTS_STATUS_SLOWED";
		else
			status = "LOC_HUD_REPORTS_STATUS_NORMAL";
		end
		pCityInstance.GrowthRateStatus:SetText( Locale.Lookup(status) );

		pCityInstance.Amenities:SetText( tostring(kCityData.AmenitiesNum).." / "..tostring(kCityData.AmenitiesRequiredNum) );

		local happinessText:string = Locale.Lookup( GameInfo.Happinesses[kCityData.Happiness].Name );
		pCityInstance.CitizenHappiness:SetText( happinessText );

		local warWearyValue:number = kCityData.AmenitiesLostFromWarWeariness;
		pCityInstance.WarWeariness:SetText( (warWearyValue==0) and "0" or "-"..tostring(warWearyValue) );

		-- Loyalty
		local pCulturalIdentity = kCityData.City:GetCulturalIdentity();
		local currentLoyalty = pCulturalIdentity:GetLoyalty();
		local maxLoyalty = pCulturalIdentity:GetMaxLoyalty();
		local loyaltyPerTurn:number = pCulturalIdentity:GetLoyaltyPerTurn();
		local loyaltyFontIcon:string = loyaltyPerTurn >= 0 and "[ICON_PressureUp]" or "[ICON_PressureDown]";
		pCityInstance.Loyalty:SetText(loyaltyFontIcon .. " " .. Round(currentLoyalty, 1) .. "/" .. maxLoyalty);

		local pAssignedGovernor = kCityData.City:GetAssignedGovernor();
		if pAssignedGovernor then
			local eGovernorType = pAssignedGovernor:GetType();
			local governorDefinition = GameInfo.Governors[eGovernorType];
			local governorMode = pAssignedGovernor:IsEstablished() and "_FILL" or "_SLOT";
			local governorIcon = "ICON_" .. governorDefinition.GovernorType .. governorMode;
			pCityInstance.Governor:SetText("[" .. governorIcon .. "]");
		else
			pCityInstance.Governor:SetText("");
		end

		pCityInstance.Strength:SetText( tostring(kCityData.Defense) );
		pCityInstance.Damage:SetText( tostring(kCityData.HitpointsTotal - kCityData.HitpointsCurrent) );			
	end

	Controls.Stack:CalculateSize();
	Controls.Scroll:CalculateSize();

	Controls.CollapseAll:SetHide(true);
	Controls.BottomYieldTotals:SetHide( true );
	Controls.BottomResourceTotals:SetHide( true );
	Controls.Scroll:SetSizeY( Controls.Main:GetSizeY() - 88);
end
--]]

function Initialize()

	m_tabIM:ResetInstances();
	m_tabs = CreateTabs( Controls.TabContainer, 42, 34, 0xFF331D05 );
	AddTabSection( "LOC_HUD_REPORTS_TAB_YIELDS",		ViewYieldsPage );
	AddTabSection( "LOC_HUD_REPORTS_TAB_RESOURCES",		ViewResourcesPage );
	AddTabSection( "LOC_HUD_REPORTS_TAB_CITY_STATUS",	ViewCityStatusPage );	
	AddTabSection( "LOC_HUD_REPORTS_TAB_DEALS",			ViewDealsPage );
	AddTabSection( "LOC_HUD_REPORTS_TAB_UNITS",			ViewUnitsPage );

	m_tabs.SameSizedTabs(50);
	m_tabs.CenterAlignTabs(-10);	
end
Initialize();

print("OK loaded ReportScreen_RiseFall.lua from Better Report Screen");