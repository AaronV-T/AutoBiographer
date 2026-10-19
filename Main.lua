AutoBiographer_Settings = nil

AutoBiographer_EventManager = {
  AuctionHouseIsOpen = nil,
  CampedPending = false,
  CurrentDamageMeterSessionId = nil,
  DamageMeterBaselineInitializationPending = false,
  DamageMeterBaselinesInitialized = false,
  DamageMeterRecordedTotals = {},
  DamageMeterResetGeneration = 0,
  DistanceTrackingActive = false,
  DistanceTrackingGeneration = 0,
  LastDistancePosition = nil,
  PendingDamageMeterFinalizationSessionId = nil,
  EventHandlers = {},
  GearPendingUnequips = {},
  GearSnapshotRetryPending = false,
  GearTrackingGeneration = 0,
  GearTrackingReady = false,
  LastPlayerDeadEventTimestamp = nil,
  LastPlayerMoney = nil,
  LastSentChatLineId = nil,
  LastReceivedWhisperLineId = nil,
  MailboxIsOpen = nil,
  MailboxMessages = nil,
  MailboxUpdatesRunning = 0,
  MailInboxUpdatedAfterOpen = nil,
  MerchantIsOpen = nil,
  NewLevelToAddToHistory = nil,
  OtherPlayerAuraStates = {},
  PlayerCampAuraHistory = nil,
  PlayerCampAuraSnapshot = nil,
  PlayerCampTrackingStartedAt = nil,
  PersistentPlayerInfo = nil,
  PlayerEnteringWorldHasFired = false,
  PlayerName = nil,
  LastRestedExperiencePool = nil,
  PlayerFlags = {
    AffectingCombat = nil,
    Afk = nil,
    GamepadUIEnabled = nil,
    InParty = nil,
    IsDeadOrGhost = nil,
    OnTaxi = nil
  },
  TemporaryTimestamps = { -- These are specifically for time tracking.
    Died = nil,
    EnteredArea = nil,
    EnteredCombat = nil,
    EnteredTaxi = nil,
    GamepadUIEnabled = nil,
    JoinedParty = nil,
    LastJump = nil,
    MarkedAfk = nil,
    OtherPlayerJoinedGroup = {}, -- Dict<UnitGuid, TempTimestamp>
    StartedCasting = nil,
  },
  TimePlayedMessageChatFramesToRegister = nil,
  TimePlayedMessageIsUnregistered = nil,
  TimePlayedMessageLastTimestamp = nil,
  TimePlayedMessageSuppressionGeneration = 0,
  TradeInfo = nil,
  ZoneChangedNewAreaEventHasFired = false
}

local AceComm = LibStub:GetLibrary("AceComm-3.0")
local EM = AutoBiographer_EventManager
local Controller = AutoBiographer_Controller
local MM = AutoBiographer_MessageManager
local Api = AutoBiographer_Api
local messageTypes = AutoBiographerEnum.MessageTrackingType
local channelMessageTypes = {
  [1] = messageTypes.General,
  [2] = messageTypes.Trade,
  [22] = messageTypes.LocalDefense,
  [23] = messageTypes.WorldDefense,
  [26] = messageTypes.LookingForGroup,
  [42] = messageTypes.TradeServices,
}
local damageMeterSessionRetentionCount = 5

-- Slash Commands

SLASH_AUTOBIOGRAPHER1, SLASH_AUTOBIOGRAPHER2 = "/autobiographer", "/ab"
function SlashCmdList.AUTOBIOGRAPHER()
  if (not AutoBiographer_MainWindow:IsShown()) then
    AutoBiographer_MainWindow:Toggle()
  end
end

SLASH_AUTOBIOGRAPHERVERIFY1, SLASH_AUTOBIOGRAPHERVERIFY2 = "/autobiographerverify", "/abverify"
function SlashCmdList.AUTOBIOGRAPHERVERIFY()
  if (not AutoBiographer_MainWindow:IsShown()) then
    AutoBiographer_MainWindow:Toggle()
  end

  if (not AutoBiographer_VerificationWindow:IsShown()) then
    AutoBiographer_VerificationWindow:Toggle()
  end
end

SLASH_AUTOBIOGRAPHERTEST1, SLASH_AUTOBIOGRAPHERTEST2 = "/autobiographertest", "/abtest"
function SlashCmdList.AUTOBIOGRAPHERTEST()
  EM:Test()
end

-- *** Locals ***

local damagedUnits = {}
local deadUnits = {}

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

