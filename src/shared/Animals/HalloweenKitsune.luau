-- HalloweenKitsune: one of the Halloween world's giga rares (QM, Oct 15): the Kitsune in Halloween colours
-- (Shared/HalloweenSkins), its model, animations and seat. Config.HalloweenGiga.

local Horse = require(script.Parent.Horse)
local HalloweenSkins = require(script.Parent.Parent.HalloweenSkins)

return Horse.variant("HalloweenKitsune", HalloweenSkins.model("HalloweenKitsune", require(script.Parent.KitsuneModel)), "Legendary", {
	seat = Vector3.new(0, 6.65, 0.7),
	neck = { center = Vector3.new(0, 7.2, -2.7), radius = 1.4 },
})
