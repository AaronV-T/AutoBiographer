-- *** AggregatedStatistics ***

AggregatedStatistics = {}
function AggregatedStatistics.New()
  return {
    ArenaStatistics = ArenaStatistics.New(),
    BattlegroundStatistics = BattlegroundStatistics.New(),
    DamageStatistics = DamageStatistics.New(),
    DeathStatistics = DeathStatistics.New(),
    ExperienceStatistics = ExperienceStatistics.New(),
    GatheringStatistics = nil,
    ItemStatisticsByItem = {}, -- Dict<CatalogItemId, ItemStatistics>
    KillStatisticsByUnit = {}, -- Dict<CatalogUnitId, KillStatistics>
    MiscellaneousStatistics = MiscellaneousStatistics.New(),
    MoneyStatistics = MoneyStatistics.New(),
    OtherPlayerStatisticsByOtherPlayer = {}, -- Dict<CatalogUnitId, PlayerStatistics>
    PvpStatistics = nil,
    QuestStatisticsByQuest = {}, -- Dict<QuestId, QuestStatistics>
    SpellStatisticsBySpell = {}, -- Dict<CatalogSpellId, SpellStatistics>
    TimeStatisticsByArea = {}, -- Dict<ZoneName-SubZoneName, TimeStatistics>
  }
end

-- *** ArenaStatistics ***

ArenaStatistics = {}
function ArenaStatistics.New()
  return {}
end

function ArenaStatistics.EnsureCreated(as, registered, teamSize)
  local subObject
  if (registered) then
    if (as.Registered == nil) then as.Registered = {} end
    subObject = as.Registered
  else
    if (as.Unregistered == nil) then as.Unregistered = {} end
    subObject = as.Unregistered
  end

  if (subObject[teamSize] == nil) then
    subObject[teamSize] = {
      joined = 0,
      losses = 0,
      wins = 0
    }
  end
end
  
function ArenaStatistics.IncrementJoined(as, registered, teamSize)
  ArenaStatistics.EnsureCreated(as, registered, teamSize)

  if (registered) then as.Registered[teamSize].joined = as.Registered[teamSize].joined + 1
  else as.Unregistered[teamSize].joined = as.Unregistered[teamSize].joined + 1
  end
end

function ArenaStatistics.IncrementLosses(as, registered, teamSize)
  ArenaStatistics.EnsureCreated(as, registered, teamSize)

  if (registered) then as.Registered[teamSize].losses = as.Registered[teamSize].losses + 1
  else as.Unregistered[teamSize].losses = as.Unregistered[teamSize].losses + 1
  end
end

function ArenaStatistics.IncrementWins(as, registered, teamSize)
  ArenaStatistics.EnsureCreated(as, registered, teamSize)

  if (registered) then as.Registered[teamSize].wins = as.Registered[teamSize].wins + 1
  else as.Unregistered[teamSize].wins = as.Unregistered[teamSize].wins + 1
  end
end

-- *** BattlegroundStatistics ***

BattlegroundStatistics = {}
function BattlegroundStatistics.New()
  return {}
end

function BattlegroundStatistics.EnsureCreated(bs, battlegroundId)
  if (bs[battlegroundId] == nil) then
    bs[battlegroundId] = {
      joined = 0,
      losses = 0,
      wins = 0
    }
  end
end
  
function BattlegroundStatistics.IncrementJoined(bs, battlegroundId)
  BattlegroundStatistics.EnsureCreated(bs, battlegroundId)
  bs[battlegroundId].joined = bs[battlegroundId].joined + 1
end

function BattlegroundStatistics.IncrementLosses(bs, battlegroundId)
  BattlegroundStatistics.EnsureCreated(bs, battlegroundId)
  bs[battlegroundId].losses = bs[battlegroundId].losses + 1
end

function BattlegroundStatistics.IncrementWins(bs, battlegroundId)
  BattlegroundStatistics.EnsureCreated(bs, battlegroundId)
  bs[battlegroundId].wins = bs[battlegroundId].wins + 1
end

-- *** DamageStatistics ***

DamageStatistics = {}
function DamageStatistics.New()
  return {}
end

