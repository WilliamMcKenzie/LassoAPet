-- TombstoneCrawler: the Halloween world's Soul Valley Uncommon (QM, Oct 15): a grey tombstone on four stubby legs with moss on its shoulders.
-- designs/halloween/TombstoneCrawler.bbmodel (tools/halloween_tombstone.py), converted (--zyx --meshes) into
-- TombstoneCrawlerModel.luau by tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local TombstoneCrawlerModel = require(script.Parent.TombstoneCrawlerModel)

return Horse.variant("TombstoneCrawler", TombstoneCrawlerModel, "Uncommon", {
	seat = Vector3.new(0, 9.3, 0),
	neck = { center = Vector3.new(0, 6, 0), radius = 2.6 },
})
