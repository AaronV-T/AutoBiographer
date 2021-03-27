HelperFunctions = {}
local HF = HelperFunctions

local Hbd = LibStub("HereBeDragons-2.0")
local HbdPins = LibStub("HereBeDragons-Pins-2.0")

function HF.GetCatalogIdFromGuid(guid)
  if (not guid) then return nil end

  local splitGuid = HF.SplitString(guid)
  
  if splitGuid[1] == "GameObject" then return "go" .. splitGuid[6] -- goID
  elseif splitGuid[1] == "Player" then return splitGuid[2] .. "-" .. splitGuid[3] -- serverID-playerUID
  elseif splitGuid[1] == "Pet" then return "pet" .. splitGuid[6] -- petID
  elseif splitGuid[1] == "Creature" then return tonumber(splitGuid[6]) -- ID
  else error("Unsupported GUID: " .. guid)
  end
end

function HF.GetCoordinatesByUnitId(unitId)
  local worldX, worldY, worldInstance = Hbd:GetUnitWorldPosition(unitId)

  local mapId = C_Map.GetBestMapForUnit(unitId)
  local x = nil
  local y = nil

  if (mapId) then
    local position = C_Map.GetPlayerMapPosition(mapId, unitId)
    if (position) then
      x = HF.Round(position.x * 100, 2)
      y = HF.Round(position.y * 100, 2)
    end
  end

  return Coordinates.New(worldInstance, mapId, x, y)
end

function HF.GetUnitTypeFromCatalogUnitId(cuid)
  if (string.match(cuid, "go%d+")) then
    return AutoBiographerEnum.UnitType.GameObject
  elseif (string.match(cuid, "%w+%-%w+")) then
    return AutoBiographerEnum.UnitType.Player
  elseif (string.match(cuid, "pet%d+")) then
    return AutoBiographerEnum.UnitType.Pet
  else
    return AutoBiographerEnum.UnitType.Creature
  end
end

-- Lua Helpers

function HF.RemoveElementsFromArrayAtIndexes(array, indexesToRemove)
  local originalLength = #array

  -- Delete entries in the array.
  for i = 1, originalLength do
    if (indexesToRemove[i]) then
      array[i] = nil
    end
  end

  -- Compact the array.
  local j = 0
  for i = 1, originalLength do
    if (array[i] ~= nil) then
      j = j + 1
      array[j] = array[i]
    end
  end
  for i = j + 1, originalLength do
    array[i] = nil
  end
end

function HF.Round(number, precision)
  if (not precision) then precision = 0 end
  
  local factor = math.pow(10, precision)
  
  number = number * factor
  number = math.floor(number + 0.5)
  return number / factor
end

function HF.SplitString(str)
  local index = 0
  local splitString = {}
  for text in string.gmatch(str, "[%w|%d]+") do
    index = index + 1
    splitString[index] = text
  end
  
  return splitString
end

function HF.GetKeysFromTable(tab, sort)
  if (not tab) then return nil end
  
  local keys = {}
  local index = 0
  for k,v in pairs(tab) do
    index = index + 1 
    keys[index] = k
  end
  
  if (sort) then table.sort(keys) end
  
  return keys
end

function HF.GetKeysFromTableReverse(tab, sort)
  if (not tab) then return nil end
  
  local keys = HF.GetKeysFromTable(tab, sort)
  local reverseKeys = {}
  local index = 0
  for i = #keys, 1, -1 do
    index = index + 1
    reverseKeys[index] = keys[i]
  end
  
  return reverseKeys
end

function HF.PrintKeysAndValuesFromTable(tab, noRecurse, indentLevel)
  if tab == nil then return end

  local indentation = ""
  if (not indentLevel) then
    indentLevel = 0
  end

  for i = 1, indentLevel do
    indentation = indentation .. "  "
  end

  for k,v in pairs(tab) do
    print(indentation .. k .. ": " .. tostring(v))

    if (not noRecurse and type(v) == "table") then
      HF.PrintKeysAndValuesFromTable(v, noRecurse, indentLevel + 1)
    end
  end
end

function HF.GetLastKeyFromTable(tab)
  local keys = HF.GetKeysFromTable(tab, true)
  return keys[#keys]
end

function HF.SubtractFloats(left, right, precision)
  if (not precision) then precision = 1 end
  
  local difference = left - right
  return HF.Round(difference, precision)
end

-- Text Formatting Helpers

function HF.CommaValue(n) -- credit http://richard.warburton.it
	local left,num,right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
	return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
end

function HF.SecondsToTimeString(totalSeconds)
  if totalSeconds == nil then return "" end

  local days = math.floor(totalSeconds / 86400)
  local hours = math.floor(totalSeconds / 3600) % 24
  local minutes = math.floor(totalSeconds / 60) % 60
  local seconds = HF.Round(totalSeconds % 60)
  
  local printDays = false
  local printHours = false
  local printMinutes = false
  
  if (days > 0) then 
    printDays = true
    printHours = true
    printMinutes = true 
  elseif (hours > 0) then 
    printHours = true
    printMinutes = true 
  elseif (minutes > 0) then
    printMinutes = true
  end
  
  local returnString = ""
  
  if printDays then
    returnString = returnString .. days .. " day"
    if days ~= 1 then returnString = returnString .. "s" end
    returnString = returnString .. ", "
  end
  
  if printHours then
    returnString = returnString .. hours .. " hour"
    if hours ~= 1 then returnString = returnString .. "s" end
    returnString = returnString .. ", "
  end
  
  if printMinutes then
    returnString = returnString .. minutes .. " minute"
    if minutes ~= 1 then returnString = returnString .. "s" end
    returnString = returnString .. ", "
  end
  
  returnString = returnString .. seconds .. " second"
  if seconds ~= 1 then returnString = returnString .. "s" end
  
  return returnString
end

function HF.TimestampToDateString(timestamp)
  if timestamp == nil then return "" end
  
  return date("%m/%d/%y %H:%M:%S", timestamp)
end