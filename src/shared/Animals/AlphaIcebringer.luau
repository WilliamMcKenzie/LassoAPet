-- Alpha Icebringer: the Tundra's alpha (QM, Nov 6): ice armour and tusks, glowing blue eyes.
-- Model from tools/alpha_skins.py; its size, odds and numbers in Config.Alphas.

local Horse = require(script.Parent.Horse)
local AlphaIcebringerModel = require(script.Parent.AlphaIcebringerModel)

return Horse.variant("AlphaIcebringer", AlphaIcebringerModel, "Divine", {
	seat = Vector3.new(0, 9.8, 1.1),
	neck = { center = Vector3.new(0, 9, -0.8), radius = 1.3 },
	size = 3, -- (the Icebringer's: Config.Alphas sets the 1.4x)
})
