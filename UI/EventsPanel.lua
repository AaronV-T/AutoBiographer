local Controller = AutoBiographer_Controller
local HF = HelperFunctions
local Enum = AutoBiographerEnum

-- Keep the existing subtype filters, including the combined guild and PvP groups.
local eventCategories = {
  { Name = "Boss kills", SubTypes = { "BossKill" } },
  { Name = "Custom events", SubTypes = { "Custom" } },
  { Name = "Deaths", SubTypes = { "PlayerDeath" } },
  { Name = "First items acquired", SubTypes = { "FirstAcquiredItem" } },
  { Name = "First kills", SubTypes = { "FirstKill" } },
  { Name = "First subzone visits", SubTypes = { "SubZoneFirstVisit" } },
  { Name = "First zone visits", SubTypes = { "ZoneFirstVisit" } },
  { Name = "Guild changes", SubTypes = { "GuildJoined", "GuildLeft", "GuildRankChanged" } },
  { Name = "Level ups", SubTypes = { "LevelUp" } },
  { Name = "PvP: arenas & battlegrounds", SubTypes = {
    "ArenaJoined", "ArenaLost", "ArenaWon", "BattlegroundJoined", "BattlegroundLost", "BattlegroundWon",
  } },
  { Name = "Quests completed", SubTypes = { "QuestTurnIn" } },
  { Name = "Reputation changes", SubTypes = { "ReputationLevelChanged" } },
  { Name = "Skill milestones", SubTypes = { "SkillMilestone" } },
  { Name = "Spells learned", SubTypes = { "SpellLearned" } },
}

local categoryBySubType = {}
for _, category in ipairs(eventCategories) do
  for _, name in ipairs(category.SubTypes) do
    categoryBySubType[Enum.EventSubType[name]] = category.Name
  end
end

local function CategoryIsChecked(category)
  for _, name in ipairs(category.SubTypes) do
    if (not AutoBiographer_Settings.EventDisplayFilters[Enum.EventSubType[name]]) then return false end
  end
  return true
end

local function CreateJournalButton(parent, text, width, onClick)
  local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  button:SetSize(width, 24)
  button:SetText(text)
  button:SetNormalFontObject("GameFontNormalSmall")
  button:SetHighlightFontObject("GameFontHighlightSmall")
  button:SetScript("OnClick", onClick)
  return button
end

local function CreateJournalRow(window)
  local row = CreateFrame("Button", nil, window.ScrollFrame.Content)
  row.DateLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  row.DateLabel:SetPoint("LEFT", 8, 0)
  row.Icon = row:CreateTexture(nil, "ARTWORK")
  row.Icon:SetPoint("TOPLEFT", 8, -6)
  row.Icon:SetSize(20, 20)
  row.TimeLabel = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  row.TimeLabel:SetPoint("TOPLEFT", 38, -9)
  row.TimeLabel:SetWidth(60)
  row.TimeLabel:SetJustifyH("LEFT")
  row.Description = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  row.Description:SetPoint("TOPLEFT", 106, -6)
  row.Description:SetJustifyH("LEFT")
  row.Description:SetJustifyV("TOP")
  row.Description:SetWordWrap(true)
  row.Selection = row:CreateTexture(nil, "BACKGROUND")
  row.Selection:SetAllPoints(row)
  row.Selection:SetColorTexture(1, 0.82, 0, 0.1)
  row.Highlight = row:CreateTexture(nil, "HIGHLIGHT")
  row.Highlight:SetAllPoints(row)
  row.Highlight:SetColorTexture(1, 1, 1, 0.05)
  row:SetScript("OnClick", function(self)
    if (self.Entry and self.Entry.EventIndex) then window:SelectEvent(self.Entry.EventIndex) end
  end)
  row:EnableMouseWheel(true)
  row:SetScript("OnMouseWheel", function(_, delta) window:ScrollJournal(delta) end)
  return row
end

local function FindFirstJournalEntry(entries, offset)
  local left, right = 1, #entries
  while (left <= right) do
    local middle = math.floor((left + right) / 2)
    if (entries[middle].Top + entries[middle].Height <= offset) then left = middle + 1
    else right = middle - 1 end
  end
  return left
end

