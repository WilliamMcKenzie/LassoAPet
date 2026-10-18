-- Bumblebee: World 3's Garden Uncommon (Oct 14; roster approved by the coordinator for QM): a round fuzzy bumblebee in yellow and black bands, a big black head with googly
-- eyes and pink cheeks, four pale blue wings, a pyramid stinger. It hovers and flies like the
-- Hawkmoth (Config.SprintSpecials). You ride on its back.
-- designs/garden/Bumblebee.bbmodel (QM's Blockbench edit, Oct 15; first built by tools/garden_*.py), converted (--zyx --meshes: its round body and wings are low-poly meshes, QM Oct 14) into BumblebeeModel.luau by
-- tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local BumblebeeModel = require(script.Parent.BumblebeeModel)

return Horse.variant("Bumblebee", BumblebeeModel, "Uncommon", {
	seat = Vector3.new(0, 8.2, -1.2),
	neck = { center = Vector3.new(0, 5.7, -4.4), radius = 2.6 },
})
