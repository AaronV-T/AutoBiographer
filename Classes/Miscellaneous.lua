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

-- *** Coordinates ***

Coordinates = {}
function Coordinates.New(instanceId, mapId, x, y)
  return {
    InstanceId = instanceId,
    MapId = mapId,
    X = x,
    Y = y
  }
end