local Controller = AutoBiographer_Controller
local EM = AutoBiographer_EventManager
local HF = HelperFunctions
local Api = AutoBiographer_Api
local Enum = AutoBiographerEnum

-- Each row references an aggregated value, not a second copy of the statistics.
local dashboardTabs = {
  { Name = "Overview", Sections = {
    { Title = "Character summary", Column = 1, Rows = {
      { "TimeLoggedIn", "Time played", "time" },
      { "DistanceTotal", "Distance travelled", "distance" },
      { "Kills", "Tagged kills" },
      { "Deaths", "Deaths" },
      { "QuestsUnique", "Unique quests completed" },
      { "MoneyTotal", "Money gained", "money" },
    } },
    { Title = "Combat & activity", Column = 2, Rows = {
      { "DamageDealt", "Damage dealt" },
      { "HealingDealt", "Healing dealt" },
      { "SpellsSucceeded", "Spells successfully cast" },
      { "TimeGrouped", "Time grouped", "time" },
      { "Camped", "Times camped" },
      { "Jumps", "Jumps" },
    } },
  } },
  { Name = "Combat", Sections = {
    { Title = "Damage & healing", Column = 0, Columns = { "Total", "Effective", "Over" }, Rows = {
      { "DamageDealt", "Damage dealt", "breakdown", "DamageDealt" },
      { "DamageTaken", "Damage taken", "breakdown", "DamageTakenByUnit" },
      { "PetDamageTaken", "Pet damage taken", "breakdown", nil, "HasPetDamageTaken" },
      { "HealingDealt", "Healing dealt", "breakdown", "HealingDealt" },
      { "HealingTaken", "Healing taken", "breakdown" },
    } },
    { Title = "Kills", Column = 1, Details = "Kills", Rows = {
      { "Kills", "Total", IsTotal = true },
      { "KillingBlows", "Killing blows" },
      { "KillAssists", "Kill assists" },
      { "GroupKills", "Group kills without damage" },
    } },
    { Title = "Deaths", Column = 2, Rows = {
      { "Deaths", "Total", IsTotal = true },
      { "DeathToCreature", "Creatures" },
      { "DeathToDrowning", "Drowning" },
      { "DeathToEnvironment", "Other environment" },
      { "DeathToFalling", "Falling" },
      { "DeathToGameObject", "Game objects" },
      { "DeathToPet", "Pets" },
      { "DeathToPlayer", "Players" },
      { "DeathToUnknown", "Unknown" },
    } },
    { Title = "Spell casts", Column = 1, Details = "Spells", Rows = {
      { "SpellsStarted", "Started" },
      { "SpellsSucceeded", "Successful" },
    } },
    { Title = "Battlegrounds", Column = 0, Availability = "Battlegrounds",
      Columns = { "Wins", "Losses", "Incomplete" }, Rows = {
      { "Battleground1", "Alterac Valley", "results" },
      { "Battleground3", "Arathi Basin", "results" },
      { "Battleground4", "Eye of the Storm", "results", nil, "HasArenas" },
      { "Battleground2", "Warsong Gulch", "results" },
    } },
    { Title = "Arenas", Column = 0, Availability = "Arenas",
      Columns = { "Wins", "Losses", "Incomplete" }, Rows = {
      { "ArenaRated2", "2v2 rated", "results" },
      { "ArenaSkirmish2", "2v2 skirmish", "results" },
      { "ArenaRated3", "3v3 rated", "results" },
      { "ArenaSkirmish3", "3v3 skirmish", "results" },
      { "ArenaRated5", "5v5 rated", "results" },
      { "ArenaSkirmish5", "5v5 skirmish", "results" },
    } },
  } },
  { Name = "Progression", Sections = {
    { Title = "Experience", Column = 1, Rows = {
      { "ExperienceKills", "Kills (total)" },
      { "ExperienceKillsBase", "Kills (base)", Indent = 12 },
      { "ExperienceRestedBonus", "Rested bonus", Indent = 12 },
      { "ExperienceGroupBonus", "Group bonus", Indent = 12 },
      { "ExperienceRaidPenalty", "Raid penalty", Indent = 12 },
      { "ExperienceQuest", "Quests" },
      { "ExperienceDiscovery", "Discovery" },
    } },
    { Title = "Quests", Column = 2, Rows = {
      { "QuestsUnique", "Unique quests completed" },
      { "QuestsRepeated", "Repeat completions" },
    } },
    { Title = "Activities", Column = 2, Rows = {
      { "Camped", "Times camped" },
      { "Jumps", "Jumps" },
    } },
  } },
  { Name = "Economy", Sections = {
    { Title = "Items acquired", Column = 1, Details = "Items", Rows = {
      { "ItemsTotal", "Total", IsTotal = true },
      { "ItemsAuctionHouse", "Auction house" },
      { "ItemsCreate", "Created" },
      { "ItemsLoot", "Looted" },
      { "ItemsMail", "Mail" },
      { "ItemsMailCod", "Mail (COD)" },
      { "ItemsTrade", "Trade" },
      { "ItemsMerchant", "Vendors" },
      { "ItemsOther", "Other sources" },
    } },
    { Title = "Money gained", Column = 2, Rows = {
      { "MoneyTotal", "Total", "money", IsTotal = true },
      { "MoneyAuctionHouseSale", "Auction house sales", "money" },
      { "MoneyLoot", "Loot", "money" },
      { "MoneyMail", "Mail", "money" },
      { "MoneyMailCod", "Mail (COD)", "money" },
      { "MoneyMerchant", "Vendors", "money" },
      { "MoneyQuest", "Quests", "money" },
      { "MoneyTrade", "Trade", "money" },
      { "MoneyOther", "Other sources", "money" },
    } },
  } },
  { Name = "Social", Sections = {
    { Title = "Buffs outside your group", Column = 1, Details = "OtherPlayers", Rows = {
      { "BuffsOutsideGroup", "Buffs given" },
      { "PlayersBuffedOutsideGroup", "Unique players buffed" },
    } },
    { Title = "Buffs within your group", Column = 1, Details = "OtherPlayers", Rows = {
      { "BuffsInGroup", "Buffs given" },
      { "PlayersBuffedInGroup", "Unique players buffed" },
    } },
    { Title = "Duels", Column = 1, Details = "OtherPlayers", Rows = {
      { "DuelsWon", "Won" },
      { "DuelsLost", "Lost" },
    } },
    { Title = "Grouping", Column = 1, Details = "OtherPlayers", Rows = {
      { "TimeGrouped", "Time grouped", "time" },
    } },
    { Title = "Messages sent", Column = 2, Rows = {
      { "MessagesTotal", "Total", IsTotal = true },
      { "MessagesBattleNetWhisper", "Battle.net private message" },
      { "MessagesBattleground", "Battleground" },
      { "MessagesCommunity", "Community" },
      { "MessagesEmote", "Emote" },
      { "MessagesGeneral", "General" },
      { "MessagesGuild", "Guild" },
      { "MessagesInstance", "Instance / battleground" },
      { "MessagesLocalDefense", "Local Defense" },
      { "MessagesLookingForGroup", "Looking For Group" },
      { "MessagesOfficer", "Officer" },
      { "MessagesOtherChannel", "Other / custom channel" },
      { "MessagesParty", "Party" },
      { "MessagesWhisper", "Private message" },
      { "MessagesRaid", "Raid" },
      { "MessagesRaidWarning", "Raid warning" },
      { "MessagesSay", "Say" },
      { "MessagesTrade", "Trade" },
      { "MessagesTradeServices", "Trade (Services)" },
      { "MessagesWorldDefense", "World Defense" },
      { "MessagesYell", "Yell" },
    } },
  } },
  { Name = "Travel", Sections = {
    { Title = "Distance travelled (recorded)", Column = 0, Rows = {
      { "DistanceTotal", "Total", "distance", IsTotal = true },
      { "DistanceOnFoot", "On foot", "distance" },
      { "DistanceMounted", "Mounted", "distance" },
      { "DistanceSwimming", "Swimming", "distance" },
      { "DistanceFlightPath", "Flight paths", "distance" },
      { "DistanceGhost", "Ghost", "distance" },
      { "DistanceAquaticForm", "Aquatic Form", "distance", nil, "IsDruid" },
      { "DistanceBearForm", "Bear Form", "distance", nil, "IsDruid" },
      { "DistanceCatForm", "Cat Form", "distance", nil, "IsDruid" },
      { "DistanceMoonkinForm", "Moonkin Form", "distance", nil, "IsDruid" },
      { "DistanceTravelForm", "Travel Form", "distance", nil, "IsDruid" },
      { "DistanceGhostWolf", "Ghost Wolf", "distance", nil, "IsShaman" },
      { "DistanceStealthed", "Stealthed", "distance", nil, "CanStealth" },
    } },
  } },
  { Name = "Time", Sections = {
    { Title = "Play time", Column = 1, Details = "Time", Rows = {
      { "TimeLoggedIn", "Total recorded", "time" },
      { "TimeInCombat", "In combat", "time" },
      { "TimeCasting", "Casting", "time" },
      { "TimeGrouped", "Grouped", "time" },
    } },
    { Title = "Other time", Column = 2, Details = "Time", Rows = {
      { "TimeAfk", "AFK", "time" },
      { "TimeDeadOrGhost", "Dead or ghost", "time" },
      { "TimeOnTaxi", "Flights", "time" },
      { "TimeGamepadUI", "Gamepad UI enabled", "time" },
    } },
    { Title = "Class activity", Column = 1, ClassStates = true, Rows = {} },
    { Title = "Aura time", Column = 2, Class = "PALADIN", Dynamic = "SpellTime", Rows = {} },
    { Title = "Pet family time", Column = 2, Class = "HUNTER", Dynamic = "CompanionTime", Rows = {} },
    { Title = "Demon time", Column = 2, Class = "WARLOCK", Dynamic = "CompanionTime", Rows = {} },
  } },
}

