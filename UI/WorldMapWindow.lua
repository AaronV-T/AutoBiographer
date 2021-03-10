local Hbd = LibStub("HereBeDragons-2.0")
local HbdPins = LibStub("HereBeDragons-Pins-2.0")

AutoBiographer_EventMapIconPool = {
  Allocated = {},
  UnAllocated = {},
}

function AutoBiographer_WorldMapWindowToggleButton_Toggle(self)
  -- If the events are already showing: hide them.
  if (AutoBiographer_WorldMapWindowToggleButton.IsActive) then
    HbdPins:RemoveAllWorldMapIcons(AutoBiographer_WorldMapWindowToggleButton)
    
    -- Release allocated icons.
    for i = 1, #AutoBiographer_EventMapIconPool.Allocated, 1 do
      local icon = AutoBiographer_EventMapIconPool.Allocated[i]
      icon:SetScript("OnEnter", nil)
      icon:SetScript("OnLeave", nil)
      table.insert(AutoBiographer_EventMapIconPool.UnAllocated, icon)
    end
    AutoBiographer_EventMapIconPool.Allocated = {}

    AutoBiographer_WorldMapWindowToggleButton:SetText("Show Events")
    AutoBiographer_WorldMapWindowToggleButton.IsActive = false
    return
  end

  -- Events are hidden. Show them.
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
            (event.Coordinates.InstanceId ~= nil and otherEvent.Coordinates.InstanceId == event.Coordinates.InstanceId))) then 
          
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

  AutoBiographer_WorldMapWindowToggleButton:SetText("Hide Events")
  AutoBiographer_WorldMapWindowToggleButton.IsActive = true
end
