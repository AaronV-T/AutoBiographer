-- *** Notes ***

Notes = {}
function Notes.New()
  return {
    GenericNotes = {}, -- Dict<int, Note>
    ItemNotes = {}, -- Dict<ItemId, Note>
    QuestNotes = {}, -- Dict<QuestId, Note>
    UnitNotes = {}, -- Dict<CatalogUnitId, Note>
  }
end

function Notes.Contains(notes, selected)
  for _, collection in pairs({ notes.GenericNotes, notes.UnitNotes, notes.ItemNotes, notes.QuestNotes }) do
    for _, note in pairs(collection or {}) do if (note == selected) then return true end end
  end
  return false
end

function Notes.Delete(notes, selected)
  for index, note in ipairs(notes.GenericNotes) do
    if (note == selected) then table.remove(notes.GenericNotes, index); return end
  end
  for _, collection in pairs({ notes.UnitNotes, notes.ItemNotes, notes.QuestNotes }) do
    for id, note in pairs(collection or {}) do if (note == selected) then collection[id] = nil; return end end
  end
end

function Notes.GetCollection(notes, subject)
  if (not subject) then return notes.GenericNotes end
  if (subject.Type == "Player" or subject.Type == "Creature") then return notes.UnitNotes end
  if (subject.Type == "Item") then return notes.ItemNotes end
  if (subject.Type == "Quest") then return notes.QuestNotes end
end

function Notes.GetPreview(note, wordLimit)
  local words = {}
  for word in string.gmatch(note and note.Content or "", "%S+") do
    if (#words == (wordLimit or 12)) then return table.concat(words, " ") .. "..." end
    words[#words + 1] = word
  end
  return table.concat(words, " ")
end

function Notes.Initialize(notes)
  -- Additive collections: retain existing notes without requiring a data reset.
  notes.GenericNotes = notes.GenericNotes or {}
  notes.ItemNotes = notes.ItemNotes or {}
  notes.QuestNotes = notes.QuestNotes or {}
  notes.UnitNotes = notes.UnitNotes or {}
  return notes
end

function Notes.Save(notes, subject, selected, content, behavior, skill)
  local collection = Notes.GetCollection(notes, subject)
  if (not collection) then return nil end
  if (subject) then
    -- One note per identity, even if opened through more than one entry point.
    selected = collection[subject.Id]
  elseif (selected and not Notes.Contains(notes, selected)) then
    return nil
  end
  if (selected) then Note.Update(selected, content, subject and subject.Name)
  else
    selected = Note.New(content, subject and subject.Name)
    if (subject) then collection[subject.Id] = selected else table.insert(collection, selected) end
  end
  if (subject and subject.Type == "Player") then
    selected.BehaviorRating = behavior ~= 0 and behavior or nil
    selected.SkillRating = skill ~= 0 and skill or nil
  end
  return selected
end

-- *** Note ***

Note = {}
function Note.New(content, name)
  return {
    CreatedTimestamp = time(),
    LastUpdatedTimestamp = time(),
    Content = content,
    Name = name
  }
end

function Note.Update(note, content, name)
	note.LastUpdatedTimestamp = time()
  note.Content = content
  if (name ~= nil) then note.Name = name end
end
