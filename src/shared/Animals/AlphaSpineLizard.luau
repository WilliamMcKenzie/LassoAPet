-- Alpha Spine Lizard: the Desert's alpha (QM, Nov 6): a darker body, a glowing sail and spines.
-- Model from tools/alpha_skins.py; its size, odds and numbers in Config.Alphas.

local Horse = require(script.Parent.Horse)
local AlphaSpineLizardModel = require(script.Parent.AlphaSpineLizardModel)

return Horse.variant("AlphaSpineLizard", AlphaSpineLizardModel, "Legendary", {
	seat = Vector3.new(0, 4.2, -4.08),
	neck = { center = Vector3.new(0, 2.84, -4.42), radius = 2.04 },
})
