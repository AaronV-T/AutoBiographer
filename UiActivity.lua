AutoBiographer_UiActivity = {
  Active = false,
  States = {},
  Frames = {},
  HookedFrames = {},
  PendingStatistics = {},
  Generation = 0,
  StatisticsKey = "UiStatistics",
}

local Activity = AutoBiographer_UiActivity
local Controller = AutoBiographer_Controller
local Api = AutoBiographer_Api
local Elements = AutoBiographerEnum.UiElement

local function ShopVisibility()
  local available, unreadable = false, false
  -- Shop frames live in Blizzard's isolated store environment.
  local readers = { StoreFrame_IsShown, CatalogShopInboundInterface and CatalogShopInboundInterface.IsShown }
  for _, reader in pairs(readers) do
    if (type(reader) == "function") then
      available = true
      local success, visible = pcall(reader)
      -- An unused shop can have no visibility attribute yet; nil means hidden.
      if (success and not (issecretvalue and issecretvalue(visible)) and (visible == nil or type(visible) == "boolean")) then
        if (visible) then return true, true end
      else
        unreadable = true
      end
    end
  end
  if (unreadable) then return nil, true end
  return false, available
end

Activity.Definitions = {
  { Id = Elements.AccountCollections, Name = "Account Collections", Frames = { "CollectionsJournal" } },
  { Id = Elements.AddonManagement, Name = "AddOn Management", Frames = { "AddonList" } },
  { Id = Elements.AuctionHouse, Name = "Auction House", Frames = { "AuctionHouseFrame", "AuctionFrame" } },
  { Id = Elements.Bags, Name = "Bags / Inventory", Frames = { "ContainerFrameCombinedBags" } },
  { Id = Elements.Bank, Name = "Bank", Frames = { "BankFrame" } },
  { Id = Elements.Character, Name = "Character", Frames = { "CharacterFrame" } },
  { Id = Elements.CustomerSupport, Name = "Customer Support", Frames = { "HelpFrame" } },
  { Id = Elements.EditMode, Name = "Edit Mode", Frames = { "EditModeManagerFrame" } },
  { Id = Elements.GroupFinder, Name = "Group Finder", Frames = { "LFGParentFrame", "PVEFrame" } },
  { Id = Elements.GuildCommunities, Name = "Guild & Communities", Frames = { "CommunitiesFrame", "GuildFrame" } },
  { Id = Elements.Legacy, Name = "Legacy", Frames = { "LegacySystemFrame" } },
  { Id = Elements.Loot, Name = "Loot", Frames = { "LootFrame" } },
  { Id = Elements.Macros, Name = "Macros", Frames = { "MacroFrame" } },
  { Id = Elements.Mailbox, Name = "Mailbox", Frames = { "MailFrame" } },
  { Id = Elements.Merchant, Name = "Merchant", Frames = { "MerchantFrame" } },
  { Id = Elements.Options, Name = "Options", Frames = { "SettingsPanel", "InterfaceOptionsFrame", "VideoOptionsFrame" } },
  { Id = Elements.Professions, Name = "Professions / Crafting", Frames = { "ProfessionsFrame", "TradeSkillFrame", "CraftFrame" } },
  { Id = Elements.QuestLog, Name = "Quest Log", Frames = { "QuestLogFrame", "QuestMapFrame" } },
  { Id = Elements.Shop, Name = "Shop", Frames = { "StoreFrame", "CatalogShopFrame" }, GetVisibility = ShopVisibility },
  { Id = Elements.Spellbook, Name = "Spellbook", Frames = { "SpellBookFrame", "PlayerSpellsFrame.SpellBookFrame" } },
  { Id = Elements.Talents, Name = "Talents", Frames = { "PlayerTalentFrame", "PlayerSpellsFrame.SpecFrame", "PlayerSpellsFrame.TalentsFrame" } },
  { Id = Elements.Trade, Name = "Trade", Frames = { "TradeFrame" } },
  { Id = Elements.Trainer, Name = "Trainer", Frames = { "ClassTrainerFrame" } },
  { Id = Elements.WorldMap, Name = "World Map", Frames = { "WorldMapFrame" } },
}

local function ResolveFrame(path)
  local frame = _G
  for name in path:gmatch("[^.]+") do
    frame = frame and frame[name]
  end
  return frame
end

local function Visible(frame)
  local success, visible = pcall(function()
    if (frame.IsForbidden and frame:IsForbidden()) then return nil end
    return frame:IsVisible()
  end)
  if (success and not (issecretvalue and issecretvalue(visible)) and type(visible) == "boolean") then
    return visible
  end
end

function Activity:TrackFrame(element, frame)
  if (not frame) then return end
  if (not self.Frames[element]) then self.Frames[element] = {} end
  self.Frames[element][frame] = true
  if (self.HookedFrames[frame]) then return end
  -- Read protected/Gamepad panels through polling, without changing their scripts.
  local success, canHook = pcall(function()
    return not (Api.IsWoWForever() and Api.IsGamepadUIEnabled())
      and not (frame.IsForbidden and frame:IsForbidden())
      and not (frame.IsProtected and frame:IsProtected())
  end)
  if (not success or not canHook) then return end
  self.HookedFrames[frame] = true
  local function Changed() self:QueueUpdate() end
  pcall(function()
    frame:HookScript("OnShow", Changed)
    frame:HookScript("OnHide", Changed)
  end)
