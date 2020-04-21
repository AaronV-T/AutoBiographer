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
