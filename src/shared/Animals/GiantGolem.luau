-- Giant Golem: World 2 Woodland Maze's Legendary (QM, Oct 13: "xxl giant stone guy with
-- glowing ORANGE eyes"). A grey stone giant knuckle-walking on huge fists: an angry horned
-- face with glowing orange eyes and maw, glowing lava veins, elbows and knees, a glowing
-- core in its chest, a crown of rock spikes on its right shoulder and a little autumn tree
-- growing out of the moss on its left. Large (tier 3).
-- designs/woodland/GiantGolem.bbmodel (tools/giant_golem.py), converted into
-- GiantGolemModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local GiantGolemModel = require(script.Parent.GiantGolemModel)

return Horse.variant("GiantGolem", GiantGolemModel, "Legendary", {
	seat = Vector3.new(0, 8.6, 1.2),
	neck = { center = Vector3.new(0, 6.8, -4.0), radius = 1.6 },
})
