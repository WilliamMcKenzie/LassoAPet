-- Buffalo: World 2 Meadow's second Rare, Rhino-sized (tier 2). A shaggy dark hump and
-- head, lighter brown back half, pale snout, cream horns turning up at grey tips, a beard,
-- shaggy front-leg cuffs and a tasselled tail. Model from designs/world2/Buffalo.bbmodel
-- (tools/buffalo_design.py, from QM's base), converted into BuffaloModel.luau by
-- tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local BuffaloModel = require(script.Parent.BuffaloModel)

return Horse.variant("Buffalo", BuffaloModel, "Rare", {
	seat = Vector3.new(0, 8.1, -0.15),
	neck = { center = Vector3.new(0, 5.7, -7.5), radius = 2.4 },
})
