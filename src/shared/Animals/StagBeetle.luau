-- Stag Beetle: World 1 Forest's Uncommon (QM, Nov 7: one of the luck-padding animals QM picked).
-- Model from tools/filler_forest.py (stag_beetle), rigged by tools/filler_export.py into
-- designs/filler/rigged/StagBeetle.bbmodel and converted into StagBeetleModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local StagBeetleModel = require(script.Parent.StagBeetleModel)

return Horse.variant("StagBeetle", StagBeetleModel, "Uncommon", {
	seat = Vector3.new(0, 4.31, 0.78),
	neck = { center = Vector3.new(0, 2.09, -3.66), radius = 1.48 },
})
