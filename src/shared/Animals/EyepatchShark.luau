-- Eyepatch Shark: World 3 Pirate Cove's Epic (Oct 14). QM's remodel of the Ocean's SharkBoss (angry brows,
-- open jaw of teeth) with an eyepatch, in the first Eyepatch Shark's bright blues (QM). You ride on its back.
-- designs/world3/pirate/EyepatchShark.bbmodel (QM's Blockbench file, recoloured), converted (--zyx) into
-- EyepatchSharkModel.luau by tools/bbmodel_to_luau.py. Small like the Robo Shark; its tier sizes it.

local Horse = require(script.Parent.Horse)
local EyepatchSharkModel = require(script.Parent.EyepatchSharkModel)

return Horse.variant("EyepatchShark", EyepatchSharkModel, "Epic", {
	seat = Vector3.new(0, 2.2, 0.5), -- (as the Ocean's SharkBoss, which QM's model is built from, Oct 14)
	neck = { center = Vector3.new(0, 1.6, -1.45), radius = 0.6 },
})
