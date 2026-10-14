-- Ankylosaurus: a low, wide, mustard tank with dark brown armour bands, bone-white spikes down
-- its back and flanks, horns on a flat armoured head, a cream beak and a big brown club on the
-- end of its tail (QM, Oct 11). Uncommon, in the Jurassic. designs/jurassic/Ankylosaurus.bbmodel
-- from tools/ankylosaurus.py (design, idle, walk and gallop: `animate`), converted by
-- tools/bbmodel_to_luau.py. You ride in the spike-free saddle on its back.

local Horse = require(script.Parent.Horse)
local AnkylosaurusModel = require(script.Parent.AnkylosaurusModel)

return Horse.variant("Ankylosaurus", AnkylosaurusModel, "Uncommon", {
	seat = Vector3.new(0, 4.95, 0),
	neck = { center = Vector3.new(0, 3.3, -4.0), radius = 1.8 },
})
