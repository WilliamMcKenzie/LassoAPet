-- Fire Ant: World 1 Volcano's Uncommon (QM, Nov 7: one of the luck-padding animals QM picked).
-- Model from tools/filler_volcano.py (fire_ant), rigged by tools/filler_export.py into
-- designs/filler/rigged/FireAnt.bbmodel and converted into FireAntModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local FireAntModel = require(script.Parent.FireAntModel)

return Horse.variant("FireAnt", FireAntModel, "Uncommon", {
	seat = Vector3.new(0, 5.42, 1.55),
	neck = { center = Vector3.new(0, 3.29, -4.84), radius = 1.92 },
})
