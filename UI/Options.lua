AutoBiographer_OptionWindow = CreateFrame("Frame", "AutoBiographer Options", UIParent)

function AutoBiographer_OptionWindow:Initialize()
  self.Header = self:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  self.Header:SetPoint("TOPLEFT", 10, -10)
  self.Header:SetText("AutoBiographer Options")
  
  local yPos = -35

  self.cbFriendlyPlayerTooltip = CreateFrame("CheckButton", nil, self, "UICheckButtonTemplate") 
  self.cbFriendlyPlayerTooltip:SetPoint("LEFT", self, "TOPLEFT", 10, yPos)
  self.fsFriendlyPlayerTooltip = self:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  self.fsFriendlyPlayerTooltip:SetPoint("LEFT", self, "TOPLEFT", 40, yPos)
  self.fsFriendlyPlayerTooltip:SetText("Show duel and grouped time info on fiendly player tooltips.")
  yPos = yPos - 30

  self.cbKillCountTooltip = CreateFrame("CheckButton", nil, self, "UICheckButtonTemplate") 
  self.cbKillCountTooltip:SetPoint("LEFT", self, "TOPLEFT", 10, yPos)
  self.fsKillCountTooltip = self:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  self.fsKillCountTooltip:SetPoint("LEFT", self, "TOPLEFT", 40, yPos)
  self.fsKillCountTooltip:SetText("Show kill count on enemy tooltips.")
  yPos = yPos - 30

  self.cbDiscoveryTooltip = CreateFrame("CheckButton", nil, self, "UICheckButtonTemplate") 
  self.cbDiscoveryTooltip:SetPoint("LEFT", self, "TOPLEFT", 10, yPos)
  self.fsDiscoveryTooltip = self:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  self.fsDiscoveryTooltip:SetPoint("LEFT", self, "TOPLEFT", 40, yPos)
  self.fsDiscoveryTooltip:SetText("Indicate Season of Discovery specific items and units on tooltips.")
  yPos = yPos - 30
  
  self.cbScreenshotOnLevelUp = CreateFrame("CheckButton", nil, self, "UICheckButtonTemplate") 
  self.cbScreenshotOnLevelUp:SetPoint("LEFT", self, "TOPLEFT", 10, yPos)
  self.fsScreenshotOnLevelUp = self:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  self.fsScreenshotOnLevelUp:SetPoint("LEFT", self, "TOPLEFT", 40, yPos)
  self.fsScreenshotOnLevelUp:SetText("Take a screenshot on level up.")
  yPos = yPos - 30
  
  self.cbScreenshotOnBossKill = CreateFrame("CheckButton", nil, self, "UICheckButtonTemplate") 
  self.cbScreenshotOnBossKill:SetPoint("LEFT", self, "TOPLEFT", 10, yPos)
  self.fsScreenshotOnBossKill = self:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  self.fsScreenshotOnBossKill:SetPoint("LEFT", self, "TOPLEFT", 40, yPos)
  self.fsScreenshotOnBossKill:SetText("Take a screenshot on boss kills.")
  yPos = yPos - 30
  
  self.cbScreenshotOnlyOnFirstBossKill = CreateFrame("CheckButton", nil, self, "UICheckButtonTemplate") 
  self.cbScreenshotOnlyOnFirstBossKill:SetPoint("LEFT", self, "TOPLEFT", 30, yPos)
  self.fsScreenshotOnlyOnFirstBossKill = self:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  self.fsScreenshotOnlyOnFirstBossKill:SetPoint("LEFT", self, "TOPLEFT", 60, yPos)
  self.fsScreenshotOnlyOnFirstBossKill:SetText("Take a screenshot only the first time killing a particular boss.")
  yPos = yPos - 30

  self.cbScreenshotOnAchievementEarned = CreateFrame("CheckButton", nil, self, "UICheckButtonTemplate") 
  self.cbScreenshotOnAchievementEarned:SetPoint("LEFT", self, "TOPLEFT", 10, yPos)
  self.fsScreenshotOnAchievementEarned = self:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  self.fsScreenshotOnAchievementEarned:SetPoint("LEFT", self, "TOPLEFT", 40, yPos)
  self.fsScreenshotOnAchievementEarned:SetText("Take a screenshot on achievements earned.")
  yPos = yPos - 30
  
  self.cbShowMinimapButton = CreateFrame("CheckButton", nil, self, "UICheckButtonTemplate") 
  self.cbShowMinimapButton:SetPoint("LEFT", self, "TOPLEFT", 10, yPos)
  self.fsShowMinimapButton = self:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  self.fsShowMinimapButton:SetPoint("LEFT", self, "TOPLEFT", 40, yPos)
  self.fsShowMinimapButton:SetText("Show button on the minimap.")
  yPos = yPos - 30
  
  self.cbShowTimePlayedOnLevelUp = CreateFrame("CheckButton", nil, self, "UICheckButtonTemplate") 
  self.cbShowTimePlayedOnLevelUp:SetPoint("LEFT", self, "TOPLEFT", 10, yPos)
  self.fsShowTimePlayedOnLevelUp = self:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  self.fsShowTimePlayedOnLevelUp:SetPoint("LEFT", self, "TOPLEFT", 40, yPos)
  self.fsShowTimePlayedOnLevelUp:SetText("Show time played upon leveling up.")
  yPos = yPos - 30

  self.cbShowLevelUpStatMessages = CreateFrame("CheckButton", nil, self, "UICheckButtonTemplate")
  self.cbShowLevelUpStatMessages:SetPoint("LEFT", self, "TOPLEFT", 10, yPos)
  self.fsShowLevelUpStatMessages = self:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  self.fsShowLevelUpStatMessages:SetPoint("LEFT", self, "TOPLEFT", 40, yPos)
  self.fsShowLevelUpStatMessages:SetText("Show health and stat gains upon leveling up in WoW Forever.")
  yPos = yPos - 30
  
  self.cbEnableMilestoneMessages = CreateFrame("CheckButton", nil, self, "UICheckButtonTemplate") 
  self.cbEnableMilestoneMessages:SetPoint("LEFT", self, "TOPLEFT", 10, yPos)
  self.fsEnableMilestoneMessages = self:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  self.fsEnableMilestoneMessages:SetPoint("LEFT", self, "TOPLEFT", 40, yPos)
  self.fsEnableMilestoneMessages:SetText("Show personal milestone messages (minor and major).")
  yPos = yPos - 30

  self.cbShareMilestonesInGuild = CreateFrame("CheckButton", nil, self, "UICheckButtonTemplate")
  self.cbShareMilestonesInGuild:SetPoint("LEFT", self, "TOPLEFT", 10, yPos)
  self.fsShareMilestonesInGuild = self:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  self.fsShareMilestonesInGuild:SetPoint("LEFT", self, "TOPLEFT", 40, yPos)
  self.fsShareMilestonesInGuild:SetText("Automatically share major milestones in guild chat.")
  yPos = yPos - 30

  self.cbShareMilestonesAsEmotes = CreateFrame("CheckButton", nil, self, "UICheckButtonTemplate")
  self.cbShareMilestonesAsEmotes:SetPoint("LEFT", self, "TOPLEFT", 10, yPos)
  self.fsShareMilestonesAsEmotes = self:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  self.fsShareMilestonesAsEmotes:SetPoint("LEFT", self, "TOPLEFT", 40, yPos)
  self.fsShareMilestonesAsEmotes:SetText("Offer major milestones as emotes (click to send).")
  yPos = yPos - 30

  self.cbRecommendCampfireMessages = CreateFrame("CheckButton", nil, self, "UICheckButtonTemplate")
  self.cbRecommendCampfireMessages:SetPoint("LEFT", self, "TOPLEFT", 10, yPos)
  self.fsRecommendCampfireMessages = self:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  self.fsRecommendCampfireMessages:SetPoint("LEFT", self, "TOPLEFT", 40, yPos)
  self.fsRecommendCampfireMessages:SetText("Recommend messages to share at campfires.")
  yPos = yPos - 30

  self.cbEnableCustomEventSharing = CreateFrame("CheckButton", nil, self, "UICheckButtonTemplate") 
  self.cbEnableCustomEventSharing:SetPoint("LEFT", self, "TOPLEFT", 10, yPos)
  self.fsEnableCustomEventSharing = self:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  self.fsEnableCustomEventSharing:SetPoint("LEFT", self, "TOPLEFT", 40, yPos)
  self.fsEnableCustomEventSharing:SetText("Allow guild members to share custom events with you.")
  yPos = yPos - 30

  self.cbEnableDebugLogging = CreateFrame("CheckButton", nil, self, "UICheckButtonTemplate") 
  self.cbEnableDebugLogging:SetPoint("LEFT", self, "TOPLEFT", 10, yPos)
  self.fsEnableDebugLogging = self:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  self.fsEnableDebugLogging:SetPoint("LEFT", self, "TOPLEFT", 40, yPos)
  self.fsEnableDebugLogging:SetText("Enable debug logging (this can negatively affect performance).")
  yPos = yPos - 30
  
  self:LoadOptions()
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
