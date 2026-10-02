-- Kraken: a squid-like head under a maroon cap, eight tentacles splayed on the sea
-- floor. Legendary, Ocean. Built by tools/kraken_design.py (designs/ocean/Kraken.bbmodel)
-- and converted into KrakenModel.luau by tools/bbmodel_to_luau.py. You ride on top of its cap.

local Horse = require(script.Parent.Horse)
local KrakenModel = require(script.Parent.KrakenModel)

return Horse.variant("Kraken", KrakenModel, "Legendary", {
	seat = Vector3.new(0, 16.3, 0.3),
	neck = { center = Vector3.new(0, 6.4, 0), radius = 2.7 },
})
