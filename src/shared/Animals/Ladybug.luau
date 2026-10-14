-- Ladybug: World 3's Garden Uncommon (Oct 14; roster approved by the coordinator for QM): a chunky ladybird: a red two-half shell with raised black spots, a black head with
-- white cheeks and big googly eyes, curly antennae; its shell lifts and amber wings buzz in the gallop.
-- You ride on its shell.
-- designs/garden/Ladybug.bbmodel (tools/garden_ladybug.py), converted (--zyx) into LadybugModel.luau by
-- tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local LadybugModel = require(script.Parent.LadybugModel)

return Horse.variant("Ladybug", LadybugModel, "Uncommon", {
	seat = Vector3.new(0, 6.0, 0.6),
	neck = { center = Vector3.new(0, 3.1, -4.6), radius = 2.5 },
})