end

function Activity:DiscoverFrames()
  for _, definition in ipairs(self.Definitions) do
    for _, path in ipairs(definition.Frames) do self:TrackFrame(definition.Id, ResolveFrame(path)) end
  end
  -- Container frames also represent bank bags. Only inventory bag IDs belong here.
  for index = 1, NUM_CONTAINER_FRAMES or 13 do
    local frame = _G["ContainerFrame" .. index]
    if (frame) then
      local success, bagId = pcall(frame.GetID, frame)
      if (success and not (issecretvalue and issecretvalue(bagId)) and type(bagId) == "number"
        and bagId >= 0 and bagId <= (NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4)) then
        self:TrackFrame(Elements.Bags, frame)
      elseif (self.Frames[Elements.Bags]) then
        self.Frames[Elements.Bags][frame] = nil
      end
    end
  end

  local skins = Baganator and Baganator.API and Baganator.API.Skins
  if (not self.BaganatorRegistered and skins and skins.GetAllFrames and skins.RegisterListener) then
    self.BaganatorRegistered = true
    local function Added(details)
      if (details.regionType ~= "ButtonFrame") then return end
      for _, tag in ipairs(details.tags or {}) do
        if (tag == "backpack") then self:TrackFrame(Elements.Bags, details.region) end
        if (tag == "bank") then self:TrackFrame(Elements.Bank, details.region) end
      end
    end
    for _, details in ipairs(skins.GetAllFrames()) do Added(details) end
    skins.RegisterListener(Added)
  end
end

function Activity:GetStatistics()
  local level = Controller.CharacterData.Levels[self.LevelNum]
  if (level) then
    if (not level[self.StatisticsKey]) then level[self.StatisticsKey] = UiStatistics.New() end
    return level[self.StatisticsKey]
  end
  -- The played-time response can create the new level after PLAYER_LEVEL_UP.
  if (not self.PendingStatistics[self.LevelNum]) then self.PendingStatistics[self.LevelNum] = UiStatistics.New() end
  return self.PendingStatistics[self.LevelNum]
end

function Activity:FlushPending()
  for levelNum, pending in pairs(self.PendingStatistics) do
    local level = Controller.CharacterData.Levels[levelNum]
    if (level) then
      if (not level[self.StatisticsKey]) then level[self.StatisticsKey] = UiStatistics.New() end
      for element, entry in pairs(pending) do
        UiStatistics.Add(level[self.StatisticsKey], element, entry.OpenCount, entry.TimeSpent)
      end
      self.PendingStatistics[levelNum] = nil
    end
  end
end

function Activity:Flush()
  if (not self.Active) then return end
  self:FlushPending()
  local now = GetTime()
  for element, state in pairs(self.States) do
    if (state.StartedAt) then
      local seconds = math.max(0, now - state.StartedAt)
      if (seconds > 0) then UiStatistics.Add(self:GetStatistics(), element, 0, seconds) end
      state.StartedAt = now
    end
  end
end

function Activity:SetLevel(levelNum)
  self:Flush()
  self.LevelNum = levelNum
end

function Activity:Update()
  if (not self.Active) then return end
  self:Flush()
  self:DiscoverFrames()
  local now = GetTime()
  for _, definition in ipairs(self.Definitions) do
    local visible, unreadable, hasVisibilityReader = false, false, false
    if (definition.GetVisibility) then
      local value
      value, hasVisibilityReader = definition.GetVisibility()
      visible, unreadable = value == true, value == nil
    end
    if (not hasVisibilityReader) then
      for frame in pairs(self.Frames[definition.Id] or {}) do
        local value = Visible(frame)
        if (value == true) then visible = true; break end
        if (value == nil) then unreadable = true end
      end
    end
    local state = self.States[definition.Id]
    if (not state) then state = {}; self.States[definition.Id] = state end
    if (visible or not unreadable) then
      if (visible and not state.IsOpen) then UiStatistics.Add(self:GetStatistics(), definition.Id, 1, 0) end
      state.IsOpen = visible
      state.StartedAt = visible and now or nil
    else
      state.StartedAt = nil
    end
  end
end

function Activity:QueueUpdate()
  if (not self.Active or self.UpdateQueued) then return end
  self.UpdateQueued = true
  local generation = self.Generation
  C_Timer.After(0, function()
    if (generation ~= self.Generation) then return end
    self.UpdateQueued = false
    self:Update()
  end)
end

function Activity:Start()
  if (self.Active) then return end
  self.Active = true
  self.Generation = self.Generation + 1
  self.LevelNum = AutoBiographer_EventManager.NewLevelToAddToHistory or Controller:GetCurrentLevelNum()
  self:Update()
  local generation = self.Generation
  local function Poll()
    if (not self.Active or generation ~= self.Generation) then return end
    self:Update()
    C_Timer.After(0.25, Poll)
  end
  C_Timer.After(0.25, Poll)
end

function Activity:Stop()
  self:Flush()
  self.Active = false
  self.UpdateQueued = false
  self.Generation = self.Generation + 1
  for _, state in pairs(self.States) do state.StartedAt = nil end
end
