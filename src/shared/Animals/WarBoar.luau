-- WarBoar: The Boar in the Red Castle's barding: dark bristles, a crimson mane, a
-- steel helm on its brow and gold tusks.
-- Made by tools/later_pets.py (Fight to Steal an Egg's; ported to Lasso A Pet, QM Nov 6:
-- its Divine there is Lasso's Uncommon, its place in its biome's Uncommon .. Legendary).

local Horse = require(script.Parent.Horse)
local WarBoarModel = require(script.Parent.WarBoarModel)

return Horse.variant("WarBoar", WarBoarModel, "Uncommon", {
	seat = Vector3.new(0, 6.27, 1.52),
	neck = { center = Vector3.new(0, 4.94, -4.56), radius = 2.66 },
})