local validUnitIds = { "focus", "focuspet", "mouseover", "mouseoverpet", "pet", "player", "target", "targetpet", "softenemy" }
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
    local name, lastName = Api.GetUnitName(validUnitIds[i])
    if (name and lastName) then name = name .. " " .. lastName end
    if (name == unitName) then
      return UnitGUID(validUnitIds[i])
    end
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
      DatabaseVersion = 1,
      EventDisplayFilters = {}, -- Dict<EventSubType, bool>
      MapEventDisplayFilters = {}, -- Dict<EventSubType, bool>
      MapEventShowAnimation = false,
      MapEventShowCircle = true,
			MapEventFollowExpansions = false,
      MinimapPos = -25,
      Options = { -- Dict<string?, bool>
        EnableCustomEventSharing = true,
        EnableDebugLogging = false,
        EnableMilestoneMessages = true,
        RecommendCampfireMessages = true,
        ShareMilestonesAsEmotes = false,
        ShareMilestonesInGuild = false,
        ShowDiscoveryInfoOnToolTips = true,
        ShowFriendlyPlayerToolTips = true,
        ShowKillCountOnUnitToolTips = true,
        ShowMinimapButton = true,
        ShowTimePlayedOnLevelUp = true,
        TakeScreenshotOnAchievementEarned = false,
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
  if type(_G["AUTOBIOGRAPHER_GEAR_CHAR"]) ~= "table" then
    _G["AUTOBIOGRAPHER_GEAR_CHAR"] = GearHistory.New()
  end
  if type(_G["AUTOBIOGRAPHER_LEVELS_CHAR"]) ~= "table" then
		_G["AUTOBIOGRAPHER_LEVELS_CHAR"] = {}
	end
  if type(_G["AUTOBIOGRAPHER_NOTES"]) ~= "table" then
    _G["AUTOBIOGRAPHER_NOTES"] = Notes.New()
  end
  if type(_G["AUTOBIOGRAPHER_SNAPSHOTS_CHAR"]) ~= "table" then
    _G["AUTOBIOGRAPHER_SNAPSHOTS_CHAR"] = CharacterSnapshots.New()
  end
  if type(_G["AUTOBIOGRAPHER_TODOS_CHAR"]) ~= "table" then
    _G["AUTOBIOGRAPHER_TODOS_CHAR"] = Todo.New()
  end
  Controller.AccountData = {
    Notes = _G["AUTOBIOGRAPHER_NOTES"],
  }
  
  Controller.CharacterData = {
    Catalogs = _G["AUTOBIOGRAPHER_CATALOGS_CHAR"],
    Events = _G["AUTOBIOGRAPHER_EVENTS_CHAR"],
    Gear = _G["AUTOBIOGRAPHER_GEAR_CHAR"],
    Levels = _G["AUTOBIOGRAPHER_LEVELS_CHAR"],
    Snapshots = _G["AUTOBIOGRAPHER_SNAPSHOTS_CHAR"],
    Todos = _G["AUTOBIOGRAPHER_TODOS_CHAR"],
  }
  
  if type(_G["AUTOBIOGRAPHER_INFO_CHAR"]) ~= "table" then
		_G["AUTOBIOGRAPHER_INFO_CHAR"] = {
      ArenaStatuses = {},
      BattlegroundStatuses = {},
      CurrentSubZone = nil,
      CurrentZone = nil,
      DatabaseVersion = AutoBiographer_MigrationManager:GetLatestCharacterDatabaseVersion(),
      ForeverBetaAnnouncementShownLastLogin = false,
      GuildName = nil,
      GuildRankIndex = nil,
      GuildRankName = nil,
      LastTotalTimePlayed = nil,
      PlayerGuid = nil,
    }
	end
  
  self.PersistentPlayerInfo = _G["AUTOBIOGRAPHER_INFO_CHAR"]

  AutoBiographer_Databases.Initialiaze()
  
  -- Prepare account data first; character upgrades may import notes into it.
  AutoBiographer_MigrationManager:RunAccountMigrations(AutoBiographer_Settings.DatabaseVersion, EM, Controller)
  AutoBiographer_MigrationManager:RunCharacterMigrations(self.PersistentPlayerInfo.DatabaseVersion, EM, Controller)
  
  --
  local playerLevel = UnitLevel("player")
  if (not Controller.CharacterData.Levels[playerLevel]) then 
    if (playerLevel == 1 and UnitXP("player") == 0) then
      Controller:OnLevelUp(time(), nil, playerLevel, 0)
    else 
      Controller:OnLevelUp(nil, nil, playerLevel)
    end
  end
  AutoBiographer_Milestones:Start()
  
  AutoBiographer_MinimapButton_Reposition()
  if (AutoBiographer_Settings.Options["ShowMinimapButton"] == false) then AutoBiographer_MinimapButton:Hide()
  else AutoBiographer_MinimapButton:Show() end

  AutoBiographer_CustomEventDetailsWindow:Initialize()
  AutoBiographer_DebugWindow:Initialize()
  AutoBiographer_EventWindow:Initialize()
  AutoBiographer_GearPanel:Initialize()
  AutoBiographer_SnapshotPanel:Initialize()
  AutoBiographer_ReplayPanel:Initialize()
  AutoBiographer_NotesWindow:Initialize()
  AutoBiographer_OptionWindow:Initialize()
  AutoBiographer_StatisticsWindow:Initialize()
  AutoBiographer_TodoPanel:Initialize()
  AutoBiographer_VerificationWindow:Initialize()
  AutoBiographer_MainWindow:Initialize()

  if (not (Api.IsWoWForever() and Api.IsGamepadUIEnabled())) then
    AutoBiographer_WorldMapOverlayWindow_Initialize()
    AutoBiographer_WorldMapOverlayWindowToggleButton_Initialize()
  end

  C_Timer.After(1, function()
    EM:RequestTimePlayedInterval()
  end)
end

function EM.EventHandlers.BAG_UPDATE_DELAYED(self)
  AutoBiographer_TodoPanel:QueueRefresh()
end

function EM.EventHandlers.BOSS_KILL(self, bossId, bossName)
  local hasKilledBossBefore = true
  if (not Catalogs.PlayerHasKilledBoss(Controller.CharacterData.Catalogs, bossId)) then
    hasKilledBossBefore = false
    Controller:UpdateCatalogBoss(CatalogBoss.New(bossId, bossName, true))
  end

  Controller:OnBossKill(time(), HelperFunctions.GetCoordinatesByUnitId("player"), bossId, bossName, hasKilledBossBefore)
end

function EM.EventHandlers.ACHIEVEMENT_EARNED(self, arg1)
  --print("ACHIEVEMENT_EARNED. " .. tostring(arg1))
  Controller:OnAchievementEarned(arg1)
end

function EM.EventHandlers.AUCTION_HOUSE_CLOSED(self, arg1, arg2)
  self.AuctionHouseIsOpen = false
end

function EM.EventHandlers.AUCTION_HOUSE_SHOW(self, arg1, arg2)
  self.AuctionHouseIsOpen = true
end

-- Older clients use BATTLEGROUND rather than INSTANCE_CHAT. Only register
-- optional chat events when the client supports them, using the normal frame.
if (Api.IsEventAvailable("CHAT_MSG_BATTLEGROUND", C_ChatInfo == nil and not Api.IsWoWForever())) then
  function EM.EventHandlers.CHAT_MSG_BATTLEGROUND(self, ...)
    self:OnMessageSent(messageTypes.Battleground, false, ...)
  end
end

if (Api.IsEventAvailable("CHAT_MSG_BATTLEGROUND_LEADER", C_ChatInfo == nil and not Api.IsWoWForever())) then
  function EM.EventHandlers.CHAT_MSG_BATTLEGROUND_LEADER(self, ...)
    self:OnMessageSent(messageTypes.Battleground, false, ...)
  end
end

if (Api.IsEventAvailable("CHAT_MSG_BN_WHISPER_INFORM", BNGetInfo ~= nil)) then
  function EM.EventHandlers.CHAT_MSG_BN_WHISPER_INFORM(self, ...)
    self:OnMessageSent(messageTypes.BattleNetWhisper, true, ...)
  end
end

function EM.EventHandlers.CHAT_MSG_CHANNEL(self, ...)
  -- zoneChannelID is the channel's stable type, not its changing /1 or /2 number.
  local zoneChannelId = select(7, ...)
  local messageType = messageTypes.OtherChannel
  if (not self:IsSecretValue(zoneChannelId) and zoneChannelId ~= nil) then
    messageType = channelMessageTypes[zoneChannelId] or messageType
  end
  self:OnMessageSent(messageType, false, ...)
end

function EM.EventHandlers.CHAT_MSG_COMBAT_XP_GAIN(self, text)
  local mobName, xpGainedFromKill = string.match(text, "(.+) dies, you gain (%d+) experience")
  local xpGainedFromGroupBonus = string.match(text, "+(%d+) group bonus")
  local xpGainedFromRestedBonus = string.match(text, "+(%d+) exp Rested bonus")
  local xpLostToRaidPenalty = string.match(text, "-(%d+) raid penalty")
  
  if (xpGainedFromKill) then Controller:OnGainedExperience(time(), HelperFunctions.GetCoordinatesByUnitId("player"), AutoBiographerEnum.ExperienceTrackingType.Kill, tonumber(xpGainedFromKill)) end
  if (xpGainedFromGroupBonus) then Controller:OnGainedExperience(time(), HelperFunctions.GetCoordinatesByUnitId("player"), AutoBiographerEnum.ExperienceTrackingType.GroupBonus, tonumber(xpGainedFromGroupBonus)) end
  -- Forever no longer includes rested XP in the message; UPDATE_EXHAUSTION
  -- records it from the pool instead. Do not count it twice if text returns.
  if (not Api.IsWoWForever() and xpGainedFromRestedBonus) then Controller:OnGainedExperience(time(), HelperFunctions.GetCoordinatesByUnitId("player"), AutoBiographerEnum.ExperienceTrackingType.RestedBonus, tonumber(xpGainedFromRestedBonus)) end
  if (xpLostToRaidPenalty) then Controller:OnGainedExperience(time(), HelperFunctions.GetCoordinatesByUnitId("player"), AutoBiographerEnum.ExperienceTrackingType.RaidPenalty, tonumber(xpLostToRaidPenalty)) end
end

if (Api.IsEventAvailable("CHAT_MSG_COMMUNITIES_CHANNEL", C_Club ~= nil)) then
  function EM.EventHandlers.CHAT_MSG_COMMUNITIES_CHANNEL(self, ...)
    self:OnMessageSent(messageTypes.Community, false, ...)
  end
end

function EM.EventHandlers.CHAT_MSG_EMOTE(self, ...)
  self:OnMessageSent(messageTypes.Emote, false, ...)
end

function EM.EventHandlers.CHAT_MSG_GUILD(self, ...)
  self:OnMessageSent(messageTypes.Guild, false, ...)
end

if (Api.IsEventAvailable("CHAT_MSG_INSTANCE_CHAT", C_ChatInfo ~= nil)) then
  function EM.EventHandlers.CHAT_MSG_INSTANCE_CHAT(self, ...)
    self:OnMessageSent(messageTypes.Instance, false, ...)
  end
end

if (Api.IsEventAvailable("CHAT_MSG_INSTANCE_CHAT_LEADER", C_ChatInfo ~= nil)) then
  function EM.EventHandlers.CHAT_MSG_INSTANCE_CHAT_LEADER(self, ...)
    self:OnMessageSent(messageTypes.Instance, false, ...)
  end
end

function EM.EventHandlers.CHAT_MSG_LOOT(self, text, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21)
  if (string.find(text, "You") ~= 1) then return end
  
  local id = HelperFunctions.GetItemIdFromTextWithChatItemLink(text)
  if (not id) then
    if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then print("[AutoBiographer] Unable to get itemId from text: '" .. text .. "'.") end
    Controller:AddLog("Unable to get itemId from text: '" .. text .. "'.", AutoBiographerEnum.LogLevel.Warning)
    return
  end

  local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemIcon, itemSellPrice, itemClassID, itemSubClassID, bindType, expacID, itemSetID, isCraftingReagent = Api.GetItemInfo(id)
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
    itemAcquisitionMethod = AutoBiographer_Fishing:ConsumeLoot(id, quantity) and
      AutoBiographerEnum.ItemAcquisitionMethod.Fishing or AutoBiographerEnum.ItemAcquisitionMethod.Loot
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

function EM.EventHandlers.CHAT_MSG_OFFICER(self, ...)
  self:OnMessageSent(messageTypes.Officer, false, ...)
end

function EM.EventHandlers.CHAT_MSG_PARTY(self, ...)
  self:OnMessageSent(messageTypes.Party, false, ...)
end

function EM.EventHandlers.CHAT_MSG_PARTY_LEADER(self, ...)
  self:OnMessageSent(messageTypes.Party, false, ...)
end

function EM.EventHandlers.CHAT_MSG_RAID(self, ...)
  self:OnMessageSent(messageTypes.Raid, false, ...)
end

function EM.EventHandlers.CHAT_MSG_RAID_LEADER(self, ...)
  self:OnMessageSent(messageTypes.Raid, false, ...)
end

function EM.EventHandlers.CHAT_MSG_RAID_WARNING(self, ...)
  self:OnMessageSent(messageTypes.RaidWarning, false, ...)
end

function EM.EventHandlers.CHAT_MSG_SAY(self, ...)
  self:OnMessageSent(messageTypes.Say, false, ...)
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

  -- Capture entire names, not individual words: Forever names include surnames.
  local winnerFullName, loserFullName = string.match(text, "^(.+) has defeated (.+) in a duel%.?$")
  if (not winnerFullName) then
    loserFullName, winnerFullName = string.match(text, "^(.+) has fled from (.+) in a duel%.?$")
  end
  if (winnerFullName and loserFullName) then
    local playerFullName, playerLastName = Api.GetUnitName("player")
    if (playerFullName and playerLastName) then playerFullName = playerFullName .. " " .. playerLastName end
    if (winnerFullName ~= playerFullName and loserFullName ~= playerFullName) then return end

    local playerWon = winnerFullName == playerFullName
    local opponentFullName = playerWon and loserFullName or winnerFullName
    local opponentGuid = FindUnitGUIDByUnitName(opponentFullName)
    if (not opponentGuid) then
      Controller:AddLog("Duel not tracked: unable to find GUID for " .. opponentFullName .. ".", AutoBiographerEnum.LogLevel.Warning)
      return
    end

    local opponentCatalogUnitId = HelperFunctions.GetCatalogIdFromGuid(opponentGuid)
    local opponentUnitId = FindUnitIdByUnitGUID(opponentGuid)
    if (opponentUnitId) then
      local name, lastName = Api.GetUnitName(opponentUnitId)
      Controller:UpdateCatalogUnit(CatalogUnit.New(
        opponentCatalogUnitId, nil, nil, nil, nil, name, lastName, nil, nil, AutoBiographerEnum.UnitType.Player
      ))
    end
    if (playerWon) then
      Controller:OnDuelWon(time(), HelperFunctions.GetCoordinatesByUnitId("player"), opponentCatalogUnitId, opponentFullName)
    else
      Controller:OnDuelLost(time(), HelperFunctions.GetCoordinatesByUnitId("player"), opponentCatalogUnitId, opponentFullName)
    end
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

function EM.EventHandlers.CHAT_MSG_TEXT_EMOTE(self, ...)
  self:OnMessageSent(messageTypes.Emote, false, ...)
end

function EM.EventHandlers.CHAT_MSG_TRADESKILLS(self, text, arg2, arg3, arg4, arg5)
  --if (string.find(text, "You create") ~= 1) then return end
  --print(text)
  --print(arg2)
end

function EM.EventHandlers.CHAT_MSG_WHISPER(self, ...)
  self:OnWhisper(false, ...)
end

function EM.EventHandlers.CHAT_MSG_WHISPER_INFORM(self, ...)
  if (self:OnMessageSent(messageTypes.Whisper, true, ...)) then self:OnWhisper(true, ...) end
end

function EM.EventHandlers.CHAT_MSG_YELL(self, ...)
  self:OnMessageSent(messageTypes.Yell, false, ...)
end

-- WoW Forever does not expose the raw combat-log payload that this legacy
-- handler requires, so do not define or register it there.
if (not Api.IsWoWForever()) then
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
          local name, lastName = Api.GetUnitName(damagerUnitId)
          Controller:UpdateCatalogUnit(CatalogUnit.New(damagerCatalogUnitId, UnitClass(damagerUnitId), UnitClassification(damagerUnitId), UnitCreatureFamily(damagerUnitId), UnitCreatureType(damagerUnitId), name, lastName, UnitRace(damagerUnitId), nil, HelperFunctions.GetUnitTypeFromCatalogUnitId(damagerCatalogUnitId)))
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
          local name, lastName = Api.GetUnitName(damagedUnitId)
          Controller:UpdateCatalogUnit(CatalogUnit.New(damagedCatalogUnitId, UnitClass(damagedUnitId), UnitClassification(damagedUnitId), UnitCreatureFamily(damagedUnitId), UnitCreatureType(damagedUnitId), name, lastName, UnitRace(damagedUnitId), nil, HelperFunctions.GetUnitTypeFromCatalogUnitId(damagedCatalogUnitId)))
        end
      end
      
      -- Process event's damage amount.
      local spellId, spellName, spellSchool, amount, overKill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand
      if (string.find(event, "SWING") == 1) then
        spellId = 6603 -- Melee swings have no spell fields in their payload.
        amount, overKill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand = select(12, CombatLogGetCurrentEventInfo())
      elseif (string.find(event, "RANGE") == 1 or string.find(event, "SPELL") == 1) then
        spellId, spellName, spellSchool, amount, overKill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand = select(12, CombatLogGetCurrentEventInfo())
      end
      
      if (amount) then
        if (not overKill or overKill == -1) then overKill = 0 end -- -1 means none, nil means INSTAKILL or other non-DAMAGE type

        local damageSpellId = spellId or 6603
        local damageSpellName = spellName or Api.GetSpellInfo(damageSpellId) or "Attack"
        
        damagedUnit.DamageTakenTotal = damagedUnit.DamageTakenTotal + amount - overKill

        if (playerCausedThisEvent) then 
          Controller:OnDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.DamageDealt, nil, damageSpellId, damageSpellName, amount, overKill)
          damagedUnit.DamageTakenFromPlayerOrPet = damagedUnit.DamageTakenFromPlayerOrPet + amount - overKill
        elseif (destGuid == self.PersistentPlayerInfo.PlayerGuid) then
          Controller:OnDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.DamageTaken, sourceName or "Unknown", damageSpellId, damageSpellName, amount, overKill)
        elseif (playerPetCausedThisEvent) then 
          Controller:OnDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.DamageDealt, nil, damageSpellId, damageSpellName, amount, overKill)
          damagedUnit.DamageTakenFromPlayerOrPet = damagedUnit.DamageTakenFromPlayerOrPet + amount - overKill
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
        local spellId, spellName, spellSchool, amount, overKill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand = select(12, CombatLogGetCurrentEventInfo())

        if (amount) then 
          if (not overKill or overKill == -1) then overKill = 0 end
          
          if (sourceGuid == self.PersistentPlayerInfo.PlayerGuid) then
            Controller:OnDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.HealingDealt, nil, spellId, spellName, amount, overKill)
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

      local playerOrGroupDmgOfTotal = HelperFunctions.Round(100 * ((deadUnit.DamageTakenFromPlayerOrPet + deadUnit.DamageTakenFromGroup) / deadUnit.DamageTakenTotal))
      local kill = Kill.New(deadUnit.GroupHasDamaged, deadUnit.PlayerHasDamaged or deadUnit.PlayerPetHasDamaged, IsUnitGUIDPlayerOrPlayerPet(deadUnit.LastUnitGuidWhoCausedDamage), weHadTag, HelperFunctions.GetCatalogIdFromGuid(destGuid), playerOrGroupDmgOfTotal)
      Controller:OnKill(time(), HelperFunctions.GetCoordinatesByUnitId("player"), kill)
    end
    
    if (destGuid ~= self.PersistentPlayerInfo.PlayerGuid) then damagedUnits[destGuid] = nil end
  end
