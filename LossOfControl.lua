AutoBiographer_LossOfControl = {
  Active = false,
  PendingStatistics = {},
}

local Tracking = AutoBiographer_LossOfControl
local Controller = AutoBiographer_Controller
local EM = AutoBiographer_EventManager
local Api = AutoBiographer_Api
local CountType = AutoBiographerEnum.MiscellaneousTrackingType.LossOfControlApplications
local TimeType = AutoBiographerEnum.TimeTrackingType.LossOfControl

function Tracking:GetStatistics()
  local statistics = Controller.CharacterData.Levels[self.LevelNum]
  if (statistics) then return statistics end
  -- A played-time response can create the new level after its first effects.
  if (not self.PendingStatistics[self.LevelNum]) then
    self.PendingStatistics[self.LevelNum] = { MiscellaneousStatistics = {}, TimeStatisticsByArea = {} }
  end
  return self.PendingStatistics[self.LevelNum]
end

function Tracking:FlushPending()
  for levelNum, pending in pairs(self.PendingStatistics) do
    local statistics = Controller.CharacterData.Levels[levelNum]
    if (statistics) then
      local count = pending.MiscellaneousStatistics[CountType]
      if (count) then MiscellaneousStatistics.Add(statistics.MiscellaneousStatistics, CountType, count) end
      for area, times in pairs(pending.TimeStatisticsByArea) do
        if (not statistics.TimeStatisticsByArea[area]) then statistics.TimeStatisticsByArea[area] = TimeStatistics.New() end
        TimeStatistics.AddTime(statistics.TimeStatisticsByArea[area], TimeType, times[TimeType])
      end
      self.PendingStatistics[levelNum] = nil
    end
  end
end

function Tracking:Flush(zone, subZone)
  self:FlushPending()
  if (not self.StartedAt) then return end
  local now = GetTime()
  local seconds = math.max(0, now - self.StartedAt)
  self.StartedAt = now
  if (seconds <= 0) then return end
  local info = EM.PersistentPlayerInfo
  local area = tostring(zone or info.CurrentZone) .. "-" .. tostring(subZone or info.CurrentSubZone)
  local statistics = self:GetStatistics()
  if (not statistics.TimeStatisticsByArea[area]) then statistics.TimeStatisticsByArea[area] = TimeStatistics.New() end
  TimeStatistics.AddTime(statistics.TimeStatisticsByArea[area], TimeType, seconds)
end

function Tracking:Update(applicationAdded)
  if (not self.Active) then return end
  self:Flush()
  if (applicationAdded) then MiscellaneousStatistics.Add(self:GetStatistics().MiscellaneousStatistics, CountType, 1) end
  local count = Api.GetPlayerLossOfControlCount()
  -- One timer covers all overlapping effects. An unreadable count pauses it;
  -- effect categories and spell details are never queried.
  self.StartedAt = count and count > 0 and GetTime() or nil
end

function Tracking:SetLevel(levelNum)
  self:Flush()
  self.LevelNum = levelNum
end

function Tracking:Start()
  if (self.Active) then return end
  self.Active = true
  self.LevelNum = EM.NewLevelToAddToHistory or Controller:GetCurrentLevelNum()
  self:Update()
end

function Tracking:Stop()
  self:Flush()
  self.Active = false
  self.StartedAt = nil
end
