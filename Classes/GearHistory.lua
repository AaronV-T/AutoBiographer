-- The snapshot is the last observed equipment; changes reconstruct its history.
-- Item ID 0 means an empty slot. Names, item links and transmog are not stored.
GearHistory = {}

function GearHistory.New()
  return { Changes = {}, Snapshot = {} }
end

function GearHistory.RecordChange(data, timestamp, slotId, itemId)
  local previousItemId = data.Snapshot[slotId]
  if (previousItemId == itemId) then return false end
  data.Snapshot[slotId] = itemId
  -- On the first scan, record equipped items as the starting outfit, but do
  -- not create unequip entries for slots that have never held a known item.
  if (previousItemId == nil and itemId == 0) then return false end
  data.Changes[#data.Changes + 1] = { Timestamp = timestamp, SlotId = slotId, ItemId = itemId }
  return true
end
