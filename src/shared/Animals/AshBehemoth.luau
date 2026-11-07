-- Ash Behemoth: World 1 Volcano's Legendary (QM, Nov 7: one of the luck-padding animals QM picked).
-- Model from tools/filler_volcano.py (ash_behemoth), rigged by tools/filler_export.py into
-- designs/filler/rigged/AshBehemoth.bbmodel and converted into AshBehemothModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local AshBehemothModel = require(script.Parent.AshBehemothModel)

return Horse.variant("AshBehemoth", AshBehemothModel, "Legendary", {
	seat = Vector3.new(0, 6.88, 0.86),
	neck = { center = Vector3.new(0, 4.44, -4.59), radius = 1.73 },
})
