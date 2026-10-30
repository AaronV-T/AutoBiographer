local panel = AutoBiographer_CharactersPanel
local Controller, Api, HF = AutoBiographer_Controller, AutoBiographer_Api, HelperFunctions
local manager = AutoBiographer_CharacterRosterManager
local rowHeight = 82
local sorts = { { "Last played", "Recent" }, { "Name", "Name" }, { "Level", "Level" } }
local slotNames = { [0] = "Ammo", "Head", "Neck", "Shoulders", "Shirt", "Chest", "Waist", "Legs", "Feet",
  "Wrists", "Hands", "Finger 1", "Finger 2", "Trinket 1", "Trinket 2", "Back", "Main Hand", "Off Hand", "Ranged", "Tabard" }

local function Label(parent, font)
  local label = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlightSmall")
  label:SetJustifyH("LEFT")
  label:SetWordWrap(false)
  return label
end

local function Button(parent, text, width, callback)
  local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  button:SetSize(width, 24)
  button:SetText(text)
  button:SetNormalFontObject("GameFontNormalSmall")
  button:SetHighlightFontObject("GameFontHighlightSmall")
  button:SetScript("OnClick", callback)
  return button
end

local function ScrollFrame(parent)
  local frame = CreateFrame("ScrollFrame", nil, parent)
  frame.Content = CreateFrame("Frame", nil, frame)
  frame:SetScrollChild(frame.Content)
  frame.Scrollbar = CreateFrame("Slider", nil, frame, "UIPanelScrollBarTemplate")
  frame.Scrollbar:SetPoint("TOPRIGHT", -2, -16)
  frame.Scrollbar:SetPoint("BOTTOMRIGHT", -2, 16)
  frame.Scrollbar:SetWidth(16)
  frame.Scrollbar:SetValueStep(1)
  frame.Scrollbar:SetScript("OnValueChanged", function(_, value)
    frame:SetVerticalScroll(value)
    if (frame.OnScroll) then frame.OnScroll() end
  end)
  frame.Scrollbar:SetMinMaxValues(0, 0)
  frame.Scrollbar:SetValue(0)
  frame:EnableMouseWheel(true)
  frame:SetScript("OnMouseWheel", function(_, delta)
    frame.Scrollbar:SetValue(math.max(0, math.min(frame.Range or 0, frame.Scrollbar:GetValue() - delta * 40)))
  end)
  return frame
end

local function SetScrollRange(frame, height)
  frame.Content:SetHeight(math.max(1, height))
  frame.Range = math.max(0, height - frame:GetHeight())
  frame.Scrollbar:SetMinMaxValues(0, frame.Range)
  frame.Scrollbar:SetValue(math.min(frame.Scrollbar:GetValue(), frame.Range))
  frame.Scrollbar:SetShown(frame.Range > 0)
end

local function Seen(entry)
  return entry.LastSeen and date("%b %d, %Y %H:%M", entry.LastSeen) or "Not recorded"
end

local function Money(entry)
  return entry.Money and Api.FormatMoney(entry.Money) or "Not recorded"
end

local function Played(entry)
  return entry.TotalTimePlayed and HF.SecondsToTimeString(entry.TotalTimePlayed, true) or "Not recorded"
end

function panel:HasFocusedTextInput()
  return self.SearchBox:HasFocus() or self.NoteEditor.EditBox:HasFocus()
end

