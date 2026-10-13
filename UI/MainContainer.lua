local Api = AutoBiographer_Api
local sections = { "Summary", "Events", "Statistics", "Snapshots", "GearHistory", "Notes", "Todos" }
local sectionLabels = { GearHistory = "Gear History", Statistics = "Statistic Details", Todos = "Tasks" }
local minimumButtonWidths = { Summary = 72, Events = 60, Statistics = 110, GearHistory = 92, Snapshots = 84, Notes = 58, Todos = 58 }
local preferredButtonWidths = { Statistics = 120 }

local function CreateNavigationButton(parent, text, width, onClick)
  local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  button:SetSize(width, 26)
  button:SetText(text)
  button:SetNormalFontObject("GameFontNormalSmall")
  button:SetHighlightFontObject("GameFontHighlightSmall")
  button:SetScript("OnClick", onClick)
  return button
end

function AutoBiographer_MainWindow:FitToScreen()
  local availableWidth = math.max(1, UIParent:GetWidth() - 24)
  local availableHeight = math.max(1, UIParent:GetHeight() - 24)
  local scale = math.min(1, availableWidth / 1000, availableHeight / 800)
  self:SetScale(scale)
  local maxWidth, maxHeight = availableWidth / scale, availableHeight / scale
  Api.SetFrameResizeBounds(self, 1000, 800, maxWidth, maxHeight)
  local geometry = AutoBiographer_Settings.MainWindowGeometry or {}
  self:SetSize(math.max(1000, math.min(maxWidth, geometry.Width or 1200)),
    math.max(800, math.min(maxHeight, geometry.Height or 1000)))
end

function AutoBiographer_MainWindow:Initialize()
  self:SetFrameLevel(100)
  self:SetMovable(true)
  self:SetResizable(true)
  self:SetClampedToScreen(true)
  self:EnableMouse(true)
  self:EnableKeyboard(true)
  self.Title = self:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  self.Title:SetPoint("LEFT", self.TitleBg, "LEFT", 8, 0)
  self.Title:SetText("AutoBiographer")

  self.PanelHost = CreateFrame("Frame", nil, self)
  self.PanelHost:SetPoint("TOPLEFT", 10, -74)
  self.PanelHost:SetPoint("BOTTOMRIGHT", -10, 12)
  self.Panels = {
    Summary = AutoBiographer_SummaryPanel,
    Events = AutoBiographer_EventWindow,
    Statistics = AutoBiographer_StatisticsWindow,
    GearHistory = AutoBiographer_GearPanel,
    Snapshots = AutoBiographer_SnapshotPanel,
    Notes = AutoBiographer_NotesWindow,
    Todos = AutoBiographer_TodoPanel,
  }
  AutoBiographer_SummaryPanel:Initialize()
  for _, panel in pairs(self.Panels) do
    panel:SetParent(self.PanelHost)
    panel:ClearAllPoints()
    panel:SetAllPoints(self.PanelHost)
    panel:SetFrameLevel(self.PanelHost:GetFrameLevel() + 1)
    panel:SetScript("OnSizeChanged", function() self:QueuePanelLayout() end)
    panel:Hide()
  end

  self.SectionButtons = {}
  -- Keep the divider subdued like the window's metal border.
  self.PageEdge = self:CreateTexture(nil, "ARTWORK")
  self.PageEdge:SetPoint("TOPLEFT", 18, -69)
  self.PageEdge:SetPoint("TOPRIGHT", -22, -69)
  self.PageEdge:SetHeight(1)
  self.PageEdge:SetColorTexture(0.45, 0.42, 0.36, 0.7)
  for i, name in ipairs(sections) do
    local button = AutioBiographer_WindowHelper:CreateTab(self, sectionLabels[name] or name, preferredButtonWidths[name] or 100, function() self:ShowSection(name) end)
    button:SetPoint("TOPLEFT", 18 + (i - 1) * 106, -41)
    self.SectionButtons[name] = button
  end
  self.OptionsButton = CreateNavigationButton(self, "Options", 80, function()
    Settings.OpenToCategory(AutoBiographer_OptionWindow.categoryID)
    self:Hide()
  end)
  self.OptionsButton:SetPoint("TOPRIGHT", -108, -39)
  self.DebugButton = CreateNavigationButton(self, "Debug", 80, function() AutoBiographer_DebugWindow:Toggle() end)
  self.DebugButton:SetPoint("TOPRIGHT", -22, -39)

  self.ResizeGrip = CreateFrame("Button", nil, self)
  self.ResizeGrip:SetSize(16, 16)
  self.ResizeGrip:SetPoint("BOTTOMRIGHT", -2, 2)
  self.ResizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
  self.ResizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
  self.ResizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
  self.ResizeGrip:SetScript("OnMouseDown", function(_, button)
    if (button == "LeftButton") then self.IsResizing = true; self:StartSizing("BOTTOMRIGHT") end
  end)
  self.ResizeGrip:SetScript("OnMouseUp", function()
    self:StopMovingOrSizing()
    self.IsResizing = false
    self:LayoutPanels()
    self:SaveGeometry()
  end)
  self:SetScript("OnMouseDown", function(_, button)
    if (button == "LeftButton") then self.IsMoving = true; self:StartMoving() end
  end)
  self:SetScript("OnMouseUp", function()
    if (self.IsMoving) then self:StopMovingOrSizing(); self.IsMoving = false; self:SaveGeometry() end
  end)
  self:SetScript("OnKeyDown", function(_, key)
    local panel = self.Panels[self.ActiveSection]
    if (panel and panel.HandleKeyDown and panel:HandleKeyDown(key)) then
      self:SetPropagateKeyboardInput(false)
      return
    end
    if (panel and panel.HasFocusedTextInput and panel:HasFocusedTextInput()) then
      self:SetPropagateKeyboardInput(true)
      return
    end
    local handled = key == "ESCAPE" or key == "HOME" or key == "END" or key == "PAGEUP" or key == "PAGEDOWN"
    self:SetPropagateKeyboardInput(not handled)
    if (key == "ESCAPE") then self:Hide()
    elseif (handled and self.ActiveSection) then
      local panel = self.Panels[self.ActiveSection]
      local handler = panel:GetScript("OnKeyDown")
      if (handler) then handler(panel, key) end
    end
  end)
  self:SetScript("OnShow", function()
    self:FitToScreen()
    self:ShowSection(self.ActiveSection or AutoBiographer_Settings.MainWindowSection or "Summary")
    self:LayoutPanels()
  end)
  self:SetScript("OnHide", function()
    if (self.IsResizing or self.IsMoving) then
      self:StopMovingOrSizing()
      self.IsResizing, self.IsMoving = false, false
      self:SaveGeometry()
    end
  end)
  self:SetScript("OnSizeChanged", function() self:QueuePanelLayout() end)
  self:RegisterEvent("UI_SCALE_CHANGED")
  self:RegisterEvent("DISPLAY_SIZE_CHANGED")
  self:SetScript("OnEvent", function() self:FitToScreen(); self:QueuePanelLayout() end)

  self:FitToScreen()
  local geometry = AutoBiographer_Settings.MainWindowGeometry
  self:ClearAllPoints()
  if (geometry and geometry.Point and geometry.RelativePoint) then
    self:SetPoint(geometry.Point, UIParent, geometry.RelativePoint, geometry.X or 0, geometry.Y or 0)
  else
    self:SetPoint("CENTER")
  end
  self.Initialized = true
  self:LayoutPanels()
  self:Hide()
  return self
