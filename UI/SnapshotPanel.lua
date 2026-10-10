local Controller = AutoBiographer_Controller
local Api = AutoBiographer_Api
local panel = AutoBiographer_SnapshotPanel
local statNames = { "Strength", "Agility", "Stamina", "Intellect", "Spirit" }
local slotNames = { [0] = "Ammo", "Head", "Neck", "Shoulders", "Shirt", "Chest", "Waist",
  "Legs", "Feet", "Wrists", "Hands", "Finger 1", "Finger 2", "Trinket 1", "Trinket 2",
  "Back", "Main Hand", "Off Hand", "Ranged", "Tabard" }
local gold = "|cffffd100"
local visibleSlots = { 1, 3, 4, 5, 6, 7, 8, 9, 10, 15, 16, 17, 18, 19 }

local function ConfigureModel(model, method, ...)
  if (model[method]) then pcall(model[method], model, ...) end
end

local function AddCatalogLines(lines, entries, catalog, formatValue)
  if (not entries) then lines[#lines + 1] = "Not captured"; return end
  local sorted = {}
  for id, value in pairs(entries) do
    sorted[#sorted + 1] = { Name = catalog[id] and catalog[id].Name or ("ID: " .. id), Value = value }
  end
  table.sort(sorted, function(a, b) return a.Name < b.Name end)
  for _, entry in ipairs(sorted) do lines[#lines + 1] = entry.Name .. ": " .. formatValue(entry.Value) end
  if (#sorted == 0) then lines[#lines + 1] = "None" end
end

local function CollectionTime(lines, timestamp, milestone)
  if (timestamp and timestamp ~= milestone) then
    lines[#lines + 1] = "|cff888888Collected " .. date("%Y-%m-%d %H:%M:%S", timestamp) .. "|r"
  end
end

function panel:ApplyPreviewEquipment()
  local model = self.Preview
  if (not model or not model.Snapshot or self.ApplyingPreview) then return end
  self.ApplyingPreview = true
  local success = pcall(function()
    -- Always clear the previous selection, including slots that are empty in
    -- this snapshot. This model never changes the player's actual equipment.
    model:Undress()
    for _, slot in ipairs(visibleSlots) do
      local id = model.Snapshot.Equipment[slot]
      if (id and id > 0) then
        local enchant = model.Snapshot.Enchants and model.Snapshot.Enchants[slot] or 0
        local hand = slot == 16 and "MAINHANDSLOT" or slot == 17 and "SECONDARYHANDSLOT" or nil
        -- Numeric TryOn arguments are appearance IDs on modern clients.
        model:TryOn("item:" .. id .. ":" .. enchant, hand)
      end
    end
  end)
  self.ApplyingPreview = false
  self.PreviewMessage:SetText(success and "Recorded gear on your current appearance.\nTransmog is not recorded." or "Equipment preview unavailable on this client.")
end

function panel:GetDetailText(entry)
  local snapshot, catalogs = entry.Snapshot, Controller.CharacterData.Catalogs
  local lines = { gold .. entry.Label .. "|r", date("%Y-%m-%d %H:%M:%S", snapshot.Timestamp),
    "Level: " .. snapshot.Level,
    "Money: " .. (snapshot.Money ~= nil and Api.FormatMoney(snapshot.Money) or "Not captured"),
    "Total time played: " .. (snapshot.TotalTimePlayed and HelperFunctions.SecondsToTimeString(snapshot.TotalTimePlayed) or "Not captured") }
  if (snapshot.Pending) then
    local missing = {}
    for _, section in ipairs({ { "Attributes", "attributes" }, { "Equipment", "equipment" },
      { "Talents", "talents" }, { "Skills", "skills / professions" } }) do
      if (not snapshot[section[1]]) then missing[#missing + 1] = section[2] end
    end
    lines[#lines + 1] = "|cffaaaaaaWaiting to capture: " .. table.concat(missing, ", ") .. ".|r"
  end
  if (snapshot.Incomplete) then lines[#lines + 1] = "|cffaaaaaaIncomplete: character leveled before missing data could be captured.|r" end
  if (snapshot.DifficultyId) then lines[#lines + 1] = "Raid difficulty ID: " .. snapshot.DifficultyId end

  lines[#lines + 1] = "\n" .. gold .. "Attributes (base / effective)|r"
  if (snapshot.Attributes) then
    for index, name in ipairs(statNames) do
      lines[#lines + 1] = name .. ": " .. snapshot.Attributes.Base[index] .. " / " .. snapshot.Attributes.Effective[index]
    end
    lines[#lines + 1] = "Max health: " .. snapshot.MaxHealth
    lines[#lines + 1] = "Max mana: " .. snapshot.MaxMana
    CollectionTime(lines, snapshot.StatsCollectedAt, snapshot.Timestamp)
  else
    lines[#lines + 1] = "Not captured"
  end

  lines[#lines + 1] = "\n" .. gold .. "Equipment|r"
  if (snapshot.Equipment) then
    for slot = 0, 19 do
      local itemId = snapshot.Equipment[slot]
      if (itemId and itemId > 0) then
        local name, link = Api.GetItemInfo(itemId)
        local text = slotNames[slot] .. ": " .. (link or name or ("Item ID: " .. itemId))
        local enchant = snapshot.Enchants and snapshot.Enchants[slot]
        if (enchant) then text = text .. " (enchant ID: " .. enchant .. ")" end
        lines[#lines + 1] = text
      end
    end
    CollectionTime(lines, snapshot.EquipmentCollectedAt, snapshot.Timestamp)
  else
    lines[#lines + 1] = "Not captured"
  end

  lines[#lines + 1] = "\n" .. gold .. "Talents|r"
  AddCatalogLines(lines, snapshot.Talents, catalogs.TalentCatalog or {}, function(rank) return "rank " .. rank end)
  lines[#lines + 1] = "Unspent points: " .. (snapshot.UnspentTalentPoints or "Not captured")
  CollectionTime(lines, snapshot.TalentsCollectedAt, snapshot.Timestamp)

  lines[#lines + 1] = "\n" .. gold .. "Skills / professions|r"
  AddCatalogLines(lines, snapshot.Skills, catalogs.SkillCatalog or {}, function(skill) return skill.Rank .. " / " .. skill.MaxRank end)
  CollectionTime(lines, snapshot.SkillsCollectedAt, snapshot.Timestamp)
  return table.concat(lines, "\n")
end

function panel:Initialize()
  AutioBiographer_WindowHelper:InitialzationHelper(self, 750, 585, 150, "Snapshots", -76)
  self.Rows, self.RowPool = {}, {}
  self.Heading = self:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  self.Heading:SetPoint("TOPLEFT", 18, -14)
  self.Heading:SetText("Character Snapshots")
  self.Description = self:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  self.Description:SetPoint("TOPLEFT", 18, -42)
  self.Description:SetText("Level-ups and first final-boss kills. Deferred values show their collection time; transmog is not recorded.")
  self.List = CreateFrame("ScrollFrame", nil, self)
  self.List.Content = CreateFrame("Frame", nil, self.List)
  self.List:SetScrollChild(self.List.Content)
  self.List.Scrollbar = CreateFrame("Slider", nil, self.List, "UIPanelScrollBarTemplate")
  self.List.Scrollbar:SetWidth(16)
  self.List.Scrollbar:SetPoint("TOPLEFT", self.List, "TOPRIGHT", 2, -16)
  self.List.Scrollbar:SetPoint("BOTTOMLEFT", self.List, "BOTTOMRIGHT", 2, 16)
  self.List.Scrollbar:SetValueStep(32)
  self.List.Scrollbar.scrollStep = 96
  self.List.Scrollbar:SetMinMaxValues(0, 0)
  self.List.Scrollbar:SetScript("OnValueChanged", function(_, value)
    self.List:SetVerticalScroll(value)
    self:RenderList()
  end)
  self.List.Scrollbar:SetValue(0)
  self.List:EnableMouseWheel(true)
  self.List:SetScript("OnMouseWheel", function(_, delta)
    local _, maximum = self.List.Scrollbar:GetMinMaxValues()
    self.List.Scrollbar:SetValue(math.max(0, math.min(maximum, self.List.Scrollbar:GetValue() - delta * 96)))
  end)

  self.PreviewHeading = self:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  self.PreviewHeading:SetText("Recorded equipment")
  self.PreviewMessage = self:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  self.PreviewMessage:SetPoint("BOTTOMLEFT", 18, 18)
  self.PreviewMessage:SetSize(220, 42)
  self.PreviewMessage:SetJustifyH("CENTER")
  local created, model = pcall(CreateFrame, "DressUpModel", nil, self)
  if (created and model.Undress and model.TryOn) then
    self.Preview = model
    model:SetScript("OnModelLoaded", function()
      ConfigureModel(model, "RefreshCamera")
      self:ApplyPreviewEquipment()
    end)
    self.RotateLeft = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
    self.RotateLeft:SetSize(32, 20)
    self.RotateLeft:SetPoint("BOTTOMLEFT", 82, 60)
    self.RotateLeft:SetText("<")
    self.RotateLeft:SetScript("OnClick", function() self:RotatePreview(-0.4) end)
    self.RotateRight = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
    self.RotateRight:SetSize(32, 20)
    self.RotateRight:SetPoint("BOTTOMLEFT", 140, 60)
    self.RotateRight:SetText(">")
    self.RotateRight:SetScript("OnClick", function() self:RotatePreview(0.4) end)
  elseif (created) then
    model:Hide()
  end

  -- A read-only HTML body supports clickable equipment links and a single
  -- details scrollbar, without duplicating item names in the saved snapshot.
  self.Detail = CreateFrame("SimpleHTML", nil, self.ScrollFrame.Content)
  self.Detail:SetPoint("TOPLEFT", 8, -8)
  self.Detail:SetFontObject("p", GameFontHighlight)
  self.Detail:SetSpacing("p", 4)
  self.Detail:SetScript("OnHyperlinkClick", function(_, link, text, button)
    local itemLink = "|H" .. link .. "|h" .. text .. "|h"
    if (not HandleModifiedItemClick or not HandleModifiedItemClick(itemLink)) then SetItemRef(link, itemLink, button) end
  end)
  self.Detail:SetScript("OnHyperlinkEnter", function(_, link)
    if (link:match("^item:")) then GameTooltip:SetOwner(self.Detail, "ANCHOR_CURSOR"); GameTooltip:SetHyperlink(link) end
  end)
  self.Detail:SetScript("OnHyperlinkLeave", function() GameTooltip:Hide() end)
  self:SetScript("OnHide", function()
    if (GameTooltip:IsOwned(self.Detail)) then GameTooltip:Hide() end
    if (self.Preview) then self.Preview.Snapshot = nil end
  end)
  self:RegisterEvent("GET_ITEM_INFO_RECEIVED")
  self:SetScript("OnEvent", function() self:QueueRefresh() end)
  self.PanelReady = true
  self:LayoutPanel()
  self:Hide()
end

function panel:LayoutPanel()
  if (not self.PanelReady) then return end
  self.Description:SetWidth(math.max(1, self:GetWidth() - 36))
  self.List:ClearAllPoints()
  self.List:SetPoint("TOPLEFT", 18, -76)
  local previewHeight = math.max(180, math.min(280, self:GetHeight() * 0.4))
  self.List:SetSize(220, math.max(100, self:GetHeight() - 186 - previewHeight))
  self.List.Content:SetWidth(220)
  if (self.Preview) then
    self.Preview:ClearAllPoints()
    self.Preview:SetPoint("BOTTOMLEFT", 18, 82)
    self.Preview:SetSize(220, previewHeight)
    self.PreviewHeading:SetPoint("BOTTOMLEFT", self.Preview, "TOPLEFT", 0, 8)
  else
    self.PreviewHeading:SetPoint("BOTTOMLEFT", 18, 82 + previewHeight + 8)
  end
  self.ScrollFrame:ClearAllPoints()
  self.ScrollFrame:SetPoint("TOPLEFT", 268, -76)
  self.ScrollFrame:SetPoint("BOTTOMRIGHT", -34, 20)
  self.ScrollFrame.Scrollbar:ClearAllPoints()
  self.ScrollFrame.Scrollbar:SetPoint("TOPLEFT", self.ScrollFrame, "TOPRIGHT", 4, -16)
  self.ScrollFrame.Scrollbar:SetPoint("BOTTOMLEFT", self.ScrollFrame, "BOTTOMRIGHT", 4, 16)
  self.ScrollFrame.Content:SetWidth(math.max(1, self:GetWidth() - 302))
  self.Detail:SetWidth(math.max(1, self:GetWidth() - 318))
  self:Update()
end

function panel:QueueRefresh()
  if (not self.PanelReady or not self:IsVisible() or self.RefreshQueued) then return end
  self.RefreshQueued = true
  C_Timer.After(0.1, function()
    self.RefreshQueued = false
    if (self:IsVisible()) then self:Update() end
  end)
end

function panel:RenderList()
  local first = math.floor(self.List:GetVerticalScroll() / 52) + 1
  local count = math.ceil(self.List:GetHeight() / 52) + 1
  for index = 1, count do
    local button = self.RowPool[index]
    if (not button) then
      button = CreateFrame("Button", nil, self.List.Content)
      button:SetSize(220, 50)
      button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
      button.Label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      button.Label:SetPoint("TOPLEFT", 6, -6)
      button.Label:SetWidth(208)
      button.Label:SetJustifyH("LEFT")
      button:SetScript("OnClick", function(row)
        self.SelectedSnapshot = row.Entry.Snapshot
        self:RenderList()
        self:ShowDetails(true)
      end)
      self.RowPool[index] = button
    end
    local rowIndex = first + index - 1
    button.Entry = self.Rows[rowIndex]
    button:ClearAllPoints()
    button:SetPoint("TOPLEFT", 0, -(rowIndex - 1) * 52)
    if (button.Entry) then
      local text = button.Entry.Label
      if (button.Entry.Snapshot == self.SelectedSnapshot) then text = gold .. text .. "|r" end
      button.Label:SetText(text .. "\n|cff888888" .. date("%Y-%m-%d %H:%M", button.Entry.Snapshot.Timestamp) .. "|r")
      button:Show()
    else
      button:Hide()
    end
  end
  for index = count + 1, #self.RowPool do self.RowPool[index]:Hide() end
end

function panel:RotatePreview(amount)
  if (self.Preview) then
    self.PreviewFacing = (self.PreviewFacing or 0.35) + amount
    ConfigureModel(self.Preview, "SetFacing", self.PreviewFacing)
  end
end

function panel:ShowDetails(resetScroll)
  local entry
  for _, row in ipairs(self.Rows) do if (row.Snapshot == self.SelectedSnapshot) then entry = row; break end end
  local text = entry and self:GetDetailText(entry) or "No snapshots recorded yet. Level up or clear a supported raid to record one."
  -- Escape HTML while retaining WoW color codes and item hyperlinks.
  text = text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub("\n", "<br/>")
  text = text:gsub("|H([^|]+)|h([^|]+)|h", '<a href="%1">%2</a>')
  self.Detail:SetText("<html><body><p>" .. text .. "</p></body></html>")
  self.Detail:SetHeight(self.Detail:GetContentHeight())
  local height = math.max(self.ScrollFrame:GetHeight(), self.Detail:GetHeight() + 16)
  self.ScrollFrame.Content:SetHeight(height)
  self.ScrollFrame.Scrollbar:SetMinMaxValues(0, math.max(0, height - self.ScrollFrame:GetHeight()))
  if (resetScroll) then self.ScrollFrame.Scrollbar:SetValue(0) end
  self:UpdatePreview()
end

function panel:Update()
  if (not self.PanelReady) then return end
  local data, catalogs = Controller:GetCharacterSnapshots(), Controller.CharacterData.Catalogs
  self.Rows = {}
  for level, snapshot in pairs(data.Levels) do
    self.Rows[#self.Rows + 1] = { Label = "Level " .. level, Snapshot = snapshot }
  end
  for id, snapshot in pairs(data.Raids) do
    self.Rows[#self.Rows + 1] = { Label = catalogs.RaidCatalog and catalogs.RaidCatalog[id] and catalogs.RaidCatalog[id].Name or ("Raid ID: " .. id), Snapshot = snapshot }
  end
  table.sort(self.Rows, function(a, b)
    if (a.Snapshot.Timestamp == b.Snapshot.Timestamp) then return a.Label < b.Label end
    return a.Snapshot.Timestamp > b.Snapshot.Timestamp
  end)
  local selectionExists = false
  for _, row in ipairs(self.Rows) do if (row.Snapshot == self.SelectedSnapshot) then selectionExists = true end end
  if (not selectionExists) then self.SelectedSnapshot = self.Rows[1] and self.Rows[1].Snapshot end
  self.List.Content:SetHeight(math.max(1, #self.Rows * 52))
  self.List.Scrollbar:SetMinMaxValues(0, math.max(0, #self.Rows * 52 - self.List:GetHeight()))
  self:RenderList()
  self:ShowDetails(not selectionExists)
end

function panel:UpdatePreview()
  local model, snapshot = self.Preview, self.SelectedSnapshot
  local available = snapshot and snapshot.Equipment ~= nil
  if (self.RotateLeft) then
    self.RotateLeft:SetShown(available and model ~= nil)
    self.RotateRight:SetShown(available and model ~= nil)
  end
  if (not model or not available) then
    if (model) then model.Snapshot = nil; model:Hide() end
    self.PreviewMessage:SetText(not snapshot and "Select a snapshot to preview its gear."
      or not available and "Equipment not captured."
      or "Equipment preview unavailable on this client.")
    return
  end
  model:Show()
  if (model.Snapshot ~= snapshot) then
    model.Snapshot = snapshot
    ConfigureModel(model, "SetAutoDress", false)
    ConfigureModel(model, "SetUseTransmogSkin", false)
    ConfigureModel(model, "SetUseTransmogChoices", false)
    ConfigureModel(model, "SetObeyHideInTransmogFlag", false)
    local success = pcall(model.SetUnit, model, "player", false, true)
    if (not success) then
      model.Snapshot = nil; model:Hide()
      self.PreviewMessage:SetText("Character preview unavailable on this client.")
      return
    end
    self.PreviewFacing = 0.35
    ConfigureModel(model, "RefreshCamera")
    ConfigureModel(model, "SetFacing", self.PreviewFacing)
  end
  self:ApplyPreviewEquipment()
end
