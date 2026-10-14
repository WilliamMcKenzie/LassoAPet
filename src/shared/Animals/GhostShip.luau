-- Ghost Ship: World 3 Pirate Cove's giga rare (Oct 14; about 1 in 1,000 of its stampede). A living
-- haunted pirate ship sailing on glowing mist: a purple hull with gold rails, glowing cyan
-- ghost sails on three masts, a Jolly Roger, cannons, a stern castle with glowing windows,
-- and a face on the bow: big plate eyes and a mouth of teeth that chomps. You ride on deck.
-- designs/world3/pirate/GhostShip.bbmodel (tools/pirate_ghost_ship.py), converted (--zyx) into GhostShipModel.luau by
-- tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local GhostShipModel = require(script.Parent.GhostShipModel)

return Horse.variant("GhostShip", GhostShipModel, "Legendary", {
	seat = Vector3.new(0, 7.7, -2.8),
	neck = { center = Vector3.new(0, 5.7, -6.75), radius = 3.2 },
})
