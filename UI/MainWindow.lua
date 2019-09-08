AutoBiographer_DebugWindow = nil
AutoBiographer_EventWindow = nil
AutoBiographer_MainWindow = nil

local Controller = AutoBiographer_Controller

function Toggle_DebugWindow()
  if (not AutoBiographer_DebugWindow) then
  
    local debugLogs = Controller:GetLogs()
    
    --parent frame 
    local frame = CreateFrame("Frame", "AutoBiographerDebug", AutoBiographer_MainWindow, "BasicFrameTemplateWithInset") 
    frame:SetSize(750, 585) 
    frame:SetPoint("CENTER") 
    
    frame:SetScript("OnHide", 
      function(self)
        AutoBiographer_DebugWindow = nil 
      end
    )

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.title:SetPoint("LEFT", frame.TitleBg, "LEFT", 5, 0);
    frame.title:SetText("AutoBiographer Debug Window")
    
    --scrollframe 
    local scrollframe = CreateFrame("ScrollFrame", nil, frame) 
    scrollframe:SetPoint("TOPLEFT", 10, -25) 
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
      local font = "GameFontWhite"
      if (debugLogs[i].Level == AutoBiographerEnum.LogLevel.Verbose) then font = "GameFontDisable"
      elseif (debugLogs[i].Level == AutoBiographerEnum.LogLevel.Debug) then font = "GameFontDisable"
      elseif (debugLogs[i].Level == AutoBiographerEnum.LogLevel.Information) then font = "GameFontWhite"
      elseif (debugLogs[i].Level == AutoBiographerEnum.LogLevel.Warning) then font = "GameFontNormal"
      elseif (debugLogs[i].Level == AutoBiographerEnum.LogLevel.Error) then font = "GameFontRed"
      elseif (debugLogs[i].Level == AutoBiographerEnum.LogLevel.Fatal) then font = "GameFontRed"
      end
      
      local text = content:CreateFontString(nil, "OVERLAY", font)
      text:SetPoint("TOPLEFT", 5, -15 * index) 
      text:SetText(debugLogs[i].Text)
      index = index + 1
    end
    
    scrollframe.content = content
    scrollframe:SetScrollChild(content)
    
    frame.LogsUpdated = function () return end
    
    AutoBiographer_DebugWindow = frame
  else
    AutoBiographer_DebugWindow:Hide()
    AutoBiographer_DebugWindow = nil
  end
end

