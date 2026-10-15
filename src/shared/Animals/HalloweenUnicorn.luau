-- HalloweenUnicorn: one of the Halloween world's giga rares (QM, Oct 15): the Unicorn in Halloween colours
-- (Shared/HalloweenSkins), its model, animations and seat. Config.HalloweenGiga.

local Horse = require(script.Parent.Horse)
local HalloweenSkins = require(script.Parent.Parent.HalloweenSkins)

return Horse.variant("HalloweenUnicorn", HalloweenSkins.model("HalloweenUnicorn", require(script.Parent.UnicornModel)), "Legendary", {
	seat = Vector3.new(0, 7.3, 1),
	neck = { center = Vector3.new(0, 7.4, -1.9), radius = 1.35 },
})
