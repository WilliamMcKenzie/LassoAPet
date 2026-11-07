-- Abyss Pillbug: World 1 Dungeon's Legendary (QM, Nov 7: one of the luck-padding animals QM picked).
-- Model from tools/filler_dungeon.py (abyss_pillbug), rigged by tools/filler_export.py into
-- designs/filler/rigged/AbyssPillbug.bbmodel and converted into AbyssPillbugModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local AbyssPillbugModel = require(script.Parent.AbyssPillbugModel)

return Horse.variant("AbyssPillbug", AbyssPillbugModel, "Legendary", {
	seat = Vector3.new(0, 4.03, 0.64),
	neck = { center = Vector3.new(0, 2.08, -5.12), radius = 1.29 },
})