function panel:Initialize()
  AutioBiographer_WindowHelper:InitialzationHelper(self, 800, 650, 150, "Characters", -68)
  -- The roster scrolls independently; the selected character fits the page.
  self.ScrollFrame:Hide()
  self.ScrollFrame.Scrollbar:Hide()
  self:SetScript("OnMouseWheel", nil)
  self:SetScript("OnKeyDown", nil)
  self.Rows, self.GearRows, self.Entries = {}, {}, {}
  AutoBiographer_Settings.CharactersView = AutoBiographer_Settings.CharactersView or {}
  self.View = AutoBiographer_Settings.CharactersView
  if (self.View.Faction ~= "Alliance" and self.View.Faction ~= "Horde") then self.View.Faction = nil end

  self.SearchBox = CreateFrame("EditBox", nil, self, "InputBoxTemplate")
  self.SearchBox:SetPoint("TOPLEFT", 24, -5)
  self.SearchBox:SetSize(190, 24)
  self.SearchBox:SetAutoFocus(false)
  self.SearchBox:SetMaxLetters(200)
  self.SearchBox:SetText("")
  self.SearchHint = Label(self.SearchBox, "GameFontDisableSmall")
  self.SearchHint:SetPoint("LEFT", 2, 0)
  self.SearchHint:SetText("Search characters...")
  self.SearchBox:SetScript("OnTextChanged", function(box)
    self.SearchHint:SetShown(box:GetText() == "")
    if (self.PanelReady) then self.List.Scrollbar:SetValue(0); self:Update() end
  end)
  self.SearchBox:SetScript("OnEscapePressed", function(box) box:ClearFocus() end)
  self.SearchBox:SetScript("OnEnterPressed", function(box) box:ClearFocus() end)

  self.RealmDropdown = CreateFrame("Frame", nil, self, "UIDropDownMenuTemplate")
  self.RealmDropdown:SetPoint("TOPLEFT", 214, -4)
  UIDropDownMenu_SetWidth(self.RealmDropdown, 130)
  UIDropDownMenu_Initialize(self.RealmDropdown, function()
    local realms = { "All realms" }
    for _, realm in ipairs(CharacterRoster.GetRealms(Controller.AccountData.Characters)) do realms[#realms + 1] = realm end
    for index, realm in ipairs(realms) do
      local key = index > 1 and realm or nil
      local info = UIDropDownMenu_CreateInfo()
      info.text, info.checked = realm, self.View.Realm == key
      info.func = function() self.View.Realm = key; self:Update(true) end
      UIDropDownMenu_AddButton(info)
    end
  end)
  self.FactionDropdown = CreateFrame("Frame", nil, self, "UIDropDownMenuTemplate")
  self.FactionDropdown:SetPoint("TOPLEFT", 376, -4)
  UIDropDownMenu_SetWidth(self.FactionDropdown, 100)
  UIDropDownMenu_Initialize(self.FactionDropdown, function()
    for _, choice in ipairs({ { "All factions" }, { FACTION_ALLIANCE or "Alliance", "Alliance" },
      { FACTION_HORDE or "Horde", "Horde" } }) do
      local info = UIDropDownMenu_CreateInfo()
      info.text, info.checked = choice[1], self.View.Faction == choice[2]
      info.func = function() self.View.Faction = choice[2]; self:Update(true) end
      UIDropDownMenu_AddButton(info)
    end
  end)
  self.SortDropdown = CreateFrame("Frame", nil, self, "UIDropDownMenuTemplate")
  self.SortDropdown:SetPoint("TOPLEFT", 508, -4)
  UIDropDownMenu_SetWidth(self.SortDropdown, 130)
  UIDropDownMenu_Initialize(self.SortDropdown, function()
    for _, choice in ipairs(sorts) do
      local info = UIDropDownMenu_CreateInfo()
      info.text, info.checked = choice[1], (self.View.Sort or "Recent") == choice[2]
      info.func = function() self.View.Sort = choice[2]; self:Update(true) end
      UIDropDownMenu_AddButton(info)
    end
  end)
  self.RefreshButton = Button(self, "Refresh", 80, function() manager:Capture(); self:Update() end)
  self.RefreshButton:SetPoint("BOTTOMRIGHT", -22, 14)
  self.ShowHidden = CreateFrame("CheckButton", nil, self, "UICheckButtonTemplate")
  self.ShowHidden:SetPoint("TOPLEFT", 18, -35)
  self.ShowHidden:SetSize(26, 26)
  self.ShowHiddenLabel = Label(self)
  self.ShowHiddenLabel:SetPoint("LEFT", self.ShowHidden, "RIGHT", 2, 0)
  self.ShowHiddenLabel:SetText("Show hidden characters")
  self.ShowHidden:SetScript("OnClick", function() self.View.ShowHidden = not not self.ShowHidden:GetChecked(); self:Update(true) end)
  self.ClearButton = Button(self, "Clear filters", 96, function()
    self.View.Realm, self.View.Faction, self.View.ShowHidden = nil, nil, nil
    self.SearchBox:SetText(""); self:Update(true)
  end)
  self.ClearButton:SetPoint("BOTTOMRIGHT", -112, 14)

  self.List = ScrollFrame(self)
  self.List:SetPoint("TOPLEFT", 18, -68)
  self.List:SetPoint("BOTTOMLEFT", 18, 48)
  self.List.OnScroll = function() self:RenderRows() end
  self.Detail = CreateFrame("Frame", nil, self)
  self.Detail:SetPoint("TOPRIGHT", -18, -68)
  self.Detail:SetPoint("BOTTOMRIGHT", -18, 48)
  self.Detail.Content = CreateFrame("Frame", nil, self.Detail)
  self.Detail.Content:SetAllPoints(self.Detail)
  self.Empty = Label(self.List, "GameFontHighlight")
  self.Empty:SetPoint("TOPLEFT", 10, -20)
  self.Empty:SetWordWrap(true)
  self.Empty:SetText("No characters match your filters.\n\nClear the filters or log into another character with AutoBiographer enabled.")

  local content = self.Detail.Content
  self.Name = Label(content, "GameFontNormalLarge")
  self.Name:SetPoint("TOPLEFT", 12, -8)
  self.Identity = Label(content)
  self.Identity:SetPoint("TOPLEFT", 12, -30)
  self.Updated = Label(content, "GameFontDisableSmall")
  self.Updated:SetPoint("TOPLEFT", 12, -48)
  self.HideButton = Button(content, "Hide", 70, function()
    local entry = self.SelectedId and Controller.AccountData.Characters.Entries[self.SelectedId]
    if (entry) then entry.Hidden = not entry.Hidden or nil; self:Update() end
  end)
  self.HideButton:SetPoint("TOPRIGHT", -10, -8)
  self.Values, self.Captions = {}, {}
  for _, name in ipairs({ "Realm", "Faction", "Location", "Guild", "Money", "Played" }) do
    local caption, value = Label(content, "GameFontDisableSmall"), Label(content)
    caption:SetText(name)
    value:SetWordWrap(true)
    self.Captions[name] = caption
    self.Values[name] = value
  end
  self.ProfessionLabel = Label(content, "GameFontDisableSmall")
  self.ProfessionLabel:SetText("Professions")
  self.Professions = Label(content)
  self.Professions:SetWordWrap(true)
  self.GearHeading = Label(content, "GameFontNormal")
  self.NoteHeading = Label(content, "GameFontNormal")
  self.NoteHeading:SetText("Personal note")
  self.NoteEditor = CreateFrame("ScrollFrame", nil, content, "InputScrollFrameTemplate")
  self.NoteEditor.EditBox:SetFontObject("ChatFontNormal")
  self.NoteEditor.EditBox:SetAutoFocus(false)
  self.NoteEditor.EditBox:SetMaxLetters(1000)
  if (self.NoteEditor.CharCount) then self.NoteEditor.CharCount:Hide() end
  self.NoteEditor.EditBox:HookScript("OnTextChanged", function(box)
    if (self.LoadingNote or not self.NoteForId) then return end
    local entry = Controller.AccountData.Characters.Entries[self.NoteForId]
    if (entry) then entry.Note = box:GetText() ~= "" and box:GetText() or nil end
  end)
  self.NoteEditor.EditBox:SetScript("OnEscapePressed", function(box) box:ClearFocus() end)
  self.NoteStatus = Label(content, "GameFontDisableSmall")
  self.NoteStatus:SetText("Saved automatically. Up to 1,000 characters.")
  self.Footer = Label(self, "GameFontDisableSmall")
  self.Footer:SetPoint("BOTTOMLEFT", 18, 20)
  self.PanelReady = true
  self:SetScript("OnShow", function() manager:Capture(); self:Update() end)
  self:SetScript("OnHide", function() self.SearchBox:ClearFocus(); self.NoteEditor.EditBox:ClearFocus(); GameTooltip:Hide() end)
  self:LayoutPanel()
  self:Hide()
end

function panel:LayoutPanel()
  if (not self.PanelReady) then return end
  local width = self:GetWidth()
  local listWidth = math.max(230, math.min(300, math.floor(width * 0.29)))
  local detailWidth = math.max(1, width - listWidth - 50)
  self.List:SetWidth(listWidth)
  self.List.Content:SetWidth(math.max(1, listWidth - 22))
  self.Empty:SetWidth(math.max(1, listWidth - 40))
  self.Detail:SetWidth(detailWidth)
  self.Footer:SetWidth(math.max(1, width - 235))
  self:Update()
end

function panel:Update(resetScroll)
  if (not self.PanelReady) then return end
  local data = Controller.AccountData.Characters
  self.Entries = CharacterRoster.GetEntries(data, { Search = self.SearchBox:GetText(), Realm = self.View.Realm,
    Faction = self.View.Faction, Sort = self.View.Sort, ShowHidden = self.View.ShowHidden })
  local selected
  for _, entry in ipairs(self.Entries) do if (entry.Id == self.SelectedId) then selected = entry end end
  if (not selected) then
    for _, entry in ipairs(self.Entries) do if (entry.Id == manager.CurrentId) then selected = entry; break end end
    selected = selected or self.Entries[1]
  end
  local changed = self.SelectedId ~= (selected and selected.Id)
  self.SelectedId = selected and selected.Id
  if (resetScroll) then self.List.Scrollbar:SetValue(0) end
  if (changed) then self.NoteEditor.EditBox:ClearFocus() end
  UIDropDownMenu_SetText(self.RealmDropdown, self.View.Realm or "All realms")
  local factionText = self.View.Faction == "Alliance" and (FACTION_ALLIANCE or "Alliance") or
    self.View.Faction == "Horde" and (FACTION_HORDE or "Horde") or self.View.Faction
  UIDropDownMenu_SetText(self.FactionDropdown, factionText or "All factions")
  local sortText = "Last played"
  for _, choice in ipairs(sorts) do if (choice[2] == self.View.Sort) then sortText = choice[1] end end
  UIDropDownMenu_SetText(self.SortDropdown, sortText)
  self.ShowHidden:SetChecked(self.View.ShowHidden)
  local total = 0
  for _ in pairs(data.Entries) do total = total + 1 end
  self.Footer:SetText(#self.Entries .. " of " .. total .. " characters | Log into each character once to add it to your roster.")
  self.Empty:SetShown(#self.Entries == 0)
  self.Detail:SetShown(selected ~= nil)
  SetScrollRange(self.List, #self.Entries * rowHeight)
  self:RenderRows()
  if (selected) then self:ShowDetails(selected) else self.NoteForId = nil end
end

function panel:RenderRows()
  local first = math.floor(self.List.Scrollbar:GetValue() / rowHeight) + 1
  local last = math.min(#self.Entries, math.ceil((self.List.Scrollbar:GetValue() + self.List:GetHeight()) / rowHeight) + 1)
  local used, width = 0, self.List.Content:GetWidth()
  for index = first, last do
    used = used + 1
    local row = self.Rows[used]
    if (not row) then
      row = CreateFrame("Button", nil, self.List.Content)
      row.Background = row:CreateTexture(nil, "BACKGROUND"); row.Background:SetAllPoints()
      row.Name, row.Level, row.Class, row.Realm, row.Seen = Label(row, "GameFontNormal"), Label(row), Label(row), Label(row), Label(row, "GameFontDisableSmall")
      row.Name:SetPoint("TOPLEFT", 8, -8)
      row.Level:SetPoint("TOPRIGHT", -8, -8); row.Level:SetWidth(32); row.Level:SetJustifyH("RIGHT")
      row.Class:SetPoint("TOPLEFT", 8, -28)
      row.Realm:SetPoint("TOPLEFT", 8, -44)
      row.Seen:SetPoint("TOPLEFT", 8, -60)
      local hover = row:CreateTexture(nil, "HIGHLIGHT"); hover:SetAllPoints(); hover:SetColorTexture(1, 1, 1, 0.05)
      row:SetScript("OnClick", function()
        self.NoteEditor.EditBox:ClearFocus(); self.SelectedId = row.Entry.Id; self:Update()
      end)
      row:EnableMouseWheel(true)
      row:SetScript("OnMouseWheel", function(_, delta) self.List:GetScript("OnMouseWheel")(self.List, delta) end)
      self.Rows[used] = row
    end
    local entry = self.Entries[index]
    row.Entry = entry
    row:ClearAllPoints(); row:SetPoint("TOPLEFT", 0, -(index - 1) * rowHeight); row:SetSize(width, rowHeight - 2)
    row.Background:SetColorTexture(1, 0.82, 0, entry.Id == self.SelectedId and 0.12 or 0.025)
    row.Name:SetWidth(math.max(1, width - 54)); row.Name:SetText(CharacterRoster.GetName(entry))
    local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[entry.Class]
    row.Name:SetTextColor(color and color.r or 1, color and color.g or 0.82, color and color.b or 0)
    row.Level:SetText(entry.Level or "?")
    row.Class:SetWidth(width - 16); row.Class:SetText((entry.ClassName or entry.Class or "Unknown class") .. " | " .. (entry.FactionName or entry.Faction or "Unknown faction"))
    row.Realm:SetWidth(width - 16); row.Realm:SetText((entry.Realm or "Unknown realm") .. (entry.Id == manager.CurrentId and " | You" or entry.Hidden and " | Hidden" or ""))
    row.Seen:SetWidth(width - 16); row.Seen:SetText(Seen(entry))
    row:Show()
  end
  for index = used + 1, #self.Rows do self.Rows[index]:Hide() end
end

function panel:ShowDetails(entry)
  local content, width, height = self.Detail.Content, self.Detail:GetWidth(), self.Detail:GetHeight()
  self.Name:SetWidth(math.max(1, width - 100)); self.Name:SetText(CharacterRoster.GetName(entry))
  self.Identity:SetWidth(width - 24)
  self.Identity:SetText("Level " .. (entry.Level or "?") .. " " .. (entry.Race or "") .. " " .. (entry.ClassName or entry.Class or ""))
  self.Updated:SetWidth(width - 24)
  self.Updated:SetText("Last updated: " .. Seen(entry) .. (entry.Id == manager.CurrentId and " | Current character" or " | Saved snapshot"))
  self.HideButton:SetText(entry.Hidden and "Unhide" or "Hide")
  local location = entry.Zone or "Not recorded"
  if (entry.SubZone and entry.SubZone ~= "" and entry.SubZone ~= entry.Zone) then location = entry.SubZone .. " (" .. location .. ")" end
  local values = { Realm = entry.Realm or "Not recorded", Faction = entry.FactionName or entry.Faction or "Not recorded",
    Location = location, Guild = entry.Guild and (entry.Guild ~= "" and entry.Guild or "None") or "Not recorded", Money = Money(entry), Played = Played(entry) }
  local top, columnWidth = 72, (width - 24) / 2
  local fields = { { "Realm", "Faction" }, { "Location", "Guild" }, { "Money", "Played" } }
  for _, fieldsInRow in ipairs(fields) do
    local rowHeight = 18
    for column, key in ipairs(fieldsInRow) do
      local left = 12 + (column - 1) * columnWidth
      local caption, value = self.Captions[key], self.Values[key]
      caption:ClearAllPoints(); caption:SetPoint("TOPLEFT", left, -top); caption:SetWidth(54)
      value:ClearAllPoints(); value:SetPoint("TOPLEFT", left + 60, -top)
      value:SetWidth(math.max(1, columnWidth - 72)); value:SetText(values[key])
      rowHeight = math.max(rowHeight, value:GetStringHeight())
    end
    top = top + rowHeight + 4
  end
  top = top + 6
  local professions = {}
  for _, profession in ipairs(entry.Professions or {}) do
    professions[#professions + 1] = profession.Name .. " " .. profession.Rank .. "/" .. profession.MaxRank
  end
  self.Professions:SetWidth(math.max(1, width - 96))
  self.ProfessionLabel:ClearAllPoints(); self.ProfessionLabel:SetPoint("TOPLEFT", 12, -top)
  self.Professions:ClearAllPoints(); self.Professions:SetPoint("TOPLEFT", 84, -top)
  self.Professions:SetText(entry.Professions and (#professions > 0 and table.concat(professions, " | ") or "None") or "Not recorded")
  top = top + math.max(18, self.Professions:GetStringHeight()) + 12
  self.GearHeading:ClearAllPoints(); self.GearHeading:SetPoint("TOPLEFT", 12, -top); self.GearHeading:SetWidth(width - 24)
  self.GearHeading:SetText("Last recorded gear" .. (entry.GearCollectedAt and (" | " .. date("%b %d %H:%M", entry.GearCollectedAt)) or ""))
  top = top + 24
  local count = 19
  if (entry.Equipment and (entry.Equipment[0] or 0) > 0) then count = 20 end
  local gearColumns = top + math.ceil(count / 2) * 24 + 110 > height and 3 or 2
  columnWidth = (width - 24) / gearColumns
  -- Keep every slot visible, reserving space for the note at minimum height.
  local gearRowHeight = math.max(24, math.min(32, math.floor((height - top - 110) / math.ceil(count / gearColumns))))
  for index = 1, count do
    local row = self.GearRows[index]
    if (not row) then
      row = CreateFrame("Button", nil, content)
      row.Icon = row:CreateTexture(nil, "ARTWORK"); row.Icon:SetPoint("TOPLEFT", 0, -1); row.Icon:SetSize(20, 20)
      row.Item, row.Slot = Label(row), Label(row, "GameFontDisableSmall")
      row.Item:SetPoint("TOPLEFT", 26, 0); row.Slot:SetPoint("TOPLEFT", 26, -12)
      row:SetScript("OnEnter", function()
        if (not row.ItemId or row.ItemId <= 0) then return end
        GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(row.Link or ("item:" .. row.ItemId)); GameTooltip:Show()
      end)
      row:SetScript("OnLeave", function() GameTooltip:Hide() end)
      row:SetScript("OnClick", function(_, button)
        if (row.ItemId and row.ItemId > 0 and SetItemRef) then SetItemRef("item:" .. row.ItemId, row.Link or ("item:" .. row.ItemId), button) end
      end)
      self.GearRows[index] = row
    end
    local slot = index == 20 and 0 or index
    local id = entry.Equipment and entry.Equipment[slot]
    local item = entry.ItemDetails and entry.ItemDetails[slot] or {}
    row.ItemId, row.Link = id, item.Link
    row:ClearAllPoints(); row:SetPoint("TOPLEFT", 12 + ((index - 1) % gearColumns) * columnWidth, -top - math.floor((index - 1) / gearColumns) * gearRowHeight)
    row:SetSize(columnWidth - 8, gearRowHeight - 2)
    row.Item:SetWidth(math.max(1, columnWidth - 36)); row.Slot:SetWidth(math.max(1, columnWidth - 36))
    row.Slot:SetText(slotNames[slot])
    row.Icon:SetShown(id ~= nil and id > 0); row.Icon:SetTexture(item.Icon or "Interface\\Icons\\inv_misc_questionmark")
    row.Item:SetText(id == nil and "Not recorded" or id == 0 and "Empty" or item.Name or ("Item #" .. id))
    local color = ITEM_QUALITY_COLORS and item.Quality and ITEM_QUALITY_COLORS[item.Quality]
    row.Item:SetTextColor(color and color.r or 0.85, color and color.g or 0.85, color and color.b or 0.85)
    row:Show()
  end
  for index = count + 1, #self.GearRows do self.GearRows[index]:Hide() end
  top = top + math.ceil(count / gearColumns) * gearRowHeight + 10
  self.NoteHeading:ClearAllPoints(); self.NoteHeading:SetPoint("TOPLEFT", 12, -top)
  local noteTop = top + 24
  self.NoteEditor:ClearAllPoints(); self.NoteEditor:SetPoint("TOPLEFT", 12, -noteTop)
  self.NoteEditor:SetSize(math.max(1, width - 38), math.max(40, height - noteTop - 24))
  self.NoteEditor.EditBox:SetWidth(math.max(1, width - 62))
  if (self.NoteForId ~= entry.Id or self.NoteEditor.EditBox:GetText() ~= (entry.Note or "")) then
    self.LoadingNote = true; self.NoteEditor.EditBox:SetText(entry.Note or ""); self.LoadingNote = false
  end
  self.NoteForId = entry.Id
  self.NoteStatus:ClearAllPoints(); self.NoteStatus:SetPoint("BOTTOMLEFT", 12, 4); self.NoteStatus:SetWidth(width - 24)
end
