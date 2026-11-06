-- Slime: A dungeon slime: a stepped green cube that squashes and hops, two big
-- eyes and a little smile. You ride on its top.
-- Made by tools/later_pets.py (Fight to Steal an Egg's; ported to Lasso A Pet, QM Nov 6:
-- its Mythic there is Lasso's Uncommon, its place in its biome's Uncommon .. Legendary).

local Horse = require(script.Parent.Horse)
local SlimeModel = require(script.Parent.SlimeModel)

return Horse.variant("Slime", SlimeModel, "Uncommon", {
	seat = Vector3.new(0, 4.9, 0.4),
	neck = { center = Vector3.new(0, 3.6, -0.5), radius = 3.2 },
})
