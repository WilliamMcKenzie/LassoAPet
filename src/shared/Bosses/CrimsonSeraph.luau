-- The Crimson Seraph: World 2 Crimson Lands' boss (QM, Oct 13: the Seraph reskinned crimson).
-- The Meadow's Seraph with near-black blood-red rings covered in eyes, crimson wings with
-- glowing red tips, a glowing red iris and a glowing red halo (#FF3B5C, the Crimson gate's
-- glow). Same angel cry as the Seraph.
-- Model from designs/bosses/CrimsonSeraph.bbmodel (tools/angel_boss.py --crimson), converted
-- into CrimsonSeraphModel.luau by tools/bbmodel_to_luau.py --zyx.

local Horse = require(script.Parent.Parent.Animals.Horse)
local CrimsonSeraphModel = require(script.Parent.CrimsonSeraphModel)

return Horse.variant("CrimsonSeraph", CrimsonSeraphModel, "Legendary", {
	seat = Vector3.new(0, 21.7, 0), -- (no one rides it: the top of its core)
	neck = { center = Vector3.new(0, 18.15, -3.6), radius = 3.6 },
	size = 1.3, -- x the model: the Seraph's size
})
