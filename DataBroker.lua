-- The display (or another addon) supplies LibDataBroker; it is optional.
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
      icon = "Interface\\Icons\\inv_misc_note_05",
      OnClick = function(_, button)
        if (not AutoBiographer_MainWindow.Initialized) then return end
        if (button == "LeftButton") then
          AutoBiographer_MainWindow:Toggle()
        elseif (button == "MiddleButton") then
          AutoBiographer_MainWindow:ShowSection("Replay")
        elseif (button == "RightButton") then
          Settings.OpenToCategory(AutoBiographer_OptionWindow.categoryID)
          AutoBiographer_MainWindow:Hide()
        end
      end,
      OnTooltipShow = function(tooltip)
        tooltip:AddLine("AutoBiographer", 1, 0.82, 0)
        tooltip:AddLine("|cffe6cc80Left-click:|r Toggle the AutoBiographer interface", 0.7, 0.7, 0.7)
        tooltip:AddLine("|cffe6cc80Middle-click:|r Adventure Replay", 0.7, 0.7, 0.7)
        tooltip:AddLine("|cffe6cc80Right-click:|r Options", 0.7, 0.7, 0.7)
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
