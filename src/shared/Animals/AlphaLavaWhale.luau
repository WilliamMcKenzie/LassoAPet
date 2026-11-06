-- Alpha Lava Whale: the Volcano's alpha (QM, Nov 6): a dark obsidian body instead of orange, 1.3x.
-- Model from tools/alpha_skins.py; its size, odds and numbers in Config.Alphas.

local Horse = require(script.Parent.Horse)
local AlphaLavaWhaleModel = require(script.Parent.AlphaLavaWhaleModel)

return Horse.variant("AlphaLavaWhale", AlphaLavaWhaleModel, "Legendary", {
	seat = Vector3.new(0, 6.4, 1.2),
	neck = { center = Vector3.new(0, 4.5, -6.5), radius = 3.8 },
})
