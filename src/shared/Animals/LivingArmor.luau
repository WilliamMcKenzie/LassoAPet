-- LivingArmor: The Icebringer as an empty suit of the castle's armour: steel plates over
-- crimson cloth, gold trim and red eyes glowing inside.
-- Made by tools/later_pets.py (Fight to Steal an Egg's; ported to Lasso A Pet, QM Nov 6:
-- its Cosmic there is Lasso's Epic, its place in its biome's Uncommon .. Legendary).

local Horse = require(script.Parent.Horse)
local LivingArmorModel = require(script.Parent.LivingArmorModel)

return Horse.variant("LivingArmor", LivingArmorModel, "Epic", {
	seat = Vector3.new(0, 9.8, 1.1),
	neck = { center = Vector3.new(0, 9, -0.8), radius = 1.3 },
	size = 1.507, -- (its longest side 34 studs)
})
