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
    LastJump = nil,
    MarkedAfk = nil,
    OtherPlayerJoinedGroup = {}, -- Dict<UnitGuid, TempTimestamp>
    StartedCasting = nil,
  },
  TimePlayedMessageChatFramesToRegister = nil,
  TimePlayedMessageIsUnregistered = nil,
  TimePlayedMessageLastTimestamp = nil,
  TradeInfo = nil,
  ZoneChangedNewAreaEventHasFired = false
}

local EM = AutoBiographer_EventManager
local Controller = AutoBiographer_Controller

-- Slash Commands

SLASH_AUTOBIOGRAPHER1, SLASH_AUTOBIOGRAPHER2 = "/autobiographer", "/ab"
function SlashCmdList.AUTOBIOGRAPHER()
  AutoBiographer_MainWindow:Toggle()
end

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
    if ((string.match(validUnitIds[i], "party") or string.match(validUnitIds[i], "raid")) and not string.match(validUnitIds[i], "target")) then
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
      MapEventDisplayFilters = {}, -- Dict<EventSubType, bool>
      MapEventShowAnimation = false,
      MapEventShowCircle = true,
			MapEventFollowExpansions = false,
      MinimapPos = -25,
      Options = { -- Dict<string?, bool>
        EnableDebugLogging = false,
        EnableMilestoneMessages = true,
        ShowFriendlyPlayerToolTips = true,
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
      _G["AUTOBIOGRAPHER_SETTINGS"].MapEventDisplayFilters[v] = true
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
      ArenaStatuses = {},
      BattlegroundStatuses = {},
      CurrentSubZone = nil,
      CurrentZone = nil,
      DatabaseVersion = 15,
      GuildName = nil,
      GuildRankIndex = nil,
      GuildRankName = nil,
      LastTotalTimePlayed = nil,
      PlayerGuid = nil,
    }
	end
  
  self.PersistentPlayerInfo = _G["AUTOBIOGRAPHER_INFO_CHAR"]

  AutoBiographer_Databases.Initialiaze()
  
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

  AutoBiographer_DebugWindow:Initialize()
  AutoBiographer_EventWindow:Initialize()
  AutoBiographer_MainWindow:Initialize()
  AutoBiographer_OptionWindow:Initialize()
  AutoBiographer_StatisticsWindow:Initialize()
  AutoBiographer_VerificationWindow:Initialize()

  AutoBiographer_WorldMapOverlayWindow_Initialize()
  AutoBiographer_WorldMapOverlayWindowToggleButton:Initialize()

  C_Timer.After(1, function()
    EM:RequestTimePlayedInterval()
  end)
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
  
  local id = HelperFunctions.GetItemIdFromTextWithChatItemLink(text)
  if (not id) then
    if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then print("[AutoBiographer] Unable to get itemId from text: '" .. text .. "'.") end
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

  local itemAcquisitionMethod = nil
  if (string.find(text, "You create") == 1) then
    itemAcquisitionMethod = AutoBiographerEnum.ItemAcquisitionMethod.Create
  elseif (string.find(text, "You receive loot") == 1) then
    itemAcquisitionMethod = AutoBiographerEnum.ItemAcquisitionMethod.Loot
  elseif (string.find(text, "You receive item") == 1) then
    if (self:WasTradeRecentlyMade() and self.TradeInfo.OtherPlayerTradeItems) then
      local matchingTradeItem = self:GetItemWithIdAndQuantity(self.TradeInfo.OtherPlayerTradeItems, id, quantity)
      if (matchingTradeItem) then
        itemAcquisitionMethod = AutoBiographerEnum.ItemAcquisitionMethod.Trade
        matchingTradeItem.quantity = 0
      end
    end

    if (not itemAcquisitionMethod and self.MailboxIsOpen) then
      for i = 1, #self.MailboxMessages do
        local message = self.MailboxMessages[i]
        local matchingMessageItem = self:GetItemWithIdAndQuantity(message.items, id, quantity)
        if (matchingMessageItem) then
          local isCanceledOrExpiredAuctionHouseListing = false
          if (message.isFromAuctionHouse) then
            if (message.auctionHouseMessageType == AutoBiographerEnum.AuctionHouseMessageType.Bought) then
              itemAcquisitionMethod = AutoBiographerEnum.ItemAcquisitionMethod.AuctionHouse
            elseif (message.auctionHouseMessageType == AutoBiographerEnum.AuctionHouseMessageType.Canceled or
                    message.auctionHouseMessageType == AutoBiographerEnum.AuctionHouseMessageType.Expired) then
              isCanceledOrExpiredAuctionHouseListing = true
            end
          elseif (message.isCod) then
            itemAcquisitionMethod = AutoBiographerEnum.ItemAcquisitionMethod.MailCod
          else
            itemAcquisitionMethod = AutoBiographerEnum.ItemAcquisitionMethod.Mail
          end
        
          matchingMessageItem.quantity = 0

          if (isCanceledOrExpiredAuctionHouseListing) then
            return
          else
            break
          end
        end
      end
    end
    
    if (not itemAcquisitionMethod and self.MerchantIsOpen) then
      itemAcquisitionMethod = AutoBiographerEnum.ItemAcquisitionMethod.Merchant
    end
  end

  if (not itemAcquisitionMethod) then
    itemAcquisitionMethod = AutoBiographerEnum.ItemAcquisitionMethod.Other
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
  
  local skillName, skillLevel = string.match(text, "Your skill in (.+) has increased to (%d+).")
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

    -- Set damage flags.
    if (damagedUnits[destGuid] == nil or unitWasOutOfCombat) then   
      local firstObservedDamageCausedByPlayerOrGroup = playerCausedThisEvent or playerPetCausedThisEvent or groupMemberCausedThisEvent
      
      damagedUnits[destGuid] = {
        DamageTakenFromGroup = 0,
        DamageTakenFromPlayerOrPet = 0,
        DamageTakenTotal = 0,
        FirstObservedDamageCausedByPlayerOrGroup = firstObservedDamageCausedByPlayerOrGroup,
        GroupHasDamaged = nil,
        IsTapDenied = nil,
        LastUnitGuidWhoCausedDamage = nil,
        PlayerHasDamaged = nil,
        PlayerPetHasDamaged = nil,
        UnitHealthMax = nil
      }
    else
      if (damagedUnitId ~= nil) then
        damagedUnits[destGuid].IsTapDenied = UnitIsTapDenied(damagedUnitId)
        --if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then Controller:AddLog(destName .. " (" .. damagedUnitId .. ") tap denied: " .. tostring(damagedUnits[destGuid].IsTapDenied), AutoBiographerEnum.LogLevel.Verbose) end
      end
    end

    local damagedUnit = damagedUnits[destGuid]

    local damagedUnitId = FindUnitIdByUnitGUID(destGuid)
    local unitWasOutOfCombat = nil
    if (damagedUnitId ~= nil) then 
      unitWasOutOfCombat = not UnitAffectingCombat(damagedUnitId)
      
      local damagedCatalogUnitId = HelperFunctions.GetCatalogIdFromGuid(destGuid)
      if (Controller:CatalogUnitIsIncomplete(damagedCatalogUnitId)) then
        Controller:UpdateCatalogUnit(CatalogUnit.New(damagedCatalogUnitId, UnitClass(damagedUnitId), UnitClassification(damagedUnitId), UnitCreatureFamily(damagedUnitId), UnitCreatureType(damagedUnitId), UnitName(damagedUnitId), UnitRace(damagedUnitId), nil, HelperFunctions.GetUnitTypeFromCatalogUnitId(damagedCatalogUnitId)))
      end

      if (damagedUnit.UnitHealthMax == nil) then
        damagedUnit.UnitHealthMax = UnitHealthMax(damagedUnitId)
      end
    end
    
    -- Process event's damage amount.
    if (string.find(event, "SWING") == 1) then
      amount, overKill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand = select(12, CombatLogGetCurrentEventInfo())
    elseif (string.find(event, "RANGE") == 1 or string.find(event, "SPELL") == 1) then
      spellId, spellName, spellSchool, amount, overKill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand = select(12, CombatLogGetCurrentEventInfo())
    end
    
    if (amount) then
      if (not overKill or overKill == -1) then overKill = 0 end -- -1 means none, nil means INSTAKILL or other non-DAMAGE type
      
      damagedUnit.DamageTakenTotal = damagedUnit.DamageTakenTotal + amount - overKill

      if (playerCausedThisEvent) then 
        Controller:OnDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.DamageDealt, amount, overKill)
        damagedUnit.DamageTakenFromPlayerOrPet = damagedUnit.DamageTakenFromPlayerOrPet + amount - overKill
      elseif (destGuid == self.PersistentPlayerInfo.PlayerGuid) then
        Controller:OnDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.DamageTaken, amount, overKill)
      elseif (playerPetCausedThisEvent) then 
        Controller:OnDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.PetDamageDealt, amount, overKill)
        damagedUnit.DamageTakenFromPlayerOrPet = damagedUnit.DamageTakenFromPlayerOrPet + amount - overKill
      elseif (destGuid == UnitGUID("pet")) then
        Controller:OnDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.PetDamageTaken, amount, overKill)
      elseif (groupMemberCausedThisEvent) then
        damagedUnit.DamageTakenFromGroup = damagedUnit.DamageTakenFromGroup + amount - overKill
      end
    end
    
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

    -- local playerOrGroupDmgOfHealthMax = HelperFunctions.Round(100 * ((deadUnit.DamageTakenFromPlayerOrPet + deadUnit.DamageTakenFromGroup) / deadUnit.UnitHealthMax)) -- This throws an error if unit dies in 1 hit.
    local playerOrGroupDmgOfTotal = HelperFunctions.Round(100 * ((deadUnit.DamageTakenFromPlayerOrPet + deadUnit.DamageTakenFromGroup) / deadUnit.DamageTakenTotal))
    -- print("Player/group dmg of max health: " .. playerOrGroupDmgOfHealthMax .. "%. Player/group dmg of total: " .. playerOrGroupDmgOfTotal .. "%.")
    local kill = Kill.New(deadUnit.GroupHasDamaged, deadUnit.PlayerHasDamaged or deadUnit.PlayerPetHasDamaged, IsUnitGUIDPlayerOrPlayerPet(deadUnit.LastUnitGuidWhoCausedDamage), weHadTag, HelperFunctions.GetCatalogIdFromGuid(destGuid), playerOrGroupDmgOfTotal)
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
  EM:MailboxClosed()
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

