AutoBiographer_OptionWindow = CreateFrame("Frame", "AutoBiographer Options", UIParent)
local Api = AutoBiographer_Api

local optionGroups = {
  { Title = "Display & Tooltips", Controls = {
    { Name = "ShowMinimapButton", Text = "Show button on the minimap." },
    { Name = "FriendlyPlayerTooltip", Text = "Show duel and grouped time info on friendly player tooltips." },
    { Name = "KillCountTooltip", Text = "Show kill count on enemy tooltips." },
    { Name = "DiscoveryTooltip", Text = "Show 'Added in Forever' on tooltips for Forever-specific items and creatures.", Availability = "Forever" },
  } },
  { Title = "Personal Messages", Controls = {
    { Name = "ShowTimePlayedOnLevelUp", Text = "Show time played upon leveling up." },
    { Name = "ShowLevelUpStatMessages", Text = "Show health and stat gains upon leveling up in WoW Forever.", Availability = "Forever" },
    { Name = "EnableMilestoneMessages", Text = "Show personal milestone messages (minor and major)." },
  } },
  { Title = "Sharing", Controls = {
    { Name = "ShareMilestonesInGuild", Text = "Automatically share major milestones in guild chat." },
    { Name = "ShareMilestonesAsEmotes", Text = "Offer major milestones as emotes (click to send)." },
    { Name = "RecommendCampfireMessages", Text = "Recommend messages to share at campfires.", Availability = "Forever" },
    { Name = "EnableCustomEventSharing", Text = "Allow guild members to share custom events with you." },
  } },
  { Title = "Screenshots", Controls = {
    { Name = "ScreenshotOnLevelUp", Text = "Take a screenshot on level up." },
    { Name = "ScreenshotOnBossKill", Text = "Take a screenshot on boss kills." },
    { Name = "ScreenshotOnlyOnFirstBossKill", Text = "Only the first time killing a particular boss.", Parent = "ScreenshotOnBossKill" },
    { Name = "ScreenshotOnAchievementEarned", Text = "Take a screenshot on achievements earned.", Availability = "Achievements" },
  } },
  { Title = "Advanced & Debug", Controls = {
    { Name = "EnableDebugLogging", Text = "Enable debug logging (this can negatively affect performance)." },
  }, DebugButton = true },
}

local function IsAvailable(availability)
  if (availability == "Forever") then return Api.IsWoWForever() end
  if (availability == "Achievements") then
    return Api.IsEventAvailable("ACHIEVEMENT_EARNED", GetAchievementInfo ~= nil)
  end
  return true
end

