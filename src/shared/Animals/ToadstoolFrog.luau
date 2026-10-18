-- ToadstoolFrog: World 3's Garden Rare (Oct 14; roster approved by the coordinator for QM): a fat lime frog wearing a giant purple toadstool with white spots for a hat;
-- it hops. You ride on the cap (it's on the neck bone).
-- designs/garden/ToadstoolFrog.bbmodel (QM's Blockbench edit, Oct 15; first built by tools/garden_*.py), converted (--zyx --meshes) into ToadstoolFrogModel.luau by
-- tools/bbmodel_to_luau.py: blocks, the cap a low-poly MeshPart (QM Oct 14 pilot: only the cap and its underside, as the GiantToadstool prop), copied from ReplicatedStorage.AnimalMeshes
-- (tools/animal_meshes.luau).

local Horse = require(script.Parent.Horse)
local ToadstoolFrogModel = require(script.Parent.ToadstoolFrogModel)

return Horse.variant("ToadstoolFrog", ToadstoolFrogModel, "Rare", {
	seat = Vector3.new(0, 11.6, -0.3),
	seatBone = "neck",
	neck = { center = Vector3.new(0, 4.6, -3.0), radius = 3.8 },
})
