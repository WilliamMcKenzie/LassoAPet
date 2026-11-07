-- Ostrich: World 1 Desert's Epic (QM, Nov 7: one of the luck-padding animals QM picked).
-- Model from tools/filler_desert.py (ostrich), rigged by tools/filler_export.py into
-- designs/filler/rigged/Ostrich.bbmodel and converted into OstrichModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local OstrichModel = require(script.Parent.OstrichModel)

return Horse.variant("Ostrich", OstrichModel, "Epic", {
	seat = Vector3.new(0, 8.6, 0),
	neck = { center = Vector3.new(0, 12.56, -2.42), radius = 1.0 },
})
