AutoBiographer_Settings = nil

AutoBiographer_EventManager = {
  AuctionHouseIsOpen = nil,
  EventHandlers = {},
  LastPlayerDeadEventTimestamp = nil,
  LastPlayerMoney = nil,
  MailboxIsOpen = nil,
  MailboxMessages = nil,
  MailboxUpdatesRunning = 0,
  MailInboxUpdatedAfterOpen = nil,
  MerchantIsOpen = nil,
  NewLevelToAddToHistory = nil,
  PersistentPlayerInfo = nil,
  PlayerEnteringWorldHasFired = false,
  PlayerName = nil,
  PlayerFlags = {
    AffectingCombat = nil,
    Afk = nil,
    InParty = nil,
    IsDeadOrGhost = nil,
    OnTaxi = nil
  },
  TemporaryTimestamps = { -- These are specifically for time tracking.
    Died = nil,
    EnteredArea = nil,
    EnteredCombat = nil,
    EnteredTaxi = nil,
    JoinedParty = nil,
    MarkedAfk = nil,
    OtherPlayerJoinedGroup = {}, -- Dict<UnitGuid, TempTimestamp>
    StartedCasting = nil,
  },
  TradeInfo = nil,
  ZoneChangedNewAreaEventHasFired = false
}

local EM = AutoBiographer_EventManager
local Controller = AutoBiographer_Controller

-- *** Locals ***

local damagedUnits = {}

local combatLogDamageEvents = { }
local combatLogHealEvents = { }
do
    local damageEventPrefixes = { "RANGE", "SPELL", "SPELL_BUILDING", "SPELL_PERIODIC", "SWING" }
    local damageEventSuffixes = { "DAMAGE", "DRAIN", "INSTAKILL", "LEECH" }
    for _, prefix in pairs(damageEventPrefixes) do
        for _, suffix in pairs(damageEventSuffixes) do
            combatLogDamageEvents[prefix .. "_" .. suffix] = true
        end
    end
end
do
    local healEventPrefixes = { "SPELL", "SPELL_PERIODIC" }
    local healEventSuffixes = { "HEAL" }
    for _, prefix in pairs(healEventPrefixes) do
        for _, suffix in pairs(healEventSuffixes) do
            combatLogHealEvents[prefix .. "_" .. suffix] = true
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

local function FindUnitGUIDByUnitName(unitName)
	for i = 1, #validUnitIds do
    if (UnitName(validUnitIds[i]) == unitName) then return UnitGUID(validUnitIds[i]) end
	end
	return nil
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
  
  if type(_G["AUTOBIOGRAPHER_SETTINGS"]) ~= "table" then
		_G["AUTOBIOGRAPHER_SETTINGS"] = {
      EventDisplayFilters = {}, -- Dict<EventSubType, bool>
      MinimapPos = -25,
      Options = { -- Dict<string?, bool>
        EnableDebugLogging = false,
        ShowKillCountOnUnitToolTips = true,
        ShowMinimapButton = true,
        ShowTimePlayedOnLevelUp = true,
        TakeScreenshotOnBossKill = true,
        TakeScreenshotOnLevelUp = true,
        TakeScreenshotOnlyOnFirstBossKill = true,
      }, 
    }
    for k,v in pairs(AutoBiographerEnum.EventSubType) do
      _G["AUTOBIOGRAPHER_SETTINGS"].EventDisplayFilters[v] = true
    end
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
  
  Controller.CharacterData = {
    Catalogs = _G["AUTOBIOGRAPHER_CATALOGS_CHAR"],
    Events = _G["AUTOBIOGRAPHER_EVENTS_CHAR"],
    Levels = _G["AUTOBIOGRAPHER_LEVELS_CHAR"]
  }
  
  if type(_G["AUTOBIOGRAPHER_INFO_CHAR"]) ~= "table" then
		_G["AUTOBIOGRAPHER_INFO_CHAR"] = {
      BattlegroundStatuses = {},
      CurrentSubZone = nil,
      CurrentZone = nil,
      DatabaseVersion = 7,
      GuildName = nil,
      GuildRankIndex = nil,
      GuildRankName = nil,
      PlayerGuid = nil,
    }
	end
  
  self.PersistentPlayerInfo = _G["AUTOBIOGRAPHER_INFO_CHAR"]
  
  -- Database Migrations
  if (not self.PersistentPlayerInfo.DatabaseVersion or self.PersistentPlayerInfo.DatabaseVersion < AutoBiographer_MigrationManager:GetLatestDatabaseVersion()) then
    AutoBiographer_MigrationManager:RunMigrations(self.PersistentPlayerInfo.DatabaseVersion, EM, Controller)
  end
  
  --
  local playerLevel = UnitLevel("player")
  if (not Controller.CharacterData.Levels[playerLevel]) then 
    if (playerLevel == 1 and UnitXP("player") == 0) then
      Controller:OnLevelUp(time(), nil, playerLevel, 0)
    else 
      Controller:OnLevelUp(nil, nil, playerLevel)
    end
  end
  
  AutoBiographer_MinimapButton_Reposition()
  if (AutoBiographer_Settings.Options["ShowMinimapButton"] == false) then AutoBiographer_MinimapButton:Hide()
  else AutoBiographer_MinimapButton:Show() end
  
  AutoBiographer_OptionWindow:Initialize()
end

function EM.EventHandlers.BOSS_KILL(self, bossId, bossName)
  local hasKilledBossBefore = true
  if (not Catalogs.PlayerHasKilledBoss(Controller.CharacterData.Catalogs, bossId)) then
    hasKilledBossBefore = false
    Controller:UpdateCatalogBoss(CatalogBoss.New(bossId, bossName, true))
  end

  Controller:OnBossKill(time(), HelperFunctions.GetCoordinatesByUnitId("player"), bossId, bossName, hasKilledBossBefore)
end

function EM.EventHandlers.AUCTION_HOUSE_CLOSED(self, arg1, arg2)
  self.AuctionHouseIsOpen = false
end

function EM.EventHandlers.AUCTION_HOUSE_SHOW(self, arg1, arg2)
  self.AuctionHouseIsOpen = true
end

function EM.EventHandlers.CHAT_MSG_COMBAT_XP_GAIN(self, text)
  local mobName, xpGainedFromKill = string.match(text, "(.+) dies, you gain (%d+) experience")
  local xpGainedFromGroupBonus = string.match(text, "+(%d+) group bonus")
  local xpGainedFromRestedBonus = string.match(text, "+(%d+) exp Rested bonus")
  local xpLostToRaidPenalty = string.match(text, "-(%d+) raid penalty")
  
  if (xpGainedFromKill) then Controller:OnGainedExperience(time(), HelperFunctions.GetCoordinatesByUnitId("player"), AutoBiographerEnum.ExperienceTrackingType.Kill, tonumber(xpGainedFromKill)) end
  if (xpGainedFromGroupBonus) then Controller:OnGainedExperience(time(), HelperFunctions.GetCoordinatesByUnitId("player"), AutoBiographerEnum.ExperienceTrackingType.GroupBonus, tonumber(xpGainedFromGroupBonus)) end
  if (xpGainedFromRestedBonus) then Controller:OnGainedExperience(time(), HelperFunctions.GetCoordinatesByUnitId("player"), AutoBiographerEnum.ExperienceTrackingType.RestedBonus, tonumber(xpGainedFromRestedBonus)) end
  if (xpLostToRaidPenalty) then Controller:OnGainedExperience(time(), HelperFunctions.GetCoordinatesByUnitId("player"), AutoBiographerEnum.ExperienceTrackingType.RaidPenalty, tonumber(xpLostToRaidPenalty)) end
end

