-- BloatedMummy: World 2 Ancient Tomb's Uncommon (QM, Oct 13). A fat, round, waddling mummy
-- wrapped in cream and sand bandages, with mismatched googly eyes glowing green, a bandage
-- slipped over one eye, a gold broad collar, a gold scarab amulet and headband, torn holes
-- glowing green with wisps, a little teal scarab crawling out, and loose bandage ends (one
-- trails on the ground). Zombie arms reach forward. You ride on top behind its head.
-- designs/tomb/BloatedMummy.bbmodel (tools/bloated_mummy.py), converted into
-- BloatedMummyModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local BloatedMummyModel = require(script.Parent.BloatedMummyModel)

return Horse.variant("BloatedMummy", BloatedMummyModel, "Uncommon", {
	seat = Vector3.new(0, 6.85, 1.15),
	neck = { center = Vector3.new(0, 7.6, -1.5), radius = 2.3 },
})
