AutoBiographer_Api = {}

local Api = AutoBiographer_Api

local function IsReadable(value, expectedType)
  return not (issecretvalue and issecretvalue(value)) and type(value) == expectedType
end

local function ReadBoolean(func, ...)
  if (not func) then return nil end
  local success, value = pcall(func, ...)
  if (not success or (issecretvalue and issecretvalue(value))) then return nil end
  if (value == nil) then return false end
  if (type(value) == "boolean") then return value end
end

function Api.FormatMoney(amount)
  if (GetCoinText) then
    return GetCoinText(amount)
  end

  if (C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString) then
    return C_CurrencyInfo.GetCoinTextureString(amount)
  end

  return tostring(amount)
end

function Api.GetAuraDataByAuraInstanceID(unitId, auraInstanceId)
  if (not C_UnitAuras or not C_UnitAuras.GetAuraDataByAuraInstanceID) then return nil end

  local success, auraData = pcall(C_UnitAuras.GetAuraDataByAuraInstanceID, unitId, auraInstanceId)
  if (success) then return auraData end
end

function Api.GetAuraDataByIndex(unitId, index, filter)
  if (not C_UnitAuras or not C_UnitAuras.GetAuraDataByIndex) then return nil end

  local success, auraData = pcall(C_UnitAuras.GetAuraDataByIndex, unitId, index, filter)
  if (success) then return auraData end
end

function Api.GetDamageMeterAvailability()
  if (not C_DamageMeter or not C_DamageMeter.IsDamageMeterAvailable) then
    return nil, "C_DamageMeter.IsDamageMeterAvailable is unavailable."
  end

  local success, available, reason = pcall(C_DamageMeter.IsDamageMeterAvailable)
  if (success) then
    return available, reason
  end

  return nil, available
end

function Api.GetDamageMeterSessionById(sessionId, meterType)
  if (not C_DamageMeter or not C_DamageMeter.GetCombatSessionFromID) then
    return nil, "C_DamageMeter.GetCombatSessionFromID is unavailable."
  end

  local success, session = pcall(C_DamageMeter.GetCombatSessionFromID, sessionId, meterType)
  if (success) then
    return session
  end

  return nil, session
end

function Api.GetDamageMeterSessionByType(sessionType, meterType)
  if (not C_DamageMeter or not C_DamageMeter.GetCombatSessionFromType) then
    return nil, "C_DamageMeter.GetCombatSessionFromType is unavailable."
  end

  local success, session = pcall(C_DamageMeter.GetCombatSessionFromType, sessionType, meterType)
  if (success) then
    return session
  end

  return nil, session
end

function Api.GetDamageMeterSessions()
  if (not C_DamageMeter or not C_DamageMeter.GetAvailableCombatSessions) then
    return nil
  end

  local success, sessions = pcall(C_DamageMeter.GetAvailableCombatSessions)
  if (success) then
    return sessions
  end
end

function Api.GetDamageMeterSessionSourceById(sessionId, meterType, sourceGuid, sourceCreatureId)
  if (not C_DamageMeter or not C_DamageMeter.GetCombatSessionSourceFromID) then
    return nil, "C_DamageMeter.GetCombatSessionSourceFromID is unavailable."
  end

  local success, source = pcall(C_DamageMeter.GetCombatSessionSourceFromID, sessionId, meterType, sourceGuid, sourceCreatureId)
  if (success) then
    return source
  end

  return nil, source
end

function Api.GetDeathRecapEvents()
  if (not C_DeathRecap or not C_DeathRecap.GetRecapEvents) then
    return nil, "C_DeathRecap.GetRecapEvents is unavailable."
  end

  local success, recapEvents = pcall(C_DeathRecap.GetRecapEvents)
  if (success) then return recapEvents end

  return nil, recapEvents
end

function Api.GetEquippedItemId(slotId)
  if (not GetInventoryItemID) then return nil end
  local success, itemId = pcall(GetInventoryItemID, "player", slotId)
  if (not success or (issecretvalue and issecretvalue(itemId))) then return nil end
  -- A readable nil is an empty slot; nil returned by this wrapper is unknown.
  if (itemId == nil) then return 0 end
  if (type(itemId) ~= "number" or itemId < 0 or itemId ~= math.floor(itemId) or itemId == math.huge) then return nil end
  return itemId
