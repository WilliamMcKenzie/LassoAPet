-- CrimsonDrake: The Spine Lizard as the castle's drake: crimson scales, a gold belly and
-- sail, black crests and two horns.
-- Made by tools/later_pets.py (Fight to Steal an Egg's; ported to Lasso A Pet, QM Nov 6:
-- its Cosmic there is Lasso's Epic, its place in its biome's Uncommon .. Legendary).

local Horse = require(script.Parent.Horse)
local CrimsonDrakeModel = require(script.Parent.CrimsonDrakeModel)

return Horse.variant("CrimsonDrake", CrimsonDrakeModel, "Epic", {
	seat = Vector3.new(0, 4.2, -4.08),
	neck = { center = Vector3.new(0, 2.84, -4.42), radius = 2.04 },
})
