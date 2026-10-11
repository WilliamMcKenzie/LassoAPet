-- Spinosaurus: a teal dinosaur with dark stripes, a long croc snout full of teeth and a big
-- fanned sail of red spines and orange webbing on its back (QM, Oct 11). Rare, Jurassic,
-- slightly smaller than the T-Rex (Config.AnimalScale). Built on the T-Rex: QM's file
-- designs/jurassic/Spinosaurus.bbmodel (tools/spinosaurus.py: sail webbing and its own idle
-- fishing snap, walk and run), converted by tools/bbmodel_to_luau.py --zyx.

local Horse = require(script.Parent.Horse)
local SpinosaurusModel = require(script.Parent.SpinosaurusModel)

return Horse.variant("Spinosaurus", SpinosaurusModel, "Rare", {
	seat = Vector3.new(0, 10.38, 0.6), -- the T-Rex's (same body)
	neck = { center = Vector3.new(0, 8.8, -4.7), radius = 2.2 },
})
