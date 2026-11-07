-- CrystalTortoise: The Treasure Turtle without its island, from the Magic Circle: a stepped
-- blue stone shell with glowing crystal scutes, a pale plastron and its teal skin.
-- Made by tools/later_pets.py (Fight to Steal an Egg's; ported to Lasso A Pet, QM Nov 6:
-- its Celestial there is Lasso's Epic, its place in its biome's Uncommon .. Legendary).

local Horse = require(script.Parent.Horse)
local CrystalTortoiseModel = require(script.Parent.CrystalTortoiseModel)

return Horse.variant("CrystalTortoise", CrystalTortoiseModel, "Epic", {
	seat = Vector3.new(0, 7.3, 0.3),
	neck = { center = Vector3.new(0, 5.18, -8.4), radius = 2 },
	size = 1.494, -- (its longest side 28 studs)
})
