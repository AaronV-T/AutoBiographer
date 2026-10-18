AutoBiographer_Fishing = {
  Attempts = {},
}

local Fishing = AutoBiographer_Fishing
local Controller = AutoBiographer_Controller
local EM = AutoBiographer_EventManager
local Api = AutoBiographer_Api
local Enum = AutoBiographerEnum
local resultDelay = 2
local lootRetention = 5

local function IsReadable(value, valueType)
  return not EM:IsSecretValue(value) and type(value) == valueType
end

local function IsFishingSpell(spellId)
  if (not IsReadable(spellId, "number")) then return false end
  if (spellId == 7620) then return true end
  local name = Api.GetSpellInfo(spellId)
  local fishingName = Api.GetSpellInfo(7620)
  return IsReadable(name, "string") and IsReadable(fishingName, "string") and name == fishingName
end

function Fishing:ConsumeLoot(itemId, quantity)
  self:Prune()
  for index = #self.Attempts, 1, -1 do
    local attempt = self.Attempts[index]
    if (attempt.Outcome == "Catch" and
        (not attempt.LootClosedAt or GetTime() - attempt.LootClosedAt <= lootRetention)) then
      local remaining = attempt.Items[itemId] or 0
      if (attempt.LootClosedAt) then
        remaining = math.min(remaining, (attempt.ClearedItems[itemId] or 0) - (attempt.ConsumedItems[itemId] or 0))
      end
      if (quantity <= remaining) then
        attempt.Items[itemId] = remaining - quantity
        attempt.ConsumedItems[itemId] = (attempt.ConsumedItems[itemId] or 0) + quantity
        return true
      end
    end
  end
  return false
end

function Fishing:Flush(zone, subZone)
  local attempt = self.ActiveAttempt
  if (not attempt) then return end
  local endTime = math.min(GetTime(), attempt.EndTime or GetTime())
  local seconds = endTime - attempt.LastTime
  if (seconds <= 0) then return end
  attempt.LastTime = endTime
  local info = EM.PersistentPlayerInfo
  Controller:AddTime(Enum.TimeTrackingType.Fishing, seconds, zone or info.CurrentZone, subZone or info.CurrentSubZone)
end

function Fishing:GetPendingAttemptCount(minLevel, maxLevel)
  local count = 0
  for _, attempt in ipairs(self.Attempts) do
    if (attempt.Pending and attempt.Level >= minLevel and attempt.Level <= maxLevel) then count = count + 1 end
  end
  return count
end

function Fishing:OnChannelStart(spellId, channelId)
  if (not IsFishingSpell(spellId)) then return end
  if (self.ActiveAttempt and IsReadable(channelId, "string") and self.ActiveAttempt.ChannelId == channelId) then return end
  if (self.ActiveAttempt) then self:OnChannelStop(7620) end
  self:Prune()
  local statistics = Controller:GetCurrentLevelStatistics()
  local attempt = {
    ChannelId = IsReadable(channelId, "string") and channelId or nil,
    Items = {}, Slots = {}, ClearedItems = {}, ConsumedItems = {},
    LastTime = GetTime(),
    Level = statistics.LevelNum,
    Pending = true,
  }
  table.insert(self.Attempts, attempt)
  self.ActiveAttempt = attempt
  Controller:AddFishingStat(Enum.MiscellaneousTrackingType.FishingCasts, attempt.Level)
  self:OnChannelUpdate()
end

function Fishing:OnChannelStop(spellId, channelId)
  if (not self.ActiveAttempt or not IsFishingSpell(spellId)) then return end
  local attempt = self.ActiveAttempt
  if (IsReadable(channelId, "string") and attempt.ChannelId and attempt.ChannelId ~= channelId) then return end
  self:Flush()
  self.ActiveAttempt = nil
  attempt.EndedAt = GetTime()
  -- Fishing loot arrives after CHANNEL_STOP. Keep the result pending briefly,
  -- and retain its loot context after LOOT_CLOSED for the later loot chat message.
  C_Timer.After(resultDelay, function()
    attempt.Pending = false
    self:Prune()
  end)
end

