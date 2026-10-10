local Controller = AutoBiographer_Controller
local Api = AutoBiographer_Api
local panel = AutoBiographer_GearPanel
local rowHeight = 28
local slotNames = {
  [0] = "Ammo", "Head", "Neck", "Shoulders", "Shirt", "Chest", "Waist", "Legs",
  "Feet", "Wrists", "Hands", "Finger 1", "Finger 2", "Trinket 1", "Trinket 2",
  "Back", "Main Hand", "Off Hand", "Ranged", "Tabard",
}

local function GetItemDisplay(itemId)
  if (not itemId or itemId == 0) then return "Empty slot", nil end
  local name, link = Api.GetItemInfo(itemId)
  return name or ("Item ID: " .. itemId), link
end

function panel:HasFocusedTextInput()
  return self.SearchBox:HasFocus()
end

function panel:Initialize()
  AutioBiographer_WindowHelper:InitialzationHelper(self, 750, 585, 150, "Gear History", -96)
  self.Rows, self.RowPool, self.Headers = {}, {}, {}
  self.SearchGeneration = 0
  self.Heading = self:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  self.Heading:SetPoint("TOPLEFT", 18, -14)
  self.Heading:SetText("Gear History")
  self.Description = self:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  self.Description:SetPoint("TOPLEFT", 18, -42)
  self.Description:SetText("Newest first. Hover for item details; click an item to open its link.")

  self.SearchBox = CreateFrame("EditBox", nil, self, "InputBoxTemplate")
  self.SearchBox:SetPoint("TOPRIGHT", -26, -14)
  self.SearchBox:SetSize(260, 24)
  self.SearchBox:SetAutoFocus(false)
  self.SearchBox:SetMaxLetters(200)
  self.SearchHint = self.SearchBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  self.SearchHint:SetPoint("LEFT", 2, 0)
  self.SearchHint:SetText("Search items or slots...")
  self.SearchBox:SetScript("OnEscapePressed", function(box) box:ClearFocus() end)
  self.SearchBox:SetScript("OnEnterPressed", function(box) box:ClearFocus(); self:Update(true) end)
  self.SearchBox:SetScript("OnTextChanged", function(box)
    self.SearchHint:SetShown(box:GetText() == "")
    self.SearchGeneration = self.SearchGeneration + 1
    local generation = self.SearchGeneration
    C_Timer.After(0.15, function()
      if (generation == self.SearchGeneration and self:IsVisible()) then self:Update(true) end
    end)
  end)
  self.SearchBox:SetText("")

  self.Header = CreateFrame("Frame", nil, self)
  self.Header:SetPoint("TOPLEFT", 18, -66)
  self.Header:SetPoint("TOPRIGHT", -32, -66)
  self.Header:SetHeight(26)
  local background = self.Header:CreateTexture(nil, "BACKGROUND")
  background:SetAllPoints(self.Header)
  background:SetColorTexture(1, 1, 1, 0.06)
  for i, label in ipairs({ "Date / time", "Equipment slot", "Change", "Item" }) do
    local header = self.Header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    header:SetText(label)
    header:SetJustifyH("LEFT")
    header:SetWordWrap(false)
    self.Headers[i] = header
  end

  self.ScrollFrame.Scrollbar.scrollStep = rowHeight * 3
  self.ScrollFrame.Scrollbar:SetScript("OnValueChanged", function(_, value)
    self.ScrollFrame:SetVerticalScroll(value)
    self:RenderVisibleRows()
  end)
  self.ScrollFrame:EnableMouseWheel(true)
  self.ScrollFrame:SetScript("OnMouseWheel", function(_, delta) self:ScrollRows(delta) end)
  self:SetScript("OnMouseWheel", function(_, delta) self:ScrollRows(delta) end)
  self.EmptyMessage = self:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  self.EmptyMessage:SetPoint("CENTER", self.ScrollFrame, "CENTER")
  self.EmptyMessage:SetJustifyH("CENTER")
  self.EmptyMessage:SetWordWrap(true)
  self.Count = self:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  self.Count:SetPoint("BOTTOMLEFT", 18, 36)
  self.Footer = self:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  self.Footer:SetPoint("BOTTOMLEFT", 18, 16)
  self.Footer:SetJustifyH("LEFT")
  self.Footer:SetWordWrap(false)
  self.Footer:SetText("Offline changes are dated when next observed. Transmog is not recorded.")
  self.RefreshButton = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
  self.RefreshButton:SetSize(80, 24)
  self.RefreshButton:SetPoint("BOTTOMRIGHT", -22, 14)
  self.RefreshButton:SetText("Refresh")
  self.RefreshButton:SetScript("OnClick", function() self:Update() end)
  self:SetScript("OnHide", function() self.SearchBox:ClearFocus(); self:HideRowTooltips() end)
  -- Item names/links may arrive after the history is first displayed.
  self:RegisterEvent("GET_ITEM_INFO_RECEIVED")
  self:SetScript("OnEvent", function(_, _, itemId, success)
    if (success and self.DisplayedItemIds and self.DisplayedItemIds[itemId]) then self:QueueRefresh() end
  end)
  self.PanelReady = true
  self:LayoutPanel()
  self:Hide()
  return self
