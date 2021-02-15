Hbd = LibStub("HereBeDragons-2.0")
HbdPins = LibStub("HereBeDragons-Pins-2.0")

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
        GameTooltip:SetText(Event.ToString(event, AutoBiographer_Controller.CharacterData.Catalogs))
        GameTooltip:Show()
      end)

      icon:SetScript("OnLeave", function(self, button)
        GameTooltip:Hide()
      end)

      HbdPins:AddWorldMapIconMap(AutoBiographer_WorldMapWindowToggleButton, icon, event.Coordinates.MapId, event.Coordinates.X / 100, event.Coordinates.Y / 100, HBD_PINS_WORLDMAP_SHOW_WORLD )--, showFlag, frameLevelType)
      table.insert(AutoBiographer_EventMapIconPool.Allocated, icon)
    end
  end

  AutoBiographer_WorldMapWindowToggleButton:SetText("Hide Events")
  AutoBiographer_WorldMapWindowToggleButton.IsActive = true
end
