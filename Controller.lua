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
    --table.insert(self.CharacterData.Events, LevelUpEvent.New(timestampAtDing, coordinates, levelNum))
    --self:PrintLastEvent()
    self:AddEvent(LevelUpEvent.New(timestampAtDing, coordinates, levelNum))
  end
end

function Controller:AddKill(kill, timestamp, coordinates)
  local currentLevel = HelperFunctions.GetLastKeyFromTable(self.CharacterData.Levels)

  KillStatistics.AddKill(self.CharacterData.Levels[currentLevel].KillStatistics, kill)
  if (kill.PlayerHasTag) then 
    print (self:GetTaggedKillsByCatalogUnitId(kill.CatalogUnitId))
    if (not Catalogs.PlayerHasKilledUnit(self.CharacterData.Catalogs, kill.CatalogUnitId)) then
      local catalogUnit = self.CharacterData.Catalogs.UnitCatalog[kill.CatalogUnitId]
      
      if (catalogUnit ~= nil) then 
        catalogUnit.Killed = true
      else
        catalogUnit = CatalogUnit.New(kill.catalogUnitId, nil, nil, nil, nil, nil, nil, true)
      end
      
      self:UpdateCatalogUnit(catalogUnit)
      --table.insert(self.CharacterData.Events, FirstKillEvent.New(timestamp, coordinates, kill.CatalogUnitId))
      --self:PrintLastEvent()
      self:AddEvent(FirstKillEvent.New(timestamp, coordinates, kill.CatalogUnitId))
    end
  end
end

function Controller:GetTaggedKillsByCatalogUnitId(catalogUnitId)
  local sum = 0
  for k,v in pairs(self.CharacterData.Levels) do
    sum = sum + KillStatistics.GetTaggedKillsByCatalogUnitId(v.KillStatistics, catalogUnitId)
  end
  
  return sum
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
  self.CharacterData.Catalogs.UnitCatalog[catalogUnit.Id] = catalogUnit
  --Catalogs.PrintUnitCatalog(self.CharacterData.Catalogs)
end