-- RafflesiaBeast: World 3's Garden Legendary (Oct 14; roster approved by the coordinator for QM): a giga rare, 1 in 1,000 of the Garden's stampede: a moss beast whose head is
-- a giant warty corpse flower on a long stem neck (QM's Blockbench edit, Oct 15, now the source), root claws
-- and a vine tail with a bud. You ride on its back.
-- designs/garden/RafflesiaBeast.bbmodel (tools/garden_rafflesia.py), converted (--zyx) into RafflesiaBeastModel.luau by
-- tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local RafflesiaBeastModel = require(script.Parent.RafflesiaBeastModel)

return Horse.variant("RafflesiaBeast", RafflesiaBeastModel, "Legendary", {
	seat = Vector3.new(0, 15.0, 1.5),
	neck = { center = Vector3.new(0, 17.8, -10.6), radius = 2.5 },
})
