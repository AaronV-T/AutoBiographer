local Hbd = LibStub("HereBeDragons-2.0")
local HbdPins = LibStub("HereBeDragons-Pins-2.0")

AutoBiographer_EventMapIconPool = {
  Allocated = {},
  UnAllocated = {},
}

AutoBiographer_WorldMapOverlayWindow = nil
AutoBiographer_WorldMapOverlayWindowToggleButton = CreateFrame("Button", "AutoBiographer_WorldMapOverlayWindowToggleButton", WorldMapFrame, "UIPanelButtonTemplate")

function AutoBiographer_WorldMapOverlayWindow_Initialize()
  AutoBiographer_WorldMapOverlayWindow = CreateFrame("Frame", "AutoBiographer_WorldMapOverlayWindow", WorldMapFrame.ScrollContainer, "BasicFrameTemplate")
  local frame = AutoBiographer_WorldMapOverlayWindow
  frame:SetSize(400, 125)
  frame:SetPoint("BOTTOMRIGHT", WorldMapFrame.ScrollContainer, "BOTTOMRIGHT")
  frame:SetFrameStrata("TOOLTIP")

  frame:EnableKeyboard(true)
  frame:EnableMouse(true)
  frame:SetMovable(true)

  frame:SetScript("OnHide", function(self)
    if (self.isMoving) then
      self:StopMovingOrSizing()
      self.isMoving = false
    end
  end)
  frame:SetScript("OnMouseDown", function(self, button)
    if (button == "LeftButton" and not self.isMoving) then
     self:StartMoving()
     self.isMoving = true
    end
  end)

  frame:SetScript("OnMouseUp", function(self, button)
    if (button == "LeftButton" and self.isMoving) then
     self:StopMovingOrSizing()
     self.isMoving = false
    end
  end)

  frame:SetScript("OnHide", function(self)
    AutoBiographer_WorldMapOverlayWindow_HideEvents()
  end)    

  frame.Title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
  frame.Title:SetPoint("LEFT", frame.TitleBg, "LEFT", 5, 0);
  frame.Title:SetText("AutoBiographer Map Events")

  frame.Toggle = function(self)
    if (self:IsVisible()) then
      self:Hide()
    else
      self:Show()
    end
  end

  -- Filter Check Boxes
  local leftPoint = 10
  frame.BossKillIcon = CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
  frame.BossKillIcon:SetSize(20, 20)
  frame.BossKillIcon:SetPoint("TOPLEFT", frame, "TOPLEFT", leftPoint, -25)
  frame.BossKillIcon:SetBackdrop({bgFile = Event.GetIconPath(BossKillEvent.New())})
  frame.BossKillIcon:SetScript("OnEnter", function(self, button)
    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    GameTooltip:ClearAllPoints();
    GameTooltip:SetPoint("TOPRIGHT", frame.BossKillIcon, "BOTTOMRIGHT", 0, 0)
    GameTooltip:SetText("Boss Kill")
    GameTooltip:Show()
  end)
  frame.BossKillIcon:SetScript("OnLeave", function(self, button)
    GameTooltip:Hide()
  end)
  frame.BossKillCb = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate") 
  frame.BossKillCb:SetPoint("TOPLEFT", frame, "TOPLEFT", leftPoint - 5, -40)
  frame.BossKillCb:SetChecked(AutoBiographer_Settings.MapEventDisplayFilters[AutoBiographerEnum.EventSubType.BossKill])
  frame.BossKillCb:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.MapEventDisplayFilters[AutoBiographerEnum.EventSubType.BossKill] = self:GetChecked()
  end)
  
  leftPoint = leftPoint + 25
  frame.CustomIcon = CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
  frame.CustomIcon:SetSize(20, 20)
  frame.CustomIcon:SetPoint("TOPLEFT", frame, "TOPLEFT", leftPoint, -25)
  frame.CustomIcon:SetBackdrop({bgFile = Event.GetIconPath(CustomEvent.New())})
  frame.CustomIcon:SetScript("OnEnter", function(self, button)
    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    GameTooltip:ClearAllPoints();
    GameTooltip:SetPoint("TOPRIGHT", frame.CustomIcon, "BOTTOMRIGHT", 0, 0)
    GameTooltip:SetText("Custom")
    GameTooltip:Show()
  end)
  frame.CustomIcon:SetScript("OnLeave", function(self, button)
    GameTooltip:Hide()
  end)
  frame.CustomCb = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate") 
  frame.CustomCb:SetPoint("TOPLEFT", frame, "TOPLEFT", leftPoint - 5, -40)
  frame.CustomCb:SetChecked(AutoBiographer_Settings.MapEventDisplayFilters[AutoBiographerEnum.EventSubType.Custom])
  frame.CustomCb:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.MapEventDisplayFilters[AutoBiographerEnum.EventSubType.Custom] = self:GetChecked()
  end)

  leftPoint = leftPoint + 25
  frame.FirstAcquiredItemIcon = CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
  frame.FirstAcquiredItemIcon:SetSize(20, 20)
  frame.FirstAcquiredItemIcon:SetPoint("TOPLEFT", frame, "TOPLEFT", leftPoint, -25)
  frame.FirstAcquiredItemIcon:SetBackdrop({bgFile = Event.GetIconPath(FirstAcquiredItemEvent.New())})
  frame.FirstAcquiredItemIcon:SetScript("OnEnter", function(self, button)
    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    GameTooltip:ClearAllPoints();
    GameTooltip:SetPoint("TOPRIGHT", frame.FirstAcquiredItemIcon, "BOTTOMRIGHT", 0, 0)
    GameTooltip:SetText("First Acquired Item")
    GameTooltip:Show()
  end)
  frame.FirstAcquiredItemIcon:SetScript("OnLeave", function(self, button)
    GameTooltip:Hide()
  end)
  frame.FirstAcquiredItemCb = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate") 
  frame.FirstAcquiredItemCb:SetPoint("TOPLEFT", frame, "TOPLEFT", leftPoint - 5, -40)
  frame.FirstAcquiredItemCb:SetChecked(AutoBiographer_Settings.MapEventDisplayFilters[AutoBiographerEnum.EventSubType.FirstAcquiredItem])
  frame.FirstAcquiredItemCb:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.MapEventDisplayFilters[AutoBiographerEnum.EventSubType.FirstAcquiredItem] = self:GetChecked()
  end)
  
  leftPoint = leftPoint + 25
  frame.FirstKillIcon = CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
  frame.FirstKillIcon:SetSize(20, 20)
  frame.FirstKillIcon:SetPoint("TOPLEFT", frame, "TOPLEFT", leftPoint, -25)
  frame.FirstKillIcon:SetBackdrop({bgFile = Event.GetIconPath(FirstKillEvent.New())})
  frame.FirstKillIcon:SetScript("OnEnter", function(self, button)
    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    GameTooltip:ClearAllPoints();
    GameTooltip:SetPoint("TOPRIGHT", frame.FirstKillIcon, "BOTTOMRIGHT", 0, 0)
    GameTooltip:SetText("First Kill")
    GameTooltip:Show()
  end)
  frame.FirstKillIcon:SetScript("OnLeave", function(self, button)
    GameTooltip:Hide()
  end)
  frame.FirstKillCb = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate") 
  frame.FirstKillCb:SetPoint("TOPLEFT", frame, "TOPLEFT", leftPoint - 5, -40)
  frame.FirstKillCb:SetChecked(AutoBiographer_Settings.MapEventDisplayFilters[AutoBiographerEnum.EventSubType.FirstKill])
  frame.FirstKillCb:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.MapEventDisplayFilters[AutoBiographerEnum.EventSubType.FirstKill] = self:GetChecked()
  end)
  
  leftPoint = leftPoint + 25
  frame.LevelUpIcon = CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
  frame.LevelUpIcon:SetSize(20, 20)
  frame.LevelUpIcon:SetPoint("TOPLEFT", frame, "TOPLEFT", leftPoint, -25)
  frame.LevelUpIcon:SetBackdrop({bgFile = Event.GetIconPath(LevelUpEvent.New())})
  frame.LevelUpIcon:SetScript("OnEnter", function(self, button)
    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    GameTooltip:ClearAllPoints();
    GameTooltip:SetPoint("TOPRIGHT", frame.LevelUpIcon, "BOTTOMRIGHT", 0, 0)
    GameTooltip:SetText("Level Up")
    GameTooltip:Show()
  end)
  frame.LevelUpIcon:SetScript("OnLeave", function(self, button)
    GameTooltip:Hide()
  end)
  frame.LevelUpCb = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate") 
  frame.LevelUpCb:SetPoint("TOPLEFT", frame, "TOPLEFT", leftPoint - 5, -40)
  frame.LevelUpCb:SetChecked(AutoBiographer_Settings.MapEventDisplayFilters[AutoBiographerEnum.EventSubType.LevelUp])
  frame.LevelUpCb:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.MapEventDisplayFilters[AutoBiographerEnum.EventSubType.LevelUp] = self:GetChecked()
  end)
  
  leftPoint = leftPoint + 25
  frame.PlayerDeathIcon = CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
  frame.PlayerDeathIcon:SetSize(20, 20)
  frame.PlayerDeathIcon:SetPoint("TOPLEFT", frame, "TOPLEFT", leftPoint, -25)
  frame.PlayerDeathIcon:SetBackdrop({bgFile = Event.GetIconPath(PlayerDeathEvent.New())})
  frame.PlayerDeathIcon:SetScript("OnEnter", function(self, button)
    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    GameTooltip:ClearAllPoints();
    GameTooltip:SetPoint("TOPRIGHT", frame.PlayerDeathIcon, "BOTTOMRIGHT", 0, 0)
    GameTooltip:SetText("Player Death")
    GameTooltip:Show()
  end)
  frame.PlayerDeathIcon:SetScript("OnLeave", function(self, button)
    GameTooltip:Hide()
  end)
  frame.PlayerDeathCb = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate") 
  frame.PlayerDeathCb:SetPoint("TOPLEFT", frame, "TOPLEFT", leftPoint - 5, -40)
  frame.PlayerDeathCb:SetChecked(AutoBiographer_Settings.MapEventDisplayFilters[AutoBiographerEnum.EventSubType.PlayerDeath])
  frame.PlayerDeathCb:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.MapEventDisplayFilters[AutoBiographerEnum.EventSubType.PlayerDeath] = self:GetChecked()
  end)
  
  leftPoint = leftPoint + 25
  frame.QuestTurnInIcon = CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
  frame.QuestTurnInIcon:SetSize(20, 20)
  frame.QuestTurnInIcon:SetPoint("TOPLEFT", frame, "TOPLEFT", leftPoint, -25)
  frame.QuestTurnInIcon:SetBackdrop({bgFile = Event.GetIconPath(QuestTurnInEvent.New())})
  frame.QuestTurnInIcon:SetScript("OnEnter", function(self, button)
    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    GameTooltip:ClearAllPoints();
    GameTooltip:SetPoint("TOPRIGHT", frame.QuestTurnInIcon, "BOTTOMRIGHT", 0, 0)
    GameTooltip:SetText("Quest Turn In")
    GameTooltip:Show()
  end)
  frame.QuestTurnInIcon:SetScript("OnLeave", function(self, button)
    GameTooltip:Hide()
  end)
  frame.QuestTurnInCb = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate") 
  frame.QuestTurnInCb:SetPoint("TOPLEFT", frame, "TOPLEFT", leftPoint - 5, -40)
  frame.QuestTurnInCb:SetChecked(AutoBiographer_Settings.MapEventDisplayFilters[AutoBiographerEnum.EventSubType.QuestTurnIn])
  frame.QuestTurnInCb:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.MapEventDisplayFilters[AutoBiographerEnum.EventSubType.QuestTurnIn] = self:GetChecked()
  end)
  
  leftPoint = leftPoint + 25
  frame.ReputationLevelChangedIcon = CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
  frame.ReputationLevelChangedIcon:SetSize(20, 20)
  frame.ReputationLevelChangedIcon:SetPoint("TOPLEFT", frame, "TOPLEFT", leftPoint, -25)
  frame.ReputationLevelChangedIcon:SetBackdrop({bgFile = Event.GetIconPath(ReputationLevelChangedEvent.New())})
  frame.ReputationLevelChangedIcon:SetScript("OnEnter", function(self, button)
    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    GameTooltip:ClearAllPoints();
    GameTooltip:SetPoint("TOPRIGHT", frame.ReputationLevelChangedIcon, "BOTTOMRIGHT", 0, 0)
    GameTooltip:SetText("Reputation Level Changed")
    GameTooltip:Show()
  end)
  frame.ReputationLevelChangedIcon:SetScript("OnLeave", function(self, button)
    GameTooltip:Hide()
  end)
  frame.ReputationLevelChangedCb = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate") 
  frame.ReputationLevelChangedCb:SetPoint("TOPLEFT", frame, "TOPLEFT", leftPoint - 5, -40)
  frame.ReputationLevelChangedCb:SetChecked(AutoBiographer_Settings.MapEventDisplayFilters[AutoBiographerEnum.EventSubType.ReputationLevelChanged])
  frame.ReputationLevelChangedCb:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.MapEventDisplayFilters[AutoBiographerEnum.EventSubType.ReputationLevelChanged] = self:GetChecked()
  end)
  
  leftPoint = leftPoint + 25
  frame.SkillMilestoneIcon = CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
  frame.SkillMilestoneIcon:SetSize(20, 20)
  frame.SkillMilestoneIcon:SetPoint("TOPLEFT", frame, "TOPLEFT", leftPoint, -25)
  frame.SkillMilestoneIcon:SetBackdrop({bgFile = Event.GetIconPath(SkillMilestoneEvent.New())})
  frame.SkillMilestoneIcon:SetScript("OnEnter", function(self, button)
    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    GameTooltip:ClearAllPoints();
    GameTooltip:SetPoint("TOPRIGHT", frame.SkillMilestoneIcon, "BOTTOMRIGHT", 0, 0)
    GameTooltip:SetText("Skill Milestone")
    GameTooltip:Show()
  end)
  frame.SkillMilestoneIcon:SetScript("OnLeave", function(self, button)
    GameTooltip:Hide()
  end)
  frame.SkillMilestoneCb = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate") 
  frame.SkillMilestoneCb:SetPoint("TOPLEFT", frame, "TOPLEFT", leftPoint - 5, -40)
  frame.SkillMilestoneCb:SetChecked(AutoBiographer_Settings.MapEventDisplayFilters[AutoBiographerEnum.EventSubType.SkillMilestone])
  frame.SkillMilestoneCb:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.MapEventDisplayFilters[AutoBiographerEnum.EventSubType.SkillMilestone] = self:GetChecked()
  end)
  
  leftPoint = leftPoint + 25
  frame.SpellLearnedIcon = CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
  frame.SpellLearnedIcon:SetSize(20, 20)
  frame.SpellLearnedIcon:SetPoint("TOPLEFT", frame, "TOPLEFT", leftPoint, -25)
  frame.SpellLearnedIcon:SetBackdrop({bgFile = Event.GetIconPath(SpellLearnedEvent.New())})
  frame.SpellLearnedIcon:SetScript("OnEnter", function(self, button)
    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    GameTooltip:ClearAllPoints();
    GameTooltip:SetPoint("TOPRIGHT", frame.SpellLearnedIcon, "BOTTOMRIGHT", 0, 0)
    GameTooltip:SetText("Spell Learned")
    GameTooltip:Show()
  end)
  frame.SpellLearnedIcon:SetScript("OnLeave", function(self, button)
    GameTooltip:Hide()
  end)
  frame.SpellLearnedCb = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate") 
  frame.SpellLearnedCb:SetPoint("TOPLEFT", frame, "TOPLEFT", leftPoint - 5, -40)
  frame.SpellLearnedCb:SetChecked(AutoBiographer_Settings.MapEventDisplayFilters[AutoBiographerEnum.EventSubType.SpellLearned])
  frame.SpellLearnedCb:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.MapEventDisplayFilters[AutoBiographerEnum.EventSubType.SpellLearned] = self:GetChecked()
  end)
  
  leftPoint = leftPoint + 25
  frame.ZoneFirstVisitIcon = CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
  frame.ZoneFirstVisitIcon:SetSize(20, 20)
  frame.ZoneFirstVisitIcon:SetPoint("TOPLEFT", frame, "TOPLEFT", leftPoint, -25)
  frame.ZoneFirstVisitIcon:SetBackdrop({bgFile = Event.GetIconPath(ZoneFirstVisitEvent.New())})
  frame.ZoneFirstVisitIcon:SetScript("OnEnter", function(self, button)
    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    GameTooltip:ClearAllPoints();
    GameTooltip:SetPoint("TOPRIGHT", frame.ZoneFirstVisitIcon, "BOTTOMRIGHT", 0, 0)
    GameTooltip:SetText("Zone or Subzone First Visited")
    GameTooltip:Show()
  end)
  frame.ZoneFirstVisitIcon:SetScript("OnLeave", function(self, button)
    GameTooltip:Hide()
  end)
  frame.ZoneFirstVisitCb = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate") 
  frame.ZoneFirstVisitCb:SetPoint("TOPLEFT", frame, "TOPLEFT", leftPoint - 5, -40)
  frame.ZoneFirstVisitCb:SetChecked(AutoBiographer_Settings.MapEventDisplayFilters[AutoBiographerEnum.EventSubType.SubZoneFirstVisit])
  frame.ZoneFirstVisitCb:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.MapEventDisplayFilters[AutoBiographerEnum.EventSubType.SubZoneFirstVisit] = self:GetChecked()
    AutoBiographer_Settings.MapEventDisplayFilters[AutoBiographerEnum.EventSubType.ZoneFirstVisit] = self:GetChecked()
  end)

  --
  frame.ShowAnimationCb = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
  frame.ShowAnimationCb:SetPoint("BOTTOMLEFT", 5, 2)
  frame.ShowAnimationCb:SetChecked(AutoBiographer_Settings.MapEventShowAnimation)
  frame.ShowAnimationCb:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.MapEventShowAnimation = self:GetChecked()
    if (AutoBiographer_Settings.MapEventShowAnimation) then
      frame.ShowCircleCb:SetChecked(false)
      AutoBiographer_Settings.MapEventShowCircle = false
    end
  end)

  frame.ShowAnimationFs = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  frame.ShowAnimationFs:SetPoint("LEFT", frame.ShowAnimationCb, "RIGHT", 2, 0)
  frame.ShowAnimationFs:SetText("Animation")

	frame.ShowCircleCb = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
  frame.ShowCircleCb:SetPoint("BOTTOM", frame.ShowAnimationCb, "TOP", 0, -10)
  frame.ShowCircleCb:SetChecked(AutoBiographer_Settings.MapEventShowCircle)
  frame.ShowCircleCb:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.MapEventShowCircle = self:GetChecked()
    if (AutoBiographer_Settings.MapEventShowCircle) then
      frame.ShowAnimationCb:SetChecked(false)
      AutoBiographer_Settings.MapEventShowAnimation = false
    end
  end)

  frame.ShowCircleFs = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  frame.ShowCircleFs:SetPoint("LEFT", frame.ShowCircleCb, "RIGHT", 2, 0)
  frame.ShowCircleFs:SetText("Circle")

	frame.FollowExpansionsCb = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
  frame.FollowExpansionsCb:SetPoint("LEFT", frame.ShowCircleCb, 90, 0)
  frame.FollowExpansionsCb:SetChecked(AutoBiographer_Settings.MapEventFollowExpansions)
  frame.FollowExpansionsCb:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.MapEventFollowExpansions = self:GetChecked()
  end)

  frame.FollowExpansionsFs = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  frame.FollowExpansionsFs:SetPoint("LEFT", frame.FollowExpansionsCb, "RIGHT", 2, 0)
  frame.FollowExpansionsFs:SetText("Follow")

  frame.EventsPerSecondEb = CreateFrame("EditBox", nil, frame, BackdropTemplateMixin and "BackdropTemplate");
  frame.EventsPerSecondEb:SetSize(30, 20)
  frame.EventsPerSecondEb:SetPoint("LEFT", frame.ShowAnimationCb, 160, 0)
  frame.EventsPerSecondEb:SetFontObject(GameTooltipTextSmall)
  frame.EventsPerSecondEb:SetBackdrop({
    bgFile = "",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = "true",
    tileSize = 32,
    edgeSize = 10,
    insets = {left = 3, right = 3, top = 3, bottom = 3}
  })
  frame.EventsPerSecondEb:SetAutoFocus(false)
  frame.EventsPerSecondEb:SetMultiLine(false)
  frame.EventsPerSecondEb:SetNumeric(true)
  frame.EventsPerSecondEb:SetScript("OnEscapePressed", function() frame.EventsPerSecondEb:ClearFocus() end)

  frame.EventsPerSecondFs = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  frame.EventsPerSecondFs:SetPoint("LEFT", frame.EventsPerSecondEb, "RIGHT", 2, 0)
  frame.EventsPerSecondFs:SetText("Events/Sec")

  frame.StartingLevelEb = CreateFrame("EditBox", nil, frame, BackdropTemplateMixin and "BackdropTemplate");
  frame.StartingLevelEb:SetSize(30, 20)
  frame.StartingLevelEb:SetPoint("BOTTOM", frame.EventsPerSecondEb, "TOP", 0, 1)
  frame.StartingLevelEb:SetFontObject(GameTooltipTextSmall)
  frame.StartingLevelEb:SetBackdrop({
    bgFile = "",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = "true",
    tileSize = 32,
    edgeSize = 10,
    insets = {left = 3, right = 3, top = 3, bottom = 3}
  })
  frame.StartingLevelEb:SetAutoFocus(false)
  frame.StartingLevelEb:SetMultiLine(false)
  frame.StartingLevelEb:SetNumeric(true)
  frame.StartingLevelEb:SetScript("OnEscapePressed", function() frame.StartingLevelEb:ClearFocus() end)

  frame.StartingLevelFs = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  frame.StartingLevelFs:SetPoint("LEFT", frame.StartingLevelEb, "RIGHT", 2, 0)
  frame.StartingLevelFs:SetText("Start Level")

  frame.LevelFs = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.LevelFs:SetPoint("TOPRIGHT", -5, -40)
  frame.LevelFs:SetText("Level: N/A")

  frame.ProgressFs = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ProgressFs:SetPoint("TOPRIGHT", frame.LevelFs, "BOTTOMRIGHT", 0, 0)
  frame.ProgressFs:SetText("Progress: N/A")

  frame.EventsBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate");
  frame.EventsBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -5, 5);
  frame.EventsBtn:SetSize(140, 40);
  frame.EventsBtn:SetText("Show Events");
  frame.EventsBtn:SetNormalFontObject("GameFontNormalLarge");
  frame.EventsBtn:SetHighlightFontObject("GameFontHighlightLarge");
  frame.EventsBtn:SetScript("OnClick", 
    function(self)
      frame.EventsPerSecondEb:ClearFocus()

      if (AutoBiographer_WorldMapOverlayWindow.EventsAreShown) then
        AutoBiographer_WorldMapOverlayWindow_HideEvents()
      else
        AutoBiographer_WorldMapOverlayWindow_ShowEvents()
      end
    end
  )
  
  frame:Hide()
