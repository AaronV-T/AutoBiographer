-- *** Notes ***

Notes = {}
function Notes.New()
  return {
    GenericNotes = {}, -- Dict<int, Note>
    UnitNotes = {}, -- Dict<CatalogUnitId, Note>
  }
end

-- *** Note ***

Note = {}
function Note.New(content)
  return {
    CreatedTimestamp = time(),
    LastUpdatedTimestamp = time(),
    Content = content
  }
end

function Note.Update(note, content)
	note.LastUpdatedTimestamp = time()
  note.Content = content
end