end

function AutoBiographer_MainWindow:LayoutPanels()
  if (not self.Initialized) then return end
  -- Leave room for Options and Debug even at the minimum window width.
  local available = self:GetWidth() - 226 - (#sections - 1) * 6
  local minimumTotal, preferredTotal = 0, 0
  for _, name in ipairs(sections) do
    minimumTotal = minimumTotal + minimumButtonWidths[name]
    preferredTotal = preferredTotal + (preferredButtonWidths[name] or 100)
  end
  local expansion = math.max(0, math.min(1, (available - minimumTotal) / (preferredTotal - minimumTotal)))
  local x = 18
  for i, name in ipairs(sections) do
    local button = self.SectionButtons[name]
    local buttonWidth = minimumButtonWidths[name] + ((preferredButtonWidths[name] or 100) - minimumButtonWidths[name]) * expansion
    button:SetTabWidth(buttonWidth)
    button:ClearAllPoints()
    button:SetPoint("TOPLEFT", x, -41)
    x = x + buttonWidth + 6
  end
  for _, panel in pairs(self.Panels) do panel:LayoutPanel() end
end

function AutoBiographer_MainWindow:QueuePanelLayout()
  if (not self.Initialized or self.LayoutQueued) then return end
  self.LayoutQueued = true
  C_Timer.After(0.1, function()
    self.LayoutQueued = false
    self:LayoutPanels()
  end)
end

function AutoBiographer_MainWindow:SaveGeometry()
  local point, _, relativePoint, x, y = self:GetPoint()
  AutoBiographer_Settings.MainWindowGeometry = {
    Width = self:GetWidth(), Height = self:GetHeight(),
    Point = point, RelativePoint = relativePoint, X = x, Y = y,
  }
end

function AutoBiographer_MainWindow:ShowSection(name)
  if (not self.Panels[name]) then name = "Summary" end
  self.ActiveSection = name
  AutoBiographer_Settings.MainWindowSection = name
  for section, panel in pairs(self.Panels) do
    if (section == name) then
      local wasVisible = panel:IsVisible()
      panel:Show()
      if (wasVisible) then panel:Update() end
      self.SectionButtons[section]:SetSelected(true)
    else
      panel:Hide()
      self.SectionButtons[section]:SetSelected(false)
    end
  end
  self:Show()
end

function AutoBiographer_MainWindow:Toggle()
  if (self:IsShown()) then self:Hide() else self:Show() end
end

function AutoBiographer_MainWindow:Update()
  local panel = self.Panels and self.Panels[self.ActiveSection or "Summary"]
  if (panel) then panel:Update() end
end
