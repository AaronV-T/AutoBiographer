-- Thresholds and announcements live here; statistics remain the source of truth.
AutoBiographer_Milestones = { Started = false }
local Milestones = AutoBiographer_Milestones

-- Source of truth for milestone thresholds and sharing eligibility.
-- Missing MinorModulus/MajorStart means there are no milestones of that kind.
-- Time values are seconds, money is copper, and distance is yards.
-- CompanionTime, CreatureKillingBlows, ItemAcquired, ItemCrafted and SpellTime
-- apply separately to each family, creature, item or aura.
Milestones.Configuration = {
  MajorMultiplier = 10,
  MinorModuliByLevel = {
    DamageOrHealing = {
      { MaxLevel = 29, Modulus = 100000 },
      { MaxLevel = 59, Modulus = 1000000 },
      { MaxLevel = 69, Modulus = 5000000 },
      { MaxLevel = 79, Modulus = 10000000 },
      { Modulus = 20000000 }, -- All remaining levels.
    },
  },
  Types = {
    BuffsGiven         = { MinorModulus = 1000,  MajorStart = 1000,    Shareable = true },
    Camped             = { MinorModulus = 100,  MajorStart = 100,     Shareable = true },
    CompanionTime      = { MinorModulus = 86400,  MajorStart = 86400,   Shareable = true }, -- This is per companion family.
    CreatureKillingBlows = { MinorModulus = 100, MajorStart = 1000,     Shareable = true }, -- This is per creature.
    CreatureTypesKilled = { MinorModulus = 100, MajorStart = 100,     Shareable = true },
    DamageDealt        = { MinorModuliByLevel = "DamageOrHealing", MajorStart = 100000, Shareable = true },
    Deaths             = { MinorModulus = 100,  MajorStart = 100,     Shareable = false },
    Distance           = { MinorModulus = 100000,  MajorStart = 1000000,  Shareable = true },
    DistanceMounted    = { MinorModulus = 100000,  MajorStart = 1000000,  Shareable = true },
    DistanceOnFoot     = { MinorModulus = 100000,  MajorStart = 1000000,  Shareable = true },
    DistanceSwimming   = { MinorModulus = 100000,  MajorStart = 1000000,  Shareable = true },
    DrowningDeaths     = { MinorModulus = 10,  MajorStart = 10,      Shareable = false },
    DuelsWon           = { MinorModulus = 10,  MajorStart = 10,      Shareable = true },
    Experience         = { MinorModulus = 1000000,  MajorStart = 1000000, Shareable = true },
    FallingDeaths      = { MinorModulus = 10,  MajorStart = 10,      Shareable = false },
    FishingCasts       = { MinorModulus = 1000, MajorStart = 1000,    Shareable = true },
    FishingCatches     = { MinorModulus = 1000, MajorStart = 1000,    Shareable = true },
    HealingDealt       = { MinorModuliByLevel = "DamageOrHealing", MajorStart = 100000, Shareable = true },
    ItemAcquired       = { MinorModulus = 1000, MajorStart = 1000,    Shareable = true }, -- This is per item.
    ItemCrafted        = { MinorModulus = 1000,  MajorStart = 1000,     Shareable = true }, -- This is per item.
    ItemsCrafted       = { MinorModulus = 1000,  MajorStart = 1000,    Shareable = true },
    Jumps              = { MinorModulus = 1000, MajorStart = 10000,   Shareable = true },
    Kills              = { MinorModulus = 1000, MajorStart = 1000,    Shareable = true },
    Messages           = { MinorModulus = 1000,  MajorStart = 1000,   Shareable = false },
    MoneyGained        = { MinorModulus = 1000000,  MajorStart = 1000000, Shareable = true },
    Quests             = { MinorModulus = 100,  MajorStart = 100,     Shareable = true },
    Shapeshifts        = { MinorModulus = 1000,  MajorStart = 1000,    Shareable = true },
    SpellsCast         = { MinorModulus = 10000,  MajorStart = 10000,   Shareable = true },
    SpellTime          = { MinorModulus = 86400,  MajorStart = 86400,   Shareable = true }, -- This is per spell.
    TimeAquaticForm    = { MinorModulus = 86400,  MajorStart = 86400,   Shareable = true },
    TimeBattleStance   = { MinorModulus = 86400,  MajorStart = 86400,   Shareable = true },
    TimeBearForm       = { MinorModulus = 86400,  MajorStart = 86400,   Shareable = true },
    TimeBerserkerStance = { MinorModulus = 86400, MajorStart = 86400,   Shareable = true },
    TimeCasting        = { MinorModulus = 86400,  MajorStart = 86400,   Shareable = true },
    TimeCatForm        = { MinorModulus = 86400,  MajorStart = 86400,   Shareable = true },
    TimeCombat         = { MinorModulus = 86400,  MajorStart = 86400,   Shareable = true },
    TimeDefensiveStance = { MinorModulus = 86400, MajorStart = 86400,   Shareable = true },
    TimeFeignDeath     = { MinorModulus = 86400,  MajorStart = 86400,   Shareable = true },
    TimeFishing        = { MinorModulus = 86400,  MajorStart = 86400,   Shareable = true },
    TimeGhostWolf      = { MinorModulus = 86400,  MajorStart = 86400,   Shareable = true },
    TimeGrouped        = { MinorModulus = 86400,  MajorStart = 86400,   Shareable = false },
    TimeMindControl    = { MinorModulus = 86400,  MajorStart = 86400,   Shareable = true },
    TimeMoonkinForm    = { MinorModulus = 86400,  MajorStart = 86400,   Shareable = true },
    TimePlayed         = { MinorModulus = 86400,  MajorStart = 86400,   Shareable = false },
    TimeShadowform     = { MinorModulus = 86400,  MajorStart = 86400,   Shareable = true },
    TimeStealthed      = { MinorModulus = 86400,  MajorStart = 86400,   Shareable = true },
    TimeTravelForm     = { MinorModulus = 86400,  MajorStart = 86400,   Shareable = true },
    UniqueItemsAcquired = { MinorModulus = 100, MajorStart = 1000,     Shareable = true },
    UniqueItemsCrafted  = { MinorModulus = 25,  MajorStart = 100,     Shareable = true },
    UniqueItemsEquipped = { MinorModulus = 25,  MajorStart = 100,     Shareable = true },
    UniquePlayersBuffed = { MinorModulus = 100, MajorStart = 100,     Shareable = true },
  },
}

