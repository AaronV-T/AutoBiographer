-- The display (or another addon) supplies LibDataBroker; it is optional.
local addonName = ...
local frame = CreateFrame("Frame")

local function RegisterLauncher()
  if (not AutoBiographer_MainWindow.Initialized) then return end

  local ldb = LibStub:GetLibrary("LibDataBroker-1.1", true)
  if (not ldb) then return end

  -- Do not replace an object already registered under this name.
  if (not ldb:GetDataObjectByName("AutoBiographer")) then
    ldb:NewDataObject("AutoBiographer", {
      type = "launcher",
      label = "AutoBiographer",
      text = "AutoBiographer",
      tocname = addonName,
      icon = "Interface\\Icons\\inv_misc_note_05",
      OnClick = function(_, button)
        if (button == "LeftButton" and AutoBiographer_MainWindow.Initialized) then
          AutoBiographer_MainWindow:Toggle()
        end
      end,
      OnTooltipShow = function(tooltip)
        tooltip:AddLine("AutoBiographer", 1, 0.82, 0)
        tooltip:AddLine("Left-click to toggle the AutoBiographer interface.", 1, 1, 1)
      end,
    })
  end

  frame:UnregisterAllEvents()
end

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(_, event)
  if (event == "PLAYER_LOGIN" or IsLoggedIn()) then RegisterLauncher() end
end)
