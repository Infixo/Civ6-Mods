print("Loading GreatPeoplePopup.lua from RGP Mod, version 5.0");
-- ===========================================================================
--	Great People Popup
-- ===========================================================================

include("InstanceManager");
include("TabSupport");
include("SupportFunctions");
include("Civ6Common"); --DifferentiateCiv
include("ModalScreen_PlayerYieldsHelper");
include("GameCapabilities");
include("GameEffectsText"); -- GetModifierText

-- ===========================================================================
--	CONSTANTS
-- ===========================================================================
local MAX_BIOGRAPHY_PARAGRAPHS	: number = 9;						-- maximum # of paragraphs for a biography
local RELOAD_CACHE_ID			: string = "GreatPeoplePopup";		-- hotloading
local SIZE_ACTION_ICON			: number = 38;

local TAB_SIZE					: number = 170;
local TAB_PADDING				: number = 10;

-- ===========================================================================
--	MEMBERS
-- ===========================================================================
local m_TopPanelConsideredHeight:number = 0;
local m_greatPersonPanelIM:table = InstanceManager:new("PanelInstance",        "Content",  Controls.PeopleStack);
local m_greatPersonRowIM  :table = InstanceManager:new("PastRecruitmentInstance",  "Content",  Controls.RecruitedStack);
local m_plannerIM:table = InstanceManager:new("EraInstance",        "Content",  Controls.PlannerStack); -- Infixo planner tab
local m_tabButtonIM       :table = InstanceManager:new("TabButtonInstance",			"Button",	Controls.TabContainer);
local m_kGreatPeople   :table;
local m_kData       :table;
local m_activeBiographyID :number = -1; -- Only allow one open at a time (or very quick exceed font allocation)
local m_activeRecruitInfoID	:number	= -1;	-- Only allow one open at a time (or very quick exceed font allocation)
local m_tabs        :table;
local m_defaultPastRowHeight    :number = -1; -- Default/mix height (from XML) for a previously recruited row
local m_displayPlayerID		:number = -1; -- What player are we displaying.  Used for looking at different players in autoplay
local m_screenWidth			:number = -1;

local m_numTabs				:number = 0;

-- Dynamic refresh call member used to override the refresh functionality
local m_RefreshFunc			:ifunction = nil;

local m_pGreatPeopleTabInstance:table	= nil;
local m_pPrevRecruitedTabInstance:table = nil;

-- Infixo: moving the Great Prophet to the end
local eClassProphet = GameInfo.GreatPersonClasses["GREAT_PERSON_CLASS_PROPHET"].Index;

-- Infixo Filters (pulldowns)
local m_filterClassID:number = -1; -- -1 for All, >-1 for Great Person Class ID
local m_filterPlayerID:number = -1; -- -1 for All, >-1 for Player ID (as in GetLocalPlayer() or Players[])

-- Infixo 2022-12-14
--local m_Eras :table;

-- ===========================================================================
-- DEBUG ROUTINES
-- ===========================================================================

