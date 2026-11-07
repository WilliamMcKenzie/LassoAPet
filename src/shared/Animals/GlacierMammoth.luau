-- Glacier Mammoth: World 1 Snow's Legendary (QM, Nov 7: one of the luck-padding animals QM picked).
-- Model from tools/filler_tundra.py (glacier_mammoth), rigged by tools/filler_export.py into
-- designs/filler/rigged/GlacierMammoth.bbmodel and converted into GlacierMammothModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local GlacierMammothModel = require(script.Parent.GlacierMammothModel)

return Horse.variant("GlacierMammoth", GlacierMammothModel, "Legendary", {
	seat = Vector3.new(0, 8.36, 1.39),
	neck = { center = Vector3.new(0, 7.39, -3.9), radius = 2.0 },
})
