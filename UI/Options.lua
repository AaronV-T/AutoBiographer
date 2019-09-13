AutoBiographer_OptionWindow = CreateFrame("Frame", "AutoBiographer Options", UIParent)

function AutoBiographer_OptionWindow:Initialize()
  self.Header = self:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  self.Header:SetPoint("TOPLEFT", 10, -10)
  self.Header:SetText("AutoBiographer (Alpha) Options")
  
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
  
  self.cbScreenshotOnlyOnFirstBossKill = CreateFrame("CheckButton", nil, self, "UICheckButtonTemplate") 
  self.cbScreenshotOnlyOnFirstBossKill:SetPoint("LEFT", self, "TOPLEFT", 30, -140)
  self.fsScreenshotOnlyOnFirstBossKill = self:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  self.fsScreenshotOnlyOnFirstBossKill:SetPoint("LEFT", self, "TOPLEFT", 60, -140)
  self.fsScreenshotOnlyOnFirstBossKill:SetText("Take a screenshot only the first time killing a particular boss.")
  
  self.cbShowMinimapButton = CreateFrame("CheckButton", nil, self, "UICheckButtonTemplate") 
  self.cbShowMinimapButton:SetPoint("LEFT", self, "TOPLEFT", 10, -170)
  self.fsShowMinimapButton = self:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  self.fsShowMinimapButton:SetPoint("LEFT", self, "TOPLEFT", 40, -170)
  self.fsShowMinimapButton:SetText("Show button on the minimap.")
  
  self.cbShowTimePlayedOnLevelUp = CreateFrame("CheckButton", nil, self, "UICheckButtonTemplate") 
  self.cbShowTimePlayedOnLevelUp:SetPoint("LEFT", self, "TOPLEFT", 10, -200)
  self.fsShowTimePlayedOnLevelUp = self:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  self.fsShowTimePlayedOnLevelUp:SetPoint("LEFT", self, "TOPLEFT", 40, -200)
  self.fsShowTimePlayedOnLevelUp:SetText("Show time played upon leveling up.")
  
  self:LoadOptions()
end

function AutoBiographer_OptionWindow:LoadOptions()
  self.cbKillCountTooltip:SetChecked(AutoBiographer_Settings.Options["ShowKillCountOnUnitToolTips"])
  self.cbScreenshotOnLevelUp:SetChecked(AutoBiographer_Settings.Options["TakeScreenshotOnLevelUp"])
  self.cbScreenshotOnBossKill:SetChecked(AutoBiographer_Settings.Options["TakeScreenshotOnBossKill"])
  self.cbScreenshotOnlyOnFirstBossKill:SetChecked(AutoBiographer_Settings.Options["TakeScreenshotOnlyOnFirstBossKill"])
  self.cbShowMinimapButton:SetChecked(AutoBiographer_Settings.Options["ShowMinimapButton"])
  self.cbShowTimePlayedOnLevelUp:SetChecked(AutoBiographer_Settings.Options["ShowTimePlayedOnLevelUp"])
end

function AutoBiographer_OptionWindow:SaveOptions()
  AutoBiographer_Settings.Options["ShowKillCountOnUnitToolTips"] = self.cbKillCountTooltip:GetChecked()
  AutoBiographer_Settings.Options["TakeScreenshotOnLevelUp"] = self.cbScreenshotOnLevelUp:GetChecked()
  AutoBiographer_Settings.Options["TakeScreenshotOnBossKill"] = self.cbScreenshotOnBossKill:GetChecked()
  AutoBiographer_Settings.Options["TakeScreenshotOnlyOnFirstBossKill"] = self.cbScreenshotOnlyOnFirstBossKill:GetChecked()
  AutoBiographer_Settings.Options["ShowMinimapButton"] = self.cbShowMinimapButton:GetChecked()
  AutoBiographer_Settings.Options["ShowTimePlayedOnLevelUp"] = self.cbShowTimePlayedOnLevelUp:GetChecked()
  
  if (AutoBiographer_Settings.Options["ShowMinimapButton"] == false) then AutoBiographer_MinimapButton:Hide()
  else AutoBiographer_MinimapButton:Show() end
end

AutoBiographer_OptionWindow.name = "AutoBiographer"
AutoBiographer_OptionWindow.cancel = function() AutoBiographer_OptionWindow:LoadOptions() end
AutoBiographer_OptionWindow.default = function() print("Not implemented.") end
AutoBiographer_OptionWindow.okay = function() AutoBiographer_OptionWindow:SaveOptions() end
InterfaceOptions_AddCategory(AutoBiographer_OptionWindow)
