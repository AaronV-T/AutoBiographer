local Controller = AutoBiographer_Controller
local EM = AutoBiographer_EventManager
local HF = HelperFunctions

AutoBiographer_MainWindow = CreateFrame("Frame", "AutoBiographerMain", UIParent, "BasicFrameTemplateWithInset")
AutoBiographer_MainWindow:SetFrameStrata("HIGH")

AutoBiographer_CustomEventDetailsWindow = CreateFrame("Frame", "AutoBiographerCustomEventDetail", AutoBiographer_MainWindow, "BasicFrameTemplate")
AutoBiographer_DebugWindow = CreateFrame("Frame", "AutoBiographerDebug", AutoBiographer_MainWindow, "BasicFrameTemplate")
AutoBiographer_EventWindow = CreateFrame("Frame", "AutoBiographerEvent", AutoBiographer_MainWindow, "BasicFrameTemplate")
AutoBiographer_NoteDetailsWindow = CreateFrame("Frame", "AutoBiographerNoteDetail", AutoBiographer_MainWindow, "BasicFrameTemplate")
AutoBiographer_NotesWindow = CreateFrame("Frame", "AutoBiographerNotes", AutoBiographer_MainWindow, "BasicFrameTemplate")
AutoBiographer_StatisticsWindow = CreateFrame("Frame", "AutoBiographerStatistics", AutoBiographer_MainWindow, "BasicFrameTemplate")
AutoBiographer_VerificationWindow = CreateFrame("Frame", "AutoBiographerVerification", AutoBiographer_MainWindow, "BasicFrameTemplate")

--
--
-- Window Initialization Helper
--
--
AutioBiographer_WindowHelper = {}
function AutioBiographer_WindowHelper:InitialzationHelper(window, width, height, frameLevel, windowTitle, scrollFrameYOffset)
  local frame = window
  frame:SetSize(width, height) 
  frame:SetPoint("CENTER")

  frame:EnableKeyboard(true)
  frame:EnableMouse(true)
  frame:SetMovable(true)

  frame:SetScript("OnHide", function(self)
    if (self.isMoving) then
      self:StopMovingOrSizing()
      self.isMoving = false
    end
  end)

  frame:SetScript("OnKeyDown", function(self, key)
    if (key == "ESCAPE") then
      frame:SetPropagateKeyboardInput(false)
      frame:Hide()
    elseif (key == "END") then
      frame:SetPropagateKeyboardInput(false)
      local sliderMin, sliderMax = frame.ScrollFrame.Scrollbar:GetMinMaxValues()
      frame.ScrollFrame.Scrollbar:SetValue(sliderMax)
    elseif (key == "HOME") then
      frame:SetPropagateKeyboardInput(false)
      local sliderMin, sliderMax = frame.ScrollFrame.Scrollbar:GetMinMaxValues()
      frame.ScrollFrame.Scrollbar:SetValue(sliderMin)
    elseif (key == "PAGEDOWN") then
      frame:SetPropagateKeyboardInput(false)
      local sliderMin, sliderMax = frame.ScrollFrame.Scrollbar:GetMinMaxValues()
      local sliderCurrentValue = frame.ScrollFrame.Scrollbar:GetValue()

      local sliderNextValue = sliderCurrentValue + frame.ScrollFrame:GetHeight()

      if (sliderNextValue > sliderMax) then
        sliderNextValue = sliderMax
      elseif (sliderNextValue < sliderMin) then
        sliderNextValue = sliderMin
      end

      frame.ScrollFrame.Scrollbar:SetValue(sliderNextValue)
    elseif (key == "PAGEUP") then
      frame:SetPropagateKeyboardInput(false)
      local sliderMin, sliderMax = frame.ScrollFrame.Scrollbar:GetMinMaxValues()
      local sliderCurrentValue = frame.ScrollFrame.Scrollbar:GetValue()

      local sliderNextValue = sliderCurrentValue - frame.ScrollFrame:GetHeight()

      if (sliderNextValue > sliderMax) then
        sliderNextValue = sliderMax
      elseif (sliderNextValue < sliderMin) then
        sliderNextValue = sliderMin
      end

      frame.ScrollFrame.Scrollbar:SetValue(sliderNextValue)
    else
      frame:SetPropagateKeyboardInput(true)
    end
  end)

  frame:SetScript("OnMouseDown", function(self, button)
    if (button == "LeftButton" and not self.isMoving) then
      self:StartMoving()
      self.isMoving = true
    end
  end)

  frame:SetScript("OnMouseUp", function(self, button)
    if (button == "LeftButton" and self.isMoving) then
      self:StopMovingOrSizing()
      self.isMoving = false
    end
  end)

  frame:SetScript("OnMouseWheel", function(self, direction)
    local sliderMin, sliderMax = frame.ScrollFrame.Scrollbar:GetMinMaxValues()
    local sliderCurrentValue = frame.ScrollFrame.Scrollbar:GetValue()

    local sliderNextValue = sliderCurrentValue - (frame.ScrollFrame.Scrollbar.scrollStep * direction)

    if (sliderNextValue > sliderMax) then
      sliderNextValue = sliderMax
    elseif (sliderNextValue < sliderMin) then
      sliderNextValue = sliderMin
    end

    frame.ScrollFrame.Scrollbar:SetValue(sliderNextValue)
  end)

  frame.Toggle = function(self)
    if (self:IsVisible()) then
      self:Hide()
    else
      self:Update()
      self:Show()
      self:SetFrameLevel(frameLevel)
    end
  end

  frame.Title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.Title:SetPoint("LEFT", frame.TitleBg, "LEFT", 5, 0);
  frame.Title:SetText("AutoBiographer " .. windowTitle .. " Window")
  
  --scrollframe 
  frame.ScrollFrame = CreateFrame("ScrollFrame", nil, frame) 
  frame.ScrollFrame:SetPoint("TOPLEFT", 10, scrollFrameYOffset) 
  frame.ScrollFrame:SetPoint("BOTTOMRIGHT", -10, 10) 

  --scrollbar 
  frame.ScrollFrame.Scrollbar = CreateFrame("Slider", nil, frame.ScrollFrame, "UIPanelScrollBarTemplate") 
  frame.ScrollFrame.Scrollbar:SetPoint("TOPLEFT", frame, "TOPRIGHT", -25, -40)
  frame.ScrollFrame.Scrollbar:SetPoint("BOTTOMLEFT", frame, "BOTTOMRIGHT", -25, 22)
  frame.ScrollFrame.Scrollbar:SetMinMaxValues(1, 1)
  frame.ScrollFrame.Scrollbar:SetValueStep(1)
  frame.ScrollFrame.Scrollbar.scrollStep = 15
  frame.ScrollFrame.Scrollbar:SetValue(0)
  frame.ScrollFrame.Scrollbar:SetWidth(16)
  frame.ScrollFrame.Scrollbar:SetScript("OnValueChanged",
    function (self, value) 
      self:GetParent():SetVerticalScroll(value) 
    end
  )
  local scrollbg = frame.ScrollFrame.Scrollbar:CreateTexture(nil, "BACKGROUND") 
  scrollbg:SetAllPoints(scrollbar) 
  scrollbg:SetTexture(0, 0, 0, 0.4)

  --content frame 
  frame.ScrollFrame.Content = CreateFrame("Frame", nil, frame.ScrollFrame)
  frame.ScrollFrame.Content:SetSize(width - 25, height)
  frame.ScrollFrame:SetScrollChild(frame.ScrollFrame.Content)
end

--
--
-- Custom Event Details Window Initialization
--
--

function AutoBiographer_CustomEventDetailsWindow:Initialize()
  local frame = self
  AutioBiographer_WindowHelper:InitialzationHelper(frame, 600, 450, 200, "Custom Event Details", -25)

  frame.ScrollFrame.Content.ContentEditBoxScrollFrame = CreateFrame("ScrollFrame", nil, frame.ScrollFrame.Content, "InputScrollFrameTemplate")
  frame.ScrollFrame.Content.ContentEditBoxScrollFrame:SetSize(500, 300)
  frame.ScrollFrame.Content.ContentEditBoxScrollFrame:SetPoint("TOP", frame.ScrollFrame.Content, "TOP", 0, -25)
  frame.ScrollFrame.Content.ContentEditBoxScrollFrame.EditBox:SetWidth(frame.ScrollFrame.Content.ContentEditBoxScrollFrame:GetWidth())
  frame.ScrollFrame.Content.ContentEditBoxScrollFrame.EditBox:SetFontObject("ChatFontNormal")
  frame.ScrollFrame.Content.ContentEditBoxScrollFrame.EditBox:SetMaxLetters(64)
  --frame.ScrollFrame.Content.ContentEditBoxScrollFrame.CharCount:Hide()

  frame.ScrollFrame.Content.CreateEventBtn = CreateFrame("Button", nil, frame.ScrollFrame.Content, "UIPanelButtonTemplate");
  frame.ScrollFrame.Content.CreateEventBtn:SetPoint("BOTTOM", frame.ScrollFrame.Content, "BOTTOM", 0, 50);
  frame.ScrollFrame.Content.CreateEventBtn:SetSize(250, 35);
  frame.ScrollFrame.Content.CreateEventBtn:SetText("Save Event and Close Window");
  frame.ScrollFrame.Content.CreateEventBtn:SetNormalFontObject("GameFontNormalLarge");
  frame.ScrollFrame.Content.CreateEventBtn:SetHighlightFontObject("GameFontHighlightLarge");
  frame.ScrollFrame.Content.CreateEventBtn:SetScript("OnClick", 
    function(self)
      Controller:AddEvent(CustomEvent.New(time(), HelperFunctions.GetCoordinatesByUnitId("player"), frame.ScrollFrame.Content.ContentEditBoxScrollFrame.EditBox:GetText()))

      AutoBiographer_EventWindow:Update()
      AutoBiographer_CustomEventDetailsWindow:Toggle()
    end
  )

  frame:Hide()
  return frame
end

--
--
-- Debug Window Initialization
--
--

function AutoBiographer_DebugWindow:Initialize()
  local frame = self
  AutioBiographer_WindowHelper:InitialzationHelper(frame, 750, 585, 250, "Debug", -25)

  frame.ScrollFrame.Content.ChildrenCount = 0

  frame.LogsUpdated = function(self) -- This is called when a new debug log is added.
    if (self:IsVisible()) then
      self:Update()
    end
  end
  
  frame:Hide()
  return frame
end

--
--
-- Event Window Initialization
--
--