local function Count(value)
  return HelperFunctions.CommaValue(value)
end

local function GetMinorModulus(rule)
  if (not rule.MinorModuliByLevel) then return rule.MinorModulus end
  local level = AutoBiographer_Controller:GetCurrentLevelNum()
  for _, tier in ipairs(Milestones.Configuration.MinorModuliByLevel[rule.MinorModuliByLevel]) do
    if (not tier.MaxLevel or level <= tier.MaxLevel) then return tier.Modulus end
  end
end

local function Sum(values)
  local total = 0
  for _, value in pairs(values) do total = total + value end
  return total
end

function Milestones:AddDefinition(key, group, phrase, getTotal, ruleKey)
  self.Definitions[key] = {
    Group = group, Phrase = phrase, GetTotal = getTotal,
    Rule = assert(self.Configuration.Types[ruleKey or key], "Missing milestone configuration: " .. (ruleKey or key)),
  }
  self.Totals[key] = getTotal()
end

function Milestones:AddTimedDefinition(key, group, label, getTotal, ruleKey)
  self:AddDefinition(key, group, function(amount)
    return "spent " .. Count(amount / 3600) .. " hours " .. label
  end, getTotal, ruleKey)
end

function Milestones:Check(key)
  local definition = self.Definitions[key]
  local previous, total = self.Totals[key], definition.GetTotal()
  self.Totals[key] = total
  if (total <= previous) then return end

  -- Record each crossed major threshold, but announce only the highest one.
  local rule = definition.Rule
  local major, threshold = nil, rule.MajorStart
  while (threshold and threshold <= total) do
    if (threshold > previous) then
      major = threshold
      AutoBiographer_Controller:AddEvent(StatisticMilestoneEvent.New(time(), HelperFunctions.GetCoordinatesByUnitId("player"),
        key, threshold, definition.Phrase(threshold)))
    end
    threshold = threshold * self.Configuration.MajorMultiplier
  end
  local minor
  threshold = GetMinorModulus(rule)
  if (threshold) then
    if (math.floor(total / threshold) > math.floor(previous / threshold)) then
      minor = math.floor(total / threshold) * threshold
    end
  end

  local options = AutoBiographer_Settings.Options
  if (options.EnableMilestoneMessages and (major or minor)) then
    local amount = math.max(major or 0, minor or 0)
    print("\124cFFFFD700[AutoBiographer] You have " .. definition.Phrase(amount) .. "!\124r")
  end
  if (major and rule.Shareable) then
    if (options.ShareMilestonesInGuild or options.ShareMilestonesAsEmotes or not options.MilestoneSharingPrompted) then
      self.SharingQueue[key] = { Phrase = definition.Phrase(major) }
    end
  end
