local Controller = AutoBiographer_Controller
local HF = HelperFunctions
local noteLimit = 1000
local rowHeight = 76
local sortOrders = {
  { Name = "Recently updated", Key = "Updated" },
  { Name = "Recently created", Key = "Created" },
  { Name = "Alphabetical", Key = "Alphabetical" },
}

local function CountCharacters(text)
  -- Count UTF-8 leading bytes, not continuation bytes.
  local _, count = string.gsub(text, "[^\128-\191]", "")
  return count
end

local function CreateButton(parent, text, width, onClick)
  local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  button:SetSize(width, 24)
  button:SetText(text)
  button:SetNormalFontObject("GameFontNormalSmall")
  button:SetHighlightFontObject("GameFontHighlightSmall")
  button:SetScript("OnClick", onClick)
  return button
end

local function GetNoteTitle(content)
  for line in string.gmatch(content or "", "[^\r\n]+") do
    local title = string.match(line, "^%s*(.-)%s*$")
    if (title ~= "") then return title end
  end
  return "Untitled note"
end

local function GetNotePreview(content)
  for _, line, ending in string.gmatch(content or "", "()([^\r\n]+)()") do
    if (string.find(line, "%S")) then
      local preview = string.gsub(string.sub(content, ending), "%s+", " ")
      return string.match(preview, "^%s*(.-)%s*$")
    end
  end
  return ""
end

local function ContainsNote(notes, selected)
  for _, note in ipairs(notes) do if (note == selected) then return true end end
  return false
end

function AutoBiographer_NotesWindow:CanSaveDraft()
  return self.HasEditor == true and self:IsDirty() and CountCharacters(self.DraftText) <= noteLimit and
    string.find(self.DraftText, "%S") ~= nil
end

function AutoBiographer_NotesWindow:CancelEdit()
  local original = self.SelectedNote or self.ReturnNote
  self:RequestLeaveDraft(function()
    self.ReturnNote = nil
    if (original and ContainsNote(Controller:GetNotes().GenericNotes, original)) then self:LoadNote(original)
    else self:LoadNote(nil) end
  end)
end

function AutoBiographer_NotesWindow:ClosePrompt()
  self.DecisionPrompt:Hide()
  self.PendingAction, self.PromptMode = nil, nil
end

function AutoBiographer_NotesWindow:DeleteNote()
  local target = self.SelectedNote
  if (not target) then return end
  local message = "Delete this note? This cannot be undone."
  if (self:IsDirty()) then message = message .. " Unsaved edits will also be discarded." end
  self:ShowPrompt("Delete", message .. "\n\n" .. GetNoteTitle(target.Content), function()
    local notes = Controller:GetNotes().GenericNotes
    for index, note in ipairs(notes) do
      if (note == target) then table.remove(notes, index); break end
    end
    self.ReturnNote = nil
    self:LoadNote(nil)
    self:Update()
    if (self.NoteEntries[1]) then self:LoadNote(self.NoteEntries[1].Note) end
  end)
end

function AutoBiographer_NotesWindow:HandleKeyDown(key)
  if (key == "ESCAPE" and self.DecisionPrompt:IsShown()) then
    self:ClosePrompt()
    return true
  end
  return false
end

function AutoBiographer_NotesWindow:HasFocusedTextInput()
  return self.EditorScroll.EditBox:HasFocus() or self.SearchBox:HasFocus()
end

