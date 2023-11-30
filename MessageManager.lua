AutoBiographer_MessageManager = {
  AddonMessagePrefix = "AutoBiographer",
  SentMessageTimestamps = {},
}

local MM = AutoBiographer_MessageManager

local AceComm = LibStub:GetLibrary("AceComm-3.0")
local LibSerialize = LibStub("LibSerialize")
local LibDeflate = LibStub("LibDeflate")

function MM.OnAddonMessageReceived(prefix, text, channel, sender, target, zoneChannelID, localID, name, instanceID)
  --print(string.format("%s, %s, %s, %s", prefix, text, channel, sender))

  if (channel ~= "GUILD") then return end

  local decoded = LibDeflate:DecodeForWoWAddonChannel(text)
  if (not decoded) then return end
  local decompressed = LibDeflate:DecompressDeflate(decoded)
  if (not decompressed) then return end
  local success, message = LibSerialize:Deserialize(decompressed)
  if (not success) then return end

  local addonMessageType, arg1 = strsplit("!", message, 2)
  addonMessageType = tonumber(addonMessageType)

  if (addonMessageType == AutoBiographerEnum.AddonMessageType.CustomEvent) then
    if (AutoBiographer_Settings.Options["EnableCustomEventSharing"]) then
      local playerName = sender
      if (UnitName("player") == sender) then playerName = "You" end
      print("\124cFFFFD700[AutoBiographer] " .. tostring(playerName) .. " shared the following event: \"" .. HelperFunctions.ShortenString(arg1, 500) .. "\"")
    elseif (UnitName("player") == sender) then
      print("\124cFFFF0000[AutoBiographer] You shared a custom event, but you haven't enabled the option for guild members to share custom events with you.")
    end
  end
end

function MM.SendAddonMessage(addonMessageType, arg1)
  local nowTimestamp = GetTime()
  if (MM.SentMessageTimestamps[addonMessageType] and nowTimestamp - MM.SentMessageTimestamps[addonMessageType] < 10) then 
    print("\124cFFFF0000[AutoBiographer] Message not sent, you are sending messages too quickly.")
    return
  end
  MM.SentMessageTimestamps[addonMessageType] = nowTimestamp

  local message = addonMessageType
  if (arg1 ~= nil) then
    message = message .. "!" .. arg1
  end

  local serialized = LibSerialize:Serialize(message)
  local compressed = LibDeflate:CompressDeflate(serialized)
  local encoded = LibDeflate:EncodeForWoWAddonChannel(compressed)

  AceComm:SendCommMessage(MM.AddonMessagePrefix, encoded, "GUILD")
end

