-- Giraffe: World 1 Meadow's Epic (QM, Nov 7: one of the luck-padding animals QM picked).
-- Model from tools/filler_meadow.py (giraffe), rigged by tools/filler_export.py into
-- designs/filler/rigged/Giraffe.bbmodel and converted into GiraffeModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local GiraffeModel = require(script.Parent.GiraffeModel)

return Horse.variant("Giraffe", GiraffeModel, "Epic", {
	seat = Vector3.new(0, 8.1, 0),
	neck = { center = Vector3.new(0, 14.13, -2.34), radius = 1.25 },
})