function AutoBiographer_NotesWindow:Initialize()
  AutioBiographer_WindowHelper:InitialzationHelper(self, 750, 585, 150, "Notes", -60)
  self.NoteEntries = {}
  self.RowPool = {}
  self.SearchGeneration = 0
  self.OriginalText, self.DraftText = "", ""
  self.SortOrder = AutoBiographer_Settings.NotesSortOrder or "Updated"
  if (self.SortOrder ~= "Updated" and self.SortOrder ~= "Created" and self.SortOrder ~= "Alphabetical") then self.SortOrder = "Updated" end

  self.SearchBox = CreateFrame("EditBox", nil, self, "InputBoxTemplate")
  self.SearchBox:SetPoint("TOPLEFT", 24, -14)
  self.SearchBox:SetSize(300, 24)
  self.SearchBox:SetAutoFocus(false)
  self.SearchBox:SetMaxLetters(200)
  self.SearchHint = self.SearchBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  self.SearchHint:SetPoint("LEFT", 2, 0)
  self.SearchHint:SetText("Search notes...")
  self.SearchBox:SetScript("OnEscapePressed", function(box) box:ClearFocus() end)
  self.SearchBox:SetScript("OnEnterPressed", function(box) box:ClearFocus(); self:Update(true) end)
  self.SearchBox:SetScript("OnTextChanged", function(box)
    self.SearchHint:SetShown(box:GetText() == "")
    self.SearchGeneration = self.SearchGeneration + 1
    local generation = self.SearchGeneration
    C_Timer.After(0.15, function()
      if (generation == self.SearchGeneration and self:IsVisible()) then self:Update(true) end
    end)
  end)
  self.SearchBox:SetText("")
  self.SortDropdown = CreateFrame("Frame", nil, self, "UIDropDownMenuTemplate")
  self.SortDropdown:SetPoint("TOPLEFT", 330, -4)
  UIDropDownMenu_SetWidth(self.SortDropdown, 170)
  UIDropDownMenu_Initialize(self.SortDropdown, function()
    for _, order in ipairs(sortOrders) do
      local info = UIDropDownMenu_CreateInfo()
      info.text = order.Name
      info.checked = self.SortOrder == order.Key
      info.func = function()
        self.SortOrder = order.Key
        AutoBiographer_Settings.NotesSortOrder = order.Key
        self:Update(true)
      end
      UIDropDownMenu_AddButton(info)
    end
  end)
  self.NewButton = CreateButton(self, "New Note", 100, function() self:NewNote() end)
  self.NewButton:SetPoint("TOPRIGHT", -22, -14)

  self.ListPanel = CreateFrame("Frame", nil, self)
  self.ListPanel:SetPoint("TOPLEFT", 18, -60)
  self.ListPanel:SetPoint("BOTTOMLEFT", 18, 44)
  local listBackground = self.ListPanel:CreateTexture(nil, "BACKGROUND")
  listBackground:SetAllPoints(self.ListPanel)
  listBackground:SetColorTexture(0, 0, 0, 0.15)
  self.ScrollFrame:ClearAllPoints()
  self.ScrollFrame:SetPoint("TOPLEFT", self.ListPanel, "TOPLEFT", 10, -10)
  self.ScrollFrame:SetPoint("BOTTOMRIGHT", self.ListPanel, "BOTTOMRIGHT", -30, 10)
  self.ScrollFrame.Scrollbar:ClearAllPoints()
  self.ScrollFrame.Scrollbar:SetPoint("TOPRIGHT", self.ListPanel, "TOPRIGHT", -10, -15)
  self.ScrollFrame.Scrollbar:SetPoint("BOTTOMRIGHT", self.ListPanel, "BOTTOMRIGHT", -10, 15)
  self.ScrollFrame.Scrollbar.scrollStep = rowHeight
  self.ScrollFrame.Scrollbar:SetScript("OnValueChanged", function(_, value)
    self.ScrollFrame:SetVerticalScroll(value)
    self:RenderNoteRows()
  end)
  self.ScrollFrame:EnableMouseWheel(true)
  self.ScrollFrame:SetScript("OnMouseWheel", function(_, delta) self:ScrollNotes(delta) end)
  self:SetScript("OnMouseWheel", nil)
  self.EmptyListMessage = self.ListPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  self.EmptyListMessage:SetPoint("CENTER")
  self.EmptyListMessage:SetJustifyH("CENTER")
  self.EmptyListMessage:SetWordWrap(true)

  self.EditorPanel = CreateFrame("Frame", nil, self)
  self.EditorPanel:SetPoint("TOPRIGHT", -18, -60)
  self.EditorPanel:SetPoint("BOTTOMRIGHT", -18, 44)
  local editorBackground = self.EditorPanel:CreateTexture(nil, "BACKGROUND")
  editorBackground:SetAllPoints(self.EditorPanel)
  editorBackground:SetColorTexture(0, 0, 0, 0.15)
  self.NoteTitle = self.EditorPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  self.NoteTitle:SetPoint("TOPLEFT", 14, -14)
  self.NoteTitle:SetHeight(22)
  self.NoteTitle:SetJustifyH("LEFT")
  self.NoteTitle:SetWordWrap(false)
  self.CreatedLabel = self.EditorPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  self.CreatedLabel:SetPoint("TOPLEFT", 14, -44)
  self.CreatedLabel:SetJustifyH("LEFT")
  self.UpdatedLabel = self.EditorPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  self.UpdatedLabel:SetPoint("TOPLEFT", 14, -62)
  self.UpdatedLabel:SetJustifyH("LEFT")

  self.EditorScroll = CreateFrame("ScrollFrame", nil, self.EditorPanel, "InputScrollFrameTemplate")
  self.EditorScroll:ClearAllPoints()
  self.EditorScroll:SetPoint("TOPLEFT", 14, -94)
  self.EditorScroll:SetPoint("BOTTOMRIGHT", -28, 78)
  self.EditorScroll.EditBox:SetFontObject("ChatFontNormal")
  self.EditorScroll.EditBox:SetAutoFocus(false)
  self.EditorScroll.EditBox:SetMaxLetters(noteLimit)
  if (self.EditorScroll.CharCount) then self.EditorScroll.CharCount:Hide() end
  self.EditorScroll.EditBox:HookScript("OnTextChanged", function(box)
    if (self.EditorLoading) then return end
    self.DraftText = box:GetText()
    self:UpdateEditorState()
  end)
  self.EditorScroll.EditBox:SetScript("OnEscapePressed", function(box) box:ClearFocus() end)

  self.EditorPlaceholder = self.EditorPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  self.EditorPlaceholder:SetPoint("CENTER")
  self.EditorPlaceholder:SetJustifyH("CENTER")
  self.EditorPlaceholder:SetWordWrap(true)
  self.EditorPlaceholder:SetText("Select a note to read or edit it.\n\nUse New Note to start writing.")
  self.DraftStatus = self.EditorPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  self.DraftStatus:SetPoint("BOTTOMLEFT", 14, 50)
  self.CharacterCount = self.EditorPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  self.CharacterCount:SetPoint("BOTTOMRIGHT", -14, 50)
  self.SaveButton = CreateButton(self.EditorPanel, "Save", 80, function() self:SaveDraft() end)
  self.SaveButton:SetPoint("BOTTOMLEFT", 14, 14)
  self.CancelButton = CreateButton(self.EditorPanel, "Cancel", 80, function() self:CancelEdit() end)
  self.CancelButton:SetPoint("LEFT", self.SaveButton, "RIGHT", 8, 0)
  self.DeleteButton = CreateButton(self.EditorPanel, "Delete", 80, function() self:DeleteNote() end)
  self.DeleteButton:SetPoint("BOTTOMRIGHT", -14, 14)
  self.SaveButton:SetScript("OnEnter", function(button)
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:SetText("Save note", 1, 0.82, 0)
    GameTooltip:AddLine("Drafts survive closing this window, but not a reload or logout. Save to keep your changes.", 1, 1, 1, true)
    GameTooltip:Show()
  end)
  self.SaveButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

  self.Footer = self:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  self.Footer:SetPoint("BOTTOMLEFT", 18, 20)
  self.Footer:SetJustifyH("LEFT")
  self.ClearSearchButton = CreateButton(self, "Clear search", 96, function() self.SearchBox:SetText(""); self:Update(true) end)
  self.ClearSearchButton:SetPoint("BOTTOMRIGHT", -22, 14)

  self.DecisionPrompt = CreateFrame("Frame", nil, self, "BasicFrameTemplate")
  self.DecisionPrompt:SetPoint("CENTER")
  self.DecisionPrompt:SetSize(430, 210)
  self.DecisionPrompt:SetFrameLevel(self:GetFrameLevel() + 20)
  self.DecisionPrompt:EnableMouse(true)
  self.DecisionPrompt.Title = self.DecisionPrompt:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  self.DecisionPrompt.Title:SetPoint("LEFT", self.DecisionPrompt.TitleBg, "LEFT", 8, 0)
  self.DecisionPrompt.Title:SetText("AutoBiographer Notes")
  self.DecisionPrompt.Message = self.DecisionPrompt:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  self.DecisionPrompt.Message:SetPoint("TOPLEFT", 24, -50)
  self.DecisionPrompt.Message:SetSize(382, 100)
  self.DecisionPrompt.Message:SetJustifyH("LEFT")
  self.DecisionPrompt.Message:SetJustifyV("TOP")
  self.DecisionPrompt.Message:SetWordWrap(true)
  self.DecisionPrompt.Primary = CreateButton(self.DecisionPrompt, "Save", 110, function()
    local action = self.PendingAction
    if (self.PromptMode == "Unsaved" and not self:SaveDraft()) then return end
    self:ClosePrompt()
    if (action) then action() end
  end)
  self.DecisionPrompt.Primary:SetPoint("BOTTOMLEFT", 24, 22)
  self.DecisionPrompt.Discard = CreateButton(self.DecisionPrompt, "Discard", 110, function()
    local action = self.PendingAction
    self:ClosePrompt()
    if (action) then action() end
  end)
  self.DecisionPrompt.Discard:SetPoint("BOTTOM", 0, 22)
  self.DecisionPrompt.Cancel = CreateButton(self.DecisionPrompt, "Cancel", 110, function() self:ClosePrompt() end)
  self.DecisionPrompt.Cancel:SetPoint("BOTTOMRIGHT", -24, 22)
  self.DecisionPrompt:SetScript("OnHide", function() self.PendingAction, self.PromptMode = nil, nil end)
  self.DecisionPrompt:Hide()
  self:SetScript("OnHide", function()
    self:ClosePrompt()
    self.EditorScroll.EditBox:ClearFocus()
    self.SearchBox:ClearFocus()
    -- Leave the draft and selection in memory; never save or discard on Hide.
  end)
  self.PanelReady = true
  self:LayoutPanel()
  self:UpdateEditorState()
  self:Hide()
  return self
