-- Crystal Elephant: World 2 Crystal Cavern's Legendary (QM, Oct 13), the War Elephant in
-- crystal armour: deep purple plates with glowing cyan trim, a ridge of tall cyan and pink
-- crystals down its back, a crown of crystals, crystal points out of its skirts, crystal
-- greaves and glowing crystal tusks. Large (tier 3), like the War Elephant.
-- designs/crystal/CrystalElephant.bbmodel (tools/crystal_elephant.py), converted (--zyx) into
-- CrystalElephantModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local CrystalElephantModel = require(script.Parent.CrystalElephantModel)

return Horse.variant("CrystalElephant", CrystalElephantModel, "Legendary", {
	seat = Vector3.new(0, 8.1, 1.2),
	neck = { center = Vector3.new(0, 6.4, -4.6), radius = 2.3 },
})
