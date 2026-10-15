-- HalloweenBoneRex: one of the Halloween world's giga rares (QM, Oct 15): the BoneRex in Halloween colours
-- (Shared/HalloweenSkins), its model, animations and seat. Config.HalloweenGiga.

local Horse = require(script.Parent.Horse)
local HalloweenSkins = require(script.Parent.Parent.HalloweenSkins)

return Horse.variant("HalloweenBoneRex", HalloweenSkins.model("HalloweenBoneRex", require(script.Parent.BoneRexModel)), "Legendary", {
	seat = Vector3.new(0, 10.62, 0.6), -- on the spine, between the low blades over the back
	neck = { center = Vector3.new(0, 9.9, -5.2), radius = 2.2 },
})
