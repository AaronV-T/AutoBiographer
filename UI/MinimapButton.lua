local function GetMinimapRadii()
  return Minimap:GetWidth() / 2 + 10, Minimap:GetHeight() / 2 + 10
end

function AutoBiographer_MinimapButton_Reposition()
  local radiusX, radiusY = GetMinimapRadii()
  local angle = math.rad(AutoBiographer_Settings.MinimapPos)
  AutoBiographer_MinimapButton:ClearAllPoints()
  AutoBiographer_MinimapButton:SetPoint("CENTER", Minimap, "CENTER", -radiusX * math.cos(angle), radiusY * math.sin(angle))
end

function AutoBiographer_MinimapButton_DraggingFrame_OnUpdate()
  local centerX, centerY = Minimap:GetCenter()
  if (not centerX or not centerY) then return end
  local cursorX, cursorY = GetCursorPosition()
  local scale = Minimap:GetEffectiveScale()
  local radiusX, radiusY = GetMinimapRadii()
  -- Cursor coordinates are screen pixels; the minimap center uses its own scale.
  -- Keep the saved angle convention: zero is left, positive angles move upward.
  local x = (centerX - cursorX / scale) / radiusX
  local y = (cursorY / scale - centerY) / radiusY
  if (x == 0 and y == 0) then return end
  AutoBiographer_Settings.MinimapPos = math.deg(math.atan2(y, x))
  AutoBiographer_MinimapButton_Reposition()
end

function AutoBiographer_MinimapButton_OnClick(arg1)
  AutoBiographer_MainWindow:Toggle()
end

function AutoBiographer_MinimapButton_OnEnter()
  GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
  GameTooltip:ClearAllPoints();
  GameTooltip:SetPoint("TOPRIGHT", AutoBiographer_MinimapButton, "BOTTOMRIGHT", 0, 0)
  GameTooltip:SetText("AutoBiographer")
  GameTooltip:Show()
end

function AutoBiographer_MinimapButton_OnLeave()
  GameTooltip:Hide()
end
