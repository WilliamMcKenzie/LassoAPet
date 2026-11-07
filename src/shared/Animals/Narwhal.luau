-- Narwhal: World 1 Snow's Epic (QM, Nov 7: one of the luck-padding animals QM picked).
-- Model from tools/filler_tundra.py (narwhal), rigged by tools/filler_export.py into
-- designs/filler/rigged/Narwhal.bbmodel and converted into NarwhalModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local NarwhalModel = require(script.Parent.NarwhalModel)

return Horse.variant("Narwhal", NarwhalModel, "Epic", {
	seat = Vector3.new(0, 3.91, 1.28),
	neck = { center = Vector3.new(0, 2.66, -2.38), radius = 1.61 },
})
