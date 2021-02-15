Event = {}
function Event.New(timestamp, type, subType)
  return {
    Timestamp = timestamp,
    Type = type,
    SubType = subType
  }
end

function Event.GetIconPath(e)
  if (e.Type == AutoBiographerEnum.EventType.Death) then
    if (e.SubType == AutoBiographerEnum.EventSubType.PlayerDeath) then
      return "Interface\\Icons\\ability_backstab"
    end
  elseif (e.Type == AutoBiographerEnum.EventType.Item) then
    if (e.SubType == AutoBiographerEnum.EventSubType.FirstAcquiredItem) then
      return "Interface\\Icons\\inv_misc_bag_10_red"
    end
  elseif (e.Type == AutoBiographerEnum.EventType.Kill) then
    if (e.SubType == AutoBiographerEnum.EventSubType.BossKill) then
      return "Interface\\Icons\\ability_warrior_challange"
    elseif (e.SubType == AutoBiographerEnum.EventSubType.FirstKill) then
      return "Interface\\Icons\\ability_dualwield"
    end
  elseif (e.Type == AutoBiographerEnum.EventType.Level) then
    if (e.SubType == AutoBiographerEnum.EventSubType.LevelUp) then
      return "Interface\\Icons\\ability_mount_charger"
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
  elseif (e.Type == AutoBiographerEnum.EventType.Quest) then
    if (e.SubType == AutoBiographerEnum.EventSubType.QuestTurnIn) then
      return "Interface\\Icons\\inv_enchant_shardbrilliantlarge"
    end
  end
  
  return "Interface\\Icons\\inv_misc_questionmark"
end

