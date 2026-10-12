local Controller = AutoBiographer_Controller
local EM = AutoBiographer_EventManager
local HF = HelperFunctions
local Api = AutoBiographer_Api
local Enum = AutoBiographerEnum

local rowHeight = 26
local views = {
  { "Damage Dealt", Enum.StatisticsDisplayMode.DamageDealt },
  { "Damage Dealt by Rank", Enum.StatisticsDisplayMode.DamageDealtByRank },
  { "Damage Taken by Spell", Enum.StatisticsDisplayMode.DamageTakenBySpell },
  { "Damage Taken by Unit", Enum.StatisticsDisplayMode.DamageTakenByUnit },
  { "Healing Dealt", Enum.StatisticsDisplayMode.HealingDealt },
  { "Healing Dealt by Rank", Enum.StatisticsDisplayMode.HealingDealtByRank },
  { "Item Acquisitions", Enum.StatisticsDisplayMode.Items },
  { "Kills", Enum.StatisticsDisplayMode.Kills },
  { "Levels", Enum.StatisticsDisplayMode.Levels },
  { "Other Players", Enum.StatisticsDisplayMode.OtherPlayers },
  { "Spells", Enum.StatisticsDisplayMode.Spells },
  { "Spells by Rank", Enum.StatisticsDisplayMode.SpellsByRank },
  { "Time", Enum.StatisticsDisplayMode.Time },
}
local headerDescriptions = {
  AH = "Items acquired from the auction house.",
  COD = "Items acquired through cash-on-delivery mail.",
  Create = "Items created by crafting.",
  Loot = "Items looted.",
  Mail = "Items received through ordinary mail.",
  Other = "Items acquired through other tracked methods.",
  Trade = "Items received through player trades.",
  Vendor = "Items purchased from vendors.",
  ["Tagged KB"] = "Killing blows against units tagged for you or your group.",
  ["Tagged KB+A"] = "Total tagged kills, including killing blows, assists, and group kills.",
  ["Untagged KB"] = "Killing blows against units not tagged for you or your group.",
  ["Untagged KB+A"] = "Total untagged kills, including killing blows, assists, and group kills.",
  ["Buffs (Outside)"] = "Qualifying buffs given to this player while they were outside your group.",
  ["Buffs (In Group)"] = "Qualifying buffs given to this player while they were in your group.",
  ["Duels (Win)"] = "Your duels won against this player.",
  ["Duels (Lose)"] = "Your duels lost to this player.",
  AFK = "Recorded time spent away from keyboard.",
  Casting = "Recorded time spent casting.",
  Dead = "Recorded time spent dead or as a ghost.",
  Combat = "Recorded time spent in combat.",
  Total = "Total recorded time. Activity columns overlap and should not be added together.",
  Taxi = "Recorded time spent on flight paths.",
  Grouped = "Recorded time spent in a party or raid.",
  Gamepad = "Recorded time with the Gamepad UI enabled.",
  ["Over Damage"] = "Tracked damage beyond the target's remaining health. Unavailable overdamage is not estimated.",
  ["Over Healing"] = "Tracked healing beyond missing health. Unavailable overhealing is not estimated.",
  Rank = "Spell rank. A dash means no rank was recorded.",
  Level = "Statistics recorded while at this level. * indicates a potentially partial recording; + indicates the current level, still in progress.",
  ["Time Played"] = "Time recorded by AutoBiographer at this level, including AFK time. Time played while the addon was disabled is not included.",
  ["XP Gained"] = "Recorded kill, quest, and exploration XP. Kill XP already includes bonuses. Hover a row for the XP breakdown.",
  ["XP/hour"] = "Recorded XP divided by recorded time played, including AFK time. The total is a combined rate, not the sum of individual rates.",
  ["Money Gained"] = "All recorded increases in your money, including trade and mail receipts.",
  ["Money Lost"] = "All recorded decreases in your money, including spending and money given away through trade or mail.",
  ["Money Net"] = "Money gained minus money lost at this level, not the character's wallet balance.",
  Kills = "Total tagged kills, including killing blows, assists, and group kills.",
  Quests = "Quest completions recorded at this level, including repeated quests.",
  Deaths = "All deaths recorded at this level.",
}

local function CreateButton(parent, text, width, onClick)
  local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  button:SetSize(width, 24)
  button:SetText(text)
  button:SetNormalFontObject("GameFontNormalSmall")
  button:SetHighlightFontObject("GameFontHighlightSmall")
  button:SetScript("OnClick", onClick)
  return button
end

local function FormatDuration(seconds)
  seconds = math.max(0, math.floor(seconds))
  local days = math.floor(seconds / 86400)
  local hours = math.floor(seconds / 3600) % 24
  local minutes = math.floor(seconds / 60) % 60
  if (days > 0) then return days .. "d " .. hours .. "h" end
  if (hours > 0) then return hours .. "h " .. minutes .. "m" end
  if (minutes > 0) then return minutes .. "m " .. seconds % 60 .. "s" end
  return seconds .. "s"
end

local function IsDurationColumn(window, column)
  return window.StatisticsDisplayMode == Enum.StatisticsDisplayMode.Time and column > 1 or
    window.StatisticsDisplayMode == Enum.StatisticsDisplayMode.OtherPlayers and column == 6 or
    window.StatisticsDisplayMode == Enum.StatisticsDisplayMode.Levels and column == 2
end

local function FormatValue(window, column, value, row)
  if (value == nil) then return "" end
  if (window.StatisticsDisplayMode == Enum.StatisticsDisplayMode.Levels) then
    if (column == 1 and row) then return tostring(value) .. (row.LevelStatistics.IsPartial and "*" or "") .. (row.LevelStatistics.IsInProgress and "+" or "") end
    if (column >= 5 and column <= 7) then return (value < 0 and "-" or "") .. Api.FormatMoney(math.abs(value)) end
    if (column == 4 and row and row[2] == 0) then return "-" end
  end
  if (IsDurationColumn(window, column)) then return FormatDuration(value) end
  if (window.CurrentTableData.HeaderValues[column] == "Rank") then
    return value == 0 and "-" or tostring(value)
  end
  if (type(value) == "number") then return HF.CommaValue(HF.Round(value, 0)) end
  return tostring(value)
end

local function ShowHeaderTooltip(header)
  GameTooltip:SetOwner(header, "ANCHOR_RIGHT")
  GameTooltip:SetText(header.Label, 1, 0.82, 0)
  if (headerDescriptions[header.Label]) then
    GameTooltip:AddLine(headerDescriptions[header.Label], 1, 1, 1, true)
  end
  GameTooltip:AddLine("Click to sort; click again to reverse.", 0.7, 0.7, 0.7)
  GameTooltip:Show()
end

function AutoBiographer_StatisticsWindow:ApplyCustomRange()
  local state = self:GetViewState()
  local currentLevel = Controller:GetCurrentLevelNum()
  state.MinLevel = math.max(1, math.min(currentLevel, self.MinimumLevelEb:GetNumber()))
  state.MaxLevel = math.max(state.MinLevel, math.min(currentLevel, self.MaximumLevelEb:GetNumber()))
  self.MinimumLevelEb:SetNumber(state.MinLevel)
  self.MaximumLevelEb:SetNumber(state.MaxLevel)
  self:Update(true)
