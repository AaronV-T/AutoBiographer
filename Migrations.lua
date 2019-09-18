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
