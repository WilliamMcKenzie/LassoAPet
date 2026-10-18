-- HalloweenKraken: one of the Halloween world's giga rares (QM, Oct 15): the Kraken in Halloween colours
-- (Shared/HalloweenSkins), its model, animations and seat. Config.HalloweenGiga.

local Horse = require(script.Parent.Horse)
local HalloweenSkins = require(script.Parent.Parent.HalloweenSkins)

return Horse.variant("HalloweenKraken", HalloweenSkins.model("HalloweenKraken", require(script.Parent.KrakenModel)), "Legendary", {
	seat = Vector3.new(0, 11.6, 3.5), -- on the back of the cap's rim, over the eye (clear of the mantle)
	seatBone = "root", -- moves with the head as it glides, staying upright
	gallopOnSprint = true, -- QM: its gallop only while sprinting, else its walk
	neck = { center = Vector3.new(0, 5.8, 0), radius = 2.4 },
})