end

function Milestones:CreateDefinitions()
  local controller, enum = AutoBiographer_Controller, AutoBiographerEnum
  local function MaxLevel() return controller:GetCurrentLevelNum() end
  local function Add(key, group, template, getter)
    self:AddDefinition(key, group, function(amount) return string.format(template, Count(amount)) end, getter)
  end
  Add("BuffsGiven", "Buffs", "given %s buffs to other players", function()
    return controller:GetOtherPlayerStatByOtherPlayerTrackingType(enum.OtherPlayerTrackingType.BuffsGivenToPlayerNotGrouped, 1, MaxLevel()) +
      controller:GetOtherPlayerStatByOtherPlayerTrackingType(enum.OtherPlayerTrackingType.BuffsGivenToPlayerWhileGrouped, 1, MaxLevel())
  end)
  Add("Camped", "Camped", "camped %s times", function()
    return controller:GetMiscellaneousStatByMiscellaneousTrackingType(enum.MiscellaneousTrackingType.Camped, 1, MaxLevel())
  end)
  Add("CreatureTypesKilled", "Kills", "defeated %s different creature types", function()
    local count = 0
    for _, unit in pairs(controller.CharacterData.Catalogs.UnitCatalog) do
      if (unit.Killed and unit.UType == enum.UnitType.Creature) then count = count + 1 end
    end
    return count
  end)
  Add("DamageDealt", "Damage", "dealt %s damage", function()
    return controller:GetDamageOrHealing(enum.DamageOrHealingCategory.DamageDealt, 1, MaxLevel())
  end)
  Add("Deaths", "Deaths", "died %s times", function()
    local total = 0
    for _, deathType in pairs(enum.DeathTrackingType) do
      total = total + controller:GetDeathsByDeathTrackingType(deathType, 1, MaxLevel())
    end
    return total
  end)
  Add("Distance", "Distance", "travelled %s yards", function()
    local total = 0
    for _, distanceType in pairs(enum.DistanceTrackingType) do
      total = total + controller:GetDistanceByDistanceTrackingType(distanceType, 1, MaxLevel())
    end
    return total
  end)
  Add("DistanceMounted", "Distance", "travelled %s yards on a mount", function()
    return controller:GetDistanceByDistanceTrackingType(enum.DistanceTrackingType.Mounted, 1, MaxLevel())
  end)
  Add("DistanceOnFoot", "Distance", "travelled %s yards on foot", function()
    return controller:GetDistanceByDistanceTrackingType(enum.DistanceTrackingType.OnFoot, 1, MaxLevel())
  end)
  Add("DistanceSwimming", "Distance", "swum %s yards", function()
    return controller:GetDistanceByDistanceTrackingType(enum.DistanceTrackingType.Swimming, 1, MaxLevel())
  end)
  Add("DrowningDeaths", "Deaths", "died to drowning %s times", function()
    return controller:GetDeathsByDeathTrackingType(enum.DeathTrackingType.DeathToDrowning, 1, MaxLevel())
  end)
  Add("DuelsWon", "Duels", "won %s duels", function()
    return controller:GetOtherPlayerStatByOtherPlayerTrackingType(enum.OtherPlayerTrackingType.DuelsLostToPlayer, 1, MaxLevel())
  end)
  Add("Experience", "Experience", "earned %s experience", function()
    -- Kill XP already includes rested/group bonuses and raid penalties.
    return controller:GetExperienceByExperienceTrackingType(enum.ExperienceTrackingType.Kill, 1, MaxLevel()) +
      controller:GetExperienceByExperienceTrackingType(enum.ExperienceTrackingType.Quest, 1, MaxLevel()) +
      controller:GetExperienceByExperienceTrackingType(enum.ExperienceTrackingType.Discovery, 1, MaxLevel())
  end)
  Add("FallingDeaths", "Deaths", "died to falling %s times", function()
    return controller:GetDeathsByDeathTrackingType(enum.DeathTrackingType.DeathToFalling, 1, MaxLevel())
  end)
  Add("FishingCasts", "Fishing", "cast a fishing line %s times", function()
    return controller:GetMiscellaneousStatByMiscellaneousTrackingType(enum.MiscellaneousTrackingType.FishingCasts, 1, MaxLevel())
  end)
  Add("FishingCatches", "Fishing", "completed %s successful fishing attempts", function()
    return controller:GetMiscellaneousStatByMiscellaneousTrackingType(enum.MiscellaneousTrackingType.FishingCatches, 1, MaxLevel())
  end)
  Add("HealingDealt", "Damage", "done %s healing", function()
    return controller:GetDamageOrHealing(enum.DamageOrHealingCategory.HealingDealt, 1, MaxLevel())
  end)
  Add("ItemsCrafted", "Items", "crafted %s items", function()
    return controller:GetItemCountForAcquisitionMethod(enum.ItemAcquisitionMethod.Create, 1, MaxLevel())
  end)
  Add("Jumps", "Jumps", "jumped %s times", function()
    return controller:GetMiscellaneousStatByMiscellaneousTrackingType(enum.MiscellaneousTrackingType.Jumps, 1, MaxLevel())
  end)
  Add("Kills", "Kills", "%s tagged kills", function()
    return KillStatistics.GetSum(controller:GetAggregatedKillStatisticsTotals(1, MaxLevel()), {
      enum.KillTrackingType.TaggedAssist, enum.KillTrackingType.TaggedGroupAssistOrKillingBlow, enum.KillTrackingType.TaggedKillingBlow,
    })
  end)
  Add("Messages", "Messages", "sent %s messages", function()
    return Sum(controller:GetAggregatedMessageStatistics(1, MaxLevel()))
  end)
  self:AddDefinition("MoneyGained", "Money", function(amount)
    return "gained " .. Count(amount / 10000) .. " gold"
  end, function() return controller:GetTotalMoneyGained(1, MaxLevel()) end)
  Add("Quests", "Quests", "completed %s quests", function()
    local dictionary = controller:GetAggregatedQuestStatisticsDictionary(1, MaxLevel())
    return QuestStatistics.GetSum(controller:GetAggregatedQuestStatisticsTotals(1, MaxLevel(), dictionary), { enum.QuestTrackingType.Completed })
  end)
  Add("Shapeshifts", "Spells", "changed druid forms %s times", function()
    local names = {}
    for _, spellId in ipairs({ 768, 5487, 9634, 1066, 783, 24858 }) do
      local name = AutoBiographer_Api.GetSpellInfo(spellId)
      if (not (issecretvalue and issecretvalue(name)) and name) then names[name] = true end
    end
    local total = 0
    for spellId, statistics in pairs(controller:GetAggregatedSpellStatisticsDictionary(1, MaxLevel())) do
      local spell = controller.CharacterData.Catalogs.SpellCatalog[spellId]
      if (spell and names[spell.Name]) then total = total + (statistics[enum.SpellTrackingType.SuccessfullyCast] or 0) end
    end
    return total
  end)
  Add("SpellsCast", "Spells", "successfully cast %s spells", function()
    return controller:GetSpellCountBySpellTrackingType(enum.SpellTrackingType.SuccessfullyCast, 1, MaxLevel())
  end)
  Add("UniqueItemsAcquired", "Items", "acquired %s different items", function()
    local count = 0
    for _, item in pairs(controller.CharacterData.Catalogs.ItemCatalog) do
      if (item.Acquired) then count = count + 1 end
    end
    return count
  end)
  Add("UniqueItemsCrafted", "Items", "crafted %s different items", function()
    local count = 0
    for _, statistics in pairs(controller:GetAggregatedItemStatisticsDictionary(1, MaxLevel())) do
      if ((statistics[enum.ItemAcquisitionMethod.Create] or 0) > 0) then count = count + 1 end
    end
    return count
  end)
  Add("UniqueItemsEquipped", "Equipment", "equipped %s different items", function()
    local count = 0
    for _, item in pairs(controller.CharacterData.Catalogs.ItemCatalog) do
      if (item.Equipped) then count = count + 1 end
    end
    return count
  end)
  Add("UniquePlayersBuffed", "Buffs", "buffed %s different players outside your group", function()
    return controller:GetUniqueOtherPlayerCountByOtherPlayerTrackingType(enum.OtherPlayerTrackingType.BuffsGivenToPlayerNotGrouped, 1, MaxLevel())
  end)

  self:AddTimedDefinition("TimeCasting", "Time", "casting", function()
    return controller:GetTimeForTimeTrackingType(enum.TimeTrackingType.Casting, 1, MaxLevel())
  end)
  self:AddTimedDefinition("TimeCombat", "Time", "in combat", function()
    return controller:GetTimeForTimeTrackingType(enum.TimeTrackingType.InCombat, 1, MaxLevel())
  end)
  self:AddTimedDefinition("TimeFishing", "Time", "fishing", function()
    return controller:GetTimeForTimeTrackingType(enum.TimeTrackingType.Fishing, 1, MaxLevel())
  end)
  self:AddTimedDefinition("TimeGrouped", "Time", "in a group", function()
    return controller:GetTimeForTimeTrackingType(enum.TimeTrackingType.InParty, 1, MaxLevel())
  end)
  self:AddTimedDefinition("TimePlayed", "Time", "logged in", function()
    return controller:GetTimeForTimeTrackingType(enum.TimeTrackingType.LoggedIn, 1, MaxLevel())
  end)
  for _, state in ipairs(AutoBiographer_ClassActivity.StateDefinitions) do
    local key, label = state[1], state[2]
    self:AddTimedDefinition("Time" .. key, "Time", "in " .. label, function()
      return controller:GetTimeForTimeTrackingType(enum.TimeTrackingType[key], 1, MaxLevel())
    end)
  end
