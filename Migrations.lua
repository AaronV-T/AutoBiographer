-- *** MigrationManager ***
AutoBiographer_MigrationManager = {
  AccountMigrations = {},
  CharacterMigrations = {},
}

local MM = AutoBiographer_MigrationManager

function MM:GetLatestAccountDatabaseVersion()
  return #self.AccountMigrations
end

function MM:GetLatestCharacterDatabaseVersion()
  return #self.CharacterMigrations
end

local function RunMigrations(migrations, currentDatabaseVersion, eventManager, controller)
  for i = (currentDatabaseVersion or 0) + 1, #migrations do
    migrations[i]:Execute(eventManager, controller)
  end
end

function MM:RunAccountMigrations(currentDatabaseVersion, eventManager, controller)
  RunMigrations(self.AccountMigrations, currentDatabaseVersion, eventManager, controller)
end

function MM:RunCharacterMigrations(currentDatabaseVersion, eventManager, controller)
  RunMigrations(self.CharacterMigrations, currentDatabaseVersion, eventManager, controller)
end

-- *** Migration Base Class ***

AutoBiographer_Migration = {}
function AutoBiographer_Migration:New(migrationNum, func, scope)
  scope = scope or "Character"
  return {
    Execute = function(self, eventManager, controller)
      controller:AddLog("Running " .. self.Scope .. " migration " .. self.MigrationNumber .. "...", AutoBiographerEnum.LogLevel.Information)
      func(eventManager, controller)
      controller:AddLog(self.Scope .. " migration " .. self.MigrationNumber .. " finished.", AutoBiographerEnum.LogLevel.Information)
      local versionData = self.Scope == "Account" and AutoBiographer_Settings or eventManager.PersistentPlayerInfo
      versionData.DatabaseVersion = self.MigrationNumber
    end,
    MigrationNumber = migrationNum,
    Scope = scope,
  }
end

local function AddMissing(data, defaults)
  for key, value in pairs(defaults) do
    if (data[key] == nil) then data[key] = value end
  end
end

-- *** Character Migrations ***
-- Keep historical numbering, including no-op slots that used to migrate
-- account settings. Those settings now belong to account migration 1.