function DamageStatistics.Add(ds, damageOrHealingCategory, amount, over)
  if (ds[damageOrHealingCategory] == nil) then ds[damageOrHealingCategory] = DamageBreakdown.New() end
  
  DamageBreakdown.Add(ds[damageOrHealingCategory], amount, over)
end

-- *** DeathStatistics ***

DeathStatistics = {}
function DeathStatistics.New()
  return {}
end

function DeathStatistics.Increment(ds, deathTrackingType)
  if (ds[deathTrackingType] == nil) then ds[deathTrackingType] = 0 end
  
  ds[deathTrackingType] = ds[deathTrackingType] + 1
end

-- *** ExperienceStatistics ***

ExperienceStatistics = {}
function ExperienceStatistics.New()
  return {}
end

function ExperienceStatistics.AddExperience(es, experienceTrackingType, amount)
  if (es[experienceTrackingType] == nil) then es[experienceTrackingType] = 0 end
  
  es[experienceTrackingType] = es[experienceTrackingType] + amount
end

-- *** ItemStatistics ***

ItemStatistics = {}
function ItemStatistics.New()
  return {}
end

function ItemStatistics.AddCount(is, itemAcquisitionMethod, quantity)
  if (not is[itemAcquisitionMethod]) then is[itemAcquisitionMethod] = 0 end
  
  is[itemAcquisitionMethod] = is[itemAcquisitionMethod] + quantity
end

function ItemStatistics.GetSum(is, itemAcquisitionMethods)
  local sum = 0
  for k, itemAcquisitionMethod in pairs(itemAcquisitionMethods) do
    if (is[itemAcquisitionMethod]) then
      sum = sum + is[itemAcquisitionMethod]
    end
  end

  return sum
end

-- *** KillStatistics ***

KillStatistics = {}
function KillStatistics.New()
  return {}
end

function KillStatistics.AddKill(ks, kill)
  local killTrackingType
  if (kill.PlayerHasTag) then
    if (kill.PlayerGotKillingBlow) then
      killTrackingType = AutoBiographerEnum.KillTrackingType.TaggedKillingBlow
    elseif (kill.PlayerGotAssist) then
      killTrackingType = AutoBiographerEnum.KillTrackingType.TaggedAssist
    else
      killTrackingType = AutoBiographerEnum.KillTrackingType.TaggedGroupAssistOrKillingBlow
    end
  else
    if (kill.PlayerGotKillingBlow) then
      killTrackingType = AutoBiographerEnum.KillTrackingType.UntaggedKillingBlow
    elseif (kill.PlayerGotAssist) then
      killTrackingType = AutoBiographerEnum.KillTrackingType.UntaggedAssist
    else
      killTrackingType = AutoBiographerEnum.KillTrackingType.UntaggedGroupAssistOrKillingBlow
    end
  end

  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then AutoBiographer_Controller:AddLog("killTrackingType: " .. tostring(killTrackingType) .. ".", AutoBiographerEnum.LogLevel.Debug) end

  if (not killTrackingType) then
    local messsage = "Kill statistic not recorded; failed to find killTrackingType."
    if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then print("[AutoBiographer] " .. messsage) end
    AutoBiographer_Controller:AddLog(messsage, AutoBiographerEnum.LogLevel.Warning)
  end

  if (ks[killTrackingType] == nil) then ks[killTrackingType] = 0 end
  ks[killTrackingType] = ks[killTrackingType] + 1

  if (kill.PlayerOrGroupDamagePercentage < 50) then
    if (ks[AutoBiographerEnum.KillTrackingType.TaggedKillWithGroupMinorityDamage] == nil) then ks[AutoBiographerEnum.KillTrackingType.TaggedKillWithGroupMinorityDamage] = 0 end
    ks[AutoBiographerEnum.KillTrackingType.TaggedKillWithGroupMinorityDamage] = ks[AutoBiographerEnum.KillTrackingType.TaggedKillWithGroupMinorityDamage] + 1
  end
end

function KillStatistics.GetSum(ks, killTrackingTypes)
  local sum = 0
  for k, killTrackingType in pairs(killTrackingTypes) do
    if (ks[killTrackingType]) then
      sum = sum + ks[killTrackingType]
    end
  end

  return sum
end

-- *** LevelStatistics ***

