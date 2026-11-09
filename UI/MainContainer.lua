local L = AutoBiographer_L
local Api = AutoBiographer_Api
local navigationGroups = {
  { Title = "Character", Sections = { "Summary", "Statistics", "Snapshots", "GearHistory" } },
  { Title = "Event Journal", Sections = { "Replay", "Events" } },
  { Title = "Tools", Sections = { "Notes", "Todos", "CampfireTales" } },
  { Title = "All Characters", Sections = { "Characters", "CharacterMap" } },
}
local sectionLabels = { Characters = "Roster", CharacterMap = "Map", GearHistory = "Gear Log", Replay = "Adventure Replay", Events = "Event Log", Todos = "Tasks", CampfireTales = "Campfire Tales" }
local sidebarLeft = 10
local sidebarWidth = 136

local function CreateNavigationButton(parent, text, width, onClick)
  local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  button:SetSize(width, 26)
  button:SetText(text)
  button:SetNormalFontObject("GameFontNormalSmall")
  button:SetHighlightFontObject("GameFontHighlightSmall")
  button:SetScript("OnClick", onClick)
  return button
end

local function CreateSidebarButton(parent, text, onClick)
  local button = CreateFrame("Button", nil, parent)
  button:SetHeight(30)
  button.Selection = button:CreateTexture(nil, "BACKGROUND")
  button.Selection:SetAllPoints()
  button.Selection:SetColorTexture(0.45, 0.32, 0.12, 0.35)
  button.Indicator = button:CreateTexture(nil, "ARTWORK")
  button.Indicator:SetPoint("TOPLEFT", 0, -3)
  button.Indicator:SetPoint("BOTTOMLEFT", 0, 3)
  button.Indicator:SetWidth(2)
  button.Indicator:SetColorTexture(1, 0.82, 0, 0.9)
  local hover = button:CreateTexture(nil, "HIGHLIGHT")
  hover:SetAllPoints()
  hover:SetColorTexture(1, 1, 1, 0.06)
  button.Label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  button.Label:SetPoint("LEFT", 10, 0)
  button.Label:SetPoint("RIGHT", -4, 0)
  button.Label:SetJustifyH("LEFT")
  button.Label:SetWordWrap(false)
  button.Label:SetText(text)
  function button:SetSelected(selected)
    self.Selection:SetShown(selected)
    self.Indicator:SetShown(selected)
    self.Label:SetTextColor(selected and 1 or 0.85, selected and 0.82 or 0.85, selected and 0 or 0.85)
    self:SetEnabled(not selected)
  end
  button:SetSelected(false)
  button:SetScript("OnClick", onClick)
  return button
end

