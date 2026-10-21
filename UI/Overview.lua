-- A read-only highlight reel. All figures come from existing character records;
-- this view adds no saved data and never changes the underlying statistics.
AutoBiographer_Overview = {}
local Overview = AutoBiographer_Overview
local Controller = AutoBiographer_Controller
local Api = AutoBiographer_Api
local Enum = AutoBiographerEnum
local HF = HelperFunctions
local fallbackIcon = "Interface\\Icons\\inv_misc_note_05"
local visibleEquipmentSlots = { 1, 3, 4, 5, 6, 7, 8, 9, 10, 15, 16, 17, 18, 19 }
local messageNames = {
  BattleNetWhisper = "Battle.net private messages", Battleground = "Battleground", Community = "Community",
  Emote = "Emotes", General = "General", Guild = "Guild", Instance = "Instance / battleground",
  LocalDefense = "Local Defense", LookingForGroup = "Looking For Group", Officer = "Officer",
  OtherChannel = "Other / custom channels", Party = "Party", Raid = "Raid", RaidWarning = "Raid warnings",
  Say = "Say", Trade = "Trade", TradeServices = "Trade (Services)", Whisper = "Private messages",
  WorldDefense = "World Defense", Yell = "Yell",
}

local function Readable(value)
  return not (issecretvalue and issecretvalue(value))
end

local function Number(value)
  return HF.CommaValue(HF.Round(value or 0, 1))
end

