-- Pink Butterfly: World 2 Woodland Maze's Uncommon (QM, Oct 13). A plump plum body with
-- googly eyes and pink-tipped antennae, four stepped wings from pale pink to hot pink, a
-- white spot on each. It hovers and flaps, and sprint flies it up like the Crystal Phoenix
-- (Config.SprintSpecials). You sit on its back between the wings.
-- designs/woodland/PinkButterfly.bbmodel (tools/pink_butterfly.py), converted with --zyx.

local Horse = require(script.Parent.Horse)
local PinkButterflyModel = require(script.Parent.PinkButterflyModel)

return Horse.variant("PinkButterfly", PinkButterflyModel, "Uncommon", {
	seat = Vector3.new(0, 8.5, 0.2),
	neck = { center = Vector3.new(0, 7.3, -3), radius = 1.7 },
})
