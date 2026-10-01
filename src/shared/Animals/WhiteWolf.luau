-- WhiteWolf: a tall white wolf with an ice-blue saddle, a big ruff and a long tail. Rare.
-- Converted from QM's old Blockbench model by tools/convert_designs.py (the pose is in its bones'
-- rest rotations), animated by tools/convert_rig.py and converted into WhiteWolfModel.luau by
-- tools/bbmodel_to_luau.py from designs/converted/WhiteWolf.bbmodel. You ride on the saddle.

local Horse = require(script.Parent.Horse)
local WhiteWolfModel = require(script.Parent.WhiteWolfModel)

return Horse.variant("WhiteWolf", WhiteWolfModel, "Rare", {
	seat = Vector3.new(0, 7.99, 1.2),
	neck = { center = Vector3.new(0, 6.94, -4.2), radius = 1.65 },
})
