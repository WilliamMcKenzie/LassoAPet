-- PumpkinPup: the Halloween world's Haunted Hills Uncommon (QM, Oct 15): a tan dog with a jack-o'-lantern head, a glowing grin, leaf ears and a vine tail.
-- designs/halloween/PumpkinPup.bbmodel (tools/halloween_pumpkin_pup.py), converted (--zyx --meshes) into
-- PumpkinPupModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local PumpkinPupModel = require(script.Parent.PumpkinPupModel)

return Horse.variant("PumpkinPup", PumpkinPupModel, "Uncommon", {
	seat = Vector3.new(0, 5.4, 0.8),
	neck = { center = Vector3.new(0, 6.2, -2.8), radius = 2.5 },
})
