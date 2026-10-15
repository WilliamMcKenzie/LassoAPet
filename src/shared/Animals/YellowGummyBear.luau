-- Yellow Gummy Bear: World 3 Candyland's Uncommon (QM, Oct 15): the Gummy Bear in lemon, 1.5x its size (Config.AnimalScale). A chunky cherry gummy bear on all fours with a
-- lighter strawberry belly and muzzle, round ears and front-facing googly eyes. You ride on its back.
-- designs/candyland/YellowGummyBear.bbmodel (tools/gummy_recolors.py recolours QM's GummyBear.bbmodel), converted (no --zyx) into YellowGummyBearModel.luau by
-- tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local YellowGummyBearModel = require(script.Parent.YellowGummyBearModel)

return Horse.variant("YellowGummyBear", YellowGummyBearModel, "Uncommon", {
	seat = Vector3.new(0, 5.5, 0.2),
	neck = { center = Vector3.new(0, 5.6, -3.7), radius = 2.2 },
})