function AutoBiographer_EventWindow:Initialize()
  local frame = self
  AutioBiographer_WindowHelper:InitialzationHelper(frame, 750, 585, 150, "Event", -80)
  
  frame.CreateCustomEventBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate");
  frame.CreateCustomEventBtn:SetPoint("CENTER", frame, "TOP", 275, -50);
  frame.CreateCustomEventBtn:SetSize(120, 35);
  frame.CreateCustomEventBtn:SetText("Create Event");
  frame.CreateCustomEventBtn:SetNormalFontObject("GameFontNormalLarge");
  frame.CreateCustomEventBtn:SetHighlightFontObject("GameFontHighlightLarge");
  frame.CreateCustomEventBtn:SetScript("OnClick", 
    function(self)
      if (AutoBiographer_CustomEventDetailsWindow:IsVisible()) then
        AutoBiographer_CustomEventDetailsWindow:Update()
      else
        AutoBiographer_CustomEventDetailsWindow:Toggle()
      end
    end
  )

  local gameVersion = HelperFunctions.GetGameVersion()

  -- Filter Check Boxes
  local leftPoint = 30
  local fsArenaAndBattleground = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  fsArenaAndBattleground:SetPoint("CENTER", frame, "TOPLEFT", leftPoint, -40)
  fsArenaAndBattleground:SetText("Arena\n& BG")
  if (gameVersion < 2) then fsArenaAndBattleground:SetText("BG") end
  local cbArenaAndBattleground = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate") 
  cbArenaAndBattleground:SetPoint("CENTER", frame, "TOPLEFT", leftPoint, -65)
  cbArenaAndBattleground:SetChecked(AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.ArenaJoined])
  cbArenaAndBattleground:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.ArenaJoined] = self:GetChecked()
    AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.ArenaLost] = self:GetChecked()
    AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.ArenaWon] = self:GetChecked()
    AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.BattlegroundJoined] = self:GetChecked()
    AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.BattlegroundLost] = self:GetChecked()
    AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.BattlegroundWon] = self:GetChecked()
    frame:Update()
  end)

  leftPoint = leftPoint + 40
  local fsBossKill = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  fsBossKill:SetPoint("CENTER", frame, "TOPLEFT", leftPoint, -40)
  fsBossKill:SetText("Boss\nKill")
  local cbBossKill= CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate") 
  cbBossKill:SetPoint("CENTER", frame, "TOPLEFT", leftPoint, -65)
  cbBossKill:SetChecked(AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.BossKill])
  cbBossKill:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.BossKill] = self:GetChecked()
    frame:Update()
  end)

  leftPoint = leftPoint + 40
  local fsBossKill = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  fsBossKill:SetPoint("CENTER", frame, "TOPLEFT", leftPoint, -40)
  fsBossKill:SetText("Custom")
  local cbBossKill= CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate") 
  cbBossKill:SetPoint("CENTER", frame, "TOPLEFT", leftPoint, -65)
  cbBossKill:SetChecked(AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.Custom])
  cbBossKill:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.Custom] = self:GetChecked()
    frame:Update()
  end)
  
  leftPoint = leftPoint + 40
  local fsFirstAcquiredItem = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  fsFirstAcquiredItem:SetPoint("CENTER", frame, "TOPLEFT", leftPoint, -40) 
  fsFirstAcquiredItem:SetText("First\nItem")
  local cbFirstAcquiredItem = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate") 
  cbFirstAcquiredItem:SetPoint("CENTER", frame, "TOPLEFT", leftPoint, -65)
  cbFirstAcquiredItem:SetChecked(AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.FirstAcquiredItem])
  cbFirstAcquiredItem:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.FirstAcquiredItem] = self:GetChecked()
    frame:Update()
  end)
  
  leftPoint = leftPoint + 40
  local fsFirstKill = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  fsFirstKill:SetPoint("CENTER", frame, "TOPLEFT", leftPoint, -40)
  fsFirstKill:SetText("First\nKill")
  local cbFirstKill = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate") 
  cbFirstKill:SetPoint("CENTER", frame, "TOPLEFT", leftPoint, -65)
  cbFirstKill:SetChecked(AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.FirstKill])
  cbFirstKill:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.FirstKill] = self:GetChecked()
    frame:Update()
  end)
  
  leftPoint = leftPoint + 40
  local fsGuild = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  fsGuild:SetPoint("CENTER", frame, "TOPLEFT", leftPoint, -40)
  fsGuild:SetText("Guild")
  local cbGuild = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate") 
  cbGuild:SetPoint("CENTER", frame, "TOPLEFT", leftPoint, -65)
  cbGuild:SetChecked(AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.GuildJoined])
  cbGuild:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.GuildJoined] = self:GetChecked()
    AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.GuildLeft] = self:GetChecked()
    AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.GuildRankChanged] = self:GetChecked()
    frame:Update()
  end)
  
  leftPoint = leftPoint + 40
  local fsLevelUp = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  fsLevelUp:SetPoint("CENTER", frame, "TOPLEFT", leftPoint, -40)
  fsLevelUp:SetText("Level\nUp")
  local cbLevelUp= CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate") 
  cbLevelUp:SetPoint("CENTER", frame, "TOPLEFT", leftPoint, -65)
  cbLevelUp:SetChecked(AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.LevelUp])
  cbLevelUp:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.LevelUp] = self:GetChecked()
    frame:Update()
  end)
  
  leftPoint = leftPoint + 40
  local fsPlayerDeath = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  fsPlayerDeath:SetPoint("CENTER", frame, "TOPLEFT", leftPoint, -40)
  fsPlayerDeath:SetText("Player\nDeath")
  local cbPlayerDeath = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate") 
  cbPlayerDeath:SetPoint("CENTER", frame, "TOPLEFT", leftPoint, -65)
  cbPlayerDeath:SetChecked(AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.PlayerDeath])
  cbPlayerDeath:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.PlayerDeath] = self:GetChecked()
    frame:Update()
  end)
  
  leftPoint = leftPoint + 40
  local fsQuestTurnIn = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  fsQuestTurnIn:SetPoint("CENTER", frame, "TOPLEFT", leftPoint, -40)
  fsQuestTurnIn:SetText("Quest")
  local cbQuestTurnIn = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate") 
  cbQuestTurnIn:SetPoint("CENTER", frame, "TOPLEFT", leftPoint, -65)
  cbQuestTurnIn:SetChecked(AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.QuestTurnIn])
  cbQuestTurnIn:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.QuestTurnIn] = self:GetChecked()
    frame:Update()
  end)
  
  leftPoint = leftPoint + 40
  local fsReputationLevelChanged = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  fsReputationLevelChanged:SetPoint("CENTER", frame, "TOPLEFT", leftPoint, -40)
  fsReputationLevelChanged:SetText("Rep\nChange")
  local cbReputationLevelChanged= CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate") 
  cbReputationLevelChanged:SetPoint("CENTER", frame, "TOPLEFT", leftPoint, -65)
  cbReputationLevelChanged:SetChecked(AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.ReputationLevelChanged])
  cbReputationLevelChanged:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.ReputationLevelChanged] = self:GetChecked()
    frame:Update()
  end)
  
  leftPoint = leftPoint + 40
  local fsSkillMilestone = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  fsSkillMilestone:SetPoint("CENTER", frame, "TOPLEFT", leftPoint, -40)
  fsSkillMilestone:SetText("Skill")
  local cbSkillMilestone = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate") 
  cbSkillMilestone:SetPoint("CENTER", frame, "TOPLEFT", leftPoint, -65)
  cbSkillMilestone:SetChecked(AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.SkillMilestone])
  cbSkillMilestone:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.SkillMilestone] = self:GetChecked()
    frame:Update()
  end)
  
  leftPoint = leftPoint + 40
  local fsSpellLearned = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  fsSpellLearned:SetPoint("CENTER", frame, "TOPLEFT", leftPoint, -40)
  fsSpellLearned:SetText("Spell")
  local cbSpellLearned= CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate") 
  cbSpellLearned:SetPoint("CENTER", frame, "TOPLEFT", leftPoint, -65)
  cbSpellLearned:SetChecked(AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.SpellLearned])
  cbSpellLearned:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.SpellLearned] = self:GetChecked()
    frame:Update()
  end)
  
  leftPoint = leftPoint + 40
  local fsSubZoneFirstVisit = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  fsSubZoneFirstVisit:SetPoint("CENTER", frame, "TOPLEFT", leftPoint, -40)
  fsSubZoneFirstVisit:SetText("Sub\nZone")
  local cbSubZoneFirstVisit = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate") 
  cbSubZoneFirstVisit:SetPoint("CENTER", frame, "TOPLEFT", leftPoint, -65)
  cbSubZoneFirstVisit:SetChecked(AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.SubZoneFirstVisit])
  cbSubZoneFirstVisit:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.SubZoneFirstVisit] = self:GetChecked()
    frame:Update()
  end)
  
  leftPoint = leftPoint + 40
  local fsZoneFirstVisit = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  fsZoneFirstVisit:SetPoint("CENTER", frame, "TOPLEFT", leftPoint, -40)
  fsZoneFirstVisit:SetText("Zone")
  local cbZoneFirstVisit = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate") 
  cbZoneFirstVisit:SetPoint("CENTER", frame, "TOPLEFT", leftPoint, -65)
  cbZoneFirstVisit:SetChecked(AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.ZoneFirstVisit])
  cbZoneFirstVisit:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.ZoneFirstVisit] = self:GetChecked()
    frame:Update()
  end)
  
  frame.ScrollFrame.Content.FontStringsPool = {
    Allocated = {},
    UnAllocated = {},
  }

  frame:Hide()
  return frame
end

--
--
-- Main Window Initialization
--
--

