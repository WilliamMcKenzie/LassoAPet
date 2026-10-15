-- PurpleTarantula: the Halloween world's Haunted Hills Rare (QM, Oct 15): a big purple tarantula with an orange stripe, orange thighs and fangs.
-- designs/halloween/PurpleTarantula.bbmodel (tools/halloween_tarantula.py), converted (--zyx --meshes) into
-- PurpleTarantulaModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local PurpleTarantulaModel = require(script.Parent.PurpleTarantulaModel)

return Horse.variant("PurpleTarantula", PurpleTarantulaModel, "Rare", {
	seat = Vector3.new(0, 7.2, 1.6),
	neck = { center = Vector3.new(0, 4.7, -3.4), radius = 1.8 },
})
