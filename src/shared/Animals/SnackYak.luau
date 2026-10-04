-- Snack Yak: QM's shaggy yak with a saddle, a fruit basket on its back, saddlebags with a
-- ham and a fish in them, and a stick dangling carrots in front of its nose. Epic, Tundra.
-- designs/snow/SnackYak.bbmodel is QM's painted model (SnackYak_QM.bbmodel) in one colour a
-- block, rigged and animated by tools/snack_yak.py, converted into SnackYakModel.luau with
-- `tools/bbmodel_to_luau.py --zyx`. You ride in the saddle, just in front of the stick.

local Horse = require(script.Parent.Horse)
local SnackYakModel = require(script.Parent.SnackYakModel)

return Horse.variant("SnackYak", SnackYakModel, "Epic", {
	seat = Vector3.new(0, 2.3, -0.1),
	neck = { center = Vector3.new(0, 1.3, -1.4), radius = 0.6 },
})
