-- Replay indexes are temporary. Saved events, snapshots and gear records are
-- never sorted or changed by playback.
AutoBiographer_Replay = {}
local Replay = AutoBiographer_Replay

local function Copy(values)
  local result = {}
  for key, value in pairs(values or {}) do result[key] = value end
  return result
end

function Replay.New(events, gear, snapshots, filters, initialLevel)
  local replay = { Events = {}, EquipmentRecords = {}, Equipment = {}, Enchants = {}, GearCursor = 0 }
  local allEvents, levelRecords = {}, {}
  for index, event in ipairs(events or {}) do
    allEvents[#allEvents + 1] = { Event = event, Order = index, Coordinates = Event.GetMapCoordinates(event) }
    if (event.SubType == AutoBiographerEnum.EventSubType.LevelUp and event.LevelNum) then
      levelRecords[#levelRecords + 1] = { Timestamp = event.Timestamp, Level = event.LevelNum }
      if (not initialLevel or event.LevelNum - 1 < initialLevel) then initialLevel = math.max(1, event.LevelNum - 1) end
    end
  end
  table.sort(allEvents, function(a, b)
    if (a.Event.Timestamp == b.Event.Timestamp) then return a.Order < b.Order end
    return a.Event.Timestamp < b.Event.Timestamp
  end)
  local records = replay.EquipmentRecords
  for _, collectionName in ipairs({ "Levels", "Raids" }) do
    for key, snapshot in pairs(snapshots and snapshots[collectionName] or {}) do
      if (snapshot.Level) then
        levelRecords[#levelRecords + 1] = { Timestamp = snapshot.Timestamp, Level = snapshot.Level }
        if (not initialLevel or snapshot.Level < initialLevel) then initialLevel = snapshot.Level end
      end
      if (snapshot.Equipment) then
        records[#records + 1] = { Timestamp = snapshot.EquipmentCollectedAt or snapshot.Timestamp,
          Snapshot = snapshot, Order = collectionName .. ":" .. tostring(key) }
      end
    end
  end
  for index, change in ipairs(gear and gear.Changes or {}) do
    records[#records + 1] = { Timestamp = change.Timestamp, Change = change, Order = index }
  end
  table.sort(records, function(a, b)
    if (a.Timestamp ~= b.Timestamp) then return a.Timestamp < b.Timestamp end
    -- Timestamp precision is one second. Apply same-second changes on top of
    -- a snapshot, preserving the recorded order of those changes.
    if ((a.Snapshot ~= nil) ~= (b.Snapshot ~= nil)) then return a.Snapshot ~= nil end
    return a.Order < b.Order
  end)
  table.sort(levelRecords, function(a, b)
    if (a.Timestamp == b.Timestamp) then return a.Level < b.Level end
    return a.Timestamp < b.Timestamp
  end)
  -- Filtering only changes which events are displayed, not the character's
  -- level or equipment at those timestamps.
  local lastCoordinates, level, levelIndex = nil, initialLevel, 1
  for _, entry in ipairs(allEvents) do
    while (levelRecords[levelIndex] and levelRecords[levelIndex].Timestamp <= entry.Event.Timestamp) do
      level = levelRecords[levelIndex].Level
      levelIndex = levelIndex + 1
    end
    entry.Level = level
    if (not filters or filters[entry.Event.SubType]) then
      lastCoordinates = entry.Coordinates or lastCoordinates
      entry.LastCoordinates = lastCoordinates
      replay.Events[#replay.Events + 1] = entry
    end
  end
  return setmetatable(replay, { __index = Replay })
end

function Replay:GetEquipmentAt(timestamp)
  local changed = false
  if (not self.GearTimestamp or timestamp < self.GearTimestamp) then
    self.Equipment, self.Enchants, self.GearCursor, self.HasEquipmentSnapshot = {}, {}, 0, false
    -- A full snapshot is a checkpoint; scrubbing backward need not replay the
    -- entire gear log before that checkpoint.
    local low, high = 1, #self.EquipmentRecords
    while (low <= high) do
      local middle = math.floor((low + high) / 2)
      if (self.EquipmentRecords[middle].Timestamp <= timestamp) then low = middle + 1
      else high = middle - 1 end
    end
    for index = high, 1, -1 do
      if (self.EquipmentRecords[index].Snapshot) then self.GearCursor = index - 1; break end
    end
    changed = true
  end
  while (self.GearCursor < #self.EquipmentRecords) do
    local record = self.EquipmentRecords[self.GearCursor + 1]
    if (record.Timestamp > timestamp) then break end
    if (record.Snapshot) then
      self.Equipment, self.Enchants = Copy(record.Snapshot.Equipment), Copy(record.Snapshot.Enchants)
      self.HasEquipmentSnapshot = true
    else
      local change = record.Change
      if (self.Equipment[change.SlotId] ~= change.ItemId) then self.Enchants[change.SlotId] = nil end
      self.Equipment[change.SlotId] = change.ItemId
    end
    self.GearCursor = self.GearCursor + 1
    changed = true
  end
  self.GearTimestamp = timestamp
  return self.Equipment, self.Enchants, self.HasEquipmentSnapshot, changed
end
