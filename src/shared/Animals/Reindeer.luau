-- Reindeer: World 1 Snow's Rare (QM, Nov 7: one of the luck-padding animals QM picked).
-- Model from tools/filler_tundra.py (reindeer), rigged by tools/filler_export.py into
-- designs/filler/rigged/Reindeer.bbmodel and converted into ReindeerModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local ReindeerModel = require(script.Parent.ReindeerModel)

return Horse.variant("Reindeer", ReindeerModel, "Rare", {
	seat = Vector3.new(0, 6.75, 0),
	neck = { center = Vector3.new(0, 8.44, -2.48), radius = 1.27 },
})
