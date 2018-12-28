﻿print("Loading GreatPeoplePopup.lua from RGP Mod, version 2.0");
-- ===========================================================================
--  Great People Popup
-- ===========================================================================

include("InstanceManager");
include("TabSupport");
include("SupportFunctions");
include("Civ6Common"); --DifferentiateCivs
include("ModalScreen_PlayerYieldsHelper");
include("GameCapabilities");

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


-- ===========================================================================
--  CONSTANTS
-- ===========================================================================
local COLOR_CLAIMED       : number = 0xffffffff;
local COLOR_AVAILABLE     : number = 0xbbffffff;
local COLOR_UNAVAILABLE     : number = 0x55ffffff;
local MAX_BIOGRAPHY_PARAGRAPHS  : number = 9;           -- maximum # of paragraphs for a biography
local MIN_WIDTH         : number = 285 * 2;         -- minimum width of screen (instance size x # of panels)
local RELOAD_CACHE_ID     : string = "GreatPeoplePopup";    -- hotloading
local SIZE_ACTION_ICON      : number = 38;
local MAX_BEFORE_TRUNC_IND_NAME : number = 220;

-- ===========================================================================
--  VARIABLES
-- ===========================================================================

local m_greatPersonPanelIM  :table  = InstanceManager:new("PanelInstance",        "Content",  Controls.PeopleStack);
local m_greatPersonRowIM  :table  = InstanceManager:new("PastRecruitmentInstance",  "Content",  Controls.RecruitedStack);
local m_uiGreatPeople   :table;
local m_kData       :table;
local m_activeBiographyID :number = -1; -- Only allow one open at a time (or very quick exceed font allocation)
local m_tabs        :table;
local m_defaultPastRowHeight    :number = -1; -- Default/mix height (from XML) for a previously recruited row
local m_screenWidth			:number = -1;
local _, m_ActscreenHeight = UIManager:GetScreenSizeVal();
local m_ModalFrameBaseSize = Controls.ModalFrame:GetSizeY();
local m_WoodPanelingBaseSize = Controls.WoodPaneling:GetSizeY();
local m_PopupContainerBaseSize = Controls.PopupContainer:GetSizeY();

-- Filters (pulldowns)
local m_filterClassID:number = -1; -- -1 for All, >-1 for Great Person Class ID
local m_filterPlayerID:number = -1; -- -1 for All, >-1 for Player ID (as in GetLocalPlayer() or Players[])

-- ===========================================================================
function GetActivationEffectTextByGreatPersonClass( greatPersonClassID:number )
  local text;
  if ((GameInfo.GreatPersonClasses["GREAT_PERSON_CLASS_WRITER"] ~= nil and greatPersonClassID == GameInfo.GreatPersonClasses["GREAT_PERSON_CLASS_WRITER"].Index) or
    (GameInfo.GreatPersonClasses["GREAT_PERSON_CLASS_ARTIST"] ~= nil and greatPersonClassID == GameInfo.GreatPersonClasses["GREAT_PERSON_CLASS_ARTIST"].Index) or
    (GameInfo.GreatPersonClasses["GREAT_PERSON_CLASS_MUSICIAN"] ~= nil and greatPersonClassID == GameInfo.GreatPersonClasses["GREAT_PERSON_CLASS_MUSICIAN"].Index)) then
    text = Locale.Lookup("LOC_GREAT_PEOPLE_WORK_CREATED");
  else
    text = Locale.Lookup("LOC_GREAT_PEOPLE_PERSON_ACTIVATED");
  end
  return text;
end

-- ===========================================================================
--  Helper to obtain biography text.
--  individualID  index of the great person
--  RETURNS:    oreder table of biography text.
-- ===========================================================================
function GetBiographyTextTable( individualID:number )

  if individualID == nil then
    return {};
  end

  -- LOC_PEDIA_GREATPEOPLE_PAGE_GREAT_PERSON_INDIVIDUAL_ABU_AL_QASIM_AL_ZAHRAWI_CHAPTER_HISTORY_PARA_1
  -- LOC_PEDIA_GREATPEOPLE_PAGE_GREAT_PERSON_INDIVIDUAL_ABDUS_SALAM_CHAPTER_HISTORY_PARA_3
  local bioPrefix :string = "LOC_PEDIA_GREATPEOPLE_PAGE_";
  local bioName :string = GameInfo.GreatPersonIndividuals[individualID].GreatPersonIndividualType;
  local bioPostfix:string = "_CHAPTER_HISTORY_PARA_";

  local kBiography:table = {};
  for i:number = 1,MAX_BIOGRAPHY_PARAGRAPHS,1 do
    local key:string = bioPrefix..bioName..bioPostfix..tostring(i);
    if Locale.HasTextKey(key) then
      kBiography[i] = Locale.Lookup(key);
    else
      break;
    end
  end
  return kBiography;
end


-- ===========================================================================
--  View the great people currently available (to be purchased)
-- ===========================================================================
function ViewCurrent( data:table )
  if (data == nil) then
    UI.DataError("GreatPeople attempting to view current timeline data but received NIL instead.");
    return;
  end

  m_uiGreatPeople = {};
  m_greatPersonPanelIM:ResetInstances();
  Controls.PeopleScroller:SetHide(false);
  Controls.RecruitedArea:SetHide(true);

  -- Infixo: moving the Great Prophet to the end
  local eClassProphet = GameInfo.GreatPersonClasses["GREAT_PERSON_CLASS_PROPHET"].Index;
  local iNumGPs = #GameInfo.GreatPersonClasses;  -- num of GPs classes
  if table.count(data.Timeline) == iNumGPs then  -- just a precaution, should always be equal
    --dprint("Moving Great Prophet to the end");
	local temp = data.Timeline[eClassProphet+1];
	for i=eClassProphet+1, iNumGPs-1, 1 do data.Timeline[i] = data.Timeline[i+1]; end
	data.Timeline[iNumGPs] = temp;
  end

  local firstAvailableIndex :number = 0;
  local preferedRecruitScrollSize = 0;
  local isPreferedRecruitScrollSizeComputed:boolean = false;
  for i, kPerson:table in ipairs(data.Timeline) do

    local instance    :table = m_greatPersonPanelIM:GetInstance();
    local classData   :table = GameInfo.GreatPersonClasses[kPerson.ClassID];
    local individualData:table = GameInfo.GreatPersonIndividuals[kPerson.IndividualID];
    local classText   :string = "";

    -- Infixo: moving the Great Prophet to the end
	local eClassID = kPerson.ClassID;
	--dprint("BEFORE: i,eClassID,eCP,tabcnt", i, eClassID, eClassProphet, table.count(data.Timeline));
	if kPerson.ClassID == nil then
		if i == iNumGPs then eClassID = eClassProphet;
		elseif i < eClassProphet+1 then eClassID = i-1;
		else eClassID = i; end
	end
	--dprint("AFTER: i,eClassID", i, eClassID);
    instance.ClassName:SetText(Locale.Lookup(GameInfo.GreatPersonClasses[eClassID].Name));

  --CQUI Changes to Keep Great Person Class Label even when all are claimed

  --[[if (kPerson.ClassID ~= nil) then
      classText = Locale.Lookup(classData.Name);
      instance.ClassName:SetText(classText);
    --end
  if(i==1) then
    instance.ClassName:SetText(Locale.Lookup("LOC_GREAT_PERSON_CLASS_GENERAL_NAME"));
  elseif(i==2) then
      instance.ClassName:SetText(Locale.Lookup("LOC_GREAT_PERSON_CLASS_ADMIRAL_NAME"));
  elseif(i==3) then
    instance.ClassName:SetText(Locale.Lookup("LOC_GREAT_PERSON_CLASS_ENGINEER_NAME"));
  elseif(i==4) then
    instance.ClassName:SetText(Locale.Lookup("LOC_GREAT_PERSON_CLASS_MERCHANT_NAME"));
  elseif(i==5) then
    instance.ClassName:SetText(Locale.Lookup("LOC_GREAT_PERSON_CLASS_PROPHET_NAME"));
  elseif(i==6) then
    instance.ClassName:SetText(Locale.Lookup("LOC_GREAT_PERSON_CLASS_SCIENTIST_NAME"));
  elseif(i==7) then
    instance.ClassName:SetText(Locale.Lookup("LOC_GREAT_PERSON_CLASS_WRITER_NAME"));
  elseif(i==8) then
    instance.ClassName:SetText(Locale.Lookup("LOC_GREAT_PERSON_CLASS_ARTIST_NAME"));
  else
    instance.ClassName:SetText(Locale.Lookup("LOC_GREAT_PERSON_CLASS_MUSICIAN_NAME"));
  end
	--]]

    if kPerson.IndividualID ~= nil then
      local individualName:string = Locale.ToUpper(kPerson.Name);
      instance.IndividualName:SetText( individualName );
      --TruncateStringWithTooltip(instance.IndividualName, MAX_BEFORE_TRUNC_IND_NAME, individualName);
    end

    if kPerson.EraID ~= nil then
      local eraName:string = Locale.ToUpper(Locale.Lookup(GameInfo.Eras[kPerson.EraID].Name));
      instance.EraName:SetText( eraName );
    end

    -- Grab icon representing type of class
    if (kPerson.ClassID ~= nil) then
      local icon:string = "ICON_" .. classData.GreatPersonClassType;
	  --dprint("icon string", icon);
      local textureOffsetX:number, textureOffsetY:number, textureSheet:string = IconManager:FindIconAtlas(icon, 50);
	  --dprint("icon texture X, Y, Sheet", textureOffsetX, textureOffsetY, textureSheet);
      if textureSheet == nil then   -- Use default if none found
        print("WARNING: Could not find icon atlas entry for the class of Great Person '"..icon.."', using default instead.");
        textureOffsetX = 0;
        textureOffsetY = 0;
        textureSheet = "GreatPeopleClass50";
      end
      instance.ClassImage:SetTexture( textureOffsetX, textureOffsetY, textureSheet );
	  -- Infixo
      --instance.ClassImage:SetSizeVal(45,45);
    end

    -- Grab icon of the great person themselves; first try a specific image, if it doesn't exist
    -- then grab a generic representation based on the class.
	--dprint("ClassID, IndividualID", kPerson.ClassID, kPerson.IndividualID);
    if (kPerson.ClassID ~= nil) and (kPerson.IndividualID ~= nil) then
      local portrait:string = "ICON_" .. individualData.GreatPersonIndividualType;
      textureOffsetX, textureOffsetY, textureSheet = IconManager:FindIconAtlas(portrait, 160);
	  --dprint("icon: portrait, OffX, OffY, Sheet", portrait, textureOffsetX, textureOffsetY, textureSheet);
      if textureSheet == nil then   -- Use a default if none found
        print("WARNING: Could not find icon atlas entry for the individual Great Person '"..portrait.."', using default instead.");
        portrait = "ICON_GENERIC_" .. classData.GreatPersonClassType .. "_" .. individualData.Gender;
        portrait = portrait:gsub("_CLASS","_INDIVIDUAL");
      end
      local isValid = instance.Portrait:SetIcon(portrait);
      if (not isValid) then
        UI.DataError("Could not find icon for "..portrait);
      end
    end

    if instance["m_EffectsIM"] ~= nil then
      instance["m_EffectsIM"]:ResetInstances();
    else
      instance["m_EffectsIM"] = InstanceManager:new("EffectInstance", "Top",  instance.EffectStack);
    end

    if kPerson.PassiveNameText ~= nil and kPerson.PassiveNameText ~= "" then
      local effectInst:table  = instance["m_EffectsIM"]:GetInstance();
      local effectText:string = kPerson.PassiveEffectText;
      local fullText:string = kPerson.PassiveNameText .. "[NEWLINE][NEWLINE]" .. effectText;
      effectInst.Text:SetText( effectText );
      effectInst.EffectTypeIcon:SetToolTipString( fullText );
      effectInst.PassiveAbilityIcon:SetHide(false);
      effectInst.ActiveAbilityIcon:SetHide(true);
    end

    if (kPerson.ActionNameText ~= nil and kPerson.ActionNameText ~= "") then
      local effectInst:table  = instance["m_EffectsIM"]:GetInstance();
      local effectText:string = kPerson.ActionEffectText;
      local fullText:string = kPerson.ActionNameText;
      if (kPerson.ActionCharges > 0) then
        fullText = fullText .. " (" .. Locale.Lookup("LOC_GREATPERSON_ACTION_CHARGES", kPerson.ActionCharges) .. ")";
      end
      fullText = fullText .. "[NEWLINE]" .. kPerson.ActionUsageText;
      fullText = fullText .. "[NEWLINE][NEWLINE]" .. effectText;
      effectInst.Text:SetText( effectText );
      effectInst.EffectTypeIcon:SetToolTipString( fullText );

      local actionIcon:string = classData.ActionIcon;
      if actionIcon ~= nil and actionIcon ~= "" then
        local textureOffsetX:number, textureOffsetY:number, textureSheet:string = IconManager:FindIconAtlas(actionIcon, SIZE_ACTION_ICON);
        if(textureSheet == nil or textureSheet == "") then
          UI.DataError("Could not find icon in ViewCurrent: icon=\""..actionIcon.."\", iconSize="..tostring(SIZE_ACTION_ICON) );
        else
          effectInst.ActiveAbilityIcon:SetTexture(textureOffsetX, textureOffsetY, textureSheet);
          effectInst.ActiveAbilityIcon:SetHide(false);
          effectInst.PassiveAbilityIcon:SetHide(true);
        end
      else
        effectInst.ActiveAbilityIcon:SetHide(true);
      end
    end

    if instance["m_RecruitIM"] ~= nil then
      instance["m_RecruitIM"]:ResetInstances();
    else
      instance["m_RecruitIM"] = InstanceManager:new("RecruitInstance", "Top", instance.RecruitStack);
    end

    if kPerson.IndividualID ~= nil and kPerson.ClassID ~= nil then

      -- Buy via gold
      if (HasCapability("CAPABILITY_GREAT_PEOPLE_RECRUIT_WITH_GOLD") and (not kPerson.CanRecruit and not kPerson.CanReject and kPerson.PatronizeWithGoldCost ~= nil and kPerson.PatronizeWithGoldCost < 1000000)) then
        instance.GoldButton:SetText(kPerson.PatronizeWithGoldCost .. "[ICON_Gold]");
        instance.GoldButton:SetToolTipString(GetPatronizeWithGoldTT(kPerson));
        instance.GoldButton:SetVoid1(kPerson.IndividualID);
        instance.GoldButton:RegisterCallback(Mouse.eLClick, OnGoldButtonClick);
        instance.GoldButton:SetDisabled(not kPerson.CanPatronizeWithGold);
        instance.GoldButton:SetHide(false);
      else
        instance.GoldButton:SetHide(true);
      end

      -- Buy via Faith
      if (HasCapability("CAPABILITY_GREAT_PEOPLE_RECRUIT_WITH_FAITH") and (not kPerson.CanRecruit and not kPerson.CanReject and kPerson.PatronizeWithFaithCost ~= nil and kPerson.PatronizeWithFaithCost < 1000000)) then
        instance.FaithButton:SetText(kPerson.PatronizeWithFaithCost .. "[ICON_Faith]");
        instance.FaithButton:SetToolTipString(GetPatronizeWithFaithTT(kPerson));
        instance.FaithButton:SetVoid1(kPerson.IndividualID);
        instance.FaithButton:RegisterCallback(Mouse.eLClick, OnFaithButtonClick);
        instance.FaithButton:SetDisabled(not kPerson.CanPatronizeWithFaith);
        instance.FaithButton:SetHide(false);
      else
        instance.FaithButton:SetHide(true);
      end

      -- Recruiting
      if (HasCapability("CAPABILITY_GREAT_PEOPLE_CAN_RECRUIT") and kPerson.CanRecruit and kPerson.RecruitCost ~= nil) then
        instance.RecruitButton:SetToolTipString( Locale.Lookup("LOC_GREAT_PEOPLE_RECRUIT_DETAILS", kPerson.RecruitCost) );
        instance.RecruitButton:SetVoid1(kPerson.IndividualID);
        instance.RecruitButton:RegisterCallback(Mouse.eLClick, OnRecruitButtonClick);
        instance.RecruitButton:SetHide(false);

        -- Auto scroll to first recruitable person.
        if kInstanceToShow==nil then
          kInstanceToShow = instance;
        end
      else
        instance.RecruitButton:SetHide(true);
      end

      -- Rejecting
      if (HasCapability("CAPABILITY_GREAT_PEOPLE_CAN_REJECT") and kPerson.CanReject and kPerson.RejectCost ~= nil) then
        instance.RejectButton:SetToolTipString( Locale.Lookup("LOC_GREAT_PEOPLE_PASS_DETAILS", kPerson.RejectCost ) );
        instance.RejectButton:SetVoid1(kPerson.IndividualID);
        instance.RejectButton:RegisterCallback(Mouse.eLClick, OnRejectButtonClick);
        instance.RejectButton:SetHide(false);
      else
        instance.RejectButton:SetHide(true);
      end

      -- Recruiting standings
      -- Let's sort the table first by points total, then by the lower player id (to push yours toward the top of the list for readability)
      local recruitTable: table = {};
      for i, kPlayerPoints in ipairs(data.PointsByClass[kPerson.ClassID]) do
        table.insert(recruitTable,kPlayerPoints);
      end
      table.sort(recruitTable,
        function (a,b)
          if(a.PointsTotal == b.PointsTotal) then
            return a.PlayerID < b.PlayerID;
          else
            return a.PointsTotal > b.PointsTotal;
          end
          end);

      for i, kPlayerPoints in ipairs(recruitTable) do
        local canEarnAnotherOfThisClass:boolean = true;
        if (kPlayerPoints.MaxPlayerInstances ~= nil and kPlayerPoints.NumInstancesEarned ~= nil) then
          canEarnAnotherOfThisClass = kPlayerPoints.MaxPlayerInstances > kPlayerPoints.NumInstancesEarned;
        end
        if (canEarnAnotherOfThisClass) then
          local recruitInst:table = instance["m_RecruitIM"]:GetInstance();
          if not isPreferedRecruitScrollSizeComputed then
            preferedRecruitScrollSize = preferedRecruitScrollSize + recruitInst.Top:GetSizeY() + 5; -- AZURENCY : 5 is the padding
          end
          recruitInst.Country:SetText( kPlayerPoints.PlayerName );
          --recruitInst.Amount:SetText( tostring(Round(kPlayerPoints.PointsTotal,1)) .. "/" .. tostring(kPerson.RecruitCost) );

          -- CQUI Points Per Turn and Turns Left -- Add the turn icon into the text
          --recruitTurnsLeft gets +0.5 so that's rounded up
          local recruitTurnsLeft = Round((kPerson.RecruitCost-kPlayerPoints.PointsTotal)/kPlayerPoints.PointsPerTurn + 0.5,0);
          if(recruitTurnsLeft == math.huge) then recruitTurnsLeft = "∞"; end
          recruitInst.CQUI_PerTurn:SetText( "(+" .. tostring(Round(kPlayerPoints.PointsPerTurn,1)) .. ") " .. tostring(recruitTurnsLeft) .. "[ICON_Turn]");


          local progressPercent :number = Clamp( kPlayerPoints.PointsTotal / kPerson.RecruitCost, 0, 1 );
          recruitInst.ProgressBar:SetPercent( progressPercent );
          local recruitColorName:string = "GreatPeopleCS";
          if kPlayerPoints.IsPlayer then
            recruitColorName = "GreatPeopleActiveCS";
          end
          --recruitInst.Amount:SetColorByName( recruitColorName );
          recruitInst.CQUI_PerTurn:SetColorByName( recruitColorName );
          recruitInst.Country:SetColorByName( recruitColorName );
          --recruitInst.Country:SetColorByName( recruitColorName );
          recruitInst.ProgressBar:SetColorByName( recruitColorName );

          --local recruitDetails:string = Locale.Lookup("LOC_CQUI_GREAT_PERSON_PROGRESS") .. tostring(Round(kPlayerPoints.PointsTotal,1)) .. "/" .. tostring(kPerson.RecruitCost)
		  --.. "[NEWLINE]" .. Locale.Lookup("LOC_GREAT_PEOPLE_POINT_DETAILS", Round(kPlayerPoints.PointsPerTurn, 1), classData.IconString, classData.Name);
		  -- Infixo
          local recruitDetails:string = tostring(Round(kPlayerPoints.PointsTotal,1)).."/"..tostring(kPerson.RecruitCost)..": "..Locale.Lookup("LOC_GREAT_PEOPLE_POINT_DETAILS", Round(kPlayerPoints.PointsPerTurn, 1), classData.IconString, classData.Name);

          DifferentiateCiv(kPlayerPoints.PlayerID,recruitInst.CivIcon,recruitInst.CivIcon,recruitInst.CivBacking, nil, nil, Game.GetLocalPlayer());

          recruitInst.Top:SetToolTipString(recruitDetails);
        end
      end
      if not isPreferedRecruitScrollSizeComputed then isPreferedRecruitScrollSizeComputed = true; end

      local sRecruitText:string = Locale.Lookup("LOC_GREAT_PEOPLE_OR_RECRUIT_WITH_PATRONAGE");
      local sRecruitTooltip:string = "";
      if (kPerson.EarnConditions ~= nil and kPerson.EarnConditions ~= "") then
        sRecruitText = "[COLOR_Civ6Red]" .. Locale.Lookup("LOC_GREAT_PEOPLE_CANNOT_EARN_PERSON") .. "[ENDCOLOR]"
        sRecruitTooltip = "[COLOR_Civ6Red]" .. kPerson.EarnConditions .. "[ENDCOLOR]";
      end
      instance.RecruitInfo:SetText(sRecruitText);
      instance.RecruitInfo:SetToolTipString(sRecruitTooltip);

      instance.RecruitScroll:CalculateSize();
    end

    -- Set the biography button.
    if kPerson.IndividualID ~= nil then
      instance.BiographyBackButton:SetText( Locale.Lookup("LOC_GREAT_PEOPLE_BIOGRAPHY") );
      instance.BiographyBackButton:SetVoid1( kPerson.IndividualID );
      instance.BiographyBackButton:RegisterCallback( Mouse.eLClick, OnBiographyBackClick );
      m_uiGreatPeople[kPerson.IndividualID] = instance;   -- Store instance for later look up
    end

    local noneAvailable   :boolean = (kPerson.ClassID == nil);
    --instance.ClassName:SetHide( noneAvailable );
    instance.TitleLine:SetHide( noneAvailable );
    instance.IndividualName:SetHide( noneAvailable );
    instance.EraName:SetHide( noneAvailable );
    instance.MainInfo:SetHide( noneAvailable );
    instance.BiographyBackButton:SetHide( noneAvailable );
    instance.ClaimedLabel:SetHide( not noneAvailable );
    instance.BiographyArea:SetHide( true );

    instance.EffectStack:CalculateSize();
    instance.EffectStackScroller:CalculateSize();

	-- CQUI
	--[[
    if (m_PopupContainerBaseSize + preferedRecruitScrollSize - 86) > m_ActscreenHeight then -- AZURENCY : 86 is the default height of the recruit scroll
      preferedRecruitScrollSize = m_ActscreenHeight - 86 - 582 -- AZURENCY :  (582 = 768 (default popup height) - 186 (default recruit progress box height))
    end


    instance.RecruitScroll:SetSizeY(preferedRecruitScrollSize);
    instance.RecruitProgressBox:SetSizeY(preferedRecruitScrollSize + 114); -- (114 = 200 - 86)
    instance.Content:SetSizeY(preferedRecruitScrollSize + 574);
	--]]
	-- end CQUI
  end

  Controls.PeopleStack:CalculateSize();
  Controls.PeopleScroller:CalculateSize();

  -- CQUI
  --local newprefsize = preferedRecruitScrollSize - 96;
  --Controls.PopupContainer:SetSizeY(m_PopupContainerBaseSize + newprefsize);
  --Controls.WoodPaneling:SetSizeY(m_WoodPanelingBaseSize + newprefsize);
  --Controls.ModalFrame:SetSizeY(m_ModalFrameBaseSize + newprefsize);
  -- CQUI

  m_screenWidth = math.max(Controls.PeopleStack:GetSizeX(), 1024);
  Controls.WoodPaneling:SetSizeX( m_screenWidth );

  -- Clamp overall popup size to not be larger than contents (overspills in 4k and eyefinitiy rigs.)
  local screenX,_     :number = UIManager:GetScreenSizeVal();
  if m_screenWidth > screenX then
    m_screenWidth = screenX;
  end

  Controls.PopupContainer:SetSizeX( m_screenWidth );
  Controls.ModalFrame:SetSizeX( m_screenWidth );

  -- Has an instance been set to auto scroll to?
  Controls.PeopleScroller:SetScrollValue( 0 );		-- Either way reset scroll first (mostly for hot seat)
  if kInstanceToShow ~= nil then
    local contentWidth		:number = kInstanceToShow.Content:GetSizeX();
    local contentOffsetx	:number = kInstanceToShow.Content:GetScreenOffset();	-- Obtaining normal offset would yield 0, but since modal is as wide as the window, this works.
    local offsetx			:number = contentOffsetx + (contentWidth * 0.5) + (m_screenWidth * 0.5);	-- Middle of screen
    local totalWidth		:number = Controls.PeopleScroller:GetSizeX();
    local scrollAmt			:number =  offsetx / totalWidth;
    scrollAmt = math.clamp( scrollAmt, 0, 1);
    Controls.PeopleScroller:SetScrollValue( scrollAmt );
  end
end

function GetPatronizeWithGoldTT(kPerson)
  return Locale.Lookup("LOC_GREAT_PEOPLE_PATRONAGE_GOLD_DETAILS", kPerson.PatronizeWithGoldCost);
end

function GetPatronizeWithFaithTT(kPerson)
  return Locale.Lookup("LOC_GREAT_PEOPLE_PATRONAGE_FAITH_DETAILS", kPerson.PatronizeWithFaithCost);
end


-- =======================================================================================
-- Filters (pulldowns)
-- =======================================================================================

function ClassNameClicked(classID:number, className:string)
	--dprint("ClassNameClicked", classID, className);
	if m_filterClassID == classID then return; end -- selected the same, do nothing
	Controls.ClassNamePull:GetButton():LocalizeAndSetText( className );
	m_filterClassID = classID;
	Refresh();
end

function PopulateClassNamePull()
	--dprint("PopulateClassNamePull");

	-- Clear current filters
	Controls.ClassNamePull:ClearEntries();

	-- Add "All" Filter LOC_CATEGORY_GREAT_PEOPLE_NAME
	local controlTable = {};
	Controls.ClassNamePull:BuildEntry( "InstanceOne", controlTable );
	local sAllText:string = Locale.Lookup("LOC_ROUTECHOOSER_FILTER_ALL").." "..Locale.Lookup("LOC_GREAT_PEOPLE_TAB_GREAT_PEOPLE");
	controlTable.Button:LocalizeAndSetText( sAllText );
	controlTable.Button:RegisterCallback( Mouse.eLClick, function() ClassNameClicked(-1, sAllText); end );

	-- Add Filters by GP class
	for classInfo in GameInfo.GreatPersonClasses() do
		local classID = classInfo.Index;
		local className = classInfo.IconString.." "..Locale.Lookup(classInfo.Name);
		--AddFilterClassName( className, function(a) return true; end);  -- TODO!!!!!!!!!
		local controlTable = {};
		Controls.ClassNamePull:BuildEntry( "InstanceOne", controlTable );
		controlTable.Button:LocalizeAndSetText( className );
		controlTable.Button:RegisterCallback( Mouse.eLClick, function() ClassNameClicked(classID, className); end );
	end

	-- Select the first filter
	Controls.ClassNamePull:GetButton():LocalizeAndSetText( sAllText );
	m_filterClassID = -1;

	-- Calculate Internals
	Controls.ClassNamePull:CalculateInternals();
end

function CivLeaderClicked(playerID:number, playerName:string)
	--dprint("CivLeaderClicked", playerID, playerName);
	if m_filterPlayerID == playerID then return; end -- selected the same, do nothing
	Controls.CivLeaderPull:GetButton():LocalizeAndSetText( playerName );
	m_filterPlayerID = playerID;
	Refresh();
end

function PopulateCivLeaderPull()
	--dprint("PopulateCivLeaderPull");

	-- Clear current filters
	Controls.CivLeaderPull:ClearEntries();

	-- Add "All" Filter  LOC_GOVT_FILTER_NONE LOC_ROUTECHOOSER_FILTER_ALL  LOC_CATEGORY_GREAT_PEOPLE_NAME LOC_GREAT_PEOPLE_TAB_GREAT_PEOPLE
	local controlAll = {};
	Controls.CivLeaderPull:BuildEntry( "InstanceOne", controlAll );
	local sAllText:string = Locale.Lookup("LOC_ROUTECHOOSER_FILTER_ALL").." "..Locale.Lookup("LOC_PLAYERS");
	controlAll.Button:LocalizeAndSetText( sAllText );
	controlAll.Button:RegisterCallback( Mouse.eLClick, function() CivLeaderClicked(-1, sAllText); end );
	
	-- Add Local Player Filter
	local localPlayerConfig:table = PlayerConfigurations[Game.GetLocalPlayer()];
	local localPlayerName = Locale.Lookup( GameInfo.Civilizations[localPlayerConfig:GetCivilizationTypeID()].Name ).." - "..Locale.Lookup("LOC_GREAT_PEOPLE_RECRUITED_BY_YOU");
	local controlLocal = {};
	Controls.CivLeaderPull:BuildEntry( "InstanceOne", controlLocal );
	controlLocal.Button:LocalizeAndSetText( localPlayerName );
	controlLocal.Button:RegisterCallback( Mouse.eLClick, function() CivLeaderClicked(Game.GetLocalPlayer(), localPlayerName); end );

	-- Add Filters by Civ
	local players:table = Game.GetPlayers();
	for _, pPlayer in ipairs(players) do
		if pPlayer and pPlayer:IsAlive() and pPlayer:IsMajor() then
			-- Has the local player met the civ?
			if pPlayer:GetDiplomacy():HasMet(Game.GetLocalPlayer()) then
				local playerConfig:table = PlayerConfigurations[pPlayer:GetID()];
				local name = Locale.Lookup(GameInfo.Civilizations[playerConfig:GetCivilizationTypeID()].Name).." - "..Locale.Lookup(playerConfig:GetPlayerName());
				--AddFilterCivLeader(name, function(a) return a:GetID() == pPlayer:GetID() end);
				local controlTable = {};
				Controls.CivLeaderPull:BuildEntry( "InstanceOne", controlTable );
				controlTable.Button:LocalizeAndSetText( name );
				controlTable.Button:RegisterCallback( Mouse.eLClick, function() CivLeaderClicked(pPlayer:GetID(), name); end );
			end
		end
	end

	-- Select the first filter
	Controls.CivLeaderPull:GetButton():LocalizeAndSetText( sAllText );
	m_filterPlayerID = -1;

	-- Calculate Internals
	Controls.CivLeaderPull:CalculateInternals();
end


-- =======================================================================================
--  Layout the data for previously recruited great people.
-- =======================================================================================
function ViewPast( data:table )
  if (data == nil) then
    UI.DataError("GreatPeople attempting to view past timeline data but received NIL instead.");
    return;
  end

  m_greatPersonRowIM:ResetInstances();
  Controls.PeopleScroller:SetHide(true);
  Controls.RecruitedArea:SetHide(false);

  local firstAvailableIndex     :number = 0;
  local localPlayerID         :number = Game.GetLocalPlayer();
  local iTotal:number = 0;

  local PADDING_FOR_SPACE_AROUND_TEXT :number = 20;

  for i, kPerson:table in ipairs(data.Timeline) do
  
    -- Infixo: a filter here!
	local bShowClass:boolean = false; -- check for GP class
	if m_filterClassID == -1 then bShowClass = true;
	else bShowClass = ( kPerson.ClassID == m_filterClassID); end
	local bShowPlayer:boolean = false; -- check for player
	if m_filterPlayerID == -1 then bShowPlayer = true;
	else bShowPlayer = ( kPerson.ClaimantID == m_filterPlayerID); end
	
	if bShowClass and bShowPlayer then -- FILTER here

    local instance  :table  = m_greatPersonRowIM:GetInstance();
    local classData :table = GameInfo.GreatPersonClasses[kPerson.ClassID];

    if m_defaultPastRowHeight < 0 then
      m_defaultPastRowHeight = instance.Content:GetSizeY();
    end
    local rowHeight :number = math.max(m_defaultPastRowHeight, 72); -- 68 is for Civ icon


    local date    :string = Calendar.MakeYearStr( kPerson.TurnGranted);
    instance.EarnDate:SetText( date );

    local classText :string = "";
    if kPerson.ClassID ~= nil then
      classText = Locale.Lookup(classData.Name);
    else
      UI.DataError("GreatPeople previous recruited as unable to find the class text for #"..tostring(i));
    end
    instance.GreatPersonInfo:SetText( kPerson.Name );
    instance.ClassName:SetText( Locale.ToUpper(classText) );
	-- Era Name
    if kPerson.EraID ~= nil then
      local eraName:string = Locale.Lookup(GameInfo.Eras[kPerson.EraID].Name);
      instance.EraName:SetText( Locale.ToUpper(eraName) );
    end

    DifferentiateCiv(kPerson.ClaimantID, instance.CivIcon, instance.CivIcon, instance.CivIndicator, nil, nil, localPlayerID);
    instance.RecruitedImage:SetHide(true);
    instance.YouIndicator:SetHide(true);
    if (kPerson.ClaimantID ~= nil) then
      local playerConfig  :table = PlayerConfigurations[kPerson.ClaimantID];  --:GetCivilizationShortDescription();
      if (playerConfig ~= nil) then
        local iconName    :string = "ICON_"..playerConfig:GetLeaderTypeName();
        local localPlayer :table  = Players[localPlayerID];

        if(localPlayer ~= nil and localPlayerID == kPerson.ClaimantID) then
          instance.RecruitedImage:SetIcon(iconName, 55);
          instance.RecruitedImage:SetToolTipString( Locale.Lookup("LOC_GREAT_PEOPLE_RECRUITED_BY_YOU"));
          instance.RecruitedImage:SetHide(false);
          instance.YouIndicator:SetHide(false);

        elseif (localPlayer ~= nil and localPlayer:GetDiplomacy() ~= nil and localPlayer:GetDiplomacy():HasMet(kPerson.ClaimantID)) then
          instance.RecruitedImage:SetIcon(iconName, 55);
          instance.RecruitedImage:SetToolTipString( Locale.Lookup(playerConfig:GetPlayerName()) );
          instance.RecruitedImage:SetHide(false);
          instance.YouIndicator:SetHide(true);
        else
          instance.RecruitedImage:SetIcon("ICON_CIVILIZATION_UNKNOWN", 55);
          instance.RecruitedImage:SetToolTipString(  Locale.Lookup("LOC_GREAT_PEOPLE_RECRUITED_BY_UNKNOWN"));
          instance.RecruitedImage:SetHide(false);
          instance.YouIndicator:SetHide(true);
        end
      end
    end

    local isLocalPlayer:boolean = (kPerson.ClaimantID ~= nil and kPerson.ClaimantID == localPlayerID);
    instance.YouIndicator:SetHide( not isLocalPlayer );

    local colorName:string = (isLocalPlayer and "GreatPeopleRow") or "GreatPeopleRowUnOwned";
    instance.Content:SetColorByName( colorName );

    -- Ability Effects

    colorName = (isLocalPlayer and "GreatPeoplePastCS") or "GreatPeoplePastUnownedCS";

    if instance["m_EffectsIM"] ~= nil then
      instance["m_EffectsIM"]:ResetInstances();
    else
      instance["m_EffectsIM"] = InstanceManager:new("PastEffectInstance", "Top", instance.EffectStack);
    end

    if (kPerson.ActionNameText ~= nil and kPerson.ActionNameText ~= "") then
      local effectInst:table  = instance["m_EffectsIM"]:GetInstance();
      local effectText:string = kPerson.ActionEffectText;
      local fullText:string = kPerson.ActionNameText;
      if (kPerson.ActionCharges > 0) then
        fullText = fullText .. " (" .. Locale.Lookup("LOC_GREATPERSON_ACTION_CHARGES", kPerson.ActionCharges) .. ")";
      end
      fullText = fullText .. "[NEWLINE]" .. kPerson.ActionUsageText;
      fullText = fullText .. "[NEWLINE][NEWLINE]" .. effectText;
      effectInst.Text:SetText( effectText );
      effectInst.EffectTypeIcon:SetToolTipString( fullText );
      effectInst.Text:SetColorByName(colorName);

      rowHeight = math.max( rowHeight, effectInst.Text:GetSizeY() + PADDING_FOR_SPACE_AROUND_TEXT );

      local actionIcon:string = classData.ActionIcon;
      if actionIcon ~= nil and actionIcon ~= "" then
        local textureOffsetX:number, textureOffsetY:number, textureSheet:string = IconManager:FindIconAtlas(actionIcon, SIZE_ACTION_ICON);
        if(textureSheet == nil or textureSheet == "") then
          error("Could not find icon in ViewCurrent: icon=\""..actionIcon.."\", iconSize="..tostring(SIZE_ACTION_ICON) );
        else
          effectInst.ActiveAbilityIcon:SetTexture(textureOffsetX, textureOffsetY, textureSheet);
          effectInst.ActiveAbilityIcon:SetHide(false);
          effectInst.PassiveAbilityIcon:SetHide(true);
        end
      else
        effectInst.ActiveAbilityIcon:SetHide(true);
      end
    end

    if kPerson.PassiveNameText ~= nil and kPerson.PassiveNameText ~= "" then
      local effectInst:table  = instance["m_EffectsIM"]:GetInstance();
      local effectText:string = kPerson.PassiveEffectText;
      local fullText:string = kPerson.PassiveNameText .. "[NEWLINE][NEWLINE]" .. effectText;
      effectInst.Text:SetText( effectText );
      effectInst.EffectTypeIcon:SetToolTipString( fullText );
      effectInst.Text:SetColorByName(colorName);

      rowHeight = math.max( rowHeight, effectInst.Text:GetSizeY() + PADDING_FOR_SPACE_AROUND_TEXT );

      effectInst.PassiveAbilityIcon:SetHide(false);
      effectInst.ActiveAbilityIcon:SetHide(true);
    end

    instance.Content:SetSizeY( rowHeight );
	iTotal = iTotal + 1;
	end -- Infixo: end FILTER here

  end
  
  Controls.Total:SetText(Locale.Lookup("LOC_HUD_CITY_TOTAL")..": "..tostring(iTotal)); -- display total

  -- Scaling to screen width required for the previously recruited tab
  Controls.PopupContainer:SetSizeX( m_screenWidth );
  Controls.ModalFrame:SetSizeX( m_screenWidth );

  Controls.RecruitedStack:CalculateSize();
  Controls.RecruitedScroller:CalculateSize();
end


-- =======================================================================================
--  Button Callback
--  Switch between biography and stats for a great person
-- =======================================================================================
function OnBiographyBackClick( individualID )

  -- If a biography is open, close it via recursive magic...
  if m_activeBiographyID ~= -1 and individualID ~= m_activeBiographyID then
    OnBiographyBackClick( m_activeBiographyID );
  end

  local instance:table= m_uiGreatPeople[individualID];
  if instance == nil then
    print("WARNING: Was unable to find instance for individual \""..tostring(individualID).."\"");
    return;
  end

  local isShowingBiography  :boolean = not instance.BiographyArea:IsHidden();
  local buttonLabelText   :string;

  instance.BiographyArea:SetHide( isShowingBiography );
  instance.MainInfo:SetHide( not isShowingBiography );
  instance.BiographyActiveBG:SetHide( isShowingBiography );

  if isShowingBiography then
    m_activeBiographyID = -1;
    buttonLabelText = Locale.Lookup("LOC_GREAT_PEOPLE_BIOGRAPHY");    -- Current showing; so hide...
  else
    m_activeBiographyID = individualID;

    -- Current hidden, show biography...
    buttonLabelText = Locale.Lookup("LOC_GREAT_PEOPLE_BACK");

    -- Get data
    local kBiographyText:table;
    for k,v in pairs(m_kData.Timeline) do
      if v.IndividualID == individualID then
        kBiographyText = v.BiographyTextTable;
        break;
      end
    end
    if kBiographyText ~= nil then
      instance.BiographyText:SetText( table.concat(kBiographyText, "[NEWLINE][NEWLINE]"));
    else
      instance.BiographyText:SetText("");
      print("WARNING: Couldn't find data for \""..tostring(individualID).."\"");
    end

    instance.BiographyScroll:CalculateSize();
  end

  instance.BiographyBackButton:SetText( buttonLabelText );
end


-- =======================================================================================
--  Populate a data table with timeline information.
--    data  An allocated table to receive the timeline.
--    isPast  If the data should be from the past (instead of the current)
-- =======================================================================================
function PopulateData( data:table, isPast:boolean )

  if data == nil then
    error("GreatPeoplePopup received an empty data in to PopulateData");
    return;
  end

  local localPlayerID :number = Game.GetLocalPlayer();
  local pGreatPeople  :table  = Game.GetGreatPeople();
  if pGreatPeople == nil then
    UI.DataError("GreatPeoplePopup received NIL great people object.");
    return;
  end

  local pTimeline:table = nil;
  if isPast then
    pTimeline = pGreatPeople:GetPastTimeline();
  else
    pTimeline = pGreatPeople:GetTimeline();
  end


  for i,entry in ipairs(pTimeline) do
    -- don't add unclaimed great people to the previously recruited tab
    if not isPast or entry.Claimant then
    local claimantName :string = nil;
    if (entry.Claimant ~= nil) then
      claimantName = Locale.Lookup(PlayerConfigurations[entry.Claimant]:GetCivilizationShortDescription());
    end

    local canRecruit      :boolean = false;
    local canReject       :boolean = false;
    local canPatronizeWithFaith :boolean = false;
    local canPatronizeWithGold  :boolean = false;
    local actionCharges     :number = 0;
    local patronizeWithGoldCost :number = nil;
    local patronizeWithFaithCost:number = nil;
    local recruitCost     :number = entry.Cost;
    local rejectCost      :number = nil;
    local earnConditions    :string = nil;
    if (entry.Individual ~= nil) then
      if (Players[localPlayerID] ~= nil) then
        canRecruit = pGreatPeople:CanRecruitPerson(localPlayerID, entry.Individual);
        if (not isPast) then
          canReject = pGreatPeople:CanRejectPerson(localPlayerID, entry.Individual);
          if (canReject) then
            rejectCost = pGreatPeople:GetRejectCost(localPlayerID, entry.Individual);
          end
        end
        canPatronizeWithGold = pGreatPeople:CanPatronizePerson(localPlayerID, entry.Individual, YieldTypes.GOLD);
        patronizeWithGoldCost = pGreatPeople:GetPatronizeCost(localPlayerID, entry.Individual, YieldTypes.GOLD);
        canPatronizeWithFaith = pGreatPeople:CanPatronizePerson(localPlayerID, entry.Individual, YieldTypes.FAITH);
        patronizeWithFaithCost = pGreatPeople:GetPatronizeCost(localPlayerID, entry.Individual, YieldTypes.FAITH);
        earnConditions = pGreatPeople:GetEarnConditionsText(localPlayerID, entry.Individual);
      end
      local individualInfo = GameInfo.GreatPersonIndividuals[entry.Individual];
      actionCharges = individualInfo.ActionCharges;
    end

    local color = COLOR_UNAVAILABLE;
    if (entry.Class ~= nil) then
      if (canRecruit or canReject) then
        color = COLOR_CLAIMED;
      else
        color = COLOR_AVAILABLE;
      end
    end

    local personName:string = "";
    if  GameInfo.GreatPersonIndividuals[entry.Individual] ~= nil then
      personName = Locale.Lookup(GameInfo.GreatPersonIndividuals[entry.Individual].Name);
    end

    local kPerson:table = {
      IndividualID      = entry.Individual,
      ClassID         = entry.Class,
      EraID         = entry.Era,
      ClaimantID        = entry.Claimant,
      ActionCharges     = actionCharges,
      ActionNameText      = entry.ActionNameText,
      ActionUsageText     = entry.ActionUsageText,
      ActionEffectText    = entry.ActionEffectText,
      BiographyTextTable    = GetBiographyTextTable( entry.Individual ),
      CanPatronizeWithFaith = canPatronizeWithFaith,
      CanPatronizeWithGold  = canPatronizeWithGold,
      CanReject       = canReject,
      ClaimantName      = claimantName,
      Color         = color,
      CanRecruit        = canRecruit,
      EarnConditions      = earnConditions,
      Name          = personName,
      PassiveNameText     = entry.PassiveNameText,
      PassiveEffectText   = entry.PassiveEffectText,
      PatronizeWithFaithCost  = patronizeWithFaithCost,
      PatronizeWithGoldCost = patronizeWithGoldCost,
      RecruitCost       = recruitCost,
      RejectCost        = rejectCost,
      TurnGranted       = entry.TurnGranted
    };
    table.insert(data.Timeline, kPerson);
    end
  end


  for classInfo in GameInfo.GreatPersonClasses() do
    local classID = classInfo.Index;
    local pointsTable = {};
    local players = Game.GetPlayers{Major = true, Alive = true};
    for i, player in ipairs(players) do
      local playerName = "";
      local isPlayer:boolean = false;
      if (player:GetID() == localPlayerID) then
        playerName = playerName .. Locale.Lookup(PlayerConfigurations[player:GetID()]:GetCivilizationShortDescription());
        isPlayer = true;
      elseif (Players[localPlayerID]:GetDiplomacy():HasMet(player:GetID())) then
        playerName = playerName .. Locale.Lookup(PlayerConfigurations[player:GetID()]:GetCivilizationShortDescription());
      else
        playerName = playerName .. Locale.Lookup("LOC_DIPLOPANEL_UNMET_PLAYER");
      end
      local playerPoints = {
        IsPlayer      = isPlayer,
        MaxPlayerInstances  = classInfo.MaxPlayerInstances,
        NumInstancesEarned  = pGreatPeople:CountPeopleReceivedByPlayer(classID, player:GetID());
        PlayerName      = playerName,
        PointsTotal     = player:GetGreatPeoplePoints():GetPointsTotal(classID),
        PointsPerTurn   = player:GetGreatPeoplePoints():GetPointsPerTurn(classID),
        PlayerID      = player:GetID()
      };
      table.insert(pointsTable, playerPoints);
    end
    table.sort(pointsTable, function(a, b)
      if (a.IsPlayer and not b.IsPlayer) then
        return true;
      elseif (not a.IsPlayer and b.IsPlayer) then
        return false;
      end
      return a.PointsTotal > b.PointsTotal;
    end);
    data.PointsByClass[classID] = pointsTable;
  end

end



-- =======================================================================================
function Open()
  if (Game.GetLocalPlayer() == -1) then
    return
  end
  
  -- Infixo:pulldowns
  PopulateClassNamePull();
  PopulateCivLeaderPull();

  -- Queue the screen as a popup, but we want it to render at a desired location in the hierarchy, not on top of everything.
  if not UIManager:IsInPopupQueue(ContextPtr) then
    local kParameters = {};
    kParameters.RenderAtCurrentParent = true;
    kParameters.InputAtCurrentParent = true;
    kParameters.AlwaysVisibleInQueue = true;
    UIManager:QueuePopup(ContextPtr, PopupPriority.Low, kParameters);
    UI.PlaySound("UI_Screen_Open");
  end
  
  Refresh();

  -- From ModalScreen_PlayerYieldsHelper
  RefreshYields();

  -- From Civ6_styles: FullScreenVignetteConsumer
  Controls.ScreenAnimIn:SetToBeginning();
  Controls.ScreenAnimIn:Play();

  LuaEvents.GreatPeople_OpenGreatPeople();
end

-- =======================================================================================
function Close()
  if not ContextPtr:IsHidden() then
    UI.PlaySound("UI_Screen_Close");
  end

  if UIManager:DequeuePopup(ContextPtr) then
    LuaEvents.GreatPeople_CloseGreatPeople();
  end
end

-- =======================================================================================
--  UI Handler
-- =======================================================================================
function OnClose()
  Close();
end

-- =======================================================================================
--  LUA Event
-- =======================================================================================
function OnOpenViaNotification()
  Open();
end

-- =======================================================================================
--  LUA Event
-- =======================================================================================
function OnOpenViaLaunchBar()
  Open();
end


-- ===========================================================================
function OnRecruitButtonClick( individualID:number )
  local pLocalPlayer = Players[Game.GetLocalPlayer()];
  if (pLocalPlayer ~= nil) then
    local kParameters:table = {};
    kParameters[PlayerOperations.PARAM_GREAT_PERSON_INDIVIDUAL_TYPE] = individualID;
    UI.RequestPlayerOperation(Game.GetLocalPlayer(), PlayerOperations.RECRUIT_GREAT_PERSON, kParameters);
    Close();
  end
end

-- ===========================================================================
function OnRejectButtonClick( individualID:number )
  local pLocalPlayer = Players[Game.GetLocalPlayer()];
  if (pLocalPlayer ~= nil) then
    local kParameters:table = {};
    kParameters[PlayerOperations.PARAM_GREAT_PERSON_INDIVIDUAL_TYPE] = individualID;
    UI.RequestPlayerOperation(Game.GetLocalPlayer(), PlayerOperations.REJECT_GREAT_PERSON, kParameters);
    Close();
  end
end

-- ===========================================================================
function OnGoldButtonClick( individualID:number  )
  local pLocalPlayer = Players[Game.GetLocalPlayer()];
  if (pLocalPlayer ~= nil) then
    local kParameters:table = {};
    kParameters[PlayerOperations.PARAM_GREAT_PERSON_INDIVIDUAL_TYPE] = individualID;
    kParameters[PlayerOperations.PARAM_YIELD_TYPE] = YieldTypes.GOLD;
    UI.RequestPlayerOperation(Game.GetLocalPlayer(), PlayerOperations.PATRONIZE_GREAT_PERSON, kParameters);
    UI.PlaySound("Purchase_With_Gold");
    Close();
  end
end

-- ===========================================================================
function OnFaithButtonClick( individualID:number  )
  local pLocalPlayer = Players[Game.GetLocalPlayer()];
  if (pLocalPlayer ~= nil) then
    local kParameters:table = {};
    kParameters[PlayerOperations.PARAM_GREAT_PERSON_INDIVIDUAL_TYPE] = individualID;
    kParameters[PlayerOperations.PARAM_YIELD_TYPE] = YieldTypes.FAITH;
    UI.RequestPlayerOperation(Game.GetLocalPlayer(), PlayerOperations.PATRONIZE_GREAT_PERSON, kParameters);
    UI.PlaySound("Purchase_With_Faith");
    Close();
  end
end

-- ===========================================================================
--  Game Engine Event
-- ===========================================================================
function OnLocalPlayerChanged( playerID:number , prevLocalPlayerID:number )
  if playerID == -1 then return; end
  m_tabs.SelectTab( Controls.ButtonGreatPeople );
end

-- ===========================================================================
--  Game Engine Event
-- ===========================================================================
function OnLocalPlayerTurnBegin()
  if (not ContextPtr:IsHidden()) then
    Refresh();
  end
end

-- ===========================================================================
--  Game Engine Event
-- ===========================================================================
function OnLocalPlayerTurnEnd()
  if (not ContextPtr:IsHidden()) and GameConfiguration.IsHotseat() then
    Close();
  end
end

-- ===========================================================================
--  Game Engine Event
-- ===========================================================================
function OnUnitGreatPersonActivated( unitOwner:number, unitID:number, greatPersonClassID:number, greatPersonIndividualID:number )
  if (unitOwner == Game.GetLocalPlayer()) then
    local player = Players[unitOwner];
    if (player ~= nil) then
      local unit = player:GetUnits():FindID(unitID);
      if (unit ~= nil) then
        local message = GetActivationEffectTextByGreatPersonClass(greatPersonClassID);
        UI.AddWorldViewText(EventSubTypes.PLOT, message, unit:GetX(), unit:GetY(), 0);
        UI.PlaySound("Claim_Great_Person");
      end
    end
  end
end

-- ===========================================================================
--  Game Engine Event
-- ===========================================================================
function OnGreatPeoplePointsChanged( playerID:number )
  -- Update for any player's change, so that the local player can see up to date information about other players' points
  if (not ContextPtr:IsHidden()) then
    Refresh();
  end
end


-- ===========================================================================
--
-- ===========================================================================
function Refresh()
  local kData :table  = {
    Timeline    = {},
    PointsByClass = {},
  };
  if m_tabs.selectedControl == Controls.ButtonPreviouslyRecruited then
    PopulateData(kData, true);  -- use past data
    ViewPast(kData);
  else
    PopulateData(kData, false); -- do not use past data
    ViewCurrent(kData);
  end

  m_kData = kData;
end



-- ===========================================================================
--  Tab callback
-- ===========================================================================
function OnGreatPeopleClick()
  Controls.SelectGreatPeople:SetHide( false );
  Controls.ButtonGreatPeople:SetSelected( true );
  Controls.SelectPreviouslyRecruited:SetHide( true );
  Controls.ButtonPreviouslyRecruited:SetSelected( false );
  -- Infixo
  Controls.ClassNamePull:SetHide( true );
  Controls.CivLeaderPull:SetHide( true );
  Controls.Total:SetHide( true );
  Refresh();
end

-- ===========================================================================
--  Tab callback
-- ===========================================================================
function OnPreviousRecruitedClick()
  Controls.SelectGreatPeople:SetHide( true );
  Controls.ButtonGreatPeople:SetSelected( false );
  Controls.SelectPreviouslyRecruited:SetHide( false );
  Controls.ButtonPreviouslyRecruited:SetSelected( true );
  -- Infixo
  Controls.ClassNamePull:SetHide( false );
  Controls.CivLeaderPull:SetHide( false );
  Controls.Total:SetHide( false );
  Refresh();
end

-- =======================================================================================
--  UI Event
-- =======================================================================================
function OnInit( isHotload:boolean )
  if isHotload then
    LuaEvents.GameDebug_GetValues(RELOAD_CACHE_ID);
  end
end

-- =======================================================================================
--  UI Event
--  Input
-- =======================================================================================
-- ===========================================================================
function KeyHandler( key:number )
    if key == Keys.VK_ESCAPE then
    Close();
    return true;
    end
    return false;
end
function OnInputHandler( pInputStruct:table )
  local uiMsg = pInputStruct:GetMessageType();
  if (uiMsg == KeyEvents.KeyUp) then return KeyHandler( pInputStruct:GetKey() ); end;
  return false;
end

-- =======================================================================================
--  UI Event
-- =======================================================================================
function OnShutdown()
  LuaEvents.GameDebug_AddValue(RELOAD_CACHE_ID, "isHidden",   ContextPtr:IsHidden() );
  LuaEvents.GameDebug_AddValue(RELOAD_CACHE_ID, "isPreviousTab",  (m_tabs.selectedControl == Controls.ButtonPreviouslyRecruited) );
end

-- ===========================================================================
--  LUA Event
--  Set cached values back after a hotload.
-- ===========================================================================
function OnGameDebugReturn( context:string, contextTable:table )
  if context ~= RELOAD_CACHE_ID then return; end
  local isHidden:boolean = contextTable["isHidden"];
  if not isHidden then
    local isPreviouslyRecruited:boolean = contextTable["isPreviousTab"];
    if isPreviouslyRecruited then
      m_tabs.SelectTab( Controls.ButtonPreviouslyRecruited );
    else
      m_tabs.SelectTab( Controls.ButtonGreatPeople );
    end
  end
end

-- =======================================================================================
--
-- =======================================================================================
function Initialize()

  if (not HasCapability("CAPABILITY_GREAT_PEOPLE_VIEW")) then
    -- Great People Viewing is off, just exit
    return;
  end

  -- Tab setup and setting of default tab.
  m_tabs = CreateTabs( Controls.TabContainer, 42, 34, 0xFF331D05 );
  m_tabs.AddTab( Controls.ButtonGreatPeople,      OnGreatPeopleClick );
  m_tabs.AddTab( Controls.ButtonPreviouslyRecruited,  OnPreviousRecruitedClick );
  m_tabs.CenterAlignTabs(-10);
  if Game.GetLocalPlayer() ~= -1 then
    m_tabs.SelectTab( Controls.ButtonGreatPeople );
  end

  -- UI Events
  ContextPtr:SetInitHandler( OnInit );
  ContextPtr:SetInputHandler( OnInputHandler, true );
  ContextPtr:SetShutdown( OnShutdown );

  -- UI Controls
  -- We use a separate BG within the PeopleScroller control since it needs to scroll with the contents
  Controls.ModalBG:SetHide(true);
  Controls.ModalScreenClose:RegisterCallback(Mouse.eLClick, OnClose);
  Controls.ModalScreenTitle:SetText(Locale.ToUpper(Locale.Lookup("LOC_GREAT_PEOPLE_TITLE")));

  -- Game engine Events
  Events.LocalPlayerChanged.Add( OnLocalPlayerChanged );
  Events.LocalPlayerTurnBegin.Add( OnLocalPlayerTurnBegin );
  Events.LocalPlayerTurnEnd.Add( OnLocalPlayerTurnEnd );
  Events.UnitGreatPersonActivated.Add( OnUnitGreatPersonActivated );
  Events.GreatPeoplePointsChanged.Add( OnGreatPeoplePointsChanged );

  -- LUA Events
  LuaEvents.GameDebug_Return.Add(             OnGameDebugReturn );
  LuaEvents.LaunchBar_OpenGreatPeoplePopup.Add(     OnOpenViaLaunchBar );
  LuaEvents.NotificationPanel_OpenGreatPeoplePopup.Add( OnOpenViaNotification );
  LuaEvents.LaunchBar_CloseGreatPeoplePopup.Add(			OnClose );

    -- Audio Events
  Controls.ButtonGreatPeople:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
  Controls.ButtonPreviouslyRecruited:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);

end
Initialize();

print("OK loaded GreatPeoplePopup.lua from RGP Mod");