local function CreateDashboardButton(parent, text, width, onClick)
  local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  button:SetSize(width, 24)
  button:SetText(text)
  button:SetNormalFontObject("GameFontNormalSmall")
  button:SetHighlightFontObject("GameFontHighlightSmall")
  button:SetScript("OnClick", onClick)
  return button
end

local function CreateDashboardRow(window, section, rowDefinition)
  local definition = section.Definition
  local row = CreateFrame("Button", nil, section)
  row.Definition = rowDefinition
  row.Label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  row.Label:SetPoint("LEFT", rowDefinition.Indent or 0, 0)
  row.Label:SetJustifyH("LEFT")
  row.Label:SetWordWrap(false)
  row.Label:SetText(rowDefinition[2])
  row.Values = {}
  for i = 1, definition.Columns and #definition.Columns or 1 do
    local value = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    value:SetJustifyH("RIGHT")
    value:SetWordWrap(false)
    table.insert(row.Values, value)
  end
  if (rowDefinition.IsTotal) then
    local background = row:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(row)
    background:SetColorTexture(1, 1, 1, 0.06)
  end
  row:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(row.Definition[2])
    for i, value in ipairs(self.Values) do
      GameTooltip:AddDoubleLine(definition.Columns and definition.Columns[i] or "Recorded",
        self.FullValues and self.FullValues[i] or value:GetText(), 1, 0.82, 0, 1, 1, 1)
    end
    if (rowDefinition[4]) then GameTooltip:AddLine("Click to view details", 0.6, 0.6, 0.6) end
    GameTooltip:Show()
  end)
  row:SetScript("OnLeave", function() GameTooltip:Hide() end)
  if (rowDefinition[4]) then
    row:SetScript("OnClick", function() window:OpenStatistics(rowDefinition[4]) end)
    local highlight = row:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(row)
    highlight:SetColorTexture(1, 0.82, 0, 0.08)
  end
  return row
