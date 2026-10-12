-- The Chicken boss: QM's Farm chicken (angry brows, red eyes, comb, tail), the first boss,
-- the Meadow's, and for now every biome's. It pops up when the BOSS IN timer runs out and
-- chases you home; it isn't a pet (no egg, no Config pet entry), so it lives here rather than
-- in Shared/Animals, which the game scans for pets.
-- Model from designs/bosses/Chicken.bbmodel (QM's Blockbench file with idle, walk and
-- gallop), converted into ChickenModel.luau by tools/bbmodel_to_luau.py --zyx (QM's eyes and
-- brows turn about two axes). Built on the Horse rig like every animal: Chicken.new() gives
-- a model that blends idle, walk and gallop by speed (update). The head bone is "neck":
-- put the anger vein (assets/ui/boss/AngerVein.png) on it.

local Horse = require(script.Parent.Parent.Animals.Horse)
local ChickenModel = require(script.Parent.ChickenModel)

return Horse.variant("Chicken", ChickenModel, "Legendary", {
	seat = Vector3.new(0, 7.4, 0.6),
	neck = { center = Vector3.new(0, 7.2, -3.2), radius = 1.9 },
	size = 4, -- x the model: about 38 studs, nearly 4x a Horse; tune freely
})
