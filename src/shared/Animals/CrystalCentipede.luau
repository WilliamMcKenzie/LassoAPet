-- Crystal Centipede: World 2 Crystal Cavern's first animal (Uncommon). A purple centipede
-- with cyan and pink crystals growing from its back and spiked crystal pincers.
-- QM's model designs/crystal/CrystalCentipede.bbmodel, animated by tools/crystal_centipede_rig.py
-- and converted (--zyx) into CrystalCentipedeModel.luau by tools/bbmodel_to_luau.py. You ride
-- its front segment.

local Horse = require(script.Parent.Horse)
local CrystalCentipedeModel = require(script.Parent.CrystalCentipedeModel)

return Horse.variant("CrystalCentipede", CrystalCentipedeModel, "Uncommon", {
	seat = Vector3.new(0, 3.4, 1.6),
	neck = { center = Vector3.new(0, 2.2, -1.4), radius = 2.4 },
})
