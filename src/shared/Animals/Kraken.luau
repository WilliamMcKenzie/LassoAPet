-- Kraken: a squid with a tall tilted mantle, one big eye and eight tentacles splayed on
-- the sea floor. Legendary, Ocean, XL (tier 4). QM's model designs/ocean/Kraken.bbmodel, animated by
-- tools/kraken_rig.py and converted into KrakenModel.luau by tools/bbmodel_to_luau.py.
-- You ride on the top of its mantle.

local Horse = require(script.Parent.Horse)
local KrakenModel = require(script.Parent.KrakenModel)

return Horse.variant("Kraken", KrakenModel, "Legendary", {
	seat = Vector3.new(0, 29.1, 3.9),
	neck = { center = Vector3.new(0, 5.8, 0), radius = 2.4 },
})
