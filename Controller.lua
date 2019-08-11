Controller = {
  CharacterData = {}
}

function Controller:AddLevel(levelNum, timestampAtDing, totalTimePlayedAtDing)
  if self.CharacterData.Levels[levelNum] ~= nil then error("Can not add level " .. levelNum .. " because it was already added.") end
  
  self.CharacterData.Levels[levelNum] = LevelStatistics.New(levelNum, totalTimePlayedAtDing, nil)
  
  local currentLevel = self.CharacterData.Levels[levelNum]
  local previousLevel = self.CharacterData.Levels[levelNum - 1]
  
  print("level " .. levelNum .. ": " .. HelperFunctions.SecondsToTimeString(currentLevel.TotalTimePlayedAtDing))
  
  if (previousLevel ~= nil and previousLevel.TotalTimePlayedAtDing ~= nil) then
    previousLevel.TimePlayedThisLevel = currentLevel.TotalTimePlayedAtDing - previousLevel.TotalTimePlayedAtDing
    print("Time played last level = " .. HelperFunctions.SecondsToTimeString(previousLevel.TimePlayedThisLevel))
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

function Controller:UpdateCatalogUnit(catalogUnit)
  self.CharacterData.Catalogs.UnitCatalog[catalogUnit.Id] = catalogUnit
end