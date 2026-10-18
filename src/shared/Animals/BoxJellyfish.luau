-- Box Jellyfish: World 3 Cnidaria's Rare (Oct 14). A real cube of a jellyfish: a cyan
-- box bell with chamfered corners on a deep-blue lip (MeshParts, QM Oct 15), glowing yellow sense-eyes, big googly eyes, and
-- three ribbon tentacles trailing from each bottom corner.
-- Model from designs/cnidaria/BoxJellyfish.bbmodel (tools/box_jellyfish.py), converted into BoxJellyfishModel.luau by
-- tools/bbmodel_to_luau.py --zyx --meshes assets/meshes/BoxJellyfish (the bell and lip copied from
-- ReplicatedStorage.AnimalMeshes, tools/animal_meshes.luau).

local Horse = require(script.Parent.Horse)
local BoxJellyfishModel = require(script.Parent.BoxJellyfishModel)

return Horse.variant("BoxJellyfish", BoxJellyfishModel, "Rare", {
	seat = Vector3.new(0, 13.1, 0),
	neck = { center = Vector3.new(0, 9, 0), radius = 3.6 },
})
