-- Crimson Scorpion: World 2's Crimson Lands Uncommon (QM, Oct 13), the Scorpion in crimson
-- with purple joints. designs/crimson/CrimsonScorpion.bbmodel (tools/crimson_scorpion.py
-- recolours QM's Scorpion, same bones and animations), converted into CrimsonScorpionModel.luau
-- by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local CrimsonScorpionModel = require(script.Parent.CrimsonScorpionModel)

return Horse.variant("CrimsonScorpion", CrimsonScorpionModel, "Uncommon", {
	seat = Vector3.new(0, 4.42, -0.52),
	neck = { center = Vector3.new(0, 2.99, -3.9), radius = 2.2 },
})
