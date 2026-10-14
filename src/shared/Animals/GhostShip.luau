-- Ghost Ship: World 3 Pirate Cove's giga rare (Oct 14). QM: built on the Pirate Cove's pirate ship prop mesh
-- (tools/pirate_meshes.py) at 0.6x, haunted purple with glowing ghost sails, a face on the bow (googly
-- eyes, a red mouth of teeth, a chomping jaw), sailing on ghost mist. You ride on the deck.
-- designs/world3/pirate/GhostShip.bbmodel (tools/pirate_ghost_ship.py), converted (--zyx --meshes) into
-- GhostShipModel.luau by tools/bbmodel_to_luau.py: the ship's pieces are MeshParts (one per bone and colour)
-- copied from ReplicatedStorage.AnimalMeshes (tools/animal_meshes.luau); the face and mist are blocks.

local Horse = require(script.Parent.Horse)
local GhostShipModel = require(script.Parent.GhostShipModel)

return Horse.variant("GhostShip", GhostShipModel, "Legendary", {
	seat = Vector3.new(0, 6.6, 2.0), -- (on the deck behind the mainmast: QM's ship-prop remake, Oct 14)
	neck = { center = Vector3.new(0, 4.7, -8.5), radius = 3.0 }, -- (the face on the bow)
})
