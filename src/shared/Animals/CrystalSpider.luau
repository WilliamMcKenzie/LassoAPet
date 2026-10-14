-- Crystal Spider: World 2 Crystal Cavern's spider (Epic). Periwinkle blue with crystals on its
-- abdomen, cyan claws and fangs. Bones and idle from the tarantula QM sent; model from
-- designs/crystal/CrystalSpider.bbmodel (tools/crystal_spider.py), converted (--zyx) into
-- CrystalSpiderModel.luau by tools/bbmodel_to_luau.py. You ride on its back, in front of the crystals.

local Horse = require(script.Parent.Horse)
local CrystalSpiderModel = require(script.Parent.CrystalSpiderModel)

return Horse.variant("CrystalSpider", CrystalSpiderModel, "Epic", {
	seat = Vector3.new(0, 1.8, -0.5),
	neck = { center = Vector3.new(0, 1.2, -1.2), radius = 1.8 },
})
