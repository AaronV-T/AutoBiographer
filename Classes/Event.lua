local L = AutoBiographer_L
Event = {}
function Event.New(timestamp, type, subType)
  return {
    Timestamp = timestamp,
    Type = type,
    SubType = subType
  }
end

function Event.GetIconPath(e)
  if (e.Type == AutoBiographerEnum.EventType.Custom) then
    if (e.SubType == AutoBiographerEnum.EventSubType.Custom) then
      return "Interface\\Icons\\inv_misc_note_06"
    end
  elseif (e.Type == AutoBiographerEnum.EventType.Death) then
    if (e.SubType == AutoBiographerEnum.EventSubType.PlayerDeath) then
      return "Interface\\Icons\\ability_backstab"
    end
  elseif (e.Type == AutoBiographerEnum.EventType.Item) then
    if (e.SubType == AutoBiographerEnum.EventSubType.FirstAcquiredItem) then
      return "Interface\\Icons\\inv_misc_bag_10_black"
    elseif (e.SubType == AutoBiographerEnum.EventSubType.FirstEquippedItem) then
      return "Interface\\Icons\\inv_chest_chain_05"
    end
  elseif (e.Type == AutoBiographerEnum.EventType.Kill) then
    if (e.SubType == AutoBiographerEnum.EventSubType.BossKill) then
      return "Interface\\Icons\\ability_warrior_challange"
    elseif (e.SubType == AutoBiographerEnum.EventSubType.FirstKill) then
      return "Interface\\Icons\\ability_dualwield"
    end
  elseif (e.Type == AutoBiographerEnum.EventType.Level) then
    if (e.SubType == AutoBiographerEnum.EventSubType.LevelUp) then
      return "Interface\\Icons\\spell_holy_innerfire"
    end
  elseif (e.Type == AutoBiographerEnum.EventType.Map) then
    if (e.SubType == AutoBiographerEnum.EventSubType.SubZoneFirstVisit) then
      return "Interface\\Icons\\inv_misc_map_01"
    elseif (e.SubType == AutoBiographerEnum.EventSubType.ZoneFirstVisit) then
      return "Interface\\Icons\\inv_misc_map_01"
    end
  elseif (e.Type == AutoBiographerEnum.EventType.Reputation) then
    if (e.SubType == AutoBiographerEnum.EventSubType.ReputationLevelChanged) then
      return "Interface\\Icons\\inv_bijou_green"
    end
  elseif (e.Type == AutoBiographerEnum.EventType.Skill) then
    if (e.SubType == AutoBiographerEnum.EventSubType.SkillMilestone) then
      return "Interface\\Icons\\inv_bijou_blue"
    end
  elseif (e.Type == AutoBiographerEnum.EventType.Spell) then
    if (e.SubType == AutoBiographerEnum.EventSubType.SpellLearned) then
      return "Interface\\Icons\\inv_helmet_53"
    end
  elseif (e.Type == AutoBiographerEnum.EventType.Statistic) then
    if (e.SubType == AutoBiographerEnum.EventSubType.StatisticMilestone) then
      return "Interface\\Icons\\inv_bijou_red"
    end
  elseif (e.Type == AutoBiographerEnum.EventType.Quest) then
    if (e.SubType == AutoBiographerEnum.EventSubType.QuestTurnIn) then
      return "Interface\\AddOns\\AutoBiographer\\Icons\\quest-turn-in-gold"
    end
  end
  
  return "Interface\\Icons\\inv_misc_questionmark"
end

function Event.GetMapCoordinates(event)
  if (not event.Coordinates) then
    return nil
  end

  if (event.Coordinates.MapId ~= nil and event.Coordinates.X ~= nil and event.Coordinates.Y ~= nil) then
    return event.Coordinates
  end

  if (event.Coordinates.InstanceId ~= nil and AutoBiographer_Databases.InstanceLocationDatabase[event.Coordinates.InstanceId]) then
    return AutoBiographer_Databases.InstanceLocationDatabase[event.Coordinates.InstanceId]
  end

  return nil
end

