-- Blue-Ringed Octopus: World 3 Cnidaria's other Rare (Oct 14). A sunny yellow octopus
-- with big glowing blue rings, one low-poly MeshPart head and mantle you sit on (QM Oct 15), big googly eyes and eight curly
-- arms, each with a glowing ring.
-- Model from designs/cnidaria/BlueRingOctopus.bbmodel (tools/blue_ring_octopus.py), converted into BlueRingOctopusModel.luau by
-- tools/bbmodel_to_luau.py --zyx --meshes assets/meshes/BlueRingOctopus (the body copied from
-- ReplicatedStorage.AnimalMeshes, tools/animal_meshes.luau).

local Horse = require(script.Parent.Horse)
local BlueRingOctopusModel = require(script.Parent.BlueRingOctopusModel)

return Horse.variant("BlueRingOctopus", BlueRingOctopusModel, "Rare", {
	seat = Vector3.new(0, 11.7, 0.6),
	neck = { center = Vector3.new(0, 6.5, 0), radius = 3.2 },
})
