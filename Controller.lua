Controller = {
  CharacterData = {}
}

function Controller:AddEvent(event)
  table.insert(self.CharacterData.Events, event)
  self:PrintLastEvent()
end

function Controller:AddLevel(levelNum, timestampAtDing, totalTimePlayedAtDing, coordinates)
  if self.CharacterData.Levels[levelNum] ~= nil then error("Can not add level " .. levelNum .. " because it was already added.") end
  
  self.CharacterData.Levels[levelNum] = LevelStatistics.New(levelNum, totalTimePlayedAtDing, nil)
  
  local currentLevel = self.CharacterData.Levels[levelNum]
  local previousLevel = self.CharacterData.Levels[levelNum - 1]
  
  print("level " .. levelNum .. ": " .. HelperFunctions.SecondsToTimeString(currentLevel.TotalTimePlayedAtDing))
  
  if (previousLevel ~= nil and previousLevel.TotalTimePlayedAtDing ~= nil) then
    previousLevel.TimePlayedThisLevel = currentLevel.TotalTimePlayedAtDing - previousLevel.TotalTimePlayedAtDing
    print("Time played last level = " .. HelperFunctions.SecondsToTimeString(previousLevel.TimePlayedThisLevel))
  end
  
  if (timestampAtDing ~= nil) then
    self:AddEvent(LevelUpEvent.New(timestampAtDing, coordinates, levelNum))
  end
end

function Controller:AddKill(kill, timestamp, coordinates)
  local currentLevel = HelperFunctions.GetLastKeyFromTable(self.CharacterData.Levels)

  KillStatistics.AddKill(self.CharacterData.Levels[currentLevel].KillStatistics, kill)
  if (kill.PlayerHasTag) then 
    print (self:GetTaggedKillsByCatalogUnitId(kill.CatalogUnitId))
    if (not Catalogs.PlayerHasKilledUnit(self.CharacterData.Catalogs, kill.CatalogUnitId)) then
      self:UpdateCatalogUnit(CatalogUnit.New(kill.CatalogUnitId, nil, nil, nil, nil, nil, nil, true))
      self:AddEvent(FirstKillEvent.New(timestamp, coordinates, kill.CatalogUnitId))
    end
  end
end

function Controller:CatalogUnitIsIncomplete(catalogUnitId)
  return self.CharacterData.Catalogs.UnitCatalog[catalogUnitId] == nil or self.CharacterData.Catalogs.UnitCatalog[catalogUnitId].Name == nil
end

function Controller:GetTaggedKillsByCatalogUnitId(catalogUnitId)
  local sum = 0
  for k,v in pairs(self.CharacterData.Levels) do
    sum = sum + KillStatistics.GetTaggedKillsByCatalogUnitId(v.KillStatistics, catalogUnitId)
  end
  
  return sum
end

function Controller:OnBossKill(timestamp, coordinates, bossId, bossName)
  self:AddEvent(BossKillEvent.New(timestamp, coordinates, bossId, bossName))
end

function Controller:OnSpellLearned(timestamp, coordinates, spellId, spellName, spellRank)
  if (self.CharacterData.Catalogs.SpellCatalog[spellId] == nil) then
    self.CharacterData.Catalogs.SpellCatalog[spellId] = CatalogSpell.New(spellId, spellName, spellRank)
  end
  
  self:AddEvent(SpellLearnedEvent.New(timestamp, coordinates, spellId))
end

function Controller:PlayerChangedSubZone(timestamp, coordinates, zoneName, subZoneName)
  if (subZoneName == nil or subZoneName == "") then return end
  
  if (self.CharacterData.Catalogs.SubZoneCatalog[subZoneName] == nil) then
    self.CharacterData.Catalogs.SubZoneCatalog[subZoneName] = CatalogSubZone.New(subZoneName, true, zoneName)
    self:AddEvent(SubZoneFirstVisitEvent.New(timestamp, coordinates, subZoneName))
  end
end

function Controller:PlayerChangedZone(timestamp, coordinates, zoneName)
  if (self.CharacterData.Catalogs.ZoneCatalog[zoneName] == nil) then
    self.CharacterData.Catalogs.ZoneCatalog[zoneName] = CatalogZone.New(zoneName, true)
    self:AddEvent(ZoneFirstVisitEvent.New(timestamp, coordinates, zoneName))
  end
end

function Controller:PlayerDied(timestamp, coordinates, killerCatalogUnitId, killerLevel)
  self:AddEvent(PlayerDeathEvent.New(timestamp, coordinates, killerCatalogUnitId, killerLevel))
end

function Controller:PrintEvents()
  for _,v in pairs(self.CharacterData.Events) do
    print(Event.ToString(v, self.CharacterData.Catalogs))
  end
end

function Controller:PrintLastEvent()
  print(Event.ToString(self.CharacterData.Events[#self.CharacterData.Events], self.CharacterData.Catalogs))
end

function Controller:QuestTurnedIn(timestamp, coordinates, questId, questTitle, xpGained, moneyGained)
  self:AddEvent(QuestTurnInEvent.New(timestamp, coordinates, questId, questTitle, xpGained, moneyGained))
end

function Controller:UpdateCatalogUnit(catalogUnit)
  if (self.CharacterData.Catalogs.UnitCatalog[catalogUnit.Id] == nil) then
    self.CharacterData.Catalogs.UnitCatalog[catalogUnit.Id] = catalogUnit
  else
    CatalogUnit.Update(self.CharacterData.Catalogs.UnitCatalog[catalogUnit.Id], catalogUnit.Id, catalogUnit.Class, catalogUnit.Clsfctn, catalogUnit.CFam, catalogUnit.CType, catalogUnit.Name, catalogUnit.Race, catalogUnit.Killed)
  end
  --Catalogs.PrintUnitCatalog(self.CharacterData.Catalogs)
end