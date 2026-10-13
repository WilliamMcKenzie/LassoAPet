-- BrownMushroom: a World 2 Crystal Cavern Living Mushroom, the medium brown one. Rare.
-- A fat cream mushroom guy on stubby legs under a domed cap. Model from
-- designs/crystal/BrownMushroom.bbmodel (tools/living_mushroom.py, animated by tools/living_mushroom_rig.py),
-- converted into BrownMushroomModel.luau by tools/bbmodel_to_luau.py. You ride on its cap.

local Horse = require(script.Parent.Horse)
local BrownMushroomModel = require(script.Parent.BrownMushroomModel)

return Horse.variant("BrownMushroom", BrownMushroomModel, "Rare", {
	seat = Vector3.new(0, 7.1, 0),
	neck = { center = Vector3.new(0, 5.17, 0), radius = 2.72 },
})
