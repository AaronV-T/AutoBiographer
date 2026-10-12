local Controller = AutoBiographer_Controller
local Api = AutoBiographer_Api
local EM = AutoBiographer_EventManager
AutoBiographer_SnapshotManager = { PendingPlayed = {}, Generation = 0 }
local manager = AutoBiographer_SnapshotManager

-- OnBossKill receives encounter IDs from BOSS_KILL, or creature IDs from
-- regular kills. Both identify the same first-clear snapshot for a raid.
local raidFinalBosses = {
  [672] = { Id = 409, Name = "Molten Core", EncounterId = 672 },
  [617] = { Id = 469, Name = "Blackwing Lair", EncounterId = 617 },
  [793] = { Id = 309, Name = "Zul'Gurub", EncounterId = 793 },
  [723] = { Id = 509, Name = "Ruins of Ahn'Qiraj", EncounterId = 723 },
  [717] = { Id = 531, Name = "Temple of Ahn'Qiraj", EncounterId = 717 },
  [1114] = { Id = 533, Name = "Naxxramas", EncounterId = 1114 },
}
for creatureId, encounterId in pairs({ [11502] = 672, [11583] = 617, [14834] = 793,
  [15339] = 723, [15727] = 717, [15990] = 1114 }) do
  raidFinalBosses[creatureId] = raidFinalBosses[encounterId]
end

local function IsReadable(value, expectedType)
  return not (issecretvalue and issecretvalue(value)) and type(value) == expectedType
end

local function NotifyPanel()
  if (AutoBiographer_SnapshotPanel and AutoBiographer_SnapshotPanel.QueueRefresh) then
    AutoBiographer_SnapshotPanel:QueueRefresh()
  end
end

local function VisitSnapshots(callback)
  if (not Controller.CharacterData.Snapshots) then return end
  local data = Controller:GetCharacterSnapshots()
  for _, collection in ipairs({ data.Levels, data.Raids }) do
    for _, snapshot in pairs(collection) do callback(snapshot) end
  end
end

