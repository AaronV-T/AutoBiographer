Controller = {
  CharacterData = {},
  Logs = {}, 
}

function Controller:AddEvent(event)
  table.insert(self.CharacterData.Events, event)
  Controller:AddLog(Event.ToString(self.CharacterData.Events[#self.CharacterData.Events], self.CharacterData.Catalogs), AutoBiographerEnum.LogLevel.Debug)
  print(Event.ToString(self.CharacterData.Events[#self.CharacterData.Events], self.CharacterData.Catalogs))
end

function Controller:AddLog(text, logLevel)
  if (logLevel == nil) then error("Unspecified logLevel. Log Text: '" .. text .. "'") end
  
  table.insert(self.Logs, { Level = logLevel, Text = tostring(text), Timestamp = time() })
  
  if (DebugWindow_Frame) then DebugWindow_Frame.LogsUpdated() end
end

function Controller:AddTime(timeTrackingType, seconds, zone, subZone)
  Controller:AddLog("Adding " .. tostring(seconds) .. " seconds of timeTrackingType " .. tostring(timeTrackingType) .. " to " .. tostring(subZone) .. " (" .. tostring(zone) .. ").", AutoBiographerEnum.LogLevel.Debug)
  
  local id = tostring(zone) .. "-" .. tostring(subZone)
  TimeStatistics.AddTime(self:GetCurrentLevelStatistics().TimeStatisticsByArea, timeTrackingType, seconds)
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

function Controller:GetDamageOrHealing(category)
  local amountSum = 0
  local overkillSum = 0
  for k,v in pairs(self.CharacterData.Levels) do
    if (category == AutoBiographerEnum.DamageOrHealingCategory.DamageDealt) then
      amountSum = amountSum + v.DamageStatistics.DamageDealt.Amount
      overkillSum = overkillSum + v.DamageStatistics.DamageDealt.Over
    elseif (category == AutoBiographerEnum.DamageOrHealingCategory.DamageTaken) then
      amountSum = amountSum + v.DamageStatistics.DamageTaken.Amount
      overkillSum = overkillSum + v.DamageStatistics.DamageTaken.Over
    else
      error("Unimplemented category: " .. category)
    end
  end
  
  return amountSum, overkillSum
end

function Controller:GetEvents()
  local retVal = {}
  for _,v in pairs(self.CharacterData.Events) do
    table.insert(retVal, tostring(Event.ToString(v, self.CharacterData.Catalogs)))
  end
  
  return retVal
end

function Controller:GetLogs()
  local retVal = {}
  for _,v in pairs(self.Logs) do
    table.insert(retVal, v.Text )
  end
  
  return retVal
end

function Controller:GetLootedMoney()
  local sum = 0
  for k,v in pairs(self.CharacterData.Levels) do
    sum = sum + v.MoneyStatistics.MoneyLooted
  end
  
  return sum
end

function Controller:GetTotalMoneyGained()
  local sum = 0
  for k,v in pairs(self.CharacterData.Levels) do
    sum = sum + v.MoneyStatistics.TotalMoneyGained
  end
  
  return sum
end

function Controller:GetTotalMoneyLost()
  local sum = 0
  for k,v in pairs(self.CharacterData.Levels) do
    sum = sum + v.MoneyStatistics.TotalMoneyLost
  end
  
  return sum
end

function Controller:GetTaggedKillsByCatalogUnitId(catalogUnitId)
  local sum = 0
  for k,v in pairs(self.CharacterData.Levels) do
    sum = sum + KillStatistics.GetTaggedKillsByCatalogUnitId(v.KillStatistics, catalogUnitId)
  end
  
  return sum
end

function Controller:GetTimeForTimeTrackingType(timeTrackingType)
  local sum = 0
  for k,v in pairs(self.CharacterData.Levels) do
    if (v.TimeStatisticsByArea[timeTrackingType]) then
      sum = sum + v.TimeStatisticsByArea[timeTrackingType]
    end
  end
  
  return sum
end

-- *** Events ***

function Controller:OnBossKill(timestamp, coordinates, bossId, bossName)
  Controller:AddLog("BossKill: " .. tostring(bossName) .. " (#" .. tostring(bossId) .. ").", AutoBiographerEnum.LogLevel.Debug)
  self:AddEvent(BossKillEvent.New(timestamp, coordinates, bossId, bossName))
end

function Controller:OnChangedSubZone(timestamp, coordinates, zoneName, subZoneName)
  if (subZoneName == nil or subZoneName == "") then return end
  Controller:AddLog("ChangedSubZone: " .. tostring(subZoneName) .. " (" .. tostring(zoneName) .. ").", AutoBiographerEnum.LogLevel.Debug)
  
  if (self.CharacterData.Catalogs.SubZoneCatalog[subZoneName] == nil) then
    self.CharacterData.Catalogs.SubZoneCatalog[subZoneName] = CatalogSubZone.New(subZoneName, true, zoneName)
    self:AddEvent(SubZoneFirstVisitEvent.New(timestamp, coordinates, subZoneName))
  end
end

function Controller:OnChangedZone(timestamp, coordinates, zoneName)
  Controller:AddLog("ChangedZone: " .. tostring(zoneName) .. ".", AutoBiographerEnum.LogLevel.Debug)

  if (self.CharacterData.Catalogs.ZoneCatalog[zoneName] == nil) then
    self.CharacterData.Catalogs.ZoneCatalog[zoneName] = CatalogZone.New(zoneName, true)
    self:AddEvent(ZoneFirstVisitEvent.New(timestamp, coordinates, zoneName))
  end
end

function Controller:OnDamageDealt(amount, overkill)
  Controller:AddLog("DamageDealt: " .. tostring(amount) .. ". Over: " .. tostring(overkill), AutoBiographerEnum.LogLevel.Debug)
  DamageStatistics.AddDamageDealt(self:GetCurrentLevelStatistics().DamageStatistics, amount, overkill)
end

function Controller:OnDamageTaken(amount, overkill)
  Controller:AddLog("DamageTaken: " .. tostring(amount) .. ". Over: " .. tostring(overkill), AutoBiographerEnum.LogLevel.Debug)
  DamageStatistics.AddDamageTaken(self:GetCurrentLevelStatistics().DamageStatistics, amount, overkill)
end

function Controller:OnDeath(timestamp, coordinates, killerCatalogUnitId, killerLevel)
  Controller:AddLog("Death: " .. " #" .. tostring(killerCatalogUnitId) .. ".", AutoBiographerEnum.LogLevel.Debug)
  self:AddEvent(PlayerDeathEvent.New(timestamp, coordinates, killerCatalogUnitId, killerLevel))
end

function Controller:OnKill(timestamp, coordinates, kill)
  Controller:AddLog("Kill: " .. " #" .. tostring(kill.CatalogUnitId) .. ".", AutoBiographerEnum.LogLevel.Debug)

  KillStatistics.AddKill(self.CharacterData.Levels[self:GetCurrentLevelNum()].KillStatistics, kill)
  if (kill.PlayerHasTag) then 
    --print (self:GetTaggedKillsByCatalogUnitId(kill.CatalogUnitId))
    if (not Catalogs.PlayerHasKilledUnit(self.CharacterData.Catalogs, kill.CatalogUnitId)) then
      self:UpdateCatalogUnit(CatalogUnit.New(kill.CatalogUnitId, nil, nil, nil, nil, nil, nil, true))
      self:AddEvent(FirstKillEvent.New(timestamp, coordinates, kill.CatalogUnitId))
    end
  end
end

function Controller:OnLevelUp(timestamp, coordinates, levelNum, totalTimePlayedAtDing)
  if self.CharacterData.Levels[levelNum] ~= nil then error("Can not add level " .. levelNum .. " because it was already added.") end
  Controller:AddLog("LevelUp: " .. tostring(levelNum) .. ", " .. HelperFunctions.SecondsToTimeString(totalTimePlayedAtDing) .. ".", AutoBiographerEnum.LogLevel.Debug)
  
  self.CharacterData.Levels[levelNum] = LevelStatistics.New(levelNum, totalTimePlayedAtDing, nil)
  
  local currentLevel = self.CharacterData.Levels[levelNum]
  local previousLevel = self.CharacterData.Levels[levelNum - 1]
  
  if (previousLevel ~= nil and previousLevel.TotalTimePlayedAtDing ~= nil) then
    previousLevel.TimePlayedThisLevel = currentLevel.TotalTimePlayedAtDing - previousLevel.TotalTimePlayedAtDing
    Controller:AddLog("Time played last level = " .. HelperFunctions.SecondsToTimeString(previousLevel.TimePlayedThisLevel), AutoBiographerEnum.LogLevel.Debug)
  end
  
  if (timestamp) then
    self:AddEvent(LevelUpEvent.New(timestamp, coordinates, levelNum))
  end
end

function Controller:OnLootMoney(timestamp, coordinates, money)
  Controller:AddLog("LootedMoney: " .. tostring(money) .. ".", AutoBiographerEnum.LogLevel.Debug)
  MoneyStatistics.AddLootedMoney(self.CharacterData.Levels[self:GetCurrentLevelNum()].MoneyStatistics, money)
end

function Controller:OnMoneyChanged(timestamp, coordinates, deltaMoney)
  Controller:AddLog("MoneyChanged: " .. tostring(deltaMoney) .. ".", AutoBiographerEnum.LogLevel.Debug)
  MoneyStatistics.MoneyChanged(self.CharacterData.Levels[self:GetCurrentLevelNum()].MoneyStatistics, deltaMoney)
end

function Controller:OnQuestTurnedIn(timestamp, coordinates, questId, questTitle, xpGained, moneyGained)
  Controller:AddLog("QuestTurnedIn: " .. tostring(questTitle) .. " (#" .. tostring(questId) .. "), " .. tostring(xpGained) .. ", " .. tostring(moneyGained) .. ".", AutoBiographerEnum.LogLevel.Debug)
  self:AddEvent(QuestTurnInEvent.New(timestamp, coordinates, questId, questTitle, xpGained, moneyGained))
end

function Controller:OnSpellLearned(timestamp, coordinates, spellId, spellName, spellRank)
  Controller:AddLog("SpellLearned: " .. tostring(spellName) .. " (#" .. tostring(spellId) .. "), " .. tostring(spellRank) .. ".", AutoBiographerEnum.LogLevel.Debug)

  if (self.CharacterData.Catalogs.SpellCatalog[spellId] == nil) then
    self.CharacterData.Catalogs.SpellCatalog[spellId] = CatalogSpell.New(spellId, spellName, spellRank)
  end
  
  self:AddEvent(SpellLearnedEvent.New(timestamp, coordinates, spellId))
end


function Controller:PrintEvents()
  for _,v in pairs(self.CharacterData.Events) do
    print(Event.ToString(v, self.CharacterData.Catalogs))
  end
end

function Controller:PrintLastEvent()
  print(Event.ToString(self.CharacterData.Events[#self.CharacterData.Events], self.CharacterData.Catalogs))
end

function Controller:UpdateCatalogUnit(catalogUnit)
  if (self.CharacterData.Catalogs.UnitCatalog[catalogUnit.Id] == nil) then
    self.CharacterData.Catalogs.UnitCatalog[catalogUnit.Id] = catalogUnit
  else
    CatalogUnit.Update(self.CharacterData.Catalogs.UnitCatalog[catalogUnit.Id], catalogUnit.Id, catalogUnit.Class, catalogUnit.Clsfctn, catalogUnit.CFam, catalogUnit.CType, catalogUnit.Name, catalogUnit.Race, catalogUnit.Killed)
  end
  
  Controller:AddLog("CatalogUnit Updated: " .. CatalogUnit.ToString(self.CharacterData.Catalogs.UnitCatalog[catalogUnit.Id]) .. ".", AutoBiographerEnum.LogLevel.Debug)
end