-- Reef Titan: one of World 3 Cnidaria's two giga rares (Oct 14), about 1 in 1,000. A
-- colossal old sea turtle carrying a living reef on its shell: six big coral clusters, glowing
-- anemones, a giant clam with a glowing pearl and a little sunken temple. You ride a mossy
-- stone seat at the front of the shell.
-- Model from designs/cnidaria/ReefTitan.bbmodel (tools/reef_titan.py), converted into ReefTitanModel.luau by
-- tools/bbmodel_to_luau.py --zyx.

local Horse = require(script.Parent.Horse)
local ReefTitanModel = require(script.Parent.ReefTitanModel)

return Horse.variant("ReefTitan", ReefTitanModel, "Legendary", {
	seat = Vector3.new(0, 13.45, -3.4),
	neck = { center = Vector3.new(0, 9.6, -17.6), radius = 3.2 },
})
