-- Rolling Log: World 2's Woodland Maze Rare, a fat living log lying across the path with
-- a grin on its bark, ringed cut ends and a tuft of autumn leaves on top. Model from
-- designs/woodland/RollingLog.bbmodel (tools/rolling_log.py), converted into
-- RollingLogModel.luau by tools/bbmodel_to_luau.py. Only its Log bone moves (idle and walk
-- rock it, the gallop rolls it), so the rider on top (on root) stays upright.

local Horse = require(script.Parent.Horse)
local RollingLogModel = require(script.Parent.RollingLogModel)

return Horse.variant("RollingLog", RollingLogModel, "Rare", {
	seat = Vector3.new(0, 5.3, 0),
	neck = { center = Vector3.new(0, 2.5, 0), radius = 2.9 },
})
