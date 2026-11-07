-- SpiritLoong: The Loong as the Magic Circle's spirit dragon: pearl white with a
-- turquoise mane and whiskers, violet bands and spines, and glowing eyes.
-- Made by tools/later_pets.py (Fight to Steal an Egg's; ported to Lasso A Pet, QM Nov 6:
-- its Cosmic there is Lasso's Legendary, its place in its biome's Uncommon .. Legendary).

local Horse = require(script.Parent.Horse)
local SpiritLoongModel = require(script.Parent.SpiritLoongModel)

return Horse.variant("SpiritLoong", SpiritLoongModel, "Celestial", {
	seat = Vector3.new(0, 7, -1.2),
	neck = { center = Vector3.new(0, 4.8, -7.2), radius = 2.6 },
	seatBone = "saddle",
	size = 0.929, -- (its longest side 42 studs)
})
