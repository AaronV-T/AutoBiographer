local Controller = AutoBiographer_Controller
local panel = AutoBiographer_ReplayPanel
local Hbd = LibStub("HereBeDragons-2.0")
local visibleSlots = { 1, 3, 4, 5, 6, 7, 8, 9, 10, 15, 16, 17, 18, 19 }
local speeds = { 1, 2, 5, 10, 25 }
local mapModes = { "Event zone", "Continent", "World" }

local function Label(parent, font)
  local text = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlightSmall")
  text:SetJustifyH("LEFT")
  return text
end

local function Button(parent, text, width, onClick)
  local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  button:SetSize(width, 24)
  button:SetText(text)
  button:SetNormalFontObject("GameFontNormalSmall")
  button:SetHighlightFontObject("GameFontHighlightSmall")
  button:SetScript("OnClick", onClick)
  return button
end

local function ConfigureModel(model, method, ...)
  if (model[method]) then pcall(model[method], model, ...) end
end

function panel:Initialize()
  self.Index, self.Speed, self.MapMode, self.Elapsed = 0, 2, "Event zone", 0
  self.Tiles, self.ExplorationTiles, self.Pins, self.VisiblePins, self.AnimatingPins = {}, {}, {}, {}, {}
  self.PlayButton = Button(self, "Play", 70, function() self:SetPlaying(not self.Playing) end)
  self.PlayButton:SetPoint("TOPLEFT", 18, -5)
  self.RestartButton = Button(self, "Restart", 70, function()
    self:SetPlaying(false)
    self:Seek(self:GetStartingEventIndex(), true)
  end)
  self.RestartButton:SetPoint("LEFT", self.PlayButton, "RIGHT", 6, 0)
  self.PreviousButton = Button(self, "<", 26, function() self:SetPlaying(false); self:Seek(self.Index - 1) end)
  self.PreviousButton:SetPoint("LEFT", self.RestartButton, "RIGHT", 6, 0)
  self.NextButton = Button(self, ">", 26, function() self:SetPlaying(false); self:Seek(self.Index + 1) end)
  self.NextButton:SetPoint("LEFT", self.PreviousButton, "RIGHT", 6, 0)

  self.SpeedDropdown = CreateFrame("Frame", nil, self, "UIDropDownMenuTemplate")
  self.SpeedDropdown:SetPoint("TOPLEFT", 214, -4)
  UIDropDownMenu_SetWidth(self.SpeedDropdown, 120)
  UIDropDownMenu_SetText(self.SpeedDropdown, "2 events / second")
  UIDropDownMenu_Initialize(self.SpeedDropdown, function()
    for _, speed in ipairs(speeds) do
      local info = UIDropDownMenu_CreateInfo()
      info.text, info.checked = speed .. " events / second", self.Speed == speed
      info.func = function() self.Speed = speed; UIDropDownMenu_SetText(self.SpeedDropdown, info.text) end
      UIDropDownMenu_AddButton(info)
    end
  end)
  self.MapDropdown = CreateFrame("Frame", nil, self, "UIDropDownMenuTemplate")
  self.MapDropdown:SetPoint("TOPLEFT", 360, -4)
  UIDropDownMenu_SetWidth(self.MapDropdown, 120)
  UIDropDownMenu_SetText(self.MapDropdown, self.MapMode)
  UIDropDownMenu_Initialize(self.MapDropdown, function()
    for _, mode in ipairs(mapModes) do
      local info = UIDropDownMenu_CreateInfo()
      info.text, info.checked = mode, self.MapMode == mode
      info.func = function()
        self.MapMode = mode; UIDropDownMenu_SetText(self.MapDropdown, mode)
        self:Seek(self.Index, true)
      end
      UIDropDownMenu_AddButton(info)
    end
  end)
  self.FilterDropdown = CreateFrame("Frame", nil, self, "UIDropDownMenuTemplate")
  self.FilterDropdown:SetPoint("TOPLEFT", 506, -4)
  UIDropDownMenu_SetWidth(self.FilterDropdown, AutioBiographer_WindowHelper.FilterDropdownWidth)
  AutoBiographer_EventFilters:InitializeDropdown(self.FilterDropdown, function() self:Update() end)
  self.RefreshButton = Button(self, "Refresh", 80, function() self:Update() end)
  self.RefreshButton:SetPoint("TOPRIGHT", -22, -5)

  self.MapTitle = Label(self, "GameFontNormal")
  self.MapTitle:SetPoint("TOPLEFT", 18, -43)
  self.MapArea = CreateFrame("Frame", nil, self)
  self.MapArea:SetClipsChildren(true)
  self.Map = CreateFrame("Frame", nil, self.MapArea)
  self.MapBackground = self.MapArea:CreateTexture(nil, "BACKGROUND")
  self.MapBackground:SetAllPoints(self.MapArea)
  self.MapBackground:SetColorTexture(0.08, 0.07, 0.06, 0.7)
  self.MapMessage = Label(self.MapArea)
  self.MapMessage:SetPoint("CENTER")
  self.MapMessage:SetText("Play your recorded events to begin.")
  self.MapHint = Label(self)
  self.MapHint:SetText("Hover over a pin for its event.")
  self.MapHint:SetTextColor(0.6, 0.6, 0.6)

  self.PreviewHost = CreateFrame("Frame", nil, self)
  self.PreviewTitle = Label(self.PreviewHost, "GameFontNormal")
  self.PreviewTitle:SetPoint("TOPLEFT", 10, 0)
  self.PreviewTitle:SetPoint("TOPRIGHT", -10, 0)
  self.PreviewTitle:SetHeight(38)
  self.PreviewTitle:SetJustifyV("TOP")
  self.PreviewMessage = Label(self.PreviewHost)
  self.PreviewMessage:SetPoint("BOTTOMLEFT", 10, 10)
  self.PreviewMessage:SetPoint("BOTTOMRIGHT", -10, 10)
  self.PreviewMessage:SetHeight(60)
  self.PreviewMessage:SetTextColor(0.6, 0.6, 0.6)
  local success, model = pcall(CreateFrame, "DressUpModel", nil, self.PreviewHost)
  if (success and model.Undress and model.TryOn) then
    self.Preview = model
    model:SetPoint("TOPLEFT", 0, -42)
    model:SetPoint("BOTTOMRIGHT", 0, 82)
    model:SetScript("OnModelLoaded", function() ConfigureModel(model, "RefreshCamera"); self:ApplyEquipment() end)
    local controls = CreateFrame("Frame", nil, self.PreviewHost)
    controls:SetAllPoints(self.PreviewHost)
    controls:SetFrameLevel(model:GetFrameLevel() + 2)
    self.RotateLeft = Button(controls, "<", 28, function() ConfigureModel(model, "SetFacing", (model:GetFacing() or 0) - 0.35) end)
    self.RotateLeft:SetPoint("BOTTOM", -20, 76)
    self.RotateRight = Button(controls, ">", 28, function() ConfigureModel(model, "SetFacing", (model:GetFacing() or 0) + 0.35) end)
    self.RotateRight:SetPoint("BOTTOM", 20, 76)
    model:Hide()
  end

  self.Timeline = CreateFrame("Slider", nil, self)
  self.Timeline:EnableMouse(true)
  self.Timeline.Track = self.Timeline:CreateTexture(nil, "BACKGROUND")
  self.Timeline.Track:SetPoint("LEFT")
  self.Timeline.Track:SetPoint("RIGHT")
  self.Timeline.Track:SetHeight(6)
  self.Timeline.Track:SetColorTexture(0.35, 0.32, 0.27, 0.9)
  self.Timeline.Thumb = self.Timeline:CreateTexture(nil, "ARTWORK")
  self.Timeline.Thumb:SetSize(24, 24)
  self.Timeline.Thumb:SetTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
  self.Timeline:SetThumbTexture(self.Timeline.Thumb)
  self.Timeline:SetOrientation("HORIZONTAL")
  self.Timeline:SetValueStep(1)
  self.Timeline:SetObeyStepOnDrag(true)
  self.Timeline:SetMinMaxValues(0, 1)
  self.Timeline:SetValue(0)
  self.Timeline:SetScript("OnValueChanged", function(_, value)
    if (not self.UpdatingSlider) then self:SetPlaying(false); self:Seek(math.floor(value + 0.5)) end
  end)
  self.Progress = Label(self)
  self.Progress:SetPoint("BOTTOMLEFT", 18, 66)
  self.Progress:SetPoint("BOTTOMRIGHT", -22, 66)
  self.Description = Label(self, "GameFontHighlight")
  self.Description:SetPoint("BOTTOMLEFT", 18, 6)
  self.Description:SetPoint("BOTTOMRIGHT", -22, 6)
  self.Description:SetHeight(32)
  self.Description:SetJustifyV("TOP")

  self:SetScript("OnShow", function() self:Update(true) end)
  self:SetScript("OnHide", function() self:SetPlaying(false); GameTooltip:Hide() end)
  self:SetScript("OnUpdate", function(_, elapsed) self:Advance(elapsed) end)
  self:RegisterEvent("MAP_EXPLORATION_UPDATED")
  self:SetScript("OnEvent", function()
    if (self:IsVisible()) then self:RenderExploration() end
  end)
  self:Hide()
  return self