function Event.ToString(e, catalogs, excludeTimestamp)
  local timestampString = excludeTimestamp and "" or (HelperFunctions.TimestampToDateString(e.Timestamp) .. ": ")

  if (e.Type == AutoBiographerEnum.EventType.Arena) then    
    local arenaTypeString
    if (e.Registered) then arenaTypeString = L["rated arena"]
    else arenaTypeString = L["arena skirmish"]
    end

    if (e.SubType == AutoBiographerEnum.EventSubType.ArenaJoined) then
      return timestampString .. L("You joined a %sv%s %s (%s).", e.TeamSize, e.TeamSize, arenaTypeString, L[AutoBiographer_Databases.ArenaDatabase[e.ArenaId]])
    elseif (e.SubType == AutoBiographerEnum.EventSubType.ArenaLost) then
      return timestampString .. L("You lost a %sv%s %s (%s).", e.TeamSize, e.TeamSize, arenaTypeString, L[AutoBiographer_Databases.ArenaDatabase[e.ArenaId]])
    elseif (e.SubType == AutoBiographerEnum.EventSubType.ArenaWon) then
      return timestampString .. L("You won a %sv%s %s (%s).", e.TeamSize, e.TeamSize, arenaTypeString, L[AutoBiographer_Databases.ArenaDatabase[e.ArenaId]])
    end
  elseif (e.Type == AutoBiographerEnum.EventType.Battleground) then
    if (e.SubType == AutoBiographerEnum.EventSubType.BattlegroundJoined) then
      return timestampString .. L("You joined %s.", L[AutoBiographer_Databases.BattlegroundDatabase[e.BattlegroundId]])
    elseif (e.SubType == AutoBiographerEnum.EventSubType.BattlegroundLost) then
      return timestampString .. L("You lost %s.", L[AutoBiographer_Databases.BattlegroundDatabase[e.BattlegroundId]])
    elseif (e.SubType == AutoBiographerEnum.EventSubType.BattlegroundWon) then
      return timestampString .. L("You won %s.", L[AutoBiographer_Databases.BattlegroundDatabase[e.BattlegroundId]])
    end
  elseif (e.Type == AutoBiographerEnum.EventType.Custom) then
    return timestampString .. "\"" .. e.Text .. "\""
  elseif (e.Type == AutoBiographerEnum.EventType.Death) then
    if (e.SubType == AutoBiographerEnum.EventSubType.PlayerDeath) then
      if (e.KillerCuid == nil) then
        if (e.EnvironmentalType == "Drowning" or e.EnvironmentalType == "Falling") then
          return timestampString .. (e.EnvironmentalType == "Drowning" and L["You drowned."] or L["You died from a fall."])
        end
        return timestampString .. L["You died."]
      else
        local unitName = "#" .. e.KillerCuid
        if (catalogs ~= nil and catalogs.UnitCatalog ~= nil and catalogs.UnitCatalog[e.KillerCuid] ~= nil) then
          if (catalogs.UnitCatalog[e.KillerCuid].UType ~= nil and catalogs.UnitCatalog[e.KillerCuid].UType == AutoBiographerEnum.UnitType.Pet) then
            unitName = L["a pet"]
          elseif (catalogs.UnitCatalog[e.KillerCuid].Name ~= nil) then
            unitName = catalogs.UnitCatalog[e.KillerCuid].Name
          end  
        end 

        local killerLevelText = ""
        if (e.KillerLevel ~= nil) then 
          local killerLevel = e.KillerLevel
          if (killerLevel == -1) then killerLevel = "?" end
          killerLevelText = L(" (level %s)", tostring(killerLevel))
        end
        return timestampString .. L("You were killed by %s%s.", unitName, killerLevelText)
      end
    end
  elseif (e.Type == AutoBiographerEnum.EventType.Guild) then
    if (e.SubType == AutoBiographerEnum.EventSubType.GuildJoined) then
      return timestampString .. L("You joined the guild %s.", e.GuildName)
    elseif (e.SubType == AutoBiographerEnum.EventSubType.GuildLeft) then
      return timestampString .. L("You left the guild %s.", e.GuildName)
    elseif (e.SubType == AutoBiographerEnum.EventSubType.GuildRankChanged) then
      return timestampString .. L("Your guild rank was changed to %s (%s).", e.GuildRankName, e.GuildRankIndex)
    end
  elseif (e.Type == AutoBiographerEnum.EventType.Item) then
    if (e.SubType == AutoBiographerEnum.EventSubType.FirstAcquiredItem) then
      local itemName = "#" .. e.CatalogItemId
      if (catalogs and catalogs.ItemCatalog and catalogs.ItemCatalog[e.CatalogItemId] and catalogs.ItemCatalog[e.CatalogItemId].Name) then itemName = catalogs.ItemCatalog[e.CatalogItemId].Name end
      return timestampString .. L("You acquired %s for the first time.", itemName)
    elseif (e.SubType == AutoBiographerEnum.EventSubType.FirstEquippedItem) then
      local itemName = "#" .. e.CatalogItemId
      if (catalogs and catalogs.ItemCatalog and catalogs.ItemCatalog[e.CatalogItemId] and catalogs.ItemCatalog[e.CatalogItemId].Name) then itemName = catalogs.ItemCatalog[e.CatalogItemId].Name end
      return timestampString .. L("You equipped %s for the first time.", itemName)
    end
  elseif (e.Type == AutoBiographerEnum.EventType.Kill) then
    if (e.SubType == AutoBiographerEnum.EventSubType.BossKill) then
      local bossName = L["boss #"] .. e.BossId
      if (e.BossName ~= nil) then bossName = e.BossName end
      return timestampString .. L("You defeated %s.", bossName)
    elseif (e.SubType == AutoBiographerEnum.EventSubType.FirstKill) then
      local unitName = "#" .. e.CatalogUnitId
      if (catalogs ~= nil and catalogs.UnitCatalog ~= nil and catalogs.UnitCatalog[e.CatalogUnitId] ~= nil and catalogs.UnitCatalog[e.CatalogUnitId].Name ~= nil) then unitName = catalogs.UnitCatalog[e.CatalogUnitId].Name end
      return timestampString .. L("You killed %s for the first time.", unitName)
    end
  elseif (e.Type == AutoBiographerEnum.EventType.Level) then
    if (e.SubType == AutoBiographerEnum.EventSubType.LevelUp) then
      return timestampString .. L("You hit level %s.", e.LevelNum)
    end
  elseif (e.Type == AutoBiographerEnum.EventType.Map) then
    if (e.SubType == AutoBiographerEnum.EventSubType.SubZoneFirstVisit) then
      local zoneName = "?"
      if (catalogs ~= nil and catalogs.SubZoneCatalog ~= nil and catalogs.SubZoneCatalog[e.SubZoneName] ~= nil and catalogs.SubZoneCatalog[e.SubZoneName].ZoneName ~= nil) then zoneName = catalogs.SubZoneCatalog[e.SubZoneName].ZoneName end
      return timestampString .. L("You entered %s (%s) for the first time.", e.SubZoneName, zoneName)
    elseif (e.SubType == AutoBiographerEnum.EventSubType.ZoneFirstVisit) then
      return timestampString .. L("You entered %s for the first time.", e.ZoneName)
    end
  elseif (e.Type == AutoBiographerEnum.EventType.Reputation) then
    if (e.SubType == AutoBiographerEnum.EventSubType.ReputationLevelChanged) then
      return timestampString .. L("You became %s with %s.", L[e.ReputationLevel], e.Faction)
    end
  elseif (e.Type == AutoBiographerEnum.EventType.Skill) then
    if (e.SubType == AutoBiographerEnum.EventSubType.SkillMilestone) then
      return timestampString .. L("Your skill in %s increased to %s.", e.SkillName, e.SkillLevel)
    end
  elseif (e.Type == AutoBiographerEnum.EventType.Spell) then
    if (e.SubType == AutoBiographerEnum.EventSubType.SpellLearned) then
      local spellText = L["spell #"] .. e.SpellId
      if (catalogs and catalogs.SpellCatalog and catalogs.SpellCatalog[e.SpellId] and catalogs.SpellCatalog[e.SpellId].Name) then 
        spellText = catalogs.SpellCatalog[e.SpellId].Name 
        if (catalogs.SpellCatalog[e.SpellId].Rank) then spellText = spellText .. L(" (Rank %s)", catalogs.SpellCatalog[e.SpellId].Rank) end
      end
      return timestampString .. L("You learned %s.", spellText)
    end
  elseif (e.Type == AutoBiographerEnum.EventType.Statistic) then
    if (e.SubType == AutoBiographerEnum.EventSubType.StatisticMilestone) then
      return timestampString .. L("You have %s!", L[e.Text])
    end
  elseif (e.Type == AutoBiographerEnum.EventType.Quest) then
    if (e.SubType == AutoBiographerEnum.EventSubType.QuestTurnIn) then
      return timestampString .. L("You turned in %s.", e.QuestTitle)
    end
  end
  
  return timestampString .. "Event with type '" .. e.Type .. "' and subType '" .. e.SubType .. "'."
