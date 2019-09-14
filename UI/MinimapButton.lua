function AutoBiographer_MinimapButton_Reposition()
	AutoBiographer_MinimapButton:SetPoint("TOPLEFT","Minimap","TOPLEFT",52-(80*cos(AutoBiographer_Settings.MinimapPos)),(80*sin(AutoBiographer_Settings.MinimapPos))-52)
end

function AutoBiographer_MinimapButton_DraggingFrame_OnUpdate()

	local xpos,ypos = GetCursorPosition()
	local xmin,ymin = Minimap:GetLeft(), Minimap:GetBottom()

	xpos = xmin-xpos/UIParent:GetScale()+70 -- get coordinates as differences from the center of the minimap
	ypos = ypos/UIParent:GetScale()-ymin-70

	AutoBiographer_Settings.MinimapPos = math.deg(math.atan2(ypos,xpos)) -- save the degrees we are relative to the minimap center
	AutoBiographer_MinimapButton_Reposition() -- move the button
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