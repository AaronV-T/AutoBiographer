local panel = AutoBiographer_CampfireTalesPanel
local Controller, Tales = AutoBiographer_Controller, CampfireTales
local savedPageSize, memoryPageSize = 5, 5

local function Label(parent, text, x, y, font)
  local label = parent:CreateFontString(nil, "OVERLAY", font or "GameFontNormalSmall")
  label:SetPoint("TOPLEFT", x, y)
  label:SetJustifyH("LEFT")
  label:SetText(text)
  return label
end

local function Button(parent, text, width, callback)
  local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  button:SetSize(width, 24)
  button:SetText(text)
  button:SetNormalFontObject("GameFontNormalSmall")
  button:SetHighlightFontObject("GameFontHighlightSmall")
  button:SetScript("OnClick", callback)
  return button
end

local function Background(frame)
  local texture = frame:CreateTexture(nil, "BACKGROUND")
  texture:SetAllPoints()
  texture:SetColorTexture(0, 0, 0, 0.2)
end

local function Row(parent, height, callback)
  local row = CreateFrame("Button", nil, parent)
  row:SetHeight(height)
  row.Label = Label(row, "", 8, -4, "GameFontHighlightSmall")
  row.Label:SetPoint("BOTTOMRIGHT", -8, 4)
  row.Label:SetJustifyV("TOP")
  row.Label:SetWordWrap(true)
  row.Selection = row:CreateTexture(nil, "BACKGROUND")
  row.Selection:SetAllPoints()
  row.Selection:SetColorTexture(0.45, 0.32, 0.12, 0.4)
  row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
  row:SetScript("OnClick", function() if (row.Entry) then callback(row.Entry) end end)
  return row
end

local function DateText(timestamp)
  return timestamp and HelperFunctions.TimestampToDateString(timestamp) or "Date unknown"
end

local function SavedRow(window, index)
  local row = Row(window.Library, 28, function(tale)
    if (tale ~= window.Selected) then window:RequestLeaveDraft(function() window:LoadDraft(tale) end) end
  end)
  row:SetPoint("TOPLEFT", 8, -36 - (index - 1) * 30)
  row.Label:SetWordWrap(false)
  row:SetScript("OnEnter", function()
    if (not row.Entry) then return end
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip:SetText(row.Entry.Title)
    GameTooltip:AddLine(row.Entry.Text, 1, 1, 1, true)
    GameTooltip:Show()
  end)
  row:SetScript("OnLeave", function() GameTooltip:Hide() end)
  return row
end

local function MemoryRow(window, index)
  local row = Row(window.MemoryBrowser, 44, function(memory) window:SelectMemory(memory) end)
  row:SetPoint("TOPLEFT", 8, -70 - (index - 1) * 48)
  row:SetScript("OnEnter", function()
    if (not row.Entry) then return end
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip:SetText(DateText(row.Entry.Timestamp))
    GameTooltip:AddLine(row.Entry.Description, 1, 1, 1, true)
    GameTooltip:Show()
  end)
  row:SetScript("OnLeave", function() GameTooltip:Hide() end)
  return row
end

