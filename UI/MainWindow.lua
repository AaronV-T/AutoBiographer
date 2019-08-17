MainWindow_Frame = nil


function Toggle_MainWindow()
  if (not MainWindow_Frame) then
  
    local events = Controller:GetEvents()
    
    --parent frame 
    local frame = CreateFrame("Frame", "MyFrame", UIParent, "BasicFrameTemplateWithInset") 
    frame:SetSize(750, 500) 
    frame:SetPoint("CENTER") 
    
    frame:SetScript("OnHide", 
      function(self)
        MainWindow_Frame = nil 
      end
    )

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
    frame.title:SetPoint("LEFT", frame.TitleBg, "LEFT", 5, 0);
    frame.title:SetText("AutoBiographer Test Window. Gold looted: " .. tostring(Controller:GetLootedMoney() / 10000) .. ". Total Gold Gained: " .. tostring(Controller:GetTotalMoneyGained() / 10000) .. ". Total Gold Lost: " .. tostring(Controller:GetTotalMoneyLost() / 10000));
    
    --scrollframe 
    scrollframe = CreateFrame("ScrollFrame", nil, frame) 
    scrollframe:SetPoint("TOPLEFT", 10, -25) 
    scrollframe:SetPoint("BOTTOMRIGHT", -10, 10) 
    local texture = scrollframe:CreateTexture() 
    texture:SetAllPoints() 
    texture:SetTexture(.5,.5,.5,1) 
    frame.scrollframe = scrollframe 

    --scrollbar 
    scrollbar = CreateFrame("Slider", nil, scrollframe, "UIPanelScrollBarTemplate") 
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
    content:SetSize(128, 128) 
    --local texture = content:CreateTexture() 
    --texture:SetAllPoints() 
    --texture:SetTexture("Interface\\GLUES\\MainMenu\\Glues-BlizzardLogo") 
    --content.texture = texture 
    
    
    --texts
    local index = 0
    for i = #events, 1, -1 do
      local text = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
      text:SetPoint("TOPLEFT", 5, -15 * index) 
      text:SetText(events[i]);
      index = index + 1
    end
    
    scrollframe.content = content 

    scrollframe:SetScrollChild(content)

    ---------------------------------
    -- Helpful Dev Code
    ---------------------------------
    SLASH_RELOADUI1 = "/rl"; -- new slash command for reloading UI
    SlashCmdList.RELOADUI = ReloadUI;

    SLASH_FRAMESTK1 = "/fs"; -- new slash command for showing framestack tool
    SlashCmdList.FRAMESTK = function()
      LoadAddOn("Blizzard_DebugTools");
      FrameStackTooltip_Toggle();
    end

    -- allows using left and right buttons to move through the chat 'edit' box
    for i = 1, NUM_CHAT_WINDOWS do
      _G["ChatFrame"..i.."EditBox"]:SetAltArrowKeyMode(false);
    end
    
    MainWindow_Frame = frame
  else
    MainWindow_Frame:Hide()
    MainWindow_Frame = nil
  end
end