function Event.ToString(e, catalogs)
  local timestampString = HelperFunctions.TimestampToDateString(e.Timestamp) .. ": "

  if (e.Type == AutoBiographerEnum.EventType.Battleground) then
    if (e.SubType == AutoBiographerEnum.EventSubType.BattlegroundJoined) then
      return timestampString .. "You joined " .. BattlegroundDatabase[e.BattlegroundId] .. "."
    elseif (e.SubType == AutoBiographerEnum.EventSubType.BattlegroundLost) then
      return timestampString .. "You lost " .. BattlegroundDatabase[e.BattlegroundId] .. "."
    elseif (e.SubType == AutoBiographerEnum.EventSubType.BattlegroundWon) then
      return timestampString .. "You won " .. BattlegroundDatabase[e.BattlegroundId] .. "."
    end
  elseif (e.Type == AutoBiographerEnum.EventType.Death) then
    if (e.SubType == AutoBiographerEnum.EventSubType.PlayerDeath) then
      if (e.KillerCuid == nil) then
        return timestampString .. "You died."
      else
        local unitName = "#" .. e.KillerCuid
        if (catalogs ~= nil and catalogs.UnitCatalog ~= nil and catalogs.UnitCatalog[e.KillerCuid] ~= nil) then
          if (catalogs.UnitCatalog[e.KillerCuid].UType ~= nil and catalogs.UnitCatalog[e.KillerCuid].UType == AutoBiographerEnum.UnitType.Pet) then
            unitName = "a pet"
          elseif (catalogs.UnitCatalog[e.KillerCuid].Name ~= nil) then
            unitName = catalogs.UnitCatalog[e.KillerCuid].Name
          end  
        end 

        local killerLevelText = ""
        if (e.KillerLevel ~= nil) then 
          local killerLevel = e.KillerLevel
          if (killerLevel == -1) then killerLevel = "?" end
          killerLevelText = " (level " .. tostring(killerLevel) .. ")"
        end
        return timestampString .. "You were killed by " .. unitName .. killerLevelText .. "."
      end
    end
  elseif (e.Type == AutoBiographerEnum.EventType.Guild) then
    if (e.SubType == AutoBiographerEnum.EventSubType.GuildJoined) then
      return timestampString .. "You joined " .. e.GuildName.. "."
    elseif (e.SubType == AutoBiographerEnum.EventSubType.GuildLeft) then
      return timestampString .. "You left " .. e.GuildName.. "."
    elseif (e.SubType == AutoBiographerEnum.EventSubType.GuildRankChanged) then
      return timestampString .. "Your guild rank was changed to " .. e.GuildRankName.. " (" .. e.GuildRankIndex .. ")."
    end
  elseif (e.Type == AutoBiographerEnum.EventType.Item) then
    if (e.SubType == AutoBiographerEnum.EventSubType.FirstAcquiredItem) then
      local itemName = "#" .. e.CatalogItemId
      if (catalogs and catalogs.ItemCatalog and catalogs.ItemCatalog[e.CatalogItemId] and catalogs.ItemCatalog[e.CatalogItemId].Name) then itemName = catalogs.ItemCatalog[e.CatalogItemId].Name end
      return timestampString .. "You acquired " .. itemName .. " for the first time."
    end
  elseif (e.Type == AutoBiographerEnum.EventType.Kill) then
    if (e.SubType == AutoBiographerEnum.EventSubType.BossKill) then
      local bossName = "boss #" .. e.BossId
      if (e.BossName ~= nil) then bossName = e.BossName end
      return timestampString .. "You defeated " .. bossName .. "."
    elseif (e.SubType == AutoBiographerEnum.EventSubType.FirstKill) then
      local unitName = "#" .. e.CatalogUnitId
      if (catalogs ~= nil and catalogs.UnitCatalog ~= nil and catalogs.UnitCatalog[e.CatalogUnitId] ~= nil and catalogs.UnitCatalog[e.CatalogUnitId].Name ~= nil) then unitName = catalogs.UnitCatalog[e.CatalogUnitId].Name end
      return timestampString .. "You killed " .. unitName .. " for the first time."
    end
  elseif (e.Type == AutoBiographerEnum.EventType.Level) then
    if (e.SubType == AutoBiographerEnum.EventSubType.LevelUp) then
      return timestampString .. "You hit level " .. e.LevelNum .. "."
    end
  elseif (e.Type == AutoBiographerEnum.EventType.Map) then
    if (e.SubType == AutoBiographerEnum.EventSubType.SubZoneFirstVisit) then
      local zoneName = "?"
      if (catalogs ~= nil and catalogs.SubZoneCatalog ~= nil and catalogs.SubZoneCatalog[e.SubZoneName] ~= nil and catalogs.SubZoneCatalog[e.SubZoneName].ZoneName ~= nil) then zoneName = catalogs.SubZoneCatalog[e.SubZoneName].ZoneName end
      return timestampString .. "You entered " .. e.SubZoneName .. " (" .. zoneName .. ") for the first time."
    elseif (e.SubType == AutoBiographerEnum.EventSubType.ZoneFirstVisit) then
      return timestampString .. "You entered " .. e.ZoneName .. " for the first time."
    end
  elseif (e.Type == AutoBiographerEnum.EventType.Reputation) then
    if (e.SubType == AutoBiographerEnum.EventSubType.ReputationLevelChanged) then
      return timestampString .. "You became " .. e.ReputationLevel .. " with " .. e.Faction .. "."
    end
  elseif (e.Type == AutoBiographerEnum.EventType.Skill) then
    if (e.SubType == AutoBiographerEnum.EventSubType.SkillMilestone) then
      return timestampString .. "Your skill in " .. e.SkillName .. " increased to " .. e.SkillLevel .. "."
    end
  elseif (e.Type == AutoBiographerEnum.EventType.Spell) then
    if (e.SubType == AutoBiographerEnum.EventSubType.SpellLearned) then
      local spellText = "spell #" .. e.SpellId
      if (catalogs and catalogs.SpellCatalog and catalogs.SpellCatalog[e.SpellId] and catalogs.SpellCatalog[e.SpellId].Name) then 
        spellText = catalogs.SpellCatalog[e.SpellId].Name 
        if (catalogs.SpellCatalog[e.SpellId].Rank) then spellText = spellText .. " (Rank " .. catalogs.SpellCatalog[e.SpellId].Rank .. ")" end
      end
      return timestampString .. "You learned " .. spellText .. "."
    end
  elseif (e.Type == AutoBiographerEnum.EventType.Quest) then
    if (e.SubType == AutoBiographerEnum.EventSubType.QuestTurnIn) then
      return timestampString .. "You turned in " .. e.QuestTitle .. "."
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

FirstAcquiredItemEvent = {}
function FirstAcquiredItemEvent.New(timestamp, coordinates, catalogItemId)
  local newInstance = WorldEvent.New(timestamp, AutoBiographerEnum.EventType.Item, AutoBiographerEnum.EventSubType.FirstAcquiredItem, coordinates)
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
function PlayerDeathEvent.New(timestamp, coordinates, killerCatalogUnitId, killerLevel)
  local newInstance = WorldEvent.New(timestamp, AutoBiographerEnum.EventType.Death, AutoBiographerEnum.EventSubType.PlayerDeath, coordinates)
  newInstance.KillerCuid = killerCatalogUnitId
  newInstance.KillerLevel = killerLevel
  
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