function AutoBiographer_MainWindow:InitializeSidebar()
  self.Sidebar = CreateFrame("Frame", nil, self)
  self.Sidebar:SetPoint("TOPLEFT", sidebarLeft, -36)
  self.Sidebar:SetPoint("BOTTOMLEFT", sidebarLeft, 18)
  self.Sidebar:SetWidth(sidebarWidth)
  local background = self.Sidebar:CreateTexture(nil, "BACKGROUND")
  background:SetAllPoints()
  background:SetColorTexture(0, 0, 0, 0.2)
  local divider = self.Sidebar:CreateTexture(nil, "ARTWORK")
  divider:SetPoint("TOPRIGHT", 0, 0)
  divider:SetPoint("BOTTOMRIGHT", 0, 0)
  divider:SetWidth(1)
  divider:SetColorTexture(0.45, 0.42, 0.36, 0.7)

  self.SidebarScroll = CreateFrame("ScrollFrame", nil, self.Sidebar)
  self.SidebarScroll:SetPoint("TOPLEFT", 4, -8)
  self.SidebarScroll:SetPoint("BOTTOMRIGHT", -4, 8)
  self.SidebarContent = CreateFrame("Frame", nil, self.SidebarScroll)
  self.SidebarScroll:SetScrollChild(self.SidebarContent)
  self.SidebarScrollbar = CreateFrame("Slider", nil, self.Sidebar, "UIPanelScrollBarTemplate")
  self.SidebarScrollbar:SetPoint("TOPRIGHT", -3, -24)
  self.SidebarScrollbar:SetPoint("BOTTOMRIGHT", -3, 24)
  self.SidebarScrollbar:SetWidth(16)
  self.SidebarScrollbar:SetValueStep(1)
  self.SidebarScrollbar:SetScript("OnValueChanged", function(_, value) self.SidebarScroll:SetVerticalScroll(value) end)
  self.SidebarScrollbar:SetMinMaxValues(0, 0)
  self.SidebarScrollbar:SetValue(0)
  self.SidebarScrollbar:Hide()
  local function Scroll(_, delta)
    self.SidebarScrollbar:SetValue(math.max(0, math.min(self.SidebarScrollRange or 0,
      self.SidebarScrollbar:GetValue() - delta * 32)))
  end
  self.SidebarScroll:EnableMouseWheel(true)
  self.SidebarScroll:SetScript("OnMouseWheel", Scroll)
  self.SidebarScroll:SetScript("OnSizeChanged", function() self:QueuePanelLayout() end)

  self.SectionButtons, self.SidebarGroups = {}, {}
  for _, definition in ipairs(navigationGroups) do
    local group = { Heading = self.SidebarContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"), Buttons = {} }
    group.Heading:SetText(L[definition.Title])
    group.Heading:SetJustifyH("LEFT")
    for _, name in ipairs(definition.Sections) do
      local button = CreateSidebarButton(self.SidebarContent, L[sectionLabels[name] or name], function() self:ShowSection(name) end)
      button:EnableMouseWheel(true)
      button:SetScript("OnMouseWheel", Scroll)
      group.Buttons[#group.Buttons + 1] = button
      self.SectionButtons[name] = button
    end
    self.SidebarGroups[#self.SidebarGroups + 1] = group
  end
end

function AutoBiographer_MainWindow:LayoutSidebar()
  local top = 4
  for _, group in ipairs(self.SidebarGroups) do
    group.Heading:ClearAllPoints()
    group.Heading:SetPoint("TOPLEFT", 8, -top)
    group.Heading:SetHeight(18)
    top = top + 24
    for _, button in ipairs(group.Buttons) do
      button:ClearAllPoints()
      button:SetPoint("TOPLEFT", 4, -top)
      button.NavigationTop = top
      top = top + 32
    end
    top = top + 14
  end
  self.SidebarScrollRange = math.max(0, top - self.SidebarScroll:GetHeight())
  local width = math.max(1, self.SidebarScroll:GetWidth() - (self.SidebarScrollRange > 0 and 18 or 0))
  self.SidebarContent:SetSize(width, top)
  for _, group in ipairs(self.SidebarGroups) do
    group.Heading:SetWidth(math.max(1, width - 16))
    for _, button in ipairs(group.Buttons) do button:SetWidth(math.max(1, width - 8)) end
  end
  self.SidebarScrollbar:SetMinMaxValues(0, self.SidebarScrollRange)
  self.SidebarScrollbar:SetValue(math.min(self.SidebarScrollbar:GetValue(), self.SidebarScrollRange))
  self.SidebarScrollbar:SetShown(self.SidebarScrollRange > 0)
  self:RevealNavigationSection(self.ActiveSection)
end

function AutoBiographer_MainWindow:RevealNavigationSection(name)
  local button = self.SectionButtons[name]
  if (not button or not button.NavigationTop) then return end
  local scroll, height = self.SidebarScrollbar:GetValue(), self.SidebarScroll:GetHeight()
  if (button.NavigationTop < scroll) then scroll = button.NavigationTop
  elseif (button.NavigationTop + button:GetHeight() > scroll + height) then
    scroll = button.NavigationTop + button:GetHeight() - height
  end
  self.SidebarScrollbar:SetValue(math.max(0, math.min(self.SidebarScrollRange or 0, scroll)))
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
  self.PanelHost:SetPoint("TOPLEFT", sidebarLeft + sidebarWidth + 4, -74)
  self.PanelHost:SetPoint("BOTTOMRIGHT", -10, 12)
  self.Panels = {
    Summary = AutoBiographer_SummaryPanel,
    Characters = AutoBiographer_CharactersPanel,
    CharacterMap = AutoBiographer_CharacterMapPanel,
    Events = AutoBiographer_EventWindow,
    Replay = AutoBiographer_ReplayPanel,
    Statistics = AutoBiographer_StatisticsWindow,
    GearHistory = AutoBiographer_GearPanel,
    Snapshots = AutoBiographer_SnapshotPanel,
    Notes = AutoBiographer_NotesWindow,
    Todos = AutoBiographer_TodoPanel,
    CampfireTales = AutoBiographer_CampfireTalesPanel,
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

  self:InitializeSidebar()
  self.SectionTitle = self:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  self.SectionTitle:SetPoint("TOPLEFT", self.PanelHost, "TOPLEFT", 18, 32)
  self.SectionTitle:SetJustifyH("LEFT")
  self.SectionTitle:SetWordWrap(false)
  -- Keep the divider subdued like the window's metal border.
  self.PageEdge = self:CreateTexture(nil, "ARTWORK")
  self.PageEdge:SetPoint("TOPLEFT", self.PanelHost, "TOPLEFT", 18, 5)
  self.PageEdge:SetPoint("TOPRIGHT", self.PanelHost, "TOPRIGHT", -22, 5)
  self.PageEdge:SetHeight(1)
  self.PageEdge:SetColorTexture(0.45, 0.42, 0.36, 0.7)
  self.OptionsButton = CreateNavigationButton(self, L["Options"], 80, function()
    Settings.OpenToCategory(AutoBiographer_OptionWindow.categoryID)
    self:Hide()
  end)
  self.OptionsButton:SetPoint("TOPRIGHT", -22, -39)

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
  self:LayoutSidebar()
  self.SectionTitle:SetWidth(math.max(1, self.PanelHost:GetWidth() - 140))
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
  self.SectionTitle:SetText(L[sectionLabels[name] or name])
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
  self:RevealNavigationSection(name)
  self:Show()
end

function AutoBiographer_MainWindow:Toggle()
  if (self:IsShown()) then self:Hide() else self:Show() end
end

function AutoBiographer_MainWindow:Update()
  local panel = self.Panels and self.Panels[self.ActiveSection or "Summary"]
  if (panel) then panel:Update() end
end
