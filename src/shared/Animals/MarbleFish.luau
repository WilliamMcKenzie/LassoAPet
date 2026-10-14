-- Marble Fish: World 2 Meadow's Uncommon. The Fish in yellow with a twisted marble horn,
-- flopping along on its belly. Model from designs/world2/MarbleFish.bbmodel
-- (tools/marble_fish.py), converted into MarbleFishModel.luau by tools/bbmodel_to_luau.py.
-- Seat and neck loop as the Fish's.

local Horse = require(script.Parent.Horse)
local MarbleFishModel = require(script.Parent.MarbleFishModel)

return Horse.variant("MarbleFish", MarbleFishModel, "Uncommon", {
	seat = Vector3.new(0, 6.48, -0.54),
	neck = { center = Vector3.new(0, 2.97, -3.51), radius = 2.565 },
})
