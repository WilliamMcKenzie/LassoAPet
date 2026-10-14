-- Treasure Turtle: World 3 Pirate Cove's Legendary (Oct 14). A huge sea turtle carrying its own
-- desert island: a stepped green shell, a sand island with a leaning palm and a little chest,
-- a hooked beak, big flippers. You ride on the island's sand beside the palm.
-- designs/world3/pirate/TreasureTurtle.bbmodel (tools/pirate_turtle.py), converted (--zyx --meshes; QM's Blockbench edit, its shell one smooth MeshPart from ReplicatedStorage.AnimalMeshes) into TreasureTurtleModel.luau by
-- tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local TreasureTurtleModel = require(script.Parent.TreasureTurtleModel)

return Horse.variant("TreasureTurtle", TreasureTurtleModel, "Legendary", {
	seat = Vector3.new(-1.2, 7.18, 0.2),
	neck = { center = Vector3.new(0, 5.18, -8.4), radius = 2.0 },
})