function panel:Initialize()
  self.SavedPage, self.MemoryPage = 1, 1
  self.SavedRows, self.MemoryRows, self.Memories, self.FilteredMemories = {}, {}, {}, {}
  self.NewButton = Button(self, "New tale", 110, function() self:RequestLeaveDraft(function() self:LoadDraft(nil) end) end)
  self.NewButton:SetPoint("TOPLEFT", 24, -5)
  self.ReturnButton = Button(self, "Back to campfire", 140, function()
    if (not AutoBiographer_CampfireSharing:CanUseCampfire()) then return end
    AutoBiographer_CampfireSharing.Pending, AutoBiographer_CampfireSharing.AutomaticPending = true, nil
    AutoBiographer_MainWindow:Hide()
    AutoBiographer_CampfireSharing:Resume()
  end)
  self.ReturnButton:SetPoint("TOPRIGHT", -22, -5)
  self.Hint = Label(self, "Choose a recorded memory for inspiration, or write a tale of your own.", 24, -40, "GameFontDisableSmall")
  self.Hint:SetPoint("TOPRIGHT", -22, -40)

  self.Library = CreateFrame("Frame", nil, self)
  self.Library:SetPoint("TOPLEFT", 18, -68)
  self.Library:SetWidth(250)
  Background(self.Library)
  Label(self.Library, "Your saved tales", 12, -12)
  self.SavedEmpty = Label(self.Library, "No saved tales yet.\nWrite one or choose a recorded memory.", 16, -50, "GameFontDisableSmall")
  self.SavedEmpty:SetWidth(218)
  self.SavedPrevious = Button(self.Library, "<", 30, function() self.SavedPage = self.SavedPage - 1; self:RenderLibrary() end)
  self.SavedPrevious:SetPoint("BOTTOMLEFT", 8, 8)
  self.SavedNext = Button(self.Library, ">", 30, function() self.SavedPage = self.SavedPage + 1; self:RenderLibrary() end)
  self.SavedNext:SetPoint("BOTTOMRIGHT", -8, 8)
  self.SavedCount = self.Library:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  self.SavedCount:SetPoint("BOTTOM", 0, 14)

  self.MemoryBrowser = CreateFrame("Frame", nil, self)
  self.MemoryBrowser:SetPoint("TOPLEFT", 18, -310)
  self.MemoryBrowser:SetPoint("BOTTOMLEFT", 18, 44)
  self.MemoryBrowser:SetWidth(250)
  Background(self.MemoryBrowser)
  Label(self.MemoryBrowser, "Recorded memories", 12, -12)
  self.SearchBox = CreateFrame("EditBox", nil, self.MemoryBrowser, "InputBoxTemplate")
  self.SearchBox:SetPoint("TOPLEFT", 16, -36)
  self.SearchBox:SetSize(218, 24)
  self.SearchBox:SetAutoFocus(false)
  self.SearchBox:SetMaxLetters(150)
  self.SearchBox:SetScript("OnEscapePressed", function(box) box:ClearFocus() end)
  self.SearchBox:SetScript("OnTextChanged", function() self.MemoryPage = 1; self:FilterMemories() end)
  self.SearchHint = Label(self.SearchBox, "Search events or dates...", 2, -5, "GameFontDisableSmall")
  self.MemoryEmpty = Label(self.MemoryBrowser, "No recorded memories yet.", 16, -80, "GameFontDisableSmall")
  self.MemoryEmpty:SetWidth(218)
  self.MemoryPrevious = Button(self.MemoryBrowser, "<", 30, function() self.MemoryPage = self.MemoryPage - 1; self:RenderMemories() end)
  self.MemoryPrevious:SetPoint("BOTTOMLEFT", 8, 8)
  self.MemoryNext = Button(self.MemoryBrowser, ">", 30, function() self.MemoryPage = self.MemoryPage + 1; self:RenderMemories() end)
  self.MemoryNext:SetPoint("BOTTOMRIGHT", -8, 8)
  self.MemoryCount = self.MemoryBrowser:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  self.MemoryCount:SetPoint("BOTTOM", 0, 14)

  self.Editor = CreateFrame("Frame", nil, self)
  self.Editor:SetPoint("TOPLEFT", 282, -68)
  self.Editor:SetPoint("BOTTOMRIGHT", -22, 44)
  Background(self.Editor)
  Label(self.Editor, "Tale title", 14, -14)
  self.TitleBox = CreateFrame("EditBox", nil, self.Editor, "InputBoxTemplate")
  self.TitleBox:SetPoint("TOPLEFT", 20, -36)
  self.TitleBox:SetPoint("TOPRIGHT", -20, -36)
  self.TitleBox:SetHeight(24)
  self.TitleBox:SetAutoFocus(false)
  self.TitleBox:SetMaxLetters(Tales.MaxTitleBytes)
  self.TitleBox:SetScript("OnEscapePressed", function(box) box:ClearFocus() end)
  self.TitleBox:SetScript("OnTextChanged", function()
    if (not self.Loading) then self.DraftTitle = self.TitleBox:GetText(); self:UpdateEditorState() end
  end)
  Label(self.Editor, "Your story (one message in /say)", 14, -82)
  self.StoryScroll = CreateFrame("ScrollFrame", nil, self.Editor, "InputScrollFrameTemplate")
  self.StoryScroll:SetPoint("TOPLEFT", 14, -106)
  self.StoryScroll:SetPoint("TOPRIGHT", -28, -106)
  self.StoryScroll:SetHeight(118)
  self.StoryScroll.EditBox:SetFontObject("ChatFontNormal")
  self.StoryScroll.EditBox:SetAutoFocus(false)
  self.StoryScroll.EditBox:SetMaxLetters(1000)
  if (self.StoryScroll.CharCount) then self.StoryScroll.CharCount:Hide() end
  self.StoryScroll.EditBox:HookScript("OnTextChanged", function(box)
    if (not self.Loading) then self.DraftText = box:GetText(); self:UpdateEditorState() end
  end)
  self.StoryScroll.EditBox:SetScript("OnEscapePressed", function(box) box:ClearFocus() end)
  self.MemoryHeading = Label(self.Editor, "Memory suggestion", 14, 0)
  self.MemoryHeading:ClearAllPoints()
  self.MemoryHeading:SetPoint("TOPLEFT", 14, -282)
  self.MemoryPreview = self.Editor:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  self.MemoryPreview:SetPoint("TOPLEFT", 14, -306)
  self.MemoryPreview:SetPoint("TOPRIGHT", -14, -306)
  self.MemoryPreview:SetHeight(118)
  self.MemoryPreview:SetJustifyH("LEFT")
  self.MemoryPreview:SetJustifyV("TOP")
  self.MemoryPreview:SetWordWrap(true)
  self.UseMemoryButton = Button(self.Editor, "Use opening", 110, function() self:UseMemory(false) end)
  self.UseMemoryButton:SetPoint("TOPLEFT", 14, -438)
  self.NextOpeningButton = Button(self.Editor, "Next opening", 110, function()
    if (self.SelectedMemory) then self.Opening = self.Opening % #self.SelectedMemory.Suggestions + 1; self:UpdateMemoryPreview() end
  end)
  self.NextOpeningButton:SetPoint("LEFT", self.UseMemoryButton, "RIGHT", 8, 0)
  self.AppendMemoryButton = Button(self.Editor, "Append memory", 120, function() self:UseMemory(true) end)
  self.AppendMemoryButton:SetPoint("LEFT", self.NextOpeningButton, "RIGHT", 8, 0)
  self.Status = self.Editor:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  self.Status:SetPoint("TOPLEFT", 14, -238)
  self.Status:SetPoint("TOPRIGHT", -122, -238)
  self.Status:SetJustifyH("LEFT")
  self.Status:SetHeight(34)
  self.Count = self.Editor:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  self.Count:SetPoint("TOPRIGHT", -14, -240)
  self.SaveButton = Button(self.Editor, "Save tale", 100, function() self:SaveDraft() end)
  self.SaveButton:SetPoint("BOTTOMLEFT", 14, 14)
  self.DeleteButton = Button(self.Editor, "Delete", 80, function() self:DeleteTale() end)
  self.DeleteButton:SetPoint("BOTTOMRIGHT", -14, 14)

  self.Footer = self:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  self.Footer:SetPoint("BOTTOMLEFT", 18, 20)
  self.Footer:SetPoint("BOTTOMRIGHT", -230, 20)
  self.Footer:SetJustifyH("LEFT")
  self.Footer:SetWordWrap(false)
  self.Footer:SetText("Save your edits to keep them after a reload or logout.")
  self.RefreshButton = Button(self, "Refresh", 80, function() self:Update() end)
  self.RefreshButton:SetPoint("BOTTOMRIGHT", -22, 14)
  self.ClearButton = Button(self, "Clear filters", 96, function() self.SearchBox:SetText(""); self:FilterMemories() end)
  self.ClearButton:SetPoint("BOTTOMRIGHT", -112, 14)

  self.Decision = CreateFrame("Frame", nil, self, "BasicFrameTemplate")
  self.Decision:SetSize(400, 180)
  self.Decision:SetPoint("CENTER")
  self.Decision:SetFrameLevel(self:GetFrameLevel() + 30)
  self.Decision:EnableMouse(true)
  self.Decision.TitleText:SetText("Campfire Tales")
  self.Decision.Message = Label(self.Decision, "", 20, -45, "GameFontHighlight")
  self.Decision.Message:SetSize(360, 70)
  self.Decision.Accept = Button(self.Decision, "Discard", 110, function()
    local action = self.PendingAction
    self.Decision:Hide()
    if (action) then action() end
  end)
  self.Decision.Accept:SetPoint("BOTTOMLEFT", 24, 18)
  self.Decision.Cancel = Button(self.Decision, "Cancel", 110, function() self.Decision:Hide() end)
  self.Decision.Cancel:SetPoint("BOTTOMRIGHT", -24, 18)
  self.Decision.CloseButton:SetScript("OnClick", function() self.Decision:Hide() end)
  self.Decision:SetScript("OnHide", function() self.PendingAction = nil end)
  self.Decision:Hide()
  self:SetScript("OnShow", function() self:Update() end)
  self:SetScript("OnHide", function()
    self.Decision:Hide()
    for _, box in ipairs({ self.TitleBox, self.StoryScroll.EditBox, self.SearchBox }) do box:ClearFocus() end
    -- Hiding the editor retains its draft; returning to a campfire resumes choices.
    C_Timer.After(0, function() AutoBiographer_CampfireSharing:Resume() end)
  end)
  self.PanelReady = true
  self:LoadDraft(nil)
  self:LayoutPanel()
  self:Hide()
