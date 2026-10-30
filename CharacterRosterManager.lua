AutoBiographer_CharacterRosterManager = { Generation = 0 }
local manager = AutoBiographer_CharacterRosterManager
local Api, Controller = AutoBiographer_Api, AutoBiographer_Controller

local function Readable(value, kind)
  return not (issecretvalue and issecretvalue(value)) and type(value) == kind
end

local function Read(func, kind, ...)
  if (not func) then return nil end
  local success, value = pcall(func, ...)
  if (success and Readable(value, kind)) then return value end
end

local function CaptureProfessions()
  if (GetProfessions and GetProfessionInfo) then return Api.GetPlayerSnapshotSkills() end
  if (not GetNumSkillLines or not GetSkillLineInfo) then return nil end
  local success, result = pcall(function()
    local count, professions, inSection = GetNumSkillLines(), {}, false
    if (not Readable(count, "number") or count <= 0) then return nil end
    for index = 1, count do
      local name, header, expanded, rank, _, _, maximum, abandonable = GetSkillLineInfo(index)
      if (not Readable(name, "string") or (issecretvalue and (issecretvalue(header) or issecretvalue(expanded) or issecretvalue(abandonable)))) then return nil end
      if (header == true or header == 1) then
        inSection = name == TRADE_SKILLS or name == SECONDARY_SKILLS or name == PROFESSIONS
        -- Collapsed headers do not expose their skills. Preserve earlier data.
        if (inSection and (expanded == false or expanded == 0)) then return nil end
      elseif (inSection or abandonable == true or abandonable == 1) then
        if (not Readable(rank, "number") or not Readable(maximum, "number")) then return nil end
        professions[#professions + 1] = { Name = name, Rank = rank, MaxRank = maximum }
      end
    end
    return professions
  end)
  if (success) then return result end
end

local function CaptureMapLocation(zone, subZone)
  if (not C_Map or not C_Map.GetBestMapForUnit or not C_Map.GetPlayerMapPosition) then return nil end
  local mapId = Read(C_Map.GetBestMapForUnit, "number", "player")
  if (not mapId or mapId <= 0) then return nil end
  local success, position = pcall(C_Map.GetPlayerMapPosition, mapId, "player")
  if (not success or not position or (issecretvalue and issecretvalue(position))) then return nil end
  local readable, x, y = pcall(function() return position.x, position.y end)
  if (not readable or not Readable(x, "number") or not Readable(y, "number")) then return nil end
  local location = { MapId = mapId, X = x * 100, Y = y * 100, Zone = zone, SubZone = subZone, Timestamp = time() }
  if (CharacterMap.HasLocation(location)) then return location end
end

function manager:CaptureEquipment(entry)
  local EM = AutoBiographer_EventManager
  if (not EM.GearTrackingReady) then return end
  local gear = Controller.CharacterData.Gear
  if (not gear or not gear.Snapshot) then return end
  local equipment, details = {}, {}
  for slot = 0, 19 do
    local id = gear.Snapshot[slot]
    if (not Readable(id, "number")) then id = entry.Equipment and entry.Equipment[slot] end
    if (Readable(id, "number")) then
      equipment[slot] = id
      if (id > 0) then
        local previous = entry.ItemDetails and entry.Equipment and entry.Equipment[slot] == id and entry.ItemDetails[slot] or {}
        local item = { Name = previous.Name, Link = previous.Link, Quality = previous.Quality, Icon = previous.Icon }
        local success, name, link, quality, _, _, _, _, _, _, icon = pcall(Api.GetItemInfo, id)
        if (success) then
          if (Readable(name, "string")) then item.Name = name end
          if (Readable(link, "string") and not item.Link) then item.Link = link end
          if (Readable(quality, "number")) then item.Quality = quality end
          if (Readable(icon, "number") or Readable(icon, "string")) then item.Icon = icon end
        end
        -- Only take an exact item link if it still matches the confirmed slot.
        if (Api.GetEquippedItemId(slot) == id) then
          local link = Read(GetInventoryItemLink, "string", "player", slot)
          if (link) then item.Link = link end
        end
        details[slot] = item
      end
    end
  end
  if (next(equipment)) then
    entry.Equipment, entry.ItemDetails, entry.GearCollectedAt = equipment, details, time()
  end
end

function manager:Capture()
  if (not self.Active or not self.Data) then return nil end
  local id = Read(UnitGUID, "string", "player") or self.CurrentId
  local name, lastName = Api.GetUnitName("player")
  if (not id or not Readable(name, "string") or name == "") then return nil end
  self.CurrentId = id
  local snapshot = { Name = name, LastName = lastName or "" }
  snapshot.Level = Read(UnitLevel, "number", "player")
  if (snapshot.Level and snapshot.Level < 1) then snapshot.Level = nil end
  snapshot.Realm = Read(GetRealmName, "string")
  snapshot.Race = Read(UnitRace, "string", "player")
  snapshot.Class, snapshot.ClassName = Api.GetPlayerClass(), Read(UnitClass, "string", "player")
  local success, faction, factionName = pcall(UnitFactionGroup, "player")
  if (success and Readable(faction, "string")) then
    snapshot.Faction = faction
    snapshot.FactionName = Readable(factionName, "string") and factionName or faction
  end
  snapshot.Zone, snapshot.SubZone = Read(GetRealZoneText, "string"), Read(GetSubZoneText, "string")
  if (snapshot.Zone == "") then snapshot.Zone, snapshot.SubZone = nil, nil end
  -- Failed/secret reads leave the last mappable position and its time intact.
  snapshot.MapLocation = CaptureMapLocation(snapshot.Zone, snapshot.SubZone)
  snapshot.Money = Read(GetMoney, "number")
  local inGuild = Read(IsInGuild, "boolean")
  if (inGuild == false) then snapshot.Guild = ""
  elseif (inGuild) then snapshot.Guild = Read(GetGuildInfo, "string", "player") end
  snapshot.Professions = CaptureProfessions()
  if (self.PlayedAmount) then snapshot.TotalTimePlayed = self.PlayedAmount + math.max(0, math.floor(GetTime() - self.PlayedAt))
  else
    local played = AutoBiographer_EventManager.PersistentPlayerInfo.LastTotalTimePlayed
    local previous = self.Data.Entries[id]
    if (Readable(played, "number")) then snapshot.TotalTimePlayed = math.max(played, previous and previous.TotalTimePlayed or 0) end
  end
  local entry = CharacterRoster.Update(self.Data, id, snapshot, time())
  self:CaptureEquipment(entry)
  return entry
end

function manager:NotifyPanel()
  for _, panel in pairs({ Roster = AutoBiographer_CharactersPanel, Map = AutoBiographer_CharacterMapPanel }) do
    if (panel.PanelReady and panel:IsVisible()) then panel:Update() end
  end
end

function manager:QueueCapture()
  if (not self.Active or self.Queued) then return end
  self.Queued = true
  local generation = self.Generation
  C_Timer.After(0.5, function()
    if (generation ~= self.Generation or not self.Active) then return end
    self.Queued = false
    self:Capture()
    self:NotifyPanel()
  end)
end

function manager:Start()
  self.Active, self.Queued = true, false
  self.Generation = self.Generation + 1
  local generation = self.Generation
  self:QueueCapture()
  local function Refresh()
    if (not self.Active or generation ~= self.Generation) then return end
    self:Capture()
    self:NotifyPanel()
    C_Timer.After(30, Refresh)
  end
  C_Timer.After(30, Refresh)
end

function manager:Stop()
  self:Capture()
  self.Active, self.Queued = false, false
  self.Generation = self.Generation + 1
end

function manager:Initialize(data)
  self.Data = data
  self.Frame = CreateFrame("Frame")
  for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "PLAYER_LEAVING_WORLD", "PLAYER_LOGOUT", "TIME_PLAYED_MSG",
    "PLAYER_LEVEL_UP", "PLAYER_MONEY", "PLAYER_EQUIPMENT_CHANGED", "UNIT_INVENTORY_CHANGED", "UNIT_NAME_UPDATE", "PLAYER_GUILD_UPDATE",
    "ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "ZONE_CHANGED_NEW_AREA", "GET_ITEM_INFO_RECEIVED", "SKILL_LINES_CHANGED" }) do
    if (Api.IsEventAvailable(event, true)) then self.Frame:RegisterEvent(event) end
  end
  self.Frame:SetScript("OnEvent", function(_, event, ...)
    if (event == "PLAYER_ENTERING_WORLD") then self:Start()
    elseif (event == "PLAYER_LEAVING_WORLD" or event == "PLAYER_LOGOUT") then self:Stop()
    elseif (event == "TIME_PLAYED_MSG") then
      local total = ...
      if (Readable(total, "number")) then self.PlayedAmount, self.PlayedAt = total, GetTime(); self:QueueCapture() end
    elseif (event == "GET_ITEM_INFO_RECEIVED") then
      local _, success = ...
      if (success) then self:QueueCapture() end
    elseif ((event ~= "UNIT_INVENTORY_CHANGED" and event ~= "UNIT_NAME_UPDATE" and event ~= "PLAYER_GUILD_UPDATE") or (...) == "player") then self:QueueCapture() end
  end)
end
