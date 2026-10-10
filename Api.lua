AutoBiographer_Api = {}

local Api = AutoBiographer_Api

local function IsReadable(value, expectedType)
  return not (issecretvalue and issecretvalue(value)) and type(value) == expectedType
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

function Api.GetPlayerSnapshotTalents(level)
  -- A level-up event can arrive before UnitLevel changes. Use the milestone's
  -- level when deciding whether the character has unlocked talents yet.
  level = level or UnitLevel("player")
  if (IsReadable(level, "number") and level < 10) then return {}, 0 end
  local success, talents, unspent = pcall(function()
    local modern = C_SpecializationInfo
    if (modern and modern.IsInitialized) then
      local initialized = modern.IsInitialized()
      if (not IsReadable(initialized, "boolean") or not initialized) then return nil end
    end
    local group = 1
    if (modern and modern.GetActiveSpecGroup) then
      group = modern.GetActiveSpecGroup(false, false)
    elseif (GetActiveTalentGroup) then
      group = GetActiveTalentGroup()
    end
    if (not IsReadable(group, "number")) then return nil end
    local result, seen = {}, {}
    local function AddTalent(id, name, rank)
      if (not IsReadable(rank, "number")) then return false end
      if (rank > 0) then
        if (not IsReadable(id, "number") or id <= 0 or not IsReadable(name, "string")) then return false end
        if (not seen[id]) then
          seen[id] = true
          result[#result + 1] = { Id = id, Name = name, Rank = rank }
        end
      end
      return true
    end
    local tabCount
    if (GetNumTalentTabs) then tabCount = GetNumTalentTabs(false, false)
    elseif (modern and modern.GetNumSpecializationsForClassID) then
      local _, _, classId = UnitClass("player")
      if (not IsReadable(classId, "number")) then return nil end
      tabCount = modern.GetNumSpecializationsForClassID(classId)
    elseif (GetNumSpecializations) then tabCount = GetNumSpecializations(false, false) end
    if (not IsReadable(tabCount, "number") or tabCount <= 0) then return nil end
    for tab = 1, tabCount do
      -- Classic has a linear talent list. Forever need not expose those
      -- globals: its namespaced query also supports the tier/column grid.
      if (GetNumTalents) then
        local count = GetNumTalents(tab, false, false)
        if (not IsReadable(count, "number") or count <= 0) then return nil end
        for index = 1, count do
          local id, name, rank
          if (modern and modern.GetTalentInfo) then
            local info = modern.GetTalentInfo({ specializationIndex = tab,
              talentIndex = index, isInspect = false, isPet = false, groupIndex = group })
            if (not IsReadable(info, "table")) then return nil end
            id, name, rank = info.talentID, info.name, info.rank
          elseif (GetTalentInfo) then
            local legacyName, _, _, _, legacyRank = GetTalentInfo(tab, index, false, false, group)
            name, rank = legacyName, legacyRank
            if (GetTalentLink) then
              local link = GetTalentLink(tab, index, false, false, group)
              if (IsReadable(link, "string")) then id = tonumber(link:match("talent:(%d+)")) end
            end
          else
            return nil
          end
          if (not AddTalent(id, name, rank)) then return nil end
        end
      elseif (modern and modern.GetTalentInfo) then
        local found = false
        -- These globals belong to the load-on-demand talent UI. Defaults also
        -- allow snapshots before the player has opened that UI.
        local tiers = MAX_NUM_TALENT_TIERS or MAX_TALENT_TIERS or 15
        local columns = NUM_TALENT_COLUMNS or 4
        if (not IsReadable(tiers, "number") or not IsReadable(columns, "number")) then return nil end
        for tier = 1, tiers do
          for column = 1, columns do
            local info = modern.GetTalentInfo({ specializationIndex = tab,
              tier = tier, column = column, isInspect = false, isPet = false, groupIndex = group })
            if (issecretvalue and issecretvalue(info)) then return nil end
            -- Empty positions in the grid are normal, not missing data.
            if (info) then
              if (not IsReadable(info, "table")) then return nil end
              found = true
              local rank = info.rank
              if (issecretvalue and issecretvalue(rank)) then return nil end
              if (not IsReadable(rank, "number")) then
                if (not IsReadable(info.selected, "boolean")) then return nil end
                rank = info.selected and 1 or 0
              end
              if (not AddTalent(info.talentID, info.name, rank)) then return nil end
            end
          end
        end
        if (not found) then return nil end
      else
        return nil
      end
    end
    local points = GetUnspentTalentPoints and GetUnspentTalentPoints(false, false, group)
    return result, IsReadable(points, "number") and points or nil
  end)
  if (success) then return talents, unspent end
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
    { IsSwimming, "player", AutoBiographerEnum.DistanceTrackingType.Swimming },
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
  return AutoBiographerEnum.DistanceTrackingType.OnFoot
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
  if (not Menu or not Menu.ModifyMenu) then return false end
  Menu.ModifyMenu("MENU_QUEST_MAP_LOG_TITLE", function(owner, rootDescription)
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
  if (Menu and Menu.ModifyMenu) then
    for _, tag in ipairs({ "SELF", "TARGET", "PLAYER", "ENEMY_PLAYER", "PARTY", "RAID_PLAYER", "FOCUS" }) do
      Menu.ModifyMenu("MENU_UNIT_" .. tag, function(owner, rootDescription, context)
        if (issecretvalue and issecretvalue(context)) then return end
        handler(context and context.unit, function(label, callback) rootDescription:CreateButton(label, callback) end)
      end)
    end
    return true
  elseif (UnitPopup_ShowMenu and UIDropDownMenu_AddButton) then
    -- Append through the legacy menu API, never alter Blizzard's menu tables.
    hooksecurefunc("UnitPopup_ShowMenu", function(dropdown, which, unit)
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

function Api.SetFrameResizeBounds(frame, minWidth, minHeight, maxWidth, maxHeight)
  if (frame.SetResizeBounds) then
    frame:SetResizeBounds(minWidth, minHeight, maxWidth, maxHeight)
  else
    frame:SetMinResize(minWidth, minHeight)
    frame:SetMaxResize(maxWidth, maxHeight)
  end
end
