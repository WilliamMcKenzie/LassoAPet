-- Alpha Fish: World 1 Meadow's alpha (QM, Nov 6): the Fish 1.4x, yellow instead of blue,
-- about 10x rarer. Model from designs/animals/AlphaFish.bbmodel (tools/alpha_designs.py).

local Horse = require(script.Parent.Horse)
local AlphaFishModel = require(script.Parent.AlphaFishModel)

return Horse.variant("AlphaFish", AlphaFishModel, "Epic", {
	seat = Vector3.new(0, 9.07, -0.756),
	neck = { center = Vector3.new(0, 4.16, -4.91), radius = 3.591 },
})