end

function AutoBiographer_WorldMapOverlayWindow_HideEvents()
  if (not AutoBiographer_WorldMapOverlayWindow.EventsAreShown) then
    return
  end

  AutoBiographer_WorldMapOverlayWindow.EventsAreShown = false
  AutoBiographer_WorldMapOverlayWindow.EventsBtn:SetText("Show Events")
  AutoBiographer_WorldMapOverlayWindow.LevelFs:SetText("Level: N/A")
  AutoBiographer_WorldMapOverlayWindow.ProgressFs:SetText("Progress: N/A")
  AutoBiographer_WorldMapOverlayWindow_SetOptionsEnabled(true)

  HbdPins:RemoveAllWorldMapIcons(AutoBiographer_WorldMapOverlayWindow)
  AutoBiographer_WorldMapOverlayWindow_UpdateCurrentEventIndicator(nil)

  -- Release allocated icons.
  for i = 1, #AutoBiographer_EventMapIconPool.Allocated, 1 do
    local icon = AutoBiographer_EventMapIconPool.Allocated[i]
    icon:SetScript("OnEnter", nil)
    icon:SetScript("OnLeave", nil)
    icon.IsShownOnMap = false

    table.insert(AutoBiographer_EventMapIconPool.UnAllocated, icon)
  end
  AutoBiographer_EventMapIconPool.Allocated = {}

  AutoBiographer_WorldMapOverlayWindow.EventIndexToIconMap = {}
