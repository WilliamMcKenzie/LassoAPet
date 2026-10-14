-- Palm Guy: one of the Jurassic's cycad palms out for a run, with the Cactus's face (two dark
-- eyes over a tall mouth), Cactus-style arms with a leaf tuft on each hand, stubby legs and a
-- crown of drooping fronds (QM, Oct 11). Uncommon, in the Jurassic, a bit bigger than the
-- Cactus (Config.AnimalScale). designs/jurassic/PalmGuy.bbmodel from tools/palm_guy.py (design,
-- idle, walk and gallop: `animate`), converted by tools/bbmodel_to_luau.py. You ride on his crown.

local Horse = require(script.Parent.Horse)
local PalmGuyModel = require(script.Parent.PalmGuyModel)

return Horse.variant("PalmGuy", PalmGuyModel, "Uncommon", {
	seat = Vector3.new(0, 12, 0),
	neck = { center = Vector3.new(0, 9.6, 0), radius = 2.0 },
})
