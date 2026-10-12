AutoBiographer_Controller = {
  AccountData = {},
  CharacterData = {},
  Logs = {},
  Temp = {},
}

local Controller = AutoBiographer_Controller
local Api = AutoBiographer_Api

function Controller:AddCompanionFamilyTime(familyId, familyName, seconds)
  if (not familyId or seconds <= 0) then return end
  local catalogs = self.CharacterData.Catalogs
  catalogs.CompanionFamilyCatalog = catalogs.CompanionFamilyCatalog or {}
  if (familyName) then catalogs.CompanionFamilyCatalog[familyId] = familyName end
  local statistics = self:GetCurrentLevelStatistics()
  statistics.TimeStatisticsByCompanionFamily = statistics.TimeStatisticsByCompanionFamily or {}
  statistics.TimeStatisticsByCompanionFamily[familyId] = (statistics.TimeStatisticsByCompanionFamily[familyId] or 0) + seconds
  AutoBiographer_Milestones:OnCompanionFamilyTime(familyId, familyName, seconds)
end

function Controller:AddDistance(distanceTrackingType, yards)
  if (distanceTrackingType == nil or yards <= 0) then return end
  local levelStatistics = self:GetCurrentLevelStatistics()
  -- Create lazily for characters whose existing level records predate tracking.
  if (not levelStatistics.DistanceStatistics) then levelStatistics.DistanceStatistics = DistanceStatistics.New() end
  DistanceStatistics.AddDistance(levelStatistics.DistanceStatistics, distanceTrackingType, yards)
  AutoBiographer_Milestones:OnStatChanged("Distance")
end

