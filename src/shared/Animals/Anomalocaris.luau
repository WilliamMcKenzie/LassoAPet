-- Anomalocaris: World 3 Cnidaria's Uncommon (Oct 14). The prehistoric "weird shrimp":
-- a long coral-red segmented body, four chunky orange swim lobes down each side that
-- ripple, googly eyes up on stalks, two spiny cream grasping arms and a blue pyramid tail fan.
-- Model from designs/cnidaria/Anomalocaris.bbmodel (tools/anomalocaris.py), converted into AnomalocarisModel.luau by
-- tools/bbmodel_to_luau.py --zyx.

local Horse = require(script.Parent.Horse)
local AnomalocarisModel = require(script.Parent.AnomalocarisModel)

return Horse.variant("Anomalocaris", AnomalocarisModel, "Uncommon", {
	seat = Vector3.new(0, 5.95, 0.5),
	neck = { center = Vector3.new(0, 4.7, -4.5), radius = 2 },
})
