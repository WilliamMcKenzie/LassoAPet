-- VineMonster: World 3's Garden Rare (Oct 14; roster approved by the coordinator for QM): a gorilla of bright twisted vines that knuckle-walks: chunky tendrils curling
-- round its arms and legs, thorny fists, pyramid thorn teeth and back thorns, a pink rose on
-- its head. You ride on its shoulders.
-- designs/garden/VineMonster.bbmodel (tools/garden_vine.py), converted (--zyx) into VineMonsterModel.luau by
-- tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local VineMonsterModel = require(script.Parent.VineMonsterModel)

return Horse.variant("VineMonster", VineMonsterModel, "Rare", {
	seat = Vector3.new(0, 9.2, 0.4),
	neck = { center = Vector3.new(0, 10.0, -2.6), radius = 2.7 },
})
