-- DungeonRat: The Pig as a dungeon rat: grey fur, round pink ears, a pointed pink
-- nose with buck teeth and a long bare tail.
-- Made by tools/later_pets.py (Fight to Steal an Egg's; ported to Lasso A Pet, QM Nov 6:
-- its Mythic there is Lasso's Uncommon, its place in its biome's Uncommon .. Legendary).

local Horse = require(script.Parent.Horse)
local DungeonRatModel = require(script.Parent.DungeonRatModel)

return Horse.variant("DungeonRat", DungeonRatModel, "Uncommon", {
	seat = Vector3.new(0, 6.4, 0.4),
	neck = { center = Vector3.new(0, 4.2, -3.9), radius = 1.9 },
})