function Controller:AddEvent(event)
  table.insert(self.CharacterData.Events, event)
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog(Event.ToString(self.CharacterData.Events[#self.CharacterData.Events], self.CharacterData.Catalogs), AutoBiographerEnum.LogLevel.Debug) end
  if (AutoBiographer_EventWindow and AutoBiographer_EventWindow.QueueRefresh) then
    AutoBiographer_EventWindow:QueueRefresh()
  end
end

function Controller:AddLog(text, logLevel)
  if (logLevel == nil) then error("Unspecified logLevel. Log Text: '" .. text .. "'") end
  
  table.insert(self.Logs, {
    Level = logLevel, Text = tostring(text),
    Timestamp = time(),
  })
  
  if (AutoBiographer_DebugWindow and AutoBiographer_DebugWindow.LogsUpdated) then
    AutoBiographer_DebugWindow:LogsUpdated()
  end
end

function Controller:AddOtherPlayerInGroupTime(otherPlayerGuid, seconds)
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("AddOtherPlayerInGroupTime: " .. " #" .. tostring(otherPlayerGuid) .. ", " .. tostring(seconds) .. " seconds.", AutoBiographerEnum.LogLevel.Debug) end
  if (not otherPlayerGuid) then
    Controller:AddLog("otherPlayerGuid was nil.", AutoBiographerEnum.LogLevel.Error)
    return
  end
  
  if (not self:GetCurrentLevelStatistics().OtherPlayerStatisticsByOtherPlayer[otherPlayerGuid]) then self:GetCurrentLevelStatistics().OtherPlayerStatisticsByOtherPlayer[otherPlayerGuid] = OtherPlayerStatistics.New() end
  OtherPlayerStatistics.Add(self:GetCurrentLevelStatistics().OtherPlayerStatisticsByOtherPlayer[otherPlayerGuid], AutoBiographerEnum.OtherPlayerTrackingType.TimeSpentGroupedWithPlayer, seconds)
end

function Controller:AddSpellTime(spellId, seconds)
  if (not spellId or seconds <= 0) then return end
  local catalog = self.CharacterData.Catalogs.SpellCatalog
  if (not catalog[spellId] or not catalog[spellId].Name) then
    local name = Api.GetSpellInfo(spellId)
    if (issecretvalue and issecretvalue(name)) then name = nil end
    if (not catalog[spellId]) then
      catalog[spellId] = CatalogSpell.New(spellId, name, Api.GetSpellRank(spellId))
    elseif (name) then
      catalog[spellId].Name = name
      catalog[spellId].Rank = catalog[spellId].Rank or Api.GetSpellRank(spellId)
    end
  end
  local statistics = self:GetCurrentLevelStatistics()
  statistics.TimeStatisticsBySpell = statistics.TimeStatisticsBySpell or {}
  statistics.TimeStatisticsBySpell[spellId] = (statistics.TimeStatisticsBySpell[spellId] or 0) + seconds
  AutoBiographer_Milestones:OnSpellTime(spellId, seconds)
end

function Controller:AddTime(timeTrackingType, seconds, zone, subZone)
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("Adding " .. tostring(seconds) .. " seconds of timeTrackingType " .. tostring(timeTrackingType) .. " to " .. tostring(subZone) .. " (" .. tostring(zone) .. ").", AutoBiographerEnum.LogLevel.Debug) end
  
  local areaId = tostring(zone) .. "-" .. tostring(subZone)
  
  if (not self:GetCurrentLevelStatistics().TimeStatisticsByArea[areaId]) then self:GetCurrentLevelStatistics().TimeStatisticsByArea[areaId] = TimeStatistics.New() end
  TimeStatistics.AddTime(self:GetCurrentLevelStatistics().TimeStatisticsByArea[areaId], timeTrackingType, seconds)
  AutoBiographer_Milestones:OnStatChanged("Time")
end

function Controller:CatalogItemIsIncomplete(catalogItemId)
  return not self.CharacterData.Catalogs.ItemCatalog[catalogItemId] or not self.CharacterData.Catalogs.ItemCatalog[catalogItemId].Name or not self.CharacterData.Catalogs.ItemCatalog[catalogItemId].Rarity
end

function Controller:CatalogUnitIsIncomplete(catalogUnitId)
  return self.CharacterData.Catalogs.UnitCatalog[catalogUnitId] == nil or self.CharacterData.Catalogs.UnitCatalog[catalogUnitId].Name == nil
end

function Controller:GetAggregatedCompanionFamilyTime(minLevel, maxLevel)
  local totals = {}
  for levelNum, statistics in pairs(self.CharacterData.Levels) do
    if (levelNum >= minLevel and levelNum <= maxLevel) then
      for familyId, seconds in pairs(statistics.TimeStatisticsByCompanionFamily or {}) do
        totals[familyId] = (totals[familyId] or 0) + seconds
      end
    end
  end
  return totals
end

function Controller:GetAggregatedDamageMeterAbilities(damageOrHealingCategories, minLevel, maxLevel, groupBySpellName)
  local abilitiesByKey = {}
  for levelNum, levelStatistics in pairs(self.CharacterData.Levels) do
    if (levelNum >= minLevel and levelNum <= maxLevel) then
      local damageStatistics = levelStatistics.DamageStatistics
      for _, damageOrHealingCategory in ipairs(damageOrHealingCategories) do
        local spells = damageStatistics[damageOrHealingCategory]
        if (spells) then
          for spellId, breakdown in pairs(spells) do
            local key = spellId
            if (groupBySpellName) then
              key = CatalogSpell.GetDamageMeterDisplayName(self.CharacterData.Catalogs.SpellCatalog[spellId], spellId)
            end
            if (not abilitiesByKey[key]) then abilitiesByKey[key] = DamageBreakdown.New() end
            DamageBreakdown.Add(abilitiesByKey[key], breakdown.Amount, breakdown.Over)
          end
        end
      end
    end
  end
  return abilitiesByKey
end

function Controller:GetAggregatedDamageTakenBySpell(damageOrHealingCategories, minLevel, maxLevel)
  local breakdownsByUnitAndSpell = {}
  for levelNum, levelStatistics in pairs(self.CharacterData.Levels) do
    if (levelNum >= minLevel and levelNum <= maxLevel) then
      local damageStatistics = levelStatistics.DamageStatistics
      for _, damageOrHealingCategory in ipairs(damageOrHealingCategories) do
        local units = damageStatistics[damageOrHealingCategory]
        if (units) then
          for unitName, spells in pairs(units) do
            if (not breakdownsByUnitAndSpell[unitName]) then breakdownsByUnitAndSpell[unitName] = {} end
            for spellId, breakdown in pairs(spells) do
              if (not breakdownsByUnitAndSpell[unitName][spellId]) then breakdownsByUnitAndSpell[unitName][spellId] = DamageBreakdown.New() end
              DamageBreakdown.Add(breakdownsByUnitAndSpell[unitName][spellId], breakdown.Amount, breakdown.Over)
            end
          end
        end
      end
    end
  end
  return breakdownsByUnitAndSpell
end

function Controller:GetAggregatedDamageTakenByUnit(damageOrHealingCategories, minLevel, maxLevel)
  local breakdownsByUnit = {}
  for levelNum, levelStatistics in pairs(self.CharacterData.Levels) do
    if (levelNum >= minLevel and levelNum <= maxLevel) then
      local damageStatistics = levelStatistics.DamageStatistics
      for _, damageOrHealingCategory in ipairs(damageOrHealingCategories) do
        local units = damageStatistics[damageOrHealingCategory]
        if (units) then
          for unitName, spells in pairs(units) do
            if (not breakdownsByUnit[unitName]) then breakdownsByUnit[unitName] = DamageBreakdown.New() end
            for _, breakdown in pairs(spells) do
              DamageBreakdown.Add(breakdownsByUnit[unitName], breakdown.Amount, breakdown.Over)
            end
          end
        end
      end
    end
  end
  return breakdownsByUnit
end

function Controller:GetAggregatedDamageTakenUnknownBreakdown(minLevel, maxLevel)
  local rawAmount, rawOver = self:GetDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.DamageTakenRaw, minLevel, maxLevel)
  local attributedAmount, attributedOver = self:GetDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.DamageTaken, minLevel, maxLevel)
  local unknownBreakdown = DamageBreakdown.New()
  unknownBreakdown.Amount = rawAmount - rawOver - (attributedAmount - attributedOver)
  return unknownBreakdown
end

function Controller:GetAggregatedItemStatisticsDictionary(minLevel, maxLevel)
  local itemStatisticsDictionary = {}
  for levelNum, levelStatistics in pairs(self.CharacterData.Levels) do
    if (levelNum >= minLevel and levelNum <= maxLevel) then
      for catalogItemId, itemStatistics in pairs(levelStatistics.ItemStatisticsByItem) do
        if (not itemStatisticsDictionary[catalogItemId]) then
          itemStatisticsDictionary[catalogItemId] = ItemStatistics.New()
        end

        for k, itemAcquisitionMethod in pairs(AutoBiographerEnum.ItemAcquisitionMethod) do
          if (itemStatistics[itemAcquisitionMethod]) then
            if (itemStatisticsDictionary[catalogItemId][itemAcquisitionMethod] == nil) then itemStatisticsDictionary[catalogItemId][itemAcquisitionMethod] = 0 end
            itemStatisticsDictionary[catalogItemId][itemAcquisitionMethod] = itemStatisticsDictionary[catalogItemId][itemAcquisitionMethod] + itemStatistics[itemAcquisitionMethod]
          end
        end
      end
    end
  end
  
  return itemStatisticsDictionary
end

function Controller:GetAggregatedKillStatisticsTotals(minLevel, maxLevel)
  local killStatisticsDictionary = self:GetAggregatedKillStatisticsDictionary(minLevel, maxLevel)
  local totalsKillStatistics = KillStatistics.New()

  for catalogUnitId, killStatistics in pairs(killStatisticsDictionary) do
    for k, killTrackingType in pairs(AutoBiographerEnum.KillTrackingType) do
      if (killStatistics[killTrackingType]) then
        if (totalsKillStatistics[killTrackingType] == nil) then totalsKillStatistics[killTrackingType] = 0 end
        totalsKillStatistics[killTrackingType] = totalsKillStatistics[killTrackingType] + killStatistics[killTrackingType]
      end
    end
  end

  return totalsKillStatistics
end

function Controller:GetAggregatedKillStatisticsByCatalogUnitId(catalogUnitId, minLevel, maxLevel)
  local killStatisticsByCatalogUnitId = KillStatistics.New()
  for levelNum, levelStatistics in pairs(self.CharacterData.Levels) do
    if (levelNum >= minLevel and levelNum <= maxLevel) then
      local killStatistics = levelStatistics.KillStatisticsByUnit[catalogUnitId]
      if (killStatistics) then
        for k, killTrackingType in pairs(AutoBiographerEnum.KillTrackingType) do
          if (killStatistics[killTrackingType]) then
            if (killStatisticsByCatalogUnitId[killTrackingType] == nil) then killStatisticsByCatalogUnitId[killTrackingType] = 0 end
            killStatisticsByCatalogUnitId[killTrackingType] = killStatisticsByCatalogUnitId[killTrackingType] + killStatistics[killTrackingType]
          end
        end
      end
    end
  end
  
  return killStatisticsByCatalogUnitId
end

function Controller:GetAggregatedKillStatisticsDictionary(minLevel, maxLevel)
  local killStatisticsDictionary = {}
  for levelNum, levelStatistics in pairs(self.CharacterData.Levels) do
    if (levelNum >= minLevel and levelNum <= maxLevel) then
      for catalogUnitId, killStatistics in pairs(levelStatistics.KillStatisticsByUnit) do
        if (not killStatisticsDictionary[catalogUnitId]) then
          killStatisticsDictionary[catalogUnitId] = KillStatistics.New()
        end

        for k, killTrackingType in pairs(AutoBiographerEnum.KillTrackingType) do
          if (killStatistics[killTrackingType]) then
            if (killStatisticsDictionary[catalogUnitId][killTrackingType] == nil) then killStatisticsDictionary[catalogUnitId][killTrackingType] = 0 end
            killStatisticsDictionary[catalogUnitId][killTrackingType] = killStatisticsDictionary[catalogUnitId][killTrackingType] + killStatistics[killTrackingType]
          end
        end
      end
    end
  end
  
  return killStatisticsDictionary
end

function Controller:GetAggregatedMessageStatistics(minLevel, maxLevel)
  local messageStatistics = MessageStatistics.New()
  for levelNum, levelStatistics in pairs(self.CharacterData.Levels) do
    if (levelNum >= minLevel and levelNum <= maxLevel) then
      for messageTrackingType, count in pairs(levelStatistics.MessageStatistics or {}) do
        messageStatistics[messageTrackingType] = (messageStatistics[messageTrackingType] or 0) + count
      end
    end
  end
  return messageStatistics
end

function Controller:GetAggregatedOtherPlayerStatisticsByCatalogUnitId(catalogUnitId, minLevel, maxLevel)
  local otherPlayerStatisticsByCatalogUnitId = OtherPlayerStatistics.New()
  for levelNum, levelStatistics in pairs(self.CharacterData.Levels) do
    if (levelNum >= minLevel and levelNum <= maxLevel) then
      local otherPlayerStatistics = levelStatistics.OtherPlayerStatisticsByOtherPlayer[catalogUnitId]
      if (otherPlayerStatistics) then
        for k, otherPlayerTrackingType in pairs(AutoBiographerEnum.OtherPlayerTrackingType) do
          if (otherPlayerStatistics[otherPlayerTrackingType]) then
            if (otherPlayerStatisticsByCatalogUnitId[otherPlayerTrackingType] == nil) then otherPlayerStatisticsByCatalogUnitId[otherPlayerTrackingType] = 0 end
            otherPlayerStatisticsByCatalogUnitId[otherPlayerTrackingType] = otherPlayerStatisticsByCatalogUnitId[otherPlayerTrackingType] + otherPlayerStatistics[otherPlayerTrackingType]
          end
        end
      end
    end
  end
  
  return otherPlayerStatisticsByCatalogUnitId
end

function Controller:GetAggregatedOtherPlayerStatisticsDictionary(minLevel, maxLevel)
  local otherPlayerStatisticsDictionary = {}
  for levelNum, levelStatistics in pairs(self.CharacterData.Levels) do
    if (levelNum >= minLevel and levelNum <= maxLevel) then
      for catalogUnitId, otherPlayerStatistics in pairs(levelStatistics.OtherPlayerStatisticsByOtherPlayer) do
        if (not otherPlayerStatisticsDictionary[catalogUnitId]) then
          otherPlayerStatisticsDictionary[catalogUnitId] = OtherPlayerStatistics.New()
        end

        for k, otherPlayerTrackingType in pairs(AutoBiographerEnum.OtherPlayerTrackingType) do
          if (otherPlayerStatistics[otherPlayerTrackingType]) then
            if (otherPlayerStatisticsDictionary[catalogUnitId][otherPlayerTrackingType] == nil) then otherPlayerStatisticsDictionary[catalogUnitId][otherPlayerTrackingType] = 0 end
            otherPlayerStatisticsDictionary[catalogUnitId][otherPlayerTrackingType] = otherPlayerStatisticsDictionary[catalogUnitId][otherPlayerTrackingType] + otherPlayerStatistics[otherPlayerTrackingType]
          end
        end
      end
    end
  end
  
  return otherPlayerStatisticsDictionary
end

function Controller:GetAggregatedQuestStatisticsDictionary(minLevel, maxLevel)
  local questStatisticsDictionary = {}
  for levelNum, levelStatistics in pairs(self.CharacterData.Levels) do
    if (levelNum >= minLevel and levelNum <= maxLevel) then
      for questId, questStatistics in pairs(levelStatistics.QuestStatisticsByQuest) do
        if (not questStatisticsDictionary[questId]) then
          questStatisticsDictionary[questId] = QuestStatistics.New()
        end

        for k, questTrackingType in pairs(AutoBiographerEnum.QuestTrackingType) do
          if (questStatistics[questTrackingType]) then
            if (questStatisticsDictionary[questId][questTrackingType] == nil) then questStatisticsDictionary[questId][questTrackingType] = 0 end
            questStatisticsDictionary[questId][questTrackingType] = questStatisticsDictionary[questId][questTrackingType] + questStatistics[questTrackingType]
          end
        end
      end
    end
  end
  
  return questStatisticsDictionary
end

function Controller:GetAggregatedQuestStatisticsTotals(minLevel, maxLevel, questStatisticsDictionary)
  if (not questStatisticsDictionary) then questStatisticsDictionary = self:GetAggregatedQuestStatisticsDictionary(minLevel, maxLevel) end
  local totalsQuestStatistics = QuestStatistics.New()

  for catalogUnitId, questStatistics in pairs(questStatisticsDictionary) do
    for k, questTrackingType in pairs(AutoBiographerEnum.QuestTrackingType) do
      if (questStatistics[questTrackingType]) then
        if (totalsQuestStatistics[questTrackingType] == nil) then totalsQuestStatistics[questTrackingType] = 0 end
        totalsQuestStatistics[questTrackingType] = totalsQuestStatistics[questTrackingType] + questStatistics[questTrackingType]
      end
    end
  end

  return totalsQuestStatistics
end

function Controller:GetAggregatedSpellStatisticsDictionary(minLevel, maxLevel)
  local spellStatisticsDictionary = {}
  for levelNum, levelStatistics in pairs(self.CharacterData.Levels) do
    if (levelNum >= minLevel and levelNum <= maxLevel) then
      for catalogSpellId, spellStatistics in pairs(levelStatistics.SpellStatisticsBySpell) do
        if (not spellStatisticsDictionary[catalogSpellId]) then
          spellStatisticsDictionary[catalogSpellId] = SpellStatistics.New()
        end

        for k, spellTrackingType in pairs(AutoBiographerEnum.SpellTrackingType) do
          if (spellStatistics[spellTrackingType]) then
            if (spellStatisticsDictionary[catalogSpellId][spellTrackingType] == nil) then spellStatisticsDictionary[catalogSpellId][spellTrackingType] = 0 end
            spellStatisticsDictionary[catalogSpellId][spellTrackingType] = spellStatisticsDictionary[catalogSpellId][spellTrackingType] + spellStatistics[spellTrackingType]
          end
        end
      end
    end
  end
  
  return spellStatisticsDictionary
end

function Controller:GetAggregatedSpellTime(minLevel, maxLevel)
  local totals = {}
  for levelNum, statistics in pairs(self.CharacterData.Levels) do
    if (levelNum >= minLevel and levelNum <= maxLevel) then
      for spellId, seconds in pairs(statistics.TimeStatisticsBySpell or {}) do
        totals[spellId] = (totals[spellId] or 0) + seconds
      end
    end
  end
  return totals
end

function Controller:GetAggregatedTimeStatisticsDictionary(minLevel, maxLevel)
  local timeStatisticsDictionary = {}
  for levelNum, levelStatistics in pairs(self.CharacterData.Levels) do
    if (levelNum >= minLevel and levelNum <= maxLevel) then
      for areaId, timeStatistics in pairs(levelStatistics.TimeStatisticsByArea) do
        if (not timeStatisticsDictionary[areaId]) then
          timeStatisticsDictionary[areaId] = TimeStatistics.New()
        end

        for k, timeTrackingType in pairs(AutoBiographerEnum.TimeTrackingType) do
          if (timeStatistics[timeTrackingType]) then
            if (timeStatisticsDictionary[areaId][timeTrackingType] == nil) then timeStatisticsDictionary[areaId][timeTrackingType] = 0 end
            timeStatisticsDictionary[areaId][timeTrackingType] = timeStatisticsDictionary[areaId][timeTrackingType] + timeStatistics[timeTrackingType]
          end
        end
      end
    end
  end
  
  return timeStatisticsDictionary
end

function Controller:GetArenaStatsByRegistrationTypeAndTeamSize(registered, teamSize, minLevel, maxLevel)
  local joined = 0
  local losses = 0
  local wins = 0
  for k,v in pairs(self.CharacterData.Levels) do
    if (k >= minLevel and k <= maxLevel) then
      local subObject
      if (registered) then subObject = v.ArenaStatistics.Registered
      else subObject = v.ArenaStatistics.Unregistered
      end

      if (subObject and subObject[teamSize]) then
        joined = joined + subObject[teamSize].joined
        losses = losses + subObject[teamSize].losses
        wins = wins + subObject[teamSize].wins
      end
    end
  end
  
  return joined, losses, wins
end

function Controller:GetBattlegroundStatsByBattlegroundId(battlegroundId, minLevel, maxLevel)
  local joined = 0
  local losses = 0
  local wins = 0
  for k,v in pairs(self.CharacterData.Levels) do
    if (k >= minLevel and k <= maxLevel) then
      if (v.BattlegroundStatistics[battlegroundId]) then
        joined = joined + v.BattlegroundStatistics[battlegroundId].joined
        losses = losses + v.BattlegroundStatistics[battlegroundId].losses
        wins = wins + v.BattlegroundStatistics[battlegroundId].wins
      end
    end
  end
  
  return joined, losses, wins
end

function Controller:GetCharacterSnapshots()
  return self.CharacterData.Snapshots
end

function Controller:GetCurrentLevelNum()
  return HelperFunctions.GetLastKeyFromTable(self.CharacterData.Levels)
end

function Controller:GetCurrentLevelStatistics()
  return self.CharacterData.Levels[self:GetCurrentLevelNum()]
end

function Controller:GetDamageOrHealing(damageOrHealingCategory, minLevel, maxLevel)
  local amountSum = 0
  local overSum = 0
  for k,v in pairs(self.CharacterData.Levels) do
    if (k >= minLevel and k <= maxLevel) then
      local amount, over = DamageStatistics.GetTotal(v.DamageStatistics, damageOrHealingCategory)
      amountSum = amountSum + amount
      overSum = overSum + over
    end
  end
  
  return amountSum, overSum
end

function Controller:GetDeathsByDeathTrackingType(deathTrackingType, minLevel, maxLevel)
  local sum = 0
  for k,v in pairs(self.CharacterData.Levels) do
    if (k >= minLevel and k <= maxLevel) then
      if (v.DeathStatistics[deathTrackingType]) then
        sum = sum + v.DeathStatistics[deathTrackingType]
      end
    end
  end
  
  return sum
end

function Controller:GetDistanceByDistanceTrackingType(distanceTrackingType, minLevel, maxLevel)
  local sum = 0
  for levelNum, levelStatistics in pairs(self.CharacterData.Levels) do
    if (levelNum >= minLevel and levelNum <= maxLevel and levelStatistics.DistanceStatistics) then
      sum = sum + (levelStatistics.DistanceStatistics[distanceTrackingType] or 0)
    end
  end
  return sum
end

function Controller:GetEvents()
  return self.CharacterData.Events
end

function Controller:GetEventString(event, excludeTimestamp)
  return Event.ToString(event, self.CharacterData.Catalogs, excludeTimestamp)
end

function Controller:GetExperienceByExperienceTrackingType(experienceTrackingType, minLevel, maxLevel)
  local sum = 0
  for k,v in pairs(self.CharacterData.Levels) do
    if (k >= minLevel and k <= maxLevel) then
      if (v.ExperienceStatistics[experienceTrackingType]) then
        sum = sum + v.ExperienceStatistics[experienceTrackingType]
      end
    end
  end
  
  return sum
end

function Controller:GetGearHistory()
  return self.CharacterData.Gear
end

function Controller:GetItemCountForAcquisitionMethod(itemAcquisitionMethod, minLevel, maxLevel)
  local sum = 0
  for k,v in pairs(self.CharacterData.Levels) do
    if (k >= minLevel and k <= maxLevel) then
      for k2,v2 in pairs(v.ItemStatisticsByItem) do
        if (v2[itemAcquisitionMethod]) then
          sum = sum + v2[itemAcquisitionMethod]
        end
      end
    end
  end
  
  return sum
end

function Controller:GetLevelStatistics(minLevel, maxLevel)
  local enum = AutoBiographerEnum
  local recordedStarts = {}
  for _, event in ipairs(self.CharacterData.Events or {}) do
    if (event.Type == enum.EventType.Level and event.SubType == enum.EventSubType.LevelUp) then
      recordedStarts[event.LevelNum] = true
    end
  end
  local result, currentLevel = {}, self:GetCurrentLevelNum()
  for levelNum, statistics in pairs(self.CharacterData.Levels) do
    if (levelNum >= minLevel and levelNum <= maxLevel) then
      local experience = statistics.ExperienceStatistics or {}
      local money = statistics.MoneyStatistics or {}
      local entry = {
        LevelNum = levelNum,
        Experience = experience,
        ExperienceTotal = (experience[enum.ExperienceTrackingType.Kill] or 0) +
          (experience[enum.ExperienceTrackingType.Quest] or 0) + (experience[enum.ExperienceTrackingType.Discovery] or 0),
        TimePlayed = 0, AfkTime = 0, GroupedTime = 0, DistanceTravelled = 0,
        MoneyGained = money.TotalMoneyGained or 0, MoneyLost = money.TotalMoneyLost or 0,
        Kills = 0, Quests = 0, Deaths = 0,
        IsPartial = not recordedStarts[levelNum],
        IsInProgress = levelNum == currentLevel,
      }
      for _, area in pairs(statistics.TimeStatisticsByArea or {}) do
        entry.TimePlayed = entry.TimePlayed + (area[enum.TimeTrackingType.LoggedIn] or 0)
        entry.AfkTime = entry.AfkTime + (area[enum.TimeTrackingType.Afk] or 0)
        entry.GroupedTime = entry.GroupedTime + (area[enum.TimeTrackingType.InParty] or 0)
      end
      for _, distance in pairs(statistics.DistanceStatistics or {}) do entry.DistanceTravelled = entry.DistanceTravelled + distance end
      for _, kills in pairs(statistics.KillStatisticsByUnit or {}) do
        entry.Kills = entry.Kills + KillStatistics.GetSum(kills, {
          enum.KillTrackingType.TaggedKillingBlow, enum.KillTrackingType.TaggedAssist, enum.KillTrackingType.TaggedGroupAssistOrKillingBlow,
        })
      end
      for _, quests in pairs(statistics.QuestStatisticsByQuest or {}) do
        entry.Quests = entry.Quests + (quests[enum.QuestTrackingType.Completed] or 0)
      end
      for _, deathType in pairs(enum.DeathTrackingType) do entry.Deaths = entry.Deaths + ((statistics.DeathStatistics or {})[deathType] or 0) end
      entry.MoneyNet = entry.MoneyGained - entry.MoneyLost
      entry.ExperiencePerHour = entry.TimePlayed > 0 and entry.ExperienceTotal * 3600 / entry.TimePlayed or 0
      result[levelNum] = entry
    end
  end
  return result
end

function Controller:GetLogs()
  return self.Logs
end

function Controller:GetMiscellaneousStatByMiscellaneousTrackingType(miscellaneousTrackingType, minLevel, maxLevel)
  local sum = 0
  for k,v in pairs(self.CharacterData.Levels) do
    if (k >= minLevel and k <= maxLevel) then
      if (v.MiscellaneousStatistics[miscellaneousTrackingType]) then
        sum = sum + v.MiscellaneousStatistics[miscellaneousTrackingType]
      end
    end
  end
  
  return sum
end

function Controller:GetMoneyForAcquisitionMethod(moneyAcquisitionMethod, minLevel, maxLevel)
  local sum = 0
  for k,v in pairs(self.CharacterData.Levels) do
    if (k >= minLevel and k <= maxLevel) then
      if (v.MoneyStatistics[moneyAcquisitionMethod]) then
        sum = sum + v.MoneyStatistics[moneyAcquisitionMethod]
      end
    end
  end
  
  return sum
end

function Controller:GetNotes()
  return Notes.Initialize(self.AccountData.Notes)
end

function Controller:GetOtherPlayerStatByOtherPlayerTrackingType(otherPlayerTrackingType, minLevel, maxLevel)
  local sum = 0
  for k,v in pairs(self.CharacterData.Levels) do
    if (k >= minLevel and k <= maxLevel) then
      for k2,v2 in pairs(v.OtherPlayerStatisticsByOtherPlayer) do
        if (v2[otherPlayerTrackingType]) then
          sum = sum + v2[otherPlayerTrackingType]
        end
      end
    end
  end
  
  return sum
end

function Controller:GetUniqueOtherPlayerCountByOtherPlayerTrackingType(otherPlayerTrackingType, minLevel, maxLevel)
  local count = 0
  local otherPlayerStatisticsDictionary = self:GetAggregatedOtherPlayerStatisticsDictionary(minLevel, maxLevel)
  for _, otherPlayerStatistics in pairs(otherPlayerStatisticsDictionary) do
    if (OtherPlayerStatistics.GetSum(otherPlayerStatistics, { otherPlayerTrackingType }) > 0) then
      count = count + 1
    end
  end

  return count
end

function Controller:GetSpellCountBySpellTrackingType(spellTrackingType, minLevel, maxLevel)
  local sum = 0
  for k,v in pairs(self.CharacterData.Levels) do
    if (k >= minLevel and k <= maxLevel) then
      for k2,v2 in pairs(v.SpellStatisticsBySpell) do
        if (v2[spellTrackingType]) then
          sum = sum + v2[spellTrackingType]
        end
      end
    end
  end
  
  return sum
end

function Controller:GetTodos()
  return Todo.Initialize(self.CharacterData.Todos)
end

function Controller:GetTotalMoneyGained(minLevel, maxLevel)
  local sum = 0
  for k,v in pairs(self.CharacterData.Levels) do
    if (k >= minLevel and k <= maxLevel) then
      sum = sum + v.MoneyStatistics.TotalMoneyGained
    end
  end
  
  return sum
end

function Controller:GetTotalMoneyLost(minLevel, maxLevel)
  local sum = 0
  for k,v in pairs(self.CharacterData.Levels) do
    if (k >= minLevel and k <= maxLevel) then
      sum = sum + v.MoneyStatistics.TotalMoneyLost
    end
  end
  
  return sum
end

function Controller:GetTimeForTimeTrackingType(timeTrackingType, minLevel, maxLevel)
  local sum = 0
  for k,v in pairs(self.CharacterData.Levels) do
    if (k >= minLevel and k <= maxLevel) then
      for k2,v2 in pairs(v.TimeStatisticsByArea) do
        if (v2[timeTrackingType]) then
          sum = sum + v2[timeTrackingType]
        end
      end
    end
  end
  
  return sum
end

-- *** Events ***

function Controller:OnAchievementEarned(achievementId)
  if (AutoBiographer_Settings.Options["TakeScreenshotOnAchievementEarned"]) then 
    self:TakeScreenshot(1.0)
  end
end

function Controller:OnAcquiredItem(timestamp, coordinates, itemAcquisitionMethod, catalogItem, quantity)
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("AcquiredItem: " .. CatalogItem.ToString(catalogItem) .. ". Quantity: " .. tostring(quantity) .. ". Method: " .. tostring(itemAcquisitionMethod) .. ".", AutoBiographerEnum.LogLevel.Debug) end
  
  if (not Catalogs.PlayerHasAcquiredItem(self.CharacterData.Catalogs, catalogItem.Id)) then
    catalogItem.Acquired = true
    self:UpdateCatalogItem(catalogItem)
    self:AddEvent(FirstAcquiredItemEvent.New(timestamp, coordinates, catalogItem.Id))
  end
  
  if (not self:GetCurrentLevelStatistics().ItemStatisticsByItem[catalogItem.Id]) then self:GetCurrentLevelStatistics().ItemStatisticsByItem[catalogItem.Id] = ItemStatistics.New() end
  ItemStatistics.AddCount(self:GetCurrentLevelStatistics().ItemStatisticsByItem[catalogItem.Id], itemAcquisitionMethod, quantity)
  AutoBiographer_Milestones:OnStatChanged("Items")
end

function Controller:OnArenaFinished(timestamp, registered, teamSize, arenaId, playerWon)
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("ArenaFinished: " .. tostring(registered) .. ", " .. tostring(teamSize) .. ", " .. tostring(arenaId) .. ", " .. tostring(playerWon) .. ".", AutoBiographerEnum.LogLevel.Debug) end
  
  if (playerWon) then
    self:AddEvent(ArenaWonEvent.New(timestamp, registered, teamSize, arenaId))
    ArenaStatistics.IncrementWins(self:GetCurrentLevelStatistics().ArenaStatistics, registered, teamSize)
  else
    self:AddEvent(ArenaLostEvent.New(timestamp, registered, teamSize, arenaId))
    ArenaStatistics.IncrementLosses(self:GetCurrentLevelStatistics().ArenaStatistics, registered, teamSize)
  end
end

function Controller:OnArenaJoined(timestamp, registered, teamSize, arenaId)
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("ArenaJoined: " .. tostring(registered) .. ", " .. tostring(teamSize) .. ", " .. tostring(arenaId) .. ", " .. tostring(playerWon) .. ".", AutoBiographerEnum.LogLevel.Debug) end
  
  self:AddEvent(ArenaJoinedEvent.New(timestamp, registered, teamSize, arenaId))
  ArenaStatistics.IncrementJoined(self:GetCurrentLevelStatistics().ArenaStatistics, registered, teamSize)
end

function Controller:OnBattlegroundFinished(timestamp, battlegroundId, playerWon)
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("BattlegroundFinished: " .. tostring(battlegroundId) .. ", " .. tostring(playerWon) .. ".", AutoBiographerEnum.LogLevel.Debug) end
  
  if (playerWon) then
    self:AddEvent(BattlegroundWonEvent.New(timestamp, battlegroundId))
    BattlegroundStatistics.IncrementWins(self:GetCurrentLevelStatistics().BattlegroundStatistics, battlegroundId)
  else
    self:AddEvent(BattlegroundLostEvent.New(timestamp, battlegroundId))
    BattlegroundStatistics.IncrementLosses(self:GetCurrentLevelStatistics().BattlegroundStatistics, battlegroundId)
  end
end

function Controller:OnBattlegroundJoined(timestamp, battlegroundId)
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("BattlegroundJoined: " .. tostring(battlegroundId) .. ".", AutoBiographerEnum.LogLevel.Debug) end
  
  self:AddEvent(BattlegroundJoinedEvent.New(timestamp, battlegroundId))
  BattlegroundStatistics.IncrementJoined(self:GetCurrentLevelStatistics().BattlegroundStatistics, battlegroundId)
end

function Controller:OnBuffedOtherPlayer(otherPlayerCatalogUnitId, otherPlayerName, isGroupedWithPlayer)
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("Buffed other player: #" .. tostring(otherPlayerCatalogUnitId) .. " (" .. tostring(otherPlayerName) .. ").", AutoBiographerEnum.LogLevel.Debug) end
  if (not otherPlayerCatalogUnitId) then
    Controller:AddLog("otherPlayerCatalogUnitId was nil.", AutoBiographerEnum.LogLevel.Error)
    return
  end

  local otherPlayerStatisticsByOtherPlayer = self:GetCurrentLevelStatistics().OtherPlayerStatisticsByOtherPlayer
  if (not otherPlayerStatisticsByOtherPlayer[otherPlayerCatalogUnitId]) then otherPlayerStatisticsByOtherPlayer[otherPlayerCatalogUnitId] = OtherPlayerStatistics.New() end
  local trackingType = isGroupedWithPlayer and AutoBiographerEnum.OtherPlayerTrackingType.BuffsGivenToPlayerWhileGrouped or AutoBiographerEnum.OtherPlayerTrackingType.BuffsGivenToPlayerNotGrouped
  OtherPlayerStatistics.Add(otherPlayerStatisticsByOtherPlayer[otherPlayerCatalogUnitId], trackingType, 1)
  AutoBiographer_Milestones:OnStatChanged("Buffs")
end

function Controller:OnBossKill(timestamp, coordinates, bossId, bossName, hasKilledBossBefore)
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("BossKill: " .. tostring(bossName) .. " (#" .. tostring(bossId) .. ").", AutoBiographerEnum.LogLevel.Debug) end
  
  local catalogUnit = self.CharacterData.Catalogs.UnitCatalog[bossId]
  local isFromRegularKillEvent = catalogUnit ~= nil and catalogUnit.Name == bossName

  local matchingBossKillEvent = nil
  local matchingEventIndex = #self.CharacterData.Events
  while (matchingBossKillEvent == nil and timestamp - self.CharacterData.Events[matchingEventIndex].Timestamp < 2) do
    local event = self.CharacterData.Events[matchingEventIndex]
    if (event.Type == AutoBiographerEnum.EventType.Kill and event.SubType == AutoBiographerEnum.EventSubType.BossKill and event.BossName == bossName) then 
      matchingBossKillEvent = event
    else
      matchingEventIndex = matchingEventIndex - 1
    end
  end

  if (matchingBossKillEvent ~= nil) then
    if (isFromRegularKillEvent) then
      Controller:AddLog("This is a regular unit kill and I found a matching boss kill event from an actual boss. Returning.", AutoBiographerEnum.LogLevel.Debug)
      return
    else
      Controller:AddLog("This is a boss unit kill and I found a matching boss kill event from a regular unit. Deleting other event.", AutoBiographerEnum.LogLevel.Debug)
      local indexesToDelete = {}
      indexesToDelete[matchingEventIndex] = true
      HelperFunctions.RemoveElementsFromArrayAtIndexes(self.CharacterData.Events, indexesToDelete)
      hasKilledBossBefore = true
    end
  end

  self:AddEvent(BossKillEvent.New(timestamp, coordinates, bossId, bossName))
  AutoBiographer_SnapshotManager:SnapshotRaid(bossId)
  
  if (AutoBiographer_Settings.Options["TakeScreenshotOnBossKill"] and (not AutoBiographer_Settings.Options["TakeScreenshotOnlyOnFirstBossKill"] or not hasKilledBossBefore)) then
    self:TakeScreenshot(0.5)
  end
end

function Controller:OnCamped()
  MiscellaneousStatistics.Add(self:GetCurrentLevelStatistics().MiscellaneousStatistics, AutoBiographerEnum.MiscellaneousTrackingType.Camped, 1)
  AutoBiographer_Milestones:OnStatChanged("Camped")
end

function Controller:OnChangedSubZone(timestamp, coordinates, zoneName, subZoneName)
  if (subZoneName == nil or subZoneName == "") then return end
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("ChangedSubZone: " .. tostring(subZoneName) .. " (" .. tostring(zoneName) .. ").", AutoBiographerEnum.LogLevel.Debug) end
  
  if (self.CharacterData.Catalogs.SubZoneCatalog[subZoneName] == nil) then
    self.CharacterData.Catalogs.SubZoneCatalog[subZoneName] = CatalogSubZone.New(subZoneName, true, zoneName)
    self:AddEvent(SubZoneFirstVisitEvent.New(timestamp, coordinates, subZoneName))
  end
end

function Controller:OnChangedZone(timestamp, coordinates, zoneName)
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("ChangedZone: " .. tostring(zoneName) .. ".", AutoBiographerEnum.LogLevel.Debug) end

  if (self.CharacterData.Catalogs.ZoneCatalog[zoneName] == nil) then
    self.CharacterData.Catalogs.ZoneCatalog[zoneName] = CatalogZone.New(zoneName, true)
    self:AddEvent(ZoneFirstVisitEvent.New(timestamp, coordinates, zoneName))
  end
end

function Controller:OnDamageOrHealing(damageOrHealingCategory, unitName, spellId, spellName, amount, overkill, creatureName)
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("DamageOrHealingCategory: " .. tostring(damageOrHealingCategory) .. ". Amount: " .. tostring(amount) .. ", over: " .. tostring(overkill), AutoBiographerEnum.LogLevel.Debug) end
  local damageStatistics = self:GetCurrentLevelStatistics().DamageStatistics
  if (damageOrHealingCategory == AutoBiographerEnum.DamageOrHealingCategory.DamageTaken) then
    if (not unitName or not spellId) then
      Controller:AddLog("Damage taken was not tracked because its source name or spell ID was nil.", AutoBiographerEnum.LogLevel.Warning)
      return
    end
    if (not self.CharacterData.Catalogs.SpellCatalog[spellId]) then self.CharacterData.Catalogs.SpellCatalog[spellId] = CatalogSpell.New(spellId, spellName, nil) end
    DamageStatistics.AddDamageTaken(damageStatistics, unitName, spellId, amount, overkill)
  elseif (damageOrHealingCategory == AutoBiographerEnum.DamageOrHealingCategory.DamageTakenRaw or
      damageOrHealingCategory == AutoBiographerEnum.DamageOrHealingCategory.HealingTakenRaw or
      damageOrHealingCategory == AutoBiographerEnum.DamageOrHealingCategory.PetDamageTakenRaw) then
    DamageStatistics.AddRawBreakdown(damageStatistics, damageOrHealingCategory, amount, overkill)
  else
    if (not spellId) then
      Controller:AddLog("Damage or healing was not tracked because its spell ID was nil.", AutoBiographerEnum.LogLevel.Warning)
      return
    end
    local catalogSpell = self.CharacterData.Catalogs.SpellCatalog[spellId]
    local spellRank = Api.GetSpellRank(spellId)
    if (not catalogSpell) then
      self.CharacterData.Catalogs.SpellCatalog[spellId] = CatalogSpell.New(spellId, spellName, spellRank, creatureName)
    else
      if (spellRank ~= nil) then catalogSpell.Rank = spellRank end
      if (creatureName ~= nil and creatureName ~= "") then catalogSpell.CreatureName = creatureName end
    end
    DamageStatistics.AddSpellBreakdown(damageStatistics, damageOrHealingCategory, spellId, amount, overkill)
  end

  AutoBiographer_Milestones:OnStatChanged("Damage")
end

function Controller:OnDeath(timestamp, coordinates, killerCatalogUnitId, killerLevel, environmentalType)
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("Death: " .. " #" .. tostring(killerCatalogUnitId) .. ".", AutoBiographerEnum.LogLevel.Debug) end
  self:AddEvent(PlayerDeathEvent.New(timestamp, coordinates, killerCatalogUnitId, killerLevel, environmentalType))

  local deathTrackingType
  if (killerCatalogUnitId == nil) then
    if (environmentalType == "Drowning") then
      deathTrackingType = AutoBiographerEnum.DeathTrackingType.DeathToDrowning
    elseif (environmentalType == "Falling") then
      deathTrackingType = AutoBiographerEnum.DeathTrackingType.DeathToFalling
    else
      deathTrackingType = AutoBiographerEnum.DeathTrackingType.DeathToEnvironment
    end
  else
    local killerUnitType = HelperFunctions.GetUnitTypeFromCatalogUnitId(killerCatalogUnitId)

    if (killerUnitType == AutoBiographerEnum.UnitType.Creature) then
      deathTrackingType = AutoBiographerEnum.DeathTrackingType.DeathToCreature
    elseif (killerUnitType == AutoBiographerEnum.UnitType.GameObject) then
      deathTrackingType = AutoBiographerEnum.DeathTrackingType.DeathToGameObject
    elseif (killerUnitType == AutoBiographerEnum.UnitType.Pet) then
      deathTrackingType = AutoBiographerEnum.DeathTrackingType.DeathToPet
    elseif (killerUnitType == AutoBiographerEnum.UnitType.Player) then
      deathTrackingType = AutoBiographerEnum.DeathTrackingType.DeathToPlayer
    elseif (killerUnitType == AutoBiographerEnum.UnitType.Unknown) then
      deathTrackingType = AutoBiographerEnum.DeathTrackingType.DeathToUnknown
    end
  end
  
  if (not deathTrackingType) then
    Controller:AddLog("Death not tracked. killerCatalogUnitId: '" .. tostring(killerCatalogUnitId) .. "'.", AutoBiographerEnum.LogLevel.Warning)
    return
  end

  DeathStatistics.Increment(self:GetCurrentLevelStatistics().DeathStatistics, deathTrackingType)
  AutoBiographer_Milestones:OnStatChanged("Deaths")
end

function Controller:OnDuelLost(timestamp, coordinates, winnerCatalogUnitId, winnerName)
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("DuelLost: " .. " #" .. tostring(winnerCatalogUnitId) .. " (" .. winnerName .. ").", AutoBiographerEnum.LogLevel.Debug) end
  if (not winnerCatalogUnitId) then
    Controller:AddLog("winnerCatalogUnitId was nil.", AutoBiographerEnum.LogLevel.Error)
    return
  end
  
  if (not self:GetCurrentLevelStatistics().OtherPlayerStatisticsByOtherPlayer[winnerCatalogUnitId]) then self:GetCurrentLevelStatistics().OtherPlayerStatisticsByOtherPlayer[winnerCatalogUnitId] = OtherPlayerStatistics.New() end
  OtherPlayerStatistics.Add(self:GetCurrentLevelStatistics().OtherPlayerStatisticsByOtherPlayer[winnerCatalogUnitId], AutoBiographerEnum.OtherPlayerTrackingType.DuelsWonAgainstPlayer, 1)
end

function Controller:OnDuelWon(timestamp, coordinates, loserCatalogUnitId, loserName)
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("DuelWon: " .. " #" .. tostring(loserCatalogUnitId) .. " (" .. loserName .. ").", AutoBiographerEnum.LogLevel.Debug) end
  if (not loserCatalogUnitId) then
    Controller:AddLog("loserCatalogUnitId was nil.", AutoBiographerEnum.LogLevel.Error)
    return
  end
  
  if (not self:GetCurrentLevelStatistics().OtherPlayerStatisticsByOtherPlayer[loserCatalogUnitId]) then self:GetCurrentLevelStatistics().OtherPlayerStatisticsByOtherPlayer[loserCatalogUnitId] = OtherPlayerStatistics.New() end
  OtherPlayerStatistics.Add(self:GetCurrentLevelStatistics().OtherPlayerStatisticsByOtherPlayer[loserCatalogUnitId], AutoBiographerEnum.OtherPlayerTrackingType.DuelsLostToPlayer, 1)
  AutoBiographer_Milestones:OnStatChanged("Duels")
end

function Controller:OnEquippedItem(timestamp, slotId, itemId)
  local changed = GearHistory.RecordChange(self:GetGearHistory(), timestamp, slotId, itemId)
  if (changed and AutoBiographer_GearPanel and AutoBiographer_GearPanel.QueueRefresh) then
    AutoBiographer_GearPanel:QueueRefresh()
  end
  return changed
end

function Controller:OnGainedExperience(timestamp, coordinates, experienceTrackingType, amount)
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("GainedExperience: " .. tostring(amount) .. ". Experience Tracking Type: " .. tostring(experienceTrackingType) .. ".", AutoBiographerEnum.LogLevel.Debug) end
  ExperienceStatistics.AddExperience(self:GetCurrentLevelStatistics().ExperienceStatistics, experienceTrackingType, amount)
  AutoBiographer_Milestones:OnStatChanged("Experience")
end

function Controller:OnGainedMoney(timestamp, coordinates, moneyAcquisitionMethod, money)
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("GainedMoney: " .. tostring(money) .. ". Acquisition Method: " .. tostring(moneyAcquisitionMethod) .. ".", AutoBiographerEnum.LogLevel.Debug) end
  MoneyStatistics.AddMoney(self:GetCurrentLevelStatistics().MoneyStatistics, moneyAcquisitionMethod, money)
end

function Controller:OnGuildRankChanged(timestamp, guildRankIndex, guildRankName)
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("GuildRankChanged: " .. " " .. tostring(guildRankName) .. " (" .. tostring(guildRankIndex) .. ").", AutoBiographerEnum.LogLevel.Debug) end
  self:AddEvent(GuildRankChangedEvent.New(timestamp, guildRankIndex, guildRankName))
end

function Controller:OnJoinedGuild(timestamp, guildName)
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("JoinedGuild: " .. " " .. tostring(guildName) .. ".", AutoBiographerEnum.LogLevel.Debug) end
  self:AddEvent(GuildJoinedEvent.New(timestamp, guildName))
end

function Controller:OnJump(timestamp)
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("Jump.", AutoBiographerEnum.LogLevel.Debug) end
  MiscellaneousStatistics.Add(self:GetCurrentLevelStatistics().MiscellaneousStatistics, AutoBiographerEnum.MiscellaneousTrackingType.Jumps, 1)
  
  AutoBiographer_Milestones:OnStatChanged("Jumps")
end

function Controller:OnKill(timestamp, coordinates, kill)
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("Kill: " .. " #" .. tostring(kill.CatalogUnitId) .. ".", AutoBiographerEnum.LogLevel.Debug) end

  if (not self:GetCurrentLevelStatistics().KillStatisticsByUnit[kill.CatalogUnitId]) then self:GetCurrentLevelStatistics().KillStatisticsByUnit[kill.CatalogUnitId] = KillStatistics.New() end
  KillStatistics.AddKill(self:GetCurrentLevelStatistics().KillStatisticsByUnit[kill.CatalogUnitId], kill)

  if (kill.PlayerHasTag) then 
    local hasKilledUnitBefore = true
    if (not Catalogs.PlayerHasKilledUnit(self.CharacterData.Catalogs, kill.CatalogUnitId)) then
      hasKilledUnitBefore = false
      self:UpdateCatalogUnit(CatalogUnit.New(kill.CatalogUnitId, nil, nil, nil, nil, nil, nil, nil, true, nil))
      
      if (self.CharacterData.Catalogs.UnitCatalog[kill.CatalogUnitId].UType == AutoBiographerEnum.UnitType.Creature) then
        self:AddEvent(FirstKillEvent.New(timestamp, coordinates, kill.CatalogUnitId))
      end
    end
    
    if (AutoBiographer_Databases.BossDatabase[kill.CatalogUnitId]) then
      Controller:OnBossKill(time(), HelperFunctions.GetCoordinatesByUnitId("player"), kill.CatalogUnitId, self.CharacterData.Catalogs.UnitCatalog[kill.CatalogUnitId].Name, hasKilledUnitBefore)
    end
  end
  AutoBiographer_Milestones:OnStatChanged("Kills")
end

function Controller:OnLeftGuild(timestamp, guildName)
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("LeftGuild: " .. " " .. tostring(guildName) .. ".", AutoBiographerEnum.LogLevel.Debug) end
  self:AddEvent(GuildLeftEvent.New(timestamp, guildName))
end

function Controller:OnLevelUp(timestamp, coordinates, levelNum, totalTimePlayedAtDing)
  if self.CharacterData.Levels[levelNum] ~= nil then error("Can not add level " .. levelNum .. " because it was already added.") end
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("LevelUp: " .. tostring(levelNum) .. ", " .. HelperFunctions.SecondsToTimeString(totalTimePlayedAtDing) .. ".", AutoBiographerEnum.LogLevel.Debug) end
  
  self.CharacterData.Levels[levelNum] = LevelStatistics.New(levelNum, totalTimePlayedAtDing, nil)
  
  local currentLevel = self.CharacterData.Levels[levelNum]
  local previousLevel = self.CharacterData.Levels[levelNum - 1]
  
  if (previousLevel and previousLevel.TotalTimePlayedAtDing and currentLevel.TotalTimePlayedAtDing) then
    previousLevel.TimePlayedThisLevel = currentLevel.TotalTimePlayedAtDing - previousLevel.TotalTimePlayedAtDing
    if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("Time played last level = " .. HelperFunctions.SecondsToTimeString(previousLevel.TimePlayedThisLevel), AutoBiographerEnum.LogLevel.Debug) end
  end
  
  if (timestamp) then
    self:AddEvent(LevelUpEvent.New(timestamp, coordinates, levelNum))
    -- A nil timestamp denotes initialization of an already-progressed
    -- character, not a milestone. New level-1 characters come through here.
    AutoBiographer_SnapshotManager:SnapshotLevel(levelNum, totalTimePlayedAtDing)
    if (AutoBiographer_Settings.Options["TakeScreenshotOnLevelUp"] and levelNum > 1) then 
      self:TakeScreenshot(1.0)
    end
  end

end

function Controller:OnMessageSent(messageTrackingType)
  local levelStatistics = self:GetCurrentLevelStatistics()
  if (not levelStatistics.MessageStatistics) then levelStatistics.MessageStatistics = MessageStatistics.New() end
  MessageStatistics.Increment(levelStatistics.MessageStatistics, messageTrackingType)
  AutoBiographer_Milestones:OnStatChanged("Messages")
end

function Controller:OnMoneyChanged(timestamp, coordinates, deltaMoney)
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("MoneyChanged: " .. tostring(deltaMoney) .. ".", AutoBiographerEnum.LogLevel.Debug) end
  MoneyStatistics.TotalMoneyChanged(self:GetCurrentLevelStatistics().MoneyStatistics, deltaMoney)
  AutoBiographer_Milestones:OnStatChanged("Money")
end

function Controller:OnQuestTurnedIn(timestamp, coordinates, questId, questTitle, xpGained, moneyGained)
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("QuestTurnedIn: " .. tostring(questTitle) .. " (#" .. tostring(questId) .. "), " .. tostring(xpGained) .. ", " .. tostring(moneyGained) .. ".", AutoBiographerEnum.LogLevel.Debug) end
  self:AddEvent(QuestTurnInEvent.New(timestamp, coordinates, questId, questTitle, xpGained, moneyGained))

  if (not self:GetCurrentLevelStatistics().QuestStatisticsByQuest[questId]) then self:GetCurrentLevelStatistics().QuestStatisticsByQuest[questId] = QuestStatistics.New() end
  QuestStatistics.Increment(self:GetCurrentLevelStatistics().QuestStatisticsByQuest[questId], AutoBiographerEnum.QuestTrackingType.Completed)

  AutoBiographer_Milestones:OnStatChanged("Quests")
end

function Controller:OnReputationLevelChanged(timestamp, coordinates, faction, reputationLevel)
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("ReputationLevelChanged: " .. tostring(faction) .. ", " .. tostring(reputationLevel) .. ".", AutoBiographerEnum.LogLevel.Debug) end
  self:AddEvent(ReputationLevelChangedEvent.New(timestamp, coordinates, faction, reputationLevel))
end

function Controller:OnSpellLearned(timestamp, coordinates, spellId, spellName, spellRank)
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("SpellLearned: " .. tostring(spellName) .. " (#" .. tostring(spellId) .. "), " .. tostring(spellRank) .. ".", AutoBiographerEnum.LogLevel.Debug) end

  if (not self.CharacterData.Catalogs.SpellCatalog[spellId]) then
    self.CharacterData.Catalogs.SpellCatalog[spellId] = CatalogSpell.New(spellId, spellName, spellRank)
    self:AddEvent(SpellLearnedEvent.New(timestamp, coordinates, spellId))
  end
end

function Controller:OnSpellStartedCasting(timestamp, coordinates, spellId, spellName, spellRank)
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("SpellStartedCasting: " .. tostring(spellName) .. " (#" .. tostring(spellId) .. "), " .. tostring(spellRank) .. ".", AutoBiographerEnum.LogLevel.Debug) end
  if (not spellId) then
    Controller:AddLog("spellId was nil.", AutoBiographerEnum.LogLevel.Error)
    return
  end
  
  if (not self.CharacterData.Catalogs.SpellCatalog[spellId]) then
    self.CharacterData.Catalogs.SpellCatalog[spellId] = CatalogSpell.New(spellId, spellName, spellRank)
  end
  
   if (not self:GetCurrentLevelStatistics().SpellStatisticsBySpell[spellId]) then self:GetCurrentLevelStatistics().SpellStatisticsBySpell[spellId] = SpellStatistics.New() end
   SpellStatistics.Increment(self:GetCurrentLevelStatistics().SpellStatisticsBySpell[spellId], AutoBiographerEnum.SpellTrackingType.StartedCasting)
end

function Controller:OnSpellSuccessfullyCast(timestamp, coordinates, spellId, spellName, spellRank)
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("SpellSuccessfullyCast: " .. tostring(spellName) .. " (#" .. tostring(spellId) .. "), " .. tostring(spellRank) .. ".", AutoBiographerEnum.LogLevel.Debug) end
  if (not spellId) then
    Controller:AddLog("spellId was nil.", AutoBiographerEnum.LogLevel.Error)
    return
  end
  
  if (not self.CharacterData.Catalogs.SpellCatalog[spellId]) then
    self.CharacterData.Catalogs.SpellCatalog[spellId] = CatalogSpell.New(spellId, spellName, spellRank)
  end
  
   if (not self:GetCurrentLevelStatistics().SpellStatisticsBySpell[spellId]) then self:GetCurrentLevelStatistics().SpellStatisticsBySpell[spellId] = SpellStatistics.New() end
   SpellStatistics.Increment(self:GetCurrentLevelStatistics().SpellStatisticsBySpell[spellId], AutoBiographerEnum.SpellTrackingType.SuccessfullyCast)
  AutoBiographer_Milestones:OnStatChanged("Spells")
end

function Controller:OnSkillLevelIncreased(timestamp, coordinates, skillName, skillLevel)
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("SkillLevelIncreased: " .. " " .. tostring(skillName) .. " (" .. tostring(skillLevel) .. ").", AutoBiographerEnum.LogLevel.Debug) end
  
  if (skillLevel % 75 == 0) then
    self:AddEvent(SkillMilestoneEvent.New(timestamp, coordinates, skillName, skillLevel))
  end
end

function Controller:PrintEvents()
  for _,v in pairs(self.CharacterData.Events) do
    print(Event.ToString(v, self.CharacterData.Catalogs))
  end
end

function Controller:PrintLastEvent()
  print(Event.ToString(self.CharacterData.Events[#self.CharacterData.Events], self.CharacterData.Catalogs))
end

function Controller:TakeScreenshot(secondsToDelay)
  if (not secondsToDelay) then secondsToDelay = 0 end

  C_Timer.After(secondsToDelay, function()
    if (self.Temp.LastScreenshotTimestamp and GetTime() - self.Temp.LastScreenshotTimestamp < 1) then
      if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then print("[AutoBiographer] Skipping screenshot, another was just taken.") end
      return
    end

    self.Temp.LastScreenshotTimestamp = GetTime()
    Screenshot()
    if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("Screenshot captured after" .. tostring(secondsToDelay) .. "s delay .", AutoBiographerEnum.LogLevel.Debug) end
  end)
end

function Controller:UpdateCatalogBoss(catalogBoss)
  if (self.CharacterData.Catalogs.BossCatalog[catalogBoss.Id] == nil) then
    self.CharacterData.Catalogs.BossCatalog[catalogBoss.Id] = catalogBoss
  else
    CatalogBoss.Update(self.CharacterData.Catalogs.BossCatalog[catalogBoss.Id], catalogBoss.Id, catalogBoss.Name, catalogBoss.Killed)
  end
  
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("CatalogBoss Updated: " .. CatalogBoss.ToString(self.CharacterData.Catalogs.BossCatalog[catalogBoss.Id]) .. ".", AutoBiographerEnum.LogLevel.Debug) end
end

function Controller:UpdateCatalogItem(catalogItem)
  if (not self.CharacterData.Catalogs.ItemCatalog[catalogItem.Id]) then
    self.CharacterData.Catalogs.ItemCatalog[catalogItem.Id] = catalogItem
  else
    CatalogItem.Update(self.CharacterData.Catalogs.ItemCatalog[catalogItem.Id], catalogItem.Id, catalogItem.Name, catalogItem.Rarity, catalogItem.Level, catalogItem.Type, catalogItem.SubType, catalogItem.Acquired)
  end
  
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("CatalogItem Updated: " .. CatalogItem.ToString(self.CharacterData.Catalogs.ItemCatalog[catalogItem.Id]) .. ".", AutoBiographerEnum.LogLevel.Debug) end
end

function Controller:UpdateCatalogUnit(catalogUnit)
  if (self.CharacterData.Catalogs.UnitCatalog[catalogUnit.Id] == nil) then
    self.CharacterData.Catalogs.UnitCatalog[catalogUnit.Id] = catalogUnit
  else
    CatalogUnit.Update(self.CharacterData.Catalogs.UnitCatalog[catalogUnit.Id], catalogUnit.Id, catalogUnit.Class, catalogUnit.Clsfctn, catalogUnit.CFam, catalogUnit.CType, catalogUnit.Name, catalogUnit.LastName, catalogUnit.Race, catalogUnit.Killed, catalogUnit.UType)
  end
  
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("CatalogUnit Updated: " .. CatalogUnit.ToString(self.CharacterData.Catalogs.UnitCatalog[catalogUnit.Id]) .. ".", AutoBiographerEnum.LogLevel.Debug) end
end
