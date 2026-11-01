-- Personal tales are saved per character. Event facts are copied into drafts;
-- editing or pruning the journal never changes a saved story.
CampfireTales = { MaxMessageBytes = 255, MaxTitleBytes = 60 }
local Tales = CampfireTales

function Tales.New()
  return { NextId = 1, Items = {} }
end

function Tales.PlainText(text)
  return ((text or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    :gsub("|H.-|h(.-)|h", "%1"):gsub("|T.-|t", ""):gsub("|A.-|a", "")
    :gsub("[%z\1-\31\127]", " "):gsub("%s+", " "):match("^%s*(.-)%s*$"))
end

function Tales.Contains(library, tale)
  for _, saved in ipairs(library.Items) do if (saved == tale) then return true end end
  return false
end

function Tales.Validate(title, text)
  title, text = Tales.PlainText(title), Tales.PlainText(text)
  if (title == "") then return nil, "Give your tale a title." end
  if (#title > Tales.MaxTitleBytes) then return nil, "The title must fit within 60 bytes." end
  if (text == "") then return nil, "Write a story or use an opening from a recorded event." end
  if (#text > Tales.MaxMessageBytes) then return nil, "Shorten your story to fit one chat message (255 bytes)." end
  return { Title = title, Text = text }
end

function Tales.Save(library, selected, title, text, sources)
  local values, message = Tales.Validate(title, text)
  if (not values) then return nil, message end
  if (selected and not Tales.Contains(library, selected)) then return nil, "That tale is no longer in your library." end
  if (not selected) then
    selected = { Id = library.NextId, CreatedTimestamp = time() }
    library.NextId = library.NextId + 1
    table.insert(library.Items, selected)
  end
  selected.Title, selected.Text, selected.LastUpdatedTimestamp = values.Title, values.Text, time()
  selected.Sources = {}
  for _, source in ipairs(sources or {}) do
    table.insert(selected.Sources, { Timestamp = source.Timestamp, SubType = source.SubType, Description = source.Description })
  end
  return selected
end

function Tales.Delete(library, selected)
  for index, tale in ipairs(library.Items) do
    if (tale == selected) then table.remove(library.Items, index); return true end
  end
  return false
end

function Tales.GetMemory(event, catalogs, databases)
  local sub, types = event.SubType, AutoBiographerEnum.EventSubType
  local title, templates, subject, detail
  local function CatalogName(collection, id, fallback)
    local entry = (catalogs[collection] or {})[id]
    return entry and entry.Name or fallback
  end
  if (sub == types.BossKill) then
    subject, title = event.BossName or ("boss #" .. tostring(event.BossId)), "A boss defeated"
    templates = { "I was there when %s fell. That is a victory I will remember.",
      "I remember the day we defeated %s. It makes the quiet evenings feel well earned.",
      "The defeat of %s is part of my story. Tonight seems a good night to tell it." }
  elseif (sub == types.PlayerDeath) then
    title = "A lesson learned"
    if (event.KillerCuid) then
      subject = CatalogName("UnitCatalog", event.KillerCuid, "an unknown foe")
      templates = { "My encounter with %s ended with a trip to the graveyard. I remember that lesson rather well.",
        "I once met my end at the hands of %s. Fortunately, the story did not end there.",
        "If you meet %s, take care. I learned that advice the hard way." }
    elseif (event.EnvironmentalType == "Falling") then
      subject = "a fall"
      templates = { "I once died to %s. The ground was rather less forgiving than I had hoped.",
        "My travels once ended in %s. I check the way down more carefully now.",
        "I still remember %s that sent me to the graveyard. Some shortcuts are not worth taking." }
    elseif (event.EnvironmentalType == "Drowning") then
      subject = "my breath"
      templates = { "I once trusted %s to last longer than it did. The water had other plans.",
        "I have drowned before. I no longer treat %s as an unlimited resource.",
        "A swim once cost me my life. These days, I keep a closer watch on %s." }
    else
      subject = "a trip to the graveyard"
      templates = { "I remember %s that taught me to be more careful.",
        "One of my adventures ended with %s. At least I returned to tell the tale.",
        "I once took %s instead of the road I had planned. Adventure can be rather rude." }
    end
  elseif (sub == types.ZoneFirstVisit or sub == types.SubZoneFirstVisit) then
    subject, title = event.ZoneName or event.SubZoneName, "A first journey"
    templates = { "I still remember my first journey into %s. Every turn was unfamiliar then.",
      "The first time I set foot in %s, I had no idea what awaited me.",
      "My first visit to %s deserves a tale of its own. Some places leave an impression." }
  elseif (sub == types.QuestTurnIn) then
    subject, title = event.QuestTitle or ("quest #" .. tostring(event.QuestId)), "A quest remembered"
    templates = { "I remember completing %s. There is always more to an errand than the reward.",
      "I saw %s through to the end. That adventure has stayed with me.",
      "The tale of %s is one I can tell from experience. I was there to finish it." }
  elseif (sub == types.LevelUp) then
    subject, title = tostring(event.LevelNum), "Growing stronger"
    templates = { "I remember reaching level %s. The next adventure suddenly seemed a little less daunting.",
      "Reaching level %s was a moment worth celebrating. There was still so much road ahead.",
      "The day I reached level %s is part of my story. It took a fair bit of adventure to get there." }
  elseif (sub == types.FirstAcquiredItem or sub == types.FirstEquippedItem) then
    subject = CatalogName("ItemCatalog", event.CatalogItemId, "an unfamiliar item")
    title = sub == types.FirstEquippedItem and "New equipment" or "A memorable find"
    templates = sub == types.FirstEquippedItem and {
      "I remember first equipping %s. New gear always brings thoughts of the next adventure.",
      "The first time I put %s to use is a memory worth keeping.",
      "I still recall taking up %s for the first time. Every piece of gear has a beginning." } or {
      "I remember acquiring %s for the first time. Some finds are hard to forget.",
      "The day %s first found its way into my bags deserves a story.",
      "I still remember my first %s. Adventure has a way of leaving you with keepsakes." }
  elseif (sub == types.FirstKill) then
    subject, title = CatalogName("UnitCatalog", event.CatalogUnitId, "an unfamiliar creature"), "A first encounter"
    templates = { "I still remember my first victory over %s. It was a new entry in a growing list of adventures.",
      "The first time I brought down %s is a tale worth telling.",
      "My first defeat of %s taught me something about the dangers along the road." }
  elseif (sub == types.GuildJoined or sub == types.GuildLeft or sub == types.GuildRankChanged) then
    subject, title = event.GuildName or event.GuildRankName, "Guild memories"
    if (sub == types.GuildJoined) then
      templates = { "I remember joining %s. A new guild can be the beginning of many adventures.",
        "The day I joined %s marked a new chapter in my travels.", "Joining %s is a memory I would share by any campfire." }
    elseif (sub == types.GuildLeft) then
      templates = { "I remember leaving %s. Some chapters end before the journey does.",
        "Leaving %s was part of my journey. There was more road ahead.", "My time with %s came to an end, but the memories remain." }
    else
      subject = event.GuildRankName or "a new rank"
      templates = { "I remember becoming %s in my guild. That day has a place in my story.",
        "The day my guild named me %s is one I remember.", "My time as %s began with a change of guild rank and a new chapter." }
    end
  elseif (event.Type == AutoBiographerEnum.EventType.Battleground) then
    subject, title = (databases.BattlegroundDatabase or {})[event.BattlegroundId] or "a battleground", "A battleground memory"
    if (sub == types.BattlegroundWon) then
      templates = { "I remember a victory in %s. It is a fine memory to bring to a warm fire.",
        "We won the day in %s. That battle deserves its own telling.", "One of my victories in %s is a story I still enjoy telling." }
    elseif (sub == types.BattlegroundLost) then
      templates = { "I remember a defeat in %s. Even a lost battle can leave a story worth telling.",
        "We did not win that day in %s. There are lessons in those battles, too.", "A loss in %s is part of my story. Every victory is not guaranteed." }
    else
      templates = { "I remember heading into %s. You never quite know how a battle will unfold.",
        "One of my adventures began by joining %s. It was a change from the open road.", "The call to %s once drew me into another battle." }
    end
  elseif (event.Type == AutoBiographerEnum.EventType.Arena) then
    subject, title = (databases.ArenaDatabase or {})[event.ArenaId] or "the arena", "An arena memory"
    local outcome = sub == types.ArenaWon and "a victory" or sub == types.ArenaLost and "a defeat" or "a match"
    templates = { "I remember " .. outcome .. " in %s. Arena battles have a way of staying with you.",
      "There was " .. outcome .. " in %s that deserves a telling by the fire.",
      "My travels brought me " .. outcome .. " in %s. The arena is a world of its own." }
  elseif (sub == types.SkillMilestone) then
    subject, detail, title = event.SkillName, tostring(event.SkillLevel), "Practice pays off"
    templates = { "I remember reaching %s skill in %s. Practice has its own rewards.",
      "The day I reached %s in %s was worth a little celebration.", "Reaching %s in %s is one of the milestones along my road." }
  elseif (sub == types.ReputationLevelChanged) then
    subject, detail, title = event.Faction, event.ReputationLevel, "A changing reputation"
    templates = { "I remember becoming %s with %s. Word of an adventurer travels.",
      "The day I became %s with %s marked a change in how I was received.", "Becoming %s with %s is part of the story of my travels." }
  elseif (sub == types.SpellLearned) then
    subject, title = CatalogName("SpellCatalog", event.SpellId, "a new spell"), "A new spell"
    templates = { "I remember learning %s. A new spell opens all sorts of possibilities.",
      "The day I learned %s was another step along my path.", "Learning %s is a memory I still carry into every adventure." }
  elseif (sub == types.StatisticMilestone and event.Text) then
    subject, title = event.Text, "A personal milestone"
    templates = { "I remember the day I could say I had %s. There is a story behind that milestone.",
      "I had %s when I reached that milestone. The road there was an adventure of its own.",
      "By that day, I had %s. Numbers can hold a surprising number of memories." }
  elseif (sub == types.Custom and event.Text) then
    subject, title = event.Text, "A recorded memory"
    templates = { "%s", "I remember this part of my travels: %s", "Here is a memory from my journal: %s" }
  end
  if (not templates or not subject or subject == "") then return nil end
  local suggestions = {}
  for _, template in ipairs(templates) do
    suggestions[#suggestions + 1] = Tales.PlainText(detail and string.format(template, detail, subject) or string.format(template, subject))
  end
  local ok, description = pcall(Event.ToString, event, catalogs, true)
  description = Tales.PlainText(ok and description or suggestions[1])
  local category = "Event"
  for name, value in pairs(types) do
    if (value == sub) then category = name:gsub("(%l)(%u)", "%1 %2"); break end
  end
  return { Title = title, Suggestions = suggestions, Timestamp = event.Timestamp,
    Description = description, SubType = sub, Category = category }
end

function Tales.GetMemories(events, catalogs, databases)
  local memories = {}
  for index = #events, 1, -1 do
    local memory = Tales.GetMemory(events[index], catalogs, databases)
    if (memory) then memory.EventIndex = index; memories[#memories + 1] = memory end
  end
  table.sort(memories, function(a, b)
    if ((a.Timestamp or 0) ~= (b.Timestamp or 0)) then return (a.Timestamp or 0) > (b.Timestamp or 0) end
    return a.EventIndex > b.EventIndex
  end)
  return memories
end
