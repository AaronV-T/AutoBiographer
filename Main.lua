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

local validUnitIds = { "focus", "focuspet", "mouseover", "mouseoverpet", "pet", "player", "target", "targetpet" }
for i = 1, 40 do
	if i <= 4 then
		validUnitIds[#validUnitIds + 1] = "party" .. i
		validUnitIds[#validUnitIds + 1] = "partypet" .. i
	end
	validUnitIds[#validUnitIds + 1] = "raid" .. i
	validUnitIds[#validUnitIds + 1] = "raidpet" .. i
end
for i = 1, 50 do
  validUnitIds[#validUnitIds + 1] = "nameplate" .. i
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

local function IsUnitGUIDInOurPartyOrRaid(unitGuid)
  for i = 1, #validUnitIds do
    if ((string.match(validUnitIds[i], "party%d") or string.match(validUnitIds[i], "raid%d")) and not string.match(validUnitIds[i], "target")) then
        if (UnitGUID(validUnitIds[i]) == unitGuid) then return true end
    end
	end
	return false
end

local function IsUnitGUIDPlayerOrPlayerPet(unitGuid)
  if (UnitGUID("player") == unitGuid) then return true end
  if (UnitGUID("pet") == unitGuid) then return true end
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
 
  if type(_G["AUTOBIOGRAPHER_CATALOGS_CHAR"]) ~= "table" then
		_G["AUTOBIOGRAPHER_CATALOGS_CHAR"] = Catalogs.New()
	end
  if type(_G["AUTOBIOGRAPHER_EVENTS_CHAR"]) ~= "table" then
		_G["AUTOBIOGRAPHER_EVENTS_CHAR"] = {}
	end
  if type(_G["AUTOBIOGRAPHER_LEVELS_CHAR"]) ~= "table" then
		_G["AUTOBIOGRAPHER_LEVELS_CHAR"] = {}
	end
  
	Controller.CharacterData = {
    Catalogs = _G["AUTOBIOGRAPHER_CATALOGS_CHAR"],
    Events = _G["AUTOBIOGRAPHER_EVENTS_CHAR"],
    Levels = _G["AUTOBIOGRAPHER_LEVELS_CHAR"]
  }
  
  local playerLevel = UnitLevel("player")
  if (Controller.CharacterData.Levels[playerLevel]) == nil then 
    if (playerLevel == 1 and UnitXP("player")) == 0 then
      Controller:AddLevel(playerLevel, time(), 0)
    else 
      Controller:AddLevel(playerLevel)
    end
  end
end

function EM.EventHandlers.COMBAT_LOG_EVENT_UNFILTERED(self)
  local timestamp, event, hideCaster, sourceGuid, sourceName, sourceFlags, sourceRaidFlags, destGuid, destName, destFlags, destRaidflags = CombatLogGetCurrentEventInfo()
  
  if (combatLogDamageEvents[event]) then
    local playerCausedThisEvent = sourceGuid == self.PlayerGuid
    local playerPetCausedThisEvent = sourceGuid == UnitGUID("pet")
    local groupMemberCausedThisEvent = IsUnitGUIDInOurPartyOrRaid(sourceGuid)
    
    local damagerUnitId = FindUnitIdByUnitGUID(sourceGuid)
    if (damagerUnitId ~= nil) then 
      local damagerCatalogUnitId = HelperFunctions.GetCatalogIdFromGuid(sourceGuid)
      if (Controller:CatalogUnitIsIncomplete(damagerCatalogUnitId)) then
        Controller:UpdateCatalogUnit(CatalogUnit.New(damagerCatalogUnitId, UnitClass(damagerUnitId), UnitClassification(damagerUnitId), UnitCreatureFamily(damagerUnitId), UnitCreatureType(damagerUnitId), UnitName(damagerUnitId), UnitRace(damagerUnitId)))
      end
    end
    
    local damagedUnitId = FindUnitIdByUnitGUID(destGuid)
    local unitWasOutOfCombat = nil
    if (damagedUnitId ~= nil) then 
      unitWasOutOfCombat = not UnitAffectingCombat(damagedUnitId)
      
      local damagedCatalogUnitId = HelperFunctions.GetCatalogIdFromGuid(destGuid)
      if (Controller:CatalogUnitIsIncomplete(damagedCatalogUnitId)) then
        Controller:UpdateCatalogUnit(CatalogUnit.New(damagedCatalogUnitId, UnitClass(damagedUnitId), UnitClassification(damagedUnitId), UnitCreatureFamily(damagedUnitId), UnitCreatureType(damagedUnitId), UnitName(damagedUnitId), UnitRace(damagedUnitId)))
      end
    end
    
    if (damagedUnits[destGuid] == nil or unitWasOutOfCombat) then   
      local firstObservedDamageCausedByPlayerOrGroup = playerCausedThisEvent or playerPetCausedThisEvent or groupMemberCausedThisEvent
      
      damagedUnits[destGuid] = {
        FirstObservedDamageCausedByPlayerOrGroup = firstObservedDamageCausedByPlayerOrGroup,
        GroupHasDamaged = nil,
        IsTapDenied = nil,
        LastUnitGuidWhoCausedDamage = nil,
        PlayerHasDamaged = nil,
        PlayerPetHasDamaged = nil
      }
    else
      if (damagedUnitId ~= nil) then
        damagedUnits[destGuid].IsTapDenied = UnitIsTapDenied(damagedUnitId)
        --print(destName .. " (" .. damagedUnitId .. ") tap denied: " .. tostring(damagedUnits[destGuid].IsTapDenied))
      end
    end
    
    local damagedUnit = damagedUnits[destGuid]
    
    if (playerCausedThisEvent) then damagedUnit.PlayerHasDamaged = true
    elseif (playerPetCausedThisEvent) then damagedUnit.PlayerPetHasDamaged = true
    elseif (groupMemberCausedThisEvent) then damagedUnit.GroupHasDamaged = true
    end
    
    damagedUnit.LastUnitGuidWhoCausedDamage = sourceGuid
    
    if (destGuid == self.PlayerGuid) then damagedUnit.LastCombatDamageTakenTimestamp = time() end
  end

  if (event ~= "UNIT_DIED") then return end
  if (damagedUnits[destGuid] == nil) then return end
  
  local deadUnit = damagedUnits[destGuid]

  local weHadTag = false
  if (deadUnit.IsTapDenied) then
    weHadTag = false
  elseif (deadUnit.IsTapDenied ~= nil and not deadUnit.IsTapDenied and (deadUnit.PlayerHasDamaged or deadUnit.PlayerPetHasDamaged or deadUnit.GroupHasDamaged)) then
    weHadTag = true
  else
    weHadTag = deadUnit.FirstObservedDamageCausedByPlayerOrGroup
  end
  
  if (deadUnit.PlayerHasDamaged or deadUnit.PlayerPetHasDamaged or weHadTag) then
    print (destName .. " Died.  Tagged: " .. tostring(weHadTag) .. ". FODCBPOG: " .. tostring(deadUnit.FirstObservedDamageCausedByPlayerOrGroup) .. ". ITD: "  .. tostring(deadUnit.IsTapDenied) .. ". PHD: " .. tostring(deadUnit.PlayerHasDamaged) .. ". PPHD: " .. tostring(deadUnit.PlayerPetHasDamaged).. ". GHD: "  .. tostring(deadUnit.GroupHasDamaged)  .. ". LastDmg: " .. tostring(deadUnit.LastUnitGuidWhoCausedDamage))
    local kill = Kill.New(deadUnit.GroupHasDamaged, deadUnit.PlayerHasDamaged or deadUnit.PlayerPetHasDamaged, IsUnitGUIDPlayerOrPlayerPet(deadUnit.LastUnitGuidWhoCausedDamage), weHadTag, HelperFunctions.GetCatalogIdFromGuid(destGuid))
    Controller:AddKill(kill, time(), HelperFunctions.GetCoordinatesByUnitId("player"))
  end
  
  if (destGuid ~= self.PlayerGuid) then damagedUnits[destGuid] = nil end
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
    Controller:AddLevel(self.NewLevelToAddToHistory, time(), totalTimePlayed, HelperFunctions.GetCoordinatesByUnitId("player"))
    self.NewLevelToAddToHistory = nil
  end
end

function EM.EventHandlers.PLAYER_DEAD(self)
  local killerCatalogUnitId = nil
  local killerLevel = nil
  if (damagedUnits[self.PlayerGuid] ~= nil) then
    if (damagedUnits[self.PlayerGuid].LastCombatDamageTakenTimestamp ~= nil and time() - damagedUnits[self.PlayerGuid].LastCombatDamageTakenTimestamp < 5) then
      killerCatalogUnitId = HelperFunctions.GetCatalogIdFromGuid(damagedUnits[self.PlayerGuid].LastUnitGuidWhoCausedDamage)
      
      local killerUnitId = FindUnitIdByUnitGUID(damagedUnits[self.PlayerGuid].LastUnitGuidWhoCausedDamage)
      if (killerUnitId ~= nil) then killerLevel = UnitLevel(killerUnitId) end
    end
  end
  
  Controller:PlayerDied(time(), HelperFunctions.GetCoordinatesByUnitId("player"), killerCatalogUnitId, killerLevel)
end

function EM.EventHandlers.PLAYER_REGEN_DISABLED(self)
  --print("PLAYER_REGEN_DISABLED.")
  --if (UnitAffectingCombat("player")) then print("Player entered combat.") end
end

function EM.EventHandlers.PLAYER_REGEN_ENABLED(self)
  --print("PLAYER_REGEN_ENABLED.")
  --if (not UnitAffectingCombat("player")) then print("Player left combat.") end
end

function EM.EventHandlers.QUEST_TURNED_IN(self, questId, xpGained, moneyGained, arg4,arg5, arg6)
  Controller:QuestTurnedIn(time(), HelperFunctions.GetCoordinatesByUnitId("player"), questId, C_QuestLog.GetQuestInfo(questId), xpGained, moneyGained)
end

function EM.EventHandlers.UNIT_COMBAT(self, unitId, action, ind, dmg, dmgType)
  --print(unitId .. ". " .. action .. ". " .. ind .. ". " .. dmg .. ". " .. dmgType)
end

function EM.EventHandlers.UNIT_FLAGS(self, unitId)
  --print("UNIT_FLAGS. " .. unitId)
end

function EM.EventHandlers.UNIT_HEALTH(self, unitId)
  --print(unitId .. ". " .. tostring(UnitIsTapDenied(unitId)))
end

function EM.EventHandlers.UNIT_TARGET(self, unitId)
  --print ("UNIT_TARGET. " .. unitId .. ": " .. tostring(UnitGUID(unitId .. "target")))
end

-- Register each event for which we have an event handler.
EM.Frame = CreateFrame("Frame")
for eventName,_ in pairs(EM.EventHandlers) do
	EM.Frame:RegisterEvent(eventName)
end
EM.Frame:SetScript("OnEvent", function(_, event, ...) EM:OnEvent(_, event, ...) end)

-- Test function.
function EM:Clear() 
  _G["AUTOBIOGRAPHER_CATALOGS_CHAR"] = nil
  _G["AUTOBIOGRAPHER_EVENTS_CHAR"] = nil
  _G["AUTOBIOGRAPHER_LEVELS_CHAR"] = nil
  print("Data cleared. Please reload ui.")
end

function EM:Test()
  local unitGuid = UnitGUID("target")
  --print(UnitIsTapDenied("target"))
  --print(UnitAffectingCombat("target"))
  --print(CanLootUnit(unitGuid)) -- hasLoot always false when called in UNIT_DIED combat log event
  --print(UnitAffectingCombat("target"))
  --print(HelperFunctions.PrintKeysAndValuesFromTable(validUnitIds))
  --print(UnitReaction("target", "player"))
  

  --print(UnitLevel("target")) -- death
  local mapID = C_Map.GetBestMapForUnit("player")
  HelperFunctions.PrintKeysAndValuesFromTable(C_Map.GetMapInfo(mapID))
  HelperFunctions.PrintKeysAndValuesFromTable(HelperFunctions.GetCoordinatesByUnitId("player"))
  
  print(GetZoneText())
  print(GetSubZoneText())
  print(GetRealZoneText())
end