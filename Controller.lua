Controller = {
  CharacterData = {}
}

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
    table.insert(self.CharacterData.Events, LevelEvent.New(timestampAtDing, coordinates, levelNum))
    self:PrintEvents()
  end
end

function Controller:AddKill(kill)
  local currentLevel = HelperFunctions.GetLastKeyFromTable(self.CharacterData.Levels)

  KillStatistics.AddKill(self.CharacterData.Levels[currentLevel].KillStatistics, kill)
  if (kill.PlayerHasTag) then print (KillStatistics.GetTaggedKillsByCatalogUnitId(self.CharacterData.Levels[currentLevel].KillStatistics, kill.CatalogUnitId)) end
end

function GetLevelKillsForUnitId(catalogUnitId, level)
  if (self.CharacterData.Levels.Kills[catalogUnitId] == nil) then return 0 end
  
  return self.CharacterData.Levels.Kills[catalogUnitId]
end

function Controller:GetTotalKillsForUnitId(catalogUnitId)
  local kills = 0
  for k,v in pairs(self.CharacterData.Levels) do
    if (v.Kills[catalogUnitId] ~= nil) then
      kills = kills + v.Kills[catalogUnitId]
    end
  end
  
  return kills
end

function Controller:PrintEvents()
  print("Printing " .. tostring(#self.CharacterData.Events) .. " events.")
  for _,v in pairs(self.CharacterData.Events) do
    print(Event.ToString(v))
  end
end

function Controller:UpdateCatalogUnit(catalogUnit)
  self.CharacterData.Catalogs.UnitCatalog[catalogUnit.Id] = catalogUnit
  --Catalogs.PrintUnitCatalog(self.CharacterData.Catalogs)
end