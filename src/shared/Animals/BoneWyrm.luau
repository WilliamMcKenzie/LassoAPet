-- BoneWyrm: The Rockworm as a skeleton (as QM made the Rockworm from the Sandworm):
-- bone segments, crypt plates and the dungeon's green glowing in its fins and horns.
-- Made by tools/later_pets.py (Fight to Steal an Egg's; ported to Lasso A Pet, QM Nov 6:
-- its Cosmic there is Lasso's Legendary, its place in its biome's Uncommon .. Legendary).

local Horse = require(script.Parent.Horse)
local Rockworm = require(script.Parent.Rockworm)
local SandwormModel = require(script.Parent.SandwormModel)
-- (QM, Oct 30: it moves just as the Sandworm does: the Sandworm's animations on its own
-- model, which has the same bones at the same pivots)
local BoneWyrmModel = table.clone(require(script.Parent.BoneWyrmModel))
BoneWyrmModel.animations = SandwormModel.animations

return Horse.variant("BoneWyrm", BoneWyrmModel, "Divine", {
	seat = Vector3.new(0, 4.45, 1.6),
	neck = { center = Vector3.new(0, 3.2, -2.6), radius = 3 },
	size = Rockworm.size * 1.1,
})
