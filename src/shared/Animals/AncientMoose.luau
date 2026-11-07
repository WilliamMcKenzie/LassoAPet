-- Ancient Moose: World 1 Forest's Legendary (QM, Nov 7: one of the luck-padding animals QM picked).
-- Model from tools/filler_forest.py (ancient_moose), rigged by tools/filler_export.py into
-- designs/filler/rigged/AncientMoose.bbmodel and converted into AncientMooseModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local AncientMooseModel = require(script.Parent.AncientMooseModel)

return Horse.variant("AncientMoose", AncientMooseModel, "Legendary", {
	seat = Vector3.new(0, 8.56, 0.01),
	neck = { center = Vector3.new(0, 9.03, -2.89), radius = 1.36 },
})
