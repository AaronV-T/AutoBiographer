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
  frame:SetSize(250, 100)
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

  frame.EventsBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate");
  frame.EventsBtn:SetPoint("CENTER");
  frame.EventsBtn:SetSize(140, 40);
  frame.EventsBtn:SetText("Show Events");
  frame.EventsBtn:SetNormalFontObject("GameFontNormalLarge");
  frame.EventsBtn:SetHighlightFontObject("GameFontHighlightLarge");
  frame.EventsBtn:SetScript("OnClick", 
    function(self)
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
  HbdPins:RemoveAllWorldMapIcons(AutoBiographer_WorldMapWindowToggleButton)

  -- Release allocated icons.
  for i = 1, #AutoBiographer_EventMapIconPool.Allocated, 1 do
    local icon = AutoBiographer_EventMapIconPool.Allocated[i]
    icon:SetScript("OnEnter", nil)
    icon:SetScript("OnLeave", nil)
    table.insert(AutoBiographer_EventMapIconPool.UnAllocated, icon)
  end
  AutoBiographer_EventMapIconPool.Allocated = {}

  AutoBiographer_WorldMapOverlayWindow.EventsBtn:SetText("Show Events")
  AutoBiographer_WorldMapOverlayWindow.EventsAreShown = false
  return
end

function AutoBiographer_WorldMapOverlayWindow_ShowEvents()
  for i = 1, #AutoBiographer_Controller.CharacterData.Events do
    local event = AutoBiographer_Controller.CharacterData.Events[i]

    if (event.Coordinates) then
      local tooltipLines = {}
      table.insert(tooltipLines, Event.ToString(event, AutoBiographer_Controller.CharacterData.Catalogs))

      for j = i - 1, 1, -1 do
        local otherEvent = AutoBiographer_Controller.CharacterData.Events[j]
        if (otherEvent.Coordinates and
            ((event.Coordinates.MapId ~= nil and otherEvent.Coordinates.MapId == event.Coordinates.MapId and
            10 > Hbd:GetZoneDistance(event.Coordinates.MapId, event.Coordinates.X, event.Coordinates.Y, otherEvent.Coordinates.MapId, otherEvent.Coordinates.X, otherEvent.Coordinates.Y)) or
            (event.Coordinates.MapId == nil and event.Coordinates.InstanceId ~= nil and otherEvent.Coordinates.InstanceId == event.Coordinates.InstanceId))) then 
          
          table.insert(tooltipLines, Event.ToString(otherEvent, AutoBiographer_Controller.CharacterData.Catalogs))
          HbdPins:RemoveWorldMapIcon(AutoBiographer_WorldMapWindowToggleButton, AutoBiographer_EventMapIconPool.Allocated[j])
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

      if (event.Coordinates.MapId ~= nil and event.Coordinates.X and event.Coordinates.Y) then
        HbdPins:AddWorldMapIconMap(AutoBiographer_WorldMapWindowToggleButton, icon, event.Coordinates.MapId, event.Coordinates.X / 100, event.Coordinates.Y / 100, HBD_PINS_WORLDMAP_SHOW_WORLD)
      elseif (event.Coordinates.InstanceId ~= nil and AutoBiographer_Databases.InstanceLocationDatabase[event.Coordinates.InstanceId]) then
        local coords = AutoBiographer_Databases.InstanceLocationDatabase[event.Coordinates.InstanceId]
        HbdPins:AddWorldMapIconMap(AutoBiographer_WorldMapWindowToggleButton, icon, coords.MapId, coords.X / 100, coords.Y / 100, HBD_PINS_WORLDMAP_SHOW_WORLD)
      end

      table.insert(AutoBiographer_EventMapIconPool.Allocated, icon)
    end
  end

  AutoBiographer_WorldMapOverlayWindow.EventsBtn:SetText("Hide Events")
  AutoBiographer_WorldMapOverlayWindow.EventsAreShown = true
end

function AutoBiographer_WorldMapOverlayWindowToggleButton_Toggle(self)
  AutoBiographer_WorldMapOverlayWindow:Toggle()
end