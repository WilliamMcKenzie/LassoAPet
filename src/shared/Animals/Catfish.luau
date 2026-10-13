-- Catfish: World 2 Temple's Uncommon. The Fish in olive green with a cream belly, a wide flat
-- snout and long block whiskers, flopping along on its belly. Model from
-- designs/temple/Catfish.bbmodel (tools/catfish.py), converted into CatfishModel.luau by
-- tools/bbmodel_to_luau.py. Seat and neck loop as the Fish's.

local Horse = require(script.Parent.Horse)
local CatfishModel = require(script.Parent.CatfishModel)

return Horse.variant("Catfish", CatfishModel, "Uncommon", {
	seat = Vector3.new(0, 6.48, -0.54),
	neck = { center = Vector3.new(0, 2.97, -3.51), radius = 2.565 },
})
