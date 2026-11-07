-- Coyote: World 1 Desert's Uncommon (QM, Nov 7: one of the luck-padding animals QM picked).
-- Model from tools/filler_desert.py (coyote), rigged by tools/filler_export.py into
-- designs/filler/rigged/Coyote.bbmodel and converted into CoyoteModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local CoyoteModel = require(script.Parent.CoyoteModel)

return Horse.variant("Coyote", CoyoteModel, "Uncommon", {
	seat = Vector3.new(0, 5.27, 0),
	neck = { center = Vector3.new(0, 5.66, -3.49), radius = 1.26 },
})
