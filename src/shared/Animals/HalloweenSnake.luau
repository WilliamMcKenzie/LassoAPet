-- HalloweenSnake: one of the Halloween world's giga rares (QM, Oct 15): the Snake in Halloween colours
-- (Shared/HalloweenSkins), its model, animations and seat. Config.HalloweenGiga.

local Horse = require(script.Parent.Horse)
local HalloweenSkins = require(script.Parent.Parent.HalloweenSkins)

return Horse.variant("HalloweenSnake", HalloweenSkins.model("HalloweenSnake", require(script.Parent.SnakeModel)), "Legendary", {
	seat = Vector3.new(0, 3.5, 1.6),
	neck = { center = Vector3.new(0, 2.2, -5), radius = 2.3 },
})
