-- Penguin: black back, white belly and face, orange beak and feet. Uncommon.
-- Model from designs/snow/Penguin.bbmodel (tools/snow_designs.py), animated by tools/snow_rig.py
-- (idle, a waddle, a fast leaning waddle for the run) and converted into PenguinModel.luau by
-- tools/bbmodel_to_luau.py. You ride on top of its head. No LegFL, so its run kicks up no dust.

local Horse = require(script.Parent.Horse)
local PenguinModel = require(script.Parent.PenguinModel)

return Horse.variant("Penguin", PenguinModel, "Uncommon", {
	seat = Vector3.new(0, 9.2, -0.15),
	neck = { center = Vector3.new(0, 7.6, -0.15), radius = 2.2 },
})
