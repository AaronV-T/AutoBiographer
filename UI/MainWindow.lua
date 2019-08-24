DebugWindow_Frame = nil
EventWindow_Frame = nil
MainWindow_Frame = nil

function Toggle_DebugWindow()
  if (not DebugWindow_Frame) then
  
    local debugLogs = Controller:GetLogs()
    
    --parent frame 
    local frame = CreateFrame("Frame", "AutoBiographerDebug", MainWindow_Frame, "BasicFrameTemplateWithInset") 
    frame:SetSize(750, 550) 
    frame:SetPoint("CENTER") 
    
    frame:SetScript("OnHide", 
      function(self)
        DebugWindow_Frame = nil 
      end
    )

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.title:SetPoint("LEFT", frame.TitleBg, "LEFT", 5, 0);
    frame.title:SetText("AutoBiographer Debug Window")
    
    --scrollframe 
    local scrollframe = CreateFrame("ScrollFrame", nil, frame) 
    scrollframe:SetPoint("TOPLEFT", 10, -35) 
    scrollframe:SetPoint("BOTTOMRIGHT", -10, 10) 


    --scrollbar 
    local scrollbar = CreateFrame("Slider", nil, scrollframe, "UIPanelScrollBarTemplate") 
    scrollbar:SetPoint("TOPLEFT", frame, "TOPRIGHT", 4, -16) 
    scrollbar:SetPoint("BOTTOMLEFT", frame, "BOTTOMRIGHT", 4, 16)
    scrollbar:SetMinMaxValues(1, (#debugLogs * 20) + 20) 
    scrollbar:SetValueStep(1) 
    scrollbar.scrollStep = 1 
    scrollbar:SetValue(0) 
    scrollbar:SetWidth(16) 
    scrollbar:SetScript("OnValueChanged",
      function (self, value) 
        self:GetParent():SetVerticalScroll(value) 
      end
    )
    local scrollbg = scrollbar:CreateTexture(nil, "BACKGROUND") 
    scrollbg:SetAllPoints(scrollbar) 
    scrollbg:SetTexture(0, 0, 0, 0.4) 
    frame.scrollbar = scrollbar 

    --content frame 
    local content = CreateFrame("Frame", nil, scrollframe) 
    content:SetSize(1, 1) 
    
    --texts
    local index = 0
    for i = #debugLogs, 1, -1 do
      local text = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      text:SetPoint("TOPLEFT", 5, -15 * index) 
      text:SetText(debugLogs[i])
      index = index + 1
    end
    
    scrollframe.content = content
    scrollframe:SetScrollChild(content)
    
    frame.LogsUpdated = function () return end
    
    DebugWindow_Frame = frame
  else
    DebugWindow_Frame:Hide()
    DebugWindow_Frame = nil
  end
end

function Toggle_EventWindow()
  if (not EventWindow_Frame) then
  
    local events = Controller:GetEvents()
    
    --parent frame 
    local frame = CreateFrame("Frame", "AutoBiographerEvent", MainWindow_Frame, "BasicFrameTemplateWithInset") 
    frame:SetSize(750, 550) 
    frame:SetPoint("CENTER") 
    
    frame:SetScript("OnHide", 
      function(self)
        EventWindow_Frame = nil 
      end
    )

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.title:SetPoint("LEFT", frame.TitleBg, "LEFT", 5, 0);
    frame.title:SetText("AutoBiographer Event Window")
    
    --scrollframe 
    local scrollframe = CreateFrame("ScrollFrame", nil, frame) 
    scrollframe:SetPoint("TOPLEFT", 10, -35) 
    scrollframe:SetPoint("BOTTOMRIGHT", -10, 10) 


    --scrollbar 
    local scrollbar = CreateFrame("Slider", nil, scrollframe, "UIPanelScrollBarTemplate") 
    scrollbar:SetPoint("TOPLEFT", frame, "TOPRIGHT", 4, -16) 
    scrollbar:SetPoint("BOTTOMLEFT", frame, "BOTTOMRIGHT", 4, 16)
    scrollbar:SetMinMaxValues(1, (#events * 20) + 20) 
    scrollbar:SetValueStep(1) 
    scrollbar.scrollStep = 1 
    scrollbar:SetValue(0) 
    scrollbar:SetWidth(16) 
    scrollbar:SetScript("OnValueChanged",
      function (self, value) 
        self:GetParent():SetVerticalScroll(value) 
      end
    ) 
    local scrollbg = scrollbar:CreateTexture(nil, "BACKGROUND") 
    scrollbg:SetAllPoints(scrollbar) 
    scrollbg:SetTexture(0, 0, 0, 0.4) 
    frame.scrollbar = scrollbar 

    --content frame 
    local content = CreateFrame("Frame", nil, scrollframe) 
    content:SetSize(1, 1) 
    
    --texts
    local index = 0
    for i = #events, 1, -1 do
      local text = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      text:SetPoint("TOPLEFT", 5, -15 * index) 
      text:SetText(events[i])
      index = index + 1
    end
    
    scrollframe.content = content
    scrollframe:SetScrollChild(content)
    
    EventWindow_Frame = frame
  else
    EventWindow_Frame:Hide()
    EventWindow_Frame = nil
  end
end

function Toggle_MainWindow()
  if (not MainWindow_Frame) then

    --parent frame 
    local frame = CreateFrame("Frame", "AutoBiographerMain", UIParent, "BasicFrameTemplateWithInset") 
    frame:SetSize(800, 600) 
    frame:SetPoint("CENTER") 
    
    frame:SetScript("OnHide", 
      function(self)
        MainWindow_Frame = nil 
      end
    )

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
    frame.title:SetPoint("LEFT", frame.TitleBg, "LEFT", 5, 0);
    frame.title:SetText("AutoBiographer Main Window")
    
    local eventsBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate");
    eventsBtn:SetPoint("CENTER", frame, "TOP", -140, -70);
    eventsBtn:SetSize(140, 40);
    eventsBtn:SetText("Events");
    eventsBtn:SetNormalFontObject("GameFontNormalLarge");
    eventsBtn:SetHighlightFontObject("GameFontHighlightLarge");
    eventsBtn:SetScript("OnClick", 
      function(self)
        Toggle_EventWindow()
      end
    )
    
    local debugBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate");
    debugBtn:SetPoint("CENTER", frame, "TOP", 140, -70);
    debugBtn:SetSize(140, 40);
    debugBtn:SetText("Debug");
    debugBtn:SetNormalFontObject("GameFontNormalLarge");
    debugBtn:SetHighlightFontObject("GameFontHighlightLarge");
    debugBtn:SetScript("OnClick", 
      function(self)
        Toggle_DebugWindow()
      end
    )
    
    local moneyText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    moneyText:SetPoint("TOPLEFT", 10, -100)
    moneyText:SetText("Gold looted: " .. tostring(Controller:GetLootedMoney() / 10000) .. ". Total Gold Gained: " .. tostring(Controller:GetTotalMoneyGained() / 10000) .. ". Total Gold Lost: " .. tostring(Controller:GetTotalMoneyLost() / 10000) .. ".")
    
    local damageText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    damageText:SetPoint("TOPLEFT", 10, -115)
    local damageDealtAmount, damageDealtOverkill = Controller:GetDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.DamageDealt)
    local damageTakenAmount, damageTakenOverkill = Controller:GetDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.DamageTaken)
    damageText:SetText("Damage Dealt: " .. tostring(damageDealtAmount) .. " (" .. tostring(damageDealtOverkill) .. " overkill). Damage Taken: " .. tostring(damageTakenAmount) .. " (" .. tostring(damageTakenOverkill) .. " overkill)." )
    
    local healingText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    healingText:SetPoint("TOPLEFT", 10, -130)
    local healingOtherAmount, healingOtherOver = Controller:GetDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.HealingDealtToOthers)
    local healingSelfAmount, healingSelfOver = Controller:GetDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.HealingDealtToSelf)
    local healingTakenAmount, healingTakenOver = Controller:GetDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.HealingTaken)
    healingText:SetText("Healing Dealt to Others: " .. tostring(healingOtherAmount) .. " (" .. tostring(healingOtherOver) .. " over). Healing Dealt to Self: " .. tostring(healingSelfAmount) .. " (" .. tostring(healingSelfOver) .. " over). Healing Taken: " .. tostring(healingTakenAmount) .. " (" .. tostring(healingTakenOver) .. " over)." )
    
    local timeText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    timeText:SetPoint("TOPLEFT", 10, -145)
    timeText:SetText("Time spent AFK: " .. tostring(Controller:GetTimeForTimeTrackingType(AutoBiographerEnum.TimeTrackingType.Afk)) .. ". Time spent in combat: " .. tostring(Controller:GetTimeForTimeTrackingType(AutoBiographerEnum.TimeTrackingType.InCombat)) .. ". Time spent on taxis: " .. tostring(Controller:GetTimeForTimeTrackingType(AutoBiographerEnum.TimeTrackingType.OnTaxi)) .. ". Time spent logged in: " .. tostring(Controller:GetTimeForTimeTrackingType(AutoBiographerEnum.TimeTrackingType.LoggedIn)) .. ". Time spent dead: " .. tostring(Controller:GetTimeForTimeTrackingType(AutoBiographerEnum.TimeTrackingType.DeadOrGhost)) .. ". Time spent casting: " .. tostring(Controller:GetTimeForTimeTrackingType(AutoBiographerEnum.TimeTrackingType.Casting)) .. ".")
    
    local itemText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    itemText:SetPoint("TOPLEFT", 10, -160)
    itemText:SetText("Items looted: " .. tostring(Controller:GetItemCountForAcquisitionMethod(AutoBiographerEnum.AcquisitionMethod.Loot)) .. ". Items acquired by other means: " .. tostring(Controller:GetItemCountForAcquisitionMethod(AutoBiographerEnum.AcquisitionMethod.Other)) .. ".")
    
    MainWindow_Frame = frame
  else
    MainWindow_Frame:Hide()
    MainWindow_Frame = nil
  end
end