AutoBiographer_ClassActivity = {
  Active = false,
  Timers = {}, -- Runtime only; saved statistics contain IDs and accumulated seconds.
}

local Activity = AutoBiographer_ClassActivity
local Api = AutoBiographer_Api
local Controller = AutoBiographer_Controller
local Enum = AutoBiographerEnum

Activity.StateDefinitions = {
  { "AquaticForm", "Aquatic Form", "DRUID", 4 },
  { "BearForm", "Bear Form", "DRUID", 5, 8 },
  { "CatForm", "Cat Form", "DRUID", 1 },
  { "MoonkinForm", "Moonkin Form", "DRUID", 31 },
  { "TravelForm", "Travel Form", "DRUID", 3 },
  { "GhostWolf", "Ghost Wolf", "SHAMAN", 16 },
  { "Shadowform", "Shadowform", "PRIEST", 13 },
  { "BattleStance", "Battle Stance", "WARRIOR", 17 },
  { "BerserkerStance", "Berserker Stance", "WARRIOR", 19 },
  { "DefensiveStance", "Defensive Stance", "WARRIOR", 18 },
  { "Stealthed", "Stealthed", "ROGUE", OtherClass = "DRUID" },
  { "FeignDeath", "Feign Death", "HUNTER" },
  { "MindControl", "Mind Control", "PRIEST" },
}

local auraSpellIds = { 465, 7294, 19746, 19876, 19888, 19891, 20218 }
local sealSpellIds = { 21084, 21082, 20375, 20164, 20165, 20166 }
local spellNames = {}

local function ReadSpellName(spellId)
  if (spellNames[spellId]) then return spellNames[spellId] end
  local name = Api.GetSpellInfo(spellId)
  if (not (issecretvalue and issecretvalue(name)) and type(name) == "string") then
    spellNames[spellId] = name
    return name
  end
end

local function SpellMatches(spellId, baseSpellIds)
  local name = ReadSpellName(spellId)
  for _, baseId in ipairs(baseSpellIds) do
    if (spellId == baseId) then return true end
    if (name and name == ReadSpellName(baseId)) then return true end
  end
  return false
end

function Activity:Flush(zone, subZone)
  local now = GetTime()
  for _, timer in pairs(self.Timers) do
    local finish = timer.ExpiresAt and math.min(now, timer.ExpiresAt) or now
    local seconds = math.max(0, finish - timer.StartedAt)
    if (seconds > 0) then
      if (timer.Kind == "State") then
        Controller:AddTime(timer.Id, seconds, zone, subZone)
      elseif (timer.Kind == "Spell") then
        Controller:AddSpellTime(timer.Id, seconds)
      elseif (timer.Kind == "Companion") then
        Controller:AddCompanionFamilyTime(timer.Id, timer.Name, seconds)
      end
    end
    timer.StartedAt = now
  end
end

function Activity:Start()
  self.Active = true
  self.Timers = {}
  self:Update()
end

function Activity:Stop()
  self.Active = false
  self.Timers = {}
end

function Activity:Update()
  if (not self.Active) then return end
  local EM = AutoBiographer_EventManager
  self:Flush(EM.PersistentPlayerInfo.CurrentZone, EM.PersistentPlayerInfo.CurrentSubZone)
  local now, desired = GetTime(), {}
  local function Add(key, kind, id, name, expiresAt)
    desired[key] = { Kind = kind, Id = id, Name = name, StartedAt = now, ExpiresAt = expiresAt }
  end

  -- Read actual states, not successful casts: forms can be cancelled, seals
  -- consumed, pets dismissed and totems destroyed without another cast.
  if (Api.GetPlayerAlive()) then
    local class = Api.GetPlayerClass()
    if (class == "DRUID" or class == "SHAMAN" or class == "PRIEST" or class == "WARRIOR") then
      local formId = Api.GetPlayerFormId()
      if (formId ~= nil) then
        for _, definition in ipairs(self.StateDefinitions) do
          if (definition[3] == class and definition[4] and (definition[4] == formId or definition[5] == formId)) then
            Add(definition[1], "State", Enum.TimeTrackingType[definition[1]])
          end
        end
      end
    end
    if ((class == "ROGUE" or class == "DRUID") and Api.GetPlayerStealthed()) then
      Add("Stealthed", "State", Enum.TimeTrackingType.Stealthed)
    end
    if (class == "HUNTER" and Api.GetPlayerFeignDeath()) then
      Add("FeignDeath", "State", Enum.TimeTrackingType.FeignDeath)
    end
    if (class == "PRIEST") then
      local channelId = Api.GetPlayerChannelSpellId()
      if (channelId and channelId > 0 and SpellMatches(channelId, { 605 })) then
        Add("MindControl", "State", Enum.TimeTrackingType.MindControl)
      end
    end
    if (class == "HUNTER" or class == "WARLOCK") then
      local familyId, familyName = Api.GetPlayerCompanionFamily()
      if (familyId and familyId > 0) then Add("Companion", "Companion", familyId, familyName) end
    end
    if (class == "PALADIN") then
      local auraId = Api.GetPlayerFormSpellId()
      if (auraId and auraId > 0 and SpellMatches(auraId, auraSpellIds)) then Add("Aura", "Spell", auraId) end
      for spellId in pairs(Api.GetPlayerHelpfulAuras() or {}) do
        if (SpellMatches(spellId, sealSpellIds)) then Add("Seal", "Spell", spellId) end
      end
    end
    if (class == "SHAMAN") then
      for slot, totem in pairs(Api.GetPlayerTotems() or {}) do
        if (totem and (not totem.ExpiresAt or totem.ExpiresAt > now)) then
          Add("Totem" .. slot, "Spell", totem.SpellId, nil, totem.ExpiresAt)
        end
      end
    end
  end
  -- Unknown/secret states end the readable interval. Never carry a stale
  -- state across an unreadable gap and retrospectively guess its duration.
  self.Timers = desired
end