end

local function CreateDashboardSection(window, definition)
  local section = CreateFrame("Frame", nil, window.ScrollFrame.Content)
  section.Definition = definition
  section.Rows = {}

  local background = section:CreateTexture(nil, "BACKGROUND")
  background:SetAllPoints(section)
  background:SetColorTexture(0, 0, 0, 0.18)

  local line = section:CreateTexture(nil, "BORDER")
  line:SetPoint("TOPLEFT", 0, 0)
  line:SetPoint("TOPRIGHT", 0, 0)
  line:SetHeight(1)
  line:SetColorTexture(0.6, 0.5, 0.3, 0.4)

  section.Title = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  section.Title:SetPoint("TOPLEFT", 12, -12)
  section.Title:SetText(definition.Title)
  section.Title:SetWordWrap(false)

  if (definition.Details) then
    section.DetailsButton = CreateDashboardButton(section, "View details", 82, function()
      window:OpenStatistics(definition.Details)
    end)
    section.DetailsButton:SetPoint("TOPRIGHT", -8, -7)
  end

  section.ColumnHeaders = {}
  for _, heading in ipairs(definition.Columns or {}) do
    local header = section:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    header:SetText(heading)
    header:SetJustifyH("RIGHT")
    table.insert(section.ColumnHeaders, header)
  end

  for _, rowDefinition in ipairs(definition.Rows) do
    table.insert(section.Rows, CreateDashboardRow(window, section, rowDefinition))
  end
  return section