end

function AutoBiographer_WorldMapOverlayWindow_ShowEvents()
  if (AutoBiographer_WorldMapOverlayWindow.EventsAreShown) then
    return
  end

  AutoBiographer_WorldMapOverlayWindow.EventsAreShown = true
  AutoBiographer_WorldMapOverlayWindow.EventsBtn:SetText("Hide Events")
  AutoBiographer_WorldMapOverlayWindow.LevelFs:SetText("Level: ?")
  AutoBiographer_WorldMapOverlayWindow_SetOptionsEnabled(false)

  local maxEventsPerSecond = 300
  if (AutoBiographer_Settings.MapEventShowAnimation) then
    maxEventsPerSecond = 25
  end

  local eventsPerSecond = AutoBiographer_WorldMapOverlayWindow.EventsPerSecondEb:GetNumber()
  if (eventsPerSecond < 1) then
    eventsPerSecond = 25
  elseif (eventsPerSecond > maxEventsPerSecond) then
    eventsPerSecond = maxEventsPerSecond
  end

  AutoBiographer_WorldMapOverlayWindow.EventsPerSecondEb:SetNumber(eventsPerSecond)
  
  local delayBetweenEvents = 1 / eventsPerSecond

  local eventsToShowPerDelay = 1
  while (delayBetweenEvents * eventsToShowPerDelay < 0.02) do
    eventsToShowPerDelay = eventsToShowPerDelay + 1
  end

  local startingLevel = AutoBiographer_WorldMapOverlayWindow.StartingLevelEb:GetNumber()
  if (startingLevel < 1) then
    startingLevel = 1
  end

  local startingIndex = -1
  for i = 1, #AutoBiographer_Controller.CharacterData.Events do
    local event = AutoBiographer_Controller.CharacterData.Events[i]
    if (event.SubType == AutoBiographerEnum.EventSubType.LevelUp) then
      if (event.LevelNum == startingLevel) then
        startingIndex = i
        break
      elseif (event.LevelNum > startingLevel)  then
        startingLevel = event.LevelNum - 1
        startingIndex = 1
        break
      end
    end
  end

  if (startingIndex < 1) then
    startingLevel = 1
    startingIndex = 1
  end

  AutoBiographer_WorldMapOverlayWindow.StartingLevelEb:SetNumber(startingLevel)

  AutoBiographer_WorldMapOverlayWindow.EventIndexToIconMap = {}
  AutoBiographer_WorldMapOverlayWindow.EventsShown = 0
  AutoBiographer_WorldMapOverlayWindow.LastDelayedEventShownTime = nil
  AutoBiographer_WorldMapOverlayWindow.MinimumEventsPerSecondShown = nil
  AutoBiographer_WorldMapOverlayWindow.ShowEventsStartTime = GetTime()
  AutoBiographer_WorldMapOverlayWindow_ShowEvent(startingIndex, startingIndex, delayBetweenEvents * eventsToShowPerDelay, eventsToShowPerDelay, {}, nil, startingLevel)
