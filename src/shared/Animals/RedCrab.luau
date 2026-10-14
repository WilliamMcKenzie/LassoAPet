-- Red Crab: World 3 Pirate Cove's Common (Oct 14). A chunky red beach crab with a faceted shell, a
-- cream belly, two big black-tipped claws (the right one bigger) that snap, googly eyes on stalks
-- and six thick legs. You ride on its shell.
-- designs/world3/pirate/RedCrab.bbmodel (tools/pirate_red_crab.py), converted (--zyx --meshes) into RedCrabModel.luau by
-- tools/bbmodel_to_luau.py: blocks, the carapace and the claws' tops low-poly MeshParts (QM Oct 14), copied from
-- ReplicatedStorage.AnimalMeshes (tools/animal_meshes.luau).

local Horse = require(script.Parent.Horse)
local RedCrabModel = require(script.Parent.RedCrabModel)

return Horse.variant("RedCrab", RedCrabModel, "Common", {
	seat = Vector3.new(0, 5.0, 0.3),
	neck = { center = Vector3.new(0, 4.15, 0.2), radius = 3.0 },
})