function AutoBiographer_MainWindow:Initialize()
  local frame = self
  AutioBiographer_WindowHelper:InitialzationHelper(frame, 800, 650, 100, "Main", -25)
  
  -- Buttons
  frame.ScrollFrame.Content.EventsBtn = CreateFrame("Button", nil, frame.ScrollFrame.Content, "UIPanelButtonTemplate");
  frame.ScrollFrame.Content.EventsBtn:SetPoint("CENTER", frame.ScrollFrame.Content, "TOP", -260, -25);
  frame.ScrollFrame.Content.EventsBtn:SetSize(120, 35);
  frame.ScrollFrame.Content.EventsBtn:SetText("Events");
  frame.ScrollFrame.Content.EventsBtn:SetNormalFontObject("GameFontNormalLarge");
  frame.ScrollFrame.Content.EventsBtn:SetHighlightFontObject("GameFontHighlightLarge");
  frame.ScrollFrame.Content.EventsBtn:SetScript("OnClick", 
    function(self)
      AutoBiographer_EventWindow:Toggle()
    end
  )

  frame.ScrollFrame.Content.StatisticsBtn = CreateFrame("Button", nil, frame.ScrollFrame.Content, "UIPanelButtonTemplate");
  frame.ScrollFrame.Content.StatisticsBtn:SetPoint("CENTER", frame.ScrollFrame.Content, "TOP", -130, -25);
  frame.ScrollFrame.Content.StatisticsBtn:SetSize(120, 35);
  frame.ScrollFrame.Content.StatisticsBtn:SetText("Statistics");
  frame.ScrollFrame.Content.StatisticsBtn:SetNormalFontObject("GameFontNormalLarge");
  frame.ScrollFrame.Content.StatisticsBtn:SetHighlightFontObject("GameFontHighlightLarge");
  frame.ScrollFrame.Content.StatisticsBtn:SetScript("OnClick", 
    function(self)
      AutoBiographer_StatisticsWindow:Toggle()
    end
  )

  frame.ScrollFrame.Content.DebugBtn = CreateFrame("Button", nil, frame.ScrollFrame.Content, "UIPanelButtonTemplate");
  frame.ScrollFrame.Content.DebugBtn:SetPoint("CENTER", frame.ScrollFrame.Content, "TOP", 0, -25);
  frame.ScrollFrame.Content.DebugBtn:SetSize(120, 35);
  frame.ScrollFrame.Content.DebugBtn:SetText("Notes");
  frame.ScrollFrame.Content.DebugBtn:SetNormalFontObject("GameFontNormalLarge");
  frame.ScrollFrame.Content.DebugBtn:SetHighlightFontObject("GameFontHighlightLarge");
  frame.ScrollFrame.Content.DebugBtn:SetScript("OnClick", 
    function(self)
      AutoBiographer_NotesWindow:Toggle()
    end
  )
  
  frame.ScrollFrame.Content.OptionsBtn = CreateFrame("Button", nil, frame.ScrollFrame.Content, "UIPanelButtonTemplate");
  frame.ScrollFrame.Content.OptionsBtn:SetPoint("CENTER", frame.ScrollFrame.Content, "TOP", 130, -25);
  frame.ScrollFrame.Content.OptionsBtn:SetSize(120, 35);
  frame.ScrollFrame.Content.OptionsBtn:SetText("Options");
  frame.ScrollFrame.Content.OptionsBtn:SetNormalFontObject("GameFontNormalLarge");
  frame.ScrollFrame.Content.OptionsBtn:SetHighlightFontObject("GameFontHighlightLarge");
  frame.ScrollFrame.Content.OptionsBtn:SetScript("OnClick", 
    function(self)
      InterfaceOptionsFrame_OpenToCategory(AutoBiographer_OptionWindow) -- Call this twice because it won't always work correcly if just called once.
      InterfaceOptionsFrame_OpenToCategory(AutoBiographer_OptionWindow)
      AutoBiographer_MainWindow:Hide()
    end
  )
  
  frame.ScrollFrame.Content.DebugBtn = CreateFrame("Button", nil, frame.ScrollFrame.Content, "UIPanelButtonTemplate");
  frame.ScrollFrame.Content.DebugBtn:SetPoint("CENTER", frame.ScrollFrame.Content, "TOP", 260, -25);
  frame.ScrollFrame.Content.DebugBtn:SetSize(120, 35);
  frame.ScrollFrame.Content.DebugBtn:SetText("Debug");
  frame.ScrollFrame.Content.DebugBtn:SetNormalFontObject("GameFontNormalLarge");
  frame.ScrollFrame.Content.DebugBtn:SetHighlightFontObject("GameFontHighlightLarge");
  frame.ScrollFrame.Content.DebugBtn:SetScript("OnClick", 
    function(self)
      AutoBiographer_DebugWindow:Toggle()
    end
  )

  local gameVersion = HelperFunctions.GetGameVersion()

  -- Header
  frame.ScrollFrame.Content.TimePlayedThisLevelFS = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.TimePlayedThisLevelFS:SetPoint("LEFT", frame.ScrollFrame.Content, "TOP", 50, -65)

  local topPoint = -55

  -- Arena Stats
  if (gameVersion == 2) then
    topPoint = topPoint - 15
    frame.ScrollFrame.Content.ArenaHeaderFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.ScrollFrame.Content.ArenaHeaderFs:SetPoint("TOPLEFT", 10, topPoint)
    frame.ScrollFrame.Content.ArenaHeaderFs:SetText("Arenas")
    topPoint = topPoint - 20

    frame.ScrollFrame.Content.Arena2v2StatsFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.ScrollFrame.Content.Arena2v2StatsFs:SetPoint("TOPLEFT", 10, topPoint)
    topPoint = topPoint - 15

    frame.ScrollFrame.Content.Arena3v3StatsFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.ScrollFrame.Content.Arena3v3StatsFs:SetPoint("TOPLEFT", 10, topPoint)
    topPoint = topPoint - 15

    frame.ScrollFrame.Content.Arena5v5StatsFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.ScrollFrame.Content.Arena5v5StatsFs:SetPoint("TOPLEFT", 10, topPoint)
    topPoint = topPoint - 15
  end

  -- Battleground Stats
  if (gameVersion < 3) then
    topPoint = topPoint - 15
    frame.ScrollFrame.Content.BattlegroundHeaderFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.ScrollFrame.Content.BattlegroundHeaderFs:SetPoint("TOPLEFT", 10, topPoint)
    frame.ScrollFrame.Content.BattlegroundHeaderFs:SetText("Battlegrounds")
    topPoint = topPoint - 20

    frame.ScrollFrame.Content.AvStatsFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.ScrollFrame.Content.AvStatsFs:SetPoint("TOPLEFT", 10, topPoint)
    topPoint = topPoint - 15

    frame.ScrollFrame.Content.AbStatsFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.ScrollFrame.Content.AbStatsFs:SetPoint("TOPLEFT", 10, topPoint)
    topPoint = topPoint - 15

    if (gameVersion == 2) then
      frame.ScrollFrame.Content.EotsStatsFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      frame.ScrollFrame.Content.EotsStatsFs:SetPoint("TOPLEFT", 10, topPoint)
      topPoint = topPoint - 15
    end

    frame.ScrollFrame.Content.WsgStatsFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.ScrollFrame.Content.WsgStatsFs:SetPoint("TOPLEFT", 10, topPoint)
    topPoint = topPoint - 15
  end

  -- Damage Stats
  topPoint = topPoint - 15
  frame.ScrollFrame.Content.DamageHeaderFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  frame.ScrollFrame.Content.DamageHeaderFs:SetPoint("TOPLEFT", 10, topPoint)
  frame.ScrollFrame.Content.DamageHeaderFs:SetText("Damage")
  topPoint = topPoint - 20

  frame.ScrollFrame.Content.DamageDealtFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.DamageDealtFs:SetPoint("TOPLEFT", 10, topPoint)
  topPoint = topPoint - 15

  frame.ScrollFrame.Content.DamageTakenFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.DamageTakenFs:SetPoint("TOPLEFT", 10, topPoint)
  topPoint = topPoint - 15

  frame.ScrollFrame.Content.HealingOtherFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.HealingOtherFs:SetPoint("TOPLEFT", 10, topPoint)
  topPoint = topPoint - 15

  frame.ScrollFrame.Content.HealingSelfFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.HealingSelfFs:SetPoint("TOPLEFT", 10, topPoint)
  topPoint = topPoint - 15

  frame.ScrollFrame.Content.HealingTakenFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.HealingTakenFs:SetPoint("TOPLEFT", 10, topPoint)
  topPoint = topPoint - 15
  
  -- Death Stats
  topPoint = topPoint - 15
  frame.ScrollFrame.Content.DeathsHeaderFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  frame.ScrollFrame.Content.DeathsHeaderFs:SetPoint("TOPLEFT", 10, topPoint)
  frame.ScrollFrame.Content.DeathsHeaderFs:SetText("Deaths")
  topPoint = topPoint - 20

  frame.ScrollFrame.Content.TotalDeathsFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.TotalDeathsFs:SetPoint("TOPLEFT", 10, topPoint)
  topPoint = topPoint - 15

  frame.ScrollFrame.Content.DeathsToCreaturesFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.DeathsToCreaturesFs:SetPoint("TOPLEFT", 20, topPoint)
  topPoint = topPoint - 15

  frame.ScrollFrame.Content.DeathsToEnvironmentFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.DeathsToEnvironmentFs:SetPoint("TOPLEFT", 20, topPoint)
  topPoint = topPoint - 15

  frame.ScrollFrame.Content.DeathsToGameObjectsFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.DeathsToGameObjectsFs:SetPoint("TOPLEFT", 20, topPoint)
  topPoint = topPoint - 15

  frame.ScrollFrame.Content.DeathsToPetsFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.DeathsToPetsFs:SetPoint("TOPLEFT", 20, topPoint)
  topPoint = topPoint - 15

  frame.ScrollFrame.Content.DeathsToPlayersFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.DeathsToPlayersFs:SetPoint("TOPLEFT", 20, topPoint)
  topPoint = topPoint - 15

  frame.ScrollFrame.Content.DeathsToUnknownFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.DeathsToUnknownFs:SetPoint("TOPLEFT", 20, topPoint)
  topPoint = topPoint - 15

  -- Experience Stats
  topPoint = topPoint - 15
  frame.ScrollFrame.Content.ExperienceHeaderFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  frame.ScrollFrame.Content.ExperienceHeaderFs:SetPoint("TOPLEFT", 10, topPoint)
  frame.ScrollFrame.Content.ExperienceHeaderFs:SetText("Experience")
  topPoint = topPoint - 20

  frame.ScrollFrame.Content.ExperienceFromKillsFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.ExperienceFromKillsFs:SetPoint("TOPLEFT", 10, topPoint)
  topPoint = topPoint - 15

  frame.ScrollFrame.Content.ExperienceFromKillsBaseFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.ExperienceFromKillsBaseFs:SetPoint("TOPLEFT", 20, topPoint)
  topPoint = topPoint - 15

  frame.ScrollFrame.Content.ExperienceFromRestedBonusFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.ExperienceFromRestedBonusFs:SetPoint("TOPLEFT", 20, topPoint)
  topPoint = topPoint - 15

  frame.ScrollFrame.Content.ExperienceFromGroupBonusFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.ExperienceFromGroupBonusFs:SetPoint("TOPLEFT", 20, topPoint)
  topPoint = topPoint - 15

  frame.ScrollFrame.Content.ExperienceLostToRaidPenaltyFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.ExperienceLostToRaidPenaltyFs:SetPoint("TOPLEFT", 20, topPoint)
  topPoint = topPoint - 15

  frame.ScrollFrame.Content.ExperienceFromQuestsFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.ExperienceFromQuestsFs:SetPoint("TOPLEFT", 10, topPoint)
  topPoint = topPoint - 15

  frame.ScrollFrame.Content.ExperienceFromDiscoveryFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.ExperienceFromDiscoveryFs:SetPoint("TOPLEFT", 10, topPoint)
  topPoint = topPoint - 15

  -- Item Stats
  topPoint = topPoint - 15
  frame.ScrollFrame.Content.ItemsHeaderFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  frame.ScrollFrame.Content.ItemsHeaderFs:SetPoint("TOPLEFT", 10, topPoint)
  frame.ScrollFrame.Content.ItemsHeaderFs:SetText("Items")
  topPoint = topPoint - 20

  frame.ScrollFrame.Content.ItemsAuctionHouseFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.ItemsAuctionHouseFs:SetPoint("TOPLEFT", 10, topPoint)
  topPoint = topPoint - 15

  frame.ScrollFrame.Content.ItemsCreatedFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.ItemsCreatedFs:SetPoint("TOPLEFT", 10, topPoint)
  topPoint = topPoint - 15

  frame.ScrollFrame.Content.ItemsLootedFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.ItemsLootedFs:SetPoint("TOPLEFT", 10, topPoint)
  topPoint = topPoint - 15

  frame.ScrollFrame.Content.ItemsMailFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.ItemsMailFs:SetPoint("TOPLEFT", 10, topPoint)
  topPoint = topPoint - 15

  frame.ScrollFrame.Content.ItemsMailCodFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.ItemsMailCodFs:SetPoint("TOPLEFT", 10, topPoint)
  topPoint = topPoint - 15

  frame.ScrollFrame.Content.ItemsTradeFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.ItemsTradeFs:SetPoint("TOPLEFT", 10, topPoint)
  topPoint = topPoint - 15

  frame.ScrollFrame.Content.ItemsVendorFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.ItemsVendorFs:SetPoint("TOPLEFT", 10, topPoint)
  topPoint = topPoint - 15

  frame.ScrollFrame.Content.ItemsOtherFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.ItemsOtherFs:SetPoint("TOPLEFT", 10, topPoint)
  topPoint = topPoint - 15

  -- Kill Stats
  topPoint = topPoint - 15
  frame.ScrollFrame.Content.KillsHeaderFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  frame.ScrollFrame.Content.KillsHeaderFs:SetPoint("TOPLEFT", 10, topPoint)
  frame.ScrollFrame.Content.KillsHeaderFs:SetText("Kills")
  topPoint = topPoint - 20

  frame.ScrollFrame.Content.TotalTaggedKillsFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.TotalTaggedKillsFs:SetPoint("TOPLEFT", 10, topPoint)
  topPoint = topPoint - 15

  frame.ScrollFrame.Content.TaggedKillingBlowsFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.TaggedKillingBlowsFs:SetPoint("TOPLEFT", 20, topPoint)
  topPoint = topPoint - 15

  frame.ScrollFrame.Content.TaggedKillAssistsFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.TaggedKillAssistsFs:SetPoint("TOPLEFT", 20, topPoint)
  topPoint = topPoint - 15

  frame.ScrollFrame.Content.TaggedGroupKillsFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.TaggedGroupKillsFs:SetPoint("TOPLEFT", 20, topPoint)
  topPoint = topPoint - 15

  -- Miscellaneous Stats
  topPoint = topPoint - 15
  frame.ScrollFrame.Content.MiscellaneousHeaderFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  frame.ScrollFrame.Content.MiscellaneousHeaderFs:SetPoint("TOPLEFT", 10, topPoint)
  frame.ScrollFrame.Content.MiscellaneousHeaderFs:SetText("Miscellaneous")
  topPoint = topPoint - 20

  frame.ScrollFrame.Content.DuelsFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.DuelsFs:SetPoint("TOPLEFT", 10, topPoint)
  topPoint = topPoint - 15

  frame.ScrollFrame.Content.JumpsFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.JumpsFs:SetPoint("TOPLEFT", 10, topPoint)
  topPoint = topPoint - 15

  frame.ScrollFrame.Content.QuestsCompletedFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.QuestsCompletedFs:SetPoint("TOPLEFT", 10, topPoint)
  topPoint = topPoint - 15

  frame.ScrollFrame.Content.SpellsFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.SpellsFs:SetPoint("TOPLEFT", 10, topPoint)
  topPoint = topPoint - 15

  -- Money Stats
  topPoint = topPoint - 15
  frame.ScrollFrame.Content.MoneyHeaderFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  frame.ScrollFrame.Content.MoneyHeaderFs:SetPoint("TOPLEFT", 10, topPoint)
  frame.ScrollFrame.Content.MoneyHeaderFs:SetText("Money")
  topPoint = topPoint - 20

  frame.ScrollFrame.Content.MoneyGainedFromAuctionHouseSalesFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.MoneyGainedFromAuctionHouseSalesFs:SetPoint("TOPLEFT", 10, topPoint)
  topPoint = topPoint - 15

  frame.ScrollFrame.Content.MoneyGainedFromLootFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.MoneyGainedFromLootFs:SetPoint("TOPLEFT", 10, topPoint)
  topPoint = topPoint - 15

  frame.ScrollFrame.Content.MoneyGainedFromMailFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.MoneyGainedFromMailFs:SetPoint("TOPLEFT", 10, topPoint)
  topPoint = topPoint - 15

  frame.ScrollFrame.Content.MoneyGainedFromMailCodFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.MoneyGainedFromMailCodFs:SetPoint("TOPLEFT", 10, topPoint)
  topPoint = topPoint - 15

  frame.ScrollFrame.Content.MoneyGainedFromMerchantsFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.MoneyGainedFromMerchantsFs:SetPoint("TOPLEFT", 10, topPoint)
  topPoint = topPoint - 15

  frame.ScrollFrame.Content.MoneyGainedFromQuestsFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.MoneyGainedFromQuestsFs:SetPoint("TOPLEFT", 10, topPoint)
  topPoint = topPoint - 15

  frame.ScrollFrame.Content.MoneyGainedFromTradeFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.MoneyGainedFromTradeFs:SetPoint("TOPLEFT", 10, topPoint)
  topPoint = topPoint - 15

  frame.ScrollFrame.Content.MoneyGainedFromOtherFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.MoneyGainedFromOtherFs:SetPoint("TOPLEFT", 10, topPoint)
  topPoint = topPoint - 15

  -- Time Stats
  topPoint = topPoint - 15
  frame.ScrollFrame.Content.TimeHeaderFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  frame.ScrollFrame.Content.TimeHeaderFs:SetPoint("TOPLEFT", 10, topPoint)
  frame.ScrollFrame.Content.TimeHeaderFs:SetText("Time")
  topPoint = topPoint - 20

  frame.ScrollFrame.Content.TimeSpentAfkFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.TimeSpentAfkFs:SetPoint("TOPLEFT", 10, topPoint)
  topPoint = topPoint - 15

  frame.ScrollFrame.Content.TimeSpentCastingFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.TimeSpentCastingFs:SetPoint("TOPLEFT", 10, topPoint)
  topPoint = topPoint - 15

  frame.ScrollFrame.Content.TimeSpentDeadFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.TimeSpentDeadFs:SetPoint("TOPLEFT", 10, topPoint)
  topPoint = topPoint - 15

  frame.ScrollFrame.Content.TimeSpentInCombatFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.TimeSpentInCombatFs:SetPoint("TOPLEFT", 10, topPoint)
  topPoint = topPoint - 15

  frame.ScrollFrame.Content.TimeSpentInGroupFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.TimeSpentInGroupFs:SetPoint("TOPLEFT", 10, topPoint)
  topPoint = topPoint - 15

  frame.ScrollFrame.Content.TimeSpentLoggedInFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.TimeSpentLoggedInFs:SetPoint("TOPLEFT", 10, topPoint)
  topPoint = topPoint - 15

  frame.ScrollFrame.Content.TimeSpentOnTaxiFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.TimeSpentOnTaxiFs:SetPoint("TOPLEFT", 10, topPoint)
  topPoint = topPoint - 15

  local _, ySize = frame.ScrollFrame:GetSize()
  frame.ScrollFrame.Scrollbar:SetMinMaxValues(1, -topPoint - ySize)

  frame:Hide()
  return frame
end

--
--
-- Note Detail Window Initialization
--
--

function AutoBiographer_NoteDetailsWindow:Initialize()
  local frame = self
  AutioBiographer_WindowHelper:InitialzationHelper(frame, 600, 450, 200, "Note Details", -25)

  frame.ScrollFrame.Content.ContentEditBoxScrollFrame = CreateFrame("ScrollFrame", nil, frame.ScrollFrame.Content, "InputScrollFrameTemplate")
  frame.ScrollFrame.Content.ContentEditBoxScrollFrame:SetSize(500, 300)
  frame.ScrollFrame.Content.ContentEditBoxScrollFrame:SetPoint("TOP", frame.ScrollFrame.Content, "TOP", 0, -25)
  frame.ScrollFrame.Content.ContentEditBoxScrollFrame.EditBox:SetWidth(frame.ScrollFrame.Content.ContentEditBoxScrollFrame:GetWidth())
  frame.ScrollFrame.Content.ContentEditBoxScrollFrame.EditBox:SetFontObject("ChatFontNormal")
  frame.ScrollFrame.Content.ContentEditBoxScrollFrame.EditBox:SetMaxLetters(1024)
  --frame.ScrollFrame.Content.ContentEditBoxScrollFrame.CharCount:Hide()

  frame.ScrollFrame.Content.CreateNoteBtn = CreateFrame("Button", nil, frame.ScrollFrame.Content, "UIPanelButtonTemplate");
  frame.ScrollFrame.Content.CreateNoteBtn:SetPoint("BOTTOM", frame.ScrollFrame.Content, "BOTTOM", 0, 50);
  frame.ScrollFrame.Content.CreateNoteBtn:SetSize(250, 35);
  frame.ScrollFrame.Content.CreateNoteBtn:SetText("Save Note and Close Window");
  frame.ScrollFrame.Content.CreateNoteBtn:SetNormalFontObject("GameFontNormalLarge");
  frame.ScrollFrame.Content.CreateNoteBtn:SetHighlightFontObject("GameFontHighlightLarge");
  frame.ScrollFrame.Content.CreateNoteBtn:SetScript("OnClick", 
    function(self)
      Note.Update(AutoBiographer_NoteDetailsWindow.SelectedNote, frame.ScrollFrame.Content.ContentEditBoxScrollFrame.EditBox:GetText())

      AutoBiographer_NotesWindow:Update()
      AutoBiographer_NoteDetailsWindow:Toggle()
    end
  )

  frame:Hide()
  return frame
end

--
--
-- Notes Window Initialization
--
--

