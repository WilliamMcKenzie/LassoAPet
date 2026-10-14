-- Swoll Fairy: World 3 Candyland Epic (Oct 14). A hugely muscly pink fairy in a mint top and lilac
-- tutu, flexing both biceps as she flies on candy-glass wings. You ride on her back cushion.
-- designs/candyland/SwollFairy.bbmodel (tools/swoll_fairy.py), converted (no --zyx) into SwollFairyModel.luau by
-- tools/bbmodel_to_luau.py.

local Horse = require(script.Parent.Horse)
local SwollFairyModel = require(script.Parent.SwollFairyModel)

return Horse.variant("SwollFairy", SwollFairyModel, "Epic", {
	seat = Vector3.new(0, 7.1, 1.7),
	neck = { center = Vector3.new(0, 8, 0), radius = 1.7 },
})
