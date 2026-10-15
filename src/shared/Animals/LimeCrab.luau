-- Lime Crab: World 3 Pirate Cove's Uncommon (QM, Oct 15): the Green Crab in a yellower green, 2x its size (Config.AnimalScale), 1/3 as often. A chunky green beach crab with a faceted shell, a
-- cream belly, two big black-tipped claws (the right one bigger) that snap, googly eyes on stalks
-- and six thick legs. You ride on its shell.
-- designs/world3/pirate/LimeCrab.bbmodel (tools/pirate_lime_crab.py recolours QM's GreenCrab.bbmodel), converted (--zyx --meshes) into LimeCrabModel.luau by
-- tools/bbmodel_to_luau.py: blocks, the carapace and the claws' tops low-poly MeshParts (QM Oct 14), copied from
-- ReplicatedStorage.AnimalMeshes (tools/animal_meshes.luau).

local Horse = require(script.Parent.Horse)
local LimeCrabModel = require(script.Parent.LimeCrabModel)

return Horse.variant("LimeCrab", LimeCrabModel, "Uncommon", {
	seat = Vector3.new(0, 5.0, 0.3),
	neck = { center = Vector3.new(0, 4.15, 0.2), radius = 3.0 },
})
