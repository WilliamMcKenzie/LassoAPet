-- Gumdrop Frog: World 3 Candyland Uncommon (Oct 14). A squat orange frog shaped like a sugar-crusted
-- gumdrop, with round eye bumps and a wide grin; it hops. You ride on top of its dome. (QM, Oct 15:
-- the gumdrop and eye bumps are low-poly meshes, converted with --meshes assets/meshes/GumdropFrog.)
-- designs/candyland/GumdropFrog.bbmodel (tools/gumdrop_frog.py), converted (no --zyx) into GumdropFrogModel.luau by
-- tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local GumdropFrogModel = require(script.Parent.GumdropFrogModel)

return Horse.variant("GumdropFrog", GumdropFrogModel, "Uncommon", {
	seat = Vector3.new(0, 5.1, 0.2),
	neck = { center = Vector3.new(0, 2.6, -3), radius = 2.3 },
})
