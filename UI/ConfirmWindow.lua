AutoBiographer_ConfirmWindow = {}
function AutoBiographer_ConfirmWindow.New(message, callback)
  local window = CreateFrame("Frame", "Confirm", UIParent, "BasicFrameTemplate") 
  window:SetSize(350, 250) 
  window:SetPoint("CENTER") 
  
  if (not window:IsVisible()) then
    window:Hide()
    return
  end
  
  window.Confirmed = false
  
  window:SetScript("OnHide", 
    function(self)
      if (callback and (window.Confirmed == false or window.Confirmed)) then callback(self.Confirmed) end
    end
  )

  window.Message = window:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge");
  window.Message:SetPoint("CENTER", window, "TOP", 0, -100);
  window.Message:SetText(message)
  
  window.AcceptBtn = CreateFrame("Button", nil, window, "UIPanelButtonTemplate");
  window.AcceptBtn :SetPoint("BOTTOM", window, "BOTTOM", -75, 10);
  window.AcceptBtn :SetSize(140, 40);
  window.AcceptBtn :SetText("Accept");
  window.AcceptBtn :SetNormalFontObject("GameFontNormalLarge");
  window.AcceptBtn :SetHighlightFontObject("GameFontHighlightLarge");
  window.AcceptBtn :SetScript("OnClick", 
    function(self)
      window.Confirmed = true
      window:Hide()
    end
  )
  
  window.CancelBtn = CreateFrame("Button", nil, window, "UIPanelButtonTemplate");
  window.CancelBtn :SetPoint("BOTTOM", window, "BOTTOM", 75, 10);
  window.CancelBtn :SetSize(140, 40);
  window.CancelBtn :SetText("Cancel");
  window.CancelBtn :SetNormalFontObject("GameFontNormalLarge");
  window.CancelBtn :SetHighlightFontObject("GameFontHighlightLarge");
  window.CancelBtn :SetScript("OnClick", 
    function(self)
      window.Confirmed = false
      window:Hide()
    end
  )
end