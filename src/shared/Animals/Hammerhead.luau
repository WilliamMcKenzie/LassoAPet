-- Hammerhead: World 1 Ocean's Rare (QM, Nov 7: one of the luck-padding animals QM picked).
-- Model from tools/filler_ocean.py (hammerhead), rigged by tools/filler_export.py into
-- designs/filler/rigged/Hammerhead.bbmodel and converted into HammerheadModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local HammerheadModel = require(script.Parent.HammerheadModel)

return Horse.variant("Hammerhead", HammerheadModel, "Rare", {
	seat = Vector3.new(0, 3.87, 2),
	neck = { center = Vector3.new(0, 2.66, -2.14), radius = 1.73 },
})
