-- Alpha Sandworm: the Desert's alpha (QM, Nov 6): the Sandworm in faded, paler sand, 3x as big.
-- Model from tools/alpha_skins.py (from the Sandworm's); its size, odds and numbers in Config.Alphas.

local Horse = require(script.Parent.Horse)
local AlphaSandwormModel = require(script.Parent.AlphaSandwormModel)

return Horse.variant("AlphaSandworm", AlphaSandwormModel, "Legendary", {
	seat = Vector3.new(0, 4.45, 1.6),
	neck = { center = Vector3.new(0, 3.2, -2.6), radius = 3 },
})