end

function EM.EventHandlers.CVAR_UPDATE(self)
  if (not self.PlayerEnteringWorldHasFired or self.PlayerFlags.GamepadUIEnabled == nil) then return end
  self:UpdateGamepadUIState()
end

function EM.EventHandlers.DAMAGE_METER_COMBAT_SESSION_UPDATED(self, meterType, sessionId)
  --print("DAMAGE_METER_COMBAT_SESSION_UPDATED. " .. tostring(meterType) .. ", " .. tostring(sessionId))
  self:OnDamageMeterCombatSessionUpdated(meterType, sessionId)
end

function EM.EventHandlers.DAMAGE_METER_CURRENT_SESSION_UPDATED(self)
  --print("DAMAGE_METER_CURRENT_SESSION_UPDATED")
  self:OnDamageMeterCurrentSessionUpdated()
end

function EM.EventHandlers.DAMAGE_METER_RESET(self)
  self:OnDamageMeterReset()
end


function EM.EventHandlers.GET_ITEM_INFO_RECEIVED(self, itemId, success)
  if (self:IsSecretValue(itemId) or self:IsSecretValue(success) or not success or not Controller.CharacterData.Todos) then return end
  for _, item in ipairs(Controller:GetTodos().Items) do
    if (item.ItemId == itemId) then AutoBiographer_TodoPanel:QueueRefresh(); return end
  end
end

function EM.EventHandlers.GROUP_ROSTER_UPDATE(self)
  self:UpdateGroupMemberInfo()
  self:SnapshotOtherPlayerAurasForGroup()
end


function EM.EventHandlers.ITEM_PUSH(self, arg1, arg2, arg3)
  --print(tostring(arg1) .. ", " .. tostring(arg2) .. ", " .. tostring(arg3))
end

function EM.EventHandlers.LEARNED_SPELL_IN_SKILL_LINE(self, spellId, skillLineIndex, isGuildPerkSpell)
  local name, rank, icon, castTime, minRange, maxRange, id = Api.GetSpellInfo(spellId)
  Controller:OnSpellLearned(time(), HelperFunctions.GetCoordinatesByUnitId("player"), spellId, name, rank)
end

function EM.EventHandlers.LOOT_CLOSED(self)
  AutoBiographer_Fishing:OnLootClosed()
end

function EM.EventHandlers.LOOT_OPENED(self)
  AutoBiographer_Fishing:OnLootReady()
end

function EM.EventHandlers.LOOT_READY(self)
  AutoBiographer_Fishing:OnLootReady()
end

function EM.EventHandlers.LOOT_SLOT_CLEARED(self, slotId)
  AutoBiographer_Fishing:OnLootSlotCleared(slotId)
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

function EM.EventHandlers.PARTY_KILL(self, attackerGuid, targetGuid)
  --print("PARTY_KILL. " .. tostring(attackerGuid) .. ", " .. tostring(targetGuid))
  if (not Api.IsWoWForever()) then return end

  local deadUnit = self:GetOrCreateDeadUnit(targetGuid, false)
  if (deadUnit and not (issecretvalue and issecretvalue(attackerGuid)) and IsUnitGUIDPlayerOrPlayerPet(attackerGuid)) then
    deadUnit.KilledByPlayer = true
  end
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

  if (Api.IsWoWForever()) then
    -- The death recap is not necessarily available during PLAYER_DEAD itself.
    -- Its entries are newest first; select the fatal entry when it has an
    -- overkill value, otherwise use the newest entry that damaged the player.
    C_Timer.After(0, function()
      local killerCatalogUnitId = nil
      local killerLevel = nil
      local recapEvents = Api.GetDeathRecapEvents()
      local fallbackEvent = nil
      local fatalEvent = nil

      for _, recapEvent in ipairs(recapEvents or {}) do
        if (recapEvent.destGUID == EM.PersistentPlayerInfo.PlayerGuid) then
          if (fallbackEvent == nil) then fallbackEvent = recapEvent end
          if (recapEvent.sourceGUID and recapEvent.overkill and recapEvent.overkill >= 0) then
            fatalEvent = recapEvent
            break
          end
        end
      end

      local killerEvent = fatalEvent or fallbackEvent
      local killerGuid = killerEvent and killerEvent.sourceGUID
      if (killerGuid) then
        local success, catalogUnitId = pcall(HelperFunctions.GetCatalogIdFromGuid, killerGuid)
        if (success) then killerCatalogUnitId = catalogUnitId end

        if (killerCatalogUnitId and killerEvent.sourceName and Controller:CatalogUnitIsIncomplete(killerCatalogUnitId)) then
          Controller:UpdateCatalogUnit(CatalogUnit.New(
            killerCatalogUnitId,
            nil,
            nil,
            nil,
            nil,
            killerEvent.sourceName,
            nil,
            nil,
            nil,
            HelperFunctions.GetUnitTypeFromCatalogUnitId(killerCatalogUnitId)
          ))
        end

        local killerUnitId = FindUnitIdByUnitGUID(killerGuid)
        if (killerUnitId ~= nil) then killerLevel = UnitLevel(killerUnitId) end
      end

      Controller:OnDeath(time(), HelperFunctions.GetCoordinatesByUnitId("player"), killerCatalogUnitId, killerLevel, killerEvent and killerEvent.environmentalType)
    end)
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

function EM.EventHandlers.PLAYER_ENTERING_WORLD(self, isLogin, isReload)
  self.PlayerEnteringWorldHasFired = true
  if (isLogin and not Api.IsWoWForever()) then
    local showAnnouncement = not self.PersistentPlayerInfo.ForeverBetaAnnouncementShownLastLogin
    self.PersistentPlayerInfo.ForeverBetaAnnouncementShownLastLogin = showAnnouncement
    if (showAnnouncement) then
      print("\124cFFFFD700AutoBiographer is now available on the WoW Forever Beta! For those with access to the Beta, if you wish to help by testing the addon and reporting any issues or feedback, it would be greatly appreciated. Thank you!\124r")
    end
  end
  AutoBiographer_TodoPanel:QueueRefresh()

  local playerGuid = UnitGUID("player")

  if (isLogin or isReload) then
    AceComm:RegisterComm(MM.AddonMessagePrefix, MM.OnAddonMessageReceived)
  end

  if (playerGuid and not self.PersistentPlayerInfo.PlayerGuid) then
    -- This is probably the first time this character has logged in while using the addon.
    self.PersistentPlayerInfo.PlayerGuid = playerGuid
    
    if (UnitLevel("player") == 1 and UnitXP("player") == 0) then
      print("\124cFFFFD700[AutoBiographer] Events and statistics are being tracked.")
    else
      print("\124cFFFFD700[AutoBiographer] Events and statistics are being tracked. Any events and statistics that occurred previously on this character are not tracked.")
    end
  elseif (playerGuid and self.PersistentPlayerInfo.PlayerGuid ~= playerGuid) then
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
                self.PersistentPlayerInfo.PlayerGuid = playerGuid
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
  self.TemporaryTimestamps.GamepadUIEnabled = nil
  self:UpdateGamepadUIState()
  self:UpdateGroupMemberInfo()
  self:SnapshotOtherPlayerAurasForKnownUnits()
  self:UpdatePlayerCampAuras(false)
  AutoBiographer_CampfireSharing:OnPlayerAuras(true)
  self:UpdatePlayerFlags()
  self:ScheduleDamageMeterSessionBaselines()
  if (Api.IsWoWForever()) then self.LastRestedExperiencePool = Api.GetRestedExperiencePool() end
  self:StartDistanceTracking()
  if (AutoBiographer_ClassActivity) then AutoBiographer_ClassActivity:Start() end
  self.GearTrackingReady = true
  self:UpdatePlayerGear()
  AutoBiographer_SnapshotManager:Resume()
end

function EM.EventHandlers.PLAYER_EQUIPMENT_CHANGED(self, slotId)
  self:UpdatePlayerGear(slotId)
end

function EM.EventHandlers.PLAYER_FLAGS_CHANGED(self, unitId)
  if (unitId == "player") then self:UpdatePlayerFlags() end
end

function EM.EventHandlers.PLAYER_REGEN_DISABLED(self)
  AutoBiographer_Milestones:PauseSharing()
  AutoBiographer_CampfireSharing:Pause()
end

function EM.EventHandlers.PLAYER_REGEN_ENABLED(self)
  AutoBiographer_Milestones:ResumeSharing()
  AutoBiographer_CampfireSharing:Resume()
  self:ScheduleDamageMeterCombatFinalization(self.CurrentDamageMeterSessionId)
  self:UpdatePlayerGear()
  if (self.GearTrackingReady and AutoBiographer_SnapshotManager) then AutoBiographer_SnapshotManager:Resume() end
  AutoBiographer_TodoPanel:QueueRefresh()
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
  AutoBiographer_Fishing:Stop()
  AutoBiographer_CampfireSharing:Reset()
  if (AutoBiographer_SnapshotManager) then AutoBiographer_SnapshotManager:Pause() end
  -- Equipment can already be unavailable here; keep the last known snapshot.
  self.GearTrackingReady = false
  self.GearTrackingGeneration = (self.GearTrackingGeneration or 0) + 1
  self.GearSnapshotRetryPending = false
  self.GearPendingUnequips = {}
  self:StopDistanceTracking()
  if (self.CampedPending) then
    self.CampedPending = false
    Controller:OnCamped()
  end
  self:UpdateTimestamps(self.PersistentPlayerInfo.CurrentZone, self.PersistentPlayerInfo.CurrentSubZone)
  if (AutoBiographer_ClassActivity) then AutoBiographer_ClassActivity:Stop() end
  self.TemporaryTimestamps.GamepadUIEnabled = nil
  self.PlayerFlags.GamepadUIEnabled = nil
end

