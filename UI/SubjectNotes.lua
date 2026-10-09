-- Subject identity and game integration; the existing Notes panel owns editing.
AutoBiographer_SubjectNotes = {}
local SN = AutoBiographer_SubjectNotes
local Controller = AutoBiographer_Controller
local Api = AutoBiographer_Api
local HF = HelperFunctions
local Rating = AutoBiographerEnum.PlayerRating
local ratingOptions = {
  { Value = Rating.TwoThumbsDown, Name = "Two thumbs down", Short = "--", Color = "ffff4040" },
  { Value = Rating.OneThumbDown, Name = "One thumb down", Short = "-", Color = "ffffa04a" },
  { Value = Rating.NotApplicable, Name = "N/A", Short = "N/A", Color = "ffffffff" },
  { Value = Rating.OneThumbUp, Name = "One thumb up", Short = "+", Color = "ff8bdd68" },
  { Value = Rating.TwoThumbsUp, Name = "Two thumbs up", Short = "++", Color = "ff35d45c" },
}
local filters = {
  { Type = "All", Name = "All notes" }, { Type = "General", Name = "General" },
  { Type = "Player", Name = "Players" }, { Type = "Creature", Name = "Creatures" },
  { Type = "Item", Name = "Items" }, { Type = "Quest", Name = "Quests" },
}

local function IsSecret(value)
  return issecretvalue and issecretvalue(value)
end

local function Button(parent, label, width, callback)
  local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  button:SetSize(width, 24)
  button:SetText(label)
  button:SetScript("OnClick", callback)
  return button
end

function SN:AddQuestTooltip(tooltip, id)
  if (IsSecret(id) or type(id) ~= "number" or id < 1 or self.QuestTooltipSubjects[tooltip] == id) then return end
  self.QuestTooltipSubjects[tooltip] = id
  self:AddTooltip(tooltip, { Type = "Quest", Id = id })
end

function SN:AddTooltip(tooltip, subject)
  if (not Controller.AccountData.Notes or not subject) then return end
  local collection = Notes.GetCollection(Controller:GetNotes(), subject)
  local note = collection and collection[subject.Id]
  if (not note) then return end
  local preview = Notes.GetPreview(note, 12)
  if (preview ~= "") then tooltip:AddLine("Note: " .. preview, 0.6, 0.85, 1, true) end
  if (subject.Type == "Player") then
    tooltip:AddLine("Behavior: " .. self:GetRatingText(note.BehaviorRating) .. " | Skill: " .. self:GetRatingText(note.SkillRating), 1, 1, 1, true)
  end
  tooltip:Show()
end

