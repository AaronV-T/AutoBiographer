-- AutoBiographer localization core.
-- Usage:  L["English text"]             -> translated text (falls back to the English key)
--         L("English %s text", value)    -> string.format on the translated text
--
-- German is used automatically on a German (deDE) game client.
-- To force German on a client with another language, set this to true:
AutoBiographer_ForceGerman = false

local L = {}
AutoBiographer_L = setmetatable(L, {
  __index = function(_, key) return key end,
  __call = function(self, key, ...) return string.format(self[key], ...) end,
})

L.IsGerman = AutoBiographer_ForceGerman or GetLocale() == "deDE"

function L.Add(translations)
  if (not L.IsGerman) then return end
  for english, translated in pairs(translations) do
    rawset(L, english, translated)
  end
end

-- Helpers for reading game chat messages in any client language.
-- They turn Blizzard GlobalStrings formats (e.g. ERR_SKILL_UP_SI = "Your skill in %s has increased to %d.")
-- into Lua patterns, so messages are recognized on German and English clients alike.
local patternCache = {}
local function BuildPattern(formatString)
  local cached = patternCache[formatString]
  if (cached) then return cached[1], cached[2] end
  local order, count = {}, 0
  local pattern = formatString:gsub("%%(%d*)%$?([sd])", function(position, kind)
    count = count + 1
    order[count] = tonumber(position) or count
    return kind == "d" and "\1" or "\2"
  end)
  pattern = pattern:gsub("([%(%)%.%+%-%*%?%[%]%^%$%%])", "%%%1")
  pattern = pattern:gsub("\1", "(%%d+)"):gsub("\2", "(.-)")
  patternCache[formatString] = { pattern, order }
  return pattern, order
end

-- Returns the values of the format's placeholders in argument order (%1$s, %2$s, ...), or nil if the text does not match.
function L.MatchFormat(text, formatString)
  if (type(text) ~= "string" or type(formatString) ~= "string") then return nil end
  local pattern, order = BuildPattern((formatString:gsub("%.$", "")))
  local captures = { string.match(text, "^" .. pattern .. "%.?$") }
  if (#captures == 0) then return nil end
  local values = {}
  for i, value in ipairs(captures) do values[order[i] or i] = value end
  return unpack(values, 1, #captures)
end

-- True if the text begins with the fixed part of the format (the text before its first placeholder).
function L.StartsWithFormat(text, formatString)
  if (type(text) ~= "string" or type(formatString) ~= "string") then return false end
  local prefix = formatString:match("^(.-)%%") or formatString
  return prefix ~= "" and string.sub(text, 1, #prefix) == prefix
end

-- True if the text contains the fixed part of the format before its first placeholder.
function L.ContainsFormat(text, formatString)
  if (type(text) ~= "string" or type(formatString) ~= "string") then return false end
  local prefix = formatString:match("^(.-)%%") or formatString
  return prefix ~= "" and string.find(text, prefix, 1, true) ~= nil
end