end

function panel:LayoutPanel()
  if (not self.PanelReady) then return end
  local usable = self:GetWidth() - 40
  local libraryWidth = math.max(160, math.min(260, math.floor(usable * 0.24)))
  local memoryWidth = math.max(190, math.min(320, math.floor(usable * 0.28)))
  self.Library:ClearAllPoints()
  self.Library:SetPoint("TOPLEFT", 18, -68)
  self.Library:SetPoint("BOTTOMLEFT", 18, 44)
  self.Library:SetWidth(libraryWidth)
  local memoryX = 18 + libraryWidth + 12
  self.MemoryBrowser:ClearAllPoints()
  self.MemoryBrowser:SetPoint("TOPLEFT", memoryX, -68)
  self.MemoryBrowser:SetPoint("BOTTOMLEFT", memoryX, 44)
  self.MemoryBrowser:SetWidth(memoryWidth)
  self.Editor:ClearAllPoints()
  self.Editor:SetPoint("TOPLEFT", memoryX + memoryWidth + 12, -68)
  self.Editor:SetPoint("BOTTOMRIGHT", -22, 44)
  self.SavedPageSize = math.max(1, math.floor((self.Library:GetHeight() - 76) / 30))
  self.MemoryPageSize = math.max(1, math.floor((self.MemoryBrowser:GetHeight() - 116) / 48))
  self.SavedEmpty:SetWidth(libraryWidth - 32)
  self.MemoryEmpty:SetWidth(memoryWidth - 32)
  self.SearchBox:SetWidth(memoryWidth - 32)
  self.StoryScroll.EditBox:SetWidth(math.max(1, self.Editor:GetWidth() - 52))
  local buttonWidth = math.max(1, math.floor((self.Editor:GetWidth() - 44) / 3))
  for _, button in ipairs({ self.UseMemoryButton, self.NextOpeningButton, self.AppendMemoryButton }) do button:SetWidth(buttonWidth) end
  self:RenderLibrary()
  self:RenderMemories()