function EM.EventHandlers.PLAYER_LEVEL_UP(self, newLevel)
  self:UpdateTimestamps(self.PersistentPlayerInfo.CurrentZone, self.PersistentPlayerInfo.CurrentSubZone)
  self.NewLevelToAddToHistory = newLevel
  
  local delay = 0.25
  C_Timer.After(delay, function()
    if (self.NewLevelToAddToHistory == nil) then return end

    -- The level-up response is printed below with time spent on the last level,
    -- rather than Blizzard's time on the newly reached level.
    EM:RequestTimePlayed(false)
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
  local questTitle = Api.GetQuestTitle(questId) or ("Quest " .. tostring(questId))
  Controller:OnQuestTurnedIn(time(), HelperFunctions.GetCoordinatesByUnitId("player"), questId, questTitle, xpGained, moneyGained)
  
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
  AutoBiographer_SnapshotManager:OnTimePlayed(totalTimePlayed)
  self.TimePlayedMessageLastTimestamp = GetTime()

  if (self.TimePlayedMessageChatFramesToRegister) then
    local chatFramesToRegister = self.TimePlayedMessageChatFramesToRegister
    local generation = self.TimePlayedMessageSuppressionGeneration
    -- Stay unregistered for the entire dispatch of this response; restoring
    -- here would let chat frames print the same TIME_PLAYED_MSG themselves.
    C_Timer.After(0, function()
      if (self.TimePlayedMessageSuppressionGeneration ~= generation or self.TimePlayedMessageChatFramesToRegister ~= chatFramesToRegister) then return end
      for i = 1, #chatFramesToRegister do
        _G["ChatFrame" .. chatFramesToRegister[i]]:RegisterEvent("TIME_PLAYED_MSG")
      end
      self.TimePlayedMessageChatFramesToRegister = nil
    end)
  end

  if self.NewLevelToAddToHistory ~= nil then
    local newLevel = self.NewLevelToAddToHistory
    Controller:OnLevelUp(time(), HelperFunctions.GetCoordinatesByUnitId("player"), newLevel, totalTimePlayed - levelTimePlayed)
    self.NewLevelToAddToHistory = nil

    if (AutoBiographer_Settings.Options["ShowTimePlayedOnLevelUp"]) then
      local function printSystemMessage(message)
        local systemColor = ChatTypeInfo and ChatTypeInfo["SYSTEM"]
        if (systemColor and DEFAULT_CHAT_FRAME) then
          DEFAULT_CHAT_FRAME:AddMessage(message, systemColor.r, systemColor.g, systemColor.b)
        else
          print(message)
        end
      end

      local previousLevel = Controller.CharacterData.Levels[newLevel - 1]
      local lastLevelTimePlayed = previousLevel and previousLevel.TimePlayedThisLevel
      printSystemMessage("Total time played: " .. HelperFunctions.SecondsToTimeString(totalTimePlayed))
      printSystemMessage("Time played last level: " .. (lastLevelTimePlayed and HelperFunctions.SecondsToTimeString(lastLevelTimePlayed) or "unavailable (not recorded)"))
    end
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
  --print("UNIT_COMBAT. " .. tostring(unitId) .. ", " .. tostring(action) .. ", " .. tostring(ind) .. ", " .. tostring(dmg) .. ", " .. tostring(dmgType))
  if (not dmg or dmg <= 0) then return end

  -- UNIT_COMBAT reports incoming effective amounts for the affected unit.
  -- WOUND is damage received and HEAL is healing received.
  if (unitId == "player") then
    if (action == "HEAL") then
      Controller:OnDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.HealingTakenRaw, nil, nil, nil, dmg, 0)
    elseif (action == "WOUND") then
      Controller:OnDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.DamageTakenRaw, nil, nil, nil, dmg, 0)
    end
  elseif (unitId == "pet" and action == "WOUND") then
    Controller:OnDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.PetDamageTakenRaw, nil, nil, nil, dmg, 0)
  end
end

function EM.EventHandlers.UNIT_AURA(self, unitId, updateInfo)
  if (self:IsSecretValue(unitId)) then return end
  if (unitId == "player") then self:UpdateClassActivity() end
  if (not Api.IsWoWForever()) then return end
  if (unitId == "player") then
    if (self.PlayerEnteringWorldHasFired) then
      self:UpdatePlayerCampAuras(true)
      AutoBiographer_CampfireSharing:OnPlayerAuras(false)
    end
  end
  self:OnUnitAura(unitId, updateInfo)
end

function EM.EventHandlers.UNIT_INVENTORY_CHANGED(self, unitId)
  if (not self:IsSecretValue(unitId) and unitId == "player") then self:UpdatePlayerGear() end
end

function EM.EventHandlers.UNIT_DIED(self, unitGuid)
  --print("UNIT_DIED. " .. tostring(unitGuid))
  if (not Api.IsWoWForever()) then return end

  local deadUnit = self:GetOrCreateDeadUnit(unitGuid, true)
  if (not deadUnit) then return end

  local unitId = FindUnitIdByUnitGUID(unitGuid)
  if (not unitId) then return end

  deadUnit.CanBeAttacked = UnitCanAttack("player", unitId)
  deadUnit.IsTapDenied = UnitIsTapDenied(unitId)

  local catalogUnitId = HelperFunctions.GetCatalogIdFromGuid(unitGuid)
  if (Controller:CatalogUnitIsIncomplete(catalogUnitId)) then
    local name, lastName = Api.GetUnitName(unitId)
    Controller:UpdateCatalogUnit(CatalogUnit.New(
      catalogUnitId,
      UnitClass(unitId),
      UnitClassification(unitId),
      UnitCreatureFamily(unitId),
      UnitCreatureType(unitId),
      name,
      lastName,
      UnitRace(unitId),
      nil,
      HelperFunctions.GetUnitTypeFromCatalogUnitId(catalogUnitId)
    ))
  end
end

function EM.EventHandlers.UNIT_FLAGS(self, unitId)
  --print("UNIT_FLAGS. " .. unitId)
  if (not self:IsSecretValue(unitId) and unitId == "player") then
    self:UpdatePlayerFlags()
    self:UpdateClassActivity()
  end
end

function EM.EventHandlers.UNIT_HEALTH(self, unitId)
  --print("UNIT_HEALTH. " .. unitId .. ". " .. tostring(UnitIsTapDenied(unitId)))
  if (not self:IsSecretValue(unitId) and unitId == "pet") then self:UpdateClassActivity() end
end

function EM.EventHandlers.UNIT_PET(self, unitId)
  if (not self:IsSecretValue(unitId) and unitId == "player") then self:UpdateClassActivity() end
end

function EM.EventHandlers.UI_ERROR_MESSAGE(self, errorType, message)
  AutoBiographer_Fishing:OnInfoMessage(message)
end

function EM.EventHandlers.UI_INFO_MESSAGE(self, messageType, message)
  AutoBiographer_Fishing:OnInfoMessage(message)
end

function EM.EventHandlers.UNIT_SPELLCAST_CHANNEL_START(self, unitId, castId, spellId, arg4, arg5)
  if (self:IsSecretValue(unitId) or unitId ~= "player") then return end
  --print("UNIT_SPELLCAST_CHANNEL_START. " .. unitId .. ", " .. tostring(arg2) .. ", " .. tostring(arg3) .. ", " .. tostring(arg4) .. ", " .. tostring(arg5))
  AutoBiographer_Fishing:OnChannelStart(spellId, arg4)
  self:OnStartedCasting(spellId)
  self:UpdateClassActivity()
end

function EM.EventHandlers.UNIT_SPELLCAST_CHANNEL_STOP(self, unitId, arg2, arg3, arg4, arg5)
  if (self:IsSecretValue(unitId) or unitId ~= "player") then return end
  --print("UNIT_SPELLCAST_CHANNEL_STOP. " .. unitId .. ", " .. tostring(arg2) .. ", " .. tostring(arg3) .. ", " .. tostring(arg4) .. ", " .. tostring(arg5))
  AutoBiographer_Fishing:OnChannelStop(arg3, arg5)
  self:OnStoppedCasting()
  self:UpdateClassActivity()
end

function EM.EventHandlers.UNIT_SPELLCAST_CHANNEL_UPDATE(self, unitId)
  if (self:IsSecretValue(unitId) or unitId ~= "player") then return end
  AutoBiographer_Fishing:OnChannelUpdate()
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

function EM.EventHandlers.UNIT_SPELLCAST_SENT(self, unitTarget, target, castGUID, spellID)
  --print("UNIT_SPELLCAST_SENT. " .. unitTarget .. ", " .. tostring(target) .. ", " .. tostring(castGUID) .. ", " .. tostring(spellID))
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
  if (self:IsSecretValue(unitId) or unitId ~= "player") then return end
  self:UpdateClassActivity()
  if (self:IsSecretValue(spellId)) then return end
  --print("UNIT_SPELLCAST_SUCCEEDED. " .. unitId .. ", " .. tostring(arg2) .. ", " .. tostring(arg3) .. ", " .. tostring(arg4) .. ", " .. tostring(arg5))
  
  local name, rank, icon, castTime, minRange, maxRange, id = Api.GetSpellInfo(spellId)
  Controller:OnSpellSuccessfullyCast(time(), HelperFunctions.GetCoordinatesByUnitId("player"), spellId, name, rank)
end

function EM.EventHandlers.UNIT_TARGET(self, unitId)
  
end

-- Optional state events still use the addon's normal event frame/dispatcher.
for _, eventName in ipairs({ "UPDATE_SHAPESHIFT_FORM", "UPDATE_SHAPESHIFT_FORMS", "UPDATE_STEALTH" }) do
  if (Api.IsEventAvailable(eventName, true)) then
    EM.EventHandlers[eventName] = function(self) self:UpdateClassActivity() end
  end
end

function EM.EventHandlers.PLAYER_FOCUS_CHANGED(self)
  self:SnapshotOtherPlayerAuras("focus")
end

function EM.EventHandlers.PLAYER_TARGET_CHANGED(self)
  self:SnapshotOtherPlayerAuras("target")
end

function EM.EventHandlers.UPDATE_EXHAUSTION(self)
  if (not Api.IsWoWForever() or not self.PlayerEnteringWorldHasFired) then return end
  local previousPool = self.LastRestedExperiencePool
  local currentPool = Api.GetRestedExperiencePool()
  self.LastRestedExperiencePool = currentPool
  -- Login/reload or unreadable data establishes a new baseline. Increases
  -- from resting/camping are not XP earned. On Forever, consuming the pool
  -- uses two pool points per bonus XP, including a partial final rested kill.
  if (previousPool == nil or currentPool == nil or currentPool >= previousPool) then return end
  Controller:OnGainedExperience(time(), HelperFunctions.GetCoordinatesByUnitId("player"),
    AutoBiographerEnum.ExperienceTrackingType.RestedBonus, (previousPool - currentPool) / 2)
end

function EM.EventHandlers.UPDATE_MOUSEOVER_UNIT(self)
  self:SnapshotOtherPlayerAuras("mouseover")
end

function EM.EventHandlers.ZONE_CHANGED(self)
  self:UpdatePlayerZone()
  AutoBiographer_TodoPanel:QueueRefresh()
end

function EM.EventHandlers.ZONE_CHANGED_INDOORS(self)
  self:UpdatePlayerZone()
  AutoBiographer_TodoPanel:QueueRefresh()
end

function EM.EventHandlers.ZONE_CHANGED_NEW_AREA(self)
  if (not self.ZoneChangedNewAreaEventHasFired) then
    self.ZoneChangedNewAreaEventHasFired = true
  end 
  
  self:UpdatePlayerZone()
  AutoBiographer_TodoPanel:QueueRefresh()
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

