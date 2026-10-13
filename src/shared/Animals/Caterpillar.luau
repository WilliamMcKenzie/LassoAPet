-- Caterpillar: World 2 Woodland Maze's Uncommon (QM, Oct 13). A chubby green and lime
-- caterpillar with yellow back spots, stubby dark green feet and orange-tipped antennae.
-- designs/woodland/Caterpillar.bbmodel (tools/woodland_caterpillar.py), animated by
-- tools/woodland_caterpillar_rig.py and converted into CaterpillarModel.luau by
-- tools/bbmodel_to_luau.py. You ride its front segment.

local Horse = require(script.Parent.Horse)
local CaterpillarModel = require(script.Parent.CaterpillarModel)

return Horse.variant("Caterpillar", CaterpillarModel, "Uncommon", {
	seat = Vector3.new(0, 3.7, 1.4),
	neck = { center = Vector3.new(0, 2.5, -1.8), radius = 2.6 },
})
