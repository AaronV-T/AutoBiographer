AutoBiographer_Settings = nil

EventManager = {
  EventHandlers = {},
  LastPlayerMoney = nil,
  NewLevelToAddToHistory = nil,
  PersistentPlayerInfo = nil,
  PlayerFlags = {
    AffectingCombat = nil,
    Afk = nil,
    IsDeadOrGhost = nil,
    OnTaxi = nil
  },
  Timestamps = {
    Died = nil,
    EnteredArea = nil,
    EnteredCombat = nil,
    EnteredTaxi = nil,
    MarkedAfk = nil,
  },
  ZoneChangedNewAreaEventHasFired = false
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

  if (time() > 1567123200) then 
    message("You are using an alpha version of AutoBiographer. Please update to the latest version.")
  end
  
  if type(_G["AUTOBIOGRAPHER_SETTINGS"]) ~= "table" then
		_G["AUTOBIOGRAPHER_SETTINGS"] = {
      MinimapPos = 45,
    }
	end
  
  AutoBiographer_Settings = _G["AUTOBIOGRAPHER_SETTINGS"]
 
  if type(_G["AUTOBIOGRAPHER_CATALOGS_CHAR"]) ~= "table" then
		_G["AUTOBIOGRAPHER_CATALOGS_CHAR"] = Catalogs.New()
	end
  if type(_G["AUTOBIOGRAPHER_EVENTS_CHAR"]) ~= "table" then
		_G["AUTOBIOGRAPHER_EVENTS_CHAR"] = {}
	end
  if type(_G["AUTOBIOGRAPHER_LEVELS_CHAR"]) ~= "table" then
		_G["AUTOBIOGRAPHER_LEVELS_CHAR"] = {}
	end
  if type(_G["AUTOBIOGRAPHER_TEMP_CHAR"]) ~= "table" then
		_G["AUTOBIOGRAPHER_TEMP_CHAR"] = {
      CurrentSubZone = nil,
      CurrentZone = nil,
    }
	end
  
	Controller.CharacterData = {
    Catalogs = _G["AUTOBIOGRAPHER_CATALOGS_CHAR"],
    Events = _G["AUTOBIOGRAPHER_EVENTS_CHAR"],
    Levels = _G["AUTOBIOGRAPHER_LEVELS_CHAR"]
  }
  
  self.PersistentPlayerInfo = _G["AUTOBIOGRAPHER_TEMP_CHAR"]
  
  local playerLevel = UnitLevel("player")
  if (Controller.CharacterData.Levels[playerLevel]) == nil then 
    if (playerLevel == 1 and UnitXP("player")) == 0 then
      Controller:OnLevelUp(time(), nil, playerLevel, 0)
    else 
      Controller:OnLevelUp(nil, nil, playerLevel)
    end
  end
  
  AutoBiographer_MinimapButton_Reposition()
end

function EM.EventHandlers.BOSS_KILL(self, bossId, bossName)
  Controller:OnBossKill(time(), HelperFunctions.GetCoordinatesByUnitId("player"), bossId, bossName)
end

function EM.EventHandlers.CHAT_MSG_MONEY(self, text, arg2, arg3, arg4, arg5)
  local moneySum = 0
  
  for copperText in string.gmatch(text, "%d+%sCopper") do
    local i = 1
    for word in string.gmatch(copperText, "%S+") do
      if (i == 1) then moneySum = tonumber(word) end
      i = i + 1
    end
  end
  
  for silverText in string.gmatch(text, "%d+%sSilver") do
    local i = 1
    for word in string.gmatch(silverText, "%S+") do
      if (i == 1) then moneySum = moneySum + tonumber(word) * 100 end
      i = i + 1
    end
  end
  
  for goldText in string.gmatch(text, "%d+%sGold") do
    local i = 1
    for word in string.gmatch(goldText, "%S+") do
      if (i == 1) then moneySum = moneySum + tonumber(word) * 10000 end
      i = i + 1
    end
  end
  
  Controller:OnLootMoney(time(), HelperFunctions.GetCoordinatesByUnitId("player"), moneySum)
end

function EM.EventHandlers.COMBAT_LOG_EVENT_UNFILTERED(self)
  local timestamp, event, hideCaster, sourceGuid, sourceName, sourceFlags, sourceRaidFlags, destGuid, destName, destFlags, destRaidflags = CombatLogGetCurrentEventInfo()

  if (combatLogDamageEvents[event]) then
    local playerCausedThisEvent = sourceGuid == self.PlayerGuid
    local playerPetCausedThisEvent = sourceGuid == UnitGUID("pet")
    local groupMemberCausedThisEvent = IsUnitGUIDInOurPartyOrRaid(sourceGuid)
    
    -- Get UnitIds of damager and damaged unit.
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
    
    -- Process event's damage amount.
    if (playerCausedThisEvent or destGuid == self.PlayerGuid) then
      if (string.find(event, "SWING") == 1) then
        amount, overKill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand = select(12, CombatLogGetCurrentEventInfo())
      elseif (string.find(event, "SPELL") == 1) then
        spellId, spellName, spellSchool, amount, overKill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand = select(12, CombatLogGetCurrentEventInfo())
      end
      
      if (amount) then 
        if (not overKill or overKill == -1) then overKill = 0 end
        
        if (playerCausedThisEvent) then Controller:OnDamageDealt(amount, overKill) 
        elseif (destGuid == self.PlayerGuid) then Controller:OnDamageTaken(amount, overKill) 
        end
      end
      --print(event .. ": " .. tostring(amount) .. ". Over: " .. overKill)
    end
    
    -- Set damage flags.
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
        --Controller:AddLog(destName .. " (" .. damagedUnitId .. ") tap denied: " .. tostring(damagedUnits[destGuid].IsTapDenied), AutoBiographerEnum.LogLevel.Verbose)
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
    Controller:AddLog(destName .. " Died.  Tagged: " .. tostring(weHadTag) .. ". FODCBPOG: " .. tostring(deadUnit.FirstObservedDamageCausedByPlayerOrGroup) .. ". ITD: "  .. tostring(deadUnit.IsTapDenied) .. ". PHD: " .. tostring(deadUnit.PlayerHasDamaged) .. ". PPHD: " .. tostring(deadUnit.PlayerPetHasDamaged).. ". GHD: "  .. tostring(deadUnit.GroupHasDamaged)  .. ". LastDmg: " .. tostring(deadUnit.LastUnitGuidWhoCausedDamage), AutoBiographerEnum.LogLevel.Debug)
    local kill = Kill.New(deadUnit.GroupHasDamaged, deadUnit.PlayerHasDamaged or deadUnit.PlayerPetHasDamaged, IsUnitGUIDPlayerOrPlayerPet(deadUnit.LastUnitGuidWhoCausedDamage), weHadTag, HelperFunctions.GetCatalogIdFromGuid(destGuid))
    Controller:OnKill(time(), HelperFunctions.GetCoordinatesByUnitId("player"), kill)
  end
  
  if (destGuid ~= self.PlayerGuid) then damagedUnits[destGuid] = nil end
end

function EM.EventHandlers.LEARNED_SPELL_IN_TAB(self, spellId, skillInfoIndex, isGuildPerkSpell)
  local name, rank, icon, castTime, minRange, maxRange, id = GetSpellInfo(spellId)
  Controller:OnSpellLearned(time(), HelperFunctions.GetCoordinatesByUnitId("player"), spellId, name, rank)
end

function EM.EventHandlers.PLAYER_ALIVE(self) -- Fired when the player releases from death to a graveyard; or accepts a resurrect before releasing their spirit. Also fires when logging in.
  -- Upon logging in this event fires before ZONE_CHANGED_NEW_AREA and GeaRealZoneText() returns the zone of the last character logged in (or nil if you haven't logged into any other characters since launching WoW).
  if (self.ZoneChangedNewAreaEventHasFired) then self:UpdatePlayerZone() end
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
  
  Controller:OnDeath(time(), HelperFunctions.GetCoordinatesByUnitId("player"), killerCatalogUnitId, killerLevel)
end

function EM.EventHandlers.PLAYER_FLAGS_CHANGED(self, unitId, arg2, arg3, arg4, arg5)
  if (unitId == "player") then self:UpdatePlayerFlags() end
  --print("PLAYER_FLAGS_CHANGED. " .. tostring(arg1) .. ", " .. tostring(arg2) .. ", " .. tostring(arg3) .. ", " .. tostring(arg4) .. ", " .. tostring(arg5))
end

function EM.EventHandlers.PLAYER_GUILD_UPDATE(self, arg1, arg2, arg3, arg4, arg5)
  print("PLAYER_GUILD_UPDATE. " .. tostring(arg1) .. ", " .. tostring(arg2) .. ", " .. tostring(arg3) .. ", " .. tostring(arg4) .. ", " .. tostring(arg5))
end

function EM.EventHandlers.PLAYER_LEVEL_UP(self, newLevel, ...)
  self.NewLevelToAddToHistory = newLevel
  
  RequestTimePlayed()
end

function EM.EventHandlers.PLAYER_LOGIN(self)
  self.PlayerGuid = UnitGUID("player") -- Player GUID Format: Player-[server ID]-[player UID]
  
  self.LastPlayerMoney = GetMoney()
  self.Timestamps.EnteredArea = time()
  self:UpdatePlayerFlags()
end

function EM.EventHandlers.PLAYER_LOGOUT(self)
  self:UpdateTimestamps()
  print("Plo")
end

function EM.EventHandlers.PLAYER_MONEY(self)
  local currentMoney = GetMoney()
  Controller:OnMoneyChanged(time(), HelperFunctions.GetCoordinatesByUnitId("player"), currentMoney - self.LastPlayerMoney)
  self.LastPlayerMoney = currentMoney
end

function EM.EventHandlers.PLAYER_UNGHOST(self) -- Fired when the player is alive after being a ghost.
  self:UpdatePlayerZone()
end

function EM.EventHandlers.QUEST_TURNED_IN(self, questId, xpGained, moneyGained, arg4,arg5, arg6)
  Controller:OnQuestTurnedIn(time(), HelperFunctions.GetCoordinatesByUnitId("player"), questId, C_QuestLog.GetQuestInfo(questId), xpGained, moneyGained)
end

function EM.EventHandlers.TIME_PLAYED_MSG(self, totalTimePlayed, levelTimePlayed) 
  if self.NewLevelToAddToHistory ~= nil then
    Controller:OnLevelUp(time(), HelperFunctions.GetCoordinatesByUnitId("player"), self.NewLevelToAddToHistory, totalTimePlayed)
    self.NewLevelToAddToHistory = nil
  end
end

function EM.EventHandlers.UNIT_COMBAT(self, unitId, action, ind, dmg, dmgType)
  --print(unitId .. ". " .. action .. ". " .. ind .. ". " .. dmg .. ". " .. dmgType)
end

function EM.EventHandlers.UNIT_FLAGS(self, unitId)
  --print("UNIT_FLAGS. " .. unitId)
  if (unitId == "player") then self:UpdatePlayerFlags() end
end

function EM.EventHandlers.UNIT_HEALTH(self, unitId)
  --print(unitId .. ". " .. tostring(UnitIsTapDenied(unitId)))
end

function EM.EventHandlers.UNIT_SPELLCAST_CHANNEL_START(self, unitId, arg2, arg3, arg4, arg5)
  --print("UNIT_SPELLCAST_CHANNEL_START. " .. unitId .. ", " .. tostring(arg2) .. ", " .. tostring(arg3) .. ", " .. tostring(arg4) .. ", " .. tostring(arg5))
end

function EM.EventHandlers.UNIT_SPELLCAST_CHANNEL_STOP(self, unitId, arg2, arg3, arg4, arg5)
  --print("UNIT_SPELLCAST_CHANNEL_STOP. " .. unitId .. ", " .. tostring(arg2) .. ", " .. tostring(arg3) .. ", " .. tostring(arg4) .. ", " .. tostring(arg5))
end

function EM.EventHandlers.UNIT_SPELLCAST_FAILED(self, unitId, arg2, arg3, arg4, arg5)
  --print("UNIT_SPELLCAST_FAILED. " .. unitId .. ", " .. tostring(arg2) .. ", " .. tostring(arg3) .. ", " .. tostring(arg4) .. ", " .. tostring(arg5))
end

function EM.EventHandlers.UNIT_SPELLCAST_FAILED_QUIET(self, unitId, arg2, arg3, arg4, arg5)
  --print("UNIT_SPELLCAST_FAILED_QUIET. " .. unitId .. ", " .. tostring(arg2) .. ", " .. tostring(arg3) .. ", " .. tostring(arg4) .. ", " .. tostring(arg5))
end

function EM.EventHandlers.UNIT_SPELLCAST_INTERRUPTED(self, unitId, arg2, arg3, arg4, arg5)
  --print("UNIT_SPELLCAST_INTERRUPTED. " .. unitId .. ", " .. tostring(arg2) .. ", " .. tostring(arg3) .. ", " .. tostring(arg4) .. ", " .. tostring(arg5))
end

function EM.EventHandlers.UNIT_SPELLCAST_START(self, unitId, arg2, arg3, arg4, arg5)
  --print("UNIT_SPELLCAST_START. " .. unitId .. ", " .. tostring(arg2) .. ", " .. tostring(arg3) .. ", " .. tostring(arg4) .. ", " .. tostring(arg5))
end

function EM.EventHandlers.UNIT_SPELLCAST_STOP(self, unitId, arg2, arg3, arg4, arg5)
  --print("UNIT_SPELLCAST_STOP. " .. unitId .. ", " .. tostring(arg2) .. ", " .. tostring(arg3) .. ", " .. tostring(arg4) .. ", " .. tostring(arg5))
end

function EM.EventHandlers.UNIT_SPELLCAST_SUCCEEDED(self, unitId, arg2, arg3, arg4, arg5)
  --print("UNIT_SPELLCAST_SUCCEEDED. " .. unitId .. ", " .. tostring(arg2) .. ", " .. tostring(arg3) .. ", " .. tostring(arg4) .. ", " .. tostring(arg5))
end

function EM.EventHandlers.UNIT_TARGET(self, unitId)
  
end

function EM.EventHandlers.UPDATE_MOUSEOVER_UNIT(self)
  --if UnitIsPlayer("mouseover") then return end
	local catalogUnitId = HelperFunctions.GetCatalogIdFromGuid(UnitGUID("mouseover"))
	if not catalogUnitId then return end
	if UnitCanAttack("player", "mouseover") then
		GameTooltip:AddLine("Killed " .. tostring(Controller:GetTaggedKillsByCatalogUnitId(catalogUnitId)) .. " times.")
	end

	GameTooltip:Show()
end
function EM.EventHandlers.ZONE_CHANGED(self)
  self:UpdatePlayerZone()
end

function EM.EventHandlers.ZONE_CHANGED_INDOORS(self)
  self:UpdatePlayerZone()
end

function EM.EventHandlers.ZONE_CHANGED_NEW_AREA(self)
  if (not self.ZoneChangedNewAreaEventHasFired) then
    self.ZoneChangedNewAreaEventHasFired = true
  end 
  
  self:UpdatePlayerZone()
end

-- *** Miscellaneous Member Functions ***
 
function EM:UpdatePlayerFlags()
  -- 
  local playerWasAffectingCombat = self.PlayerFlags.AffectingCombat
  self.PlayerFlags.AffectingCombat = UnitAffectingCombat("player")
  
  local playerWasAfk = self.PlayerFlags.Afk
  self.PlayerFlags.Afk = UnitIsAFK("player")
  
  local playerWasDeadOrGhost = self.PlayerFlags.IsDeadOrGhost
  self.PlayerFlags.IsDeadOrGhost = UnitIsDeadOrGhost("player")
  
  local playerWasOnTaxi = self.PlayerFlags.OnTaxi
  self.PlayerFlags.OnTaxi = UnitOnTaxi("player")
  
  -- Special 
  if (playerWasAffectingCombat and not self.PlayerFlags.AffectingCombat) then
    -- Player left combat.
    if (EM.Timestamps.EnteredCombat) then
      Controller:AddTime(AutoBiographerEnum.TimeTrackingType.InCombat, time() - EM.Timestamps.EnteredCombat, self.PersistentPlayerInfo.CurrentZone, self.PersistentPlayerInfo.CurrentSubZone)
    else
      Controller:AddLog("Player left combat but there was no timestamp for entering combat.", AutoBiographerEnum.LogLevel.Warning)
    end
    EM.Timestamps.EnteredCombat = nil
  elseif (not playerWasAffectingCombat and self.PlayerFlags.AffectingCombat) then
    -- Player entered combat or was in combat after loading UI.
    EM.Timestamps.EnteredCombat = time()
  end
  
  if (playerWasAfk and not self.PlayerFlags.Afk) then 
    -- Player cleared AFK.
    if (EM.Timestamps.MarkedAfk) then
      Controller:AddTime(AutoBiographerEnum.TimeTrackingType.Afk, time() - EM.Timestamps.MarkedAfk, self.PersistentPlayerInfo.CurrentZone, self.PersistentPlayerInfo.CurrentSubZone)
    else
      Controller:AddLog("Player left AFK but there was no timestamp for entering AFK.", AutoBiographerEnum.LogLevel.Warning)
    end
    EM.Timestamps.MarkedAfk = nil
  elseif (not playerWasAfk and self.PlayerFlags.Afk) then 
    -- Player marked AFK or was AFK after loading UI.
    EM.Timestamps.MarkedAfk = time()
  end
  
  if (playerWasDeadOrGhost and not self.PlayerFlags.IsDeadOrGhost) then 
    -- Player revived.
    if (EM.Timestamps.Died) then
      Controller:AddTime(AutoBiographerEnum.TimeTrackingType.DeadOrGhost, time() - EM.Timestamps.Died, self.PersistentPlayerInfo.CurrentZone, self.PersistentPlayerInfo.CurrentSubZone)
    else
      Controller:AddLog("Player revived but there was no timestamp for dieing.", AutoBiographerEnum.LogLevel.Warning)
    end
    EM.Timestamps.Died = nil
  elseif (not playerWasDeadOrGhost and self.PlayerFlags.IsDeadOrGhost) then 
    -- Player died or was dead after loading UI
    EM.Timestamps.Died = time()
  end
  
  if (playerWasOnTaxi and not self.PlayerFlags.OnTaxi) then
    -- Player left taxi.
    if (EM.Timestamps.EnteredTaxi) then
      Controller:AddTime(AutoBiographerEnum.TimeTrackingType.OnTaxi, time() - EM.Timestamps.EnteredTaxi, self.PersistentPlayerInfo.CurrentZone, self.PersistentPlayerInfo.CurrentSubZone)
    else
      Controller:AddLog("Player left taxi but there was no timestamp for entering taxi.", AutoBiographerEnum.LogLevel.Warning)
    end
    EM.Timestamps.EnteredTaxi = nil
    
    self:UpdatePlayerZone()
  elseif (not playerWasOnTaxi and self.PlayerFlags.OnTaxi) then
    -- Player entered taxi or was on taxi after loading UI.
    EM.Timestamps.EnteredTaxi = time()
  end
end

function EM:UpdatePlayerZone()
  if (UnitIsDeadOrGhost("player") or UnitOnTaxi("player")) then return end
  
  local previousSubZone = self.PersistentPlayerInfo.CurrentSubZone
  self.PersistentPlayerInfo.CurrentSubZone = GetSubZoneText()
  
  local previousZone = self.PersistentPlayerInfo.CurrentZone
  self.PersistentPlayerInfo.CurrentZone = GetRealZoneText()
  
  if (previousSubZone ~= self.PersistentPlayerInfo.CurrentSubZone or previousZone ~= self.PersistentPlayerInfo.CurrentZone) then
    self.UpdateTimestamps(previousZone, previousSubZone)
  end
  
  Controller:OnChangedZone(time(), HelperFunctions.GetCoordinatesByUnitId("player"), self.PersistentPlayerInfo.CurrentZone)
  Controller:OnChangedSubZone(time(), HelperFunctions.GetCoordinatesByUnitId("player"), self.PersistentPlayerInfo.CurrentZone, self.PersistentPlayerInfo.CurrentSubZone)
end

function EM:UpdateTimestamps(zone, subZone)
  -- Afk
  if (EM.Timestamps.MarkedAfk) then
    Controller:AddTime(AutoBiographerEnum.TimeTrackingType.Afk, time() - EM.Timestamps.MarkedAfk, zone, subZone)
    EM.Timestamps.MarkedAfk = time()
  end
  
  -- DeadOrGhost
  if (EM.Timestamps.Died) then
    Controller:AddTime(AutoBiographerEnum.TimeTrackingType.DeadOrGhost, time() - EM.Timestamps.Died, zone, subZone)
    EM.Timestamps.DeadOrGhost = time()
  end
  
  -- In Combat
  if (EM.Timestamps.EnteredCombat) then
    Controller:AddTime(AutoBiographerEnum.TimeTrackingType.InCombat, time() - EM.Timestamps.EnteredCombat, zone, subZone)
    EM.Timestamps.EnteredCombat = time()
  end
  
  -- Logged In
  if (EM.Timestamps.EnteredArea) then
    Controller:AddTime(AutoBiographerEnum.TimeTrackingType.LoggedIn, time() - EM.Timestamps.EnteredArea, zone, subZone)
    EM.Timestamps.EnteredArea = time()
  end
  
  -- On Taxi
  if (EM.Timestamps.EnteredTaxi) then
    Controller:AddTime(AutoBiographerEnum.TimeTrackingType.OnTaxi, time() - EM.Timestamps.EnteredTaxi, zone, subZone)
    EM.Timestamps.EnteredTaxi = time()
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
  _G["AUTOBIOGRAPHER_CATALOGS_CHAR"] = nil
  _G["AUTOBIOGRAPHER_EVENTS_CHAR"] = nil
  _G["AUTOBIOGRAPHER_LEVELS_CHAR"] = nil
  print("Data cleared. Please reload ui.")
end

function EM:Test()
  local unitGuid = UnitGUID("target")
  --print(CanLootUnit(unitGuid)) -- hasLoot always false when called in UNIT_DIED combat log event, have to wait for it to register correctly

  --GetQuestsCompleted() -- lists ids of every completed quest
end