table.insert(MM.CharacterMigrations,
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

table.insert(MM.CharacterMigrations,
  AutoBiographer_Migration:New(
    2,
    function(eventManager, controller)
    end
  )
)

table.insert(MM.CharacterMigrations,
  AutoBiographer_Migration:New(
    3,
    function(eventManager, controller)
      for k,v in pairs(controller.CharacterData.Levels) do
        if (v.ExperienceStatistics == nil) then v.ExperienceStatistics = ExperienceStatistics.New() end
      end
    end
  )
)

table.insert(MM.CharacterMigrations,
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

table.insert(MM.CharacterMigrations,
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

table.insert(MM.CharacterMigrations,
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

table.insert(MM.CharacterMigrations,
  AutoBiographer_Migration:New(
    7,
    function(eventManager, controller)
      if (eventManager.PersistentPlayerInfo.BattlegroundStatuses == nil) then
        eventManager.PersistentPlayerInfo.BattlegroundStatuses = {}
      end

      -- Create BattlegroundStatistics for each level.
      for k,v in pairs(controller.CharacterData.Levels) do
        if (v.BattlegroundStatistics == nil) then
          v.BattlegroundStatistics = BattlegroundStatistics.New()
        end
      end

    end
  )
)

table.insert(MM.CharacterMigrations,
  AutoBiographer_Migration:New(
    8,
    function(eventManager, controller)

    end
  )
)

table.insert(MM.CharacterMigrations,
  AutoBiographer_Migration:New(
    9,
    function(eventManager, controller)
      if (controller:GetCurrentLevelStatistics().KillStatistics) then
        local ensureKillStatisticsExistsForCatalogUnitId = function(killStatisticsByUnit, catalogUnitId)
          if (not killStatisticsByUnit[catalogUnitId]) then
            killStatisticsByUnit[catalogUnitId] = {
              TaggedAssists = 0,
              TaggedGroupAssistsAndKillingBlows = 0,
              TaggedKillingBlows = 0,
              UntaggedAssists = 0,
              UntaggedGroupAssistsAndKillingBlows = 0,
              UntaggedKillingBlows = 0,
            }
          end
        end
      
        for levelNum, levelStats in pairs(controller.CharacterData.Levels) do
          if (not levelStats.KillStatisticsByUnit) then
            levelStats.KillStatisticsByUnit = {}
        
            for catalogUnitId, taggedKillingBlows in pairs(levelStats.KillStatistics.TaggedKills.PlayerKillingBlows) do
              ensureKillStatisticsExistsForCatalogUnitId(levelStats.KillStatisticsByUnit, catalogUnitId)
              levelStats.KillStatisticsByUnit[catalogUnitId].TaggedKillingBlows = levelStats.KillStatisticsByUnit[catalogUnitId].TaggedKillingBlows + taggedKillingBlows
            end
            for catalogUnitId, taggedAssists in pairs(levelStats.KillStatistics.TaggedKills.PlayerAssists) do
              ensureKillStatisticsExistsForCatalogUnitId(levelStats.KillStatisticsByUnit, catalogUnitId)
              levelStats.KillStatisticsByUnit[catalogUnitId].TaggedAssists = levelStats.KillStatisticsByUnit[catalogUnitId].TaggedAssists + taggedAssists
            end
            for catalogUnitId, taggedGroupAssistsAndKillingBlows in pairs(levelStats.KillStatistics.TaggedKills.GroupAssistsAndKillingBlows) do
              ensureKillStatisticsExistsForCatalogUnitId(levelStats.KillStatisticsByUnit, catalogUnitId)
              levelStats.KillStatisticsByUnit[catalogUnitId].TaggedGroupAssistsAndKillingBlows = levelStats.KillStatisticsByUnit[catalogUnitId].TaggedGroupAssistsAndKillingBlows + taggedGroupAssistsAndKillingBlows
            end
            for catalogUnitId, untaggedKillingBlows in pairs(levelStats.KillStatistics.UntaggedKills.PlayerKillingBlows) do
              ensureKillStatisticsExistsForCatalogUnitId(levelStats.KillStatisticsByUnit, catalogUnitId)
              levelStats.KillStatisticsByUnit[catalogUnitId].UntaggedKillingBlows = levelStats.KillStatisticsByUnit[catalogUnitId].UntaggedKillingBlows + untaggedKillingBlows
            end
            for catalogUnitId, untaggedAssists in pairs(levelStats.KillStatistics.UntaggedKills.PlayerAssists) do
              ensureKillStatisticsExistsForCatalogUnitId(levelStats.KillStatisticsByUnit, catalogUnitId)
              levelStats.KillStatisticsByUnit[catalogUnitId].UntaggedAssists = levelStats.KillStatisticsByUnit[catalogUnitId].UntaggedAssists + untaggedAssists
            end
            for catalogUnitId, untaggedGroupAssistsAndKillingBlows in pairs(levelStats.KillStatistics.UntaggedKills.GroupAssistsAndKillingBlows) do
              ensureKillStatisticsExistsForCatalogUnitId(levelStats.KillStatisticsByUnit, catalogUnitId)
              levelStats.KillStatisticsByUnit[catalogUnitId].UntaggedGroupAssistsAndKillingBlows = levelStats.KillStatisticsByUnit[catalogUnitId].UntaggedGroupAssistsAndKillingBlows + untaggedGroupAssistsAndKillingBlows
            end

            levelStats.KillStatistics = nil
          end
        end
      end

    end
  )
)

table.insert(MM.CharacterMigrations,
  AutoBiographer_Migration:New(
    10,
    function(eventManager, controller)
      for levelNum, levelStatistics in pairs(controller.CharacterData.Levels) do
        for catalogUnitId, killStatistics in pairs(levelStatistics.KillStatisticsByUnit) do
          if (killStatistics.TaggedAssists) then
            killStatistics[AutoBiographerEnum.KillTrackingType.TaggedAssist] = killStatistics.TaggedAssists
          end
          if (killStatistics.TaggedGroupAssistsAndKillingBlows) then
            killStatistics[AutoBiographerEnum.KillTrackingType.TaggedGroupAssistOrKillingBlow] = killStatistics.TaggedGroupAssistsAndKillingBlows
          end
          if (killStatistics.TaggedKillingBlows) then
            killStatistics[AutoBiographerEnum.KillTrackingType.TaggedKillingBlow] = killStatistics.TaggedKillingBlows
          end
          if (killStatistics.UntaggedAssists) then
            killStatistics[AutoBiographerEnum.KillTrackingType.UntaggedAssist] = killStatistics.UntaggedAssists
          end
          if (killStatistics.UntaggedGroupAssistsAndKillingBlows) then
            killStatistics[AutoBiographerEnum.KillTrackingType.UntaggedGroupAssistOrKillingBlow] = killStatistics.UntaggedGroupAssistsAndKillingBlows
          end
          if (killStatistics.UntaggedKillingBlows) then
            killStatistics[AutoBiographerEnum.KillTrackingType.UntaggedKillingBlow] = killStatistics.UntaggedKillingBlows
          end

          killStatistics.TaggedAssists = nil
          killStatistics.TaggedGroupAssistsAndKillingBlows = nil
          killStatistics.TaggedKillingBlows = nil
          killStatistics.UntaggedAssists = nil
          killStatistics.UntaggedGroupAssistsAndKillingBlows = nil
          killStatistics.UntaggedKillingBlows = nil
        end
      end
    end
  )
)

table.insert(MM.CharacterMigrations,
  AutoBiographer_Migration:New(
    11,
    function(eventManager, controller)
    end
  )
)

table.insert(MM.CharacterMigrations,
  AutoBiographer_Migration:New(
    12,
    function(eventManager, controller)
      -- Create QuestStatisticsByQuest for each level.
      for k,v in pairs(controller.CharacterData.Levels) do
        if (v.QuestStatisticsByQuest == nil) then v.QuestStatisticsByQuest = {} end
      end

      -- Populate each level's QuestStatisticsByQuest.
      local levelNum = HelperFunctions.GetKeysFromTable(controller.CharacterData.Levels, true)[1]
      for i = 1, #controller.CharacterData.Events do
        local event = controller.CharacterData.Events[i]

        if (event.Type == AutoBiographerEnum.EventType.Level and event.SubType == AutoBiographerEnum.EventSubType.LevelUp) then
          levelNum = event.LevelNum
        elseif (event.Type == AutoBiographerEnum.EventType.Quest and event.SubType == AutoBiographerEnum.EventSubType.QuestTurnIn) then
          if (controller.CharacterData.Levels[levelNum].QuestStatisticsByQuest[event.QuestId] == nil) then
            controller.CharacterData.Levels[levelNum].QuestStatisticsByQuest[event.QuestId] = QuestStatistics.New()
          end

          QuestStatistics.Increment(controller.CharacterData.Levels[levelNum].QuestStatisticsByQuest[event.QuestId], AutoBiographerEnum.QuestTrackingType.Completed)
        end
      end
    end
  )
)

table.insert(MM.CharacterMigrations,
  AutoBiographer_Migration:New(
    13,
    function(eventManager, controller)
      if (eventManager.PersistentPlayerInfo.ArenaStatuses == nil) then
        eventManager.PersistentPlayerInfo.ArenaStatuses = {}
      end      

      -- Create ArenaStatistics for each level.
      for k,v in pairs(controller.CharacterData.Levels) do
        if (v.ArenaStatistics == nil) then
          v.ArenaStatistics = ArenaStatistics.New()
        end
      end

    end
  )
)

table.insert(MM.CharacterMigrations,
  AutoBiographer_Migration:New(
    14,
    function(eventManager, controller)
      -- Delete duplicate spell learned events.
      local seenSpellIds = {}
      local indexesToDelete = {}
      for i = 1, #controller.CharacterData.Events do
        local event = controller.CharacterData.Events[i]

        if (event.Type == AutoBiographerEnum.EventType.Spell and event.SubType == AutoBiographerEnum.EventSubType.SpellLearned) then
          local spellId = event.SpellId
          if (seenSpellIds[spellId] == nil) then
            seenSpellIds[spellId] = true
          else
            indexesToDelete[i] = true
          end
        end
      end

      HelperFunctions.RemoveElementsFromArrayAtIndexes(controller.CharacterData.Events, indexesToDelete)
      controller:AddLog("Deleted " .. #HelperFunctions.GetKeysFromTable(indexesToDelete) .. " duplicate spell learned events.", AutoBiographerEnum.LogLevel.Information)
    end
  )
)

table.insert(MM.CharacterMigrations,
  AutoBiographer_Migration:New(
    15,
    function(eventManager, controller)
    end
  )
)

table.insert(MM.CharacterMigrations,
  AutoBiographer_Migration:New(
    16,
    function(eventManager, controller)
    end
  )
)

table.insert(MM.CharacterMigrations,
  AutoBiographer_Migration:New(
    17,
    function(eventManager, controller)
    end
  )
)

table.insert(MM.CharacterMigrations,
  AutoBiographer_Migration:New(
    18,
    function(eventManager, controller)
    end
  )
)

table.insert(MM.CharacterMigrations,
  AutoBiographer_Migration:New(
    19,
    function(eventManager, controller)
    end
  )
)

table.insert(MM.CharacterMigrations,
  AutoBiographer_Migration:New(
    20,
    function(eventManager, controller)
      local catalogs = controller.CharacterData.Catalogs
      AddMissing(catalogs, Catalogs.New())

      -- Version 19 stored one aggregate per category, using different enum
      -- numbers. Keep those totals; their spell/source details were not saved.
      local categories = AutoBiographerEnum.DamageOrHealingCategory
      local upgradingDamage = (eventManager.PersistentPlayerInfo.DatabaseVersion or 0) < 20
      for _, levelStatistics in pairs(controller.CharacterData.Levels) do
        if (upgradingDamage) then
          local old, migrated = levelStatistics.DamageStatistics or {}, DamageStatistics.New()
          local function SpellTotal(oldCategory, category)
            local breakdown = old[oldCategory]
            if (breakdown) then
              DamageStatistics.AddSpellBreakdown(migrated, category, 0, breakdown.Amount, breakdown.Over)
              if (not catalogs.SpellCatalog[0]) then catalogs.SpellCatalog[0] = CatalogSpell.New(0, "Unknown", nil) end
            end
          end
          local function RawTotal(oldCategory, category)
            local breakdown = old[oldCategory]
            if (breakdown) then DamageStatistics.AddRawBreakdown(migrated, category, breakdown.Amount, breakdown.Over) end
          end
          SpellTotal(0, categories.DamageDealt)
          SpellTotal(5, categories.DamageDealt) -- Pet damage is included with the player's damage now.
          SpellTotal(2, categories.HealingDealt)
          SpellTotal(3, categories.HealingDealt)
          RawTotal(1, categories.DamageTakenRaw)
          RawTotal(4, categories.HealingTakenRaw)
          RawTotal(6, categories.PetDamageTakenRaw)
          levelStatistics.DamageStatistics = migrated
        end
        AddMissing(levelStatistics, {
          DamageStatistics = DamageStatistics.New(),
          DistanceStatistics = DistanceStatistics.New(),
          MessageStatistics = MessageStatistics.New(),
          TimeStatisticsByCompanionFamily = {},
          TimeStatisticsBySpell = {},
        })
      end

      local notes = controller.AccountData.Notes
      local legacyNotes = _G["AUTOBIOGRAPHER_NOTES_CHAR"]
      if (type(legacyNotes) == "table" and legacyNotes ~= notes) then
        for _, note in ipairs(legacyNotes.GenericNotes or {}) do
          if (not Notes.Contains(notes, note)) then table.insert(notes.GenericNotes, note) end
        end
        for id, note in pairs(legacyNotes.UnitNotes or {}) do
          local unit = catalogs.UnitCatalog[id]
          local name = unit and unit.Name or ("Unit #" .. tostring(id))
          if (unit and unit.LastName) then name = name .. " " .. unit.LastName end
          if (not note.Name) then note.Name = name end
          local existing = notes.UnitNotes[id]
          if (not existing) then
            notes.UnitNotes[id] = note
          elseif (existing ~= note and existing.Content ~= note.Content) then
            -- One linked note per identity: retain a conflicting character
            -- note as a named general note instead of overwriting either.
            local copy = {}
            for key, value in pairs(note) do copy[key] = value end
            copy.Content = note.Name .. "\n" .. note.Content
            table.insert(notes.GenericNotes, copy)
          end
        end
      end
      _G["AUTOBIOGRAPHER_NOTES_CHAR"] = nil

      AddMissing(controller.CharacterData.Gear, GearHistory.New())
      AddMissing(controller.CharacterData.Snapshots, CharacterSnapshots.New())
      local tasks = controller.CharacterData.Todos
      AddMissing(tasks, Todo.New())
      for _, item in ipairs(tasks.Items) do
        if (item.Enabled == false) then item.Completed = true end
        item.Enabled = nil
        if (item.Type == "Always") then item.Recurring = nil end
      end

      eventManager.PersistentPlayerInfo.HasBeenShownCustomEventReminder = nil
    end
  )
)

-- *** Account Migrations ***
-- Released account settings have no independent version; nil starts at 0.
table.insert(MM.AccountMigrations,
  AutoBiographer_Migration:New(
    1,
    function(eventManager, controller)
      local settings = AutoBiographer_Settings
      AddMissing(settings, {
        EventDisplayFilters = {}, MapEventDisplayFilters = {}, Options = {},
        MapEventShowAnimation = false, MapEventShowCircle = true,
        MapEventFollowExpansions = false, MinimapPos = -25,
      })
      AddMissing(settings.Options, {
        EnableCustomEventSharing = true, EnableDebugLogging = false,
        EnableMilestoneMessages = true, RecommendCampfireMessages = true,
        ShareMilestonesAsEmotes = false, ShareMilestonesInGuild = false,
        ShowDiscoveryInfoOnToolTips = true, ShowFriendlyPlayerToolTips = true,
        ShowKillCountOnUnitToolTips = true, ShowMinimapButton = true,
        ShowLevelUpStatMessages = true, ShowTimePlayedOnLevelUp = true,
        TakeScreenshotOnAchievementEarned = false, TakeScreenshotOnBossKill = true,
        TakeScreenshotOnLevelUp = true, TakeScreenshotOnlyOnFirstBossKill = true,
      })
      settings.Options.ShowLowRankCombatSkillWarnings = nil
      for _, subType in pairs(AutoBiographerEnum.EventSubType) do
        if (settings.EventDisplayFilters[subType] == nil) then settings.EventDisplayFilters[subType] = true end
        if (settings.MapEventDisplayFilters[subType] == nil) then settings.MapEventDisplayFilters[subType] = true end
      end
      AddMissing(controller.AccountData.Notes, Notes.New())
    end,
    "Account"
  )
)