LevelStatistics = {}
function LevelStatistics.New(levelNum, totalTimePlayedAtDing, timePlayedThisLevel)
  local newInstance = AggregatedStatistics.New()
  newInstance.LevelNum = levelNum -- int
  newInstance.TotalTimePlayedAtDing = totalTimePlayedAtDing -- int (seconds)
  newInstance.TimePlayedThisLevel = timePlayedThisLevel -- int (seconds)

  return newInstance
end

-- *** MiscellaneousStatistics ***

MiscellaneousStatistics = {}
function MiscellaneousStatistics.New()
  return {}
end

function MiscellaneousStatistics.Add(ms, miscellaneousTrackingType, value)
  if (ms[miscellaneousTrackingType] == nil) then ms[miscellaneousTrackingType] = 0 end
  
  ms[miscellaneousTrackingType] = ms[miscellaneousTrackingType] + value
end

-- *** MoneyStatistics ***

MoneyStatistics = {}
function MoneyStatistics.New()
  return {
    TotalMoneyGained = 0,
    TotalMoneyLost = 0,
  }
end

function MoneyStatistics.AddMoney(ms, moneyAcquisitionMethod, money)
  if (not ms[moneyAcquisitionMethod]) then ms[moneyAcquisitionMethod] = 0 end
  
  ms[moneyAcquisitionMethod] = ms[moneyAcquisitionMethod] + money
end

function MoneyStatistics.TotalMoneyChanged(ms, deltaMoney) 
  if (deltaMoney < 0) then ms.TotalMoneyLost =  ms.TotalMoneyLost + abs(deltaMoney)
  elseif (deltaMoney > 0) then ms.TotalMoneyGained =  ms.TotalMoneyGained + deltaMoney
  end
end

-- *** OtherPlayerStatistics ***

OtherPlayerStatistics = {}
function OtherPlayerStatistics.New()
  return {}
end

function OtherPlayerStatistics.Add(ops, otherPlayerTrackingType, sum)
  if (not ops[otherPlayerTrackingType]) then ops[otherPlayerTrackingType] = 0 end
  
  ops[otherPlayerTrackingType] = ops[otherPlayerTrackingType] + sum
end

function OtherPlayerStatistics.GetSum(ops, otherPlayerTrackingTypes)
  local sum = 0
  for k, otherPlayerTrackingType in pairs(otherPlayerTrackingTypes) do
    if (ops[otherPlayerTrackingType]) then
      sum = sum + ops[otherPlayerTrackingType]
    end
  end

  return sum
end

-- *** QuestStatistics ***

QuestStatistics = {}
function QuestStatistics.New()
  return {}
end

function QuestStatistics.Increment(qs, questTrackingType)
  if (not qs[questTrackingType]) then qs[questTrackingType] = 0 end
  
  qs[questTrackingType] = qs[questTrackingType] + 1
end

function QuestStatistics.GetSum(qs, questTrackingTypes)
  local sum = 0
  for k, questTrackingType in pairs(questTrackingTypes) do
    if (qs[questTrackingType]) then
      sum = sum + qs[questTrackingType]
    end
  end

  return sum
end

-- *** SpellStatistics ***

SpellStatistics = {}
function SpellStatistics.New()
  return {}
end

function SpellStatistics.Increment(ss, spellTrackingType)
  if (not ss[spellTrackingType]) then ss[spellTrackingType] = 0 end
  
  ss[spellTrackingType] = ss[spellTrackingType] + 1
end

function SpellStatistics.GetSum(ss, spellTrackingTypes)
  local sum = 0
  for k, spellTrackingType in pairs(spellTrackingTypes) do
    if (ss[spellTrackingType]) then
      sum = sum + ss[spellTrackingType]
    end
  end

  return sum
end

-- *** TimeStatistics ***

TimeStatistics = {}
function TimeStatistics.New()
  return {}
end

function TimeStatistics.AddTime(ts, timeTrackingType, seconds)
  if (ts[timeTrackingType] == nil) then ts[timeTrackingType] = 0 end
  
  ts[timeTrackingType] = ts[timeTrackingType] + seconds
end

function TimeStatistics.GetSum(ts, timeTrackingTypes)
  local sum = 0
  for k, timeTrackingType in pairs(timeTrackingTypes) do
    if (ts[timeTrackingType]) then
      sum = sum + ts[timeTrackingType]
    end
  end

  return sum
end