function Toggle_EventWindow()
  if (not AutoBiographer_EventWindow) then
  
    local events = Controller:GetEvents()
    
    --parent frame 
    local frame = CreateFrame("Frame", "AutoBiographerEvent", AutoBiographer_MainWindow, "BasicFrameTemplateWithInset")
    frame:SetSize(750, 585) 
    frame:SetPoint("CENTER") 
    
    frame:SetScript("OnHide", 
      function(self)
        AutoBiographer_EventWindow = nil 
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
    
    AutoBiographer_EventWindow = frame
  else
    AutoBiographer_EventWindow:Hide()
    AutoBiographer_EventWindow = nil
  end
end

function Toggle_MainWindow()
  if (not AutoBiographer_MainWindow) then

    --parent frame 
    local frame = CreateFrame("Frame", "AutoBiographerMain", UIParent, "BasicFrameTemplateWithInset") 
    frame:SetSize(800, 600) 
    frame:SetPoint("CENTER") 
    
    frame:SetScript("OnHide", 
      function(self)
        AutoBiographer_MainWindow = nil 
      end
    )

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
    frame.title:SetPoint("LEFT", frame.TitleBg, "LEFT", 5, 0);
    frame.title:SetText("AutoBiographer Main Window")
    
     --scrollframe 
    local scrollframe = CreateFrame("ScrollFrame", nil, frame) 
    scrollframe:SetPoint("TOPLEFT", 10, -25) 
    scrollframe:SetPoint("BOTTOMRIGHT", -10, 10) 

    --scrollbar 
    local scrollbar = CreateFrame("Slider", nil, scrollframe, "UIPanelScrollBarTemplate") 
    scrollbar:SetPoint("TOPLEFT", frame, "TOPRIGHT", -25, -45) 
    scrollbar:SetPoint("BOTTOMLEFT", frame, "BOTTOMRIGHT", -25, 22)
    scrollbar:SetMinMaxValues(1, 250) 
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
    content:SetSize(775, 600)
    content:SetPoint("TOPLEFT", scrollframe, "TOPRIGHT", 0, 0) 
    content:SetPoint("BOTTOMLEFT", scrollframe, "BOTTOMRIGHT", 0, 0)
    
    -- Buttons
    local eventsBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate");
    eventsBtn:SetPoint("CENTER", content, "TOP", -225, -25);
    eventsBtn:SetSize(140, 40);
    eventsBtn:SetText("Events");
    eventsBtn:SetNormalFontObject("GameFontNormalLarge");
    eventsBtn:SetHighlightFontObject("GameFontHighlightLarge");
    eventsBtn:SetScript("OnClick", 
      function(self)
        Toggle_EventWindow()
      end
    )
    
    local optionsBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate");
    optionsBtn:SetPoint("CENTER", content, "TOP", -75, -25);
    optionsBtn:SetSize(140, 40);
    optionsBtn:SetText("Options");
    optionsBtn:SetNormalFontObject("GameFontNormalLarge");
    optionsBtn:SetHighlightFontObject("GameFontHighlightLarge");
    optionsBtn:SetScript("OnClick", 
      function(self)
        InterfaceOptionsFrame_OpenToCategory(AutoBiographer_OptionWindow) -- Call this twice because it won't always work correcly if just called once.
        InterfaceOptionsFrame_OpenToCategory(AutoBiographer_OptionWindow)
        Toggle_MainWindow()
      end
    )
    
    local debugBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate");
    debugBtn:SetPoint("CENTER", content, "TOP", 75, -25);
    debugBtn:SetSize(140, 40);
    debugBtn:SetText("Debug");
    debugBtn:SetNormalFontObject("GameFontNormalLarge");
    debugBtn:SetHighlightFontObject("GameFontHighlightLarge");
    debugBtn:SetScript("OnClick", 
      function(self)
        Toggle_DebugWindow()
      end
    )
    
    local closeBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate");
    closeBtn:SetPoint("CENTER", content, "TOP", 225, -25);
    closeBtn:SetSize(140, 40);
    closeBtn:SetText("Close");
    closeBtn:SetNormalFontObject("GameFontNormalLarge");
    closeBtn:SetHighlightFontObject("GameFontHighlightLarge");
    closeBtn:SetScript("OnClick", 
      function(self)
        Toggle_MainWindow()
      end
    )
    
    -- Damage
    local damageHeaderFs = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    damageHeaderFs:SetPoint("TOPLEFT", 10, -75)
    damageHeaderFs:SetText("Damage")
    
    local damageDealtAmount, damageDealtOver = Controller:GetDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.DamageDealt)
    local petDamageDealtAmount, petDamageDealtOver = Controller:GetDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.PetDamageDealt)
    local damageDealtText = "Damage Dealt: " .. tostring(damageDealtAmount) .. " (" .. tostring(damageDealtOver) .. " over)."
    if (petDamageDealtAmount > 0) then damageDealtText = damageDealtText .. " Pet Damage Dealt: " .. tostring(petDamageDealtAmount) .. " (" .. tostring(petDamageDealtOver) .. " over)." end
    local damageDealtFs = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    damageDealtFs:SetPoint("TOPLEFT", 10, -95)
    damageDealtFs:SetText(damageDealtText)
    
    local damageTakenAmount, damageTakenOver = Controller:GetDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.DamageTaken)
    local petDamageTakenAmount, petDamageTakenOver = Controller:GetDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.PetDamageTaken)
    local damageTakenText = "Damage Taken: " .. tostring(damageTakenAmount) .. " (" .. tostring(damageTakenOver) .. " over)."
    if (petDamageTakenAmount > 0) then damageTakenText = damageTakenText .. " Pet Damage Taken: " .. tostring(petDamageTakenAmount) .. " (" .. tostring(petDamageTakenOver) .. " over)." end
    local damageTakenFs = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    damageTakenFs:SetPoint("TOPLEFT", 10, -110)
    damageTakenFs:SetText(damageTakenText)
    
    local healingOtherAmount, healingOtherOver = Controller:GetDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.HealingDealtToOthers)
    local healingOtherFs = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    healingOtherFs:SetPoint("TOPLEFT", 10, -125)
    healingOtherFs:SetText("Healing Dealt to Others: " .. tostring(healingOtherAmount) .. " (" .. tostring(healingOtherOver) .. " over).")
    
    local healingSelfAmount, healingSelfOver = Controller:GetDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.HealingDealtToSelf)
    local healingSelfFs = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    healingSelfFs:SetPoint("TOPLEFT", 10, -140)
    healingSelfFs:SetText("Healing Dealt to Self: " .. tostring(healingSelfAmount) .. " (" .. tostring(healingSelfOver) .. " over).")
    
    local healingTakenAmount, healingTakenOver = Controller:GetDamageOrHealing(AutoBiographerEnum.DamageOrHealingCategory.HealingTaken)
    local healingTakenFs = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    healingTakenFs:SetPoint("TOPLEFT", 10, -155)
    healingTakenFs:SetText("Healing Taken: " .. tostring(healingTakenAmount) .. " (" .. tostring(healingTakenOver) .. " over).")
    
    -- Experience
    local experienceHeaderFs = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    experienceHeaderFs:SetPoint("TOPLEFT", 10, -185)
    experienceHeaderFs:SetText("Experience")

    local experienceFromKills = Controller:GetExperienceByExperienceTrackingType(AutoBiographerEnum.ExperienceTrackingType.Kill)
    local experienceFromKillsFs = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    experienceFromKillsFs:SetPoint("TOPLEFT", 10, -205)
    experienceFromKillsFs:SetText("Experience From Kills: " .. tostring(experienceFromKills) .. ".")
        
    local experienceFromRestedBonus = Controller:GetExperienceByExperienceTrackingType(AutoBiographerEnum.ExperienceTrackingType.RestedBonus)
    local experienceFromRestedBonusFs = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    experienceFromRestedBonusFs:SetPoint("TOPLEFT", 20, -220)
    experienceFromRestedBonusFs:SetText("Experience From Rested Bonus: " .. tostring(experienceFromRestedBonus) .. ".")
    
    local experienceFromGroupBonus = Controller:GetExperienceByExperienceTrackingType(AutoBiographerEnum.ExperienceTrackingType.GroupBonus)
    local experienceFromGroupBonusFs = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    experienceFromGroupBonusFs:SetPoint("TOPLEFT", 20, -235)
    experienceFromGroupBonusFs:SetText("Experience From Group Bonus: " .. tostring(experienceFromGroupBonus) .. ".")
    
    local experienceLostToRaidPenalty = Controller:GetExperienceByExperienceTrackingType(AutoBiographerEnum.ExperienceTrackingType.RaidPenalty)
    local experienceLostToRaidPenaltyFs = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    experienceLostToRaidPenaltyFs:SetPoint("TOPLEFT", 20, -250)
    experienceLostToRaidPenaltyFs:SetText("Experience Lost To Raid Penalty: " .. tostring(experienceLostToRaidPenalty) .. ".")
    
    local experienceFromQuests = Controller:GetExperienceByExperienceTrackingType(AutoBiographerEnum.ExperienceTrackingType.Quest)
    local experienceFromQuestsFs = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    experienceFromQuestsFs:SetPoint("TOPLEFT", 10, -265)
    experienceFromQuestsFs:SetText("Experience From Quests: " .. tostring(experienceFromQuests) .. ".")
    
    local experienceFromDiscovery = Controller:GetExperienceByExperienceTrackingType(AutoBiographerEnum.ExperienceTrackingType.Discovery)
    local experienceFromDiscoveryFs = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    experienceFromDiscoveryFs:SetPoint("TOPLEFT", 10, -280)
    experienceFromDiscoveryFs:SetText("Experience From Discovery: " .. tostring(experienceFromDiscovery) .. ".")
    
    -- Items
    local itemsHeaderFs = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    itemsHeaderFs:SetPoint("TOPLEFT", 10, -310)
    itemsHeaderFs:SetText("Items")
    
    local itemsCreated = Controller:GetItemCountForAcquisitionMethod(AutoBiographerEnum.AcquisitionMethod.Create)
    local itemsCreatedFs = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    itemsCreatedFs:SetPoint("TOPLEFT", 10, -330)
    itemsCreatedFs:SetText("Items Created: " .. tostring(itemsCreated) .. ".")
    
    local itemsLooted = Controller:GetItemCountForAcquisitionMethod(AutoBiographerEnum.AcquisitionMethod.Loot)
    local itemsLootedFs = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    itemsLootedFs:SetPoint("TOPLEFT", 10, -345)
    itemsLootedFs:SetText("Items Looted: " .. tostring(itemsLooted) .. ".")
    
    local itemsOther = Controller:GetItemCountForAcquisitionMethod(AutoBiographerEnum.AcquisitionMethod.Other)
    local itemsOtherFs = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    itemsOtherFs:SetPoint("TOPLEFT", 10, -360)
    itemsOtherFs:SetText("Other Items Acquired: " .. tostring(itemsOther) .. ".")
    
    -- Kills
    local killsHeaderFs = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    killsHeaderFs:SetPoint("TOPLEFT", 10, -390)
    killsHeaderFs:SetText("Kills")
    
    local taggedKillingBlows = Controller:GetTaggedKillingBlows()
    local taggedKillingBlowsFs = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    taggedKillingBlowsFs:SetPoint("TOPLEFT", 10, -410)
    taggedKillingBlowsFs:SetText("Tagged Killing Blows: " .. tostring(taggedKillingBlows) .. ".")
    
    local otherTaggedKills = Controller:GetTaggedKills() - taggedKillingBlows
    local otherTaggedKillsFs = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    otherTaggedKillsFs:SetPoint("TOPLEFT", 10, -425)
    otherTaggedKillsFs:SetText("Other Tagged Kills: " .. tostring(otherTaggedKills) .. ".")
    
    -- Money
    local moneyHeaderFs = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    moneyHeaderFs:SetPoint("TOPLEFT", 10, -455)
    moneyHeaderFs:SetText("Money")
    
    local moneyLooted = Controller:GetMoneyForAcquisitionMethod(AutoBiographerEnum.AcquisitionMethod.Loot)
    local moneyLootedFs = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    moneyLootedFs:SetPoint("TOPLEFT", 10, -475)
    moneyLootedFs:SetText("Money Looted: " .. GetCoinText(moneyLooted) .. ".")
    
    local moneyGainedFromQuesting = Controller:GetMoneyForAcquisitionMethod(AutoBiographerEnum.AcquisitionMethod.Quest)
    local moneyGainedFromQuestingFs = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    moneyGainedFromQuestingFs:SetPoint("TOPLEFT", 10, -490)
    moneyGainedFromQuestingFs:SetText("Money Gained From Quests: " .. GetCoinText(moneyGainedFromQuesting) .. ".")
    
    local moneyGainedFromOther = Controller:GetTotalMoneyGained() - moneyLooted - moneyGainedFromQuesting
    local moneyOtherFs = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    moneyOtherFs:SetPoint("TOPLEFT", 10, -505)
    moneyOtherFs:SetText("Money Gained From Other Sources: " .. GetCoinText(moneyGainedFromOther) .. ".")
    
    -- Other Player Stats
    local otherPlayerHeaderFs = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    otherPlayerHeaderFs:SetPoint("TOPLEFT", 10, -535)
    otherPlayerHeaderFs:SetText("Other Player")
    
    local duelsWon = Controller:GetOtherPlayerStatByOtherPlayerTrackingType(AutoBiographerEnum.OtherPlayerTrackingType.DuelsLostToPlayer)
    local duelsWonFs = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    duelsWonFs:SetPoint("TOPLEFT", 10, -555)
    duelsWonFs:SetText("Duels Won: " .. tostring(duelsWon) .. ".")
    
    local duelsLost = Controller:GetOtherPlayerStatByOtherPlayerTrackingType(AutoBiographerEnum.OtherPlayerTrackingType.DuelsWonAgainstPlayer)
    local duelsLostFs = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    duelsLostFs:SetPoint("TOPLEFT", 10, -570)
    duelsLostFs:SetText("Duels Lost: " .. tostring(duelsLost) .. ".")
    
    -- Spells
    local spellsHeaderFs = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    spellsHeaderFs:SetPoint("TOPLEFT", 10, -600)
    spellsHeaderFs:SetText("Spells")
    
    local spellsStartedCasting = Controller:GetSpellCountBySpellTrackingType(AutoBiographerEnum.SpellTrackingType.StartedCasting)
    local spellsStartedCastingFs = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    spellsStartedCastingFs:SetPoint("TOPLEFT", 10, -620)
    spellsStartedCastingFs:SetText("Spells Started Casting: " .. tostring(spellsStartedCasting) .. ".")
    
    local spellsSuccessfullyCast = Controller:GetSpellCountBySpellTrackingType(AutoBiographerEnum.SpellTrackingType.SuccessfullyCast)
    local spellsSuccessfullyCastFs = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    spellsSuccessfullyCastFs:SetPoint("TOPLEFT", 10, -635)
    spellsSuccessfullyCastFs:SetText("Spells Successfully Cast: " .. tostring(spellsSuccessfullyCast) .. ".")
    
    -- Time
    local timeHeaderFs = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    timeHeaderFs:SetPoint("TOPLEFT", 10, -665)
    timeHeaderFs:SetText("Time")
    
    local timeSpentAfk = Controller:GetTimeForTimeTrackingType(AutoBiographerEnum.TimeTrackingType.Afk)
    local timeSpentAfkFs = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    timeSpentAfkFs:SetPoint("TOPLEFT", 10, -685)
    timeSpentAfkFs:SetText("Time Spent AFK: " .. HelperFunctions.SecondsToTimeString(timeSpentAfk) .. ".")
    
    local timeSpentCasting = Controller:GetTimeForTimeTrackingType(AutoBiographerEnum.TimeTrackingType.Casting)
    local timeSpentCastingFs = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    timeSpentCastingFs:SetPoint("TOPLEFT", 10, -700)
    timeSpentCastingFs:SetText("Time Spent Casting: " .. HelperFunctions.SecondsToTimeString(timeSpentCasting) .. ".")
    
    local timeSpentDead = Controller:GetTimeForTimeTrackingType(AutoBiographerEnum.TimeTrackingType.DeadOrGhost)
    local timeSpentDeadFs = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    timeSpentDeadFs:SetPoint("TOPLEFT", 10, -715)
    timeSpentDeadFs:SetText("Time Spent Dead: " .. HelperFunctions.SecondsToTimeString(timeSpentDead) .. ".")
    
    local timeSpentInCombat = Controller:GetTimeForTimeTrackingType(AutoBiographerEnum.TimeTrackingType.InCombat)
    local timeSpentInCombatFs = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    timeSpentInCombatFs:SetPoint("TOPLEFT", 10, -730)
    timeSpentInCombatFs:SetText("Time Spent in Combat: " .. HelperFunctions.SecondsToTimeString(timeSpentInCombat) .. ".")
    
    local timeSpentInGroup = Controller:GetTimeForTimeTrackingType(AutoBiographerEnum.TimeTrackingType.InParty)
    local timeSpentInGroupFs = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    timeSpentInGroupFs:SetPoint("TOPLEFT", 10, -745)
    timeSpentInGroupFs:SetText("Time Spent in Group: " .. HelperFunctions.SecondsToTimeString(timeSpentInGroup) .. ".")
    
    local timeSpentLoggedIn = Controller:GetTimeForTimeTrackingType(AutoBiographerEnum.TimeTrackingType.LoggedIn)
    local timeSpentLoggedInFs = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    timeSpentLoggedInFs:SetPoint("TOPLEFT", 10, -760)
    timeSpentLoggedInFs:SetText("Time Spent Logged In: " .. HelperFunctions.SecondsToTimeString(timeSpentLoggedIn) .. ".")
    
    local timeSpentOnTaxi = Controller:GetTimeForTimeTrackingType(AutoBiographerEnum.TimeTrackingType.OnTaxi)
    local timeSpentOnTaxiFs = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    timeSpentOnTaxiFs:SetPoint("TOPLEFT", 10, -775)
    timeSpentOnTaxiFs:SetText("Time Spent on Flights: " .. HelperFunctions.SecondsToTimeString(timeSpentOnTaxi) .. ".")
    
    scrollframe.content = content
    scrollframe:SetScrollChild(content)
    
    AutoBiographer_MainWindow = frame
  else
    AutoBiographer_MainWindow:Hide()
    AutoBiographer_MainWindow = nil
  end
end