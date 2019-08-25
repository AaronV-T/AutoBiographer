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
    
    -- Buttons
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
    
    -- Money
    local moneyLooted = Controller:GetMoneyForAcquisitionMethod(AutoBiographerEnum.AcquisitionMethod.Loot)
    local moneyLootedText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    moneyLootedText:SetPoint("TOPLEFT", 10, -100)
    moneyLootedText:SetText("Money Looted: " .. GetCoinText(moneyLooted) .. ".")
    
    local moneyGainedFromQuesting = Controller:GetMoneyForAcquisitionMethod(AutoBiographerEnum.AcquisitionMethod.Quest)
    local moneyGainedFromQuestingText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    moneyGainedFromQuestingText:SetPoint("TOPLEFT", 10, -115)
    moneyGainedFromQuestingText:SetText("Money Gained From Quests: " .. GetCoinText(moneyGainedFromQuesting) .. ".")
    
    local moneyGainedFromOther = Controller:GetTotalMoneyGained() - moneyLooted - moneyGainedFromQuesting
    local moneyOtherText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    moneyOtherText:SetPoint("TOPLEFT", 10, -130)
    moneyOtherText:SetText("Money Gained From Other Sources: " .. GetCoinText(moneyGainedFromOther) .. ".")
    
    -- Damage
    local damageDealtAmount, damageDealtOver = Controller:GetDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.DamageDealt)
    local damageDealtText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    damageDealtText:SetPoint("TOPLEFT", 10, -160)
    damageDealtText:SetText("Damage Dealt: " .. tostring(damageDealtAmount) .. " (" .. tostring(damageDealtOver) .. " over).")
    
    local damageTakenAmount, damageTakenOver = Controller:GetDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.DamageTaken)
    local damageTakenText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    damageTakenText:SetPoint("TOPLEFT", 10, -175)
    damageTakenText:SetText("Damage Taken: " .. tostring(damageTakenAmount) .. " (" .. tostring(damageTakenOver) .. " over).")
    
    local healingOtherAmount, healingOtherOver = Controller:GetDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.HealingDealtToOthers)
    local healingOtherText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    healingOtherText:SetPoint("TOPLEFT", 10, -190)
    healingOtherText:SetText("Healing Dealt to Others: " .. tostring(healingOtherAmount) .. " (" .. tostring(healingOtherOver) .. " over).")
    
    local healingSelfAmount, healingSelfOver = Controller:GetDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.HealingDealtToSelf)
    local healingSelfText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    healingSelfText:SetPoint("TOPLEFT", 10, -205)
    healingSelfText:SetText("Healing Dealt to Self: " .. tostring(healingSelfAmount) .. " (" .. tostring(healingSelfOver) .. " over).")
    
    local healingTakenAmount, healingTakenOver = Controller:GetDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.HealingTaken)
    local healingTakenText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    healingTakenText:SetPoint("TOPLEFT", 10, -220)
    healingTakenText:SetText("Healing Taken: " .. tostring(healingTakenAmount) .. " (" .. tostring(healingTakenOver) .. " over).")
    
    -- Time
    local timeSpentAfk = Controller:GetTimeForTimeTrackingType(AutoBiographerEnum.TimeTrackingType.Afk)
    local timeSpentAfkText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    timeSpentAfkText:SetPoint("TOPLEFT", 10, -250)
    timeSpentAfkText:SetText("Time Spent AFK: " .. HelperFunctions.SecondsToTimeString(timeSpentAfk) .. ".")
    
    local timeSpentCasting = Controller:GetTimeForTimeTrackingType(AutoBiographerEnum.TimeTrackingType.Casting)
    local timeSpentCastingText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    timeSpentCastingText:SetPoint("TOPLEFT", 10, -265)
    timeSpentCastingText:SetText("Time Spent Casting: " .. HelperFunctions.SecondsToTimeString(timeSpentCasting) .. ".")
    
    local timeSpentDead = Controller:GetTimeForTimeTrackingType(AutoBiographerEnum.TimeTrackingType.DeadOrGhost)
    local timeSpentDeadText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    timeSpentDeadText:SetPoint("TOPLEFT", 10, -280)
    timeSpentDeadText:SetText("Time Spent Dead: " .. HelperFunctions.SecondsToTimeString(timeSpentDead) .. ".")
    
    local timeSpentInCombat = Controller:GetTimeForTimeTrackingType(AutoBiographerEnum.TimeTrackingType.InCombat)
    local timeSpentAfkText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    timeSpentAfkText:SetPoint("TOPLEFT", 10, -295)
    timeSpentAfkText:SetText("Time Spent in Combat: " .. HelperFunctions.SecondsToTimeString(timeSpentInCombat) .. ".")
    
    local timeSpentLoggedIn = Controller:GetTimeForTimeTrackingType(AutoBiographerEnum.TimeTrackingType.LoggedIn)
    local timeSpentLoggedInText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    timeSpentLoggedInText:SetPoint("TOPLEFT", 10, -310)
    timeSpentLoggedInText:SetText("Time Spent Logged In: " .. HelperFunctions.SecondsToTimeString(timeSpentLoggedIn) .. ".")
    
    local timeSpentOnTaxi = Controller:GetTimeForTimeTrackingType(AutoBiographerEnum.TimeTrackingType.OnTaxi)
    local timeSpentOnTaxiText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    timeSpentOnTaxiText:SetPoint("TOPLEFT", 10, -325)
    timeSpentOnTaxiText:SetText("Time Spent on Flights: " .. HelperFunctions.SecondsToTimeString(timeSpentOnTaxi) .. ".")
    
    -- Items
    local itemsCreated = Controller:GetItemCountForAcquisitionMethod(AutoBiographerEnum.AcquisitionMethod.Create)
    local itemsCreatedText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    itemsCreatedText:SetPoint("TOPLEFT", 10, -355)
    itemsCreatedText:SetText("Items Created: " .. tostring(itemsCreated) .. ".")
    
    local itemsLooted = Controller:GetItemCountForAcquisitionMethod(AutoBiographerEnum.AcquisitionMethod.Loot)
    local itemsLootedText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    itemsLootedText:SetPoint("TOPLEFT", 10, -370)
    itemsLootedText:SetText("Items Looted: " .. tostring(itemsLooted) .. ".")
    
    local itemsOther = Controller:GetItemCountForAcquisitionMethod(AutoBiographerEnum.AcquisitionMethod.Other)
    local itemsOtherText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    itemsOtherText:SetPoint("TOPLEFT", 10, -385)
    itemsOtherText:SetText("Other Items Acquired: " .. tostring(itemsOther) .. ".")
    
    -- Kills
    local taggedKills = Controller:GetTaggedKills()
    local taggedKillsText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    taggedKillsText:SetPoint("TOPLEFT", 10, -415)
    taggedKillsText:SetText("Tagged Kills: " .. tostring(taggedKills) .. ".")
    
    MainWindow_Frame = frame
  else
    MainWindow_Frame:Hide()
    MainWindow_Frame = nil
  end
end