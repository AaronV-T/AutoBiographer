AutoBiographer_Api = {}

local Api = AutoBiographer_Api

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

function Api.GetUnitName(unitId)
  local name, lastName = UnitName(unitId)
  if (issecretvalue and issecretvalue(name)) then name = nil end
  -- The second return is a surname on Forever, but a realm on other clients.
  if (not Api.IsWoWForever() or (issecretvalue and issecretvalue(lastName))) then lastName = nil end
  if (name == "") then name = nil end
  if (lastName == "") then lastName = nil end
  return name, lastName
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
