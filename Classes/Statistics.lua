-- *** AggregatedStatistics ***

AggregatedStatistics = {}
function AggregatedStatistics.New()
  return {
    DamageStatistics = DamageStatistics.New(),
    ExperienceStatistics = ExperienceStatistics.New(),
    GatheringStatistics = nil,
    ItemStatisticsByItem = {}, -- Dict<CatalogItemId, ItemStatistics>
    KillStatistics = KillStatistics.New(),
    MiscellaneousStatistics = MiscellaneousStatistics.New(),
    MoneyStatistics = MoneyStatistics.New(),
    OtherPlayerStatisticsByOtherPlayer = {}, -- Dict<CatalogUnitId, PlayerStatistics>
    PvpStatistics = nil,
    SpellStatisticsBySpell = {}, -- Dict<CatalogSpellId, SpellStatistics>
    TimeStatisticsByArea = {}, -- Dict<ZoneName-SubZoneName, TimeStatistics>
  }
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

function ItemStatistics.AddCount(is, acquisitionMethod, quantity)
  if (not is[acquisitionMethod]) then is[acquisitionMethod] = 0 end
  
  is[acquisitionMethod] = is[acquisitionMethod] + quantity
end

-- *** KillStatistics ***

KillStatistics = {}
function KillStatistics.New()
  return {
    UntaggedKills = KillBreakdown.New(),
    TaggedKills = KillBreakdown.New()
  }
end

function KillStatistics.AddKill(ks, kill) 
  if (kill.PlayerHasTag) then
    KillBreakdown.AddKill(ks.TaggedKills, kill)
  else
    KillBreakdown.AddKill(ks.UntaggedKills, kill)
  end
end

function KillStatistics.GetTaggedKillingBlows(ks)
  return KillBreakdown.GetTotalKillingBlows(ks.TaggedKills)
end

function KillStatistics.GetTaggedKills(ks)
  return KillBreakdown.GetTotalKills(ks.TaggedKills)
end

function KillStatistics.GetTaggedKillsByCatalogUnitId(ks, catalogUnitId)
  return KillBreakdown.GetTotalKillsByCatalogUnitId(ks.TaggedKills, catalogUnitId)
end

function KillStatistics.GetTotalKillingBlowsByCatalogUnitId(ks, catalogUnitId)
  local sum = 0
  
  if (ks.TaggedKills.PlayerKillingBlows[catalogUnitId]) then
    sum = sum + ks.TaggedKills.PlayerKillingBlows[catalogUnitId]
  end
  
  if (ks.UntaggedKills.PlayerKillingBlows[catalogUnitId]) then
    sum = sum + ks.UntaggedKills.PlayerKillingBlows[catalogUnitId]
  end
  
  return sum
end

function KillStatistics.GetTotalKillsByCatalogUnitId(ks, unitId)
  return KillBreakdown.GetTotalKillsByCatalogUnitId(ks.UntaggedKills, unitId) + KillBreakdown.GetTotalKillsByCatalogUnitId(ks.TaggedKills, unitId)
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

function MoneyStatistics.AddMoney(ms, acquisitionMethod, money)
  if (not ms[acquisitionMethod]) then ms[acquisitionMethod] = 0 end
  
  ms[acquisitionMethod] = ms[acquisitionMethod] + money
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

-- *** SpellStatistics ***

SpellStatistics = {}
function SpellStatistics.New()
  return {}
end

function SpellStatistics.Increment(ss, spellTrackingType)
  if (not ss[spellTrackingType]) then ss[spellTrackingType] = 0 end
  
  ss[spellTrackingType] = ss[spellTrackingType] + 1
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