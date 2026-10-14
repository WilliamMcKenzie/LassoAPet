-- Desire Troll: World 3 Candyland Legendary (Oct 14). A hulking strawberry troll knuckle-walking on
-- grape fists, with candy-corn tusks and cotton-candy hair. Large. You ride on its wrapper saddle.
-- designs/candyland/DesireTroll.bbmodel (tools/desire_troll.py), converted (no --zyx) into DesireTrollModel.luau by
-- tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local DesireTrollModel = require(script.Parent.DesireTrollModel)

return Horse.variant("DesireTroll", DesireTrollModel, "Legendary", {
	seat = Vector3.new(0, 8.2, 0.5),
	neck = { center = Vector3.new(0, 7.2, -4.5), radius = 2.2 },
})