-- debug routine - prints a table (no recursion)
function dshowtable(tTable:table)
	if tTable == nil then print("dshowtable: table is nil"); return; end
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
function ChangeDisplayPlayerID(bBackward)
	
	if (bBackward == nil) then
		bBackward = false;
	end

	local aPlayers = PlayerManager.GetAliveMajors();
	local playerCount = #aPlayers;

	-- Anything set yet?
	if (m_displayPlayerID ~= -1) then
		-- Loop and find the current player and skip to the next
		for i, pPlayer in ipairs(aPlayers) do
			if (pPlayer:GetID() == m_displayPlayerID) then

				if (bBackward) then
					-- Have a previous one?
					if (i >= 2) then
						-- Yes
						m_displayPlayerID = aPlayers[ playerCount ]:GetID();
					else
						-- Go to the end
						m_displayPlayerID = aPlayers[1]:GetID();
					end
				else
					-- Have a next one?
					if (#aPlayer > i) then
						-- Yes
						m_displayPlayerID = aPlayers[i + 1]:GetID();
					else
						-- Back to the beginning
						m_displayPlayerID = aPlayers[1]:GetID();
					end
				end

				return m_displayPlayerID;
			end
		end

	end

	-- No player, or didn't find the previous player, start from the beginning.
	if (playerCount > 0) then
		m_displayPlayerID = aPlayers[1]:GetID();
	end

	return m_displayPlayerID;
end
				
-- ===========================================================================
function GetDisplayPlayerID()

	if Automation.IsActive() then
		if (m_displayPlayerID ~= -1) then
			return m_displayPlayerID;
		end

		return ChangeDisplayPlayerID();
	end

	return Game.GetLocalPlayer();
end

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
function AddRecruit( kData:table, kPerson:table )

    local instance    :table = m_greatPersonPanelIM:GetInstance();
    local classData   :table = GameInfo.GreatPersonClasses[kPerson.ClassID];
    local individualData:table = GameInfo.GreatPersonIndividuals[kPerson.IndividualID];
    local classText   :string = "";

    -- Infixo: moving the Great Prophet to the end
	local iNumGPs = table.count(kData.Timeline); -- General Commandante is 10th class but doesn't go into the Timeline
	local eClassID = kPerson.ClassID;
	--print("BEFORE: i,eClassID,eCP,iNumGPs", i, eClassID, eClassProphet, iNumGPs);
	if eClassID == nil then
		if i == iNumGPs then eClassID = eClassProphet;
		elseif i < eClassProphet+1 then eClassID = i-1;
		else eClassID = i; end
	end
	--print("AFTER: i,eClassID", i, eClassID);
    instance.ClassName:SetText(Locale.Lookup(GameInfo.GreatPersonClasses[eClassID].Name));

    if kPerson.IndividualID ~= nil then
      local individualName:string = Locale.ToUpper(kPerson.Name);
      instance.IndividualName:SetText( individualName );
    end

    if kPerson.EraID ~= nil then
      local eraName:string = Locale.ToUpper(Locale.Lookup(GameInfo.Eras[kPerson.EraID].Name));
      instance.EraName:SetText( eraName );
	  -- Infixo: show all GPs from this era in the tooltip
	  local sEraType:string = GameInfo.Eras[kPerson.EraID].EraType;
	  local sGPClass:string = GameInfo.GreatPersonClasses[eClassID].GreatPersonClassType;
	  local tTT:table = {};
	  for gp in GameInfo.GreatPersonIndividuals() do
		if gp.GreatPersonClassType == sGPClass and gp.EraType == sEraType then
		  if GreatPersonHasBeenRecruited(gp.Index) then
			table.insert(tTT, "[COLOR_Grey]"..Locale.Lookup(gp.Name).." - "..Locale.Lookup("LOC_TECH_KEY_UNAVAILABLE").."[ENDCOLOR]");
		  else
			table.insert(tTT, Locale.Lookup(gp.Name));
		  end
		end
	  end
	  instance.EraName:SetToolTipString(table.concat(tTT, "[NEWLINE]"));
    end

    -- Grab icon of the great person themselves; first try a specific image, if it doesn't exist
    -- then grab a generic representation based on the class.
	--print("ClassID, IndividualID", kPerson.ClassID, kPerson.IndividualID);
    if (kPerson.ClassID ~= nil) and (kPerson.IndividualID ~= nil) then
      local portrait:string = "ICON_" .. individualData.GreatPersonIndividualType;
      textureOffsetX, textureOffsetY, textureSheet = IconManager:FindIconAtlas(portrait, 160);
	  --print("icon: portrait, OffX, OffY, Sheet", portrait, textureOffsetX, textureOffsetY, textureSheet);
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

    -- Infixo: passive effect moved to the end
    if kPerson.PassiveNameText ~= nil and kPerson.PassiveNameText ~= "" then
      local effectInst:table  = instance["m_EffectsIM"]:GetInstance();
      local effectText:string = kPerson.PassiveEffectText;
      local fullText:string = kPerson.PassiveNameText .. "[NEWLINE][NEWLINE]" .. effectText;
      effectInst.Text:SetText( effectText );
      effectInst.EffectTypeIcon:SetToolTipString( fullText );
      effectInst.PassiveAbilityIcon:SetHide(false);
      effectInst.ActiveAbilityIcon:SetHide(true);
    end

    if instance["m_RecruitIM"] ~= nil then
      instance["m_RecruitIM"]:ResetInstances();
    else
      instance["m_RecruitIM"] = InstanceManager:new("RecruitInstance", "Top", instance.RecruitStack);
    end

	if instance["m_RecruitExtendedIM"] ~= nil then
	  instance["m_RecruitExtendedIM"]:ResetInstances();
	else
      instance["m_RecruitExtendedIM"] = InstanceManager:new("RecruitInstance", "Top", instance.RecruitInfoStack);
	end

    if kPerson.IndividualID ~= nil and kPerson.ClassID ~= nil then

      -- Buy via gold
      if (HasCapability("CAPABILITY_GREAT_PEOPLE_RECRUIT_WITH_GOLD") and (not kPerson.CanRecruit and not kPerson.CanReject and kPerson.PatronizeWithGoldCost ~= nil and kPerson.PatronizeWithGoldCost < 1000000)) then
        instance.GoldButton:SetText(kPerson.PatronizeWithGoldCost .. "[ICON_Gold]");
        instance.GoldButton:SetToolTipString(GetPatronizeWithGoldTT(kPerson));
        instance.GoldButton:SetVoid1(kPerson.IndividualID);
        instance.GoldButton:RegisterCallback(Mouse.eLClick, OnGoldButtonClick);
        instance.GoldButton:SetDisabled((not kPerson.CanPatronizeWithGold) or IsReadOnly());
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
        instance.FaithButton:SetDisabled((not kPerson.CanPatronizeWithFaith) or IsReadOnly());
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

	  -- If Recruit or Reject buttons are shown hide the minimized recruit stack
	  --[[ Infixo not used
	  if not instance.RejectButton:IsHidden() or not instance.RecruitButton:IsHidden() then
		instance.RecruitMinimizedStack:SetHide(true);
	  else
		instance.RecruitMinimizedStack:SetHide(false);
	  end
	  --]]

      -- Recruiting standings
      -- Let's sort the table first by points total, then by the lower player id (to push yours toward the top of the list for readability)
      local recruitTable: table = {};
      for i, kPlayerPoints in ipairs(kData.PointsByClass[kPerson.ClassID]) do
	    kPlayerPoints.TurnsLeft = Round((kPerson.RecruitCost-kPlayerPoints.PointsTotal)/kPlayerPoints.PointsPerTurn + 0.5,0);
        table.insert(recruitTable,kPlayerPoints);
      end
      table.sort(recruitTable,
        function (a,b) -- sort first by TurnsLeft, then by PointsTotal, then by PlayerID
		  if a.TurnsLeft == b.TurnsLeft then
            if a.PointsTotal == b.PointsTotal then
              return a.PlayerID < b.PlayerID;
            else
              return a.PointsTotal > b.PointsTotal;
            end
		  else
		    return a.TurnsLeft < b.TurnsLeft;
		  end
        end);

      for i, kPlayerPoints in ipairs(recruitTable) do
        local canEarnAnotherOfThisClass:boolean = true;
        if (kPlayerPoints.MaxPlayerInstances ~= nil and kPlayerPoints.NumInstancesEarned ~= nil) then
          canEarnAnotherOfThisClass = kPlayerPoints.MaxPlayerInstances > kPlayerPoints.NumInstancesEarned;
        end
        if (canEarnAnotherOfThisClass) then
          local recruitInst:table = instance["m_RecruitIM"]:GetInstance();
          recruitInst.Country:SetText( kPlayerPoints.PlayerName );
          --recruitInst.Amount:SetText( tostring(Round(kPlayerPoints.PointsTotal,1)) .. "/" .. tostring(kPerson.RecruitCost) );

          -- CQUI Points Per Turn and Turns Left -- Add the turn icon into the text
          --recruitTurnsLeft gets +0.5 so that's rounded up
          local recruitTurnsLeft = kPlayerPoints.TurnsLeft; --Round((kPerson.RecruitCost-kPlayerPoints.PointsTotal)/kPlayerPoints.PointsPerTurn + 0.5,0);
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
	  
	  if (kPerson.EarnConditions ~= nil and kPerson.EarnConditions ~= "") then
	    instance.RecruitInfo:SetText("[COLOR_Civ6Red]" .. Locale.Lookup("LOC_GREAT_PEOPLE_CANNOT_EARN_PERSON") .. "[ENDCOLOR]");
	    instance.RecruitInfo:SetToolTipString("[COLOR_Civ6Red]" .. kPerson.EarnConditions .. "[ENDCOLOR]");
	    instance.RecruitInfo:SetHide(false);
	  else
	    instance.RecruitInfo:SetHide(true);
	  end

      instance.RecruitScroll:CalculateSize();
    end

    if kPerson.IndividualID ~= nil then
      -- Set the biography buttons
      instance.BiographyBackButton:SetVoid1( kPerson.IndividualID );
      instance.BiographyBackButton:RegisterCallback( Mouse.eLClick, OnBiographyClick );
	  instance.BiographyOpenButton:SetVoid1( kPerson.IndividualID );
	  instance.BiographyOpenButton:RegisterCallback( Mouse.eLClick, OnBiographyClick );
			
	  -- Setup extended recruit info buttons
	  --[[ Infixo not used
	  instance.RecruitInfoOpenButton:SetVoid1( kPerson.IndividualID );
	  instance.RecruitInfoOpenButton:RegisterCallback( Mouse.eLClick, OnRecruitInfoClick );
	  instance.RecruitInfoBackButton:SetVoid1( kPerson.IndividualID );
	  instance.RecruitInfoBackButton:RegisterCallback( Mouse.eLClick, OnRecruitInfoClick );
      --]]
      m_kGreatPeople[kPerson.IndividualID] = instance;   -- Store instance for later look up
    end

	local noneAvailable		:boolean = (kPerson.IndividualID == nil);
    instance.ClassName:SetHide( noneAvailable );
    --instance.TitleLine:SetHide( noneAvailable ); -- Infixo: not used
    instance.IndividualName:SetHide( noneAvailable );
    instance.EraName:SetHide( noneAvailable );
    instance.MainInfo:SetHide( noneAvailable );
    instance.BiographyBackButton:SetHide( noneAvailable );
    instance.ClaimedLabel:SetHide( not noneAvailable );
    instance.BiographyArea:SetHide( true );
	--instance.RecruitInfoArea:SetHide( true ); -- Infixo: not used
	instance.FadedBackground:SetHide( true );
	instance.BiographyOpenButton:SetHide( noneAvailable );
    instance.EffectStack:CalculateSize();
    instance.EffectStackScroller:CalculateSize();


  end

-- ===========================================================================
function ResetGreatPeopleInstances()
	m_greatPersonPanelIM:ResetInstances();
	m_greatPersonRowIM:ResetInstances();
	m_plannerIM:ResetInstances();
end

-- ===========================================================================
--  View the great people currently available (to be purchased)
-- ===========================================================================

-- Infixo: find out if a GP has already been recruited
--Game	GetGreatPeople GetPastTimeline
---> table of { Class, Individual, Era, Claimant, Cost, TurnGranted }
function GreatPersonHasBeenRecruited(eIndividual:number)
	for _,pastGP in ipairs(Game.GetGreatPeople():GetPastTimeline()) do
		if pastGP.Individual == eIndividual then return true; end
	end
	return false;
end

function ViewCurrent( data:table )
    if (data == nil) then
        UI.DataError("GreatPeople attempting to view current timeline data but received NIL instead.");
        return;
    end

    m_kGreatPeople = {};
    ResetGreatPeopleInstances();
    Controls.PeopleScroller:SetHide(false);
    Controls.RecruitedArea:SetHide(true);
    Controls.PlannerArea:SetHide(true);

	local kInstanceToShow:table = nil;
	
	-- Infixo: moving the Great Prophet to the end
	--print("Moving Great Prophet to the end");
	local iNumGPs = table.count(data.Timeline); -- General Commandante is 10th class but doesn't go into the Timeline, so I can't use #GameInfo
	--print("iNumGPs", iNumGPs, "from Timeline", table.count(data.Timeline)); -- Infixo
	local temp = data.Timeline[eClassProphet+1];
	for i=eClassProphet+1, iNumGPs-1, 1 do data.Timeline[i] = data.Timeline[i+1]; end
	data.Timeline[iNumGPs] = temp;

	for i, kPerson:table in ipairs(data.Timeline) do
		AddRecruit(data, kPerson);
	end
	
	Controls.PeopleStack:CalculateSize();
	Controls.PeopleScroller:CalculateSize();

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
    if IsTutorialRunning() then
        Controls.PeopleScroller:SetScrollValue( .3 );
    end
end

function FillRecruitInstance(instance:table, playerPoints:table, personData:table, classData:table)
	instance.Country:SetText( playerPoints.PlayerName );
	
	instance.Amount:SetText( tostring(Round(playerPoints.PointsTotal,1)) .. "/" .. tostring(personData.RecruitCost) );
	local progressPercent :number = Clamp( playerPoints.PointsTotal / personData.RecruitCost, 0, 1 );
	instance.ProgressBar:SetPercent( progressPercent );
	
	local recruitColorName:string = "GreatPeopleCS";
	if playerPoints.IsPlayer then
		recruitColorName = "GreatPeopleActiveCS";			
	end
	instance.Amount:SetColorByName( recruitColorName );
	instance.Country:SetColorByName( recruitColorName );
	instance.Country:SetColorByName( recruitColorName );
	instance.ProgressBar:SetColorByName( recruitColorName );

	DifferentiateCiv(playerPoints.PlayerID,instance.CivIcon,instance.CivIcon,instance.CivBacking, nil, nil, Game.GetLocalPlayer());

	local recruitDetails:string = Locale.Lookup("LOC_GREAT_PEOPLE_POINT_DETAILS", Round(playerPoints.PointsPerTurn, 1), classData.IconString, classData.Name);
	instance.Top:SetToolTipString(recruitDetails);
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
	--print("FUN ClassNameClicked", classID, className);
	if m_filterClassID == classID then return; end -- selected the same, do nothing
	Controls.ClassNamePull:GetButton():LocalizeAndSetText( className );
	m_filterClassID = classID;
	Refresh();
end

function PopulateClassNamePull()
	--print("FUN PopulateClassNamePull");

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
	--print("FUN CivLeaderClicked", playerID, playerName);
	if m_filterPlayerID == playerID then return; end -- selected the same, do nothing
	Controls.CivLeaderPull:GetButton():LocalizeAndSetText( playerName );
	m_filterPlayerID = playerID;
	Refresh();
end

function PopulateCivLeaderPull()
	--print("FUN PopulateCivLeaderPull");

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

  ResetGreatPeopleInstances();	
  Controls.PeopleScroller:SetHide(true);
  Controls.RecruitedArea:SetHide(false);
  Controls.PlannerArea:SetHide(true);

  local localPlayerID         :number = Game.GetLocalPlayer();
  local iTotal:number = 0; -- Infixo

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
    -- Infixo end

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
    instance.ClassName:SetText( Locale.ToUpper(classText) );
    instance.GreatPersonInfo:SetText( kPerson.Name );

	-- Infixo Era Name
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

		elseif (Game.GetLocalObserver() == PlayerTypes.OBSERVER or (localPlayer ~= nil and localPlayer:GetDiplomacy() ~= nil and localPlayer:GetDiplomacy():HasMet(kPerson.ClaimantID))) then
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

    -- Infixo: passive effect moved to the end
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
	iTotal = iTotal + 1; -- Infixo
	end -- Infixo: end FILTER here

  end
  
  Controls.Total:SetText(Locale.Lookup("LOC_HUD_CITY_TOTAL")..": "..tostring(iTotal)); -- Infixo display total

  -- Scaling to screen width required for the previously recruited tab
  Controls.PopupContainer:SetSizeX( m_screenWidth );
  Controls.ModalFrame:SetSizeX( m_screenWidth );

  Controls.RecruitedStack:CalculateSize();
  Controls.RecruitedScroller:CalculateSize();
end


-- =======================================================================================
--  Layout the data for planner
--  TODO: Planner uses past data passed in the "data" table
-- =======================================================================================

function SetPortrait( individual:table, iconControl:table, size:number )
	local portrait :string = "ICON_" .. individual.GreatPersonIndividualType;
	textureOffsetX, textureOffsetY, textureSheet = IconManager:FindIconAtlas(portrait, 160);
	--print("icon: portrait, OffX, OffY, Sheet", portrait, textureOffsetX, textureOffsetY, textureSheet);
	if textureSheet == nil then   -- Use a default if none found
		print("WARNING: Could not find icon atlas entry for the individual Great Person '"..portrait.."', using default instead.");
		portrait = "ICON_GENERIC_" .. individual.GreatPersonClassType .. "_" .. individual.Gender;
		portrait = portrait:gsub("_CLASS","_INDIVIDUAL");
	end
	local isValid = iconControl:SetIcon(portrait, size == nil and 160 or size);
	if (not isValid) then
		UI.DataError("Could not find icon for "..portrait);
	end
end

-- the game only provides past timeline and current info
-- there is no easy way to decode effects for future people
-- the below code is taken from civilopedia page
function GetEffectText(greatPerson :table)

	local greatPersonType = greatPerson.GreatPersonIndividualType;

	local active_ability = {};
	for row in GameInfo.GreatPersonIndividualActionModifiers() do
		if(row.GreatPersonIndividualType == greatPersonType) then
			local text = GetModifierText(row.ModifierId, "Summary");
			if(text) then
				table.insert(active_ability, text);
			end
		end
	end

	local passive_ability = {};
	for row in GameInfo.GreatPersonIndividualBirthModifiers() do
		if(row.GreatPersonIndividualType == greatPersonType) then
			local text = GetModifierText(row.ModifierId, "Summary");
			if(text) then
				table.insert(passive_ability, text);
			end
		end
	end

	local has_active = (greatPerson.ActionCharges > 0) and (#active_ability > 0 or greatPerson.ActionEffectTextOverride);
	local has_passive = #passive_ability > 0 or greatPerson.BirthEffectTextOverride;

	local effTxt :table = {};
	
	if(has_active) then
		local active_name = greatPerson.ActionNameTextOverride or "LOC_GREATPERSON_ACTION_NAME_DEFAULT";
		local name = Locale.Lookup("LOC_UI_PEDIA_GREATPERSON_ACTION", active_name, greatPerson.ActionCharges); -- {1_ActionName} ({2_ChargeAmount} {2_ChargeAmount : plural 1?charge; other?charges;})
		local active_body = greatPerson.ActionEffectTextOverride or table.concat(active_ability, "[NEWLINE]");
		--AddHeaderBody(name, active_body);
		table.insert(effTxt, name);
		table.insert(effTxt, Locale.Lookup(active_body));
	end

	if(has_passive) then
		local passive_name = greatPerson.BirthNameTextOverride or "LOC_GREATPERSON_PASSIVE_NAME_DEFAULT";
		local passive_body = greatPerson.BirthEffectTextOverride or table.concat(passive_ability, "[NEWLINE]");
		--AddHeaderBody(passive_name, passive_body);
		table.insert(effTxt, Locale.Lookup(passive_name));
		table.insert(effTxt, Locale.Lookup(passive_body));
	end

	return table.concat(effTxt, "[NEWLINE]");
end

function ViewPlanner( data:table )
  if (data == nil) then
    UI.DataError("GreatPeople attempting to view past timeline data but received NIL instead.");
    return;
  end

  ResetGreatPeopleInstances();	
  Controls.PeopleScroller:SetHide(true);
  Controls.RecruitedArea:SetHide(true);
  Controls.PlannerArea:SetHide(false);

  --local localPlayerID         :number = Game.GetLocalPlayer();

  --local PADDING_FOR_SPACE_AROUND_TEXT :number = 20;


	-- iterate through all eras (ex. Ancient and Future) and build instances for each one
	local kEraInstances = {}; -- temp storage so can iterate through GPs only once
	for era in GameInfo.Eras() do
		if era.ChronologyIndex >= 2 and era.ChronologyIndex <= 8 then
			local eraInstance :table  = m_plannerIM:GetInstance(); -- get a new instance of Era
			eraInstance.EraStack:DestroyAllChildren();
			--eraInstance.kPlannerIM = InstanceManager:new("PlannerInstance", "Content", eraInstance.EraStack);
			eraInstance.EraName:SetText( Locale.ToUpper(Locale.Lookup(era.Name)) );
			kEraInstances[ era.EraType ] = eraInstance;
		end
	end
	--dshowtable(kEraInstances);

			  
	-- iterate through GPs and place them in specific era instances
	for gp in GameInfo.GreatPersonIndividuals() do
		-- TODO: filter
		if gp.GreatPersonClassType == "GREAT_PERSON_CLASS_SCIENTIST" then
			--dshowtable(gp);
			--print("===================");
			-- add a new GP instance
			local instance :table = {};
			--print("era instance is", kEraInstances[gp.EraType]);
			--dshowtable(kEraInstances[gp.EraType]);
			--print("===================");
			--local instance :table = kEraInstances[gp.EraType].kPlannerIM:GetInstance(); -- get a new instance of Planner 
			ContextPtr:BuildInstanceForControl("PlannerInstance", instance, kEraInstances[gp.EraType].EraStack);
			--print("instance is", instance);
			--dshowtable(instance);
			SetPortrait( gp, instance.Portrait, 40 );
			instance.IndividualName:SetText(Locale.Lookup(gp.Name));
			instance.Effect:SetText( GetEffectText(gp) );
		end
	
		-- TODO: xxxxxxxxxxxx
		
	end
	
	Controls.PlannerStack:CalculateSize();
	Controls.PlannerScroller:CalculateSize();

    m_screenWidth = math.max(Controls.PlannerStack:GetSizeX(), 1024);
    --Controls.WoodPaneling2:SetSizeX( m_screenWidth );

    -- Clamp overall popup size to not be larger than contents (overspills in 4k and eyefinitiy rigs.)
    local screenX,_     :number = UIManager:GetScreenSizeVal();
    if m_screenWidth > screenX then
        m_screenWidth = screenX;
    end

    Controls.PopupContainer:SetSizeX( m_screenWidth );
    Controls.ModalFrame:SetSizeX( m_screenWidth );
	
end -- ViewPlanner


-- =======================================================================================
-- Toggle Extended Recruit Info whether open or closed
-- =======================================================================================
function OnRecruitInfoClick( individualID )
	-- If a recruit info is open, close the last opened
	if m_activeRecruitInfoID ~= -1 and individualID ~= m_activeRecruitInfoID then
		OnRecruitInfoClick( m_activeRecruitInfoID );		
	end
	
	local instance:table= m_kGreatPeople[individualID];
	if instance == nil then
		print("WARNING: Was unable to find instance for individual \""..tostring(individualID).."\"");
		return;
	end

	--local isShowingRecruitInfo:boolean = not instance.RecruitInfoArea:IsHidden(); -- Infixo: not used

	instance.BiographyArea:SetHide( true );
	--instance.RecruitInfoArea:SetHide( isShowingRecruitInfo ); -- Infixo: not used
	instance.MainInfo:SetHide( not isShowingRecruitInfo );
	instance.FadedBackground:SetHide( isShowingRecruitInfo );
	instance.BiographyOpenButton:SetHide( not isShowingRecruitInfo );

	if isShowingRecruitInfo then	
		m_activeRecruitInfoID = -1;
	else
		m_activeRecruitInfoID = individualID;
	end
end

-- =======================================================================================
--  Button Callback
--  Switch between biography and stats for a great person
-- =======================================================================================
function OnBiographyClick( individualID )

  -- If a biography is open, close it via recursive magic...
  if m_activeBiographyID ~= -1 and individualID ~= m_activeBiographyID then
    OnBiographyClick( m_activeBiographyID );
  end

  local instance:table= m_kGreatPeople[individualID];
  if instance == nil then
    print("WARNING: Was unable to find instance for individual \""..tostring(individualID).."\"");
    return;
  end

  local isShowingBiography  :boolean = not instance.BiographyArea:IsHidden();
  local buttonLabelText   :string;

  instance.BiographyArea:SetHide( isShowingBiography );
  --instance.RecruitInfoArea:SetHide( true ); -- Infixo: not used
  instance.MainInfo:SetHide( not isShowingBiography );
  instance.FadedBackground:SetHide( isShowingBiography );
  instance.BiographyOpenButton:SetHide( not isShowingBiography );

  if isShowingBiography then
	-- Current showing; so hide...		
    m_activeBiographyID = -1;
  else
    -- Current hidden, show biography...
    m_activeBiographyID = individualID;

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

  local displayPlayerID :number = GetDisplayPlayerID();
    if (displayPlayerID == -1) then
	  return;
	end

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
      if (Players[displayPlayerID] ~= nil) then
        canRecruit = pGreatPeople:CanRecruitPerson(displayPlayerID, entry.Individual);
        if (not isPast) then
          canReject = pGreatPeople:CanRejectPerson(displayPlayerID, entry.Individual);
          if (canReject) then
            rejectCost = pGreatPeople:GetRejectCost(displayPlayerID, entry.Individual);
          end
        end
        canPatronizeWithGold = pGreatPeople:CanPatronizePerson(displayPlayerID, entry.Individual, YieldTypes.GOLD);
        patronizeWithGoldCost = pGreatPeople:GetPatronizeCost(displayPlayerID, entry.Individual, YieldTypes.GOLD);
        canPatronizeWithFaith = pGreatPeople:CanPatronizePerson(displayPlayerID, entry.Individual, YieldTypes.FAITH);
        patronizeWithFaithCost = pGreatPeople:GetPatronizeCost(displayPlayerID, entry.Individual, YieldTypes.FAITH);
        earnConditions = pGreatPeople:GetEarnConditionsText(displayPlayerID, entry.Individual);
      end
      local individualInfo = GameInfo.GreatPersonIndividuals[entry.Individual];
      actionCharges = individualInfo.ActionCharges;
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
	  if (player:GetID() == displayPlayerID) then
        playerName = playerName .. Locale.Lookup(PlayerConfigurations[player:GetID()]:GetCivilizationShortDescription());
        isPlayer = true;
			elseif (Game.GetLocalObserver() == PlayerTypes.OBSERVER or Players[displayPlayerID]:GetDiplomacy():HasMet(player:GetID())) then
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
    -- Infixo end

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
    if not RefreshYields() then
        Controls.Vignette:SetSizeY(m_TopPanelConsideredHeight);
    end

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
	SelectTab( m_pGreatPeopleTabInstance.Button );
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
	if (unitOwner == Game.GetLocalObserver() or Game.GetLocalObserver() == PlayerTypes.OBSERVER) then
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
function Refresh( newRefreshFunc:ifunction )
	-- Update the refresh function if passed in a new one
	if newRefreshFunc ~= nil then
		m_RefreshFunc = newRefreshFunc;
	end

	-- Call current refresh function
	if m_RefreshFunc ~= nil then
		m_RefreshFunc();
	end
end

-- ===========================================================================
function RefreshCurrentGreatPeople()
	local kData :table	= {
		Timeline		= {},
		PointsByClass	= {},
	};

	PopulateData(kData, false);	-- do not use past data
	ViewCurrent(kData);

	m_kData = kData;
end

-- ===========================================================================
function RefreshPreviousGreatPeople()
	local kData :table	= {
		Timeline		= {},
		PointsByClass	= {},
	};

	PopulateData(kData, true);	-- use past data
	ViewPast(kData);

	m_kData = kData;
end

-- ===========================================================================
function RefreshPlannerTab()
	-- planner will also use previously recruited data
	local kData :table	= {
		Timeline		= {},
		PointsByClass	= {},
	};

	PopulateData(kData, true);	-- use past data
	ViewPlanner(kData);

	m_kData = kData;
end

-- ===========================================================================
--  Tab callbacks
-- ===========================================================================

function OnGreatPeopleClick( uiSelectedButton:table )
	ResetTabButtons();
	SetTabButtonsSelected(uiSelectedButton);
    -- Infixo
    Controls.ClassNamePull:SetHide( true );
    Controls.CivLeaderPull:SetHide( true );
    Controls.Total:SetHide( true );
    -- Infixo end
	Refresh(RefreshCurrentGreatPeople);
end

function OnPreviousRecruitedClick( uiSelectedButton:table )
	ResetTabButtons();
	SetTabButtonsSelected(uiSelectedButton);
    -- Infixo
    Controls.ClassNamePull:SetHide( false );
    Controls.CivLeaderPull:SetHide( false );
    Controls.Total:SetHide( false );
    -- Infixo end
	Refresh(RefreshPreviousGreatPeople);
end

function OnPlannerClick( uiSelectedButton:table )
	ResetTabButtons();
	SetTabButtonsSelected(uiSelectedButton);
    -- hide controls from previously recruited
    Controls.ClassNamePull:SetHide( true );
    Controls.CivLeaderPull:SetHide( true );
    Controls.Total:SetHide( true );
    -- Infixo end
	Refresh(RefreshPlannerTab);
end

-- ===========================================================================
-- FOR OVERRIDE
-- ===========================================================================
function IsReadOnly()
	return false;
end

-- =======================================================================================
--  UI Event
-- =======================================================================================
function OnInit( isHotload:boolean )
	LateInitialize();
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

	m_tabButtonIM:ResetInstances();

	-- Game engine Events	
	Events.LocalPlayerChanged.Remove( OnLocalPlayerChanged );	
	Events.LocalPlayerTurnBegin.Remove( OnLocalPlayerTurnBegin );	
	Events.LocalPlayerTurnEnd.Remove( OnLocalPlayerTurnEnd );
	Events.UnitGreatPersonActivated.Remove( OnUnitGreatPersonActivated );
	Events.GreatPeoplePointsChanged.Remove( OnGreatPeoplePointsChanged );
	
	-- LUA Events
	LuaEvents.GameDebug_Return.Remove(							OnGameDebugReturn );
	LuaEvents.LaunchBar_OpenGreatPeoplePopup.Remove(			OnOpenViaLaunchBar );
	LuaEvents.NotificationPanel_OpenGreatPeoplePopup.Remove(	OnOpenViaNotification );
	LuaEvents.LaunchBar_CloseGreatPeoplePopup.Remove(			OnClose );
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
function AddTabInstance( buttonText:string, callbackFunc:ifunction )
	local kInstance:object = m_tabButtonIM:GetInstance();
	kInstance.Button:SetText(Locale.Lookup(buttonText));
	kInstance.Button:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	m_tabs.AddTab( kInstance.Button, callbackFunc );
	m_numTabs = m_numTabs + 1;
	return kInstance;
end

-- =======================================================================================
function SelectTab( buttonControl:table )
	m_tabs.SelectTab(buttonControl);
end

-- =======================================================================================
function SetTabButtonsSelected( buttonControl:table )
	for i=1, m_tabButtonIM.m_iCount, 1 do
		local buttonInstance:table = m_tabButtonIM:GetAllocatedInstance(i);
		if buttonInstance and buttonInstance.Button == buttonControl then
			buttonInstance.Button:SetSelected(true);
			buttonInstance.SelectButton:SetHide(false);
		end
	end
end

-- =======================================================================================
function ResetTabButtons()
	for i=1, m_tabButtonIM.m_iCount, 1 do
		local buttonInstance:table = m_tabButtonIM:GetAllocatedInstance(i);
		if buttonInstance then
			buttonInstance.Button:SetSelected(false);
			buttonInstance.SelectButton:SetHide(true);
		end
	end
end

-- =======================================================================================
function ResizeTabContainer()
	if m_numTabs > 0 then
		local desiredSize = (TAB_SIZE * m_numTabs) + (TAB_PADDING * (m_numTabs - 1));
		Controls.TabContainer:SetSizeX(desiredSize);
	end
end

-- =======================================================================================
-- This function should be overridden in mods/dlc to add new tabs to this screen
-- =======================================================================================
function AddCustomTabs()
	-- No custom tabs in base games
end

-- =======================================================================================
function LateInitialize()
	--[[
	TODO: populate reusable data here
	--]]
	-- supported great person classess
	-- TODO: probably could be moved to DB
	GameInfo.GreatPersonClasses.GREAT_PERSON_CLASS_GENERAL.Planner = true;
	GameInfo.GreatPersonClasses.GREAT_PERSON_CLASS_ADMIRAL.Planner = true;
	GameInfo.GreatPersonClasses.GREAT_PERSON_CLASS_ENGINEER.Planner = true;
	GameInfo.GreatPersonClasses.GREAT_PERSON_CLASS_MERCHANT.Planner = true;
	GameInfo.GreatPersonClasses.GREAT_PERSON_CLASS_SCIENTIST.Planner = true;
	-- detect which eras are there
end

-- =======================================================================================
--
-- =======================================================================================
function Initialize()

    if (not HasCapability("CAPABILITY_GREAT_PEOPLE_VIEW")) then
        -- Great People Viewing is off, just exit
        return;
    end

	m_numTabs = 0;
    
    -- Tab setup and setting of default tab.
    m_tabs = CreateTabs( Controls.TabContainer, 42, 34, UI.GetColorValueFromHexLiteral(0xFF331D05) );
    
	m_pGreatPeopleTabInstance = AddTabInstance("LOC_GREAT_PEOPLE_TAB_GREAT_PEOPLE", OnGreatPeopleClick);
	m_pPrevRecruitedTabInstance = AddTabInstance("LOC_GREAT_PEOPLE_TAB_PREVIOUSLY_RECRUITED", OnPreviousRecruitedClick);
	m_pPlannerTabInstance = AddTabInstance("LOC_GAMESUMMARY_OVERVIEW", OnPlannerClick);

	AddCustomTabs()

	ResizeTabContainer();
    
	m_tabs.CenterAlignTabs(-10);
	m_tabs.SelectTab( m_pGreatPeopleTabInstance.Button );

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
	
	m_TopPanelConsideredHeight = Controls.Vignette:GetSizeY() - TOP_PANEL_OFFSET;
end

-- This wildcard include will include all loaded files beginning with "GreatPeoplePopup_"
-- This method replaces the uses of include("GreatPeoplePopup") in files that want to override 
-- functions from this file. If you're implementing a new "GreatPeoplePopup_" file DO NOT include this file.
include("GreatPeoplePopup_", true);

Initialize();

print("OK loaded GreatPeoplePopup.lua from RGP Mod");