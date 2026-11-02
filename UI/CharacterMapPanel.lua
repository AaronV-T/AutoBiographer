local panel = AutoBiographer_CharacterMapPanel
local Controller, manager = AutoBiographer_Controller, AutoBiographer_CharacterRosterManager
local Hbd = LibStub("HereBeDragons-2.0")

local function Label(parent, font)
  local text = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlightSmall")
  text:SetJustifyH("LEFT"); text:SetWordWrap(false)
  return text
end

local function Button(parent, text, width, callback)
  local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  button:SetSize(width, 24); button:SetText(text)
  button:SetNormalFontObject("GameFontNormalSmall"); button:SetHighlightFontObject("GameFontHighlightSmall")
  button:SetScript("OnClick", callback)
  return button
end

local function Translate(x, y, from, to)
  return Hbd:TranslateZoneCoordinates(x, y, from, to)
end

local function LocationText(entry)
  local location = entry.MapLocation
  if (not CharacterMap.HasLocation(location)) then return "No map location recorded. Log into this character to record one." end
  local zone = location.Zone or (panel:GetMapInfo(location.MapId) or {}).name or ("Map #" .. location.MapId)
  if (location.SubZone and location.SubZone ~= "" and location.SubZone ~= zone) then zone = location.SubZone .. " (" .. zone .. ")" end
  return zone .. string.format(" | %.1f, %.1f", location.X, location.Y)
end

function panel:GetMapInfo(id)
  self.MapInfo = self.MapInfo or {}
  if (not id) then return nil end
  if (self.MapInfo[id]) then return self.MapInfo[id] end
  if (not C_Map or not C_Map.GetMapInfo) then return nil end
  local success, info = pcall(C_Map.GetMapInfo, id)
  if (success and info) then self.MapInfo[id] = info; return info end
end

function panel:HasFocusedTextInput()
  return self.SearchBox:HasFocus() or self.LevelRange:HasFocus()
end

