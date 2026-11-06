-- Alpha Rhino: World 1 Meadow's alpha (QM, Nov 6): the Rhino 1.4x, tinted red, about 10x
-- rarer. Model from designs/animals/AlphaRhino.bbmodel (tools/alpha_designs.py).

local Horse = require(script.Parent.Horse)
local AlphaRhinoModel = require(script.Parent.AlphaRhinoModel)

return Horse.variant("AlphaRhino", AlphaRhinoModel, "Legendary", {
	seat = Vector3.new(0, 10.4, 3.08),
	neck = { center = Vector3.new(0, 7.28, -5.18), radius = 2.66 },
})
