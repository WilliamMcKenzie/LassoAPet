-- RedMushroom: a World 2 Crystal Cavern Living Mushroom, the small red one with white spots. Uncommon.
-- A fat cream mushroom guy on stubby legs under a domed cap. Model from
-- designs/crystal/RedMushroom.bbmodel (tools/living_mushroom.py, animated by tools/living_mushroom_rig.py),
-- converted into RedMushroomModel.luau by tools/bbmodel_to_luau.py. You ride on its cap.

local Horse = require(script.Parent.Horse)
local RedMushroomModel = require(script.Parent.RedMushroomModel)

return Horse.variant("RedMushroom", RedMushroomModel, "Uncommon", {
	seat = Vector3.new(0, 5.16, 0),
	neck = { center = Vector3.new(0, 3.76, 0), radius = 2.05 },
})
