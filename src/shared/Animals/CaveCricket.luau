-- Cave Cricket: World 1 Dungeon's Uncommon (QM, Nov 7: one of the luck-padding animals QM picked).
-- Model from tools/filler_dungeon.py (cave_cricket), rigged by tools/filler_export.py into
-- designs/filler/rigged/CaveCricket.bbmodel and converted into CaveCricketModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local CaveCricketModel = require(script.Parent.CaveCricketModel)

return Horse.variant("CaveCricket", CaveCricketModel, "Uncommon", {
	seat = Vector3.new(0, 3.87, 1.33),
	neck = { center = Vector3.new(0, 2.42, -3.02), radius = 1.28 },
})
