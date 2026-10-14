-- Animals sink a bit in water (QM, Oct 14; Config.WaterSink): Ride's place() draws a wild or
-- ridden animal this many studs lower (its rider, welded on, goes down with it). Only the
-- model moves: the ride still runs on the entity's x, z.
--
--   WaterSink(entity, now) -> studs, eased in and out
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local Ground = require(ReplicatedStorage.Shared.Ground)

local SINK = Config.WaterSink or {}
local RATE = SINK.Rate or 6
local MEASURE_EVERY = 1 -- s: how often an animal in the water has its height measured again (it can grow)

return function(entity, now)
	local water = Ground.waterAt(entity.x, entity.z)
	local fraction = water and SINK[water] or 0
	local want = 0
	if fraction > 0 then
		if not entity.sinkHeight or now - entity.sinkMeasured > MEASURE_EVERY then
			entity.sinkHeight, entity.sinkMeasured = entity.animal.model:GetExtentsSize().Y, now
		end
		want = fraction * entity.sinkHeight
	end
	local sink = entity.sink or 0
	if sink ~= want then
		sink += (want - sink) * (1 - math.exp(-RATE * (now - (entity.sinkAt or now))))
		if math.abs(sink - want) < 0.01 then
			sink = want
		end
	end
	entity.sink, entity.sinkAt = sink, now
	return sink
end
