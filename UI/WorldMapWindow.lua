local Hbd = LibStub("HereBeDragons-2.0")
local HbdPins = LibStub("HereBeDragons-Pins-2.0")

AutoBiographer_EventMapIconPool = {
  Allocated = {},
  UnAllocated = {},
}

AutoBiographer_WorldMapOverlayWindow = nil

function AutoBiographer_WorldMapOverlayWindow_Initialize()
  AutoBiographer_WorldMapOverlayWindow = CreateFrame("Frame", "AutoBiographerW", WorldMapFrame.ScrollContainer, "BasicFrameTemplate")
  local frame = AutoBiographer_WorldMapOverlayWindow
  frame:SetSize(300, 125)
  frame:SetPoint("BOTTOMRIGHT", WorldMapFrame.ScrollContainer, "BOTTOMRIGHT")

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
  local leftPoint = -112.5
  frame.BossKillIcon = CreateFrame("Frame", nil, frame)
  frame.BossKillIcon:SetSize(20, 20)
  frame.BossKillIcon:SetPoint("TOP", frame, "TOP", leftPoint, -25)
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
  frame.BossKillCb= CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate") 
  frame.BossKillCb:SetPoint("TOP", frame, "TOP", leftPoint, -40)
  frame.BossKillCb:SetChecked(AutoBiographer_Settings.MapEventDisplayFilters[AutoBiographerEnum.EventSubType.BossKill])
  frame.BossKillCb:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.MapEventDisplayFilters[AutoBiographerEnum.EventSubType.BossKill] = self:GetChecked()
  end)
  
  leftPoint = leftPoint + 25
  frame.FirstAcquiredItemIcon = CreateFrame("Frame", nil, frame)
  frame.FirstAcquiredItemIcon:SetSize(20, 20)
  frame.FirstAcquiredItemIcon:SetPoint("TOP", frame, "TOP", leftPoint, -25)
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
  frame.FirstAcquiredItemCb:SetPoint("TOP", frame, "TOP", leftPoint, -40)
  frame.FirstAcquiredItemCb:SetChecked(AutoBiographer_Settings.MapEventDisplayFilters[AutoBiographerEnum.EventSubType.FirstAcquiredItem])
  frame.FirstAcquiredItemCb:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.MapEventDisplayFilters[AutoBiographerEnum.EventSubType.FirstAcquiredItem] = self:GetChecked()
  end)
  
  leftPoint = leftPoint + 25
  frame.FirstKillIcon = CreateFrame("Frame", nil, frame)
  frame.FirstKillIcon:SetSize(20, 20)
  frame.FirstKillIcon:SetPoint("TOP", frame, "TOP", leftPoint, -25)
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
  frame.FirstKillCb:SetPoint("TOP", frame, "TOP", leftPoint, -40)
  frame.FirstKillCb:SetChecked(AutoBiographer_Settings.MapEventDisplayFilters[AutoBiographerEnum.EventSubType.FirstKill])
  frame.FirstKillCb:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.MapEventDisplayFilters[AutoBiographerEnum.EventSubType.FirstKill] = self:GetChecked()
  end)
  
  leftPoint = leftPoint + 25
  frame.LevelUpIcon = CreateFrame("Frame", nil, frame)
  frame.LevelUpIcon:SetSize(20, 20)
  frame.LevelUpIcon:SetPoint("TOP", frame, "TOP", leftPoint, -25)
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
  frame.LevelUpCb:SetPoint("TOP", frame, "TOP", leftPoint, -40)
  frame.LevelUpCb:SetChecked(AutoBiographer_Settings.MapEventDisplayFilters[AutoBiographerEnum.EventSubType.LevelUp])
  frame.LevelUpCb:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.MapEventDisplayFilters[AutoBiographerEnum.EventSubType.LevelUp] = self:GetChecked()
  end)
  
  leftPoint = leftPoint + 25
  frame.PlayerDeathIcon = CreateFrame("Frame", nil, frame)
  frame.PlayerDeathIcon:SetSize(20, 20)
  frame.PlayerDeathIcon:SetPoint("TOP", frame, "TOP", leftPoint, -25)
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
  frame.PlayerDeathCb:SetPoint("TOP", frame, "TOP", leftPoint, -40)
  frame.PlayerDeathCb:SetChecked(AutoBiographer_Settings.MapEventDisplayFilters[AutoBiographerEnum.EventSubType.PlayerDeath])
  frame.PlayerDeathCb:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.MapEventDisplayFilters[AutoBiographerEnum.EventSubType.PlayerDeath] = self:GetChecked()
  end)
  
  leftPoint = leftPoint + 25
  frame.QuestTurnInIcon = CreateFrame("Frame", nil, frame)
  frame.QuestTurnInIcon:SetSize(20, 20)
  frame.QuestTurnInIcon:SetPoint("TOP", frame, "TOP", leftPoint, -25)
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
  frame.QuestTurnInCb:SetPoint("TOP", frame, "TOP", leftPoint, -40)
  frame.QuestTurnInCb:SetChecked(AutoBiographer_Settings.MapEventDisplayFilters[AutoBiographerEnum.EventSubType.QuestTurnIn])
  frame.QuestTurnInCb:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.MapEventDisplayFilters[AutoBiographerEnum.EventSubType.QuestTurnIn] = self:GetChecked()
  end)
  
  leftPoint = leftPoint + 25
  frame.ReputationLevelChangedIcon = CreateFrame("Frame", nil, frame)
  frame.ReputationLevelChangedIcon:SetSize(20, 20)
  frame.ReputationLevelChangedIcon:SetPoint("TOP", frame, "TOP", leftPoint, -25)
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
  frame.ReputationLevelChangedCb:SetPoint("TOP", frame, "TOP", leftPoint, -40)
  frame.ReputationLevelChangedCb:SetChecked(AutoBiographer_Settings.MapEventDisplayFilters[AutoBiographerEnum.EventSubType.ReputationLevelChanged])
  frame.ReputationLevelChangedCb:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.MapEventDisplayFilters[AutoBiographerEnum.EventSubType.ReputationLevelChanged] = self:GetChecked()
  end)
  
  leftPoint = leftPoint + 25
  frame.SkillMilestoneIcon = CreateFrame("Frame", nil, frame)
  frame.SkillMilestoneIcon:SetSize(20, 20)
  frame.SkillMilestoneIcon:SetPoint("TOP", frame, "TOP", leftPoint, -25)
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
  frame.SkillMilestoneCb:SetPoint("TOP", frame, "TOP", leftPoint, -40)
  frame.SkillMilestoneCb:SetChecked(AutoBiographer_Settings.MapEventDisplayFilters[AutoBiographerEnum.EventSubType.SkillMilestone])
  frame.SkillMilestoneCb:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.MapEventDisplayFilters[AutoBiographerEnum.EventSubType.SkillMilestone] = self:GetChecked()
  end)
  
  leftPoint = leftPoint + 25
  frame.SpellLearnedIcon = CreateFrame("Frame", nil, frame)
  frame.SpellLearnedIcon:SetSize(20, 20)
  frame.SpellLearnedIcon:SetPoint("TOP", frame, "TOP", leftPoint, -25)
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
  frame.SpellLearnedCb:SetPoint("TOP", frame, "TOP", leftPoint, -40)
  frame.SpellLearnedCb:SetChecked(AutoBiographer_Settings.MapEventDisplayFilters[AutoBiographerEnum.EventSubType.SpellLearned])
  frame.SpellLearnedCb:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.MapEventDisplayFilters[AutoBiographerEnum.EventSubType.SpellLearned] = self:GetChecked()
  end)
  
  leftPoint = leftPoint + 25
  frame.ZoneFirstVisitIcon = CreateFrame("Frame", nil, frame)
  frame.ZoneFirstVisitIcon:SetSize(20, 20)
  frame.ZoneFirstVisitIcon:SetPoint("TOP", frame, "TOP", leftPoint, -25)
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
  frame.ZoneFirstVisitCb:SetPoint("TOP", frame, "TOP", leftPoint, -40)
  frame.ZoneFirstVisitCb:SetChecked(AutoBiographer_Settings.MapEventDisplayFilters[AutoBiographerEnum.EventSubType.SubZoneFirstVisit])
  frame.ZoneFirstVisitCb:SetScript("OnClick", function(self, event, arg1)
    AutoBiographer_Settings.MapEventDisplayFilters[AutoBiographerEnum.EventSubType.SubZoneFirstVisit] = self:GetChecked()
    AutoBiographer_Settings.MapEventDisplayFilters[AutoBiographerEnum.EventSubType.ZoneFirstVisit] = self:GetChecked()
  end)

  -- 
  frame.EventsPerSecondEb = CreateFrame("EditBox", nil, frame);
  frame.EventsPerSecondEb:SetSize(30, 20)
  frame.EventsPerSecondEb:SetPoint("BOTTOMLEFT", 5, 5)
  frame.EventsPerSecondEb:SetBackdrop({
    bgFile = "",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = "true",
    tileSize = 32,
    edgeSize = 10,
    insets = {left = 3, right = 3, top = 3, bottom = 3}
  })
  frame.EventsPerSecondEb:SetFont("Fonts\\FRIZQT__.TTF", 11)
  frame.EventsPerSecondEb:SetAutoFocus(false)
  frame.EventsPerSecondEb:SetMultiLine(false)
  frame.EventsPerSecondEb:SetNumeric(true)
  frame.EventsPerSecondEb:SetScript("OnEscapePressed", function() frame.EventsPerSecondEb:ClearFocus() end)

  frame.EventsPerSecondFs = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.EventsPerSecondFs:SetPoint("LEFT", frame.EventsPerSecondEb, "RIGHT", 2, 0)
  frame.EventsPerSecondFs:SetText("Events Per Second")

  frame.ProgressFs = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.ProgressFs:SetPoint("BOTTOMRIGHT", -5, 45)
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
  AutoBiographer_WorldMapOverlayWindow.ProgressFs:SetText("Progress: N/A")

  HbdPins:RemoveAllWorldMapIcons(AutoBiographer_WorldMapWindowToggleButton)

  -- Release allocated icons.
  for i = 1, #AutoBiographer_EventMapIconPool.Allocated, 1 do
    local icon = AutoBiographer_EventMapIconPool.Allocated[i]
    icon:SetScript("OnEnter", nil)
    icon:SetScript("OnLeave", nil)
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

  local eventsPerSecond = AutoBiographer_WorldMapOverlayWindow.EventsPerSecondEb:GetNumber()
  if (eventsPerSecond < 1) then
    eventsPerSecond = 100
  elseif (eventsPerSecond > 500) then
    eventsPerSecond = 500
  end

  AutoBiographer_WorldMapOverlayWindow.EventsPerSecondEb:SetNumber(eventsPerSecond)

  local delayBetweenEvents = 1 / eventsPerSecond

  local eventsToShowPerDelay = 1
  while (delayBetweenEvents * eventsToShowPerDelay < 0.02) do
    eventsToShowPerDelay = eventsToShowPerDelay + 1
  end

  AutoBiographer_WorldMapOverlayWindow.EventIndexToIconMap = {}
  AutoBiographer_WorldMapOverlayWindow_ShowEvent(1, delayBetweenEvents * eventsToShowPerDelay, eventsToShowPerDelay, {})
