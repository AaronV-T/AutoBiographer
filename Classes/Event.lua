Event = {}
function Event.New(timestamp, type, subType)
  return {
    Timestamp = timestamp,
    Type = type,
    SubType = subType
  }
end

function Event.ToString(e, catalogs)
  local timestampString = HelperFunctions.TimestampToDateString(e.Timestamp) .. ": "

  if (e.Type == AutoBiographerEnum.EventType.Kill) then
    if (e.SubType == AutoBiographerEnum.LevelEventSubType.FirstKill) then
      local unitName = "#" .. e.CatalogUnitId
      if (catalogs ~= nil and catalogs.UnitCatalog ~= nil and catalogs.UnitCatalog[e.CatalogUnitId] ~= nil and catalogs.UnitCatalog[e.CatalogUnitId].Name ~= nil) then unitName = catalogs.UnitCatalog[e.CatalogUnitId].Name end
      return timestampString .. "You killed " .. unitName .. " for the first time."
    end
  elseif (e.Type == AutoBiographerEnum.EventType.Level) then
    if (e.SubType == AutoBiographerEnum.LevelEventSubType.LevelUp) then
      return timestampString .. "You hit level " .. e.LevelNum .. "."
    end
  else
    return timestampString .. "Event with type '" .. e.Type .. "' and subType '" .. e.SubType .. "'."
  end
end

WorldEvent = {}
function WorldEvent.New(timestamp, type, subType, coordinates)
  local newInstance = Event.New(timestamp, type, subType)
  newInstance.Coordinates = coordinates
  
  return newInstance
end

FirstKillEvent = {}
function FirstKillEvent.New(timestamp, coordinates, catalogUnitId)
  local newInstance = WorldEvent.New(timestamp, AutoBiographerEnum.EventType.Kill, AutoBiographerEnum.LevelEventSubType.FirstKill, coordinates)
  newInstance.CatalogUnitId = catalogUnitId
  
  return newInstance
end

LevelUpEvent = {}
function LevelUpEvent.New(timestamp, coordinates, levelNum)
  local newInstance = WorldEvent.New(timestamp, AutoBiographerEnum.EventType.Level, AutoBiographerEnum.LevelEventSubType.LevelUp, coordinates)
  newInstance.LevelNum = levelNum
  
  return newInstance
end