local function Top(totals, limit)
  local entries = {}
  for candidate, value in pairs(totals) do
    if (value > 0) then entries[#entries + 1] = { Name = candidate, Amount = value } end
  end
  table.sort(entries, function(a, b)
    if (a.Amount ~= b.Amount) then return a.Amount > b.Amount end
    return a.Name < b.Name
  end)
  while (#entries > limit) do table.remove(entries) end
  return entries
end

local function Best(totals)
  local first = Top(totals, 1)[1]
  if (first) then return first.Name, first.Amount end
end

local function Add(totals, name, amount)
  if (name and name ~= "" and amount > 0) then totals[name] = (totals[name] or 0) + amount end
end

function Overview:BuildHighlights(window)
  local minLevel, maxLevel = window.DisplayMinLevel, window.DisplayMaxLevel
  local catalogs = Controller.CharacterData.Catalogs
  local damage = Controller:GetAggregatedDamageMeterAbilities({ Enum.DamageOrHealingCategory.DamageDealt }, minLevel, maxLevel)
  local healing = Controller:GetAggregatedDamageMeterAbilities({ Enum.DamageOrHealingCategory.HealingDealt }, minLevel, maxLevel)
  local casts, totemCasts, damageNames, healingNames = {}, {}, {}, {}
  for id, stats in pairs(Controller:GetAggregatedSpellStatisticsDictionary(minLevel, maxLevel)) do
    local spell = catalogs.SpellCatalog[id]
    if (spell) then
      Add(casts, spell.Name, stats[Enum.SpellTrackingType.SuccessfullyCast] or 0)
      -- Match the same totem placement names as the campfire story category.
      if (spell.Name and spell.Name:match(" Totem$")) then
        Add(totemCasts, spell.Name, stats[Enum.SpellTrackingType.SuccessfullyCast] or 0)
      end
    end
  end
  for _, pair in ipairs({ { damage, damageNames }, { healing, healingNames } }) do
    for id, breakdown in pairs(pair[1]) do
      local spell = catalogs.SpellCatalog[id]
      if (spell and spell.Name) then
        Add(pair[2], CatalogSpell.GetDamageMeterDisplayName(spell, id), breakdown.Amount - breakdown.Over)
      end
    end
  end
  local creatures, players, items, acquired, zones = {}, {}, {}, {}, {}
  for id, stats in pairs(Controller:GetAggregatedKillStatisticsDictionary(minLevel, maxLevel)) do
    local unit = catalogs.UnitCatalog[id]
    if (unit and unit.UType == Enum.UnitType.Creature) then
      Add(creatures, unit.Name, (stats[Enum.KillTrackingType.TaggedKillingBlow] or 0) + (stats[Enum.KillTrackingType.UntaggedKillingBlow] or 0))
    end
  end
  window.DashboardValues.BuffsTotal, window.DashboardValues.PlayersBuffedTotal = 0, 0
  for id, stats in pairs(Controller:GetAggregatedOtherPlayerStatisticsDictionary(minLevel, maxLevel)) do
    local buffs = (stats[Enum.OtherPlayerTrackingType.BuffsGivenToPlayerNotGrouped] or 0) +
      (stats[Enum.OtherPlayerTrackingType.BuffsGivenToPlayerWhileGrouped] or 0)
    window.DashboardValues.BuffsTotal = window.DashboardValues.BuffsTotal + buffs
    if (buffs > 0) then window.DashboardValues.PlayersBuffedTotal = window.DashboardValues.PlayersBuffedTotal + 1 end
    local unit = catalogs.UnitCatalog[id]
    if (unit and unit.Name) then
      local name = unit.Name .. (unit.LastName and unit.LastName ~= "" and (" " .. unit.LastName) or "")
      Add(players, name, stats[Enum.OtherPlayerTrackingType.TimeSpentGroupedWithPlayer] or 0)
    end
  end
  for id, stats in pairs(Controller:GetAggregatedItemStatisticsDictionary(minLevel, maxLevel)) do
    local item = catalogs.ItemCatalog[id]
    if (item) then
      Add(items, item.Name, stats[Enum.ItemAcquisitionMethod.Create] or 0)
      local total = 0
      for _, method in pairs(Enum.ItemAcquisitionMethod) do total = total + (stats[method] or 0) end
      Add(acquired, item.Name, total)
    end
  end
  for area, stats in pairs(Controller:GetAggregatedTimeStatisticsDictionary(minLevel, maxLevel)) do
    local zone = area:match("^(.-)%-") or area
    -- Login timers can run before the zone is known, saving "nil-nil".
    -- Keep that time in the totals, but don't present it as a real place.
    if (zone ~= "nil") then Add(zones, zone, stats[Enum.TimeTrackingType.LoggedIn] or 0) end
  end
  local messages = {}
  for category, trackingType in pairs(Enum.MessageTrackingType) do
    Add(messages, messageNames[category], window.DashboardValues["Messages" .. category] or 0)
  end
  local deaths = self:BuildDeathSources(window)
  local highlights = {}
  local function Highlight(title, totals, describe, view, icon, caption, format)
    local entries = Top(totals, 3)
    if (#entries > 0) then
      for _, entry in ipairs(entries) do
        entry.Description = describe(entry.Amount)
        entry.Value = (format or Number)(entry.Amount)
      end
      highlights[#highlights + 1] = { Title = title, Name = entries[1].Name, Description = entries[1].Description,
        Entries = entries, Caption = caption, View = view, Icon = icon }
    end
  end
  Highlight("Your signature moves", casts, function(n) return Number(n) .. " successful casts, across all ranks" end,
    "Spells", "Interface\\Icons\\spell_holy_magicalsentry", "Successful casts, across all ranks")
  Highlight("Where you made memories", zones, function(n) return HF.SecondsToTimeString(n, true) .. " recorded here" end,
    "Time", "Interface\\Icons\\inv_misc_map_01", "Recorded time in each zone", function(n) return HF.SecondsToTimeString(n, true) end)
  Highlight("Bane of their kind", creatures, function(n) return Number(n) .. " personal killing blows" end,
    "Kills", "Interface\\Icons\\ability_dualwield", "Personal killing blows, tagged and untagged")
  Highlight("The end of the road", deaths, function(n) return Number(n) .. " deaths" end,
    "Deaths", "Interface\\Icons\\ability_backstab", "Most frequent sources of death")
  Highlight("Your hardest hitters", damageNames, function(n) return Number(n) .. " effective damage" end,
    "DamageDealt", "Interface\\Icons\\spell_fire_flamebolt", "Effective damage, across all ranks")
  Highlight("Your healing touch", healingNames, function(n) return Number(n) .. " effective healing" end,
    "HealingDealt", "Interface\\Icons\\spell_holy_flashheal", "Effective healing, across all ranks")
  Highlight("Your favorite finds", acquired, function(n) return Number(n) .. " acquired" end,
    "Items", "Interface\\Icons\\inv_misc_bag_10", "Items acquired by any method")
  Highlight("Made by your hands", items, function(n) return Number(n) .. " crafted by you" end,
    "Items", "Interface\\Icons\\trade_blacksmithing", "Items crafted")
  Highlight("Your travelling companions", players, function(n) return HF.SecondsToTimeString(n, true) .. " adventuring together" end,
    "OtherPlayers", "Interface\\Icons\\spell_holy_prayerofhealing", "Time adventuring together", function(n) return HF.SecondsToTimeString(n, true) end)
  Highlight("Your voice in Azeroth", messages, function(n) return Number(n) .. " messages sent" end,
    "Social", "Interface\\Icons\\inv_misc_note_01", "Messages sent by chat type")

  local class, states = window.PlayerClass, {}
  for _, state in ipairs(AutoBiographer_ClassActivity and AutoBiographer_ClassActivity.StateDefinitions or {}) do
    if (state[3] == class and state[1] ~= "MindControl" and state[1] ~= "FeignDeath") then
      Add(states, state[2], window.DashboardValues["Time" .. state[1]] or 0)
    end
  end
  local title, totals, timeValue, view = "Your class in action", states, true, "Time"
  if (class == "DRUID") then title = "Your favorite form"
  elseif (class == "WARRIOR") then title = "Your favorite stance"
  elseif (class == "ROGUE") then title = "Life in the shadows"
  elseif (class == "SHAMAN") then title, totals, timeValue, view = "Your elemental calling", totemCasts, false, "Spells"
  elseif (class == "WARLOCK" or class == "HUNTER") then
    totals = {}
    for id, seconds in pairs(Controller:GetAggregatedCompanionFamilyTime(minLevel, maxLevel)) do
      Add(totals, (catalogs.CompanionFamilyCatalog or {})[id], seconds)
    end
    title = class == "WARLOCK" and "Your demonic companion" or "Your faithful companion"
  elseif (class == "PALADIN") then
    totals, title = {}, "Your guiding aura"
    for id, seconds in pairs(Controller:GetAggregatedSpellTime(minLevel, maxLevel)) do
      local spell = catalogs.SpellCatalog[id]
      if (spell) then Add(totals, spell.Name, seconds) end
    end
  end
  local name, amount = Best(totals)
  if (not name) then
    -- Classes without readable time data still get a truthful ability spotlight.
    local useHealing = (window.DashboardValues.HealingDealt or 0) > (window.DashboardValues.DamageDealt or 0)
    name, amount = Best(useHealing and healingNames or damageNames)
    title, timeValue, view = useHealing and "Your healing touch" or "Your hardest hitter", false, useHealing and "HealingDealt" or "DamageDealt"
  end
  local spotlight = name and { Title = title, Name = name, View = view,
    SummaryTab = (class == "PALADIN" or class == "DRUID") and timeValue and "Time" or nil,
    Description = timeValue and (HF.SecondsToTimeString(amount, true) .. " recorded") or
      view == "Spells" and (Number(amount) .. " successful casts") or
      (Number(amount) .. " effective " .. (view == "HealingDealt" and "healing" or "damage")) }
  return highlights, spotlight
end

function Overview:BuildDeathSources(window)
  local values, deaths = window.DashboardValues, {}
  Add(deaths, "Drowning", values.DeathToDrowning or 0)
  Add(deaths, "Falling", values.DeathToFalling or 0)
  Add(deaths, "Other environment", values.DeathToEnvironment or 0)
  for catalogUnitId, count in pairs(Controller:GetAggregatedDeathStatisticsDictionary(window.DisplayMinLevel, window.DisplayMaxLevel)) do
    local unit = Controller.CharacterData.Catalogs.UnitCatalog[catalogUnitId]
    local name = unit and unit.Name
    if (name and unit.LastName and unit.LastName ~= "") then name = name .. " " .. unit.LastName end
    Add(deaths, name or "Unknown source", count)
  end
  return deaths
end

function Overview:BuildJourney()
  local entries, seenLevels = {}, {}
  local snapshots = Controller:GetCharacterSnapshots() or {}
  local function Include(entry)
    entries[#entries + 1] = entry
    table.sort(entries, function(a, b)
      if (a.Timestamp ~= b.Timestamp) then return a.Timestamp > b.Timestamp end
      return a.Key < b.Key
    end)
    if (#entries > 4) then table.remove(entries) end
  end
  for index, event in ipairs(Controller:GetEvents() or {}) do
    if (event.SubType == Enum.EventSubType.LevelUp) then
      local snapshot = snapshots.Levels and snapshots.Levels[event.LevelNum]
      seenLevels[event.LevelNum] = true
      Include({ Key = "level:" .. event.LevelNum, Title = "Reached level " .. event.LevelNum,
        Timestamp = event.Timestamp or 0, Event = event, EventIndex = index, Snapshot = snapshot })
    elseif (event.SubType == Enum.EventSubType.StatisticMilestone) then
      Include({ Key = "event:" .. index, Title = "Milestone: " .. (event.Text or ((event.Statistic or "Statistic") .. " " .. Number(event.Amount))),
        Timestamp = event.Timestamp or 0, Event = event, EventIndex = index })
    end
  end
  for level, snapshot in pairs(snapshots.Levels or {}) do
    if (not seenLevels[level]) then
      Include({ Key = "level:" .. level, Title = level == 1 and "Your adventure began" or ("Reached level " .. level),
        Timestamp = snapshot.Timestamp or 0, Snapshot = snapshot })
    end
  end
  for id, snapshot in pairs(snapshots.Raids or {}) do
    local raid = (Controller.CharacterData.Catalogs.RaidCatalog or {})[id]
    Include({ Key = "raid:" .. id, Title = "First clear: " .. (raid and raid.Name or ("Raid #" .. id)),
      Timestamp = snapshot.Timestamp or 0, Snapshot = snapshot })
  end
  return entries
end

local function Label(parent, template, size)
  local label = parent:CreateFontString(nil, "OVERLAY", template)
  label:SetJustifyH("LEFT")
  label:SetWordWrap(false)
  if (size) then label:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", size, "") end
  return label
end

local function Card(parent, color)
  local card = CreateFrame("Button", nil, parent)
  card.Background = card:CreateTexture(nil, "BACKGROUND")
  card.Background:SetAllPoints(card)
  card.Background:SetColorTexture(0, 0, 0, 0.32)
  card.Tint = card:CreateTexture(nil, "BACKGROUND", nil, 1)
  card.Tint:SetAllPoints(card)
  card.Tint:SetColorTexture(color.r, color.g, color.b, 0.06)
  card.Edge = card:CreateTexture(nil, "BORDER")
  card.Edge:SetPoint("TOPLEFT"); card.Edge:SetPoint("TOPRIGHT"); card.Edge:SetHeight(1)
  card.Edge:SetColorTexture(color.r, color.g, color.b, 0.5)
  local hover = card:CreateTexture(nil, "HIGHLIGHT")
  hover:SetAllPoints(card); hover:SetColorTexture(1, 1, 1, 0.035)
  card:SetScript("OnEnter", function(self)
    if (not self.Data) then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(self.Data.Title, 1, 0.82, 0)
    if (self.Data.Entries) then
      for rank, entry in ipairs(self.Data.Entries) do
        GameTooltip:AddLine(rank .. ". " .. entry.Name .. " - " .. entry.Description, 1, 1, 1, true)
      end
    else
      GameTooltip:AddLine(self.Data.Name or "", 1, 1, 1, true)
      GameTooltip:AddLine(self.Data.Description or "", 0.8, 0.8, 0.8, true)
    end
    GameTooltip:AddLine("Click to explore", 0.6, 0.6, 0.6)
    GameTooltip:Show()
  end)
  card:SetScript("OnLeave", function() GameTooltip:Hide() end)
  return card
end

local function Position(frame, x, y, width, height)
  frame:ClearAllPoints(); frame:SetPoint("TOPLEFT", x, -y); frame:SetSize(width, height)
end

function Overview:Initialize(window)
  if (window.Overview) then window.Overview:Hide(); window.Overview:UnregisterAllEvents() end
  local root = CreateFrame("Frame", nil, window.ScrollFrame.Content)
  window.Overview = root
  root.Window = window
  local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[window.PlayerClass] or { r = 1, g = 0.82, b = 0.4 }
  root.Hero = Card(root, color)
  root.Hero:SetScript("OnEnter", nil)
  root.Portrait = root.Hero:CreateTexture(nil, "ARTWORK")
  root.Portrait:SetTexture(fallbackIcon)
  root.Portrait:SetSize(96, 96); root.Portrait:SetPoint("LEFT", 44, 0)
  local success, model = pcall(CreateFrame, "DressUpModel", nil, root.Hero)
  if (success and model.SetUnit) then
    root.Model = model
    model:EnableMouse(false)
    model:SetScript("OnModelLoaded", function(self)
      if (self.RefreshCamera) then self:RefreshCamera() end
      Overview:ApplySnapshotEquipment(root)
    end)
  elseif (success) then model:Hide() end
  root.Name = Label(root.Hero, "GameFontNormalLarge", 27)
  root.Name:SetTextColor(color.r, color.g, color.b)
  root.Identity = Label(root.Hero, "GameFontHighlight")
  root.PlayTime = Label(root.Hero, "GameFontHighlight", 18)
  root.Scope = Label(root.Hero, "GameFontDisableSmall")
  root.Spotlight = Card(root.Hero, color)
  root.Spotlight.Title = Label(root.Spotlight, "GameFontNormalSmall")
  root.Spotlight.Name = Label(root.Spotlight, "GameFontHighlight", 16)
  root.Spotlight.Description = Label(root.Spotlight, "GameFontDisableSmall")
  root.Spotlight.Title:SetPoint("TOPLEFT", 12, -9)
  root.Spotlight.Name:SetPoint("TOPLEFT", 12, -27)
  root.Spotlight.Description:SetPoint("TOPLEFT", 12, -48)
  root.Spotlight:SetScript("OnClick", function(self)
    if (self.Data.SummaryTab) then window:SelectTab(self.Data.SummaryTab) else window:OpenStatistics(self.Data.View) end
  end)
  root.Headlines, root.Highlights, root.JourneyRows = {}, {}, {}
  local metrics = {
    { "Kills", "Foes defeated", "Tagged kills, including assists and group kills", "Kills", "Interface\\Icons\\ability_dualwield" },
    { "DistanceTotal", "Distance travelled", "Across all recorded travel types", "Travel", "Interface\\Icons\\inv_boots_08" },
    { "QuestsUnique", "Adventures completed", "Unique quests completed", "Progression", "Interface\\Icons\\inv_misc_book_09" },
    { "DamageDealt", "Damage dealt", "Total recorded damage, including overdamage", "DamageDealt", "Interface\\Icons\\spell_fire_flamebolt" },
    { "HealingDealt", "Healing dealt", "Total recorded healing, including overhealing", "HealingDealt", "Interface\\Icons\\spell_holy_flashheal" },
    { "Deaths", "Deaths", "Every recorded end of an adventure", "Combat", "Interface\\Icons\\ability_backstab" },
    { "MoneyTotal", "Money gained", "Total earned, not your current balance", "Economy", "Interface\\Icons\\inv_misc_coin_01", "money" },
    { "Camped", "Times camped", "Benefits earned around a campfire", "Progression", "Interface\\Icons\\spell_fire_fire" },
    { "Jumps", "Jumps", "A little extra spring in your step", "Progression", "Interface\\Icons\\ability_rogue_sprint" },
    { "PlayersBuffedTotal", "Players buffed", "Unique players, inside and outside your group", "Social", "Interface\\Icons\\spell_holy_prayerofhealing" },
    { "BuffsTotal", "Buffs given", "Buffs given to other players", "Social", "Interface\\Icons\\spell_holy_magicalsentry" },
    { "MessagesTotal", "Messages sent", "Across all recorded chat types", "Social", "Interface\\Icons\\inv_misc_note_01" },
  }
  for _, metric in ipairs(metrics) do
    local card = Card(root, color)
    card.Metric = metric
    card.Icon = card:CreateTexture(nil, "ARTWORK")
    card.Icon:SetSize(24, 24); card.Icon:SetPoint("TOPRIGHT", -12, -12); card.Icon:SetTexture(metric[5])
    card.Value = Label(card, "GameFontNormalLarge", metric[6] == "money" and 18 or 26); card.Value:SetPoint("TOPLEFT", 14, -12)
    card.Title = Label(card, "GameFontHighlight"); card.Title:SetPoint("TOPLEFT", 14, -52); card.Title:SetText(metric[2])
    card.Description = Label(card, "GameFontDisableSmall"); card.Description:SetPoint("TOPLEFT", 14, -74); card.Description:SetText(metric[3])
    card:SetScript("OnClick", function()
      if (Enum.StatisticsDisplayMode[metric[4]] ~= nil) then window:OpenStatistics(metric[4]) else window:SelectTab(metric[4]) end
    end)
    root.Headlines[#root.Headlines + 1] = card
  end
  for index = 1, 10 do
    local card = Card(root, color)
    card.Icon = card:CreateTexture(nil, "ARTWORK"); card.Icon:SetSize(28, 28); card.Icon:SetPoint("TOPLEFT", 14, -14)
    card.Title = Label(card, "GameFontNormalSmall"); card.Title:SetPoint("TOPLEFT", 54, -14)
    card.Description = Label(card, "GameFontDisableSmall"); card.Description:SetPoint("TOPLEFT", 54, -32)
    card.Rows = {}
    for rank = 1, 3 do
      local row = { Name = Label(card, "GameFontHighlight", 14), Value = Label(card, "GameFontNormal", 13) }
      row.Name:SetPoint("TOPLEFT", 14, -59 - (rank - 1) * 28)
      row.Value:SetPoint("TOPRIGHT", -14, -59 - (rank - 1) * 28); row.Value:SetJustifyH("RIGHT")
      card.Rows[rank] = row
    end
    card.Name = card.Rows[1].Name
    card:SetScript("OnClick", function(self)
      if (self.Data.View == "Deaths" or self.Data.View == "Social") then
        window:SelectTab(self.Data.View == "Deaths" and "Combat" or "Social")
      else window:OpenStatistics(self.Data.View) end
    end)
    root.Highlights[index] = card
  end
  root.EmptyHighlights = Label(root, "GameFontHighlight")
  root.EmptyHighlights:SetText("Your legend is just beginning. Fight, craft and adventure with others to discover your personal highlights.")
  root.EmptyHighlights:SetWordWrap(true)
  root.Journey = Card(root, color); root.Journey:SetScript("OnEnter", nil)
  root.JourneyHeading = Label(root.Journey, "GameFontNormalLarge", 18)
  root.JourneyHeading:SetText("Chapters of your journey"); root.JourneyHeading:SetPoint("TOPLEFT", 14, -12)
  root.JourneyScope = Label(root.Journey, "GameFontDisableSmall")
  root.JourneyScope:SetText("Latest lifetime milestones - click to revisit"); root.JourneyScope:SetPoint("TOPLEFT", 14, -36)
  root.JourneyEmpty = Label(root.Journey, "GameFontHighlight")
  root.JourneyEmpty:SetText("Your next level-up or major milestone will begin the next chapter.")
  root.JourneyEmpty:SetPoint("TOPLEFT", 14, -66)
  for index = 1, 4 do
    local row = CreateFrame("Button", nil, root.Journey)
    row.Date = Label(row, "GameFontNormalSmall"); row.Date:SetPoint("LEFT", 0, 0); row.Date:SetWidth(92)
    row.Title = Label(row, "GameFontHighlight"); row.Title:SetPoint("LEFT", 108, 0)
    local hover = row:CreateTexture(nil, "HIGHLIGHT"); hover:SetAllPoints(row); hover:SetColorTexture(1, 1, 1, 0.04)
    row:SetScript("OnClick", function(self) Overview:OpenJourney(self.Entry) end)
    row:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText(self.Entry.Title, 1, 0.82, 0)
      GameTooltip:AddLine(self.Entry.Timestamp > 0 and date("%Y-%m-%d %H:%M", self.Entry.Timestamp) or "Date not recorded", 1, 1, 1)
      GameTooltip:AddLine(self.Entry.Snapshot and "Click to view this character snapshot" or "Click to view this event", 0.7, 0.7, 0.7)
      GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    root.JourneyRows[index] = row
  end
  root:SetScript("OnShow", function() Overview:RefreshModel(root) end)
  root:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
  root:SetScript("OnEvent", function() if (root:IsVisible()) then Overview:RefreshModel(root) end end)
  root:Hide()
end

function Overview:GetAppearanceSnapshot(window)
  if (window.DisplayMinLevel == 1 and window.DisplayMaxLevel == 9999) then return nil end
  local level = math.min(window.DisplayMaxLevel, Controller:GetCurrentLevelNum())
  if (level < window.DisplayMinLevel) then return nil end
  local snapshots = Controller:GetCharacterSnapshots()
  local snapshot = snapshots and snapshots.Levels and snapshots.Levels[level]
  if (snapshot and snapshot.Equipment) then return snapshot, level end
  return nil, level
end

function Overview:ApplySnapshotEquipment(root)
  local model, snapshot = root.Model, root.AppearanceSnapshot
  if (not model or not snapshot or root.ApplyingEquipment) then return true end
  root.ApplyingEquipment = true
  local success = pcall(function()
    -- Clear all prior gear, including slots empty in the selected snapshot.
    model:Undress()
    for _, slot in ipairs(visibleEquipmentSlots) do
      local id = snapshot.Equipment[slot]
      if (id and id > 0) then
        local enchant = snapshot.Enchants and snapshot.Enchants[slot] or 0
        local hand = slot == 16 and "MAINHANDSLOT" or slot == 17 and "SECONDARYHANDSLOT" or nil
        model:TryOn("item:" .. id .. ":" .. enchant, hand)
      end
    end
  end)
  root.ApplyingEquipment = false
  if (not success) then
    model:Hide(); root.Portrait:Show()
    root.Scope:SetText("Highlights: " .. root.Window.DropdownText .. " | Appearance: snapshot preview unavailable")
  end
  return success
end

function Overview:RefreshModel(root)
  local snapshot, level = self:GetAppearanceSnapshot(root.Window)
  root.AppearanceSnapshot = snapshot
  local appearance = snapshot and ("level " .. level .. " snapshot gear (no transmog)") or
    level and ("current equipment (no level " .. level .. " gear snapshot)") or "current equipment"
  root.Scope:SetText("Highlights: " .. root.Window.DropdownText .. " | Appearance: " .. appearance)
  if (SetPortraitTexture) then pcall(SetPortraitTexture, root.Portrait, "player") end
  if (not root.Model) then
    if (snapshot) then root.Scope:SetText("Highlights: " .. root.Window.DropdownText .. " | Appearance: snapshot preview unavailable") end
    return
  end
  local model = root.Model
  local success = pcall(function()
    if (model.SetAutoDress) then model:SetAutoDress(snapshot == nil) end
    -- Forever's outfit skin mode can leave the live model without textures.
    -- Use the native character appearance for both live and recorded gear.
    for _, method in ipairs({ "SetUseTransmogSkin", "SetUseTransmogChoices", "SetObeyHideInTransmogFlag" }) do
      if (model[method]) then model[method](model, false) end
    end
    model:SetUnit("player", false, true)
    if (snapshot) then
      if (not self:ApplySnapshotEquipment(root)) then error("Snapshot preview unavailable") end
    end
    if (model.SetFacing) then model:SetFacing(0.35) end
  end)
  model:SetShown(success); root.Portrait:SetShown(not success)
  if (not success and snapshot) then
    root.Scope:SetText("Highlights: " .. root.Window.DropdownText .. " | Appearance: snapshot preview unavailable")
  end
end

function Overview:OpenJourney(entry)
  GameTooltip:Hide()
  if (entry.Snapshot) then
    AutoBiographer_SnapshotPanel.SelectedSnapshot = entry.Snapshot
    AutoBiographer_MainWindow:ShowSection("Snapshots")
  else
    local index
    for i, event in ipairs(Controller:GetEvents()) do if (event == entry.Event) then index = i; break end end
    if (not index) then return end
    local events = AutoBiographer_EventWindow
    AutoBiographer_MainWindow:ShowSection("Events")
    events.SearchBox:SetText("")
    AutoBiographer_Settings.EventDisplayFilters[entry.Event.SubType] = true
    events:Update(true); events:SelectEvent(index)
    local row = events.EntriesByEventIndex[index]
    if (row) then events.ScrollFrame.Scrollbar:SetValue(math.min(events.MaxScroll, row.Top)) end
  end
end

function Overview:Update(window)
  local root, values = window.Overview, window.DashboardValues
  local name, lastName = Api.GetUnitName("player")
  root.Name:SetText((name or AutoBiographer_EventManager.PlayerName or "Adventurer") .. (lastName and (" " .. lastName) or ""))
  local race = UnitRace and UnitRace("player")
  local className = UnitClass and UnitClass("player")
  root.Identity:SetText("Level " .. Controller:GetCurrentLevelNum() .. " " ..
    (Readable(race) and race and (race .. " ") or "") .. (Readable(className) and className or window.PlayerClass or "Adventurer"))
  root.PlayTime:SetText(HF.SecondsToTimeString(values.TimeLoggedIn or 0, true) .. " of recorded adventures")
  self:RefreshModel(root)
  root.HighlightData, root.Spotlight.Data = self:BuildHighlights(window)
  for _, card in ipairs(root.Headlines) do
    local metric = card.Metric
    local value = metric[6] == "money" and Api.FormatMoney(values[metric[1]] or 0) or
      metric[1] == "DistanceTotal" and HF.FormatDistance(values.DistanceTotal) or Number(values[metric[1]])
    card.Value:SetText(value)
    card.Data = { Title = metric[2], Name = value, Description = metric[3] }
  end
  for index, card in ipairs(root.Highlights) do
    card.Data = root.HighlightData[index]
    if (card.Data) then
      card.Title:SetText(card.Data.Title)
      card.Description:SetText(card.Data.Caption); card.Icon:SetTexture(card.Data.Icon)
      for rank, row in ipairs(card.Rows) do
        local entry = card.Data.Entries[rank]
        row.Name:SetText(entry and (rank .. ". " .. entry.Name) or "")
        row.Value:SetText(entry and entry.Value or "")
      end
    end
    card:SetShown(card.Data ~= nil)
  end
  local spotlight = root.Spotlight.Data
  if (spotlight) then
    root.Spotlight.Title:SetText(spotlight.Title); root.Spotlight.Name:SetText(spotlight.Name)
    root.Spotlight.Description:SetText(spotlight.Description)
  end
  root.Spotlight:SetShown(spotlight ~= nil)
  root.JourneyData = self:BuildJourney()
  for index, row in ipairs(root.JourneyRows) do
    row.Entry = root.JourneyData[index]
    if (row.Entry) then
      row.Date:SetText(row.Entry.Timestamp > 0 and date("%b %d, %Y", row.Entry.Timestamp) or "Undated")
      row.Title:SetText(row.Entry.Title)
    end
    row:SetShown(row.Entry ~= nil)
  end
  root.JourneyEmpty:SetShown(#root.JourneyData == 0)
  root.EmptyHighlights:SetShown(#root.HighlightData == 0)
end

function Overview:Layout(window, width)
  local root, gap = window.Overview, 12
  local modelWidth = math.min(220, width * 0.25)
  Position(root, 0, 0, width, 1)
  Position(root.Hero, 0, 0, width, 210)
  if (root.Model) then Position(root.Model, 8, 6, modelWidth, 198) end
  local x, textWidth = modelWidth + 26, width - modelWidth - 42
  for _, entry in ipairs({ { root.Name, 20, 36 }, { root.Identity, 66, 18 },
    { root.PlayTime, 101, 24 }, { root.Scope, 130, 16 } }) do Position(entry[1], x, entry[2], textWidth, entry[3]) end
  Position(root.Spotlight, x, 151, textWidth, 59)
  -- The compact hero spotlight keeps its description beside its title.
  root.Spotlight.Description:ClearAllPoints(); root.Spotlight.Description:SetPoint("TOPRIGHT", -12, -9)
  root.Spotlight.Description:SetWidth(textWidth * 0.48)
  root.Spotlight.Description:SetJustifyH("RIGHT")
  root.Spotlight.Title:SetWidth(textWidth * 0.48 - 24); root.Spotlight.Name:SetWidth(textWidth - 24)
  local metricWidth = (width - 2 * gap) / 3
  for index, card in ipairs(root.Headlines) do
    Position(card, ((index - 1) % 3) * (metricWidth + gap), 222 + math.floor((index - 1) / 3) * 113, metricWidth, 101)
    card.Value:SetWidth(metricWidth - 58); card.Title:SetWidth(metricWidth - 28); card.Description:SetWidth(metricWidth - 28)
  end
  local highlightsTop = 222 + math.ceil(#root.Headlines / 3) * 113 + 8
  local count = root.HighlightData and #root.HighlightData or 0
  local cardWidth = (width - gap) / 2
  for index, card in ipairs(root.Highlights) do
    Position(card, ((index - 1) % 2) * (cardWidth + gap), highlightsTop + math.floor((index - 1) / 2) * 155, cardWidth, 143)
    card.Title:SetWidth(cardWidth - 68); card.Description:SetWidth(cardWidth - 68)
    for _, row in ipairs(card.Rows) do
      row.Name:SetWidth((cardWidth - 40) * 0.65); row.Value:SetWidth((cardWidth - 40) * 0.35)
    end
  end
  Position(root.EmptyHighlights, 14, highlightsTop, width - 28, 52)
  local journeyTop = highlightsTop + (count == 0 and 64 or math.ceil(count / 2) * 155) + 10
  local journeyCount = root.JourneyData and #root.JourneyData or 0
  local journeyHeight = 62 + math.max(1, journeyCount) * 40
  Position(root.Journey, 0, journeyTop, width, journeyHeight)
  root.JourneyHeading:SetWidth(width - 28); root.JourneyScope:SetWidth(width - 28); root.JourneyEmpty:SetWidth(width - 28)
  for index, row in ipairs(root.JourneyRows) do
    Position(row, 14, 58 + (index - 1) * 40, width - 28, 40)
    row.Title:SetWidth(width - 144)
  end
  local height = journeyTop + journeyHeight + 12
  root:SetHeight(height)
  return height
end