end

function AutoBiographer_StatisticsWindow:ApplyLevelFilter(filter)
  self:GetViewState().LevelFilter = filter
  self:Update(true)
end

function AutoBiographer_StatisticsWindow:ClearFilters()
  local state = self:GetViewState()
  state.Search = ""
  state.LevelFilter = "All"
  self.IsRestoringView = true
  self.SearchBox:SetText("")
  self.IsRestoringView = false
  self:Update(true)
end

function AutoBiographer_StatisticsWindow:GetTableData(minLevel, maxLevel)

  -- Get table data.
  local tableData
  local isRankView = self.StatisticsDisplayMode == AutoBiographerEnum.StatisticsDisplayMode.DamageDealtByRank or
    self.StatisticsDisplayMode == AutoBiographerEnum.StatisticsDisplayMode.HealingDealtByRank or
    self.StatisticsDisplayMode == AutoBiographerEnum.StatisticsDisplayMode.SpellsByRank
  
  if (self.StatisticsDisplayMode == AutoBiographerEnum.StatisticsDisplayMode.DamageDealt) then
    local abilitiesBySpellName = Controller:GetAggregatedDamageMeterAbilities({ AutoBiographerEnum.DamageOrHealingCategory.DamageDealt }, minLevel, maxLevel, true)
    tableData = {
      HeaderValues = { "Spell Name", "Effective Damage", "Over Damage" },
      RowOffsets = { 0, 250, 450, 650 },
      Rows = {},
    }
    for spellName, breakdown in pairs(abilitiesBySpellName) do
      table.insert(tableData.Rows, { spellName, breakdown.Amount - breakdown.Over, breakdown.Over })
    end
  elseif (self.StatisticsDisplayMode == AutoBiographerEnum.StatisticsDisplayMode.DamageDealtByRank) then
    local abilitiesBySpellId = Controller:GetAggregatedDamageMeterAbilities({ AutoBiographerEnum.DamageOrHealingCategory.DamageDealt }, minLevel, maxLevel)
    tableData = {
      HeaderValues = { "Spell Name", "Rank", "Effective Damage", "Over Damage" },
      RowOffsets = { 0, 250, 330, 490, 650 },
      Rows = {},
    }
    for spellId, breakdown in pairs(abilitiesBySpellId) do
      local catalogSpell = Controller.CharacterData.Catalogs.SpellCatalog[spellId]
      local spellName = CatalogSpell.GetDamageMeterDisplayName(catalogSpell, spellId)
      local rank = catalogSpell and catalogSpell.Rank
      if (type(rank) == "string") then rank = tonumber(string.match(rank, "%d+")) end
      rank = rank or Api.GetSpellRank(spellId) or 0
      table.insert(tableData.Rows, { spellName, rank, breakdown.Amount - breakdown.Over, breakdown.Over, SpellId = spellId })
    end
  elseif (self.StatisticsDisplayMode == AutoBiographerEnum.StatisticsDisplayMode.DamageTakenBySpell) then
    local breakdownsByUnitAndSpell = Controller:GetAggregatedDamageTakenBySpell({ AutoBiographerEnum.DamageOrHealingCategory.DamageTaken }, minLevel, maxLevel)
    tableData = {
      HeaderValues = { "Spell Name", "Unit Name", "Effective Damage", "Over Damage" },
      RowOffsets = { 0, 200, 365, 505, 650 },
      Rows = {},
    }
    for unitName, spells in pairs(breakdownsByUnitAndSpell) do
      for spellId, breakdown in pairs(spells) do
        local catalogSpell = Controller.CharacterData.Catalogs.SpellCatalog[spellId]
        local spellName = catalogSpell and catalogSpell.Name or ("Spell ID: " .. tostring(spellId))
        table.insert(tableData.Rows, { spellName, unitName, breakdown.Amount - breakdown.Over, breakdown.Over, SpellId = spellId })
      end
    end
    local unknownBreakdown = Controller:GetAggregatedDamageTakenUnknownBreakdown(minLevel, maxLevel)
    if (unknownBreakdown.Amount ~= 0 or unknownBreakdown.Over ~= 0) then
      table.insert(tableData.Rows, { "Unknown", "Unknown", unknownBreakdown.Amount - unknownBreakdown.Over, unknownBreakdown.Over, IsUnknown = true })
    end
  elseif (self.StatisticsDisplayMode == AutoBiographerEnum.StatisticsDisplayMode.DamageTakenByUnit) then
    local breakdownsByUnit = Controller:GetAggregatedDamageTakenByUnit({ AutoBiographerEnum.DamageOrHealingCategory.DamageTaken }, minLevel, maxLevel)
    tableData = {
      HeaderValues = { "Unit Name", "Effective Damage", "Over Damage" },
      RowOffsets = { 0, 250, 450, 650 },
      Rows = {},
    }
    for unitName, breakdown in pairs(breakdownsByUnit) do
      table.insert(tableData.Rows, { unitName, breakdown.Amount - breakdown.Over, breakdown.Over })
    end
    local unknownBreakdown = Controller:GetAggregatedDamageTakenUnknownBreakdown(minLevel, maxLevel)
    if (unknownBreakdown.Amount ~= 0 or unknownBreakdown.Over ~= 0) then
      table.insert(tableData.Rows, { "Unknown", unknownBreakdown.Amount - unknownBreakdown.Over, unknownBreakdown.Over, IsUnknown = true })
    end
  elseif (self.StatisticsDisplayMode == AutoBiographerEnum.StatisticsDisplayMode.HealingDealt) then
    local abilitiesBySpellName = Controller:GetAggregatedDamageMeterAbilities({ AutoBiographerEnum.DamageOrHealingCategory.HealingDealt }, minLevel, maxLevel, true)
    tableData = {
      HeaderValues = { "Spell Name", "Effective Healing", "Over Healing" },
      RowOffsets = { 0, 250, 450, 650 },
      Rows = {},
    }
    for spellName, breakdown in pairs(abilitiesBySpellName) do
      table.insert(tableData.Rows, { spellName, breakdown.Amount - breakdown.Over, breakdown.Over })
    end
  elseif (self.StatisticsDisplayMode == AutoBiographerEnum.StatisticsDisplayMode.HealingDealtByRank) then
    local abilitiesBySpellId = Controller:GetAggregatedDamageMeterAbilities({ AutoBiographerEnum.DamageOrHealingCategory.HealingDealt }, minLevel, maxLevel)
    tableData = {
      HeaderValues = { "Spell Name", "Rank", "Effective Healing", "Over Healing" },
      RowOffsets = { 0, 250, 330, 490, 650 },
      Rows = {},
    }
    for spellId, breakdown in pairs(abilitiesBySpellId) do
      local catalogSpell = Controller.CharacterData.Catalogs.SpellCatalog[spellId]
      local spellName = CatalogSpell.GetDamageMeterDisplayName(catalogSpell, spellId)
      local rank = catalogSpell and catalogSpell.Rank
      if (type(rank) == "string") then rank = tonumber(string.match(rank, "%d+")) end
      rank = rank or Api.GetSpellRank(spellId) or 0
      table.insert(tableData.Rows, { spellName, rank, breakdown.Amount - breakdown.Over, breakdown.Over, SpellId = spellId })
    end
  elseif (self.StatisticsDisplayMode == AutoBiographerEnum.StatisticsDisplayMode.Items) then
    local itemStatisticsByItem = Controller:GetAggregatedItemStatisticsDictionary(minLevel, maxLevel)
    tableData = {
      HeaderValues = { "Item Name", "AH", "COD", "Create", "Loot", "Mail", "Other", "Trade", "Vendor" },
      RowOffsets = { 0, 225, 275, 325, 375, 425, 475, 525, 575, 625 },
      Rows = {},
    }
    for catalogItemId, itemStatistics in pairs(itemStatisticsByItem) do
      if (Controller.CharacterData.Catalogs.ItemCatalog[catalogItemId]) then
        local itemName
        if (Controller.CharacterData.Catalogs.ItemCatalog[catalogItemId].Name) then
          itemName = Controller.CharacterData.Catalogs.ItemCatalog[catalogItemId].Name
        else
          itemName = "Item ID: " .. tostring(catalogItemId)
        end

        local row = {
          itemName,
          ItemStatistics.GetSum(itemStatistics, { AutoBiographerEnum.ItemAcquisitionMethod.AuctionHouse }),
          ItemStatistics.GetSum(itemStatistics, { AutoBiographerEnum.ItemAcquisitionMethod.MailCod }),
          ItemStatistics.GetSum(itemStatistics, { AutoBiographerEnum.ItemAcquisitionMethod.Create }),
          ItemStatistics.GetSum(itemStatistics, { AutoBiographerEnum.ItemAcquisitionMethod.Loot }),
          ItemStatistics.GetSum(itemStatistics, { AutoBiographerEnum.ItemAcquisitionMethod.Mail }),
          ItemStatistics.GetSum(itemStatistics, { AutoBiographerEnum.ItemAcquisitionMethod.Other }),
          ItemStatistics.GetSum(itemStatistics, { AutoBiographerEnum.ItemAcquisitionMethod.Trade }),
          ItemStatistics.GetSum(itemStatistics, { AutoBiographerEnum.ItemAcquisitionMethod.Merchant }),
        }
        row.ItemId = catalogItemId
        table.insert(tableData.Rows, row)
      end
    end
  elseif (self.StatisticsDisplayMode == AutoBiographerEnum.StatisticsDisplayMode.Kills) then
    local killStatisticsByUnit = Controller:GetAggregatedKillStatisticsDictionary(minLevel, maxLevel)
    tableData = {
      HeaderValues = { "Unit Name", "Tagged KB", "Tagged KB+A", "Untagged KB", "Untagged KB+A" },
      RowOffsets = { 0, 225, 340, 455, 570, 685 },
      Rows = {},
    }
    local unknownRow
    for catalogUnitId, killStatistics in pairs(killStatisticsByUnit) do
      local catalogUnit = Controller.CharacterData.Catalogs.UnitCatalog[catalogUnitId]
      local unitName = catalogUnit and catalogUnit.Name
      if (unitName and unitName ~= "" and catalogUnit.LastName and catalogUnit.LastName ~= "") then
        unitName = unitName .. " " .. catalogUnit.LastName
      end
      local row = {
        unitName,
        KillStatistics.GetSum(killStatistics, { AutoBiographerEnum.KillTrackingType.TaggedKillingBlow }),
        KillStatistics.GetSum(killStatistics, { AutoBiographerEnum.KillTrackingType.TaggedAssist, AutoBiographerEnum.KillTrackingType.TaggedGroupAssistOrKillingBlow, AutoBiographerEnum.KillTrackingType.TaggedKillingBlow }),
        KillStatistics.GetSum(killStatistics, { AutoBiographerEnum.KillTrackingType.UntaggedKillingBlow }),
        KillStatistics.GetSum(killStatistics, { AutoBiographerEnum.KillTrackingType.UntaggedAssist, AutoBiographerEnum.KillTrackingType.UntaggedGroupAssistOrKillingBlow, AutoBiographerEnum.KillTrackingType.UntaggedKillingBlow }),
      }
      if (unitName and unitName ~= "") then
        table.insert(tableData.Rows, row)
      else
        if (not unknownRow) then
          unknownRow = { "Unknown", 0, 0, 0, 0 }
          table.insert(tableData.Rows, unknownRow)
        end
        for column = 2, 5 do
          unknownRow[column] = unknownRow[column] + row[column]
        end
      end
    end
  elseif (self.StatisticsDisplayMode == AutoBiographerEnum.StatisticsDisplayMode.Levels) then
    tableData = {
      HeaderValues = { "Level", "Time Played", "XP Gained", "XP/hour", "Money Gained", "Money Lost", "Money Net", "Kills", "Quests", "Deaths" },
      RowOffsets = { 0, 60, 165, 260, 350, 480, 610, 740, 800, 860, 920 },
      RateColumns = { [4] = { Numerator = 3, Denominator = 2, Multiplier = 3600 } },
      Rows = {},
    }
    for levelNum, statistics in pairs(Controller:GetLevelStatistics(minLevel, maxLevel)) do
      table.insert(tableData.Rows, { levelNum, statistics.TimePlayed, statistics.ExperienceTotal, statistics.ExperiencePerHour,
        statistics.MoneyGained, statistics.MoneyLost, statistics.MoneyNet, statistics.Kills, statistics.Quests, statistics.Deaths,
        LevelStatistics = statistics, SearchText = (statistics.IsPartial and "partial " or "") .. (statistics.IsInProgress and "in progress" or ""),
      })
    end
  elseif (self.StatisticsDisplayMode == AutoBiographerEnum.StatisticsDisplayMode.OtherPlayers) then
    local otherPlayerStatisticsByUnit = Controller:GetAggregatedOtherPlayerStatisticsDictionary(minLevel, maxLevel)
    tableData = {
      HeaderValues = { "Unit Name", "Buffs (Outside)", "Buffs (In Group)", "Duels (Win)", "Duels (Lose)", "Time Grouped" },
      RowOffsets = { 0, 170, 290, 400, 485, 570, 700 },
      Rows = {},
    }
    for catalogUnitId, otherPlayerStatistics in pairs(otherPlayerStatisticsByUnit) do
      local catalogUnit = Controller.CharacterData.Catalogs.UnitCatalog[catalogUnitId]
      local unitName = catalogUnit and catalogUnit.Name or ("Unit ID: " .. tostring(catalogUnitId))
      if (catalogUnit and catalogUnit.Name and catalogUnit.LastName and catalogUnit.LastName ~= "") then
        unitName = unitName .. " " .. catalogUnit.LastName
      end

      local row = {
        unitName,
        OtherPlayerStatistics.GetSum(otherPlayerStatistics, { AutoBiographerEnum.OtherPlayerTrackingType.BuffsGivenToPlayerNotGrouped }),
        OtherPlayerStatistics.GetSum(otherPlayerStatistics, { AutoBiographerEnum.OtherPlayerTrackingType.BuffsGivenToPlayerWhileGrouped }),
        OtherPlayerStatistics.GetSum(otherPlayerStatistics, { AutoBiographerEnum.OtherPlayerTrackingType.DuelsLostToPlayer }),
        OtherPlayerStatistics.GetSum(otherPlayerStatistics, { AutoBiographerEnum.OtherPlayerTrackingType.DuelsWonAgainstPlayer }),
        OtherPlayerStatistics.GetSum(otherPlayerStatistics, { AutoBiographerEnum.OtherPlayerTrackingType.TimeSpentGroupedWithPlayer }),
      }
      table.insert(tableData.Rows, row)
    end
  elseif (self.StatisticsDisplayMode == AutoBiographerEnum.StatisticsDisplayMode.Spells) then
    local spellStatisticsBySpell = Controller:GetAggregatedSpellStatisticsDictionary(minLevel, maxLevel)
    tableData = {
      HeaderValues = { "Spell Name", "Started Casting", "Successfully Cast" },
      RowOffsets = { 0, 225, 340, 455 },
      Rows = {},
    }

    local dictAggregatedBySpellName = {}
    for catalogSpellId, spellStatistics in pairs(spellStatisticsBySpell) do
      if (Controller.CharacterData.Catalogs.SpellCatalog[catalogSpellId]) then
        local spellName
        if (Controller.CharacterData.Catalogs.SpellCatalog[catalogSpellId].Name) then
          spellName = Controller.CharacterData.Catalogs.SpellCatalog[catalogSpellId].Name
        else
          spellName = "Spell ID: " .. catalogSpellId
        end

        local startedCasting = SpellStatistics.GetSum(spellStatistics, { AutoBiographerEnum.SpellTrackingType.StartedCasting })
        local successfullyCast = SpellStatistics.GetSum(spellStatistics, { AutoBiographerEnum.SpellTrackingType.SuccessfullyCast })

        if (not dictAggregatedBySpellName[spellName]) then
          dictAggregatedBySpellName[spellName] = {
            spellName,
            startedCasting,
            successfullyCast,
          }
        else
          dictAggregatedBySpellName[spellName][2] = dictAggregatedBySpellName[spellName][2] + startedCasting
          dictAggregatedBySpellName[spellName][3] = dictAggregatedBySpellName[spellName][3] + successfullyCast
        end
      end
    end

    for k, row in pairs(dictAggregatedBySpellName) do
      table.insert(tableData.Rows, row)
    end
  elseif (self.StatisticsDisplayMode == AutoBiographerEnum.StatisticsDisplayMode.SpellsByRank) then
    local spellStatisticsBySpell = Controller:GetAggregatedSpellStatisticsDictionary(minLevel, maxLevel)
    tableData = {
      HeaderValues = { "Spell Name", "Rank", "Started Casting", "Successfully Cast" },
      RowOffsets = { 0, 250, 330, 490, 650 },
      Rows = {},
    }
    for spellId, spellStatistics in pairs(spellStatisticsBySpell) do
      local catalogSpell = Controller.CharacterData.Catalogs.SpellCatalog[spellId]
      local spellName = catalogSpell and catalogSpell.Name or ("Spell ID: " .. tostring(spellId))
      local rank = catalogSpell and catalogSpell.Rank
      if (type(rank) == "string") then rank = tonumber(string.match(rank, "%d+")) end
      rank = rank or Api.GetSpellRank(spellId) or 0
      local startedCasting = SpellStatistics.GetSum(spellStatistics, { AutoBiographerEnum.SpellTrackingType.StartedCasting })
      local successfullyCast = SpellStatistics.GetSum(spellStatistics, { AutoBiographerEnum.SpellTrackingType.SuccessfullyCast })
      table.insert(tableData.Rows, { spellName, rank, startedCasting, successfullyCast, SpellId = spellId })
    end
  elseif (self.StatisticsDisplayMode == AutoBiographerEnum.StatisticsDisplayMode.Time) then
    local timeStatisticsByArea = Controller:GetAggregatedTimeStatisticsDictionary(minLevel, maxLevel)
    tableData = {
      HeaderValues = { "Area", "AFK", "Casting", "Dead", "Combat", "Total", "Taxi", "Grouped", "Gamepad" },
      RowOffsets = { 0, 225, 285, 345, 405, 465, 525, 585, 645, 705 },
      Rows = {},
    }

    local dictAggregatedByZone = {}
    for areaId, timeStatistics in pairs(timeStatisticsByArea) do
      local zone = string.sub(areaId, 1, areaId:find("-") - 1)
      local afk = TimeStatistics.GetSum(timeStatistics, { AutoBiographerEnum.TimeTrackingType.Afk })
      local casting = TimeStatistics.GetSum(timeStatistics, { AutoBiographerEnum.TimeTrackingType.Casting })
      local deadOrGhost = TimeStatistics.GetSum(timeStatistics, { AutoBiographerEnum.TimeTrackingType.DeadOrGhost })
      local inCombat = TimeStatistics.GetSum(timeStatistics, { AutoBiographerEnum.TimeTrackingType.InCombat })
      local loggedIn = TimeStatistics.GetSum(timeStatistics, { AutoBiographerEnum.TimeTrackingType.LoggedIn })
      local onTaxi = TimeStatistics.GetSum(timeStatistics, { AutoBiographerEnum.TimeTrackingType.OnTaxi })
      local inParty = TimeStatistics.GetSum(timeStatistics, { AutoBiographerEnum.TimeTrackingType.InParty })
      local gamepadUI = TimeStatistics.GetSum(timeStatistics, { AutoBiographerEnum.TimeTrackingType.GamepadUI })

      if (not dictAggregatedByZone[zone]) then
        dictAggregatedByZone[zone] = {
          zone,
          afk,
          casting,
          deadOrGhost,
          inCombat,
          loggedIn,
          onTaxi,
          inParty,
          gamepadUI,
        }
      else
        dictAggregatedByZone[zone][2] = dictAggregatedByZone[zone][2] + afk
        dictAggregatedByZone[zone][3] = dictAggregatedByZone[zone][3] + casting
        dictAggregatedByZone[zone][4] = dictAggregatedByZone[zone][4] + deadOrGhost
        dictAggregatedByZone[zone][5] = dictAggregatedByZone[zone][5] + inCombat
        dictAggregatedByZone[zone][6] = dictAggregatedByZone[zone][6] + loggedIn
        dictAggregatedByZone[zone][7] = dictAggregatedByZone[zone][7] + onTaxi
        dictAggregatedByZone[zone][8] = dictAggregatedByZone[zone][8] + inParty
        dictAggregatedByZone[zone][9] = dictAggregatedByZone[zone][9] + gamepadUI
      end
    end

    for k, row in pairs(dictAggregatedByZone) do
      if (row[1] ~= "nil") then
        table.insert(tableData.Rows, row)
      end
    end
  else
    print("[AutoBiographer] Unsupported Statistics Display Mode. This should not happen!")
    return
  end

  -- Only attach a spell tooltip to grouped names when they identify one catalog spell.
  -- Rows with several ranks deliberately retain a summary tooltip instead.
  if (tableData.HeaderValues[1] == "Spell Name" and not isRankView) then
    local spellIdsByName = {}
    for spellId, spell in pairs(Controller.CharacterData.Catalogs.SpellCatalog) do
      local displayName = CatalogSpell.GetDamageMeterDisplayName(spell, spellId)
      for _, name in ipairs({ spell.Name or displayName, displayName }) do
        if (spellIdsByName[name] and spellIdsByName[name] ~= spellId) then spellIdsByName[name] = 0
        else spellIdsByName[name] = spellId end
      end
    end
    for _, row in ipairs(tableData.Rows) do
      local spellId = spellIdsByName[row[1]]
      if (not row.SpellId and not row.IsUnknown and spellId and spellId ~= 0) then row.SpellId = spellId end
    end
  end
  return tableData, isRankView