end

function Api.GetInventoryItemCount(itemId)
  local getItemCount = GetItemCount or (C_Item and C_Item.GetItemCount)
  if (not getItemCount) then return nil end
  -- Count carried items, not bank stock or remaining charges.
  local success, count = pcall(getItemCount, itemId, false, false)
  if (success and not (issecretvalue and issecretvalue(count)) and type(count) == "number") then return count end
end

function Api.GetItemInfo(item)
  if (GetItemInfo) then
    return GetItemInfo(item)
  end

  if (C_Item and C_Item.GetItemInfo) then
    return C_Item.GetItemInfo(item)
  end
end

function Api.GetPlayerAlive()
  local dead = ReadBoolean(UnitIsDeadOrGhost, "player")
  if (dead ~= nil) then return not dead end
end

function Api.GetPlayerChannelSpellId()
  if (not UnitChannelInfo) then return nil end
  local success, name, _, _, _, _, _, _, spellId = pcall(UnitChannelInfo, "player")
  if (not success or (issecretvalue and issecretvalue(name))) then return nil end
  if (name == nil) then return 0 end
  if (IsReadable(spellId, "number")) then return spellId end
end

function Api.GetPlayerClass()
  if (not UnitClass) then return nil end
  local success, _, class = pcall(UnitClass, "player")
  if (success and IsReadable(class, "string")) then return class end
end

function Api.GetPlayerCompanionFamily()
  local exists = ReadBoolean(UnitExists, "pet")
  if (exists == nil) then return nil end
  if (not exists) then return 0 end
  local dead = ReadBoolean(UnitIsDeadOrGhost, "pet")
  if (dead == nil) then return nil end
  if (dead) then return 0 end
  if (not UnitCreatureFamily) then return nil end
  local success, name, id = pcall(UnitCreatureFamily, "pet")
  if (success and IsReadable(id, "number") and id > 0 and IsReadable(name, "string")) then return id, name end
  -- Older clients expose only the localized family name. Do not invent an ID.
end

function Api.GetPlayerFeignDeath()
  return ReadBoolean(UnitIsFeignDeath, "player")
end

function Api.GetPlayerFormId()
  if (GetShapeshiftFormID) then
    local success, formId = pcall(GetShapeshiftFormID)
    if (not success or (issecretvalue and issecretvalue(formId))) then return nil end
    if (formId == nil) then return 0 end
    if (IsReadable(formId, "number")) then return formId end
    return nil
  end
  local spellId = Api.GetPlayerFormSpellId()
  if (spellId == nil) then return nil end
  if (spellId == 0) then return 0 end
  return ({ [768] = 1, [783] = 3, [1066] = 4, [5487] = 5, [9634] = 8,
    [15473] = 13, [2645] = 16, [2457] = 17, [71] = 18, [2458] = 19, [24858] = 31 })[spellId]
end

function Api.GetPlayerFormSpellId()
  if (not GetShapeshiftForm or not GetShapeshiftFormInfo) then return nil end
  local success, index = pcall(GetShapeshiftForm)
  if (not success or not IsReadable(index, "number")) then return nil end
  if (index == 0) then return 0 end
  local ok, _, second, _, fourth, fifth = pcall(GetShapeshiftFormInfo, index)
  if (not ok) then return nil end
  -- Modern: icon, active, castable, spellID. Older: icon, name, active, castable, spellID.
  if (IsReadable(fourth, "number")) then return fourth end
  if (IsReadable(second, "string") and IsReadable(fifth, "number")) then return fifth end
end

function Api.GetPlayerSnapshotAttributes()
  local success, result = pcall(function()
    local health, mana = UnitHealthMax("player"), UnitPowerMax("player", 0)
    if (not IsReadable(health, "number") or not IsReadable(mana, "number")) then return nil end
    local attributes = { Base = {}, Effective = {} }
    for index = 1, 5 do
      local stat, effective, positive, negative = UnitStat("player", index)
      if (not IsReadable(stat, "number") or not IsReadable(effective, "number")
        or not IsReadable(positive, "number") or not IsReadable(negative, "number")) then return nil end
      attributes.Base[index] = stat - positive - negative
      attributes.Effective[index] = effective
    end
    return { Attributes = attributes, MaxHealth = health, MaxMana = mana }
  end)
  if (success) then return result end
