-- PurpleMushroom: a World 2 Crystal Cavern Living Mushroom, the giant purple one with white spots. Epic.
-- A fat cream mushroom guy on stubby legs under a domed cap. Model from
-- designs/crystal/PurpleMushroom.bbmodel (tools/living_mushroom.py, animated by tools/living_mushroom_rig.py),
-- converted into PurpleMushroomModel.luau by tools/bbmodel_to_luau.py. You ride on its cap.

local Horse = require(script.Parent.Horse)
local PurpleMushroomModel = require(script.Parent.PurpleMushroomModel)

return Horse.variant("PurpleMushroom", PurpleMushroomModel, "Epic", {
	seat = Vector3.new(0, 9.68, 0),
	neck = { center = Vector3.new(0, 7.05, 0), radius = 3.99 },
})
