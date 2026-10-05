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

function Api.GetItemInfo(item)
  if (GetItemInfo) then
    return GetItemInfo(item)
  end

  if (C_Item and C_Item.GetItemInfo) then
    return C_Item.GetItemInfo(item)
  end
end

function Api.GetQuestTitle(questId)
  if (not C_QuestLog) then return nil end

  local getQuestTitle = C_QuestLog.GetQuestInfo or C_QuestLog.GetTitleForQuestID
  if (not getQuestTitle) then return nil end

  local success, questTitle = pcall(getQuestTitle, questId)
  if (success) then return questTitle end
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

function Api.IsGamepadUIEnabled()
  return GetCVar and GetCVar("InputDeviceInterfaceStyle") == "1"
end

function Api.IsWoWForever()
  local _, _, _, interfaceVersion = GetBuildInfo()
  return interfaceVersion > 16000 and interfaceVersion < 20000
end

function Api.RegisterTooltipHandler(scriptType, tooltipDataType, handler)
  if (Api.IsWoWForever() and TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType) then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType[tooltipDataType], handler)
  else
    GameTooltip:HookScript(scriptType, handler)
  end
end
