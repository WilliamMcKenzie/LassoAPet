-- Orange Butterfly: World 2 Woodland Maze's Rare (QM, Oct 13). A chubby fuzzy brown
-- butterfly with a cream collar, a striped abdomen and big googly eyes; four big-block
-- wings, sunny yellow by the body to bright orange to autumn orange-red at the edges, cream
-- spots on the forewings and brown eye spots on the hindwings. It hovers, and sprint flies
-- it up like the Crystal Phoenix (Config.SprintSpecials). You ride on its back.
-- Model from designs/woodland/OrangeButterfly.bbmodel (tools/orange_butterfly.py, which
-- also converts it into OrangeButterflyModel.luau with --zyx).

local Horse = require(script.Parent.Horse)
local OrangeButterflyModel = require(script.Parent.OrangeButterflyModel)

return Horse.variant("OrangeButterfly", OrangeButterflyModel, "Rare", {
	seat = Vector3.new(0, 9.4, 0.5),
	neck = { center = Vector3.new(0, 7.5, -4.1), radius = 1.9 },
})
