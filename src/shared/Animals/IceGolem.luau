-- IceGolem: a knuckle-walking ice golem with ice crystals growing out of its back. Epic.
-- Converted from QM's old Blockbench model by tools/convert_designs.py (the pose is in its bones'
-- rest rotations), animated by tools/convert_rig.py and converted into IceGolemModel.luau by
-- tools/bbmodel_to_luau.py from designs/converted/IceGolem.bbmodel. You ride on its snowy shoulders, in front of the crystals.

local Horse = require(script.Parent.Horse)
local IceGolemModel = require(script.Parent.IceGolemModel)

return Horse.variant("IceGolem", IceGolemModel, "Epic", {
	seat = Vector3.new(0, 13.36, 0.4),
	neck = { center = Vector3.new(0, 9.2, -1.6), radius = 2.8 },
})
