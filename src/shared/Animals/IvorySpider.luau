-- IvorySpider: World 2's Crimson Lands Epic, a white spider with four red eyes and
-- three-joint legs. QM's model designs/crimson/IvorySpider.bbmodel (from QM's tarantula
-- base via tools/ivory_spider.py), converted --zyx into IvorySpiderModel.luau by
-- tools/bbmodel_to_luau.py. You ride on its abdomen, so the seat follows that bone.

local Horse = require(script.Parent.Horse)
local IvorySpiderModel = require(script.Parent.IvorySpiderModel)

return Horse.variant("IvorySpider", IvorySpiderModel, "Epic", {
	seat = Vector3.new(0, 2, 2.5),
	seatBone = "abdomen",
	neck = { center = Vector3.new(0, 0.7, -2.1), radius = 1.6 },
})