end

function panel:HideRowTooltips()
  for _, row in ipairs(self.RowPool) do
    if (GameTooltip:IsOwned(row)) then GameTooltip:Hide() end
  end
end

function panel:LayoutPanel()
  if (not self.PanelReady) then return end
  local width = math.max(1, self:GetWidth() - 50)
  self.ColumnOffsets = { 0, 185, 340, 430, width }
  for i, header in ipairs(self.Headers) do
    header:ClearAllPoints()
    header:SetPoint("LEFT", self.Header, "LEFT", self.ColumnOffsets[i] + 8, 0)
    header:SetWidth(math.max(1, self.ColumnOffsets[i + 1] - self.ColumnOffsets[i] - 16))
  end
  self.Description:SetWidth(width)
  self.Footer:SetWidth(math.max(1, self:GetWidth() - 130))
  self.EmptyMessage:SetWidth(math.max(1, width - 60))
  self.ScrollFrame:ClearAllPoints()
  self.ScrollFrame:SetPoint("TOPLEFT", 18, -96)
  self.ScrollFrame:SetPoint("BOTTOMRIGHT", -32, 62)
  self.ScrollFrame.Content:SetWidth(width)
  self.ScrollFrame.Scrollbar:ClearAllPoints()
  self.ScrollFrame.Scrollbar:SetPoint("TOPLEFT", self, "TOPRIGHT", -25, -101)
  self.ScrollFrame.Scrollbar:SetPoint("BOTTOMLEFT", self, "BOTTOMRIGHT", -25, 67)
  self:UpdateScrollRange()
end

function panel:QueueRefresh()
  if (not self.PanelReady or not self:IsVisible() or self.RefreshQueued) then return end
  self.RefreshQueued = true
  C_Timer.After(0.1, function()
    self.RefreshQueued = false
    if (self:IsVisible()) then self:Update() end
  end)
end

