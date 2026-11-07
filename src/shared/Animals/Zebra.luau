-- Zebra: World 1 Meadow's Uncommon (QM, Nov 6), the Horse in white with black stripes as
-- flush slices, a black muzzle, mane and hooves. Model from designs/animals/Zebra.bbmodel
-- (tools/zebra_design.py), converted into ZebraModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local ZebraModel = require(script.Parent.ZebraModel)

return Horse.variant("Zebra", ZebraModel, "Uncommon", {
	seat = Vector3.new(0, 7.3, 1),
	neck = { center = Vector3.new(0, 7.4, -1.9), radius = 1.35 },
})
