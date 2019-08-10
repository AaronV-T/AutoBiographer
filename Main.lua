EventManager = {
  EventHandlers = {},
  NewLevelToAddToHistory = nil
}

local EM = EventManager

-- *** Locals ***

local damagedUnits = {}

local combatLogDamageEvents = { }
do
    local damageEventPrefixes = { "RANGE", "SPELL", "SPELL_BUILDING", "SPELL_PERIODIC", "SWING"  }
    local damageEventSuffixes = { "DAMAGE", "DRAIN", "INSTAKILL", "LEECH" }
    for _, prefix in pairs(damageEventPrefixes) do
        for _, suffix in pairs(damageEventSuffixes) do
            combatLogDamageEvents[prefix .. "_" .. suffix] = true
        end
    end
end

local validUnitIds = { "focus", "focuspet", "mouseover", "mouseoverpet", "pet", "target", "targetpet" }
for i = 1, 40 do
	if i <= 4 then
		validUnitIds[#validUnitIds + 1] = "party" .. i
		validUnitIds[#validUnitIds + 1] = "partypet" .. i
	end
	validUnitIds[#validUnitIds + 1] = "raid" .. i
	validUnitIds[#validUnitIds + 1] = "raidpet" .. i
end
for i = 1, #validUnitIds do
	validUnitIds[#validUnitIds + 1] = validUnitIds[i] .. "target"
end

local function FindUnitIdByUnitGUID(unitGuid)
	for i = 1, #validUnitIds do
		if UnitGUID(validUnitIds[i]) == unitGuid then return validUnitIds[i] end
	end
	return nil
end

local function IsUnitInOurPartyOrRaid(unitGuid)
  for i = 1, #validUnitIds do
    if ((string.match(validUnitIds[i], "party%d") or string.match(validUnitIds[i], "raid%d")) and not string.match(validUnitIds[i], "target")) then
        if (UnitGUID(validUnitIds[i]) == unitGuid) then return true end
    end
	end
	return false
end

-- *** Event Handlers ***

function EM:OnEvent(_, event, ...)
  if self.EventHandlers[event] then
		self.EventHandlers[event](self, ...)
	end
end

function EM.EventHandlers.ADDON_LOADED(self, addonName, ...)
  if addonName ~= "AutoBiographer" then return end
 
  if type(_G["AUTOBIOGRAPHER_LEVELS_CHAR"]) ~= "table" then
		_G["AUTOBIOGRAPHER_LEVELS_CHAR"] = { }
	end
  
	Controller.CharacterData = {
    Levels = _G["AUTOBIOGRAPHER_LEVELS_CHAR"]
  }
  
  if (Controller.CharacterData.Levels[UnitLevel("player")]) == nil then 
    if (UnitLevel("player") == 1 and UnitXP("player")) == 0 then
      Controller:AddLevel(UnitLevel("player"), time(), 0)
    else 
      Controller:AddLevel(UnitLevel("player"))
    end
  end
end

function EM.EventHandlers.COMBAT_LOG_EVENT_UNFILTERED(self)
  local timestamp, event, hideCaster, sourceGuid, sourceName, sourceFlags, sourceRaidFlags, destGuid, destName, destFlags, destRaidflags = CombatLogGetCurrentEventInfo()

  --print(event)
  --if (playerCausedThisEvent) then print(CombatLogGetCurrentEventInfo()) end
  
  if (combatLogDamageEvents[event]) then
    local playerCausedThisEvent = sourceGuid == self.PlayerGuid
    --if (playerCausedThisEvent) then print(UnitIsTapDenied("target")) end
    
    if (damagedUnits[destGuid] == nil) then   
      local firstObservedDamageCausedByPlayerOrGroup = false
      if (playerCausedThisEvent or IsUnitInOurPartyOrRaid(sourceGuid)) then
        firstObservedDamageCausedByPlayerOrGroup = true

      end
      
      damagedUnits[destGuid] = {
        FirstObservedDamageCausedByPlayerOrGroup = firstObservedDamageCausedByPlayerOrGroup,
        IsTapDenied = nil, -- If true, guaranteed we don't have tag. If false, guaranteed we have tag.
        LastUnitGuidWhoCausedDamage = sourceGuid,
        PlayerHasDamaged = playerCausedThisEvent
      }
    else
      if (damagedUnits[destGuid].IsTapDenied == nil) then
        local damagedUnitId = FindUnitIdByUnitGUID(destGuid)
        if (damagedUnitId ~= nil) then
          damagedUnits[destGuid].IsTapDenied = UnitIsTapDenied(damagedUnitId)
          --print(destName .. " tap denied: " .. tostring(damagedUnits[destGuid].IsTapDenied))
        end
      end
    end
    
    local damagedUnit = damagedUnits[destGuid]
    if (not damagedUnit.PlayerHasDamaged and playerCausedThisEvent) then damagedUnit.PlayerHasDamaged = true end
    damagedUnit.LastUnitGuidWhoCausedDamage = sourceGuid
  end

  if (event ~= "UNIT_DIED") then return end
  
  if (damagedUnits[destGuid] == nil) then return end
  
  local deadUnit = damagedUnits[destGuid]
  
  local weHadTag = false
  if (deadUnit.IsTapDenied ~= nil) then
    weHadTag = not deadUnit.IsTapDenied
  else
    weHadTag = deadUnit.FirstObservedDamageCausedByPlayerOrGroup
  end
  
  if (deadUnit.PlayerHasDamaged or weHadTag) then
    print (destName .. " Died.  Tagged: " .. tostring(weHadTag) .. ". FirstDmg: " .. tostring(deadUnit.FirstObservedDamageCausedByPlayerOrGroup) .. ". IsTapDenied: "  .. tostring(deadUnit.IsTapDenied) .. ". PlayerHasDamaged: " .. tostring(deadUnit.PlayerHasDamaged) .. ". LastDmg: " .. tostring(deadUnit.LastUnitGuidWhoCausedDamage))
    
    Controller:AddKill(Kill.New(false, deadUnit.PlayerHasDamaged, deadUnit.LastUnitGuidWhoCausedDamage == self.PlayerGuid, weHadTag, HelperFunctions.GetIdFromGuid(destGuid)))
  end
  
  damagedUnits[destGuid] = nil
end

function EM.EventHandlers.PLAYER_LEVEL_UP(self, newLevel, ...)
  self.NewLevelToAddToHistory = newLevel
  
  RequestTimePlayed()
end

function EM.EventHandlers.PLAYER_LOGIN(self)
  self.PlayerGuid = UnitGUID("player") -- Player GUID Format: Player-[server ID]-[player UID]
end

function EM.EventHandlers.TIME_PLAYED_MSG(self, totalTimePlayed, levelTimePlayed) 
  if self.NewLevelToAddToHistory ~= nil then
    Controller:AddLevel(self.NewLevelToAddToHistory, time(), totalTimePlayed)
    self.NewLevelToAddToHistory = nil
  end
end

-- Register each event for which we have an event handler.
EM.Frame = CreateFrame("Frame")
for eventName,_ in pairs(EM.EventHandlers) do
	EM.Frame:RegisterEvent(eventName)
end
EM.Frame:SetScript("OnEvent", function(_, event, ...) EM:OnEvent(_, event, ...) end)

-- Test function.
function EM:Clear() 
  _G["Controller_CHAR"] = nil
  print("Data cleared. Please reload ui.")
end

function EM:Test()
  print("Test")
  local unitGuid = UnitGUID("target")
  --print (UnitIsTapDenied("target"))
  --print(CanLootUnit(unitGuid))
  --print(UnitAffectingCombat("target"))
end