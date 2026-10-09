local Controller = AutoBiographer_Controller
local HF = HelperFunctions
local panel = AutoBiographer_TodoPanel
local rowHeight = 82
local trackerRowHeight = 28
local types = { { Key = "Always", Name = "Until manually completed" }, { Key = "Inventory", Name = "Inventory count" }, { Key = "Area", Name = "In an area" } }
local operators = { { Key = "<", Name = "Less than (<)" }, { Key = "<=", Name = "At most (<=)" },
  { Key = ">", Name = "Greater than (>)" }, { Key = ">=", Name = "At least (>=)" }, { Key = "=", Name = "Equal to (=)" } }

local function Label(parent, text, x, y, font)
  local label = parent:CreateFontString(nil, "OVERLAY", font or "GameFontNormalSmall")
  label:SetPoint("TOPLEFT", x, y)
  label:SetText(text)
  label:SetJustifyH("LEFT")
  return label
end

local function Button(parent, text, width, callback)
  local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  button:SetSize(width, 24)
  button:SetText(text)
  button:SetScript("OnClick", callback)
  return button
end

local function Check(parent, text, x, y, callback)
  local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  check:SetSize(24, 24)
  check:SetPoint("TOPLEFT", x, y)
  check.Label = Label(check, text, 28, -6, "GameFontHighlightSmall")
  check.Label:ClearAllPoints()
  check.Label:SetPoint("LEFT", check, "RIGHT", 4, 0)
  check.Label:SetJustifyV("MIDDLE")
  check:SetScript("OnClick", function(self) callback(self:GetChecked() == true) end)
  return check
end

local function Dropdown(parent, choices, callback)
  local dropdown = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
  dropdown.Choices = choices
  UIDropDownMenu_Initialize(dropdown, function()
    for _, choice in ipairs(choices) do
      local key, name = choice.Key, choice.Name
      local info = UIDropDownMenu_CreateInfo()
      info.text, info.checked = name, dropdown.Value == key
      info.func = function() dropdown.Value = key; UIDropDownMenu_SetText(dropdown, name); callback(key) end
      UIDropDownMenu_AddButton(info)
    end
  end)
  return dropdown
end

local function SelectDropdown(dropdown, key)
  dropdown.Value = key
  for _, choice in ipairs(dropdown.Choices) do
    if (choice.Key == key) then UIDropDownMenu_SetText(dropdown, choice.Name); return end
  end
end

local function EditBox(parent, x, y, width, maximum, callback)
  local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
  box:SetPoint("TOPLEFT", x, y)
  box:SetSize(width, 24)
  box:SetAutoFocus(false)
  box:SetMaxLetters(maximum)
  box:SetScript("OnTextChanged", function(self) callback(self:GetText()) end)
  box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  return box
end

local function Status(entry)
  if (entry.Item.Completed) then return "|cff9d9d9dCompleted|r" end
  if (entry.Matches == nil) then return "|cffffd166Waiting for readable game data|r" end
  if (entry.Active) then return "|cff35d45cActive|r" end
  return "|cffffd166Waiting for condition|r"
end

local function StatusLine(entry)
  local item = entry.Item
  local created = item.CreatedTimestamp and HF.TimestampToDateString(item.CreatedTimestamp) or "Unknown"
  local text = Status(entry) .. " | Created: " .. created
  if (item.Completed) then
    local completed = item.CompletedTimestamp and HF.TimestampToDateString(item.CompletedTimestamp) or "Unknown"
    text = text .. " | Completed: " .. completed
  end
  return text
end

function panel:Complete(item, completed)
  if (not Todo.Contains(Controller:GetTodos(), item)) then return end
  Todo.SetCompleted(item, completed)
  self:Update()
end

function panel:DeleteSelected()
  local selected = self.Selected
  if (not selected) then return end
  AutoBiographer_ConfirmWindow.New("Delete this to-do?\nThis cannot be undone.", function(confirmed)
    if (not confirmed or self.Selected ~= selected) then return end
    Todo.Delete(Controller:GetTodos(), selected)
    self:LoadDraft(nil)
    self:Update()
  end)
end

function panel:HasFocusedTextInput()
  for _, box in ipairs({ self.TitleBox, self.ItemBox, self.CountBox, self.AreaBox }) do
    if (box:IsVisible() and box:HasFocus()) then return true end
  end
  return false
