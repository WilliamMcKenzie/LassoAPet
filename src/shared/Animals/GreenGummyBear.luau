-- Green Gummy Bear: World 3 Candyland's Rare (QM, Oct 15): the Gummy Bear in lime, 2x its size (Config.AnimalScale). A chunky cherry gummy bear on all fours with a
-- lighter strawberry belly and muzzle, round ears and front-facing googly eyes. You ride on its back.
-- designs/candyland/GreenGummyBear.bbmodel (tools/gummy_recolors.py recolours QM's GummyBear.bbmodel), converted (no --zyx) into GreenGummyBearModel.luau by
-- tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local GreenGummyBearModel = require(script.Parent.GreenGummyBearModel)

return Horse.variant("GreenGummyBear", GreenGummyBearModel, "Rare", {
	seat = Vector3.new(0, 5.5, 0.2),
	neck = { center = Vector3.new(0, 5.6, -3.7), radius = 2.2 },
})
