-- Emperor Scorpion: the Desert's alpha Scorpion (QM, Nov 6): dark scales, glowing blue eyes, 2x.
-- Model from tools/alpha_skins.py; its size, odds and numbers in Config.Alphas.

local Horse = require(script.Parent.Horse)
local EmperorScorpionModel = require(script.Parent.EmperorScorpionModel)

return Horse.variant("EmperorScorpion", EmperorScorpionModel, "Epic", {
	seat = Vector3.new(0, 4.42, -0.52),
	neck = { center = Vector3.new(0, 2.99, -3.9), radius = 2.2 },
})
