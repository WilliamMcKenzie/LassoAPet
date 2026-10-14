-- Lion: World 2 Meadow's Rare. Golden coat, cream muzzle, chest and paws, a big blocky
-- brown mane framing its face, small round ears and a long tail with a dark tuft.
-- Model from designs/world2/Lion.bbmodel (tools/lion_design.py), converted into
-- LionModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local LionModel = require(script.Parent.LionModel)

return Horse.variant("Lion", LionModel, "Rare", {
	seat = Vector3.new(0, 6.6, 0.9),
	neck = { center = Vector3.new(0, 5.8, -3.0), radius = 2.2 },
})