end

function AutoBiographer_WorldMapOverlayWindow_ShowEvent(eventIndex, firstIndex, delay, eventsToShowPerDelay, eventsShownPerMapId, currentEventsExpansion, currentEventsLevel, isBatchedCall)
  if (not AutoBiographer_WorldMapOverlayWindow.EventsAreShown or eventIndex > #AutoBiographer_Controller.CharacterData.Events) then
    if (AutoBiographer_Settings.Options["EnableDebugLogging"]) then
      local averageEventsPerSecondShown = HelperFunctions.Round(AutoBiographer_WorldMapOverlayWindow.EventsShown / (GetTime() - AutoBiographer_WorldMapOverlayWindow.ShowEventsStartTime), 2)
      print("[AutoBiographer] Events/Second -- Avg: " .. averageEventsPerSecondShown .. ". Min: " .. tostring(AutoBiographer_WorldMapOverlayWindow.MinimumEventsPerSecondShown))
    end

    AutoBiographer_WorldMapOverlayWindow_UpdateCurrentEventIndicator(nil)
    return
  end

  local event = AutoBiographer_Controller.CharacterData.Events[eventIndex]

  local progress = ((eventIndex - firstIndex + 1) / (#AutoBiographer_Controller.CharacterData.Events - firstIndex + 1))* 100
  local extraSpaces = ""
  if (progress < 10) then extraSpaces = "  " end
  AutoBiographer_WorldMapOverlayWindow.ProgressFs:SetText("Progress: " .. extraSpaces .. string.format("%.1f%%", progress))

  if (event.SubType == AutoBiographerEnum.EventSubType.LevelUp) then
    extraSpaces = ""
    if (event.LevelNum < 10) then extraSpaces = "  " end
		currentEventsLevel = event.LevelNum
    AutoBiographer_WorldMapOverlayWindow.LevelFs:SetText("Level: " .. extraSpaces .. event.LevelNum)
  end

  local mapCoordinates = Event.GetMapCoordinates(event)
  if (not mapCoordinates or not AutoBiographer_Settings.MapEventDisplayFilters[event.SubType]) then
    AutoBiographer_WorldMapOverlayWindow_ShowEvent(eventIndex + 1, firstIndex, delay, eventsToShowPerDelay, eventsShownPerMapId, currentEventsExpansion, currentEventsLevel, false)
    return
  end

  AutoBiographer_WorldMapOverlayWindow.EventsShown = AutoBiographer_WorldMapOverlayWindow.EventsShown + 1

  if (not isBatchedCall) then
    local thisEventShownTime = GetTime()
    if (AutoBiographer_WorldMapOverlayWindow.LastDelayedEventShownTime) then
      local deltaTime = thisEventShownTime - AutoBiographer_WorldMapOverlayWindow.LastDelayedEventShownTime
      local currentEventsPerSecond = HelperFunctions.Round((1 / deltaTime) * eventsToShowPerDelay, 2);
      --AutoBiographer_WorldMapOverlayWindow.ProgressFs:SetText("EPS: " .. currentEventsPerSecond .. "")
      if (not AutoBiographer_WorldMapOverlayWindow.MinimumEventsPerSecondShown or currentEventsPerSecond < AutoBiographer_WorldMapOverlayWindow.MinimumEventsPerSecondShown) then
        AutoBiographer_WorldMapOverlayWindow.MinimumEventsPerSecondShown = currentEventsPerSecond
      end
    end
    AutoBiographer_WorldMapOverlayWindow.LastDelayedEventShownTime = thisEventShownTime
  end

  if (AutoBiographer_Settings.MapEventFollowExpansions) then
		if (currentEventsLevel ~= nil) then
			if ((currentEventsExpansion == nil or currentEventsExpansion < 1) and currentEventsLevel <= 60 and (mapCoordinates.InstanceId == 0 or mapCoordinates.InstanceId == 1)) then
				currentEventsExpansion = 1
				if (WorldMapFrame:GetMapID() ~= 947) then
					WorldMapFrame:SetMapID(947)
				end
			elseif ((currentEventsExpansion == nil or currentEventsExpansion < 2) and currentEventsLevel >= 58 and mapCoordinates.InstanceId == 530) then
				currentEventsExpansion = 2
				if (WorldMapFrame:GetMapID() ~= 1945) then
					WorldMapFrame:SetMapID(1945)
				end
				-- TODO: Don't delete existing icons.
				for j = eventIndex - 1, firstIndex, -1 do
					local otherEvent = AutoBiographer_Controller.CharacterData.Events[j]
					local otherMapCoordinates = Event.GetMapCoordinates(otherEvent)
					if (otherMapCoordinates and AutoBiographer_WorldMapOverlayWindow.EventIndexToIconMap[j] and
							AutoBiographer_WorldMapOverlayWindow.EventIndexToIconMap[j].IsShownOnMap and otherMapCoordinates.InstanceId ~= 530) then
						HbdPins:RemoveWorldMapIcon(AutoBiographer_WorldMapOverlayWindow, AutoBiographer_WorldMapOverlayWindow.EventIndexToIconMap[j])
						AutoBiographer_WorldMapOverlayWindow.EventIndexToIconMap[j].IsShownOnMap = false
					end
				end
      elseif ((currentEventsExpansion == nil or currentEventsExpansion < 3) and currentEventsLevel >= 68 and mapCoordinates.InstanceId == 571) then
				currentEventsExpansion = 3
        -- TODO: Set map to all Azeroth and only delete outlands icons.
				if (WorldMapFrame:GetMapID() ~= 113) then
					WorldMapFrame:SetMapID(113)
				end
				
				for j = eventIndex - 1, firstIndex, -1 do
					local otherEvent = AutoBiographer_Controller.CharacterData.Events[j]
					local otherMapCoordinates = Event.GetMapCoordinates(otherEvent)
					if (otherMapCoordinates and AutoBiographer_WorldMapOverlayWindow.EventIndexToIconMap[j] and
							AutoBiographer_WorldMapOverlayWindow.EventIndexToIconMap[j].IsShownOnMap and otherMapCoordinates.InstanceId ~= 571) then
						HbdPins:RemoveWorldMapIcon(AutoBiographer_WorldMapOverlayWindow, AutoBiographer_WorldMapOverlayWindow.EventIndexToIconMap[j])
						AutoBiographer_WorldMapOverlayWindow.EventIndexToIconMap[j].IsShownOnMap = false
					end
				end
			end
		end

		mapCoordinates = AutoBiographer_WorldMapOverlayWindow_TransformCoordinates(currentEventsExpansion, mapCoordinates)
	end

  if (not eventsShownPerMapId[mapCoordinates.MapId]) then
    eventsShownPerMapId[mapCoordinates.MapId] = 0
  end

  local tooltipLines = {}
  table.insert(tooltipLines, Event.ToString(event, AutoBiographer_Controller.CharacterData.Catalogs))

	-- Todo: A map of coordinates to tooltipLines could make this much more efficient.
  for j = eventIndex - 1, firstIndex, -1 do
    local otherEvent = AutoBiographer_Controller.CharacterData.Events[j]
    local otherMapCoordinates = Event.GetMapCoordinates(otherEvent)
		if (otherMapCoordinates and AutoBiographer_Settings.MapEventDisplayFilters[otherEvent.SubType]) then
			if (AutoBiographer_Settings.MapEventFollowExpansions) then
				otherMapCoordinates = AutoBiographer_WorldMapOverlayWindow_TransformCoordinates(currentEventsExpansion, otherMapCoordinates)
			end

			if (mapCoordinates.MapId == otherMapCoordinates.MapId and
					10 > Hbd:GetZoneDistance(mapCoordinates.MapId, mapCoordinates.X / 100, mapCoordinates.Y / 100, otherMapCoordinates.MapId, otherMapCoordinates.X / 100, otherMapCoordinates.Y / 100)) then
				table.insert(tooltipLines, Event.ToString(otherEvent, AutoBiographer_Controller.CharacterData.Catalogs))
				if (AutoBiographer_WorldMapOverlayWindow.EventIndexToIconMap[j].IsShownOnMap) then
					HbdPins:RemoveWorldMapIcon(AutoBiographer_WorldMapOverlayWindow, AutoBiographer_WorldMapOverlayWindow.EventIndexToIconMap[j])
					AutoBiographer_WorldMapOverlayWindow.EventIndexToIconMap[j].IsShownOnMap = false
				end
			end
		end
  end

  local icon = table.remove(AutoBiographer_EventMapIconPool.UnAllocated)
  if (not icon) then
    icon = CreateFrame("Frame", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate")
  end
  
  icon:SetWidth(8)
  icon:SetHeight(8)
  icon:SetBackdrop({bgFile = Event.GetIconPath(event)})

  icon:SetScript("OnEnter", function(self, button)
    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    GameTooltip:ClearAllPoints();
    GameTooltip:SetPoint("TOPRIGHT", icon, "BOTTOMRIGHT", 0, 0)

    if (#tooltipLines == 1) then
      GameTooltip:SetText("1 Event")
    else
      GameTooltip:SetText(#tooltipLines .. " Events")
    end
    
    for j = 1, #tooltipLines do
			if (j >= 100) then
				break
			end

      GameTooltip:AddLine(tooltipLines[j])
    end
    
    GameTooltip:Show()
  end)

  icon:SetScript("OnLeave", function(self, button)
    GameTooltip:Hide()
  end)

  if (AutoBiographer_Settings.MapEventShowAnimation) then
    if (not icon.animationGroup) then
      icon.animationGroup = icon:CreateAnimationGroup()    
      local scaleAnimation = icon.animationGroup:CreateAnimation("Scale")
      scaleAnimation:SetScale(0.5, 0.5)
      scaleAnimation:SetDuration(0.5)
      scaleAnimation:SetSmoothing("IN")
      scaleAnimation:SetScript("OnPlay", function()
        icon:SetWidth(16)
        icon:SetHeight(16)
      end)
      scaleAnimation:SetScript("OnFinished", function()
        icon:SetWidth(8)
        icon:SetHeight(8)
      end)
    end

    if (icon.animationGroup:IsPlaying()) then
      icon.animationGroup:Restart()
    else
      icon.animationGroup:Play()
    end
  end
  
  HbdPins:AddWorldMapIconMap(AutoBiographer_WorldMapOverlayWindow, icon, mapCoordinates.MapId, mapCoordinates.X / 100, mapCoordinates.Y / 100, HBD_PINS_WORLDMAP_SHOW_WORLD)
  icon.IsShownOnMap = true

  local frameLevel = icon:GetFrameLevel()
  icon:SetFrameLevel(frameLevel + eventsShownPerMapId[mapCoordinates.MapId])

  table.insert(AutoBiographer_EventMapIconPool.Allocated, icon)
  AutoBiographer_WorldMapOverlayWindow.EventIndexToIconMap[eventIndex] = icon
  eventsShownPerMapId[mapCoordinates.MapId] = eventsShownPerMapId[mapCoordinates.MapId] + 1

  if (AutoBiographer_WorldMapOverlayWindow.EventsShown % eventsToShowPerDelay == 0) then
    if (AutoBiographer_Settings.MapEventShowCircle) then
      AutoBiographer_WorldMapOverlayWindow_UpdateCurrentEventIndicator(mapCoordinates)
    end

    C_Timer.After(delay, function()
      AutoBiographer_WorldMapOverlayWindow_ShowEvent(eventIndex + 1, firstIndex, delay, eventsToShowPerDelay, eventsShownPerMapId, currentEventsExpansion, currentEventsLevel, false)
    end)
  else
    AutoBiographer_WorldMapOverlayWindow_ShowEvent(eventIndex + 1, firstIndex, delay, eventsToShowPerDelay, eventsShownPerMapId, currentEventsExpansion, currentEventsLevel, true)
  end
end

function AutoBiographer_WorldMapOverlayWindow_TransformCoordinates(currentEventsExpansion, mapCoordinates)
	if (currentEventsExpansion == 1 and mapCoordinates.InstanceId == 530) then
		return Coordinates.New(0, 1419, 59.56, 58.66) -- Dark portal in Blasted Lands.
	elseif (currentEventsExpansion == 2 and mapCoordinates.InstanceId ~= 530) then
		return Coordinates.New(530, 1944, 89.34, 50.22) -- Dark portal in Hellfire Peninsula.
  elseif (currentEventsExpansion == 3 and mapCoordinates.InstanceId ~= 571) then
		return Coordinates.New(571, 113, 80.6, 94.67) -- Off southern tip of Howling Fjord.
	end

	return mapCoordinates;
end

function AutoBiographer_WorldMapOverlayWindow_SetOptionsEnabled(enabled)
  AutoBiographer_WorldMapOverlayWindow.BossKillCb:SetEnabled(enabled)
  AutoBiographer_WorldMapOverlayWindow.CustomCb:SetEnabled(enabled)
  AutoBiographer_WorldMapOverlayWindow.FirstAcquiredItemCb:SetEnabled(enabled)
  AutoBiographer_WorldMapOverlayWindow.FirstKillCb:SetEnabled(enabled)
  AutoBiographer_WorldMapOverlayWindow.LevelUpCb:SetEnabled(enabled)
  AutoBiographer_WorldMapOverlayWindow.PlayerDeathCb:SetEnabled(enabled)
  AutoBiographer_WorldMapOverlayWindow.QuestTurnInCb:SetEnabled(enabled)
  AutoBiographer_WorldMapOverlayWindow.ReputationLevelChangedCb:SetEnabled(enabled)
  AutoBiographer_WorldMapOverlayWindow.SkillMilestoneCb:SetEnabled(enabled)
  AutoBiographer_WorldMapOverlayWindow.SpellLearnedCb:SetEnabled(enabled)
  AutoBiographer_WorldMapOverlayWindow.ZoneFirstVisitCb:SetEnabled(enabled)

  AutoBiographer_WorldMapOverlayWindow.ShowAnimationCb:SetEnabled(enabled)
  AutoBiographer_WorldMapOverlayWindow.ShowCircleCb:SetEnabled(enabled)
end

function AutoBiographer_WorldMapOverlayWindow_UpdateCurrentEventIndicator(coordinates)
  if (not AutoBiographer_WorldMapOverlayWindow.CircleIcon) then
    AutoBiographer_WorldMapOverlayWindow.CircleIcon = CreateFrame("Frame", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate")
    AutoBiographer_WorldMapOverlayWindow.CircleIcon:SetWidth(16)
    AutoBiographer_WorldMapOverlayWindow.CircleIcon:SetHeight(16)
    AutoBiographer_WorldMapOverlayWindow.CircleIcon:SetBackdrop({bgFile = "Interface\\AddOns\\AutoBiographer\\Icons\\circle.blp"})
  else
    HbdPins:RemoveWorldMapIcon(AutoBiographer_WorldMapOverlayWindow, AutoBiographer_WorldMapOverlayWindow.CircleIcon)
  end

  if (not coordinates) then
    return
  end

  HbdPins:AddWorldMapIconMap(AutoBiographer_WorldMapOverlayWindow, AutoBiographer_WorldMapOverlayWindow.CircleIcon, coordinates.MapId, coordinates.X / 100, coordinates.Y / 100, HBD_PINS_WORLDMAP_SHOW_WORLD)

  AutoBiographer_WorldMapOverlayWindow.CircleIcon:SetFrameLevel(9999)
end

function AutoBiographer_WorldMapOverlayWindowToggleButton:Initialize()
  local frame = AutoBiographer_WorldMapOverlayWindowToggleButton
  frame:SetPoint("BOTTOMLEFT", WorldMapFrame.ScrollContainer, "TOPLEFT", 0, 2);
  frame:SetSize(120, 20);
  frame:SetText("Event Window");
  frame:SetNormalFontObject("GameFontNormal");
  frame:SetHighlightFontObject("GameFontHighlight");
  frame:SetFrameLevel(10)
  frame:SetScript("OnClick", 
    function(self)
      AutoBiographer_WorldMapOverlayWindow:Toggle()
    end
  )

  if (HelperFunctions.GetGameVersion() >= 4) then
    frame:Hide()
  end
end
