AutoBiographer_Controller = {
  CharacterData = {},
  Logs = {
    FirstIndex = 1,
    LastIndex = 0,
  }, 
}

local Controller = AutoBiographer_Controller

function Controller:AddEvent(event)
  table.insert(self.CharacterData.Events, event)
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog(Event.ToString(self.CharacterData.Events[#self.CharacterData.Events], self.CharacterData.Catalogs), AutoBiographerEnum.LogLevel.Debug) end
end

function Controller:AddLog(text, logLevel)
  if (logLevel == nil) then error("Unspecified logLevel. Log Text: '" .. text .. "'") end
  
  if (self.Logs.LastIndex - self.Logs.FirstIndex >= 1000) then
    self.Logs[self.Logs.FirstIndex] = nil
    self.Logs.FirstIndex = self.Logs.FirstIndex + 1
  end
  
  self.Logs.LastIndex = self.Logs.LastIndex + 1
  
  self.Logs[self.Logs.LastIndex] = { 
    Level = logLevel, Text = tostring(text),
    Timestamp = time() ,
  }
  
  if (AutoBiographer_DebugWindow ) then AutoBiographer_DebugWindow.LogsUpdated() end
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

function Controller:AddTime(timeTrackingType, seconds, zone, subZone)
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("Adding " .. tostring(seconds) .. " seconds of timeTrackingType " .. tostring(timeTrackingType) .. " to " .. tostring(subZone) .. " (" .. tostring(zone) .. ").", AutoBiographerEnum.LogLevel.Debug) end
  
  local areaId = tostring(zone) .. "-" .. tostring(subZone)
  
  if (not self:GetCurrentLevelStatistics().TimeStatisticsByArea[areaId]) then self:GetCurrentLevelStatistics().TimeStatisticsByArea[areaId] = TimeStatistics.New() end
  TimeStatistics.AddTime(self:GetCurrentLevelStatistics().TimeStatisticsByArea[areaId], timeTrackingType, seconds)
end

function Controller:CatalogItemIsIncomplete(catalogItemId)
  return not self.CharacterData.Catalogs.ItemCatalog[catalogItemId] or not self.CharacterData.Catalogs.ItemCatalog[catalogItemId].Name or not self.CharacterData.Catalogs.ItemCatalog[catalogItemId].Rarity
end

function Controller:CatalogUnitIsIncomplete(catalogUnitId)
  return self.CharacterData.Catalogs.UnitCatalog[catalogUnitId] == nil or self.CharacterData.Catalogs.UnitCatalog[catalogUnitId].Name == nil
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
      if (v.DamageStatistics[damageOrHealingCategory]) then
        amountSum = amountSum + v.DamageStatistics[damageOrHealingCategory].Amount
        overSum = overSum + v.DamageStatistics[damageOrHealingCategory].Over
      end
    end
  end
  
  return amountSum, overSum
end

function Controller:GetEvents()
  return self.CharacterData.Events
end

function Controller:GetEventString(event)
  return Event.ToString(event, self.CharacterData.Catalogs)
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

function Controller:GetItemCountForAcquisitionMethod(acquisitionMethod, minLevel, maxLevel)
  local sum = 0
  for k,v in pairs(self.CharacterData.Levels) do
    if (k >= minLevel and k <= maxLevel) then
      for k2,v2 in pairs(v.ItemStatisticsByItem) do
        if (v2[acquisitionMethod]) then
          sum = sum + v2[acquisitionMethod]
        end
      end
    end
  end
  
  return sum
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

function Controller:GetMoneyForAcquisitionMethod(acquisitionMethod, minLevel, maxLevel)
  local sum = 0
  for k,v in pairs(self.CharacterData.Levels) do
    if (k >= minLevel and k <= maxLevel) then
      if (v.MoneyStatistics[acquisitionMethod]) then
        sum = sum + v.MoneyStatistics[acquisitionMethod]
      end
    end
  end
  
  return sum
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

function Controller:GetTaggedKillingBlows(minLevel, maxLevel)
  local sum = 0
  for k,v in pairs(self.CharacterData.Levels) do
    if (k >= minLevel and k <= maxLevel) then
      sum = sum + KillStatistics.GetTaggedKillingBlows(v.KillStatistics)
    end
  end
  
  return sum
end

function Controller:GetTaggedKills(minLevel, maxLevel)
  local sum = 0
  for k,v in pairs(self.CharacterData.Levels) do
    if (k >= minLevel and k <= maxLevel) then
      sum = sum + KillStatistics.GetTaggedKills(v.KillStatistics)
    end
  end
  
  return sum
end

function Controller:GetTaggedKillsByCatalogUnitId(catalogUnitId, minLevel, maxLevel)
  local sum = 0
  for k,v in pairs(self.CharacterData.Levels) do
    if (k >= minLevel and k <= maxLevel) then
      sum = sum + KillStatistics.GetTaggedKillsByCatalogUnitId(v.KillStatistics, catalogUnitId)
    end
  end
  
  return sum
end

function Controller:GetTotalKillingBlowsByCatalogUnitId(catalogUnitId, minLevel, maxLevel)
  local sum = 0
  for k,v in pairs(self.CharacterData.Levels) do
    if (k >= minLevel and k <= maxLevel) then
      sum = sum + KillStatistics.GetTotalKillingBlowsByCatalogUnitId(v.KillStatistics, catalogUnitId)
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

function Controller:OnAcquiredItem(timestamp, coordinates, acquisitionMethod, catalogItem, quantity)
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("AcquiredItem: " .. CatalogItem.ToString(catalogItem) .. ". Quantity: " .. tostring(quantity) .. ". Method: " .. tostring(acquisitionMethod) .. ".", AutoBiographerEnum.LogLevel.Debug) end
  
  if (not Catalogs.PlayerHasAcquiredItem(self.CharacterData.Catalogs, catalogItem.Id)) then
    catalogItem.Acquired = true
    self:UpdateCatalogItem(catalogItem)
    self:AddEvent(FirstAcquiredItemEvent.New(timestamp, coordinates, catalogItem.Id))
  end
  
  if (not self:GetCurrentLevelStatistics().ItemStatisticsByItem[catalogItem.Id]) then self:GetCurrentLevelStatistics().ItemStatisticsByItem[catalogItem.Id] = ItemStatistics.New() end
  ItemStatistics.AddCount(self:GetCurrentLevelStatistics().ItemStatisticsByItem[catalogItem.Id], acquisitionMethod, quantity)
end

function Controller:OnBossKill(timestamp, coordinates, bossId, bossName, hasKilledBossBefore)
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("BossKill: " .. tostring(bossName) .. " (#" .. tostring(bossId) .. ").", AutoBiographerEnum.LogLevel.Debug) end
  
  self:AddEvent(BossKillEvent.New(timestamp, coordinates, bossId, bossName))
  
  if (AutoBiographer_Settings.Options["TakeScreenshotOnBossKill"] and (not AutoBiographer_Settings.Options["TakeScreenshotOnlyOnFirstBossKill"] or not hasKilledBossBefore)) then
    self:TakeScreenshot(0.35)
  end
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

function Controller:OnDamageOrHealing(damageOrHealingCategory, amount, overkill)
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("DamageOrHealingCategory: " .. tostring(damageOrHealingCategory) .. ". Amount: " .. tostring(amount) .. ", over: " .. tostring(overkill), AutoBiographerEnum.LogLevel.Debug) end
  DamageStatistics.Add(self:GetCurrentLevelStatistics().DamageStatistics, damageOrHealingCategory, amount, overkill)
end

function Controller:OnDeath(timestamp, coordinates, killerCatalogUnitId, killerLevel)
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("Death: " .. " #" .. tostring(killerCatalogUnitId) .. ".", AutoBiographerEnum.LogLevel.Debug) end
  self:AddEvent(PlayerDeathEvent.New(timestamp, coordinates, killerCatalogUnitId, killerLevel))
  MiscellaneousStatistics.Add(self:GetCurrentLevelStatistics().MiscellaneousStatistics, AutoBiographerEnum.MiscellaneousTrackingType.PlayerDeaths, 1)
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
end

function Controller:OnGainedExperience(timestamp, coordinates, experienceTrackingType, amount)
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("GainedExperience: " .. tostring(amount) .. ". Experience Tracking Type: " .. tostring(experienceTrackingType) .. ".", AutoBiographerEnum.LogLevel.Debug) end
  ExperienceStatistics.AddExperience(self:GetCurrentLevelStatistics().ExperienceStatistics, experienceTrackingType, amount)
end

function Controller:OnGainedMoney(timestamp, coordinates, acquisitionMethod, money)
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("GainedMoney: " .. tostring(money) .. ". Acquisition Method: " .. tostring(acquisitionMethod) .. ".", AutoBiographerEnum.LogLevel.Debug) end
  MoneyStatistics.AddMoney(self:GetCurrentLevelStatistics().MoneyStatistics, acquisitionMethod, money)
end

function Controller:OnGuildRankChanged(timestamp, guildRankIndex, guildRankName)
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("GuildRankChanged: " .. " " .. tostring(guildRankName) .. " (" .. tostring(guildRankIndex) .. ").", AutoBiographerEnum.LogLevel.Debug) end
  self:AddEvent(GuildRankChangedEvent.New(timestamp, guildRankIndex, guildRankName))
end

function Controller:OnJoinedGuild(timestamp, guildName)
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("JoinedGuild: " .. " " .. tostring(guildName) .. ".", AutoBiographerEnum.LogLevel.Debug) end
  self:AddEvent(GuildJoinedEvent.New(timestamp, guildName))
end

function Controller:OnKill(timestamp, coordinates, kill)
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("Kill: " .. " #" .. tostring(kill.CatalogUnitId) .. ".", AutoBiographerEnum.LogLevel.Debug) end

  KillStatistics.AddKill(self.CharacterData.Levels[self:GetCurrentLevelNum()].KillStatistics, kill)
  if (kill.PlayerHasTag) then 
    local hasKilledUnitBefore = true
    if (not Catalogs.PlayerHasKilledUnit(self.CharacterData.Catalogs, kill.CatalogUnitId)) then
      hasKilledUnitBefore = false
      self:UpdateCatalogUnit(CatalogUnit.New(kill.CatalogUnitId, nil, nil, nil, nil, nil, nil, true))
      self:AddEvent(FirstKillEvent.New(timestamp, coordinates, kill.CatalogUnitId))
    end
    
    if (BossDatabase[kill.CatalogUnitId]) then
      Controller:OnBossKill(time(), HelperFunctions.GetCoordinatesByUnitId("player"), kill.CatalogUnitId, self.CharacterData.Catalogs.UnitCatalog[kill.CatalogUnitId].Name, hasKilledUnitBefore)
    end
  end
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
    if (AutoBiographer_Settings.Options["TakeScreenshotOnLevelUp"] and levelNum > 1) then 
      self:TakeScreenshot(1.15)
    end
  end
end

function Controller:OnMoneyChanged(timestamp, coordinates, deltaMoney)
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("MoneyChanged: " .. tostring(deltaMoney) .. ".", AutoBiographerEnum.LogLevel.Debug) end
  MoneyStatistics.TotalMoneyChanged(self:GetCurrentLevelStatistics().MoneyStatistics, deltaMoney)
end

function Controller:OnQuestTurnedIn(timestamp, coordinates, questId, questTitle, xpGained, moneyGained)
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("QuestTurnedIn: " .. tostring(questTitle) .. " (#" .. tostring(questId) .. "), " .. tostring(xpGained) .. ", " .. tostring(moneyGained) .. ".", AutoBiographerEnum.LogLevel.Debug) end
  self:AddEvent(QuestTurnInEvent.New(timestamp, coordinates, questId, questTitle, xpGained, moneyGained))
end

function Controller:OnReputationLevelChanged(timestamp, coordinates, faction, reputationLevel)
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("ReputationLevelChanged: " .. tostring(faction) .. ", " .. tostring(reputationLevel) .. ".", AutoBiographerEnum.LogLevel.Debug) end
  self:AddEvent(ReputationLevelChangedEvent.New(timestamp, coordinates, faction, reputationLevel))
end

function Controller:OnSpellLearned(timestamp, coordinates, spellId, spellName, spellRank)
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("SpellLearned: " .. tostring(spellName) .. " (#" .. tostring(spellId) .. "), " .. tostring(spellRank) .. ".", AutoBiographerEnum.LogLevel.Debug) end

  if (not self.CharacterData.Catalogs.SpellCatalog[spellId]) then
    self.CharacterData.Catalogs.SpellCatalog[spellId] = CatalogSpell.New(spellId, spellName, spellRank)
  end
  
  self:AddEvent(SpellLearnedEvent.New(timestamp, coordinates, spellId))
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
    Screenshot()
    if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("Screenshot captured after" .. tostring(secondsToDelay) .. "s delay .", AutoBiographerEnum.LogLevel.Debug) end
  end)
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
    CatalogUnit.Update(self.CharacterData.Catalogs.UnitCatalog[catalogUnit.Id], catalogUnit.Id, catalogUnit.Class, catalogUnit.Clsfctn, catalogUnit.CFam, catalogUnit.CType, catalogUnit.Name, catalogUnit.Race, catalogUnit.Killed)
  end
  
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog("CatalogUnit Updated: " .. CatalogUnit.ToString(self.CharacterData.Catalogs.UnitCatalog[catalogUnit.Id]) .. ".", AutoBiographerEnum.LogLevel.Debug) end
end