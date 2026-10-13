-- Tiger: World 2 Temple's Rare. Bright orange coat with bold black stripe bands over the
-- back, legs, forehead and tail, white muzzle, cheeks, chest, belly and paws, a pink nose
-- and round ears. Model from designs/temple/Tiger.bbmodel (tools/tiger_design.py),
-- converted into TigerModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local TigerModel = require(script.Parent.TigerModel)

return Horse.variant("Tiger", TigerModel, "Rare", {
	seat = Vector3.new(0, 6.4, 0.9),
	neck = { center = Vector3.new(0, 5.6, -3.0), radius = 2.2 },
})
