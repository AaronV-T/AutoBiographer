-- *** AggregatedStatistics ***

AggregatedStatistics = {}
function AggregatedStatistics.New()
  return {
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
    SpellStatisticsBySpell = {}, -- Dict<CatalogSpellId, SpellStatistics>
    TimeStatisticsByArea = {}, -- Dict<ZoneName-SubZoneName, TimeStatistics>
  }
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
      killTrackingType = AutoBiographerEnum.KillTrackingType.TaggedAssists
    else
      killTrackingType = AutoBiographerEnum.KillTrackingType.TaggedGroupAssistsAndKillingBlows
    end
  else
    if (kill.PlayerGotKillingBlow) then
      killTrackingType = AutoBiographerEnum.KillTrackingType.UntaggedKillingBlows
    elseif (kill.PlayerGotAssist) then
      killTrackingType = AutoBiographerEnum.KillTrackingType.UntaggedAssists
    else
      killTrackingType = AutoBiographerEnum.KillTrackingType.UntaggedGroupAssistsAndKillingBlows
    end
  end

  if (killTrackingType) then
    if (ks[killTrackingType] == nil) then ks[killTrackingType] = 0 end

    ks[killTrackingType] = ks[killTrackingType] + 1
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