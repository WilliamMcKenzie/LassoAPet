-- AncientTreant: World 3's Garden Legendary (Oct 14; roster approved by the coordinator for QM): a giga rare, 1 in 1,000 of the Garden's stampede: a towering walking tree
-- with a face in its bark, a moss beard, twig fingers and a blossom-dotted canopy. You ride on
-- the canopy (the neck bone).
-- designs/garden/AncientTreant.bbmodel (tools/garden_treant.py), converted (--zyx) into AncientTreantModel.luau by
-- tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local AncientTreantModel = require(script.Parent.AncientTreantModel)

return Horse.variant("AncientTreant", AncientTreantModel, "Legendary", {
	seat = Vector3.new(0, 35.4, 0),
	seatBone = "neck",
	neck = { center = Vector3.new(0, 20.2, 0), radius = 5.1 },
})
