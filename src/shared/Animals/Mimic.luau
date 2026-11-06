-- Mimic: A treasure chest that bit back: wood and gold bands, a lid that chomps
-- over rows of teeth, a long tongue and glowing eyes in the dark, on four stubby legs.
-- Made by tools/later_pets.py (Fight to Steal an Egg's; ported to Lasso A Pet, QM Nov 6:
-- its Celestial there is Lasso's Epic, its place in its biome's Uncommon .. Legendary).

local Horse = require(script.Parent.Horse)
local MimicModel = require(script.Parent.MimicModel)

return Horse.variant("Mimic", MimicModel, "Epic", {
	seat = Vector3.new(0, 5.6, 1),
	neck = { center = Vector3.new(0, 3.6, -0.4), radius = 3.2 },
})
