-- Moon Jellyfish: World 3 Cnidaria's Common (Oct 14). A chubby lilac bell of stacked
-- octagonal tiers, four glowing pink horseshoe pads round the rider, big googly eyes, a skirt
-- of rim panels with pink fringe tentacles that pulse, and four frilly pink oral arms.
-- It swims, and sprint flies it up like the Crystal Phoenix (Config.SprintSpecials).
-- Model from designs/cnidaria/MoonJellyfish.bbmodel (tools/moon_jellyfish.py), converted into MoonJellyfishModel.luau by
-- tools/bbmodel_to_luau.py --zyx.

local Horse = require(script.Parent.Horse)
local MoonJellyfishModel = require(script.Parent.MoonJellyfishModel)

return Horse.variant("MoonJellyfish", MoonJellyfishModel, "Common", {
	seat = Vector3.new(0, 11.3, 0),
	neck = { center = Vector3.new(0, 8.5, 0), radius = 4 },
})
