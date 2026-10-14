-- The Crystal Seraph: World 2 Crystal Cavern's boss (QM, Oct 13: "a crystal recolor of the
-- seraphim"; it took the Crystal Tyrant's place). The Meadow's Seraph in the cavern props'
-- colours: cyan crystal rings covered in eyes, pink crystal wings with glowing cyan tips, a
-- glowing pink iris and a glowing cyan halo. Same angel cry as the Seraph.
-- Model from designs/bosses/CrystalSeraph.bbmodel (tools/angel_boss.py --crystal), converted
-- into CrystalSeraphModel.luau by tools/bbmodel_to_luau.py --zyx.

local Horse = require(script.Parent.Parent.Animals.Horse)
local CrystalSeraphModel = require(script.Parent.CrystalSeraphModel)

return Horse.variant("CrystalSeraph", CrystalSeraphModel, "Legendary", {
	seat = Vector3.new(0, 21.7, 0), -- (no one rides it: the top of its core)
	neck = { center = Vector3.new(0, 18.15, -3.6), radius = 3.6 },
	size = 1.3, -- x the model: the Seraph's size
})
