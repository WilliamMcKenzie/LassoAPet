-- HalloweenPhoenix: one of the Halloween world's giga rares (QM, Oct 15): the Phoenix in Halloween colours
-- (Shared/HalloweenSkins), its model, animations and seat. Config.HalloweenGiga.

local Horse = require(script.Parent.Horse)
local HalloweenSkins = require(script.Parent.Parent.HalloweenSkins)

return Horse.variant("HalloweenPhoenix", HalloweenSkins.model("HalloweenPhoenix", require(script.Parent.PhoenixModel)), "Legendary", {
	seat = Vector3.new(0, 4.5, 0.8),
	neck = { center = Vector3.new(0, 6.9, -4.3), radius = 1.8 },
})