function EM.EventHandlers.CHAT_MSG_LOOT(self, text, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21)
  if (string.find(text, "You") ~= 1) then return end
  
  local itemAcquisitionMethod = nil
  if (string.find(text, "You create") == 1) then
    itemAcquisitionMethod = AutoBiographerEnum.ItemAcquisitionMethod.Create
  elseif (string.find(text, "You receive loot") == 1) then
    itemAcquisitionMethod = AutoBiographerEnum.ItemAcquisitionMethod.Loot
  else
    itemAcquisitionMethod = AutoBiographerEnum.ItemAcquisitionMethod.Other
  end
  
  local id = nil
  for idMatch in string.gmatch(text, "item:%d+") do
    id = string.sub(idMatch, 6, #idMatch)
  end
  
  if (not id) then 
    Controller:AddLog("Unable to get itemId from text: '" .. text .. "'.", AutoBiographerEnum.LogLevel.Warning)
    return
  end

  local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemIcon, itemSellPrice, itemClassID, itemSubClassID, bindType, expacID, itemSetID, isCraftingReagent = GetItemInfo(id)
  if (not itemName) then
    for nameMatch in string.gmatch(text, "%[%.+%]") do
      itemName = string.sub(nameMatch, 2, #nameMatch - 1)
    end
  end
  
  local catalogItem = CatalogItem.New(id, itemName, itemRarity, itemLevel, itemType, itemSubType, nil)

  if (Controller:CatalogItemIsIncomplete(catalogItem.Id)) then
    Controller:UpdateCatalogItem(catalogItem)
  end
  
  local quantity = 1
  for quantityText in string.gmatch(text, "x%d+.") do
    quantity = tonumber(string.sub(quantityText, 2, #quantityText - 1))
  end
  
  Controller:OnAcquiredItem(time(), HelperFunctions.GetCoordinatesByUnitId("player"), itemAcquisitionMethod, catalogItem, quantity)
end


function EM.EventHandlers.CHAT_MSG_MONEY(self, text, arg2, arg3, arg4, arg5)
  if (string.find(text, "You") ~= 1) then return end
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
  
  Controller:OnGainedMoney(time(), HelperFunctions.GetCoordinatesByUnitId("player"), AutoBiographerEnum.MoneyAcquisitionMethod.Loot, moneySum)
end

function EM.EventHandlers.CHAT_MSG_SKILL(self, text)
  if (string.find(text, "Your skill in") ~= 1) then return end
  
  local skillName = nil
  local skillLevel = nil
  local index = 1
  for word in string.gmatch(text, "%w+") do
    if (index == 4) then skillName = word end
    if (index == 8) then skillLevel = tonumber(word) end
    index = index + 1
  end
  
  if (skillName and skillLevel) then
    Controller:OnSkillLevelIncreased(time(), HelperFunctions.GetCoordinatesByUnitId("player"), skillName, skillLevel)
  end
end

function EM.EventHandlers.CHAT_MSG_SYSTEM(self, text)
  if (not self.PlayerEnteringWorldHasFired) then return end

  if (string.find(text, self.PlayerName .. " has defeated %w+ in a duel") == 1 or string.find(text, "%w+ has fled from " .. self.PlayerName .. " in a duel") == 1) then
    -- Player won a duel.
    local splitText = HelperFunctions.SplitString(text)
    local defeatedPlayerName = nil
    if (string.find(text, "defeated")) then defeatedPlayerName = splitText[4]
    else defeatedPlayerName = splitText[1] end
    
    Controller:OnDuelWon(time(), HelperFunctions.GetCoordinatesByUnitId("player"), HelperFunctions.GetCatalogIdFromGuid(FindUnitGUIDByUnitName(defeatedPlayerName)), defeatedPlayerName)
  elseif (string.find(text, "%w+ has defeated " .. self.PlayerName .. " in a duel") == 1 or string.find(text, self.PlayerName .. " has fled from %w+ in a duel") == 1) then
    -- Player lost a duel.
    local splitText = HelperFunctions.SplitString(text)
    local winningPlayerName = nil
    if (string.find(text, "defeated")) then winningPlayerName = splitText[1]
    else winningPlayerName = splitText[5] end
    
    Controller:OnDuelLost(time(), HelperFunctions.GetCoordinatesByUnitId("player"), HelperFunctions.GetCatalogIdFromGuid(FindUnitGUIDByUnitName(winningPlayerName)), winningPlayerName)
  elseif (string.find(text, "Discovered .+") == 1) then
    -- Player discovered a new area.
    local area, xpGainedFromDiscovery = string.match(text, "Discovered (.+): (%d+) experience gained")
    
    if (xpGainedFromDiscovery) then Controller:OnGainedExperience(time(), HelperFunctions.GetCoordinatesByUnitId("player"), AutoBiographerEnum.ExperienceTrackingType.Discovery, tonumber(xpGainedFromDiscovery)) end
  elseif (string.find(text, "You are now .+ with .+") == 1) then
    -- Player reached a new reputation level with a faction.
    local reputationLevel, faction = string.match(text, "You are now (.+) with (.+)%.")
    
    if (faction and reputationLevel) then Controller:OnReputationLevelChanged(time(), HelperFunctions.GetCoordinatesByUnitId("player"), faction, reputationLevel) end
  end
end

function EM.EventHandlers.CHAT_MSG_TRADESKILLS(self, text, arg2, arg3, arg4, arg5)
  --if (string.find(text, "You create") ~= 1) then return end
  --print(text)
  --print(arg2)
end

function EM.EventHandlers.COMBAT_LOG_EVENT_UNFILTERED(self)
  local timestamp, event, hideCaster, sourceGuid, sourceName, sourceFlags, sourceRaidFlags, destGuid, destName, destFlags, destRaidflags = CombatLogGetCurrentEventInfo()
  
  if (combatLogDamageEvents[event]) then
    local playerCausedThisEvent = sourceGuid == self.PersistentPlayerInfo.PlayerGuid
    local playerPetCausedThisEvent = sourceGuid == UnitGUID("pet")
    local groupMemberCausedThisEvent = IsUnitGUIDInOurPartyOrRaid(sourceGuid)
    
    -- Get UnitIds of damager and damaged unit.
    local damagerUnitId = FindUnitIdByUnitGUID(sourceGuid)
    if (damagerUnitId ~= nil) then 
      local damagerCatalogUnitId = HelperFunctions.GetCatalogIdFromGuid(sourceGuid)
      if (Controller:CatalogUnitIsIncomplete(damagerCatalogUnitId)) then
        Controller:UpdateCatalogUnit(CatalogUnit.New(damagerCatalogUnitId, UnitClass(damagerUnitId), UnitClassification(damagerUnitId), UnitCreatureFamily(damagerUnitId), UnitCreatureType(damagerUnitId), UnitName(damagerUnitId), UnitRace(damagerUnitId), nil, HelperFunctions.GetUnitTypeFromCatalogUnitId(damagerCatalogUnitId)))
      end
    end
    
    local damagedUnitId = FindUnitIdByUnitGUID(destGuid)
    local unitWasOutOfCombat = nil
    if (damagedUnitId ~= nil) then 
      unitWasOutOfCombat = not UnitAffectingCombat(damagedUnitId)
      
      local damagedCatalogUnitId = HelperFunctions.GetCatalogIdFromGuid(destGuid)
      if (Controller:CatalogUnitIsIncomplete(damagedCatalogUnitId)) then
        Controller:UpdateCatalogUnit(CatalogUnit.New(damagedCatalogUnitId, UnitClass(damagedUnitId), UnitClassification(damagedUnitId), UnitCreatureFamily(damagedUnitId), UnitCreatureType(damagedUnitId), UnitName(damagedUnitId), UnitRace(damagedUnitId), nil, HelperFunctions.GetUnitTypeFromCatalogUnitId(damagedCatalogUnitId)))
      end
    end
    
    -- Process event's damage amount if the damage was dealt or taken by the player or his pet.
    if (playerCausedThisEvent or destGuid == self.PersistentPlayerInfo.PlayerGuid or playerPetCausedThisEvent or destGuid == UnitGUID("pet")) then
      if (string.find(event, "SWING") == 1) then
        amount, overKill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand = select(12, CombatLogGetCurrentEventInfo())
      elseif (string.find(event, "SPELL") == 1) then
        spellId, spellName, spellSchool, amount, overKill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand = select(12, CombatLogGetCurrentEventInfo())
      end
      
      if (amount) then 
        if (not overKill or overKill == -1) then overKill = 0 end
        
        if (playerCausedThisEvent) then 
          Controller:OnDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.DamageDealt, amount, overKill)
        elseif (destGuid == self.PersistentPlayerInfo.PlayerGuid) then 
          Controller:OnDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.DamageTaken, amount, overKill)
        elseif (playerPetCausedThisEvent) then 
          Controller:OnDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.PetDamageDealt, amount, overKill)
        elseif (destGuid == UnitGUID("pet")) then 
          Controller:OnDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.PetDamageTaken, amount, overKill)  
        end
      end
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
        --if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog(destName .. " (" .. damagedUnitId .. ") tap denied: " .. tostring(damagedUnits[destGuid].IsTapDenied), AutoBiographerEnum.LogLevel.Verbose) end
      end
    end
    
    local damagedUnit = damagedUnits[destGuid]
    
    if (playerCausedThisEvent) then damagedUnit.PlayerHasDamaged = true
    elseif (playerPetCausedThisEvent) then damagedUnit.PlayerPetHasDamaged = true
    elseif (groupMemberCausedThisEvent) then damagedUnit.GroupHasDamaged = true
    end
    
    damagedUnit.LastUnitGuidWhoCausedDamage = sourceGuid
    
    if (destGuid == self.PersistentPlayerInfo.PlayerGuid) then damagedUnit.LastCombatDamageTakenTimestamp = time() end
  elseif (combatLogHealEvents[event]) then
    -- Process event's heal amount.
    if (sourceGuid == self.PersistentPlayerInfo.PlayerGuid or destGuid == self.PersistentPlayerInfo.PlayerGuid) then
      spellId, spellName, spellSchool, amount, overKill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand = select(12, CombatLogGetCurrentEventInfo())
      
      if (amount) then 
        if (not overKill or overKill == -1) then overKill = 0 end
        
        if (sourceGuid == self.PersistentPlayerInfo.PlayerGuid) then
          if (destGuid == self.PersistentPlayerInfo.PlayerGuid) then
            Controller:OnDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.HealingDealtToSelf, amount, overKill)
          else
            Controller:OnDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.HealingDealtToOthers, amount, overKill)
          end
        end
        
        if (destGuid == self.PersistentPlayerInfo.PlayerGuid) then
          Controller:OnDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.HealingTaken, amount, overKill)
        end
        
      end
    end
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
    if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog(destName .. " Died.  Tagged: " .. tostring(weHadTag) .. ". FODCBPOG: " .. tostring(deadUnit.FirstObservedDamageCausedByPlayerOrGroup) .. ". ITD: "  .. tostring(deadUnit.IsTapDenied) .. ". PHD: " .. tostring(deadUnit.PlayerHasDamaged) .. ". PPHD: " .. tostring(deadUnit.PlayerPetHasDamaged).. ". GHD: "  .. tostring(deadUnit.GroupHasDamaged)  .. ". LastDmg: " .. tostring(deadUnit.LastUnitGuidWhoCausedDamage), AutoBiographerEnum.LogLevel.Debug) end
    local kill = Kill.New(deadUnit.GroupHasDamaged, deadUnit.PlayerHasDamaged or deadUnit.PlayerPetHasDamaged, IsUnitGUIDPlayerOrPlayerPet(deadUnit.LastUnitGuidWhoCausedDamage), weHadTag, HelperFunctions.GetCatalogIdFromGuid(destGuid))
    Controller:OnKill(time(), HelperFunctions.GetCoordinatesByUnitId("player"), kill)
  end
  
  if (destGuid ~= self.PersistentPlayerInfo.PlayerGuid) then damagedUnits[destGuid] = nil end
