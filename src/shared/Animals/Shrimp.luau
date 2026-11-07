-- Shrimp: World 1 Ocean's Uncommon (QM, Nov 7: one of the luck-padding animals QM picked).
-- Model from tools/filler_ocean.py (shrimp), rigged by tools/filler_export.py into
-- designs/filler/rigged/Shrimp.bbmodel and converted into ShrimpModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local ShrimpModel = require(script.Parent.ShrimpModel)

return Horse.variant("Shrimp", ShrimpModel, "Uncommon", {
	seat = Vector3.new(0, 4.86, 1.78),
	neck = { center = Vector3.new(0, 3.24, -5.18), radius = 4.94 },
})
