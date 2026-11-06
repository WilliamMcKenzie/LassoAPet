-- Gecko: World 1 Meadow's Rare (QM, Nov 6), low and long: green with orange bands, big
-- googly eyes, sticky toe pads and a tapering tail. Model from designs/animals/Gecko.bbmodel
-- (tools/gecko_design.py), converted into GeckoModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local GeckoModel = require(script.Parent.GeckoModel)

return Horse.variant("Gecko", GeckoModel, "Rare", {
	seat = Vector3.new(0, 5.6, 0.32),
	neck = { center = Vector3.new(0, 3.52, -7.04), radius = 3.04 },
})
