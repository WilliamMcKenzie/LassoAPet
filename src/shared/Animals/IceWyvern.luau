-- IceWyvern: a two-legged ice wyvern with foldable wings, antlers and tusks. Legendary.
-- QM's model designs/snow/IceWyvern.bbmodel, animated by tools/snow_rig.py and converted into
-- IceWyvernModel.luau by tools/bbmodel_to_luau.py. You ride on its back between the wings.
-- Its slit pupils glow (Neon). Besides idle, walk and gallop it has a "fly" animation
-- (wingbeats, legs tucked, the body 2 studs up) that Horse:update doesn't blend; it's there
-- for a flying ability. No LegFL, so its run kicks up no dust.
-- Seat and neck points are in the model's own frame; the root bone's 10 degree rest tilt is
-- applied on top, as for the parts.

local Horse = require(script.Parent.Horse)
local IceWyvernModel = require(script.Parent.IceWyvernModel)

return Horse.variant("IceWyvern", IceWyvernModel, "Legendary", {
	seat = Vector3.new(0, 10.76, -0.99),
	neck = { center = Vector3.new(0, 8.4, -6.4), radius = 2.2 },
})