end

function EM.EventHandlers.GROUP_ROSTER_UPDATE(self)
  self:UpdateGroupMemberInfo()
end


function EM.EventHandlers.ITEM_PUSH(self, arg1, arg2, arg3)
  --print(tostring(arg1) .. ", " .. tostring(arg2) .. ", " .. tostring(arg3))
end

function EM.EventHandlers.LEARNED_SPELL_IN_TAB(self, spellId, skillInfoIndex, isGuildPerkSpell)
  local name, rank, icon, castTime, minRange, maxRange, id = GetSpellInfo(spellId)
  Controller:OnSpellLearned(time(), HelperFunctions.GetCoordinatesByUnitId("player"), spellId, name, rank)
end

function EM.EventHandlers.MAIL_CLOSED(self, arg1, arg2)
  self.MailboxIsOpen = false
  self.MailboxMessages = nil
  self.MailInboxUpdatedAfterOpen = nil
end

function EM.EventHandlers.MAIL_SHOW(self, arg1, arg2)
  self.MailboxIsOpen = true
  self.MailboxMessages = {}
  self.MailInboxUpdatedAfterOpen = false
end

function EM.EventHandlers.MAIL_INBOX_UPDATE(self, arg1, arg2)
  --print("MAIL_INBOX_UPDATE: " .. tostring(arg1) .. ", " .. tostring(arg2))
  if (self.MailInboxUpdatedAfterOpen) then return end
  self.MailInboxUpdatedAfterOpen = true

  self:UpdateMailboxMessages()
end

function EM.EventHandlers.UPDATE_PENDING_MAIL(self, arg1, arg2)
  --print("UPDATE_PENDING_MAIL: " .. tostring(arg1) .. ", " .. tostring(arg2))
  if (not self.MailboxIsOpen) then return end

  self:UpdateMailboxMessages()
end

function EM.EventHandlers.MERCHANT_CLOSED(self, arg1, arg2)
  self.MerchantIsOpen = false
end

function EM.EventHandlers.MERCHANT_SHOW(self, arg1, arg2)
  self.MerchantIsOpen = true
end

