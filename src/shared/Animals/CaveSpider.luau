-- CaveSpider: The Scorpion as a cave spider: no claws or tail but a big round abdomen,
-- a fourth pair of legs, slate black with the dungeon's green glowing in its eyes and back.
-- Made by tools/later_pets.py (Fight to Steal an Egg's; ported to Lasso A Pet, QM Nov 6:
-- its Divine there is Lasso's Rare, its place in its biome's Uncommon .. Legendary).

local Horse = require(script.Parent.Horse)
local CaveSpiderModel = require(script.Parent.CaveSpiderModel)

return Horse.variant("CaveSpider", CaveSpiderModel, "Rare", {
	seat = Vector3.new(0, 4.42, -0.52),
	neck = { center = Vector3.new(0, 2.99, -3.9), radius = 2.2 },
})
