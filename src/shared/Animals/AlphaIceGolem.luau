-- Alpha Ice Golem: the Tundra's alpha (QM, Nov 6): yellow instead of blue, 1.5x.
-- Model from tools/alpha_skins.py; its size, odds and numbers in Config.Alphas.

local Horse = require(script.Parent.Horse)
local AlphaIceGolemModel = require(script.Parent.AlphaIceGolemModel)

return Horse.variant("AlphaIceGolem", AlphaIceGolemModel, "Legendary", {
	seat = Vector3.new(0, 13.36, 0.4),
	neck = { center = Vector3.new(0, 9.2, -1.6), radius = 2.8 },
})