function AutoBiographer_OptionWindow:Initialize()
  self.Header = self:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  self.Header:SetPoint("TOPLEFT", 16, -14)
  self.Header:SetText("AutoBiographer Options")

  self.ScrollFrame = CreateFrame("ScrollFrame", nil, self)
  self.ScrollFrame:SetPoint("TOPLEFT", 16, -46)
  self.ScrollFrame:SetPoint("BOTTOMRIGHT", -36, 16)
  self.Content = CreateFrame("Frame", nil, self.ScrollFrame)
  self.Content:SetPoint("TOPLEFT")
  self.ScrollFrame:SetScrollChild(self.Content)
  self.Scrollbar = CreateFrame("Slider", nil, self.ScrollFrame, "UIPanelScrollBarTemplate")
  self.Scrollbar:SetPoint("TOPRIGHT", self, "TOPRIGHT", -12, -50)
  self.Scrollbar:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -12, 20)
  self.Scrollbar:SetWidth(16)
  self.Scrollbar:SetValueStep(1)
  -- Install this before SetValue: the template's own initialization callback
  -- must not try to scroll the settings canvas instead of our ScrollFrame.
  self.Scrollbar:SetScript("OnValueChanged", function(_, value) self.ScrollFrame:SetVerticalScroll(value) end)
  self.Scrollbar:SetMinMaxValues(0, 0)
  self.Scrollbar:SetValue(0)
  self.ScrollFrame:EnableMouseWheel(true)
  self.ScrollFrame:SetScript("OnMouseWheel", function(_, delta)
    self.Scrollbar:SetValue(math.max(0, math.min(self.ScrollRange, self.Scrollbar:GetValue() - delta * 40)))
  end)
  self.Groups = {}
  for _, definition in ipairs(optionGroups) do
    local group = CreateFrame("Frame", nil, self.Content)
    group.Definition, group.Controls = definition, {}
    group.Heading = group:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    group.Heading:SetPoint("TOPLEFT", 0, 0)
    group.Heading:SetText(definition.Title)
    group.Divider = group:CreateTexture(nil, "ARTWORK")
    group.Divider:SetPoint("TOPLEFT", 0, -22)
    group.Divider:SetPoint("TOPRIGHT", 0, -22)
    group.Divider:SetHeight(1)
    group.Divider:SetColorTexture(0.45, 0.42, 0.36, 0.5)
    for _, option in ipairs(definition.Controls) do
      local check = CreateFrame("CheckButton", nil, group, "UICheckButtonTemplate")
      check:SetSize(28, 28)
      local label = group:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      label:SetText(option.Text)
      label:SetJustifyH("LEFT")
      label:SetWordWrap(true)
      self["cb" .. option.Name], self["fs" .. option.Name] = check, label
      group.Controls[#group.Controls + 1] = { Definition = option, Check = check, Label = label }
    end
    if (definition.DebugButton) then
      self.DebugButton = CreateFrame("Button", nil, group, "UIPanelButtonTemplate")
      self.DebugButton:SetSize(100, 24)
      self.DebugButton:SetText("Debug")
      self.DebugButton:SetNormalFontObject("GameFontNormalSmall")
      self.DebugButton:SetHighlightFontObject("GameFontHighlightSmall")
      self.DebugButton:SetScript("OnClick", function() AutoBiographer_DebugWindow:Toggle() end)
    end
    self.Groups[#self.Groups + 1] = group
  end
  self.cbScreenshotOnBossKill:HookScript("OnClick", function() self:UpdateDependencies() end)
  self:SetScript("OnSizeChanged", function() self:LayoutOptions() end)
  self.ScrollFrame:SetScript("OnSizeChanged", function() self:LayoutOptions() end)
  self:SetScript("OnShow", function() self:LayoutOptions() end)
  self:LayoutOptions()
  self:LoadOptions()
end

function AutoBiographer_OptionWindow:LayoutOptions()
  if (not self.Groups or self.LayingOut) then return end
  self.LayingOut = true
  local width = math.max(200, self.ScrollFrame:GetWidth())
  self.Content:SetWidth(width)
  local top = 0
  for _, group in ipairs(self.Groups) do
    group:ClearAllPoints()
    group:SetPoint("TOPLEFT", 0, -top)
    group:SetWidth(width)
    group.Heading:SetWidth(width)
    local y = 32
    for _, control in ipairs(group.Controls) do
      local visible = not not IsAvailable(control.Definition.Availability)
      control.Check:SetShown(visible)
      control.Label:SetShown(visible)
      if (visible) then
        local indent = control.Definition.Parent and 20 or 0
        control.Label:SetWidth(math.max(1, width - indent - 36))
        local rowHeight = math.max(28, control.Label:GetStringHeight() + 8)
        control.Check:ClearAllPoints()
        control.Check:SetPoint("TOPLEFT", indent, -y - (rowHeight - 28) / 2)
        control.Label:ClearAllPoints()
        control.Label:SetPoint("LEFT", control.Check, "RIGHT", 6, 0)
        y = y + rowHeight
      end
    end
    if (group.Definition.DebugButton) then
      self.DebugButton:ClearAllPoints()
      self.DebugButton:SetPoint("TOPLEFT", 0, -y - 4)
      y = y + 32
    end
    group:SetHeight(y)
    top = top + y + 20
  end
  self.Content:SetHeight(top)
  self.ScrollRange = math.max(0, top - self.ScrollFrame:GetHeight())
  self.Scrollbar:SetMinMaxValues(0, self.ScrollRange)
  self.Scrollbar:SetValue(math.min(self.Scrollbar:GetValue(), self.ScrollRange))
  self.Scrollbar:SetShown(self.ScrollRange > 0)
  self.LayingOut = false
end

function AutoBiographer_OptionWindow:UpdateDependencies()
  local enabled = not not self.cbScreenshotOnBossKill:GetChecked()
  self.cbScreenshotOnlyOnFirstBossKill:SetEnabled(enabled)
  local brightness = enabled and 1 or 0.5
  self.fsScreenshotOnlyOnFirstBossKill:SetTextColor(brightness, brightness, brightness)
end

function AutoBiographer_OptionWindow:LoadOptions()
  self.cbEnableCustomEventSharing:SetChecked(AutoBiographer_Settings.Options["EnableCustomEventSharing"])
  self.cbEnableDebugLogging:SetChecked(AutoBiographer_Settings.Options["EnableDebugLogging"])
  self.cbEnableMilestoneMessages:SetChecked(AutoBiographer_Settings.Options["EnableMilestoneMessages"])
  self.cbShareMilestonesInGuild:SetChecked(AutoBiographer_Settings.Options.ShareMilestonesInGuild)
  self.cbShareMilestonesAsEmotes:SetChecked(AutoBiographer_Settings.Options.ShareMilestonesAsEmotes)
  self.cbRecommendCampfireMessages:SetChecked(AutoBiographer_Settings.Options["RecommendCampfireMessages"])
  self.cbFriendlyPlayerTooltip:SetChecked(AutoBiographer_Settings.Options["ShowFriendlyPlayerToolTips"])
  self.cbKillCountTooltip:SetChecked(AutoBiographer_Settings.Options["ShowKillCountOnUnitToolTips"])
  self.cbDiscoveryTooltip:SetChecked(AutoBiographer_Settings.Options["ShowDiscoveryInfoOnToolTips"])
  self.cbScreenshotOnLevelUp:SetChecked(AutoBiographer_Settings.Options["TakeScreenshotOnLevelUp"])
  self.cbScreenshotOnBossKill:SetChecked(AutoBiographer_Settings.Options["TakeScreenshotOnBossKill"])
  self.cbScreenshotOnlyOnFirstBossKill:SetChecked(AutoBiographer_Settings.Options["TakeScreenshotOnlyOnFirstBossKill"])
  self.cbScreenshotOnAchievementEarned:SetChecked(AutoBiographer_Settings.Options["TakeScreenshotOnAchievementEarned"])
  self.cbShowMinimapButton:SetChecked(AutoBiographer_Settings.Options["ShowMinimapButton"])
  self.cbShowLevelUpStatMessages:SetChecked(AutoBiographer_Settings.Options["ShowLevelUpStatMessages"])
  self.cbShowTimePlayedOnLevelUp:SetChecked(AutoBiographer_Settings.Options["ShowTimePlayedOnLevelUp"])
  self:UpdateDependencies()
end

function AutoBiographer_OptionWindow:SaveOptions()
  local options = AutoBiographer_Settings.Options
  local guild = not not self.cbShareMilestonesInGuild:GetChecked()
  local emote = not not self.cbShareMilestonesAsEmotes:GetChecked()
  if (guild ~= options.ShareMilestonesInGuild or emote ~= options.ShareMilestonesAsEmotes) then
    options.MilestoneSharingPrompted = true
  end
  options.ShareMilestonesInGuild = guild
  options.ShareMilestonesAsEmotes = emote
  AutoBiographer_Settings.Options["EnableCustomEventSharing"] = self.cbEnableCustomEventSharing:GetChecked()
  AutoBiographer_Settings.Options["EnableDebugLogging"] = self.cbEnableDebugLogging:GetChecked()
  AutoBiographer_Settings.Options["EnableMilestoneMessages"] = self.cbEnableMilestoneMessages:GetChecked()
  AutoBiographer_Settings.Options["RecommendCampfireMessages"] = self.cbRecommendCampfireMessages:GetChecked()
  AutoBiographer_Settings.Options["ShowFriendlyPlayerToolTips"] = self.cbFriendlyPlayerTooltip:GetChecked()
  AutoBiographer_Settings.Options["ShowKillCountOnUnitToolTips"] = self.cbKillCountTooltip:GetChecked()
  AutoBiographer_Settings.Options["ShowDiscoveryInfoOnToolTips"] = self.cbDiscoveryTooltip:GetChecked()
  AutoBiographer_Settings.Options["TakeScreenshotOnLevelUp"] = self.cbScreenshotOnLevelUp:GetChecked()
  AutoBiographer_Settings.Options["TakeScreenshotOnBossKill"] = self.cbScreenshotOnBossKill:GetChecked()
  AutoBiographer_Settings.Options["TakeScreenshotOnlyOnFirstBossKill"] = self.cbScreenshotOnlyOnFirstBossKill:GetChecked()
  AutoBiographer_Settings.Options["TakeScreenshotOnAchievementEarned"] = self.cbScreenshotOnAchievementEarned:GetChecked()
  AutoBiographer_Settings.Options["ShowMinimapButton"] = self.cbShowMinimapButton:GetChecked()
  AutoBiographer_Settings.Options["ShowLevelUpStatMessages"] = self.cbShowLevelUpStatMessages:GetChecked()
  AutoBiographer_Settings.Options["ShowTimePlayedOnLevelUp"] = self.cbShowTimePlayedOnLevelUp:GetChecked()
  
  if (AutoBiographer_Settings.Options["ShowMinimapButton"] == false) then AutoBiographer_MinimapButton:Hide()
  else AutoBiographer_MinimapButton:Show() end
  AutoBiographer_Milestones:ResumeSharing()
end

AutoBiographer_OptionWindow.name = "AutoBiographer"
AutoBiographer_OptionWindow.OnCommit = function() AutoBiographer_OptionWindow:SaveOptions() end
AutoBiographer_OptionWindow.OnRefresh = function() AutoBiographer_OptionWindow:LoadOptions() end

local autoBiographerOptionsCategory = Settings.RegisterCanvasLayoutCategory(AutoBiographer_OptionWindow, AutoBiographer_OptionWindow.name)
AutoBiographer_OptionWindow.categoryID = autoBiographerOptionsCategory:GetID()
Settings.RegisterAddOnCategory(autoBiographerOptionsCategory)
