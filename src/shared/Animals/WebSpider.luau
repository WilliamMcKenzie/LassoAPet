-- Cave Spider: World 1 Dungeon's Rare (QM, Nov 7: one of the luck-padding animals QM picked).
-- Model from tools/filler_dungeon.py (cave_spider), rigged by tools/filler_export.py into
-- designs/filler/rigged/WebSpider.bbmodel and converted into WebSpiderModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local WebSpiderModel = require(script.Parent.WebSpiderModel)

return Horse.variant("WebSpider", WebSpiderModel, "Rare", {
	seat = Vector3.new(0, 6.6, 1.12),
	neck = { center = Vector3.new(0, 3.68, -1.78), radius = 2.26 },
})