end

function panel:Initialize()
  AutioBiographer_WindowHelper:InitialzationHelper(self, 800, 650, 150, "To-do", -94)
  self.Rows, self.Entries, self.ActiveEntries, self.IncompleteEntries, self.DisplayEntries = {}, {}, {}, {}, {}
  self.View = "All"
  self.Heading = Label(self, "To-do", 18, -12, "GameFontNormalLarge")
  self.NewButton = Button(self, "New task", 100, function() self:SelectTask(nil) end)
  self.NewButton:SetPoint("TOPRIGHT", -320, -8)
  self.IncompleteButton = Button(self, "Incomplete tasks", 140, function() self:SelectView("Incomplete") end)
  self.IncompleteButton:SetPoint("TOPLEFT", 18, -45)
  self.AllButton = Button(self, "All tasks", 90, function() self:SelectView("All") end)
  self.AllButton:SetPoint("LEFT", self.IncompleteButton, "RIGHT", 6, 0)
  self.TrackerCheck = Check(self, "Show tracker", 0, 0, function(checked)
    Controller:GetTodos().ShowTracker = checked
    self:UpdateTracker()
  end)
  self.TrackerCheck:ClearAllPoints()
  self.TrackerCheck:SetPoint("TOPRIGHT", -150, -8)
  self.Empty = Label(self.ScrollFrame, "No tasks yet. Use New task to add one.", 8, -8, "GameFontDisableSmall")
  self.Message = Label(self, "", 18, -1, "GameFontHighlightSmall")
  self.Message:ClearAllPoints()
  self.Message:SetPoint("BOTTOMLEFT", 18, 15)

  self.Editor = CreateFrame("Frame", nil, self)
  self.Editor.Background = self.Editor:CreateTexture(nil, "BACKGROUND")
  self.Editor.Background:SetAllPoints()
  self.Editor.Background:SetColorTexture(0, 0, 0, 0.2)
  self.EditorTitle = Label(self.Editor, "New task", 14, -12, "GameFontNormalLarge")
  Label(self.Editor, "Task", 14, -44)
  self.TitleBox = EditBox(self.Editor, 18, -62, 300, 240, function(value) self:SetDraftField("Title", value) end)
  Label(self.Editor, "Show this task when", 14, -98)
  self.TypeDropdown = Dropdown(self.Editor, types, function(value)
    self:SetDraftField("Type", value)
    self:UpdateEditor()
  end)
  self.TypeDropdown:SetPoint("TOPLEFT", 0, -116)
  self.ItemLabel = Label(self.Editor, "Item ID or link (drag an item into the box)", 14, -155)
  self.ItemBox = EditBox(self.Editor, 18, -175, 300, 512, function(value) self:SetDraftField("ItemText", value) end)
  self.ItemBox:SetScript("OnReceiveDrag", function()
    local kind, id = GetCursorInfo()
    if (not (issecretvalue and (issecretvalue(kind) or issecretvalue(id))) and kind == "item" and type(id) == "number") then
      self.ItemBox:SetText(tostring(id)); ClearCursor()
    end
  end)
  self.ComparisonLabel = Label(self.Editor, "Comparison", 14, -211)
  self.OperatorDropdown = Dropdown(self.Editor, operators, function(value) self:SetDraftField("Operator", value) end)
  self.OperatorDropdown:SetPoint("TOPLEFT", 0, -229)
  self.CountLabel = Label(self.Editor, "Count", 222, -211)
  self.CountBox = EditBox(self.Editor, 226, -231, 76, 10, function(value) self:SetDraftField("CountText", value) end)
  self.AreaLabel = Label(self.Editor, "City, zone, or subzone (exact name)", 14, -155)
  self.AreaBox = EditBox(self.Editor, 18, -175, 300, 120, function(value)
    if (self:SetDraftField("Area", value)) then self:SetDraftField("Zone", nil) end
  end)
  self.ZoneButton = Button(self.Editor, "Use current zone / city", 230, function() self:UseCurrentArea(false) end)
  self.ZoneButton:SetPoint("TOPLEFT", 14, -211)
  self.SubZoneButton = Button(self.Editor, "Use current subzone", 230, function() self:UseCurrentArea(true) end)
  self.SubZoneButton:SetPoint("TOPLEFT", 14, -241)
  self.RecurringCheck = Check(self.Editor, "Recurring reminder", 10, -278, function(value)
    self:SetDraftField("Recurring", value)
    self:UpdateEditor()
  end)
  self.Hint = Label(self.Editor, "", 14, -314, "GameFontDisableSmall")
  self.Hint:SetWordWrap(true)
  self.Hint:SetHeight(32)
  self.MoveUpButton = Button(self.Editor, "Move up", 110, function() self:MoveSelected(-1) end)
  self.MoveUpButton:SetPoint("TOPLEFT", 14, -350)
  self.MoveDownButton = Button(self.Editor, "Move down", 110, function() self:MoveSelected(1) end)
  self.MoveDownButton:SetPoint("LEFT", self.MoveUpButton, "RIGHT", 6, 0)
  self.SaveButton = Button(self.Editor, "Save", 80, function() self:SaveDraft() end)
  self.SaveButton:SetPoint("BOTTOMLEFT", 14, 14)
  self.CancelButton = Button(self.Editor, "Cancel", 80, function() self:LoadDraft(self.Selected) end)
  self.CancelButton:SetPoint("LEFT", self.SaveButton, "RIGHT", 6, 0)
  self.DeleteButton = Button(self.Editor, "Delete", 80, function() self:DeleteSelected() end)
  self.DeleteButton:SetPoint("BOTTOMRIGHT", -14, 14)
  self.ScrollFrame.Scrollbar:SetScript("OnValueChanged", function(_, value)
    self.ScrollFrame:SetVerticalScroll(value)
    self:RenderRows()
  end)
  self:InitializeTracker()
  self:LoadDraft(nil)
  self.PanelReady = true
  self:LayoutPanel()
  self:Update()
  self:Hide()
