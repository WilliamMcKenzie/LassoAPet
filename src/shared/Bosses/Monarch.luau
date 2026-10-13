-- The Monarch: World 2 Woodland Maze's boss (QM, Oct 13: "an insanely cool butterfly boss,
-- giant monarch butterfly"). Four huge orange wings veined and bordered in black with white
-- spots, a black body with a white-dotted abdomen, clubbed antennae and big googly eyes. It
-- flies low over the path flapping, and chases you home like the Chicken; it isn't a pet, so
-- it lives in Shared/Bosses. Model from designs/bosses/Monarch.bbmodel (tools/butterfly_boss.py),
-- converted into MonarchModel.luau by tools/bbmodel_to_luau.py --zyx.

local Horse = require(script.Parent.Parent.Animals.Horse)
local MonarchModel = require(script.Parent.MonarchModel)

return Horse.variant("Monarch", MonarchModel, "Legendary", {
	seat = Vector3.new(0, 14.6, 0), -- (no one rides it: the top of its thorax)
	neck = { center = Vector3.new(0, 12.9, -4.2), radius = 2 },
	size = 1.5, -- x the model (a guess: about 70 studs wingtip to wingtip; Studio tunes it)
})
