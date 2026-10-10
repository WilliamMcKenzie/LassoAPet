-- Chicken: a giant Minecraft-style chicken, white boxes, yellow beak, red wattle, red eyes
-- (QM picked take A, Oct 10). Two legs and flapping wings like the Penguin: no LegFL, so its
-- run kicks up no dust. Model from designs/animals/Chicken.bbmodel (tools/chicken_design.py game),
-- converted into ChickenModel.luau by tools/bbmodel_to_luau.py. Seat and neck loop from meta.json.

local Horse = require(script.Parent.Horse)
local ChickenModel = require(script.Parent.ChickenModel)

return Horse.variant("Chicken", ChickenModel, "Rare", {
	seat = Vector3.new(0, 7.4, 0.6),
	neck = { center = Vector3.new(0, 7.2, -3.2), radius = 1.9 },
})
