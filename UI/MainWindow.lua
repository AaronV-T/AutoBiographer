local Controller = AutoBiographer_Controller
local HF = HelperFunctions

AutoBiographer_MainWindow = CreateFrame("Frame", "AutoBiographerMain", UIParent, "BasicFrameTemplateWithInset")
AutoBiographer_MainWindow:SetFrameStrata("HIGH")

AutoBiographer_DebugWindow = CreateFrame("Frame", "AutoBiographerDebug", AutoBiographer_MainWindow, "BasicFrameTemplate")
AutoBiographer_EventWindow = CreateFrame("Frame", "AutoBiographerEvent", AutoBiographer_MainWindow, "BasicFrameTemplate")
AutoBiographer_StatisticsWindow = CreateFrame("Frame", "AutoBiographerStatistics", AutoBiographer_MainWindow, "BasicFrameTemplate")

--
--
-- Debug Window Initialization
--
--

function AutoBiographer_DebugWindow:Initialize()
  local frame = self
  frame:SetSize(750, 585)
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

  frame.Title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.Title:SetPoint("LEFT", frame.TitleBg, "LEFT", 5, 0);
  frame.Title:SetText("AutoBiographer Debug Window")
  
  --scrollframe 
  frame.ScrollFrame = CreateFrame("ScrollFrame", nil, frame) 
  frame.ScrollFrame:SetPoint("TOPLEFT", 10, -25) 
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
  frame.ScrollFrame.Content:SetSize(1, 1)
  frame.ScrollFrame.Content.ChildrenCount = 0
  frame.ScrollFrame:SetScrollChild(frame.ScrollFrame.Content)

  frame.LogsUpdated = function(self) -- This is called when a new debug log is added.
    if (self:IsVisible()) then
      self:Update()
    end
  end

  frame.Toggle = function(self)
    if (self:IsVisible()) then
      self:Hide()
    else
      self:Update()
      self:Show()
      self:SetFrameLevel(250)
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
  frame:SetSize(750, 585) 
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
      local sliderMin, sliderMax = frame.SubFrame.ScrollFrame.Scrollbar:GetMinMaxValues()
      frame.SubFrame.ScrollFrame.Scrollbar:SetValue(sliderMax)
    elseif (key == "HOME") then
      frame:SetPropagateKeyboardInput(false)
      local sliderMin, sliderMax = frame.SubFrame.ScrollFrame.Scrollbar:GetMinMaxValues()
      frame.SubFrame.ScrollFrame.Scrollbar:SetValue(sliderMin)
    elseif (key == "PAGEDOWN") then
      frame:SetPropagateKeyboardInput(false)
      local sliderMin, sliderMax = frame.SubFrame.ScrollFrame.Scrollbar:GetMinMaxValues()
      local sliderCurrentValue = frame.SubFrame.ScrollFrame.Scrollbar:GetValue()

      local sliderNextValue = sliderCurrentValue + frame.SubFrame.ScrollFrame:GetHeight()

      if (sliderNextValue > sliderMax) then
        sliderNextValue = sliderMax
      elseif (sliderNextValue < sliderMin) then
        sliderNextValue = sliderMin
      end

      frame.SubFrame.ScrollFrame.Scrollbar:SetValue(sliderNextValue)
    elseif (key == "PAGEUP") then
      frame:SetPropagateKeyboardInput(false)
      local sliderMin, sliderMax = frame.SubFrame.ScrollFrame.Scrollbar:GetMinMaxValues()
      local sliderCurrentValue = frame.SubFrame.ScrollFrame.Scrollbar:GetValue()

      local sliderNextValue = sliderCurrentValue - frame.SubFrame.ScrollFrame:GetHeight()

      if (sliderNextValue > sliderMax) then
        sliderNextValue = sliderMax
      elseif (sliderNextValue < sliderMin) then
        sliderNextValue = sliderMin
      end

      frame.SubFrame.ScrollFrame.Scrollbar:SetValue(sliderNextValue)
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
    local sliderMin, sliderMax = frame.SubFrame.ScrollFrame.Scrollbar:GetMinMaxValues()
    local sliderCurrentValue = frame.SubFrame.ScrollFrame.Scrollbar:GetValue()

    local sliderNextValue = sliderCurrentValue - (frame.SubFrame.ScrollFrame.Scrollbar.scrollStep * direction)

    if (sliderNextValue > sliderMax) then
      sliderNextValue = sliderMax
    elseif (sliderNextValue < sliderMin) then
      sliderNextValue = sliderMin
    end

    frame.SubFrame.ScrollFrame.Scrollbar:SetValue(sliderNextValue)
  end)

  frame.Title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.Title:SetPoint("LEFT", frame.TitleBg, "LEFT", 5, 0);
  frame.Title:SetText("AutoBiographer Event Window")
  
  frame.SubFrame = CreateFrame("Frame", "AutoBiographerEventSub", frame)
  frame.SubFrame:SetPoint("TOPLEFT", 10, -25) 
  frame.SubFrame:SetPoint("BOTTOMRIGHT", -10, 10) 
  
  -- Filter Check Boxes
  local leftPoint = -300
  local fsBattleground = frame.SubFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  fsBattleground:SetPoint("CENTER", frame.SubFrame, "TOP", leftPoint, -15)
  fsBattleground:SetText("Battle\nground")
  local cbBattleground= CreateFrame("CheckButton", nil, frame.SubFrame, "UICheckButtonTemplate") 
  cbBattleground:SetPoint("CENTER", frame.SubFrame, "TOP", leftPoint, -40)
  cbBattleground:SetChecked(AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.BattlegroundJoined])
  cbBattleground:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.BattlegroundJoined] = self:GetChecked()
    AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.BattlegroundLost] = self:GetChecked()
    AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.BattlegroundWon] = self:GetChecked()
    frame:Update()
  end)

  leftPoint = leftPoint + 50
  local fsBossKill = frame.SubFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  fsBossKill:SetPoint("CENTER", frame.SubFrame, "TOP", leftPoint, -15)
  fsBossKill:SetText("Boss\nKill")
  local cbBossKill= CreateFrame("CheckButton", nil, frame.SubFrame, "UICheckButtonTemplate") 
  cbBossKill:SetPoint("CENTER", frame.SubFrame, "TOP", leftPoint, -40)
  cbBossKill:SetChecked(AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.BossKill])
  cbBossKill:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.BossKill] = self:GetChecked()
    frame:Update()
  end)
  
  leftPoint = leftPoint + 50
  local fsFirstAcquiredItem = frame.SubFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  fsFirstAcquiredItem:SetPoint("CENTER", frame.SubFrame, "TOP", leftPoint, -15) 
  fsFirstAcquiredItem:SetText("First\nItem")
  local cbFirstAcquiredItem = CreateFrame("CheckButton", nil, frame.SubFrame, "UICheckButtonTemplate") 
  cbFirstAcquiredItem:SetPoint("CENTER", frame.SubFrame, "TOP", leftPoint, -40)
  cbFirstAcquiredItem:SetChecked(AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.FirstAcquiredItem])
  cbFirstAcquiredItem:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.FirstAcquiredItem] = self:GetChecked()
    frame:Update()
  end)
  
  leftPoint = leftPoint + 50
  local fsFirstKill = frame.SubFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  fsFirstKill:SetPoint("CENTER", frame.SubFrame, "TOP", leftPoint, -15)
  fsFirstKill:SetText("First\nKill")
  local cbFirstKill = CreateFrame("CheckButton", nil, frame.SubFrame, "UICheckButtonTemplate") 
  cbFirstKill:SetPoint("CENTER", frame.SubFrame, "TOP", leftPoint, -40)
  cbFirstKill:SetChecked(AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.FirstKill])
  cbFirstKill:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.FirstKill] = self:GetChecked()
    frame:Update()
  end)
  
  leftPoint = leftPoint + 50
  local fsGuild = frame.SubFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  fsGuild:SetPoint("CENTER", frame.SubFrame, "TOP", leftPoint, -15)
  fsGuild:SetText("Guild")
  local cbGuild = CreateFrame("CheckButton", nil, frame.SubFrame, "UICheckButtonTemplate") 
  cbGuild:SetPoint("CENTER", frame.SubFrame, "TOP", leftPoint, -40)
  cbGuild:SetChecked(AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.GuildJoined])
  cbGuild:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.GuildJoined] = self:GetChecked()
    AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.GuildLeft] = self:GetChecked()
    AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.GuildRankChanged] = self:GetChecked()
    frame:Update()
  end)
  
  leftPoint = leftPoint + 50
  local fsLevelUp = frame.SubFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  fsLevelUp:SetPoint("CENTER", frame.SubFrame, "TOP", leftPoint, -15)
  fsLevelUp:SetText("Level\nUp")
  local cbLevelUp= CreateFrame("CheckButton", nil, frame.SubFrame, "UICheckButtonTemplate") 
  cbLevelUp:SetPoint("CENTER", frame.SubFrame, "TOP", leftPoint, -40)
  cbLevelUp:SetChecked(AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.LevelUp])
  cbLevelUp:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.LevelUp] = self:GetChecked()
    frame:Update()
  end)
  
  leftPoint = leftPoint + 50
  local fsPlayerDeath = frame.SubFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  fsPlayerDeath:SetPoint("CENTER", frame.SubFrame, "TOP", leftPoint, -15)
  fsPlayerDeath:SetText("Player\nDeath")
  local cbPlayerDeath = CreateFrame("CheckButton", nil, frame.SubFrame, "UICheckButtonTemplate") 
  cbPlayerDeath:SetPoint("CENTER", frame.SubFrame, "TOP", leftPoint, -40)
  cbPlayerDeath:SetChecked(AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.PlayerDeath])
  cbPlayerDeath:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.PlayerDeath] = self:GetChecked()
    frame:Update()
  end)
  
  leftPoint = leftPoint + 50
  local fsQuestTurnIn = frame.SubFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  fsQuestTurnIn:SetPoint("CENTER", frame.SubFrame, "TOP", leftPoint, -15)
  fsQuestTurnIn:SetText("Quest")
  local cbQuestTurnIn = CreateFrame("CheckButton", nil, frame.SubFrame, "UICheckButtonTemplate") 
  cbQuestTurnIn:SetPoint("CENTER", frame.SubFrame, "TOP", leftPoint, -40)
  cbQuestTurnIn:SetChecked(AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.QuestTurnIn])
  cbQuestTurnIn:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.QuestTurnIn] = self:GetChecked()
    frame:Update()
  end)
  
  leftPoint = leftPoint + 50
  local fsReputationLevelChanged = frame.SubFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  fsReputationLevelChanged:SetPoint("CENTER", frame.SubFrame, "TOP", leftPoint, -15)
  fsReputationLevelChanged:SetText("Rep\nChanged")
  local cbReputationLevelChanged= CreateFrame("CheckButton", nil, frame.SubFrame, "UICheckButtonTemplate") 
  cbReputationLevelChanged:SetPoint("CENTER", frame.SubFrame, "TOP", leftPoint, -40)
  cbReputationLevelChanged:SetChecked(AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.ReputationLevelChanged])
  cbReputationLevelChanged:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.ReputationLevelChanged] = self:GetChecked()
    frame:Update()
  end)
  
  leftPoint = leftPoint + 50
  local fsSkillMilestone = frame.SubFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  fsSkillMilestone:SetPoint("CENTER", frame.SubFrame, "TOP", leftPoint, -15)
  fsSkillMilestone:SetText("Skill")
  local cbSkillMilestone = CreateFrame("CheckButton", nil, frame.SubFrame, "UICheckButtonTemplate") 
  cbSkillMilestone:SetPoint("CENTER", frame.SubFrame, "TOP", leftPoint, -40)
  cbSkillMilestone:SetChecked(AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.SkillMilestone])
  cbSkillMilestone:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.SkillMilestone] = self:GetChecked()
    frame:Update()
  end)
  
  leftPoint = leftPoint + 50
  local fsSpellLearned = frame.SubFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  fsSpellLearned:SetPoint("CENTER", frame.SubFrame, "TOP", leftPoint, -15)
  fsSpellLearned:SetText("Spell")
  local cbSpellLearned= CreateFrame("CheckButton", nil, frame.SubFrame, "UICheckButtonTemplate") 
  cbSpellLearned:SetPoint("CENTER", frame.SubFrame, "TOP", leftPoint, -40)
  cbSpellLearned:SetChecked(AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.SpellLearned])
  cbSpellLearned:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.SpellLearned] = self:GetChecked()
    frame:Update()
  end)
  
  leftPoint = leftPoint + 50
  local fsSubZoneFirstVisit = frame.SubFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  fsSubZoneFirstVisit:SetPoint("CENTER", frame.SubFrame, "TOP", leftPoint, -15)
  fsSubZoneFirstVisit:SetText("Sub\nZone")
  local cbSubZoneFirstVisit = CreateFrame("CheckButton", nil, frame.SubFrame, "UICheckButtonTemplate") 
  cbSubZoneFirstVisit:SetPoint("CENTER", frame.SubFrame, "TOP", leftPoint, -40)
  cbSubZoneFirstVisit:SetChecked(AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.SubZoneFirstVisit])
  cbSubZoneFirstVisit:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.SubZoneFirstVisit] = self:GetChecked()
    frame:Update()
  end)
  
  leftPoint = leftPoint + 50
  local fsZoneFirstVisit = frame.SubFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  fsZoneFirstVisit:SetPoint("CENTER", frame.SubFrame, "TOP", leftPoint, -15)
  fsZoneFirstVisit:SetText("Zone")
  local cbZoneFirstVisit = CreateFrame("CheckButton", nil, frame.SubFrame, "UICheckButtonTemplate") 
  cbZoneFirstVisit:SetPoint("CENTER", frame.SubFrame, "TOP", leftPoint, -40)
  cbZoneFirstVisit:SetChecked(AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.ZoneFirstVisit])
  cbZoneFirstVisit:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.ZoneFirstVisit] = self:GetChecked()
    frame:Update()
  end)
  
  --scrollframe 
  frame.SubFrame.ScrollFrame = CreateFrame("ScrollFrame", nil, frame.SubFrame) 
  frame.SubFrame.ScrollFrame:SetPoint("TOPLEFT", 10, -65) 
  frame.SubFrame.ScrollFrame:SetPoint("BOTTOMRIGHT", -10, 10) 

  --scrollbar 
  frame.SubFrame.ScrollFrame.Scrollbar = CreateFrame("Slider", nil, frame.SubFrame.ScrollFrame, "UIPanelScrollBarTemplate")
  frame.SubFrame.ScrollFrame.Scrollbar:SetPoint("TOPLEFT", frame.SubFrame, "TOPRIGHT", -15, -17)
  frame.SubFrame.ScrollFrame.Scrollbar:SetPoint("BOTTOMLEFT", frame.SubFrame, "BOTTOMRIGHT", -15, 12)
  frame.SubFrame.ScrollFrame.Scrollbar:SetMinMaxValues(1, 1)
  frame.SubFrame.ScrollFrame.Scrollbar:SetValueStep(1)
  frame.SubFrame.ScrollFrame.Scrollbar.scrollStep = 15
  frame.SubFrame.ScrollFrame.Scrollbar:SetValue(0)
  frame.SubFrame.ScrollFrame.Scrollbar:SetWidth(16)
  frame.SubFrame.ScrollFrame.Scrollbar:SetScript("OnValueChanged",
    function (self, value) 
      self:GetParent():SetVerticalScroll(value) 
    end
  ) 
  local scrollbg = frame.SubFrame.ScrollFrame.Scrollbar:CreateTexture(nil, "BACKGROUND") 
  scrollbg:SetAllPoints(frame.SubFrame.ScrollFrame.Scrollbar) 
  scrollbg:SetTexture(0, 0, 0, 0.4) 

   --content frame
   frame.SubFrame.ScrollFrame.Content = CreateFrame("Frame", nil, frame.SubFrame.ScrollFrame)
   frame.SubFrame.ScrollFrame.Content:SetSize(1, 1)
   frame.SubFrame.ScrollFrame.Content.FontStringsPool = {
     Allocated = {},
     UnAllocated = {},
   }
   frame.SubFrame.ScrollFrame:SetScrollChild(frame.SubFrame.ScrollFrame.Content)

  frame.Toggle = function(self)
    if (self:IsVisible()) then
      self:Hide()
    else
      self:Update()
      self:Show()
      self:SetFrameLevel(150)
    end
  end

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
  frame:SetSize(800, 600) 
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
  
  frame.Title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
  frame.Title:SetPoint("LEFT", frame.TitleBg, "LEFT", 5, 0);
  frame.Title:SetText("AutoBiographer Main Window")

   --scrollframe 
  frame.ScrollFrame = CreateFrame("ScrollFrame", nil, frame) 
  frame.ScrollFrame:SetPoint("TOPLEFT", 10, -25) 
  frame.ScrollFrame:SetPoint("BOTTOMRIGHT", -10, 10) 

  --scrollbar 
  frame.ScrollFrame.Scrollbar = CreateFrame("Slider", nil, frame.ScrollFrame, "UIPanelScrollBarTemplate")
  frame.ScrollFrame.Scrollbar:SetPoint("TOPLEFT", frame, "TOPRIGHT", -25, -45)
  frame.ScrollFrame.Scrollbar:SetPoint("BOTTOMLEFT", frame, "BOTTOMRIGHT", -25, 22)
  frame.ScrollFrame.Scrollbar:SetMinMaxValues(1, 510)
  frame.ScrollFrame.Scrollbar:SetValueStep(1)
  frame.ScrollFrame.Scrollbar.scrollStep = 15
  frame.ScrollFrame.Scrollbar:SetValue(0)
  frame.ScrollFrame.Scrollbar:SetWidth(16)
  frame.ScrollFrame.Scrollbar:SetScript("OnValueChanged",
    function (self, value) 
      self:GetParent():SetVerticalScroll(value) 
    end
  )
  
  frame.Toggle = function(self)
    if (self:IsVisible()) then
      self:Hide()
    else
      self:Update()
      self:Show()
      self:SetFrameLevel(100)
    end
  end

  -- Content Frame 
  frame.ScrollFrame.Content = CreateFrame("Frame", nil, frame.ScrollFrame) 
  frame.ScrollFrame.Content:SetSize(775, 600)
  frame.ScrollFrame.Content:SetPoint("TOPLEFT", frame.ScrollFrame, "TOPRIGHT", 0, 0) 
  frame.ScrollFrame.Content:SetPoint("BOTTOMLEFT", frame.ScrollFrame, "BOTTOMRIGHT", 0, 0)
  frame.ScrollFrame:SetScrollChild(frame.ScrollFrame.Content)
  
  -- Buttons
  frame.ScrollFrame.Content.EventsBtn = CreateFrame("Button", nil, frame.ScrollFrame.Content, "UIPanelButtonTemplate");
  frame.ScrollFrame.Content.EventsBtn:SetPoint("CENTER", frame.ScrollFrame.Content, "TOP", -225, -25);
  frame.ScrollFrame.Content.EventsBtn:SetSize(140, 40);
  frame.ScrollFrame.Content.EventsBtn:SetText("Events");
  frame.ScrollFrame.Content.EventsBtn:SetNormalFontObject("GameFontNormalLarge");
  frame.ScrollFrame.Content.EventsBtn:SetHighlightFontObject("GameFontHighlightLarge");
  frame.ScrollFrame.Content.EventsBtn:SetScript("OnClick", 
    function(self)
      AutoBiographer_EventWindow:Toggle()
    end
  )

  frame.ScrollFrame.Content.StatisticsBtn = CreateFrame("Button", nil, frame.ScrollFrame.Content, "UIPanelButtonTemplate");
  frame.ScrollFrame.Content.StatisticsBtn:SetPoint("CENTER", frame.ScrollFrame.Content, "TOP", -75, -25);
  frame.ScrollFrame.Content.StatisticsBtn:SetSize(140, 40);
  frame.ScrollFrame.Content.StatisticsBtn:SetText("Statistics");
  frame.ScrollFrame.Content.StatisticsBtn:SetNormalFontObject("GameFontNormalLarge");
  frame.ScrollFrame.Content.StatisticsBtn:SetHighlightFontObject("GameFontHighlightLarge");
  frame.ScrollFrame.Content.StatisticsBtn:SetScript("OnClick", 
    function(self)
      AutoBiographer_StatisticsWindow:Toggle()
    end
  )
  
  frame.ScrollFrame.Content.OptionsBtn = CreateFrame("Button", nil, frame.ScrollFrame.Content, "UIPanelButtonTemplate");
  frame.ScrollFrame.Content.OptionsBtn:SetPoint("CENTER", frame.ScrollFrame.Content, "TOP", 75, -25);
  frame.ScrollFrame.Content.OptionsBtn:SetSize(140, 40);
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
  frame.ScrollFrame.Content.DebugBtn:SetPoint("CENTER", frame.ScrollFrame.Content, "TOP", 225, -25);
  frame.ScrollFrame.Content.DebugBtn:SetSize(140, 40);
  frame.ScrollFrame.Content.DebugBtn:SetText("Debug");
  frame.ScrollFrame.Content.DebugBtn:SetNormalFontObject("GameFontNormalLarge");
  frame.ScrollFrame.Content.DebugBtn:SetHighlightFontObject("GameFontHighlightLarge");
  frame.ScrollFrame.Content.DebugBtn:SetScript("OnClick", 
    function(self)
      AutoBiographer_DebugWindow:Toggle()
    end
  )
  
  -- Header
  frame.ScrollFrame.Content.TimePlayedThisLevelFS = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.TimePlayedThisLevelFS:SetPoint("LEFT", frame.ScrollFrame.Content, "TOP", 50, -65)

  -- Battleground Stats
  local topPoint = -75
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

  frame.ScrollFrame.Content.WsgStatsFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.WsgStatsFs:SetPoint("TOPLEFT", 10, topPoint)
  topPoint = topPoint - 15

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

  -- Experience Stats
  topPoint = topPoint - 15
  frame.ScrollFrame.Content.ExperienceHeaderFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  frame.ScrollFrame.Content.ExperienceHeaderFs:SetPoint("TOPLEFT", 10, topPoint)
  frame.ScrollFrame.Content.ExperienceHeaderFs:SetText("Experience")
  topPoint = topPoint - 20

  frame.ScrollFrame.Content.ExperienceFromKillsFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.ExperienceFromKillsFs:SetPoint("TOPLEFT", 10, topPoint)
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

  frame.ScrollFrame.Content.ItemsCreatedFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.ItemsCreatedFs:SetPoint("TOPLEFT", 10, topPoint)
  topPoint = topPoint - 15

  frame.ScrollFrame.Content.ItemsLootedFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.ItemsLootedFs:SetPoint("TOPLEFT", 10, topPoint)
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

  frame.ScrollFrame.Content.TaggedKillingBlowsFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.TaggedKillingBlowsFs:SetPoint("TOPLEFT", 10, topPoint)
  topPoint = topPoint - 15

  frame.ScrollFrame.Content.OtherTaggedKillsFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.OtherTaggedKillsFs:SetPoint("TOPLEFT", 10, topPoint)
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

  -- Other Player Stats
  topPoint = topPoint - 15
  frame.ScrollFrame.Content.OtherPlayerHeaderFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  frame.ScrollFrame.Content.OtherPlayerHeaderFs:SetPoint("TOPLEFT", 10, topPoint)
  frame.ScrollFrame.Content.OtherPlayerHeaderFs:SetText("Other Player")
  topPoint = topPoint - 20

  frame.ScrollFrame.Content.DuelsWonFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.DuelsWonFs:SetPoint("TOPLEFT", 10, topPoint)
  topPoint = topPoint - 15

  frame.ScrollFrame.Content.DuelsLostFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.DuelsLostFs:SetPoint("TOPLEFT", 10, topPoint)
  topPoint = topPoint - 15

  -- Spell Stats
  topPoint = topPoint - 15
  frame.ScrollFrame.Content.SpellsHeaderFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  frame.ScrollFrame.Content.SpellsHeaderFs:SetPoint("TOPLEFT", 10, topPoint)
  frame.ScrollFrame.Content.SpellsHeaderFs:SetText("Spells")
  topPoint = topPoint - 20

  frame.ScrollFrame.Content.SpellsStartedCastingFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.SpellsStartedCastingFs:SetPoint("TOPLEFT", 10, topPoint)
  topPoint = topPoint - 15

  frame.ScrollFrame.Content.SpellsSuccessfullyCastFs = frame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ScrollFrame.Content.SpellsSuccessfullyCastFs:SetPoint("TOPLEFT", 10, topPoint)
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
  frame:SetSize(750, 585) 
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
      local sliderMin, sliderMax = frame.SubFrame.ScrollFrame.Scrollbar:GetMinMaxValues()
      frame.SubFrame.ScrollFrame.Scrollbar:SetValue(sliderMax)
    elseif (key == "HOME") then
      frame:SetPropagateKeyboardInput(false)
      local sliderMin, sliderMax = frame.SubFrame.ScrollFrame.Scrollbar:GetMinMaxValues()
      frame.SubFrame.ScrollFrame.Scrollbar:SetValue(sliderMin)
    elseif (key == "PAGEDOWN") then
      frame:SetPropagateKeyboardInput(false)
      local sliderMin, sliderMax = frame.SubFrame.ScrollFrame.Scrollbar:GetMinMaxValues()
      local sliderCurrentValue = frame.SubFrame.ScrollFrame.Scrollbar:GetValue()

      local sliderNextValue = sliderCurrentValue + frame.SubFrame.ScrollFrame:GetHeight()

      if (sliderNextValue > sliderMax) then
        sliderNextValue = sliderMax
      elseif (sliderNextValue < sliderMin) then
        sliderNextValue = sliderMin
      end

      frame.SubFrame.ScrollFrame.Scrollbar:SetValue(sliderNextValue)
    elseif (key == "PAGEUP") then
      frame:SetPropagateKeyboardInput(false)
      local sliderMin, sliderMax = frame.SubFrame.ScrollFrame.Scrollbar:GetMinMaxValues()
      local sliderCurrentValue = frame.SubFrame.ScrollFrame.Scrollbar:GetValue()

      local sliderNextValue = sliderCurrentValue - frame.SubFrame.ScrollFrame:GetHeight()

      if (sliderNextValue > sliderMax) then
        sliderNextValue = sliderMax
      elseif (sliderNextValue < sliderMin) then
        sliderNextValue = sliderMin
      end

      frame.SubFrame.ScrollFrame.Scrollbar:SetValue(sliderNextValue)
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
    local sliderMin, sliderMax = frame.SubFrame.ScrollFrame.Scrollbar:GetMinMaxValues()
    local sliderCurrentValue = frame.SubFrame.ScrollFrame.Scrollbar:GetValue()

    local sliderNextValue = sliderCurrentValue - (frame.SubFrame.ScrollFrame.Scrollbar.scrollStep * direction)

    if (sliderNextValue > sliderMax) then
      sliderNextValue = sliderMax
    elseif (sliderNextValue < sliderMin) then
      sliderNextValue = sliderMin
    end

    frame.SubFrame.ScrollFrame.Scrollbar:SetValue(sliderNextValue)
  end)

  frame.Title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.Title:SetPoint("LEFT", frame.TitleBg, "LEFT", 5, 0);
  frame.Title:SetText("AutoBiographer Event Window")
  
  frame.SubFrame = CreateFrame("Frame", "AutoBiographerEventSub", frame)
  frame.SubFrame:SetPoint("TOPLEFT", 10, -25) 
  frame.SubFrame:SetPoint("BOTTOMRIGHT", -10, 10) 
  
  -- Dropdown
  frame.SubFrame.Dropdown = CreateFrame("Frame", nil, frame.SubFrame, "UIDropDownMenuTemplate")
  frame.SubFrame.Dropdown:SetSize(100, 25)
  frame.SubFrame.Dropdown:SetPoint("LEFT", frame.SubFrame, "TOP", -frame.SubFrame.Dropdown:GetWidth(), -15)

  if (not frame.DropdownText) then frame.DropdownText = "Kill Statistics" end
  if (not frame.StatisticsDisplayMode) then frame.StatisticsDisplayMode = AutoBiographerEnum.StatisticsDisplayMode.Kills end
  
  UIDropDownMenu_Initialize(frame.SubFrame.Dropdown, function(frame, level, menuList)
    local info = UIDropDownMenu_CreateInfo()
    info.func = function(frame, arg1, arg2, checked)
      AutoBiographer_StatisticsWindow.DropdownText = frame.value   
      AutoBiographer_StatisticsWindow.StatisticsDisplayMode = arg1
      AutoBiographer_StatisticsWindow:Update()
    end
  
    info.text, info.arg1 = "Kill Statistics", AutoBiographerEnum.StatisticsDisplayMode.Kills
    UIDropDownMenu_AddButton(info)
    info.text, info.arg1 = "Other Player Statistics", AutoBiographerEnum.StatisticsDisplayMode.OtherPlayers
    UIDropDownMenu_AddButton(info)
  end)
  
  UIDropDownMenu_SetText(frame.SubFrame.Dropdown, frame.DropdownText)

  -- Table Headers
  frame.SubFrame.TableHeaders = {}

  self.SubFrame.OrderColumnIndex = 1
  self.SubFrame.OrderDirection = "ASC"

  --scrollframe 
  frame.SubFrame.ScrollFrame = CreateFrame("ScrollFrame", nil, frame.SubFrame) 
  frame.SubFrame.ScrollFrame:SetPoint("TOPLEFT", 10, -65) 
  frame.SubFrame.ScrollFrame:SetPoint("BOTTOMRIGHT", -10, 10) 

  --scrollbar 
  frame.SubFrame.ScrollFrame.Scrollbar = CreateFrame("Slider", nil, frame.SubFrame.ScrollFrame, "UIPanelScrollBarTemplate")
  frame.SubFrame.ScrollFrame.Scrollbar:SetPoint("TOPLEFT", frame.SubFrame, "TOPRIGHT", -15, -17)
  frame.SubFrame.ScrollFrame.Scrollbar:SetPoint("BOTTOMLEFT", frame.SubFrame, "BOTTOMRIGHT", -15, 12)
  frame.SubFrame.ScrollFrame.Scrollbar:SetMinMaxValues(1, 1)
  frame.SubFrame.ScrollFrame.Scrollbar:SetValueStep(1)
  frame.SubFrame.ScrollFrame.Scrollbar.scrollStep = 15
  frame.SubFrame.ScrollFrame.Scrollbar:SetValue(0)
  frame.SubFrame.ScrollFrame.Scrollbar:SetWidth(16)
  frame.SubFrame.ScrollFrame.Scrollbar:SetScript("OnValueChanged",
    function (self, value) 
      self:GetParent():SetVerticalScroll(value) 
    end
  ) 
  local scrollbg = frame.SubFrame.ScrollFrame.Scrollbar:CreateTexture(nil, "BACKGROUND") 
  scrollbg:SetAllPoints(frame.SubFrame.ScrollFrame.Scrollbar) 
  scrollbg:SetTexture(0, 0, 0, 0.4) 

  --content frame
  frame.SubFrame.ScrollFrame.Content = CreateFrame("Frame", nil, frame.SubFrame.ScrollFrame)
  frame.SubFrame.ScrollFrame.Content:SetSize(1, 1)
  frame.SubFrame.ScrollFrame.Content.FontStringsPool = {
    Allocated = {},
    UnAllocated = {},
  }
  frame.SubFrame.ScrollFrame:SetScrollChild(frame.SubFrame.ScrollFrame.Content)

  frame.Toggle = function(self)
    if (self:IsVisible()) then
      self:Hide()
    else
      self:Update()
      self:Show()
      self:SetFrameLevel(200)
    end
  end

  frame:Hide()
  return frame
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
  for i = 1, #self.SubFrame.ScrollFrame.Content.FontStringsPool.Allocated, 1 do
    local fs = self.SubFrame.ScrollFrame.Content.FontStringsPool.Allocated[i]
    fs:Hide()
    fs:SetText("")
    table.insert(self.SubFrame.ScrollFrame.Content.FontStringsPool.UnAllocated, fs)
  end
  self.SubFrame.ScrollFrame.Content.FontStringsPool.Allocated = {}

  local events = Controller:GetEvents()

  for i = 1, #events, 1 do
    if (AutoBiographer_Settings.EventDisplayFilters[events[i].SubType]) then
      local fs = table.remove(self.SubFrame.ScrollFrame.Content.FontStringsPool.UnAllocated)
      if (not fs) then
        fs = self.SubFrame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      end
      
      fs:SetPoint("TOPLEFT", 5, -15 * #self.SubFrame.ScrollFrame.Content.FontStringsPool.Allocated) 
      fs:SetText(Controller:GetEventString(events[i]))
      fs:Show()
      table.insert(self.SubFrame.ScrollFrame.Content.FontStringsPool.Allocated, fs)
    end
  end
  
  local scrollbarMaxValue = (#self.SubFrame.ScrollFrame.Content.FontStringsPool.Allocated * 15) - self.SubFrame.ScrollFrame:GetHeight();
  if (scrollbarMaxValue <= 0) then scrollbarMaxValue = 1 end
  self.SubFrame.ScrollFrame.Scrollbar:SetMinMaxValues(1, scrollbarMaxValue)
  self.SubFrame.ScrollFrame.Scrollbar:SetValue(scrollbarMaxValue)
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
        
        for i = 0, 5 do
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
  end
  
  -- Battleground Stats
  local avJoined, avLosses, avWins = Controller:GetBattlegroundStatsByBattlegroundId(1, self.DisplayMinLevel, self.DisplayMaxLevel)
  local avStatsText = "Alterac Valley - Wins: " .. HF.CommaValue(avWins) .. ". Losses: " .. HF.CommaValue(avLosses) .. ". Incomplete: " .. HF.CommaValue(avJoined - avLosses - avWins) .. "."
  self.ScrollFrame.Content.AvStatsFs:SetText(avStatsText)

  local abJoined, abLosses, abWins = Controller:GetBattlegroundStatsByBattlegroundId(3, self.DisplayMinLevel, self.DisplayMaxLevel)
  local abStatsText = "Arathi Basin - Wins: " .. HF.CommaValue(abWins) .. ". Losses: " .. HF.CommaValue(abLosses) .. ". Incomplete: " .. HF.CommaValue(abJoined - abLosses - abWins) .. "."
  self.ScrollFrame.Content.AbStatsFs:SetText(abStatsText)

  local wsgJoined, wsgLosses, wsgWins = Controller:GetBattlegroundStatsByBattlegroundId(2, self.DisplayMinLevel, self.DisplayMaxLevel)
  local wsgStatsText = "Warsong Gulch - Wins: " .. HF.CommaValue(wsgWins) .. ". Losses: " .. HF.CommaValue(wsgLosses) .. ". Incomplete: " .. HF.CommaValue(wsgJoined - wsgLosses - wsgWins) .. "."
  self.ScrollFrame.Content.WsgStatsFs:SetText(wsgStatsText)

  -- Damage Stats
  local damageDealtAmount, damageDealtOver = Controller:GetDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.DamageDealt, self.DisplayMinLevel, self.DisplayMaxLevel)
  local petDamageDealtAmount, petDamageDealtOver = Controller:GetDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.PetDamageDealt, self.DisplayMinLevel, self.DisplayMaxLevel)
  local damageDealtText = "Damage Dealt: " .. HF.CommaValue(damageDealtAmount) .. " (" .. HF.CommaValue(damageDealtOver) .. " over)."
  if (petDamageDealtAmount > 0) then damageDealtText = damageDealtText .. " Pet Damage Dealt: " .. tostring(petDamageDealtAmount) .. " (" .. tostring(petDamageDealtOver) .. " over)." end
  self.ScrollFrame.Content.DamageDealtFs:SetText(damageDealtText)
  
  local damageTakenAmount, damageTakenOver = Controller:GetDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.DamageTaken, self.DisplayMinLevel, self.DisplayMaxLevel)
  local petDamageTakenAmount, petDamageTakenOver = Controller:GetDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.PetDamageTaken, self.DisplayMinLevel, self.DisplayMaxLevel)
  local damageTakenText = "Damage Taken: " .. HF.CommaValue(damageTakenAmount) .. " (" .. HF.CommaValue(damageTakenOver) .. " over)."
  if (petDamageTakenAmount > 0) then damageTakenText = damageTakenText .. " Pet Damage Taken: " .. HF.CommaValue(petDamageTakenAmount) .. " (" .. HF.CommaValue(petDamageTakenOver) .. " over)." end
  self.ScrollFrame.Content.DamageTakenFs:SetText(damageTakenText)
  
  local healingOtherAmount, healingOtherOver = Controller:GetDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.HealingDealtToOthers, self.DisplayMinLevel, self.DisplayMaxLevel)
  self.ScrollFrame.Content.HealingOtherFs:SetText("Healing Dealt to Others: " .. HF.CommaValue(healingOtherAmount) .. " (" .. HF.CommaValue(healingOtherOver) .. " over).")
  
  local healingSelfAmount, healingSelfOver = Controller:GetDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.HealingDealtToSelf, self.DisplayMinLevel, self.DisplayMaxLevel)
  self.ScrollFrame.Content.HealingSelfFs:SetText("Healing Dealt to Self: " .. HF.CommaValue(healingSelfAmount) .. " (" .. HF.CommaValue(healingSelfOver) .. " over).")
  
  local healingTakenAmount, healingTakenOver = Controller:GetDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.HealingTaken, self.DisplayMinLevel, self.DisplayMaxLevel)
  self.ScrollFrame.Content.HealingTakenFs:SetText("Healing Taken: " .. HF.CommaValue(healingTakenAmount) .. " (" .. HF.CommaValue(healingTakenOver) .. " over).")
  
  -- Death Stats
  local deathsToCreatures = Controller:GetDeathsByDeathTrackingType(AutoBiographerEnum.DeathTrackingType.DeathToCreature, self.DisplayMinLevel, self.DisplayMaxLevel)
  local deathsToEnvironment = Controller:GetDeathsByDeathTrackingType(AutoBiographerEnum.DeathTrackingType.DeathToEnvironment, self.DisplayMinLevel, self.DisplayMaxLevel)
  local deathsToGameObjects = Controller:GetDeathsByDeathTrackingType(AutoBiographerEnum.DeathTrackingType.DeathToGameObject, self.DisplayMinLevel, self.DisplayMaxLevel)
  local deathsToPets = Controller:GetDeathsByDeathTrackingType(AutoBiographerEnum.DeathTrackingType.DeathToPet, self.DisplayMinLevel, self.DisplayMaxLevel)
  local deathsToPlayers = Controller:GetDeathsByDeathTrackingType(AutoBiographerEnum.DeathTrackingType.DeathToPlayer, self.DisplayMinLevel, self.DisplayMaxLevel)
  local totalDeaths = deathsToCreatures + deathsToEnvironment + deathsToGameObjects + deathsToPets + deathsToPlayers
  self.ScrollFrame.Content.TotalDeathsFs:SetText("Total Deaths: " .. HF.CommaValue(totalDeaths) .. ".")
  self.ScrollFrame.Content.DeathsToCreaturesFs:SetText("Deaths to Creatures: " .. HF.CommaValue(deathsToCreatures) .. ".")
  self.ScrollFrame.Content.DeathsToEnvironmentFs:SetText("Deaths to Environment: " .. HF.CommaValue(deathsToEnvironment) .. ".")
  self.ScrollFrame.Content.DeathsToGameObjectsFs:SetText("Deaths to Game Objects: " .. HF.CommaValue(deathsToGameObjects) .. ".")
  self.ScrollFrame.Content.DeathsToPetsFs:SetText("Deaths to Pets: " .. HF.CommaValue(deathsToPets) .. ".")
  self.ScrollFrame.Content.DeathsToPlayersFs:SetText("Deaths to Players: " .. HF.CommaValue(deathsToPlayers) .. ".")

  -- Experience Stats
  local experienceFromKills = Controller:GetExperienceByExperienceTrackingType(AutoBiographerEnum.ExperienceTrackingType.Kill, self.DisplayMinLevel, self.DisplayMaxLevel)
  self.ScrollFrame.Content.ExperienceFromKillsFs:SetText("Experience From Kills: " .. HF.CommaValue(experienceFromKills) .. ".")
      
  local experienceFromRestedBonus = Controller:GetExperienceByExperienceTrackingType(AutoBiographerEnum.ExperienceTrackingType.RestedBonus, self.DisplayMinLevel, self.DisplayMaxLevel)
  self.ScrollFrame.Content.ExperienceFromRestedBonusFs:SetText("Experience From Rested Bonus: " .. HF.CommaValue(experienceFromRestedBonus) .. ".")
  
  local experienceFromGroupBonus = Controller:GetExperienceByExperienceTrackingType(AutoBiographerEnum.ExperienceTrackingType.GroupBonus, self.DisplayMinLevel, self.DisplayMaxLevel)
  self.ScrollFrame.Content.ExperienceFromGroupBonusFs:SetText("Experience From Group Bonus: " .. HF.CommaValue(experienceFromGroupBonus) .. ".")
  
  local experienceLostToRaidPenalty = Controller:GetExperienceByExperienceTrackingType(AutoBiographerEnum.ExperienceTrackingType.RaidPenalty, self.DisplayMinLevel, self.DisplayMaxLevel)
  self.ScrollFrame.Content.ExperienceLostToRaidPenaltyFs:SetText("Experience Lost To Raid Penalty: " .. HF.CommaValue(experienceLostToRaidPenalty) .. ".")
  
  local experienceFromQuests = Controller:GetExperienceByExperienceTrackingType(AutoBiographerEnum.ExperienceTrackingType.Quest, self.DisplayMinLevel, self.DisplayMaxLevel)
  self.ScrollFrame.Content.ExperienceFromQuestsFs:SetText("Experience From Quests: " .. HF.CommaValue(experienceFromQuests) .. ".")
  
  local experienceFromDiscovery = Controller:GetExperienceByExperienceTrackingType(AutoBiographerEnum.ExperienceTrackingType.Discovery, self.DisplayMinLevel, self.DisplayMaxLevel)
  self.ScrollFrame.Content.ExperienceFromDiscoveryFs:SetText("Experience From Discovery: " .. HF.CommaValue(experienceFromDiscovery) .. ".")
  
  -- Item Stats
  local itemsCreated = Controller:GetItemCountForAcquisitionMethod(AutoBiographerEnum.ItemAcquisitionMethod.Create, self.DisplayMinLevel, self.DisplayMaxLevel)
  self.ScrollFrame.Content.ItemsCreatedFs:SetText("Items Created: " .. HF.CommaValue(itemsCreated) .. ".")
  
  local itemsLooted = Controller:GetItemCountForAcquisitionMethod(AutoBiographerEnum.ItemAcquisitionMethod.Loot, self.DisplayMinLevel, self.DisplayMaxLevel)
  self.ScrollFrame.Content.ItemsLootedFs:SetText("Items Looted: " .. HF.CommaValue(itemsLooted) .. ".")
  
  local itemsOther = Controller:GetItemCountForAcquisitionMethod(AutoBiographerEnum.ItemAcquisitionMethod.Other, self.DisplayMinLevel, self.DisplayMaxLevel)
  self.ScrollFrame.Content.ItemsOtherFs:SetText("Items Acquired By Other Means: " .. HF.CommaValue(itemsOther) .. ".")
  
  -- Kill Stats
  local totalsKillStatistics = Controller:GetAggregatedKillStatisticsTotals(self.DisplayMinLevel, self.DisplayMaxLevel)
  local taggedKillingBlows = KillStatistics.GetSum(totalsKillStatistics, { AutoBiographerEnum.KillTrackingType.TaggedKillingBlow })
  self.ScrollFrame.Content.TaggedKillingBlowsFs:SetText("Tagged Killing Blows: " .. HF.CommaValue(taggedKillingBlows) .. ".")
  
  local otherTaggedKills = KillStatistics.GetSum(totalsKillStatistics, { AutoBiographerEnum.KillTrackingType.TaggedAssist, AutoBiographerEnum.KillTrackingType.TaggedGroupAssistOrKillingBlow })
  self.ScrollFrame.Content.OtherTaggedKillsFs:SetText("Other Tagged Kills: " .. HF.CommaValue(otherTaggedKills) .. ".")

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
  
  -- Other Player Stats 
  local duelsWon = Controller:GetOtherPlayerStatByOtherPlayerTrackingType(AutoBiographerEnum.OtherPlayerTrackingType.DuelsLostToPlayer, self.DisplayMinLevel, self.DisplayMaxLevel)
  self.ScrollFrame.Content.DuelsWonFs:SetText("Duels Won: " .. HF.CommaValue(duelsWon) .. ".")
  
  local duelsLost = Controller:GetOtherPlayerStatByOtherPlayerTrackingType(AutoBiographerEnum.OtherPlayerTrackingType.DuelsWonAgainstPlayer, self.DisplayMinLevel, self.DisplayMaxLevel)
  self.ScrollFrame.Content.DuelsLostFs:SetText("Duels Lost: " .. HF.CommaValue(duelsLost) .. ".")
  
  -- Spell Stats
  local spellsStartedCasting = Controller:GetSpellCountBySpellTrackingType(AutoBiographerEnum.SpellTrackingType.StartedCasting, self.DisplayMinLevel, self.DisplayMaxLevel)
  self.ScrollFrame.Content.SpellsStartedCastingFs:SetText("Spells Started Casting: " .. HF.CommaValue(spellsStartedCasting) .. ".")
  
  local spellsSuccessfullyCast = Controller:GetSpellCountBySpellTrackingType(AutoBiographerEnum.SpellTrackingType.SuccessfullyCast, self.DisplayMinLevel, self.DisplayMaxLevel)
  self.ScrollFrame.Content.SpellsSuccessfullyCastFs:SetText("Spells Successfully Cast: " .. HF.CommaValue(spellsSuccessfullyCast) .. ".")
  
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
-- Statistics Window Update
--
--

