-- Velociraptor: a blue raptor with navy stripes, a cream belly and jaw, lilac teeth down a
-- long snout, an orange feather crest, arm feathers and tail fan, and a raised black sickle
-- claw on each foot (QM, Oct 11). Rare, in the Jurassic, where it runs in packs of three
-- (Config.HerdPacks). designs/jurassic/Raptor.bbmodel from tools/raptor_design.py (design,
-- idle, walk and gallop: `animate`), converted by tools/bbmodel_to_luau.py. You ride on its back.

local Horse = require(script.Parent.Horse)
local RaptorModel = require(script.Parent.RaptorModel)

return Horse.variant("Raptor", RaptorModel, "Rare", {
	seat = Vector3.new(0, 6.74, 0.2),
	neck = { center = Vector3.new(0, 6.6, -2.8), radius = 1.2 },
})
