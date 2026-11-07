-- Seal: World 1 Snow's Uncommon (QM, Nov 7: one of the luck-padding animals QM picked).
-- Model from tools/filler_tundra.py (seal), rigged by tools/filler_export.py into
-- designs/filler/rigged/Seal.bbmodel and converted into SealModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local SealModel = require(script.Parent.SealModel)

return Horse.variant("Seal", SealModel, "Uncommon", {
	seat = Vector3.new(0, 3.65, 2.19),
	neck = { center = Vector3.new(0, 3.84, -3.29), radius = 2.2 },
})
