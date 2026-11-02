-- Compact account-wide summaries. Full journals and statistics remain per character.
CharacterRoster = {}

function CharacterRoster.New()
  return { Version = 1, Entries = {} }
end

function CharacterRoster.GetName(entry)
  return (entry.Name or "Unknown character") .. (entry.LastName and entry.LastName ~= "" and (" " .. entry.LastName) or "")
end

function CharacterRoster.Update(data, id, snapshot, timestamp)
  local entry = data.Entries[id]
  if (not entry) then entry = { Id = id }; data.Entries[id] = entry end
  -- Snapshot updates never replace the user's note or hidden state.
  for key, value in pairs(snapshot) do
    if (key ~= "Note" and key ~= "Hidden" and key ~= "Id") then entry[key] = value end
  end
  entry.LastSeen = timestamp
  return entry
end

function CharacterRoster.GetEntries(data, options)
  options = options or {}
  local entries, search = {}, string.lower(options.Search or "")
  for _, entry in pairs(data.Entries) do
    if ((options.ShowHidden or not entry.Hidden) and (not options.Realm or entry.Realm == options.Realm) and
      (not options.Faction or entry.Faction == options.Faction) and
      (not options.MinLevel or entry.Level and entry.Level >= options.MinLevel) and
      (not options.MaxLevel or entry.Level and entry.Level <= options.MaxLevel)) then
      local text = table.concat({ CharacterRoster.GetName(entry), entry.ClassName or entry.Class or "", entry.Race or "",
        entry.Realm or "", entry.FactionName or entry.Faction or "", entry.Zone or "", entry.SubZone or "",
        entry.Guild or "", entry.Note or "" }, " ")
      if (search == "" or string.find(string.lower(text), search, 1, true)) then entries[#entries + 1] = entry end
    end
  end
  table.sort(entries, function(a, b)
    if (options.Sort == "Level" and (a.Level or 0) ~= (b.Level or 0)) then return (a.Level or 0) > (b.Level or 0) end
    if (options.Sort ~= "Name" and options.Sort ~= "Level" and (a.LastSeen or 0) ~= (b.LastSeen or 0)) then return (a.LastSeen or 0) > (b.LastSeen or 0) end
    local left, right = string.lower(CharacterRoster.GetName(a)), string.lower(CharacterRoster.GetName(b))
    if (left ~= right) then return left < right end
    if (a.Realm ~= b.Realm) then return (a.Realm or "") < (b.Realm or "") end
    return a.Id < b.Id
  end)
  return entries
end

function CharacterRoster.GetRealms(data)
  local seen, realms = {}, {}
  for _, entry in pairs(data.Entries) do
    if (entry.Realm and not seen[entry.Realm]) then seen[entry.Realm] = true; realms[#realms + 1] = entry.Realm end
  end
  table.sort(realms)
  return realms
end
