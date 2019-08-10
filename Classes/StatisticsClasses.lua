-- *** AggregatedStatistics ***

AggregatedStatistics = {}
function AggregatedStatistics.New()
  local newInstance = {
    GatheringStatistics = nil,
    ItemStatistics = nil,
    KillStatistics = KillStatistics.New(),
    MiscellaneousStatistics = nil,
    MoneyStatistics = nil,
    PvpStatistics = nil,
    SpellStatistics = nil,
    TimeStatisticsByZone = nil
  }
  
  return newInstance
end

-- *** KillStatistics ***

KillStatistics = {}
function KillStatistics.New()
  local newInstance = {
    UntaggedKills = KillBreakdown.New(),
    TaggedKills = KillBreakdown.New()
  }
  
  return newInstance
end

function KillStatistics.AddKill(ks, kill) 
  if (kill.PlayerHasTag) then
    KillBreakdown.AddKill(ks.TaggedKills, kill)
  else
    KillBreakdown.AddKill(ks.UntaggedKills, kill)
  end
end

function KillStatistics.GetTaggedKillsForUnit(ks, unitId)
  return KillBreakdown.GetTotalKillsForUnit(ks.TaggedKills, unitId)
end

function KillStatistics.GetTotalKillsForUnit(ks, unitId)
  return KillBreakdown.GetTotalKillsForUnit(ks.UntaggedKills, unitId) + KillBreakdown.GetTotalKillsForUnit(ks.TaggedKills, unitId)
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