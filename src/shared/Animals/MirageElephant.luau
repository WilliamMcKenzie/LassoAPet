-- Mirage Elephant: World 1 Desert's Legendary (QM, Nov 7: one of the luck-padding animals QM picked).
-- Model from tools/filler_desert.py (mirage_elephant), rigged by tools/filler_export.py into
-- designs/filler/rigged/MirageElephant.bbmodel and converted into MirageElephantModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local MirageElephantModel = require(script.Parent.MirageElephantModel)

return Horse.variant("MirageElephant", MirageElephantModel, "Legendary", {
	seat = Vector3.new(0, 13.65, 0),
	neck = { center = Vector3.new(0, 12.55, -2.8), radius = 1.47 },
})