end

function AutoBiographer_WorldMapOverlayWindow_ShowEvent(eventIndex, delay, eventsToShowPerDelay, eventsShownPerMapId)
  if (not AutoBiographer_WorldMapOverlayWindow.EventsAreShown or eventIndex > #AutoBiographer_Controller.CharacterData.Events) then
    return
  end

  AutoBiographer_WorldMapOverlayWindow.ProgressFs:SetText("Progress: " .. string.format("%.f %%", (eventIndex / #AutoBiographer_Controller.CharacterData.Events)* 100))

  local event = AutoBiographer_Controller.CharacterData.Events[eventIndex]
  local mapCoordinates = Event.GetMapCoordinates(event)
  if (not mapCoordinates or not AutoBiographer_Settings.MapEventDisplayFilters[event.SubType]) then
    AutoBiographer_WorldMapOverlayWindow_ShowEvent(eventIndex + 1, delay, eventsToShowPerDelay, eventsShownPerMapId)
    return
  end

  if (not eventsShownPerMapId[mapCoordinates.MapId]) then
    eventsShownPerMapId[mapCoordinates.MapId] = 0
  end

  local tooltipLines = {}
  table.insert(tooltipLines, Event.ToString(event, AutoBiographer_Controller.CharacterData.Catalogs))

  for j = eventIndex - 1, 1, -1 do
    local otherEvent = AutoBiographer_Controller.CharacterData.Events[j]
    local otherMapCoordinates = Event.GetMapCoordinates(otherEvent)
    if (otherMapCoordinates and AutoBiographer_Settings.MapEventDisplayFilters[otherEvent.SubType] and mapCoordinates.MapId == otherMapCoordinates.MapId and
        5 > Hbd:GetZoneDistance(mapCoordinates.MapId, mapCoordinates.X / 100, mapCoordinates.Y / 100, otherMapCoordinates.MapId, otherMapCoordinates.X / 100, otherMapCoordinates.Y / 100)) then
      
      table.insert(tooltipLines, Event.ToString(otherEvent, AutoBiographer_Controller.CharacterData.Catalogs))
      HbdPins:RemoveWorldMapIcon(AutoBiographer_WorldMapWindowToggleButton, AutoBiographer_WorldMapOverlayWindow.EventIndexToIconMap[j])
    end
  end

  local icon = table.remove(AutoBiographer_EventMapIconPool.UnAllocated)
  if (not icon) then
    icon = CreateFrame("Frame", nil, UIParent)
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
      GameTooltip:AddLine(tooltipLines[j])
    end
    
    GameTooltip:Show()
  end)

  icon:SetScript("OnLeave", function(self, button)
    GameTooltip:Hide()
  end)

  HbdPins:AddWorldMapIconMap(AutoBiographer_WorldMapWindowToggleButton, icon, mapCoordinates.MapId, mapCoordinates.X / 100, mapCoordinates.Y / 100, HBD_PINS_WORLDMAP_SHOW_WORLD)

  local frameLevel = icon:GetFrameLevel()
  icon:SetFrameLevel(frameLevel + eventsShownPerMapId[mapCoordinates.MapId])

  table.insert(AutoBiographer_EventMapIconPool.Allocated, icon)
  AutoBiographer_WorldMapOverlayWindow.EventIndexToIconMap[eventIndex] = icon
  eventsShownPerMapId[mapCoordinates.MapId] = eventsShownPerMapId[mapCoordinates.MapId] + 1

  local eventsShown = 0
  for k, v in pairs(eventsShownPerMapId) do
    eventsShown = eventsShown + v
  end
  
  if (eventsShown % eventsToShowPerDelay == 0) then
    C_Timer.After(delay, function()
      AutoBiographer_WorldMapOverlayWindow_ShowEvent(eventIndex + 1, delay, eventsToShowPerDelay, eventsShownPerMapId)
    end)
  else
    AutoBiographer_WorldMapOverlayWindow_ShowEvent(eventIndex + 1, delay, eventsToShowPerDelay, eventsShownPerMapId)
  end
end

function AutoBiographer_WorldMapOverlayWindowToggleButton_Toggle(self)
  AutoBiographer_WorldMapOverlayWindow:Toggle()
end