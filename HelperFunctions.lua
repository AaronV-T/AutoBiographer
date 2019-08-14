HelperFunctions = {}
local HF = HelperFunctions


function HF.GetCatalogIdFromGuid(guid)
  if guid == nil then return nil end

  local index = 0
  local splitGuid = {}
  for text in string.gmatch(guid, "[%w|%d]+") do
    index = index + 1
    splitGuid[index] = text
  end
   
  if splitGuid[1] == "Player" then return splitGuid[2] .. "-" .. splitGuid[3] -- serverID-playerUID
  elseif splitGuid[1] == "Creature" or "Pet" then return tonumber(splitGuid[6]) -- ID
  else error("Unsupported GUID: " .. guid)
  end
end

function HF.GetCoordinatesByUnitId(unitId)
  local mapId = C_Map.GetBestMapForUnit(unitId)
  
  if (mapId == nil) then return nil end
  
  local position = C_Map.GetPlayerMapPosition(mapId, unitId)
  
  if (position == nil) then return nil end
  
  return Coordinates.New(mapId, HF.Round(position.x * 100, 2), HF.Round(position.y * 100, 2))
end

-- Lua Helpers

function HF.Round(number, precision)
  if (not precision) then precision = 0 end
  
  local factor = math.pow(10, precision)
  
  number = number * factor
  number = math.floor(number + 0.5)
  return number / factor
end

function HF.GetKeysFromTable(tab)
  if tab == nil then return nil end

  local keys = {}
  local index = 0
  for k,v in pairs(tab) do
    index = index + 1 
    keys[index] = k
  end
  
  table.sort(keys)
  
  return keys
end

function HF.PrintKeysAndValuesFromTable(tab)
  if tab == nil then return end

  for k,v in pairs(tab) do
    print(k .. ": " .. tostring(v))
  end
end

function HF.GetLastKeyFromTable(tab)
  local keys = HF.GetKeysFromTable(tab)
  return keys[#keys]
end

-- Text Formatting Helpers

function HF.SecondsToTimeString(totalSeconds)
  if totalSeconds == nil then return "" end

  local days = math.floor(totalSeconds / 86400)
  local hours = math.floor(totalSeconds / 3600) % 24
  local minutes = math.floor(totalSeconds / 60) % 60
  local seconds = totalSeconds % 60
  
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