end

function panel:IsDirty()
  return self.DraftTitle ~= (self.Selected and self.Selected.Title or "") or self.DraftText ~= (self.Selected and self.Selected.Text or "")
end

function panel:Confirm(message, label, action)
  self.PendingAction = action
  self.Decision.Message:SetText(message)
  self.Decision.Accept:SetText(label)
  self.Decision:Show()
end

function panel:RequestLeaveDraft(action)
  if (self:IsDirty()) then self:Confirm("Discard unsaved changes to this tale?", "Discard", action)
  else action() end
end

function panel:LoadDraft(tale)
  self.Selected, self.DraftTitle, self.DraftText = tale, tale and tale.Title or "", tale and tale.Text or ""
  self.DraftSources = {}
  for _, source in ipairs(tale and tale.Sources or {}) do table.insert(self.DraftSources, source) end
  self:SyncDraft()
  self:RenderLibrary()
end

function panel:SyncDraft()
  self.Loading = true
  self.TitleBox:SetText(self.DraftTitle)
  self.StoryScroll.EditBox:SetText(self.DraftText)
  self.StoryScroll.EditBox:SetCursorPosition(0)
  self.Loading = false
  self:UpdateEditorState()
end

function panel:UpdateEditorState()
  local valid, message = Tales.Validate(self.DraftTitle, self.DraftText)
  local bytes = #Tales.PlainText(self.DraftText)
  self.Count:SetText(bytes .. " / " .. Tales.MaxMessageBytes .. " bytes")
  self.Count:SetTextColor(bytes > Tales.MaxMessageBytes and 1 or 0.8, bytes > Tales.MaxMessageBytes and 0.2 or 0.8, bytes > Tales.MaxMessageBytes and 0.2 or 0.8)
  self.SaveButton:SetEnabled(valid ~= nil and self:IsDirty())
  self.DeleteButton:SetEnabled(self.Selected ~= nil)
  self.Status:SetText(valid and (self:IsDirty() and "Unsaved changes" or "Saved") or message)
