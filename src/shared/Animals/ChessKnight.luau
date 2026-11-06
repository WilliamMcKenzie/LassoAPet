-- ChessKnight: A giant chess knight from the Red Castle's hall: ivory, a crimson mane
-- and gold rings, hopping on its round base like the piece it is.
-- Made by tools/later_pets.py (Fight to Steal an Egg's; ported to Lasso A Pet, QM Nov 6:
-- its Celestial there is Lasso's Rare, its place in its biome's Uncommon .. Legendary).

local Horse = require(script.Parent.Horse)
local ChessKnightModel = require(script.Parent.ChessKnightModel)

return Horse.variant("ChessKnight", ChessKnightModel, "Rare", {
	seat = Vector3.new(0, 5.6, 1.5),
	neck = { center = Vector3.new(0, 5.6, -0.6), radius = 2 },
})
