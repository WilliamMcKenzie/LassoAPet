-- PinkCrystal: a World 2 Crystal Cavern Living Crystal, the pink one. Rare.
-- A single crystal guy (shaft and pyramid tip) running on the Cactus's legs, arms and face.
-- Model and the Cactus's animations from designs/crystal/PinkCrystal.bbmodel (tools/living_crystal.py),
-- converted into PinkCrystalModel.luau by tools/bbmodel_to_luau.py. You ride on its tip.

local Horse = require(script.Parent.Horse)
local PinkCrystalModel = require(script.Parent.PinkCrystalModel)

return Horse.variant("PinkCrystal", PinkCrystalModel, "Rare", {
	seat = Vector3.new(0, 13.6, 0.2),
	neck = { center = Vector3.new(0, 9.5, 0), radius = 2.2 },
})