local function GetJournalLocation(event, mapNames)
  local location = event.ZoneName
  if (event.SubZoneName) then
    local catalog = Controller.CharacterData.Catalogs.SubZoneCatalog[event.SubZoneName]
    location = event.SubZoneName
    if (catalog and catalog.ZoneName) then location = location .. " (" .. catalog.ZoneName .. ")" end
  end
  local coordinates = Event.GetMapCoordinates(event)
  if (coordinates and coordinates.MapId) then
    local mapName = mapNames[coordinates.MapId]
    if (not mapName) then
      if (C_Map and C_Map.GetMapInfo) then
        local info = C_Map.GetMapInfo(coordinates.MapId)
        if (info) then mapName = info.name end
      end
      mapName = mapName or ("Map #" .. coordinates.MapId)
      mapNames[coordinates.MapId] = mapName
    end
    location = location or mapName
    if (coordinates.X and coordinates.Y) then
      location = location .. string.format(" | %.1f, %.1f", coordinates.X, coordinates.Y)
    end
  elseif (event.Coordinates and event.Coordinates.InstanceId) then
    location = location or ("Instance #" .. event.Coordinates.InstanceId)
  end
  return location or "Location not recorded"
end

function AutoBiographer_EventWindow:CaptureScrollAnchor()
  local offset = self.ScrollFrame.Scrollbar:GetValue()
  if (offset <= 0) then return nil, 0 end
  local entry = self.JournalEntries[FindFirstJournalEntry(self.JournalEntries, offset)]
  if (entry) then return entry.Key, offset - entry.Top end
  return nil, offset
end

