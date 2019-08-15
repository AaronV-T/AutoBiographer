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

  if (e.Type == AutoBiographerEnum.EventType.Death) then
    if (e.SubType == AutoBiographerEnum.DeathEventSubType.PlayerDeath) then
      if (e.KillerCuid == nil) then
        return timestampString .. "You died."
      else
        local unitName = "#" .. e.KillerCuid
        if (catalogs ~= nil and catalogs.UnitCatalog ~= nil and catalogs.UnitCatalog[e.KillerCuid] ~= nil and catalogs.UnitCatalog[e.KillerCuid].Name ~= nil) then unitName = catalogs.UnitCatalog[e.KillerCuid].Name end
        local killerLevelText = ""
        if (e.KillerLevel ~= nil) then 
          local killerLevel = e.KillerLevel
          if (killerLevel == -1) then killerLevel = "?" end
          killerLevelText = " (level " .. tostring(killerLevel) .. ")"
        end
        return timestampString .. "You were killed by " .. unitName .. killerLevelText .. "."
      end
    end
  elseif (e.Type == AutoBiographerEnum.EventType.Kill) then
    if (e.SubType == AutoBiographerEnum.KillEventSubType.BossKill) then
      return timestampString .. "You killed " .. e.BossName.. "."
    end
    if (e.SubType == AutoBiographerEnum.KillEventSubType.FirstKill) then
      local unitName = "#" .. e.CatalogUnitId
      if (catalogs ~= nil and catalogs.UnitCatalog ~= nil and catalogs.UnitCatalog[e.CatalogUnitId] ~= nil and catalogs.UnitCatalog[e.CatalogUnitId].Name ~= nil) then unitName = catalogs.UnitCatalog[e.CatalogUnitId].Name end
      return timestampString .. "You killed " .. unitName .. " for the first time."
    end
  elseif (e.Type == AutoBiographerEnum.EventType.Level) then
    if (e.SubType == AutoBiographerEnum.LevelEventSubType.LevelUp) then
      return timestampString .. "You hit level " .. e.LevelNum .. "."
    end
  elseif (e.Type == AutoBiographerEnum.EventType.Map) then
    if (e.SubType == AutoBiographerEnum.MapEventSubType.SubZoneFirstVisit) then
      local zoneName = "?"
      if (catalogs ~= nil and catalogs.SubZoneCatalog ~= nil and catalogs.SubZoneCatalog[e.SubZoneName] ~= nil and catalogs.SubZoneCatalog[e.SubZoneName].ZoneName ~= nil) then zoneName = catalogs.SubZoneCatalog[e.SubZoneName].ZoneName end
      return timestampString .. "You entered " .. e.SubZoneName .. " (" .. zoneName .. ") for the first time."
    end
    if (e.SubType == AutoBiographerEnum.MapEventSubType.ZoneFirstVisit) then
      return timestampString .. "You entered " .. e.ZoneName .. " for the first time."
    end
  elseif (e.Type == AutoBiographerEnum.EventType.Spell) then
    if (e.SubType == AutoBiographerEnum.SpellEventSubType.SpellLearned) then
      local spellText = "spell #" .. e.SpellId
      if (catalogs and catalogs.SpellCatalog and catalogs.SpellCatalog[e.SpellId] and catalogs.SpellCatalog[e.SpellId].Name) then 
        spellText = catalogs.SpellCatalog[e.SpellId].Name 
        if (catalogs.SpellCatalog[e.SpellId].Rank) then spellText = spellText .. " (Rank " .. catalogs.SpellCatalog[e.SpellId].Rank .. ")" end
      end
      return timestampString .. "You learned " .. spellText .. "."
    end
  elseif (e.Type == AutoBiographerEnum.EventType.Quest) then
    if (e.SubType == AutoBiographerEnum.QuestEventSubType.QuestTurnIn) then
      return timestampString .. "You turned in " .. e.QuestTitle .. "."
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

-- *** Concrete Events ***

BossKillEvent = {}
function BossKillEvent.New(timestamp, coordinates, bossId, bossName)
  local newInstance = WorldEvent.New(timestamp, AutoBiographerEnum.EventType.Kill, AutoBiographerEnum.KillEventSubType.BossKill, coordinates)
  newInstance.BossId = bossId
  newInstance.BossName = bossName
  
  return newInstance
end

FirstKillEvent = {}
function FirstKillEvent.New(timestamp, coordinates, catalogUnitId)
  local newInstance = WorldEvent.New(timestamp, AutoBiographerEnum.EventType.Kill, AutoBiographerEnum.KillEventSubType.FirstKill, coordinates)
  newInstance.CatalogUnitId = catalogUnitId
  
  return newInstance
end

LevelUpEvent = {}
function LevelUpEvent.New(timestamp, coordinates, levelNum)
  local newInstance = WorldEvent.New(timestamp, AutoBiographerEnum.EventType.Level, AutoBiographerEnum.LevelEventSubType.LevelUp, coordinates)
  newInstance.LevelNum = levelNum
  
  return newInstance
end

PlayerDeathEvent = {}
function PlayerDeathEvent.New(timestamp, coordinates, killerCatalogUnitId, killerLevel)
  local newInstance = WorldEvent.New(timestamp, AutoBiographerEnum.EventType.Death, AutoBiographerEnum.DeathEventSubType.PlayerDeath, coordinates)
  newInstance.KillerCuid = killerCatalogUnitId
  newInstance.KillerLevel = killerLevel
  
  return newInstance
end

QuestTurnInEvent = {}
function QuestTurnInEvent.New(timestamp, coordinates, questId, questTitle, xpGained, moneyGained)
  local newInstance = WorldEvent.New(timestamp, AutoBiographerEnum.EventType.Quest, AutoBiographerEnum.QuestEventSubType.QuestTurnIn, coordinates)
  newInstance.QuestId = questId
  newInstance.QuestTitle = questTitle
  newInstance.XpGained = xpGained
  newInstance.MoneyGained = moneyGained
  
  return newInstance
end

SpellLearnedEvent = {}
function SpellLearnedEvent.New(timestamp, coordinates, spellId)
  local newInstance = WorldEvent.New(timestamp, AutoBiographerEnum.EventType.Spell, AutoBiographerEnum.SpellEventSubType.SpellLearned, coordinates)
  newInstance.SpellId = spellId
  
  return newInstance
end

SubZoneFirstVisitEvent = {}
function SubZoneFirstVisitEvent.New(timestamp, coordinates, subZoneName)
  local newInstance = WorldEvent.New(timestamp, AutoBiographerEnum.EventType.Map, AutoBiographerEnum.MapEventSubType.SubZoneFirstVisit, coordinates)
  newInstance.SubZoneName = subZoneName
  
  return newInstance
end

ZoneFirstVisitEvent = {}
function ZoneFirstVisitEvent.New(timestamp, coordinates, zoneName)
  local newInstance = WorldEvent.New(timestamp, AutoBiographerEnum.EventType.Map, AutoBiographerEnum.MapEventSubType.ZoneFirstVisit, coordinates)
  newInstance.ZoneName = zoneName
  
  return newInstance
end
