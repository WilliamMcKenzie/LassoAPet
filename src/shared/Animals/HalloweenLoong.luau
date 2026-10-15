-- HalloweenLoong: one of the Halloween world's giga rares (QM, Oct 15): the Loong in Halloween colours
-- (Shared/HalloweenSkins), its model, animations and seat. Config.HalloweenGiga.

local Horse = require(script.Parent.Horse)
local HalloweenSkins = require(script.Parent.Parent.HalloweenSkins)

return Horse.variant("HalloweenLoong", HalloweenSkins.model("HalloweenLoong", require(script.Parent.LoongModel)), "Legendary", {
	seat = Vector3.new(0, 7, -1.2),
	seatBone = "saddle", -- on the chest, which the slither swings about
	neck = { center = Vector3.new(0, 4.8, -7.2), radius = 2.6 },
})
