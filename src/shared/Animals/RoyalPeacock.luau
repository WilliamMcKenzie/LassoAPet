-- RoyalPeacock: The Firebird as the castle garden's peacock: royal blue with a teal
-- breast, gold claws and a gold crest.
-- Made by tools/later_pets.py (Fight to Steal an Egg's; ported to Lasso A Pet, QM Nov 6:
-- its Celestial there is Lasso's Rare, its place in its biome's Uncommon .. Legendary).

local Horse = require(script.Parent.Horse)
local RoyalPeacockModel = require(script.Parent.RoyalPeacockModel)

return Horse.variant("RoyalPeacock", RoyalPeacockModel, "Rare", {
	seat = Vector3.new(0, 8.6, 0.8),
	neck = { center = Vector3.new(0, 11, -4.6), radius = 2 },
})
