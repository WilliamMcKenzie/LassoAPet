-- Anglerfish: World 1 Ocean's Epic (QM, Nov 7: one of the luck-padding animals QM picked).
-- Model from tools/filler_ocean.py (anglerfish), rigged by tools/filler_export.py into
-- designs/filler/rigged/Anglerfish.bbmodel and converted into AnglerfishModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local AnglerfishModel = require(script.Parent.AnglerfishModel)

return Horse.variant("Anglerfish", AnglerfishModel, "Epic", {
	seat = Vector3.new(0, 5.67, 1.77),
	neck = { center = Vector3.new(0, 4.43, -3.19), radius = 1.43 },
})
