-- RafflesiaBeast: World 3's Garden Legendary (Oct 14; roster approved by the coordinator for QM): a giga rare, 1 in 1,000 of the Garden's stampede: a hulking moss beast
-- carrying a giant warty corpse flower on its back, pyramid fangs and root claws. You ride in
-- the flower's well.
-- designs/garden/RafflesiaBeast.bbmodel (tools/garden_rafflesia.py), converted (--zyx) into RafflesiaBeastModel.luau by
-- tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local RafflesiaBeastModel = require(script.Parent.RafflesiaBeastModel)

return Horse.variant("RafflesiaBeast", RafflesiaBeastModel, "Legendary", {
	seat = Vector3.new(0, 16.3, 0.5),
	neck = { center = Vector3.new(0, 12.0, -12.0), radius = 5.3 },
})
