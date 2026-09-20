AutoBiographer_Api = {}

local Api = AutoBiographer_Api

function Api.IsWoWForever()
  local _, _, _, interfaceVersion = GetBuildInfo()
  return interfaceVersion > 16000 and interfaceVersion < 20000
end

function Api.GetItemInfo(item)
  if (GetItemInfo) then
    return GetItemInfo(item)
  end

  if (C_Item and C_Item.GetItemInfo) then
    return C_Item.GetItemInfo(item)
  end
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

function Api.FormatMoney(amount)
  if (GetCoinText) then
    return GetCoinText(amount)
  end

  if (C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString) then
    return C_CurrencyInfo.GetCoinTextureString(amount)
  end

  return tostring(amount)
end

function Api.RegisterTooltipHandler(scriptType, tooltipDataType, handler)
  if (Api.IsWoWForever() and TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType) then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType[tooltipDataType], handler)
  else
    GameTooltip:HookScript(scriptType, handler)
  end
end

function Api.SupportsLegacySkillLines()
  return GetNumSkillLines ~= nil and GetSkillLineInfo ~= nil
end

function Api.GetNumSkillLines()
  if (GetNumSkillLines) then
    return GetNumSkillLines()
  end

  return 0
end

function Api.GetSkillLineInfo(skillIndex)
  if (GetSkillLineInfo) then
    return GetSkillLineInfo(skillIndex)
  end
end