function SN:GetEntries()
  local notes = Controller:GetNotes()
  local entries = {}
  for index, note in ipairs(notes.GenericNotes) do
    entries[#entries + 1] = { Note = note, Index = index, Key = "General:" .. index, Type = "General" }
  end
  for _, kind in ipairs({ "Unit", "Item", "Quest" }) do
    for id, note in pairs(notes[kind .. "Notes"]) do
      local subjectType = kind
      if (kind == "Unit") then
        subjectType = HF.GetUnitTypeFromCatalogUnitId(id) == AutoBiographerEnum.UnitType.Player and "Player" or "Creature"
      end
      entries[#entries + 1] = { Note = note, Key = subjectType .. ":" .. tostring(id), Type = subjectType,
        Subject = { Type = subjectType, Id = id, Name = note.Name } }
    end
  end
  return entries
end

function SN:GetLinkedSubject(text, expectedType)
  if (IsSecret(text) or type(text) ~= "string") then return nil end
  local kind, id = string.match(text, "(item):(%d+)")
  if (not kind) then kind, id = string.match(text, "(quest):(%d+)") end
  if (kind) then kind = kind == "item" and "Item" or "Quest"
  else kind, id = expectedType, string.match(text, "^%s*(%d+)%s*$") end
  id = tonumber(id)
  if ((kind ~= "Item" and kind ~= "Quest") or not id or id < 1) then return nil end
  local name = string.match(text, "%[([^%]]+)%]")
  if (kind == "Item") then
    local itemName = Api.GetItemInfo(id)
    if (not IsSecret(itemName)) then name = itemName or name end
  else
    local title = Api.GetQuestTitle(id)
    if (not IsSecret(title)) then name = title or name end
  end
  return { Type = kind, Id = id, Name = name }
end

function SN:GetRatingText(value)
  for _, option in ipairs(ratingOptions) do
    if (option.Value == (value or 0)) then return "|c" .. option.Color .. option.Short .. "|r" end
  end
  return "|cffffffffN/A|r"
end

function SN:GetSubjectTitle(subject)
  if (not subject) then return nil end
  local collection = Notes.GetCollection(Controller:GetNotes(), subject)
  local note = collection and collection[subject.Id]
  return subject.Name or note and note.Name or (subject.Type .. " #" .. tostring(subject.Id))
end

function SN:GetUnitSubject(unit, includeName)
  if (IsSecret(unit) or type(unit) ~= "string") then return nil end
  local guid = UnitGUID(unit)
  if (IsSecret(guid) or type(guid) ~= "string") then return nil end
  local kind = string.match(guid, "^(%w+)%-")
  if (kind ~= "Player" and kind ~= "Creature") then return nil end
  local id = HF.GetCatalogIdFromGuid(guid)
  if (not id) then return nil end
  local fullName
  if (includeName) then
    local name, lastName = Api.GetUnitName(unit)
    if (name) then
      fullName = (kind == "Player" and lastName) and (name .. " " .. lastName) or name
    end
  end
  return { Type = kind, Id = id, Name = fullName }
end

function SN:InitializeHooks()
  if (not self.UnitMenuRegistered) then
    self.UnitMenuRegistered = Api.RegisterUnitNoteMenu(function(unit, addButton)
      local subject = self:GetUnitSubject(unit, true)
      if (not subject) then return end
      addButton(subject.Type == "Player" and "Edit Note and Rating" or "Edit Note", function() self:Open(subject) end)
    end)
  end
  if (not self.QuestMenuRegistered) then
    self.QuestMenuRegistered = Api.RegisterQuestNoteMenu(function(id, addButton)
      if (IsSecret(id) or type(id) ~= "number" or id < 1) then return end
      addButton("Edit Note", function()
        self:Open(self:GetLinkedSubject(tostring(id), "Quest"))
      end)
    end)
  end
  if (not self.TooltipsRegistered) then
    self.TooltipsRegistered = true
    Api.RegisterTooltipHandler("OnTooltipSetUnit", "Unit", function(tooltip)
      if (not tooltip.GetUnit) then return end
      local _, unit = tooltip:GetUnit()
      self:AddTooltip(tooltip, self:GetUnitSubject(unit))
    end)
    Api.RegisterTooltipHandler("OnTooltipSetItem", "Item", function(tooltip, data)
      if (IsSecret(data)) then return end
      local id = data and data.id
      if (IsSecret(id)) then return end
      if (not id and tooltip.GetItem) then
        local _, link = tooltip:GetItem()
        if (not IsSecret(link) and type(link) == "string") then id = tonumber(string.match(link, "item:(%d+)")) end
      end
      if (type(id) == "number") then self:AddTooltip(tooltip, { Type = "Item", Id = id }) end
    end)
    -- Quest log tooltips are built manually, rather than as unit/item tooltip data.
    if (EventRegistry) then
      EventRegistry:RegisterCallback("QuestMapLogTitleButton.OnEnter", function(_, owner, id)
        self:AddQuestTooltip(GameTooltip, id)
      end, self)
    end
    self.HookedHyperlinkTooltips = {}
    self.HookedQuestFunctions = {}
    self.QuestTooltipSubjects = {}
  end
  for _, tooltip in ipairs({ GameTooltip, ItemRefTooltip }) do
    if (tooltip.SetHyperlink and not self.HookedHyperlinkTooltips[tooltip]) then
      self.HookedHyperlinkTooltips[tooltip] = true
      tooltip:HookScript("OnTooltipCleared", function() self.QuestTooltipSubjects[tooltip] = nil end)
      hooksecurefunc(tooltip, "SetHyperlink", function(frame, link)
        if (IsSecret(link) or type(link) ~= "string") then return end
        local id = tonumber(string.match(link, "quest:(%d+)"))
        if (id) then self:AddQuestTooltip(frame, id) end
      end)
    end
  end
  for _, name in ipairs({ "QuestMapLogTitleButton_OnEnter", "QuestLogTitleButton_OnEnter" }) do
    if (_G[name] and not self.HookedQuestFunctions[name]) then
      self.HookedQuestFunctions[name] = true
      hooksecurefunc(name, function(owner)
        self:AddQuestTooltip(GameTooltip, Api.GetQuestTooltipId(owner))
      end)
    end
  end
end

function SN:InitializePanel(panel)
  panel.SubjectFilter = "All"
  panel.SubjectDropdown = CreateFrame("Frame", nil, panel, "UIDropDownMenuTemplate")
  panel.SubjectDropdown:SetPoint("TOPLEFT", 2, -36)
  UIDropDownMenu_SetWidth(panel.SubjectDropdown, 145)
  UIDropDownMenu_SetText(panel.SubjectDropdown, "All notes")
  UIDropDownMenu_Initialize(panel.SubjectDropdown, function()
    for _, filter in ipairs(filters) do
      local info = UIDropDownMenu_CreateInfo()
      info.text, info.checked = filter.Name, panel.SubjectFilter == filter.Type
      info.func = function()
        panel.SubjectFilter = filter.Type
        UIDropDownMenu_SetText(panel.SubjectDropdown, filter.Name)
        panel:Update(true)
      end
      UIDropDownMenu_AddButton(info)
    end
  end)
  panel.SubjectButton = Button(panel, "Linked Note", 120, function() self:ShowPicker(panel) end)
  panel.SubjectButton:SetPoint("RIGHT", panel.NewButton, "LEFT", -8, 0)
  panel.ListPanel:SetPoint("TOPLEFT", 18, -86)
  panel.EditorPanel:SetPoint("TOPRIGHT", -18, -86)
  panel.RatingsPanel = CreateFrame("Frame", nil, panel.EditorPanel)
  panel.RatingsPanel:SetPoint("TOPLEFT", 14, -86)
  panel.RatingsPanel:SetSize(400, 58)
  for index, field in ipairs({ "Behavior", "Skill" }) do
    local label = panel.RatingsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", (index - 1) * 205, 0)
    label:SetText(field)
    panel[field .. "Buttons"] = {}
    for position, option in ipairs(ratingOptions) do
      local button = Button(panel.RatingsPanel, self:GetRatingText(option.Value), 34, function()
        panel["Draft" .. field] = option.Value
        panel:UpdateEditorState()
      end)
      button:SetPoint("TOPLEFT", (index - 1) * 205 + (position - 1) * 38, -20)
      button.Rating = option.Value
      button.Selection = button:CreateTexture(nil, "OVERLAY")
      button.Selection:SetAllPoints(button)
      button.Selection:SetColorTexture(1, 0.82, 0, 0.2)
      button:SetScript("OnEnter", function(owner)
        GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
        GameTooltip:SetText(field .. ": " .. option.Name, 1, 1, 1)
        GameTooltip:AddLine("Choose a rating, then Save to keep it.", 1, 1, 1, true)
        GameTooltip:Show()
      end)
      button:SetScript("OnLeave", function() GameTooltip:Hide() end)
      panel[field .. "Buttons"][position] = button
    end
  end
  self:InitializeHooks()
  self.HookFrame = CreateFrame("Frame")
  self.HookFrame:RegisterEvent("ADDON_LOADED")
  self.HookFrame:SetScript("OnEvent", function() self:InitializeHooks() end)
end

function SN:Open(subject)
  local panel = AutoBiographer_NotesWindow
  if (not panel.PanelReady) then return end
  AutoBiographer_MainWindow:ShowSection("Notes")
  panel:RequestLeaveDraft(function()
    local note = Notes.GetCollection(Controller:GetNotes(), subject)[subject.Id]
    panel.SubjectFilter = "All"
    UIDropDownMenu_SetText(panel.SubjectDropdown, "All notes")
    panel.SearchBox:SetText("")
    panel.ReturnNote, panel.ReturnSubject = panel.SelectedNote, panel.SelectedSubject
    panel:LoadNote(note, not note, subject)
    panel:Update()
    panel:RevealSelectedNote()
    panel.EditorScroll.EditBox:SetFocus()
  end)
end

function SN:ShowPicker(panel)
  if (not panel.SubjectPicker) then
    local picker = CreateFrame("Frame", nil, panel, "BasicFrameTemplate")
    panel.SubjectPicker = picker
    picker:SetSize(450, 300)
    picker:SetPoint("CENTER")
    picker:SetFrameLevel(panel:GetFrameLevel() + 15)
    picker:EnableMouse(true)
    local title = picker:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 14, -6)
    title:SetText("Note for a player, creature, item, or quest")
    Button(picker, "Current target", 150, function()
      local subject = self:GetUnitSubject("target", true)
      if (subject) then picker:Hide(); self:Open(subject)
      else picker.Error:SetText("Target a player or creature first.") end
    end):SetPoint("TOPLEFT", 24, -40)
    local help = picker:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    help:SetPoint("TOPLEFT", 24, -82)
    help:SetSize(400, 40)
    help:SetJustifyH("LEFT")
    help:SetText("Paste an item/quest link or ID below. You can also drag an item here, or use /abnote with a chat link.")
    picker.Input = CreateFrame("EditBox", nil, picker, "InputBoxTemplate")
    picker.Input:SetPoint("TOPLEFT", 30, -124)
    picker.Input:SetSize(388, 24)
    picker.Input:SetAutoFocus(false)
    picker.Input:SetMaxLetters(512)
    picker.Input:SetScript("OnEscapePressed", function() picker:Hide() end)
    picker.Input:SetScript("OnReceiveDrag", function()
      local kind, id, link = GetCursorInfo()
      if (not IsSecret(kind) and kind == "item" and not IsSecret(id)) then
        picker.Input:SetText(not IsSecret(link) and link or tostring(id))
        ClearCursor()
      end
    end)
    local function useInput(kind)
      local subject = self:GetLinkedSubject(picker.Input:GetText(), kind)
      if (subject) then picker:Hide(); self:Open(subject)
      else picker.Error:SetText("Enter a valid item or quest link, or a positive numeric ID.") end
    end
    Button(picker, "Item note", 120, function() useInput("Item") end):SetPoint("TOPLEFT", 24, -162)
    Button(picker, "Quest note", 120, function() useInput("Quest") end):SetPoint("TOPLEFT", 156, -162)
    picker.QuestDropdown = CreateFrame("Frame", nil, picker, "UIDropDownMenuTemplate")
    picker.QuestDropdown:SetPoint("TOPLEFT", 4, -192)
    UIDropDownMenu_SetWidth(picker.QuestDropdown, 280)
    UIDropDownMenu_SetText(picker.QuestDropdown, "Choose a quest from your quest log")
    UIDropDownMenu_Initialize(picker.QuestDropdown, function()
      local quests = Api.GetQuestLogEntries()
      for _, quest in ipairs(quests) do
        local info = UIDropDownMenu_CreateInfo()
        info.text, info.notCheckable = quest.Name or "Quest #" .. quest.Id, true
        info.func = function()
          picker:Hide(); self:Open({ Type = "Quest", Id = quest.Id, Name = quest.Name })
        end
        UIDropDownMenu_AddButton(info)
      end
      if (#quests == 0) then
        local info = UIDropDownMenu_CreateInfo()
        info.text, info.disabled, info.notCheckable = "No quests in your quest log", true, true
        UIDropDownMenu_AddButton(info)
      end
    end)
    picker.Error = picker:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    picker.Error:SetPoint("BOTTOMLEFT", 24, 16)
    picker.Error:SetSize(310, 35)
    picker.Error:SetJustifyH("LEFT")
    picker.Error:SetTextColor(1, 0.3, 0.3)
    Button(picker, "Cancel", 80, function() picker:Hide() end):SetPoint("BOTTOMRIGHT", -20, 16)
    picker:SetScript("OnHide", function() picker.Input:ClearFocus() end)
  end
  panel.SubjectPicker.Error:SetText("")
  panel.SubjectPicker.Input:SetText("")
  panel.SubjectPicker:Show()
end

SLASH_AUTOBIOGRAPHERNOTE1 = "/abnote"
function SlashCmdList.AUTOBIOGRAPHERNOTE(text)
  if (not AutoBiographer_NotesWindow.PanelReady) then return end
  local subject = SN:GetLinkedSubject(text)
  if (not subject and string.match(text, "^%s*$")) then subject = SN:GetUnitSubject("target", true) end
  if (subject) then SN:Open(subject)
  else
    AutoBiographer_MainWindow:ShowSection("Notes")
    SN:ShowPicker(AutoBiographer_NotesWindow)
  end
end