function manager:CaptureDetails(snapshot, includeAttributes)
  local catalogs = Controller.CharacterData.Catalogs
  catalogs.SkillCatalog = catalogs.SkillCatalog or {}
  catalogs.TalentCatalog = catalogs.TalentCatalog or {}

  if (not snapshot.Equipment) then
    local equipment, enchants = Api.GetPlayerSnapshotEquipment()
    -- As with gear history, do not mistake a transient empty inventory for a
    -- real set of unequips. Retry after inventory data has become available.
    if (equipment) then
      local known = Controller.CharacterData.Gear and Controller.CharacterData.Gear.Snapshot or {}
      for slot, itemId in pairs(equipment) do
        if (itemId == 0 and (known[slot] or 0) > 0) then equipment = nil; break end
      end
    end
    if (equipment) then
      snapshot.Equipment, snapshot.Enchants = equipment, enchants
      snapshot.EquipmentCollectedAt = time()
    end
  end

  if (not snapshot.Talents) then
    local talents, unspent, failure = Api.GetPlayerSnapshotTalents(snapshot.Level)
    -- Diagnostic state stays in memory, never in the saved snapshot. Repeated
    -- retries with the same failure should not flood chat every second.
    self.TalentDiagnosticMessages = self.TalentDiagnosticMessages or {}
    if (talents) then
      snapshot.Talents, snapshot.UnspentTalentPoints = {}, unspent
      for _, talent in ipairs(talents) do
        catalogs.TalentCatalog[talent.Id] = { Name = talent.Name }
        snapshot.Talents[talent.Id] = talent.Rank
      end
      snapshot.TalentsCollectedAt = time()
      if (self.TalentDiagnosticMessages[snapshot]) then
        print("[AutoBiographer Talents] Level " .. snapshot.Level .. ": captured " .. #talents .. " selected talents after retry.")
        self.TalentDiagnosticMessages[snapshot] = nil
      end
    else
      failure = failure or "Talent reader returned no data without a failure reason."
      if (self.TalentDiagnosticMessages[snapshot] ~= failure) then
        self.TalentDiagnosticMessages[snapshot] = failure
        print("[AutoBiographer Talents] Level " .. snapshot.Level .. ", retry " .. (self.RetryAttempts or 0) .. ": " .. failure)
      end
    end
  end

  if (not snapshot.Skills) then
    local skills = Api.GetPlayerSnapshotSkills()
    if (skills) then
      snapshot.Skills = {}
      for _, skill in ipairs(skills) do
        local id = skill.Id
        if (not id or id <= 0) then
          -- Older APIs give names but no skill-line IDs. Intern each name once
          -- with a negative catalog ID, leaving positive IDs for actual APIs.
          local nextId = -1
          for catalogId, entry in pairs(catalogs.SkillCatalog) do
            if (entry.Name == skill.Name) then id = catalogId end
            if (catalogId <= nextId) then nextId = catalogId - 1 end
          end
          id = id or nextId
        end
        catalogs.SkillCatalog[id] = { Name = skill.Name }
        snapshot.Skills[id] = { Rank = skill.Rank, MaxRank = skill.MaxRank }
      end
      snapshot.SkillsCollectedAt = time()
    end
  end

  if (includeAttributes and not snapshot.Attributes) then
    local currentLevel = UnitLevel("player")
    if (IsReadable(currentLevel, "number") and currentLevel == snapshot.Level) then
      local stats = Api.GetPlayerSnapshotAttributes()
      if (stats) then
        snapshot.Attributes, snapshot.MaxHealth, snapshot.MaxMana = stats.Attributes, stats.MaxHealth, stats.MaxMana
        snapshot.StatsCollectedAt = time()
      end
    end
  end
  snapshot.Pending = not (snapshot.Equipment and snapshot.Talents and snapshot.Skills and snapshot.Attributes)
end

function manager:OnTimePlayed(totalTimePlayed)
  if (not IsReadable(totalTimePlayed, "number")) then return end
  local now = GetTime()
  self.LastPlayedAmount, self.LastPlayedAt = totalTimePlayed, now
  for snapshot, startedAt in pairs(self.PendingPlayed) do
    snapshot.TotalTimePlayed = math.max(0, totalTimePlayed - math.floor(now - startedAt))
  end
  self.PendingPlayed = {}
  NotifyPanel()
end

function manager:Pause()
  self.Active = false
  self.Generation = self.Generation + 1
  self.RetryQueued = false
end

function manager:Resume()
  self.Active = true
  self.RetryAttempts = 0
  self:ScheduleRetry()
end

function manager:RetryPending()
  if (not self.Active) then return end
  local level = UnitLevel("player")
  if (not IsReadable(level, "number")) then self:ScheduleRetry(); return end
  local pending = false
  VisitSnapshots(function(snapshot)
    if (snapshot.Pending) then
      if (level > snapshot.Level) then
        -- Never label a later level's stats/build as an earlier milestone.
        snapshot.Pending, snapshot.Incomplete = false, true
      elseif (level == snapshot.Level) then
        self:CaptureDetails(snapshot, true)
      end
      if (snapshot.Pending) then pending = true end
    end
  end)
  NotifyPanel()
  if (pending) then self:ScheduleRetry() end
end

function manager:ScheduleRetry()
  if (not self.Active or self.RetryQueued or (self.RetryAttempts or 0) >= 60) then return end
  self.RetryQueued = true
  local generation = self.Generation
  C_Timer.After(1, function()
    if (not self.Active or generation ~= self.Generation) then return end
    self.RetryQueued = false
    self.RetryAttempts = (self.RetryAttempts or 0) + 1
    self:RetryPending()
  end)
end

function manager:SnapshotLevel(level, totalTimePlayed)
  if (not IsReadable(level, "number")) then return end
  local snapshots = Controller:GetCharacterSnapshots()
  if (snapshots.Levels[level]) then return end
  snapshots.Levels[level] = self:StartSnapshot(level, totalTimePlayed)
  NotifyPanel()
end

function manager:SnapshotRaid(bossId)
  if (not self.Active or not IsReadable(bossId, "number")) then return end
  local success, name, instanceType, difficulty, _, _, _, _, instanceId = pcall(GetInstanceInfo)
  if (not success or not IsReadable(instanceType, "string") or instanceType ~= "raid") then return end
  local raid = raidFinalBosses[bossId]
  -- Onyxia's Lair has only one boss; its encounter ID varies by client.
  if (not raid and IsReadable(instanceId, "number") and instanceId == 249) then
    raid = { Id = 249, Name = "Onyxia's Lair" }
  end
  if (not raid) then return end
  local level = UnitLevel("player")
  if (not IsReadable(level, "number")) then return end
  local snapshots = Controller:GetCharacterSnapshots()
  if (snapshots.Raids[raid.Id]) then return end
  local catalogs = Controller.CharacterData.Catalogs
  catalogs.RaidCatalog = catalogs.RaidCatalog or {}
  catalogs.RaidCatalog[raid.Id] = { Name = IsReadable(name, "string") and name or raid.Name }
  local snapshot = self:StartSnapshot(level)
  -- Never store a creature ID in the encounter ID field.
  if (raid.EncounterId) then snapshot.EncounterId = raid.EncounterId
  elseif (bossId ~= 10184) then snapshot.EncounterId = bossId end
  if (IsReadable(difficulty, "number")) then snapshot.DifficultyId = difficulty end
  snapshots.Raids[raid.Id] = snapshot
  NotifyPanel()
end

function manager:StartSnapshot(level, totalTimePlayed)
  local snapshot = { Timestamp = time(), Level = level, Pending = true }
  -- Capture copper at the milestone, never backfill an older snapshot with
  -- the character's current balance when deferred sections are retried.
  if (GetMoney) then
    local success, money = pcall(GetMoney)
    if (success and IsReadable(money, "number")) then snapshot.Money = money end
  end
  -- Freeze gear, talents and skills immediately; only retry missing fields.
  -- Health/stats wait one second so level and maximum-resource updates arrive.
  -- Initial level 1 is created during ADDON_LOADED. Wait for world entry
  -- before reading its equipment, talents, skills and attributes.
  if (self.Active) then self:CaptureDetails(snapshot, false) end
  local now = GetTime()
  if (IsReadable(totalTimePlayed, "number")) then
    snapshot.TotalTimePlayed = totalTimePlayed
  else
    if (self.LastPlayedAmount) then
      snapshot.TotalTimePlayed = self.LastPlayedAmount + math.floor(now - self.LastPlayedAt)
    end
    self.PendingPlayed[snapshot] = now
  end
  self.RetryAttempts = 0
  self:ScheduleRetry()
  if (self.PendingPlayed[snapshot]) then
    local generation = self.Generation
    C_Timer.After(0.25, function()
      if (self.Active and generation == self.Generation and self.PendingPlayed[snapshot] and not EM.NewLevelToAddToHistory) then
        EM:RequestTimePlayed(false)
      end
    end)
  end
  return snapshot
end
