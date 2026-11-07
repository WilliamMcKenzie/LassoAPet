-- RoyalEagle: The Phoenix as the castle's heraldic eagle: white and gold feathers on
-- a crimson body, no flame.
-- Made by tools/later_pets.py (Fight to Steal an Egg's; ported to Lasso A Pet, QM Nov 6:
-- its Void there is Lasso's Legendary, its place in its biome's Uncommon .. Legendary).

local Horse = require(script.Parent.Horse)
local RoyalEagleModel = require(script.Parent.RoyalEagleModel)

return Horse.variant("RoyalEagle", RoyalEagleModel, "Legendary", {
	seat = Vector3.new(0, 4.5, 0.8),
	neck = { center = Vector3.new(0, 6.9, -4.3), radius = 1.8 },
	size = 1.357, -- (its longest side 38 studs)
})