end

function Milestones:FinishEmote(key, share)
  if (InCombatLockdown()) then return end
  local entry = self.SharingQueue[key]
  if (entry and not entry.EmoteHandled) then
    if (share) then
      AutoBiographer_Api.SendMilestoneMessage("has " .. entry.Phrase:gsub("your group", "their group") .. "!", "EMOTE")
    end
    entry.EmoteHandled = true
  end
  self:PauseSharing()
  self:ResumeSharing()
end

function Milestones:Flush()
  self.CheckPending = false
  local dirty = self.Dirty
  self.Dirty = {}
  local keys = {}
  for key, definition in pairs(self.Definitions) do
    if (dirty[definition.Group]) then keys[#keys + 1] = key end
  end
  table.sort(keys)
  for _, key in ipairs(keys) do self:Check(key) end
  self:ResumeSharing()
end

function Milestones:OnAcquiredItem(itemId, acquisitionMethod, quantity)
  if (not self.Started) then return end
  local controller, enum = AutoBiographer_Controller, AutoBiographerEnum
  for _, ruleKey in ipairs({ "ItemAcquired", "ItemCrafted" }) do
    local crafted = ruleKey == "ItemCrafted"
    if (not crafted or acquisitionMethod == enum.ItemAcquisitionMethod.Create) then
      local key = ruleKey .. itemId
      if (not self.Definitions[key]) then
        self:AddDefinition(key, key, function(amount)
          local item = controller.CharacterData.Catalogs.ItemCatalog[itemId]
          return (crafted and "crafted " or "acquired ") .. Count(amount) .. " of " .. (item and item.Name or "item #" .. itemId)
        end, function()
          local total = 0
          for _, level in pairs(controller.CharacterData.Levels) do
            local statistics = level.ItemStatisticsByItem[itemId]
            if (statistics) then
              total = total + (crafted and (statistics[enum.ItemAcquisitionMethod.Create] or 0) or
                ItemStatistics.GetSum(statistics, enum.ItemAcquisitionMethod))
            end
          end
          return total
        end, ruleKey)
        -- Register lazily after this acquisition, but baseline before its delta.
        -- Older totals won't replay announcements after a login or reload.
        self.Totals[key] = self.Totals[key] - quantity
      end
      -- Only recheck the changed item, not every item encountered this session.
      self:OnStatChanged(key)
    end
  end
end

function Milestones:OnCompanionFamilyTime(familyId, familyName, seconds)
  if (not self.Started) then return end
  local key = "CompanionTime" .. familyId
  if (not self.Definitions[key]) then
    self:AddTimedDefinition(key, "CompanionTime", "with " .. (familyName or "companion family #" .. familyId), function()
      return AutoBiographer_Controller:GetAggregatedCompanionFamilyTime(1, AutoBiographer_Controller:GetCurrentLevelNum())[familyId] or 0
    end, "CompanionTime")
    self.Totals[key] = self.Totals[key] - seconds
  end
  self:OnStatChanged("CompanionTime")
end

function Milestones:OnKill(kill)
  if (not self.Started or not kill.PlayerGotKillingBlow or
      HelperFunctions.GetUnitTypeFromCatalogUnitId(kill.CatalogUnitId) ~= AutoBiographerEnum.UnitType.Creature) then return end
  local controller, enum = AutoBiographer_Controller, AutoBiographerEnum
  local unitId = kill.CatalogUnitId
  local key = "CreatureKillingBlows" .. unitId
  if (not self.Definitions[key]) then
    self:AddDefinition(key, key, function(amount)
      local unit = controller.CharacterData.Catalogs.UnitCatalog[unitId]
      return "landed " .. Count(amount) .. " killing blows against " .. (unit and unit.Name or "creature #" .. unitId)
    end, function()
      return KillStatistics.GetSum(controller:GetAggregatedKillStatisticsByCatalogUnitId(unitId, 1, controller:GetCurrentLevelNum()), {
        enum.KillTrackingType.TaggedKillingBlow, enum.KillTrackingType.UntaggedKillingBlow,
      })
    end, "CreatureKillingBlows")
    self.Totals[key] = self.Totals[key] - 1
  end
  self:OnStatChanged(key)
end

function Milestones:OnSpellTime(spellId, seconds)
  if (not self.Started) then return end
  -- Aggregate aura ranks by name, without saving another counter or catalog.
  local catalog = AutoBiographer_Controller.CharacterData.Catalogs.SpellCatalog
  local spell = catalog[spellId]
  if (not spell or not spell.Name) then return end
  local name, key = spell.Name, "SpellTime" .. spell.Name
  if (not self.Definitions[key]) then
    self:AddTimedDefinition(key, "SpellTime", "with " .. name, function()
      local total = 0
      for id, duration in pairs(AutoBiographer_Controller:GetAggregatedSpellTime(1, AutoBiographer_Controller:GetCurrentLevelNum())) do
        if (catalog[id] and catalog[id].Name == name) then total = total + duration end
      end
      return total
    end, "SpellTime")
    self.Totals[key] = self.Totals[key] - seconds
  end
  self:OnStatChanged("SpellTime")
end

function Milestones:OnStatChanged(group)
  if (not self.Started) then return end
  self.Dirty[group] = true
  if (self.CheckPending) then return end
  self.CheckPending = true
  -- Coalesce ability-by-ability damage meter updates and frequent time samples.
  C_Timer.After(1, function() self:Flush() end)
end

function Milestones:PauseSharing()
  if (self.Prompt) then self.Prompt:Hide() end
end

function Milestones:ResumeSharing()
  if (not self.Started or InCombatLockdown()) then return end
  if (not next(self.SharingQueue)) then self:PauseSharing(); return end
  local options = AutoBiographer_Settings.Options
  if (not options.MilestoneSharingPrompted) then
    self:ShowSharingPrompt(true)
    return
  end
  if (not options.ShareMilestonesInGuild and not options.ShareMilestonesAsEmotes) then
    self.SharingQueue = {}
    self:PauseSharing()
    return
  end
  local inGuild = IsInGuild()
  for key, entry in pairs(self.SharingQueue) do
    -- Each channel consumes its own part of the entry. Neither one cancels
    -- the other, including when the player skips an emote or is unguilded.
    if (not options.ShareMilestonesInGuild or not inGuild) then entry.GuildHandled = true end
    if (not options.ShareMilestonesAsEmotes) then entry.EmoteHandled = true end
    if (not entry.GuildHandled and not self.SharingPending) then
      local delay = math.max(0, 10 - (GetTime() - (self.LastSharedAt or -10)))
      if (delay > 0) then
        self.SharingPending = true
        C_Timer.After(delay, function() self.SharingPending = false; self:ResumeSharing() end)
      else
        entry.GuildHandled = true
        if (AutoBiographer_Api.SendMilestoneMessage("[AutoBiographer] I have " .. entry.Phrase:gsub("your group", "my group") .. "!", "GUILD")) then
          self.LastSharedAt = GetTime()
        end
      end
    end
    if (entry.GuildHandled and entry.EmoteHandled) then self.SharingQueue[key] = nil end
  end
  if (options.ShareMilestonesAsEmotes) then
    -- Guild delivery does not remove the click-to-send emote offer.
    self:ShowSharingPrompt(false)
  else
    self:PauseSharing()
  end
end

function Milestones:SetSharingOptions(guild, emote)
  local options = AutoBiographer_Settings.Options
  options.MilestoneSharingPrompted = true
  options.ShareMilestonesInGuild = not not guild
  options.ShareMilestonesAsEmotes = not not emote
  local window = AutoBiographer_OptionWindow
  if (window and window.cbShareMilestonesInGuild) then
    window.cbShareMilestonesInGuild:SetChecked(options.ShareMilestonesInGuild)
    window.cbShareMilestonesAsEmotes:SetChecked(options.ShareMilestonesAsEmotes)
  end
  self:PauseSharing()
  self:ResumeSharing()
end

function Milestones:ShowSharingPrompt(firstTime)
  if (not self.Prompt) then
    local window = CreateFrame("Frame", "AutoBiographerMilestoneSharing", UIParent, "BasicFrameTemplate")
    self.Prompt = window
    window:SetPoint("TOP", UIParent, "TOP", 0, -4)
    window:SetFrameStrata("DIALOG")
    window:Hide()
    window.TitleText:SetText("AutoBiographer milestones")
    window.Message = window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    window.Message:SetPoint("TOPLEFT", 12, -32)
    window.Message:SetWidth(296)
    window.Message:SetJustifyH("LEFT")
    window.Guild = CreateFrame("CheckButton", nil, window, "UICheckButtonTemplate")
    window.Guild:SetPoint("TOPLEFT", 12, -91)
    window.GuildLabel = window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    window.GuildLabel:SetPoint("LEFT", window.Guild, "RIGHT", 2, 0)
    window.GuildLabel:SetText("Automatically share in guild chat")
    window.Emote = CreateFrame("CheckButton", nil, window, "UICheckButtonTemplate")
    window.Emote:SetPoint("TOPLEFT", 12, -117)
    window.EmoteLabel = window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    window.EmoteLabel:SetPoint("LEFT", window.Emote, "RIGHT", 2, 0)
    window.EmoteLabel:SetText("Offer emotes (click to send)")
    window.Buttons = {}
    for index = 1, 2 do
      local button = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
      button:SetSize(142, 24)
      button:SetPoint("BOTTOMLEFT", 12 + (index - 1) * 154, 12)
      button:SetScript("OnClick", function()
        if (window.FirstTime) then
          self:SetSharingOptions(index == 1 and window.Guild:GetChecked(), index == 1 and window.Emote:GetChecked())
        else
          self:FinishEmote(window.MilestoneKey, index == 1)
        end
      end)
      window.Buttons[index] = button
    end
    window.CloseButton:SetScript("OnClick", function()
      if (window.FirstTime) then self:SetSharingOptions(false, false)
      else
        for _, entry in pairs(self.SharingQueue) do entry.EmoteHandled = true end
        self:PauseSharing()
        self:ResumeSharing()
      end
    end)
  end
  local window = self.Prompt
  local key = window.MilestoneKey
  local entry = key and self.SharingQueue[key]
  if (not entry or (not firstTime and entry.EmoteHandled)) then
    key = nil
    for candidate, queued in pairs(self.SharingQueue) do
      if (firstTime or not queued.EmoteHandled) then key, entry = candidate, queued; break end
    end
  end
  if (not key) then window:Hide(); return end
  -- Rechecking stats must not reset choices the player is editing.
  local initializeChoices = firstTime and (not window:IsShown() or not window.FirstTime)
  window.FirstTime = firstTime
  window.MilestoneKey = key
  window:SetSize(320, firstTime and 190 or 140)
  window.Message:SetText("You have " .. entry.Phrase .. "!\n" .. (firstTime and
    "Choose either or both sharing options." or "Share this milestone as an emote?"))
  window.Guild:SetShown(firstTime)
  window.GuildLabel:SetShown(firstTime)
  window.Emote:SetShown(firstTime)
  window.EmoteLabel:SetShown(firstTime)
  if (initializeChoices) then
    window.Guild:SetChecked(true)
    window.Emote:SetChecked(true)
  end
  window.Buttons[1]:SetText(firstTime and "Save" or "Share")
  window.Buttons[2]:SetText(firstTime and "Keep private" or "Skip")
  window:Show()
end

function Milestones:Start()
  self.Definitions, self.Totals, self.Dirty, self.SharingQueue = {}, {}, {}, {}
  self.CheckPending, self.SharingPending = false, false
  self:CreateDefinitions()
  self.Started = true
end
