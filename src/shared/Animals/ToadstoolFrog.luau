-- ToadstoolFrog: World 3's Garden Rare (Oct 14; roster approved by the coordinator for QM): a fat lime frog wearing a giant purple toadstool with white spots for a hat;
-- it hops. You ride on the cap (it's on the neck bone).
-- designs/garden/ToadstoolFrog.bbmodel (tools/garden_frog.py), converted (--zyx) into ToadstoolFrogModel.luau by
-- tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local ToadstoolFrogModel = require(script.Parent.ToadstoolFrogModel)

return Horse.variant("ToadstoolFrog", ToadstoolFrogModel, "Rare", {
	seat = Vector3.new(0, 12.0, -2.1),
	seatBone = "neck",
	neck = { center = Vector3.new(0, 4.6, -3.0), radius = 3.8 },
})