end

function AutoBiographer_SummaryPanel:Initialize()
  AutioBiographer_WindowHelper:InitialzationHelper(self, 800, 650, 100, "Main", -157)
  self.Title:SetText("AutoBiographer")
  self.DisplayMinLevel = self.DisplayMinLevel or 1
  self.DisplayMaxLevel = self.DisplayMaxLevel or 9999
  self.DropdownText = self.DropdownText or "Total"
  self.ActiveTab = AutoBiographer_Settings.MainWindowTab or "Overview"
  self.DashboardPages = {}
  self.TabButtons = {}
  self.DashboardValues = {}
  self.GameVersion = HF.GetGameVersion()
  self.PlayerClass = Api.GetPlayerClass()

  self.CharacterLabel = self:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  self.CharacterLabel:SetPoint("TOPLEFT", 18, -14)
  self.CharacterLabel:SetSize(280, 24)
  self.CharacterLabel:SetJustifyH("LEFT")
  self.CharacterLabel:SetWordWrap(false)

  self.FilterLabel = self:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  self.FilterLabel:SetPoint("TOPLEFT", 18, -54)
  self.FilterLabel:SetText("Show:")
  self.Dropdown = CreateFrame("Frame", nil, self, "UIDropDownMenuTemplate")
  self.Dropdown:SetPoint("TOPLEFT", 55, -43)
  UIDropDownMenu_SetWidth(self.Dropdown, 165)
  UIDropDownMenu_Initialize(self.Dropdown, function(dropdown, level, menuList)
    self:UpdateLevelFilter(level, menuList)
  end)
  self.LevelTimeLabel = self:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  self.LevelTimeLabel:SetPoint("TOPRIGHT", -24, -54)
  self.LevelTimeLabel:SetWidth(480)
  self.LevelTimeLabel:SetJustifyH("RIGHT")

  for i, tab in ipairs(dashboardTabs) do
    local button = CreateDashboardButton(self, tab.Name, 100, function() self:SelectTab(tab.Name) end)
    button:SetPoint("TOPLEFT", 18 + (i - 1) * 106, -88)
    button:SetDisabledFontObject("GameFontNormalSmall")
    self.TabButtons[tab.Name] = button
    local sections = {}
    for _, definition in ipairs(tab.Sections) do
      if (definition.ClassStates) then
        definition.Rows = {}
        for _, state in ipairs(AutoBiographer_ClassActivity and AutoBiographer_ClassActivity.StateDefinitions or {}) do
          if (self.PlayerClass and (state[3] == self.PlayerClass or state.OtherClass == self.PlayerClass)) then
            table.insert(definition.Rows, { "Time" .. state[1], state[2], "time" })
          end
        end
      end
      if ((not definition.Class or definition.Class == self.PlayerClass) and
        (not definition.ClassStates or #definition.Rows > 0) and
        (not definition.Availability or
        definition.Availability == "Battlegrounds" and self.GameVersion < 3 or
        definition.Availability == "Arenas" and self.GameVersion == 2)) then
        table.insert(sections, CreateDashboardSection(self, definition))
      end
    end
    self.DashboardPages[tab.Name] = sections
  end
  if (not self.DashboardPages[self.ActiveTab]) then self.ActiveTab = "Overview" end

  self.ScrollFrame:ClearAllPoints()
  self.ScrollFrame:SetPoint("TOPLEFT", 18, -129)
  self.ScrollFrame:SetPoint("BOTTOMRIGHT", -32, 46)
  self.ScrollFrame.Content:SetWidth(750)
  self.ScrollFrame.Scrollbar:ClearAllPoints()
  self.ScrollFrame.Scrollbar:SetPoint("TOPLEFT", self, "TOPRIGHT", -25, -134)
  self.ScrollFrame.Scrollbar:SetPoint("BOTTOMLEFT", self, "BOTTOMRIGHT", -25, 51)
  self.ScrollFrame.Scrollbar.scrollStep = 22

  self.Footer = self:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  self.Footer:SetPoint("BOTTOMLEFT", 18, 20)
  self.Footer:SetWidth(640)
  self.Footer:SetJustifyH("LEFT")
  self.RefreshButton = CreateDashboardButton(self, "Refresh", 80, function() self:Update() end)
  self.RefreshButton:SetPoint("BOTTOMRIGHT", -22, 14)

  self.PanelReady = true
  self:LayoutPanel()
  self:Hide()
  return self
end

function AutoBiographer_SummaryPanel:LayoutDashboard()
  local width = self.ScrollFrame.Content:GetWidth()
  local columnWidth = (width - 16) / 2
  local columnBottom = { 0, 0 }
  for name, sections in pairs(self.DashboardPages) do
    local selected = name == self.ActiveTab
    if (selected) then self.TabButtons[name]:Disable()
    else self.TabButtons[name]:Enable() end
    for _, section in ipairs(sections) do
      section:Hide()
      if (selected) then
        local definition = section.Definition
        local column = definition.Column
        local fullWidth = column == 0
        local sectionWidth = fullWidth and width or columnWidth
        local top = fullWidth and math.max(columnBottom[1], columnBottom[2]) or columnBottom[column]
        section:ClearAllPoints()
        section:SetPoint("TOPLEFT", column == 2 and columnWidth + 16 or 0, -top)
        section:SetWidth(sectionWidth)
        section.Title:SetWidth(sectionWidth - (definition.Details and 110 or 24))
        local valueWidth = definition.Columns and 100 or 160
        for i, header in ipairs(section.ColumnHeaders) do
          header:SetPoint("TOPRIGHT", -12 - (#section.ColumnHeaders - i) * valueWidth, -36)
          header:SetWidth(valueWidth - 6)
        end
        local rowTop = definition.Columns and 56 or 36
        for _, row in ipairs(section.Rows) do
          local condition = row.Definition[5]
          row:Hide()
          if (not condition or self.DashboardValues[condition]) then
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", 12, -rowTop)
            row:SetSize(sectionWidth - 24, 22)
            row.Label:SetWidth(sectionWidth - 30 - #row.Values * valueWidth - (row.Definition.Indent or 0))
            for i, value in ipairs(row.Values) do
              value:SetPoint("RIGHT", -(#row.Values - i) * valueWidth, 0)
              value:SetWidth(valueWidth - 6)
            end
            row:Show()
            rowTop = rowTop + 22
          end
        end
        local height = rowTop + 10
        section:SetHeight(height)
        if (fullWidth) then
          columnBottom[1], columnBottom[2] = top + height + 16, top + height + 16
        else
          columnBottom[column] = top + height + 16
        end
        section:Show()
      end
    end
  end
  local contentHeight = math.max(columnBottom[1], columnBottom[2]) - 16
  local maxScroll = math.max(0, contentHeight - self.ScrollFrame:GetHeight())
  self.ScrollFrame.Content:SetHeight(math.max(1, contentHeight))
  self.ScrollFrame.Scrollbar:SetMinMaxValues(0, maxScroll)
  self.ScrollFrame.Scrollbar:SetValue(math.min(self.ScrollFrame.Scrollbar:GetValue(), maxScroll))
  self.ScrollFrame.Scrollbar:SetShown(maxScroll > 0)
end

function AutoBiographer_SummaryPanel:LayoutPanel()
  if (not self.PanelReady) then return end
  self.ScrollFrame.Content:SetWidth(math.max(1, self:GetWidth() - 50))
  self.Footer:SetWidth(math.max(1, self:GetWidth() - 160))
  self.LevelTimeLabel:SetWidth(math.max(1, self:GetWidth() - 310))
  self:LayoutDashboard()
end

function AutoBiographer_SummaryPanel:OpenStatistics(viewName)
  local window = AutoBiographer_StatisticsWindow
  window:SelectView(Enum.StatisticsDisplayMode[viewName], self.DisplayMinLevel,
    math.min(self.DisplayMaxLevel, Controller:GetCurrentLevelNum()))
  AutoBiographer_MainWindow:ShowSection("Statistics")
end

function AutoBiographer_SummaryPanel:SelectTab(name)
  if (not self.DashboardPages[name]) then return end
  self.ActiveTab = name
  AutoBiographer_Settings.MainWindowTab = name
  self.ScrollFrame.Scrollbar:SetValue(0)
  self:Update()
end

function AutoBiographer_SummaryPanel:Update()
  -- Commit active timers before aggregating. Restarting them prevents double counts.
  -- During the level-up request, wait for the new level record to be created first.
  if (EM.PlayerEnteringWorldHasFired and EM.TemporaryTimestamps.EnteredArea and not EM.NewLevelToAddToHistory) then
    EM:UpdateTimestamps(EM.PersistentPlayerInfo.CurrentZone, EM.PersistentPlayerInfo.CurrentSubZone)
  end
  local minLevel, maxLevel = self.DisplayMinLevel, self.DisplayMaxLevel
  local values = {}
  self.DashboardValues = values
  values.HasArenas = self.GameVersion == 2
  values.IsDruid = self.PlayerClass == "DRUID"
  values.IsShaman = self.PlayerClass == "SHAMAN"
  values.CanStealth = self.PlayerClass == "DRUID" or self.PlayerClass == "ROGUE"
  values.DistanceTotal = 0
  for category, trackingType in pairs(Enum.DistanceTrackingType) do
    local yards = Controller:GetDistanceByDistanceTrackingType(trackingType, minLevel, maxLevel)
    values["Distance" .. category] = yards
    values.DistanceTotal = values.DistanceTotal + yards
  end

  local name, lastName = Api.GetUnitName("player")
  if (name and lastName) then name = name .. " " .. lastName end
  self.CharacterLabel:SetText((name or EM.PlayerName or "Character") .. " | Level " .. Controller:GetCurrentLevelNum())
  UIDropDownMenu_SetText(self.Dropdown, self.DropdownText)
  local level = minLevel == maxLevel and Controller.CharacterData.Levels[minLevel]
  self.LevelTimeLabel:SetText(level and level.TimePlayedThisLevel and
    ("Time at level " .. minLevel .. ": " .. HF.SecondsToTimeString(level.TimePlayedThisLevel, true)) or "")

  for _, category in ipairs({ "DamageDealt", "DamageTaken", "PetDamageTaken", "HealingDealt", "HealingTaken" }) do
    local enumName = category
    if (category == "DamageTaken" or category == "PetDamageTaken" or category == "HealingTaken") then
      enumName = category .. "Raw"
    end
    local amount, over = Controller:GetDamageOrHealing(Enum.DamageOrHealingCategory[enumName], minLevel, maxLevel)
    values[category] = amount
    values[category .. "Breakdown"] = { amount, amount - over, over }
  end
  values.HasPetDamageTaken = values.PetDamageTaken > 0 or values.PetDamageTakenBreakdown[3] > 0

  values.Deaths = 0
  for _, category in ipairs({ "DeathToCreature", "DeathToDrowning", "DeathToEnvironment", "DeathToFalling",
    "DeathToGameObject", "DeathToPet", "DeathToPlayer", "DeathToUnknown" }) do
    values[category] = Controller:GetDeathsByDeathTrackingType(Enum.DeathTrackingType[category], minLevel, maxLevel)
    values.Deaths = values.Deaths + values[category]
  end

  local kills = Controller:GetAggregatedKillStatisticsTotals(minLevel, maxLevel)
  values.KillingBlows = KillStatistics.GetSum(kills, { Enum.KillTrackingType.TaggedKillingBlow })
  values.KillAssists = KillStatistics.GetSum(kills, { Enum.KillTrackingType.TaggedAssist })
  values.GroupKills = KillStatistics.GetSum(kills, { Enum.KillTrackingType.TaggedGroupAssistOrKillingBlow })
  values.Kills = values.KillingBlows + values.KillAssists + values.GroupKills
  for _, category in ipairs({ "Discovery", "GroupBonus", "RaidPenalty", "RestedBonus", "Quest" }) do
    values["Experience" .. category] = Controller:GetExperienceByExperienceTrackingType(Enum.ExperienceTrackingType[category], minLevel, maxLevel)
  end
  values.ExperienceKills = Controller:GetExperienceByExperienceTrackingType(Enum.ExperienceTrackingType.Kill, minLevel, maxLevel)
  values.ExperienceKillsBase = values.ExperienceKills - values.ExperienceRestedBonus - values.ExperienceGroupBonus + values.ExperienceRaidPenalty

  local quests = Controller:GetAggregatedQuestStatisticsDictionary(minLevel, maxLevel)
  local questTotals = Controller:GetAggregatedQuestStatisticsTotals(minLevel, maxLevel, quests)
  values.QuestsUnique = HF.GetTableLength(quests)
  values.QuestsRepeated = QuestStatistics.GetSum(questTotals, { Enum.QuestTrackingType.Completed }) - values.QuestsUnique
  values.SpellsStarted = Controller:GetSpellCountBySpellTrackingType(Enum.SpellTrackingType.StartedCasting, minLevel, maxLevel)
  values.SpellsSucceeded = Controller:GetSpellCountBySpellTrackingType(Enum.SpellTrackingType.SuccessfullyCast, minLevel, maxLevel)
  for _, category in ipairs({ "Camped", "Jumps" }) do
    values[category] = Controller:GetMiscellaneousStatByMiscellaneousTrackingType(Enum.MiscellaneousTrackingType[category], minLevel, maxLevel)
  end

  values.ItemsTotal = 0
  for category, acquisitionMethod in pairs(Enum.ItemAcquisitionMethod) do
    values["Items" .. category] = Controller:GetItemCountForAcquisitionMethod(acquisitionMethod, minLevel, maxLevel)
    values.ItemsTotal = values.ItemsTotal + values["Items" .. category]
  end
  values.MessagesTotal = 0
  local messageStatistics = Controller:GetAggregatedMessageStatistics(minLevel, maxLevel)
  for category, messageTrackingType in pairs(Enum.MessageTrackingType) do
    local count = messageStatistics[messageTrackingType] or 0
    values["Messages" .. category] = count
    values.MessagesTotal = values.MessagesTotal + count
  end
  values.MoneyTotal = Controller:GetTotalMoneyGained(minLevel, maxLevel)
  values.MoneyOther = values.MoneyTotal
  for _, category in ipairs({ "AuctionHouseDepositReturn", "AuctionHouseOutbid", "AuctionHouseSale", "Loot",
    "Mail", "MailCod", "Merchant", "Quest", "Trade" }) do
    values["Money" .. category] = Controller:GetMoneyForAcquisitionMethod(Enum.MoneyAcquisitionMethod[category], minLevel, maxLevel)
    values.MoneyOther = values.MoneyOther - values["Money" .. category]
  end
  values.MoneyOther = math.max(0, values.MoneyOther)

  values.DuelsWon = Controller:GetOtherPlayerStatByOtherPlayerTrackingType(Enum.OtherPlayerTrackingType.DuelsLostToPlayer, minLevel, maxLevel)
  values.DuelsLost = Controller:GetOtherPlayerStatByOtherPlayerTrackingType(Enum.OtherPlayerTrackingType.DuelsWonAgainstPlayer, minLevel, maxLevel)
  for _, category in ipairs({ "OutsideGroup", "InGroup" }) do
    local trackingType = category == "OutsideGroup" and Enum.OtherPlayerTrackingType.BuffsGivenToPlayerNotGrouped or Enum.OtherPlayerTrackingType.BuffsGivenToPlayerWhileGrouped
    values["Buffs" .. category] = Controller:GetOtherPlayerStatByOtherPlayerTrackingType(trackingType, minLevel, maxLevel)
    values["PlayersBuffed" .. category] = Controller:GetUniqueOtherPlayerCountByOtherPlayerTrackingType(trackingType, minLevel, maxLevel)
  end
  for category, trackingType in pairs(Enum.TimeTrackingType) do
    local key = category == "InParty" and "Grouped" or category
    values["Time" .. key] = Controller:GetTimeForTimeTrackingType(trackingType, minLevel, maxLevel)
  end
  self:UpdateClassTimeRows(minLevel, maxLevel)

  if (self.GameVersion < 3) then
    for _, id in ipairs({ 1, 2, 3, 4 }) do
      local joined, losses, wins = Controller:GetBattlegroundStatsByBattlegroundId(id, minLevel, maxLevel)
      values["Battleground" .. id] = { wins, losses, joined - losses - wins }
    end
  end
  if (self.GameVersion == 2) then
    for _, size in ipairs({ 2, 3, 5 }) do
      for _, registered in ipairs({ true, false }) do
        local joined, losses, wins = Controller:GetArenaStatsByRegistrationTypeAndTeamSize(registered, size, minLevel, maxLevel)
        values["Arena" .. (registered and "Rated" or "Skirmish") .. size] = { wins, losses, joined - losses - wins }
      end
    end
  end

  for _, sections in pairs(self.DashboardPages) do
    for _, section in ipairs(sections) do
      for _, row in ipairs(section.Rows) do
        local key, _, format = unpack(row.Definition)
        local value = values[key]
        row.FullValues = {}
        if (format == "breakdown" or format == "results") then
          local numbers = format == "breakdown" and values[key .. "Breakdown"] or value
          for i, number in ipairs(numbers or { 0, 0, 0 }) do
            row.Values[i]:SetText(HF.CommaValue(number))
            row.FullValues[i] = HF.CommaValue(number)
          end
        elseif (format == "time") then
          row.Values[1]:SetText(HF.SecondsToTimeString(value or 0, true))
          row.FullValues[1] = HF.SecondsToTimeString(value or 0)
        elseif (format == "distance") then
          local yards = HF.CommaValue(HF.Round(value or 0, 1))
          row.Values[1]:SetText(yards .. " yd")
          row.FullValues[1] = yards .. " yards"
        elseif (format == "money") then
          row.Values[1]:SetText(Api.FormatMoney(value or 0))
          row.FullValues[1] = Api.FormatMoney(value or 0)
        else
          row.Values[1]:SetText(HF.CommaValue(value or 0))
          row.FullValues[1] = HF.CommaValue(value or 0)
        end
      end
    end
  end
  self.Footer:SetText(self.ActiveTab == "Travel" and "Horizontal distance in yards; areas without readable coordinates are not recorded." or
    self.ActiveTab == "Time" and "Time categories overlap; they do not add up to total play time." or
    ("Recorded statistics | " .. self.DropdownText))
  self:LayoutDashboard()
end

function AutoBiographer_SummaryPanel:UpdateClassTimeRows(minLevel, maxLevel)
  for _, section in ipairs(self.DashboardPages.Time) do
    local dynamic = section.Definition.Dynamic
    if (dynamic) then
      section.RowPool = section.RowPool or {}
      for _, row in pairs(section.RowPool) do row:Hide() end
      local totals, names = {}, {}
      if (dynamic == "SpellTime") then
        for spellId, seconds in pairs(Controller:GetAggregatedSpellTime(minLevel, maxLevel)) do
          local spell = Controller.CharacterData.Catalogs.SpellCatalog[spellId]
          local name = spell and spell.Name or ("Spell #" .. spellId)
          totals[name] = (totals[name] or 0) + seconds
        end
      else
        local catalog = Controller.CharacterData.Catalogs.CompanionFamilyCatalog or {}
        for familyId, seconds in pairs(Controller:GetAggregatedCompanionFamilyTime(minLevel, maxLevel)) do
          local name = catalog[familyId] or ("Family #" .. familyId)
          totals[name] = (totals[name] or 0) + seconds
        end
      end
      for name in pairs(totals) do names[#names + 1] = name end
      table.sort(names)
      if (#names == 0) then names[1] = "None recorded"; totals[names[1]] = 0 end
      section.Rows = {}
      for _, name in ipairs(names) do
        local key = dynamic .. name
        if (not section.RowPool[key]) then
          section.RowPool[key] = CreateDashboardRow(self, section, { key, name, "time" })
        end
        table.insert(section.Rows, section.RowPool[key])
        self.DashboardValues[key] = totals[name]
      end
    end
  end
end

function AutoBiographer_SummaryPanel:UpdateLevelFilter(level, menuList)
  local info = UIDropDownMenu_CreateInfo()
  info.func = function(button, minLevel, maxLevel)
    self.DropdownText = button.value
    self.DisplayMinLevel, self.DisplayMaxLevel = minLevel, maxLevel
    self:Update()
  end
  if (not level or level == 1) then
    info.text, info.arg1, info.arg2 = "Total", 1, 9999
    info.checked = self.DisplayMinLevel == 1 and self.DisplayMaxLevel == 9999
    UIDropDownMenu_AddButton(info, level)
    local highestRange = math.floor((Controller:GetCurrentLevelNum() - 1) / 10)
    for range = 0, highestRange do
      local includeRange = false
      for i = 1, 10 do
        if (Controller.CharacterData.Levels[range * 10 + i]) then includeRange = true end
      end
      if (includeRange) then
        info.arg1, info.arg2 = range * 10 + 1, range * 10 + 10
        info.text = "Levels " .. info.arg1 .. " - " .. info.arg2
        info.menuList, info.hasArrow = range, true
        info.checked = self.DisplayMinLevel == info.arg1 and self.DisplayMaxLevel == info.arg2
        UIDropDownMenu_AddButton(info, level)
      end
    end
  else
    for i = 1, 10 do
      local levelNum = menuList * 10 + i
      if (Controller.CharacterData.Levels[levelNum]) then
        info.text, info.arg1, info.arg2 = "Level " .. levelNum, levelNum, levelNum
        info.checked = self.DisplayMinLevel == levelNum and self.DisplayMaxLevel == levelNum
        UIDropDownMenu_AddButton(info, level)
      end
    end
  end
end