end

function panel:Advance(elapsed)
  if (not self:IsVisible()) then return end
  for index = #self.AnimatingPins, 1, -1 do
    local pin = self.AnimatingPins[index]
    pin.PopElapsed = pin.PopElapsed + elapsed
    local size = 18 + 12 * math.max(0, 1 - pin.PopElapsed / 0.35)
    pin:SetSize(size, size)
    if (pin.PopElapsed >= 0.35) then pin.PopElapsed = nil; table.remove(self.AnimatingPins, index) end
  end
  if (not self.Playing) then return end
  self.Elapsed = self.Elapsed + elapsed
  -- Limit catch-up after a stall; never skip events or loop through the whole
  -- history in one frame.
  local steps = math.min(10, math.floor(self.Elapsed * self.Speed))
  if (steps == 0) then return end
  self.Elapsed = math.min(1, self.Elapsed - steps / self.Speed)
  for _ = 1, steps do
    if (self.Index >= #self.Replay.Events) then self:SetPlaying(false); break end
    self:Seek(self.Index + 1)
  end
end

function panel:ApplyEquipment()
  local model = self.Preview
  if (not model or not self.Equipment or self.ApplyingEquipment) then return end
  self.ApplyingEquipment = true
  local success = pcall(function()
    model:Undress()
    for _, slot in ipairs(visibleSlots) do
      local id = self.Equipment[slot]
      if (id and id > 0) then
        local hand = slot == 16 and "MAINHANDSLOT" or slot == 17 and "SECONDARYHANDSLOT" or nil
        model:TryOn("item:" .. id .. ":" .. (self.Enchants[slot] or 0), hand)
      end
    end
  end)
  self.ApplyingEquipment = false
  if (not success) then self.PreviewMessage:SetText("Equipment preview unavailable on this client.") end
end

function panel:GetDisplayMap(coordinates)
  if (not coordinates) then return nil end
  local id = coordinates.MapId
  if (self.MapMode == "Event zone" or not C_Map or not C_Map.GetMapInfo) then return id end
  -- Follow parent maps instead of assuming every event is on Azeroth.
  local visited = {}
  while (not visited[id]) do
    visited[id] = true
    local info = C_Map.GetMapInfo(id)
    if (not info or info.mapType <= (self.MapMode == "Continent" and 2 or 1)) then break end
    if (not info.parentMapID or info.parentMapID == 0) then break end
    id = info.parentMapID
  end
  return id
end

function panel:GetPinPosition(entry)
  local coordinates = entry.Coordinates
  if (not coordinates or not self.MapId) then return nil end
  local x, y = coordinates.X / 100, coordinates.Y / 100
  if (coordinates.MapId ~= self.MapId) then
    x, y = Hbd:TranslateZoneCoordinates(x, y, coordinates.MapId, self.MapId)
  end
  if (x and y and x >= 0 and x <= 1 and y >= 0 and y <= 1) then return x, y end
end

function panel:AddPin(entry, pop)
  if (not self.Layer) then return end
  local x, y = self:GetPinPosition(entry)
  if (not x) then return end
  local pin = self.Pins[#self.VisiblePins + 1]
  if (not pin) then
    pin = CreateFrame("Button", nil, self.Map)
    pin.Icon = pin:CreateTexture(nil, "ARTWORK")
    pin.Icon:SetAllPoints(pin)
    pin:SetScript("OnEnter", function(button)
      GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
      GameTooltip:AddLine(Controller:GetEventString(button.Entry.Event), 1, 1, 1, true)
      GameTooltip:Show()
    end)
    pin:SetScript("OnLeave", function() GameTooltip:Hide() end)
    self.Pins[#self.Pins + 1] = pin
  end
  pin.Entry, pin.X, pin.Y, pin.PopElapsed = entry, x, y, pop and 0 or nil
  if (pop) then self.AnimatingPins[#self.AnimatingPins + 1] = pin end
  if (self.CurrentPin) then self.CurrentPin:SetFrameLevel(self.Map:GetFrameLevel() + 1) end
  pin:SetFrameLevel(self.Map:GetFrameLevel() + 2)
  self.CurrentPin = pin
  pin.Icon:SetTexture(Event.GetIconPath(entry.Event))
  pin:SetSize(pop and 30 or 18, pop and 30 or 18)
  pin:ClearAllPoints()
  pin:SetPoint("CENTER", self.Map, "TOPLEFT", x * self.Map:GetWidth(), -y * self.Map:GetHeight())
  pin:Show()
  self.VisiblePins[#self.VisiblePins + 1] = pin
end

function panel:RebuildPins()
  GameTooltip:Hide()
  for _, pin in ipairs(self.Pins) do pin:Hide(); pin.Entry = nil; pin.PopElapsed = nil end
  self.VisiblePins, self.AnimatingPins, self.CurrentPin = {}, {}, nil
  if (not self.Replay or not self.Layer) then return end
  for index = 1, self.Index do
    local entry = self.Replay.Events[index]
    self:AddPin(entry, index == self.Index)
  end
end

local function TextureFileSize(pixels, tileSize)
  if (pixels == tileSize) then return tileSize end
  local size = 16
  while (size < pixels) do size = size * 2 end
  return size
end

function panel:RenderExploration()
  for _, tile in ipairs(self.ExplorationTiles) do tile:Hide() end
  if (not self.Layer or not C_MapExplorationInfo or not C_MapExplorationInfo.GetExploredMapTextures) then return end
  local overlays = C_MapExplorationInfo.GetExploredMapTextures(self.MapId)
  local layer, index = self.Layer, 0
  local scaleX, scaleY = self.Map:GetWidth() / layer.layerWidth, self.Map:GetHeight() / layer.layerHeight
  -- Zone map art is a blank outline. Explored subzones are separate, tiled
  -- overlays, using the player's current discoveries (not historical fog).
  for _, overlay in ipairs(overlays or {}) do
    if (not overlay.isShownByMouseOver) then
      local columns = math.ceil(overlay.textureWidth / layer.tileWidth)
      local rows = math.ceil(overlay.textureHeight / layer.tileHeight)
      for row = 1, rows do
        for column = 1, columns do
          local fileId = overlay.fileDataIDs[(row - 1) * columns + column]
          if (fileId) then
            index = index + 1
            local tile = self.ExplorationTiles[index]
            if (not tile) then tile = self.Map:CreateTexture(nil, "ARTWORK"); self.ExplorationTiles[index] = tile end
            local width = math.min(layer.tileWidth, overlay.textureWidth - (column - 1) * layer.tileWidth)
            local height = math.min(layer.tileHeight, overlay.textureHeight - (row - 1) * layer.tileHeight)
            tile:ClearAllPoints()
            tile:SetPoint("TOPLEFT", (overlay.offsetX + (column - 1) * layer.tileWidth) * scaleX,
              -(overlay.offsetY + (row - 1) * layer.tileHeight) * scaleY)
            tile:SetSize(width * scaleX, height * scaleY)
            tile:SetTexture(fileId)
            tile:SetTexCoord(0, width / TextureFileSize(width, layer.tileWidth), 0, height / TextureFileSize(height, layer.tileHeight))
            tile:SetDrawLayer("ARTWORK", overlay.isDrawOnTopLayer and 1 or 0)
            tile:Show()
          end
        end
      end
    end
  end
end

function panel:RenderMap()
  for _, tile in ipairs(self.Tiles) do tile:Hide() end
  for _, tile in ipairs(self.ExplorationTiles) do tile:Hide() end
  self.Layer = nil
  local layers = self.MapId and C_Map and C_Map.GetMapArtLayers and C_Map.GetMapArtLayers(self.MapId)
  local layer = layers and layers[1]
  local textures = layer and C_Map.GetMapArtLayerTextures and C_Map.GetMapArtLayerTextures(self.MapId, 1)
  if (not layer or not textures or #textures == 0) then
    self.MapMessage:SetText(self.MapId and "Map art unavailable for this location." or "No recorded map location yet.")
    self.MapMessage:Show()
    return
  end
  self.Layer = layer
  self.MapMessage:Hide()
  local width = math.min(self.MapArea:GetWidth(), self.MapArea:GetHeight() * layer.layerWidth / layer.layerHeight)
  local height = width * layer.layerHeight / layer.layerWidth
  self.Map:SetSize(width, height)
  self.Map:ClearAllPoints()
  self.Map:SetPoint("CENTER", self.MapArea, "CENTER")
  local columns = math.ceil(layer.layerWidth / layer.tileWidth)
  for index, fileId in ipairs(textures) do
    local tile = self.Tiles[index]
    if (not tile) then tile = self.Map:CreateTexture(nil, "BACKGROUND"); self.Tiles[index] = tile end
    local left = ((index - 1) % columns) * layer.tileWidth
    local top = math.floor((index - 1) / columns) * layer.tileHeight
    local tileWidth = math.min(layer.tileWidth, layer.layerWidth - left)
    local tileHeight = math.min(layer.tileHeight, layer.layerHeight - top)
    tile:ClearAllPoints()
    tile:SetPoint("TOPLEFT", left / layer.layerWidth * width, -top / layer.layerHeight * height)
    tile:SetSize(tileWidth / layer.layerWidth * width, tileHeight / layer.layerHeight * height)
    tile:SetTexture(fileId)
    -- Last row/column may be padded; crop rather than stretching that padding.
    tile:SetTexCoord(0, tileWidth / layer.tileWidth, 0, tileHeight / layer.tileHeight)
    tile:Show()
  end
  self:RenderExploration()
end

function panel:LayoutPanel()
  if (not self.MapArea) then return end
  local previewWidth = math.floor(self:GetWidth() * 0.28)
  self.PreviewHost:ClearAllPoints()
  self.PreviewHost:SetPoint("TOPRIGHT", -18, -43)
  self.PreviewHost:SetPoint("BOTTOMRIGHT", -18, 88)
  self.PreviewHost:SetWidth(previewWidth)
  self.MapArea:ClearAllPoints()
  self.MapArea:SetPoint("TOPLEFT", 18, -68)
  self.MapArea:SetPoint("BOTTOMRIGHT", -previewWidth - 34, 88)
  self:LayoutMapHeading()
  self.Timeline:ClearAllPoints()
  self.Timeline:SetPoint("BOTTOMLEFT", 24, 44)
  self.Timeline:SetPoint("BOTTOMRIGHT", -28, 44)
  self.Timeline:SetHeight(16)
  self:RenderMap()
  self:RebuildPins()
end

function panel:LayoutMapHeading()
  local available = self:GetWidth() - self.PreviewHost:GetWidth() - 52
  self.MapTitle:SetWidth(math.min(self.MapTitle:GetStringWidth(), available * 0.5))
  self.MapTitle:SetHeight(18)
  self.MapTitle:SetWordWrap(false)
  self.MapHint:ClearAllPoints()
  self.MapHint:SetPoint("LEFT", self.MapTitle, "RIGHT", 12, 0)
  self.MapHint:SetWidth(math.max(1, available - self.MapTitle:GetWidth() - 12))
  self.MapHint:SetHeight(18)
  self.MapHint:SetWordWrap(false)
end

function panel:Seek(index, rebuild)
  if (not self.Replay) then return end
  index = math.max(0, math.min(#self.Replay.Events, index))
  local incremental = index == self.Index + 1 and not rebuild
  self.Index = index
  self.UpdatingSlider = true
  self.Timeline:SetValue(index)
  self.UpdatingSlider = false
  local entry = self.Replay.Events[index]
  local mapId = self:GetDisplayMap(entry and entry.LastCoordinates)
  if (mapId ~= self.MapId or rebuild) then
    self.MapId = mapId
    self:RenderMap()
    incremental = false
  end
  local mapInfo = mapId and C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(mapId)
  self.MapTitle:SetText(mapInfo and mapInfo.name or "Your journey")
  self:LayoutMapHeading()
  local name, lastName = AutoBiographer_Api.GetUnitName("player")
  name = (name or AutoBiographer_EventManager.PlayerName or "Adventurer") .. (lastName and (" " .. lastName) or "")
  self.PreviewTitle:SetText(name .. (entry and (" | Level " .. (entry.Level or "unknown")) or ""))
  if (incremental) then self:AddPin(entry, true) else self:RebuildPins() end
  self.Progress:SetText("Event " .. index .. " / " .. #self.Replay.Events ..
    (entry and "  |  " .. date("%Y-%m-%d %H:%M:%S", entry.Event.Timestamp) or ""))
  self.Description:SetText(entry and Controller:GetEventString(entry.Event, true) ..
    (not entry.Coordinates and "\n|cff888888Location not recorded.|r" or "") or
    (#self.Replay.Events == 0 and (#Controller:GetEvents() == 0 and "No events have been recorded yet." or "No events match the selected filters.") or
    "Press Play to relive your journey, or drag the timeline to an event."))
  self.PreviousButton:SetEnabled(index > 0)
  self.NextButton:SetEnabled(index < #self.Replay.Events)
  self.PlayButton:SetEnabled(#self.Replay.Events > 0)
  if (entry) then self:UpdateEquipment(entry.Event.Timestamp) else
    self.Equipment = nil
    if (self.Preview) then self.Preview:Hide() end
    self.PreviewMessage:SetText("Gear will follow the event timeline.")
  end
  if (self.Playing and index >= #self.Replay.Events) then self:SetPlaying(false) end
end

function panel:SetPlaying(playing)
  self.Playing = playing and self.Replay ~= nil and #self.Replay.Events > 0
  self.Elapsed = 0
  self.PlayButton:SetText(self.Playing and "Pause" or "Play")
  if (self.Playing and self.Index >= #self.Replay.Events) then self:Seek(0) end
end

function panel:GetStartingEventIndex()
  for index, entry in ipairs(self.Replay and self.Replay.Events or {}) do
    local coordinates = entry.Coordinates
    if (coordinates and type(coordinates.MapId) == "number" and coordinates.MapId > 0 and
      type(coordinates.X) == "number" and type(coordinates.Y) == "number" and
      coordinates.X >= 0 and coordinates.X <= 100 and coordinates.Y >= 0 and coordinates.Y <= 100) then
      return index
    end
  end
  -- Without any recorded locations, still let the user read their events and
  -- see the corresponding gear rather than starting with an empty preview.
  return self.Replay and #self.Replay.Events > 0 and 1 or 0
end

function panel:Update(resetToStart)
  self:SetPlaying(false)
  local previous = self.Replay and self.Replay.Events[self.Index]
  local initialLevel
  for level in pairs(Controller.CharacterData.Levels or {}) do
    if (not initialLevel or level < initialLevel) then initialLevel = level end
  end
  self.Replay = AutoBiographer_Replay.New(Controller:GetEvents(), Controller:GetGearHistory(), Controller:GetCharacterSnapshots(),
    AutoBiographer_Settings.EventDisplayFilters, initialLevel)
  if (resetToStart) then
    self.Index = self:GetStartingEventIndex()
  elseif (previous) then
    self.Index = 0
    for index, entry in ipairs(self.Replay.Events) do
      if (entry.Event.Timestamp > previous.Event.Timestamp) then break end
      self.Index = index
      if (entry.Event == previous.Event) then break end
    end
  end
  self.Index = math.min(self.Index, #self.Replay.Events)
  self.Equipment = nil
  self.UpdatingSlider = true
  self.Timeline:SetMinMaxValues(0, math.max(1, #self.Replay.Events))
  self.UpdatingSlider = false
  self:LayoutPanel()
  self:Seek(self.Index, true)
end

function panel:UpdateEquipment(timestamp)
  local wasEmpty = self.Equipment == nil
  local complete, changed
  self.Equipment, self.Enchants, complete, changed = self.Replay:GetEquipmentAt(timestamp)
  local hasGear = next(self.Equipment) ~= nil
  self.PreviewMessage:SetText(not hasGear and "No equipment was recorded at this time." or
    (complete and "Recorded gear on your current appearance.\nTransmog is not recorded." or
    "Gear log only; unrecorded slots are unknown.\nTransmog is not recorded."))
  local model = self.Preview
  if (not model) then self.PreviewMessage:SetText("Character preview unavailable on this client."); return end
  if (not hasGear) then model:Hide(); return end
  if (not self.ModelReady) then
    ConfigureModel(model, "SetAutoDress", false)
    ConfigureModel(model, "SetUseTransmogSkin", false)
    ConfigureModel(model, "SetUseTransmogChoices", false)
    ConfigureModel(model, "SetObeyHideInTransmogFlag", false)
    self.ModelReady = pcall(model.SetUnit, model, "player", false, true)
    ConfigureModel(model, "RefreshCamera")
    ConfigureModel(model, "SetFacing", 0.35)
  end
  if (not self.ModelReady) then model:Hide(); self.PreviewMessage:SetText("Character preview unavailable on this client."); return end
  model:Show()
  if (changed or wasEmpty) then self:ApplyEquipment() end
end
