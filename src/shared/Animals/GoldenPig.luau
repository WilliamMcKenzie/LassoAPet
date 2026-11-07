-- Golden Pig: World 1 Meadow's alpha (QM, Nov 6): the Pig 2x and gold, about 10x rarer.
-- Model from designs/animals/GoldenPig.bbmodel (tools/alpha_designs.py).

local Horse = require(script.Parent.Horse)
local GoldenPigModel = require(script.Parent.GoldenPigModel)

return Horse.variant("GoldenPig", GoldenPigModel, "Rare", {
	seat = Vector3.new(0, 12.8, 0.8),
	neck = { center = Vector3.new(0, 8.4, -7.8), radius = 3.8 },
})
