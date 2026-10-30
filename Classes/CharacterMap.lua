CharacterMap = {}

local function Number(value)
  return type(value) == "number" and value == value and math.abs(value) ~= math.huge
end

function CharacterMap.HasLocation(location)
  return type(location) == "table" and Number(location.MapId) and location.MapId > 0 and location.MapId == math.floor(location.MapId) and
    Number(location.X) and Number(location.Y) and location.X >= 0 and location.X <= 100 and location.Y >= 0 and location.Y <= 100
end

function CharacterMap.GetWorldMap(mapId, getInfo)
  local visited, result = {}, mapId
  while (mapId and not visited[mapId]) do
    visited[mapId] = true
    local info = getInfo(mapId)
    if (not info or info.mapType == 0) then break end
    result = mapId
    if (info.mapType == 1 or not info.parentMapID or info.parentMapID == 0) then break end
    mapId = info.parentMapID
  end
  return result
end

function CharacterMap.GetMaps(entries, getInfo)
  local maps, seen = {}, {}
  local function AddChain(mapId)
    while (mapId and mapId > 0 and not seen[mapId]) do
      seen[mapId] = true
      local info = getInfo(mapId)
      -- The cosmic overview cannot represent accurate character positions.
      if (not info or info.mapType == 0) then break end
      maps[#maps + 1] = { Id = mapId, Name = info.name or ("Map #" .. mapId), Type = info.mapType or 3 }
      mapId = info.parentMapID
    end
  end
  AddChain(947) -- Azeroth, also used by HereBeDragons for world projections.
  for _, entry in ipairs(entries) do if (CharacterMap.HasLocation(entry.MapLocation)) then AddChain(entry.MapLocation.MapId) end end
  table.sort(maps, function(a, b)
    if (a.Type ~= b.Type) then return a.Type < b.Type end
    if (a.Name ~= b.Name) then return a.Name < b.Name end
    return a.Id < b.Id
  end)
  return maps
end

function CharacterMap.GetPosition(location, mapId, translate)
  if (not CharacterMap.HasLocation(location) or not mapId) then return nil end
  local x, y = location.X / 100, location.Y / 100
  if (location.MapId ~= mapId) then
    local success
    success, x, y = pcall(translate, x, y, location.MapId, mapId)
    if (not success) then return nil end
  end
  if (Number(x) and Number(y) and x >= 0 and x <= 1 and y >= 0 and y <= 1) then return x, y end
end

function CharacterMap.GetMarkers(entries, mapId, translate, width, height)
  local groups, shown, elsewhere, missing = {}, 0, 0, 0
  for _, entry in ipairs(entries) do
    if (not CharacterMap.HasLocation(entry.MapLocation)) then missing = missing + 1
    else
      local x, y = CharacterMap.GetPosition(entry.MapLocation, mapId, translate)
      if (not x) then elsewhere = elsewhere + 1
      else
        shown = shown + 1
        local group
        for _, candidate in ipairs(groups) do
          local dx, dy = (candidate.X - x) * width, (candidate.Y - y) * height
          if (dx * dx + dy * dy < 24 * 24) then group = candidate; break end
        end
        if (not group) then group = { X = x, Y = y, Entries = {} }; groups[#groups + 1] = group end
        group.Entries[#group.Entries + 1] = entry
      end
    end
  end
  return groups, shown, elsewhere, missing
end