function AutoBiographer_StatisticsWindow:Update()
  -- Get table data.
  local tableData
  
  if (self.StatisticsDisplayMode == AutoBiographerEnum.StatisticsDisplayMode.Kills) then
    local killStatisticsByUnit = Controller:GetAggregatedKillStatisticsDictionary(1, 9999)
    tableData = {
      HeaderValues = { "Unit Name", "Tagged Kills", "Tagged Assists", "Untagged Kills", "Untagged Assists" },
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
          KillStatistics.GetSum(killStatistics, { AutoBiographerEnum.KillTrackingType.TaggedAssist, AutoBiographerEnum.KillTrackingType.TaggedGroupAssistOrKillingBlow }),
          KillStatistics.GetSum(killStatistics, { AutoBiographerEnum.KillTrackingType.UntaggedKillingBlow }),
          KillStatistics.GetSum(killStatistics, { AutoBiographerEnum.KillTrackingType.UntaggedAssist, AutoBiographerEnum.KillTrackingType.UntaggedGroupAssistOrKillingBlow }),
        }
        table.insert(tableData.Rows, row)
      end
    end
  elseif (self.StatisticsDisplayMode == AutoBiographerEnum.StatisticsDisplayMode.OtherPlayers) then
    local otherPlayerStatisticsByUnit = Controller:GetAggregatedOtherPlayerStatisticsDictionary(1, 9999)
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
  else
    print("Unsupported Statistics Display Mode. This should not happen!")
    return
  end

  table.sort(tableData.Rows, function(rowA, rowB)
    if (self.SubFrame.OrderDirection == "ASC") then
      return rowA[self.SubFrame.OrderColumnIndex] < rowB[self.SubFrame.OrderColumnIndex]
    else
      return rowA[self.SubFrame.OrderColumnIndex] > rowB[self.SubFrame.OrderColumnIndex]
    end
  end)
  
  -- Setup table headers.
  for k, headerFrame in pairs(self.SubFrame.TableHeaders) do
    headerFrame:Hide()
  end
  
  for i = 1, #tableData.HeaderValues do
    header = CreateFrame("Button", nil, self.SubFrame, "UIPanelButtonTemplate");
    header:SetPoint("TOPLEFT", self.SubFrame, 25 + tableData.RowOffsets[i], -40);
    header:SetPoint("BOTTOMRIGHT", self.SubFrame, "TOPLEFT", 25 + tableData.RowOffsets[i + 1], -60);
    header:SetText(tableData.HeaderValues[i]);
    header:SetNormalFontObject("GameFontNormal");
    header:SetHighlightFontObject("GameFontHighlight");
    header:SetScript("OnClick", 
      function(self)
        if (AutoBiographer_StatisticsWindow.SubFrame.OrderColumnIndex == i) then
          if (AutoBiographer_StatisticsWindow.SubFrame.OrderDirection == "DESC") then
            AutoBiographer_StatisticsWindow.SubFrame.OrderDirection = "ASC"
          else
            AutoBiographer_StatisticsWindow.SubFrame.OrderDirection = "DESC"
          end
        else
          AutoBiographer_StatisticsWindow.SubFrame.OrderColumnIndex = i
          AutoBiographer_StatisticsWindow.SubFrame.OrderDirection = "DESC"
        end
        AutoBiographer_StatisticsWindow:Update()
      end
    )
    table.insert(self.SubFrame.TableHeaders, header)
  end

  -- Release previous table body font strings.
  for i = 1, #self.SubFrame.ScrollFrame.Content.FontStringsPool.Allocated, 1 do
    local fs = self.SubFrame.ScrollFrame.Content.FontStringsPool.Allocated[i]
    fs:Hide()
    fs:SetText("")
    table.insert(self.SubFrame.ScrollFrame.Content.FontStringsPool.UnAllocated, fs)
  end
  self.SubFrame.ScrollFrame.Content.FontStringsPool.Allocated = {}

  -- Setup table body.
  for i = 1, #tableData.Rows, 1 do
    for j = 1, #tableData.Rows[i], 1 do
      local fs = table.remove(self.SubFrame.ScrollFrame.Content.FontStringsPool.UnAllocated)
      if (not fs) then
        fs = self.SubFrame.ScrollFrame.Content:CreateFontString(nil, "OVERLAY")
      end
      
      if (i % 2 == 0) then
        fs:SetFontObject("GameFontNormal")
      else
        fs:SetFontObject("GameFontHighlight")
      end

      fs:SetPoint("TOPLEFT", self.SubFrame.ScrollFrame.Content, 17 + tableData.RowOffsets[j], -15 * (i - 1))
      fs:SetText(tableData.Rows[i][j])
      fs:Show()
      table.insert(self.SubFrame.ScrollFrame.Content.FontStringsPool.Allocated, fs)
    end
  end
  
  local scrollbarMaxValue = (#tableData.Rows * 15) - self.SubFrame.ScrollFrame:GetHeight();
  if (scrollbarMaxValue <= 0) then scrollbarMaxValue = 1 end
  self.SubFrame.ScrollFrame.Scrollbar:SetMinMaxValues(1, scrollbarMaxValue)
end