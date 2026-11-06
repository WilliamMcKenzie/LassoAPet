-- Seahorse: A big coral seahorse from the Ocean Trench: a curled tail, a long snout,
-- a crown of spines and little fins. It swims upright, bobbing; you ride behind its head.
-- Made by tools/later_pets.py (Fight to Steal an Egg's; ported to Lasso A Pet, QM Nov 6:
-- its Divine there is Lasso's Rare, its place in its biome's Uncommon .. Legendary).

local Horse = require(script.Parent.Horse)
local SeahorseModel = require(script.Parent.SeahorseModel)

return Horse.variant("Seahorse", SeahorseModel, "Rare", {
	seat = Vector3.new(0, 7.4, 1.6),
	neck = { center = Vector3.new(0, 7, -0.4), radius = 1.8 },
})