end

function panel:InitializeTracker()
  self.Tracker = CreateFrame("Frame", "AutoBiographerTodoTracker", UIParent)
  local tracker = self.Tracker
  tracker:SetHeight(60)
  tracker:SetFrameStrata("MEDIUM")
  tracker:SetClampedToScreen(true)
  tracker:SetMovable(true)
  tracker:EnableMouse(true)
  tracker.Background = tracker:CreateTexture(nil, "BACKGROUND")
  tracker.Background:SetAllPoints()
  tracker.Background:SetColorTexture(0, 0, 0, 0.65)
  -- Use a dedicated drag surface rather than a clickable navigation button.
  tracker.Header = CreateFrame("Frame", nil, tracker)
  tracker.Header:SetHeight(24)
  tracker.Header:SetPoint("TOPLEFT", 10, -8)
  tracker.Header:EnableMouse(true)
  tracker.Header.Title = Label(tracker.Header, "AutoBiographer To-do", 0, -6, "GameFontNormal")
  tracker.Header.Title:SetWordWrap(false)
  -- Allow for font/layout rounding so the last letters are not ellipsized.
  local titleWidth = math.ceil(tracker.Header.Title:GetStringWidth()) + 8
  tracker.Header:SetWidth(titleWidth)
  tracker.Header.Title:SetWidth(titleWidth)
  tracker:SetWidth(titleWidth + 74)
  tracker.OpenButton = Button(tracker, "Open", 50, function() AutoBiographer_MainWindow:ShowSection("Todos") end)
  tracker.OpenButton:SetPoint("LEFT", tracker.Header, "RIGHT", 4, 0)
  local function StartDragging()
    tracker.IsMoving = true
    tracker:StartMoving()
  end
  local function StopDragging()
    if (not tracker.IsMoving) then return end
    tracker:StopMovingOrSizing()
    tracker.IsMoving = false
    local point, _, relativePoint, x, y = tracker:GetPoint()
    Controller:GetTodos().TrackerPosition = { Point = point, RelativePoint = relativePoint, X = x, Y = y }
  end
  tracker:RegisterForDrag("LeftButton")
  tracker:SetScript("OnDragStart", StartDragging)
  tracker:SetScript("OnDragStop", StopDragging)
  tracker:SetScript("OnHide", StopDragging)
  tracker.Header:RegisterForDrag("LeftButton")
  tracker.Header:SetScript("OnDragStart", StartDragging)
  tracker.Header:SetScript("OnDragStop", StopDragging)
  local position = Controller:GetTodos().TrackerPosition
  if (position) then tracker:SetPoint(position.Point, UIParent, position.RelativePoint, position.X, position.Y)
  else tracker:SetPoint("RIGHT", UIParent, "RIGHT", -35, 0) end
  tracker.Rows = {}
  for index = 1, 6 do
    local row = Check(tracker, "", 10, -36 - (index - 1) * trackerRowHeight, function()
      local entry = self.ActiveEntries[index]
      if (entry) then self:Complete(entry.Item, true) end
    end)
    row.Label:SetWidth(tracker:GetWidth() - 48)
    row.Label:SetHeight(28)
    row.Label:SetWordWrap(true)
    tracker.Rows[index] = row
  end
  tracker.More = Button(tracker, "", tracker:GetWidth() - 20, function() AutoBiographer_MainWindow:ShowSection("Todos") end)
  tracker.More:SetPoint("BOTTOMLEFT", 10, 8)
  tracker:Hide()
