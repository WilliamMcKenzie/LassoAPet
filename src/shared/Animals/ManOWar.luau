-- Man o' War: World 3 Cnidaria's Epic (Oct 14). A tapered stepped gas balloon running
-- blue to pink, a tall ribbed magenta crest sail, googly eyes on the nose, and six long
-- stinging tentacles trailing back to glowing pink pyramid tips. You ride the front half.
-- Model from designs/cnidaria/ManOWar.bbmodel (tools/man_o_war.py), converted into ManOWarModel.luau by
-- tools/bbmodel_to_luau.py --zyx.

local Horse = require(script.Parent.Horse)
local ManOWarModel = require(script.Parent.ManOWarModel)

return Horse.variant("ManOWar", ManOWarModel, "Epic", {
	seat = Vector3.new(0, 11.0, -3.5),
	neck = { center = Vector3.new(0, 9, -5.5), radius = 2.4 },
})
