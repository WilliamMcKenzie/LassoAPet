-- Rat: World 1 Dungeon's Uncommon (QM, Nov 7: one of the luck-padding animals QM picked).
-- Model from tools/filler_dungeon.py (rat), rigged by tools/filler_export.py into
-- designs/filler/rigged/Rat.bbmodel and converted into RatModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local RatModel = require(script.Parent.RatModel)

return Horse.variant("Rat", RatModel, "Uncommon", {
	seat = Vector3.new(0, 4.4, 0),
	neck = { center = Vector3.new(0, 3.16, -4.53), radius = 1.75 },
})