function EM.EventHandlers.PLAYER_ALIVE(self) -- Fired when the player releases from death to a graveyard; or accepts a resurrect before releasing their spirit. Also fires when logging in.
  -- Upon logging in this event fires before ZONE_CHANGED_NEW_AREA and GetRealZoneText() returns the zone of the last character logged in (or nil if you haven't logged into any other characters since launching WoW).
  if (self.ZoneChangedNewAreaEventHasFired) then self:UpdatePlayerZone() end
end

function EM.EventHandlers.PLAYER_DEAD(self)
  local thisPlayerDeadEventTimestamp = GetTime()
  local lastPlayerDeadEventTimestamp = self.LastPlayerDeadEventTimestamp
  self.LastPlayerDeadEventTimestamp = thisPlayerDeadEventTimestamp

  -- This event can fire when the pet is dismissed while the player is dead.
  -- If self.PlayerFlags.IsDeadOrGhost is false then we know that the player actually died. If true, this event most likely is erroneous (because this event should fire before we update the PlayerFlags values but that isn't guaranteed).
  -- If the pet is alive when the player died, the 2nd event will be fired very quickly. If the pet was dead when the player died, the 2nd event can take quite up to 20 seconds to fire.
  local playerClass, englishClass = UnitClass("player")
  if ((englishClass == "HUNTER" or englishClass == "WARLOCK") and
      self.PlayerFlags.IsDeadOrGhost and
      lastPlayerDeadEventTimestamp and (thisPlayerDeadEventTimestamp - lastPlayerDeadEventTimestamp < 20)) then
    Controller:AddLog("Ignoring this PLAYER_DEAD event.", AutoBiographerEnum.LogLevel.Debug)
    return
  end

  local killerCatalogUnitId = nil
  local killerLevel = nil
  if (damagedUnits[self.PersistentPlayerInfo.PlayerGuid]) then
    if (damagedUnits[self.PersistentPlayerInfo.PlayerGuid].LastCombatDamageTakenTimestamp and time() - damagedUnits[self.PersistentPlayerInfo.PlayerGuid].LastCombatDamageTakenTimestamp < 5) then
      killerCatalogUnitId = HelperFunctions.GetCatalogIdFromGuid(damagedUnits[self.PersistentPlayerInfo.PlayerGuid].LastUnitGuidWhoCausedDamage)
      
      local killerUnitId = FindUnitIdByUnitGUID(damagedUnits[self.PersistentPlayerInfo.PlayerGuid].LastUnitGuidWhoCausedDamage)
      if (killerUnitId ~= nil) then killerLevel = UnitLevel(killerUnitId) end
    end
  end
  
  Controller:OnDeath(time(), HelperFunctions.GetCoordinatesByUnitId("player"), killerCatalogUnitId, killerLevel)
end

function EM.EventHandlers.PLAYER_ENTERING_WORLD(self)
  self.PlayerEnteringWorldHasFired = true

  if (not self.PersistentPlayerInfo.PlayerGuid) then
    -- This is probably the first time this character has logged in while using the addon.
    self.PersistentPlayerInfo.PlayerGuid = UnitGUID("player")
  elseif (self.PersistentPlayerInfo.PlayerGuid ~= UnitGUID("player")) then
    -- The character was probably deleted and a new character was made with the same name.
    AutoBiographer_ConfirmWindow.New("If you have deleted and remade a\ncharacter with the same name, click accept\nand AutoBiographer will\ndelete its stored data for " .. UnitName("player") .. ".", 
      function(deleteConfirmed)
        if (deleteConfirmed) then
          self:ClearCharacterData(true, false)
          self:UpdatePlayerZone()
        else
          AutoBiographer_ConfirmWindow.New("If you have transferred your character\nto a new realm, click accept\nand AutoBiographer will\nkeep its stored data for " .. UnitName("player") .. ".", 
            function(transferConfirmed)
              if (transferConfirmed) then
                self.PersistentPlayerInfo.PlayerGuid = UnitGUID("player")
              end
            end
          )
        end
      end
    )
  end
  
  self.LastPlayerMoney = GetMoney()
  self.PlayerName = UnitName("player")
  self.TemporaryTimestamps.EnteredArea = GetTime()
  self:UpdateGroupMemberInfo()
  self:UpdatePlayerFlags()
end

function EM.EventHandlers.PLAYER_FLAGS_CHANGED(self, unitId)
  if (unitId == "player") then self:UpdatePlayerFlags() end
end

function EM.EventHandlers.PLAYER_GUILD_UPDATE(self, unitId)
  if (not self.PlayerEnteringWorldHasFired or unitId ~= "player") then return end
  self:UpdatePlayerGuildInfo()
end

function EM.EventHandlers.PLAYER_LEAVING_WORLD(self)
  self:UpdateTimestamps(self.PersistentPlayerInfo.CurrentZone, self.PersistentPlayerInfo.CurrentSubZone)
end

function EM.EventHandlers.PLAYER_LEVEL_UP(self, newLevel, ...)
  self:UpdateTimestamps(self.PersistentPlayerInfo.CurrentZone, self.PersistentPlayerInfo.CurrentSubZone)
  self.NewLevelToAddToHistory = newLevel
  
  if (AutoBiographer_Settings.Options["ShowTimePlayedOnLevelUp"] == false) then
    for i = 1, 10 do 
      _G["ChatFrame" .. i]:UnregisterEvent("TIME_PLAYED_MSG")
    end
  end
  
  RequestTimePlayed()
end

function EM.EventHandlers.PLAYER_LOGIN(self)
  
end

function EM.EventHandlers.PLAYER_MONEY(self)
  local currentMoney = GetMoney()
  local deltaMoney = currentMoney - self.LastPlayerMoney
  --print("PLAYER_MONEY. Delta: " .. tostring(deltaMoney))
  
  if (self.AuctionHouseIsOpen) then
  elseif (self.MailboxIsOpen and deltaMoney > 0) then
    local moneyAllocatedToMail = false
    for i = 1, #self.MailboxMessages do
      local message = self.MailboxMessages[i]
      if (not message.moneyIsAssumedTaken and message.money and message.money == deltaMoney) then
        self:MailMoneyTaken(message)
        moneyAllocatedToMail = true
        break
      end
    end -- for i

    if (not moneyAllocatedToMail) then
      for i = 1, #self.MailboxMessages do
        local message1 = self.MailboxMessages[i]
        if (not message1.moneyIsAssumedTaken and message1.money) then
          for j = i + 1, #self.MailboxMessages do
            local message2 = self.MailboxMessages[j]
            if (not message2.moneyIsAssumedTaken and message2.money and (message1.money + message2.money == deltaMoney)) then
              self:MailMoneyTaken(message1)
              self:MailMoneyTaken(message2)
              moneyAllocatedToMail = true
              break
            end
          end -- for j

          if (moneyAllocatedToMail) then break end
        end
      end -- for i
    end

    if (not moneyAllocatedToMail) then
      for i = 1, #self.MailboxMessages do
        local message1 = self.MailboxMessages[i]
        if (not message1.moneyIsAssumedTaken and message1.money) then
          for j = i + 1, #self.MailboxMessages do
            local message2 = self.MailboxMessages[j]
            if (not message2.moneyIsAssumedTaken and message2.money) then
              for k = j + 1, #self.MailboxMessages do
                local message3 = self.MailboxMessages[k]
                if (not message3.moneyIsAssumedTaken and message3.money and (message1.money + message2.money + message3.money == deltaMoney)) then
                  self:MailMoneyTaken(message1)
                  self:MailMoneyTaken(message2)
                  self:MailMoneyTaken(message3)
                  moneyAllocatedToMail = true
                  break
                end
              end -- for k

              if (moneyAllocatedToMail) then break end
            end
          end -- for j

          if (moneyAllocatedToMail) then break end
        end
      end -- for i
    end

    if (not moneyAllocatedToMail) then
      for i = 1, #self.MailboxMessages do
        local message1 = self.MailboxMessages[i]
        if (not message1.moneyIsAssumedTaken and message1.money) then
          for j = i + 1, #self.MailboxMessages do
            local message2 = self.MailboxMessages[j]
            if (not message2.moneyIsAssumedTaken and message2.money) then
              for k = j + 1, #self.MailboxMessages do
                local message3 = self.MailboxMessages[k]
                if (not message3.moneyIsAssumedTaken and message3.money) then
                  for l = k + 1, #self.MailboxMessages do
                    local message4 = self.MailboxMessages[l]
                    if (not message4.moneyIsAssumedTaken and message4.money and (message1.money + message2.money + message3.money + message4.money == deltaMoney)) then
                      self:MailMoneyTaken(message1)
                      self:MailMoneyTaken(message2)
                      self:MailMoneyTaken(message3)
                      self:MailMoneyTaken(message4)
                      moneyAllocatedToMail = true
                      break
                    end
                  end -- for l

                  if (moneyAllocatedToMail) then break end
                end
              end -- for k

              if (moneyAllocatedToMail) then break end
            end
          end -- for j

          if (moneyAllocatedToMail) then break end
        end
      end -- for i
    end

    if (not moneyAllocatedToMail) then
      for i = 1, #self.MailboxMessages do
        local message1 = self.MailboxMessages[i]
        if (not message1.moneyIsAssumedTaken and message1.money) then
          for j = i + 1, #self.MailboxMessages do
            local message2 = self.MailboxMessages[j]
            if (not message2.moneyIsAssumedTaken and message2.money) then
              for k = j + 1, #self.MailboxMessages do
                local message3 = self.MailboxMessages[k]
                if (not message3.moneyIsAssumedTaken and message3.money) then
                  for l = k + 1, #self.MailboxMessages do
                    local message4 = self.MailboxMessages[l]
                    if (not message4.moneyIsAssumedTaken and message4.money) then
                      for m = l + 1, #self.MailboxMessages do
                        local message5 = self.MailboxMessages[m]
                        if (not message5.moneyIsAssumedTaken and message5.money and
                            (message1.money + message2.money + message3.money + message4.money + message5.money == deltaMoney)) then
                          self:MailMoneyTaken(message1)
                          self:MailMoneyTaken(message2)
                          self:MailMoneyTaken(message3)
                          self:MailMoneyTaken(message4)
                          self:MailMoneyTaken(message5)
                          moneyAllocatedToMail = true
                          break
                        end
                      end -- for m

                      if (moneyAllocatedToMail) then break end
                    end
                  end -- for l

                  if (moneyAllocatedToMail) then break end
                end
              end -- for k

              if (moneyAllocatedToMail) then break end
            end
          end -- for j

          if (moneyAllocatedToMail) then break end
        end
      end -- for i
    end

    if (not moneyAllocatedToMail) then
      for i = 1, #self.MailboxMessages do
        local message1 = self.MailboxMessages[i]
        if (not message1.moneyIsAssumedTaken and message1.money) then
          for j = i + 1, #self.MailboxMessages do
            local message2 = self.MailboxMessages[j]
            if (not message2.moneyIsAssumedTaken and message2.money) then
              for k = j + 1, #self.MailboxMessages do
                local message3 = self.MailboxMessages[k]
                if (not message3.moneyIsAssumedTaken and message3.money) then
                  for l = k + 1, #self.MailboxMessages do
                    local message4 = self.MailboxMessages[l]
                    if (not message4.moneyIsAssumedTaken and message4.money) then
                      for m = l + 1, #self.MailboxMessages do
                        local message5 = self.MailboxMessages[m]
                        if (not message5.moneyIsAssumedTaken and message5.money) then
                          for n = m + 1, #self.MailboxMessages do
                            local message6 = self.MailboxMessages[n]
                            if (not message6.moneyIsAssumedTaken and message6.money and
                                (message1.money + message2.money + message3.money + message4.money + message5.money + message6.money == deltaMoney)) then
                              self:MailMoneyTaken(message1)
                              self:MailMoneyTaken(message2)
                              self:MailMoneyTaken(message3)
                              self:MailMoneyTaken(message4)
                              self:MailMoneyTaken(message5)
                              self:MailMoneyTaken(message6)
                              moneyAllocatedToMail = true
                              break
                            end
                          end -- for n

                          if (moneyAllocatedToMail) then break end
                        end
                      end -- for m

                      if (moneyAllocatedToMail) then break end
                    end
                  end -- for l

                  if (moneyAllocatedToMail) then break end
                end
              end -- for k

              if (moneyAllocatedToMail) then break end
            end
          end -- for j

          if (moneyAllocatedToMail) then break end
        end
      end -- for i
    end

    if (not moneyAllocatedToMail) then
      print("Money change did not match six messages.")
    end
  elseif (self.MerchantIsOpen) then
    if (deltaMoney > 0) then
      Controller:OnGainedMoney(time(), HelperFunctions.GetCoordinatesByUnitId("player"), AutoBiographerEnum.MoneyAcquisitionMethod.Merchant, deltaMoney)
    end
  elseif (self.TradeInfo and not self.TradeInfo.Canceled and self.TradeInfo.Closed and GetTime() - self.TradeInfo.ClosedTimestamp < 1) then
    local tradeDeltaMoney = 0
    if (self.TradeInfo.OtherPlayerTradeMoney) then tradeDeltaMoney = tradeDeltaMoney + self.TradeInfo.OtherPlayerTradeMoney end
    if (self.TradeInfo.PlayerTradeMoney) then tradeDeltaMoney = tradeDeltaMoney - self.TradeInfo.PlayerTradeMoney end

    if (tradeDeltaMoney == deltaMoney) then
      if (deltaMoney > 0) then
        Controller:OnGainedMoney(time(), HelperFunctions.GetCoordinatesByUnitId("player"), AutoBiographerEnum.MoneyAcquisitionMethod.Trade, deltaMoney)
      end

      self.TradeInfo.OtherPlayerTradeMoney = 0
      self.TradeInfo.PlayerTradeMoney = 0
    end
  end
  
  Controller:OnMoneyChanged(time(), HelperFunctions.GetCoordinatesByUnitId("player"), deltaMoney)
  self.LastPlayerMoney = currentMoney
end

function EM.EventHandlers.PLAYER_UNGHOST(self) -- Fired when the player is alive after being a ghost.
  self:UpdatePlayerZone()
end

function EM.EventHandlers.QUEST_TURNED_IN(self, questId, xpGained, moneyGained)
  Controller:OnQuestTurnedIn(time(), HelperFunctions.GetCoordinatesByUnitId("player"), questId, C_QuestLog.GetQuestInfo(questId), xpGained, moneyGained)
  
  if (moneyGained and moneyGained > 0) then
    Controller:OnGainedMoney(time(), HelperFunctions.GetCoordinatesByUnitId("player"), AutoBiographerEnum.MoneyAcquisitionMethod.Quest, moneyGained)
  end
  
  if (xpGained and xpGained > 0) then
    Controller:OnGainedExperience(time(), HelperFunctions.GetCoordinatesByUnitId("player"), AutoBiographerEnum.ExperienceTrackingType.Quest, xpGained)
  end
end

function EM.EventHandlers.UPDATE_BATTLEFIELD_STATUS(self, battleFieldIndex)
  local status, mapName, instanceID, minlevel, maxlevel, teamSize, registeredMatch = GetBattlefieldStatus(battleFieldIndex)
  if (status == nil or status == "error") then
    return
  end
  
  -- Get the battleground's ID (Note: GetBattlegroundInfo is not a reliable function and should be avoided).
  local bgId = nil
  for k,v in pairs(BattlegroundDatabase) do
    if (v == mapName) then
      bgId = k
    end
  end

  if (bgId == nil) then
    return
  end

  -- If the status isn't "active": save status and return.
  if (status ~= "active") then
    self.PersistentPlayerInfo.BattlegroundStatuses[bgId] = status
    return
  end

  -- If the last status for this battleground was "finished": return.
  if (self.PersistentPlayerInfo.BattlegroundStatuses[bgId] == "finished") then
    return
  end

  -- If the last status for this battleground was "confirm": the player must have just joined the battleground.
  if (self.PersistentPlayerInfo.BattlegroundStatuses[bgId] == "confirm") then
    Controller:OnBattlegroundJoined(time(), bgId)
  end

  -- If the match isn't over: save status and return.
  local winner = GetBattlefieldWinner()
  if (winner == nil) then
    self.PersistentPlayerInfo.BattlegroundStatuses[bgId] = status
    return
  end

  -- The match just ended.
  local playerWon = false
  local englishFaction, localizedFaction = UnitFactionGroup("player")
  if ((winner == 0 and englishFaction == "Horde") or (winner == 1 and englishFaction == "Alliance")) then
    playerWon = true
  end

  Controller:OnBattlegroundFinished(time(), bgId, playerWon)
  self.PersistentPlayerInfo.BattlegroundStatuses[bgId] = "finished"
end

function EM.EventHandlers.TIME_PLAYED_MSG(self, totalTimePlayed, levelTimePlayed) 
  if (AutoBiographer_Settings.Options["ShowTimePlayedOnLevelUp"] == false) then
    for i = 1, 10 do 
      _G["ChatFrame" .. i]:RegisterEvent("TIME_PLAYED_MSG")
    end
  end

  if self.NewLevelToAddToHistory ~= nil then
    Controller:OnLevelUp(time(), HelperFunctions.GetCoordinatesByUnitId("player"), self.NewLevelToAddToHistory, totalTimePlayed)
    self.NewLevelToAddToHistory = nil
  end
end

function EM.EventHandlers.TRADE_ACCEPT_UPDATE(self, playerAccepts, otherPlayerAccepts)
  --print("TRADE_ACCEPT_UPDATE, " .. tostring(playerAccepts) .. ", " .. tostring(otherPlayerAccepts))
  if (self.TradeInfo == nil) then return end

  self.TradeInfo.OtherPlayerTradeMoney = tonumber(GetTargetTradeMoney())
  self.TradeInfo.PlayerTradeMoney = tonumber(GetPlayerTradeMoney())
end

function EM.EventHandlers.TRADE_CLOSED(self)
  --print("TRADE_CLOSED")
  if (self.TradeInfo == nil) then return end

  self.TradeInfo.Closed = true
  self.TradeInfo.ClosedTimestamp = GetTime()
end

function EM.EventHandlers.TRADE_REQUEST_CANCEL(self)
  --print("TRADE_REQUEST_CANCEL")
  if (self.TradeInfo == nil) then return end

  self.TradeInfo.Canceled = true
end

function EM.EventHandlers.TRADE_SHOW(self)
  self.TradeInfo = {}
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

function EM.EventHandlers.UNIT_SPELLCAST_CHANNEL_START(self, unitId, castId, spellId, arg4, arg5)
  if (unitId ~= "player") then return end
  --print("UNIT_SPELLCAST_CHANNEL_START. " .. unitId .. ", " .. tostring(arg2) .. ", " .. tostring(arg3) .. ", " .. tostring(arg4) .. ", " .. tostring(arg5))
  self:OnStartedCasting(spellId)
end

function EM.EventHandlers.UNIT_SPELLCAST_CHANNEL_STOP(self, unitId, arg2, arg3, arg4, arg5)
  if (unitId ~= "player") then return end
  --print("UNIT_SPELLCAST_CHANNEL_STOP. " .. unitId .. ", " .. tostring(arg2) .. ", " .. tostring(arg3) .. ", " .. tostring(arg4) .. ", " .. tostring(arg5))
  self:OnStoppedCasting()
end

function EM.EventHandlers.UNIT_SPELLCAST_FAILED(self, unitId, arg2, arg3, arg4, arg5)
  if (unitId ~= "player") then return end
  --print("UNIT_SPELLCAST_FAILED. " .. unitId .. ", " .. tostring(arg2) .. ", " .. tostring(arg3) .. ", " .. tostring(arg4) .. ", " .. tostring(arg5))
end

function EM.EventHandlers.UNIT_SPELLCAST_FAILED_QUIET(self, unitId, arg2, arg3, arg4, arg5)
  if (unitId ~= "player") then return end
  --print("UNIT_SPELLCAST_FAILED_QUIET. " .. unitId .. ", " .. tostring(arg2) .. ", " .. tostring(arg3) .. ", " .. tostring(arg4) .. ", " .. tostring(arg5))
end

function EM.EventHandlers.UNIT_SPELLCAST_INTERRUPTED(self, unitId, arg2, arg3, arg4, arg5)
  if (unitId ~= "player") then return end
  --print("UNIT_SPELLCAST_INTERRUPTED. " .. unitId .. ", " .. tostring(arg2) .. ", " .. tostring(arg3) .. ", " .. tostring(arg4) .. ", " .. tostring(arg5))
end

function EM.EventHandlers.UNIT_SPELLCAST_START(self, unitId, castId, spellId)
  if (unitId ~= "player") then return end
  --print("UNIT_SPELLCAST_START. " .. unitId .. ", " .. tostring(arg2) .. ", " .. tostring(arg3) .. ", " .. tostring(arg4) .. ", " .. tostring(arg5))

  self:OnStartedCasting(spellId)
end

function EM.EventHandlers.UNIT_SPELLCAST_STOP(self, unitId, arg2, arg3, arg4, arg5)
  if (unitId ~= "player") then return end
  --print("UNIT_SPELLCAST_STOP. " .. unitId .. ", " .. tostring(arg2) .. ", " .. tostring(arg3) .. ", " .. tostring(arg4) .. ", " .. tostring(arg5))
  self:OnStoppedCasting()
end

function EM.EventHandlers.UNIT_SPELLCAST_SUCCEEDED(self, unitId, castId, spellId)
  if (unitId ~= "player") then return end
  --print("UNIT_SPELLCAST_SUCCEEDED. " .. unitId .. ", " .. tostring(arg2) .. ", " .. tostring(arg3) .. ", " .. tostring(arg4) .. ", " .. tostring(arg5))
  
  local name, rank, icon, castTime, minRange, maxRange, id = GetSpellInfo(spellId)
  Controller:OnSpellSuccessfullyCast(time(), HelperFunctions.GetCoordinatesByUnitId("player"), spellId, name, rank)
end

function EM.EventHandlers.UNIT_TARGET(self, unitId)
  
end

function EM.EventHandlers.UPDATE_MOUSEOVER_UNIT(self)
	local catalogUnitId = HelperFunctions.GetCatalogIdFromGuid(UnitGUID("mouseover"))
	if not catalogUnitId then return end
	if (AutoBiographer_Settings.Options["ShowKillCountOnUnitToolTips"] and UnitCanAttack("player", "mouseover")) then
    if (UnitIsPlayer("mouseover")) then
      GameTooltip:AddLine("Killed " .. tostring(Controller:GetTotalKillingBlowsByCatalogUnitId(catalogUnitId, 1, 9999)) .. " times.")
    else
      GameTooltip:AddLine("Killed " .. tostring(Controller:GetTaggedKillsByCatalogUnitId(catalogUnitId, 1, 9999)) .. " times.")
    end
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

function EM:MailMoneyTaken(message)
  --print("Message match: " .. message.sender)
  if (message.isFromAuctionHouse) then
    if (message.auctionHouseMessageType == AutoBiographerEnum.AuctionHouseMessageType.Outbid) then
      Controller:OnGainedMoney(time(), HelperFunctions.GetCoordinatesByUnitId("player"), AutoBiographerEnum.MoneyAcquisitionMethod.AuctionHouseOutbid, message.money)
    elseif (message.auctionHouseMessageType == AutoBiographerEnum.AuctionHouseMessageType.Sold) then
      Controller:OnGainedMoney(time(), HelperFunctions.GetCoordinatesByUnitId("player"), AutoBiographerEnum.MoneyAcquisitionMethod.AuctionHouseDepositReturn, message.auctionDeposit)
      Controller:OnGainedMoney(time(), HelperFunctions.GetCoordinatesByUnitId("player"), AutoBiographerEnum.MoneyAcquisitionMethod.AuctionHouseSale, message.money - message.auctionDeposit)
    end
  elseif (message.isCodPayment) then
    -- This is the payment for a COD mail message.
    Controller:OnGainedMoney(time(), HelperFunctions.GetCoordinatesByUnitId("player"), AutoBiographerEnum.MoneyAcquisitionMethod.MailCod, message.money)
  else
    -- This is a direct mail message.
    Controller:OnGainedMoney(time(), HelperFunctions.GetCoordinatesByUnitId("player"), AutoBiographerEnum.MoneyAcquisitionMethod.Mail, message.money)
  end

  message.moneyIsAssumedTaken = true
end

function EM:OnStartedCasting(spellId)
  if (self.TemporaryTimestamps.StartedCasting) then
    Controller:AddTime(AutoBiographerEnum.TimeTrackingType.Casting, HelperFunctions.SubtractFloats(GetTime(), self.TemporaryTimestamps.StartedCasting), self.PersistentPlayerInfo.CurrentZone, self.PersistentPlayerInfo.CurrentSubZone)
  end
  
  self.TemporaryTimestamps.StartedCasting = GetTime()
  
  local name, rank, icon, castTime, minRange, maxRange, id = GetSpellInfo(spellId)
  Controller:OnSpellStartedCasting(time(), HelperFunctions.GetCoordinatesByUnitId("player"), spellId, name, rank)
end 

function EM:OnStoppedCasting()
  if (self.TemporaryTimestamps.StartedCasting) then
    Controller:AddTime(AutoBiographerEnum.TimeTrackingType.Casting, HelperFunctions.SubtractFloats(GetTime(), self.TemporaryTimestamps.StartedCasting), self.PersistentPlayerInfo.CurrentZone, self.PersistentPlayerInfo.CurrentSubZone)
  else
    Controller:AddLog("Player stopped casting but there was no timestamp for starting casting.", AutoBiographerEnum.LogLevel.Warning)
  end
  self.TemporaryTimestamps.StartedCasting = nil
end

function EM:UpdateGroupMemberInfo()
  -- Populate list of unit GUIDs in player's party/raid.
  local unitGuidsInGroup = {}
  for i = 1, 4 do
    local guid = UnitGUID("party" .. i)
    if (guid and guid ~= self.PersistentPlayerInfo.PlayerGuid) then
      unitGuidsInGroup[guid] = true
    end
  end
  
  for i = 1, 40 do
    local guid = UnitGUID("raid" .. i)
    if (guid and guid ~= self.PersistentPlayerInfo.PlayerGuid) then
      unitGuidsInGroup[guid] = true
    end
  end
  
  -- Save current timestamp for every unit in group.
  for k,v in pairs(unitGuidsInGroup) do
    if (not self.TemporaryTimestamps.OtherPlayerJoinedGroup[k]) then
      self.TemporaryTimestamps.OtherPlayerJoinedGroup[k] = GetTime()
    end
  end
  
  -- Add time in group for every unit that left the group.
  for k,v in pairs(self.TemporaryTimestamps.OtherPlayerJoinedGroup) do
    if (not unitGuidsInGroup[k]) then
      Controller:AddOtherPlayerInGroupTime(HelperFunctions.GetCatalogIdFromGuid(k), HelperFunctions.SubtractFloats(GetTime(), v))
      self.TemporaryTimestamps.OtherPlayerJoinedGroup[k] = nil
    end
  end
end

function EM:UpdateMailboxMessages() 
  --print ("Start UpdateMailboxMessages")
  self.MailboxUpdatesRunning = self.MailboxUpdatesRunning + 1

  local mailboxMessages = {}

  local _, totalItems = GetInboxNumItems()
  for i = 1, totalItems do
    local _, _, sender, subject, money, codAmount, _, _, _, _, _, _, _ = GetInboxHeaderInfo(i)

    local message = {
      money = money,
      sender = sender
    }
 
    if (sender and string.find(sender, "Auction House")) then
      message.isFromAuctionHouse = true

      invoiceType, itemName, playerName, bid, buyout, deposit, consignment = GetInboxInvoiceInfo(i)

      if (invoiceType == nil) then
        if (string.find(subject, "Auction cancelled") ~= nil) then
          message.auctionHouseMessageType = AutoBiographerEnum.AuctionHouseMessageType.Canceled
        elseif (string.find(subject, "Auction expired") ~= nil) then
          message.auctionHouseMessageType = AutoBiographerEnum.AuctionHouseMessageType.Expired
        elseif (string.find(subject, "Outbid on") ~= nil) then
          message.auctionHouseMessageType = AutoBiographerEnum.AuctionHouseMessageType.Outbid
        end
      else
        if (invoiceType == "buyer") then
          message.auctionHouseMessageType = AutoBiographerEnum.AuctionHouseMessageType.Bought
        elseif (invoiceType == "seller") then
          message.auctionHouseMessageType = AutoBiographerEnum.AuctionHouseMessageType.Sold
        end

        message.auctionSalePrice = math.max(tonumber(bid), tonumber(buyout))
        message.auctionDeposit = tonumber(deposit)
      end
    elseif (subject and string.find(subject, "COD Payment:")) then
      message.isCodPayment = true
    end
    
    table.insert(mailboxMessages, message)
  end

  if (self.MailboxUpdatesRunning == 1) then
    --print ("Set MailboxMessages")
    self.MailboxMessages = mailboxMessages
  end

  self.MailboxUpdatesRunning = self.MailboxUpdatesRunning - 1
  --print ("End UpdateMailboxMessages")
end

function EM:UpdatePlayerGuildInfo()
  local guildName, guildRankName, guildRankIndex = GetGuildInfo("player")
  
  if (self.PersistentPlayerInfo.GuildName ~= guildName) then
    if (guildName) then
      Controller:OnJoinedGuild(time(), guildName)
    else
      Controller:OnLeftGuild(time(), self.PersistentPlayerInfo.GuildName)
    end
  elseif (self.PersistentPlayerInfo.GuildRankIndex ~= guildRankIndex and self.PersistentPlayerInfo.GuildRankIndex and guildRankIndex) then
    Controller:OnGuildRankChanged(time(), guildRankIndex, guildRankName)
  end
  
  self.PersistentPlayerInfo.GuildName = guildName
  self.PersistentPlayerInfo.GuildRankIndex = guildRankIndex
  self.PersistentPlayerInfo.GuildRankName = guildRankName
end
 
function EM:UpdatePlayerFlags()
  -- 
  local playerWasAffectingCombat = self.PlayerFlags.AffectingCombat
  self.PlayerFlags.AffectingCombat = UnitAffectingCombat("player")
  
  local playerWasAfk = self.PlayerFlags.Afk
  self.PlayerFlags.Afk = UnitIsAFK("player")
  
  local playerWasDeadOrGhost = self.PlayerFlags.IsDeadOrGhost
  self.PlayerFlags.IsDeadOrGhost = UnitIsDeadOrGhost("player")
  
  local playerWasInParty = self.PlayerFlags.InParty
  self.PlayerFlags.InParty = UnitInParty("player")
  
  local playerWasOnTaxi = self.PlayerFlags.OnTaxi
  self.PlayerFlags.OnTaxi = UnitOnTaxi("player")
  
  -- Special 
  if (playerWasAffectingCombat and not self.PlayerFlags.AffectingCombat) then
    -- Player left combat.
    if (self.TemporaryTimestamps.EnteredCombat) then
      Controller:AddTime(AutoBiographerEnum.TimeTrackingType.InCombat, HelperFunctions.SubtractFloats(GetTime(), self.TemporaryTimestamps.EnteredCombat), self.PersistentPlayerInfo.CurrentZone, self.PersistentPlayerInfo.CurrentSubZone)
    else
      Controller:AddLog("Player left combat but there was no timestamp for entering combat.", AutoBiographerEnum.LogLevel.Warning)
    end
    self.TemporaryTimestamps.EnteredCombat = nil
  elseif (not playerWasAffectingCombat and self.PlayerFlags.AffectingCombat) then
    -- Player entered combat or was in combat after loading UI.
    self.TemporaryTimestamps.EnteredCombat = GetTime()
  end
  
  if (playerWasAfk and not self.PlayerFlags.Afk) then 
    -- Player cleared AFK.
    if (self.TemporaryTimestamps.MarkedAfk) then
      Controller:AddTime(AutoBiographerEnum.TimeTrackingType.Afk, HelperFunctions.SubtractFloats(GetTime(), self.TemporaryTimestamps.MarkedAfk), self.PersistentPlayerInfo.CurrentZone, self.PersistentPlayerInfo.CurrentSubZone)
    else
      Controller:AddLog("Player left AFK but there was no timestamp for entering AFK.", AutoBiographerEnum.LogLevel.Warning)
    end
    self.TemporaryTimestamps.MarkedAfk = nil
  elseif (not playerWasAfk and self.PlayerFlags.Afk) then 
    -- Player marked AFK or was AFK after loading UI.
    self.TemporaryTimestamps.MarkedAfk = GetTime()
  end
  
  if (playerWasDeadOrGhost and not self.PlayerFlags.IsDeadOrGhost) then 
    -- Player revived.
    if (self.TemporaryTimestamps.Died) then
      Controller:AddTime(AutoBiographerEnum.TimeTrackingType.DeadOrGhost, HelperFunctions.SubtractFloats(GetTime(), self.TemporaryTimestamps.Died), self.PersistentPlayerInfo.CurrentZone, self.PersistentPlayerInfo.CurrentSubZone)
    else
      Controller:AddLog("Player revived but there was no timestamp for dieing.", AutoBiographerEnum.LogLevel.Warning)
    end
    self.TemporaryTimestamps.Died = nil
  elseif (not playerWasDeadOrGhost and self.PlayerFlags.IsDeadOrGhost) then 
    -- Player died or was dead after loading UI
    self.TemporaryTimestamps.Died = GetTime()
  end
  
  if (playerWasInParty and not self.PlayerFlags.InParty) then
    -- Player left party.
    if (self.TemporaryTimestamps.JoinedParty) then
      Controller:AddTime(AutoBiographerEnum.TimeTrackingType.InParty, HelperFunctions.SubtractFloats(GetTime(), self.TemporaryTimestamps.JoinedParty), self.PersistentPlayerInfo.CurrentZone, self.PersistentPlayerInfo.CurrentSubZone)
    else
      Controller:AddLog("Player left party but there was no timestamp for joining a party.", AutoBiographerEnum.LogLevel.Warning)
    end
    self.TemporaryTimestamps.JoinedParty = nil
  elseif (not playerWasInParty and self.PlayerFlags.InParty) then 
    -- Player joined party.
    self.TemporaryTimestamps.JoinedParty = GetTime()
  end
  
  if (playerWasOnTaxi and not self.PlayerFlags.OnTaxi) then
    -- Player left taxi.
    if (self.TemporaryTimestamps.EnteredTaxi) then
      Controller:AddTime(AutoBiographerEnum.TimeTrackingType.OnTaxi, HelperFunctions.SubtractFloats(GetTime(), self.TemporaryTimestamps.EnteredTaxi), self.PersistentPlayerInfo.CurrentZone, self.PersistentPlayerInfo.CurrentSubZone)
    else
      Controller:AddLog("Player left taxi but there was no timestamp for entering taxi.", AutoBiographerEnum.LogLevel.Warning)
    end
    self.TemporaryTimestamps.EnteredTaxi = nil
    
    self:UpdatePlayerZone()
  elseif (not playerWasOnTaxi and self.PlayerFlags.OnTaxi) then
    -- Player entered taxi or was on taxi after loading UI.
    self.TemporaryTimestamps.EnteredTaxi = GetTime()
  end
end

function EM:UpdatePlayerZone()
  if (UnitIsDeadOrGhost("player") or UnitOnTaxi("player")) then return end
  
  local previousSubZone = self.PersistentPlayerInfo.CurrentSubZone
  self.PersistentPlayerInfo.CurrentSubZone = GetSubZoneText()
  if (not self.PersistentPlayerInfo.CurrentSubZone or self.PersistentPlayerInfo.CurrentSubZone == "") then
    self.PersistentPlayerInfo.CurrentSubZone = GetMinimapZoneText()
  end
  
  local previousZone = self.PersistentPlayerInfo.CurrentZone
  self.PersistentPlayerInfo.CurrentZone = GetRealZoneText()
    
  if (previousSubZone ~= self.PersistentPlayerInfo.CurrentSubZone or previousZone ~= self.PersistentPlayerInfo.CurrentZone) then
    self:UpdateTimestamps(previousZone, previousSubZone)
  end
  
  Controller:OnChangedZone(time(), HelperFunctions.GetCoordinatesByUnitId("player"), self.PersistentPlayerInfo.CurrentZone)
  Controller:OnChangedSubZone(time(), HelperFunctions.GetCoordinatesByUnitId("player"), self.PersistentPlayerInfo.CurrentZone, self.PersistentPlayerInfo.CurrentSubZone)
end

function EM:UpdateTimestamps(zone, subZone)
  -- Afk
  if (self.TemporaryTimestamps.MarkedAfk) then
    Controller:AddTime(AutoBiographerEnum.TimeTrackingType.Afk, HelperFunctions.SubtractFloats(GetTime(), self.TemporaryTimestamps.MarkedAfk), zone, subZone)
    self.TemporaryTimestamps.MarkedAfk = GetTime()
  end
  
  -- DeadOrGhost
  if (self.TemporaryTimestamps.Died) then
    Controller:AddTime(AutoBiographerEnum.TimeTrackingType.DeadOrGhost, HelperFunctions.SubtractFloats(GetTime(), self.TemporaryTimestamps.Died), zone, subZone)
    self.TemporaryTimestamps.DeadOrGhost = GetTime()
  end
  
  -- In Combat
  if (self.TemporaryTimestamps.EnteredCombat) then
    Controller:AddTime(AutoBiographerEnum.TimeTrackingType.InCombat, HelperFunctions.SubtractFloats(GetTime(), self.TemporaryTimestamps.EnteredCombat), zone, subZone)
    self.TemporaryTimestamps.EnteredCombat = GetTime()
  end
  
  -- In Party
  if (self.TemporaryTimestamps.JoinedParty) then
    Controller:AddTime(AutoBiographerEnum.TimeTrackingType.InParty, HelperFunctions.SubtractFloats(GetTime(), self.TemporaryTimestamps.JoinedParty), zone, subZone)
    self.TemporaryTimestamps.JoinedParty = GetTime()
  end
  
  -- Logged In
  if (self.TemporaryTimestamps.EnteredArea) then
    Controller:AddTime(AutoBiographerEnum.TimeTrackingType.LoggedIn, HelperFunctions.SubtractFloats(GetTime(), self.TemporaryTimestamps.EnteredArea), zone, subZone)
    self.TemporaryTimestamps.EnteredArea = GetTime()
  end
  
  -- On Taxi
  if (self.TemporaryTimestamps.EnteredTaxi) then
    Controller:AddTime(AutoBiographerEnum.TimeTrackingType.OnTaxi, HelperFunctions.SubtractFloats(GetTime(), self.TemporaryTimestamps.EnteredTaxi), zone, subZone)
    self.TemporaryTimestamps.EnteredTaxi = GetTime()
  end
  
  -- Other Players in Group
  for k,v in pairs(self.TemporaryTimestamps.OtherPlayerJoinedGroup) do
    Controller:AddOtherPlayerInGroupTime(HelperFunctions.GetCatalogIdFromGuid(k), HelperFunctions.SubtractFloats(GetTime(), v))
    self.TemporaryTimestamps.OtherPlayerJoinedGroup[k] = GetTime()
  end
end

-- Register each event for which we have an event handler.
EM.Frame = CreateFrame("Frame")
for eventName,_ in pairs(EM.EventHandlers) do
	EM.Frame:RegisterEvent(eventName)
end
EM.Frame:SetScript("OnEvent", function(_, event, ...) EM:OnEvent(_, event, ...) end)

-- Test functions.
function EM:ClearAllData(doNotRequireConfirmation, doNotReloadUI) 
  local func = function(confirmed)
    if (not confirmed) then return end
    _G["AUTOBIOGRAPHER_SETTINGS"] = nil
    self:ClearCharacterData(true, doNotReloadUI)
  end
  
  if (doNotRequireConfirmation) then
    func(true)
  else
    AutoBiographer_ConfirmWindow.New("Clear character and global data?", func)
  end
end

function EM:ClearCharacterData(doNotRequireConfirmation, doNotReloadUI) 
  local clearFunc = function(confirmed)
    if (not confirmed) then return end
    _G["AUTOBIOGRAPHER_CATALOGS_CHAR"] = nil
    _G["AUTOBIOGRAPHER_EVENTS_CHAR"] = nil
    _G["AUTOBIOGRAPHER_LEVELS_CHAR"] = nil
    _G["AUTOBIOGRAPHER_INFO_CHAR"] = nil
    if (not doNotReloadUI) then ReloadUI() end
  end
  print(doNotRequireConfirmation)
  if (doNotRequireConfirmation) then
    clearFunc(true)
  else
    AutoBiographer_ConfirmWindow.New("Clear character data?", clearFunc)
  end
end

function EM:Test()
  --print(HelperFunctions.GetCatalogIdFromGuid("GameObject-0-4380-533-11441-181544-000050305B"))
  --Controller:OnDeath(time(), nil, "go181544", nil)
end