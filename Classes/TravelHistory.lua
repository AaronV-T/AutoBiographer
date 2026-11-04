TravelHistory = {}

local VERSION = 1
local MAX_POINTS_PER_SEGMENT = 256
local UNITS_PER_YARD = 4

function TravelHistory.New()
  return { Version = VERSION, Segments = {} }
end

function TravelHistory.Record(history, active, sample, continuesPrevious)
  if (not history or history.Version ~= VERSION or type(history.Segments) ~= "table") then return nil end

  local x = math.floor(sample.X * UNITS_PER_YARD + 0.5)
  local y = math.floor(sample.Y * UNITS_PER_YARD + 0.5)
  local segment = active and active.Segment
  if (continuesPrevious and segment
    and segment.InstanceId == sample.InstanceId and segment.MapId == sample.MapId
    and segment.LevelNum == sample.LevelNum and segment.TrackingType == sample.TrackingType) then
    local offsetSeconds = math.floor(sample.Timestamp - active.StartedAt)
    local deltaX, deltaY = x - active.LastX, y - active.LastY
    if (deltaX == 0 and deltaY == 0) then
      segment.EndOffsetSeconds = offsetSeconds
      return active
    end

    local heldPosition = segment.EndOffsetSeconds > active.LastPointOffsetSeconds
    local pointsNeeded = heldPosition and 2 or 1
    if (active.PointCount + pointsNeeded <= MAX_POINTS_PER_SEGMENT) then
      -- Each triple is whole seconds since the first sample, then X and Y deltas in quarter-yards.
      -- A zero-delta point just before movement preserves the end of a stationary pause.
      local points = ""
      if (heldPosition) then points = string.format("%d,0,0;", segment.EndOffsetSeconds) end
      segment.Points = segment.Points .. points .. string.format("%d,%d,%d;", offsetSeconds, deltaX, deltaY)
      segment.EndOffsetSeconds = offsetSeconds
      active.LastPointOffsetSeconds = offsetSeconds
      active.LastX, active.LastY = x, y
      active.PointCount = active.PointCount + pointsNeeded
      return active
    end
  end

  segment = {
    StartTime = time(),
    InstanceId = sample.InstanceId,
    MapId = sample.MapId,
    LevelNum = sample.LevelNum,
    TrackingType = sample.TrackingType,
    ContinuesPrevious = continuesPrevious and active ~= nil,
    -- Raw world coordinates in yards, in the coordinate space of InstanceId.
    StartX = x / UNITS_PER_YARD,
    StartY = y / UNITS_PER_YARD,
    EndOffsetSeconds = 0,
    Points = "",
  }
  table.insert(history.Segments, segment)
  return {
    Segment = segment,
    StartedAt = sample.Timestamp,
    LastX = x,
    LastY = y,
    LastPointOffsetSeconds = 0,
    PointCount = 0,
  }
end