end

function panel:LayoutPanel()
  if (not self.PanelReady) then return end
  local width = self:GetWidth()
  local editorWidth = math.min(430, math.floor(width * 0.48))
  local listWidth = width - editorWidth - 54
  self.Editor:SetWidth(editorWidth)
  self.Editor:ClearAllPoints()
  self.Editor:SetPoint("TOPRIGHT", -18, -46)
  self.Editor:SetPoint("BOTTOMRIGHT", -18, 40)
  self.ScrollFrame:ClearAllPoints()
  self.ScrollFrame:SetPoint("TOPLEFT", 18, -90)
  self.ScrollFrame:SetPoint("BOTTOMRIGHT", self, "BOTTOMLEFT", listWidth + 18, 40)
  self.ScrollFrame.Scrollbar:ClearAllPoints()
  self.ScrollFrame.Scrollbar:SetPoint("TOPLEFT", self.ScrollFrame, "TOPRIGHT", 0, -16)
  self.ScrollFrame.Scrollbar:SetPoint("BOTTOMLEFT", self.ScrollFrame, "BOTTOMRIGHT", 0, 16)
  self.ScrollFrame.Content:SetWidth(listWidth)
  self.Message:SetWidth(width - 36)
  self.TitleBox:SetWidth(editorWidth - 38)
  self.ItemBox:SetWidth(editorWidth - 38)
  self.AreaBox:SetWidth(editorWidth - 38)
  self.Hint:SetWidth(editorWidth - 28)
  UIDropDownMenu_SetWidth(self.TypeDropdown, editorWidth - 46)
  UIDropDownMenu_SetWidth(self.OperatorDropdown, 170)
  self:UpdateScrollRange()
  self:RenderRows()
end

function panel:IsDirty()
  if (not self.Draft or not self.OriginalDraft) then return false end
  for _, key in ipairs({ "Title", "Type" }) do
    if (self.Draft[key] ~= self.OriginalDraft[key]) then return true end
  end
  local conditionFields = self.Draft.Type == "Inventory" and { "ItemText", "CountText", "Operator", "Recurring" } or
    self.Draft.Type == "Area" and { "Area", "Zone", "Recurring" } or {}
  for _, key in ipairs(conditionFields) do
    if (self.Draft[key] ~= self.OriginalDraft[key]) then return true end
  end
  return false
end

function panel:LoadDraft(item)
  self.Selected, self.Loading = item, true
  self.Draft = { Title = item and item.Title or "", Type = item and item.Type or "Always",
    ItemText = item and item.ItemId and tostring(item.ItemId) or "", CountText = item and item.Count and tostring(item.Count) or "10",
    Operator = item and item.Operator or "<", Area = item and item.Area or "", Zone = item and item.Zone,
    Recurring = item ~= nil and item.Type ~= "Always" and item.Recurring ~= false }
  self.OriginalDraft = {}
  for key, value in pairs(self.Draft) do self.OriginalDraft[key] = value end
  self.TitleBox:SetText(self.Draft.Title)
  self.ItemBox:SetText(self.Draft.ItemText)
  self.CountBox:SetText(self.Draft.CountText)
  self.AreaBox:SetText(self.Draft.Area)
  SelectDropdown(self.TypeDropdown, self.Draft.Type)
  SelectDropdown(self.OperatorDropdown, self.Draft.Operator)
  self.RecurringCheck:SetChecked(self.Draft.Recurring)
  self.Dirty, self.Loading = false, false
  self.Message:SetText("")
  self:UpdateEditor()
