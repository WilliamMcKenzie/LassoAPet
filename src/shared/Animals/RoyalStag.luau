-- Royal Stag: World 1 Castle's Rare (QM, Nov 7: one of the luck-padding animals QM picked).
-- Model from tools/filler_castle.py (royal_stag), rigged by tools/filler_export.py into
-- designs/filler/rigged/RoyalStag.bbmodel and converted into RoyalStagModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local RoyalStagModel = require(script.Parent.RoyalStagModel)

return Horse.variant("RoyalStag", RoyalStagModel, "Rare", {
	seat = Vector3.new(0, 6.87, -0.03),
	neck = { center = Vector3.new(0, 8.66, -2.4), radius = 1.11 },
})
