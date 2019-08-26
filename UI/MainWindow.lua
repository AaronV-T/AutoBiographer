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
    scrollframe:SetBackdrop( { 
      bgFile = "Interface/FrameGeneral/UI-Background-Marble", 
      edgeFile = nil, tile = false, tileSize = 0, edgeSize = 0, 
      insets = { left = 0, right = 0, top = 0, bottom = 0 }
    });

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
    
    local subFrame = CreateFrame("Frame", "AutoBiographerEvent", frame)
    subFrame:SetPoint("TOPLEFT", 10, -25) 
    subFrame:SetPoint("BOTTOMRIGHT", -10, 10) 
    subFrame:SetBackdrop( { 
      bgFile = "Interface/FrameGeneral/UI-Background-Marble", 
      edgeFile = nil, tile = false, tileSize = 0, edgeSize = 0, 
      insets = { left = 0, right = 0, top = 0, bottom = 0 }
    });
    
    subFrame.RepopulateContent = function(self)
      Toggle_EventWindow()
      Toggle_EventWindow()
    end
    
    -- Filter Check Boxes
    local fsBossKill = subFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fsBossKill:SetPoint("CENTER", subFrame, "TOP", -250, -15)
    fsBossKill:SetText("Boss\nKill")
    local cbBossKill= CreateFrame("CheckButton", nil, subFrame, "UICheckButtonTemplate") 
    cbBossKill:SetPoint("CENTER", subFrame, "TOP", -250, -40)
    cbBossKill:SetChecked(AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.BossKill])
    cbBossKill:SetScript("OnClick", function(self, event, arg1)
      AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.BossKill] = self:GetChecked()
      subFrame:RepopulateContent()
    end)
    
    local fsFirstAcquiredItem = subFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fsFirstAcquiredItem:SetPoint("CENTER", subFrame, "TOP", -200, -15) 
    fsFirstAcquiredItem:SetText("First\nItem")
    local cbFirstAcquiredItem = CreateFrame("CheckButton", nil, subFrame, "UICheckButtonTemplate") 
    cbFirstAcquiredItem:SetPoint("CENTER", subFrame, "TOP", -200, -40)
    cbFirstAcquiredItem:SetChecked(AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.FirstAcquiredItem])
    cbFirstAcquiredItem:SetScript("OnClick", function(self, event, arg1)
      AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.FirstAcquiredItem] = self:GetChecked()
      subFrame:RepopulateContent()
    end)
    
    local fsFirstKill = subFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fsFirstKill:SetPoint("CENTER", subFrame, "TOP", -150, -15)
    fsFirstKill:SetText("First\nKill")
    local cbFirstKill = CreateFrame("CheckButton", nil, subFrame, "UICheckButtonTemplate") 
    cbFirstKill:SetPoint("CENTER", subFrame, "TOP", -150, -40)
    cbFirstKill:SetChecked(AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.FirstKill])
    cbFirstKill:SetScript("OnClick", function(self, event, arg1)
      AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.FirstKill] = self:GetChecked()
      subFrame:RepopulateContent()
    end)
    
    local fsGuild = subFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fsGuild:SetPoint("CENTER", subFrame, "TOP", -100, -15)
    fsGuild:SetText("Guild")
    local cbGuild = CreateFrame("CheckButton", nil, subFrame, "UICheckButtonTemplate") 
    cbGuild:SetPoint("CENTER", subFrame, "TOP", -100, -40)
    cbGuild:SetChecked(AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.GuildJoined])
    cbGuild:SetScript("OnClick", function(self, event, arg1)
      AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.GuildJoined] = self:GetChecked()
      AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.GuildLeft] = self:GetChecked()
      AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.GuildRankChanged] = self:GetChecked()
      subFrame:RepopulateContent()
    end)
    
    local fsLevelUp = subFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fsLevelUp:SetPoint("CENTER", subFrame, "TOP", -50, -15)
    fsLevelUp:SetText("Level\nUp")
    local cbLevelUp= CreateFrame("CheckButton", nil, subFrame, "UICheckButtonTemplate") 
    cbLevelUp:SetPoint("CENTER", subFrame, "TOP", -50, -40)
    cbLevelUp:SetChecked(AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.LevelUp])
    cbLevelUp:SetScript("OnClick", function(self, event, arg1)
      AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.LevelUp] = self:GetChecked()
      subFrame:RepopulateContent()
    end)
    
    local fsPlayerDeath = subFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fsPlayerDeath:SetPoint("CENTER", subFrame, "TOP", 0, -15)
    fsPlayerDeath:SetText("Player\nDeath")
    local cbPlayerDeath = CreateFrame("CheckButton", nil, subFrame, "UICheckButtonTemplate") 
    cbPlayerDeath:SetPoint("CENTER", subFrame, "TOP", 0, -40)
    cbPlayerDeath:SetChecked(AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.PlayerDeath])
    cbPlayerDeath:SetScript("OnClick", function(self, event, arg1)
      AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.PlayerDeath] = self:GetChecked()
      subFrame:RepopulateContent()
    end)
    
    local fsQuestTurnIn = subFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fsQuestTurnIn:SetPoint("CENTER", subFrame, "TOP", 50, -15)
    fsQuestTurnIn:SetText("Quest")
    local cbQuestTurnIn = CreateFrame("CheckButton", nil, subFrame, "UICheckButtonTemplate") 
    cbQuestTurnIn:SetPoint("CENTER", subFrame, "TOP", 50, -40)
    cbQuestTurnIn:SetChecked(AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.QuestTurnIn])
    cbQuestTurnIn:SetScript("OnClick", function(self, event, arg1)
      AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.QuestTurnIn] = self:GetChecked()
      subFrame:RepopulateContent()
    end)
    
    local fsSkillMilestone = subFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fsSkillMilestone:SetPoint("CENTER", subFrame, "TOP", 100, -15)
    fsSkillMilestone:SetText("Skill")
    local cbSkillMilestone = CreateFrame("CheckButton", nil, subFrame, "UICheckButtonTemplate") 
    cbSkillMilestone:SetPoint("CENTER", subFrame, "TOP", 100, -40)
    cbSkillMilestone:SetChecked(AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.SkillMilestone])
    cbSkillMilestone:SetScript("OnClick", function(self, event, arg1)
      AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.SkillMilestone] = self:GetChecked()
      subFrame:RepopulateContent()
    end)
    
    local fsSpellLearned = subFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fsSpellLearned:SetPoint("CENTER", subFrame, "TOP", 150, -15)
    fsSpellLearned:SetText("Spell")
    local cbSpellLearned= CreateFrame("CheckButton", nil, subFrame, "UICheckButtonTemplate") 
    cbSpellLearned:SetPoint("CENTER", subFrame, "TOP", 150, -40)
    cbSpellLearned:SetChecked(AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.SpellLearned])
    cbSpellLearned:SetScript("OnClick", function(self, event, arg1)
      AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.SpellLearned] = self:GetChecked()
      subFrame:RepopulateContent()
    end)
    
    local fsSubZoneFirstVisit = subFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fsSubZoneFirstVisit:SetPoint("CENTER", subFrame, "TOP", 200, -15)
    fsSubZoneFirstVisit:SetText("Sub\nZone")
    local cbSubZoneFirstVisit = CreateFrame("CheckButton", nil, subFrame, "UICheckButtonTemplate") 
    cbSubZoneFirstVisit:SetPoint("CENTER", subFrame, "TOP", 200, -40)
    cbSubZoneFirstVisit:SetChecked(AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.SubZoneFirstVisit])
    cbSubZoneFirstVisit:SetScript("OnClick", function(self, event, arg1)
      AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.SubZoneFirstVisit] = self:GetChecked()
      subFrame:RepopulateContent()
    end)
    
    local fsZoneFirstVisit = subFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fsZoneFirstVisit:SetPoint("CENTER", subFrame, "TOP", 250, -15)
    fsZoneFirstVisit:SetText("Zone")
    local cbZoneFirstVisit = CreateFrame("CheckButton", nil, subFrame, "UICheckButtonTemplate") 
    cbZoneFirstVisit:SetPoint("CENTER", subFrame, "TOP", 250, -40)
    cbZoneFirstVisit:SetChecked(AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.ZoneFirstVisit])
    cbZoneFirstVisit:SetScript("OnClick", function(self, event, arg1)
      AutoBiographer_Settings.EventDisplayFilters[AutoBiographerEnum.EventSubType.ZoneFirstVisit] = self:GetChecked()
      subFrame:RepopulateContent()
    end)
    
    --scrollframe 
    local scrollframe = CreateFrame("ScrollFrame", nil, subFrame) 
    scrollframe:SetPoint("TOPLEFT", 10, -65) 
    scrollframe:SetPoint("BOTTOMRIGHT", -10, 10) 

    --scrollbar 
    local scrollbar = CreateFrame("Slider", nil, scrollframe, "UIPanelScrollBarTemplate") 
    scrollbar:SetPoint("TOPLEFT", subFrame, "TOPRIGHT", 4, -16) 
    scrollbar:SetPoint("BOTTOMLEFT", subFrame, "BOTTOMRIGHT", 4, 16)
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
      if (AutoBiographer_Settings.EventDisplayFilters[events[i].SubType]) then
        local text = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        text:SetPoint("TOPLEFT", 5, -15 * index) 
        text:SetText(Controller:GetEventString(events[i]))--text:SetText(events[i])
        index = index + 1
      end
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
    local eventsBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate");
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
    
    local debugBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate");
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
    
    -- Damage
    local damageHeaderText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    damageHeaderText:SetPoint("TOPLEFT", 10, -100)
    damageHeaderText:SetText("Damage")
    
    local damageDealtAmount, damageDealtOver = Controller:GetDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.DamageDealt)
    local damageDealtText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    damageDealtText:SetPoint("TOPLEFT", 10, -120)
    damageDealtText:SetText("Damage Dealt: " .. tostring(damageDealtAmount) .. " (" .. tostring(damageDealtOver) .. " over).")
    
    local damageTakenAmount, damageTakenOver = Controller:GetDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.DamageTaken)
    local damageTakenText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    damageTakenText:SetPoint("TOPLEFT", 10, -135)
    damageTakenText:SetText("Damage Taken: " .. tostring(damageTakenAmount) .. " (" .. tostring(damageTakenOver) .. " over).")
    
    local healingOtherAmount, healingOtherOver = Controller:GetDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.HealingDealtToOthers)
    local healingOtherText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    healingOtherText:SetPoint("TOPLEFT", 10, -150)
    healingOtherText:SetText("Healing Dealt to Others: " .. tostring(healingOtherAmount) .. " (" .. tostring(healingOtherOver) .. " over).")
    
    local healingSelfAmount, healingSelfOver = Controller:GetDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.HealingDealtToSelf)
    local healingSelfText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    healingSelfText:SetPoint("TOPLEFT", 10, -165)
    healingSelfText:SetText("Healing Dealt to Self: " .. tostring(healingSelfAmount) .. " (" .. tostring(healingSelfOver) .. " over).")
    
    local healingTakenAmount, healingTakenOver = Controller:GetDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.HealingTaken)
    local healingTakenText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    healingTakenText:SetPoint("TOPLEFT", 10, -180)
    healingTakenText:SetText("Healing Taken: " .. tostring(healingTakenAmount) .. " (" .. tostring(healingTakenOver) .. " over).")
    
    -- Items
    local itemsHeaderText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    itemsHeaderText:SetPoint("TOPLEFT", 10, -210)
    itemsHeaderText:SetText("Items")
    
    local itemsCreated = Controller:GetItemCountForAcquisitionMethod(AutoBiographerEnum.AcquisitionMethod.Create)
    local itemsCreatedText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    itemsCreatedText:SetPoint("TOPLEFT", 10, -230)
    itemsCreatedText:SetText("Items Created: " .. tostring(itemsCreated) .. ".")
    
    local itemsLooted = Controller:GetItemCountForAcquisitionMethod(AutoBiographerEnum.AcquisitionMethod.Loot)
    local itemsLootedText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    itemsLootedText:SetPoint("TOPLEFT", 10, -245)
    itemsLootedText:SetText("Items Looted: " .. tostring(itemsLooted) .. ".")
    
    local itemsOther = Controller:GetItemCountForAcquisitionMethod(AutoBiographerEnum.AcquisitionMethod.Other)
    local itemsOtherText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    itemsOtherText:SetPoint("TOPLEFT", 10, -260)
    itemsOtherText:SetText("Other Items Acquired: " .. tostring(itemsOther) .. ".")
    
    -- Kills
    local killsHeaderText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    killsHeaderText:SetPoint("TOPLEFT", 10, -290)
    killsHeaderText:SetText("Kills")
    
    local taggedKillingBlows = Controller:GetTaggedKillingBlows()
    local taggedKillingBlowsText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    taggedKillingBlowsText:SetPoint("TOPLEFT", 10, -310)
    taggedKillingBlowsText:SetText("Tagged Killing Blows: " .. tostring(taggedKillingBlows) .. ".")
    
    local otherTaggedKills = Controller:GetTaggedKills() - taggedKillingBlows
    local otherTaggedKillsText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    otherTaggedKillsText:SetPoint("TOPLEFT", 10, -325)
    otherTaggedKillsText:SetText("Other Tagged Kills: " .. tostring(otherTaggedKills) .. ".")
    
    -- Money
    local moneyHeaderText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    moneyHeaderText:SetPoint("TOPLEFT", 10, -355)
    moneyHeaderText:SetText("Money")
    
    local moneyLooted = Controller:GetMoneyForAcquisitionMethod(AutoBiographerEnum.AcquisitionMethod.Loot)
    local moneyLootedText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    moneyLootedText:SetPoint("TOPLEFT", 10, -375)
    moneyLootedText:SetText("Money Looted: " .. GetCoinText(moneyLooted) .. ".")
    
    local moneyGainedFromQuesting = Controller:GetMoneyForAcquisitionMethod(AutoBiographerEnum.AcquisitionMethod.Quest)
    local moneyGainedFromQuestingText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    moneyGainedFromQuestingText:SetPoint("TOPLEFT", 10, -390)
    moneyGainedFromQuestingText:SetText("Money Gained From Quests: " .. GetCoinText(moneyGainedFromQuesting) .. ".")
    
    local moneyGainedFromOther = Controller:GetTotalMoneyGained() - moneyLooted - moneyGainedFromQuesting
    local moneyOtherText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    moneyOtherText:SetPoint("TOPLEFT", 10, -405)
    moneyOtherText:SetText("Money Gained From Other Sources: " .. GetCoinText(moneyGainedFromOther) .. ".")
    
    -- Time
    local timeHeaderText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    timeHeaderText:SetPoint("TOPLEFT", 10, -435)
    timeHeaderText:SetText("Time")
    
    local timeSpentAfk = Controller:GetTimeForTimeTrackingType(AutoBiographerEnum.TimeTrackingType.Afk)
    local timeSpentAfkText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    timeSpentAfkText:SetPoint("TOPLEFT", 10, -455)
    timeSpentAfkText:SetText("Time Spent AFK: " .. HelperFunctions.SecondsToTimeString(timeSpentAfk) .. ".")
    
    local timeSpentCasting = Controller:GetTimeForTimeTrackingType(AutoBiographerEnum.TimeTrackingType.Casting)
    local timeSpentCastingText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    timeSpentCastingText:SetPoint("TOPLEFT", 10, -470)
    timeSpentCastingText:SetText("Time Spent Casting: " .. HelperFunctions.SecondsToTimeString(timeSpentCasting) .. ".")
    
    local timeSpentDead = Controller:GetTimeForTimeTrackingType(AutoBiographerEnum.TimeTrackingType.DeadOrGhost)
    local timeSpentDeadText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    timeSpentDeadText:SetPoint("TOPLEFT", 10, -485)
    timeSpentDeadText:SetText("Time Spent Dead: " .. HelperFunctions.SecondsToTimeString(timeSpentDead) .. ".")
    
    local timeSpentInCombat = Controller:GetTimeForTimeTrackingType(AutoBiographerEnum.TimeTrackingType.InCombat)
    local timeSpentAfkText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    timeSpentAfkText:SetPoint("TOPLEFT", 10, -500)
    timeSpentAfkText:SetText("Time Spent in Combat: " .. HelperFunctions.SecondsToTimeString(timeSpentInCombat) .. ".")
    
    local timeSpentLoggedIn = Controller:GetTimeForTimeTrackingType(AutoBiographerEnum.TimeTrackingType.LoggedIn)
    local timeSpentLoggedInText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    timeSpentLoggedInText:SetPoint("TOPLEFT", 10, -515)
    timeSpentLoggedInText:SetText("Time Spent Logged In: " .. HelperFunctions.SecondsToTimeString(timeSpentLoggedIn) .. ".")
    
    local timeSpentOnTaxi = Controller:GetTimeForTimeTrackingType(AutoBiographerEnum.TimeTrackingType.OnTaxi)
    local timeSpentOnTaxiText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    timeSpentOnTaxiText:SetPoint("TOPLEFT", 10, -530)
    timeSpentOnTaxiText:SetText("Time Spent on Flights: " .. HelperFunctions.SecondsToTimeString(timeSpentOnTaxi) .. ".")
    
    MainWindow_Frame = frame
  else
    MainWindow_Frame:Hide()
    MainWindow_Frame = nil
  end
end