end

WorldEvent = {}
function WorldEvent.New(timestamp, type, subType, coordinates)
  local newInstance = Event.New(timestamp, type, subType)
  newInstance.Coordinates = coordinates
  
  return newInstance
end

-- *** Concrete Events ***

ArenaJoinedEvent = {}
function ArenaJoinedEvent.New(timestamp, registered, teamSize, arenaId)
  local newInstance = Event.New(timestamp, AutoBiographerEnum.EventType.Arena, AutoBiographerEnum.EventSubType.ArenaJoined)
  newInstance.ArenaId = arenaId
  newInstance.Registered = registered
  newInstance.TeamSize = teamSize
  
  return newInstance
end

ArenaLostEvent = {}
function ArenaLostEvent.New(timestamp, registered, teamSize, arenaId)
  local newInstance = Event.New(timestamp, AutoBiographerEnum.EventType.Arena, AutoBiographerEnum.EventSubType.ArenaLost)
  newInstance.ArenaId = arenaId
  newInstance.Registered = registered
  newInstance.TeamSize = teamSize
  
  return newInstance
end

ArenaWonEvent = {}
function ArenaWonEvent.New(timestamp, registered, teamSize, arenaId)
  local newInstance = Event.New(timestamp, AutoBiographerEnum.EventType.Arena, AutoBiographerEnum.EventSubType.ArenaWon)
  newInstance.ArenaId = arenaId
  newInstance.Registered = registered
  newInstance.TeamSize = teamSize
  
  return newInstance
