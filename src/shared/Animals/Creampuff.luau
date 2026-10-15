-- Creampuff: World 3 Candyland Rare (Oct 14). A grumpy cream puff whose top bun chomps like a mouth
-- as it hops. You ride on its lid. (QM, Oct 15: no longer spoiled; bun, cream, lid and cherry are
-- smooth meshes, converted with --meshes assets/meshes/Creampuff.)
-- designs/candyland/Creampuff.bbmodel (tools/creampuff.py), converted (no --zyx) into CreampuffModel.luau by
-- tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local CreampuffModel = require(script.Parent.CreampuffModel)

return Horse.variant("Creampuff", CreampuffModel, "Rare", {
	seat = Vector3.new(0, 5.75, 0.9),
	seatBone = "neck",
	neck = { center = Vector3.new(0, 4.5, -0.2), radius = 2.6 },
})
