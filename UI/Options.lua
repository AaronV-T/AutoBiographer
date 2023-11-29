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
  
  self.cbEnableMilestoneMessages = CreateFrame("CheckButton", nil, self, "UICheckButtonTemplate") 
  self.cbEnableMilestoneMessages:SetPoint("LEFT", self, "TOPLEFT", 10, yPos)
  self.fsEnableMilestoneMessages = self:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  self.fsEnableMilestoneMessages:SetPoint("LEFT", self, "TOPLEFT", 40, yPos)
  self.fsEnableMilestoneMessages:SetText("Enable milestone messages.")
  yPos = yPos - 30

  self.cbShowLowRankCombatSkillWarnings = CreateFrame("CheckButton", nil, self, "UICheckButtonTemplate") 
  self.cbShowLowRankCombatSkillWarnings:SetPoint("LEFT", self, "TOPLEFT", 10, yPos)
  self.fsShowLowRankCombatSkillWarnings = self:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  self.fsShowLowRankCombatSkillWarnings:SetPoint("LEFT", self, "TOPLEFT", 40, yPos)
  self.fsShowLowRankCombatSkillWarnings:SetText("Show occasional warnings for low rank combat skills.")
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
  self.cbFriendlyPlayerTooltip:SetChecked(AutoBiographer_Settings.Options["ShowFriendlyPlayerToolTips"])
  self.cbKillCountTooltip:SetChecked(AutoBiographer_Settings.Options["ShowKillCountOnUnitToolTips"])
  self.cbDiscoveryTooltip:SetChecked(AutoBiographer_Settings.Options["ShowDiscoveryInfoOnToolTips"])
  self.cbScreenshotOnLevelUp:SetChecked(AutoBiographer_Settings.Options["TakeScreenshotOnLevelUp"])
  self.cbScreenshotOnBossKill:SetChecked(AutoBiographer_Settings.Options["TakeScreenshotOnBossKill"])
  self.cbScreenshotOnlyOnFirstBossKill:SetChecked(AutoBiographer_Settings.Options["TakeScreenshotOnlyOnFirstBossKill"])
  self.cbScreenshotOnAchievementEarned:SetChecked(AutoBiographer_Settings.Options["TakeScreenshotOnAchievementEarned"])
  self.cbShowLowRankCombatSkillWarnings:SetChecked(AutoBiographer_Settings.Options["ShowLowRankCombatSkillWarnings"])
  self.cbShowMinimapButton:SetChecked(AutoBiographer_Settings.Options["ShowMinimapButton"])
  self.cbShowTimePlayedOnLevelUp:SetChecked(AutoBiographer_Settings.Options["ShowTimePlayedOnLevelUp"])
end

function AutoBiographer_OptionWindow:SaveOptions()
  AutoBiographer_Settings.Options["EnableCustomEventSharing"] = self.cbEnableCustomEventSharing:GetChecked()
  AutoBiographer_Settings.Options["EnableDebugLogging"] = self.cbEnableDebugLogging:GetChecked()
  AutoBiographer_Settings.Options["EnableMilestoneMessages"] = self.cbEnableMilestoneMessages:GetChecked()
  AutoBiographer_Settings.Options["ShowFriendlyPlayerToolTips"] = self.cbFriendlyPlayerTooltip:GetChecked()
  AutoBiographer_Settings.Options["ShowKillCountOnUnitToolTips"] = self.cbKillCountTooltip:GetChecked()
  AutoBiographer_Settings.Options["ShowDiscoveryInfoOnToolTips"] = self.cbDiscoveryTooltip:GetChecked()
  AutoBiographer_Settings.Options["TakeScreenshotOnLevelUp"] = self.cbScreenshotOnLevelUp:GetChecked()
  AutoBiographer_Settings.Options["TakeScreenshotOnBossKill"] = self.cbScreenshotOnBossKill:GetChecked()
  AutoBiographer_Settings.Options["TakeScreenshotOnlyOnFirstBossKill"] = self.cbScreenshotOnlyOnFirstBossKill:GetChecked()
  AutoBiographer_Settings.Options["TakeScreenshotOnAchievementEarned"] = self.cbScreenshotOnAchievementEarned:GetChecked()
  AutoBiographer_Settings.Options["ShowLowRankCombatSkillWarnings"] = self.cbShowLowRankCombatSkillWarnings:GetChecked()
  AutoBiographer_Settings.Options["ShowMinimapButton"] = self.cbShowMinimapButton:GetChecked()
  AutoBiographer_Settings.Options["ShowTimePlayedOnLevelUp"] = self.cbShowTimePlayedOnLevelUp:GetChecked()
  
  if (AutoBiographer_Settings.Options["ShowMinimapButton"] == false) then AutoBiographer_MinimapButton:Hide()
  else AutoBiographer_MinimapButton:Show() end
end

AutoBiographer_OptionWindow.name = "AutoBiographer"
AutoBiographer_OptionWindow.cancel = function() AutoBiographer_OptionWindow:LoadOptions() end
AutoBiographer_OptionWindow.default = function() print("[AutoBiographer] Not implemented.") end
AutoBiographer_OptionWindow.okay = function() AutoBiographer_OptionWindow:SaveOptions() end
InterfaceOptions_AddCategory(AutoBiographer_OptionWindow)
