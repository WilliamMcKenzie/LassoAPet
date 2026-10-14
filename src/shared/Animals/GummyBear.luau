-- Gummy Bear: World 3 Candyland's Common (Oct 14). A chunky cherry gummy bear on all fours with a
-- lighter strawberry belly and muzzle, round ears and front-facing googly eyes. You ride on its back.
-- designs/candyland/GummyBear.bbmodel (tools/gummy_bear.py), converted (no --zyx) into GummyBearModel.luau by
-- tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local GummyBearModel = require(script.Parent.GummyBearModel)

return Horse.variant("GummyBear", GummyBearModel, "Common", {
	seat = Vector3.new(0, 5.5, 0.2),
	neck = { center = Vector3.new(0, 5.6, -3.7), radius = 2.2 },
})
