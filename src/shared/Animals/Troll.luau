-- Troll: a hunched blue winter troll in a bone mask (red eye, scarred white eye) with tusks, a white ponytail and a spiked club. Epic.
-- Converted from QM's old Blockbench model by tools/convert_designs.py (the pose is in its bones'
-- rest rotations), animated by tools/convert_rig.py and converted into TrollModel.luau by
-- tools/bbmodel_to_luau.py from designs/converted/Troll.bbmodel. You ride on top of its hunched shoulders.

local Horse = require(script.Parent.Horse)
local TrollModel = require(script.Parent.TrollModel)

return Horse.variant("Troll", TrollModel, "Epic", {
	seat = Vector3.new(0, 14.58, 4.28),
	neck = { center = Vector3.new(0, 11.25, 0), radius = 2.7 },
})
