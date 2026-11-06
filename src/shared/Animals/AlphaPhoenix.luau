-- Alpha Phoenix: the Volcano's alpha (QM, Nov 6): blue fire instead of regular fire, 2x.
-- Model from tools/alpha_skins.py; its size, odds and numbers in Config.Alphas.

local Horse = require(script.Parent.Horse)
local AlphaPhoenixModel = require(script.Parent.AlphaPhoenixModel)

return Horse.variant("AlphaPhoenix", AlphaPhoenixModel, "Legendary", {
	seat = Vector3.new(0, 4.5, 0.8),
	neck = { center = Vector3.new(0, 6.9, -4.3), radius = 1.8 },
})