function AutoBiographer_NotesWindow:Initialize()
  local frame = self
  AutioBiographer_WindowHelper:InitialzationHelper(frame, 750, 585, 150, "Notes", -60)

  frame.CreateNoteBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate");
  frame.CreateNoteBtn:SetPoint("CENTER", frame, "TOP", 0, -40);
  frame.CreateNoteBtn:SetSize(120, 35);
  frame.CreateNoteBtn:SetText("Create Note");
  frame.CreateNoteBtn:SetNormalFontObject("GameFontNormalLarge");
  frame.CreateNoteBtn:SetHighlightFontObject("GameFontHighlightLarge");
  frame.CreateNoteBtn:SetScript("OnClick", 
    function(self)
      local newNote = Note.New("")
      table.insert(Controller:GetNotes().GenericNotes, newNote)
      AutoBiographer_NoteDetailsWindow.SelectedNote = newNote
      
      AutoBiographer_NotesWindow:Update()

      if (AutoBiographer_NoteDetailsWindow:IsVisible()) then
        AutoBiographer_NoteDetailsWindow:Update()
      else
        AutoBiographer_NoteDetailsWindow:Toggle()
      end
    end
  )

  local createdTimestampHeaderFs = self.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  createdTimestampHeaderFs:SetPoint("TOPLEFT", 5, 0)
  createdTimestampHeaderFs:SetText("Created")

  local lastUpdatedTimestampHeaderFs = self.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  lastUpdatedTimestampHeaderFs:SetPoint("TOPLEFT", 80, 0)
  lastUpdatedTimestampHeaderFs:SetText("Updated")

  local actionsHeaderFs = self.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  actionsHeaderFs:SetPoint("TOPLEFT", 155, 0)
  actionsHeaderFs:SetText("Actions")

  local contentHeaderFs = self.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  contentHeaderFs:SetPoint("TOPLEFT", 260, 0)
  contentHeaderFs:SetText("Note Content")

  frame.ScrollFrame.Content.ButtonsPool = {
    Allocated = {},
    UnAllocated = {},
  }

  frame.ScrollFrame.Content.FontStringsPool = {
    Allocated = {},
    UnAllocated = {},
  }

  frame:Hide()
  return frame
end

--
--
-- Statistics Window Initialization
--
--

function AutoBiographer_StatisticsWindow:Initialize()
  local frame = self
  AutioBiographer_WindowHelper:InitialzationHelper(frame, 750, 585, 150, "Statistics", -90)
  
  -- Dropdown
  frame.Dropdown = CreateFrame("Frame", nil, frame, "UIDropDownMenuTemplate")
  frame.Dropdown:SetSize(100, 25)
  frame.Dropdown:SetPoint("LEFT", frame, "TOP", -frame.Dropdown:GetWidth(), -40)

  if (not frame.DropdownText) then frame.DropdownText = "Kills" end
  if (not frame.StatisticsDisplayMode) then frame.StatisticsDisplayMode = AutoBiographerEnum.StatisticsDisplayMode.Kills end
  
  UIDropDownMenu_Initialize(frame.Dropdown, function(frame, level, menuList)
    local info = UIDropDownMenu_CreateInfo()
    info.func = function(frame, arg1, arg2, checked)
      AutoBiographer_StatisticsWindow.DropdownText = frame.value   
      AutoBiographer_StatisticsWindow.StatisticsDisplayMode = arg1
      AutoBiographer_StatisticsWindow.OrderColumnIndex = 1
      AutoBiographer_StatisticsWindow.OrderDirection = "ASC"
      AutoBiographer_StatisticsWindow:Update()
    end
  
    info.text, info.arg1 = "Item Aquisitions", AutoBiographerEnum.StatisticsDisplayMode.Items
    UIDropDownMenu_AddButton(info)
    info.text, info.arg1 = "Kills", AutoBiographerEnum.StatisticsDisplayMode.Kills
    UIDropDownMenu_AddButton(info)
    info.text, info.arg1 = "Other Players", AutoBiographerEnum.StatisticsDisplayMode.OtherPlayers
    UIDropDownMenu_AddButton(info)
    info.text, info.arg1 = "Spells", AutoBiographerEnum.StatisticsDisplayMode.Spells
    UIDropDownMenu_AddButton(info)
    info.text, info.arg1 = "Time", AutoBiographerEnum.StatisticsDisplayMode.Time
    UIDropDownMenu_AddButton(info)
  end)

  -- Level Range
  frame.MinimumLevelFs = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.MinimumLevelFs:SetPoint("LEFT", frame.Dropdown, "RIGHT", 60, 0)
  frame.MinimumLevelFs:SetText("Minimum Level:")
  frame.MinimumLevelEb = CreateFrame("EditBox", nil, frame, BackdropTemplateMixin and "BackdropTemplate");
  frame.MinimumLevelEb:SetSize(20, 20)
  frame.MinimumLevelEb:SetPoint("LEFT", frame.MinimumLevelFs, "RIGHT", 2, 0)
  frame.MinimumLevelEb:SetFontObject(GameTooltipTextSmall)
  frame.MinimumLevelEb:SetBackdrop({
    bgFile = "",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = "true",
    tileSize = 32,
    edgeSize = 10,
    insets = {left = 3, right = 3, top = 3, bottom = 3}
  })
  frame.MinimumLevelEb:SetAutoFocus(false)
  frame.MinimumLevelEb:SetMultiLine(false)
  frame.MinimumLevelEb:SetNumeric(true)
  frame.MinimumLevelEb:SetScript("OnEscapePressed", function() frame.MinimumLevelEb:ClearFocus() end)
  frame.MinimumLevelEb:SetScript("OnTextChanged", function(arg1, arg2)
    if (not arg2) then
      return
    end

    frame.MinimumLevelEb.DebounceCount = frame.MinimumLevelEb.DebounceCount + 1
    C_Timer.After(2, function()
      frame.MinimumLevelEb.DebounceCount = frame.MinimumLevelEb.DebounceCount - 1

      if (frame.MinimumLevelEb.DebounceCount == 0) then
        frame.MinimumLevelEb:ClearFocus()

        if (frame.MinimumLevelEb:GetNumber() < 1) then
          frame.MinimumLevelEb:SetNumber(1)
        elseif (frame.MinimumLevelEb:GetNumber() > frame.MaximumLevelEb:GetNumber()) then
          frame.MinimumLevelEb:SetNumber(frame.MaximumLevelEb:GetNumber())
        end
    
        frame:Update()
      end
    end)
  end)
  frame.MinimumLevelEb:SetNumber(1)
  frame.MinimumLevelEb.DebounceCount = 0

  frame.MaximumLevelFs = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.MaximumLevelFs:SetPoint("LEFT", frame.MinimumLevelEb, "RIGHT", 15, 0)
  frame.MaximumLevelFs:SetText("Maximum Level:")
  frame.MaximumLevelEb = CreateFrame("EditBox", nil, frame, BackdropTemplateMixin and "BackdropTemplate");
  frame.MaximumLevelEb:SetSize(20, 20)
  frame.MaximumLevelEb:SetPoint("LEFT", frame.MaximumLevelFs, "RIGHT", 2, 0)
  frame.MaximumLevelEb:SetFontObject(GameTooltipTextSmall)
  frame.MaximumLevelEb:SetBackdrop({
    bgFile = "",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = "true",
    tileSize = 32,
    edgeSize = 10,
    insets = {left = 3, right = 3, top = 3, bottom = 3}
  })
  frame.MaximumLevelEb:SetAutoFocus(false)
  frame.MaximumLevelEb:SetMultiLine(false)
  frame.MaximumLevelEb:SetNumeric(true)
  frame.MaximumLevelEb:SetScript("OnEscapePressed", function() frame.MaximumLevelEb:ClearFocus() end)
  frame.MaximumLevelEb:SetScript("OnTextChanged", function(arg1, arg2)
    if (not arg2) then
      return
    end

    frame.MaximumLevelEb.DebounceCount = frame.MaximumLevelEb.DebounceCount + 1
    C_Timer.After(2, function()
      frame.MaximumLevelEb.DebounceCount = frame.MaximumLevelEb.DebounceCount - 1

      if (frame.MaximumLevelEb.DebounceCount == 0) then
        frame.MaximumLevelEb:ClearFocus()
        
        if (frame.MaximumLevelEb:GetNumber() > Controller:GetCurrentLevelNum()) then
          frame.MaximumLevelEb:SetNumber(Controller:GetCurrentLevelNum())
        elseif (frame.MaximumLevelEb:GetNumber() < frame.MinimumLevelEb:GetNumber()) then
          frame.MaximumLevelEb:SetNumber(frame.MinimumLevelEb:GetNumber())
        end
    
        frame:Update()
      end
    end)
  end)
  frame.MaximumLevelEb:SetNumber(Controller:GetCurrentLevelNum())
  frame.MaximumLevelEb.DebounceCount = 0

  frame.SortColumnNameFs = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.SortColumnNameFs:SetPoint("TOPLEFT", frame, 10, -35)

  -- Table Headers
  frame.TableHeaders = {}

  self.OrderColumnIndex = 1
  self.OrderDirection = "ASC"
  
  frame.ScrollFrame.Content.FontStringsPool = {
    Allocated = {},
    UnAllocated = {},
  }

  frame:Hide()
  return frame
end

--
--
-- Verification Window Initialization
--
--

function AutoBiographer_VerificationWindow:Initialize()
  local frame = self
  AutioBiographer_WindowHelper:InitialzationHelper(frame, 750, 585, 150, "Verification", -25)

  local topPoint = -55

  frame.ScrollFrame.Content.PercentageTimeTrackedFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.PercentageTimeTrackedFs:SetPoint("TOPLEFT", 10, topPoint)
  topPoint = topPoint - 15

  frame.ScrollFrame.Content.TaggedKillsFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.TaggedKillsFs:SetPoint("TOPLEFT", 10, topPoint)
  topPoint = topPoint - 15

  if (HelperFunctions.GetGameVersion() == 1) then
    frame.ScrollFrame.Content.ExpectedlevelFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.ScrollFrame.Content.ExpectedlevelFs:SetPoint("TOPLEFT", 10, topPoint)
    topPoint = topPoint - 15
  end

  frame:Hide()
  return frame
end

--
--
-- Custom Event Details Window Update
--
--

function AutoBiographer_CustomEventDetailsWindow:Update()
  self.ScrollFrame.Content.ContentEditBoxScrollFrame.EditBox:SetText("")
end

--
--
-- Debug Window Update
--
--

function AutoBiographer_DebugWindow:Update()
  local previousScrollbarMaxValue = (self.ScrollFrame.Content.ChildrenCount * 15) - self.ScrollFrame:GetHeight();
  local previousScrollbarValue = self.ScrollFrame.Scrollbar:GetValue()
  local previousScrollbarValueWasAtMax = previousScrollbarValue >= previousScrollbarMaxValue

  local debugLogs = Controller:GetLogs()
  for i = self.ScrollFrame.Content.ChildrenCount + 1, #debugLogs, 1 do
    local font = "GameFontWhite"
    if (debugLogs[i].Level == AutoBiographerEnum.LogLevel.Verbose) then font = "GameFontDisable"
    elseif (debugLogs[i].Level == AutoBiographerEnum.LogLevel.Debug) then font = "GameFontDisable"
    elseif (debugLogs[i].Level == AutoBiographerEnum.LogLevel.Information) then font = "GameFontWhite"
    elseif (debugLogs[i].Level == AutoBiographerEnum.LogLevel.Warning) then font = "GameFontNormal"
    elseif (debugLogs[i].Level == AutoBiographerEnum.LogLevel.Error) then font = "GameFontRed"
    elseif (debugLogs[i].Level == AutoBiographerEnum.LogLevel.Fatal) then font = "GameFontRed"
    end
    
    local text = self.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", font)
    text:SetPoint("TOPLEFT", 5, -15 * i) 
    text:SetText(debugLogs[i].Text)
    self.ScrollFrame.Content.ChildrenCount = self.ScrollFrame.Content.ChildrenCount + 1
  end
  
  local scrollbarMaxValue = (self.ScrollFrame.Content.ChildrenCount * 15) - self.ScrollFrame:GetHeight();
  if (scrollbarMaxValue <= 0) then scrollbarMaxValue = 1 end
  self.ScrollFrame.Scrollbar:SetMinMaxValues(1, scrollbarMaxValue)

  if (previousScrollbarValueWasAtMax) then
    self.ScrollFrame.Scrollbar:SetValue(scrollbarMaxValue)
  end
end

--
--
-- Event Window Update
--
--