end

function AutoBiographer_NotesWindow:IsDirty()
  return self.HasEditor == true and self.DraftText ~= self.OriginalText
end

function AutoBiographer_NotesWindow:LayoutPanel()
  if (not self.PanelReady) then return end
  local width = self:GetWidth()
  local listWidth = math.max(250, math.min(340, width * 0.3))
  local editorWidth = width - listWidth - 56
  self.ListPanel:SetWidth(listWidth)
  self.ScrollFrame.Content:SetWidth(listWidth - 40)
  self.EmptyListMessage:SetWidth(listWidth - 36)
  self.EditorPanel:SetWidth(editorWidth)
  self.NoteTitle:SetWidth(editorWidth - 28)
  self.CreatedLabel:SetWidth(editorWidth - 28)
  self.UpdatedLabel:SetWidth(editorWidth - 28)
  self.EditorPlaceholder:SetWidth(editorWidth - 50)
  self.EditorScroll.EditBox:SetWidth(math.max(1, editorWidth - 52))
  self.Footer:SetWidth(width - 160)
  self:UpdateListScrollRange()
  self:RenderNoteRows()
end

function AutoBiographer_NotesWindow:LoadNote(note, isNew)
  self.EditorInitialized = true
  self.SelectedNote = note
  self.IsNewDraft = isNew == true
  self.HasEditor = note ~= nil or self.IsNewDraft
  self.OriginalText = note and note.Content or ""
  self.DraftText = self.OriginalText
  self.EditorLoading = true
  -- Legacy notes longer than the current limit must be readable without truncation.
  self.EditorScroll.EditBox:SetMaxLetters(math.max(noteLimit, string.len(self.DraftText)))
  self.EditorScroll.EditBox:SetText(self.DraftText)
  self.EditorScroll.EditBox:SetCursorPosition(0)
  self.EditorScroll.EditBox:ClearFocus()
  self.EditorScroll:SetVerticalScroll(0)
  self.EditorLoading = false
  self:UpdateEditorState()
  self:RenderNoteRows()
