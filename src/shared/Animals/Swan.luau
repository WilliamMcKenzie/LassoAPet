-- Swan: World 1 Castle's Uncommon (QM, Nov 7: one of the luck-padding animals QM picked).
-- Model from tools/filler_castle.py (swan), rigged by tools/filler_export.py into
-- designs/filler/rigged/Swan.bbmodel and converted into SwanModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local SwanModel = require(script.Parent.SwanModel)

return Horse.variant("Swan", SwanModel, "Uncommon", {
	seat = Vector3.new(0, 3.94, 0.72),
	neck = { center = Vector3.new(0, 7.96, -3.76), radius = 1.2 },
})