function AutoBiographer_EventWindow:Update()
  -- Release previous font strings.
  for i = 1, #self.ScrollFrame.Content.FontStringsPool.Allocated, 1 do
    local fs = self.ScrollFrame.Content.FontStringsPool.Allocated[i]
    fs:Hide()
    fs:SetText("")
    table.insert(self.ScrollFrame.Content.FontStringsPool.UnAllocated, fs)
  end
  self.ScrollFrame.Content.FontStringsPool.Allocated = {}

  local events = Controller:GetEvents()
  for i = 1, #events, 1 do
    if (AutoBiographer_Settings.EventDisplayFilters[events[i].SubType]) then
      local fs = table.remove(self.ScrollFrame.Content.FontStringsPool.UnAllocated)
      if (not fs) then
        fs = self.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      end
      
      fs:SetPoint("TOPLEFT", self.ScrollFrame.Content, 5, -15 * #self.ScrollFrame.Content.FontStringsPool.Allocated)
      fs:SetText(HelperFunctions.ShortenString(Controller:GetEventString(events[i]), 85))
      fs:Show()
      table.insert(self.ScrollFrame.Content.FontStringsPool.Allocated, fs)
      --print("Showing: " .. Controller:GetEventString(events[i]))
    end
  end
  
  local scrollbarMaxValue = (#self.ScrollFrame.Content.FontStringsPool.Allocated * 15) - self.ScrollFrame:GetHeight();
  if (scrollbarMaxValue <= 0) then scrollbarMaxValue = 1 end
  self.ScrollFrame.Scrollbar:SetMinMaxValues(1, scrollbarMaxValue)
  self.ScrollFrame.Scrollbar:SetValue(scrollbarMaxValue)
end

--
--
-- Main Window Update
--
--

function AutoBiographer_MainWindow:Update()
  -- Dropdown
  if (not self.ScrollFrame.Content.Dropdown or self.ScrollFrame.Content.DropdownCreatedAtLevel ~= Controller:GetCurrentLevelNum()) then
    if (self.ScrollFrame.Content.Dropdown) then
      self.ScrollFrame.Content.Dropdown:Hide()
    end

    self.ScrollFrame.Content.Dropdown = CreateFrame("Frame", nil, self.ScrollFrame.Content, "UIDropDownMenuTemplate")
    self.ScrollFrame.Content.Dropdown:SetSize(100, 25)
    self.ScrollFrame.Content.Dropdown:SetPoint("LEFT", self.ScrollFrame.Content, "TOP", -self.ScrollFrame.Content.Dropdown:GetWidth(), -65)
    
    self.ScrollFrame.Content.DropdownCreatedAtLevel = Controller:GetCurrentLevelNum()

    if (not self.DropdownText) then self.DropdownText = "Total" end
    if (not self.DisplayMaxLevel) then self.DisplayMaxLevel = 9999 end
    if (not self.DisplayMinLevel) then self.DisplayMinLevel = 1 end
    
    local dropdownOnClick = function(self, arg1, arg2, checked)
      AutoBiographer_MainWindow.DropdownText = self.value
      
      AutoBiographer_MainWindow.DisplayMinLevel = arg1
      AutoBiographer_MainWindow.DisplayMaxLevel = arg2
      
      AutoBiographer_MainWindow:Update()
    end
    
    UIDropDownMenu_Initialize(self.ScrollFrame.Content.Dropdown, function(self, level, menuList)
      local info = UIDropDownMenu_CreateInfo()
      info.func = dropdownOnClick
    
      if (not level or level == 1) then
        info.text, info.arg1, info.arg2 = "Total", 1, 9999
        UIDropDownMenu_AddButton(info)
        
        for i = 0, 7 do
          local includeThisRange = false
          for j = 1, 10 do
            if (Controller.CharacterData.Levels[(i * 10) + j]) then includeThisRange = true end
          end
          
          if (includeThisRange) then
            info.arg1 = (i * 10) + 1
            info.arg2 = (i * 10) + 10
            info.text = "Levels " .. info.arg1 .. " - " .. info.arg2
            info.menuList = i
            info.hasArrow = true
            UIDropDownMenu_AddButton(info)
          end
        end
      else
        for i = 1, 10 do
          info.arg1 = (menuList * 10) + i
          info.arg2 = info.arg1
          info.text = "Level " .. info.arg1
          
          if (Controller.CharacterData.Levels[info.arg1]) then UIDropDownMenu_AddButton(info, level) end
        end
      end
    end)
  end

  UIDropDownMenu_SetText(self.ScrollFrame.Content.Dropdown, self.DropdownText)
  
  -- Header Stuff
  if (self.DisplayMinLevel == self.DisplayMaxLevel and Controller.CharacterData.Levels[self.DisplayMinLevel] and Controller.CharacterData.Levels[self.DisplayMinLevel].TimePlayedThisLevel) then
    self.ScrollFrame.Content.TimePlayedThisLevelFS:SetText("Time played this level: " .. HF.SecondsToTimeString(Controller.CharacterData.Levels[self.DisplayMinLevel].TimePlayedThisLevel))
  else
    self.ScrollFrame.Content.TimePlayedThisLevelFS:SetText("")
  end
  
  -- Arena Stats
  if (self.ScrollFrame.Content.ArenaHeaderFs) then
    local arenaRegistered2v2Joined, arenaRegistered2v2Losses, arenaRegistered2v2Wins = Controller:GetArenaStatsByRegistrationTypeAndTeamSize(true, 2, self.DisplayMinLevel, self.DisplayMaxLevel)
    local arenaUnregistered2v2Joined, arenaUnregistered2v2Losses, arenaUnregistered2v2Wins = Controller:GetArenaStatsByRegistrationTypeAndTeamSize(false, 2, self.DisplayMinLevel, self.DisplayMaxLevel)
    local arenaRegistered2v2StatsText = "2v2 Rated - Wins: " .. HF.CommaValue(arenaRegistered2v2Wins) .. ". Losses: " .. HF.CommaValue(arenaRegistered2v2Losses) .. ". Incomplete: " .. HF.CommaValue(arenaRegistered2v2Joined - arenaRegistered2v2Losses - arenaRegistered2v2Wins) .. "."
    local arenaUnregistered2v2StatsText = "2v2 Skirmish - Wins: " .. HF.CommaValue(arenaUnregistered2v2Wins) .. ". Losses: " .. HF.CommaValue(arenaUnregistered2v2Losses) .. ". Incomplete: " .. HF.CommaValue(arenaUnregistered2v2Joined - arenaUnregistered2v2Losses - arenaUnregistered2v2Wins) .. "."
    self.ScrollFrame.Content.Arena2v2StatsFs:SetText(arenaRegistered2v2StatsText .. " " .. arenaUnregistered2v2StatsText)

    local arenaRegistered3v3Joined, arenaRegistered3v3Losses, arenaRegistered3v3Wins = Controller:GetArenaStatsByRegistrationTypeAndTeamSize(true, 3, self.DisplayMinLevel, self.DisplayMaxLevel)
    local arenaUnregistered3v3Joined, arenaUnregistered3v3Losses, arenaUnregistered3v3Wins = Controller:GetArenaStatsByRegistrationTypeAndTeamSize(false, 3, self.DisplayMinLevel, self.DisplayMaxLevel)
    local arenaRegistered3v3StatsText = "3v3 Rated - Wins: " .. HF.CommaValue(arenaRegistered3v3Wins) .. ". Losses: " .. HF.CommaValue(arenaRegistered3v3Losses) .. ". Incomplete: " .. HF.CommaValue(arenaRegistered3v3Joined - arenaRegistered3v3Losses - arenaRegistered3v3Wins) .. "."
    local arenaUnregistered3v3StatsText = "3v3 Skirmish - Wins: " .. HF.CommaValue(arenaUnregistered3v3Wins) .. ". Losses: " .. HF.CommaValue(arenaUnregistered3v3Losses) .. ". Incomplete: " .. HF.CommaValue(arenaUnregistered3v3Joined - arenaUnregistered3v3Losses - arenaUnregistered3v3Wins) .. "."
    self.ScrollFrame.Content.Arena3v3StatsFs:SetText(arenaRegistered3v3StatsText .. " " .. arenaUnregistered3v3StatsText)

    local arenaRegistered5v5Joined, arenaRegistered5v5Losses, arenaRegistered5v5Wins = Controller:GetArenaStatsByRegistrationTypeAndTeamSize(true, 5, self.DisplayMinLevel, self.DisplayMaxLevel)
    local arenaUnregistered5v5Joined, arenaUnregistered5v5Losses, arenaUnregistered5v5Wins = Controller:GetArenaStatsByRegistrationTypeAndTeamSize(false, 5, self.DisplayMinLevel, self.DisplayMaxLevel)
    local arenaRegistered5v5StatsText = "5v5 Rated - Wins: " .. HF.CommaValue(arenaRegistered5v5Wins) .. ". Losses: " .. HF.CommaValue(arenaRegistered5v5Losses) .. ". Incomplete: " .. HF.CommaValue(arenaRegistered5v5Joined - arenaRegistered5v5Losses - arenaRegistered5v5Wins) .. "."
    local arenaUnregistered5v5StatsText = "5v5 Skirmish - Wins: " .. HF.CommaValue(arenaUnregistered5v5Wins) .. ". Losses: " .. HF.CommaValue(arenaUnregistered5v5Losses) .. ". Incomplete: " .. HF.CommaValue(arenaUnregistered5v5Joined - arenaUnregistered5v5Losses - arenaUnregistered5v5Wins) .. "."
    self.ScrollFrame.Content.Arena5v5StatsFs:SetText(arenaRegistered5v5StatsText .. " " .. arenaUnregistered5v5StatsText)
  end

  -- Battleground Stats
  if (self.ScrollFrame.Content.BattlegroundHeaderFs) then
    local avJoined, avLosses, avWins = Controller:GetBattlegroundStatsByBattlegroundId(1, self.DisplayMinLevel, self.DisplayMaxLevel)
    local avStatsText = "Alterac Valley - Wins: " .. HF.CommaValue(avWins) .. ". Losses: " .. HF.CommaValue(avLosses) .. ". Incomplete: " .. HF.CommaValue(avJoined - avLosses - avWins) .. "."
    self.ScrollFrame.Content.AvStatsFs:SetText(avStatsText)

    local abJoined, abLosses, abWins = Controller:GetBattlegroundStatsByBattlegroundId(3, self.DisplayMinLevel, self.DisplayMaxLevel)
    local abStatsText = "Arathi Basin - Wins: " .. HF.CommaValue(abWins) .. ". Losses: " .. HF.CommaValue(abLosses) .. ". Incomplete: " .. HF.CommaValue(abJoined - abLosses - abWins) .. "."
    self.ScrollFrame.Content.AbStatsFs:SetText(abStatsText)

    if (self.ScrollFrame.Content.EotsStatsFs) then
      local eotsJoined, eotsLosses, eotsWins = Controller:GetBattlegroundStatsByBattlegroundId(4, self.DisplayMinLevel, self.DisplayMaxLevel)
      local eotsStatsText = "Eye of the Storm - Wins: " .. HF.CommaValue(eotsWins) .. ". Losses: " .. HF.CommaValue(eotsLosses) .. ". Incomplete: " .. HF.CommaValue(eotsJoined - eotsLosses - eotsWins) .. "."
      self.ScrollFrame.Content.EotsStatsFs:SetText(eotsStatsText)
    end

    local wsgJoined, wsgLosses, wsgWins = Controller:GetBattlegroundStatsByBattlegroundId(2, self.DisplayMinLevel, self.DisplayMaxLevel)
    local wsgStatsText = "Warsong Gulch - Wins: " .. HF.CommaValue(wsgWins) .. ". Losses: " .. HF.CommaValue(wsgLosses) .. ". Incomplete: " .. HF.CommaValue(wsgJoined - wsgLosses - wsgWins) .. "."
    self.ScrollFrame.Content.WsgStatsFs:SetText(wsgStatsText)
  end

  -- Damage Stats
  local damageDealtAmount, damageDealtOver = Controller:GetDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.DamageDealt, self.DisplayMinLevel, self.DisplayMaxLevel)
  local petDamageDealtAmount, petDamageDealtOver = Controller:GetDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.PetDamageDealt, self.DisplayMinLevel, self.DisplayMaxLevel)
  local damageDealtText = "Damage Dealt: " .. HF.CommaValue(damageDealtAmount) .. " (" .. HF.AbbreviatedValue(damageDealtAmount - damageDealtOver) .. " effective, " .. HF.AbbreviatedValue(damageDealtOver) .. " over)."
  if (petDamageDealtAmount > 0) then damageDealtText = damageDealtText .. " Pet Damage Dealt: " .. HF.AbbreviatedValue(petDamageDealtAmount) .. " (" .. HF.AbbreviatedValue(petDamageDealtAmount - petDamageDealtOver) .. " effective, " .. HF.AbbreviatedValue(petDamageDealtOver) .. " over)." end
  self.ScrollFrame.Content.DamageDealtFs:SetText(damageDealtText)
  
  local damageTakenAmount, damageTakenOver = Controller:GetDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.DamageTaken, self.DisplayMinLevel, self.DisplayMaxLevel)
  local petDamageTakenAmount, petDamageTakenOver = Controller:GetDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.PetDamageTaken, self.DisplayMinLevel, self.DisplayMaxLevel)
  local damageTakenText = "Damage Taken: " .. HF.CommaValue(damageTakenAmount) .. " (" .. HF.AbbreviatedValue(damageTakenAmount - damageTakenOver) .. " effective, " .. HF.AbbreviatedValue(damageTakenOver) .. " over)."
  if (petDamageTakenAmount > 0) then damageTakenText = damageTakenText .. " Pet Damage Taken: " .. HF.AbbreviatedValue(petDamageTakenAmount) .. " (" .. HF.AbbreviatedValue(petDamageTakenAmount - petDamageTakenOver) .. " effective, " .. HF.AbbreviatedValue(petDamageTakenOver) .. " over)." end
  self.ScrollFrame.Content.DamageTakenFs:SetText(damageTakenText)
  
  local healingOtherAmount, healingOtherOver = Controller:GetDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.HealingDealtToOthers, self.DisplayMinLevel, self.DisplayMaxLevel)
  self.ScrollFrame.Content.HealingOtherFs:SetText("Healing Dealt to Others: " .. HF.CommaValue(healingOtherAmount) .. " (" .. HF.AbbreviatedValue(healingOtherAmount - healingOtherOver) .. " effective, " .. HF.AbbreviatedValue(healingOtherOver) .. " over).")
  
  local healingSelfAmount, healingSelfOver = Controller:GetDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.HealingDealtToSelf, self.DisplayMinLevel, self.DisplayMaxLevel)
  self.ScrollFrame.Content.HealingSelfFs:SetText("Healing Dealt to Self: " .. HF.CommaValue(healingSelfAmount) .. " (" .. HF.AbbreviatedValue(healingSelfAmount - healingSelfOver) .. " effective, " .. HF.AbbreviatedValue(healingSelfOver) .. " over).")
  
  local healingTakenAmount, healingTakenOver = Controller:GetDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.HealingTaken, self.DisplayMinLevel, self.DisplayMaxLevel)
  self.ScrollFrame.Content.HealingTakenFs:SetText("Healing Taken: " .. HF.CommaValue(healingTakenAmount) .. " (" .. HF.AbbreviatedValue(healingTakenAmount - healingTakenOver) .. " effective, " .. HF.AbbreviatedValue(healingTakenOver) .. " over).")
  
  -- Death Stats
  local deathsToCreatures = Controller:GetDeathsByDeathTrackingType(AutoBiographerEnum.DeathTrackingType.DeathToCreature, self.DisplayMinLevel, self.DisplayMaxLevel)
  local deathsToEnvironment = Controller:GetDeathsByDeathTrackingType(AutoBiographerEnum.DeathTrackingType.DeathToEnvironment, self.DisplayMinLevel, self.DisplayMaxLevel)
  local deathsToGameObjects = Controller:GetDeathsByDeathTrackingType(AutoBiographerEnum.DeathTrackingType.DeathToGameObject, self.DisplayMinLevel, self.DisplayMaxLevel)
  local deathsToPets = Controller:GetDeathsByDeathTrackingType(AutoBiographerEnum.DeathTrackingType.DeathToPet, self.DisplayMinLevel, self.DisplayMaxLevel)
  local deathsToPlayers = Controller:GetDeathsByDeathTrackingType(AutoBiographerEnum.DeathTrackingType.DeathToPlayer, self.DisplayMinLevel, self.DisplayMaxLevel)
  local deathsToUnknown = Controller:GetDeathsByDeathTrackingType(AutoBiographerEnum.DeathTrackingType.DeathToUnknown, self.DisplayMinLevel, self.DisplayMaxLevel)
  local totalDeaths = deathsToCreatures + deathsToEnvironment + deathsToGameObjects + deathsToPets + deathsToPlayers + deathsToUnknown
  self.ScrollFrame.Content.TotalDeathsFs:SetText("Total Deaths: " .. HF.CommaValue(totalDeaths) .. ".")
  self.ScrollFrame.Content.DeathsToCreaturesFs:SetText("Deaths to Creatures: " .. HF.CommaValue(deathsToCreatures) .. ".")
  self.ScrollFrame.Content.DeathsToEnvironmentFs:SetText("Deaths to Environment: " .. HF.CommaValue(deathsToEnvironment) .. ".")
  self.ScrollFrame.Content.DeathsToGameObjectsFs:SetText("Deaths to Game Objects: " .. HF.CommaValue(deathsToGameObjects) .. ".")
  self.ScrollFrame.Content.DeathsToPetsFs:SetText("Deaths to Pets: " .. HF.CommaValue(deathsToPets) .. ".")
  self.ScrollFrame.Content.DeathsToPlayersFs:SetText("Deaths to Players: " .. HF.CommaValue(deathsToPlayers) .. ".")
  self.ScrollFrame.Content.DeathsToUnknownFs:SetText("Deaths to Unknown: " .. HF.CommaValue(deathsToUnknown) .. ".")

  -- Experience Stats
  local experienceFromKills = Controller:GetExperienceByExperienceTrackingType(AutoBiographerEnum.ExperienceTrackingType.Kill, self.DisplayMinLevel, self.DisplayMaxLevel)
  local experienceFromRestedBonus = Controller:GetExperienceByExperienceTrackingType(AutoBiographerEnum.ExperienceTrackingType.RestedBonus, self.DisplayMinLevel, self.DisplayMaxLevel)
  local experienceFromGroupBonus = Controller:GetExperienceByExperienceTrackingType(AutoBiographerEnum.ExperienceTrackingType.GroupBonus, self.DisplayMinLevel, self.DisplayMaxLevel)
  local experienceLostToRaidPenalty = Controller:GetExperienceByExperienceTrackingType(AutoBiographerEnum.ExperienceTrackingType.RaidPenalty, self.DisplayMinLevel, self.DisplayMaxLevel)
  local experienceFromKillsBase = experienceFromKills - experienceFromRestedBonus - experienceFromGroupBonus + experienceLostToRaidPenalty

  self.ScrollFrame.Content.ExperienceFromKillsFs:SetText("Experience From Kills (Total): " .. HF.CommaValue(experienceFromKills) .. ".")
  self.ScrollFrame.Content.ExperienceFromKillsBaseFs:SetText("Experience From Kills (Base): " .. HF.CommaValue(experienceFromKillsBase) .. ".")
  self.ScrollFrame.Content.ExperienceFromRestedBonusFs:SetText("Experience From Rested Bonus: " .. HF.CommaValue(experienceFromRestedBonus) .. ".")
  self.ScrollFrame.Content.ExperienceFromGroupBonusFs:SetText("Experience From Group Bonus: " .. HF.CommaValue(experienceFromGroupBonus) .. ".")
  self.ScrollFrame.Content.ExperienceLostToRaidPenaltyFs:SetText("Experience Lost To Raid Penalty: " .. HF.CommaValue(experienceLostToRaidPenalty) .. ".")
  
  local experienceFromQuests = Controller:GetExperienceByExperienceTrackingType(AutoBiographerEnum.ExperienceTrackingType.Quest, self.DisplayMinLevel, self.DisplayMaxLevel)
  self.ScrollFrame.Content.ExperienceFromQuestsFs:SetText("Experience From Quests: " .. HF.CommaValue(experienceFromQuests) .. ".")
  
  local experienceFromDiscovery = Controller:GetExperienceByExperienceTrackingType(AutoBiographerEnum.ExperienceTrackingType.Discovery, self.DisplayMinLevel, self.DisplayMaxLevel)
  self.ScrollFrame.Content.ExperienceFromDiscoveryFs:SetText("Experience From Discovery: " .. HF.CommaValue(experienceFromDiscovery) .. ".")
  
  -- Item Stats
  local itemsAuctionHouse = Controller:GetItemCountForAcquisitionMethod(AutoBiographerEnum.ItemAcquisitionMethod.AuctionHouse, self.DisplayMinLevel, self.DisplayMaxLevel)
  self.ScrollFrame.Content.ItemsAuctionHouseFs:SetText("Items Acquired From Auction House: " .. HF.CommaValue(itemsAuctionHouse) .. ".")

  local itemsCreated = Controller:GetItemCountForAcquisitionMethod(AutoBiographerEnum.ItemAcquisitionMethod.Create, self.DisplayMinLevel, self.DisplayMaxLevel)
  self.ScrollFrame.Content.ItemsCreatedFs:SetText("Items Created: " .. HF.CommaValue(itemsCreated) .. ".")
  
  local itemsLooted = Controller:GetItemCountForAcquisitionMethod(AutoBiographerEnum.ItemAcquisitionMethod.Loot, self.DisplayMinLevel, self.DisplayMaxLevel)
  self.ScrollFrame.Content.ItemsLootedFs:SetText("Items Looted: " .. HF.CommaValue(itemsLooted) .. ".")

  local itemsMail = Controller:GetItemCountForAcquisitionMethod(AutoBiographerEnum.ItemAcquisitionMethod.Mail, self.DisplayMinLevel, self.DisplayMaxLevel)
  self.ScrollFrame.Content.ItemsMailFs:SetText("Items Acquired From Mail (Direct): " .. HF.CommaValue(itemsMail) .. ".")

  local itemsMailCod = Controller:GetItemCountForAcquisitionMethod(AutoBiographerEnum.ItemAcquisitionMethod.MailCod, self.DisplayMinLevel, self.DisplayMaxLevel)
  self.ScrollFrame.Content.ItemsMailCodFs:SetText("Items Acquired From Mail (COD): " .. HF.CommaValue(itemsMailCod) .. ".")
  
  local itemsTrade = Controller:GetItemCountForAcquisitionMethod(AutoBiographerEnum.ItemAcquisitionMethod.Trade, self.DisplayMinLevel, self.DisplayMaxLevel)
  self.ScrollFrame.Content.ItemsTradeFs:SetText("Items Acquired By Trade: " .. HF.CommaValue(itemsTrade) .. ".")

  local itemsMerchant = Controller:GetItemCountForAcquisitionMethod(AutoBiographerEnum.ItemAcquisitionMethod.Merchant, self.DisplayMinLevel, self.DisplayMaxLevel)
  self.ScrollFrame.Content.ItemsVendorFs:SetText("Items Acquired From Vendors: " .. HF.CommaValue(itemsMerchant) .. ".")

  local itemsOther = Controller:GetItemCountForAcquisitionMethod(AutoBiographerEnum.ItemAcquisitionMethod.Other, self.DisplayMinLevel, self.DisplayMaxLevel)
  self.ScrollFrame.Content.ItemsOtherFs:SetText("Items Acquired By Other Means: " .. HF.CommaValue(itemsOther) .. ".")
  
  -- Kill Stats
  local totalsKillStatistics = Controller:GetAggregatedKillStatisticsTotals(self.DisplayMinLevel, self.DisplayMaxLevel)

  local totalTaggedKills = KillStatistics.GetSum(totalsKillStatistics, { AutoBiographerEnum.KillTrackingType.TaggedAssist, AutoBiographerEnum.KillTrackingType.TaggedGroupAssistOrKillingBlow, AutoBiographerEnum.KillTrackingType.TaggedKillingBlow })
  self.ScrollFrame.Content.TotalTaggedKillsFs:SetText("Total Tagged Kills: " .. HF.CommaValue(totalTaggedKills) .. ".")
  
  local taggedKillingBlows = KillStatistics.GetSum(totalsKillStatistics, { AutoBiographerEnum.KillTrackingType.TaggedKillingBlow })
  self.ScrollFrame.Content.TaggedKillingBlowsFs:SetText("Killing Blows: " .. HF.CommaValue(taggedKillingBlows) .. ".")
  
  local taggedAssists = KillStatistics.GetSum(totalsKillStatistics, { AutoBiographerEnum.KillTrackingType.TaggedAssist })
  self.ScrollFrame.Content.TaggedKillAssistsFs:SetText("Kill Assists: " .. HF.CommaValue(taggedAssists) .. ".")

  local taggedGroupKills = KillStatistics.GetSum(totalsKillStatistics, { AutoBiographerEnum.KillTrackingType.TaggedGroupAssistOrKillingBlow })
  self.ScrollFrame.Content.TaggedGroupKillsFs:SetText("Group Kills without Player Damage: " .. HF.CommaValue(taggedGroupKills) .. ".")

  -- Miscellaneous Stats
  local duelsWon = Controller:GetOtherPlayerStatByOtherPlayerTrackingType(AutoBiographerEnum.OtherPlayerTrackingType.DuelsLostToPlayer, self.DisplayMinLevel, self.DisplayMaxLevel)
  local duelsLost = Controller:GetOtherPlayerStatByOtherPlayerTrackingType(AutoBiographerEnum.OtherPlayerTrackingType.DuelsWonAgainstPlayer, self.DisplayMinLevel, self.DisplayMaxLevel)
  self.ScrollFrame.Content.DuelsFs:SetText("Duels Won: " .. HF.CommaValue(duelsWon) .. ". Duels Lost: " .. HF.CommaValue(duelsLost) .. ".")
  
  local jumps = Controller:GetMiscellaneousStatByMiscellaneousTrackingType(AutoBiographerEnum.MiscellaneousTrackingType.Jumps, self.DisplayMinLevel, self.DisplayMaxLevel)
  self.ScrollFrame.Content.JumpsFs:SetText("Jumps: " .. jumps)

  local aggregatedQuestStatisticsDictionary = Controller:GetAggregatedQuestStatisticsDictionary(self.DisplayMinLevel, self.DisplayMaxLevel)
  local totalsQuestStatistics = Controller:GetAggregatedQuestStatisticsTotals(self.DisplayMinLevel, self.DisplayMaxLevel, aggregatedQuestStatisticsDictionary)
  local uniqueQuestsCompleted = HelperFunctions.GetTableLength(aggregatedQuestStatisticsDictionary)
  local duplicateQuestsCompleted = QuestStatistics.GetSum(totalsQuestStatistics, { AutoBiographerEnum.QuestTrackingType.Completed }) - uniqueQuestsCompleted
  self.ScrollFrame.Content.QuestsCompletedFs:SetText("Unique Quests Completed: " .. HF.CommaValue(uniqueQuestsCompleted) .. ". Duplicate Quests Completed: " .. HF.CommaValue(duplicateQuestsCompleted) .. ".")

  local spellsStartedCasting = Controller:GetSpellCountBySpellTrackingType(AutoBiographerEnum.SpellTrackingType.StartedCasting, self.DisplayMinLevel, self.DisplayMaxLevel)
  local spellsSuccessfullyCast = Controller:GetSpellCountBySpellTrackingType(AutoBiographerEnum.SpellTrackingType.SuccessfullyCast, self.DisplayMinLevel, self.DisplayMaxLevel)
  self.ScrollFrame.Content.SpellsFs:SetText("Spells Started Casting: " .. HF.CommaValue(spellsStartedCasting) .. ". Spells Successfully Cast: " .. HF.CommaValue(spellsSuccessfullyCast) .. ".")

  -- Money Stats
  local moneyGainedFromAuctionHouseSales = Controller:GetMoneyForAcquisitionMethod(AutoBiographerEnum.MoneyAcquisitionMethod.AuctionHouseSale, self.DisplayMinLevel, self.DisplayMaxLevel)
  self.ScrollFrame.Content.MoneyGainedFromAuctionHouseSalesFs:SetText("Money Gained from Auction House: " .. GetCoinText(moneyGainedFromAuctionHouseSales) .. ".")

  local moneyGainedFromLoot = Controller:GetMoneyForAcquisitionMethod(AutoBiographerEnum.MoneyAcquisitionMethod.Loot, self.DisplayMinLevel, self.DisplayMaxLevel)
  self.ScrollFrame.Content.MoneyGainedFromLootFs:SetText("Money Looted: " .. GetCoinText(moneyGainedFromLoot) .. ".")
  
  local moneyGainedFromMail = Controller:GetMoneyForAcquisitionMethod(AutoBiographerEnum.MoneyAcquisitionMethod.Mail, self.DisplayMinLevel, self.DisplayMaxLevel)
  self.ScrollFrame.Content.MoneyGainedFromMailFs:SetText("Money Gained From Mail (Direct): " .. GetCoinText(moneyGainedFromMail) .. ".")

  local moneyGainedFromMailCod = Controller:GetMoneyForAcquisitionMethod(AutoBiographerEnum.MoneyAcquisitionMethod.MailCod, self.DisplayMinLevel, self.DisplayMaxLevel)
  self.ScrollFrame.Content.MoneyGainedFromMailCodFs:SetText("Money Gained From Mail (COD): " .. GetCoinText(moneyGainedFromMailCod) .. ".")

  local moneyGainedFromMerchants = Controller:GetMoneyForAcquisitionMethod(AutoBiographerEnum.MoneyAcquisitionMethod.Merchant, self.DisplayMinLevel, self.DisplayMaxLevel)
  self.ScrollFrame.Content.MoneyGainedFromMerchantsFs:SetText("Money Gained From Merchants: " .. GetCoinText(moneyGainedFromMerchants) .. ".")
  
  local moneyGainedFromQuests = Controller:GetMoneyForAcquisitionMethod(AutoBiographerEnum.MoneyAcquisitionMethod.Quest, self.DisplayMinLevel, self.DisplayMaxLevel)
  self.ScrollFrame.Content.MoneyGainedFromQuestsFs:SetText("Money Gained From Quests: " .. GetCoinText(moneyGainedFromQuests) .. ".")

  local moneyGainedFromTrade = Controller:GetMoneyForAcquisitionMethod(AutoBiographerEnum.MoneyAcquisitionMethod.Trade, self.DisplayMinLevel, self.DisplayMaxLevel)
  self.ScrollFrame.Content.MoneyGainedFromTradeFs:SetText("Money Gained From Trade: " .. GetCoinText(moneyGainedFromTrade) .. ".")
  
  local moneyGainedFromAuctionHouseDepositReturns = Controller:GetMoneyForAcquisitionMethod(AutoBiographerEnum.MoneyAcquisitionMethod.AuctionHouseDepositReturn, self.DisplayMinLevel, self.DisplayMaxLevel)
  local moneyGainedFromAuctionHouseOutbids = Controller:GetMoneyForAcquisitionMethod(AutoBiographerEnum.MoneyAcquisitionMethod.AuctionHouseOutbid, self.DisplayMinLevel, self.DisplayMaxLevel)
  local moneyGainedFromOther = Controller:GetTotalMoneyGained(self.DisplayMinLevel, self.DisplayMaxLevel) - moneyGainedFromAuctionHouseDepositReturns -
    moneyGainedFromAuctionHouseOutbids - moneyGainedFromAuctionHouseSales - moneyGainedFromLoot - moneyGainedFromMail - moneyGainedFromMailCod - moneyGainedFromMerchants -
    moneyGainedFromQuests - moneyGainedFromTrade
  if (moneyGainedFromOther < 0) then moneyGainedFromOther = 0 end -- This should not ever happen.
  self.ScrollFrame.Content.MoneyGainedFromOtherFs:SetText("Money Gained From Other Sources: " .. GetCoinText(moneyGainedFromOther) .. ".")
  
  -- Time Stats
  local timeSpentAfk = Controller:GetTimeForTimeTrackingType(AutoBiographerEnum.TimeTrackingType.Afk, self.DisplayMinLevel, self.DisplayMaxLevel)
  self.ScrollFrame.Content.TimeSpentAfkFs:SetText("Time Spent AFK: " .. HF.SecondsToTimeString(timeSpentAfk) .. ".")
  
  local timeSpentCasting = Controller:GetTimeForTimeTrackingType(AutoBiographerEnum.TimeTrackingType.Casting, self.DisplayMinLevel, self.DisplayMaxLevel)
  self.ScrollFrame.Content.TimeSpentCastingFs:SetText("Time Spent Casting: " .. HF.SecondsToTimeString(timeSpentCasting) .. ".")
  
  local timeSpentDead = Controller:GetTimeForTimeTrackingType(AutoBiographerEnum.TimeTrackingType.DeadOrGhost, self.DisplayMinLevel, self.DisplayMaxLevel)
  self.ScrollFrame.Content.TimeSpentDeadFs:SetText("Time Spent Dead: " .. HF.SecondsToTimeString(timeSpentDead) .. ".")
  
  local timeSpentInCombat = Controller:GetTimeForTimeTrackingType(AutoBiographerEnum.TimeTrackingType.InCombat, self.DisplayMinLevel, self.DisplayMaxLevel)
  self.ScrollFrame.Content.TimeSpentInCombatFs:SetText("Time Spent in Combat: " .. HF.SecondsToTimeString(timeSpentInCombat) .. ".")
  
  local timeSpentInGroup = Controller:GetTimeForTimeTrackingType(AutoBiographerEnum.TimeTrackingType.InParty, self.DisplayMinLevel, self.DisplayMaxLevel)
  self.ScrollFrame.Content.TimeSpentInGroupFs:SetText("Time Spent in Group: " .. HF.SecondsToTimeString(timeSpentInGroup) .. ".")
  
  local timeSpentLoggedIn = Controller:GetTimeForTimeTrackingType(AutoBiographerEnum.TimeTrackingType.LoggedIn, self.DisplayMinLevel, self.DisplayMaxLevel)
  self.ScrollFrame.Content.TimeSpentLoggedInFs:SetText("Time Spent Logged In: " .. HF.SecondsToTimeString(timeSpentLoggedIn) .. ".")
  
  local timeSpentOnTaxi = Controller:GetTimeForTimeTrackingType(AutoBiographerEnum.TimeTrackingType.OnTaxi, self.DisplayMinLevel, self.DisplayMaxLevel)
  self.ScrollFrame.Content.TimeSpentOnTaxiFs:SetText("Time Spent on Flights: " .. HF.SecondsToTimeString(timeSpentOnTaxi) .. ".")
