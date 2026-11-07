-- MysticOwl: The Penguin as the Magic Circle's owl: tawny feathers with darker wings,
-- a speckled cream front, a wide pale face with big amber eyes, ear tufts and a small beak.
-- Made by tools/later_pets.py (Fight to Steal an Egg's; ported to Lasso A Pet, QM Nov 6:
-- its Celestial there is Lasso's Epic, its place in its biome's Uncommon .. Legendary).

local Horse = require(script.Parent.Horse)
local MysticOwlModel = require(script.Parent.MysticOwlModel)

return Horse.variant("MysticOwl", MysticOwlModel, "Epic", {
	seat = Vector3.new(0, 9.9, -0.2),
	neck = { center = Vector3.new(0, 7.9, -0.2), radius = 2.2 },
})
