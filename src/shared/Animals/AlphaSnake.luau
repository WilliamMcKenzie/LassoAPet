-- Alpha Snake: the Desert's alpha (QM, Nov 6): glowing green horns and spines instead of blue.
-- Model from tools/alpha_skins.py; its size, odds and numbers in Config.Alphas.

local Horse = require(script.Parent.Horse)
local AlphaSnakeModel = require(script.Parent.AlphaSnakeModel)

return Horse.variant("AlphaSnake", AlphaSnakeModel, "Divine", {
	seat = Vector3.new(0, 3.5, 1.6),
	neck = { center = Vector3.new(0, 2.2, -5), radius = 2.3 },
})
