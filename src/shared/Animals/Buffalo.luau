-- Buffalo: World 1 Meadow's Rare (QM, Nov 6; was World 2's), Rhino-sized (tier 2). A tall dark
-- shaggy hump, a lower brown back half, a low head with a pale snout, a tuft and cream horns
-- out the sides to upturned points. Model from designs/animals/Buffalo.bbmodel
-- (tools/buffalo_meadow_design.py), converted into BuffaloModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local BuffaloModel = require(script.Parent.BuffaloModel)

return Horse.variant("Buffalo", BuffaloModel, "Rare", {
	seat = Vector3.new(0, 9.72, 2.16),
	neck = { center = Vector3.new(0, 5.67, -5.94), radius = 2.97 },
})