Api.RegisterTooltipHandler("OnTooltipSetItem", "Item", function(self, data)
  -- TooltipDataProcessor passes the item ID in data.  In particular, the
  -- comparison tooltips used by bags do not implement the legacy GetItem().
  local itemId = data and data.id
  local link = nil
  if (not itemId and self.GetItem) then
    local _, itemLink = self:GetItem()
    link = itemLink
    if (link) then
      itemId = HelperFunctions.GetItemIdFromTextWithChatItemLink(link)
    end
  end

  if (not itemId) then
    if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then print("[AutoBiographer] Unable to get itemId from tooltip.") end
    Controller:AddLog("Unable to get itemId from tooltip.", AutoBiographerEnum.LogLevel.Warning)
    return
  end

  itemId = tonumber(itemId)

  if (AutoBiographer_Settings.Options["ShowDiscoveryInfoOnToolTips"] and AutoBiographer_Databases.ItemDatabase and not AutoBiographer_Databases.ItemDatabase[itemId]) then
    self:AddLine("Added in Forever")
  end
  
  self:Show()
end)

Api.RegisterTooltipHandler("OnTooltipSetUnit", "Unit", function(self)
  if (not self.GetUnit) then return end
  local _, unitId = self:GetUnit()
  -- Forever can restrict tooltip identity.
  if (EM:IsSecretValue(unitId) or type(unitId) ~= "string" or unitId == "") then return end

  local unitGuid = UnitGUID(unitId)
  if (EM:IsSecretValue(unitGuid) or type(unitGuid) ~= "string" or unitGuid == "") then return end
  local success, catalogUnitId = pcall(HelperFunctions.GetCatalogIdFromGuid, unitGuid)
  if (not success or not catalogUnitId) then return end

  local canAttack = UnitCanAttack("player", unitId)
  local isPlayer = UnitIsPlayer(unitId)
  if (EM:IsSecretValue(canAttack) or EM:IsSecretValue(isPlayer)) then return end

	if (AutoBiographer_Settings.Options["ShowKillCountOnUnitToolTips"] and canAttack) then
    local killStatistics = Controller:GetAggregatedKillStatisticsByCatalogUnitId(catalogUnitId, 1, 9999)
    if (isPlayer) then
      GameTooltip:AddLine("Killed " .. tostring(KillStatistics.GetSum(killStatistics, { AutoBiographerEnum.KillTrackingType.TaggedKillingBlow, AutoBiographerEnum.KillTrackingType.UntaggedKillingBlow })) .. " times.")
    else
      GameTooltip:AddLine("Killed " .. tostring(KillStatistics.GetSum(killStatistics, { AutoBiographerEnum.KillTrackingType.TaggedAssist, AutoBiographerEnum.KillTrackingType.TaggedGroupAssistOrKillingBlow, AutoBiographerEnum.KillTrackingType.TaggedKillingBlow })) .. " times.")
    end
  end

  if (AutoBiographer_Settings.Options["ShowFriendlyPlayerToolTips"] and not canAttack and isPlayer) then
    local otherPlayerStatistics = Controller:GetAggregatedOtherPlayerStatisticsByCatalogUnitId(catalogUnitId, 1, 9999)
    local tooltipString = ""

    local duelsWon = OtherPlayerStatistics.GetSum(otherPlayerStatistics, { AutoBiographerEnum.OtherPlayerTrackingType.DuelsLostToPlayer })
    local duelsLost = OtherPlayerStatistics.GetSum(otherPlayerStatistics, { AutoBiographerEnum.OtherPlayerTrackingType.DuelsWonAgainstPlayer })
    if (duelsWon > 0 or duelsLost > 0) then
      tooltipString = tooltipString .. "Duels (W/L): " .. tostring(duelsWon) .. "/" .. tostring(duelsLost) .. ". "
    end

    local buffsGivenNotGrouped = OtherPlayerStatistics.GetSum(otherPlayerStatistics, { AutoBiographerEnum.OtherPlayerTrackingType.BuffsGivenToPlayerNotGrouped })
    local buffsGivenWhileGrouped = OtherPlayerStatistics.GetSum(otherPlayerStatistics, { AutoBiographerEnum.OtherPlayerTrackingType.BuffsGivenToPlayerWhileGrouped })
    if (buffsGivenNotGrouped > 0 or buffsGivenWhileGrouped > 0) then
      tooltipString = tooltipString .. "Buffs Given (Outside/In Group): " .. tostring(buffsGivenNotGrouped) .. "/" .. tostring(buffsGivenWhileGrouped) .. ". "
    end

    local timeGrouped = OtherPlayerStatistics.GetSum(otherPlayerStatistics, { AutoBiographerEnum.OtherPlayerTrackingType.TimeSpentGroupedWithPlayer })
    if (timeGrouped > 0) then
      tooltipString = tooltipString .. "Time Grouped: " .. HelperFunctions.SecondsToTimeString(timeGrouped, true) .. ". "
    end

    if (tooltipString ~= "") then
      GameTooltip:AddLine(tooltipString)
    end
	end

  if (AutoBiographer_Settings.Options["ShowDiscoveryInfoOnToolTips"] and HelperFunctions.GetUnitTypeFromCatalogUnitId(catalogUnitId) == AutoBiographerEnum.UnitType.Creature and
      AutoBiographer_Databases.NpcDatabase and not AutoBiographer_Databases.NpcDatabase[catalogUnitId]) then
    GameTooltip:AddLine("Added in Forever")
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

function EM:OnMessageSent(messageTrackingType, outgoingOnly, ...)
  if (not self.PlayerEnteringWorldHasFired) then return end

  -- INFORM events confirm our outgoing whispers; their GUID is the recipient.
  -- Other chat events echo everyone, so only count a readable local-player GUID.
  -- Never inspect or save the message text (which can also be secret).
  if (not outgoingOnly) then
    local senderGuid = select(12, ...)
    local playerGuid = UnitGUID("player")
    if (self:IsSecretValue(senderGuid) or self:IsSecretValue(playerGuid)) then return end
    if (not senderGuid or not playerGuid or senderGuid ~= playerGuid) then return end
  end

  local lineId = select(11, ...)
  if (not self:IsSecretValue(lineId) and type(lineId) == "number" and lineId > 0) then
    if (lineId == self.LastSentChatLineId) then return end
    self.LastSentChatLineId = lineId
  end
  Controller:OnMessageSent(messageTrackingType)
  return true
end

function EM:OnWhisper(outgoing, ...)
  if (not self.PlayerEnteringWorldHasFired) then return end
  -- WHISPER identifies the sender; WHISPER_INFORM identifies the recipient.
  -- Never inspect or persist the message text.
  local otherGuid = select(12, ...)
  local playerGuid = UnitGUID("player")
  if (self:IsSecretValue(otherGuid) or self:IsSecretValue(playerGuid) or
      type(otherGuid) ~= "string" or not playerGuid or otherGuid == playerGuid or
      not string.match(otherGuid, "^Player%-")) then return end
  local success, catalogUnitId = pcall(HelperFunctions.GetCatalogIdFromGuid, otherGuid)
  if (not success or not catalogUnitId) then return end

  -- Outgoing messages were already deduplicated by OnMessageSent. Keep incoming
  -- line IDs separate so receiving a whisper cannot affect sent-message totals.
  if (not outgoing) then
    local lineId = select(11, ...)
    if (not self:IsSecretValue(lineId) and type(lineId) == "number" and lineId > 0) then
      if (lineId == self.LastReceivedWhisperLineId) then return end
      self.LastReceivedWhisperLineId = lineId
    end
  end

  local fullName = select(2, ...)
  local name, lastName
  if (not self:IsSecretValue(fullName) and type(fullName) == "string" and fullName ~= "") then
    name = fullName
    if (Api.IsWoWForever()) then
      local firstName, surname = string.match(fullName, "^(%S+)%s+(.+)$")
      if (firstName) then name, lastName = firstName, surname end
    end
  end
  Controller:UpdateCatalogUnit(CatalogUnit.New(
    catalogUnitId, nil, nil, nil, nil, name, lastName, nil, nil, AutoBiographerEnum.UnitType.Player
  ))
  Controller:OnWhisper(catalogUnitId, outgoing)
end

function EM:OnStartedCasting(spellId)
  if (self.TemporaryTimestamps.StartedCasting) then
    Controller:AddTime(AutoBiographerEnum.TimeTrackingType.Casting, HelperFunctions.SubtractFloats(GetTime(), self.TemporaryTimestamps.StartedCasting), self.PersistentPlayerInfo.CurrentZone, self.PersistentPlayerInfo.CurrentSubZone)
  end
  
  self.TemporaryTimestamps.StartedCasting = GetTime()
  
  local name, rank, icon, castTime, minRange, maxRange, id = Api.GetSpellInfo(spellId)
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
  if (not showMessage) then self:SuppressTimePlayedMessages() end
  
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

function EM:StartDistanceTracking()
  self:StopDistanceTracking()
  self.DistanceTrackingActive = true
  local generation = self.DistanceTrackingGeneration
  self:UpdateTravelDistance()
  local function Sample()
    if (not self.DistanceTrackingActive or self.DistanceTrackingGeneration ~= generation) then return end
    self:UpdateTravelDistance()
    self:UpdateClassActivity()
    C_Timer.After(1, Sample)
  end
  C_Timer.After(1, Sample)
end

function EM:StopDistanceTracking()
  self.DistanceTrackingActive = false
  self.DistanceTrackingGeneration = self.DistanceTrackingGeneration + 1
  self.LastDistancePosition = nil
end

function EM:SuppressTimePlayedMessages()
  self.TimePlayedMessageSuppressionGeneration = self.TimePlayedMessageSuppressionGeneration + 1
  if (self.TimePlayedMessageChatFramesToRegister) then return end
  self.TimePlayedMessageChatFramesToRegister = {}
  for i = 1, 10 do
    local chatFrame = _G["ChatFrame" .. i]
    if (chatFrame and chatFrame:IsEventRegistered("TIME_PLAYED_MSG")) then
      table.insert(self.TimePlayedMessageChatFramesToRegister, i)
      chatFrame:UnregisterEvent("TIME_PLAYED_MSG")
    end
  end
end

function EM:UpdateClassActivity()
  if (AutoBiographer_ClassActivity) then AutoBiographer_ClassActivity:Update() end
end

function EM:UpdateGamepadUIState()
  self.PlayerFlags.GamepadUIEnabled = Api.IsGamepadUIEnabled()
  local startedAt = self.TemporaryTimestamps.GamepadUIEnabled
  if (self.PlayerFlags.GamepadUIEnabled) then
    if (not startedAt) then self.TemporaryTimestamps.GamepadUIEnabled = GetTime() end
  elseif (startedAt) then
    Controller:AddTime(AutoBiographerEnum.TimeTrackingType.GamepadUI, HelperFunctions.SubtractFloats(GetTime(), startedAt), self.PersistentPlayerInfo.CurrentZone, self.PersistentPlayerInfo.CurrentSubZone)
    self.TemporaryTimestamps.GamepadUIEnabled = nil
  end
end

function EM:UpdateGroupMemberInfo()
  -- Populate list of unit GUIDs in player's party/raid.
  local unitGuidsInGroup = {}
  local rosterIncomplete = false
  local function AddGroupMember(unitId)
    local guid = UnitGUID(unitId)
    if (self:IsSecretValue(guid)) then
      rosterIncomplete = true
      return
    end
    if (not guid or guid == self.PersistentPlayerInfo.PlayerGuid or unitGuidsInGroup[guid]) then return end
    unitGuidsInGroup[guid] = true

    -- Group-time tracking must catalog members itself; Forever has no combat
    -- log handler to populate these records for the Other Players window.
    local catalogUnitId = HelperFunctions.GetCatalogIdFromGuid(guid)
    local catalogUnit = Controller.CharacterData.Catalogs.UnitCatalog[catalogUnitId]
    if (Controller:CatalogUnitIsIncomplete(catalogUnitId) or catalogUnit.UType ~= AutoBiographerEnum.UnitType.Player) then
      local name, lastName = Api.GetUnitName(unitId)
      local class = UnitClass(unitId)
      local race = UnitRace(unitId)
      if (self:IsSecretValue(name)) then name = nil end
      if (self:IsSecretValue(class)) then class = nil end
      if (self:IsSecretValue(race)) then race = nil end
      if (name == "") then name = nil end
      Controller:UpdateCatalogUnit(CatalogUnit.New(
        catalogUnitId, class, nil, nil, nil, name, lastName, race, nil, AutoBiographerEnum.UnitType.Player
      ))
    end
  end

  for i = 1, 4 do AddGroupMember("party" .. i) end
  for i = 1, 40 do AddGroupMember("raid" .. i) end
  
  -- Save current timestamp for every unit in group.
  for k,v in pairs(unitGuidsInGroup) do
    if (not self.TemporaryTimestamps.OtherPlayerJoinedGroup[k]) then
      self.TemporaryTimestamps.OtherPlayerJoinedGroup[k] = GetTime()
    end
  end
  
  -- An unreadable GUID is not evidence that an existing member left.
  if (rosterIncomplete) then return end

  -- Add time in group for every unit that left the group.
  for k,v in pairs(self.TemporaryTimestamps.OtherPlayerJoinedGroup) do
    if (not unitGuidsInGroup[k]) then
      Controller:AddOtherPlayerInGroupTime(HelperFunctions.GetCatalogIdFromGuid(k), HelperFunctions.SubtractFloats(GetTime(), v))
      self.TemporaryTimestamps.OtherPlayerJoinedGroup[k] = nil
    end
  end
end

function EM:IsSecretValue(value)
  return issecretvalue and issecretvalue(value)
end

function EM:IsOtherPlayerAuraUnit(unitId)
  if (self:IsSecretValue(unitId) or not unitId or unitId == "player") then return false end

  local isPlayer = UnitIsPlayer(unitId)
  local isSelf = UnitIsUnit(unitId, "player")
  if (self:IsSecretValue(isPlayer) or self:IsSecretValue(isSelf)) then return false end
  return isPlayer and not isSelf
end

function EM:StoreOtherPlayerAura(auraState, auraData)
  if (self:IsSecretValue(auraData) or not auraData or self:IsSecretValue(auraData.auraInstanceID) or self:IsSecretValue(auraData.duration) or
      self:IsSecretValue(auraData.expirationTime) or self:IsSecretValue(auraData.spellId) or not auraData.auraInstanceID or not auraData.spellId) then
    return false
  end

  local aura = {
    Duration = auraData.duration,
    ExpirationTime = auraData.expirationTime,
    SpellId = auraData.spellId,
  }
  auraState.ByAuraInstanceId[auraData.auraInstanceID] = aura
  auraState.BySpellId[auraData.spellId] = aura
  return true
end

function EM:SnapshotOtherPlayerAuras(unitId)
  if (not Api.IsWoWForever() or not self:IsOtherPlayerAuraUnit(unitId)) then return end

  local unitGuid = UnitGUID(unitId)
  if (self:IsSecretValue(unitGuid) or not unitGuid) then return end

  local auraState = { ByAuraInstanceId = {}, BySpellId = {} }
  for index = 1, 255 do
    local auraData = Api.GetAuraDataByIndex(unitId, index, "HELPFUL")
    if (self:IsSecretValue(auraData)) then
      self.OtherPlayerAuraStates[unitGuid] = nil
      return
    end
    if (not auraData) then break end
    if (not self:StoreOtherPlayerAura(auraState, auraData)) then
      -- An incomplete baseline cannot tell us that a buff was absent.
      self.OtherPlayerAuraStates[unitGuid] = nil
      return
    end
  end
  self.OtherPlayerAuraStates[unitGuid] = auraState
end

function EM:SnapshotOtherPlayerAurasForGroup()
  for i = 1, 4 do
    self:SnapshotOtherPlayerAuras("party" .. i)
  end
  for i = 1, 40 do
    self:SnapshotOtherPlayerAuras("raid" .. i)
  end
end

function EM:SnapshotOtherPlayerAurasForKnownUnits()
  self:SnapshotOtherPlayerAuras("focus")
  self:SnapshotOtherPlayerAuras("mouseover")
  self:SnapshotOtherPlayerAuras("target")
  self:SnapshotOtherPlayerAurasForGroup()
end

function EM:ShouldTrackOtherPlayerBuff(previousAura)
  if (not previousAura) then return true end
  if (not previousAura.Duration or previousAura.Duration <= 0 or not previousAura.ExpirationTime) then return false end

  return previousAura.ExpirationTime - GetTime() < previousAura.Duration / 2
end

function EM:TrackOtherPlayerBuff(unitId)
  -- Check current group membership even when the recipient is target or mouseover.
  local inParty = UnitInParty(unitId)
  local raidIndex = UnitInRaid(unitId)
  if (self:IsSecretValue(inParty) or self:IsSecretValue(raidIndex)) then return end
  local isGroupedWithPlayer = inParty or raidIndex ~= nil

  local unitGuid = UnitGUID(unitId)
  if (self:IsSecretValue(unitGuid) or not unitGuid) then return end

  local success, catalogUnitId = pcall(HelperFunctions.GetCatalogIdFromGuid, unitGuid)
  if (not success or not catalogUnitId) then return end

  if (Controller:CatalogUnitIsIncomplete(catalogUnitId)) then
    local name, lastName = Api.GetUnitName(unitId)
    Controller:UpdateCatalogUnit(CatalogUnit.New(
      catalogUnitId,
      UnitClass(unitId),
      UnitClassification(unitId),
      UnitCreatureFamily(unitId),
      UnitCreatureType(unitId),
      name,
      lastName,
      UnitRace(unitId),
      nil,
      AutoBiographerEnum.UnitType.Player
    ))
  end

  Controller:OnBuffedOtherPlayer(catalogUnitId, UnitName(unitId), isGroupedWithPlayer)
end

-- These are the aura spells, not the spells used to place a totem. Matching
-- their localized names also covers higher ranks without listing every rank.
local totemBuffSpells = {
  [5672] = "Healing Stream",
  [5677] = "Mana Spring",
  [8072] = "Stoneskin",
  [8076] = "Strength of Earth",
  [8178] = "Grounding Totem Effect",
  [8182] = "Frost Resistance",
  [8185] = "Fire Resistance",
  [8230] = "Flametongue Totem Effect",
  [8515] = "Windfury Totem",
  [8836] = "Grace of Air",
  [10596] = "Nature Resistance",
  [15108] = "Windwall",
  [16191] = "Mana Tide",
  [25909] = "Tranquil Air",
}
local totemBuffNames

function EM:IsTotemBuff(auraData)
  if (self:IsSecretValue(auraData.spellId)) then return true end
  if (totemBuffSpells[auraData.spellId]) then return true end
  if (not totemBuffNames) then
    totemBuffNames = {}
    for spellId, name in pairs(totemBuffSpells) do
      totemBuffNames[name] = true
      local localizedName = Api.GetSpellInfo(spellId)
      if (not self:IsSecretValue(localizedName) and localizedName) then
        totemBuffNames[localizedName] = true
      end
    end
  end
  local name = auraData.name
  if (self:IsSecretValue(name) or not name) then
    name = auraData.spellId and Api.GetSpellInfo(auraData.spellId)
  end
  if (self:IsSecretValue(name) or not name) then return true end
  return totemBuffNames[name] or string.find(name, "Totem", 1, true) ~= nil
end

function EM:TryTrackOtherPlayerBuff(unitId, auraData, previousAura, isRefresh)
  if (self:IsSecretValue(auraData) or not auraData or self:IsSecretValue(auraData.isHelpful) or self:IsSecretValue(auraData.sourceUnit) or
      self:IsSecretValue(auraData.expirationTime)) then
    return
  end
  if (not auraData.isHelpful or auraData.sourceUnit ~= "player") then return end
  if (self:IsTotemBuff(auraData)) then return end
  if (isRefresh and (not previousAura or not auraData.expirationTime or not previousAura.ExpirationTime or
      auraData.expirationTime <= previousAura.ExpirationTime)) then return end
  if (not self:ShouldTrackOtherPlayerBuff(previousAura)) then return end

  self:TrackOtherPlayerBuff(unitId)
end

function EM:OnUnitAura(unitId, updateInfo)
  if (not self:IsOtherPlayerAuraUnit(unitId)) then return end

  local unitGuid = UnitGUID(unitId)
  if (self:IsSecretValue(unitGuid) or not unitGuid) then return end

  local auraState = self.OtherPlayerAuraStates[unitGuid]
  -- Check secrecy before testing the boolean or iterating any update lists.
  -- Invalidate the baseline because we cannot observe these aura changes.
  if (self:IsSecretValue(updateInfo)) then
    self.OtherPlayerAuraStates[unitGuid] = nil
    return
  end
  if (updateInfo and (self:IsSecretValue(updateInfo.isFullUpdate) or self:IsSecretValue(updateInfo.addedAuras) or
      self:IsSecretValue(updateInfo.updatedAuraInstanceIDs) or self:IsSecretValue(updateInfo.removedAuraInstanceIDs))) then
    self.OtherPlayerAuraStates[unitGuid] = nil
    return
  end
  if (not auraState or not updateInfo or updateInfo.isFullUpdate) then
    self:SnapshotOtherPlayerAuras(unitId)
    return
  end

  for _, auraData in ipairs(updateInfo.addedAuras or {}) do
    if (self:IsSecretValue(auraData) or not auraData or self:IsSecretValue(auraData.isHelpful)) then
      self.OtherPlayerAuraStates[unitGuid] = nil
      return
    end
    if (auraData.isHelpful) then
      local previousAura = not self:IsSecretValue(auraData.spellId) and auraState.BySpellId[auraData.spellId] or nil
      if (not self:StoreOtherPlayerAura(auraState, auraData)) then
        self.OtherPlayerAuraStates[unitGuid] = nil
        return
      end
      self:TryTrackOtherPlayerBuff(unitId, auraData, previousAura, false)
    end
  end

  for _, auraInstanceId in ipairs(updateInfo.updatedAuraInstanceIDs or {}) do
    if (not self:IsSecretValue(auraInstanceId)) then
      local previousAura = auraState.ByAuraInstanceId[auraInstanceId]
      local auraData = Api.GetAuraDataByAuraInstanceID(unitId, auraInstanceId)
      if (self:IsSecretValue(auraData)) then
        self.OtherPlayerAuraStates[unitGuid] = nil
        return
      end
      if (previousAura and auraData) then
        if (not self:StoreOtherPlayerAura(auraState, auraData)) then
          self.OtherPlayerAuraStates[unitGuid] = nil
          return
        end
        self:TryTrackOtherPlayerBuff(unitId, auraData, previousAura, true)
      end
    else
      self.OtherPlayerAuraStates[unitGuid] = nil
      return
    end
  end

  for _, auraInstanceId in ipairs(updateInfo.removedAuraInstanceIDs or {}) do
    if (not self:IsSecretValue(auraInstanceId)) then
      local previousAura = auraState.ByAuraInstanceId[auraInstanceId]
      auraState.ByAuraInstanceId[auraInstanceId] = nil
      if (previousAura and auraState.BySpellId[previousAura.SpellId] == previousAura) then
        auraState.BySpellId[previousAura.SpellId] = nil
      end
    else
      self.OtherPlayerAuraStates[unitGuid] = nil
      return
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

function EM:UpdatePlayerCampAuras(trackChanges)
  if (not Api.IsWoWForever()) then return end
  if (not trackChanges or not self.PlayerCampTrackingStartedAt) then
    self.PlayerCampTrackingStartedAt = GetTime()
  end

  -- Read both buffs and debuffs. Incremental UNIT_AURA data may be secret,
  -- and only these two aura states are needed to identify completed rests.
  local snapshot = { HasBoostedRest = false }
  for _, filter in ipairs({ "HELPFUL", "HARMFUL" }) do
    for index = 1, 255 do
      local auraData = Api.GetAuraDataByIndex("player", index, filter)
      if (self:IsSecretValue(auraData)) then
        self.PlayerCampAuraSnapshot = nil
        return
      end
      if (not auraData) then break end
      if (self:IsSecretValue(auraData.spellId)) then
        self.PlayerCampAuraSnapshot = nil
        return
      end
      if (auraData.spellId == 1229741) then -- Camp Benefits
        local expirationTime = auraData.expirationTime
        if (self:IsSecretValue(expirationTime) or type(expirationTime) ~= "number") then
          self.PlayerCampAuraSnapshot = nil
          return
        end
        snapshot.CampBenefitsExpirationTime = expirationTime
        if (not self:IsSecretValue(auraData.duration) and type(auraData.duration) == "number") then
          snapshot.CampBenefitsDuration = auraData.duration
        end
        if (not self:IsSecretValue(auraData.auraInstanceID) and type(auraData.auraInstanceID) == "number") then
          snapshot.CampBenefitsAuraInstanceId = auraData.auraInstanceID
        end
      elseif (auraData.spellId == 1229451) then -- Boosted Rest: additions only, never refreshes.
        snapshot.HasBoostedRest = true
        if (not self:IsSecretValue(auraData.auraInstanceID) and type(auraData.auraInstanceID) == "number") then
          snapshot.BoostedRestAuraInstanceId = auraData.auraInstanceID
        end
        if (not self:IsSecretValue(auraData.expirationTime) and type(auraData.expirationTime) == "number") then
          snapshot.BoostedRestExpirationTime = auraData.expirationTime
        end
        if (not self:IsSecretValue(auraData.duration) and type(auraData.duration) == "number") then
          snapshot.BoostedRestDuration = auraData.duration
        end
      end
    end
  end

  local previousSnapshot = self.PlayerCampAuraSnapshot
  self.PlayerCampAuraSnapshot = snapshot
  -- An aura can be omitted from combat-time scans without actually ending.
  -- Compare positive observations with the last confirmed benefits, not with
  -- a possibly empty previous scan. Keep this history in memory across gaps.
  local history = self.PlayerCampAuraHistory or {}
  local benefitsReceived = snapshot.CampBenefitsExpirationTime and
    (not history.CampBenefitsExpirationTime or snapshot.CampBenefitsExpirationTime > history.CampBenefitsExpirationTime or
      (snapshot.CampBenefitsAuraInstanceId and history.CampBenefitsAuraInstanceId and
        snapshot.CampBenefitsAuraInstanceId ~= history.CampBenefitsAuraInstanceId))
  local boostedRestReceived = snapshot.HasBoostedRest and
    (not history.HasBoostedRest or
      (snapshot.BoostedRestAuraInstanceId and history.BoostedRestAuraInstanceId and
        snapshot.BoostedRestAuraInstanceId ~= history.BoostedRestAuraInstanceId) or
      ((not snapshot.BoostedRestAuraInstanceId or not history.BoostedRestAuraInstanceId) and
        snapshot.BoostedRestExpirationTime and history.BoostedRestExpirationTime and
        snapshot.BoostedRestExpirationTime > history.BoostedRestExpirationTime))
  -- The login scan can be empty before auras finish loading. A later first
  -- observation is still a baseline if the buff was applied before entry.
  local function AppliedSinceEntry(expirationTime, duration, previouslyObserved)
    if (expirationTime and duration and duration > 0) then
      return expirationTime - duration >= self.PlayerCampTrackingStartedAt
    end
    -- Without readable timing, do not count a previously unseen login buff.
    return previouslyObserved
  end
  local newBenefits = benefitsReceived and AppliedSinceEntry(snapshot.CampBenefitsExpirationTime,
    snapshot.CampBenefitsDuration, history.CampBenefitsExpirationTime ~= nil)
  local newBoostedRest = boostedRestReceived and AppliedSinceEntry(snapshot.BoostedRestExpirationTime,
    snapshot.BoostedRestDuration, history.HasBoostedRest == true)
  if (snapshot.CampBenefitsExpirationTime) then
    history.CampBenefitsExpirationTime = benefitsReceived and snapshot.CampBenefitsExpirationTime or
      math.max(history.CampBenefitsExpirationTime, snapshot.CampBenefitsExpirationTime)
    if (snapshot.CampBenefitsAuraInstanceId or benefitsReceived) then
      history.CampBenefitsAuraInstanceId = snapshot.CampBenefitsAuraInstanceId
    end
  end
  if (snapshot.HasBoostedRest) then
    history.HasBoostedRest = true
    if (snapshot.BoostedRestAuraInstanceId or boostedRestReceived) then
      history.BoostedRestAuraInstanceId = snapshot.BoostedRestAuraInstanceId
    end
    if (snapshot.BoostedRestExpirationTime) then
      history.BoostedRestExpirationTime = boostedRestReceived and snapshot.BoostedRestExpirationTime or
        math.max(history.BoostedRestExpirationTime or snapshot.BoostedRestExpirationTime, snapshot.BoostedRestExpirationTime)
    end
  end
  self.PlayerCampAuraHistory = history
  -- Login/reload and the first readable snapshot after secret data are baselines.
  if (not trackChanges or not previousSnapshot) then return end
  if (not newBenefits and not newBoostedRest) then return end
  if (self.CampedPending) then return end

  -- Combine both benefits into one completed rest, even across separate aura events.
  self.CampedPending = true
  C_Timer.After(0.25, function()
    if (not self.CampedPending) then return end
    self.CampedPending = false
    Controller:OnCamped()
  end)
end

function EM:UpdatePlayerGear(slotId, retryCount)
  if (not self.GearTrackingReady or not Controller.CharacterData.Gear) then return end
  if (self:IsSecretValue(slotId)) then slotId = nil end
  if (slotId ~= nil and (type(slotId) ~= "number" or slotId < 0 or slotId > 19 or slotId ~= math.floor(slotId))) then return end

  local timestamp = time()
  local incomplete = false
  self.GearPendingUnequips = self.GearPendingUnequips or {}
  -- Include the legacy ammo/ranged slots as well as armor, weapons and jewelry.
  for slot = slotId or 0, slotId or 19 do
    local itemId = Api.GetEquippedItemId(slot)
    if (itemId == nil) then
      incomplete = true
    elseif (itemId == 0 and (Controller.CharacterData.Gear.Snapshot[slot] or 0) > 0) then
      -- During login, inventory can briefly report every equipped slot empty.
      -- Preserve known gear until a later read confirms the slot stayed empty.
      if (not self.GearPendingUnequips[slot]) then
        local pendingSlotId = slot
        local pending = { Timestamp = timestamp }
        local generation = self.GearTrackingGeneration
        self.GearPendingUnequips[slot] = pending
        C_Timer.After(1, function()
          if (not self.GearTrackingReady or generation ~= self.GearTrackingGeneration or
            self.GearPendingUnequips[pendingSlotId] ~= pending) then return end
          self.GearPendingUnequips[pendingSlotId] = nil
          local currentItemId = Api.GetEquippedItemId(pendingSlotId)
          if (currentItemId == 0) then
            Controller:OnEquippedItem(pending.Timestamp, pendingSlotId, 0)
          elseif (currentItemId ~= nil) then
            Controller:OnEquippedItem(time(), pendingSlotId, currentItemId)
          else
            self:UpdatePlayerGear(pendingSlotId)
          end
        end)
      end
    else
      self.GearPendingUnequips[slot] = nil
      Controller:OnEquippedItem(timestamp, slot, itemId)
    end
  end

  -- Never treat a failed/secret read as an unequip. Retry briefly when data
  -- is unavailable; inventory changes and leaving combat also rescan it.
  if (incomplete and not self.GearSnapshotRetryPending and (retryCount or 0) < 5) then
    self.GearSnapshotRetryPending = true
    local generation = self.GearTrackingGeneration
    C_Timer.After(0.5, function()
      if (not self.GearTrackingReady or generation ~= self.GearTrackingGeneration) then return end
      self.GearSnapshotRetryPending = false
      self:UpdatePlayerGear(nil, (retryCount or 0) + 1)
    end)
  end
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

function EM:FinalizeKill(unitGuid)
  local deadUnit = deadUnits[unitGuid]
  deadUnits[unitGuid] = nil
  if (not deadUnit or deadUnit.CanBeAttacked == false) then return end

  local inInstance = IsInInstance()
  local playerHasTag = deadUnit.IsTapDenied == false or inInstance
  if (not playerHasTag and not deadUnit.KilledByPlayer) then return end

  local success, catalogUnitId = pcall(HelperFunctions.GetCatalogIdFromGuid, unitGuid)
  if (not success or not catalogUnitId) then return end

  if (not Controller.CharacterData.Catalogs.UnitCatalog[catalogUnitId]) then
    Controller:UpdateCatalogUnit(CatalogUnit.New(
      catalogUnitId,
      nil,
      nil,
      nil,
      nil,
      nil,
      nil,
      nil,
      nil,
      HelperFunctions.GetUnitTypeFromCatalogUnitId(catalogUnitId)
    ))
  end

  local kill = Kill.New(false, playerHasTag and not deadUnit.KilledByPlayer, deadUnit.KilledByPlayer, playerHasTag, catalogUnitId, nil)
  Controller:OnKill(time(), HelperFunctions.GetCoordinatesByUnitId("player"), kill)
end

function EM:GetOrCreateDeadUnit(unitGuid, shouldScheduleFinalization)
  if (not unitGuid or (issecretvalue and issecretvalue(unitGuid))) then return nil end

  local deadUnit = deadUnits[unitGuid]
  if (not deadUnit) then
    deadUnit = {}
    deadUnits[unitGuid] = deadUnit
  end

  if (shouldScheduleFinalization and not deadUnit.FinalizeScheduled) then
    deadUnit.FinalizeScheduled = true
    C_Timer.After(1, function()
      EM:FinalizeKill(unitGuid)
    end)
  end

  return deadUnit
end

function EM:ForEachDamageMeterBreakdown(sessionId, callback)
  local playerGuid = UnitGUID("player")
  if (not playerGuid or not Enum or not Enum.DamageMeterType) then return end

  local function GetPlainMeterNumber(value)
    if (issecretvalue and issecretvalue(value)) then return nil end
    return tonumber(value) or 0
  end

  local function ForEachAbilityBreakdown(meterType, category)
    local source = Api.GetDamageMeterSessionSourceById(sessionId, meterType, playerGuid, nil)
    if (not source or not source.combatSpells or #source.combatSpells == 0) then return end

    for _, spell in ipairs(source.combatSpells) do
      local spellName = Api.GetSpellInfo(spell.spellID) or ("Spell " .. tostring(spell.spellID))
      local creatureName = nil
      if (not self:IsSecretValue(spell.creatureName) and spell.creatureName ~= nil and spell.creatureName ~= "") then
        creatureName = spell.creatureName
      end
      local amount = GetPlainMeterNumber(spell.totalAmount)
      local over = GetPlainMeterNumber(spell.overkillAmount)
      if (amount ~= nil and over ~= nil) then callback(category, nil, spell.spellID, spellName, amount, over, creatureName) end
    end
  end

  local function ForEachDamageTakenBreakdown()
    local source = Api.GetDamageMeterSessionSourceById(sessionId, Enum.DamageMeterType.DamageTaken, playerGuid, nil)
    if (not source or not source.combatSpells or #source.combatSpells == 0) then return end

    for _, spell in ipairs(source.combatSpells) do
      local details = spell.combatSpellDetails or {}
      local sourceName = tostring(details.unitName or spell.creatureName or "Unknown source")
      local spellName = Api.GetSpellInfo(spell.spellID) or details.spellName or ("Spell " .. tostring(spell.spellID))
      local amount = GetPlainMeterNumber(spell.totalAmount)
      local over = GetPlainMeterNumber(spell.overkillAmount)
      if (amount ~= nil and over ~= nil) then
        callback(AutoBiographerEnum.DamageOrHealingCategory.DamageTaken, sourceName, spell.spellID, spellName, amount, over)
      end
    end
  end

  ForEachAbilityBreakdown(Enum.DamageMeterType.DamageDone, AutoBiographerEnum.DamageOrHealingCategory.DamageDealt)
  ForEachAbilityBreakdown(Enum.DamageMeterType.HealingDone, AutoBiographerEnum.DamageOrHealingCategory.HealingDealt)
  ForEachDamageTakenBreakdown()
end

function EM:GetDamageMeterRecordedTotal(sessionId, category, unitName, spellId)
  if (self.DamageMeterRecordedTotals[sessionId] == nil) then self.DamageMeterRecordedTotals[sessionId] = {} end
  if (self.DamageMeterRecordedTotals[sessionId][category] == nil) then self.DamageMeterRecordedTotals[sessionId][category] = {} end

  local sourceKey = unitName or ""
  local recordedBySource = self.DamageMeterRecordedTotals[sessionId][category]
  if (recordedBySource[sourceKey] == nil) then recordedBySource[sourceKey] = {} end
  if (recordedBySource[sourceKey][spellId] == nil) then recordedBySource[sourceKey][spellId] = DamageBreakdown.New() end

  return recordedBySource[sourceKey][spellId]
end

function EM:InitializeDamageMeterSessionBaselines()
  self.DamageMeterBaselineInitializationPending = false
  self.DamageMeterBaselinesInitialized = true
  if (not Api.IsWoWForever()) then return end

  -- Blizzard retains these sessions through reloads and relogins, while this
  -- addon's delta cache is intentionally in-memory only.  Record the current
  -- values as a baseline so a later update contributes only new values.
  local sessionIds = {}
  for _, session in pairs(Api.GetDamageMeterSessions() or {}) do
    local sessionId = tonumber(session.sessionID)
    if (sessionId and sessionId > 0) then table.insert(sessionIds, sessionId) end
  end
  table.sort(sessionIds, function(a, b) return a > b end)

  for index = 1, math.min(#sessionIds, damageMeterSessionRetentionCount) do
    local sessionId = sessionIds[index]
    self:ForEachDamageMeterBreakdown(sessionId, function(category, unitName, spellId, _, amount, over)
      local recorded = self:GetDamageMeterRecordedTotal(sessionId, category, unitName, spellId)
      recorded.Amount = amount
      recorded.Over = over
    end)
  end

  self.CurrentDamageMeterSessionId = sessionIds[1]
  self:TrimDamageMeterRecordedTotals()
end

function EM:OnDamageMeterCombatSessionUpdated(meterType, sessionId)
  -- WoW Forever follows each completed-session update with a session ID of 0
  -- when it clears the current session.  Zero is not a queryable combat
  -- session, so retain the most recent completed session instead.
  if (not sessionId or sessionId <= 0) then return end

  self.CurrentDamageMeterSessionId = sessionId
  if (not UnitAffectingCombat("player")) then
    self:ScheduleDamageMeterCombatFinalization(sessionId)
  end
end

function EM:OnDamageMeterCurrentSessionUpdated()
  if (not UnitAffectingCombat("player")) then
    self:ScheduleDamageMeterCombatFinalization(self.CurrentDamageMeterSessionId)
  end
end

function EM:OnDamageMeterReset()
  -- This resets only our temporary delta cache.  Historical AutoBiographer
  -- statistics remain intact when the Blizzard damage meter is reset.
  self.CurrentDamageMeterSessionId = nil
  self.DamageMeterRecordedTotals = {}
  self.DamageMeterResetGeneration = self.DamageMeterResetGeneration + 1
  self.PendingDamageMeterFinalizationSessionId = nil
end

function EM:ScheduleDamageMeterCombatFinalization(sessionId)
  if (not sessionId or sessionId <= 0 or sessionId == self.PendingDamageMeterFinalizationSessionId) then return end

  self.PendingDamageMeterFinalizationSessionId = sessionId
  local resetGeneration = self.DamageMeterResetGeneration
  C_Timer.After(0.05, function()
    if (resetGeneration ~= EM.DamageMeterResetGeneration) then return end
    if (EM.PendingDamageMeterFinalizationSessionId == sessionId) then
      EM.PendingDamageMeterFinalizationSessionId = nil
    end
    EM:FinalizeDamageMeterCombat(sessionId)
  end)
end

function EM:FinalizeDamageMeterCombat(sessionId)
  if (not Api.IsWoWForever() or not self.DamageMeterBaselinesInitialized or not sessionId or sessionId <= 0) then return end

  self:ForEachDamageMeterBreakdown(sessionId, function(category, unitName, spellId, spellName, amount, over, creatureName)
    local recorded = self:GetDamageMeterRecordedTotal(sessionId, category, unitName, spellId)
    local amountDelta = amount - recorded.Amount
    local overDelta = over - recorded.Over
    if (amountDelta > 0 or overDelta > 0) then
      Controller:OnDamageOrHealing(category, unitName, spellId, spellName, math.max(amountDelta, 0), math.max(overDelta, 0), creatureName)
    end

    recorded.Amount = math.max(recorded.Amount, amount)
    recorded.Over = math.max(recorded.Over, over)
  end)
  self:TrimDamageMeterRecordedTotals()
end

function EM:ScheduleDamageMeterSessionBaselines()
  if (self.DamageMeterBaselinesInitialized or self.DamageMeterBaselineInitializationPending) then return end

  self.DamageMeterBaselineInitializationPending = true
  C_Timer.After(0, function()
    EM:InitializeDamageMeterSessionBaselines()
  end)
end

function EM:TrimDamageMeterRecordedTotals()
  local sessionIds = {}
  for sessionId in pairs(self.DamageMeterRecordedTotals) do
    table.insert(sessionIds, sessionId)
  end
  table.sort(sessionIds, function(a, b) return a > b end)

  for index = damageMeterSessionRetentionCount + 1, #sessionIds do
    self.DamageMeterRecordedTotals[sessionIds[index]] = nil
  end
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
  AutoBiographer_Fishing:Flush(zone, subZone)
  if (AutoBiographer_ClassActivity) then AutoBiographer_ClassActivity:Flush(zone, subZone) end
  -- Afk
  if (self.TemporaryTimestamps.MarkedAfk) then
    Controller:AddTime(AutoBiographerEnum.TimeTrackingType.Afk, HelperFunctions.SubtractFloats(GetTime(), self.TemporaryTimestamps.MarkedAfk), zone, subZone)
    self.TemporaryTimestamps.MarkedAfk = GetTime()
  end

  -- Casting
  if (self.TemporaryTimestamps.StartedCasting) then
    Controller:AddTime(AutoBiographerEnum.TimeTrackingType.Casting, HelperFunctions.SubtractFloats(GetTime(), self.TemporaryTimestamps.StartedCasting), zone, subZone)
    self.TemporaryTimestamps.StartedCasting = GetTime()
  end
  
  -- DeadOrGhost
  if (self.TemporaryTimestamps.Died) then
    Controller:AddTime(AutoBiographerEnum.TimeTrackingType.DeadOrGhost, HelperFunctions.SubtractFloats(GetTime(), self.TemporaryTimestamps.Died), zone, subZone)
    self.TemporaryTimestamps.Died = GetTime()
  end
  
  -- Gamepad UI
  if (self.TemporaryTimestamps.GamepadUIEnabled) then
    Controller:AddTime(AutoBiographerEnum.TimeTrackingType.GamepadUI, HelperFunctions.SubtractFloats(GetTime(), self.TemporaryTimestamps.GamepadUIEnabled), zone, subZone)
    self.TemporaryTimestamps.GamepadUIEnabled = GetTime()
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

function EM:UpdateTravelDistance()
  if (not self.DistanceTrackingActive) then return end
  local x, y, instanceId = Api.GetPlayerWorldPosition()
  local trackingType = x and Api.GetTravelTrackingType()
  if (x == nil or trackingType == nil) then
    self.LastDistancePosition = nil
    return
  end
  local now = GetTime()
  local levelNum = Controller:GetCurrentLevelNum()
  local previous = self.LastDistancePosition
  self.LastDistancePosition = { X = x, Y = y, InstanceId = instanceId,
    Timestamp = now, TrackingType = trackingType, LevelNum = levelNum }
  if (not previous or previous.InstanceId ~= instanceId or previous.TrackingType ~= trackingType or previous.LevelNum ~= levelNum) then return end
  local elapsed = now - previous.Timestamp
  -- Allow scheduling jitter around the one-second interval, but do not bridge
  -- loading screens, long frame stalls, or missing samples.
  if (elapsed <= 0 or elapsed > 2) then return end
  local deltaX, deltaY = x - previous.X, y - previous.Y
  local yards = math.sqrt(deltaX * deltaX + deltaY * deltaY)
  local maximumSpeeds = {
    [AutoBiographerEnum.DistanceTrackingType.FlightPath] = 200,
    [AutoBiographerEnum.DistanceTrackingType.Ghost] = 40,
    [AutoBiographerEnum.DistanceTrackingType.Mounted] = 70,
    [AutoBiographerEnum.DistanceTrackingType.OnFoot] = 35,
    [AutoBiographerEnum.DistanceTrackingType.Swimming] = 35,
  }
  -- Broad speed limits allow normal movement and reject teleport-like jumps.
  -- Every rejected segment becomes the next baseline, never a delayed jump.
  if (yards > (maximumSpeeds[trackingType] or 35) * elapsed + 2) then return end
  Controller:AddDistance(trackingType, yards)
end

function EM:WasTradeRecentlyMade()
  return self.TradeInfo and not self.TradeInfo.Canceled and (not self.TradeInfo.Closed or GetTime() - self.TradeInfo.ClosedTimestamp < 1)
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
    _G["AUTOBIOGRAPHER_GEAR_CHAR"] = nil
    _G["AUTOBIOGRAPHER_LEVELS_CHAR"] = nil
    _G["AUTOBIOGRAPHER_SNAPSHOTS_CHAR"] = nil
    _G["AUTOBIOGRAPHER_INFO_CHAR"] = nil
    _G["AUTOBIOGRAPHER_TODOS_CHAR"] = nil
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
  print("[AutoBiographer] Test")

  local creatureTypesKilled = 0
  for _, unit in pairs(Controller.CharacterData.Catalogs.UnitCatalog) do
    if (unit.Killed and unit.UType == AutoBiographerEnum.UnitType.Creature) then
      creatureTypesKilled = creatureTypesKilled + 1
    end
  end
  print("[AutoBiographer] Creature types killed: " .. creatureTypesKilled)
end
