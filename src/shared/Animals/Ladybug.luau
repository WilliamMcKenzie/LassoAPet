-- Ladybug: World 3's Garden Uncommon (Oct 14; roster approved by the coordinator for QM): a chunky ladybird: a red two-half shell with flat black spots, a black head with
-- white cheeks and big googly eyes, curly antennae; its shell lifts and amber wings buzz in the gallop.
-- You ride on its shell.
-- designs/garden/Ladybug.bbmodel (QM's Blockbench edit, Oct 15; first built by tools/garden_*.py), converted (--zyx --meshes: the shell halves and their spots are low-poly meshes, QM Oct 14) into LadybugModel.luau by
-- tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local LadybugModel = require(script.Parent.LadybugModel)

return Horse.variant("Ladybug", LadybugModel, "Uncommon", {
	seat = Vector3.new(0, 9.0, 2.6),
	neck = { center = Vector3.new(0, 2.5, -3.9), radius = 2.5 },
})
