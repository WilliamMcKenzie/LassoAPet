-- Fortress Tortoise: World 1 Castle's Legendary (QM, Nov 7: one of the luck-padding animals QM picked).
-- Model from tools/filler_castle.py (fortress_tortoise), rigged by tools/filler_export.py into
-- designs/filler/rigged/FortressTortoise.bbmodel and converted into FortressTortoiseModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local FortressTortoiseModel = require(script.Parent.FortressTortoiseModel)

return Horse.variant("FortressTortoise", FortressTortoiseModel, "Legendary", {
	seat = Vector3.new(0, 6.63, -1.24),
	neck = { center = Vector3.new(0, 2.9, -4.28), radius = 1.0 },
})