end

function AutoBiographer_StatisticsWindow:GetViewState()
  local mode = self.StatisticsDisplayMode
  if (not self.ViewStates[mode]) then
    self.ViewStates[mode] = {
      Search = "", LevelFilter = "All", MinLevel = 1, MaxLevel = Controller:GetCurrentLevelNum(),
      SortColumn = 1, SortDirection = "ASC", Scroll = 0,
    }
  end
  return self.ViewStates[mode]
end

function AutoBiographer_StatisticsWindow:Initialize()
  AutioBiographer_WindowHelper:InitialzationHelper(self, 750, 585, 150, "Statistics", -114)
  self.ViewStates = {}
  self.RowPool = {}
  self.TableHeaders = {}
  self.TotalCells = {}
  self.FilterGeneration = 0
  self.StatisticsDisplayMode = self.StatisticsDisplayMode or Enum.StatisticsDisplayMode.Kills
  self.DropdownText = self.DropdownText or "Kills"

  self.Dropdown = CreateFrame("Frame", nil, self, "UIDropDownMenuTemplate")
  self.Dropdown:SetPoint("TOPLEFT", 14, -4)
  UIDropDownMenu_SetWidth(self.Dropdown, 200)
  UIDropDownMenu_Initialize(self.Dropdown, function()
    for _, view in ipairs(views) do
      local info = UIDropDownMenu_CreateInfo()
      info.text = view[1]
      info.checked = self.StatisticsDisplayMode == view[2]
      info.func = function() self:SelectView(view[2]) end
      UIDropDownMenu_AddButton(info)
    end
  end)
  self.LevelDropdown = CreateFrame("Frame", nil, self, "UIDropDownMenuTemplate")
  self.LevelDropdown:SetPoint("TOPLEFT", 264, -4)
  UIDropDownMenu_SetWidth(self.LevelDropdown, 154)
  UIDropDownMenu_Initialize(self.LevelDropdown, function()
    for _, filter in ipairs({ { "All levels", "All" }, { "Current level", "Current" }, { "Custom range", "Custom" } }) do
      local info = UIDropDownMenu_CreateInfo()
      info.text = filter[1]
      info.checked = self:GetViewState().LevelFilter == filter[2]
      info.func = function() self:ApplyLevelFilter(filter[2]) end
      UIDropDownMenu_AddButton(info)
    end
  end)

  self.SearchBox = CreateFrame("EditBox", nil, self, "InputBoxTemplate")
  self.SearchBox:SetPoint("TOPRIGHT", -26, -14)
  self.SearchBox:SetHeight(24)
  self.SearchBox:SetAutoFocus(false)
  self.SearchBox:SetMaxLetters(200)
  self.SearchHint = self.SearchBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  self.SearchHint:SetPoint("LEFT", 2, 0)
  self.SearchHint:SetText("Search statistics...")
  self.SearchBox:SetScript("OnEscapePressed", function(box) box:ClearFocus() end)
  self.SearchBox:SetScript("OnEnterPressed", function(box) box:ClearFocus(); self:UpdateFilteredRows(true) end)
  self.SearchBox:SetScript("OnTextChanged", function(box)
    self.SearchHint:SetShown(box:GetText() == "")
    if (self.IsRestoringView) then return end
    self:GetViewState().Search = box:GetText()
    self.FilterGeneration = self.FilterGeneration + 1
    local generation = self.FilterGeneration
    C_Timer.After(0.15, function()
      if (generation == self.FilterGeneration and self:IsVisible()) then self:UpdateFilteredRows(true) end
    end)
  end)
  self.SearchBox:SetText("")
  self.ScopeLabel = self:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  self.ScopeLabel:SetPoint("TOPLEFT", 18, -53)
  self.ScopeLabel:SetJustifyH("LEFT")
  self.ScopeLabel:SetWordWrap(false)

  self.CustomRange = CreateFrame("Frame", nil, self)
  self.CustomRange:SetPoint("TOPRIGHT", -22, -45)
  self.CustomRange:SetSize(230, 24)
  local previous
  for i, name in ipairs({ "Minimum", "Maximum" }) do
    local label = self.CustomRange:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetText(i == 1 and "From level" or "to")
    if (previous) then label:SetPoint("LEFT", previous, "RIGHT", 12, 0)
    else label:SetPoint("LEFT", 0, 0) end
    local box = CreateFrame("EditBox", nil, self.CustomRange, "InputBoxTemplate")
    box:SetPoint("LEFT", label, "RIGHT", 12, 0)
    box:SetSize(40, 22)
    box:SetAutoFocus(false)
    box:SetNumeric(true)
    box:SetMaxLetters(3)
    box:SetScript("OnEscapePressed", function(editBox)
      local state = self:GetViewState()
      editBox:SetNumber(name == "Minimum" and state.MinLevel or state.MaxLevel)
      editBox:ClearFocus()
    end)
    box:SetScript("OnEnterPressed", function(editBox) editBox:ClearFocus() end)
    box:SetScript("OnEditFocusLost", function() if (not self.IsRestoringView) then self:ApplyCustomRange() end end)
    self[name .. "LevelEb"] = box
    previous = box
  end
  self.CustomRange:Hide()

  self.ScrollFrame.Scrollbar.scrollStep = rowHeight * 3
  self.ScrollFrame.Scrollbar:SetScript("OnValueChanged", function(_, value)
    self.ScrollFrame:SetVerticalScroll(value)
    if (not self.IsRestoringView) then self:GetViewState().Scroll = value end
    self:RenderVisibleRows()
  end)
  self.ScrollFrame:EnableMouseWheel(true)
  self.ScrollFrame:SetScript("OnMouseWheel", function(_, delta) self:ScrollRows(delta) end)
  self:SetScript("OnMouseWheel", function(_, delta) self:ScrollRows(delta) end)
  self.TotalsPanel = CreateFrame("Frame", nil, self)
  self.TotalsPanel:SetPoint("BOTTOMLEFT", 18, 44)
  self.TotalsPanel:SetPoint("BOTTOMRIGHT", -32, 44)
  self.TotalsPanel:SetHeight(32)
  local background = self.TotalsPanel:CreateTexture(nil, "BACKGROUND")
  background:SetAllPoints(self.TotalsPanel)
  background:SetColorTexture(1, 1, 1, 0.06)
  local line = self.TotalsPanel:CreateTexture(nil, "BORDER")
  line:SetPoint("TOPLEFT")
  line:SetPoint("TOPRIGHT")
  line:SetHeight(1)
  line:SetColorTexture(0.6, 0.5, 0.3, 0.4)
  self.TotalsPanel:EnableMouse(true)
  self.TotalsPanel:SetScript("OnEnter", function(panel)
    GameTooltip:SetOwner(panel, "ANCHOR_RIGHT")
    GameTooltip:SetText(self:GetViewState().Search ~= "" and "Matching-row totals" or "Totals", 1, 0.82, 0)
    GameTooltip:AddLine("Totals include the rows matching the current search and level filter. Names and ranks are not added together.", 1, 1, 1, true)
    if (self.StatisticsDisplayMode == Enum.StatisticsDisplayMode.Time) then
      GameTooltip:AddLine(headerDescriptions.Total, 1, 1, 1, true)
    elseif (self.StatisticsDisplayMode == Enum.StatisticsDisplayMode.Levels) then
      GameTooltip:AddLine(headerDescriptions["XP/hour"], 1, 1, 1, true)
    end
    GameTooltip:Show()
  end)
  self.TotalsPanel:SetScript("OnLeave", function() GameTooltip:Hide() end)

  self.EmptyMessage = self:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  self.EmptyMessage:SetPoint("CENTER", self.ScrollFrame, "CENTER")
  self.EmptyMessage:SetWordWrap(true)
  self.Footer = self:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  self.Footer:SetPoint("BOTTOMLEFT", 18, 20)
  self.Footer:SetJustifyH("LEFT")
  self.ClearButton = CreateButton(self, "Clear filters", 96, function() self:ClearFilters() end)
  self.ClearButton:SetPoint("BOTTOMRIGHT", -112, 14)
  self.RefreshButton = CreateButton(self, "Refresh", 80, function() self:Update() end)
  self.RefreshButton:SetPoint("BOTTOMRIGHT", -22, 14)
  self:SetScript("OnHide", function()
    if (self.StatisticsDisplayMode and not self.IsRestoringView) then
      self:GetViewState().Scroll = self.ScrollFrame.Scrollbar:GetValue()
    end
    self.SearchBox:ClearFocus()
    self.IsRestoringView = true
    self.MinimumLevelEb:ClearFocus()
    self.MaximumLevelEb:ClearFocus()
    self.IsRestoringView = false
  end)
  self.PanelReady = true
  self:LayoutPanel()
  self:Hide()
  return self
