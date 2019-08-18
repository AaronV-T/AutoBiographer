-- *** Kill ***

Kill = {}
function Kill.New(groupGotAssistOrKillingBlow, playerGotAssist, playerGotKillingBlow, playerHasTag, catalogUnitId)
  return {
    CatalogUnitId = catalogUnitId,
    GroupGotAssistOrKillingBlow = groupGotAssistOrKillingBlow,
    PlayerHasTag = playerHasTag,
    PlayerGotAssist = playerGotAssist,
    PlayerGotKillingBlow= playerGotKillingBlow
  }
end

-- *** DamageBreakdown ***

DamageBreakdown = {}
function DamageBreakdown.New()
  return {
    Amount = 0,
    Over = 0,
  }
end

function DamageBreakdown.Add(db, amount, over)
  db.Amount = db.Amount + amount
  db.Over = db.Over + over
end

-- *** KillBreakdown ***

KillBreakdown = {}
function KillBreakdown.New()
  return {
    PlayerKillingBlows = {}, -- int[]
    PlayerAssists = {}, -- int[]
    GroupAssistsAndKillingBlows = {} -- int[]
  }
end

function KillBreakdown.AddKill(kb, kill)
  if (kill.PlayerGotKillingBlow) then
    if (kb.PlayerKillingBlows[kill.CatalogUnitId] == nil) then kb.PlayerKillingBlows[kill.CatalogUnitId] = 1
    else kb.PlayerKillingBlows[kill.CatalogUnitId] = kb.PlayerKillingBlows[kill.CatalogUnitId] + 1
    end
  elseif (kill.PlayerGotAssist) then
    if (kb.PlayerAssists[kill.CatalogUnitId] == nil) then kb.PlayerAssists[kill.CatalogUnitId] = 1
    else kb.PlayerAssists[kill.CatalogUnitId] = kb.PlayerAssists[kill.CatalogUnitId] + 1
    end
  else
    if (kb.GroupAssistsAndKillingBlows[kill.CatalogUnitId] == nil) then kb.GroupAssistsAndKillingBlows[kill.CatalogUnitId] = 1
    else kb.GroupAssistsAndKillingBlows[kill.CatalogUnitId] = kb.GroupAssistsAndKillingBlows[kill.CatalogUnitId] + 1
    end
  end
end

function KillBreakdown.GetTotalKillsByCatalogUnitId(kb, catalogUnitId)
  local sum =  0
  if (kb.PlayerKillingBlows[catalogUnitId]) ~= nil then
    sum = sum + kb.PlayerKillingBlows[catalogUnitId]
  end
  if (kb.PlayerAssists[catalogUnitId]) ~= nil then
    sum = sum + kb.PlayerAssists[catalogUnitId]
  end
  if (kb.GroupAssistsAndKillingBlows[catalogUnitId]) ~= nil then
    sum = sum + kb.GroupAssistsAndKillingBlows[catalogUnitId]
  end
  
  return sum
end

-- *** Coordinates ***

Coordinates = {}
function Coordinates.New(mapId, x, y)
  return {
    MapId = mapId,
    X = x,
    Y = y
  }
end