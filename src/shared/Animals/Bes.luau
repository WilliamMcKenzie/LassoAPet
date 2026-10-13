-- Bes: World 2 Ancient Tomb's Legendary (QM, Oct 13: the three Tomb of the Ancients bosses
-- are the Tomb's Legendaries, "very complex/detailed"). A hulking sandstone war-god golem:
-- a lion face with glowing turquoise eyes under a striped nemes headdress and a crown of
-- five plumes, a gold and blue false beard and collar, a gold kilt with a glowing scarab,
-- glowing cracks, a round Silver Shield with an ankh on his left arm, a glowing Fire
-- Boomerang in his right fist, and three Pyramid Artifacts floating around him. Large
-- (tier 3). You ride on the gold throne on his back. designs/tomb/Bes.bbmodel
-- (tools/bes.py), converted into BesModel.luau by tools/bbmodel_to_luau.py (no --zyx).

local Horse = require(script.Parent.Horse)
local BesModel = require(script.Parent.BesModel)

return Horse.variant("Bes", BesModel, "Legendary", {
	seat = Vector3.new(0, 14.8, 1.1),
	neck = { center = Vector3.new(0, 14.8, -3.6), radius = 2.4 },
})