end

function AutoBiographer_StatisticsWindow:LayoutPanel()
  if (not self.PanelReady) then return end
  self.SearchBox:SetWidth(math.max(180, math.min(300, self:GetWidth() - 538)))
  self.ScopeLabel:SetWidth(math.max(1, self:GetWidth() - 285))
  self.Footer:SetWidth(math.max(1, self:GetWidth() - 235))
  self.EmptyMessage:SetWidth(math.max(1, self:GetWidth() - 130))
  self.ScrollFrame:ClearAllPoints()
  self.ScrollFrame:SetPoint("TOPLEFT", 18, -114)
  self.ScrollFrame:SetPoint("BOTTOMRIGHT", -32, 82)
  self.ScrollFrame.Content:SetWidth(math.max(1, self:GetWidth() - 50))
  self.ScrollFrame.Scrollbar:ClearAllPoints()
  self.ScrollFrame.Scrollbar:SetPoint("TOPLEFT", self, "TOPRIGHT", -25, -119)
  self.ScrollFrame.Scrollbar:SetPoint("BOTTOMLEFT", self, "BOTTOMRIGHT", -25, 87)
  if (self.CurrentTableData) then self:RenderStatisticsTable() end
end

function AutoBiographer_StatisticsWindow:RenderStatisticsTable()
  local tableData = self.CurrentTableData
  if (not tableData or not self.FilteredRows) then return end
  self.ColumnOffsets = {}
  local scale = self.ScrollFrame.Content:GetWidth() / tableData.RowOffsets[#tableData.RowOffsets]
  for i, offset in ipairs(tableData.RowOffsets) do self.ColumnOffsets[i] = offset * scale end
  local offsets = self.ColumnOffsets
  local state = self:GetViewState()
  for _, header in ipairs(self.TableHeaders) do header:Hide() end
  for _, cell in ipairs(self.TotalCells) do cell:Hide() end
  for i, label in ipairs(tableData.HeaderValues) do
    local header = self.TableHeaders[i]
    if (not header) then
      header = CreateButton(self, "", 100, function() end)
      header.Arrow = header:CreateTexture(nil, "OVERLAY")
      header.Arrow:SetSize(10, 10)
      header.Arrow:SetPoint("RIGHT", -5, 0)
      self.TableHeaders[i] = header
    end
    header.Label = label
    header:ClearAllPoints()
    header:SetPoint("TOPLEFT", 18 + offsets[i], -84)
    header:SetSize(offsets[i + 1] - offsets[i], 26)
    header:SetText(label)
    local text = header:GetFontString()
    text:ClearAllPoints()
    text:SetPoint("LEFT", 6, 0)
    text:SetPoint("RIGHT", -18, 0)
    text:SetWordWrap(false)
    -- Set alignment explicitly; columns containing names are text, all others are numeric.
    text:SetJustifyH((i == 1 or label == "Unit Name") and "LEFT" or "RIGHT")
    header.Arrow:SetTexture(state.SortDirection == "ASC" and "Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up" or "Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
    header.Arrow:SetShown(state.SortColumn == i)
    header:SetScript("OnClick", function()
      if (state.SortColumn == i) then state.SortDirection = state.SortDirection == "ASC" and "DESC" or "ASC"
      else state.SortColumn = i; state.SortDirection = (i == 1 or label == "Unit Name") and "ASC" or "DESC" end
      self:UpdateFilteredRows(true)
    end)
    header:SetScript("OnEnter", ShowHeaderTooltip)
    header:SetScript("OnLeave", function() GameTooltip:Hide() end)
    header:Show()

    local totalCell = self.TotalCells[i]
    if (not totalCell) then
      totalCell = self.TotalsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      self.TotalCells[i] = totalCell
    end
    totalCell:ClearAllPoints()
    totalCell:SetPoint("LEFT", self.TotalsPanel, "LEFT", offsets[i] + 8, 0)
    totalCell:SetWidth(math.max(1, offsets[i + 1] - offsets[i] - 16))
    totalCell:SetWordWrap(false)
    totalCell:SetJustifyH(i == 1 and "LEFT" or "RIGHT")
    totalCell:SetText(i == 1 and (state.Search ~= "" and "Matching total" or "Total") or FormatValue(self, i, self.FilteredTotals[i]))
    totalCell:Show()
  end
  local height = math.max(1, #self.FilteredRows * rowHeight)
  self.ScrollFrame.Content:SetHeight(height)
  local maximum = math.max(0, height - self.ScrollFrame:GetHeight())
  local scroll = math.min(state.Scroll or 0, maximum)
  self.IsRestoringView = true
  self.ScrollFrame.Scrollbar:SetMinMaxValues(0, maximum)
  self.ScrollFrame.Scrollbar:SetValue(scroll)
  self.ScrollFrame:SetVerticalScroll(scroll)
  self.IsRestoringView = false
  state.Scroll = scroll
  self.ScrollFrame.Scrollbar:SetShown(maximum > 0)
  self.EmptyMessage:SetShown(#self.FilteredRows == 0)
  self.EmptyMessage:SetText(#tableData.Rows == 0 and "No statistics recorded for this view and level range.\nTry All levels or another statistics type." or "No statistics match your search.\nTry another name or clear the filters.")
  self.Footer:SetText(HF.CommaValue(#self.FilteredRows) .. " of " .. HF.CommaValue(#tableData.Rows) .. " rows")
  if (self.StatisticsDisplayMode == Enum.StatisticsDisplayMode.Levels) then
    self.Footer:SetText(self.Footer:GetText() .. "  |  * Partial recording  + In progress")
  end
  self:RenderVisibleRows()
end

function AutoBiographer_StatisticsWindow:RenderVisibleRows()
  if (not self.ColumnOffsets or not self.FilteredRows) then return end
  -- Recycled cells can represent a different row after scrolling or filtering.
  for _, row in ipairs(self.RowPool) do
    for _, cell in ipairs(row.Cells) do
      if (GameTooltip:IsOwned(cell)) then GameTooltip:Hide() end
    end
  end
  local scroll = self.ScrollFrame.Scrollbar:GetValue()
  local first = math.floor(scroll / rowHeight) + 1
  local last = math.min(#self.FilteredRows, math.ceil((scroll + self.ScrollFrame:GetHeight()) / rowHeight) + 1)
  local poolIndex = 0
  for index = first, last do
    poolIndex = poolIndex + 1
    local row = self.RowPool[poolIndex]
    if (not row) then
      row = CreateFrame("Button", nil, self.ScrollFrame.Content)
      row.Cells = {}
      row.Background = row:CreateTexture(nil, "BACKGROUND")
      row.Background:SetAllPoints(row)
      row.Highlight = row:CreateTexture(nil, "ARTWORK")
      row.Highlight:SetAllPoints(row)
      row.Highlight:SetColorTexture(1, 1, 1, 0.06)
      row.Highlight:Hide()
      row:EnableMouseWheel(true)
      row:SetScript("OnMouseWheel", function(_, delta) self:ScrollRows(delta) end)
      self.RowPool[poolIndex] = row
    end
    row.Data = self.FilteredRows[index]
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", 0, -(index - 1) * rowHeight)
    row:SetSize(self.ScrollFrame.Content:GetWidth(), rowHeight)
    row.Background:SetColorTexture(1, 1, 1, index % 2 == 0 and 0.025 or 0)
    row.Highlight:Hide()
    for _, cell in ipairs(row.Cells) do cell:Hide() end
    for column = 1, #self.CurrentTableData.HeaderValues do
      local cell = row.Cells[column]
      if (not cell) then
        cell = CreateFrame("Button", nil, row)
        cell.Text = cell:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        cell.Text:SetPoint("LEFT", 8, 0)
        cell.Text:SetPoint("RIGHT", -8, 0)
        cell.Text:SetWordWrap(false)
        cell:EnableMouseWheel(true)
        cell:SetScript("OnMouseWheel", function(_, delta) self:ScrollRows(delta) end)
        cell:SetScript("OnEnter", function(button)
          row.Highlight:Show()
          self:ShowRowTooltip(button, row.Data, button.Column)
        end)
        cell:SetScript("OnLeave", function(button)
          row.Highlight:Hide()
          if (GameTooltip:IsOwned(button)) then GameTooltip:Hide() end
        end)
        row.Cells[column] = cell
      end
      cell.Column = column
      cell:ClearAllPoints()
      cell:SetPoint("TOPLEFT", self.ColumnOffsets[column], 0)
      cell:SetSize(self.ColumnOffsets[column + 1] - self.ColumnOffsets[column], rowHeight)
      cell.Text:SetJustifyH(type(row.Data[column]) == "number" and "RIGHT" or "LEFT")
      cell.Text:SetText(FormatValue(self, column, row.Data[column], row.Data))
      cell:Show()
    end
    row:Show()
  end
  for i = poolIndex + 1, #self.RowPool do self.RowPool[i]:Hide() end
end

function AutoBiographer_StatisticsWindow:SaveViewState()
  if (not self.StatisticsDisplayMode) then return end
  self:GetViewState().Scroll = self.ScrollFrame.Scrollbar:GetValue()
end

function AutoBiographer_StatisticsWindow:ScrollRows(delta)
  local _, maximum = self.ScrollFrame.Scrollbar:GetMinMaxValues()
  self.ScrollFrame.Scrollbar:SetValue(math.max(0, math.min(maximum,
    self.ScrollFrame.Scrollbar:GetValue() - delta * self.ScrollFrame.Scrollbar.scrollStep)))
end

function AutoBiographer_StatisticsWindow:SelectView(mode, minLevel, maxLevel)
  self:SaveViewState()
  self.IsRestoringView = true
  self.SearchBox:ClearFocus()
  self.MinimumLevelEb:ClearFocus()
  self.MaximumLevelEb:ClearFocus()
  self.FilterGeneration = self.FilterGeneration + 1
  for _, view in ipairs(views) do
    if (view[2] == mode) then self.StatisticsDisplayMode = mode; self.DropdownText = view[1]; break end
  end
  local state = self:GetViewState()
  if (minLevel and maxLevel) then
    local currentLevel = Controller:GetCurrentLevelNum()
    state.MinLevel = math.max(1, math.min(currentLevel, minLevel))
    state.MaxLevel = math.max(state.MinLevel, math.min(currentLevel, maxLevel))
    if (state.MinLevel == 1 and maxLevel >= currentLevel) then state.LevelFilter = "All"
    elseif (state.MinLevel == currentLevel and state.MaxLevel == currentLevel) then state.LevelFilter = "Current"
    else state.LevelFilter = "Custom" end
    state.Scroll = 0
  end
  self.SearchBox:SetText(state.Search)
  self.IsRestoringView = false
  self.CurrentTableData = nil
  self:Update()
end

function AutoBiographer_StatisticsWindow:ShowRowTooltip(owner, row, column)
  GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
  if (row.LevelStatistics) then
    GameTooltip:SetText("Level " .. row[1], 1, 0.82, 0)
    if (row.LevelStatistics.IsInProgress) then GameTooltip:AddLine("In progress", 0.3, 1, 0.3) end
    if (row.LevelStatistics.IsPartial) then GameTooltip:AddLine("The beginning of this level was not recorded; statistics may be partial.", 1, 0.82, 0, true) end
  elseif (column == 1 and row.ItemId and Api.GetItemInfo(row.ItemId)) then
    GameTooltip:SetHyperlink("item:" .. tostring(row.ItemId))
  elseif (column == 1 and row.SpellId and Api.GetSpellInfo(row.SpellId)) then
    GameTooltip:SetHyperlink("spell:" .. tostring(row.SpellId))
  else
    GameTooltip:SetText(tostring(row[1]), 1, 0.82, 0)
  end
  for i = 2, #self.CurrentTableData.HeaderValues do
    local value = row[i]
    local text = IsDurationColumn(self, i) and HF.SecondsToTimeString(value, true) or FormatValue(self, i, value, row)
    GameTooltip:AddDoubleLine(self.CurrentTableData.HeaderValues[i], text, 0.8, 0.8, 0.8, 1, 1, 1)
  end
  if (row.IsUnknown) then
    GameTooltip:AddLine("Raw damage taken that could not be attributed to a unit or spell by the damage meter.", 1, 1, 1, true)
  end
  if (row.LevelStatistics) then
    local statistics, xp = row.LevelStatistics, row.LevelStatistics.Experience
    local types = Enum.ExperienceTrackingType
    local killXp, rested, group, penalty = xp[types.Kill] or 0, xp[types.RestedBonus] or 0, xp[types.GroupBonus] or 0, xp[types.RaidPenalty] or 0
    GameTooltip:AddLine("XP breakdown", 1, 0.82, 0)
    for _, entry in ipairs({ { "Kills (total)", killXp }, { "  Kills (base)", killXp - rested - group + penalty },
      { "  Rested bonus", rested }, { "  Group bonus", group }, { "  Raid penalty", penalty },
      { "Quests", xp[types.Quest] or 0 }, { "Exploration", xp[types.Discovery] or 0 } }) do
      GameTooltip:AddDoubleLine(entry[1], HF.CommaValue(entry[2]), 0.8, 0.8, 0.8, 1, 1, 1)
    end
    GameTooltip:AddDoubleLine("AFK time", HF.SecondsToTimeString(statistics.AfkTime, true), 0.8, 0.8, 0.8, 1, 1, 1)
    GameTooltip:AddDoubleLine("Grouped time", HF.SecondsToTimeString(statistics.GroupedTime, true), 0.8, 0.8, 0.8, 1, 1, 1)
    GameTooltip:AddDoubleLine("Distance travelled", HF.CommaValue(HF.Round(statistics.DistanceTravelled / 1760, 1)) .. " mi", 0.8, 0.8, 0.8, 1, 1, 1)
  end
  GameTooltip:Show()
end

function AutoBiographer_StatisticsWindow:Update(resetScroll)
  local state = self:GetViewState()
  local currentLevel = Controller:GetCurrentLevelNum()
  local minLevel, maxLevel = 1, currentLevel
  if (state.LevelFilter == "Current") then minLevel = currentLevel
  elseif (state.LevelFilter == "Custom") then
    state.MinLevel = math.max(1, math.min(currentLevel, state.MinLevel))
    state.MaxLevel = math.max(state.MinLevel, math.min(currentLevel, state.MaxLevel))
    minLevel, maxLevel = state.MinLevel, state.MaxLevel
  end
  self.IsRestoringView = true
  self.MinimumLevelEb:SetNumber(state.MinLevel)
  self.MaximumLevelEb:SetNumber(state.MaxLevel)
  self.CustomRange:SetShown(state.LevelFilter == "Custom")
  self.IsRestoringView = false
  UIDropDownMenu_SetText(self.Dropdown, self.DropdownText)
  UIDropDownMenu_SetText(self.LevelDropdown, state.LevelFilter == "All" and "All levels" or state.LevelFilter == "Current" and "Current level" or "Custom range")
  self.ScopeLabel:SetText(minLevel == maxLevel and "Statistics recorded at level " .. minLevel or "Statistics recorded at levels " .. minLevel .. "–" .. maxLevel)
  -- Refresh active play-time counters through the existing tracking path.
  if (EM.PlayerEnteringWorldHasFired and EM.TemporaryTimestamps.EnteredArea and not EM.NewLevelToAddToHistory) then
    EM:UpdateTimestamps(EM.PersistentPlayerInfo.CurrentZone, EM.PersistentPlayerInfo.CurrentSubZone)
  end
  self.CurrentTableData, self.CurrentIsRankView = self:GetTableData(minLevel, maxLevel)
  self:UpdateFilteredRows(resetScroll)
end

function AutoBiographer_StatisticsWindow:UpdateFilteredRows(resetScroll)
  if (not self.CurrentTableData) then return end
  local state = self:GetViewState()
  local search = string.lower(state.Search)
  local rows, totals = {}, {}
  local rateColumns = self.CurrentTableData.RateColumns or {}
  for _, row in ipairs(self.CurrentTableData.Rows) do
    local names = {}
    for i, value in ipairs(row) do
      if (i == 1 or type(value) == "string" or self.CurrentTableData.HeaderValues[i] == "Rank") then
        table.insert(names, tostring(value))
      end
    end
    if (row.SearchText) then table.insert(names, row.SearchText) end
    if (search == "" or string.find(string.lower(table.concat(names, " ")), search, 1, true)) then
      table.insert(rows, row)
      for i, value in ipairs(row) do
        if (type(value) == "number" and self.CurrentTableData.HeaderValues[i] ~= "Rank" and self.CurrentTableData.HeaderValues[i] ~= "Level" and not rateColumns[i]) then
          totals[i] = (totals[i] or 0) + value
        end
      end
    end
  end
  for column, rate in pairs(rateColumns) do
    local denominator = totals[rate.Denominator] or 0
    totals[column] = denominator > 0 and (totals[rate.Numerator] or 0) * rate.Multiplier / denominator or 0
  end
  local column = math.max(1, math.min(#self.CurrentTableData.HeaderValues, state.SortColumn))
  state.SortColumn = column
  table.sort(rows, function(left, right)
    local a, b = left[column], right[column]
    if (self.CurrentIsRankView and column == 1 and a == b) then a, b = left[2], right[2] end
    if (state.SortDirection == "ASC") then return a < b end
    return a > b
  end)
  -- Numeric columns still show a zero total when there are no matching rows.
  for i, label in ipairs(self.CurrentTableData.HeaderValues) do
    if (i > 1 and label ~= "Rank" and label ~= "Unit Name") then totals[i] = totals[i] or 0 end
  end
  self.FilteredRows, self.FilteredTotals = rows, totals
  if (resetScroll) then state.Scroll = 0 end
  self:RenderStatisticsTable()
end

