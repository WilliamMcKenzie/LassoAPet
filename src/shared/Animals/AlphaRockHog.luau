-- Alpha Rock Hog: the Volcano's alpha (QM, Nov 6): its whole body molten, not just the horns.
-- Model from tools/alpha_skins.py; its size, odds and numbers in Config.Alphas.

local Horse = require(script.Parent.Horse)
local AlphaRockHogModel = require(script.Parent.AlphaRockHogModel)

return Horse.variant("AlphaRockHog", AlphaRockHogModel, "Epic", {
	seat = Vector3.new(0, 6.27, 0.9),
	neck = { center = Vector3.new(0, 4.94, -4.56), radius = 2.66 },
})