function Fishing:OnChannelUpdate()
  if (not self.ActiveAttempt or not UnitChannelInfo) then return end
  local success, name, text, icon, startMs, endMs = pcall(UnitChannelInfo, "player")
  if (success and IsReadable(endMs, "number") and endMs / 1000 >= self.ActiveAttempt.LastTime) then
    self.ActiveAttempt.EndTime = endMs / 1000
  end
end

function Fishing:OnInfoMessage(message)
  if (not IsReadable(message, "string")) then return end
  local outcome
  if (message == ERR_FISH_ESCAPED) then outcome = "GotAway"
  elseif (message == ERR_FISH_NOT_HOOKED) then outcome = "Other"
  else return end
  self:Prune()
  local attempt = self.ActiveAttempt or self.Attempts[#self.Attempts]
  if (not attempt or attempt.Outcome) then return end
  attempt.Outcome = outcome
  attempt.Pending = false
  if (outcome == "GotAway") then
    Controller:AddFishingStat(Enum.MiscellaneousTrackingType.FishGotAway, attempt.Level)
  end
end

function Fishing:OnLootClosed()
  local attempt = self.LootAttempt
  if (not attempt) then return end
  attempt.LootClosedAt = GetTime()
  self.LootAttempt = nil
  C_Timer.After(lootRetention, function() self:Prune() end)
end

function Fishing:OnLootReady()
  if (not IsFishingLoot) then return end
  local success, fishingLoot = pcall(IsFishingLoot)
  if (not success or not IsReadable(fishingLoot, "boolean")) then return end
  if (not fishingLoot) then
    self:OnLootClosed()
    return
  end
  self:Prune()
  local attempt = self.LootAttempt
  if (not attempt) then
    -- Prefer the latest ended cast: the player could already have recast before
    -- the previous cast's loot event arrives.
    for index = #self.Attempts, 1, -1 do
      local candidate = self.Attempts[index]
      if (candidate.EndedAt) then attempt = candidate; break end
    end
    if (attempt and attempt.Outcome) then return end
    attempt = attempt or (self.ActiveAttempt and not self.ActiveAttempt.Outcome and self.ActiveAttempt)
    if (not attempt) then return end
    self.LootAttempt = attempt
    attempt.Outcome = "Catch"
    attempt.Pending = false
    Controller:AddFishingStat(Enum.MiscellaneousTrackingType.FishingCatches, attempt.Level)
  end

  local count = GetNumLootItems()
  if (not IsReadable(count, "number")) then return end
  for slot = 1, count do
    local link = GetLootSlotLink(slot)
    local _, _, quantity = GetLootSlotInfo(slot)
    if (IsReadable(link, "string") and IsReadable(quantity, "number") and quantity > 0) then
      local itemId = HelperFunctions.GetItemIdFromTextWithChatItemLink(link)
      if (itemId and not attempt.Slots[slot]) then
        attempt.Slots[slot] = { ItemId = itemId, Quantity = quantity }
        attempt.Items[itemId] = (attempt.Items[itemId] or 0) + quantity
      end
    end
  end
end

function Fishing:OnLootSlotCleared(slotId)
  local attempt = self.LootAttempt
  if (not attempt or not IsReadable(slotId, "number")) then return end
  local slot = attempt.Slots[slotId]
  if (not slot or slot.Cleared) then return end
  slot.Cleared = true
  attempt.ClearedItems[slot.ItemId] = (attempt.ClearedItems[slot.ItemId] or 0) + slot.Quantity
end

function Fishing:Prune()
  local now = GetTime()
  for index = #self.Attempts, 1, -1 do
    local attempt = self.Attempts[index]
    local lastTime = attempt.LootClosedAt or attempt.EndedAt
    if (attempt ~= self.ActiveAttempt and attempt ~= self.LootAttempt and not attempt.Pending and
        lastTime and now - lastTime >= lootRetention) then
      table.remove(self.Attempts, index)
    end
  end
end

function Fishing:Stop()
  self:Flush()
  self.ActiveAttempt = nil
  self.LootAttempt = nil
  self.Attempts = {}
end