end

--
--
-- Note Details Window Update
--
--

function AutoBiographer_NoteDetailsWindow:Update()
  self.ScrollFrame.Content.ContentEditBoxScrollFrame.EditBox:SetText(self.SelectedNote.Content)
end

--
--
-- Notes Window Update
--
--

function AutoBiographer_NotesWindow:Update()
  local genericNotes = Controller:GetNotes().GenericNotes
  local sortedGenericNotes = {}
  for i = 1, #genericNotes, 1 do
    table.insert(sortedGenericNotes, genericNotes[i])
  end

  table.sort(sortedGenericNotes, function(rowA, rowB)
    return rowA.LastUpdatedTimestamp > rowB.LastUpdatedTimestamp
  end)

  for i = 1, #self.ScrollFrame.Content.ButtonsPool.Allocated, 1 do
    local button = self.ScrollFrame.Content.ButtonsPool.Allocated[i]
    button:Hide()
    table.insert(self.ScrollFrame.Content.ButtonsPool.UnAllocated, fs)
  end

  for i = 1, #self.ScrollFrame.Content.FontStringsPool.Allocated, 1 do
    local fs = self.ScrollFrame.Content.FontStringsPool.Allocated[i]
    fs:Hide()
    fs:SetText("")
    table.insert(self.ScrollFrame.Content.FontStringsPool.UnAllocated, fs)
  end
  self.ScrollFrame.Content.FontStringsPool.Allocated = {}

  for i = 1, #sortedGenericNotes, 1 do
    local font = "GameFontHighlight"

    local createdTimestampFs = table.remove(self.ScrollFrame.Content.FontStringsPool.UnAllocated)
    if (not createdTimestampFs) then
      createdTimestampFs = self.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", font)
    end
    createdTimestampFs:SetPoint("TOPLEFT", 5, -15 * i)
    createdTimestampFs:SetText(HelperFunctions.TimestampToDateString(sortedGenericNotes[i].CreatedTimestamp, true))
    createdTimestampFs:Show()
    table.insert(self.ScrollFrame.Content.FontStringsPool.Allocated, createdTimestampFs)

    local lastUpdatedTimestampFs = table.remove(self.ScrollFrame.Content.FontStringsPool.UnAllocated)
    if (not lastUpdatedTimestampFs) then
      lastUpdatedTimestampFs = self.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", font)
    end
    lastUpdatedTimestampFs:SetPoint("TOPLEFT", 80, -15 * i)
    lastUpdatedTimestampFs:SetText(HelperFunctions.TimestampToDateString(sortedGenericNotes[i].LastUpdatedTimestamp, true))
    lastUpdatedTimestampFs:Show()
    table.insert(self.ScrollFrame.Content.FontStringsPool.Allocated, lastUpdatedTimestampFs)

    local deleteNoteButton = table.remove(self.ScrollFrame.Content.ButtonsPool.UnAllocated)
    if (not deleteNoteButton) then
      deleteNoteButton = CreateFrame("Button", nil, self.ScrollFrame.Content, "UIPanelButtonTemplate")
    end
    deleteNoteButton:SetPoint("TOPLEFT", 155, -15 * i);
    deleteNoteButton:SetSize(50, 15)
    deleteNoteButton:SetText("Delete")
    deleteNoteButton:SetNormalFontObject("GameFontNormal")
    deleteNoteButton:SetHighlightFontObject("GameFontHighlight")
    deleteNoteButton:SetScript("OnClick",
      function(self)
        local noteToDelete = sortedGenericNotes[i]

        AutoBiographer_ConfirmWindow.New("Confirm note deletion:\n'" .. HelperFunctions.ShortenString(noteToDelete.Content, 30) .. "'", 
          function(deleteConfirmed)
            if (deleteConfirmed) then
              local indexToDelete = -1
              for j = 1, #genericNotes, 1 do
                if (genericNotes[j] == noteToDelete) then indexToDelete = j end
              end

              local indexesToDelete = {}
              indexesToDelete[indexToDelete] = true
              HelperFunctions.RemoveElementsFromArrayAtIndexes(genericNotes, indexesToDelete)

              AutoBiographer_NotesWindow:Update()

              if (AutoBiographer_NoteDetailsWindow.SelectedNote == noteToDelete and AutoBiographer_NoteDetailsWindow:IsVisible()) then
                AutoBiographer_NoteDetailsWindow:Toggle()
              end
            end
          end
        )
      end
    )
    deleteNoteButton:Show()
    table.insert(self.ScrollFrame.Content.ButtonsPool.Allocated, deleteNoteButton)

    local noteDetailsButton = table.remove(self.ScrollFrame.Content.ButtonsPool.UnAllocated)
    if (not noteDetailsButton) then
      noteDetailsButton = CreateFrame("Button", nil, self.ScrollFrame.Content, "UIPanelButtonTemplate")
    end
    noteDetailsButton:SetPoint("TOPLEFT", 210, -15 * i);
    noteDetailsButton:SetSize(50, 15)
    noteDetailsButton:SetText("Details")
    noteDetailsButton:SetNormalFontObject("GameFontNormal")
    noteDetailsButton:SetHighlightFontObject("GameFontHighlight")
    noteDetailsButton:SetScript("OnClick",
      function(self)
        AutoBiographer_NoteDetailsWindow.SelectedNote = sortedGenericNotes[i]

        if (AutoBiographer_NoteDetailsWindow:IsVisible()) then
          AutoBiographer_NoteDetailsWindow:Update()
        else
          AutoBiographer_NoteDetailsWindow:Toggle()
        end
      end
    )
    noteDetailsButton:Show()
    table.insert(self.ScrollFrame.Content.ButtonsPool.Allocated, noteDetailsButton)

    local contentFs = table.remove(self.ScrollFrame.Content.FontStringsPool.UnAllocated)
    if (not contentFs) then
      contentFs = self.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", font)
    end
    contentFs:SetPoint("TOPLEFT", 260, -15 * i)
    contentFs:SetText(HelperFunctions.ShortenString(sortedGenericNotes[i].Content, 65))
    contentFs:Show()
    table.insert(self.ScrollFrame.Content.FontStringsPool.Allocated, contentFs)
  end
  
  local scrollbarMaxValue = (#sortedGenericNotes * 15) - self.ScrollFrame:GetHeight();
  if (scrollbarMaxValue <= 0) then scrollbarMaxValue = 1 end
  self.ScrollFrame.Scrollbar:SetMinMaxValues(1, scrollbarMaxValue)
end

--
--
-- Statistics Window Update
--
--

function AutoBiographer_StatisticsWindow:Update()
  UIDropDownMenu_SetText(self.Dropdown, self.DropdownText)
  local minLevel = self.MinimumLevelEb:GetNumber()
  local maxLevel = self.MaximumLevelEb:GetNumber()

  -- Get table data.
  local tableData
  
  if (self.StatisticsDisplayMode == AutoBiographerEnum.StatisticsDisplayMode.Items) then
    local itemStatisticsByItem = Controller:GetAggregatedItemStatisticsDictionary(minLevel, maxLevel)
    tableData = {
      HeaderValues = { "Item Name", "AH", "COD", "Create", "Loot", "Mail", "Other", "Trade", "Vendor" },
      RowOffsets = { 0, 225, 275, 325, 375, 425, 475, 525, 575, 625 },
      Rows = {},
    }
    for catalogItemId, itemStatistics in pairs(itemStatisticsByItem) do
      if (Controller.CharacterData.Catalogs.ItemCatalog[catalogItemId]) then
        local itemName
        if (Controller.CharacterData.Catalogs.ItemCatalog[catalogItemId].Name) then
          itemName = Controller.CharacterData.Catalogs.ItemCatalog[catalogItemId].Name
        else
          itemName = "Item ID: " .. catalogUnitId
        end

        local row = {
          itemName,
          ItemStatistics.GetSum(itemStatistics, { AutoBiographerEnum.ItemAcquisitionMethod.AuctionHouse }),
          ItemStatistics.GetSum(itemStatistics, { AutoBiographerEnum.ItemAcquisitionMethod.MailCod }),
          ItemStatistics.GetSum(itemStatistics, { AutoBiographerEnum.ItemAcquisitionMethod.Create }),
          ItemStatistics.GetSum(itemStatistics, { AutoBiographerEnum.ItemAcquisitionMethod.Loot }),
          ItemStatistics.GetSum(itemStatistics, { AutoBiographerEnum.ItemAcquisitionMethod.Mail }),
          ItemStatistics.GetSum(itemStatistics, { AutoBiographerEnum.ItemAcquisitionMethod.Other }),
          ItemStatistics.GetSum(itemStatistics, { AutoBiographerEnum.ItemAcquisitionMethod.Trade }),
          ItemStatistics.GetSum(itemStatistics, { AutoBiographerEnum.ItemAcquisitionMethod.Merchant }),
        }
        table.insert(tableData.Rows, row)
      end
    end
  elseif (self.StatisticsDisplayMode == AutoBiographerEnum.StatisticsDisplayMode.Kills) then
    local killStatisticsByUnit = Controller:GetAggregatedKillStatisticsDictionary(minLevel, maxLevel)
    tableData = {
      HeaderValues = { "Unit Name", "Tagged KB", "Tagged KB+A", "Untagged KB", "Untagged KB+A" },
      RowOffsets = { 0, 225, 340, 455, 570, 685 },
      Rows = {},
    }
    for catalogUnitId, killStatistics in pairs(killStatisticsByUnit) do
      if (Controller.CharacterData.Catalogs.UnitCatalog[catalogUnitId] and Controller.CharacterData.Catalogs.UnitCatalog[catalogUnitId].UType == AutoBiographerEnum.UnitType.Creature) then
        local unitName
        if (Controller.CharacterData.Catalogs.UnitCatalog[catalogUnitId].Name) then
          unitName = Controller.CharacterData.Catalogs.UnitCatalog[catalogUnitId].Name
        else
          unitName = "Unit ID: " .. catalogUnitId
        end

        local row = {
          unitName,
          KillStatistics.GetSum(killStatistics, { AutoBiographerEnum.KillTrackingType.TaggedKillingBlow }),
          KillStatistics.GetSum(killStatistics, { AutoBiographerEnum.KillTrackingType.TaggedAssist, AutoBiographerEnum.KillTrackingType.TaggedGroupAssistOrKillingBlow, AutoBiographerEnum.KillTrackingType.TaggedKillingBlow }),
          KillStatistics.GetSum(killStatistics, { AutoBiographerEnum.KillTrackingType.UntaggedKillingBlow }),
          KillStatistics.GetSum(killStatistics, { AutoBiographerEnum.KillTrackingType.UntaggedAssist, AutoBiographerEnum.KillTrackingType.UntaggedGroupAssistOrKillingBlow, AutoBiographerEnum.KillTrackingType.UntaggedKillingBlow }),
        }
        table.insert(tableData.Rows, row)
      end
    end
  elseif (self.StatisticsDisplayMode == AutoBiographerEnum.StatisticsDisplayMode.OtherPlayers) then
    local otherPlayerStatisticsByUnit = Controller:GetAggregatedOtherPlayerStatisticsDictionary(minLevel, maxLevel)
    tableData = {
      HeaderValues = { "Unit Name", "Duels (Win)", "Duels (Lose)", "Time Grouped" },
      RowOffsets = { 0, 225, 340, 455, 570 },
      Rows = {},
    }
    for catalogUnitId, otherPlayerStatistics in pairs(otherPlayerStatisticsByUnit) do
      if (Controller.CharacterData.Catalogs.UnitCatalog[catalogUnitId] and Controller.CharacterData.Catalogs.UnitCatalog[catalogUnitId].UType == AutoBiographerEnum.UnitType.Player) then
        local unitName
        if (Controller.CharacterData.Catalogs.UnitCatalog[catalogUnitId].Name) then
          unitName = Controller.CharacterData.Catalogs.UnitCatalog[catalogUnitId].Name
        else
          unitName = "Unit ID: " .. catalogUnitId
        end

        local row = {
          unitName,
          OtherPlayerStatistics.GetSum(otherPlayerStatistics, { AutoBiographerEnum.OtherPlayerTrackingType.DuelsLostToPlayer }),
          OtherPlayerStatistics.GetSum(otherPlayerStatistics, { AutoBiographerEnum.OtherPlayerTrackingType.DuelsWonAgainstPlayer }),
          HelperFunctions.Round(OtherPlayerStatistics.GetSum(otherPlayerStatistics, { AutoBiographerEnum.OtherPlayerTrackingType.TimeSpentGroupedWithPlayer }) / 3600, 2),
        }
        table.insert(tableData.Rows, row)
      end
    end
  elseif (self.StatisticsDisplayMode == AutoBiographerEnum.StatisticsDisplayMode.Spells) then
    local spellStatisticsBySpell = Controller:GetAggregatedSpellStatisticsDictionary(minLevel, maxLevel)
    tableData = {
      HeaderValues = { "Spell Name", "Started Casting", "Successfully Cast" },
      RowOffsets = { 0, 225, 340, 455 },
      Rows = {},
    }

    local dictAggregatedBySpellName = {}
    for catalogSpellId, spellStatistics in pairs(spellStatisticsBySpell) do
      if (Controller.CharacterData.Catalogs.SpellCatalog[catalogSpellId]) then
        local spellName
        if (Controller.CharacterData.Catalogs.SpellCatalog[catalogSpellId].Name) then
          spellName = Controller.CharacterData.Catalogs.SpellCatalog[catalogSpellId].Name
        else
          spellName = "Spell ID: " .. catalogSpellId
        end

        local startedCasting = SpellStatistics.GetSum(spellStatistics, { AutoBiographerEnum.SpellTrackingType.StartedCasting })
        local successfullyCast = SpellStatistics.GetSum(spellStatistics, { AutoBiographerEnum.SpellTrackingType.SuccessfullyCast })

        if (not dictAggregatedBySpellName[spellName]) then
          dictAggregatedBySpellName[spellName] = {
            spellName,
            startedCasting,
            successfullyCast,
          }
        else
          dictAggregatedBySpellName[spellName][2] = dictAggregatedBySpellName[spellName][2] + startedCasting
          dictAggregatedBySpellName[spellName][3] = dictAggregatedBySpellName[spellName][3] + successfullyCast
        end
      end
    end

    for k, row in pairs(dictAggregatedBySpellName) do
      table.insert(tableData.Rows, row)
    end
  elseif (self.StatisticsDisplayMode == AutoBiographerEnum.StatisticsDisplayMode.Time) then
    local timeStatisticsByArea = Controller:GetAggregatedTimeStatisticsDictionary(minLevel, maxLevel)
    tableData = {
      HeaderValues = { "Area", "AFK", "Casting", "Dead", "Combat", "Total", "Taxi", "Grouped" },
      RowOffsets = { 0, 225, 285, 345, 405, 465, 525, 585, 645 },
      Rows = {},
    }

    local dictAggregatedByZone = {}
    for areaId, timeStatistics in pairs(timeStatisticsByArea) do
      local zone = string.sub(areaId, 1, areaId:find("-") - 1)
      local afk = HelperFunctions.Round(TimeStatistics.GetSum(timeStatistics, { AutoBiographerEnum.TimeTrackingType.Afk }) / 3600, 2)
      local casting = HelperFunctions.Round(TimeStatistics.GetSum(timeStatistics, { AutoBiographerEnum.TimeTrackingType.Casting }) / 3600, 2)
      local deadOrGhost = HelperFunctions.Round(TimeStatistics.GetSum(timeStatistics, { AutoBiographerEnum.TimeTrackingType.DeadOrGhost }) / 3600, 2)
      local inCombat = HelperFunctions.Round(TimeStatistics.GetSum(timeStatistics, { AutoBiographerEnum.TimeTrackingType.InCombat }) / 3600, 2)
      local loggedIn = HelperFunctions.Round(TimeStatistics.GetSum(timeStatistics, { AutoBiographerEnum.TimeTrackingType.LoggedIn }) / 3600, 2)
      local onTaxi = HelperFunctions.Round(TimeStatistics.GetSum(timeStatistics, { AutoBiographerEnum.TimeTrackingType.OnTaxi }) / 3600, 2)
      local inParty = HelperFunctions.Round(TimeStatistics.GetSum(timeStatistics, { AutoBiographerEnum.TimeTrackingType.InParty }) / 3600, 2)

      if (not dictAggregatedByZone[zone]) then
        dictAggregatedByZone[zone] = {
          zone,
          afk,
          casting,
          deadOrGhost,
          inCombat,
          loggedIn,
          onTaxi,
          inParty,
        }
      else
        dictAggregatedByZone[zone][2] = dictAggregatedByZone[zone][2] + afk
        dictAggregatedByZone[zone][3] = dictAggregatedByZone[zone][3] + casting
        dictAggregatedByZone[zone][4] = dictAggregatedByZone[zone][4] + deadOrGhost
        dictAggregatedByZone[zone][5] = dictAggregatedByZone[zone][5] + inCombat
        dictAggregatedByZone[zone][6] = dictAggregatedByZone[zone][6] + loggedIn
        dictAggregatedByZone[zone][7] = dictAggregatedByZone[zone][7] + onTaxi
        dictAggregatedByZone[zone][8] = dictAggregatedByZone[zone][8] + inParty
      end
    end

    for k, row in pairs(dictAggregatedByZone) do
      if (row[1] ~= "nil") then
        table.insert(tableData.Rows, row)
      end
    end
  else
    print("[AutoBiographer] Unsupported Statistics Display Mode. This should not happen!")
    return
  end

  table.sort(tableData.Rows, function(rowA, rowB)
    if (self.OrderDirection == "ASC") then
      return rowA[self.OrderColumnIndex] < rowB[self.OrderColumnIndex]
    else
      return rowA[self.OrderColumnIndex] > rowB[self.OrderColumnIndex]
    end
  end)

  -- Sort column description.
  self.SortColumnNameFs:SetText("Sorting by '" .. tableData.HeaderValues[self.OrderColumnIndex] .. "' " .. self.OrderDirection .. ".")
  
  -- Setup table headers.
  for k, headerFrame in pairs(self.TableHeaders) do
    headerFrame:Hide()
  end
  
  for i = 1, #tableData.HeaderValues do
    header = CreateFrame("Button", nil, self, "UIPanelButtonTemplate");
    header:SetPoint("TOPLEFT", self, 25 + tableData.RowOffsets[i], -65);
    header:SetPoint("BOTTOMRIGHT", self, "TOPLEFT", 25 + tableData.RowOffsets[i + 1], -85);
    header:SetText(tableData.HeaderValues[i]);
    header:SetNormalFontObject("GameFontNormal");
    header:SetHighlightFontObject("GameFontHighlight");
    header:SetScript("OnClick", 
      function(self)
        if (AutoBiographer_StatisticsWindow.OrderColumnIndex == i) then
          if (AutoBiographer_StatisticsWindow.OrderDirection == "DESC") then
            AutoBiographer_StatisticsWindow.OrderDirection = "ASC"
          else
            AutoBiographer_StatisticsWindow.OrderDirection = "DESC"
          end
        else
          AutoBiographer_StatisticsWindow.OrderColumnIndex = i
          AutoBiographer_StatisticsWindow.OrderDirection = "DESC"
        end
        AutoBiographer_StatisticsWindow:Update()
      end
    )
    table.insert(self.TableHeaders, header)
  end

  -- Release previous table body font strings.
  for i = 1, #self.ScrollFrame.Content.FontStringsPool.Allocated, 1 do
    local fs = self.ScrollFrame.Content.FontStringsPool.Allocated[i]
    fs:Hide()
    fs:SetText("")
    table.insert(self.ScrollFrame.Content.FontStringsPool.UnAllocated, fs)
  end
  self.ScrollFrame.Content.FontStringsPool.Allocated = {}

  -- Setup table body.
  for i = 1, #tableData.Rows, 1 do
    for j = 1, #tableData.Rows[i], 1 do
      local fs = table.remove(self.ScrollFrame.Content.FontStringsPool.UnAllocated)
      if (not fs) then
        fs = self.ScrollFrame.Content:CreateFontString(nil, "OVERLAY")
      end
      
      if (i % 2 == 0) then
        fs:SetFontObject("GameFontNormal")
      else
        fs:SetFontObject("GameFontHighlight")
      end

      fs:SetPoint("TOPLEFT", self.ScrollFrame.Content, 17 + tableData.RowOffsets[j], -15 * (i - 1))

      local text = tableData.Rows[i][j]
      local maxTextLength = (tableData.RowOffsets[j + 1] - tableData.RowOffsets[j]) / 7
      if (string.len(text) > maxTextLength) then
        text = string.sub(text, 1, maxTextLength - 3) .. "..."
      end

      fs:SetText(text)
      fs:Show()
      table.insert(self.ScrollFrame.Content.FontStringsPool.Allocated, fs)
    end
  end
  
  local scrollbarMaxValue = (#tableData.Rows * 15) - self.ScrollFrame:GetHeight();
  if (scrollbarMaxValue <= 0) then scrollbarMaxValue = 1 end
  self.ScrollFrame.Scrollbar:SetMinMaxValues(1, scrollbarMaxValue)
end

function AutoBiographer_VerificationWindow:Update()
  local timeTrackedLoggedIn = Controller:GetTimeForTimeTrackingType(AutoBiographerEnum.TimeTrackingType.LoggedIn, 1, 100)
  local percentageTimeTracked = HF.Round(100 * (timeTrackedLoggedIn / EM.PersistentPlayerInfo.LastTotalTimePlayed), 0)
  self.ScrollFrame.Content.PercentageTimeTrackedFs:SetText("Percentage of time played that AutoBiographer has tracked: " .. percentageTimeTracked .. "%.")

  local totalsKillStatistics = Controller:GetAggregatedKillStatisticsTotals(1, 100)
  local totalTaggedKills = KillStatistics.GetSum(totalsKillStatistics, { AutoBiographerEnum.KillTrackingType.TaggedAssist, AutoBiographerEnum.KillTrackingType.TaggedGroupAssistOrKillingBlow, AutoBiographerEnum.KillTrackingType.TaggedKillingBlow })
  local taggedKillsWithGroupMinorityDamage = KillStatistics.GetSum(totalsKillStatistics, { AutoBiographerEnum.KillTrackingType.TaggedKillWithGroupMinorityDamage })
  self.ScrollFrame.Content.TaggedKillsFs:SetText("Tagged Kills: " .. HF.CommaValue(totalTaggedKills) .. ". Tagged Kills With Majority Damage From Outside Group: " .. HF.CommaValue(taggedKillsWithGroupMinorityDamage) .. ".")

  if (self.ScrollFrame.Content.ExpectedlevelFs) then
    local experienceFromKills = Controller:GetExperienceByExperienceTrackingType(AutoBiographerEnum.ExperienceTrackingType.Kill, 1, 100)
    local experienceFromQuests = Controller:GetExperienceByExperienceTrackingType(AutoBiographerEnum.ExperienceTrackingType.Quest, 1, 100)
    local experienceFromDiscovery = Controller:GetExperienceByExperienceTrackingType(AutoBiographerEnum.ExperienceTrackingType.Discovery, 1, 100)
    local totalExperience = experienceFromKills + experienceFromQuests + experienceFromDiscovery
    local xpToLevel = 0
    local expectedLevel = 1
    for i = 1, #AutoBiographer_Databases.XpPerLevelDatabase do
      if (xpToLevel + AutoBiographer_Databases.XpPerLevelDatabase[i] > totalExperience) then
        expectedLevel = i + ((totalExperience - xpToLevel) / AutoBiographer_Databases.XpPerLevelDatabase[i])
        break
      end
      xpToLevel = xpToLevel + AutoBiographer_Databases.XpPerLevelDatabase[i]
    end
    self.ScrollFrame.Content.ExpectedlevelFs:SetText("Expected  Level: " .. HF.Round(expectedLevel, 2) .. ".")
  end
end