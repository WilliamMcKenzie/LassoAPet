-- Armored Ram: World 1 Castle's Uncommon (QM, Nov 7: one of the luck-padding animals QM picked).
-- Model from tools/filler_castle.py (armored_ram), rigged by tools/filler_export.py into
-- designs/filler/rigged/ArmoredRam.bbmodel and converted into ArmoredRamModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local ArmoredRamModel = require(script.Parent.ArmoredRamModel)

return Horse.variant("ArmoredRam", ArmoredRamModel, "Uncommon", {
	seat = Vector3.new(0, 7.18, 0),
	neck = { center = Vector3.new(0, 6.73, -4.93), radius = 1.9 },
})