end

BattlegroundJoinedEvent = {}
function BattlegroundJoinedEvent.New(timestamp, battlegroundId)
  local newInstance = Event.New(timestamp, AutoBiographerEnum.EventType.Battleground, AutoBiographerEnum.EventSubType.BattlegroundJoined)
  newInstance.BattlegroundId = battlegroundId
  
  return newInstance
end

BattlegroundLostEvent = {}
function BattlegroundLostEvent.New(timestamp, battlegroundId)
  local newInstance = Event.New(timestamp, AutoBiographerEnum.EventType.Battleground, AutoBiographerEnum.EventSubType.BattlegroundLost)
  newInstance.BattlegroundId = battlegroundId
  
  return newInstance
end

BattlegroundWonEvent = {}
function BattlegroundWonEvent.New(timestamp, battlegroundId)
  local newInstance = Event.New(timestamp, AutoBiographerEnum.EventType.Battleground, AutoBiographerEnum.EventSubType.BattlegroundWon)
  newInstance.BattlegroundId = battlegroundId
  
  return newInstance
end

BossKillEvent = {}
function BossKillEvent.New(timestamp, coordinates, bossId, bossName)
  local newInstance = WorldEvent.New(timestamp, AutoBiographerEnum.EventType.Kill, AutoBiographerEnum.EventSubType.BossKill, coordinates)
  newInstance.BossId = bossId
  newInstance.BossName = bossName
  
  return newInstance
end

CustomEvent = {}
function CustomEvent.New(timestamp, coordinates, text)
  local newInstance = WorldEvent.New(timestamp, AutoBiographerEnum.EventType.Custom, AutoBiographerEnum.EventSubType.Custom, coordinates)
  newInstance.Text = text
  
  return newInstance
end

FirstAcquiredItemEvent = {}
function FirstAcquiredItemEvent.New(timestamp, coordinates, catalogItemId)
  local newInstance = WorldEvent.New(timestamp, AutoBiographerEnum.EventType.Item, AutoBiographerEnum.EventSubType.FirstAcquiredItem, coordinates)
  newInstance.CatalogItemId = catalogItemId
  
  return newInstance
end

FirstEquippedItemEvent = {}
function FirstEquippedItemEvent.New(timestamp, coordinates, catalogItemId)
  local newInstance = WorldEvent.New(timestamp, AutoBiographerEnum.EventType.Item, AutoBiographerEnum.EventSubType.FirstEquippedItem, coordinates)
  newInstance.CatalogItemId = catalogItemId

  return newInstance
end

FirstKillEvent = {}
function FirstKillEvent.New(timestamp, coordinates, catalogUnitId)
  local newInstance = WorldEvent.New(timestamp, AutoBiographerEnum.EventType.Kill, AutoBiographerEnum.EventSubType.FirstKill, coordinates)
  newInstance.CatalogUnitId = catalogUnitId
  
  return newInstance
end

GuildJoinedEvent = {}
function GuildJoinedEvent.New(timestamp, guildName)
  local newInstance = Event.New(timestamp, AutoBiographerEnum.EventType.Guild, AutoBiographerEnum.EventSubType.GuildJoined)
  newInstance.GuildName = guildName
  
  return newInstance
end

