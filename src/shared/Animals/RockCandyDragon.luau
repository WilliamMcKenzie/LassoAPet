-- Rock Candy Dragon: World 3 Candyland giga rare, 1 in 1,000 of its stampede (Oct 14). A big flying
-- cherry-red dragon: rainbow rock-candy crystal clusters down its spine, bat wings of thick
-- hard-candy panes (grape, sky, lime) on white candy-stick fingers, white crystal horns, lollipop
-- cheeks and a lollipop tail tip. XL. You ride on its back between the wings.
-- designs/candyland/RockCandyDragon.bbmodel (tools/rock_candy_dragon.py), converted (no --zyx) into
-- RockCandyDragonModel.luau by tools/bbmodel_to_luau.py (about 189k characters, like the Nut's).

local Horse = require(script.Parent.Horse)
local RockCandyDragonModel = require(script.Parent.RockCandyDragonModel)

return Horse.variant("RockCandyDragon", RockCandyDragonModel, "Legendary", {
	seat = Vector3.new(0, 9.65, -0.2),
	neck = { center = Vector3.new(0, 9.4, -5.8), radius = 1.9 },
})
