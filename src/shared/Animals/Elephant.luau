-- Elephant: World 1 Meadow's Epic (QM, Nov 6: "just use the war elephant but take its armor
-- off"). Model from designs/animals/Elephant.bbmodel (tools/elephant_design.py), converted
-- into ElephantModel.luau by tools/bbmodel_to_luau.py --zyx. The War Elephant's seat and neck.

local Horse = require(script.Parent.Horse)
local ElephantModel = require(script.Parent.ElephantModel)

return Horse.variant("Elephant", ElephantModel, "Epic", {
	seat = Vector3.new(0, 8.1, 1.2),
	neck = { center = Vector3.new(0, 6.4, -4.6), radius = 2.3 },
})
