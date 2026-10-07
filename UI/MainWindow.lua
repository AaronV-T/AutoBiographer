local Controller = AutoBiographer_Controller
local EM = AutoBiographer_EventManager
local HF = HelperFunctions
local Api = AutoBiographer_Api

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
  frame.ScrollFrame.Content.ContentEditBoxScrollFrame.EditBox:SetMaxLetters(500)
  --frame.ScrollFrame.Content.ContentEditBoxScrollFrame.CharCount:Hide()

  frame.ScrollFrame.Content.cbShareEvent = CreateFrame("CheckButton", nil, frame.ScrollFrame.Content, "UICheckButtonTemplate") 
  frame.ScrollFrame.Content.cbShareEvent:SetPoint("LEFT", frame.ScrollFrame.Content, "BOTTOM", -50, 95)
  frame.ScrollFrame.Content.fsShareEvent = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.fsShareEvent:SetPoint("LEFT", frame.ScrollFrame.Content, "BOTTOM", -20, 95)
  frame.ScrollFrame.Content.fsShareEvent:SetText("Share with guild.")

  frame.ScrollFrame.Content.CreateEventBtn = CreateFrame("Button", nil, frame.ScrollFrame.Content, "UIPanelButtonTemplate");
  frame.ScrollFrame.Content.CreateEventBtn:SetPoint("BOTTOM", frame.ScrollFrame.Content, "BOTTOM", 0, 50);
  frame.ScrollFrame.Content.CreateEventBtn:SetSize(250, 35);
  frame.ScrollFrame.Content.CreateEventBtn:SetText("Save Event and Close Window");
  frame.ScrollFrame.Content.CreateEventBtn:SetNormalFontObject("GameFontNormalLarge");
  frame.ScrollFrame.Content.CreateEventBtn:SetHighlightFontObject("GameFontHighlightLarge");
  frame.ScrollFrame.Content.CreateEventBtn:SetScript("OnClick", 
    function(self)
      local text = frame.ScrollFrame.Content.ContentEditBoxScrollFrame.EditBox:GetText()
      Controller:AddEvent(CustomEvent.New(time(), HelperFunctions.GetCoordinatesByUnitId("player"), text))

      AutoBiographer_EventWindow:Update()
      AutoBiographer_CustomEventDetailsWindow:Toggle()

      if (frame.ScrollFrame.Content.cbShareEvent:GetChecked()) then
        AutoBiographer_MessageManager.SendAddonMessage(AutoBiographerEnum.AddonMessageType.CustomEvent, text)
      end
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

  frame.ScrollFrame.Content.OverlayFramesPool = {
    Allocated = {},
    UnAllocated = {},
  }

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
  frame.ScrollFrame.Content.ContentEditBoxScrollFrame.EditBox:SetMaxLetters(1000)
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
  
    info.text, info.arg1 = "Damage Dealt", AutoBiographerEnum.StatisticsDisplayMode.DamageDealt
    UIDropDownMenu_AddButton(info)
    info.text, info.arg1 = "Damage Dealt by Rank", AutoBiographerEnum.StatisticsDisplayMode.DamageDealtByRank
    UIDropDownMenu_AddButton(info)
    info.text, info.arg1 = "Damage Taken by Spell", AutoBiographerEnum.StatisticsDisplayMode.DamageTakenBySpell
    UIDropDownMenu_AddButton(info)
    info.text, info.arg1 = "Damage Taken by Unit", AutoBiographerEnum.StatisticsDisplayMode.DamageTakenByUnit
    UIDropDownMenu_AddButton(info)
    info.text, info.arg1 = "Healing Dealt", AutoBiographerEnum.StatisticsDisplayMode.HealingDealt
    UIDropDownMenu_AddButton(info)
    info.text, info.arg1 = "Healing Dealt by Rank", AutoBiographerEnum.StatisticsDisplayMode.HealingDealtByRank
    UIDropDownMenu_AddButton(info)
    info.text, info.arg1 = "Item Aquisitions", AutoBiographerEnum.StatisticsDisplayMode.Items
    UIDropDownMenu_AddButton(info)
    info.text, info.arg1 = "Kills", AutoBiographerEnum.StatisticsDisplayMode.Kills
    UIDropDownMenu_AddButton(info)
    info.text, info.arg1 = "Other Players", AutoBiographerEnum.StatisticsDisplayMode.OtherPlayers
    UIDropDownMenu_AddButton(info)
    info.text, info.arg1 = "Spells", AutoBiographerEnum.StatisticsDisplayMode.Spells
    UIDropDownMenu_AddButton(info)
    info.text, info.arg1 = "Spells by Rank", AutoBiographerEnum.StatisticsDisplayMode.SpellsByRank
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
  self.ScrollFrame.Content.cbShareEvent:SetChecked(false)
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
  for i = 1, #self.ScrollFrame.Content.FontStringsPool.Allocated, 1 do
    local fs = self.ScrollFrame.Content.FontStringsPool.Allocated[i]
    fs:Hide()
    fs:SetText("")
    table.insert(self.ScrollFrame.Content.FontStringsPool.UnAllocated, fs)
  end
  self.ScrollFrame.Content.FontStringsPool.Allocated = {}

  for i = 1, #self.ScrollFrame.Content.OverlayFramesPool.Allocated, 1 do
    local overlayFrame = self.ScrollFrame.Content.OverlayFramesPool.Allocated[i]
    overlayFrame:Hide()
    table.insert(self.ScrollFrame.Content.OverlayFramesPool.UnAllocated, overlayFrame)
  end
  self.ScrollFrame.Content.OverlayFramesPool.Allocated = {}

  local events = Controller:GetEvents()
  for i = 1, #events, 1 do
    if (AutoBiographer_Settings.EventDisplayFilters[events[i].SubType]) then
      local eventString = Controller:GetEventString(events[i])

      local fs = table.remove(self.ScrollFrame.Content.FontStringsPool.UnAllocated)
      if (not fs) then
        fs = self.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      end
      
      fs:SetPoint("TOPLEFT", self.ScrollFrame.Content, 5, -15 * #self.ScrollFrame.Content.FontStringsPool.Allocated)
      fs:SetText(HelperFunctions.ShortenString(eventString, 85))
      fs:Show()
      table.insert(self.ScrollFrame.Content.FontStringsPool.Allocated, fs)

      local overlayFrame = table.remove(self.ScrollFrame.Content.OverlayFramesPool.UnAllocated)
      if (not overlayFrame) then
        overlayFrame = CreateFrame("Frame", nil, self.ScrollFrame.Content, nil)
      end

      overlayFrame:SetPoint("TOPLEFT", self.ScrollFrame.Content, 5, -15 * #self.ScrollFrame.Content.OverlayFramesPool.Allocated)
      overlayFrame:SetSize(750, 15)
      overlayFrame:SetScript("OnEnter", function(self, button)
        GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
        GameTooltip:ClearAllPoints()
        GameTooltip:SetPoint("TOPRIGHT", overlayFrame, "BOTTOMRIGHT", 0, 0)
        GameTooltip:SetText(eventString)
        GameTooltip:Show()
      end)
      overlayFrame:SetScript("OnLeave", function(self, button)
        GameTooltip:Hide()
      end)
      overlayFrame:Show()
      table.insert(self.ScrollFrame.Content.OverlayFramesPool.Allocated, overlayFrame)

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
    table.insert(self.ScrollFrame.Content.ButtonsPool.UnAllocated, button)
  end
  self.ScrollFrame.Content.ButtonsPool.Allocated = {}

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
  local isRankView = self.StatisticsDisplayMode == AutoBiographerEnum.StatisticsDisplayMode.DamageDealtByRank or
    self.StatisticsDisplayMode == AutoBiographerEnum.StatisticsDisplayMode.HealingDealtByRank or
    self.StatisticsDisplayMode == AutoBiographerEnum.StatisticsDisplayMode.SpellsByRank
  
  if (self.StatisticsDisplayMode == AutoBiographerEnum.StatisticsDisplayMode.DamageDealt) then
    local abilitiesBySpellName = Controller:GetAggregatedDamageMeterAbilities({ AutoBiographerEnum.DamageOrHealingCategory.DamageDealt }, minLevel, maxLevel, true)
    tableData = {
      HeaderValues = { "Spell Name", "Effective Damage", "Over Damage" },
      RowOffsets = { 0, 250, 450, 650 },
      Rows = {},
    }
    for spellName, breakdown in pairs(abilitiesBySpellName) do
      table.insert(tableData.Rows, { spellName, breakdown.Amount - breakdown.Over, breakdown.Over })
    end
  elseif (self.StatisticsDisplayMode == AutoBiographerEnum.StatisticsDisplayMode.DamageDealtByRank) then
    local abilitiesBySpellId = Controller:GetAggregatedDamageMeterAbilities({ AutoBiographerEnum.DamageOrHealingCategory.DamageDealt }, minLevel, maxLevel)
    tableData = {
      HeaderValues = { "Spell Name", "Rank", "Effective Damage", "Over Damage" },
      RowOffsets = { 0, 250, 330, 490, 650 },
      Rows = {},
    }
    for spellId, breakdown in pairs(abilitiesBySpellId) do
      local catalogSpell = Controller.CharacterData.Catalogs.SpellCatalog[spellId]
      local spellName = CatalogSpell.GetDamageMeterDisplayName(catalogSpell, spellId)
      local rank = catalogSpell and catalogSpell.Rank
      if (type(rank) == "string") then rank = tonumber(string.match(rank, "%d+")) end
      rank = rank or Api.GetSpellRank(spellId) or 0
      table.insert(tableData.Rows, { spellName, rank, breakdown.Amount - breakdown.Over, breakdown.Over })
    end
  elseif (self.StatisticsDisplayMode == AutoBiographerEnum.StatisticsDisplayMode.DamageTakenBySpell) then
    local breakdownsByUnitAndSpell = Controller:GetAggregatedDamageTakenBySpell({ AutoBiographerEnum.DamageOrHealingCategory.DamageTaken }, minLevel, maxLevel)
    tableData = {
      HeaderValues = { "Spell Name", "Unit Name", "Effective Damage", "Over Damage" },
      RowOffsets = { 0, 200, 365, 505, 650 },
      Rows = {},
    }
    for unitName, spells in pairs(breakdownsByUnitAndSpell) do
      for spellId, breakdown in pairs(spells) do
        local catalogSpell = Controller.CharacterData.Catalogs.SpellCatalog[spellId]
        local spellName = catalogSpell and catalogSpell.Name or ("Spell ID: " .. tostring(spellId))
        table.insert(tableData.Rows, { spellName, unitName, breakdown.Amount - breakdown.Over, breakdown.Over })
      end
    end
    local unknownBreakdown = Controller:GetAggregatedDamageTakenUnknownBreakdown(minLevel, maxLevel)
    if (unknownBreakdown.Amount ~= 0 or unknownBreakdown.Over ~= 0) then
      table.insert(tableData.Rows, { "Unknown", "Unknown", unknownBreakdown.Amount - unknownBreakdown.Over, unknownBreakdown.Over })
    end
  elseif (self.StatisticsDisplayMode == AutoBiographerEnum.StatisticsDisplayMode.DamageTakenByUnit) then
    local breakdownsByUnit = Controller:GetAggregatedDamageTakenByUnit({ AutoBiographerEnum.DamageOrHealingCategory.DamageTaken }, minLevel, maxLevel)
    tableData = {
      HeaderValues = { "Unit Name", "Effective Damage", "Over Damage" },
      RowOffsets = { 0, 250, 450, 650 },
      Rows = {},
    }
    for unitName, breakdown in pairs(breakdownsByUnit) do
      table.insert(tableData.Rows, { unitName, breakdown.Amount - breakdown.Over, breakdown.Over })
    end
    local unknownBreakdown = Controller:GetAggregatedDamageTakenUnknownBreakdown(minLevel, maxLevel)
    if (unknownBreakdown.Amount ~= 0 or unknownBreakdown.Over ~= 0) then
      table.insert(tableData.Rows, { "Unknown", unknownBreakdown.Amount - unknownBreakdown.Over, unknownBreakdown.Over })
    end
  elseif (self.StatisticsDisplayMode == AutoBiographerEnum.StatisticsDisplayMode.HealingDealt) then
    local abilitiesBySpellName = Controller:GetAggregatedDamageMeterAbilities({ AutoBiographerEnum.DamageOrHealingCategory.HealingDealt }, minLevel, maxLevel, true)
    tableData = {
      HeaderValues = { "Spell Name", "Effective Healing", "Over Healing" },
      RowOffsets = { 0, 250, 450, 650 },
      Rows = {},
    }
    for spellName, breakdown in pairs(abilitiesBySpellName) do
      table.insert(tableData.Rows, { spellName, breakdown.Amount - breakdown.Over, breakdown.Over })
    end
  elseif (self.StatisticsDisplayMode == AutoBiographerEnum.StatisticsDisplayMode.HealingDealtByRank) then
    local abilitiesBySpellId = Controller:GetAggregatedDamageMeterAbilities({ AutoBiographerEnum.DamageOrHealingCategory.HealingDealt }, minLevel, maxLevel)
    tableData = {
      HeaderValues = { "Spell Name", "Rank", "Effective Healing", "Over Healing" },
      RowOffsets = { 0, 250, 330, 490, 650 },
      Rows = {},
    }
    for spellId, breakdown in pairs(abilitiesBySpellId) do
      local catalogSpell = Controller.CharacterData.Catalogs.SpellCatalog[spellId]
      local spellName = CatalogSpell.GetDamageMeterDisplayName(catalogSpell, spellId)
      local rank = catalogSpell and catalogSpell.Rank
      if (type(rank) == "string") then rank = tonumber(string.match(rank, "%d+")) end
      rank = rank or Api.GetSpellRank(spellId) or 0
      table.insert(tableData.Rows, { spellName, rank, breakdown.Amount - breakdown.Over, breakdown.Over })
    end
  elseif (self.StatisticsDisplayMode == AutoBiographerEnum.StatisticsDisplayMode.Items) then
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
      HeaderValues = { "Unit Name", "Buffs (Outside)", "Buffs (In Group)", "Duels (Win)", "Duels (Lose)", "Time Grouped" },
      RowOffsets = { 0, 170, 290, 400, 485, 570, 700 },
      Rows = {},
    }
    for catalogUnitId, otherPlayerStatistics in pairs(otherPlayerStatisticsByUnit) do
      local catalogUnit = Controller.CharacterData.Catalogs.UnitCatalog[catalogUnitId]
      local unitName = catalogUnit and catalogUnit.Name or ("Unit ID: " .. tostring(catalogUnitId))
      if (catalogUnit and catalogUnit.Name and catalogUnit.LastName and catalogUnit.LastName ~= "") then
        unitName = unitName .. " " .. catalogUnit.LastName
      end

      local row = {
        unitName,
        OtherPlayerStatistics.GetSum(otherPlayerStatistics, { AutoBiographerEnum.OtherPlayerTrackingType.BuffsGivenToPlayerNotGrouped }),
        OtherPlayerStatistics.GetSum(otherPlayerStatistics, { AutoBiographerEnum.OtherPlayerTrackingType.BuffsGivenToPlayerWhileGrouped }),
        OtherPlayerStatistics.GetSum(otherPlayerStatistics, { AutoBiographerEnum.OtherPlayerTrackingType.DuelsLostToPlayer }),
        OtherPlayerStatistics.GetSum(otherPlayerStatistics, { AutoBiographerEnum.OtherPlayerTrackingType.DuelsWonAgainstPlayer }),
        OtherPlayerStatistics.GetSum(otherPlayerStatistics, { AutoBiographerEnum.OtherPlayerTrackingType.TimeSpentGroupedWithPlayer }),
      }
      table.insert(tableData.Rows, row)
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
  elseif (self.StatisticsDisplayMode == AutoBiographerEnum.StatisticsDisplayMode.SpellsByRank) then
    local spellStatisticsBySpell = Controller:GetAggregatedSpellStatisticsDictionary(minLevel, maxLevel)
    tableData = {
      HeaderValues = { "Spell Name", "Rank", "Started Casting", "Successfully Cast" },
      RowOffsets = { 0, 250, 330, 490, 650 },
      Rows = {},
    }
    for spellId, spellStatistics in pairs(spellStatisticsBySpell) do
      local catalogSpell = Controller.CharacterData.Catalogs.SpellCatalog[spellId]
      local spellName = catalogSpell and catalogSpell.Name or ("Spell ID: " .. tostring(spellId))
      local rank = catalogSpell and catalogSpell.Rank
      if (type(rank) == "string") then rank = tonumber(string.match(rank, "%d+")) end
      rank = rank or Api.GetSpellRank(spellId) or 0
      local startedCasting = SpellStatistics.GetSum(spellStatistics, { AutoBiographerEnum.SpellTrackingType.StartedCasting })
      local successfullyCast = SpellStatistics.GetSum(spellStatistics, { AutoBiographerEnum.SpellTrackingType.SuccessfullyCast })
      table.insert(tableData.Rows, { spellName, rank, startedCasting, successfullyCast })
    end
  elseif (self.StatisticsDisplayMode == AutoBiographerEnum.StatisticsDisplayMode.Time) then
    local timeStatisticsByArea = Controller:GetAggregatedTimeStatisticsDictionary(minLevel, maxLevel)
    tableData = {
      HeaderValues = { "Area", "AFK", "Casting", "Dead", "Combat", "Total", "Taxi", "Grouped", "Gamepad" },
      RowOffsets = { 0, 225, 285, 345, 405, 465, 525, 585, 645, 705 },
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
      local gamepadUI = HelperFunctions.Round(TimeStatistics.GetSum(timeStatistics, { AutoBiographerEnum.TimeTrackingType.GamepadUI }) / 3600, 2)

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
          gamepadUI,
        }
      else
        dictAggregatedByZone[zone][2] = dictAggregatedByZone[zone][2] + afk
        dictAggregatedByZone[zone][3] = dictAggregatedByZone[zone][3] + casting
        dictAggregatedByZone[zone][4] = dictAggregatedByZone[zone][4] + deadOrGhost
        dictAggregatedByZone[zone][5] = dictAggregatedByZone[zone][5] + inCombat
        dictAggregatedByZone[zone][6] = dictAggregatedByZone[zone][6] + loggedIn
        dictAggregatedByZone[zone][7] = dictAggregatedByZone[zone][7] + onTaxi
        dictAggregatedByZone[zone][8] = dictAggregatedByZone[zone][8] + inParty
        dictAggregatedByZone[zone][9] = dictAggregatedByZone[zone][9] + gamepadUI
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
    if (isRankView and self.OrderColumnIndex == 1 and rowA[1] == rowB[1]) then
      if (self.OrderDirection == "ASC") then
        return rowA[2] < rowB[2]
      else
        return rowA[2] > rowB[2]
      end
    end
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
      if (self.StatisticsDisplayMode == AutoBiographerEnum.StatisticsDisplayMode.OtherPlayers and j == 6) then
        text = HelperFunctions.SecondsToTimeString(text, true)
      elseif (isRankView and j == 2 and text == 0) then
        text = "-"
      end

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
