-- Crystal Phoenix: World 2 Crystal Cavern's Phoenix (QM, Oct 13), crystals instead of fire.
-- The Phoenix's shape, bones and animations in purple, pink and cyan, glowing crystal points
-- for its wing tips and tail, crystals for head plumes and on its back. Epic. It never lands,
-- and sprint flies it up like the Phoenix (Config.SprintSpecials).
-- QM's file designs/crystal/CrystalPhoenix.bbmodel, converted by tools/bbmodel_to_luau.py --zyx.

local Horse = require(script.Parent.Horse)
local CrystalPhoenixModel = require(script.Parent.CrystalPhoenixModel)

return Horse.variant("CrystalPhoenix", CrystalPhoenixModel, "Epic", {
	seat = Vector3.new(0, 4.5, 0.8),
	neck = { center = Vector3.new(0, 6.9, -4.3), radius = 1.8 },
})
