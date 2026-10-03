-- Squid: the Kraken's model and animations in pink and orange, medium size. Epic, Ocean.
-- designs/ocean/Squid.bbmodel is made from QM's Kraken by tools/squid_design.py and
-- converted into SquidModel.luau by tools/bbmodel_to_luau.py. You ride on top of its mantle.

local Horse = require(script.Parent.Horse)
local SquidModel = require(script.Parent.SquidModel)

return Horse.variant("Squid", SquidModel, "Epic", {
	seat = Vector3.new(0, 29.1, 3.9),
	neck = { center = Vector3.new(0, 5.8, 0), radius = 2.4 },
	seatOnNeck = true, -- on top of the mantle, which leans and bobs as it glides (QM: rider was hidden)
})
