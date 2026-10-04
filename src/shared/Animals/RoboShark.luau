-- Robo Shark: QM's riveted metal shark statue (cyan glowing eyes, gold marks, a jaw
-- hanging wide open, pyramid teeth, a bent tail). Legendary, Ocean, large (tier 3).
-- QM's file designs/ocean/RoboShark.bbmodel, animated by tools/robo_shark_rig.py and
-- converted with `tools/bbmodel_to_luau.py --zyx`. You ride on its back behind the
-- dorsal fin; at a run its jaw snaps shut on every tail beat.

local Horse = require(script.Parent.Horse)
local RoboSharkModel = require(script.Parent.RoboSharkModel)

return Horse.variant("RoboShark", RoboSharkModel, "Legendary", {
	seat = Vector3.new(0, 2.02, 0.5),
	neck = { center = Vector3.new(0, 1.64, -1.45), radius = 0.5 },
})
