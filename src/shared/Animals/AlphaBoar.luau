-- Alpha Boar: the Tundra's alpha (QM, Nov 6): the Elder Boar's model with glowing white eyes,
-- 2x the Boar. Model from tools/alpha_skins.py; its size, odds and numbers in Config.Alphas.

local Horse = require(script.Parent.Horse)
local AlphaBoarModel = require(script.Parent.AlphaBoarModel)

return Horse.variant("AlphaBoar", AlphaBoarModel, "Rare", {
	seat = Vector3.new(0, 9.4, 2.28),
	neck = { center = Vector3.new(0, 7.41, -6.84), radius = 4 },
})
