-- IceDrake: a hunched wingless ice drake, cyan with white fur rings, red eyes and swept-back horns. Legendary.
-- Converted from QM's old Blockbench model by tools/convert_designs.py (the pose is in its bones'
-- rest rotations), animated by tools/convert_rig.py and converted into IceDrakeModel.luau by
-- tools/bbmodel_to_luau.py from designs/converted/IceDrake.bbmodel. You ride on its back between the spikes.

local Horse = require(script.Parent.Horse)
local IceDrakeModel = require(script.Parent.IceDrakeModel)

return Horse.variant("IceDrake", IceDrakeModel, "Legendary", {
	seat = Vector3.new(0, 7.9, -0.6),
	neck = { center = Vector3.new(0, 6.37, -7.14), radius = 1.87 },
})
