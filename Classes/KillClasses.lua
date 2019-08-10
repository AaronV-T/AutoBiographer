-- *** Kill ***

Kill = {}
function Kill.New(groupGotAssistOrKillingBlow, playerGotAssist, playerGotKillingBlow, playerHasTag, unitId)
  local newInstance = {
    GroupGotAssistOrKillingBlow = groupGotAssistOrKillingBlow,
    PlayerHasTag = playerHasTag,
    PlayerGotAssist = playerGotAssist,
    PlayerGotKillingBlow= playerGotKillingBlow,
    UnitId = unitId
  }
  
  return newInstance
end

-- *** KillBreakdown ***

KillBreakdown = {}
function KillBreakdown.New()
  local newInstance = {
    PlayerKillingBlows = {}, -- int[]
    PlayerAssists = {}, -- int[]
    GroupAssistsAndKillingBlows = {} -- int[]
  }
  
  return newInstance
end

function KillBreakdown.AddKill(kb, kill)
  if (kill.PlayerGotKillingBlow) then
    if (kb.PlayerKillingBlows[kill.UnitId] == nil) then kb.PlayerKillingBlows[kill.UnitId] = 1
    else kb.PlayerKillingBlows[kill.UnitId] = kb.PlayerKillingBlows[kill.UnitId] + 1
    end
  elseif (kill.PlayerGotAssist) then
    if (kb.PlayerAssists[kill.UnitId] == nil) then kb.PlayerAssists[kill.UnitId] = 1
    else kb.PlayerAssists[kill.UnitId] = kb.PlayerAssists[kill.UnitId] + 1
    end
  else
    if (kb.GroupAssistsAndKillingBlows[kill.UnitId] == nil) then kb.GroupAssistsAndKillingBlows[kill.UnitId] = 1
    else kb.GroupAssistsAndKillingBlows[kill.UnitId] = kb.GroupAssistsAndKillingBlows[kill.UnitId] + 1
    end
  end
end

function KillBreakdown.GetTotalKillsForUnit(kb, unitId)
  local sum =  0
  if (kb.PlayerKillingBlows[unitId]) ~= nil then
    sum = sum + kb.PlayerKillingBlows[unitId]
  end
  if (kb.PlayerAssists[unitId]) ~= nil then
    sum = sum + kb.PlayerAssists[unitId]
  end
  if (kb.GroupAssistsAndKillingBlows[unitId]) ~= nil then
    sum = sum + kb.GroupAssistsAndKillingBlows[unitId]
  end
  
  return sum
end