-- Spoiled Creampuff: World 3 Candyland Rare (Oct 14). A grumpy cream puff gone off (green mould, a
-- sour drip, a cracked lid) whose top bun chomps like a mouth as it hops. You ride on its lid.
-- designs/candyland/Creampuff.bbmodel (tools/creampuff.py), converted (no --zyx) into CreampuffModel.luau by
-- tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local CreampuffModel = require(script.Parent.CreampuffModel)

return Horse.variant("Creampuff", CreampuffModel, "Rare", {
	seat = Vector3.new(0, 5.65, 0.9),
	seatBone = "neck",
	neck = { center = Vector3.new(0, 4.4, -0.2), radius = 2.6 },
})