end

function panel:RenderLibrary()
  if (not self.PanelReady) then return end
  local items = {}
  for _, tale in ipairs(Controller:GetCampfireTales().Items) do items[#items + 1] = tale end
  table.sort(items, function(a, b)
    if (a.LastUpdatedTimestamp ~= b.LastUpdatedTimestamp) then return a.LastUpdatedTimestamp > b.LastUpdatedTimestamp end
    return a.Id > b.Id
  end)
  local pageSize = self.SavedPageSize or savedPageSize
  local pages = math.max(1, math.ceil(#items / pageSize))
  self.SavedPage = math.max(1, math.min(pages, self.SavedPage))
  for index = 1, pageSize do
    if (not self.SavedRows[index]) then self.SavedRows[index] = SavedRow(self, index) end
  end
  for index, row in ipairs(self.SavedRows) do
    row:SetWidth(math.max(1, self.Library:GetWidth() - 16))
    row.Entry = index <= pageSize and items[(self.SavedPage - 1) * pageSize + index] or nil
    row:SetShown(row.Entry ~= nil)
    if (row.Entry) then row.Label:SetText(row.Entry.Title); row.Selection:SetShown(row.Entry == self.Selected) end
  end
  self.SavedEmpty:SetShown(#items == 0)
  self.SavedCount:SetText(self.SavedPage .. " / " .. pages .. " | " .. #items .. " tales")
  self.SavedPrevious:SetEnabled(self.SavedPage > 1)
  self.SavedNext:SetEnabled(self.SavedPage < pages)
end

function panel:FilterMemories()
  if (not self.PanelReady) then return end
  local search = string.lower(self.SearchBox:GetText() or "")
  self.SearchHint:SetShown(search == "")
  self.FilteredMemories = {}
  for _, memory in ipairs(self.Memories) do
    if (search == "" or memory.SearchText:find(search, 1, true)) then table.insert(self.FilteredMemories, memory) end
  end
  self:RenderMemories()
end

function panel:RenderMemories()
  local pageSize = self.MemoryPageSize or memoryPageSize
  local pages = math.max(1, math.ceil(#self.FilteredMemories / pageSize))
  self.MemoryPage = math.max(1, math.min(pages, self.MemoryPage))
  for index = 1, pageSize do
    if (not self.MemoryRows[index]) then self.MemoryRows[index] = MemoryRow(self, index) end
  end
  for index, row in ipairs(self.MemoryRows) do
    row:SetWidth(math.max(1, self.MemoryBrowser:GetWidth() - 16))
    row.Entry = index <= pageSize and self.FilteredMemories[(self.MemoryPage - 1) * pageSize + index] or nil
    row:SetShown(row.Entry ~= nil)
    if (row.Entry) then
      row.Label:SetText(DateText(row.Entry.Timestamp) .. "\n" .. row.Entry.Description)
      row.Selection:SetShown(row.Entry == self.SelectedMemory)
    end
  end
  self.MemoryEmpty:SetShown(#self.FilteredMemories == 0)
  self.MemoryEmpty:SetText(#self.Memories == 0 and "No recorded memories yet. You can still write your own story." or "No matching memories.")
  self.MemoryCount:SetText(self.MemoryPage .. " / " .. pages .. " | " .. #self.FilteredMemories .. " events")
  self.MemoryPrevious:SetEnabled(self.MemoryPage > 1)
  self.MemoryNext:SetEnabled(self.MemoryPage < pages)
end

function panel:SelectMemory(memory)
  self.SelectedMemory, self.Opening = memory, 1
  self:UpdateMemoryPreview()
  self:RenderMemories()
end

function panel:UpdateMemoryPreview()
  local memory = self.SelectedMemory
  self.MemoryPreview:SetText(memory and (DateText(memory.Timestamp) .. " | " .. memory.Description .. "\n\n" .. memory.Suggestions[self.Opening]) or
    "Choose an event from Recorded memories. Browse the suggested openings, then use or append one and edit it freely.")
  for _, button in ipairs({ self.UseMemoryButton, self.NextOpeningButton, self.AppendMemoryButton }) do button:SetEnabled(memory ~= nil) end
end

function panel:UseMemory(append)
  local memory = self.SelectedMemory
  if (not memory) then return end
  local function Apply()
    local text = memory.Suggestions[self.Opening]
    if (append and self.DraftText:find("%S")) then self.DraftText = self.DraftText .. " " .. text
    else self.DraftText, self.DraftSources = text, {} end
    if (self.DraftTitle == "") then self.DraftTitle = memory.Title end
    self.DraftSources[#self.DraftSources + 1] = memory
    self:SyncDraft()
    self.StoryScroll.EditBox:SetFocus()
  end
  if (not append and self.DraftText:find("%S")) then self:Confirm("Replace the current story text with this opening?", "Replace", Apply)
  else Apply() end
end

function panel:SaveDraft()
  local saved, message = Tales.Save(Controller:GetCampfireTales(), self.Selected, self.DraftTitle, self.DraftText, self.DraftSources)
  if (not saved) then self.Status:SetText(message); return false end
  self.SavedPage = 1
  self:LoadDraft(saved)
  AutoBiographer_CampfireSharing.PersonalOffers = nil
  return true
end

function panel:DeleteTale()
  local tale = self.Selected
  if (not tale) then return end
  self:Confirm("Delete this saved tale? Unsaved edits will also be discarded.", "Delete", function()
    Tales.Delete(Controller:GetCampfireTales(), tale)
    self:LoadDraft(nil)
    AutoBiographer_CampfireSharing.PersonalOffers = nil
  end)
end

function panel:Update()
  if (not self.PanelReady) then return end
  self.Memories = Tales.GetMemories(Controller:GetEvents(), Controller.CharacterData.Catalogs, AutoBiographer_Databases)
  local mapNames = {}
  for _, memory in ipairs(self.Memories) do
    local event = Controller:GetEvents()[memory.EventIndex]
    local location = event.ZoneName or event.SubZoneName or ""
    local coordinates = Event.GetMapCoordinates(event)
    if (location == "" and coordinates and coordinates.MapId and C_Map and C_Map.GetMapInfo) then
      if (not mapNames[coordinates.MapId]) then
        local ok, info = pcall(C_Map.GetMapInfo, coordinates.MapId)
        mapNames[coordinates.MapId] = ok and info and info.name or ""
      end
      location = mapNames[coordinates.MapId]
    end
    memory.SearchText = string.lower(memory.Title .. " " .. memory.Category .. " " .. memory.Description .. " " .. location .. " " .. DateText(memory.Timestamp))
  end
  self:RenderLibrary()
  self:FilterMemories()
  self:UpdateMemoryPreview()
  self:UpdateEditorState()
  self.ReturnButton:SetEnabled(AutoBiographer_CampfireSharing:CanUseCampfire())
end

function panel:HasFocusedTextInput()
  return self.TitleBox:HasFocus() or self.StoryScroll.EditBox:HasFocus() or self.SearchBox:HasFocus()
end

function panel:HandleKeyDown(key)
  if (key == "ESCAPE" and self.Decision:IsShown()) then self.Decision:Hide(); return true end
  return false
end
