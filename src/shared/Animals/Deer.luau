-- Deer: World 1 Forest's Rare (QM, Nov 7: one of the luck-padding animals QM picked).
-- Model from tools/filler_forest.py (deer), rigged by tools/filler_export.py into
-- designs/filler/rigged/Deer.bbmodel and converted into DeerModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local DeerModel = require(script.Parent.DeerModel)

return Horse.variant("Deer", DeerModel, "Rare", {
	seat = Vector3.new(0, 7, 0),
	neck = { center = Vector3.new(0, 9, -2.43), radius = 1.21 },
})
