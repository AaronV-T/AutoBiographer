-- Reuse UI usage timing, level boundaries and pending-level buffering, with
-- separate runtime state and a separate saved statistics collection.
AutoBiographer_FeatureActivity = setmetatable({
  Active = false,
  States = {},
  Frames = {},
  HookedFrames = {},
  PendingStatistics = {},
  Generation = 0,
  StatisticsKey = "FeatureStatistics",
  Definitions = {},
}, { __index = AutoBiographer_UiActivity })

local Activity = AutoBiographer_FeatureActivity
local Features = AutoBiographerEnum.AddonFeature
local Modes = AutoBiographerEnum.StatisticsDisplayMode

local function Add(key, name, frameName, selection, value)
  table.insert(Activity.Definitions, {
    Id = Features[key], Name = name, Frames = { frameName },
    GetVisibility = function()
      local frame = _G[frameName]
      local visible = AutoBiographer_MainWindow and AutoBiographer_MainWindow:IsVisible()
        and frame and frame:IsVisible() and (not selection or frame[selection] == value)
      return visible == true, true
    end,
  })
end

Add("AdventureReplay", "Adventure Replay", "AutoBiographer_ReplayPanel")
Add("CampfireTales", "Campfire Tales", "AutoBiographer_CampfireTalesPanel")
Add("EventLog", "Event Log", "AutoBiographer_EventWindow")
Add("GearLog", "Gear Log", "AutoBiographer_GearPanel")
Add("Map", "Map", "AutoBiographer_CharacterMapPanel")
Add("Notes", "Notes", "AutoBiographer_NotesWindow")
Add("Roster", "Roster", "AutoBiographer_CharactersPanel")
Add("Snapshots", "Snapshots", "AutoBiographer_SnapshotPanel")
Add("Statistics", "Statistics", "AutoBiographer_StatisticsWindow")
for _, view in ipairs({
  { "DamageDealt", "Damage Dealt", Modes.DamageDealt },
  { "DamageDealtByRank", "Damage Dealt by Rank", Modes.DamageDealtByRank },
  { "DamageTakenBySpell", "Damage Taken by Spell", Modes.DamageTakenBySpell },
  { "DamageTakenByUnit", "Damage Taken by Unit", Modes.DamageTakenByUnit },
  { "Deaths", "Deaths", Modes.Deaths },
  { "FeatureUsage", "Feature Usage", Modes.FeatureUsage },
  { "HealingDealt", "Healing Dealt", Modes.HealingDealt },
  { "HealingDealtByRank", "Healing Dealt by Rank", Modes.HealingDealtByRank },
  { "ItemAcquisitions", "Item Acquisitions", Modes.Items },
  { "ItemRolls", "Item Rolls", Modes.ItemRolls },
  { "Kills", "Kills", Modes.Kills },
  { "Levels", "Levels", Modes.Levels },
  { "OtherPlayers", "Other Players", Modes.OtherPlayers },
  { "RandomRolls", "Random Rolls", Modes.RandomRolls },
  { "Spells", "Spells", Modes.Spells },
  { "SpellsByRank", "Spells by Rank", Modes.SpellsByRank },
  { "Time", "Time", Modes.Time },
  { "UiUsage", "UI Usage", Modes.UiUsage },
}) do
  Add("Statistics" .. view[1], "Statistics / " .. view[2], "AutoBiographer_StatisticsWindow", "StatisticsDisplayMode", view[3])
end
Add("Summary", "Summary", "AutoBiographer_SummaryPanel")
for _, name in ipairs({ "Combat", "Economy", "Overview", "Progression", "Social", "Time", "Travel" }) do
  Add("Summary" .. name, "Summary / " .. name, "AutoBiographer_SummaryPanel", "ActiveTab", name)
end
Add("Tasks", "Tasks", "AutoBiographer_TodoPanel")

function Activity:DiscoverFrames()
  local function Watch(frame)
    if (not frame or self.HookedFrames[frame]) then return end
    self.HookedFrames[frame] = true
    -- Our own panels can update immediately, including a close and reopen in
    -- the same frame. Main-window hooks also catch parent visibility changes.
    local function Changed() self:Update() end
    frame:HookScript("OnShow", Changed)
    frame:HookScript("OnHide", Changed)
  end
  Watch(AutoBiographer_MainWindow)
  for _, definition in ipairs(self.Definitions) do Watch(_G[definition.Frames[1]]) end
end
