-- Parrot: World 3 Pirate Cove's Uncommon (Oct 14), the pirate's macaw. A scarlet macaw that flies
-- everywhere: wings banded red, yellow and blue, a long red tail, raised plate eyes, a hooked
-- beak and a little black tricorn with a skull. You ride on its back between the wings.
-- designs/world3/pirate/Parrot.bbmodel (tools/pirate_parrot.py), converted (--zyx) into ParrotModel.luau by
-- tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local ParrotModel = require(script.Parent.ParrotModel)

return Horse.variant("Parrot", ParrotModel, "Uncommon", {
	seat = Vector3.new(0, 4.55, 0.6),
	neck = { center = Vector3.new(0, 3.5, -5.3), radius = 1.8 },
})