function EM.EventHandlers.UPDATE_PENDING_MAIL(self, arg1, arg2) -- Fired when receiving new mail or sometimes when reading/opening mail.
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
    
    if (UnitLevel("player") == 1 and UnitXP("player") == 0) then
      print("\124cFFFFD700[AutoBiographer] Events and statistics are being tracked.")
    else
      print("\124cFFFFD700[AutoBiographer] Events and statistics are being tracked. Any events and statistics that occurred previously on this character are not tracked.")
    end
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

function EM.EventHandlers.PLAYER_INTERACTION_MANAGER_FRAME_HIDE(self, type)
  if (type == 17) then
    EM:MailboxClosed()
  end
end

function EM.EventHandlers.PLAYER_LEAVING_WORLD(self)
  self:UpdateTimestamps(self.PersistentPlayerInfo.CurrentZone, self.PersistentPlayerInfo.CurrentSubZone)
end

function EM.EventHandlers.PLAYER_LEVEL_UP(self, newLevel, ...)
  self:UpdateTimestamps(self.PersistentPlayerInfo.CurrentZone, self.PersistentPlayerInfo.CurrentSubZone)
  self.NewLevelToAddToHistory = newLevel
  
  local delay = 0.25
  C_Timer.After(delay, function()
    if (self.TimePlayedMessageLastTimestamp and GetTime() - self.TimePlayedMessageLastTimestamp <= delay) then
      return
    end

    local showMessage = AutoBiographer_Settings.Options["ShowTimePlayedOnLevelUp"]
    EM:RequestTimePlayed(showMessage)
  end)
