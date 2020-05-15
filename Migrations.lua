-- *** MigrationManager ***
AutoBiographer_MigrationManager = {
  Migrations = {}
}

local MM = AutoBiographer_MigrationManager

function MM:GetLatestDatabaseVersion()
  return #self.Migrations
end

function MM:RunMigrations(currentDatabaseVersion, eventManager, controller)
  if (not currentDatabaseVersion) then currentDatabaseVersion = 0 end
  if (currentDatabaseVersion >= #self.Migrations) then return end

  for i = currentDatabaseVersion + 1, #self.Migrations do
    self.Migrations[i]:Execute(eventManager, controller)
  end
end

-- *** Migration Base Class ***

AutoBiographer_Migration = {}
function AutoBiographer_Migration:New(migrationNum, func)
  return {
    Execute = function(self, eventManager, controller)
      controller:AddLog("Running migration " .. self.MigrationNumber .. "...", AutoBiographerEnum.LogLevel.Information)
      func(eventManager, controller)
      controller:AddLog("Migration " .. self.MigrationNumber .. " finished.", AutoBiographerEnum.LogLevel.Information)
      eventManager.PersistentPlayerInfo.DatabaseVersion = self.MigrationNumber
    end,
    MigrationNumber = migrationNum
  }
end

-- *** Concrete Migrations ***

table.insert(MM.Migrations, 
  AutoBiographer_Migration:New(
    1,
    function(eventManager, controller)
      for k,v in pairs(controller.CharacterData.Levels) do
        if (v.OtherPlayerStatisticsByOtherPlayer == nil) then v.OtherPlayerStatisticsByOtherPlayer = {} end
        if (v.SpellStatisticsBySpell == nil) then v.SpellStatisticsBySpell = {} end
      end
    end
  )
)

table.insert(MM.Migrations, 
  AutoBiographer_Migration:New(
    2,
    function(eventManager, controller)
      if (AutoBiographer_Settings.Options["ShowMinimapButton"] == nil) then AutoBiographer_Settings.Options["ShowMinimapButton"] = true end
      if (AutoBiographer_Settings.Options["ShowTimePlayedOnLevelUp"] == nil) then AutoBiographer_Settings.Options["ShowTimePlayedOnLevelUp"] = true end
    end
  )
)

table.insert(MM.Migrations, 
  AutoBiographer_Migration:New(
    3,
    function(eventManager, controller)
      if (AutoBiographer_Settings.Options["EnableDebugLogging"] == nil) then AutoBiographer_Settings.Options["EnableDebugLogging"] = false end
      if (AutoBiographer_Settings.Options["TakeScreenshotOnlyOnFirstBossKill"] == nil) then AutoBiographer_Settings.Options["TakeScreenshotOnlyOnFirstBossKill"] = true end
      
      for k,v in pairs(controller.CharacterData.Levels) do
        if (v.ExperienceStatistics == nil) then v.ExperienceStatistics = ExperienceStatistics.New() end
      end
    end
  )
)

table.insert(MM.Migrations, 
  AutoBiographer_Migration:New(
    4,
    function(eventManager, controller)
      -- Delete erroneous death events for pet classes.
      local playerClass, englishClass = UnitClass("player")
      if (englishClass == "HUNTER" or englishClass == "WARLOCK") then
        local lastDeathTimestamp = nil
        local indexesToDelete = {}
        for i = 1, #controller.CharacterData.Events do
          local event = controller.CharacterData.Events[i]

          if (event.Type == AutoBiographerEnum.EventType.Death or event.SubType == AutoBiographerEnum.EventSubType.PlayerDeath) then
            if (lastDeathTimestamp and (event.Timestamp - lastDeathTimestamp < 10)) then 
              indexesToDelete[i] = true
            end
            lastDeathTimestamp = event.Timestamp
          end        
        end
        HelperFunctions.RemoveElementsFromArrayAtIndexes(controller.CharacterData.Events, indexesToDelete)
        controller:AddLog("Deleted " .. #HelperFunctions.GetKeysFromTable(indexesToDelete) .. " duplicate death events.", AutoBiographerEnum.LogLevel.Information)
      end

      -- Create MiscellaneousStatistics for each level.
      for k,v in pairs(controller.CharacterData.Levels) do
        if (v.MiscellaneousStatistics == nil) then v.MiscellaneousStatistics = MiscellaneousStatistics.New() end
      end

      -- Populate each level's MiscellaneousStatistics with death count.
      local levelNum = HelperFunctions.GetKeysFromTable(controller.CharacterData.Levels, true)[1]
      for i = 1, #controller.CharacterData.Events do
        local event = controller.CharacterData.Events[i]

        if (event.Type == AutoBiographerEnum.EventType.Level and event.SubType == AutoBiographerEnum.EventSubType.LevelUp) then
          levelNum = event.LevelNum
        end

        if (event.Type == AutoBiographerEnum.EventType.Death and event.SubType == AutoBiographerEnum.EventSubType.PlayerDeath) then
          MiscellaneousStatistics.Add(controller.CharacterData.Levels[levelNum].MiscellaneousStatistics, AutoBiographerEnum.MiscellaneousTrackingType.PlayerDeaths, 1)
        end
      end
    end
  )
)

table.insert(MM.Migrations, 
  AutoBiographer_Migration:New(
    5,
    function(eventManager, controller)
      -- Create BossCatalog.
      if (controller.CharacterData.Catalogs.BossCatalog == nil) then controller.CharacterData.Catalogs.BossCatalog = {} end
      
      -- Delete duplicate boss kill events and update BossCatalog.
      local indexesToDelete = {}
      for i = 1, #controller.CharacterData.Events do
        local event = controller.CharacterData.Events[i]

        if (event.Type == AutoBiographerEnum.EventType.Kill and event.SubType == AutoBiographerEnum.EventSubType.BossKill) then
          local catalogUnit = controller.CharacterData.Catalogs.UnitCatalog[event.BossId]
          local isFromRegularKillEvent = catalogUnit ~= nil and catalogUnit.Name == event.BossName

          if (not isFromRegularKillEvent) then
            if (not Catalogs.PlayerHasKilledBoss(controller.CharacterData.Catalogs, event.BossId)) then
              controller:UpdateCatalogBoss(CatalogBoss.New(event.BossId, event.BossName, true))
            end
          end

          local matchingBossKillEvent = nil
          local otherEventIndex = i - 1
          while (matchingBossKillEvent == nil and event.Timestamp - controller.CharacterData.Events[otherEventIndex].Timestamp < 2) do
            local otherEvent = controller.CharacterData.Events[otherEventIndex]
            if (otherEvent.Type == AutoBiographerEnum.EventType.Kill and otherEvent.SubType == AutoBiographerEnum.EventSubType.BossKill and otherEvent.BossName == event.BossName) then 
              matchingBossKillEvent = otherEvent
            else
              otherEventIndex = otherEventIndex - 1
            end
          end

          if (matchingBossKillEvent ~= nil) then
            if (isFromRegularKillEvent) then
              indexesToDelete[i] = true
            else
              indexesToDelete[otherEventIndex] = true
            end
          end
        end
      end
      HelperFunctions.RemoveElementsFromArrayAtIndexes(controller.CharacterData.Events, indexesToDelete)
      controller:AddLog("Deleted " .. #HelperFunctions.GetKeysFromTable(indexesToDelete) .. " duplicate boss kill events.", AutoBiographerEnum.LogLevel.Information)
    end
  )
)

table.insert(MM.Migrations, 
  AutoBiographer_Migration:New(
    6,
    function(eventManager, controller)
      -- Update UnitCatalog with unit types.
      for k,v in pairs(controller.CharacterData.Catalogs.UnitCatalog) do
        if (v.UType == nil) then
          v.UType = HelperFunctions.GetUnitTypeFromCatalogUnitId(v.Id)

          if (v.UType == AutoBiographerEnum.UnitType.Player) then v.Killed = nil end -- A bug was setting the player units Killed field.
        end
      end

      -- Create DeathStatistics for each level.
      for k,v in pairs(controller.CharacterData.Levels) do
        if (v.DeathStatistics == nil) then v.DeathStatistics = DeathStatistics.New() end
        v.MiscellaneousStatistics[AutoBiographerEnum.MiscellaneousTrackingType.PlayerDeaths] = nil
      end

      -- Populate each level's DeathStatistics.
      local levelNum = HelperFunctions.GetKeysFromTable(controller.CharacterData.Levels, true)[1]
      for i = 1, #controller.CharacterData.Events do
        local event = controller.CharacterData.Events[i]

        if (event.Type == AutoBiographerEnum.EventType.Level and event.SubType == AutoBiographerEnum.EventSubType.LevelUp) then
          levelNum = event.LevelNum
        elseif (event.Type == AutoBiographerEnum.EventType.Death and event.SubType == AutoBiographerEnum.EventSubType.PlayerDeath) then
          local deathTrackingType

          if (event.KillerCuid == nil) then 
            deathTrackingType = AutoBiographerEnum.DeathTrackingType.DeathToEnvironment
          elseif (HelperFunctions.GetUnitTypeFromCatalogUnitId(event.KillerCuid) == AutoBiographerEnum.UnitType.Creature) then
            deathTrackingType = AutoBiographerEnum.DeathTrackingType.DeathToCreature
          elseif (HelperFunctions.GetUnitTypeFromCatalogUnitId(event.KillerCuid) == AutoBiographerEnum.UnitType.Pet) then
            deathTrackingType = AutoBiographerEnum.DeathTrackingType.DeathToPet
          elseif (HelperFunctions.GetUnitTypeFromCatalogUnitId(event.KillerCuid) == AutoBiographerEnum.UnitType.Player) then
            deathTrackingType = AutoBiographerEnum.DeathTrackingType.DeathToPlayer
          end
          
          DeathStatistics.Increment(controller.CharacterData.Levels[levelNum].DeathStatistics, deathTrackingType)
        end
      end
    end
  )
)
