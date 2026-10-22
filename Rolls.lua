AutoBiographer_Rolls = {
  Started = false,
  SeenLootRolls = {}, -- Runtime only; don't count the same history row on every update.
  LastRandomRollLineId = nil,
}

local Rolls = AutoBiographer_Rolls
local Api = AutoBiographer_Api
local Controller = AutoBiographer_Controller

local function IsReadable(value, expectedType)
  return not (issecretvalue and issecretvalue(value)) and type(value) == expectedType
end

-- Use the client's localized message, including positional placeholders,
-- rather than hardcoding the English /roll chat message.
local function MatchRandomRoll(text)
  if (not IsReadable(RANDOM_ROLL_RESULT, "string")) then return end
  local pattern, arguments, offset, nextArgument = "^", {}, 1, 1
  while (offset <= #RANDOM_ROLL_RESULT) do
    local remaining = RANDOM_ROLL_RESULT:sub(offset)
    local position, kind = remaining:match("^%%(%d+)%$([sd])")
    local consumed
    if (position) then
      consumed = #position + 3
      position = tonumber(position)
    else
      kind = remaining:match("^%%([sd])")
      if (kind) then position, consumed = nextArgument, 2; nextArgument = nextArgument + 1 end
    end
    if (kind) then
      pattern = pattern .. (kind == "d" and "(%d+)" or "(.-)")
      arguments[#arguments + 1] = position
      offset = offset + consumed
    else
      local character = remaining:sub(1, 1)
      if (remaining:sub(1, 2) == "%%") then offset = offset + 2 else offset = offset + 1 end
      pattern = pattern .. character:gsub("(%W)", "%%%1")
    end
  end
  local captures = { text:match(pattern .. "$") }
  local values = {}
  for index, value in ipairs(captures) do values[arguments[index]] = value end
  return values[1], tonumber(values[2]), tonumber(values[3]), tonumber(values[4])
end

function Rolls:OnLootHistoryChanged()
  if (not self.Started) then return end
  for _, result in ipairs(Api.GetPlayerLootRolls()) do
    if (not self.SeenLootRolls[result.Key]) then
      self.SeenLootRolls[result.Key] = true
      Controller:OnItemRolled(time(), result.ItemId, result.Roll, result.RollType, result.ItemLink)
    end
  end
end

function Rolls:OnSystemMessage(text, lineId)
  if (not self.Started or not IsReadable(text, "string")) then return end
  local roller, roll, minimum, maximum = MatchRandomRoll(text)
  if (not roller or not roll or minimum ~= 1 or maximum ~= 100 or roll < minimum or roll > maximum) then return end
  local name, lastName = Api.GetUnitName("player")
  if (not IsReadable(name, "string")) then return end
  if (IsReadable(lastName, "string") and lastName ~= "") then name = name .. " " .. lastName end
  if (roller ~= name) then
    -- Classic chat can qualify a player's name with their own realm.
    local realm = GetNormalizedRealmName and GetNormalizedRealmName()
    if (Api.IsWoWForever() or not IsReadable(realm, "string") or roller ~= name .. "-" .. realm) then return end
  end
  if (IsReadable(lineId, "number") and lineId > 0) then
    if (self.LastRandomRollLineId == lineId) then return end
    self.LastRandomRollLineId = lineId
  end
  Controller:OnRandomRolled(roll)
end

function Rolls:Start()
  if (self.Started) then return end
  -- Existing completed history after a reload/relogin is a baseline, not new
  -- rolls. Pending rolls can still be counted when their results arrive.
  for _, result in ipairs(Api.GetPlayerLootRolls()) do self.SeenLootRolls[result.Key] = true end
  self.Started = true
end