function panel:Initialize()
  AutioBiographer_WindowHelper:InitialzationHelper(self, 800, 650, 150, "Character Map", -78)
  self.ScrollFrame:Hide(); self.ScrollFrame.Scrollbar:Hide()
  self:SetScript("OnMouseWheel", nil); self:SetScript("OnKeyDown", nil)
  self.Tiles, self.ExplorationTiles, self.Pins, self.Entries = {}, {}, {}, {}
  AutoBiographer_Settings.CharactersMapView = AutoBiographer_Settings.CharactersMapView or {}
  AutoBiographer_Settings.CharactersView = AutoBiographer_Settings.CharactersView or {}
  self.MapView, self.Filters = AutoBiographer_Settings.CharactersMapView, AutoBiographer_Settings.CharactersView
  self.MapId = self.MapView.MapId
  self.MapDropdown = CreateFrame("Frame", nil, self, "UIDropDownMenuTemplate")
  self.MapDropdown:SetPoint("TOPLEFT", 242, -38); UIDropDownMenu_SetWidth(self.MapDropdown, 210)
  UIDropDownMenu_Initialize(self.MapDropdown, function()
    for _, map in ipairs(self.Maps or {}) do
      local info = UIDropDownMenu_CreateInfo()
      info.text, info.checked = map.Name, map.Id == self.MapId
      info.func = function() self:SetMap(map.Id) end
      UIDropDownMenu_AddButton(info)
    end
  end)
  self.RealmDropdown = CreateFrame("Frame", nil, self, "UIDropDownMenuTemplate")
  self.RealmDropdown:SetPoint("TOPLEFT", 214, -4); UIDropDownMenu_SetWidth(self.RealmDropdown, 130)
  UIDropDownMenu_Initialize(self.RealmDropdown, function()
    local realms = { "All realms" }
    for _, realm in ipairs(CharacterRoster.GetRealms(Controller.AccountData.Characters)) do realms[#realms + 1] = realm end
    for index, realm in ipairs(realms) do
      local key = index > 1 and realm or nil
      local info = UIDropDownMenu_CreateInfo()
      info.text, info.checked = realm, self.Filters.Realm == key
      info.func = function() self.Filters.Realm = key; self:Update() end
      UIDropDownMenu_AddButton(info)
    end
  end)
  self.FactionDropdown = CreateFrame("Frame", nil, self, "UIDropDownMenuTemplate")
  self.FactionDropdown:SetPoint("TOPLEFT", 376, -4); UIDropDownMenu_SetWidth(self.FactionDropdown, 100)
  UIDropDownMenu_Initialize(self.FactionDropdown, function()
    for _, choice in ipairs({ { "All factions" }, { FACTION_ALLIANCE or "Alliance", "Alliance" },
      { FACTION_HORDE or "Horde", "Horde" } }) do
      local info = UIDropDownMenu_CreateInfo()
      info.text, info.checked = choice[1], choice[2] == self.Filters.Faction
      info.func = function() self.Filters.Faction = choice[2]; self:Update() end
      UIDropDownMenu_AddButton(info)
    end
  end)
  self.LevelRange = AutioBiographer_WindowHelper:CreateLevelRange(self, function(minLevel, maxLevel)
    self.MapView.MinLevel, self.MapView.MaxLevel = minLevel, maxLevel
    self:Update()
  end)
  self.LevelRange:SetPoint("TOPLEFT", 514, -5)
  self.LevelRange:SetRange(self.MapView.MinLevel, self.MapView.MaxLevel)
  self.RefreshButton = Button(self, "Refresh", 80, function() manager:Capture(); self:Update() end)
  self.RefreshButton:SetPoint("BOTTOMRIGHT", -22, 14)
  self.SearchBox = CreateFrame("EditBox", nil, self, "InputBoxTemplate")
  self.SearchBox:SetPoint("TOPLEFT", 24, -5); self.SearchBox:SetSize(190, 24)
  self.SearchBox:SetAutoFocus(false); self.SearchBox:SetMaxLetters(200); self.SearchBox:SetText("")
  self.SearchHint = Label(self.SearchBox, "GameFontDisableSmall")
  self.SearchHint:SetPoint("LEFT", 2, 0); self.SearchHint:SetText("Search characters...")
  self.SearchBox:SetScript("OnEscapePressed", function(box) box:ClearFocus() end)
  self.SearchBox:SetScript("OnEnterPressed", function(box) box:ClearFocus() end)
  self.SearchBox:SetScript("OnTextChanged", function(box)
    self.SearchHint:SetShown(box:GetText() == "")
    if (self.PanelReady) then self:Update() end
  end)
  self.ShowHidden = CreateFrame("CheckButton", nil, self, "UICheckButtonTemplate")
  self.ShowHidden:SetPoint("TOPLEFT", 18, -35); self.ShowHidden:SetSize(26, 26)
  self.HiddenLabel = Label(self); self.HiddenLabel:SetPoint("LEFT", self.ShowHidden, "RIGHT", 2, 0); self.HiddenLabel:SetText("Show hidden characters")
  self.ShowHidden:SetScript("OnClick", function() self.Filters.ShowHidden = not not self.ShowHidden:GetChecked(); self:Update() end)
  self.WorldButton = Button(self, "World", 70, function()
    self:SetMap(CharacterMap.GetWorldMap(self.MapId, function(id) return self:GetMapInfo(id) end))
  end)
  self.WorldButton:SetPoint("TOPLEFT", 514, -39)
  self.UpButton = Button(self, "Up", 54, function()
    local info = self:GetMapInfo(self.MapId)
    if (info and info.parentMapID) then self:SetMap(info.parentMapID) end
  end)
  self.UpButton:SetPoint("TOPLEFT", 590, -39)
  self.ClearButton = Button(self, "Clear filters", 96, function()
    self.Filters.Realm, self.Filters.Faction, self.Filters.ShowHidden = nil, nil, nil
    self.MapView.MinLevel, self.MapView.MaxLevel = nil, nil
    self.LevelRange:SetRange(nil, nil)
    self.SearchBox:SetText(""); self:Update()
  end)
  self.ClearButton:SetPoint("BOTTOMRIGHT", -112, 14)

  self.MapArea = CreateFrame("Frame", nil, self)
  self.MapArea:SetPoint("TOPLEFT", 18, -78); self.MapArea:SetPoint("BOTTOMRIGHT", -22, 144)
  local background = self.MapArea:CreateTexture(nil, "BACKGROUND")
  background:SetAllPoints(); background:SetColorTexture(0.06, 0.05, 0.04, 0.7)
  self.Map = CreateFrame("Frame", nil, self.MapArea)
  self.MapMessage = Label(self.MapArea, "GameFontHighlight")
  self.MapMessage:SetPoint("CENTER"); self.MapMessage:SetJustifyH("CENTER"); self.MapMessage:SetWordWrap(true)

  self.Selection = CreateFrame("Frame", nil, self)
  self.Selection:SetPoint("BOTTOMLEFT", 18, 40); self.Selection:SetPoint("BOTTOMRIGHT", -22, 40); self.Selection:SetHeight(94)
  self.Name = Label(self.Selection, "GameFontNormalLarge"); self.Name:SetPoint("TOPLEFT", 0, -2)
  self.Identity = Label(self.Selection); self.Identity:SetPoint("TOPLEFT", 0, -28)
  self.Location = Label(self.Selection); self.Location:SetPoint("TOPLEFT", 0, -49)
  self.Recorded = Label(self.Selection, "GameFontDisableSmall"); self.Recorded:SetPoint("TOPLEFT", 0, -70)
  self.ZoneButton = Button(self.Selection, "Show zone", 90, function()
    if (self.SelectedEntry and CharacterMap.HasLocation(self.SelectedEntry.MapLocation)) then self:SetMap(self.SelectedEntry.MapLocation.MapId) end
  end)
  self.ZoneButton:SetPoint("TOPRIGHT", -102, 0)
  self.RosterButton = Button(self.Selection, "View roster", 96, function()
    if (self.SelectedEntry) then
      AutoBiographer_CharactersPanel.SearchBox:SetText("")
      AutoBiographer_CharactersPanel.SelectedId = self.SelectedEntry.Id
      AutoBiographer_MainWindow:ShowSection("Characters")
    end
  end)
  self.RosterButton:SetPoint("TOPRIGHT", 0, 0)
  self.Footer = Label(self, "GameFontDisableSmall"); self.Footer:SetPoint("BOTTOMLEFT", 18, 20)
  self.PanelReady = true
  self:SetScript("OnShow", function() manager:Capture(); self:Update() end)
  self:SetScript("OnHide", function() self.SearchBox:ClearFocus(); self.LevelRange:ClearFocus(); GameTooltip:Hide() end)
  self:LayoutPanel(); self:Hide()
end

function panel:LayoutPanel()
  if (not self.PanelReady) then return end
  local width = math.max(1, self:GetWidth() - 40)
  self.MapMessage:SetWidth(width - 24)
  self.Name:SetWidth(math.max(1, width - 208))
  for _, text in ipairs({ self.Identity, self.Location, self.Recorded }) do text:SetWidth(width) end
  self.Footer:SetWidth(math.max(1, self:GetWidth() - 235))
  self:Update()
end

function panel:SetMap(id)
  if (not id) then return end
  local info = self:GetMapInfo(id)
  if (info and info.mapType == 0) then return end
  self.MapId, self.MapView.MapId = id, id
  self:Update()
end

function panel:Update()
  if (not self.PanelReady) then return end
  self.Entries = CharacterRoster.GetEntries(Controller.AccountData.Characters, { Search = self.SearchBox:GetText(),
    Realm = self.Filters.Realm, Faction = self.Filters.Faction, ShowHidden = self.Filters.ShowHidden, Sort = "Name",
    MinLevel = self.MapView.MinLevel, MaxLevel = self.MapView.MaxLevel })
  local selected
  for _, entry in ipairs(self.Entries) do if (entry.Id == self.SelectedId) then selected = entry; break end end
  if (not selected) then
    for _, entry in ipairs(self.Entries) do
      if (CharacterMap.HasLocation(entry.MapLocation) and (not selected or entry.Id == manager.CurrentId)) then selected = entry end
    end
    selected = selected or self.Entries[1]
  end
  self.SelectedEntry, self.SelectedId = selected, selected and selected.Id
  self.Maps = CharacterMap.GetMaps(self.Entries, function(id) return self:GetMapInfo(id) end)
  if (not self.MapId) then
    self.MapId = self:GetMapInfo(947) and 947 or (self.Maps[1] and self.Maps[1].Id) or 947
  end
  local info = self:GetMapInfo(self.MapId)
  UIDropDownMenu_SetText(self.MapDropdown, info and info.name or ("Map #" .. self.MapId))
  UIDropDownMenu_SetText(self.RealmDropdown, self.Filters.Realm or "All realms")
  local faction = self.Filters.Faction == "Alliance" and (FACTION_ALLIANCE or "Alliance") or
    self.Filters.Faction == "Horde" and (FACTION_HORDE or "Horde") or self.Filters.Faction
  UIDropDownMenu_SetText(self.FactionDropdown, faction or "All factions")
  self.ShowHidden:SetChecked(self.Filters.ShowHidden)
  local parent = info and self:GetMapInfo(info.parentMapID)
  self.UpButton:SetEnabled(parent ~= nil and parent.mapType ~= 0)
  self.WorldButton:SetEnabled(CharacterMap.GetWorldMap(self.MapId, function(id) return self:GetMapInfo(id) end) ~= self.MapId)
  AutoBiographer_MapCanvas.Render(self)
  self:RenderPins()
  self:UpdateSelection()
end

function panel:RenderPins()
  for _, pin in ipairs(self.Pins) do pin:Hide(); pin.Group = nil end
  local groups, shown, elsewhere, missing = CharacterMap.GetMarkers(self.Entries, self.MapId, Translate, self.Map:GetWidth(), self.Map:GetHeight())
  if (self.Layer) then
    for index, group in ipairs(groups) do
      local pin = self.Pins[index]
      if (not pin) then
        pin = CreateFrame("Button", nil, self.Map)
        local border = pin:CreateTexture(nil, "BACKGROUND"); border:SetAllPoints(); border:SetColorTexture(0, 0, 0, 1)
        pin.Icon = pin:CreateTexture(nil, "ARTWORK"); pin.Icon:SetPoint("TOPLEFT", 2, -2); pin.Icon:SetPoint("BOTTOMRIGHT", -2, 2)
        pin.Count = Label(pin, "GameFontNormalSmall"); pin.Count:SetPoint("BOTTOMRIGHT", 4, -4)
        pin.Selected = pin:CreateTexture(nil, "OVERLAY"); pin.Selected:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        pin.Selected:SetBlendMode("ADD"); pin.Selected:SetPoint("CENTER"); pin.Selected:SetSize(42, 42)
        pin:SetScript("OnEnter", function() self:ShowPinTooltip(pin) end)
        pin:SetScript("OnLeave", function() GameTooltip:Hide() end)
        pin:SetScript("OnClick", function()
          local nextIndex = 1
          for i, entry in ipairs(pin.Group.Entries) do if (entry.Id == self.SelectedId) then nextIndex = i % #pin.Group.Entries + 1; break end end
          self.SelectedEntry = pin.Group.Entries[nextIndex]; self.SelectedId = self.SelectedEntry.Id
          self:RenderPins(); self:UpdateSelection(); self:ShowPinTooltip(pin)
        end)
        self.Pins[index] = pin
      end
      local character, isSelected = group.Entries[1], false
      for _, entry in ipairs(group.Entries) do if (entry.Id == self.SelectedId) then character, isSelected = entry, true; break end end
      pin.Group = group
      pin:SetSize(24, 24); pin:ClearAllPoints()
      pin:SetPoint("CENTER", self.Map, "TOPLEFT", group.X * self.Map:GetWidth(), -group.Y * self.Map:GetHeight())
      pin:SetFrameLevel(self.Map:GetFrameLevel() + (isSelected and 3 or 2))
      local coords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[character.Class]
      pin.Icon:SetTexture(coords and "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes" or "Interface\\Icons\\inv_misc_note_05")
      if (coords) then pin.Icon:SetTexCoord(unpack(coords)) else pin.Icon:SetTexCoord(0, 1, 0, 1) end
      pin.Count:SetText(#group.Entries > 1 and tostring(#group.Entries) or "")
      pin.Selected:SetShown(isSelected); pin:Show()
    end
  else shown = 0 end
  self.Footer:SetText(shown .. " of " .. #self.Entries .. " characters on this map | " .. elsewhere .. " elsewhere | " .. missing .. " need a location update")
end

function panel:UpdateSelection()
  local entry = self.SelectedEntry
  self.RosterButton:SetEnabled(entry ~= nil)
  self.ZoneButton:SetEnabled(entry ~= nil and CharacterMap.HasLocation(entry.MapLocation))
  self.Name:SetText(entry and CharacterRoster.GetName(entry) or "No characters match your filters")
  self.Identity:SetText(entry and ("Level " .. (entry.Level or "?") .. " " .. (entry.ClassName or entry.Class or "") .. " | " ..
    (entry.Realm or "Unknown realm") .. " | " .. (entry.FactionName or entry.Faction or "")) or "Clear the filters or log into another character with AutoBiographer enabled.")
  self.Location:SetText(entry and LocationText(entry) or "")
  local location = entry and entry.MapLocation
  self.Recorded:SetText(location and location.Timestamp and ("Location recorded: " .. date("%b %d, %Y %H:%M", location.Timestamp) ..
    " | Hover for details; click a shared marker to cycle characters.") or "Locations appear after logging into each character with this update.")
end

function panel:ShowPinTooltip(pin)
  if (not pin.Group) then return end
  GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
  for index, entry in ipairs(pin.Group.Entries) do
    if (index > 8) then GameTooltip:AddLine("+" .. (#pin.Group.Entries - 8) .. " more characters. Click to cycle."); break end
    local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[entry.Class]
    GameTooltip:AddLine(CharacterRoster.GetName(entry) .. " | Level " .. (entry.Level or "?"), color and color.r or 1, color and color.g or 0.82, color and color.b or 0)
    GameTooltip:AddLine((entry.Realm or "Unknown realm") .. " | " .. LocationText(entry), 1, 1, 1, true)
    if (entry.MapLocation.Timestamp) then GameTooltip:AddLine(date("%b %d, %Y %H:%M", entry.MapLocation.Timestamp), 0.65, 0.65, 0.65) end
  end
  GameTooltip:Show()
end
