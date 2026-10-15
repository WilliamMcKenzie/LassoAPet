-- VineMonster: World 3's Garden Rare (Oct 14; roster approved by the coordinator for QM): a block gorilla of bright vines that knuckle-walks:
-- smooth mesh vines spiralling up its arms, mesh leaf shoulder pads and a mesh pink rose on its head
-- (redone cleaner Oct 15; QM then edited the .bbmodel by hand, now the source: three eyes, no mouth), thorny fists, pyramid thorn teeth and back thorns. You ride on its shoulders.
-- designs/garden/VineMonster.bbmodel (tools/garden_vine.py), converted (--zyx) into VineMonsterModel.luau by
-- tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local VineMonsterModel = require(script.Parent.VineMonsterModel)

return Horse.variant("VineMonster", VineMonsterModel, "Rare", {
	seat = Vector3.new(0, 9.4, 0.6),
	neck = { center = Vector3.new(0, 9.35, -3.6), radius = 2.7 },
})
