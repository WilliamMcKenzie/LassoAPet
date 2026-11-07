-- Snail: World 1 Meadow's Uncommon (QM, Nov 7: one of the luck-padding animals QM picked).
-- Model from tools/filler_meadow.py (snail), rigged by tools/filler_export.py into
-- designs/filler/rigged/Snail.bbmodel and converted into SnailModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local SnailModel = require(script.Parent.SnailModel)

return Horse.variant("Snail", SnailModel, "Uncommon", {
	seat = Vector3.new(0, 8.21, -0.63),
	neck = { center = Vector3.new(0, 5.6, -4.42), radius = 3.92 },
})
