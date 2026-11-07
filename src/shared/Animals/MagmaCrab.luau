-- Magma Crab: World 1 Volcano's Rare (QM, Nov 7: one of the luck-padding animals QM picked).
-- Model from tools/filler_volcano.py (magma_crab), rigged by tools/filler_export.py into
-- designs/filler/rigged/MagmaCrab.bbmodel and converted into MagmaCrabModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local MagmaCrabModel = require(script.Parent.MagmaCrabModel)

return Horse.variant("MagmaCrab", MagmaCrabModel, "Rare", {
	seat = Vector3.new(0, 4.22, -2.11),
	neck = { center = Vector3.new(0, 5.28, -2.32), radius = 1.14 },
})
