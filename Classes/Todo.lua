-- Definitions and completion state are saved; live condition results are not.
Todo = {}
local lastMatches = setmetatable({}, { __mode = "k" })

local comparisons = {
  ["<"] = function(count, threshold) return count < threshold end,
  ["<="] = function(count, threshold) return count <= threshold end,
  [">"] = function(count, threshold) return count > threshold end,
  [">="] = function(count, threshold) return count >= threshold end,
  ["="] = function(count, threshold) return count == threshold end,
}

local function Trim(text) return string.match(text or "", "^%s*(.-)%s*$") end
local function Readable(value) return not (issecretvalue and issecretvalue(value)) end

function Todo.Contains(data, item)
  for _, current in ipairs(data.Items) do if (current == item) then return true end end
  return false
end

function Todo.Delete(data, item)
  for index, current in ipairs(data.Items) do
    if (current == item) then table.remove(data.Items, index); return end
  end
end

function Todo.Describe(item)
  if (item.Type == "Inventory") then
    local name = AutoBiographer_Api.GetItemInfo(item.ItemId)
    if (not Readable(name) or not name) then name = "Item #" .. item.ItemId end
    return name .. " " .. item.Operator .. " " .. item.Count
  elseif (item.Type == "Area") then
    return "In " .. item.Area .. (item.Zone and " (" .. item.Zone .. ")" or "")
  end
  return "Until manually completed"
end

function Todo.Evaluate(item, context)
  if (item.Type == "Inventory") then
    local compare = comparisons[item.Operator]
    if (not compare or not item.ItemId or type(item.Count) ~= "number") then return nil end
    local count = context.GetItemCount(item.ItemId)
    if (not Readable(count) or type(count) ~= "number") then return nil end
    return compare(count, item.Count), count
  elseif (item.Type == "Area") then
    if (not Readable(context.Zone) or not Readable(context.SubZone) or not Readable(context.MinimapZone)) then return nil end
    if (not context.Zone or context.Zone == "") then return nil end
    local area = string.lower(Trim(item.Area))
    if (area == "") then return nil end
    if (item.Zone and string.lower(context.Zone) ~= string.lower(item.Zone)) then return false end
    return area == string.lower(context.Zone) or area == string.lower(context.SubZone or "") or
      area == string.lower(context.MinimapZone or "")
  end
  return true
end

function Todo.GetContext()
  local counts = {}
  return {
    Zone = GetRealZoneText(), SubZone = GetSubZoneText(), MinimapZone = GetMinimapZoneText(),
    GetItemCount = function(id)
      if (counts[id] == nil) then counts[id] = AutoBiographer_Api.GetInventoryItemCount(id) or false end
      if (counts[id] ~= false) then return counts[id] end
    end,
  }
end

function Todo.Move(data, item, neighbor)
  if (item == neighbor) then return false end
  local from, to
  for index, current in ipairs(data.Items) do
    if (current == item) then from = index end
    if (current == neighbor) then to = index end
  end
  if (not from or not to) then return false end
  table.remove(data.Items, from)
  table.insert(data.Items, to, item)
  return true
end

function Todo.New()
  return { Items = {}, ShowTracker = true }
end

function Todo.Save(data, selected, draft)
  local title = Trim(draft.Title)
  if (title == "") then return nil, "Enter a task name." end
  if (#title > 240) then return nil, "The task name is too long." end
  local item = { Title = title, Type = draft.Type }
  if (item.Type ~= "Always") then item.Recurring = draft.Recurring == true end
  if (item.Type == "Inventory") then
    local text = Trim(draft.ItemText)
    local id = tonumber(string.match(text, "item:(%d+)")) or tonumber(text)
    local count = tonumber(draft.CountText)
    if (not id or id <= 0 or id ~= math.floor(id)) then return nil, "Enter an item ID or paste an item link (or drag an item here)." end
    if (not comparisons[draft.Operator]) then return nil, "Choose a comparison." end
    if (not count or count < 0 or count ~= math.floor(count)) then return nil, "Enter a whole-number count of zero or more." end
    item.ItemId, item.Count, item.Operator = id, count, draft.Operator
  elseif (item.Type == "Area") then
    item.Area = Trim(draft.Area)
    if (item.Area == "") then return nil, "Enter a city, zone, or subzone name." end
    item.Zone = draft.Zone
  elseif (item.Type ~= "Always") then return nil, "Choose a condition." end
  if (selected) then
    if (not Todo.Contains(data, selected)) then return nil, "This task no longer exists." end
    -- Editing a completed task's rule starts a fresh reminder.
    local ruleChanged = selected.Type ~= item.Type or selected.ItemId ~= item.ItemId or selected.Count ~= item.Count or
      selected.Operator ~= item.Operator or selected.Area ~= item.Area or selected.Zone ~= item.Zone
    item.Completed = not ruleChanged and selected.Completed or nil
    item.CreatedTimestamp = selected.CreatedTimestamp
    item.CompletedTimestamp = item.Completed and selected.CompletedTimestamp or nil
    for key in pairs(selected) do selected[key] = nil end
    for key, value in pairs(item) do selected[key] = value end
    return selected
  end
  item.CreatedTimestamp = time()
  table.insert(data.Items, item)
  return item
end

function Todo.SetCompleted(item, completed)
  if (completed) then
    if (not item.Completed) then item.CompletedTimestamp = time() end
    item.Completed = true
  else
    item.Completed = nil
    item.CompletedTimestamp = nil
  end
end

function Todo.Update(data, context)
  local entries, active, nonCompleted = {}, {}, {}
  for _, item in ipairs(data.Items) do
    local matches, value = Todo.Evaluate(item, context)
    -- Unreadable data is unknown, not false: never re-arm on a secret value.
    -- A waiting task can also be completed. Do not immediately undo that
    -- checkbox on the same false condition; wait for a new condition cycle.
    if (item.Type ~= "Always" and item.Recurring ~= false and matches == false and lastMatches[item] ~= false) then
      Todo.SetCompleted(item, false)
    end
    if (matches ~= nil) then lastMatches[item] = matches end
    local entry = { Item = item, Matches = matches, Value = value, Active = matches == true and not item.Completed }
    entries[#entries + 1] = entry
    if (entry.Active) then active[#active + 1] = entry end
    if (not item.Completed) then nonCompleted[#nonCompleted + 1] = entry end
  end
  return entries, active, nonCompleted
end