end

function panel:MoveSelected(direction)
  local selectedIndex
  for index, entry in ipairs(self.DisplayEntries) do
    if (entry.Item == self.Selected) then selectedIndex = index; break end
  end
  local neighbor = selectedIndex and self.DisplayEntries[selectedIndex + direction]
  if (neighbor and Todo.Move(Controller:GetTodos(), self.Selected, neighbor.Item)) then self:Update() end
end

function panel:QueueRefresh()
  if (not self.PanelReady or self.RefreshQueued) then return end
  self.RefreshQueued = true
  C_Timer.After(0.1, function()
    self.RefreshQueued = false
    self:Update()
  end)
end

function panel:RenderRows()
  if (not self.PanelReady) then return end
  local offset = self.ScrollFrame.Scrollbar:GetValue()
  local first = math.floor(offset / rowHeight) + 1
  local visible = math.ceil(self.ScrollFrame:GetHeight() / rowHeight) + 1
  for index = 1, math.min(visible, math.max(0, #self.DisplayEntries - first + 1)) do
    local row = self.Rows[index]
    if (not row) then
      row = CreateFrame("Button", nil, self.ScrollFrame.Content)
      row.Check = Check(row, "", 0, -8, function(value) if (row.Entry) then self:Complete(row.Entry.Item, value) end end)
      row.Title = Label(row, "", 32, -8, "GameFontHighlight")
      row.Title:SetWordWrap(false)
      row.Title:SetHeight(18)
      row.Description = Label(row, "", 32, -30, "GameFontDisableSmall")
      row.Description:SetHeight(14)
      row.Description:SetWordWrap(false)
      row.Status = Label(row, "", 32, -46, "GameFontDisableSmall")
      row.Status:SetHeight(32)
      row.Status:SetWordWrap(true)
      row.Highlight = row:CreateTexture(nil, "HIGHLIGHT")
      row.Highlight:SetAllPoints()
      row.Highlight:SetColorTexture(1, 1, 1, 0.06)
      row:SetScript("OnClick", function() if (row.Entry) then self:SelectTask(row.Entry.Item) end end)
      self.Rows[index] = row
    end
    row.Entry = self.DisplayEntries[first + index - 1]
    row:SetSize(self.ScrollFrame.Content:GetWidth(), rowHeight)
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", 0, -(first + index - 2) * rowHeight)
    row.Title:SetWidth(math.max(1, row:GetWidth() - 40))
    row.Description:SetWidth(math.max(1, row:GetWidth() - 40))
    row.Status:SetWidth(math.max(1, row:GetWidth() - 40))
    row.Title:SetText(row.Entry.Item.Title)
    local count = row.Entry.Value and " | Have " .. row.Entry.Value or ""
    row.Description:SetText("Condition: " .. Todo.Describe(row.Entry.Item) .. count)
    row.Status:SetText(StatusLine(row.Entry))
    row.Check:SetChecked(row.Entry.Item.Completed == true)
    row:Show()
  end
  for index = math.min(visible, math.max(0, #self.DisplayEntries - first + 1)) + 1, #self.Rows do self.Rows[index]:Hide() end
  self.Empty:SetShown(#self.DisplayEntries == 0)
  self.Empty:SetText(self.View == "Incomplete" and "No incomplete tasks." or "No tasks yet. Use New task to add one.")
end

function panel:SaveDraft()
  local saved, message = Todo.Save(Controller:GetTodos(), self.Selected, self.Draft)
  if (not saved) then self.Message:SetText(message); return end
  self:LoadDraft(saved)
  self:Update()
  self.Message:SetText("Task saved.")
end

function panel:SelectTask(item)
  if (item and item == self.Selected) then return end
  if (not self:IsDirty()) then self:LoadDraft(item); return end
  AutoBiographer_ConfirmWindow.New("Discard unsaved to-do changes?", function(confirmed)
    if (confirmed) then self:LoadDraft(item) end
  end)
end

function panel:SelectView(view)
  self.View = view == "Incomplete" and "Incomplete" or "All"
  self.ScrollFrame.Scrollbar:SetValue(0)
  self:Update()
end

function panel:SetDraftField(key, value)
  if (self.Loading or not self.Draft or self.Draft[key] == value) then return false end
  self.Draft[key] = value
  self.Dirty = self:IsDirty()
  self.SaveButton:SetEnabled(self.Dirty)
  return true
end

function panel:Update()
  if (not self.PanelReady) then return end
  if (AutoBiographer_EventManager.PlayerEnteringWorldHasFired) then
    self.Entries, self.ActiveEntries, self.IncompleteEntries = Todo.Update(Controller:GetTodos(), Todo.GetContext())
  end
  self.DisplayEntries = self.View == "Incomplete" and self.IncompleteEntries or self.Entries
  self.Heading:SetText("To-do | " .. #self.ActiveEntries .. " active / " .. #Controller:GetTodos().Items .. " tasks")
  self.IncompleteButton:SetEnabled(self.View ~= "Incomplete")
  self.AllButton:SetEnabled(self.View ~= "All")
  self.TrackerCheck:SetChecked(Controller:GetTodos().ShowTracker)
  self:UpdateScrollRange()
  if (self:IsVisible()) then self:RenderRows() end
  self:UpdateTracker()
  self:UpdateOrderButtons()
end

function panel:UpdateEditor()
  self.EditorTitle:SetText(self.Selected and "Edit task" or "New task")
  self.DeleteButton:SetEnabled(self.Selected ~= nil)
  self.SaveButton:SetEnabled(self.Dirty == true)
  self.Hint:SetText((self.Draft.Type == "Always" or not self.Draft.Recurring) and "This task stays completed until you uncheck it." or
    "Recurring: completing hides the task until its condition stops matching, then matches again.")
  local inventory, area = self.Draft.Type == "Inventory", self.Draft.Type == "Area"
  self.RecurringCheck:SetShown(inventory or area)
  for _, control in ipairs({ self.ItemLabel, self.ItemBox, self.ComparisonLabel, self.OperatorDropdown, self.CountLabel, self.CountBox }) do
    control:SetShown(inventory)
  end
  for _, control in ipairs({ self.AreaLabel, self.AreaBox, self.ZoneButton, self.SubZoneButton }) do control:SetShown(area) end
  self:UpdateOrderButtons()
end

function panel:UpdateOrderButtons()
  local selectedIndex
  for index, entry in ipairs(self.DisplayEntries) do
    if (entry.Item == self.Selected) then selectedIndex = index; break end
  end
  self.MoveUpButton:SetEnabled(selectedIndex ~= nil and selectedIndex > 1)
  self.MoveDownButton:SetEnabled(selectedIndex ~= nil and selectedIndex < #self.DisplayEntries)
end

function panel:UpdateScrollRange()
  local height = math.max(1, #self.DisplayEntries * rowHeight)
  self.ScrollFrame.Content:SetHeight(height)
  local maximum = math.max(0, height - self.ScrollFrame:GetHeight())
  local scrollbar = self.ScrollFrame.Scrollbar
  local offset = math.min(scrollbar:GetValue(), maximum)
  scrollbar:SetMinMaxValues(0, maximum)
  scrollbar:SetValue(offset)
  scrollbar:SetShown(maximum > 0)
end

function panel:UpdateTracker()
  if (not self.Tracker) then return end
  local count = #self.ActiveEntries
  for index, row in ipairs(self.Tracker.Rows) do
    local entry = self.ActiveEntries[index]
    row:SetShown(entry ~= nil)
    row:SetChecked(false)
    if (entry) then row.Label:SetText(entry.Item.Title) end
  end
  self.Tracker.More:SetShown(count > 6)
  self.Tracker.More:SetText((count - 6) .. " more tasks - open list")
  self.Tracker:SetHeight(36 + math.min(count, 6) * trackerRowHeight + (count > 6 and 32 or 4))
  self.Tracker:SetShown(Controller:GetTodos().ShowTracker and count > 0)
end

function panel:UseCurrentArea(subzone)
  local context = Todo.GetContext()
  local value = subzone and context.SubZone or context.Zone
  if (issecretvalue and (issecretvalue(value) or issecretvalue(context.Zone))) then return end
  if (not value or value == "") then self.Message:SetText("The current area is not available yet."); return end
  self.AreaBox:SetText(value)
  self:SetDraftField("Area", value)
  self:SetDraftField("Zone", subzone and context.Zone or nil)
  self.Message:SetText(subzone and "Subzone scoped to " .. context.Zone .. "." or "Current zone selected.")
end
