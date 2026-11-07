-- Walrus: World 1 Snow's Rare (QM, Nov 7: one of the luck-padding animals QM picked).
-- Model from tools/filler_tundra.py (walrus), rigged by tools/filler_export.py into
-- designs/filler/rigged/Walrus.bbmodel and converted into WalrusModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local WalrusModel = require(script.Parent.WalrusModel)

return Horse.variant("Walrus", WalrusModel, "Rare", {
	seat = Vector3.new(0, 5.08, 1.85),
	neck = { center = Vector3.new(0, 4.61, -3.69), radius = 1.98 },
})
