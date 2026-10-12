local Controller = AutoBiographer_Controller
local EM = AutoBiographer_EventManager
local HF = HelperFunctions
local Api = AutoBiographer_Api

AutoBiographer_MainWindow = CreateFrame("Frame", "AutoBiographerMain", UIParent, "BasicFrameTemplateWithInset")
AutoBiographer_MainWindow:SetFrameStrata("HIGH")
AutoBiographer_MainWindow:Hide()
AutoBiographer_SummaryPanel = CreateFrame("Frame", nil, AutoBiographer_MainWindow)
AutoBiographer_TodoPanel = CreateFrame("Frame", nil, AutoBiographer_MainWindow)

AutoBiographer_CustomEventDetailsWindow = CreateFrame("Frame", "AutoBiographerCustomEventDetail", AutoBiographer_MainWindow, "BasicFrameTemplate")
AutoBiographer_DebugWindow = CreateFrame("Frame", "AutoBiographerDebug", AutoBiographer_MainWindow, "BasicFrameTemplate")
AutoBiographer_EventWindow = CreateFrame("Frame", "AutoBiographerEvent", AutoBiographer_MainWindow)
AutoBiographer_GearPanel = CreateFrame("Frame", nil, AutoBiographer_MainWindow)
AutoBiographer_SnapshotPanel = CreateFrame("Frame", nil, AutoBiographer_MainWindow)
AutoBiographer_NotesWindow = CreateFrame("Frame", "AutoBiographerNotes", AutoBiographer_MainWindow)
AutoBiographer_StatisticsWindow = CreateFrame("Frame", "AutoBiographerStatistics", AutoBiographer_MainWindow)
AutoBiographer_VerificationWindow = CreateFrame("Frame", "AutoBiographerVerification", AutoBiographer_MainWindow, "BasicFrameTemplate")

for section, panel in pairs({ Summary = AutoBiographer_SummaryPanel, Todos = AutoBiographer_TodoPanel, Events = AutoBiographer_EventWindow, GearHistory = AutoBiographer_GearPanel, Snapshots = AutoBiographer_SnapshotPanel,
  Statistics = AutoBiographer_StatisticsWindow, Notes = AutoBiographer_NotesWindow }) do
  panel.IsEmbeddedPanel = true
  panel.SectionName = section
  panel:Hide()
end

