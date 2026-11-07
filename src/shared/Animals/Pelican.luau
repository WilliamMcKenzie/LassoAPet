-- Pelican: World 1 Ocean's Uncommon (QM, Nov 7: one of the luck-padding animals QM picked).
-- Model from tools/filler_ocean.py (pelican), rigged by tools/filler_export.py into
-- designs/filler/rigged/Pelican.bbmodel and converted into PelicanModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local PelicanModel = require(script.Parent.PelicanModel)

return Horse.variant("Pelican", PelicanModel, "Uncommon", {
	seat = Vector3.new(0, 6.63, 0.11),
	neck = { center = Vector3.new(0, 6.75, -1.3), radius = 1.0 },
})
