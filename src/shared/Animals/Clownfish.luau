-- Clownfish: the Fish in clownfish orange with three white bands edged in black (QM, Oct 11).
-- Uncommon, Ocean. designs/ocean/Clownfish.bbmodel (tools/clownfish.py: the Fish's shapes,
-- bones and flops), converted into ClownfishModel.luau by tools/bbmodel_to_luau.py. You sit
-- where you sit on the Fish.

local Horse = require(script.Parent.Horse)
local ClownfishModel = require(script.Parent.ClownfishModel)

return Horse.variant("Clownfish", ClownfishModel, "Uncommon", {
	seat = Vector3.new(0, 6.48, -0.54),
	neck = { center = Vector3.new(0, 2.97, -3.51), radius = 2.565 },
})
