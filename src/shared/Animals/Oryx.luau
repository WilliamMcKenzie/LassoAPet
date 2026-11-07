-- Oryx: World 1 Desert's Rare (QM, Nov 7: one of the luck-padding animals QM picked).
-- Model from tools/filler_desert.py (oryx), rigged by tools/filler_export.py into
-- designs/filler/rigged/Oryx.bbmodel and converted into OryxModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local OryxModel = require(script.Parent.OryxModel)

return Horse.variant("Oryx", OryxModel, "Rare", {
	seat = Vector3.new(0, 6.6, 0),
	neck = { center = Vector3.new(0, 8.36, -2.47), radius = 1.25 },
})