GuildLeftEvent = {}
function GuildLeftEvent.New(timestamp, guildName)
  local newInstance = Event.New(timestamp, AutoBiographerEnum.EventType.Guild, AutoBiographerEnum.EventSubType.GuildLeft)
  newInstance.GuildName = guildName
  
  return newInstance
end

GuildRankChangedEvent = {}
function GuildRankChangedEvent.New(timestamp, guildRankIndex, guildRankName)
  local newInstance = Event.New(timestamp, AutoBiographerEnum.EventType.Guild, AutoBiographerEnum.EventSubType.GuildRankChanged)
  newInstance.GuildRankIndex = guildRankIndex
  newInstance.GuildRankName = guildRankName
  
  return newInstance
end

LevelUpEvent = {}
function LevelUpEvent.New(timestamp, coordinates, levelNum)
  local newInstance = WorldEvent.New(timestamp, AutoBiographerEnum.EventType.Level, AutoBiographerEnum.EventSubType.LevelUp, coordinates)
  newInstance.LevelNum = levelNum
  
  return newInstance
end

PlayerDeathEvent = {}
function PlayerDeathEvent.New(timestamp, coordinates, killerCatalogUnitId, killerLevel, environmentalType)
  local newInstance = WorldEvent.New(timestamp, AutoBiographerEnum.EventType.Death, AutoBiographerEnum.EventSubType.PlayerDeath, coordinates)
  newInstance.KillerCuid = killerCatalogUnitId
  newInstance.KillerLevel = killerLevel
  newInstance.EnvironmentalType = environmentalType
  
  return newInstance
end

QuestTurnInEvent = {}
function QuestTurnInEvent.New(timestamp, coordinates, questId, questTitle, xpGained, moneyGained)
  local newInstance = WorldEvent.New(timestamp, AutoBiographerEnum.EventType.Quest, AutoBiographerEnum.EventSubType.QuestTurnIn, coordinates)
  newInstance.QuestId = questId
  newInstance.QuestTitle = questTitle
  newInstance.XpGained = xpGained
  newInstance.MoneyGained = moneyGained
  
  return newInstance
end

ReputationLevelChangedEvent = {}
function ReputationLevelChangedEvent.New(timestamp, coordinates, faction, reputationLevel)
  local newInstance = WorldEvent.New(timestamp, AutoBiographerEnum.EventType.Reputation, AutoBiographerEnum.EventSubType.ReputationLevelChanged, coordinates)
  newInstance.Faction = faction
  newInstance.ReputationLevel = reputationLevel
  
  return newInstance
end

SkillMilestoneEvent = {}
function SkillMilestoneEvent.New(timestamp, coordinates, skillName, skillLevel)
  local newInstance = WorldEvent.New(timestamp, AutoBiographerEnum.EventType.Skill, AutoBiographerEnum.EventSubType.SkillMilestone, coordinates)
  newInstance.SkillName = skillName
  newInstance.SkillLevel = skillLevel
  
  return newInstance
end

SpellLearnedEvent = {}
function SpellLearnedEvent.New(timestamp, coordinates, spellId)
  local newInstance = WorldEvent.New(timestamp, AutoBiographerEnum.EventType.Spell, AutoBiographerEnum.EventSubType.SpellLearned, coordinates)
  newInstance.SpellId = spellId
  
  return newInstance
end

StatisticMilestoneEvent = {}
function StatisticMilestoneEvent.New(timestamp, coordinates, statistic, amount, text)
  local newInstance = WorldEvent.New(timestamp, AutoBiographerEnum.EventType.Statistic, AutoBiographerEnum.EventSubType.StatisticMilestone, coordinates)
  newInstance.Statistic = statistic
  newInstance.Amount = amount
  newInstance.Text = text

  return newInstance
end

SubZoneFirstVisitEvent = {}
function SubZoneFirstVisitEvent.New(timestamp, coordinates, subZoneName)
  local newInstance = WorldEvent.New(timestamp, AutoBiographerEnum.EventType.Map, AutoBiographerEnum.EventSubType.SubZoneFirstVisit, coordinates)
  newInstance.SubZoneName = subZoneName
  
  return newInstance
end

ZoneFirstVisitEvent = {}
function ZoneFirstVisitEvent.New(timestamp, coordinates, zoneName)
  local newInstance = WorldEvent.New(timestamp, AutoBiographerEnum.EventType.Map, AutoBiographerEnum.EventSubType.ZoneFirstVisit, coordinates)
  newInstance.ZoneName = zoneName
  
  return newInstance
end
