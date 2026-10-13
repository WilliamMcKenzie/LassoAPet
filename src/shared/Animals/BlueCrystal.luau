-- BlueCrystal: a World 2 Crystal Cavern Living Crystal, the blue one. Uncommon.
-- A single crystal guy (shaft and pyramid tip) running on the Cactus's legs, arms and face.
-- Model and the Cactus's animations from designs/crystal/BlueCrystal.bbmodel (tools/living_crystal.py),
-- converted into BlueCrystalModel.luau by tools/bbmodel_to_luau.py. You ride on its tip.

local Horse = require(script.Parent.Horse)
local BlueCrystalModel = require(script.Parent.BlueCrystalModel)

return Horse.variant("BlueCrystal", BlueCrystalModel, "Uncommon", {
	seat = Vector3.new(0, 13.6, 0.2),
	neck = { center = Vector3.new(0, 9.5, 0), radius = 2.2 },
})
