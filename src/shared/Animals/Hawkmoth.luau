-- Hawkmoth: World 2 Woodland Maze's death's-head hawkmoth (QM, Oct 13; Epic). A dark body with
-- a cream skull on its back, glowing orange eyes under angry brows, horn antennae, sharp spiked
-- wings and an orange-ringed abdomen ending in a stinger. It hovers (never lands), and sprint
-- flies it up like the Phoenix (Config.SprintSpecials). You ride on its back over the skull.
-- designs/woodland/Hawkmoth.bbmodel (tools/hawkmoth.py), converted (--zyx) into
-- HawkmothModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local HawkmothModel = require(script.Parent.HawkmothModel)

return Horse.variant("Hawkmoth", HawkmothModel, "Epic", {
	seat = Vector3.new(0, 7.5, 0.4),
	neck = { center = Vector3.new(0, 5.4, -4.4), radius = 2.2 },
})