end

function EM.EventHandlers.PLAYER_LOGIN(self)
  
end

function EM.EventHandlers.PLAYER_MONEY(self)
  local currentMoney = GetMoney()
  local deltaMoney = currentMoney - self.LastPlayerMoney
  --print("PLAYER_MONEY. Delta: " .. tostring(deltaMoney))
  
  Controller:OnMoneyChanged(time(), HelperFunctions.GetCoordinatesByUnitId("player"), deltaMoney)

  if (self.AuctionHouseIsOpen) then
  elseif (self.MailboxIsOpen and deltaMoney > 0) then
    if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then AutoBiographer_Controller:AddLog("Scanning mail to match delta money (" .. tostring(deltaMoney) .. ").", AutoBiographerEnum.LogLevel.Debug) end
    local moneyAllocatedToMail = false

    -- Scan each message individually to see if money change matched it exactly.
    for i = 1, #self.MailboxMessages do
      local message = self.MailboxMessages[i]
      if (not message.moneyIsAssumedTaken and message.money and message.money == deltaMoney) then
        if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then AutoBiographer_Controller:AddLog("Delta money (" .. tostring(deltaMoney) .. ") matched 1 message.", AutoBiographerEnum.LogLevel.Debug) end
        self:MailMoneyTakenFromOneMessage(message)
        moneyAllocatedToMail = true
        break
      end
    end -- for i

    if (not moneyAllocatedToMail) then
      -- Scan messages starting from the beginning of the message list.
      local sum = 0
      local messagesContributingToSum = {}
      for i = 1, #self.MailboxMessages do
        local message = self.MailboxMessages[i]
        if (not message.moneyIsAssumedTaken and message.money) then
          sum = sum + message.money
          table.insert(messagesContributingToSum, message)
          if (sum == deltaMoney) then
            if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then AutoBiographer_Controller:AddLog("Delta money (" .. tostring(deltaMoney) .. ") matched " .. tostring(#messagesContributingToSum) .. " messages.", AutoBiographerEnum.LogLevel.Debug) end
            self:MailMoneyTakenFromMultipleMessages(messagesContributingToSum)
            moneyAllocatedToMail = true
            break
          end
        end
      end -- for i

      if (not moneyAllocatedToMail and AutoBiographer_Settings.Options["EnableDebugLogging"]) then
        AutoBiographer_Controller:AddLog("Delta money (" .. tostring(deltaMoney) .. ") did not match " .. tostring(#messagesContributingToSum) .. " messages (message money sum: " .. tostring(sum) .. ").", AutoBiographerEnum.LogLevel.Debug)
      end
    end

    if (not moneyAllocatedToMail) then
      AutoBiographer_Controller:AddLog("Delta money (" .. tostring(deltaMoney) .. ") did not match scanned messages.", AutoBiographerEnum.LogLevel.Warning)
      if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then print("[AutoBiographer] Delta money (" .. tostring(deltaMoney) .. ") did not match scanned messages.") end
    end
  elseif (self.MerchantIsOpen) then
    if (deltaMoney > 0) then
      Controller:OnGainedMoney(time(), HelperFunctions.GetCoordinatesByUnitId("player"), AutoBiographerEnum.MoneyAcquisitionMethod.Merchant, deltaMoney)
    end
  elseif (self:WasTradeRecentlyMade()) then
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
  --print("Status: " .. tostring(status) .. ". MapName: " .. tostring(mapName) .. ". InstanceId: " .. tostring(instanceID) .. ". MinLevel: " .. tostring(minlevel) .. ". MaxLevel: " .. tostring(maxlevel) .. ". TeamSize: " .. tostring(teamSize) .. ". RegisteredMatch: " .. tostring(registeredMatch))
  if (status == nil or status == "none" or status == "error") then
    return
  end
  
  local isBattleground = teamSize == nil or teamSize == 0

  -- Get the arena or battleground ID (Note: GetBattlegroundInfo is not a reliable function and should be avoided).
  local battlegroundId = nil
  if (isBattleground) then
    for bgId, bgName in pairs(AutoBiographer_Databases.BattlegroundDatabase) do
      if (bgName == mapName) then
        battlegroundId = bgId
      end
    end

    if (battlegroundId == nil) then
      if (mapName == "Random Battleground") then
        for i = 1, #AutoBiographer_Databases.BattlegroundDatabase do
          self.PersistentPlayerInfo.BattlegroundStatuses[i] = status
        end
      else
        Controller:AddLog("Unsupported battleground map name '" .. tostring(mapName) .. "'.", AutoBiographerEnum.LogLevel.Warning)
      end

      return
    end
  end

  -- If the status isn't "active": save status and return.
  if (status ~= "active") then
    if (isBattleground) then self.PersistentPlayerInfo.BattlegroundStatuses[battlegroundId] = status
    else self.PersistentPlayerInfo.ArenaStatuses[teamSize] = status
    end

    return
  end

  local arenaId
  if (not isBattleground) then
    for aId, aName in pairs(AutoBiographer_Databases.ArenaDatabase) do
      if (aName == mapName) then
        arenaId = aId
      end
    end
    
    
    if (arenaId == nil) then
      Controller:AddLog("Unsupported arena map name '" .. tostring(mapName) .. "'.", AutoBiographerEnum.LogLevel.Warning)
      return
    end
  end

  local lastStatus
  if (isBattleground) then lastStatus = self.PersistentPlayerInfo.BattlegroundStatuses[battlegroundId]
  else lastStatus = self.PersistentPlayerInfo.ArenaStatuses[teamSize]
  end

  -- If the last status for this battlefield was "finished": return.
  if (lastStatus == "finished") then
    return
  end

  -- If the last status for this battlefield was "confirm": the player must have just joined the battlefield.
  if (lastStatus == "confirm") then
    if (isBattleground) then Controller:OnBattlegroundJoined(time(), battlegroundId)
    else Controller:OnArenaJoined(time(), registeredMatch, teamSize, arenaId)
    end
  end

  -- If the match isn't over: save status and return.
  local winner = GetBattlefieldWinner()
  if (winner == nil) then
    if (isBattleground) then self.PersistentPlayerInfo.BattlegroundStatuses[battlegroundId] = status
    else self.PersistentPlayerInfo.ArenaStatuses[teamSize] = status
    end

    return
  end

  -- The match just ended.
  local numScores = GetNumBattlefieldScores()
  for i = 1, numScores do
    name, killingBlows, honorableKills, deaths, honorGained, faction, rank, race, class = GetBattlefieldScore(i);
    if (name == UnitName("player")) then
      local playerWon = faction == winner

      if (isBattleground) then Controller:OnBattlegroundFinished(time(), battlegroundId, playerWon)
      else Controller:OnArenaFinished(time(), registeredMatch, teamSize, arenaId, playerWon)
      end

      if (isBattleground) then self.PersistentPlayerInfo.BattlegroundStatuses[battlegroundId] = "finished"
      else self.PersistentPlayerInfo.ArenaStatuses[teamSize] = "finished"
      end

      break
    end
  end
end

function EM.EventHandlers.TIME_PLAYED_MSG(self, totalTimePlayed, levelTimePlayed)
  self.TimePlayedMessageLastTimestamp = GetTime()

  if (self.TimePlayedMessageChatFramesToRegister) then
    for i = 1, #self.TimePlayedMessageChatFramesToRegister do
      _G["ChatFrame" .. self.TimePlayedMessageChatFramesToRegister[i]]:RegisterEvent("TIME_PLAYED_MSG")
    end
    self.TimePlayedMessageChatFramesToRegister = nil
  end

  if self.NewLevelToAddToHistory ~= nil then
    Controller:OnLevelUp(time(), HelperFunctions.GetCoordinatesByUnitId("player"), self.NewLevelToAddToHistory, totalTimePlayed)
    self.NewLevelToAddToHistory = nil
  end

  if (self.PersistentPlayerInfo.LastTotalTimePlayed == nil) then
    self.PersistentPlayerInfo.LastTotalTimePlayed = totalTimePlayed
    return
  end

  local timeSinceLastTotalTimePlayed = totalTimePlayed - self.PersistentPlayerInfo.LastTotalTimePlayed
  self.PersistentPlayerInfo.LastTotalTimePlayed = totalTimePlayed
  if (timeSinceLastTotalTimePlayed > 120) then
    print ("\124cFFFF0000[AutoBiographer] There are approximately " .. HelperFunctions.Round(timeSinceLastTotalTimePlayed / 60) .. " minutes of play time on this character unaccounted for by AutoBiographer. Some events or statistics may not have been tracked.")
    -- TODO: Add debug event here.
    -- TODO: Scan money and items to check for changes.
  end
end

function EM.EventHandlers.TRADE_ACCEPT_UPDATE(self, playerAccepts, otherPlayerAccepts)
  --print("TRADE_ACCEPT_UPDATE, " .. tostring(playerAccepts) .. ", " .. tostring(otherPlayerAccepts))

  -- Trade events are not consistent, items/money may be traded before TRADE_ACCEPT_UPDATE fires with both arguments set and before TRADE_CLOSED fires.
  if ((playerAccepts == 0 and otherPlayerAccepts == 0) or GetTradePlayerItemLink(7) or GetTradeTargetItemLink(7)) then
    self.TradeInfo = nil
    return
  end
  
  self.TradeInfo = {}
  self.TradeInfo.OtherPlayerTradeMoney = tonumber(GetTargetTradeMoney())
  self.TradeInfo.PlayerTradeMoney = tonumber(GetPlayerTradeMoney())

  self.TradeInfo.OtherPlayerTradeItems = {}
  for i = 1, 6 do
    local name, texture, quantity, quality, isUsable, enchant = GetTradeTargetItemInfo(i)
    local chatItemLink = GetTradeTargetItemLink(i)

    if (not chatItemLink) then break end
    
    local itemId = HelperFunctions.GetItemIdFromTextWithChatItemLink(chatItemLink)
    local item = {
      id = itemId,
      quantity = quantity,
    }

    table.insert(self.TradeInfo.OtherPlayerTradeItems, item)
  end
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

-- function EM.EventHandlers.TRADE_SHOW(self)
--   --print("TRADE_SHOW")
--   self.TradeInfo = {}
-- end

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

hooksecurefunc("AscendStop", function()
  if (not IsFalling()) then
    return
  end

  local timeNow = GetTime()
  if (not EM.TemporaryTimestamps.LastJump or HelperFunctions.SubtractFloats(timeNow, EM.TemporaryTimestamps.LastJump) > 0.75) then
    Controller:OnJump(time())
    EM.TemporaryTimestamps.LastJump = timeNow
  end
end);

GameTooltip:HookScript("OnTooltipSetUnit", function(self)
	local catalogUnitId = HelperFunctions.GetCatalogIdFromGuid(UnitGUID("mouseover"))
  if (not catalogUnitId) then
    return
  end

	if (AutoBiographer_Settings.Options["ShowKillCountOnUnitToolTips"] and UnitCanAttack("player", "mouseover")) then
    local killStatistics = Controller:GetAggregatedKillStatisticsByCatalogUnitId(catalogUnitId, 1, 9999)
    if (UnitIsPlayer("mouseover")) then
      GameTooltip:AddLine("Killed " .. tostring(KillStatistics.GetSum(killStatistics, { AutoBiographerEnum.KillTrackingType.TaggedKillingBlow, AutoBiographerEnum.KillTrackingType.UntaggedKillingBlow })) .. " times.")
    else
      GameTooltip:AddLine("Killed " .. tostring(KillStatistics.GetSum(killStatistics, { AutoBiographerEnum.KillTrackingType.TaggedAssist, AutoBiographerEnum.KillTrackingType.TaggedGroupAssistOrKillingBlow, AutoBiographerEnum.KillTrackingType.TaggedKillingBlow })) .. " times.")
    end
  elseif (AutoBiographer_Settings.Options["ShowFriendlyPlayerToolTips"] and not UnitCanAttack("player", "mouseover") and UnitIsPlayer("mouseover")) then
    local otherPlayerStatistics = Controller:GetAggregatedOtherPlayerStatisticsByCatalogUnitId(catalogUnitId, 1, 9999)
    local tooltipString = ""

    local duelsWon = OtherPlayerStatistics.GetSum(otherPlayerStatistics, { AutoBiographerEnum.OtherPlayerTrackingType.DuelsLostToPlayer })
    local duelsLost = OtherPlayerStatistics.GetSum(otherPlayerStatistics, { AutoBiographerEnum.OtherPlayerTrackingType.DuelsWonAgainstPlayer })
    if (duelsWon > 0 or duelsLost > 0) then
      tooltipString = tooltipString .. "Duels (W/L): " .. tostring(duelsWon) .. "/" .. tostring(duelsLost) .. ". "
    end

    local timeGrouped = HelperFunctions.Round(OtherPlayerStatistics.GetSum(otherPlayerStatistics, { AutoBiographerEnum.OtherPlayerTrackingType.TimeSpentGroupedWithPlayer }) / 3600, 2)
    if (timeGrouped > 0) then
      tooltipString = tooltipString .. "Time Grouped: " .. timeGrouped .. "h. "
    end

    if (tooltipString ~= "") then
      GameTooltip:AddLine(tooltipString)
    end
	end

	self:Show()
end)

-- *** Miscellaneous Member Functions ***

function EM:GetItemWithIdAndQuantity(tab, id, quantity)
  if tab == nil then return nil end

  for k,v in pairs(tab) do
    if (v.id and tostring(v.id) == tostring(id) and v.quantity and tostring(v.quantity) == tostring(quantity)) then
      return v
    end
  end

  return nil
end

function EM:MailboxClosed()
  self.MailboxIsOpen = false
  self.MailboxMessages = nil
  self.MailInboxUpdatedAfterOpen = nil
end

function EM:MailMoneyTakenFromMultipleMessages(messages)
  for i = 1, #messages do
    self:MailMoneyTakenFromOneMessage(messages[i])
  end
end

function EM:MailMoneyTakenFromOneMessage(message)
  --print("Message match: " .. message.sender)
  
  if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then
    local sender = "Unknown Sender"
    if (message.sender) then sender = message.sender end
    AutoBiographer_Controller:AddLog("Message match: '" .. sender .. "'.", AutoBiographerEnum.LogLevel.Debug)
  end

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

function EM:RequestTimePlayed(showMessage)
  if (not showMessage) then
    self.TimePlayedMessageChatFramesToRegister = {}
    for i = 1, 10 do
      if (_G["ChatFrame" .. i]:IsEventRegistered("TIME_PLAYED_MSG")) then
        table.insert(self.TimePlayedMessageChatFramesToRegister, i)
        _G["ChatFrame" .. i]:UnregisterEvent("TIME_PLAYED_MSG")
      end
    end
  end
  
  RequestTimePlayed()
end

function EM:RequestTimePlayedInterval()
  if (not self.TimePlayedMessageLastTimestamp or GetTime() - self.TimePlayedMessageLastTimestamp >= 30) then
    EM:RequestTimePlayed(false)
  end

  C_Timer.After(60, function()
    EM:RequestTimePlayedInterval()
  end)
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
      sender = sender,
      items = {},
    }

    if (codAmount and codAmount > 0) then
      message.isCod = true
    end
 
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
    
    for j = 1, ATTACHMENTS_MAX_RECEIVE do
      local name, itemId, texture, count, quality, canUse = GetInboxItem(i, j)
      if (itemId) then
        local item = {
          id = itemId,
          quantity = count,
        }

        table.insert(message.items, item)
      end
    end

    table.insert(mailboxMessages, message)
  end

  -- If this is the only mailbox update currently running.
  if (self.MailboxUpdatesRunning == 1) then
    -- Compare existing messages with messages from this update.
    if (not self.MailboxMessages or #self.MailboxMessages < #mailboxMessages) then
      --print ("Set MailboxMessages")
      self.MailboxMessages = mailboxMessages
    end
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

function EM:WasTradeRecentlyMade()
  return self.TradeInfo and not self.TradeInfo.Canceled and (not self.TradeInfo.Closed or GetTime() - self.TradeInfo.ClosedTimestamp < 1)
end

-- Register each event for which we have an event handler.
EM.GameVersion = HelperFunctions.GetGameVersion()
EM.Frame = CreateFrame("Frame")
for eventName,_ in pairs(EM.EventHandlers) do
  if (EM.GameVersion > 2 or eventName ~= "PLAYER_INTERACTION_MANAGER_FRAME_HIDE") then
	  EM.Frame:RegisterEvent(eventName)
  end
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

function EM:GetDistanceFromTarget()
  local playerPosition = HelperFunctions.GetCoordinatesByUnitId("player")
  local targetPosition = HelperFunctions.GetCoordinatesByUnitId("target")

  local xDist = HelperFunctions.Round(targetPosition.X - playerPosition.X, 2)
  local yDist = HelperFunctions.Round(targetPosition.Y - playerPosition.Y, 2)
  local dist = HelperFunctions.Round(math.sqrt(xDist * xDist + yDist * yDist), 2)
  print(tostring(xDist) .. ", " .. tostring(yDist) .. " (" .. tostring(dist) .. ")")
end

function EM:GetPosition()
  local position = HelperFunctions.GetCoordinatesByUnitId("player")
  HelperFunctions.PrintKeysAndValuesFromTable(position)
end

function EM:Test()
  print("MailboxIsOpen: " .. tostring(self.MailboxIsOpen))
end