function AutoBiographer_EventWindow:Initialize()
  AutioBiographer_WindowHelper:InitialzationHelper(self, 800, 650, 150, "Events", -104)
  self.Title:SetText("AutoBiographer Events")
  self.JournalEntries = {}
  self.EntriesByEventIndex = {}
  self.RowPool = {}
  self.MapNames = {}
  self.SortOrder = AutoBiographer_Settings.EventSortOrder == "Oldest" and "Oldest" or "Newest"
  self.SearchGeneration = 0

  self.SearchBox = CreateFrame("EditBox", nil, self, "InputBoxTemplate")
  self.SearchBox:SetPoint("TOPLEFT", 24, -14)
  self.SearchBox:SetSize(235, 24)
  self.SearchBox:SetAutoFocus(false)
  self.SearchBox:SetMaxLetters(200)
  self.SearchBox:SetText("")
  self.SearchHint = self.SearchBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  self.SearchHint:SetPoint("LEFT", 2, 0)
  self.SearchHint:SetText("Search events...")
  self.SearchBox:SetScript("OnEscapePressed", function(box) box:ClearFocus() end)
  self.SearchBox:SetScript("OnEnterPressed", function(box)
    box:ClearFocus()
    self:Update(true)
  end)
  self.SearchBox:SetScript("OnTextChanged", function(box)
    self.SearchHint:SetShown(box:GetText() == "")
    self.SearchGeneration = self.SearchGeneration + 1
    local generation = self.SearchGeneration
    C_Timer.After(0.15, function()
      if (self.Initialized and self:IsVisible() and self.SearchGeneration == generation) then self:Update(true) end
    end)
  end)

  self.FilterDropdown = CreateFrame("Frame", nil, self, "UIDropDownMenuTemplate")
  self.FilterDropdown:SetPoint("TOPLEFT", 265, -4)
  UIDropDownMenu_SetWidth(self.FilterDropdown, 145)
  UIDropDownMenu_SetText(self.FilterDropdown, "Filters")
  UIDropDownMenu_Initialize(self.FilterDropdown, function()
    local info = UIDropDownMenu_CreateInfo()
    info.notCheckable = true
    info.text = "Select all"
    info.func = function() self:SetAllFilters(true) end
    UIDropDownMenu_AddButton(info)
    info.text = "Clear all"
    info.func = function() self:SetAllFilters(false) end
    UIDropDownMenu_AddButton(info)
    for _, category in ipairs(eventCategories) do
      info = UIDropDownMenu_CreateInfo()
      info.text = category.Name
      info.checked = CategoryIsChecked(category)
      info.isNotRadio = true
      info.keepShownOnClick = true
      info.func = function()
        local enabled = not CategoryIsChecked(category)
        for _, name in ipairs(category.SubTypes) do
          AutoBiographer_Settings.EventDisplayFilters[Enum.EventSubType[name]] = enabled
        end
        self:Update(true)
      end
      UIDropDownMenu_AddButton(info)
    end
  end)

  self.SortDropdown = CreateFrame("Frame", nil, self, "UIDropDownMenuTemplate")
  self.SortDropdown:SetPoint("TOPLEFT", 440, -4)
  UIDropDownMenu_SetWidth(self.SortDropdown, 140)
  UIDropDownMenu_Initialize(self.SortDropdown, function()
    for _, order in ipairs({ "Newest", "Oldest" }) do
      local info = UIDropDownMenu_CreateInfo()
      info.text = order .. " first"
      info.checked = self.SortOrder == order
      info.func = function()
        self.SortOrder = order
        AutoBiographer_Settings.EventSortOrder = order
        self:Update(true)
      end
      UIDropDownMenu_AddButton(info)
    end
  end)

  self.CreateCustomEventBtn = CreateJournalButton(self, "Create Event", 120, function()
    if (AutoBiographer_CustomEventDetailsWindow:IsVisible()) then AutoBiographer_CustomEventDetailsWindow:Update()
    else AutoBiographer_CustomEventDetailsWindow:Toggle() end
  end)
  self.CreateCustomEventBtn:SetPoint("TOPRIGHT", -22, -14)
  self.FilterSummary = self:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  self.FilterSummary:SetPoint("TOPLEFT", 18, -51)
  self.FilterSummary:SetWidth(750)
  self.FilterSummary:SetJustifyH("LEFT")

  self.ScrollFrame:ClearAllPoints()
  self.ScrollFrame:SetPoint("TOPLEFT", 18, -75)
  self.ScrollFrame:SetPoint("BOTTOMRIGHT", -32, 210)
  self.ScrollFrame.Content:SetWidth(750)
  self.ScrollFrame.Scrollbar:ClearAllPoints()
  self.ScrollFrame.Scrollbar:SetPoint("TOPLEFT", self, "TOPRIGHT", -25, -80)
  self.ScrollFrame.Scrollbar:SetPoint("BOTTOMLEFT", self, "BOTTOMRIGHT", -25, 215)
  self.ScrollFrame.Scrollbar:SetMinMaxValues(0, 0)
  self.ScrollFrame.Scrollbar:SetValue(0)
  self.ScrollFrame.Scrollbar.scrollStep = 44
  self.ScrollFrame.Scrollbar:SetScript("OnValueChanged", function(_, value)
    self.ScrollFrame:SetVerticalScroll(value)
    self:RenderJournalRows()
  end)
  self.ScrollFrame:EnableMouseWheel(true)
  self.ScrollFrame:SetScript("OnMouseWheel", function(_, delta) self:ScrollJournal(delta) end)
  self:SetScript("OnMouseWheel", function(_, delta) self:ScrollJournal(delta) end)

  self.MeasureText = self:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  self.MeasureText:SetWidth(632)
  self.MeasureText:SetWordWrap(true)
  self.MeasureText:Hide()
  self.EmptyMessage = self:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  self.EmptyMessage:SetPoint("CENTER", self.ScrollFrame, "CENTER", 0, 0)
  self.EmptyMessage:SetWidth(650)
  self.EmptyMessage:SetText("No events match your search and filters.")
  self.EmptyMessage:Hide()

  self.DetailsPanel = CreateFrame("Frame", nil, self)
  self.DetailsPanel:SetPoint("BOTTOMLEFT", 18, 46)
  self.DetailsPanel:SetPoint("BOTTOMRIGHT", -18, 46)
  self.DetailsPanel:SetHeight(150)
  local background = self.DetailsPanel:CreateTexture(nil, "BACKGROUND")
  background:SetAllPoints(self.DetailsPanel)
  background:SetColorTexture(0, 0, 0, 0.18)
  local line = self.DetailsPanel:CreateTexture(nil, "BORDER")
  line:SetPoint("TOPLEFT", 0, 0)
  line:SetPoint("TOPRIGHT", 0, 0)
  line:SetHeight(1)
  line:SetColorTexture(0.6, 0.5, 0.3, 0.4)
  self.DetailsTitle = self.DetailsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  self.DetailsTitle:SetPoint("TOPLEFT", 12, -12)
  self.DetailsTitle:SetWidth(730)
  self.DetailsTitle:SetJustifyH("LEFT")
  self.DetailsLocation = self.DetailsPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  self.DetailsLocation:SetPoint("TOPLEFT", 12, -33)
  self.DetailsLocation:SetWidth(710)
  self.DetailsLocation:SetJustifyH("LEFT")
  self.DetailsLocation:SetWordWrap(false)
  self.DetailsScroll = CreateFrame("ScrollFrame", nil, self.DetailsPanel)
  self.DetailsScroll:SetPoint("TOPLEFT", 12, -56)
  self.DetailsScroll:SetPoint("BOTTOMRIGHT", -30, 12)
  self.DetailsContent = CreateFrame("Frame", nil, self.DetailsScroll)
  self.DetailsContent:SetWidth(722)
  self.DetailsContent:SetHeight(1)
  self.DetailsScroll:SetScrollChild(self.DetailsContent)
  self.DetailsText = self.DetailsContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  self.DetailsText:SetPoint("TOPLEFT", 0, 0)
  self.DetailsText:SetWidth(718)
  self.DetailsText:SetJustifyH("LEFT")
  self.DetailsText:SetJustifyV("TOP")
  self.DetailsText:SetWordWrap(true)
  self.DetailsScrollbar = CreateFrame("Slider", nil, self.DetailsPanel, "UIPanelScrollBarTemplate")
  self.DetailsScrollbar:SetPoint("TOPRIGHT", -10, -62)
  self.DetailsScrollbar:SetPoint("BOTTOMRIGHT", -10, 17)
  self.DetailsScrollbar:SetMinMaxValues(0, 0)
  self.DetailsScrollbar:SetValue(0)
  self.DetailsScrollbar:SetValueStep(1)
  self.DetailsScrollbar.scrollStep = 24
  self.DetailsScrollbar:SetScript("OnValueChanged", function(_, value) self.DetailsScroll:SetVerticalScroll(value) end)
  self.DetailsScroll:EnableMouseWheel(true)
  self.DetailsScroll:SetScript("OnMouseWheel", function(_, delta)
    local _, maximum = self.DetailsScrollbar:GetMinMaxValues()
    self.DetailsScrollbar:SetValue(math.max(0, math.min(maximum, self.DetailsScrollbar:GetValue() - delta * 24)))
  end)

  self.EventCount = self:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  self.EventCount:SetPoint("BOTTOMLEFT", 18, 20)
  self.ResetButton = CreateJournalButton(self, "Clear filters", 96, function() self:ResetFilters() end)
  self.ResetButton:SetPoint("BOTTOMRIGHT", -112, 14)
  self.RefreshButton = CreateJournalButton(self, "Refresh", 80, function() self:Update() end)
  self.RefreshButton:SetPoint("BOTTOMRIGHT", -22, 14)
  self.Initialized = true
  self.PanelReady = true
  self:LayoutPanel()
  self:UpdateDetails(true)
  self:Hide()
  return self
