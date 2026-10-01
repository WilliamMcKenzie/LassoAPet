-- PolarBear: a big hunched white bear, black nose, dark claws. Epic.
-- QM's model designs/snow/PolarBear.bbmodel (the hunch is in its bones' rest rotations),
-- animated by tools/snow_rig.py (the gallop is the leap) and converted into
-- PolarBearModel.luau by tools/bbmodel_to_luau.py. You ride on top of its shoulder hump.

local Horse = require(script.Parent.Horse)
local PolarBearModel = require(script.Parent.PolarBearModel)

return Horse.variant("PolarBear", PolarBearModel, "Epic", {
	seat = Vector3.new(0, 12.8, -0.5),
	neck = { center = Vector3.new(0, 8, -6.2), radius = 2.8 },
})
