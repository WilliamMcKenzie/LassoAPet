-- HalloweenCrystalElephant: one of the Halloween world's giga rares (QM, Oct 15): the CrystalElephant in Halloween colours
-- (Shared/HalloweenSkins), its model, animations and seat. Config.HalloweenGiga.

local Horse = require(script.Parent.Horse)
local HalloweenSkins = require(script.Parent.Parent.HalloweenSkins)

return Horse.variant("HalloweenCrystalElephant", HalloweenSkins.model("HalloweenCrystalElephant", require(script.Parent.CrystalElephantModel)), "Legendary", {
	seat = Vector3.new(0, 8.1, 1.2),
	neck = { center = Vector3.new(0, 6.4, -4.6), radius = 2.3 },
})
