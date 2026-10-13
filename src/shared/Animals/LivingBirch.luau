-- Living Birch: a World 2 Woodland Maze Rare (QM, Oct 13), an autumn birch out for a run on
-- Palm Guy's body plan: a stacked white birch trunk with dark bands and marks, Palm Guy's face
-- (two dark eyes over a tall mouth), Cactus-style arms with a leaf tuft on each hand, stubby
-- legs and a chunky autumn canopy like the woodland's prop birches. Palm Guy's idle, walk and
-- gallop. designs/woodland/LivingBirch.bbmodel from tools/living_birch.py (`animate` adds the
-- animations), converted by tools/bbmodel_to_luau.py. You ride on top of the canopy.

local Horse = require(script.Parent.Horse)
local LivingBirchModel = require(script.Parent.LivingBirchModel)

return Horse.variant("LivingBirch", LivingBirchModel, "Rare", {
	seat = Vector3.new(0, 17.3, 0), -- on the top clumps, not in them
	neck = { center = Vector3.new(0, 9.6, 0), radius = 2.0 },
})