end

function AutoBiographer_EventWindow:LayoutPanel()
  if (not self.PanelReady) then return end
  local width = math.max(1, self:GetWidth() - 50)
  self.ScrollFrame.Content:SetWidth(width)
  self.JournalTextWidth = math.max(1, width - 118)
  self.MeasureText:SetWidth(self.JournalTextWidth)
  self.EmptyMessage:SetWidth(width - 50)
  self.FilterSummary:SetWidth(width)
  self.DetailsContent:SetWidth(self:GetWidth() - 78)
  self.DetailsText:SetWidth(self:GetWidth() - 82)
  self.DetailsTitle:SetWidth(self:GetWidth() - 70)
  self.DetailsLocation:SetWidth(self:GetWidth() - 90)
  if (self:IsVisible()) then
    if (AutoBiographer_MainWindow.IsResizing) then
      self:RenderJournalRows()
      self:UpdateDetails()
    else
      self:Update()
    end
  end
end

function AutoBiographer_EventWindow:QueueRefresh()
  if (not self.Initialized or not self:IsVisible() or self.RefreshQueued) then return end
  self.RefreshQueued = true
  C_Timer.After(0.1, function()
    self.RefreshQueued = false
    if (self:IsVisible()) then self:Update() end
  end)
end

function AutoBiographer_EventWindow:RenderJournalRows()
  if (not self.Initialized) then return end
  local scroll = self.ScrollFrame.Scrollbar:GetValue()
  local first = FindFirstJournalEntry(self.JournalEntries, math.max(0, scroll - 50))
  local bottom = scroll + self.ScrollFrame:GetHeight() + 50
  local poolIndex = 0
  for i = first, #self.JournalEntries do
    local entry = self.JournalEntries[i]
    if (entry.Top >= bottom) then break end
    poolIndex = poolIndex + 1
    local row = self.RowPool[poolIndex]
    if (not row) then
      row = CreateJournalRow(self)
      self.RowPool[poolIndex] = row
    end
    row.Entry = entry
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", 0, -entry.Top)
    row:SetSize(self.ScrollFrame.Content:GetWidth(), entry.Height)
    local isEvent = entry.EventIndex ~= nil
    row:EnableMouse(isEvent)
    row.DateLabel:SetShown(not isEvent)
    row.Icon:SetShown(isEvent)
    row.TimeLabel:SetShown(isEvent)
    row.Description:SetShown(isEvent)
    row.Selection:SetShown(isEvent and entry.EventIndex == self.SelectedEventIndex)
    if (isEvent) then
      row.Icon:SetTexture(Event.GetIconPath(entry.Event))
      row.TimeLabel:SetText(entry.TimeLabel)
      row.Description:SetWidth(self.JournalTextWidth)
      row.Description:SetHeight(entry.Height - 12)
      row.Description:SetText(entry.Description)
    else
      row.DateLabel:SetText(entry.DateLabel)
    end
    row:Show()
  end
  for i = poolIndex + 1, #self.RowPool do
    self.RowPool[i].Entry = nil
    self.RowPool[i]:Hide()
  end
