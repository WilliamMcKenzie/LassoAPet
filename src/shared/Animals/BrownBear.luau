-- Brown Bear: World 1 Forest's Epic (QM, Nov 7: one of the luck-padding animals QM picked).
-- Model from tools/filler_forest.py (brown_bear), rigged by tools/filler_export.py into
-- designs/filler/rigged/BrownBear.bbmodel and converted into BrownBearModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local BrownBearModel = require(script.Parent.BrownBearModel)

return Horse.variant("BrownBear", BrownBearModel, "Epic", {
	seat = Vector3.new(0, 7.37, 0),
	neck = { center = Vector3.new(0, 6.69, -4.53), radius = 1.83 },
})
