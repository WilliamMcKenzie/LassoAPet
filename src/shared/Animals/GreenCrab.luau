-- Green Crab: World 3 Pirate Cove's Common (Oct 14; QM made it green in Blockbench). A chunky green beach crab with a faceted shell, a
-- cream belly, two big black-tipped claws (the right one bigger) that snap, googly eyes on stalks
-- and six thick legs. You ride on its shell.
-- designs/world3/pirate/GreenCrab.bbmodel (QM's hand edit of tools/pirate_red_crab.py's crab), converted (--zyx --meshes) into GreenCrabModel.luau by
-- tools/bbmodel_to_luau.py: blocks, the carapace and the claws' tops low-poly MeshParts (QM Oct 14), copied from
-- ReplicatedStorage.AnimalMeshes (tools/animal_meshes.luau).

local Horse = require(script.Parent.Horse)
local GreenCrabModel = require(script.Parent.GreenCrabModel)

return Horse.variant("GreenCrab", GreenCrabModel, "Common", {
	seat = Vector3.new(0, 5.0, 0.3),
	neck = { center = Vector3.new(0, 4.15, 0.2), radius = 3.0 },
})
