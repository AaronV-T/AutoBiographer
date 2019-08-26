AutoBiographer_OptionWindow = CreateFrame("Frame", "AutoBiographer Options", UIParent)

function AutoBiographer_OptionWindow:Initialize()
  self.Header = self:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  self.Header:SetPoint("TOPLEFT", 10, -10)
  self.Header:SetText("AutoBiographer Options")
  
  self.cbKillCountTooltip = CreateFrame("CheckButton", nil, self, "UICheckButtonTemplate") 
  self.cbKillCountTooltip:SetPoint("LEFT", self, "TOPLEFT", 10, -50)
  self.fsKillCountTooltip = self:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  self.fsKillCountTooltip:SetPoint("LEFT", self, "TOPLEFT", 40, -50)
  self.fsKillCountTooltip:SetText("Show kill count on unit tooltips.")
  
  self.cbScreenshotOnLevelUp = CreateFrame("CheckButton", nil, self, "UICheckButtonTemplate") 
  self.cbScreenshotOnLevelUp:SetPoint("LEFT", self, "TOPLEFT", 10, -80)
  self.fsScreenshotOnLevelUp = self:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  self.fsScreenshotOnLevelUp:SetPoint("LEFT", self, "TOPLEFT", 40, -80)
  self.fsScreenshotOnLevelUp:SetText("Take a screenshot on level up.")
  
  self.cbScreenshotOnBossKill = CreateFrame("CheckButton", nil, self, "UICheckButtonTemplate") 
  self.cbScreenshotOnBossKill:SetPoint("LEFT", self, "TOPLEFT", 10, -110)
  self.fsScreenshotOnBossKill = self:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  self.fsScreenshotOnBossKill:SetPoint("LEFT", self, "TOPLEFT", 40, -110)
  self.fsScreenshotOnBossKill:SetText("Take a screenshot on boss kills.")
  
  self:LoadOptions()
end

function AutoBiographer_OptionWindow:LoadOptions()
  self.cbKillCountTooltip:SetChecked(AutoBiographer_Settings.Options["ShowKillCountOnUnitToolTips"])
  self.cbScreenshotOnLevelUp:SetChecked(AutoBiographer_Settings.Options["TakeScreenshotOnLevelUp"])
  self.cbScreenshotOnBossKill:SetChecked(AutoBiographer_Settings.Options["TakeScreenshotOnBossKill"])
end

function AutoBiographer_OptionWindow:SaveOptions()
  AutoBiographer_Settings.Options["ShowKillCountOnUnitToolTips"] = self.cbKillCountTooltip:GetChecked()
  AutoBiographer_Settings.Options["TakeScreenshotOnLevelUp"] = self.cbScreenshotOnLevelUp:GetChecked()
  AutoBiographer_Settings.Options["TakeScreenshotOnBossKill"] = self.cbScreenshotOnBossKill:GetChecked()
end

AutoBiographer_OptionWindow.name = "AutoBiographer"
AutoBiographer_OptionWindow.cancel = function() AutoBiographer_OptionWindow:LoadOptions() end
AutoBiographer_OptionWindow.default = function() print("Not implemented.") end
AutoBiographer_OptionWindow.okay = function() AutoBiographer_OptionWindow:SaveOptions() end
InterfaceOptions_AddCategory(AutoBiographer_OptionWindow)