end

function Api.GetPlayerSnapshotEquipment()
  local equipment, enchants = {}, {}
  for slotId = 0, 19 do
    local itemId = Api.GetEquippedItemId(slotId)
    if (itemId == nil) then return nil end
    equipment[slotId] = itemId
    if (itemId > 0 and GetInventoryItemLink) then
      local success, link = pcall(GetInventoryItemLink, "player", slotId)
      if (success and IsReadable(link, "string")) then
        local enchantId = tonumber(link:match("item:%d+:(%d+)"))
        if (enchantId and enchantId > 0) then enchants[slotId] = enchantId end
      end
    end
  end
  return equipment, enchants
end

function Api.GetPlayerSnapshotSkills()
  local success, result = pcall(function()
    local skills = {}
    if (GetProfessions and GetProfessionInfo) then
      local indices = { GetProfessions() }
      -- Profession indices can have holes (e.g. no second primary profession).
      for _, index in pairs(indices) do
        if (not IsReadable(index, "number")) then return nil end
        local name, _, rank, maxRank, _, _, skillId = GetProfessionInfo(index)
        if (not IsReadable(name, "string") or not IsReadable(rank, "number")
          or not IsReadable(maxRank, "number")) then return nil end
        skills[#skills + 1] = { Id = IsReadable(skillId, "number") and skillId or nil,
          Name = name, Rank = rank, MaxRank = maxRank }
      end
    elseif (GetNumSkillLines and GetSkillLineInfo) then
      for index = 1, GetNumSkillLines() do
        local name, isHeader, _, rank, _, _, maxRank = GetSkillLineInfo(index)
        if (issecretvalue and issecretvalue(isHeader)) then return nil end
        if (not isHeader or isHeader == 0) then
          if (not IsReadable(name, "string") or not IsReadable(rank, "number")
            or not IsReadable(maxRank, "number")) then return nil end
          skills[#skills + 1] = { Name = name, Rank = rank, MaxRank = maxRank }
        end
      end
    else
      return nil
    end
    return skills
  end)
  if (success) then return result end
end

function Api.GetPlayerSnapshotTalents(level, diagnostic)
  local stage = "talent snapshot"
  local function Value(value)
    if (issecretvalue and issecretvalue(value)) then return "<secret>" end
    return tostring(value)
  end
  local function Trace(message)
    if (diagnostic) then diagnostic(message) end
  end
  local function Query(description)
    stage = description
    Trace("Query: " .. stage)
  end
  local function Fail(reason)
    return nil, nil, stage .. ": " .. reason
  end
  -- A level-up event can arrive before UnitLevel changes. Use the milestone's
  -- level when deciding whether the character has unlocked talents yet.
  level = level or UnitLevel("player")
  Trace("Level=" .. Value(level))
  if (IsReadable(level, "number") and level < 10) then
    Trace("Talents not unlocked: returning an empty build.")
    return {}, 0
  end
  local success, talents, unspent, failure = pcall(function()
    local result, seen = {}, {}
    local function AddTalent(id, name, rank)
      Trace("Talent: id=" .. Value(id) .. ", name=" .. Value(name) .. ", rank=" .. Value(rank))
      if (not IsReadable(rank, "number")) then return false, "unreadable rank=" .. Value(rank) end
      if (rank > 0) then
        if (not IsReadable(id, "number") or id <= 0 or not IsReadable(name, "string")) then
          return false, "selected talent has invalid id=" .. Value(id) .. " or name=" .. Value(name)
        end
        if (not seen[id]) then
          seen[id] = true
          result[#result + 1] = { Id = id, Name = name, Rank = rank }
        end
      end
      return true
    end
    if (Api.IsWoWForever()) then
      -- Forever exposes talents through trait trees, not the specialization
      -- tier/column grid. Keep the same catalog-ID/rank snapshot format.
      Query("Forever trait APIs")
      if (not C_ClassTalents or not C_ClassTalents.GetActiveConfigID or not C_Traits
        or not C_Traits.GetConfigInfo or not C_Traits.GetTreeNodes or not C_Traits.GetNodeInfo
        or not C_Traits.GetEntryInfo or not C_Traits.GetDefinitionInfo) then
        return Fail("required trait API unavailable")
      end
      Query("C_ClassTalents.GetActiveConfigID()")
      local configId = C_ClassTalents.GetActiveConfigID()
      Trace("configId=" .. Value(configId))
      if (not IsReadable(configId, "number") or configId <= 0) then return Fail("invalid configId=" .. Value(configId)) end
      Query("C_Traits.GetConfigInfo(configId=" .. configId .. ")")
      local config = C_Traits.GetConfigInfo(configId)
      if (not IsReadable(config, "table")) then return Fail("invalid config=" .. Value(config)) end
      if (not IsReadable(config.treeIDs, "table") or #config.treeIDs == 0) then return Fail("missing or unreadable treeIDs") end
      for _, treeId in ipairs(config.treeIDs) do
        if (not IsReadable(treeId, "number") or treeId <= 0) then return Fail("invalid treeId=" .. Value(treeId)) end
        Query("C_Traits.GetTreeNodes(treeId=" .. treeId .. ")")
        local nodes = C_Traits.GetTreeNodes(treeId)
        if (not IsReadable(nodes, "table") or #nodes == 0) then return Fail("missing or unreadable nodes") end
        for _, nodeId in ipairs(nodes) do
          if (not IsReadable(nodeId, "number") or nodeId <= 0) then return Fail("invalid nodeId=" .. Value(nodeId)) end
          Query("C_Traits.GetNodeInfo(configId=" .. configId .. ", nodeId=" .. nodeId .. ")")
          local node = C_Traits.GetNodeInfo(configId, nodeId)
          if (not IsReadable(node, "table")) then return Fail("invalid node=" .. Value(node)) end
          local rank = node.activeRank
          if (not IsReadable(rank, "number") or rank < 0) then return Fail("invalid activeRank=" .. Value(rank)) end
          if (rank > 0) then
            if (not IsReadable(node.activeEntry, "table")) then return Fail("missing or unreadable activeEntry") end
            local entryId = node.activeEntry.entryID
            if (not IsReadable(entryId, "number") or entryId <= 0) then return Fail("invalid entryId=" .. Value(entryId)) end
            Query("C_Traits.GetEntryInfo(configId=" .. configId .. ", entryId=" .. entryId .. ")")
            local entry = C_Traits.GetEntryInfo(configId, entryId)
            if (not IsReadable(entry, "table")) then return Fail("invalid entry=" .. Value(entry)) end
            local definitionId = entry.definitionID
            if (not IsReadable(definitionId, "number") or definitionId <= 0) then return Fail("invalid definitionId=" .. Value(definitionId)) end
            Query("C_Traits.GetDefinitionInfo(definitionId=" .. definitionId .. ")")
            local definition = C_Traits.GetDefinitionInfo(definitionId)
            if (not IsReadable(definition, "table")) then return Fail("invalid definition=" .. Value(definition)) end
            local spellId = definition.spellID
            if (not IsReadable(spellId, "number") or spellId <= 0) then return Fail("invalid spellId=" .. Value(spellId)) end
            Query("GetSpellInfo(spellId=" .. spellId .. ")")
            local name = Api.GetSpellInfo(spellId)
            -- Use the trait entry as its stable catalog ID; the definition's
            -- spell ID is only needed to resolve the displayed talent name.
            local added, reason = AddTalent(entryId, name, rank)
            if (not added) then return Fail(reason) end
          end
        end
      end
      Query("GetUnspentTalentPoints()")
      local points = GetUnspentTalentPoints and GetUnspentTalentPoints()
      Trace("unspentPoints=" .. Value(points))
      return result, IsReadable(points, "number") and points or nil
    end
    local modern = C_SpecializationInfo
    Trace("APIs: C_SpecializationInfo=" .. tostring(modern ~= nil) ..
      ", GetNumTalentTabs=" .. tostring(GetNumTalentTabs ~= nil) ..
      ", GetNumTalents=" .. tostring(GetNumTalents ~= nil) ..
      ", modern.GetTalentInfo=" .. tostring(modern ~= nil and modern.GetTalentInfo ~= nil) ..
      ", GetTalentInfo=" .. tostring(GetTalentInfo ~= nil))
    if (modern and modern.IsInitialized) then
      Query("C_SpecializationInfo.IsInitialized()")
      local initialized = modern.IsInitialized()
      Trace("initialized=" .. Value(initialized))
      if (not IsReadable(initialized, "boolean") or not initialized) then return Fail("initialized=" .. Value(initialized)) end
    end
    local group = 1
    if (modern and modern.GetActiveSpecGroup) then
      Query("C_SpecializationInfo.GetActiveSpecGroup(false, false)")
      group = modern.GetActiveSpecGroup(false, false)
    elseif (GetActiveTalentGroup) then
      Query("GetActiveTalentGroup()")
      group = GetActiveTalentGroup()
    end
    Trace("group=" .. Value(group))
    if (not IsReadable(group, "number")) then return Fail("unreadable group=" .. Value(group)) end
    local tabCount
    if (GetNumTalentTabs) then
      Query("GetNumTalentTabs(false, false)")
      tabCount = GetNumTalentTabs(false, false)
    elseif (modern and modern.GetNumSpecializationsForClassID) then
      Query("UnitClass(player), then C_SpecializationInfo.GetNumSpecializationsForClassID(classId)")
      local _, _, classId = UnitClass("player")
      Trace("classId=" .. Value(classId))
      if (not IsReadable(classId, "number")) then return Fail("unreadable classId=" .. Value(classId)) end
      tabCount = modern.GetNumSpecializationsForClassID(classId)
    elseif (GetNumSpecializations) then
      Query("GetNumSpecializations(false, false)")
      tabCount = GetNumSpecializations(false, false)
    else
      return Fail("no talent tree count API available")
    end
    Trace("tabCount=" .. Value(tabCount))
    if (not IsReadable(tabCount, "number") or tabCount <= 0) then return Fail("invalid tabCount=" .. Value(tabCount)) end
    for tab = 1, tabCount do
      -- Classic has a linear talent list; other non-Forever versions may
      -- expose the namespaced tier/column grid instead.
      if (GetNumTalents) then
        Query("GetNumTalents(tab=" .. tab .. ", false, false)")
        local count = GetNumTalents(tab, false, false)
        Trace("talentCount=" .. Value(count))
        if (not IsReadable(count, "number") or count <= 0) then return Fail("invalid talentCount=" .. Value(count)) end
        for index = 1, count do
          local id, name, rank
          if (modern and modern.GetTalentInfo) then
            Query("C_SpecializationInfo.GetTalentInfo: specializationIndex=" .. tab .. ", talentIndex=" .. index .. ", groupIndex=" .. group .. ", isInspect=false, isPet=false")
            local info = modern.GetTalentInfo({ specializationIndex = tab,
              talentIndex = index, isInspect = false, isPet = false, groupIndex = group })
            if (not IsReadable(info, "table")) then return Fail("invalid info=" .. Value(info)) end
            id, name, rank = info.talentID, info.name, info.rank
          elseif (GetTalentInfo) then
            Query("GetTalentInfo: tab=" .. tab .. ", index=" .. index .. ", group=" .. group)
            local legacyName, _, _, _, legacyRank = GetTalentInfo(tab, index, false, false, group)
            name, rank = legacyName, legacyRank
            if (GetTalentLink) then
              Query("GetTalentLink: tab=" .. tab .. ", index=" .. index .. ", group=" .. group)
              local link = GetTalentLink(tab, index, false, false, group)
              Trace("link=" .. Value(link))
              if (IsReadable(link, "string")) then id = tonumber(link:match("talent:(%d+)")) end
            end
          else
            return Fail("no talent info API available")
          end
          local added, reason = AddTalent(id, name, rank)
          if (not added) then return Fail(reason) end
        end
      elseif (modern and modern.GetTalentInfo) then
        local found = false
        -- These globals belong to the load-on-demand talent UI. Defaults also
        -- allow snapshots before the player has opened that UI.
        local tiers = MAX_NUM_TALENT_TIERS or MAX_TALENT_TIERS or 15
        local columns = NUM_TALENT_COLUMNS or 4
        Query("talent grid: tab=" .. tab .. ", tiers=" .. Value(tiers) .. ", columns=" .. Value(columns))
        if (not IsReadable(tiers, "number") or not IsReadable(columns, "number")) then return Fail("unreadable grid dimensions") end
        for tier = 1, tiers do
          for column = 1, columns do
            stage = "C_SpecializationInfo.GetTalentInfo: specializationIndex=" .. tab .. ", tier=" .. tier .. ", column=" .. column .. ", groupIndex=" .. group .. ", isInspect=false, isPet=false"
            -- Empty cells are expected; only log populated cells or failures.
            local info = modern.GetTalentInfo({ specializationIndex = tab,
              tier = tier, column = column, isInspect = false, isPet = false, groupIndex = group })
            if (issecretvalue and issecretvalue(info)) then return Fail("info=<secret>") end
            -- Empty positions in the grid are normal, not missing data.
            if (info) then
              Trace("Query: " .. stage)
              if (not IsReadable(info, "table")) then return Fail("invalid info=" .. Value(info)) end
              found = true
              local rank = info.rank
              if (issecretvalue and issecretvalue(rank)) then return Fail("rank=<secret>") end
              if (not IsReadable(rank, "number")) then
                Trace("rank=" .. Value(rank) .. ", selected=" .. Value(info.selected))
                if (not IsReadable(info.selected, "boolean")) then return Fail("unreadable rank and selected=" .. Value(info.selected)) end
                rank = info.selected and 1 or 0
              end
              local added, reason = AddTalent(info.talentID, info.name, rank)
              if (not added) then return Fail(reason) end
            end
          end
        end
        if (not found) then return Fail("no talent info found anywhere in tab " .. tab .. " (" .. tiers .. " tiers x " .. columns .. " columns)") end
      else
        return Fail("no talent info API available")
      end
    end
    Query("GetUnspentTalentPoints(false, false, group=" .. group .. ")")
    local points = GetUnspentTalentPoints and GetUnspentTalentPoints(false, false, group)
    Trace("unspentPoints=" .. Value(points))
    return result, IsReadable(points, "number") and points or nil
  end)
  if (not success) then
    failure = "API error during " .. stage .. ": " .. Value(talents)
    talents, unspent = nil, nil
  end
  if (failure) then Trace("FAILED: " .. failure)
  else Trace("SUCCESS: " .. #talents .. " selected talents, unspentPoints=" .. Value(unspent)) end
  return talents, unspent, failure
end

function Api.GetPlayerStealthed()
  return ReadBoolean(IsStealthed)
end

function Api.GetPlayerWorldPosition()
  if (not UnitPosition) then return nil end
  local success, y, x, _, instanceId = pcall(UnitPosition, "player")
  if (not success) then return nil end
  for _, value in pairs({ x = x, y = y, instanceId = instanceId }) do
    if (issecretvalue and issecretvalue(value)) then return nil end
    if (type(value) ~= "number" or value ~= value or math.abs(value) == math.huge) then return nil end
  end
  if (x == nil or y == nil or instanceId == nil) then return nil end
  return x, y, instanceId
end

function Api.GetQuestLogEntries()
  local entries = {}
  local count = 0
  if (C_QuestLog and C_QuestLog.GetNumQuestLogEntries) then count = C_QuestLog.GetNumQuestLogEntries()
  elseif (GetNumQuestLogEntries) then count = GetNumQuestLogEntries() end
  if ((issecretvalue and issecretvalue(count)) or type(count) ~= "number") then return entries end
  for index = 1, count do
    local id, title, header
    if (C_QuestLog and C_QuestLog.GetInfo) then
      local info = C_QuestLog.GetInfo(index)
      if (not (issecretvalue and issecretvalue(info)) and info) then id, title, header = info.questID, info.title, info.isHeader end
    elseif (GetQuestLogTitle) then
      local level, tag, collapsed, complete, frequency
      title, level, tag, header, collapsed, complete, frequency, id = GetQuestLogTitle(index)
    end
    if (not (issecretvalue and (issecretvalue(id) or issecretvalue(title) or issecretvalue(header))) and id and id > 0 and not header) then
      entries[#entries + 1] = { Id = id, Name = title }
    end
  end
  return entries
end

function Api.GetQuestTitle(questId)
  if (not C_QuestLog) then return nil end

  local getQuestTitle = C_QuestLog.GetQuestInfo or C_QuestLog.GetTitleForQuestID
  if (not getQuestTitle) then return nil end

  local success, questTitle = pcall(getQuestTitle, questId)
  if (success) then return questTitle end
end

function Api.GetQuestTooltipId(owner)
  if ((issecretvalue and issecretvalue(owner)) or not owner) then return nil end
  local id = owner.questID
  if (issecretvalue and issecretvalue(id)) then return nil end
  if (not id) then
    local info = owner.info
    if (issecretvalue and issecretvalue(info)) then return nil end
    if (info) then id = info.questID end
  end
  if (issecretvalue and issecretvalue(id)) then return nil end
  if (id) then return id end
  local index = owner.questLogIndex
  if (issecretvalue and issecretvalue(index)) then return nil end
  if (not index and owner.GetID) then
    index = owner:GetID()
    if (issecretvalue and issecretvalue(index)) then return nil end
    if (QuestLogListScrollFrame and FauxScrollFrame_GetOffset) then index = index + FauxScrollFrame_GetOffset(QuestLogListScrollFrame) end
  end
  if (issecretvalue and issecretvalue(index)) then return nil end
  if (index and C_QuestLog and C_QuestLog.GetInfo) then
    local info = C_QuestLog.GetInfo(index)
    if (issecretvalue and issecretvalue(info)) then return nil end
    return info and info.questID
  elseif (index and GetQuestLogTitle) then
    return select(8, GetQuestLogTitle(index))
  end
end

function Api.GetRestedExperiencePool()
  if (not GetXPExhaustion) then return nil end
  local success, pool = pcall(GetXPExhaustion)
  if (not success or (issecretvalue and issecretvalue(pool))) then return nil end
  -- The API returns nil when the readable pool is exhausted, not when its
  -- value is secret. Keep those cases distinct so the final bonus is counted.
  if (pool == nil) then return 0 end
  if (type(pool) ~= "number" or pool < 0) then return nil end
  return pool
end

function Api.GetSpellInfo(spellId)
  if (GetSpellInfo) then
    return GetSpellInfo(spellId)
  end

  if (C_Spell and C_Spell.GetSpellInfo) then
    local spellInfo = C_Spell.GetSpellInfo(spellId)
    if (spellInfo) then
      return spellInfo.name, nil, spellInfo.iconID, spellInfo.castTime,
        spellInfo.minRange, spellInfo.maxRange, spellInfo.spellID,
        spellInfo.originalIconID
    end
  end
end

function Api.GetSpellRank(spellId)
  local _, subtext = Api.GetSpellInfo(spellId)
  if (issecretvalue and issecretvalue(subtext)) then return nil end
  if ((subtext == nil or subtext == "") and C_Spell and C_Spell.GetSpellSubtext) then
    subtext = C_Spell.GetSpellSubtext(spellId)
  end
  if (issecretvalue and issecretvalue(subtext)) then return nil end
  if (type(subtext) ~= "string") then return nil end
  return tonumber(string.match(subtext, "%d+"))
end

function Api.GetTravelTrackingType()
  -- Check in priority order so overlapping states count in exactly one category.
  local states = {
    { UnitIsGhost, "player", AutoBiographerEnum.DistanceTrackingType.Ghost },
    { UnitOnTaxi, "player", AutoBiographerEnum.DistanceTrackingType.FlightPath },
    { IsMounted, nil, AutoBiographerEnum.DistanceTrackingType.Mounted },
  }
  for _, state in ipairs(states) do
    if (not state[1]) then return nil end
    local success, active
    if (state[2]) then success, active = pcall(state[1], state[2])
    else success, active = pcall(state[1]) end
    if (not success or (issecretvalue and issecretvalue(active))) then return nil end
    if (active) then return state[3] end
  end
  local class = Api.GetPlayerClass()
  if (UnitClass and class == nil) then return nil end
  if (class == "DRUID" or class == "ROGUE") then
    local stealthed = Api.GetPlayerStealthed()
    if (stealthed == nil) then return nil end
    if (stealthed) then return AutoBiographerEnum.DistanceTrackingType.Stealthed end
  end
  if (class == "DRUID" or class == "SHAMAN") then
    local formId = Api.GetPlayerFormId()
    if (formId == nil) then return nil end
    local category = ({ [1] = "CatForm", [3] = "TravelForm", [4] = "AquaticForm",
      [5] = "BearForm", [8] = "BearForm", [16] = "GhostWolf", [31] = "MoonkinForm" })[formId]
    if (category) then return AutoBiographerEnum.DistanceTrackingType[category] end
  end
  local swimming = ReadBoolean(IsSwimming, "player")
  if (swimming == nil) then return nil end
  return swimming and AutoBiographerEnum.DistanceTrackingType.Swimming or AutoBiographerEnum.DistanceTrackingType.OnFoot
end

function Api.GetUnitName(unitId)
  local name, lastName = UnitName(unitId)
  if (issecretvalue and issecretvalue(name)) then name = nil end
  -- The second return is a surname on Forever, but a realm on other clients.
  if (not Api.IsWoWForever() or (issecretvalue and issecretvalue(lastName))) then lastName = nil end
  if (name == "") then name = nil end
  if (lastName == "") then lastName = nil end
  return name, lastName
end

function Api.IsEventAvailable(eventName, fallback)
  if (C_EventUtils and C_EventUtils.IsEventValid) then return C_EventUtils.IsEventValid(eventName) end
  return fallback
end

function Api.IsGamepadUIEnabled()
  return GetCVar and GetCVar("InputDeviceInterfaceStyle") == "1"
end

function Api.IsWoWForever()
  local _, _, _, interfaceVersion = GetBuildInfo()
  return interfaceVersion > 16000 and interfaceVersion < 20000
end

function Api.RegisterQuestNoteMenu(handler)
  -- Leave Forever's protected Gamepad UI menus untouched.
  if (Api.IsWoWForever() and Api.IsGamepadUIEnabled()) then return false end
  if (not Menu or not Menu.ModifyMenu) then return false end
  Menu.ModifyMenu("MENU_QUEST_MAP_LOG_TITLE", function(owner, rootDescription)
    if (Api.IsWoWForever() and Api.IsGamepadUIEnabled()) then return end
    handler(owner and owner.questID, function(label, callback) rootDescription:CreateButton(label, callback) end)
  end)
  return true
end

function Api.RegisterTooltipHandler(scriptType, tooltipDataType, handler)
  if (Api.IsWoWForever() and TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType) then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType[tooltipDataType], handler)
  else
    GameTooltip:HookScript(scriptType, handler)
  end
end

function Api.RegisterUnitNoteMenu(handler)
  if (Api.IsWoWForever() and Api.IsGamepadUIEnabled()) then return false end
  if (Menu and Menu.ModifyMenu) then
    for _, tag in ipairs({ "SELF", "TARGET", "PLAYER", "ENEMY_PLAYER", "PARTY", "RAID_PLAYER", "FOCUS" }) do
      Menu.ModifyMenu("MENU_UNIT_" .. tag, function(owner, rootDescription, context)
        if (Api.IsWoWForever() and Api.IsGamepadUIEnabled()) then return end
        if (issecretvalue and issecretvalue(context)) then return end
        handler(context and context.unit, function(label, callback) rootDescription:CreateButton(label, callback) end)
      end)
    end
    return true
  elseif (UnitPopup_ShowMenu and UIDropDownMenu_AddButton) then
    -- Append through the legacy menu API, never alter Blizzard's menu tables.
    hooksecurefunc("UnitPopup_ShowMenu", function(dropdown, which, unit)
      if (Api.IsWoWForever() and Api.IsGamepadUIEnabled()) then return end
      if (UIDROPDOWNMENU_MENU_LEVEL and UIDROPDOWNMENU_MENU_LEVEL ~= 1) then return end
      if (issecretvalue and issecretvalue(unit)) then return end
      handler(unit or dropdown and dropdown.unit, function(label, callback)
        local info = UIDropDownMenu_CreateInfo()
        info.text, info.func, info.notCheckable = label, callback, true
        UIDropDownMenu_AddButton(info, 1)
      end)
    end)
    return true
  end
  return false
end

function Api.SendMilestoneMessage(message, channel)
  if (C_ChatInfo and C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown()) then return false end
  local send = C_ChatInfo and C_ChatInfo.SendChatMessage or SendChatMessage
  if (not send) then return false end
  send(message, channel)
  return true
end

function Api.SetFrameResizeBounds(frame, minWidth, minHeight, maxWidth, maxHeight)
  if (frame.SetResizeBounds) then
    frame:SetResizeBounds(minWidth, minHeight, maxWidth, maxHeight)
  else
    frame:SetMinResize(minWidth, minHeight)
    frame:SetMaxResize(maxWidth, maxHeight)
  end
end
