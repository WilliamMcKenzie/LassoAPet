-- Griffin: World 1 Castle's Epic (QM, Nov 7: one of the luck-padding animals QM picked).
-- Model from tools/filler_castle.py (griffin), rigged by tools/filler_export.py into
-- designs/filler/rigged/Griffin.bbmodel and converted into GriffinModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local GriffinModel = require(script.Parent.GriffinModel)

return Horse.variant("Griffin", GriffinModel, "Epic", {
	seat = Vector3.new(0, 4.42, 0),
	neck = { center = Vector3.new(0, 5.21, -2.83), radius = 1.06 },
})
