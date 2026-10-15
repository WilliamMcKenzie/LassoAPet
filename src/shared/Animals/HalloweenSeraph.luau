-- HalloweenSeraph: one of the Halloween world's giga rares (QM, Oct 15): the Seraph in Halloween colours
-- (Shared/HalloweenSkins), its model, animations and seat. Config.HalloweenGiga.

local Horse = require(script.Parent.Horse)
local HalloweenSkins = require(script.Parent.Parent.HalloweenSkins)

return Horse.variant("HalloweenSeraph", HalloweenSkins.model("HalloweenSeraph", require(script.Parent.Parent.Bosses.SeraphModel)), "Legendary", {
	seat = Vector3.new(0, 34.4, 0), -- (on its halo)
	neck = { center = Vector3.new(0, 18.15, 0), radius = 4.6 }, -- (round its core)
})
