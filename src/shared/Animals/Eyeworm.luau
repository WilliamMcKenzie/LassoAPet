-- Eyeworm: World 2's Crimson Lands Uncommon, a crimson worm with purple rings and one
-- yellow eye. designs/crimson/Eyeworm.bbmodel (tools/crimson_worm.py, which also
-- animates it with the Sandworm's slither), converted into EyewormModel.luau by
-- tools/bbmodel_to_luau.py. You ride its front segment.

local Horse = require(script.Parent.Horse)
local EyewormModel = require(script.Parent.EyewormModel)

return Horse.variant("Eyeworm", EyewormModel, "Uncommon", {
	seat = Vector3.new(0, 3.6, 1.35),
	neck = { center = Vector3.new(0, 2.2, -2.1), radius = 2.7 },
})
