-- The Royal Cnidarian: World 3 Cnidaria's boss (Oct 14; after the Cnidarian Reef's boss).
-- A gigantic crowned jellyfish: a low-poly MeshPart bell in violet, magenta and orchid
-- bands (QM Oct 15), a gold crown of pyramid points
-- with glowing gems, big googly eyes under scowling brows, a mouth of pyramid teeth, a frilled
-- skirt that pulses, twelve long glowing cyan and pink tentacles, four frilly oral arms, and
-- four little Gold Cnidarian jellies orbiting it. It charges through you like World 2's bosses.
-- Model from designs/cnidaria/RoyalCnidarian.bbmodel (tools/royal_cnidarian.py), converted
-- into RoyalCnidarianModel.luau by tools/bbmodel_to_luau.py --zyx --meshes
-- assets/meshes/RoyalCnidarian (the bell and the minions' bells from ReplicatedStorage.AnimalMeshes).

local Horse = require(script.Parent.Parent.Animals.Horse)
local RoyalCnidarianModel = require(script.Parent.RoyalCnidarianModel)

return Horse.variant("RoyalCnidarian", RoyalCnidarianModel, "Legendary", {
	seat = Vector3.new(0, 17.6, 0), -- (no one rides the boss: the top of its bell, in the crown)
	neck = { center = Vector3.new(0, 12, 0), radius = 6 },
	size = 3, -- x the model: about 63 studs (a guess)
})