function panel:RenderVisibleRows()
  if (not self.ColumnOffsets) then return end
  self:HideRowTooltips()
  local scroll = self.ScrollFrame.Scrollbar:GetValue()
  local first = math.floor(scroll / rowHeight) + 1
  local last = math.min(#self.Rows, math.ceil((scroll + self.ScrollFrame:GetHeight()) / rowHeight) + 1)
  local used = 0
  for index = first, last do
    used = used + 1
    local row = self.RowPool[used]
    if (not row) then
      row = CreateFrame("Button", nil, self.ScrollFrame.Content)
      row.Cells = {}
      row.Background = row:CreateTexture(nil, "BACKGROUND")
      row.Background:SetAllPoints(row)
      row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
      row:EnableMouseWheel(true)
      row:SetScript("OnMouseWheel", function(_, delta) self:ScrollRows(delta) end)
      row:SetScript("OnEnter", function(button) self:ShowRowTooltip(button) end)
      row:SetScript("OnLeave", function(button)
        if (GameTooltip:IsOwned(button)) then GameTooltip:Hide() end
      end)
      row:SetScript("OnClick", function(button, mouseButton)
        local data = button.Data
        if (not data.DisplayItemId or data.DisplayItemId == 0) then return end
        if (data.Link and HandleModifiedItemClick and HandleModifiedItemClick(data.Link)) then return end
        if (SetItemRef) then SetItemRef("item:" .. data.DisplayItemId, data.Link or data.Name, mouseButton) end
      end)
      for column = 1, 4 do
        local cell = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        cell:SetJustifyH("LEFT")
        cell:SetWordWrap(false)
        row.Cells[column] = cell
      end
      self.RowPool[used] = row
    end
    row.Data = self.Rows[index]
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", 0, -(index - 1) * rowHeight)
    row:SetSize(self.ScrollFrame.Content:GetWidth(), rowHeight)
    row.Background:SetColorTexture(1, 1, 1, index % 2 == 0 and 0.025 or 0)
    local data = row.Data
    local values = { data.Date, data.Slot, data.Action, data.Link or data.Name }
    for column, cell in ipairs(row.Cells) do
      cell:ClearAllPoints()
      cell:SetPoint("LEFT", row, "LEFT", self.ColumnOffsets[column] + 8, 0)
      cell:SetWidth(math.max(1, self.ColumnOffsets[column + 1] - self.ColumnOffsets[column] - 16))
      cell:SetText(values[column])
    end
    row:Show()
  end
  for i = used + 1, #self.RowPool do self.RowPool[i]:Hide() end
end

function panel:ScrollRows(delta)
  local _, maximum = self.ScrollFrame.Scrollbar:GetMinMaxValues()
  self.ScrollFrame.Scrollbar:SetValue(math.max(0, math.min(maximum,
    self.ScrollFrame.Scrollbar:GetValue() - delta * self.ScrollFrame.Scrollbar.scrollStep)))
end

function panel:ShowRowTooltip(row)
  local data = row.Data
  GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
  if (data.DisplayItemId and data.DisplayItemId > 0) then GameTooltip:SetHyperlink("item:" .. data.DisplayItemId)
  else GameTooltip:SetText(data.Name, 1, 0.82, 0) end
  GameTooltip:AddLine(data.Action .. " - " .. data.Slot, 1, 1, 1)
  GameTooltip:AddLine(data.Date, 0.7, 0.7, 0.7)
  GameTooltip:Show()
end

function panel:Update(resetScroll)
  local changes = Controller:GetGearHistory().Changes
  local previousBySlot, entries, itemDisplay = {}, {}, {}
  local query = string.lower(self.SearchBox:GetText())
  self.DisplayedItemIds = {}
  -- Derive removed items from earlier changes, without expanding saved data.
  for _, change in ipairs(changes) do
    local removed = change.ItemId == 0
    local itemId = removed and previousBySlot[change.SlotId] or change.ItemId
    previousBySlot[change.SlotId] = change.ItemId
    if (not itemDisplay[itemId or 0]) then
      local name, link = GetItemDisplay(itemId)
      itemDisplay[itemId or 0] = { Name = name, Link = link }
    end
    if (itemId and itemId > 0) then self.DisplayedItemIds[itemId] = true end
    local display = itemDisplay[itemId or 0]
    local entry = { Date = date("%Y-%m-%d %H:%M:%S", change.Timestamp),
      Slot = slotNames[change.SlotId] or ("Slot " .. change.SlotId),
      Action = removed and "Unequipped" or "Equipped", DisplayItemId = itemId,
      Name = display.Name, Link = display.Link }
    if (query == "" or string.find(string.lower(entry.Date .. " " .. entry.Slot .. " " .. entry.Action .. " " .. entry.Name .. " " .. (itemId or 0)), query, 1, true)) then
      entries[#entries + 1] = entry
    end
  end
  self.Rows = {}
  for i = #entries, 1, -1 do self.Rows[#self.Rows + 1] = entries[i] end
  if (resetScroll) then self.ScrollFrame.Scrollbar:SetValue(0) end
  self.EmptyMessage:SetText(#changes == 0 and "No gear history recorded yet.\nEquipped items and future changes will appear here." or "No gear changes match your search.")
  self.EmptyMessage:SetShown(#self.Rows == 0)
  self.Count:SetText(#self.Rows .. " of " .. #changes .. " changes")
  self:UpdateScrollRange()
end

function panel:UpdateScrollRange()
  local height = math.max(1, #self.Rows * rowHeight)
  self.ScrollFrame.Content:SetHeight(height)
  local maximum = math.max(0, height - self.ScrollFrame:GetHeight())
  local scrollbar = self.ScrollFrame.Scrollbar
  local scroll = math.min(scrollbar:GetValue(), maximum)
  scrollbar:SetMinMaxValues(0, maximum)
  scrollbar:SetValue(scroll)
  self.ScrollFrame:SetVerticalScroll(scroll)
  scrollbar:SetShown(maximum > 0)
  self:RenderVisibleRows()
end