end

function AutoBiographer_NotesWindow:NewNote()
  self:RequestLeaveDraft(function()
    self.ReturnNote = self.SelectedNote or self.ReturnNote
    self:LoadNote(nil, true)
    self.EditorScroll.EditBox:SetFocus()
  end)
end

function AutoBiographer_NotesWindow:RenderNoteRows()
  if (not self.PanelReady) then return end
  local scroll = self.ScrollFrame.Scrollbar:GetValue()
  local first = math.floor(scroll / rowHeight) + 1
  local last = math.min(#self.NoteEntries, math.ceil((scroll + self.ScrollFrame:GetHeight()) / rowHeight) + 1)
  local count = 0
  for index = first, last do
    count = count + 1
    local row = self.RowPool[count]
    if (not row) then
      row = CreateFrame("Button", nil, self.ScrollFrame.Content)
      row.Background = row:CreateTexture(nil, "BACKGROUND")
      row.Background:SetAllPoints(row)
      row.Selection = row:CreateTexture(nil, "ARTWORK")
      row.Selection:SetAllPoints(row)
      row.Selection:SetColorTexture(1, 0.82, 0, 0.1)
      row.Highlight = row:CreateTexture(nil, "HIGHLIGHT")
      row.Highlight:SetAllPoints(row)
      row.Highlight:SetColorTexture(1, 1, 1, 0.06)
      row.Title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      row.Title:SetPoint("TOPLEFT", 8, -9)
      row.Title:SetHeight(18)
      row.Title:SetJustifyH("LEFT")
      row.Title:SetWordWrap(false)
      row.Preview = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      row.Preview:SetPoint("TOPLEFT", 8, -31)
      row.Preview:SetHeight(32)
      row.Preview:SetJustifyH("LEFT")
      row.Preview:SetJustifyV("TOP")
      row.Preview:SetWordWrap(true)
      row:SetScript("OnClick", function(button) self:SelectNote(button.Entry.Note) end)
      row:EnableMouseWheel(true)
      row:SetScript("OnMouseWheel", function(_, delta) self:ScrollNotes(delta) end)
      self.RowPool[count] = row
    end
    row.Entry = self.NoteEntries[index]
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", 0, -(index - 1) * rowHeight)
    row:SetSize(self.ScrollFrame.Content:GetWidth(), rowHeight - 4)
    row.Background:SetColorTexture(1, 1, 1, index % 2 == 0 and 0.025 or 0)
    row.Selection:SetShown(row.Entry.Note == self.SelectedNote)
    row.Title:SetWidth(row:GetWidth() - 16)
    row.Title:SetText(row.Entry.Title)
    row.Preview:SetWidth(row:GetWidth() - 16)
    row.Preview:SetText(row.Entry.Preview)
    row:Show()
  end
  for index = count + 1, #self.RowPool do self.RowPool[index]:Hide() end
end

function AutoBiographer_NotesWindow:RequestLeaveDraft(action)
  if (self.DecisionPrompt:IsShown()) then return end
  if (self:IsDirty()) then self:ShowPrompt("Unsaved", "Save your changes before continuing?", action)
  else action() end
end

function AutoBiographer_NotesWindow:RevealSelectedNote()
  for index, entry in ipairs(self.NoteEntries) do
    if (entry.Note == self.SelectedNote) then
      local top = (index - 1) * rowHeight
      local scroll = self.ScrollFrame.Scrollbar:GetValue()
      local height = self.ScrollFrame:GetHeight()
      if (top < scroll) then self.ScrollFrame.Scrollbar:SetValue(top)
      elseif (top + rowHeight > scroll + height) then
        local _, maximum = self.ScrollFrame.Scrollbar:GetMinMaxValues()
        self.ScrollFrame.Scrollbar:SetValue(math.min(maximum, top + rowHeight - height))
      end
      break
    end
  end
end

function AutoBiographer_NotesWindow:SaveDraft()
  if (not self:CanSaveDraft()) then return false end
  local notes = Controller:GetNotes().GenericNotes
  if (self.IsNewDraft) then
    self.SelectedNote = Note.New(self.DraftText)
    table.insert(notes, self.SelectedNote)
    self.IsNewDraft = false
  elseif (ContainsNote(notes, self.SelectedNote)) then
    Note.Update(self.SelectedNote, self.DraftText)
  else
    return false
  end
  self.OriginalText = self.DraftText
  self.ReturnNote = nil
  self:UpdateEditorState()
  self:Update()
  self:RevealSelectedNote()
  return true
end

function AutoBiographer_NotesWindow:ScrollNotes(delta)
  local _, maximum = self.ScrollFrame.Scrollbar:GetMinMaxValues()
  self.ScrollFrame.Scrollbar:SetValue(math.max(0, math.min(maximum,
    self.ScrollFrame.Scrollbar:GetValue() - delta * rowHeight)))
end

function AutoBiographer_NotesWindow:SelectNote(note)
  if (note == self.SelectedNote) then return end
  self:RequestLeaveDraft(function()
    self.ReturnNote = nil
    if (ContainsNote(Controller:GetNotes().GenericNotes, note)) then self:LoadNote(note) end
  end)
end

function AutoBiographer_NotesWindow:ShowPrompt(mode, message, action)
  if (self.DecisionPrompt:IsShown()) then return end
  self.PromptMode, self.PendingAction = mode, action
  self.DecisionPrompt.Message:SetText(message)
  self.DecisionPrompt.Primary:SetText(mode == "Unsaved" and "Save" or "Delete")
  self.DecisionPrompt.Primary:SetEnabled(mode ~= "Unsaved" or self:CanSaveDraft())
  self.DecisionPrompt.Discard:SetShown(mode == "Unsaved")
  self.EditorScroll.EditBox:ClearFocus()
  self.DecisionPrompt:Show()
end

function AutoBiographer_NotesWindow:Update(resetScroll)
  if (not self.PanelReady) then return end
  local notes = Controller:GetNotes().GenericNotes
  local search = string.lower(self.SearchBox:GetText())
  local entries = {}
  for index, note in ipairs(notes) do
    local content = note.Content or ""
    if (search == "" or string.find(string.lower(content), search, 1, true)) then
      table.insert(entries, { Note = note, Index = index, Title = GetNoteTitle(content), Preview = GetNotePreview(content) })
    end
  end
  table.sort(entries, function(left, right)
    if (self.SortOrder == "Alphabetical") then
      local a, b = string.lower(left.Title), string.lower(right.Title)
      if (a ~= b) then return a < b end
    else
      local field = self.SortOrder == "Created" and "CreatedTimestamp" or "LastUpdatedTimestamp"
      local a, b = left.Note[field] or 0, right.Note[field] or 0
      if (a ~= b) then return a > b end
    end
    return left.Index < right.Index
  end)
  self.NoteEntries = entries
  if (self.SelectedNote and not ContainsNote(notes, self.SelectedNote)) then
    if (self:IsDirty()) then self.SelectedNote = nil; self.IsNewDraft = true; self.OriginalText = ""
    else self:LoadNote(nil) end
  end
  if (not self.EditorInitialized) then self:LoadNote(entries[1] and entries[1].Note) end
  if (resetScroll) then self.ScrollFrame.Scrollbar:SetValue(0) end
  self:UpdateListScrollRange()
  self:RenderNoteRows()
  self:UpdateEditorState()
  self.EmptyListMessage:SetShown(#entries == 0)
  self.EmptyListMessage:SetText(#notes == 0 and "Create your first note\nwith New Note." or "No notes match\nyour search.")
  self.Footer:SetText(HF.CommaValue(#entries) .. " of " .. HF.CommaValue(#notes) .. " notes")
  for _, order in ipairs(sortOrders) do
    if (order.Key == self.SortOrder) then UIDropDownMenu_SetText(self.SortDropdown, order.Name); break end
  end
end

function AutoBiographer_NotesWindow:UpdateEditorState()
  local active = self.HasEditor == true
  local dirty = self:IsDirty()
  self.EditorScroll:SetShown(active)
  self.EditorPlaceholder:SetShown(not active)
  self.NoteTitle:SetText(active and (self.IsNewDraft and self.DraftText == "" and "New note" or GetNoteTitle(self.DraftText)) or "Notes")
  self.CreatedLabel:SetText(self.SelectedNote and "Created: " .. HF.TimestampToDateString(self.SelectedNote.CreatedTimestamp) or active and "New note — not saved" or "")
  self.UpdatedLabel:SetText(self.SelectedNote and "Updated: " .. HF.TimestampToDateString(self.SelectedNote.LastUpdatedTimestamp) or "")
  local count = CountCharacters(self.DraftText)
  self.CharacterCount:SetText(active and count .. " / " .. noteLimit or "")
  self.CharacterCount:SetTextColor(count > noteLimit and 1 or 0.8, count > noteLimit and 0.2 or 0.8, count > noteLimit and 0.2 or 0.8)
  self.DraftStatus:SetText(not active and "" or count > noteLimit and "Over character limit" or dirty and "Unsaved changes" or self.IsNewDraft and "New draft" or "Saved")
  self.SaveButton:SetEnabled(self:CanSaveDraft())
  self.CancelButton:SetEnabled(active and (dirty or self.IsNewDraft))
  self.DeleteButton:SetEnabled(self.SelectedNote ~= nil)
  if (self.PromptMode == "Unsaved") then self.DecisionPrompt.Primary:SetEnabled(self:CanSaveDraft()) end
end

function AutoBiographer_NotesWindow:UpdateListScrollRange()
  local height = math.max(1, #self.NoteEntries * rowHeight)
  self.ScrollFrame.Content:SetHeight(height)
  local maximum = math.max(0, height - self.ScrollFrame:GetHeight())
  self.ScrollFrame.Scrollbar:SetMinMaxValues(0, maximum)
  self.ScrollFrame.Scrollbar:SetValue(math.min(self.ScrollFrame.Scrollbar:GetValue(), maximum))
  self.ScrollFrame.Scrollbar:SetShown(maximum > 0)
end