end

function AutoBiographer_EventWindow:ResetFilters()
  self.SearchBox:SetText("")
  self:SetAllFilters(true)
end

function AutoBiographer_EventWindow:ScrollJournal(delta)
  self.ScrollFrame.Scrollbar:SetValue(math.max(0, math.min(self.MaxScroll or 0,
    self.ScrollFrame.Scrollbar:GetValue() - delta * self.ScrollFrame.Scrollbar.scrollStep)))
end

function AutoBiographer_EventWindow:SelectEvent(eventIndex)
  self.SelectedEventIndex = eventIndex
  self:RenderJournalRows()
  self:UpdateDetails(true)
end

function AutoBiographer_EventWindow:SetAllFilters(enabled)
  for _, subType in pairs(Enum.EventSubType) do
    AutoBiographer_Settings.EventDisplayFilters[subType] = enabled
  end
  self:Update(true)
end

function AutoBiographer_EventWindow:Update(resetScroll)
  if (not self.Initialized) then return end
  local anchorKey, anchorOffset
  if (not resetScroll) then anchorKey, anchorOffset = self:CaptureScrollAnchor() end
  local oldScroll = self.ScrollFrame.Scrollbar:GetValue()
  local search = string.lower(self.SearchBox:GetText())
  local matches = {}
  local events = Controller:GetEvents()
  for eventIndex, event in ipairs(events) do
    if (AutoBiographer_Settings.EventDisplayFilters[event.SubType]) then
      local description = Controller:GetEventString(event, true)
      local category = categoryBySubType[event.SubType] or "Event"
      local location = GetJournalLocation(event, self.MapNames)
      local timestamp = event.Timestamp
      local dateLabel = timestamp and date("%B %d, %Y", timestamp) or "Unknown date"
      local searchable = description .. " " .. category .. " " .. location .. " " .. dateLabel .. " " .. HF.TimestampToDateString(timestamp)
      if (search == "" or string.find(string.lower(searchable), search, 1, true)) then
        table.insert(matches, {
          Key = "event:" .. eventIndex, EventIndex = eventIndex, Event = event,
          Category = category, Description = description, Location = location,
          DayKey = timestamp and date("%Y-%m-%d", timestamp) or "unknown",
          DateLabel = dateLabel, TimeLabel = timestamp and date("%H:%M:%S", timestamp) or "--:--",
        })
      end
    end
  end
  table.sort(matches, function(left, right)
    local leftTime, rightTime = left.Event.Timestamp, right.Event.Timestamp
    if (leftTime == rightTime) then
      if (self.SortOrder == "Oldest") then return left.EventIndex < right.EventIndex end
      return left.EventIndex > right.EventIndex
    end
    -- Undated records belong at the end in either sort direction.
    if (leftTime == nil) then return false end
    if (rightTime == nil) then return true end
    if (self.SortOrder == "Oldest") then return leftTime < rightTime end
    return leftTime > rightTime
  end)

  local entries, offsets, byEventIndex = {}, {}, {}
  local top, previousDay = 0, nil
  for _, entry in ipairs(matches) do
    if (entry.DayKey ~= previousDay) then
      local heading = { Key = "day:" .. entry.DayKey, DateLabel = entry.DateLabel, Top = top, Height = 28 }
      table.insert(entries, heading)
      offsets[heading.Key] = top
      top = top + heading.Height
      previousDay = entry.DayKey
    end
    self.MeasureText:SetText(entry.Description)
    entry.Top = top
    entry.Height = math.max(32, math.min(34, self.MeasureText:GetStringHeight()) + 12)
    top = top + entry.Height
    table.insert(entries, entry)
    offsets[entry.Key] = entry.Top
    byEventIndex[entry.EventIndex] = entry
  end
  self.JournalEntries = entries
  self.EntriesByEventIndex = byEventIndex
  if (not byEventIndex[self.SelectedEventIndex]) then self.SelectedEventIndex = nil end
  self.ScrollFrame.Content:SetHeight(math.max(1, top))
  self.MaxScroll = math.max(0, top - self.ScrollFrame:GetHeight())
  local newScroll = resetScroll and 0 or oldScroll
  if (anchorKey and offsets[anchorKey]) then newScroll = offsets[anchorKey] + anchorOffset end
  self.ScrollFrame.Scrollbar:SetMinMaxValues(0, self.MaxScroll)
  self.ScrollFrame.Scrollbar:SetValue(math.min(newScroll, self.MaxScroll))
  self.ScrollFrame.Scrollbar:SetShown(self.MaxScroll > 0)
  self.EmptyMessage:SetShown(#matches == 0)
  self.EventCount:SetText(HF.CommaValue(#matches) .. " of " .. HF.CommaValue(#events) .. " events")
  self:UpdateFilterSummary()
  UIDropDownMenu_SetText(self.SortDropdown, self.SortOrder .. " first")
  self:RenderJournalRows()
  self:UpdateDetails()
end

function AutoBiographer_EventWindow:UpdateDetails(resetScroll)
  local entry = self.EntriesByEventIndex[self.SelectedEventIndex]
  if (entry) then
    self.DetailsTitle:SetText(entry.Category .. " | " ..
      (entry.Event.Timestamp and HF.TimestampToDateString(entry.Event.Timestamp) or "Unknown date"))
    self.DetailsLocation:SetText(entry.Location)
    self.DetailsText:SetText(entry.Description)
  else
    self.DetailsTitle:SetText("Event details")
    self.DetailsLocation:SetText("")
    self.DetailsText:SetText("Select an event above to read its full description and recorded location.")
  end
  local height = math.max(1, self.DetailsText:GetStringHeight())
  self.DetailsContent:SetHeight(height)
  local maximum = math.max(0, height - self.DetailsScroll:GetHeight())
  local offset = resetScroll and 0 or self.DetailsScrollbar:GetValue()
  self.DetailsScrollbar:SetMinMaxValues(0, maximum)
  self.DetailsScrollbar:SetValue(math.min(offset, maximum))
  self.DetailsScrollbar:SetShown(maximum > 0)
end

function AutoBiographer_EventWindow:UpdateFilterSummary()
  UIDropDownMenu_SetText(self.FilterDropdown, "Filters")
  local selected, total = 0, 0
  for _, subType in pairs(Enum.EventSubType) do
    total = total + 1
    if (AutoBiographer_Settings.EventDisplayFilters[subType]) then selected = selected + 1 end
  end
  local text = selected == total and "All event types" or (selected .. " of " .. total .. " event types")
  if (self.SearchBox:GetText() ~= "") then text = text .. " | Search active" end
  self.FilterSummary:SetText(text .. " | Click an event to view details")
end