--
--
-- Window Initialization Helper
--
--
AutioBiographer_WindowHelper = {}
function AutioBiographer_WindowHelper:CreateTab(parent, text, width, onClick)
  local tab = CreateFrame("Button", nil, parent)
  tab:SetSize(width, 28)
  -- Keep the standard red button fill and bevels. The selected tab is taller
  -- and omits the bottom bevel so it joins the panel rather than floating above it.
  local function CreateArtwork(selected)
    local height = selected and 28 or 24
    local topOffset = selected and 0 or -4
    local bottom = selected and 0.59375 or 0.6875
    -- Anchor every slice to the same top edge instead of chaining their centers.
    local left = tab:CreateTexture(nil, "BORDER")
    left:SetSize(12, height)
    left:SetPoint("TOPLEFT", tab, "TOPLEFT", 0, topOffset)
    left:SetTexCoord(0, 0.09375, 0, bottom)
    local middle = tab:CreateTexture(nil, "BORDER")
    middle:SetSize(math.max(1, width - 24), height)
    middle:SetPoint("TOPLEFT", tab, "TOPLEFT", 12, topOffset)
    middle:SetTexCoord(0.09375, 0.53125, 0, bottom)
    local right = tab:CreateTexture(nil, "BORDER")
    right:SetSize(12, height)
    right:SetPoint("TOPRIGHT", tab, "TOPRIGHT", 0, topOffset)
    right:SetTexCoord(0.53125, 0.625, 0, bottom)
    for _, texture in ipairs({ left, middle, right }) do
      texture:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up")
    end
    return { left, middle, right }
  end
  tab.ActiveArtwork = CreateArtwork(true)
  tab.InactiveArtwork = CreateArtwork(false)
  tab.Label = tab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  tab.Label:SetWordWrap(false)
  tab:SetFontString(tab.Label)
  tab:SetNormalFontObject("GameFontNormalSmall")
  tab:SetHighlightFontObject("GameFontHighlightSmall")
  tab:SetDisabledFontObject("GameFontHighlightSmall")
  tab:SetText(text)
  tab.Hover = tab:CreateTexture(nil, "HIGHLIGHT")
  tab.Hover:SetTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
  tab.Hover:SetTexCoord(0, 0.625, 0, 0.6875)
  tab.Hover:SetBlendMode("ADD")
  tab.Hover:SetPoint("TOPLEFT", 0, -4)
  tab.Hover:SetPoint("BOTTOMRIGHT")
  tab:SetHighlightTexture(tab.Hover)
  function tab:SetTabWidth(value)
    self:SetWidth(value)
    self.ActiveArtwork[2]:SetWidth(math.max(1, value - 24))
    self.InactiveArtwork[2]:SetWidth(math.max(1, value - 24))
    self.Label:SetWidth(math.max(1, value - 24))
  end
  local function SetPressed(self, pressed)
    for _, texture in ipairs(self.InactiveArtwork) do
      texture:SetTexture(pressed and "Interface\\Buttons\\UI-Panel-Button-Down" or "Interface\\Buttons\\UI-Panel-Button-Up")
    end
  end
  function tab:SetSelected(selected)
    self.Selected = selected
    SetPressed(self, false)
    for _, texture in ipairs(self.ActiveArtwork) do texture:SetShown(selected) end
    for _, texture in ipairs(self.InactiveArtwork) do texture:SetShown(not selected) end
    if (selected) then self:Disable() else self:Enable() end
    self.Label:ClearAllPoints()
    self.Label:SetPoint("CENTER", 0, selected and 0 or -2)
  end
  tab:SetTabWidth(width)
  tab:SetSelected(false)
  tab:SetScript("OnClick", onClick)
  tab:SetScript("OnMouseDown", function(self) if (not self.Selected) then SetPressed(self, true) end end)
  tab:SetScript("OnMouseUp", function(self) SetPressed(self, false) end)
  tab:SetScript("OnHide", function(self) SetPressed(self, false) end)
  return tab
end

function AutioBiographer_WindowHelper:InitialzationHelper(window, width, height, frameLevel, windowTitle, scrollFrameYOffset)
  local frame = window
  frame:SetSize(width, height) 
  if (not frame.IsEmbeddedPanel) then frame:SetPoint("CENTER") end

  frame:EnableKeyboard(not frame.IsEmbeddedPanel)
  frame:EnableMouse(true)
  frame:SetMovable(not frame.IsEmbeddedPanel)

  frame:SetScript("OnHide", function(self)
    if (self.isMoving) then
      self:StopMovingOrSizing()
      self.isMoving = false
    end
  end)

  frame:SetScript("OnKeyDown", function(self, key)
    if (key == "ESCAPE") then
      frame:SetPropagateKeyboardInput(false)
      if (frame.IsEmbeddedPanel) then AutoBiographer_MainWindow:Hide()
      else frame:Hide() end
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
    if (not self.IsEmbeddedPanel and button == "LeftButton" and not self.isMoving) then
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
    if (self.IsEmbeddedPanel) then
      AutoBiographer_MainWindow:ShowSection(self.SectionName)
    elseif (self:IsVisible()) then
      self:Hide()
    else
      self:Update()
      self:Show()
      self:SetFrameLevel(frameLevel)
    end
  end

  frame.Title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  if (frame.IsEmbeddedPanel) then
    frame.Title:Hide()
    frame:SetScript("OnShow", function(panel)
      if (panel.PanelReady) then panel:Update() end
    end)
  else
    frame.Title:SetPoint("LEFT", frame.TitleBg, "LEFT", 5, 0)
  end
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
  scrollbg:SetAllPoints(frame.ScrollFrame.Scrollbar)
  scrollbg:SetColorTexture(0, 0, 0, 0.4)

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
