-- Crocodile: World 2 Meadow's Rare. Low and long, green with a pale belly, jaws held open
-- with pyramid teeth, eye bumps with googly eyes and brows on top of the head, dark scutes
-- down the back and a long tapering tail. Model from designs/world2/Crocodile.bbmodel (QM's
-- edit of tools/crocodile_design.py), converted into CrocodileModel.luau by
-- tools/bbmodel_to_luau.py --zyx.

local Horse = require(script.Parent.Horse)
local CrocodileModel = require(script.Parent.CrocodileModel)

return Horse.variant("Crocodile", CrocodileModel, "Rare", {
	seat = Vector3.new(0, 3.6, 0.2),
	neck = { center = Vector3.new(0, 1.9, -6.2), radius = 1.5 },
})
